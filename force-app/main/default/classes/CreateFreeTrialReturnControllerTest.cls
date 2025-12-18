@isTest
private class CreateFreeTrialReturnControllerTest {
    
    private static final String CSV_CONTENT = 'Product Code,Trial Quantity,Buying Quantity\n' +
        'HW-2GB-WIFI-DATA,20,5\n' +
        'HW-2GB-WIFI-DATA-2,30,10';
        
    private static final String CSV_CONTENT_WITH_HYPERLINK = 'Product Code,Trial Quantity,Buying Quantity\n' +
        '=HYPERLINK("https://example.com","HW-2GB-WIFI-DATA"),20,5';

    private static final String CSV_CONTENT_WITH_COMMAS = 'Product Code,Trial Quantity,Buying Quantity\n' +
        '"HW-Agtegra Cooperative - VG/FORMS/AG53/CRGO Trial","123,445",100\n' +
        'HW-2GB-WIFI-DATA-2,"1,000",500';
        
    @TestSetup
    static void makeData() {
        Account testAccount = new Account(
            Name = 'Testers 1 Inc',
            BillingStreet = '26 Napier Street',
            BillingCity = 'London',
            BillingPostalCode = '1030',
            BillingCountry = 'United Kingdom',
            Billing_Email__c = 'test@example.com',
            Organization_Size__c = '100 - 499',
            Industry = 'Other'
        );
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            LastName = 'Test Contact'
        );
        insert testContact;

        // Create trial opportunity
        Opportunity trialOpp = new Opportunity(
            AccountId = testAccount.Id,
            Type = 'Free Trial Opportunity',
            Name = 'Test Trial Opportunity',
            StageName = 'Proposal',
            CloseDate = System.today().addDays(30),
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
            Shipping_Contact__c = testContact.Id,
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard'
        );
        insert trialOpp;

        // Create return opportunity linked to trial
        Opportunity returnOpp = new Opportunity(
            AccountId = testAccount.Id,
            Type = 'Return Opportunity',
            Name = 'Test Return Opportunity',
            StageName = 'Proposal',
            CloseDate = System.today().addDays(30),
            TrialResolutionOppty__c = trialOpp.Id,
            Shipping_Contact__c = testContact.Id,
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard'
        );
        insert returnOpp;

        // Create test products
        List<Product2> products = new List<Product2>{
            new Product2(
                Name = 'Test Product 1',
                ProductCode = 'HW-2GB-WIFI-DATA',
                Family = 'Hardware',
                Product_Type__c = 'License',
                IsActive = true
            ),
            new Product2(
                Name = 'Test Product 2',
                ProductCode = 'HW-2GB-WIFI-DATA-2',
                Family = 'Hardware',
                Product_Type__c = 'License',
                IsActive = true
            ),
            new Product2(
                Name = 'Agtegra Product',
                ProductCode = 'HW-Agtegra Cooperative - VG/FORMS/AG53/CRGO Trial',
                Family = 'Hardware',
                Product_Type__c = 'License',
                IsActive = true
            )
        };
        insert products;

        // Create price book entries
        Id standardPricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        for(Product2 prod : products) {
            pbes.add(new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = prod.Id,
                UnitPrice = 10000,
                IsActive = true
            ));
        }
        insert pbes;
    }

    @isTest
    static void testFullBuyScenario() {
        Opportunity returnOpp = [SELECT Id FROM Opportunity WHERE Type = 'Return Opportunity' LIMIT 1];
        Opportunity trialOpp = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Opportunity' LIMIT 1];
        
        trialOpp.Free_Trial_Purchase__c = 'Full Buy';
        update trialOpp;

        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        Test.startTest();
        
        CreateFreeTrialReturnController.FreeTrialRequest request = new CreateFreeTrialReturnController.FreeTrialRequest();
        request.optyLineItems = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = returnOpp.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 10,
                UnitPrice = 10000
            )
        };
        request.opportunityId = returnOpp.Id;
        
        CreateFreeTrialReturnController.insertOptyLineItem(new List<CreateFreeTrialReturnController.FreeTrialRequest>{request});
        
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :returnOpp.Id],
            'No line items should be created for Full Buy scenario');
    }

    @isTest
    static void testPartialBuyScenario() {
        Opportunity returnOpp = [SELECT Id, TrialResolutionOppty__c FROM Opportunity WHERE Type = 'Return Opportunity' LIMIT 1];
        Opportunity trialOpp = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Opportunity' LIMIT 1];
        
        trialOpp.Free_Trial_Purchase__c = 'Partial Buy';
        update trialOpp;

        createAndLinkCSVFile(trialOpp.Id, CSV_CONTENT);

        // Add debug statements
        System.debug('=== Test Data Setup ===');
        List<Product2> products = [SELECT Id, ProductCode FROM Product2];
        System.debug('Products: ' + products);
        
        List<PricebookEntry> allPbes = [SELECT Id, ProductCode FROM PricebookEntry];
        System.debug('All PricebookEntries: ' + allPbes);
        
        List<PricebookEntry> pbes = [SELECT Id, ProductCode FROM PricebookEntry WHERE ProductCode IN ('HW-2GB-WIFI-DATA', 'HW-2GB-WIFI-DATA-2')];
        System.debug('Filtered PricebookEntries: ' + pbes);
        
        Test.startTest();
        
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
        for(PricebookEntry pbe : pbes) {
            lineItems.add(new OpportunityLineItem(
                OpportunityId = returnOpp.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 10,
                UnitPrice = 10000
            ));
        }
        
        CreateFreeTrialReturnController.FreeTrialRequest request = new CreateFreeTrialReturnController.FreeTrialRequest();
        request.optyLineItems = lineItems;
        request.opportunityId = returnOpp.Id;
        
        CreateFreeTrialReturnController.insertOptyLineItem(new List<CreateFreeTrialReturnController.FreeTrialRequest>{request});
        
        Test.stopTest();

        System.debug('=== Test Results ===');
        List<OpportunityLineItem> resultItems = [
            SELECT Quantity, PricebookEntry.ProductCode 
            FROM OpportunityLineItem 
            WHERE OpportunityId = :returnOpp.Id
            ORDER BY PricebookEntry.ProductCode
        ];
        System.debug('Created OpportunityLineItems: ' + resultItems);
        
        System.assertEquals(2, resultItems.size(), 'Should create two line items');
    }

    @isTest
    static void testPartialBuyWithCommasInNumbers() {
        Opportunity returnOpp = [SELECT Id, TrialResolutionOppty__c FROM Opportunity WHERE Type = 'Return Opportunity' LIMIT 1];
        Opportunity trialOpp = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Opportunity' LIMIT 1];
        
        trialOpp.Free_Trial_Purchase__c = 'Partial Buy';
        update trialOpp;

        createAndLinkCSVFile(trialOpp.Id, CSV_CONTENT_WITH_COMMAS);

        List<PricebookEntry> pbes = [
            SELECT Id, ProductCode 
            FROM PricebookEntry 
            WHERE ProductCode IN ('HW-Agtegra Cooperative - VG/FORMS/AG53/CRGO Trial', 'HW-2GB-WIFI-DATA-2')
        ];
        
        Test.startTest();
        
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
        for(PricebookEntry pbe : pbes) {
            lineItems.add(new OpportunityLineItem(
                OpportunityId = returnOpp.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 10000
            ));
        }
        
        CreateFreeTrialReturnController.FreeTrialRequest request = new CreateFreeTrialReturnController.FreeTrialRequest();
        request.optyLineItems = lineItems;
        request.opportunityId = returnOpp.Id;
        
        CreateFreeTrialReturnController.insertOptyLineItem(new List<CreateFreeTrialReturnController.FreeTrialRequest>{request});
        
        Test.stopTest();

        List<OpportunityLineItem> resultItems = [
            SELECT Quantity, PricebookEntry.ProductCode 
            FROM OpportunityLineItem 
            WHERE OpportunityId = :returnOpp.Id
            ORDER BY PricebookEntry.ProductCode
        ];
        
        System.assertEquals(2, resultItems.size(), 'Should create two line items');
        
        for(OpportunityLineItem oli : resultItems) {
            if(oli.PricebookEntry.ProductCode == 'HW-Agtegra Cooperative - VG/FORMS/AG53/CRGO Trial') {
                System.assertEquals(123345, oli.Quantity, 'Agtegra product should have correct quantity after parsing comma');
            } else if(oli.PricebookEntry.ProductCode == 'HW-2GB-WIFI-DATA-2') {
                System.assertEquals(500, oli.Quantity, 'Second product should have correct quantity');
            }
        }
    }

    @isTest
    static void testPartialBuyWithHyperlink() {
        Opportunity returnOpp = [SELECT Id, TrialResolutionOppty__c FROM Opportunity WHERE Type = 'Return Opportunity' LIMIT 1];
        Opportunity trialOpp = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Opportunity' LIMIT 1];
        
        trialOpp.Free_Trial_Purchase__c = 'Partial Buy';
        update trialOpp;

        createAndLinkCSVFile(trialOpp.Id, CSV_CONTENT_WITH_HYPERLINK);

        PricebookEntry pbe = [
            SELECT Id, ProductCode 
            FROM PricebookEntry 
            WHERE ProductCode = 'HW-2GB-WIFI-DATA' 
            LIMIT 1
        ];
        
        Test.startTest();
        
        CreateFreeTrialReturnController.FreeTrialRequest request = new CreateFreeTrialReturnController.FreeTrialRequest();
        request.optyLineItems = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = returnOpp.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 10,
                UnitPrice = 10000
            )
        };
        request.opportunityId = returnOpp.Id;
        
        CreateFreeTrialReturnController.insertOptyLineItem(new List<CreateFreeTrialReturnController.FreeTrialRequest>{request});
        
        Test.stopTest();

    }

    @isTest
    static void testInvalidRequest() {
        Test.startTest();
        try {
            CreateFreeTrialReturnController.insertOptyLineItem(null);
            System.assert(false, 'Should have thrown an exception');
        } catch(Exception e) {
            System.debug('Actual error message: ' + e.getMessage());
            System.assert(e.getMessage().contains('Error in CreateFreeTrialReturnController'), 
                'Error message should contain expected text. Actual message: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testInvalidCSVFormat() {
        Opportunity returnOpp = [SELECT Id FROM Opportunity WHERE Type = 'Return Opportunity' LIMIT 1];
        Opportunity trialOpp = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Opportunity' LIMIT 1];
        
        trialOpp.Free_Trial_Purchase__c = 'Partial Buy';
        update trialOpp;

        createAndLinkCSVFile(trialOpp.Id, 'Product Code,Buying Quantity\nHW-2GB-WIFI-DATA,5');

        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        Test.startTest();
        try {
            CreateFreeTrialReturnController.FreeTrialRequest request = new CreateFreeTrialReturnController.FreeTrialRequest();
            request.optyLineItems = new List<OpportunityLineItem>{
                new OpportunityLineItem(
                    OpportunityId = returnOpp.Id,
                    PricebookEntryId = pbe.Id,
                    Quantity = 10,
                    UnitPrice = 10000
                )
            };
            request.opportunityId = returnOpp.Id;
            
            CreateFreeTrialReturnController.insertOptyLineItem(new List<CreateFreeTrialReturnController.FreeTrialRequest>{request});
        } catch(CreateFreeTrialReturnController.FreeTrialException e) {
            System.assert(e.getMessage().contains('Invalid CSV format'), 
                'Error message should indicate invalid CSV format');
        }
        Test.stopTest();
    }

    private static void createAndLinkCSVFile(Id opportunityId, String content) {
        System.debug('=== Starting createAndLinkCSVFile ===');
        System.debug('Opportunity ID: ' + opportunityId);
        System.debug('Content: ' + content);
        
        ContentVersion cv = new ContentVersion(
            Title = 'UpdatedOpportunityLineItems.csv',
            PathOnClient = 'UpdatedOpportunityLineItems.csv',
            VersionData = Blob.valueOf(content)
        );
        insert cv;
        System.debug('Created ContentVersion: ' + cv);
        
        // Re-query ContentVersion to get ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        System.debug('Re-queried ContentVersion with ContentDocumentId: ' + cv);
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = opportunityId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        System.debug('Created ContentDocumentLink: ' + cdl);
    }
}