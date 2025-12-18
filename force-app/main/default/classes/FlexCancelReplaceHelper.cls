/****************************************************************************************************************************
 * @Test class: FlexAccountCancelReplaceControllerTest
* Date      	- Project#     - Developer/ Company      	   - Description
* -----------------------------------------------------------------------------------------------------------------------------------
* 01/06/2025    - GTMS-25705   - Anas Siddiquee/ Accenture 	   - Helper class for Cancel and Replace
* 01/20/2025    - GTMS-25961   - Anas Siddiquee/ Accenture     - Set the Quote Start Date 15 days after the Opp. close date for rebook
* 04/15/2025    - GTMS-26249   - Rushikesh/ Accenture        -   added a method to create a snapshot quote.
*/
public without sharing class FlexCancelReplaceHelper {
    @TestVisible
	private static Boolean isTestContext = Test.isRunningTest();
    public static List<AsyncApexJob> futureJobList = new List<AsyncApexJob>();
    public static List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
	
    /**
    * @description - Loads the quote model for a given contract ID using the CPQ Amendment API
    * @params - contractId The ID of the contract to be amended
    * @return - QuoteModel The loaded quote model
    */
    public static QuoteModel load(String contractId) {
        String quoteJSON;
        quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contractId, null);
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    /**
    * @description - Creates a new replacement opportunity
    * @params - amendContracts contains the details in the form of wrapper
    * @return - Opportunity Returns a newly created replacement Opportunity
    */
    public static Opportunity createReplacementOpp(FlexAmendContractsMsg amendContracts,Boolean hasNoNterms ) {
        System.debug('Enter createReplacementOpp ' + amendContracts.accountId);
        Account acc = [SELECT Name , CurrencyIsoCode FROM Account WHERE Id = :amendContracts.accountId LIMIT 1];
        Opportunity opp = new Opportunity();
        opp.AccountId = amendContracts.accountId;
        opp.CurrencyIsoCode = acc.CurrencyIsoCode;  // Explicitly set the currency
        opp.Name = 'Replacement - ' + acc.Name;
        opp.StageName = 'Qualified';
        opp.CloseDate = Date.valueOf(amendContracts.startDate);
        opp.RecordTypeId = getRecordTypeIdByDeveloperName('Opportunity', 'Standard_Opportunity');
        opp.Type = 'Revenue Opportunity';
        opp.Sub_Type__c = 'Contract Replacement';
        opp.Flex_Has_Non_Standard_Terms__c = hasNoNterms;
        //opp.Bypass_Validation_Rule_DateTime__c = DateTime.now();
        insert opp;
        return opp;
    }

    /**
    * @description - Creates a new replacement quote
    * @params - The details in the form of wrapper, The new replacement opportunity
    * @return - SBQQ__Quote__c Returns a newly created replacement Quote
    */
    public static SBQQ__Quote__c createReplacementQuote(FlexAmendContractsMsg amendContracts, Opportunity opportunity) {
        Account account = [SELECT Id,CurrencyIsoCode, Payment_Terms__c FROM Account WHERE Id = :amendContracts.accountId];
        System.debug('Enter isRebook ' + amendContracts.isRebook);
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = opportunity.Id;
        quote.CurrencyIsoCode = account.CurrencyIsoCode;
        quote.SBQQ__PaymentTerms__c = account.Payment_Terms__c;
        quote.SBQQ__Account__c = amendContracts.accountId;
        quote.SBQQ__LineItemsGrouped__c = true;
        System.debug('Enter SBQQ__Account__c '+ quote.SBQQ__Account__c);

        if (amendContracts.isRebook) {
            quote.Flex_Is_Rebook_Quote__c = true; //GTMS-26503 and Flex_Is_Rebook_Quote__c is false by default 
            quote.SBQQ__StartDate__c = Date.valueOf(amendContracts.startDate) + 15;
            quote.SBQQ__EndDate__c = Date.valueOf(amendContracts.endDate);
            Integer termLengthInMonths = (quote.SBQQ__EndDate__c.year() - quote.SBQQ__StartDate__c.year()) * 12 + (quote.SBQQ__EndDate__c.month() - quote.SBQQ__StartDate__c.month());
            if (quote.SBQQ__EndDate__c.day() > quote.SBQQ__StartDate__c.day()) {
                termLengthInMonths += 1;
            }
            quote.SBQQ__SubscriptionTerm__c = termLengthInMonths;
            if (amendContracts.contractIds != null && amendContracts.contractIds.size() > 0) {
                List<Contract> contracts = [SELECT Id, EndDate, Status, Is_Active__c, Deactivated__c, AccountId FROM Contract WHERE Id IN :amendContracts.contractIds ORDER BY EndDate DESC LIMIT 1];
                if (!contracts.isEmpty()) {
                    quote.Co_Term_Contract__c = contracts[0].Id;
                    System.debug('Enter helper '+ contracts[0].Is_Active__c + ' ' + contracts[0].Status + ' ' + contracts[0].Deactivated__c + ' ' + contracts[0].AccountId);
                }
            } else {
                quote.Co_Term_Contract__c = amendContracts.contractIds[0];
            }
        } else {
            quote.SBQQ__StartDate__c = Date.valueOf(amendContracts.startDate);
            quote.SBQQ__SubscriptionTerm__c = amendContracts.termLength;
            System.debug('TTMM End Date '+amendContracts.endDate);
            quote.SBQQ__EndDate__c = Date.valueOf(amendContracts.endDate);
        }
        insert quote;
        System.debug('Enter createReplacementQuote ' + logRecordList);
        return quote;
    }
     /**
     * //GTMS-26834 Creates and inserts SBQQ__QuoteLineGroup__c records for the specified quote and group names.     *
     * @param quoteId           The Id of the SBQQ__Quote__c to associate the groups with.
     * @param quoteGroupNames   A set of group names to create SBQQ__QuoteLineGroup__c records for.
     * @return                  A map from group name to the inserted SBQQ__QuoteLineGroup__c record.
     */
    public static Map<String, SBQQ__QuoteLineGroup__c> createQuoteGroups(String quoteId, Set<String> quoteGroupNames) {
        List<SBQQ__QuoteLineGroup__c> quoteGroupsToInsert = new List<SBQQ__QuoteLineGroup__c>();
        Map<String, SBQQ__QuoteLineGroup__c> quoteGroupMap = new Map<String, SBQQ__QuoteLineGroup__c>();
        
        for(String name : quoteGroupNames) {
            SBQQ__QuoteLineGroup__c quoteGroupRecord = new SBQQ__QuoteLineGroup__c();
            quoteGroupRecord.Name = name;
            quoteGroupRecord.SBQQ__Quote__c = quoteId;
            quoteGroupRecord.SBQQ__Number__c = name == FlexConstants__c.getInstance('FlexConstants').Net_New_Products__c ? 1 : (name == FlexConstants__c.getInstance('FlexConstants').Carryover_Products__c ? 2 : 3);    
            quoteGroupsToInsert.add(quoteGroupRecord);
        }        
        insert quoteGroupsToInsert;
        
        if(!quoteGroupsToInsert.isEmpty()) {
            for(SBQQ__QuoteLineGroup__c quoteGroup : quoteGroupsToInsert) {
                quoteGroupMap.put(quoteGroup.Name, quoteGroup);
            }        	    
        }
        return quoteGroupMap;
    }

    /**
     * Checks if the current user has been assigned a specific Permission Set.
     * @param permissionSetName The API name of the Permission Set to check for assignment.
     * @return Boolean True if the current user has the specified Permission Set assigned, otherwise false.
     */
    @AuraEnabled
    public static Boolean hasPermissionSet(String permissionSetName) {
        Id userId = UserInfo.getUserId();
        
        // Query for the assignment - returns empty list if not found
        List<PermissionSetAssignment> assignments = [
            SELECT Id 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userId 
            AND PermissionSet.Name = :permissionSetName
            LIMIT 1
        ];
        
        // If the list has any elements, the permission set is assigned
        return !assignments.isEmpty();
    }

    /**
     * Retrieves contracts associated with failed Flex_Log__c records for a given Account record,
     * grouping the results by Log Group Id.     *
     * @param recordId The Id of the Account record for which to retrieve failed contract logs.
     */
    @AuraEnabled
    public static Map<String, List<Map<String, Object>>> getContractsGroupedByLogGroup(Id recordId) {
        List<Flex_Log__c> failedLogs = [
            SELECT Id, Log_Group_Id__c, ContractId__c, Name, CreatedDate, Status__c
            FROM Flex_Log__c 
            WHERE AccountId__c = :recordId 
            AND Status__c = 'Failed' 
            AND Log_Group_Id__c != null 
            AND ContractId__c != null
        ];

        Set<Id> contractIds = new Set<Id>();
        for (Flex_Log__c log : failedLogs) {
            if (log.ContractId__c != null) {
                contractIds.add(log.ContractId__c);
            }
        }

        Map<Id, Contract> contractMap = new Map<Id, Contract>(
            [SELECT Id, ContractNumber, AccountId, StartDate, EndDate 
            FROM Contract 
            WHERE Id IN :contractIds]
        );

        Map<String, List<Map<String, Object>>> result = new Map<String, List<Map<String, Object>>>();

        for (Flex_Log__c log : failedLogs) {
            if (!contractMap.containsKey(log.ContractId__c)) continue;

            String groupId = log.Log_Group_Id__c;
            Contract c = contractMap.get(log.ContractId__c);

            Map<String, Object> contractEntry = new Map<String, Object>();
            contractEntry.put('Id', c.Id);
            contractEntry.put('ContractNumber', c.ContractNumber);
            contractEntry.put('AccountId', c.AccountId);
            contractEntry.put('StartDate', c.StartDate);
            contractEntry.put('EndDate', c.EndDate);
            contractEntry.put('LogName', log.Name);
            contractEntry.put('Status', log.Status__c);
            contractEntry.put('LastInitiatedDate', log.CreatedDate);

            if (!result.containsKey(groupId)) {
                result.put(groupId, new List<Map<String, Object>>());
            }

            result.get(groupId).add(contractEntry);
        }

        return result;
    }    
    
    /**
     * Re-initiates the amendment process by retrieving and deserializing contract amendment data.
     *
     * This method fetches a Flex_Log__c record based on the provided groupId, retrieves the associated
     * ContentDocument, and obtains the latest ContentVersion. It then reads the VersionData (expected to be
     * a JSON string), deserializes it into a FlexAmendContractsMsg object, and returns it.
     *
     * @param groupId The unique identifier for the log group used to locate the Flex_Log__c record.
     */
    @AuraEnabled
    public static FlexAmendContractsMsg reinitiateProcess(String groupId)
    {
        Flex_Log__c logRecord = [SELECT Id, (SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks) 
                                 FROM Flex_Log__c 
                                 WHERE Log_Group_Id__c = :groupId][0];
        
        Id contentDocumentId = logRecord.ContentDocumentLinks[0].ContentDocumentId;
        ContentVersion cv = [SELECT ContentDocumentId, VersionData 
                            FROM ContentVersion 
                            WHERE ContentDocumentId = :contentDocumentId 
                            AND IsLatest = true];
        System.debug('logRecord found : ' + logRecord);                    
        String jsonString = cv.VersionData.toString();
        FlexAmendContractsMsg amendContracts = (FlexAmendContractsMsg)JSON.deserialize(jsonString, FlexAmendContractsMsg.class);
        
        return amendContracts;
    }
    
    /**
     * Creates quote lines for an upgraded/ replacement quote given set of Flex log records.
     *
     * This method retrieves the relevant Flex_Log__c records and associated ContentDocument data,
     * parses the quote line information from the latest ContentVersion, and creates new quote lines
     * for the upgraded products. It also handles the creation of quote line groups and updates the
     * replacement quote if new quote lines are generated.
     *
     * @param params The FlexAmendQueueableParams object containing the list of Flex log record IDs to process.
     */
    public static void createUpgradedQuoteLines(FlexAmendQueueableParams params) {
        List<Flex_Log__c> logList = [
            SELECT Id, Status__c, AmendFutureMethodId__c, ErrorMessage__c, AccountId__c, ContractId__c, RevenueOpportunityId__c, 
                   RevenueQuoteId__c, RevenueQuoteId__r.Flex_Is_Rebook_Quote__c, RevenueQuoteId__r.CurrencyIsoCode, RevenueQuoteId__r.SBQQ__PriceBook__c, RevenueQuoteId__r.SBQQ__SubscriptionTerm__c, 
                   AmendedOpportunityId__c, AmendedQuoteId__c, 
                   (SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks)
            FROM Flex_Log__c 
            WHERE Id IN :params.logRecordList 
            ORDER BY CreatedDate ASC
        ];

        Id contentDocumentId = logList[0].ContentDocumentLinks[0].ContentDocumentId;
        ContentVersion cv = [
            SELECT ContentDocumentId, VersionData 
            FROM ContentVersion 
            WHERE ContentDocumentId = :contentDocumentId AND IsLatest = true
        ];
        String jsonString = cv.VersionData.toString();

        FlexCancelReplaceHelper.bypassTriggers();                
        Map<String, SBQQ__QuoteLineGroup__c> quoteGroups = FlexCancelReplaceHelper.createQuoteGroups(
            logList[0].RevenueQuoteId__c, 
            new Set<String>{
                FlexConstants__c.getInstance('FlexConstants').Net_New_Products__c,
                FlexConstants__c.getInstance('FlexConstants').Carryover_Products__c,
                FlexConstants__c.getInstance('FlexConstants').Upgraded_Products__c
            }
        );
        SBQQQuoteLineTriggerHandler.bypassQuoteLineMethod = true;  
        List<SBQQ__QuoteLine__c> quoteLines = FlexCancelReplaceHelper.createQuoteLines(
            jsonString, 
            logList[0].RevenueQuoteId__r, 
            logList[0].AccountId__c, 
            quoteGroups
        );
        System.debug('quoteLines returned ' + quoteLines);
        if (!quoteLines.isEmpty()) {
            FlexCancelReplaceHelper.updateReplacementQuote(logList[0].RevenueQuoteId__r.Id);
        }
    }
    
    /**
     * Bypasses various trigger handlers and disables SBQQ trigger control.
     */
    public static void bypassTriggers(){
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        SBQQ.TriggerControl.disable();
    }

    /**
     * Creates and inserts SBQQ__QuoteLine__c records based on the provided JSON string and quote details.
     *
     * This method processes a JSON string representing quote line data, determines which products are upgrades or carryovers,
     * and creates corresponding SBQQ__QuoteLine__c records for each scenario. It handles both platform upgrade (PnP) and legacy cases,
     * including hardware upgrades and default hardware associations. The method calculates additional discount amounts for carryover lines
     * and associates each quote line with the appropriate quote line group, quote, and account.
     *
     * @param jsonString   The JSON string containing quote line data, expected to deserialize into FlexAmendContractsMsg.
     * @param quote        The SBQQ__Quote__c record to which the quote lines will be associated.
     * @param accountId    The Id of the Account to associate with the quote lines.
     * @param quoteGroups  A map of group names to SBQQ__QuoteLineGroup__c records, used to group quote lines appropriately.
     * @return             A list of SBQQ__QuoteLine__c records that were created and inserted.
     */
    public static List<SBQQ__QuoteLine__c> createQuoteLines(String jsonString, SBQQ__Quote__c quote, String accountId, Map<String, SBQQ__QuoteLineGroup__c> quoteGroups) {
        FlexAmendContractsMsg amendContracts = (FlexAmendContractsMsg)JSON.deserialize(jsonString, FlexAmendContractsMsg.class);
        List<ProductWrapper> wrappers = amendContracts.quoteLineData;
        System.debug('createQuoteLines input: ' + JSON.serializePretty(wrappers));

        SBQQ__QuoteLineGroup__c upgradeGroup = quoteGroups.get(FlexConstants__c.getInstance('FlexConstants').Upgraded_Products__c);
        SBQQ__QuoteLineGroup__c carryOverGroup = quoteGroups.get(FlexConstants__c.getInstance('FlexConstants').Carryover_Products__c);
        Set<Id> carryOverProductIds = new Set<Id>();
        List<SBQQ__QuoteLine__c> quoteLinesToInsert = new List<SBQQ__QuoteLine__c>();

        // First pass: Collect product IDs
        for (ProductWrapper wrapper : wrappers) {
            if (wrapper.finalScreenDetails != null) {
                for (ProductWrapper.ShipToAddress address : wrapper.finalScreenDetails.shipToAddresses) {
                    if (address.upgradeProduct != null) {
                        if (address.upgradeProduct.upgradeQuantity < address.quantity) {
                            carryOverProductIds.add(wrapper.finalScreenDetails.productId);
                        }
                    } else {
                        carryOverProductIds.add(wrapper.finalScreenDetails.productId);
                    }
                }
            }
        }

        // Query PricebookEntries
        Map<Id, PricebookEntry> productToPbeMap = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id, UnitPrice, CurrencyIsoCode, Pricebook2.IsStandard
            FROM PricebookEntry
            WHERE Product2Id IN :carryOverProductIds
                AND CurrencyIsoCode = :quote.CurrencyIsoCode
                AND IsActive = true
                AND Pricebook2Id = :quote.SBQQ__PriceBook__c
        ]) {
            productToPbeMap.put(pbe.Product2Id, pbe);
        }

        for (ProductWrapper wrapper : wrappers) {
            if (wrapper.finalScreenDetails == null) continue;

            // Handle PnP case
            if (
                wrapper.platformUpgradeScreenDetails != null &&
                !wrapper.platformUpgradeScreenDetails.isEmpty() &&
                wrapper.platformUpgradeScreenDetails[0].selectedUpgradeProduct != null
            ) {
                // Calculate total remaining quantity
                Decimal totalRemainingQty = 0;

                // Check if any hardware upgrades exist
                Boolean hasHardwareUpgrades = false;
                for (ProductWrapper.ShipToAddress address : wrapper.finalScreenDetails.shipToAddresses) {
                    if (address.upgradeProduct != null) {
                        hasHardwareUpgrades = true;
                        // Create upgrade line for finalScreenDetails upgrade product
                        SBQQ__QuoteLine__c upgradeLine = new SBQQ__QuoteLine__c(
                            SBQQ__Group__c = upgradeGroup.Id,
                            SBQQ__Product__c = address.upgradeProduct.productId,
                            SBQQ__Quantity__c = address.upgradeProduct.upgradeQuantity,
                            Ship_To__c = address.addressId,
                            SBQQ__Quote__c = quote.Id,
                            Account__c = accountId,
                            Existing_Product__c = wrapper.originalProductId,
                            SBQQ__PriorQuantity__c = address.upgradeProduct.upgradeQuantity
                        );
                        quoteLinesToInsert.add(upgradeLine);
                        System.debug('address.upgradeProduct.defaultHardwareId' + address.upgradeProduct.defaultHardwareId);
                        if (address.upgradeProduct.defaultHardwareId != 'None' && address.upgradeProduct.defaultHardwareId != null) {
                            SBQQ__QuoteLine__c upgradeLineForDefaultHardware = new SBQQ__QuoteLine__c(
                                SBQQ__Group__c = upgradeGroup.Id,
                                SBQQ__Product__c = address.upgradeProduct.defaultHardwareId,
                                SBQQ__Quantity__c = address.upgradeProduct.upgradeQuantity,
                                Ship_To__c = address.addressId,
                                SBQQ__Quote__c = quote.Id,
                                Account__c = accountId,
                                Existing_Product__c = wrapper.originalProductId,
                                SBQQ__PriorQuantity__c = address.upgradeProduct.upgradeQuantity
                            );
                            quoteLinesToInsert.add(upgradeLineForDefaultHardware);
                        }

                        // Add to total remaining quantity if there are remaining units
                        if (address.upgradeProduct.remainingQuantity != null) {
                            totalRemainingQty += address.upgradeProduct.remainingQuantity;
                        }
                    }
                }

                if (!hasHardwareUpgrades) {
                    // Create single platform upgrade line when no hardware upgrades exist
                    SBQQ__QuoteLine__c platformUpgradeLine = new SBQQ__QuoteLine__c(
                        SBQQ__Group__c = upgradeGroup.Id,
                        SBQQ__Product__c = wrapper.platformUpgradeScreenDetails[0].selectedUpgradeProduct.productId,
                        SBQQ__Quantity__c = wrapper.originalTotalQuantity,
                        Ship_To__c = wrapper.platformUpgradeScreenDetails[0].shippingAddressId,
                        SBQQ__Quote__c = quote.Id,
                        Account__c = accountId,
                        Existing_Product__c = wrapper.originalProductId,
                        SBQQ__PriorQuantity__c = wrapper.originalTotalQuantity
                    );
                    quoteLinesToInsert.add(platformUpgradeLine);
                } else if (totalRemainingQty > 0) {
                    // Create platform upgrade line for remaining quantities when hardware upgrades exist
                    SBQQ__QuoteLine__c platformUpgradeLine = new SBQQ__QuoteLine__c(
                        SBQQ__Group__c = upgradeGroup.Id,
                        SBQQ__Product__c = wrapper.platformUpgradeScreenDetails[0].selectedUpgradeProduct.productId,
                        SBQQ__Quantity__c = totalRemainingQty,
                        Ship_To__c = wrapper.platformUpgradeScreenDetails[0].shippingAddressId,
                        SBQQ__Quote__c = quote.Id,
                        Account__c = accountId,
                        Existing_Product__c = wrapper.originalProductId,
                        SBQQ__PriorQuantity__c = totalRemainingQty
                    );
                    quoteLinesToInsert.add(platformUpgradeLine);
                }
                continue;
            }

            // Handle Legacy case and PnP without platform upgrade
            for (ProductWrapper.ShipToAddress address : wrapper.finalScreenDetails.shipToAddresses) {
                if (address.upgradeProduct != null) {
                    // Create upgrade quote line
                    SBQQ__QuoteLine__c upgradeLine = new SBQQ__QuoteLine__c(
                        SBQQ__Group__c = upgradeGroup.Id,
                        SBQQ__Product__c = address.upgradeProduct.productId,
                        SBQQ__Quantity__c = address.upgradeProduct.upgradeQuantity,
                        Ship_To__c = address.addressId,
                        SBQQ__Quote__c = quote.Id,
                        Account__c = accountId,
                        Existing_Product__c = wrapper.originalProductId,
                        SBQQ__PriorQuantity__c = address.upgradeProduct.upgradeQuantity
                    );
                    quoteLinesToInsert.add(upgradeLine);
                    System.debug(' address.upgradeProduct.defaultHardwareId' + address.upgradeProduct.defaultHardwareId);
                    if (address.upgradeProduct.defaultHardwareId != 'None' && address.upgradeProduct.defaultHardwareId != null) {
                        SBQQ__QuoteLine__c upgradeLineForDefaultHardware = new SBQQ__QuoteLine__c(
                            SBQQ__Group__c = upgradeGroup.Id,
                            SBQQ__Product__c = address.upgradeProduct.defaultHardwareId,
                            SBQQ__Quantity__c = address.upgradeProduct.upgradeQuantity,
                            Ship_To__c = address.addressId,
                            SBQQ__Quote__c = quote.Id,
                            Account__c = accountId,
                            Existing_Product__c = wrapper.originalProductId,
                            SBQQ__PriorQuantity__c = address.upgradeProduct.upgradeQuantity
                        );
                        quoteLinesToInsert.add(upgradeLineForDefaultHardware);
                    }

                    if (address.upgradeProduct.upgradeQuantity < address.quantity) {
                        Decimal remainingQuantity = address.quantity - address.upgradeProduct.upgradeQuantity;

                        // Create carryover line for remaining quantity
                        SBQQ__QuoteLine__c carryOverLine = new SBQQ__QuoteLine__c(
                            SBQQ__Group__c = carryOverGroup.Id,
                            SBQQ__Product__c = wrapper.finalScreenDetails.productId,
                            SBQQ__Quantity__c = remainingQuantity,
                            Ship_To__c = address.addressId,
                            SBQQ__Quote__c = quote.Id,
                            Account__c = accountId,
                            SBQQ__PriorQuantity__c = remainingQuantity
                        );
                        carryOverLine.SBQQ__AdditionalDiscountAmount__c = (productToPbeMap.get(wrapper.finalScreenDetails.productId).UnitPrice * (quote.SBQQ__SubscriptionTerm__c / 12)) - (address.averageMonthlyUnitPrice * quote.SBQQ__SubscriptionTerm__c);
                        quoteLinesToInsert.add(carryOverLine);
                    }
                } else {
                    // Create carryover line for full quantity
                    SBQQ__QuoteLine__c carryOverLine = new SBQQ__QuoteLine__c(
                        SBQQ__Group__c = carryOverGroup.Id,
                        SBQQ__Product__c = wrapper.finalScreenDetails.productId,
                        SBQQ__Quantity__c = address.quantity,
                        Ship_To__c = address.addressId,
                        SBQQ__Quote__c = quote.Id,
                        Account__c = accountId,
                        SBQQ__PriorQuantity__c = address.quantity
                    );
                    carryOverLine.SBQQ__AdditionalDiscountAmount__c = (productToPbeMap.get(wrapper.finalScreenDetails.productId).UnitPrice * (quote.SBQQ__SubscriptionTerm__c / 12)) - (address.averageMonthlyUnitPrice * quote.SBQQ__SubscriptionTerm__c);
                    quoteLinesToInsert.add(carryOverLine);
                }
            }
        }

        if (!quoteLinesToInsert.isEmpty()) {
            insert quoteLinesToInsert;
        }
        return quoteLinesToInsert;
    }

    /**
    * @description - Updates the Amended Opportunity for a given opportunity ID
    * @params - amendedOppId The ID of the opportunity to be updated
    */
    public static Id updateCancellationOpp(Id amendedOppId, Id replacementOppId, Date startDate) {
        Opportunity oppRecord = [SELECT Id, Name, Account.Name, SBQQ__AmendedContract__r.ContractNumber FROM Opportunity WHERE Id = :amendedOppId];
        oppRecord.Name = 'Cancellation - ' + '[' + oppRecord.Account.Name + '] ' + '-[' + oppRecord.SBQQ__AmendedContract__r.ContractNumber + '#]';
        oppRecord.Type = 'Remorse Refund';
        oppRecord.Sub_Type__c = 'Contract Cancellation';
        oppRecord.StageName = 'Return Created';
        oppRecord.Bypass_Validation_Rule_DateTime__c = DateTime.now();
        oppRecord.Swap__c = true;
        oppRecord.RecordTypeId = getRecordTypeIdByDeveloperName('Opportunity', 'Return_Opportunity');
        oppRecord.Upgraded_Opportunity_ID__c = replacementOppId;
        oppRecord.CloseDate = startDate;
        update oppRecord;

        // Create a new Related_Opportunity__c record
        Related_Opportunity__c relatedOpp = new Related_Opportunity__c();
        relatedOpp.Revenue_Opportunity__c = replacementOppId;
        relatedOpp.Cancelation_Opportunity__c = oppRecord.Id;
        insert relatedOpp;

        return relatedOpp.Id;
    }

    /**
    * @description - Update the Cancellation (Amended Quote) with relevant details
    * @params - model The QuoteModel for the amended quote, startDate The start date for the amended quote
    */
    public static QuoteModel updateCancellationQuote(QuoteModel model, Date startDate, Boolean isRebook, Id relatedOppId) {
            model.record.SBQQ__StartDate__c = startDate;
        // Update the Related opportunity field on the quote
        if (relatedOppId != null) {
            model.record.Flex_Related_Opportunity__c = relatedOppId;
        }
        model.record.Flex_Bypass_Validation_Rule_Date_Time__c = DateTime.now();

        for (QuoteLineModel line : model.lineItems) {
            line.record.SBQQ__Quantity__c = 0;
        }
        SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(model));
        return model;
    }
    /**
     * @description -GTMS-26249 Creates a snapshot quote which contain all the original subscriptions
     *  @params - cnrQuoteIds Set of Amended Quote IDs
     * @return ID of the newly created snapshot quote
    */
    @future
    public static void createSnapShotQuote(List<Id> flexLogIds) {
        Set<Id> amendedQuoteIdSet = new Set<Id>();
        Set<Id> revenueOppIdSet = new Set<Id>();
        
        List<Flex_Log__c> flexLogList = [SELECT Id, AmendedQuoteId__c, RevenueOpportunityId__c, snapShotQuoteId__c, ErrorMessage__c FROM Flex_Log__c WHERE Id IN :flexLogIds];
        
        for (Flex_Log__c log : flexLogList) {
            amendedQuoteIdSet.add(log.AmendedQuoteId__c);
            revenueOppIdSet.add(log.RevenueOpportunityId__c);
        }
        
        try {
            // Query the original quotes to get their opportunity references
            List<SBQQ__Quote__c> cnrQuoteList = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE Id IN :amendedQuoteIdSet];
            
            if (!cnrQuoteList.isEmpty()) {
                // Create a new empty quote linked to the Upgraded Opportunity
                SBQQ__Quote__c emptyQuote = new SBQQ__Quote__c();
                Id upgradedOpportunityId = revenueOppIdSet.isEmpty() ? null : revenueOppIdSet.iterator().next();
                emptyQuote.SBQQ__Opportunity2__c = upgradedOpportunityId;
                
                insert emptyQuote;

                // Dynamically get all field names from the QuoteLine object for complete cloning
                Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get('SBQQ__QuoteLine__c');
                Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
                Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();

                // Create a list of all field names
                List<String> reqFields = new List<String>();
                for (String fieldName : fieldsMap.keySet()) {
                    reqFields.add(fieldName);
                }
                
                // Construct and execute a dynamic SOQL query to get all fields from the original quote lines
                String soqlQuery = 'SELECT ' + String.join(reqFields, ',') + ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :cnrQuoteList';
                List<SBQQ__QuoteLine__c> listQL = Database.query(soqlQuery);

                // Clone each quote line and associate it with the new quote
                List<SBQQ__QuoteLine__c> listQLNew = new List<SBQQ__QuoteLine__c>();
                for (SBQQ__QuoteLine__c ql : listQL) {
                    SBQQ__QuoteLine__c newQL = ql.clone();
                    newQL.SBQQ__Quote__c = emptyQuote.Id; // Link to new quote
                    newQL.Previous_Quantity__c = ql.SBQQ__Quantity__c;
                    newQL.SBQQ__Quantity__c = ql.SBQQ__PriorQuantity__c;
                    newQL.SBQQ__PriorQuantity__c = null;
                    listQLNew.add(newQL);
                }
                
                bypassTriggers();
                

                // Insert all cloned quote lines
                insert listQLNew;
                
                
                if (listQLNew.size() > 0) {
                    emptyQuote.Snapshot_Quote__c = true;
                    emptyQuote.Flex_Bypass_Validation_Rule_Date_Time__c = Datetime.now();
                    update emptyQuote;
                }

                if (!flexLogList.isEmpty()) {
                    for (Flex_Log__c log : flexLogList) {
                        log.snapShotQuoteId__c = emptyQuote.Id;
                    }
                    update flexLogList;
                }
            }
        } catch (Exception e) {
            System.debug('PR Error in snapShotQuote: ' + e.getMessage());
            System.debug('PR Stack Trace: ' + e.getStackTraceString());
            handleError(flexLogList, 'Failed in snapShotQuote:', e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString());
        }
    }

    /**
     * @description - Recalculates the snapshot quote by setting the Recalculate_Quote__c flag to true
     * @params - logRecordIds The list of log record IDs to process
     */
    @future
    public static void recalculateSnapshotQuote(Set<Id> logRecordIds) {
        if (logRecordIds == null || logRecordIds.isEmpty()) {
            return;
        }

        try {
            List<Flex_Log__c> logRecords = [SELECT Id, snapShotQuoteId__c FROM Flex_Log__c WHERE Id IN :logRecordIds];

            Set<Id> snapshotQuoteIds = new Set<Id>();
            for (Flex_Log__c log : logRecords) {
                if (log.snapShotQuoteId__c != null) {
                    snapshotQuoteIds.add(log.snapShotQuoteId__c);
                }
            }

            if (!snapshotQuoteIds.isEmpty()) {
                List<SBQQ__Quote__c> snapshotQuotes = [SELECT Id, Recalculate_Quote__c FROM SBQQ__Quote__c WHERE Id IN :snapshotQuoteIds];
                
                List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
                for (SBQQ__Quote__c quote : snapshotQuotes) {
                    if (!quote.Recalculate_Quote__c) {
                        quote.Recalculate_Quote__c = true;
                        quotesToUpdate.add(quote);
                    }
                }

                if (!quotesToUpdate.isEmpty()) {
                    update quotesToUpdate;
                }
            }
        } catch (Exception e) {
            System.debug('PR Error in recalculateSnapshotQuote: ' + e.getMessage());
            System.debug('PR Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }

    @future
    public static void updateReplacementQuote(Id quoteId) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Id = quoteId;
        quote.SBQQ__Primary__c = true;
        update quote;
     }

    /**
    * @description - Retrieves the record type ID for a given object name and record type developer name
    * @params - The name of the object, The developer name of the record type
    * @return - Id Returns the record type ID
    */
    public static Id getRecordTypeIdByDeveloperName(String sObjectType, String developerName) {
        Schema.SObjectType sObjectSchema = Schema.getGlobalDescribe().get(sObjectType); // Get the SObjectType from the string
        Schema.RecordTypeInfo recordTypeInfo = sObjectSchema.getDescribe().getRecordTypeInfosByDeveloperName().get(developerName); // Get the RecordTypeInfo by DeveloperName

        // Return the RecordTypeId
        if (recordTypeInfo != null) {
            return recordTypeInfo.getRecordTypeId();
        } else {
            return null;
        }
    }

    /**
    * @description - Validate if all future jobs have successfully completed
    * @params - queueableJobIdSet The set of Queueable job IDs
    */
    public static String hasFutureJobsCompleted(String className, String methodName, List<Id> queueableJobIdSet) {
        if (queueableJobIdSet == null || queueableJobIdSet.isEmpty()) {
            return 'Success'; // No jobs to check, consider them as completed
        }


        // Get the created date of the first Queueable job
        AsyncApexJob firstQueueableRecord = [SELECT Id, CreatedDate, Status FROM AsyncApexJob WHERE Id = :queueableJobIdSet[0] LIMIT 1];

        // Query all future jobs triggered after the first Queueable job
        futureJobList = [SELECT Id, Status, ExtendedStatus FROM AsyncApexJob WHERE CreatedDate >= :firstQueueableRecord.CreatedDate 
                         AND CreatedById = :UserInfo.getUserId() AND ApexClass.Name = :className 
                         AND MethodName = :methodName AND JobType = 'Future' 
                         ORDER BY CreatedDate ASC];

        Boolean hasInProgress = false;

        for (AsyncApexJob job : futureJobList) {
            if (job.Status == 'Failed' || job.Status == 'Aborted') {
                return 'Fail'; // Stop if any job has failed
            } else if (job.Status == 'Processing' || job.Status == 'Queued') {
                hasInProgress = true; // Track if any job is still in progress
            }
        }

        return hasInProgress ? 'In Progress' : 'Success'; // Return status based on job completion
    }

    /**
    * @description - Update the Log records with future jobs and their status
    * @params - logRecordList The list of log records to update
    */
    public static void updateFutureJobLog(List<Flex_Log__c> logRecordList, Boolean originalAccountFlag, String methodName) {
        try {
            // Extract the IDs from the logRecordList
            Set<Id> logRecordIdSet = new Set<Id>();
            for (Flex_Log__c logRecord : logRecordList) {
                logRecordIdSet.add(logRecord.Id);
            }

            // Query the records based on the extracted IDs
            List<Flex_Log__c> logsToUpdateList = [SELECT Id, Status__c, AmendFutureMethodId__c, RecalculateFutureMethod__c, AmendedOpportunityId__c, AmendedQuoteId__c, RevenueOpportunityId__c, ContractId__c, ErrorMessage__c FROM Flex_Log__c WHERE Id IN :logRecordIdSet ORDER BY CreatedDate ASC];
            System.debug('Enter futureJobList '+ futureJobList);
            System.debug('Updating future job log ' + logRecordList + ' ' + futureJobList);
            for (Integer i = 0; i < logsToUpdateList.size(); i++) {
                System.debug('Enter logsToUpdateList before' + logsToUpdateList[i].ErrorMessage__c);

                System.debug('Enter futureJobList[i].Status ' + futureJobList[i].Status);
                if (logsToUpdateList[i].Status__c != 'Failed') {
                    logsToUpdateList[i].Status__c = futureJobList[i].Status;
                }
                System.debug('Enter updateFutureJobLog ' + logsToUpdateList[i].ErrorMessage__c);
                System.debug('Enter futureJobList[i].ExtendedStatus ' + futureJobList[i].ExtendedStatus);
                if (String.isNotBlank(logsToUpdateList[i].ErrorMessage__c) && String.isNotBlank(futureJobList[i].ExtendedStatus)) {
                    System.debug('Enter logsToUpdateList[i].ErrorMessage__c ' + logsToUpdateList[i].ErrorMessage__c);
                    logsToUpdateList[i].ErrorMessage__c += futureJobList[i].ExtendedStatus;
                    logsToUpdateList[i].Status__c = 'Failed';
                } else if(String.isBlank(logsToUpdateList[i].ErrorMessage__c) && String.isNotBlank(futureJobList[i].ExtendedStatus)){
                    logsToUpdateList[i].Status__c = 'Failed';
                    logsToUpdateList[i].ErrorMessage__c = futureJobList[i].ExtendedStatus;
                }
                if(methodName == 'setQuoteFlag'){
                    logsToUpdateList[i].RecalculateFutureMethod__c = futureJobList[i].Id;
                    break;
                } else {
                    logsToUpdateList[i].AmendFutureMethodId__c = futureJobList[i].Id;
                }                
                System.debug('Enter logsToUpdateList after' + logsToUpdateList[i].ErrorMessage__c);
            }
            System.debug('Enter logsToUpdateList ' + logsToUpdateList);
            update logsToUpdateList;

            // Perform rollback if any log record has Status__c as 'Failed'
            Boolean shouldRollback = false;
            for (Flex_Log__c log : logsToUpdateList) {
                if (log.Status__c == 'Failed') {
                    shouldRollback = true;
                    break;
                }
            }

            if (shouldRollback) {
                performRollback(logsToUpdateList, originalAccountFlag);
            }
            System.debug('Enter logRecordList ' + logRecordList);
        } catch (Exception e) {
            System.debug('Error updating future job log: ' + e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString());
        }
    }

    /**
    * @description - Checks if any log record in the list has a Status__c field set to 'Failed'
    * @params - logRecordList The list of log records to check
    * @return - Boolean Returns true if any log record has Status__c as 'Failed', otherwise false
    */
    public static Boolean hasFailedLogs(List<Flex_Log__c> logRecordList) {
        // Extract the IDs from the logRecordList
        Set<Id> logRecordIdSet = new Set<Id>();
        for (Flex_Log__c logRecord : logRecordList) {
            logRecordIdSet.add(logRecord.Id);
        }
        for (Flex_Log__c logRecord : [SELECT Id, Status__c FROM Flex_Log__c WHERE Id IN :logRecordIdSet]) {
            if (logRecord.Status__c == 'Failed') {
                return true;
            }
        }
        return false;
    }

    /**
    * @description - Updates the log records with the provided error message
    * @params logRecordList - The list of log records to update, The error message to append to the log records
    */
    public static List<Flex_Log__c> handleError(List<Flex_Log__c> logRecordList, String methodName, String errorMessage) {
        System.debug('Enter handleError '+ logRecordList + ' ' + errorMessage);
        if (logRecordList != null && !logRecordList.isEmpty()) {
            for (Flex_Log__c logRecord : logRecordList) {
                if(methodName != 'Failed in snapShotQuote:'){
                logRecord.Status__c = 'Failed';
            }
                if (logRecord.ErrorMessage__c != null) {
                    logRecord.ErrorMessage__c += '\n\n' + methodName + ': ' + errorMessage + '\n\n';
                } else {
                    logRecord.ErrorMessage__c = methodName + ': ' + errorMessage + '\n\n';
                }
            }
        }
        update logRecordList;
        return logRecordList;
        // Send email notification
        // FlexLogNotifier.notifyByEmail(logRecordList);
    }

    /**
    * @description - Sets the primary flag on the quotes associated with the given log records to true
    * @params - logRecordIds The list of log record IDs containing the AmendedQuoteId__c
    */
    @future
    public static void setQuoteFlag(List<Id> logRecordIdList) {
        if (logRecordIdList == null || logRecordIdList.isEmpty()) {
            handleError(new List<Flex_Log__c>(), 'setQuoteFlag', 'No quotes were found to move to primary');
            return;
        }

        List<Flex_Log__c> logRecordList = [SELECT Id, AmendedQuoteId__c, AccountId__c, ContractId__c, ErrorMessage__c FROM Flex_Log__c WHERE Id IN :logRecordIdList];
        try {
            Set<Id> amendedQuoteIdSet = new Set<Id>();
            for (Flex_Log__c log : logRecordList) {
                amendedQuoteIdSet.add(log.AmendedQuoteId__c);
            }

            if (!amendedQuoteIdSet.isEmpty()) {
                // TriggerHandler.bypass('OpportunityTriggerHandler');
                List<SBQQ__Quote__c> quoteList = [SELECT Id, Recalculate_Quote__c, SBQQ__Primary__c FROM SBQQ__Quote__c 
                                                  WHERE Id IN :amendedQuoteIdSet];
                System.debug('Enter quoteList ' + quoteList);
                for (SBQQ__Quote__c quote : quoteList) {
                    quote.Flex_Bypass_Validation_Rule_Date_Time__c = DateTime.now();
                    quote.SBQQ__Primary__c = true;
                }
                update quoteList;
            }
        } catch (Exception e) {
            // Update the log with the error message
            System.debug('Enter handleError setQuoteFlag ' + logRecordList + ' ' + e.getMessage() + 'Stack Trace: ' + e.getStackTraceString());
            handleError(logRecordList, 'Failed in setQuoteFlag: ', e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString());
        }
    }

    /**
    * @description - Updates the Contract_C_R_In_Progress__c field to true for given contract Ids if not already set
    * @params - contractIds The Set of contract Ids to update
    */
    public static void updateCRFlagOnContracts(List<Id> contractIds) {
        List<Contract> contractList = [SELECT Id, Contract_C_R_In_Progress__c FROM Contract WHERE Id IN :contractIds];
        List<Contract> contractsToUpdate = new List<Contract>();
        
        // Check each contract and update flag if not already set
        for(Contract contract : contractList) {
            if(!contract.Contract_C_R_In_Progress__c) {
                contract.Contract_C_R_In_Progress__c = true;
                contractsToUpdate.add(contract);
            }
        }

        if(!contractsToUpdate.isEmpty()) {
            update contractsToUpdate;
        }
    }

    /**
    * @description - Updates the Account_C_R_In_Progress__c field to true for a given account Id if not already set
    * @params - accountId The Id of the account to update
    * @return - String Returns a message indicating the result of the operation
    */
    public static void updateCNRFlagOnAccount(Id accountId, FlexAmendContractsMsg amendContracts) {
        Account acc = [SELECT Id, Account_C_R_In_Progress__c FROM Account WHERE Id = :accountId LIMIT 1];
        amendContracts.originalAccountFlag = acc.Account_C_R_In_Progress__c; // Store original state of the flag
        System.debug('Enter cnr flag ' + acc.Account_C_R_In_Progress__c);
        if (!acc.Account_C_R_In_Progress__c) {
            acc.Account_C_R_In_Progress__c = true;
            update acc;
        }
    }

    /**
    * @description - Updates the Flex_Replacement_Opportunity__c field on the specified contracts with the given opportunity Id
    * @param contractIds - Set of contract Ids to update, Id of the replacement opportunity to link to the contracts
    */
    public static void updateReplacementOpportunityOnContracts(List<String> contractIds, Id replacementOppId) {
        List<Contract> contractsToUpdate = [SELECT Id, Flex_Replacement_Opportunity__c FROM Contract WHERE Id IN :contractIds];
        
        // Update the Flex_Replacement_Opportunity__c field on each contract
        for (Contract contract : contractsToUpdate) {
            contract.Flex_Replacement_Opportunity__c = replacementOppId;
        }
        
        if (!contractsToUpdate.isEmpty()) {
            update contractsToUpdate;
        }
    }

    /**
    * @description - Performs rollback by deleting the related records
    * @params - logRecordList The list of log records to check and delete related records
    */
    public static void performRollback(List<Flex_Log__c> logRecordList, Boolean originalAccountFlag) {
        System.debug('Enter originalAccountFlag performRollback ' + originalAccountFlag);
        Savepoint sp = Database.setSavepoint(); // Set a savepoint
        try {
            Set<Id> amendedOppIdSet = new Set<Id>();
            Set<Id> revenueOppIdSet = new Set<Id>();
            Set<Id> contractIdSet = new Set<Id>();

            for (Flex_Log__c logRecord : logRecordList) {
                if (logRecord.AmendedOpportunityId__c != null) {
                    amendedOppIdSet.add(logRecord.AmendedOpportunityId__c);
                    System.debug('amendedOppIdSet ' + amendedOppIdSet);
                    System.debug('amendedOppIdSet Quote ' + logRecord.AmendedQuoteId__c);
                }
                if (logRecord.RevenueOpportunityId__c != null) {
                    revenueOppIdSet.add(logRecord.RevenueOpportunityId__c);
                    System.debug('revenueOppIdSet ' + revenueOppIdSet);
                    //System.debug('revenueOppIdSet Quote ' + logRecord.RevenueQuoteId__c);
                }
                if (logRecord.ContractId__c != null) {
                    contractIdSet.add(logRecord.ContractId__c);
                    System.debug('contractIdSet ' + contractIdSet);
                }
            }

            // Delete opportunities
            if (!amendedOppIdSet.isEmpty()) {
                System.debug('amendedOppIdSet not empty ' + [SELECT Id FROM Opportunity WHERE Id IN :amendedOppIdSet]);
                delete [SELECT Id FROM Opportunity WHERE Id IN :amendedOppIdSet];
                System.debug('amendedOppIdSet after delete');
            }
            if (!revenueOppIdSet.isEmpty()) {
                System.debug('revenueOppIdSet not empty ' + [SELECT Id FROM Opportunity WHERE Id IN :revenueOppIdSet]);
                delete [SELECT Id FROM Opportunity WHERE Id IN :revenueOppIdSet];
                System.debug('revenueOppIdSet after delete');
            }

            // Reset the contract level flags and collect account ID
            Id accountId;
            if (!contractIdSet.isEmpty()) {
                List<Contract> contractList = [SELECT Id, AccountId, Flex_Is_Rebook__c, Contract_C_R_In_Progress__c FROM Contract WHERE Id IN :contractIdSet];
                for (Contract contract : contractList) {
                    // Check if the Flex_Is_Rebook__c field is already false, if not set field to false
                    if (contract.Flex_Is_Rebook__c) {
                        contract.Flex_Is_Rebook__c = false;
                    }
                    // Check if the Contract_C_R_In_Progress__c field is already false, if not set field to false
                    if (contract.Contract_C_R_In_Progress__c) {
                        contract.Contract_C_R_In_Progress__c = false;
                    }
                    accountId = contract.AccountId;
                }
                update contractList;
            }

            // Reset the account level flag
            if (accountId != null) {
                Account acc = [SELECT Id, Account_C_R_In_Progress__c FROM Account WHERE Id = :accountId LIMIT 1];
                System.debug('Enter roll back before ' + acc.Account_C_R_In_Progress__c);
                acc.Account_C_R_In_Progress__c = originalAccountFlag;
                update acc;
            }
        } catch (Exception e) {
            // Rollback to the savepoint
            Database.rollback(sp);
            // Update the log with the error message
            handleError(logRecordList, 'Failed in performRollback: ', e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString());
        }
    }


}