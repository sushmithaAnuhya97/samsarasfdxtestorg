@IsTest
private class BillingProrationAmountQueueableTest {
    @TestSetup
    static void setupTestData() {

        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        newAccount.add(account);
        insert newAccount;
        List<Contact> newContacts = new List<Contact>();
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=account.Id);
        newContacts.add(contact);
        insert newContacts;
        //Create Shipping Address
        List<Shipping_Address__c> shippingAddresses = new  List<Shipping_Address__c>();
        Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                             , Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                             , Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
        shippingAddresses.add(shipTo);
        insert shippingAddresses;
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Billing_360_Transaction__c = true, License_End_Date__c = Date.Today() + 60,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',  Selected_Payment_Type__c ='Direct Annual',
                                                         CloseDate = System.today() + 5, Owner_Role_Copy__c='Industrial',StageName = 'Incubate', Billing_360_Manual_Override__c = 'Yes');
       
        newOpportunities.add(revenueOpportunity);
        Test.startTest();
        insert newOpportunities;
        //List<SBQQ__Quote__c> quoteLst = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c =revenueOpportunity.Id,  Billing_Ann_Date__c= System.today()+ 45, Selected_Payment_Type__c = 'Direct Annual',
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, Buyout_Amount__c = 6.0, Subsidy_Amount__c=3.0,SBQQ__Primary__c = false, License_Term__c = '36', SBQQ__StartDate__c = Date.today());
        insert quote;
        // Create test product
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'LIC-VG-LD', Family = 'Test', Product_Type__c = 'License');
        insert prod;
        
        // Create price book entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        // Create quote line
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = prod.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 100,
            SBQQ__CustomerPrice__c = 90,
            SBQQ__NetPrice__c = 90
        );
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert quoteLine;
        quote.Selected_Payment_Type__c = 'Direct Annual';
        update quote;
        TriggerHandler.clearAllBypasses();
        Test.stoptest();
    }
    
    @IsTest
    static void testSuccessfulCallout() {
        // Get test quote
        SBQQ__Quote__c quote = [SELECT Id,Close_Date__c FROM SBQQ__Quote__c LIMIT 1];
        
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new BillingProrationMockSuccess());
        
        Test.startTest();
        System.enqueueJob(new BillingProrationAmountQueueable(new List<String>{quote.Id}));
        Test.stopTest();
    }
    
     @IsTest
    static void testSuccessfulCallout2() {
        // Get test quote
        SBQQ__Quote__c quote = [SELECT Id,Close_Date__c FROM SBQQ__Quote__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
         Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(120),
                ContractTerm = 12
        );
        insert contract;
        quote.SBQQ__MasterContract__c = contract.Id;
        update quote;
        
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new BillingProrationMockSuccess());
        
        Test.startTest();
        System.enqueueJob(new BillingProrationAmountQueueable(new List<String>{quote.Id}));
        Test.stopTest();
    }
    
    @IsTest
    static void testFailedCallout() {
        // Get test quote
        SBQQ__Quote__c quote = [SELECT Id,Close_Date__c FROM SBQQ__Quote__c LIMIT 1];
        
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new BillingProrationMockError());
        
        Test.startTest();
        System.enqueueJob(new BillingProrationAmountQueueable(new List<String>{quote.Id}, 'CloseDate change'));
        Test.stopTest();
        
        // Verify results
        quote = [SELECT Id, API_Status__c, API_Error_msg__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        System.assertEquals('Error', quote.API_Status__c);
        System.assert(quote.API_Error_msg__c != null);
    }

    @IsTest
    static void billingProrationAmountControllertest() {
        // Get test quote
        SBQQ__Quote__c quote = [SELECT Id,Close_Date__c FROM SBQQ__Quote__c LIMIT 1];       
        Test.startTest();
        // Create wrapper list
        List<BillingProrationAmountController.InputQuoteIdsWrapper> quoteIds = new List<BillingProrationAmountController.InputQuoteIdsWrapper>();
        BillingProrationAmountController.InputQuoteIdsWrapper wrapper = new BillingProrationAmountController.InputQuoteIdsWrapper();
        wrapper.quoteId = quote.Id;
        quoteIds.add(wrapper);
        BillingProrationAmountController.makeCallout(quoteIds);
        Test.stopTest();
    }    
     @IsTest
    static void billingProrationAmountControllertest2() {
        // Get test quote
        SBQQ__Quote__c quote = [SELECT Id,Close_Date__c, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1]; 
        quote.Billing_Ann_Date__c = null;
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        update quote;
        Account acc = [SELECT Id FROM Account LIMIT 1];
        acc.Next_Recurring_Bill_Date__c = Date.Today().addDays(1);
        update acc;
         Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(120),
                ContractTerm = 12,
                SBQQ__Opportunity__c = quote.SBQQ__Opportunity2__c
        );
        insert contract;
        quote.SBQQ__MasterContract__c = contract.Id;
        update quote;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        List<BillingProrationAmountController.InputQuoteIdsWrapper> quoteIds = new List<BillingProrationAmountController.InputQuoteIdsWrapper>();
        BillingProrationAmountController.InputQuoteIdsWrapper wrapper = new BillingProrationAmountController.InputQuoteIdsWrapper();
        wrapper.quoteId = quote.Id;
        quoteIds.add(wrapper);
        BillingProrationAmountController.makeCallout(quoteIds);
        Test.stopTest();
    }  
    
    @IsTest
    static void testretryBillingProration() {
        // Get test quote
        SBQQ__Quote__c quote = [SELECT Id,Close_Date__c FROM SBQQ__Quote__c LIMIT 1]; 
        quote.API_Error_msg__c = 'Test Error';
        quote.Billing_Ann_Date__c = null;
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        update quote;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        BillingProrationAmountController.retryBillingProration(quote.Id);
        BillingProrationAmountController.getPrefixErrorMessage();
        BillingProrationAmountController.getSuffixErrorMessage();
        Test.stopTest();
    } 
    
    @IsTest
    static void testretryBillingProration3() {
        // Get test quote
        SBQQ__Quote__c quote = [SELECT Id,Close_Date__c FROM SBQQ__Quote__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        quote.API_Error_msg__c = 'Test Error';
        quote.Billing_Ann_Date__c = null;
        acc.Next_Recurring_Bill_Date__c = Date.today().adddays(10);
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        update quote;
        
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        BillingProrationAmountController.retryBillingProration(quote.Id);
        BillingProrationAmountController.getPrefixErrorMessage();
        BillingProrationAmountController.getSuffixErrorMessage();
        Test.stopTest();
    }
    
    @IsTest
    static void testStartDateValidationChange() {
        // Get test quote
        SBQQ__Quote__c quote = [SELECT Id,Close_Date__c, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1]; 
        quote.Billing_Ann_Date__c = null;
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        update quote;
        Account acc = [SELECT Id FROM Account LIMIT 1];
        acc.Next_Recurring_Bill_Date__c = Date.Today().addDays(1);
        update acc;
         Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(120),
                ContractTerm = 12,
                SBQQ__Opportunity__c = quote.SBQQ__Opportunity2__c
        );
        insert contract;
        quote.SBQQ__MasterContract__c = contract.Id;
        update quote;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>([SELECT Id,Close_Date__c, Next_Recurring_Bill_Date__c, Billing_Ann_Date__c, SBQQ__Opportunity2__r.Billing_360_Transaction__c, Associated_Opportunity_Type__c,
                                                                        SBQQ__MasterContract__r.SBQQ__Opportunity__r.Billing_360_Transaction__c, SBQQ__MasterContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c, Selected_Payment_Type__c,
                                                                        (SELECT Id, SBQQ__EffectiveQuantity__c, Product_Type__c, Total_Annual_Price__c FROM SBQQ__LineItems__r)
                                                                        FROM SBQQ__Quote__c WHERE Id =: quote.Id]);
        Test.startTest();
        BillingProrationAmountController.handleStartDateChange(quoteMap, new Set<Id>{quote.Id});
        Test.stopTest();
    }
    
    @IsTest
    static void testeligibleForBillingProrationAPICallout() {
        // Get test quote
        SBQQ__Quote__c quote = [SELECT Id,Close_Date__c, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1]; 
        quote.Billing_Ann_Date__c = null;
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        update quote;
        Account acc = [SELECT Id FROM Account LIMIT 1];
        acc.Next_Recurring_Bill_Date__c = Date.Today().addDays(1);
        update acc;
         Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(120),
                ContractTerm = 12,
                SBQQ__Opportunity__c = quote.SBQQ__Opportunity2__c
        );
        insert contract;
        quote.SBQQ__MasterContract__c = contract.Id;
        update quote;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        BillingProrationAmountController.eligibleForBillingProrationAPICallout(new List<String>{quote.Id});
        Test.stopTest();
    }
    
    // Mock success response
    private class BillingProrationMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success":true}');
            return res;
        }
    }
    
    // Mock error response
    private class BillingProrationMockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error":"Test error message"}');
            return res;
        }
    }  
    
   public Class InputQuoteIdsWrapper {
        @InvocableVariable 
        public string quoteId;
    }
}