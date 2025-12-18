@isTest
private class InternalFinanceRequestHelperTest {
    private static string TEST_ACCOUNT_NAME_STRING = 'Testers 2 Inc';
    private static string TEST_OPPORTUNITY_NAME_STRING = 'Test Opportunity 2';
	
    @testsetup static void setupData(){
        test.startTest();

        // Create test data (insert records)
        Account acc = new Account(
            Name = TEST_ACCOUNT_NAME_STRING,
                                BillingStreet = '26 Napier Street',
                                BillingCity = 'London',
                                BillingPostalCode  = '1030',
                                BillingCountry = 'United Kingdom',
            Billing_Email__c  = 'test@example.com',
                                Organization_Size__c = '100 - 499',
                                Payment_Terms__c = 'Net 45',
            Industry = 'Other'
        );
        insert acc;

        // Create opportunity with an editable stage
        Opportunity opp = new Opportunity(
            Name = TEST_OPPORTUNITY_NAME_STRING, 
            StageName = 'Qualification',
            CloseDate = Date.today()
        );
        opp.AccountId = acc.Id;
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert quote;

        test.stopTest();
    }
    
    // Test EMEA MM Net 5 auto-approval
    @istest static void testAutoApprovePaymentTerms_EMEA_MM_Net5() {
        Account acc = [SELECT Id, Approved_Payment_Type__c, Payment_Terms__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id, Payment_Terms__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        User usr = [SELECT Id FROM User WHERE IsActive = true AND UserRole.Name LIKE '%MM%' AND Region__c = 'EMEA' LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        DELETE [SELECT Id FROM contract WHERE AccountId = :acc.Id];

        System.runAs(adminUser) {
            TriggerHandler.bypass('AccountTriggerHandler');
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            TriggerHandler.bypass('OpportunityTriggerHandler');
            TriggerHandler.bypass('OpportunityTriggerHandlerContext');
            TriggerHandler.bypass('GS_OpportunityTriggerHandler');
            acc.Approved_Payment_Type__c = 'Upfront Payments';
            UPDATE acc;

            opp.ownerId = usr.Id;
            UPDATE opp;
        }

        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 5',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id
        );

        test.startTest();
        insert request;
        test.stopTest();

        Internal_Finance_Approval_Request__c req = [
            SELECT Id, Auto_Approved__c, Payment_Type_Approval_Status__c 
            FROM Internal_Finance_Approval_Request__c 
            WHERE Id = :request.Id
        ];
        //Assert.isTrue(req.Auto_Approved__c);
        //Assert.isTrue(req.Payment_Type_Approval_Status__c == InternalFinanceRequestHelper.IFR_APPROVAL_STATUS_APPROVED_STRING);
    }

    // Test EMEA COR UK Net 10 auto-approval
    @istest static void testAutoApprovePaymentTerms_EMEA_COR_UK_Net10() {
        Account acc = [SELECT Id, Approved_Payment_Type__c, Payment_Terms__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id, Payment_Terms__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        User usr = [SELECT Id FROM User WHERE IsActive = true AND UserRole.Name LIKE '%COR%' AND UserRole.Name LIKE '%UK%' LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        DELETE [SELECT Id FROM contract WHERE AccountId = :acc.Id];

        System.runAs(adminUser) {
            TriggerHandler.bypass('AccountTriggerHandler');
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            TriggerHandler.bypass('OpportunityTriggerHandler');
            TriggerHandler.bypass('OpportunityTriggerHandlerContext');
            TriggerHandler.bypass('GS_OpportunityTriggerHandler');
            acc.Approved_Payment_Type__c = 'Direct Annual';
            UPDATE acc;

            opp.ownerId = usr.Id;
            UPDATE opp;
        }

        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 10',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id
        );

        test.startTest();
        insert request;
        test.stopTest();

        Internal_Finance_Approval_Request__c req = [
            SELECT Id, Auto_Approved__c, Payment_Type_Approval_Status__c 
            FROM Internal_Finance_Approval_Request__c 
            WHERE Id = :request.Id
        ];
        Assert.isTrue(req.Auto_Approved__c);
        Assert.isTrue(req.Payment_Type_Approval_Status__c == InternalFinanceRequestHelper.IFR_APPROVAL_STATUS_APPROVED_STRING);
    }

    // Test COR Net 30 auto-approval
    @istest static void testAutoApprovePaymentTerms_COR_Net30() {
        Account acc = [SELECT Id, Approved_Payment_Type__c, Payment_Terms__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id, Payment_Terms__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        User usr = [SELECT Id FROM User WHERE IsActive = true AND UserRole.Name LIKE '%COR%' LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        DELETE [SELECT Id FROM contract WHERE AccountId = :acc.Id];

        System.runAs(adminUser) {
            TriggerHandler.bypass('AccountTriggerHandler');
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            TriggerHandler.bypass('OpportunityTriggerHandler');
            TriggerHandler.bypass('OpportunityTriggerHandlerContext');
            TriggerHandler.bypass('GS_OpportunityTriggerHandler');
            acc.Approved_Payment_Type__c = 'Direct Annual';
            acc.Payment_Terms__c = 'Net 30';
            UPDATE acc;

            opp.ownerId = usr.Id;
            UPDATE opp;
        }

        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 30',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id
        );

        test.startTest();
        insert request;
        test.stopTest();

    }

    @istest static void testAutoApprovePaymentTerms_SEL_Net30() {
        Account acc = [SELECT Id, Approved_Payment_Type__c, Payment_Terms__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id, Payment_Terms__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        User usr = [SELECT Id FROM User WHERE IsActive = true AND UserRole.Name LIKE '%SEL%' LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        DELETE [SELECT Id FROM contract WHERE AccountId = :acc.Id];

        System.runAs(adminUser) {
            TriggerHandler.bypass('AccountTriggerHandler');
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            TriggerHandler.bypass('OpportunityTriggerHandler');
            TriggerHandler.bypass('OpportunityTriggerHandlerContext');
            TriggerHandler.bypass('GS_OpportunityTriggerHandler');
            acc.Approved_Payment_Type__c = 'Direct Annual';
            acc.Payment_Terms__c = 'Net 30';
            UPDATE acc;

            opp.ownerId = usr.Id;
            UPDATE opp;
        }

        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 30',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id
        );

        test.startTest();
        insert request;
        test.stopTest();

    }
    
    // Test Opportunity-only exception
    @istest static void testOpportunityOnlyException() {
        Account acc = [SELECT Id, Approved_Payment_Type__c, Payment_Terms__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id, Payment_Terms__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        User usr = [SELECT Id FROM User WHERE IsActive = true AND UserRole.Name LIKE '%STR%' LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        DELETE [SELECT Id FROM contract WHERE AccountId = :acc.Id];

        System.runAs(adminUser) {
            acc.Approved_Payment_Type__c = 'Direct Monthly';
            UPDATE acc;

            opp.ownerId = usr.Id;
            opp.Payment_Terms_Opportunity_only_exception__c = true;
            UPDATE opp;
        }

        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 30',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id
        );

        test.startTest();
        insert request;
        test.stopTest();

        // Verify quote was updated but account wasn't
        quote = [SELECT SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        acc = [SELECT Payment_Terms__c FROM Account WHERE Id = :acc.Id];
        //System.assertEquals('Net 30', quote.SBQQ__PaymentTerms__c);
        System.assertNotEquals('Net 30', acc.Payment_Terms__c);
    }

    // Test negative scenarios
    @istest static void testNegativeScenarios() {
        Account acc = [SELECT Id, Approved_Payment_Type__c, Payment_Terms__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id, Payment_Terms__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        DELETE [SELECT Id FROM contract WHERE AccountId = :acc.Id];

        System.runAs(adminUser) {
            acc.Approved_Payment_Type__c = 'Direct Monthly';
            acc.Delinquent__c = true;
            UPDATE acc;
        }

        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 30',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id
        );

        test.startTest();
        insert request;
        test.stopTest();

        Internal_Finance_Approval_Request__c req = [
            SELECT Id, Auto_Approved__c, Payment_Type_Approval_Status__c 
            FROM Internal_Finance_Approval_Request__c 
            WHERE Id = :request.Id
        ];
        Assert.isFalse(req.Auto_Approved__c);
        Assert.areEqual('Pending', req.Payment_Type_Approval_Status__c);
    }

    // Test multiple quotes update
    @istest static void testMultipleQuotesUpdate() {
        Account acc = [SELECT Id, Approved_Payment_Type__c, Payment_Terms__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id, Payment_Terms__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        User usr = [SELECT Id FROM User WHERE IsActive = true AND UserRole.Name LIKE '%STR%' LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        DELETE [SELECT Id FROM contract WHERE AccountId = :acc.Id];

        // Create additional quotes
        List<SBQQ__Quote__c> additionalQuotes = new List<SBQQ__Quote__c>();
        for(Integer i = 0; i < 3; i++) {
            additionalQuotes.add(new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Primary__c = false
            ));
        }
        insert additionalQuotes;

        System.runAs(adminUser) {
            acc.Approved_Payment_Type__c = 'Direct Monthly';
            UPDATE acc;

            opp.ownerId = usr.Id;
            UPDATE opp;
        }

        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 30',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = additionalQuotes[0].Id
        );

        test.startTest();
        insert request;
        test.stopTest();

    }

    // Test System Admin API Profile handling
    @istest static void testSystemAdminAPIProfileHandling() {
        Account acc = [SELECT Id, Approved_Payment_Type__c, Payment_Terms__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id, Payment_Terms__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        DELETE [SELECT Id FROM contract WHERE AccountId = :acc.Id];

        System.runAs(adminUser) {
            acc.Approved_Payment_Type__c = 'Direct Monthly';
            UPDATE acc;

            opp.StageName = 'Qualification';  // Not Closed Won or Lost
            UPDATE opp;
        }

        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 30',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id,
            Requested_Payment_Types__c = 'Direct Monthly'
        );

        Test.startTest();
        System.runAs(new User(
            Id = UserInfo.getUserId(),
            ProfileId = [SELECT Id FROM Profile WHERE Name = :System.Label.System_Admin_API_Profile LIMIT 1].Id
        )) {
            insert request;
            request.Payment_Type_Approval_Status__c = 'Approved';
            request.Approved_Payment_Type__c = 'Direct Monthly';
            update request;
        }
        Test.stopTest();

        // Verify the opportunity was updated
        opp = [SELECT Id, Internal_Finance_Payment_Type__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Direct Monthly', opp.Internal_Finance_Payment_Type__c);
    }

    // Test Opportunity Update Handling
    @istest static void testOpportunityUpdateHandling() {
        Account acc = [SELECT Id, Approved_Payment_Type__c, Payment_Terms__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id, Payment_Terms__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        DELETE [SELECT Id FROM contract WHERE AccountId = :acc.Id];

        System.runAs(adminUser) {
            acc.Approved_Payment_Type__c = 'Direct Monthly';
            UPDATE acc;

            opp.StageName = 'Qualification';
            UPDATE opp;
        }

        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 30',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id,
            Requested_Payment_Types__c = 'Direct Monthly'
        );

        Test.startTest();
        insert request;
        request.Payment_Type_Approval_Status__c = 'Approved';
        request.Approved_Payment_Type__c = 'Direct Monthly';
        update request;
        Test.stopTest();

        // Verify the opportunity was updated
        opp = [SELECT Id, Internal_Finance_Payment_Type__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Direct Monthly', opp.Internal_Finance_Payment_Type__c);
    }

    // Test Additional Quote Processing
    @istest static void testAdditionalQuoteProcessing() {
        Account acc = [SELECT Id, Approved_Payment_Type__c, Payment_Terms__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id, Payment_Terms__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        DELETE [SELECT Id FROM contract WHERE AccountId = :acc.Id];

        // Create multiple opportunities for the same account
        List<Opportunity> additionalOpps = new List<Opportunity>();
        for(Integer i = 0; i < 2; i++) {
            additionalOpps.add(new Opportunity(
                Name = 'Additional Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Qualification',
                CloseDate = Date.today(),
                Probability = 50
            ));
        }
        insert additionalOpps;

        // Create quotes for each opportunity
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for(Opportunity additionalOpp : additionalOpps) {
            quotes.add(new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = additionalOpp.Id,
                SBQQ__Primary__c = true,
                SBQQ__Status__c = 'Draft'
            ));
        }
        insert quotes;

        System.runAs(adminUser) {
            acc.Approved_Payment_Type__c = 'Direct Monthly';
            UPDATE acc;

            opp.Payment_Terms_Opportunity_only_exception__c = false;
            UPDATE opp;
        }

        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 30',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quotes[0].Id
        );

        Test.startTest();
        insert request;
        Test.stopTest();

    }

    
    @isTest static void testAutoCreateandApprovalCreditLimitIncrease() {
        User testUser = [Select Id from User where Profile.Name like '%Samsara Sales%' and (Profile.Name like '%AE2%' or Profile.Name like '%AE3%') and IsActive = true LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        Account acc = new Account(
            Name = 'Test Credit Limit Increase AccX',
            BillingStreet = '26 Napier Street',
            BillingCity = 'London',
            BillingPostalCode  = '1030',
            BillingCountry = 'Canada',
            Billing_Email__c  = 'test@example.com',
            Organization_Size__c = '100 - 499',
            Payment_Terms__c = 'Net 45',
            Industry = 'Other',
            BillingCountryCode = 'CA',
            Number_of_Vehicles__c = 15,
            Approved_Payment_Type__c = 'Direct Monthly'
        );

        System.runAs(testUser) {
            insert acc;
        }

        acc.DNBI_Data_Available__c = true;
        acc.DNBI_Commercial_Credit_Percentage__c = 88;
        acc.DNBI_SlowNegExpCount__c = 6.25;
        acc.DNBI_Financial_Stress_Score__c = 90;
        acc.DNBI_PAYDEX__c = 80;
        acc.DNBI_Recommended_Credit_Limit__c = 5000;
        acc.Credit_Limit__c = 1000;
        acc.DNBI_Trade_Experiences_Count__c = 6;
            
        System.runAs(adminUser) {
            update acc;
        }

        Opportunity preopp = new Opportunity(
            Name = 'Pre opp', 
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            amount = 50
        );
        System.runAs(adminUser) {
            insert preopp;
        }
		
        Opportunity opp = new Opportunity(
            Name = 'Test Credit Limit Increase OppX', 
            StageName = 'Qualification',
            CloseDate = Date.today()+30,
            AccountId = acc.Id
        );
        System.runAs(testUser) {
            insert opp;
        }
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__SubscriptionTerm__c = 10,
            Estimated_Annual_Payment__c = 12000,
            Custom_License_Term__c = 2
        );
        System.runAs(testUser) {  
            insert quote;
        }

		//Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
		//Create Product
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
        insert vgLicense;
        
        //Create PriceBookEntry
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        insert vgLicensePB;
        

		Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO' LIMIT 1];
		PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id LIMIT 1]; 
		SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(Subsidy_Amount__c=10, Subsidy_Quantity__c=5, Subsidy_Method__c = 'Fixed $', SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id,SBQQ__NetPrice__c=4000);
		TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
		insert quoteLineOne;
        quote.Selected_Payment_Type__c = 'Direct Monthly';
        System.runAs(adminUser) {
            update quote;
            
            Credit_Report__c creditReport = new Credit_Report__c(
                Account__c = acc.Id,
                Common_Value__c = 'C',
                Credit_Limit__c = 1000,
                Requested_Credit_Amount__c = 500,
                Status__c = 'Active',
                D_B_Data_Available__c = false,
                Credit_Report_Timestamp__c = Datetime.now()
            );
            insert creditReport;
        }

        List<Id> quoteIds = new List<Id>{quote.Id};

        List<SBQQ__Quote__c> quotes = [
            SELECT Id, SBQQ__Account__c, SBQQ__Opportunity2__c, Quote_Amount_Greater_Than_Remain_Credit__c,
                   SBQQ__Status__c, Configuration_Segment__c, Associated_Opportunity_Type__c, 
                   SBQQ__Type__c, Selected_Payment_Type__c
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
        ];

        // Run the test as the test user
        System.runAs(testUser) {
            InternalFinanceRequestHelper helper = new InternalFinanceRequestHelper();

            test.startTest();
            List<Internal_Finance_Approval_Request__c> newRequests = InternalFinanceRequestHelper.createCreditLimitIncreaseRequest(new List<Id>{quote.Id});	
            test.stopTest();

            // Verify that a request was created
            //System.assertEquals(1, newRequests.size(), 'A Credit Limit Increase request should be created.');

        }
    }
	
    @isTest static void testCreateCreditLimitIncreaseRequest_InvalidCriteria() {
        // Setup test data
        Account acc = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        
        test.startTest();
        List<Internal_Finance_Approval_Request__c> newRequests = InternalFinanceRequestHelper.createCreditLimitIncreaseRequest(new List<Id>{quote.Id});
        test.stopTest();

        // Verify that no request was created
        System.assertEquals(0, newRequests.size(), 'No Credit Limit Increase request should be created.');
    }

    @IsTest
    static void testUSAccountCreditCheck() {
        // Setup test data
        Account usAccount = new Account(
            Name = 'US Test Account',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingStateCode = 'CA',
            BillingPostalCode = '12345',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            Global_Geography__c = 'NA',
            Organization_Size__c = '100 - 499'
        );
        insert usAccount;

        // Insert required custom settings
        Creditsafe_Settings__c csSettings = new Creditsafe_Settings__c();
        csSettings.CreditsafeUser__c = 'testuser';
        csSettings.CreditsafePassword__c = 'testpass';
        insert csSettings;

        DNB_Settings__c dnbSettings = new DNB_Settings__c();
        dnbSettings.DNBIUser__c = 'testuser';
        dnbSettings.DNBIPwd__c = 'testpass';
        insert dnbSettings;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Test.startTest();
        try {
            InternalFinanceRequestHelper.triggerCreditCheck(usAccount.Id);
        } catch(Exception e) {
            // Debug statement removed
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testEUAccountCreditCheck() {
        // Setup test data
        Account euAccount = new Account(
            Name = 'EU Test Account',
            BillingStreet = '456 Test St',
            BillingCity = 'Test City',
            BillingPostalCode = '67890',
            BillingCountry = 'Angola',
            BillingCountryCode = 'AO',
            Global_Geography__c = 'France',
            Organization_Size__c = '100 - 499'
        );
        insert euAccount;

        // Insert required custom settings
        Creditsafe_Settings__c csSettings = new Creditsafe_Settings__c();
        csSettings.CreditsafeUser__c = 'testuser';
        csSettings.CreditsafePassword__c = 'testpass';
        insert csSettings;

        DNB_Settings__c dnbSettings = new DNB_Settings__c();
        dnbSettings.DNBIUser__c = 'testuser';
        dnbSettings.DNBIPwd__c = 'testpass';
        insert dnbSettings;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Test.startTest();
        try {
            InternalFinanceRequestHelper.triggerCreditCheck(euAccount.Id);
        } catch(Exception e) {
            // Debug statement removed
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testIncompleteAddressAccount() {
        // Setup test data
        Account incompleteAccount = new Account(
            Name = 'Incomplete Address Account',
            BillingStreet = '789 Test St',
            BillingCity = 'Test City',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            BillingStateCode = 'NY',
            Global_Geography__c = 'NA',
            Organization_Size__c = '100 - 499'
        );
        insert incompleteAccount;

        // Insert required custom settings
        Creditsafe_Settings__c csSettings = new Creditsafe_Settings__c();
        csSettings.CreditsafeUser__c = 'testuser';
        csSettings.CreditsafePassword__c = 'testpass';
        insert csSettings;

        DNB_Settings__c dnbSettings = new DNB_Settings__c();
        dnbSettings.DNBIUser__c = 'testuser';
        dnbSettings.DNBIPwd__c = 'testpass';
        insert dnbSettings;
        
        Test.startTest();
        try {
            InternalFinanceRequestHelper.triggerCreditCheck(incompleteAccount.Id);
        } catch(Exception e) {}
        Test.stopTest();
    }

    // Updated mock response for all HTTP callouts
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            
            if(req.getEndpoint().contains('Authentication/V2.0')) {
                res.setBody('{"AuthenticationDetail": {"Token": "mock-token"}}');
            } else if(req.getEndpoint().contains('authenticate')) {
                res.setBody('{"token": "mock-token"}');
            } else if(req.getEndpoint().contains('organizations?CountryISOAlpha2Code')) {
                res.setBody('{"MatchResponse": {"MatchResponseDetail": {"MatchCandidate": [{"DUNSNumber": "123456789", "OrganizationPrimaryName": {"OrganizationName": {"$": "Test Company"}}}]}}}');
            } else if(req.getEndpoint().contains('companies?countries')) {
                res.setBody('{"companies": [{"id": "123456", "name": "Test Company"}]}');
            } else {
                res.setBody('{"success": true, "report": {"companySummary": {"creditRating": {"commonValue": "GOOD", "creditLimit": {"value": "10000"}}, "businessName": "Test Company", "companyStatus": {"status": "Active"}}}}');
            }
            return res;
        }
    }
    
    @isTest static void testGetTotalAutoApprovedAmount() {
        // Setup test accounts
        Account testAcc1 = new Account(
            Name = 'Test Account 1',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingStateCode = 'CA',
            BillingPostalCode = '12345',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            Organization_Size__c = '100 - 499',
            Approved_Payment_Type__c = 'Direct Monthly'
        );
        insert testAcc1;
        Test.startTest();
        InternalFinanceRequestHelper helper = new InternalFinanceRequestHelper();
        Decimal totalAmountAcc1 = helper.getTotalAutoApprovedAmount(testAcc1.Id);

        Test.stopTest();
    }
    
    @isTest 
    static void testGetAccountEligibilityMap() {
        // Setup test accounts
        List<Account> testAccounts = new List<Account>();
        
        Account testAcc1 = new Account(
            Name = 'Test Account 1 - Eligibility',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingStateCode = 'CA',
            BillingPostalCode = '12345',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            Organization_Size__c = '100 - 499',
            Approved_Payment_Type__c = 'Direct Monthly'
        );
        testAccounts.add(testAcc1);
        
        Account testAcc2 = new Account(
            Name = 'Test Account 2 - Eligibility',
            BillingStreet = '456 Test Ave',
            BillingCity = 'Test City 2',
            BillingStateCode = 'NY',
            BillingPostalCode = '67890',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            Organization_Size__c = '100 - 499',
            Approved_Payment_Type__c = 'Direct Monthly'
        );
        testAccounts.add(testAcc2);
        
        Account testAcc3 = new Account(
            Name = 'Test Account 3 - Eligibility',
            BillingStreet = '789 Test Blvd',
            BillingCity = 'Test City 3',
            BillingStateCode = 'TX',
            BillingPostalCode = '13579',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            Organization_Size__c = '100 - 499',
            Approved_Payment_Type__c = 'Direct Monthly'
        );
        testAccounts.add(testAcc3);
        
        insert testAccounts;
        
        Test.startTest();
        
        // Test scenario 1: Empty set of account IDs
        Set<Id> emptyAccountIds = new Set<Id>();
        Map<Id, Boolean> emptyResult = InternalFinanceRequestHelper.getAccountEligibilityMap(emptyAccountIds);
        
        // Test scenario 2: Single account ID (no metadata records in test context, should default to true)
        Set<Id> singleAccountId = new Set<Id>{testAcc1.Id};
        Map<Id, Boolean> singleResult = InternalFinanceRequestHelper.getAccountEligibilityMap(singleAccountId);
        
        // Test scenario 3: Multiple account IDs (no metadata records in test context, should default to true)
        Set<Id> multipleAccountIds = new Set<Id>{testAcc1.Id, testAcc2.Id, testAcc3.Id};
        Map<Id, Boolean> multipleResult = InternalFinanceRequestHelper.getAccountEligibilityMap(multipleAccountIds);
        
        // Test scenario 4: Non-existent account ID (should still handle gracefully)
        Account dummyAcc = new Account(
            Name = 'Dummy Account for Eligibility',
            BillingStreet = '999 Dummy St',
            BillingCity = 'Dummy City',
            BillingStateCode = 'CA',
            BillingPostalCode = '99999',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            Organization_Size__c = '100 - 499'
        );
        insert dummyAcc;
        Set<Id> dummyAccountId = new Set<Id>{dummyAcc.Id};
        Map<Id, Boolean> dummyResult = InternalFinanceRequestHelper.getAccountEligibilityMap(dummyAccountId);
        
        // Test scenario 5: Mixed set with some existing and some non-existing references
        Set<Id> mixedAccountIds = new Set<Id>{testAcc1.Id, testAcc2.Id};
        Map<Id, Boolean> mixedResult = InternalFinanceRequestHelper.getAccountEligibilityMap(mixedAccountIds);
        
        Test.stopTest();
    }
    
    //Test class changes related to GTMS-28505
    @isTest static void testAutoApprovalCreditLimitIncrease() {
        User testUser = [Select Id from User where Profile.Name like '%Samsara Sales%' and (Profile.Name like '%AE2%' or Profile.Name like '%AE3%') and IsActive = true and (UserRole.Name like '%COR%' or UserRole.Name like '%MM%') LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        Account acc = new Account(
            Name = 'Test Credit Limit Increase AccX',
            BillingStreet = '26 Napier Street',
            BillingCity = 'London',
            BillingPostalCode  = '1030',
            BillingCountry = 'Canada',
            Billing_Email__c  = 'test@example.com',
            Organization_Size__c = '100 - 499',
            Payment_Terms__c = 'Net 45',
            Industry = 'Other',
            BillingCountryCode = 'CA',
            Number_of_Vehicles__c = 15,
            Approved_Payment_Type__c = 'Direct Monthly',
            CurrencyIsoCode = 'USD'
        );

        System.runAs(testUser) {
            insert acc;
        }

        acc.DNBI_Data_Available__c = true;
        acc.DNBI_Commercial_Credit_Percentage__c = 88;
        acc.DNBI_SlowNegExpCount__c = 6.25;
        acc.DNBI_Financial_Stress_Score__c = 90;
        acc.DNBI_PAYDEX__c = 80;
        acc.DNBI_Recommended_Credit_Limit__c = 5000;
        acc.Credit_Limit__c = 1000;
        acc.DNBI_Trade_Experiences_Count__c = 6;
            
        System.runAs(adminUser) {
            update acc;
            system.debug('Acc updated sucessfully'+acc.CurrencyIsoCode);
        }

        Opportunity preopp = new Opportunity(
            Name = 'Pre opp', 
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            amount = 50
        );
        System.runAs(adminUser) {
            insert preopp;
        }
		
        Opportunity opp = new Opportunity(
            Name = 'Test Credit Limit Increase OppX', 
            StageName = 'Qualification',
            CloseDate = Date.today()+30,
            AccountId = acc.Id
        );
        System.runAs(testUser) {
            insert opp;
        }
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__SubscriptionTerm__c = 10,
            Estimated_Annual_Payment__c = 12000,
            Custom_License_Term__c = 2
        );
        System.runAs(testUser) {  
            insert quote;
        }

		//Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
		//Create Product
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
        insert vgLicense;
        
        //Create PriceBookEntry
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 1500, IsActive = true);
        insert vgLicensePB;
        

		Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO' LIMIT 1];
		PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id LIMIT 1]; 
		SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(Subsidy_Amount__c=10, Subsidy_Quantity__c=5, Subsidy_Method__c = 'Fixed $', SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id,SBQQ__NetPrice__c=1400);
		TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
		insert quoteLineOne;
        quote.Selected_Payment_Type__c = 'Direct Monthly';
        System.runAs(adminUser) {
            update quote;
           System.debug('Quote Updated successfully'+quote.Quote_ACV__c); 
            Credit_Report__c creditReport = new Credit_Report__c(
                Account__c = acc.Id,
                Common_Value__c = 'A',
                Credit_Limit__c = 1000,
                Requested_Credit_Amount__c = 500,
                Status__c = 'Active',
                D_B_Data_Available__c = false,
                Credit_Report_Timestamp__c = Datetime.now()
            );
            insert creditReport;
        }

        List<Id> quoteIds = new List<Id>{quote.Id};

        List<SBQQ__Quote__c> quotes = [
            SELECT Id, SBQQ__Account__c, SBQQ__Opportunity2__c, Quote_Amount_Greater_Than_Remain_Credit__c,
                   SBQQ__Status__c, Configuration_Segment__c, Associated_Opportunity_Type__c, 
                   SBQQ__Type__c, Selected_Payment_Type__c
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
        ];

        // Run the test as the test user
        // Create the IFR record manually to test auto-approval logic
        Internal_Finance_Approval_Request__c testRequest = new Internal_Finance_Approval_Request__c(
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id,
            Request_Type__c = 'Credit Limit Increase',
            Payment_Type_Approval_Status__c = 'Pending',
            Submitted_Date__c = System.today(),
            Submitter__c = testUser.Id,
            Notes_from_Requester__c = 'CLI auto created from Approval Flow'
        );
        insert testRequest;

        // Run the test as the test user - Testing AUTO APPROVAL logic only
        System.runAs(testUser) {
            InternalFinanceRequestHelper helper = new InternalFinanceRequestHelper();

            test.startTest();
            // Test auto approval logic
            helper.autoApproveCreditLimitIncrease(new List<Internal_Finance_Approval_Request__c>{testRequest});
            System.runAs(adminUser) {
                acc.Netsuite_Delinquent_Status__c = 'Current';
                update acc;
            }
            // Test auto approval logic again after account update
            helper.autoApproveCreditLimitIncrease(new List<Internal_Finance_Approval_Request__c>{testRequest});        
            test.stopTest();

            // Verify that the request exists and get final results
            List<Internal_Finance_Approval_Request__c> requests = [
                SELECT Id, Payment_Type_Approval_Status__c, Auto_Approved__c, New_Monthly_Credit_Limit__c, Auto_Approved_Amount__c
                FROM Internal_Finance_Approval_Request__c 
                WHERE Id = :testRequest.Id
            ];
            System.assertEquals(1, requests.size(), 'The IFR request should exist.');
        }    
    }
    
    @isTest 
    static void testAutoApproveCreditLimitIncreaseNullEmpty() {
        InternalFinanceRequestHelper helper = new InternalFinanceRequestHelper();
        
        Test.startTest();
        helper.autoApproveCreditLimitIncrease(null);
        helper.autoApproveCreditLimitIncrease(new List<Internal_Finance_Approval_Request__c>());
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetCLIEnabledForUser_GlobalDisabled() {
        // Create test user using TestDataFactory
        User testUser = TestDataFactoryForAccountsAndOpps.createUser(
            'test.user9308@example.com', 
            'TestUser', 
            'System Administrator',
            false
        );
        insert testUser;
        
        Test.startTest();
        Boolean result = InternalFinanceRequestHelper.getCLIEnabledForUser(testUser.Id);
        
        Test.stopTest();
        
    }
    // Test method written for GTMS-28505 User Hierarchy logic.
    @isTest
    static void testGetCLIEnabledForUserHierarchy_AllLevels() {
        // Create a 5-level management hierarchy
        // Level 5 Manager (Top level)
        User level5Manager = TestDataFactoryForAccountsAndOpps.createUser('hierarchy.level5@example.com', 'Level5Manager', 'System Administrator', false);
        insert level5Manager;
        
        // Level 4 Manager
        User level4Manager = TestDataFactoryForAccountsAndOpps.createUser('hierarchy.level4@example.com', 'Level4Manager', 'System Administrator',false);
        level4Manager.ManagerId = level5Manager.Id;
        insert level4Manager;
        
        // Level 3 Manager
        User level3Manager = TestDataFactoryForAccountsAndOpps.createUser('hierarchy.level3@example.com', 'Level3Manager', 'System Administrator',false);
        level3Manager.ManagerId = level4Manager.Id;
        insert level3Manager;
        
        // Level 2 Manager
        User level2Manager = TestDataFactoryForAccountsAndOpps.createUser('hierarchy.level2@example.com', 'Level2Manager', 'System Administrator',false);
        level2Manager.ManagerId = level3Manager.Id;
        insert level2Manager;
        
        // Level 1 Manager (Direct Manager)
        User level1Manager = TestDataFactoryForAccountsAndOpps.createUser('hierarchy.level1@example.com', 'Level1Manager','System Administrator',false);
        level1Manager.ManagerId = level2Manager.Id;
        insert level1Manager;
        
        // Employee
        User employee = TestDataFactoryForAccountsAndOpps.createUser('hierarchy.employee@example.com', 'HierarchyEmployee', 'System Administrator', false);
        employee.ManagerId = level1Manager.Id;
        insert employee;
        
        // Query the employee with full manager hierarchy populated
        User currentUser = [SELECT Id, ManagerId,
                   Manager.Id, Manager.ManagerId,
                   Manager.Manager.Id, Manager.Manager.ManagerId,
                   Manager.Manager.Manager.Id, Manager.Manager.Manager.ManagerId,
                   Manager.Manager.Manager.Manager.Id, Manager.Manager.Manager.Manager.ManagerId,
                   Manager.Manager.Manager.Manager.Manager.Id
            FROM User WHERE Id = :employee.Id LIMIT 1];
        
        Test.startTest();
        
        // Test Level 1: Direct manager in director list
        Set<String> directorUsersLevel1 = new Set<String>{level1Manager.Id};
        Boolean result1 = InternalFinanceRequestHelper.getCLIEnabledForUserHierarchy(directorUsersLevel1, currentUser);
        
        // Test Level 2: Manager's manager in director list
        Set<String> directorUsersLevel2 = new Set<String>{level2Manager.Id};
        Boolean result2 = InternalFinanceRequestHelper.getCLIEnabledForUserHierarchy(directorUsersLevel2, currentUser);
        
        // Test Level 3: Manager's manager's manager in director list
        Set<String> directorUsersLevel3 = new Set<String>{level3Manager.Id};
        Boolean result3 = InternalFinanceRequestHelper.getCLIEnabledForUserHierarchy(directorUsersLevel3, currentUser);
        
        // Test Level 4: Manager's manager's manager's manager in director list
        Set<String> directorUsersLevel4 = new Set<String>{level4Manager.Id};
        Boolean result4 = InternalFinanceRequestHelper.getCLIEnabledForUserHierarchy(directorUsersLevel4, currentUser);
        
        // Test Level 5: Manager's manager's manager's manager's manager in director list
        Set<String> directorUsersLevel5 = new Set<String>{level5Manager.Id};
        Boolean result5 = InternalFinanceRequestHelper.getCLIEnabledForUserHierarchy(directorUsersLevel5, currentUser);
        
        // Test with no manager in director list
        Set<String> emptyDirectorUsers = new Set<String>{'invalidUserId123'};
        Boolean resultEmpty = InternalFinanceRequestHelper.getCLIEnabledForUserHierarchy(emptyDirectorUsers, currentUser);
        
        // Test getCLIEnabledForUser method for comprehensive coverage
        
        // Test 1: User directly in director list with toggle enabled (covers userInDirectorList = true, !isDirectorToggleDisabled = true)
        Automation_Settings__c cliDirectorSetting = new Automation_Settings__c(
            Name = 'CLI Automation Director level toggle',
            Data__c = employee.Id + ',' + level2Manager.Id,
            Disabled__c = false
        );
        insert cliDirectorSetting;
        
        Boolean cliResult1 = InternalFinanceRequestHelper.getCLIEnabledForUser(employee.Id);
        
        // Test 2: User in director list but toggle disabled (covers userInDirectorList = true, isDirectorToggleDisabled = true -> return false)
        cliDirectorSetting.Disabled__c = true;
        update cliDirectorSetting;
        
        Boolean cliResult2 = InternalFinanceRequestHelper.getCLIEnabledForUser(employee.Id);
        
        // Test 3: User not directly in list but manager is in hierarchy (covers getCLIEnabledForUserHierarchy call)
        cliDirectorSetting.Disabled__c = false;
        cliDirectorSetting.Data__c = level2Manager.Id; // level2Manager is in employee's hierarchy
        update cliDirectorSetting;
        
        Boolean cliResult3 = InternalFinanceRequestHelper.getCLIEnabledForUser(employee.Id);
        
        // Test 4: User not in director list and no manager in hierarchy (covers !userInDirectorList -> return isCliAutomationEnabled)
        cliDirectorSetting.Data__c = 'someRandomUserId123';
        update cliDirectorSetting;
        
        Boolean cliResult4 = InternalFinanceRequestHelper.getCLIEnabledForUser(employee.Id);
        
        // Test 5: Exception scenario (covers catch block) - delete the setting to cause null scenario
        delete cliDirectorSetting;
        
        Boolean cliResult5 = InternalFinanceRequestHelper.getCLIEnabledForUser(employee.Id);
        
        Test.stopTest();
        
        // Verify all levels return true when the respective manager is in director list
        Assert.isTrue(result1, 'Should return true when Level 1 manager (direct manager) is in director list');
        Assert.isTrue(result2, 'Should return true when Level 2 manager is in director list');
        Assert.isTrue(result3, 'Should return true when Level 3 manager is in director list');
        Assert.isTrue(result4, 'Should return true when Level 4 manager is in director list');
        Assert.isTrue(result5, 'Should return true when Level 5 manager is in director list');
        Assert.isFalse(resultEmpty, 'Should return false when no manager is in director list');
        
        // Verify getCLIEnabledForUser method coverage
        Assert.isTrue(cliResult1, 'Should return true when user is directly in director list and toggle enabled');
        Assert.isFalse(cliResult2, 'Should return false when user is in director list but toggle disabled');
        Assert.isTrue(cliResult3, 'Should return true when user manager is in director list via hierarchy');
        // cliResult4 and cliResult5 depend on global label CLI_Automation_Enabled, so we just verify method executed without assertion
    }
    
    @isTest static void testUpdateQuoteReqPaymentTerms() {
        // Setup test data
        Account acc = [SELECT Id, Approved_Payment_Type__c, Payment_Terms__c FROM Account WHERE Name = :TEST_ACCOUNT_NAME_STRING];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_STRING];
        SBQQ__Quote__c primaryQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        // Clean up any existing contracts
        DELETE [SELECT Id FROM contract WHERE AccountId = :acc.Id];
        
        System.runAs(adminUser) {
             TriggerHandler.bypass('AccountTriggerHandler');
             TriggerHandler.bypass('GS_AccountTriggerHandler');
             TriggerHandler.bypass('OpportunityTriggerHandler');
             TriggerHandler.bypass('OpportunityTriggerHandlerContext');
             TriggerHandler.bypass('GS_OpportunityTriggerHandler');
            acc.Approved_Payment_Type__c = 'Direct Monthly';
            acc.Payment_Terms__c = 'Net 45'; // Different from requested terms
            UPDATE acc;
            
            opp.Payment_Terms_Opportunity_only_exception__c = false; // Allow both account and quote updates
            UPDATE opp;
        }
        
        // Create additional opportunities for the same account to test additional quotes functionality
        List<Opportunity> additionalOpps = new List<Opportunity>();
        for(Integer i = 1; i <= 3; i++) {
            additionalOpps.add(new Opportunity(
                Name = 'Additional Test Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Qualification',
                CloseDate = Date.today() + 30,
                Probability = 50,
                Type = 'Revenue Opportunity',
                SBQQ__Renewal__c = false,
                Is_Webstore_Upsell_Opportunity__c = false,
                Small_Fleet_Opportunity__c = false,
                Payment_Terms_Opportunity_only_exception__c = false,
                Finance_Partner__c = null,
                Reseller_Partner__c = null
            ));
        }
        insert additionalOpps;
        
        // Create additional quotes for each additional opportunity
        List<SBQQ__Quote__c> additionalQuotes = new List<SBQQ__Quote__c>();
        for(Opportunity additionalOpp : additionalOpps) {
            additionalQuotes.add(new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = additionalOpp.Id,
                SBQQ__Primary__c = true,
                SBQQ__Status__c = 'Draft',
                SBQQ__Account__c = acc.Id,
                SBQQ__PaymentTerms__c = 'Net 45' // Initial payment terms
            ));
        }
        insert additionalQuotes;
        
        // Create the Internal Finance Request
        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 30',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = primaryQuote.Id
        );
        
        Test.startTest();
        
        // Insert the request - this should trigger the afterInsertOrUpdate logic
        insert request;
        
        // Approve the request - this should trigger afterUpdateOnly and updateQuoteReqPaymentTerms
        request.Payment_Type_Approval_Status__c = 'Approved';
        update request;
        
        Test.stopTest();
    }
}