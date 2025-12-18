/**********************************************************************
Name: FreeTrialDecisionHandler
=======================================================================
Purpose: This class will contain methods that handles Free Trial Decision logic                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Mar-06        INITIAL DEVELOPMENT FOR GTMS-11881

***********************************************************************/

public class FreeTrialDecisionsHandler {
    
    private static Set<String> currentFTOpptyId = new Set<String>();
    private static Contract conObj = new Contract();
    
    static final String ASYNC_OPERATION_FREE_TRIAL_DECISION = 'FreeTrialDecision';
    
    public class FreeTrialInfo {
        @auraenabled public List<FTProductList> productList {get;set;}
        @auraenabled public String contractId{get;set;}
        @auraenabled public String accountId{get;set;}
        @auraenabled public String opportunityId{get;set;}
        //@auraenabled public String opportunityFTId{get;set;}
        @auraenabled public String opportunityType{get;set;}
        @auraenabled public List<String> opportunityIdFT{get;set;}
        
    }
    public class FTProductList {
        @auraenabled public String Id {get;set;}
        @auraenabled public String productId {get;set;}
        @auraenabled public String opptyName{get;set;}
        @auraenabled public String productName{get;set;}
        @auraenabled public String productCode{get;set;}
        @auraenabled public String serialNumber{get;set;}
        @auraenabled public Double trialQuantity{get;set;}
        @auraenabled public Double buyingQuantity{get;set;}
        @auraenabled public Double remainingQuantity{get;set;}
        @auraenabled public String originalNSOrderId{get;set;}
    }
    
    public class FreeTrialFlowInfo {
        @InvocableVariable public String contractId;
        @InvocableVariable public String accountId;
        @InvocableVariable public String opportunityId;
        @InvocableVariable public String opportunityFTId;
        @InvocableVariable public List<String> opportunityIdFT;
        @InvocableVariable public String opportunityType;
        @InvocableVariable public List<OpportunityLineItem> opptyProducts;
        @InvocableVariable public String productIdListStr;
        @InvocableVariable public List<FTProductList> productList;
        @InvocableVariable public String serialNumberStr;
        @InvocableVariable public String decisionFT;
    }
    
    public class FreeTrialFlowResponse {
        @InvocableVariable public String opportunityLink;
        @InvocableVariable public String returnOpportunityLink;
    }
    
    /**********************************************************************
    Name: createOpportunity
    =======================================================================
    Purpose: handles the logic to create opportunity                                                    
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Mar-06        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    @auraenabled 
    public static void createOpportunity(List<FreeTrialInfo> infoFTDetails) {
        String infoFTDetailsSerialized = JSON.serialize(infoFTDetails);
        createOpportunityFuture(infoFTDetailsSerialized);
    }
    
    @future
    private static void createOpportunityFuture(string infoFTDetailsSerialized) {
        List<FreeTrialInfo> infoFTDetails = (List<FreeTrialInfo>) JSON.deserialize(infoFTDetailsSerialized, List<FreeTrialInfo>.class);
        string opptyId = null;
        Opportunity optyToCreate = new Opportunity();
        List<FTProductList> productListFT = new List<FTProductList>();
        productListFT = infoFTDetails[0].productList;
        optyToCreate.name = 'FT Opportunity';
        optyToCreate.CloseDate = System.today();
        optyToCreate.AccountId = infoFTDetails[0].accountId;
        if ((productListFT != null && productListFT.size()>0) || infoFTDetails[0].opportunityType =='Revenue Opportunity') {
            optyToCreate.Type = 'Revenue Opportunity';
            optyToCreate.StageName = 'Qualified';
        }
        else {
            optyToCreate.Type = 'Free Trial Return';
            optyToCreate.StageName = 'Return Created';
            optyToCreate.Returning_Opportunity__c = infoFTDetails[0].opportunityId;
        }
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert optyToCreate;
        system.debug('RODRIGO optyToCreate ' + optyToCreate.Id);
        
        if (optyToCreate.Type == 'Revenue Opportunity') {
            SBQQ.TriggerControl.disable();
            SBQQ__Quote__c cpqFT = new SBQQ__Quote__c();
            cpqFT.Quote_Name__c = 'FT Quote';
            cpqFT.SBQQ__Opportunity2__c = optyToCreate.Id;
            cpqFT.SBQQ__Account__c = optyToCreate.AccountId;
            //GTMS-11888
            cpqFT.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Free_Trial').getRecordTypeId();
            insert cpqFT;
            List<SBQQ__QuoteLine__c> forInsert = new List<SBQQ__QuoteLine__c>();
            FOR (FTProductList ftProduct : productListFT) {
                SBQQ__QuoteLine__c obj = new SBQQ__QuoteLine__c();
                obj.SBQQ__Quote__c  = cpqFT.Id;
                obj.SBQQ__Product__c  = ftProduct.Id;
                obj.Account__c = cpqFT.SBQQ__Account__c; 
                obj.accountLookupTest__c = cpqFT.SBQQ__Account__c; 
                obj.Ship_To__c  = null;
                if (ftProduct.buyingQuantity != null)
                    obj.SBQQ__Quantity__c  = ftProduct.buyingQuantity;
                forInsert.add(obj);
            }
            if (forInsert != null && forInsert.size()>0) {
                insert forInsert;
            }
            SBQQ.TriggerControl.enable();
        }
        
        notifyUser(optyToCreate.Id, optyToCreate.Name, optyToCreate.Type);
        //return System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + optyToCreate.Id;
    }
    /**********************************************************************
    Name: getProductList
    =======================================================================
    Purpose: handles the logic to return list of product base on contract id                                                      
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Mar-06        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    @auraenabled 
    public static FreeTrialInfo getProductList(Id contractId, string freeTrialDecision) {
        FreeTrialInfo ftInfo = new FreeTrialInfo();
        List<OpportunityLineItem> productList = new List<OpportunityLineItem>();
        List<FTProductList> productListFT = new List<FTProductList>();

        productList = getOpportunityItem(contractId);  
        
        Set<Id> requiredQuoteLineIds = new Set<Id>();
        for (OpportunityLineItem opItem : productList) {
            if(opItem.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__c != null) {
                requiredQuoteLineIds.add(opItem.SBQQ__QuoteLine__c);
            }
            if (opItem.ProductCode.containsIgnoreCase('LIC') || opItem.ProductCode.containsIgnoreCase('BUNDLE')) {
                FTProductList prodFT = new FTProductList();
                prodFT.Id = opItem.Id;
                prodFT.productId = opItem.Product_ID__c ;
                prodFT.opptyName = opItem.Oppty_Name__c;
                prodFT.productName = opItem.Product2.Name;
                prodFT.productCode = opItem.ProductCode;
                prodFT.trialQuantity = opItem.Quantity;
                prodFT.originalNSOrderId = opItem.Opportunity.Netsuite_Id__c;
                prodFT.serialNumber = '';
                if (freeTrialDecision == 'No Buy')
                    prodFT.buyingQuantity = 0;
                else
                    prodFT.buyingQuantity = opItem.Quantity;
                prodFT.remainingQuantity = prodFT.trialQuantity - prodFT.buyingQuantity;
                productListFT.add(prodFT);
            }
        }
        
        for (OpportunityLineItem opItem : productList) {
             if(opItem.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__c == null && !requiredQuoteLineIds.contains(opItem.SBQQ__QuoteLine__c)) {
                FTProductList prodFT = new FTProductList();
                prodFT.Id = opItem.Id;
                prodFT.productId = opItem.Product_ID__c ;
                prodFT.opptyName = opItem.Oppty_Name__c;
                prodFT.productName = opItem.Product2.Name;
                prodFT.productCode = opItem.ProductCode;
                prodFT.trialQuantity = opItem.Quantity;
                prodFT.originalNSOrderId = opItem.Opportunity.Netsuite_Id__c;
                prodFT.serialNumber = '';
                if (freeTrialDecision == 'No Buy')
                    prodFT.buyingQuantity = 0;
                else
                    prodFT.buyingQuantity = opItem.Quantity;
                prodFT.remainingQuantity = prodFT.trialQuantity - prodFT.buyingQuantity;
                productListFT.add(prodFT);
             }
        }
        List<String> listStrings = new List<String>(currentFTOpptyId);
        
        ftInfo.contractId = contractId;
        ftInfo.productList = productListFT;
        ftInfo.accountId = conObj.AccountId;
        ftInfo.opportunityId = conObj.SBQQ__Opportunity__c;
        ftInfo.opportunityIdFT = listStrings;
        return ftInfo;
    }
    
    @testvisible
    private static void notifyUser(string oppyId, string opptyName, string opptyType) 
    {
        // Get the Id for our custom notification type
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Free_Trial_Creation_Notification'];
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        
        // Set the contents for the notification
        notification.setTitle(opptyType + ' Creation Notification');
        notification.setBody(opptyName + ' has been created');
        
        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        //notification.setTargetId(Userinfo.getUserId());
        notification.setTargetId(oppyId);
        // Actually send the notification
        try {
            notification.send(new Set<String> { Userinfo.getUserId() });
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
    
    /**********************************************************************
    Name: createOpportunityIM
    =======================================================================
    Purpose: handles the logic to create opportunity                                                    
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Mar-06        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    @InvocableMethod(label='Create FT Opportunity') 
    public static void createOpportunityIM(List<FreeTrialFlowInfo> infoFTDetails) {
        handleDecision(JSON.serialize(infoFTDetails));
    }
    
    @future(callout=true)
    public static void handleDecision(String infoFTDetails) {
        handleDecision((List<FreeTrialFlowInfo>)JSON.deserialize(infoFTDetails, List<FreeTrialFlowInfo>.class));
    }
    
    public static void handleDecision(List<FreeTrialFlowInfo> infoFTDetails) {
        Savepoint sp = Database.setSavepoint();
        try {
            Set<String> netsuiteIds = new Set<String>();
            Set<String> serialNumbers = new Set<String>();
            
            Opportunity currentOpportunity = new Opportunity();
            List<Opportunity> amendedOpportunities = new List<Opportunity>();
            List<Opportunity> allOpportunities = new List<Opportunity>();
    
            Boolean isPartialBuy = String.isNotBlank(infoFTDetails[0].productIdListStr);
    
            String shipToAddress = null;
            Id priceBook = null;
            Opportunity originalRevOpp = null;
            String oppCurrency = null; 
            String returnNumberShipping = null;
            
            List<SBQQ__Quote__c> originalRevQuotes = null;
    
            if (String.isNotBlank(infoFTDetails[0].opportunityId)) {
                currentOpportunity = [SELECT Pricebook2Id, Price_Book_Name__c, Shipping_Address_NEW__c, Netsuite_Id__c, TrialResolutionOppty__c, CurrencyIsoCode, Return_Number_Shipping__c, 
              		All_Serial_Numbers__c, FT_Conversion_Netsuite_Id__c, FT_Return__c from Opportunity WHERE Id =: infoFTDetails[0].opportunityId];
            }
            else {
                currentOpportunity = [SELECT Pricebook2Id, Price_Book_Name__c, Shipping_Address_NEW__c, Netsuite_Id__c, TrialResolutionOppty__c, CurrencyIsoCode, Return_Number_Shipping__c, 
         			All_Serial_Numbers__c, FT_Conversion_Netsuite_Id__c, FT_Return__c from Opportunity WHERE Id =: infoFTDetails[0].opportunityFTId];
            }
            
            amendedOpportunities = [SELECT Id, FT_Conversion_Serial_No__c, FT_Conversion_Netsuite_Id__c, All_Serial_Numbers__c, TrialResolutionOppty__c, FT_Return__c FROM Opportunity 
   				WHERE SBQQ__AmendedContract__c =:infoFTDetails[0].contractId];
            allOpportunities.addAll(amendedOpportunities);
    
            shipToAddress = currentOpportunity.Shipping_Address_NEW__c;
            priceBook = currentOpportunity.Pricebook2Id;
            oppCurrency = currentOpportunity.CurrencyIsoCode;
            returnNumberShipping = currentOpportunity.Return_Number_Shipping__c;
            
            if(currentOpportunity.TrialResolutionOppty__c != null){
                originalRevOpp = [SELECT Id, Name, SBQQ__AmendedContract__c FROM Opportunity WHERE Id =:currentOpportunity.TrialResolutionOppty__c];
                originalRevQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =: originalRevOpp.Id ORDER BY SBQQ__Primary__c DESC, CreatedDate DESC];
            }
            
            if(String.isNotBlank(currentOpportunity.FT_Conversion_Netsuite_Id__c)) {
                netsuiteIds = new Set<String>(currentOpportunity.FT_Conversion_Netsuite_Id__c.split(','));
            }
            if(String.isNotBlank(currentOpportunity.All_Serial_Numbers__c)) {
                serialNumbers = new Set<String>(currentOpportunity.All_Serial_Numbers__c.split(','));
            }
         
            // STAGE - INITIALIZE OPPORTUNITY
            List<Opportunity> opportunities = new List<Opportunity>();
            Opportunity revenueOpportunity = new Opportunity();
            Opportunity returnOpportunity = new Opportunity();
            String currentOpptyId = infoFTDetails[0].opportunityId;
            
            if (infoFTDetails[0].opportunityType == 'Revenue Opportunity') {
                revenueOpportunity.CloseDate = System.today();
                revenueOpportunity.AccountId = infoFTDetails[0].accountId;
                revenueOpportunity.Shipping_Address_NEW__c = shipToAddress;
                revenueOpportunity.Pricebook2Id = priceBook;
                revenueOpportunity.Free_Trial_Purchase__c = isPartialBuy ? 'Partial Buy' : 'Full Buy';
                if(originalRevOpp != null){
                    revenueOpportunity.Id = originalRevOpp.Id;
                    revenueOpportunity.Name = originalRevOpp.Name;
                }else{
                    revenueOpportunity.name = 'FT Revenue Opportunity ' + date.today().format();
                    revenueOpportunity.Type = 'Revenue Opportunity';
                    revenueOpportunity.StageName = 'Qualified';
                    if(isPartialBuy) {
                        revenueOpportunity.FT_Conversion_Serial_No__c = infoFTDetails[0].serialNumberStr;
                        revenueOpportunity.FT_Conversion_Netsuite_Id__c = String.join(new List<String>(netsuiteIds), ',');
                    }
                    revenueOpportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standard_Opportunity').getRecordTypeId();
                    revenueOpportunity.CurrencyIsoCode = oppCurrency;
                }
                opportunities.add(revenueOpportunity);
                allOpportunities.add(revenueOpportunity);
            }
            
            if (infoFTDetails[0].opportunityType == 'Free Trial Return' || isPartialBuy) {
                if(!isPartialBuy) {
                    for(Opportunity amendedOpportunity : amendedOpportunities) {
                        if(String.isNotBlank(amendedOpportunity.FT_Conversion_Netsuite_Id__c)) {
                            netsuiteIds.add(amendedOpportunity.FT_Conversion_Netsuite_Id__c);
                        }
                        
                        if(String.isNotBlank(amendedOpportunity.All_Serial_Numbers__c)) {
                            serialNumbers.addAll(new Set<String>(currentOpportunity.All_Serial_Numbers__c.split(',')));
                        }
                    }
                    returnOpportunity.All_Serial_Numbers__c = String.join(new List<String>(serialNumbers), ',');
                	returnOpportunity.FT_Conversion_Netsuite_Id__c = String.join(new List<String>(netsuiteIds), ',');
                }
                returnOpportunity.CloseDate = System.today();
                returnOpportunity.AccountId = infoFTDetails[0].accountId;
                returnOpportunity.Shipping_Address_NEW__c = shipToAddress;
                returnOpportunity.Pricebook2Id = priceBook;
                if(String.isNotBlank(returnNumberShipping)) {
                    returnOpportunity.Return_Number_Shipping__c = returnNumberShipping;
                }
                returnOpportunity.name = 'FT Return Opportunity ' + date.today().format();
                returnOpportunity.Type = 'Free Trial Return';
                returnOpportunity.StageName = 'Return Created';
                returnOpportunity.Free_Trial_Purchase__c = isPartialBuy ? 'Partial Buy' : 'No Purchase';
                returnOpportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Return_Opportunity').getRecordTypeId();
                returnOpportunity.Returning_Opportunity__c = String.isNotBlank(infoFTDetails[0].opportunityId) ? infoFTDetails[0].opportunityId : infoFTDetails[0].opportunityFTId;
                returnOpportunity.TrialResolutionOppty__c = originalRevOpp != null ? originalRevOpp.Id : null;
                returnOpportunity.Original_FT_NS_Id__c  = currentOpportunity.Netsuite_Id__c;
                returnOpportunity.CurrencyIsoCode = oppCurrency;
                opportunities.add(returnOpportunity);
                allOpportunities.add(returnOpportunity);
            }
            
            // STAGE - INSERT REVENUE/Return OPPORTUNITY
            if (String.isBlank(currentOpptyId)) {
                upsert opportunities;
            }
            
            if(currentOpportunity.TrialResolutionOppty__c == null && infoFTDetails[0].opportunityType == 'Revenue Opportunity') {
                currentOpportunity.TrialResolutionOppty__c = revenueOpportunity.Id;
                setOpportunityLookup(amendedOpportunities, 'TrialResolutionOppty__c', revenueOpportunity.Id);
            }
            if(currentOpportunity.FT_Return__c == null && (infoFTDetails[0].opportunityType == 'Free Trial Return' || isPartialBuy)) {
                currentOpportunity.FT_Return__c = returnOpportunity.Id;
                setOpportunityLookup(amendedOpportunities, 'FT_Return__c', returnOpportunity.Id);
                setOpportunityLookup(amendedOpportunities, 'Returning_Opportunity__c', currentOpportunity.Id);
            }
            allOpportunities.add(currentOpportunity);
    
            List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
            SBQQ__Quote__c cpqFT        = new SBQQ__Quote__c();
            SBQQ__Quote__c cpqFT2 = new SBQQ__Quote__c();
    
            if (infoFTDetails[0].opportunityType == 'Revenue Opportunity') {
                if(originalRevOpp != null) {
                    if(originalRevQuotes != null && !originalRevQuotes.isEmpty()){
                        cpqFT.Id = originalRevQuotes[0].Id;
                    }
                }
                if(originalRevQuotes == null || originalRevQuotes != null && originalRevQuotes.isEmpty()) {
                    if(originalRevOpp != null && originalRevOpp.SBQQ__AmendedContract__c != null) {
                        cpqFT.SBQQ__MasterContract__c = originalRevOpp.SBQQ__AmendedContract__c;
                    	cpqFT.SBQQ__Type__c = 'Amendment';
                    }
                    cpqFt.SBQQ__SalesRep__c     = UserInfo.getUserId();
                    cpqFT.Quote_Name__c         = 'FT Quote ' + date.today().format();
                    cpqFT.SBQQ__PriceBook__c    = priceBook;
                    cpqFT.SBQQ__PricebookId__c  = priceBook;
                    cpqFT.SBQQ__Opportunity2__c = revenueOpportunity.Id;
                    cpqFT.SBQQ__Account__c      = infoFTDetails[0].accountId;
                    cpqFT.CurrencyIsoCode 		= oppCurrency;
                    //GTMS-11888
                    cpqFT.RecordTypeId          = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Free_Trial').getRecordTypeId();
                }
                quotes.add(cpqFT);
            }
    
            if (infoFTDetails[0].opportunityType == 'Free Trial Return' || isPartialBuy) {
                cpqFT2.Quote_Name__c = 'FT Quote' + date.today().format();
                cpqFT2.SBQQ__SalesRep__c     = UserInfo.getUserId();
                cpqFT2.SBQQ__Opportunity2__c = returnOpportunity.Id;
                cpqFT2.SBQQ__Account__c = infoFTDetails[0].accountId;
                cpqFT2.SBQQ__PriceBook__c = priceBook;
                cpqFT2.SBQQ__PricebookId__c = priceBook;
                cpqFT2.CurrencyIsoCode 		= oppCurrency;
                cpqFT2.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Free_Trial').getRecordTypeId();
                quotes.add(cpqFT2);
            }
    
            SBQQ.TriggerControl.disable();
            upsert quotes;
            SBQQ.TriggerControl.enable();
    
            // STAGE - QUERYING ITEMS
            // get all product items of opportunities - related to the contract
            List<OpportunityLineItem> allContractOptyProdItems = getOpportunityItem(infoFTDetails[0].contractId);
            
            // Build a map based on the "RequiredBy" field, to set the quantities of any other products in the bundle
            Map<String, List<OpportunityLineItem>> requiredByToOLIMap = sortOliIntoList(allContractOptyProdItems);
    
            String shipFromLocation = 'Free Trial';
            if(allContractOptyProdItems[0].SBQQ__QuoteLine__r.Ship_From_Location__c == 'Estafeta '){
                shipFromLocation = 'MX Free Trial';
            }else if(allContractOptyProdItems[0].SBQQ__QuoteLine__r.Ship_From_Location__c == 'VCK'){
                shipFromLocation = 'Free Trial EU';
            }
    
            Map<Id, Id> mapLineId = new Map<Id, Id>();
            for(OpportunityLineItem recOli : allContractOptyProdItems) {
                mapLineId.put(recOli.Id, recOli.Line_Item_ID__c);
            }
    
            List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
            List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
            List<Id> freeTrialLineItemIds = new List<Id>();
    
            if (infoFTDetails[0].opportunityType == 'Revenue Opportunity' && !isPartialBuy) {
                for (OpportunityLineItem iterator : allContractOptyProdItems) {
                    SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
                    quoteLine.SBQQ__Quote__c  = cpqFT.Id;
                    quoteLine.SBQQ__Product__c  = iterator.Product2Id;
                    quoteLine.Account__c = cpqFT.SBQQ__Account__c; 
                    quoteLine.Ship_To__c  = shipToAddress;
                    quoteLine.SBQQ__PricebookEntryId__c = iterator.PricebookEntryId;
                    quoteLine.SBQQ__ListPrice__c = iterator.SBQQ__QuoteLine__r.SBQQ__ListPrice__c;
                    if(iterator.ProductCode.containsIgnoreCase('LIC') || (iterator.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c == null && !iterator.ProductCode.containsIgnoreCase('BUNDLE'))) {
                    	quoteLine.SBQQ__ListPrice__c = null;
                    }
                    quoteLine.CurrencyIsoCode = oppCurrency;
                    quoteLine.Original_FT_Oppty_Line_Item_SF_Id__c = (iterator.Line_Item_ID__c == null) ? mapLineId.get(iterator.Id) : iterator.Line_Item_ID__c;
                    if (iterator.Quantity != null)
                        quoteLine.SBQQ__Quantity__c  = iterator.Quantity;
                    quoteLines.add(quoteLine);
                    freeTrialLineItemIds.add(iterator.Id);
                }
            }
    
            if (infoFTDetails[0].opportunityType == 'Free Trial Return' && !isPartialBuy) {
                for (OpportunityLineItem iterator : allContractOptyProdItems) {
                    if (iterator.Quantity > 0) {
                        OpportunityLineItem oppLineItem = new OpportunityLineItem();
                        oppLineItem.Product2Id = iterator.Product2Id;
                        oppLineItem.Account__c = infoFTDetails[0].accountId;
                        oppLineItem.PricebookEntryId = iterator.PricebookEntryId;
                        oppLineItem.Original_FT_Oppty_Line_Item_SF_Id__c = (iterator.Line_Item_ID__c == null) ? mapLineId.get(iterator.Id) : iterator.Line_Item_ID__c;
                        oppLineItem.Ship_To__c  = shipToAddress;
                        oppLineItem.TotalPrice = 0;
                        oppLineItem.OpportunityId = returnOpportunity.id;
                        oppLineItem.License_Term_Copy__c = returnOpportunity.License_Term__c;
                        oppLineItem.Quantity = iterator.Quantity;
                        oppLineItem.Original_FT_Oppty_Line_Item_SF_Id__c = (iterator.Line_Item_ID__c == null) ? mapLineId.get(iterator.Id) : iterator.Line_Item_ID__c;
                        oppLineItems.add(oppLineItem);
                    }
    
                    SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
                    quoteLine.SBQQ__Quote__c  = cpqFT2.Id;
                    quoteLine.SBQQ__Product__c  = iterator.Product2Id;
                    quoteLine.Account__c = infoFTDetails[0].accountId; 
                    quoteLine.Ship_To__c  = shipToAddress;
                    quoteLine.SBQQ__PricebookEntryId__c = iterator.PricebookEntryId;
                    quoteLine.SBQQ__ListPrice__c = iterator.Line_List_Price__c;
                    quoteLine.SBQQ__CustomerPrice__c = iterator.Line_List_Price__c;
                    quoteLine.SBQQ__NetPrice__c = iterator.Line_List_Price__c;
                    quoteLine.SBQQ__PartnerPrice__c = iterator.Line_List_Price__c;
                    quoteLine.SBQQ__ProratedPrice__c = iterator.Line_List_Price__c;
                    quoteLine.SBQQ__RegularPrice__c = iterator.Line_List_Price__c;
                    quoteLine.CurrencyIsoCode = oppCurrency;
                    quoteLine.Original_FT_Oppty_Line_Item_SF_Id__c = (iterator.Line_Item_ID__c == null) ? mapLineId.get(iterator.Id) : iterator.Line_Item_ID__c;
                    if (iterator.Quantity != null)
                        quoteLine.SBQQ__Quantity__c  = iterator.Quantity;
                    quoteLines.add(quoteLine);
                }
            }
    
            if(isPartialBuy) {
                List<String> selectedLines = infoFTDetails[0].productIdListStr.split(';');
                for(String selectedLine : selectedLines) {
                    if (selectedLine.indexOf('|') > 0) {
                        String lineId = selectedLine.substringBefore('|');
                        Double productQty = Double.valueOf(selectedLine.substringAfter('|'));
                        for (OpportunityLineItem iterator : requiredByToOLIMap.get(lineId)) {
                            if(productQty > 0) {
                                SBQQ__QuoteLine__c revenueQuoteLine = new SBQQ__QuoteLine__c();
                                revenueQuoteLine.SBQQ__Quote__c  = cpqFT.Id;
                                revenueQuoteLine.SBQQ__Product__c  = iterator.Product2Id;
                                revenueQuoteLine.Account__c = infoFTDetails[0].accountId; 
                                revenueQuoteLine.Ship_To__c  = shipToAddress;
                                revenueQuoteLine.SBQQ__PricebookEntryId__c = iterator.PricebookEntryId;
                                revenueQuoteLine.SBQQ__ListPrice__c = iterator.SBQQ__QuoteLine__r.SBQQ__ListPrice__c;
                                revenueQuoteLine.SBQQ__Quantity__c  = iterator.Quantity;
                                if(iterator.ProductCode.containsIgnoreCase('LIC')) {
                                	revenueQuoteLine.SBQQ__Quantity__c  = productQty;    
                                }
                                if(iterator.ProductCode.containsIgnoreCase('LIC') || (iterator.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c == null && !iterator.ProductCode.containsIgnoreCase('BUNDLE'))) {
                                    revenueQuoteLine.SBQQ__ListPrice__c = null;
                                }
                                revenueQuoteLine.Original_FT_Oppty_Line_Item_SF_Id__c = (iterator.Line_Item_ID__c == null) ? mapLineId.get(iterator.Id) : iterator.Line_Item_ID__c;
                                quoteLines.add(revenueQuoteLine);
                                freeTrialLineItemIds.add(iterator.Id);
                            }
    
                            Decimal remainingQty = iterator.Quantity - productQty;
                            if(remainingQty > 0) {
                                SBQQ__QuoteLine__c returnQuoteLine = new SBQQ__QuoteLine__c();
                                returnQuoteLine.SBQQ__Quote__c  = cpqFT2.Id;
                                returnQuoteLine.SBQQ__Product__c  = iterator.Product2Id;
                                returnQuoteLine.Account__c = infoFTDetails[0].accountId; 
                                returnQuoteLine.Ship_To__c  = shipToAddress;
                                returnQuoteLine.SBQQ__PricebookEntryId__c = iterator.PricebookEntryId;
                                returnQuoteLine.SBQQ__ListPrice__c = iterator.Line_List_Price__c;
                                returnQuoteLine.Original_FT_Oppty_Line_Item_SF_Id__c = (iterator.Line_Item_ID__c == null) ? mapLineId.get(iterator.Id) : iterator.Line_Item_ID__c;
                                returnQuoteLine.SBQQ__Quantity__c  = iterator.Quantity - productQty;
                                quoteLines.add(returnQuoteLine);      
                                
                                OpportunityLineItem returnOppLineItem = new OpportunityLineItem();
                                returnOppLineItem.Product2Id = iterator.Product2Id;
                                returnOppLineItem.Account__c = infoFTDetails[0].accountId;
                                returnOppLineItem.PricebookEntryId = iterator.PricebookEntryId;
                                returnOppLineItem.Original_FT_Oppty_Line_Item_SF_Id__c = (iterator.Line_Item_ID__c == null) ? mapLineId.get(iterator.Id) : iterator.Line_Item_ID__c;
                                returnOppLineItem.Ship_To__c  = shipToAddress;
                                returnOppLineItem.OpportunityId = returnOpportunity.id;
                                returnOppLineItem.License_Term_Copy__c = returnOpportunity.License_Term__c;
                                returnOppLineItem.Quantity = iterator.Quantity; 
                                if(iterator.ProductCode.containsIgnoreCase('LIC')) {
                                	returnOppLineItem.Quantity = iterator.Quantity - productQty;    
                                }
                                returnOppLineItem.UnitPrice = (iterator.UnitPrice != null) ? iterator.UnitPrice : 0;
                                returnOppLineItem.Selected_Sales_Price__c = 0;               
                                oppLineItems.add(returnOppLineItem);
                            }                                 
                        }
                    }
                }
            }
    
            SBQQ.TriggerControl.disable();
    
            if(!quoteLines.isEmpty()){
                insert quoteLines;
            }
            if(!oppLineItems.isEmpty()){
                insert oppLineItems;
            }
            
            if(!freeTrialLineItemIds.isEmpty()) {
                revenueOpportunity.Original_FT_Oppty_Line_Item_SF_Ids__c = String.join(freeTrialLineItemIds, ';');
            }
            
            if(!allOpportunities.isEmpty()) {
                update allOpportunities;
            }
            
            SBQQ.TriggerControl.enable();   
            
            // Send Notifications
            for(Opportunity opportunity : [SELECT Id, Name, Type FROM Opportunity WHERE Id IN:opportunities]) {
                notifyUser(opportunity.Id, opportunity.Name, opportunity.Type);
            }
        }
        catch(Exception e) {
            Database.rollback(sp);
            Contract contract = [SELECT Id, Free_Trial_Decision_Taken__c FROM Contract WHERE Id =: infoFTDetails[0].contractId];
            contract.Free_Trial_Decision_Taken__c = false;
            update contract;
        }
    }
    
    private static void setOpportunityLookup(List<Opportunity> opps, String fieldName, Id opportunityId) {
        for(Opportunity opp : opps) {
            opp.put(fieldName, opportunityId);
        }
    }

    public static Map<String, List<OpportunityLineItem>> sortOliIntoList(List<OpportunityLineItem> itemList){
        Map<String, List<OpportunityLineItem>> jointMap = new Map<String, List<OpportunityLineItem>>();
        
        Set<Id> requiredQuoteLineIds = new Set<Id>();
        for (OpportunityLineItem item : itemList){
            if (item.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__c != null){
                List<OpportunityLineItem> oliList = jointMap.get(item.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c);
                if (oliList == null){
                    oliList = new List<OpportunityLineItem>();
                    jointMap.put(item.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c, oliList);
                }
                oliList.add(item);
                requiredQuoteLineIds.add(item.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__c);
            }
        }
        
        // Add standalone
        for (OpportunityLineItem item : itemList) {
            if (item.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__c == null && !requiredQuoteLineIds.contains(item.SBQQ__QuoteLine__c)){
                jointMap.put(item.SBQQ__QuoteLine__c, new List<OpportunityLineItem> {item});
            }
        }

        // Create a Map with the LIC from the component is the pivot ID
        Map<String, List<OpportunityLineItem>> returnMap = new Map<String, List<OpportunityLineItem>>();
        for (String key : jointMap.keySet()){
            List<OpportunityLineItem> tempList = jointMap.get(key);
            if(tempList != null && tempList.size() == 1) {
                returnMap.put(tempList[0].Id, tempList);
            }
            else {
                for (OpportunityLineItem item : tempList){
                    if (item.ProductCode.containsIgnoreCase('LIC')){
                        returnMap.put(item.Id, tempList);
                    }
                }
            }
        }

        return returnMap;
    }
    
    /**********************************************************************
    Name: getOpportunityItem
    =======================================================================
    Purpose: handles the logic to pulling of opportunity items                                                
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-May-05        INITIAL DEVELOPMENT
    
    ***********************************************************************/ 
    public static List<OpportunityLineItem> getOpportunityItem(Id contractId)
    {
        List<OpportunityLineItem> productList = new List<OpportunityLineItem>();
        
        conObj = [SELECT Id, ContractNumber, SBQQ__Opportunity__c, Opportunity_Name__c, Opportunity_Type__c, AccountId   from Contract where Id =: contractId];
        if (conObj.Opportunity_Type__c=='Free Trial Opportunity')
            currentFTOpptyId.add(conObj.SBQQ__Opportunity__c);
        else {
            List<Opportunity> optyInfoList = [SELECT Id FROM Opportunity WHERE TrialResolutionOppty__c =: conObj.SBQQ__Opportunity__c];
            FOR(Opportunity rec : optyInfoList) {
                currentFTOpptyId.add(rec.id);
            }
        }
        
        List<Opportunity> optyInfoRenewed = [SELECT Id FROM Opportunity WHERE SBQQ__AmendedContract__c =: contractId];
        FOR(Opportunity rec : optyInfoRenewed) {
            currentFTOpptyId.add(rec.Id);
        }
        system.debug('currentFTOpptyId ' + currentFTOpptyId);
        
        // get list of contracted opportunity
        
        //
        //system.debug('RODRIGO contractId ' + optyInfo);
        //if (optyInfo == null)
        //    return null;
        
        productList = [SELECT Id, Name, ProductCode, Quantity, Product_ID__c, Product2.Name, Oppty_Name__c, Opportunity.Netsuite_Id__c, Line_List_Price__c, 
                       PricebookEntryId, Line_Item_ID__c, UnitPrice, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.SBQQ__RequiredBy__c, SBQQ__QuoteLine__r.Ship_From_Location__c, 
                       SBQQ__QuoteLine__r.SBQQ__ListPrice__c FROM OpportunityLineItem WHERE OpportunityId =: currentFTOpptyId ];
        system.debug('productList ' + productList);
        return productList;
    }   
}