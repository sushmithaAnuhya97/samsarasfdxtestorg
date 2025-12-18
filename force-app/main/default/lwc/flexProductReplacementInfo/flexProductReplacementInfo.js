import { LightningElement, track, api } from 'lwc';
import getSubscriptionsByProductAndAddress from '@salesforce/apex/FlexContractConsolidation.getSubscriptionsByProductAndAddress';
export default class FlexProductReplacementInfo extends LightningElement {
    @track error;
    @track hasErrorForQuantity;
    @track hasErrorForProduct;
    @track totalProducts;
    @track ineligibleToProductSelection; 
    @track expandSymbol;
    @track togglePnP = false;
    @track hasRendered = false;    
    @track selectAllChecked = false;
    @track hasProProduct = false;
    @api isLoadingPnpOne ;
    @api pnpTwoData;
    @api ineligibleBannerBoolean; 
    @api tempIds;
    @api ineligibleProductListFromWizard
    @api  pnpScreenOneSubscriptionData;
    @api accountPilotCustomer; 
    @api contractIds;
    @api pricebookId;
    @api subscriptionData;
    @api updatedSubscriptionData;
    @api cardTitle = 'Contract Subscriptions';
    @api showSelectionControls ;
    @api showReplacementControls ;
    @api ineligibleProductList;
    isLoading = false;
    baseURL =window.location.origin;

    // Getter for Hardware Upgrade tab label with count
    get hardwareUpgradeTabLabel() {
        const count = this.subscriptionData ? this.subscriptionData.length : 0;
        // For legacy accounts (AccountPilotCustomer is false), show "Available for Upgrade"
        if (!this.accountPilotCustomer) {
            return `Available for Upgrade (${count})`;
        }
        return `Hardware Upgrade (${count})`;
    }
    
    // Getter for Ineligible Products tab label with count
    get ineligibleProductsTabLabel() {
        const count = this.ineligibleProductList ? this.ineligibleProductList.length : 0;
        return `Ineligible for Upgrade (${count})`;
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
        if (this.accountPilotCustomer) {
            const arraysAreSame = this.areArraysEqual(this.contractIds, this.tempIds);
            if (!arraysAreSame) {
                this.tempIds = this.contractIds;
                this.loadSubscriptionData();
            } else {
                const productMap = new Map();
                let temp = [];
                if (this.pnpTwoData) {
                    // temp = [...this.pnpTwoData];
                    temp = JSON.parse(JSON.stringify(this.pnpTwoData));
                } else {
                    // temp = [...this.pnpScreenOneSubscriptionData];
                    temp = JSON.parse(JSON.stringify(this.pnpScreenOneSubscriptionData));

                }
                const isProProduct = temp.some(wrapper =>
                    wrapper.licenseType === 'Pro' || wrapper.subscriptionWrappers.some(detail => detail.licenseType === 'Pro')
                );
                this.dispatchDataChangeEvents(isProProduct);
                temp.forEach(product => {
                    const productId = product.pnpOneProductDetails.selectedProductId;
                    if (productMap.has(productId)) {
                        const existingProduct = productMap.get(productId);
                        const mergedWrappers = [...existingProduct.subscriptionWrappers];
                        product.subscriptionWrappers.forEach(wrapper => {
                            const existingWrapperIndex = mergedWrappers.findIndex(
                                w => w.shippingAddressId === wrapper.shippingAddressId
                            );
                            if (existingWrapperIndex !== -1) {
                                mergedWrappers[existingWrapperIndex] = {
                                    ...mergedWrappers[existingWrapperIndex],
                                    quantity: mergedWrappers[existingWrapperIndex].quantity + wrapper.quantity
                                };
                            } else {
                                mergedWrappers.push({ ...wrapper });
                            }
                        });
                        const newTotalQuantity = mergedWrappers.reduce((sum, wrapper) => sum + wrapper.quantity, 0);
                        productMap.set(productId, {
                            ...existingProduct,
                            subscriptionWrappers: mergedWrappers,
                            totalQuantity: newTotalQuantity
                        });
                    } else {
                        const totalQuantity = product.subscriptionWrappers.reduce((sum, wrapper) => sum + wrapper.quantity, 0);
                        productMap.set(productId, {
                            ...product,
                            totalQuantity: totalQuantity
                        });
                    }
                });
                let mergedProducts = Array.from(productMap.values());
                
                this.pnpScreenOneSubscriptionData = [...temp];
                const ineleigbleProductsArray = [];
                let idx = 1;
                // this.subscriptionData = mergedProducts.filter(product => {
                this.subscriptionData = temp.filter(product => {

                    let data = JSON.parse(JSON.stringify(product));
                    if (!data.availableProducts || data.availableProducts.length === 0 ||
                        (data.availableProducts.length === 1 && data.availableProducts[0].Id === data.subscriptionWrappers[0].pnpOneProductDetails.selectedProductId)) {
                        data.productId = data.subscriptionWrappers[0].pnpOneProductDetails.selectedProductId?data.subscriptionWrappers[0].pnpOneProductDetails.selectedProductId :data.availableProducts[0].Id  ;
                        data.productName = data.subscriptionWrappers[0].pnpOneProductDetails.selectedProductName?data.subscriptionWrappers[0].pnpOneProductDetails.selectedProductName:data.availableProducts[0].Name;
                        data.rowNumber = idx;
                        idx += 1;
                        ineleigbleProductsArray.push(data);
                        return false;
                    }
                    return true;
                });
                let idx2 = 1;
                this.subscriptionData = this.subscriptionData.map((product, index) => {
                    product.rowNumber = idx2;
                    idx2 += 1;
                    return product;
                });
                this.ineligibleProductList = ineleigbleProductsArray.length === 0 ? this.ineligibleProductListFromWizard : [...ineleigbleProductsArray];
                // this.totalProducts = mergedProducts.length;
                this.totalProducts = temp.length;

                this.ineligibleToProductSelection = this.ineligibleProductList && this.ineligibleProductList.length === this.totalProducts;
            }
        } else {
            if (this.contractIds != undefined && JSON.stringify(this.tempIds) != JSON.stringify(this.contractIds)) {
                this.tempIds = this.contractIds;
                this.loadSubscriptionData();
            }
        }
        this.dispatchEvent(new CustomEvent('currentscreen', {
            detail: {
                tempIds: this.contractIds,
                ineligibleToProductSelection: this.ineligibleToProductSelection
            }
        }));
        if (this.ineligibleBannerBoolean !== undefined) {
            this.ineligibleToProductSelection = this.ineligibleBannerBoolean;
        }
        if( this.subscriptionData !== undefined && this.subscriptionData.length === 0 ){
            this.ineligibleToProductSelection  = true;
        }
    }
    
    async loadSubscriptionData() {
        this.isLoading = true;
        try {
            const result = await getSubscriptionsByProductAndAddress({
                contractIdList: this.contractIds,
                priceBookId: this.pricebookId,
                accountPilotCustomer: this.accountPilotCustomer,
                togglePnP: this.togglePnP,
                productIdsFromPnpOne : []
            });
            console.log(' flexProductReplacementInfo loadSubscriptionData result', JSON.stringify(result));
            this.subscriptionData = this.processSubscriptionData(result);
            this.notifySubscriptionDataChange();
            if( result !== undefined){
                const isProProduct = result.some(wrapper => 
                    wrapper.licenseType === 'Pro' || wrapper.subscriptionWrappers.some(detail => detail.licenseType === 'Pro')
                );
                this.dispatchDataChangeEvents(isProProduct);
            }
        } catch (error) {
            console.error('Error loading subscription data:', error);
            this.error = error;
        } finally {
            this.isLoading = false;
        }
    }
    notifySubscriptionDataChange() {
        this.dispatchEvent(new CustomEvent('subscriptiondatachange', {
            detail: this.subscriptionData,
            bubbles: true,
            composed: true
        }));
    }
    processSubscriptionData(data) {
        let tempArray = [];
        let ineleigbleProductsArray = [];
        let idx = 1;
        this.totalProducts = data.length;
        data.map((parent) => {
            if (!parent.availableProducts || 
                parent.availableProducts.length === 0 ||
                (parent.availableProducts.length === 1 && parent.availableProducts[0].Id === parent.productId)) {  // If only one product in dropdown and it's the same product
                parent.productLink = `${this.baseURL}/${parent.productId}`;
                parent.rowNumber = idx;
                idx++;
                ineleigbleProductsArray.push(parent);
                this.ineligibleProductList = [...ineleigbleProductsArray];
            } else {
                if (parent.availableProducts.length === 1) {
                    let selectedProductCode = "";
                    let selectedProductCodeData = JSON.parse(JSON.stringify(parent.availableProducts[0]));     
                    if( selectedProductCodeData.Flex_Default_Hardware__r){
                        selectedProductCode = selectedProductCodeData.Flex_Default_Hardware__r.ProductCode;
                    }else{
                        selectedProductCode = 'None';
                    }
                    let eligibleProducts = {
                        ...parent,
                        productLink: `${this.baseURL}/${parent.productId}`,
                        isExpanded: true,
                        rowNumber: idx,
                        expandSymbol: 'utility:dash',
                        isSelectedForReplacement: false,
                        disableInputControls: true,
                        replacementQuantity: '',
                        pnpOneProductDetails:{selectedProductUrl : ''},
                        availableProductOptions: this.convertProductsToOptions(parent.availableProducts),
                        singleProductInProductOptionsBoolean: parent.availableProducts.length === 1,
                        subscriptionWrappers: parent.subscriptionWrappers.map(child => ({
                            ...child,
                            uniqueId: child.productId + '-' + child.shippingAddressId,
                            isSelectedForReplacement: false,
                            selectedProductId: '',
                            selectedProductName: '',
                            selectedProductCode: selectedProductCode,
                            replaceProduct: false,
                            quantityToReplace: '',
                            isProductNotReplaceable: true,
                            disableInputControls: true,
                            shippingAddressLink: `${this.baseURL}/${child.shippingAddressId}`,
                            replacementQuantity: '',
                            remainingQuantity: null,
                            pnpOneProductDetails:{selectedProductUrl : ''},
                            availableProductOptions: this.convertProductsToOptions(child.availableProducts),
                            singleProductInProductOptionsBoolean: child.availableProducts.length === 1,
                            ineligibleProduct: child.availableProducts ? (child.availableProducts.length === 1 ? child.availableProducts[0] : '') : ''
                        }))
                    };
                    tempArray.push(eligibleProducts);
                    idx++;
                }else{
                    let eligibleProducts = {
                        ...parent,
                        productLink: `${this.baseURL}/${parent.productId}`,
                        isExpanded: true,
                        rowNumber: idx,
                        expandSymbol: 'utility:dash',
                        isSelectedForReplacement: false,
                        disableInputControls: true,
                        replacementQuantity: '',
                        availableProductOptions: this.convertProductsToOptions(parent.availableProducts),
                        singleProductInProductOptionsBoolean: parent.availableProducts.length === 1,
                        subscriptionWrappers: parent.subscriptionWrappers.map(child => ({
                            ...child,
                            uniqueId: child.productId + '-' + child.shippingAddressId,
                            isSelectedForReplacement: false,
                            selectedProductId: '',
                            selectedProductName: '',
                            selectedProductCode: '',
                            replaceProduct: false,
                            quantityToReplace: '',
                            isProductNotReplaceable: true,
                            disableInputControls: true,
                            shippingAddressLink: `${this.baseURL}/${child.shippingAddressId}`,
                            replacementQuantity: '',
                            remainingQuantity: null,
                            availableProductOptions: this.convertProductsToOptions(child.availableProducts),
                            singleProductInProductOptionsBoolean: child.availableProducts.length === 1,
                            ineligibleProduct: child.availableProducts ? (child.availableProducts.length === 1 ? child.availableProducts[0] :   '') : ''
                        }))
                    };
                    tempArray.push(eligibleProducts);
                    idx++;
                }
            }
        });
        this.ineligibleToProductSelection = this.ineligibleProductList ? this.ineligibleProductList?.length === this.totalProducts : false;
        this.dispatchEvent(new CustomEvent('bannerchange', {
            detail: {
                tempIds: this.contractIds,
                ineligibleToProductSelection: this.ineligibleToProductSelection
            }
        }));
        return tempArray;
    }
    convertProductsToOptions(products) {
        if(!products) {
            return [];
        }
        return products.map(product => ({
            label: product.Name,
            value: product.Id
        }));
    }
   
    renderedCallback() {
        if (!this.hasRendered && this.subscriptionData) {
            this.hasRendered = true;
           const nextButtonValidationEvent = new CustomEvent('productfieldsvalidationchange', {
            detail: {
                subscriptionData: JSON.parse(JSON.stringify(this.subscriptionData)),
            },
            bubbles: true,
        });
        this.dispatchEvent(nextButtonValidationEvent);
        }
        if( this.subscriptionData !== undefined){
            const isProProduct = this.subscriptionData.some(wrapper => 
                wrapper.licenseType === 'Pro' || wrapper.subscriptionWrappers.some(detail => detail.licenseType === 'Pro')
            );
            this.hasProProduct = isProProduct;
        }
           
    }
    handleShipToProductSelect(event) {
        try {
            const selectedProductId = event.detail.value;       
            const rowIndex = parseInt(event.target.dataset.index);
            const detailIndex = parseInt(event.target.dataset.detailIndex);
            const input = event.target;                                
            this.subscriptionData = [...this.subscriptionData];
            this.subscriptionData[rowIndex] = {
                ...this.subscriptionData[rowIndex],
                subscriptionWrappers: [...this.subscriptionData[rowIndex].subscriptionWrappers]
            };
            this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex] = {
                ...this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex],
                selectedProductId: selectedProductId
            };
            let selectedProductCodeData = JSON.parse(JSON.stringify(this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].availableProducts.find((option)=>{                    
                return option.Id === selectedProductId;
            }))) ;             
            if( selectedProductCodeData.Flex_Default_Hardware__r){
                this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].selectedProductCode = selectedProductCodeData.Flex_Default_Hardware__r.ProductCode;
                this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].selectedProductHardwareId = selectedProductCodeData.Flex_Default_Hardware__r.Id;
            }else{
                this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].selectedProductCode = 'None';
                this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].selectedProductHardwareId = null;
            }    
            this.updateDetailTooltip(rowIndex, detailIndex, selectedProductCodeData);    
            const selectedOption = this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].availableProductOptions.find(
                option => option.value === selectedProductId
            );    
            this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].selectedProductName = selectedOption.label;    
            if (!selectedProductId) {
                input.setCustomValidity('Please select a product');
                this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].validationErrorForProduct = true;
                this.subscriptionData = [...this.subscriptionData];
                this.subscriptionData[rowIndex] = {
                    ...this.subscriptionData[rowIndex],
                    subscriptionWrappers: [...this.subscriptionData[rowIndex].subscriptionWrappers]
                };
                this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex] = {
                    ...this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex],
                    errorClassForProduct: 'custom-combobox error-class'
                };
            } else {
                input.setCustomValidity('');
                this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].validationErrorForProduct = false; 
                this.subscriptionData = [...this.subscriptionData];
                this.subscriptionData[rowIndex] = {
                    ...this.subscriptionData[rowIndex],
                    subscriptionWrappers: [...this.subscriptionData[rowIndex].subscriptionWrappers]
                };
                this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex] = {
                    ...this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex],
                    errorClassForProduct: 'custom-combobox '
                };
            }
            input.reportValidity();
            const pnpscreenTwoForSelectAllDisptach = new CustomEvent('pnponedatafromselectalldispatch', {
                detail: {
                    pnpTwoData : this.subscriptionData
                },
                bubbles: true,
            });
            this.dispatchEvent(pnpscreenTwoForSelectAllDisptach);
        } catch (error) {
            console.error('Error in handleShipToProductSelect:', error);
        }
    }
   
    handleProductSelectAll(event){
        const selectedProductId = event.target.value;
        const selectedOption = event.target.options.find(opt => opt.value === event.detail.value).label;
        const rowIndex = event.target.dataset.index;
        const input = event.target;
        let selectedProductCodeData = JSON.parse(JSON.stringify(this.subscriptionData[rowIndex].availableProducts.find((option)=>{
            return option.Id === selectedProductId;
        })));
        this.subscriptionData = [...this.subscriptionData];
        this.subscriptionData[rowIndex] = {
            ...this.subscriptionData[rowIndex],
            selectedProductId: selectedProductId,
            selectedProductName: selectedOption,           
            validationErrorForProduct: !selectedProductId,
            errorClassForProduct: selectedProductId ? 'custom-combobox' : 'custom-combobox error-class'
        };
        if( selectedProductCodeData.Flex_Default_Hardware__r){
            this.subscriptionData[rowIndex] = {
                ...this.subscriptionData[rowIndex],
                selectedProductCode: selectedProductCodeData.Flex_Default_Hardware__r.ProductCode,
                selectedProductHardwareId: selectedProductCodeData.Flex_Default_Hardware__r.Id
            } 
        }else{
            this.subscriptionData[rowIndex] = {
                ...this.subscriptionData[rowIndex],
                selectedProductCode: 'None',
                selectedProductHardwareId : null
            } 
        }
        this.updateTooltip(rowIndex, selectedProductCodeData);
        const pnpscreenTwoForSelectAllDisptach = new CustomEvent('pnponedatafromselectalldispatch', {
            detail: {
                pnpTwoData : this.subscriptionData
            },
            bubbles: true,
        });
        this.dispatchEvent(pnpscreenTwoForSelectAllDisptach);
        if(!selectedProductId ){
            input.setCustomValidity('Please select a product');
        }else{
            input.setCustomValidity('');
        }
        input.reportValidity();
    }
    
    handleSelectAllCheckbox(event) {
        event.stopPropagation();
        const rowIndex = parseInt(event.target.dataset.index);
        const checked = event.target.checked;
        this.subscriptionData = this.subscriptionData.map((wrapper, index) => {
            if (index === rowIndex) {
                let selectedProductCode = "";
                let selectedProductHardwareId = "";
                let selectedProductCodeData = JSON.parse(JSON.stringify(wrapper.availableProducts[0]));
                if (selectedProductCodeData.Flex_Default_Hardware__r) {
                    selectedProductCode = selectedProductCodeData.Flex_Default_Hardware__r.ProductCode;
                    selectedProductHardwareId = selectedProductCodeData.Flex_Default_Hardware__r.Id;
                } else {
                    selectedProductCode = 'None';
                }
                const singleProduct = wrapper.availableProductOptions && wrapper.availableProductOptions.length === 1
                    ? wrapper.availableProductOptions[0]
                    : null;
                let selectedProductCodeForProduct = '';
                if (checked && singleProduct && wrapper.availableProducts && wrapper.availableProducts.length > 0) {
                    const productData = wrapper.availableProducts[0];
                    if (productData.ProductCode) {
                        selectedProductCodeForProduct = `SKU: ${productData.ProductCode}`;
                    } else if (productData.Flex_Default_Hardware__r && productData.Flex_Default_Hardware__r.ProductCode) {
                        selectedProductCodeForProduct = `SKU: ${productData.Flex_Default_Hardware__r.ProductCode}`;
                    } else {
                        selectedProductCodeForProduct = 'SKU: None';
                    }
                }
                return {
                    ...wrapper,
                    replaceProduct: checked,
                    isProductNotReplaceable: checked,
                    selectedProductId: checked && singleProduct ? singleProduct.value : '',
                    selectedProductName: checked && singleProduct ? singleProduct.label : '',
                    selectedProductCode: checked && singleProduct ? selectedProductCode : 'None',
                    selectedProductHardwareId : checked && singleProduct ? selectedProductHardwareId : 'None',
                    selectedProductCodeForProduct: selectedProductCodeForProduct,
                    subscriptionWrappers: wrapper.subscriptionWrappers.map(detail => ({
                        ...detail,
                        replaceProduct: false,
                        isProductNotReplaceable: true,
                        quantityToReplace: checked ? wrapper.totalQuantity : '',
                        replacementProduct: detail.replacementProduct || '',
                        validationError: false,
                        validationErrorBoolean: false,
                        errorClass: 'input-style-quantity',
                        validationErrorForProduct: false,
                        errorClassForProduct: 'custom-combobox',
                        selectedProductName: checked ? wrapper.singleProductInProductOptionsBoolean ? wrapper.availableProducts[0].Name : '' : '',
                        selectedProductCode: checked ? wrapper.singleProductInProductOptionsBoolean ? selectedProductCode : '' : '',
                        selectedProductId: '',
                        selectedProductCodeForProduct: '' // Clear tooltip - ensure no product code shows for partial select rows
                    }))
                };
            }
            return wrapper;
        });
        const pnpscreenTwoForSelectAllDisptach = new CustomEvent('pnponedatafromselectalldispatch', {
            detail: {
                pnpTwoData : this.subscriptionData
            },
            bubbles: true,
        });
        this.dispatchEvent(pnpscreenTwoForSelectAllDisptach);
    
    }
    handlePartialUpgradeCheckbox(event) { 
        try {
            event.stopPropagation();
            const rowIndex = parseInt(event.target.dataset.index);
            const detailIndex = parseInt(event.target.dataset.detailIndex);
            const checked = event.target.checked;            
            if (!checked) {
                const combobox = this.template.querySelector(`lightning-combobox[data-index="${rowIndex}"][data-detail-index="${detailIndex}"]`);
                if (combobox) {
                    combobox.value = '';
                }
            }
            this.subscriptionData = JSON.parse(JSON.stringify(this.subscriptionData));    
            if (this.subscriptionData[rowIndex] && this.subscriptionData[rowIndex].subscriptionWrappers) {
                const wrapper = this.subscriptionData[rowIndex];
                const detail = wrapper.subscriptionWrappers[detailIndex];        
                if (detail) {
                    let selectedProductCode = "None";
                    let selectedProductHardwareId = "None";
                    let selectedProductCodeForProduct = '';            
                    const hasSingleProduct = detail.availableProducts && detail.availableProducts.length === 1;    
                    if (hasSingleProduct) {
                        const selectedProductCodeData = detail.availableProducts[0];    
                        if (selectedProductCodeData.Flex_Default_Hardware__r) {
                            selectedProductCode = selectedProductCodeData.Flex_Default_Hardware__r.ProductCode;
                            selectedProductHardwareId = selectedProductCodeData.Flex_Default_Hardware__r.Id;
                        }        
                        if (checked) {
                            if (selectedProductCodeData.ProductCode) {
                                selectedProductCodeForProduct = `SKU: ${selectedProductCodeData.ProductCode}`;
                            } else if (selectedProductCodeData.Flex_Default_Hardware__r && selectedProductCodeData.Flex_Default_Hardware__r.ProductCode) {
                                selectedProductCodeForProduct = `SKU: ${selectedProductCodeData.Flex_Default_Hardware__r.ProductCode}`;
                            } else {
                                selectedProductCodeForProduct = 'SKU: None';
                            }
                        }
                    }    
                    wrapper.subscriptionWrappers[detailIndex] = {
                        ...detail,
                        replaceProduct: checked,
                        isProductNotReplaceable: !checked,
                        quantityToReplace: checked ? detail.quantity : '',
                        validationError: false,
                        validationErrorBoolean: false,
                        errorClass: 'input-style-quantity',
                        validationErrorForProduct: false,
                        errorClassForProduct: 'select-style',
                        selectedProductName: checked && hasSingleProduct ? detail.availableProducts[0].Name : '',
                        selectedProductCode: checked && hasSingleProduct ? selectedProductCode : 'None',
                        selectedProductHardwareId: checked && hasSingleProduct ? selectedProductHardwareId : 'None',
                        selectedProductId: checked && hasSingleProduct ? detail.availableProducts[0].Id : '',
                        selectedProductCodeForProduct: selectedProductCodeForProduct
                    };
                    if (checked && hasSingleProduct && detail.availableProducts && detail.availableProducts.length > 0) {
                        this.updateDetailTooltip(rowIndex, detailIndex, detail.availableProducts[0]);
                    }
                }
            }
        } catch (error) {
            console.error('Error in handlePartialUpgradeCheckbox:', error);
        }
        const pnpscreenTwoForSelectAllDisptach = new CustomEvent('pnponedatafromselectalldispatch', {
            detail: {
                pnpTwoData: this.subscriptionData
            },
            bubbles: true,
        });
        this.dispatchEvent(pnpscreenTwoForSelectAllDisptach);
    }

    handleQuantityChange(event){
        const rowIndex = parseInt(event.target.dataset.index);
        const detailIndex = parseInt(event.target.dataset.detailIndex);
        const newQuantity = event.target.value;
        this.subscriptionData = this.subscriptionData.map((wrapper, index) => {
            if (index === rowIndex) {
                return {
                    ...wrapper,
                    subscriptionWrappers: wrapper.subscriptionWrappers.map((detail, idx) => {
                        if (idx === detailIndex) {
                            return {
                                ...detail,
                                quantityToReplace: parseInt(newQuantity),
                                remainingQuantity: -(detail.quantity - parseInt(newQuantity)),
                                validationError:(newQuantity > detail.quantity || newQuantity <= 0 ) && newQuantity !== undefined  ? true:false,  
                                validationErrorBoolean : newQuantity > detail.quantity ? true : false, 
                                errorClass : (newQuantity > detail.quantity || newQuantity <= 0 ) && newQuantity !== undefined ? 'input-style-quantity error-class':'input-style-quantity'  
                            };
                        }
                        return detail;
                    })
                };
            }
            return wrapper;
        }); 
        const pnpscreenTwoForSelectAllDisptach = new CustomEvent('pnponedatafromselectalldispatch', {
            detail: {
                pnpTwoData : this.subscriptionData
            },
            bubbles: true,
        });
        this.dispatchEvent(pnpscreenTwoForSelectAllDisptach);
    }

    dispatchDataChangeEvents(param) {      
        const custEvent = new CustomEvent('proproductexist', {
            detail : param  
        });
        this.dispatchEvent(custEvent);
    }
    handleToggleExpand(event) {
        const productId = event.currentTarget.dataset.productid;
        this.subscriptionData = this.subscriptionData.map(item => {
            if (item.productId === productId) {
                return {
                    ...item,
                    isExpanded: !item.isExpanded
                };
            }
            return item;
        });
        this.notifySubscriptionDataChange();
    }

    handleSelectAllHeaderCheckbox(event) {
        try {
            const isChecked = event.target.checked;
            this.selectAllChecked = isChecked; 
            if (this.subscriptionData) {
                this.subscriptionData = this.subscriptionData.map(wrapper => {
                    let selectedProductCode = "None";
                    let selectedProductHardwareId = null;
                    let selectedProductCodeForProduct = '';
                    if (isChecked && wrapper.availableProducts && wrapper.availableProducts.length > 0) {
                        const productData = wrapper.availableProducts[0];
                        if (productData.Flex_Default_Hardware__r) {
                            selectedProductCode = productData.Flex_Default_Hardware__r.ProductCode;
                            selectedProductHardwareId = productData.Flex_Default_Hardware__r.Id;
                        }
                        if (isChecked && wrapper.singleProductInProductOptionsBoolean) {
                            if (productData.ProductCode) {
                                selectedProductCodeForProduct = `SKU: ${productData.ProductCode}`;
                            } else if (productData.Flex_Default_Hardware__r && productData.Flex_Default_Hardware__r.ProductCode) {
                                selectedProductCodeForProduct = `SKU: ${productData.Flex_Default_Hardware__r.ProductCode}`;
                            } else {
                                selectedProductCodeForProduct = 'SKU: None';
                            }
                        }
                    }
                    const singleProduct = wrapper.availableProductOptions && wrapper.availableProductOptions.length === 1? wrapper.availableProductOptions[0] : null;
                    const updatedWrapper = {
                        ...wrapper,
                        replaceProduct: isChecked,
                        selectedProductId: isChecked && singleProduct ? singleProduct.value : '',
                        selectedProductName: isChecked && singleProduct ? singleProduct.label : '',
                        selectedProductCode: isChecked ? selectedProductCode : 'None',
                        selectedProductHardwareId: isChecked ? selectedProductHardwareId : null,
                        selectedProductCodeForProduct: isChecked && wrapper.singleProductInProductOptionsBoolean && singleProduct ? selectedProductCodeForProduct : '',
                        errorClassForProduct: isChecked ? 'custom-combobox' : 'custom-combobox error-class'
                    };
                    if (wrapper.subscriptionWrappers) {
                        updatedWrapper.subscriptionWrappers = wrapper.subscriptionWrappers.map(detail => ({
                            ...detail,
                            replaceProduct: false, // Reset partial selections
                            isProductNotReplaceable: true, // Disable partial selection
                            quantityToReplace: '', // Clear quantity
                            validationError: false,
                            validationErrorBoolean: false,
                            errorClass: 'input-style-quantity',
                            validationErrorForProduct: false,
                            errorClassForProduct: 'custom-combobox',
                            selectedProductId: '', // Clear selected product
                            selectedProductName: '', // Clear selected product name
                            selectedProductCode: '', // Clear selected product code
                            selectedProductCodeForProduct: '' // Clear tooltip - ensure no product code shows for partial select rows
                        }));
                    }
                    return updatedWrapper;
                });
                this.notifySubscriptionDataChange();
            }
        } catch (error) {
            console.error('Error in handleSelectAllHeaderCheckbox:', error);
        }
        const pnpscreenTwoForSelectAllDisptach = new CustomEvent('pnponedatafromselectalldispatch', {
            detail: {
                pnpTwoData : this.subscriptionData
            },
            bubbles: true,
        });
        this.dispatchEvent(pnpscreenTwoForSelectAllDisptach);
    }

    getProductCodeForDisplay(productData) {    
        if (productData && productData.ProductCode) {
            return productData.ProductCode;
        } else if (productData && productData.Flex_Default_Hardware__r && productData.Flex_Default_Hardware__r.ProductCode) {
            return productData.Flex_Default_Hardware__r.ProductCode;
        } else {
            return 'None';
        }
    }

    updateTooltip(rowIndex, productData) {
        try {        
            if (productData && productData.ProductCode) {
                this.subscriptionData[rowIndex] = {
                    ...this.subscriptionData[rowIndex],
                    selectedProductCodeForProduct: `SKU: ${productData.ProductCode}`
                };
            } else if (this.subscriptionData[rowIndex].singleProductInProductOptionsBoolean && 
                      this.subscriptionData[rowIndex].availableProducts && 
                      this.subscriptionData[rowIndex].availableProducts.length > 0) {
                const singleProduct = this.subscriptionData[rowIndex].availableProducts[0];
                if (singleProduct.ProductCode) {
                    this.subscriptionData[rowIndex] = {
                        ...this.subscriptionData[rowIndex],
                        selectedProductCodeForProduct: `SKU: ${singleProduct.ProductCode}`
                    };
                }
            }
        } catch (error) {
            console.log('Error in updateTooltip:', error.message);
        }
    }

    updateDetailTooltip(rowIndex, detailIndex, productData) {
        if (productData && productData.ProductCode) {
            this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex] = {
                ...this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex],
                selectedProductCodeForProduct: `SKU: ${productData.ProductCode}`
            };
        } else if (this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].singleProductInProductOptionsBoolean && 
                  this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].availableProducts && 
                  this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].availableProducts.length > 0) {
            const singleProduct = this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex].availableProducts[0];
            if (singleProduct.ProductCode) {
                this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex] = {
                    ...this.subscriptionData[rowIndex].subscriptionWrappers[detailIndex],
                    selectedProductCodeForProduct: `SKU: ${singleProduct.ProductCode}`
                };
            }
        }
    }
}