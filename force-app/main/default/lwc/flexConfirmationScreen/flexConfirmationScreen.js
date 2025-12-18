import { LightningElement  ,api , track} from 'lwc';
export default class FlexConfirmationScreen extends LightningElement {
    @api finalConfirmationScreenJson;
    @api pnpBoolean ;
    @track processedConfirmationScreenData
    @track changedProductsData ; 
    @track noChangeProductData;
    @track noChangeTabCount ;
    @track changeTabCount ;
    @track changeTabLabel ='Product Upgrade Request' ;
    @track noChangeTabLabel ='No Change';
    @track allChangedProductsExpanded = true;
    @track allNoChangeProductsExpanded = false;
    @track isProductChangeRequestExpanded = true;
    baseURL =window.location.origin;

    connectedCallback(){
        this.processedConfirmationScreenData = this.formatConfirmationScreenDataMethod(this.finalConfirmationScreenJson);
        if( this.pnpBoolean){
            this.createChangedProductDataMethodForPnp();
        }else{
            this.createChangedProductDataMethodForLegacy();
        }
    }
    formatConfirmationScreenDataMethod(data) {
        let processedData = JSON.parse(JSON.stringify(data));        
        processedData.forEach((product) => {
            if( product.finalScreenDetails){
                product.finalScreenDetails.shipToAddresses.forEach((shipTo) => {
                    if( shipTo.upgradeProduct){
                        shipTo.upgradeProduct = {
                            ...shipTo.upgradeProduct,
                            defaultHardwareId: shipTo.upgradeProduct.defaultHardwareId === 'None'? null : shipTo.upgradeProduct.defaultHardwareId, 
                        };
                    }
                });
            }
        });
        return processedData ;
    }

    calculateTotalUpgradeQuantity(shippingAddressSummaries) {
        let totalUpgradeQty = 0;
        let totalQty = 0;        
        shippingAddressSummaries.forEach(shipTo => {
            const upgradeQtyParts = shipTo.upgradeQuantity.split(' / ');
            if (upgradeQtyParts.length === 2) {
                totalUpgradeQty += parseInt(upgradeQtyParts[0], 10);
                totalQty += parseInt(upgradeQtyParts[1], 10);
            }
        });
        return `${totalUpgradeQty} / ${totalQty}`;
    }

    createChangedProductDataMethodForPnp() {
        let platformUpgradeSummaryListForEachProduct = [];
        let noChangeProductsList = [];
        this.processedConfirmationScreenData.forEach((product, index) => {
            let shipToSummariesListForNoChange  = [];
            if( !product.ineligibleProductId){
                    if(product !== null){
                        const platformUpgradeDetails = product.platformUpgradeScreenDetails ? JSON.parse(JSON.stringify(product.platformUpgradeScreenDetails)) : null;
                        if (platformUpgradeDetails) {  
                            let platformUpgradeSummaryListForEachShipTo = [];
                            let  totalQty = 0;
                            if (product.finalScreenDetails) {
                                product.finalScreenDetails.shipToAddresses.forEach((shipTo , index2) => {
                                    totalQty += shipTo.quantity;
                                    if (shipTo.upgradeProduct) {
                                        if( shipTo.upgradeProduct.upgradeQuantity === shipTo.quantity){
                                            platformUpgradeSummaryListForEachShipTo.push({
                                                address: shipTo.addressName,
                                                addressLink: `${this.baseURL}/${shipTo.addressId}`,
                                                totalQuantity: shipTo.quantity,
                                                upgradeQuantity: `${shipTo.upgradeProduct.upgradeQuantity} / ${shipTo.quantity}` ,
                                                upgradeTo: shipTo.upgradeProduct.productName,
                                                uniqueId: `${shipTo.upgradeProduct.productId}-${shipTo.addressId}`,
                                                upgradeToLink: `${this.baseURL}/${shipTo.upgradeProduct.productId}`,
                                                defaultHardware: shipTo.upgradeProduct.productCode,
                                                defaultHardwareCodeURL : shipTo.upgradeProduct.defaultHardwareCodeURL,
                                                toggleLink :  shipTo.upgradeProduct.productCode !=='None' ? true : false
                                            });
                                        }
                                        else{
                                            platformUpgradeSummaryListForEachShipTo.push({
                                                address: shipTo.addressName,
                                                addressLink: `${this.baseURL}/${shipTo.addressId}`,
                                                totalQuantity: shipTo.quantity,
                                                upgradeQuantity: `${shipTo.upgradeProduct.upgradeQuantity} / ${shipTo.quantity}` ,
                                                upgradeTo: shipTo.upgradeProduct.productName,
                                                upgradeToLink: `${this.baseURL}/${shipTo.upgradeProduct.productId}`,
                                                defaultHardware: shipTo.upgradeProduct.productCode,
                                                uniqueId: `${shipTo.upgradeProduct.productId}-${shipTo.addressId}`,
                                                defaultHardwareCodeURL : shipTo.upgradeProduct.defaultHardwareCodeURL,
                                                toggleLink :  shipTo.upgradeProduct.productCode !=='None' ? true : false
                                            });
                                            const indexSearchInPlateformUpgrade  = product.platformUpgradeScreenDetails.findIndex((element)=>{
                                                return element.shippingAddressId === shipTo.addressId
                                            }) 
                                            
                                            if(!product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade]?.selectedUpgradeProduct){
                                                shipToSummariesListForNoChange.push({
                                                    addressName : shipTo.addressName,
                                                    addressId : shipTo.addressId,
                                                    addressLink: `${this.baseURL}/${shipTo.addressId}` ,
                                                    totalQuantity : shipTo.quantity,
                                                    remainingQuantity:  shipTo.upgradeProduct.remainingQuantity,
                                                    remainingQuantityText : `${shipTo.upgradeProduct.remainingQuantity} / ${shipTo.quantity}`
                                                })
                                            }else{
                                                platformUpgradeSummaryListForEachShipTo.push({
                                                    address: shipTo.addressName,
                                                    addressLink: `${this.baseURL}/${shipTo.addressId}`,
                                                    totalQuantity: shipTo.quantity,
                                                    upgradeQuantity: `${shipTo.upgradeProduct.remainingQuantity} / ${shipTo.quantity}` ,
                                                    upgradeTo: product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade]?.selectedUpgradeProduct?product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade].selectedUpgradeProduct.productName: product.originalProductName,
                                                    upgradeToLink: `${this.baseURL}/${product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade].selectedUpgradeProduct.productId ?product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade].selectedUpgradeProduct.productId:product.originalProductId}`,   
                                                    defaultHardware: 'None',
                                                    toggleLink : false,
                                                    uniqueId: `${product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade].selectedUpgradeProduct.productId}-${shipTo.addressId}`,
                                                    


                                                });
                                            }
                                        }
                                    }else{
                                        const indexSearchInPlateformUpgrade  = product.platformUpgradeScreenDetails.findIndex((element)=>{
                                            return element.shippingAddressId === shipTo.addressId
                                        }) 

                                       if( product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade]?.selectedUpgradeProduct){
                                        platformUpgradeSummaryListForEachShipTo.push({
                                            address: shipTo.addressName,
                                            addressLink: `${this.baseURL}/${shipTo.addressId}`,
                                            totalQuantity: shipTo.quantity,
                                            upgradeQuantity: `${shipTo.quantity} / ${shipTo.quantity}` ,
                                            upgradeTo: product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade].selectedUpgradeProduct?  product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade].selectedUpgradeProduct.productName : product.originalProductName,
                                            upgradeToLink: `${this.baseURL}/${product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade].selectedUpgradeProduct.productId ?product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade].selectedUpgradeProduct.productId:product.originalProductId}`,    
                                            defaultHardware: 'None',
                                            toggleLink : false,
                                            uniqueId: `${product.platformUpgradeScreenDetails[indexSearchInPlateformUpgrade].selectedUpgradeProduct.productId}-${shipTo.addressId}`,
                                                    
                                            
                                        })
                                       }else{
                                            shipToSummariesListForNoChange.push({
                                            addressName : shipTo.addressName,
                                            addressId : shipTo.addressId,
                                            addressLink: `${this.baseURL}/${shipTo.addressId}` ,
                                            totalQuantity : shipTo.quantity,
                                            remainingQuantity:  shipTo.quantity,
                                            remainingQuantityText : `${shipTo.quantity} / ${shipTo.quantity}`
                                            })
                                       }
                                    }
                                });
                                if(shipToSummariesListForNoChange.length > 0 ){
                                    noChangeProductsList.push({
                                        productId : product.originalProductId,
                                        productName : product.originalProductName,
                                        productLink: `${this.baseURL}/${product.originalProductId}`,
                                        totalQuantity : totalQty,
                                        totalRemainingQuantity : totalQty,
                                        shippingAddressSummaries :shipToSummariesListForNoChange
                                    })
                                }
                                if (platformUpgradeSummaryListForEachShipTo.length > 0) {
                                    // Calculate total upgrade quantity for this product
                                    const totalUpgradeQuantity = this.calculateTotalUpgradeQuantity(platformUpgradeSummaryListForEachShipTo);
                                    
                                    platformUpgradeSummaryListForEachProduct.push({
                                        productId: product.originalProductId,
                                        productName: product.originalProductName,
                                        productLink: `${this.baseURL}/${product.originalProductId}`,
                                        totalQuantity : totalQty,
                                        totalUpgradeQuantity: totalUpgradeQuantity,
                                        shippingAddressSummaries: platformUpgradeSummaryListForEachShipTo.reverse()
                                    });
                                }
                            }
                        }
                    }
            }else{
                let shippingAddressSummariesList  = [];
                product.screenTwoDetails.shipToAddresses.forEach((shipTo) =>{
                    shippingAddressSummariesList.push({
                            addressName : shipTo.addressName,
                            addressLink: `${this.baseURL}/${shipTo.addressId}`,
                            totalQuantity : shipTo.quantity,
                            remainingQuantityText : `${shipTo.quantity} / ${shipTo.quantity}`
                    })
                })
                
                noChangeProductsList.push({
                    productId : product.ineligibleProductId,
                    productName : product.ineligibleProductName,
                    totalQuantity : product.totalQuantity,
                    productLink: `${this.baseURL}/${product.originalProductId}`,
                    totalRemainingQuantityText :  `${product.totalQuantity} / ${product.totalQuantity} ` , 
                    shippingAddressSummaries :shippingAddressSummariesList
                })
            }
        });
        
        noChangeProductsList.forEach(product => {
            let totalRemaining = 0;
            let totalQty = 0;    
            product.shippingAddressSummaries.forEach(address => {
                const parts = address.remainingQuantityText.split(' / ');
                if (parts.length === 2) {
                    totalRemaining += parseInt(parts[0], 10);
                    totalQty += parseInt(parts[1], 10);
                }
            });
            product.totalRemainingQuantityText = `${totalRemaining} / ${totalQty}`;
        });
        
        platformUpgradeSummaryListForEachProduct = platformUpgradeSummaryListForEachProduct.map((product) => {
            return {
                expandSymbol : 'utility:dash',
                isExpanded : true,
                ...product
            };
        });
        noChangeProductsList = noChangeProductsList.map((product) => {
            return {
                isExpanded: false,
                ...product
            };
        });
        this.noChangeProductData = noChangeProductsList;
        this.changedProductsData = platformUpgradeSummaryListForEachProduct
        this.noChangeTabCount = noChangeProductsList.length;
        this.changeTabCount = platformUpgradeSummaryListForEachProduct.length;
        this.noChangeTabLabel = `No Change (${this.noChangeTabCount})`;
        this.changeTabLabel = `Product Upgrade Request (${this.changeTabCount})`;
    }
    createChangedProductDataMethodForLegacy(){
        let platformUpgradeSummaryListForEachProduct = [];
        let noChangeProductsList = [];
        this.processedConfirmationScreenData.forEach((product) => {
            product.isExpanded = true;
            if( !product.ineligibleProductId){        
                    if(product !== null){                
                        let  tempList = [];
                        let shipToSummariesListForNoChange  = [];
                        let  totalQty = 0;
                        product.finalScreenDetails.shipToAddresses.forEach((shipTo ) => {
                                totalQty += shipTo.quantity;
                                if( shipTo.upgradeProduct){  
                                    tempList.push({   
                                        address: shipTo.addressName,
                                        addressLink: `${this.baseURL}/${shipTo.addressId}`,
                                        totalQuantity: shipTo.quantity,
                                        upgradeQtyNumber : shipTo.upgradeProduct.upgradeQuantity,
                                        upgradeQuantity: `${shipTo.upgradeProduct.upgradeQuantity} / ${shipTo.quantity}` ,
                                        upgradeTo: shipTo.upgradeProduct.productName,
                                        upgradeToLink: `${this.baseURL}/${shipTo.upgradeProduct.productId}`,
                                        defaultHardware :shipTo.upgradeProduct.productCode,
                                        defaultHardwareCodeURL : shipTo.upgradeProduct.defaultHardwareCodeURL,
                                        toggleLink :  shipTo.upgradeProduct.productCode !=='None' ? true : false
                                    })
                                    if(  shipTo.upgradeProduct.remainingQuantity !== 0 &&  shipTo.upgradeProduct.remainingQuantity !== null ){
                                            shipToSummariesListForNoChange.push({
                                                addressName : shipTo.addressName,
                                                addressId : shipTo.addressId,
                                                addressLink: `${this.baseURL}/${shipTo.addressId}` ,
                                                totalQuantity : shipTo.quantity,
                                                remainingQuantity: shipTo.upgradeProduct.remainingQuantity,
                                                remainingQuantityText : `${shipTo.upgradeProduct.remainingQuantity} / ${shipTo.quantity}`
                                            })   
                                    }
                                }else{ 
                                    shipToSummariesListForNoChange.push({
                                        addressName : shipTo.addressName,
                                        addressId : shipTo.addressId,
                                        addressLink: `${this.baseURL}/${shipTo.addressId}` ,
                                        totalQuantity : shipTo.quantity,
                                        remainingQuantity: shipTo.quantity,
                                        remainingQuantityText : `${shipTo.quantity} / ${shipTo.quantity}`
                                    })
                                }
                        })
                        if(shipToSummariesListForNoChange.length > 0 ){
                            noChangeProductsList.push({
                                productId : product.originalProductId,
                                productName : product.originalProductName,
                                productLink: `${this.baseURL}/${product.originalProductId}`,
                                totalQuantity : totalQty,
                                totalRemainingQuantity : totalQty,
                                shippingAddressSummaries :shipToSummariesListForNoChange
                            })
                        }
                        if (tempList.length > 0) {
                            // Calculate total upgrade quantity for this product
                            const totalUpgradeQuantity = this.calculateTotalUpgradeQuantity(tempList);
                            
                            platformUpgradeSummaryListForEachProduct.push({
                                productId: product.originalProductId,
                                totalQuantity : totalQty,
                                productName: product.originalProductName,
                                productLink: `${this.baseURL}/${product.originalProductId}`,
                                totalUpgradeQuantity: totalUpgradeQuantity,
                                shippingAddressSummaries: tempList
                            });
                        }
                    }
            }else{
                let shippingAddressSummariesList  = [];
                product.screenTwoDetails.shipToAddresses.forEach((shipTo) =>{
                    shippingAddressSummariesList.push(
                        {
                            addressName : shipTo.addressName,
                            addressId : shipTo.addressId,
                            addressLink: `${this.baseURL}/${shipTo.addressId}` ,
                            totalQuantity : shipTo.quantity,
                            remainingQuantity: shipTo.quantity,
                            remainingQuantityText : `${shipTo.quantity} / ${shipTo.quantity}`
                        }
                    )
                })
                noChangeProductsList.push({
                    productId : product.ineligibleProductId,
                    productName : product.ineligibleProductName,
                    totalQuantity : product.totalQuantity,
                    productLink: `${this.baseURL}/${product.originalProductId}`,
                    shippingAddressSummaries :shippingAddressSummariesList
                })
            }
        });
        
        noChangeProductsList.forEach(product => {
            let totalRemaining = 0;
            let totalQty = 0;
            product.shippingAddressSummaries.forEach(address => {
                const parts = address.remainingQuantityText.split(' / ');
                if (parts.length === 2) {
                    totalRemaining += parseInt(parts[0], 10);
                    totalQty += parseInt(parts[1], 10);
                }
            });
            product.totalRemainingQuantityText = `${totalRemaining} / ${totalQty}`;
        });
        
        platformUpgradeSummaryListForEachProduct = platformUpgradeSummaryListForEachProduct.map((product) => {
            return {
                expandSymbol : 'utility:dash',
                isExpanded : true,
                ...product
            };
        });
        noChangeProductsList = noChangeProductsList.map((product) => {
            return {
                isExpanded: false,
                ...product
            };
        });
        this.noChangeProductData = noChangeProductsList;
        this.changedProductsData = platformUpgradeSummaryListForEachProduct;
        this.noChangeTabCount = noChangeProductsList.length;
        this.changeTabCount = platformUpgradeSummaryListForEachProduct.length; 
        this.noChangeTabLabel = `No Change (${this.noChangeTabCount})`;
        this.changeTabLabel = `Product Upgrade Request (${this.changeTabCount})`;
    }

    handleToggleExpand(event) {
        const productId = event.currentTarget.dataset.productid;
        this.changedProductsData  = this.changedProductsData.map(wrapper => {
            if(wrapper.productId === productId){    
                const isExpanded = !wrapper.isExpanded;
                return { 
                    ...wrapper,
                    isExpanded
                }
            }
            return wrapper; 
        }) 
        this.allChangedProductsExpanded = this.changedProductsData.every(product => product.isExpanded);
    }

    handleNoChangeToggleExpand(event) {
        const productId = event.currentTarget.dataset.productid;
        this.noChangeProductData = this.noChangeProductData.map(wrapper => {
            if(wrapper.productId === productId){    
                return { 
                    ...wrapper,
                    isExpanded: !wrapper.isExpanded
                }
            }
            return wrapper; 
        }) 
        this.allNoChangeProductsExpanded = this.noChangeProductData.every(product => product.isExpanded);
    }
    
    handleToggleAllChangedProducts() {
        const newExpandedState = !this.allChangedProductsExpanded;
        this.allChangedProductsExpanded = newExpandedState;
        this.changedProductsData = this.changedProductsData.map(product => {
            return {
                ...product,
                isExpanded: newExpandedState
            };
        });
    }
    
    // New method to toggle all no change products
    handleToggleAllNoChangeProducts() {
        const newExpandedState = !this.allNoChangeProductsExpanded;
        this.allNoChangeProductsExpanded = newExpandedState;
        this.noChangeProductData = this.noChangeProductData.map(product => {
            return {
                ...product,
                isExpanded: newExpandedState
            };
        });
    }

    handleProductChangeRequestToggle() {
        this.isProductChangeRequestExpanded = !this.isProductChangeRequestExpanded;
    }
}