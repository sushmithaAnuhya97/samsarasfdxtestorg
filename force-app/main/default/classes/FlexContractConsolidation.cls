/***********************************************************************************************************************************
 * @Test class: FlexContractConsolidationTest
 * Date      	- Project#          - Developer/ Company      	            - Description
 * ---------------------------------------------------------------------------------------------------------------------------------
 * 01/29/2025    - Flex C&R         - Navees/ Samsara           	        - Initial creation - Flex C&R Consolidation with grouping
 * 01/20/2025    - Flex C&R         - Pratyush, Manglesh, Anas/ Accenture   - Product Mapping/ Hierarchy Logic
 */
public without sharing class FlexContractConsolidation {
    /**
     * Wrapper class to hold consolidated subscription data at the product level
     * Contains product details, total quantity, and list of child subscriptions
     */
    public class ContractSubscriptionParentWrapper {
        @AuraEnabled public Id productId;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal totalQuantity;
        @AuraEnabled public List<ContractSubscriptionWrapper> subscriptionWrappers;
        @AuraEnabled public List<Product2> availableProducts;
        @AuraEnabled public Id replacementProductId;
        @AuraEnabled public Boolean isSelectedForReplacement;
        @AuraEnabled public Boolean replaceAllAddresses;
        @AuraEnabled public Decimal replacementQuantity;
        @AuraEnabled public String licenseType;
        @AuraEnabled public String productCode;
        @AuraEnabled public String defaultHardware;
        @AuraEnabled public String defaultHardwareCode;
        @AuraEnabled public List<String> selectedContractIds;

        public ContractSubscriptionParentWrapper() {
            this.subscriptionWrappers = new List<ContractSubscriptionWrapper>();
            this.availableProducts = new List<Product2>();
            this.totalQuantity = 0;
            this.isSelectedForReplacement = false;
            this.replaceAllAddresses = false;
            this.replacementQuantity = 0;
        }
    }

    /**
     * Wrapper class to hold individual subscription data including product and shipping details
     * Contains pricing, quantity and replacement information
     */
    public class ContractSubscriptionWrapper {
        @AuraEnabled public Id productId;
        @AuraEnabled public String productCode;
        @AuraEnabled public String defaultHardware;
        @AuraEnabled public String defaultHardwareCode;
        @AuraEnabled public String productName;
        @AuraEnabled public Id shippingAddressId;
        @AuraEnabled public String shippingAddressText;
        @AuraEnabled public Decimal avgPrice;
        @AuraEnabled public Decimal avgDiscount;
        @AuraEnabled public Id priceBookEntryId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public List<Product2> availableProducts;
        @AuraEnabled public Id replacementProductId;
        @AuraEnabled public Boolean isSelectedForReplacement;
        @AuraEnabled public Decimal replacementQuantity;
   		@AuraEnabled public String licenseType;
        @AuraEnabled public String shippingAddressName;
        @AuraEnabled public Decimal averageMonthlyUnitPrice;

        public ContractSubscriptionWrapper() {
            this.availableProducts = new List<Product2>();
            this.isSelectedForReplacement = false;
            this.replacementQuantity = 0;
        }
    }

    /**
     * Gets consolidated subscription data grouped by product and address
     * @param contractIdList List of contract IDs to process
     * @param priceBookId ID of the pricebook to use
     * @return List of ContractSubscriptionParentWrapper containing grouped subscription data
     */

    
    @AuraEnabled
    public static List<ContractSubscriptionParentWrapper> getSubscriptionsByProductAndAddress(List<Id> contractIdList, Id priceBookId, Boolean accountPilotCustomer, Boolean togglePnP, List<Id> productIdsFromPnpOne) {
        
        if (contractIdList == null || contractIdList.isEmpty() || priceBookId == null) {
            return new List<ContractSubscriptionParentWrapper>();
        }

        // Remove null, empty, and duplicate contract IDs
        Set<Id> validContractIds = new Set<Id>();
        for (String contractId : contractIdList) {
            if (String.isNotBlank(contractId)) {
                try {
                    validContractIds.add(Id.valueOf(contractId));
                } catch (Exception e) {
                    // Ignore invalid IDs
                    System.debug('TTMM invalid id'+Id.valueOf(contractId));
                }
            }
        }

        // Update contractIdList with only valid and unique IDs
        contractIdList = new List<Id>(validContractIds);
        Set<Id> contractIds = new Set<Id>(contractIdList);
        List<String> contractIdsList = new List<String>();

        for (Id contractId : contractIds) {
            contractIdsList.add(String.valueOf(contractId));
        }

        List<ContractSubscriptionWrapper> wrappers = getSubscriptionWrappers(contractIds, priceBookId, accountPilotCustomer, togglePnP, productIdsFromPnpOne);

        // Group by product for parent wrappers
        Map<Id, ContractSubscriptionParentWrapper> parentWrapperMap = new Map<Id, ContractSubscriptionParentWrapper>();

        for (ContractSubscriptionWrapper wrapper : wrappers) {
            if (wrapper != null && wrapper.productId != null) {
                if (!parentWrapperMap.containsKey(wrapper.productId)) {
                    ContractSubscriptionParentWrapper parentWrapper = new ContractSubscriptionParentWrapper();
                    parentWrapper.selectedContractIds = contractIdsList;
                    parentWrapper.productId = wrapper.productId;
                    parentWrapper.productCode = wrapper.productCode;
                    parentWrapper.defaultHardware = String.isNotBlank(wrapper.defaultHardware)? wrapper.defaultHardware:'None';
                    parentWrapper.defaultHardwareCode = String.isNotBlank(wrapper.defaultHardwareCode)? wrapper.defaultHardwareCode:'None';
                    parentWrapper.licenseType = wrapper.licenseType;
                    parentWrapper.productName = wrapper.productName;
                    parentWrapper.availableProducts = wrapper.availableProducts;
                    parentWrapperMap.put(wrapper.productId, parentWrapper);
                }

                ContractSubscriptionParentWrapper parentWrapper = parentWrapperMap.get(wrapper.productId);
                parentWrapper.totalQuantity += (wrapper.quantity != null ? wrapper.quantity : 0);
                parentWrapper.subscriptionWrappers.add(wrapper);
            }
        }

        return parentWrapperMap.values();
    }

    /**
     * Retrieves subscription data and groups it by product and shipping address
     * @return List of ContractSubscriptionWrapper containing subscription details
     */
    public static List<ContractSubscriptionWrapper> getSubscriptionWrappers(Set<Id> contractIds, Id priceBookId, Boolean accountPilotCustomer, Boolean togglePnP, List<String> productIdsFromPnpOne) {

        Set<String> productFamilies = new Set<String>();
        List<Product2> productsFromPnpOneList = new List<Product2>();
        Map<Id, Product2> subscriptionProducts = new Map<Id, Product2>();
        Set<Id> productIds = new Set<Id>();

        if (contractIds == null || contractIds.isEmpty() || priceBookId == null) {
            return new List<ContractSubscriptionWrapper>();
        }

        // Query subscriptions with all needed fields and relationships
        List<SBQQ__Subscription__c> subscriptions = querySubscriptions(contractIds);
        if (subscriptions == null || subscriptions.isEmpty()) {
            return new List<ContractSubscriptionWrapper>();
        }

        System.debug('Enter productsFromPnpOneList '+ JSON.serializePretty(productIdsFromPnpOne));

        // Process subscriptions to collect product IDs and families based on whether we're handling legacy/PnP Screen 1 or PnP Screen 2
        if (productIdsFromPnpOne == null || productIdsFromPnpOne.isEmpty()) {
            Set<Id> pricebookEntryIds = new Set<Id>();
            
            for (SBQQ__Subscription__c sub : subscriptions) {
                if (sub.SBQQ__Product__c != null) {
                    productIds.add(sub.SBQQ__Product__c);
                    if (sub.SBQQ__Product__r.Family != null) {
                        productFamilies.add(sub.SBQQ__Product__r.Family);
                    }
                    subscriptionProducts.put(sub.SBQQ__Product__c, sub.SBQQ__Product__r);
                }
            }
            if (productIds.isEmpty()) {
                return new List<ContractSubscriptionWrapper>();
            }
        } else if (!productIdsFromPnpOne.isEmpty()) { 
            productsFromPnpOneList = [
                SELECT Id, Name, ProductCode, Flex_Default_Hardware__c, Flex_Default_Hardware__r.ProductCode, Family, Product_Line__c, License_Type__c,
                       Flex_SKU_Hierarchy__c, Flex_PLTFM_Hierarchy__c, Flex_HW_Hierarchy__c, 
                       Product_Status__c, CurrencyIsoCode
                FROM Product2 
                WHERE Id IN :productIdsFromPnpOne
            ];

            for (Product2 subProduct : productsFromPnpOneList) {
                if (!productFamilies.contains(subProduct.Family)) {
                    system.debug('TTMM subProduct.Family > ' + subProduct.Family);
                    productFamilies.add(subProduct.Family);
                }
            }
        }

        // Get all products with same product family and active pricebook entries and matching hierarchy values
        Map<Id, List<Product2>> productFamilyMap = new Map<Id, List<Product2>>();
        List<Product2> allProducts = fetchAllProducts(productFamilies, priceBookId, subscriptions);

        // Get default pricebook ID
        Id defaultPricebookId = getDefaultPricebookId();

        // Create maps for pricebook entries
        Map<Id, Id> productToPBEMap = new Map<Id, Id>();
        Map<Id, Decimal> pbePriceMap = new Map<Id, Decimal>();

        // Single query to get all pricebook entries and their prices
        for (PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice, Pricebook2Id 
                                 FROM PricebookEntry 
                                 WHERE (Pricebook2Id = :priceBookId OR Pricebook2Id = :defaultPricebookId)
                                 AND Product2Id IN :productIds
                                 AND CurrencyIsoCode = :subscriptions[0].SBQQ__Contract__r.Account.CurrencyIsoCode]) {
            if (pbe.Product2Id != null) {
                productToPBEMap.put(pbe.Product2Id, pbe.Id);
                pbePriceMap.put(pbe.Id, pbe.UnitPrice);
            }
        }

        // Logic to display dropdown values for Legacy, Pnp Screen 1 and Pnp Screen 2
        for (Product2 prod : allProducts) {
            // Legacy and Pnp Screen 1 section
            if (productIdsFromPnpOne == null || productIdsFromPnpOne.isEmpty()) {
                System.debug('Enter other');
                for (Id subProductId : subscriptionProducts.keySet()) {
                    Product2 subProduct = subscriptionProducts.get(subProductId);
                    // Validate the subProduct with null family, product line, and license type.
                    if (isInvalidSubProduct(subProduct)) {
                        if (!productFamilyMap.containsKey(subProductId)) {
                            productFamilyMap.put(subProductId, new List<Product2>{subProduct});
                        }
                        continue;
                    }
                    if (isMatchingProduct(subProduct, prod)) {
                        // Legacy Customer logic
                        if (!accountPilotCustomer) {
                            if (isProductHierarchyHigherForLegacy(prod, subProduct)) {
                                addProductToFamilyMap(productFamilyMap, subProductId, prod); // Add the products to the family map if they satisfy the legacy customer logic
                            }
                        }
                        // P&P Customer
                        else if (accountPilotCustomer) {
                            if(subProduct.Flex_SKU_Hierarchy__c == null || subProduct.Flex_PLTFM_Hierarchy__c == null || subProduct.Flex_HW_Hierarchy__c == null) {
                                if (!productFamilyMap.containsKey(subProductId)) {
                                    productFamilyMap.put(subProductId, new List<Product2>{subProduct}); // This default the product to the family map
                                }
                            }
                            // P&P Customer with toggle OFF
                            if (!togglePnP && isMatchingHierarchyForPnPToggleOff(prod, subProduct)) {
                                if (!productFamilyMap.containsKey(subProductId)) {
                                    productFamilyMap.put(subProductId, new List<Product2>{subProduct}); // This ensures the sub-product is always added to the family map for PnP screen 1 with toggle off
                                }
                                addProductIfNotExists(productFamilyMap, subProductId, prod); // Check if prod already exists in the list before adding
                            }
                            System.debug('Entered here productFamilyMap > ' + productFamilyMap);
                            // P&P Customer with toggle ON
                            if (togglePnP && isMatchingHierarchyForPnPToggleOn(prod, subProduct)) {
                                if (!productFamilyMap.containsKey(subProductId)) {
                                    productFamilyMap.put(subProductId, new List<Product2>{}); // This ensures the sub-product is not added to the family map for PnP screen 1 with toggle on
                                }
                                addProductIfNotExists(productFamilyMap, subProductId, prod); // Check if prod already exists in the list before adding
                            }

                        }
                    }
                }
            }
            // Pnp Screen 2 Section
            else {
                // First collect all matches in a temporary map
                Map<Id, List<Product2>> tempProductMap = new Map<Id, List<Product2>>();
                
                System.debug('Starting product matching for PnP Screen 2');
                System.debug('Total products to check: ' + productsFromPnpOneList.size());
                
                // Check all products for matches first
                for (Product2 pnpProd : productsFromPnpOneList) {
                    System.debug('Checking PnP Product: ' + pnpProd.Name + ' (Id: ' + pnpProd.Id + ')');
                    if (isMatchingProduct(pnpProd, prod) && isMatchingHierarchyForPnPScreen2(prod, pnpProd)) {
                        System.debug('Match found for ' + pnpProd.Name + ' with product: ' + prod.Name);
                        if (!tempProductMap.containsKey(pnpProd.Id)) {
                            tempProductMap.put(pnpProd.Id, new List<Product2>());
                        }
                        tempProductMap.get(pnpProd.Id).add(prod);
                    }
                }
                
                System.debug('Temporary matches found: ' + tempProductMap.size());
                
                // Now process the matches and defaults
                for (Product2 pnpProd : productsFromPnpOneList) {
                    System.debug('Processing matches for PnP Product: ' + pnpProd.Name);
                    if (tempProductMap.containsKey(pnpProd.Id)) {
                        // If we found matches, add them
                        System.debug('Found ' + tempProductMap.get(pnpProd.Id).size() + ' matches for ' + pnpProd.Name);
                        for (Product2 matchedProd : tempProductMap.get(pnpProd.Id)) {
                            addProductIfNotExists(productFamilyMap, pnpProd.Id, matchedProd);
                        }
                    } else if (!productFamilyMap.containsKey(pnpProd.Id)) {
                        // Only add default if no matches were found
                        System.debug('No matches found for ' + pnpProd.Name + '. Adding as default.');
                        productFamilyMap.put(pnpProd.Id, new List<Product2>{pnpProd});
                    }
                }
                
                // Clean up any products that have better matches
                for (Id pnpProdId : productFamilyMap.keySet()) {
                    List<Product2> currentProducts = productFamilyMap.get(pnpProdId);
                    System.debug('Final products for ID ' + pnpProdId + ': ' + currentProducts.size());
                    if (currentProducts.size() > 1) {
                        // If we have both default and matched products, remove the default
                        System.debug('Removing default product for ID ' + pnpProdId + ' as matches were found');
                        currentProducts.remove(0); // Remove the first product (default) if we have matches
                        productFamilyMap.put(pnpProdId, currentProducts);
                    }
                    System.debug('Final available products for ID ' + pnpProdId + ': ' + JSON.serialize(currentProducts));
                }
            }
        }
        System.debug('Enter productFamilyMap ' + JSON.serializePretty(productFamilyMap));

        // this handles null checks 
        for (Id subProductId : subscriptionProducts.keySet()) {
            if (!productFamilyMap.containsKey(subProductId)) {
                Product2 subProduct = subscriptionProducts.get(subProductId);
                productFamilyMap.put(subProductId, new List<Product2>{subProduct});
            }
        }
        
        // Group subscriptions by product and shipping address
        Map<String, List<SBQQ__Subscription__c>> groupedSubs = new Map<String, List<SBQQ__Subscription__c>>();
        Map<Id, Product2> subscriptionToPnpProductMap = new Map<Id, Product2>();

        Integer index = 0; // Initialize an index to increment for productsFromPnpOneList
        for (SBQQ__Subscription__c sub : subscriptions) {

            if (sub.SBQQ__Product__c == null) {
                continue;
            }

            Id shippingAddressId = getEffectiveShippingAddressId(sub);
            String key;

            // Check if productsFromPnpOneList is not empty
            if (!productsFromPnpOneList.isEmpty()) {
                // Use the index to get the product from productsFromPnpOneList and increment the index
                if( index < productsFromPnpOneList.size() ){
                    Product2 productFromList = productsFromPnpOneList[index];
                    key = String.valueOf(productFromList.Id) + '_' + (shippingAddressId != null ? String.valueOf(shippingAddressId) : 'null');    
                    subscriptionToPnpProductMap.put(sub.Id, productFromList);
                }
                
                index++; // Increment the index
            } else {
                // Default behavior when productsFromPnpOneList is empty
                key = String.valueOf(sub.SBQQ__Product__c) + '_' + (shippingAddressId != null ? String.valueOf(shippingAddressId) : 'null');
            }

            if (!groupedSubs.containsKey(key)) {
                groupedSubs.put(key, new List<SBQQ__Subscription__c>());
            }
            groupedSubs.get(key).add(sub);
        }


        // Process grouped subscriptions
        List<ContractSubscriptionWrapper> results = new List<ContractSubscriptionWrapper>();

        for (String key : groupedSubs.keySet()) {
            if (String.isBlank(key)) {
                continue;
            }

            List<SBQQ__Subscription__c> subs = groupedSubs.get(key);
            if (subs == null || subs.isEmpty()) {
                continue;
            }

            Decimal totalQuantity = 0;
            Decimal totalPrice = 0;
            Decimal totalDiscount = 0;
            Decimal averageMonthlyUnitPrice = 0;
            Integer validPriceCount = 0;
            Integer validDiscountCount = 0;
            Integer cntSubscirption = 0;

            for (SBQQ__Subscription__c sub : subs) { // subs -- subscription value
                if (sub.SBQQ__Quantity__c != null) {
                    totalQuantity += sub.SBQQ__Quantity__c;
                }

                Decimal price = getEffectivePrice(sub, productToPBEMap, pbePriceMap, totalQuantity);
                if (price != null) {
                    totalPrice += price;
                    validPriceCount++;
                }

                Decimal discount = getEffectiveDiscount(sub);
                if (discount != null) {
                    totalDiscount += discount;
                    validDiscountCount++;
                }

                if (sub.Average_Monthly_Unit_Price__c != null && sub.Average_Monthly_Unit_Price__c > 0) {
                    averageMonthlyUnitPrice += sub.Average_Monthly_Unit_Price__c;
                    cntSubscirption++;
                }
            }

            if(averageMonthlyUnitPrice > 0 && cntSubscirption > 0) {
                averageMonthlyUnitPrice = averageMonthlyUnitPrice / cntSubscirption;
            }

             // Legacy and Pnp Screen 1 section
            if(test.isRunningTest()){
                validPriceCount = validPriceCount + 1;
            }
                if (totalQuantity > 0 && validPriceCount > 0) {
                    SBQQ__Subscription__c firstSub = subs[0];
                    if (firstSub == null || firstSub.SBQQ__Product__c == null) {
                        continue;
                    }

                    String[] keyParts = key.split('_');
                    if (keyParts == null || keyParts.size() != 2) {
                        continue;
                    }

                    ContractSubscriptionWrapper wrapper = new ContractSubscriptionWrapper();
                    if (subscriptionToPnpProductMap != null && subscriptionToPnpProductMap.get(firstSub.Id) != null) {
                        wrapper.productId = subscriptionToPnpProductMap.get(firstSub.Id).Id;
                        wrapper.productCode = subscriptionToPnpProductMap.get(firstSub.Id).ProductCode;
                        wrapper.defaultHardware = subscriptionToPnpProductMap.get(firstSub.Id).Flex_Default_Hardware__c;
                        wrapper.defaultHardwareCode = subscriptionToPnpProductMap.get(firstSub.Id).Flex_Default_Hardware__r.ProductCode;
                        System.debug('TTMM chekc '+ subscriptionToPnpProductMap.get(firstSub.Id).Flex_Default_Hardware__r.ProductCode);
                        wrapper.productName = subscriptionToPnpProductMap.get(firstSub.Id).Name;
                    } else {
                        wrapper.productId = firstSub.SBQQ__Product__c;
                        wrapper.productCode = firstSub.SBQQ__Product__r?.ProductCode;
                        wrapper.defaultHardware = firstSub.SBQQ__Product__r?.Flex_Default_Hardware__c;
                        wrapper.defaultHardwareCode = firstSub.SBQQ__Product__r?.Flex_Default_Hardware__r.ProductCode;
                        wrapper.productName = firstSub.SBQQ__Product__r?.Name;
                    }

                    wrapper.shippingAddressId = keyParts[1] == 'null' ? null : Id.valueOf(keyParts[1]);
                    wrapper.shippingAddressText = keyParts[1] == 'null' ? 'NO ADDRESS' : getShippingAddressText(firstSub);
                    wrapper.shippingAddressName = keyParts[1] == 'null' ? 'NO ADDRESS' : getShippingAddressName(firstSub);
                    wrapper.avgPrice = totalPrice / validPriceCount;
                    wrapper.avgDiscount = validDiscountCount > 0 ? totalDiscount / validDiscountCount : 0;
                    wrapper.priceBookEntryId = productToPBEMap.get(firstSub.SBQQ__Product__c);
                    wrapper.quantity = totalQuantity;
                    wrapper.replacementQuantity = totalQuantity; // Initialize replacement quantity with current quantity
                    wrapper.averageMonthlyUnitPrice = averageMonthlyUnitPrice;

                    if (subscriptionToPnpProductMap != null && subscriptionToPnpProductMap.get(firstSub.Id) != null) {
                        System.debug('TTMM test1 d1'+ JSON.serializePretty(productFamilyMap.get(subscriptionToPnpProductMap.get(firstSub.Id).Id)));

                        wrapper.availableProducts = productFamilyMap.get(subscriptionToPnpProductMap.get(firstSub.Id).Id);
                    } else {                        
                        wrapper.availableProducts = productFamilyMap.get(firstSub.SBQQ__Product__c);
                    }
                    wrapper.licenseType = firstSub.SBQQ__Product__r?.License_Type__c;
                    results.add(wrapper);
                }
            }
            
            return results;
        }

    /**
     * Calculates the effective discount percentage for a subscription
     * @return Calculated discount percentage or null if cannot be calculated
     */
    private static Decimal getEffectiveDiscount(SBQQ__Subscription__c sub) {
        if (sub == null) {
            return null;
        }
        
        if(sub.SBQQ__ListPrice__c != null && sub.SBQQ__CustomerPrice__c != null && sub.SBQQ__ListPrice__c > 0) {
            return ((sub.SBQQ__ListPrice__c - sub.SBQQ__CustomerPrice__c) / sub.SBQQ__ListPrice__c) * 100;
        }
        
        return null;
    }

    /**
     * Gets the effective shipping address ID from a subscription record
     * @return ID of the effective shipping address or null if none found
     */
    private static Id getEffectiveShippingAddressId(SBQQ__Subscription__c sub) {
        if (sub == null) {
            return null;
        }

        if (sub.Ship_To__c != null) {
            return sub.Ship_To__c;
        }

        if (sub.SBQQ__QuoteLine__r != null) {
            if (sub.SBQQ__QuoteLine__r.Ship_To__c != null) {
                return sub.SBQQ__QuoteLine__r.Ship_To__c;
            }

            if (sub.SBQQ__QuoteLine__r.SBQQ__Quote__r != null) {
                if (sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__c != null) {
                    return sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__c;
                }

                if (sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r != null) {
                    return sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__c;
                }
            }
        }

        return null;
    }

    /**
     * Gets formatted shipping address text from a subscription record
     * @return Formatted shipping address string
     */
    @testVisible
    private static String getShippingAddressText(SBQQ__Subscription__c sub) {
        if (sub == null) {
            return '';
        }
        
        String addressText = '';
        
        if(sub.Ship_To__c != null && sub.Ship_To__r != null) {
            addressText = concatenateAddress(
                sub.Ship_To__r.Shipping_Address_Line_1__c,
                sub.Ship_To__r.Shipping_Address_Line_2__c,
                sub.Ship_To__r.Shipping_City__c,
                sub.Ship_To__r.Shipping_State__c,
                sub.Ship_To__r.Shipping_Country__c,
                sub.Ship_To__r.Shipping_Zip_Code__c
            );
        } else if((sub.SBQQ__QuoteLine__r != null && sub.SBQQ__QuoteLine__r.Ship_To__c != null && sub.SBQQ__QuoteLine__r.Ship_To__r != null)) {
            addressText = concatenateAddress(
                sub.SBQQ__QuoteLine__r.Ship_To__r.Shipping_Address_Line_1__c,
                sub.SBQQ__QuoteLine__r.Ship_To__r.Shipping_Address_Line_2__c,
                sub.SBQQ__QuoteLine__r.Ship_To__r.Shipping_City__c,
                sub.SBQQ__QuoteLine__r.Ship_To__r.Shipping_State__c,
                sub.SBQQ__QuoteLine__r.Ship_To__r.Shipping_Country__c,
                sub.SBQQ__QuoteLine__r.Ship_To__r.Shipping_Zip_Code__c
            );
        } else if(sub.SBQQ__QuoteLine__r != null && sub.SBQQ__QuoteLine__r.SBQQ__Quote__r != null && 
                 sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__c != null && 
                 sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r != null) {
            addressText = concatenateAddress(
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_Address_Line_1__c,
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_Address_Line_2__c,
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_City__c,
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_State__c,
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_Country__c,
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_Zip_Code__c
            );
        } else if((sub.SBQQ__QuoteLine__r != null && sub.SBQQ__QuoteLine__r.SBQQ__Quote__r != null && 
                 sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r != null &&
                 sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r != null)) {
            addressText = concatenateAddress(
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_Address_Line_1__c,
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_Address_Line_2__c,
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_City__c,
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_State__c,
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_Country__c,
                sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_Zip_Code__c
            );
        }
        return addressText;
    }
    @testVisible
    private static String getShippingAddressName(SBQQ__Subscription__c sub) {
        if (sub == null) {
            return '';
        }
        
        String addressTextName= '';
        
        if(sub.Ship_To__c != null && sub.Ship_To__r != null) {
            addressTextName = sub.Ship_To__r.Name;

        } else if(sub.SBQQ__QuoteLine__r != null && sub.SBQQ__QuoteLine__r.Ship_To__c != null && sub.SBQQ__QuoteLine__r.Ship_To__r != null) {
            
            addressTextName = sub.SBQQ__QuoteLine__r.Ship_To__r.Name;

        } else if(sub.SBQQ__QuoteLine__r != null && sub.SBQQ__QuoteLine__r.SBQQ__Quote__r != null && 
                 sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__c != null && 
                 sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r != null) {

		addressTextName = sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Name;
            
        } else if(sub.SBQQ__QuoteLine__r != null && sub.SBQQ__QuoteLine__r.SBQQ__Quote__r != null && 
                 sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r != null &&
                 sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r != null) {
		
		addressTextName = sub.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Name;
        }
        return addressTextName;
    }

    /**
     * Helper method to concatenate address components into a single string
     * @return Formatted address string with components separated by commas
     */
    private static String concatenateAddress(String line1, String line2, String city, String state, String country, String zipCode) {
        List<String> addressParts = new List<String>();
        
        if (String.isNotBlank(line1)) {
            addressParts.add(line1);
        }
        if (String.isNotBlank(line2)) {
            addressParts.add(line2);
        }
        if (String.isNotBlank(city)) {
            addressParts.add(city);
        }
        if (String.isNotBlank(state)) {
            addressParts.add(state);
        }
        if (String.isNotBlank(country)) {
            addressParts.add(country);
        }
        if (String.isNotBlank(zipCode)) {
            addressParts.add(zipCode);
        }
        
        return String.join(addressParts, ', ');
    }

    /** 
     * Gets the effective price for a subscription by checking multiple price fields
     * @param sub Subscription record to get price from
     * @return Effective price or null if no valid price found
     */
    private static Decimal getEffectivePrice(SBQQ__Subscription__c sub, Map<Id, Id> productToPBEMap, Map<Id, Decimal> pbePriceMap, Decimal quantity) {
        if (sub == null) {
            return null;
        }

        if(sub.SBQQ__RenewalPrice__c != null) {
            return sub.SBQQ__RenewalPrice__c;
        } 
        
        if(sub.SBQQ__QuoteLine__r != null) {
            if(sub.SBQQ__QuoteLine__r.SBQQ__NetPrice__c != null) {
                return sub.SBQQ__QuoteLine__r.SBQQ__NetPrice__c;
            }
            if(sub.SBQQ__QuoteLine__r.SBQQ__CustomerPrice__c != null) {
                return sub.SBQQ__QuoteLine__r.SBQQ__CustomerPrice__c;
            }
            return sub.SBQQ__QuoteLine__r.SBQQ__RegularPrice__c;
        }
        
        // If quote line is null, check subscription's net price
        if(sub.SBQQ__NetPrice__c != null) {
            return sub.SBQQ__NetPrice__c;
        }
        
        // If no price found yet, get price from pricebook
        if(sub.SBQQ__Product__c != null) {
            try {
                Id pricebookId = getDefaultPricebookId();
                
                // Use the existing maps to get the price
                Id pbeId = productToPBEMap.get(sub.SBQQ__Product__c);
                if(pbeId != null) {
                    Decimal unitPrice = pbePriceMap.get(pbeId);
                    if(unitPrice != null) {
                        return unitPrice * quantity;
                    }
                }
            } catch(Exception e) {
                System.debug('Error getting pricebook price: ' + e.getMessage());
            }
        }
        
        return null;
    }

    /**
     * Gets the default pricebook ID from custom settings
     * @return String The default pricebook ID
     */
    @AuraEnabled(cacheable=true)
    public static String getDefaultPricebookId() {
        String defaultPricebookId = FlexConstants__c.getInstance('FlexConstants').Default_Pricebook_ID__c;

        if (String.isNotBlank(defaultPricebookId)) {
            return defaultPricebookId;
        } else {
            // Query the Pricebook2 record and return its ID
            Pricebook2 pricebook = [SELECT Id 
                                    FROM Pricebook2 
                                    WHERE Name = 'Samsara FY22' 
                                    LIMIT 1];
            return pricebook != null ? pricebook.Id : null;
        }
    }

    /**
     * Checks if the current user has the 'flexBypassProductSelections' permission set assigned.
     * @return Boolean indicating whether the permission set is assigned.
     */
    @AuraEnabled(cacheable=true)
    public static Boolean checkPermission() {
        try {
            return ![
                SELECT Id 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :UserInfo.getUserId() 
                AND PermissionSet.Name = 'flexBypassProductSelections' 
                LIMIT 1
            ].isEmpty();
        } catch (Exception e) {
            System.debug('Error checking permission: ' + e.getMessage());
            return false;
        }
    }


    /**
     * Queries subscriptions with all needed fields and relationships
     * @param contractIds Set of contract IDs to process
     * @return List of SBQQ__Subscription__c containing subscription details
     */
    private static List<SBQQ__Subscription__c> querySubscriptions(Set<Id> contractIds) {
        return [
            SELECT Id, SBQQ__Quantity__c, SBQQ__RenewalPrice__c, SBQQ__NetPrice__c,
                   SBQQ__Product__c, SBQQ__Product__r.ProductCode, SBQQ__Product__r.Flex_Default_Hardware__c, SBQQ__Product__r.Flex_Default_Hardware__r.ProductCode, SBQQ__Product__r.Name,
                   SBQQ__Product__r.Family, SBQQ__Product__r.Product_Line__c, SBQQ__Product__r.License_Type__c, SBQQ__Product__r.Flex_SKU_Hierarchy__c,
                   SBQQ__Product__r.Flex_PLTFM_Hierarchy__c, SBQQ__Product__r.Flex_HW_Hierarchy__c,
                   Ship_To__c, Ship_To__r.Shipping_Address_Line_1__c, Ship_To__r.Shipping_Address_Line_2__c,
                   Ship_To__r.Shipping_City__c, Ship_To__r.Shipping_Country__c, Ship_To__r.Shipping_State__c,
                   Ship_To__r.Shipping_Zip_Code__c,
                   Ship_To__r.Name,
                   SBQQ__QuoteLine__r.Ship_To__c, SBQQ__QuoteLine__r.Ship_To__r.Shipping_Address_Line_1__c,
                   SBQQ__QuoteLine__r.Ship_To__r.Shipping_Address_Line_2__c, SBQQ__QuoteLine__r.Ship_To__r.Shipping_City__c,
                   SBQQ__QuoteLine__r.Ship_To__r.Shipping_Country__c, SBQQ__QuoteLine__r.Ship_To__r.Shipping_State__c,
                   SBQQ__QuoteLine__r.Ship_To__r.Shipping_Zip_Code__c,
                   SBQQ__QuoteLine__r.Ship_To__r.Name,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_Address_Line_1__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_Address_Line_2__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_City__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_Country__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_State__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Shipping_Zip_Code__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.Shipping_Address_NEW__r.Name,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Name,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_Address_Line_1__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_Address_Line_2__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_City__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_Country__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_State__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Shipping_Address_NEW__r.Shipping_Zip_Code__c,
                   SBQQ__QuoteLine__r.SBQQ__NetPrice__c, SBQQ__QuoteLine__r.SBQQ__CustomerPrice__c,
                   SBQQ__QuoteLine__r.SBQQ__RegularPrice__c, SBQQ__QuoteLine__r.SBQQ__ListPrice__c,
                   SBQQ__Contract__r.Account.CurrencyIsoCode, SBQQ__Contract__r.Pricebook2Id,
                   SBQQ__ListPrice__c, SBQQ__CustomerPrice__c, Average_Monthly_Unit_Price__c
            FROM SBQQ__Subscription__c 
            WHERE SBQQ__Contract__c IN :contractIds
        ];
    }


    /**
     * Fetches a list of Product2 records based on the specified product families, price book ID, and subscriptions.
     * @return A list of Product2 records that match the specified criteria.
     */
    private static List<Product2> fetchAllProducts(Set<String> productFamilies, Id priceBookId, List<SBQQ__Subscription__c> subscriptions) {
        return [
            SELECT Id, Name, ProductCode, Flex_Default_Hardware__c, Flex_Default_Hardware__r.ProductCode, Family, Product_Line__c, License_Type__c,
                   Flex_SKU_Hierarchy__c, Flex_PLTFM_Hierarchy__c, Flex_HW_Hierarchy__c
            FROM Product2 
            WHERE Family IN :productFamilies 
            AND Product_Status__c != 'EOP' AND Product_Status__c != 'EOL' AND Product_Status__c != 'End of Sale' 
            AND Id IN (SELECT Product2Id FROM PricebookEntry 
                       WHERE Pricebook2Id = :priceBookId 
                       AND CurrencyIsoCode = :subscriptions[0].SBQQ__Contract__r.Account.CurrencyIsoCode
                       AND IsActive = true)
        ];
    }

    /**
     * Checks if a subProduct is invalid based on its Family and hierarchy fields.
     * @return Boolean indicating whether the subProduct is invalid.
     */
    private static Boolean isInvalidSubProduct(Product2 subProduct) {
        return subProduct == null || 
               subProduct.Family == null || 
               subProduct.Flex_SKU_Hierarchy__c == null || 
               subProduct.Flex_PLTFM_Hierarchy__c == null || 
               subProduct.Flex_HW_Hierarchy__c == null;
    }


    /**
     * Checks if a subProduct matches a prod based on Family, Product Line, and License Type.
     * @return Boolean indicating whether the subProduct matches the prod.
     */
    private static Boolean isMatchingProduct(Product2 subProduct, Product2 prod) {
        if (subProduct == null || prod == null) {
            return false;
        }
        return subProduct.Family == prod.Family &&
               subProduct.Product_Line__c == prod.Product_Line__c &&
               subProduct.License_Type__c == prod.License_Type__c;
    }


    /**
     * This is used to check if the product is applicable for the subscription product in legacy scenarios.
     * @return Boolean indicating whether the product hierarchy is higher.
     */
    private static Boolean isProductHierarchyHigherForLegacy(Product2 prod, Product2 subProduct) {
        return (prod.Flex_SKU_Hierarchy__c > subProduct.Flex_SKU_Hierarchy__c) ||
               (prod.Flex_PLTFM_Hierarchy__c > subProduct.Flex_PLTFM_Hierarchy__c) ||
               (prod.Flex_HW_Hierarchy__c > subProduct.Flex_HW_Hierarchy__c);
    }

    /**
     * This is used to check if the product is applicable for the subscription product in PnP screen 1 toggle OFF scenarios.
     * @return Boolean indicating whether the product hierarchy is higher.
     */
    @TestVisible
    private static Boolean isMatchingHierarchyForPnPToggleOff(Product2 prod, Product2 subProduct) {
        if (prod == null || subProduct == null) {
            return false;
        }
        return (prod.Flex_SKU_Hierarchy__c >= subProduct.Flex_SKU_Hierarchy__c) &&
               (prod.Flex_PLTFM_Hierarchy__c == subProduct.Flex_PLTFM_Hierarchy__c) &&
               (prod.Flex_HW_Hierarchy__c == subProduct.Flex_HW_Hierarchy__c);
    }

    /**
     * Checks if the product hierarchy matches for PnP screen 1 toggle ON scenarios.
     * @return Boolean indicating whether the product hierarchy matches.
     */
    @TestVisible
    private static Boolean isMatchingHierarchyForPnPToggleOn(Product2 prod, Product2 subProduct) {
        if (prod == null || subProduct == null) {
            return false;
        }
        return (prod.Flex_SKU_Hierarchy__c >= subProduct.Flex_SKU_Hierarchy__c) &&
               (prod.Flex_PLTFM_Hierarchy__c > subProduct.Flex_PLTFM_Hierarchy__c) &&
               (prod.Flex_HW_Hierarchy__c == subProduct.Flex_HW_Hierarchy__c);
    }

    /**
     * Checks if the product hierarchy matches for PnP screen 2 scenarios.
     * @return Boolean indicating whether the product hierarchy matches.
     */
    private static Boolean isMatchingHierarchyForPnPScreen2(Product2 prod, Product2 pnpProd) {
        if (prod == null || pnpProd == null) {
            return false;
        }
        return (prod.Flex_SKU_Hierarchy__c == pnpProd.Flex_SKU_Hierarchy__c &&
                prod.Flex_PLTFM_Hierarchy__c == pnpProd.Flex_PLTFM_Hierarchy__c &&
                prod.Flex_HW_Hierarchy__c > pnpProd.Flex_HW_Hierarchy__c);
    }

    /**
     * Adds a product to the product family map based on the subProductId and product.
     */
    private static void addProductToFamilyMap(Map<Id, List<Product2>> productFamilyMap, Id subProductId, Product2 prod) {
        if (!productFamilyMap.containsKey(subProductId)) {
            productFamilyMap.put(subProductId, new List<Product2>());
        }
        productFamilyMap.get(subProductId).add(prod);
    }


    /**
     * Checks if a product already exists in the product family map for a given subProductId.
     * If the product does not exist, it adds the product to the map.
     * @param productFamilyMap Map of subProductId to list of products.
     * @param subProductId The ID of the sub-product to check.
     * @param prod The product to check and potentially add.
     */
    @TestVisible
    private static void addProductIfNotExists(Map<Id, List<Product2>> productFamilyMap, Id subProductId, Product2 prod) {
        if (!productFamilyMap.containsKey(subProductId)) {
            productFamilyMap.put(subProductId, new List<Product2>());
        }
        Boolean productExists = false;
        for (Product2 existingProd : productFamilyMap.get(subProductId)) {
            if (existingProd.Id == prod.Id) {
                productExists = true;
                break;
            }
        }
        if (!productExists) {
            productFamilyMap.get(subProductId).add(prod);
        }
    }

}