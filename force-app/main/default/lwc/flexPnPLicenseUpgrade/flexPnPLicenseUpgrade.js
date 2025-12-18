import { LightningElement, track, api } from 'lwc';
import getSubscriptionsByProductAndAddress from '@salesforce/apex/FlexContractConsolidation.getSubscriptionsByProductAndAddress';

export default class FlexPnPLicenseUpgrade extends LightningElement {
    @api contractIds;
    @api pricebookId;
    @api accountPilotCustomer;
    @api tempIds;
    @api pnpOneData;
    @api pnpToggleData;
    @track hasProProduct = false;
    @track togglePnP = false;
    @track validationError = '';
    @track isLoading = false;
    @track validationErrors = [];
    @track subscriptionData = [];
    @track subData ;
    @track products = [];
    isLoading = false;
    isPlatformUpgrade = false;
    baseURL =window.location.origin;

    @api
    get togglePnPValue() {
        return this.togglePnP;
    }

    @api
    getSelectedProducts() {
        const selectedProducts = this.products.filter(product => product.selected);
        return selectedProducts;
    }

    @api
    validate() {
        if (this.togglePnP) {
            const hasUnselectedProducts = this.subscriptionData.some(data => 
                !data.pnpOneProductDetails.selectedProductId || 
                data.pnpOneProductDetails.selectedProductId === data.productId
            );
            if (hasUnselectedProducts) {
                this.validationError = 'Please select upgrade products for all items when Platform entitlements upgrade is enabled';
                return {
                    isValid: false,
                    errorMessage: this.validationError
                };
            }
        }
        this.validationError = '';
        return {
            isValid: true,
            errorMessage: ''
        };
    }

    @api
    createPnPScreenOneJSON() {
        const pnpScreenOneData = this.subscriptionData.map(parent => {
            let selectedUpgradeProduct = null;
            if (parent.pnpOneProductDetails?.selectedProductId && 
                parent.pnpOneProductDetails?.selectedProductName &&
                parent.pnpOneProductDetails.selectedProductId !== parent.productId) {
                selectedUpgradeProduct = {
                    productId: parent.pnpOneProductDetails.selectedProductId,
                    productName: parent.pnpOneProductDetails.selectedProductName,
                    isPlatformProduct: parent.pnpOneProductDetails.isPlatformProduct
                };
            }

            return {
                productId: parent.productId,
                productName: parent.productName,
                productCode: parent.productCode,
                totalQuantity: parent.totalQuantity,
                licenseType: parent.licenseType,
                isPlatformUpgradeEnabled: this.togglePnP,
                addressDetails: parent.subscriptionWrappers.map(child => {
                    return {
                        shippingAddressId: child.shippingAddressId,
                        quantity: child.quantity,
                        licenseType: child.licenseType,
                        selectedUpgradeProduct: selectedUpgradeProduct 
                    };
                })
            };
        });
        return pnpScreenOneData;
    }

    @api
    setValidationErrors(errors) {
        if (!errors || !Array.isArray(errors)) return;
        const errorMap = new Map();
        let firstError = null;
        errors.forEach(error => {
            if (!firstError) {
                firstError = error;
            }
            error.products.forEach(product => {
                if (!errorMap.has(product.parentId)) {
                    errorMap.set(product.parentId, {
                        hasValidationError: true,
                        validationMessage: error.message,
                        bannerMessage: error.bannerMessage
                    });
                }
            });
        });

        // Set the banner message to the first error's banner message
        if (firstError) {
            this.validationError = firstError.bannerMessage;
        }

        // Update the subscription data with validation errors
        this.subscriptionData = this.subscriptionData.map(wrapper => {
            const error = errorMap.get(wrapper.productId);
            if (error) {
                return {
                    ...wrapper,
                    hasValidationError: true,
                    validationMessage: error.validationMessage,
                    bannerMessage: error.bannerMessage
                };
            }
            return {
                ...wrapper,
                hasValidationError: false,
                validationMessage: '',
                bannerMessage: ''
            };
        });
    }

    areArraysEqual = (arr1, arr2) => {
        if (!Array.isArray(arr1) || !Array.isArray(arr2)) {
            return false;
        }
        if (arr1.length !== arr2.length) {
            return false;
        }
        return arr1.every(item => arr2.includes(item)) && arr2.every(item => arr1.includes(item));
    };
    
    connectedCallback() {
        const arraysAreSame = this.areArraysEqual(this.contractIds, this.tempIds);
        if( !this.pnpOneData  || !arraysAreSame){
            this.loadSubscriptionData();
        }else{
            this.subscriptionData = JSON.parse(JSON.stringify(this.pnpOneData));
            this.togglePnP = this.pnpToggleData;
            const isProProduct =  this.subscriptionData.some(wrapper => 
            wrapper.licenseType === 'Pro' || wrapper.subscriptionWrappers.some(detail => detail.licenseType === 'Pro')
        );
        }
        this.dispatchEvent(new CustomEvent('currentpnpscreen', {
            detail: {
                tempIds: this.contractIds,
            }
        }));
    }

    renderedCallback() {
        const nextPnPSubscriptionDataEvent = new CustomEvent('nextpnpsubscriptiondatachange', {
            detail: {
                subscriptionData : this.subscriptionData
            },
            bubbles: true,
        });
        this.dispatchEvent(nextPnPSubscriptionDataEvent);

        const validationEvent = new CustomEvent('productfieldsvalidationchange', {
            detail: {
                subscriptionData: JSON.parse(JSON.stringify(this.subscriptionData)),
                hasUnselectedProducts: this.hasUnselectedProducts()
            },
            bubbles: true,
        });
        this.dispatchEvent(validationEvent);
        if( this.subscriptionData !== undefined){
            const isProProduct = this.subscriptionData.some(wrapper => 
                wrapper.licenseType === 'Pro' || wrapper.subscriptionWrappers.some(detail => detail.licenseType === 'Pro')
            );
            this.hasProProduct = isProProduct;
        }
    }
    hasUnselectedProducts() {
        if (!this.togglePnP) return false;
        return this.subscriptionData.some(data => 
            !data.pnpOneProductDetails.selectedProductId || 
            data.pnpOneProductDetails.selectedProductId === data.productId ||
            data.pnpOneProductDetails.selectedProductName === 'Select License Upgrade Product'
        );
    }

    async loadSubscriptionData() {
        this.isLoading = true;
        try {
            const result = await getSubscriptionsByProductAndAddress({
                contractIdList: this.contractIds,
                priceBookId: this.pricebookId,
                accountPilotCustomer: this.accountPilotCustomer,
                togglePnP: this.togglePnP
            });
            console.log('TTMM result new', JSON.stringify(result));
            this.subscriptionData = this.processSubscriptionData(result);
        } catch (error) {
            this.error = error;
        } finally {
            this.isLoading = false;
        }
    }
    processSubscriptionData(data) {
        if (!data || !Array.isArray(data)) {
            return [];
        }
        const processedData = data.map((parent, index) => {
            let availableProducts = parent.availableProducts || [];
            if (parent.productCode) {
                let transformedProductCode;
                if (parent.productCode.includes('-PREM-')) {
                    transformedProductCode = parent.productCode.replace('-PREM-', '-PREMIER-');
                    availableProducts = availableProducts.filter(product => 
                        product.ProductCode !== transformedProductCode
                    );
                } else if (parent.productCode.includes('-PREMIER-')) {
                    transformedProductCode = parent.productCode.replace('-PREMIER-', '-PREM-');
                    availableProducts = availableProducts.filter(product => 
                        product.ProductCode !== transformedProductCode
                    );
                }
            }
            const singleProductInProductOptionsBoolean = availableProducts.length === 1;
            const singleProduct = singleProductInProductOptionsBoolean ? availableProducts[0] : null;
            return {
                ...parent,
                productLink: `${this.baseURL}/${parent.productId}`,
                isExpanded: true,
                pnpOneProductDetails: {
                    togglePnp: this.togglePnP,
                    selectedProductId: singleProductInProductOptionsBoolean ? singleProduct.Id : '',
                    selectedProductName: singleProductInProductOptionsBoolean ? singleProduct.Name : '',
                    selectedProductCode: singleProductInProductOptionsBoolean ? `SKU: ${singleProduct.ProductCode}` : '',
                    selectedProductUrl: singleProductInProductOptionsBoolean ? `${this.baseURL}/${singleProduct.Id}` : ''
                },
                rowNumber: index + 1,
                expandSymbol: 'utility:dash',
                isSelectedForReplacement: false,
                disableInputControls: true,
                replacementQuantity: '',
                availableProducts: availableProducts,
                availableProductOptions: this.convertProductsToOptions(availableProducts),
                singleProductInProductOptionsBoolean: singleProductInProductOptionsBoolean,
                subscriptionWrappers: (parent.subscriptionWrappers || []).map(child => {
                    const childAvailableProducts = child.availableProducts || []; 
                    const childSingleProductInProductOptionsBoolean = childAvailableProducts.length === 1;
                    const childSingleProduct = childSingleProductInProductOptionsBoolean ? childAvailableProducts[0] : null;
                
                    return {
                        ...child,
                        pnpOneProductDetails: {
                            togglePnp: this.togglePnP,
                            selectedProductId: childSingleProductInProductOptionsBoolean ? childSingleProduct.Id : '',
                            selectedProductName: childSingleProductInProductOptionsBoolean ? childSingleProduct.Name : '',
                            selectedProductCode: childSingleProductInProductOptionsBoolean ? childSingleProduct.ProductCode : '',
                            selectedProductUrl: childSingleProductInProductOptionsBoolean ? `${this.baseURL}/${childSingleProduct.Id}` : ''
                        },
                        uniqueId: child.productId + '-' + child.shippingAddressId,
                        isSelectedForReplacement: false,
                        isProductNotReplaceable: true,
                        disableInputControls: true,
                        shippingAddressLink: `${this.baseURL}/${child.shippingAddressId}`,
                        replacementQuantity: '',
                        availableProducts: childAvailableProducts,
                        availableProductOptions: this.convertProductsToOptions(childAvailableProducts),
                        singleProductInProductOptionsBoolean: childSingleProductInProductOptionsBoolean
                    };
                })
            };
        });
        const pnpscreenOneDisptach = new CustomEvent('pnponedatadispatchone', {
            detail: {
                pnpOneData : processedData,
                toggle: this.togglePnP,
            },
            
        });
        this.dispatchEvent(pnpscreenOneDisptach);
        return processedData;
    }

    convertProductsToOptions(products) {
        const productsArray = products || [];
        if (!Array.isArray(productsArray)) {
            return [];
        }
        const options = productsArray
            .filter(product => product && product.Name && product.Id)
            .map(product => ({
                label: product.Name,
                value: product.Id
            }));
        return options;
    }
    notifyProductDataChange() {
        this.dispatchEvent(new CustomEvent('productdatachange', {
            detail: this.products,
            bubbles: true,
            composed: true
        }));
    }
    async handleLicenseUpgradeChange(event) {
        try {
            this.isPlatformUpgrade = event.target.checked;
            this.togglePnP = event.target.checked;
            this.validationError = '';
            if (this.togglePnP) {
                this.subscriptionData = this.subscriptionData.map(data => {
                    return {
                        ...data,
                        pnpOneProductDetails: {
                            selectedProductId: data.singleProductInProductOptionsBoolean ? data.availableProducts[0].Id : data.productId,
                            selectedProductName: data.singleProductInProductOptionsBoolean ? data.availableProducts[0].Name : 'Select License Upgrade Product',
                            selectedProductUrl: data.singleProductInProductOptionsBoolean ? `${this.baseURL}/${data.availableProducts[0].Id}` : `${this.baseURL}/${data.productId}`,
                            selectedProductCode: data.singleProductInProductOptionsBoolean ? `SKU: ${data.availableProducts[0].ProductCode}` : data.productCode
                        },
                        subscriptionWrappers: data.subscriptionWrappers.map(wrapper => {
                            return {
                                ...wrapper,
                                pnpOneProductDetails: {
                                    selectedProductId: wrapper.singleProductInProductOptionsBoolean ? wrapper.availableProducts[0].Id : data.productId,
                                    selectedProductName: wrapper.singleProductInProductOptionsBoolean ? wrapper.availableProducts[0].Name : wrapper.productName,
                                    selectedProductUrl: wrapper.singleProductInProductOptionsBoolean ? `${this.baseURL}/${wrapper.availableProducts[0].Id}` : `${this.baseURL}/${data.productId}`,
                                    selectedProductCode: wrapper.singleProductInProductOptionsBoolean ? wrapper.availableProducts[0].ProductCode : data.productCode
                                }
                            };
                        })
                    };
                });
            }
            await this.loadSubscriptionData();

            const pnpscreenOneToggleDisptach = new CustomEvent('pnponetoggledispatch', {
                detail: {
                    pnpOneData: this.subscriptionData,
                    toggle: event.target.checked,
                },
                bubbles: true,
            });
            this.dispatchEvent(pnpscreenOneToggleDisptach);

            this.products = this.products.map(product => ({
                ...product,
                isDisabled: !this.isPlatformUpgrade || !product.selected
            }));
            
            this.dispatchEvent(new CustomEvent('Licenseupgradechange', {
                detail: this.isPlatformUpgrade,
                bubbles: true,
                composed: true
            }));
            // manglesh code -
            
        } catch (error) {
            console.log('Error',error.message);
            
        }
    }

    handleProductSelect(event) {
        try {
            const selectedProductId = event.target.value;
            const selectedOption = event.target.options.find(opt => opt.value === event.detail.value).label;
            const rowIndex = event.target.dataset.index;
            if (this.togglePnP && !selectedProductId) {
                this.validationError = 'Product selection is mandatory when Platform entitlements upgrade is enabled';
                return;
            }
            let availableProductsdata = JSON.parse(JSON.stringify(this.subscriptionData[rowIndex].availableProducts));
            const selectedProductCode = availableProductsdata.find(product => product.Id === selectedProductId)?.ProductCode;
            this.validationError = '';
            this.subscriptionData[rowIndex].pnpOneProductDetails.selectedProductId = selectedProductId;
            this.subscriptionData[rowIndex].pnpOneProductDetails.selectedProductName = selectedOption;
            this.subscriptionData[rowIndex].pnpOneProductDetails.selectedProductUrl = `${this.baseURL}/${selectedProductId}`;
            this.subscriptionData[rowIndex].pnpOneProductDetails.selectedProductCode = `SKU: ${selectedProductCode}`;

            this.subscriptionData[rowIndex].subscriptionWrappers.forEach(wrapper => {
                wrapper.pnpOneProductDetails.selectedProductId = selectedProductId;
                wrapper.pnpOneProductDetails.selectedProductName = selectedOption;
                wrapper.pnpOneProductDetails.selectedProductUrl = `${this.baseURL}/${selectedProductId}`;
                wrapper.pnpOneProductDetails.selectedProductCode = selectedProductCode ;
            });

            // persist logic add - manglesh 
            const pnpscreenOneDisptach = new CustomEvent('pnponedatadispatchone', {
                detail: {
                    pnpOneData : this.subscriptionData,
                    toggle: this.togglePnP,
                },
                
            });
            this.dispatchEvent(pnpscreenOneDisptach);
            const nextPnPSubscriptionDataEvent = new CustomEvent('nextpnpsubscriptiondatachange', {
                detail: {
                    subscriptionData : this.subscriptionData
                },
                bubbles: true,
            });
            this.dispatchEvent(nextPnPSubscriptionDataEvent);
        } catch (error) {
            console.log('Error', error.message , error);
        }
    }

    
}