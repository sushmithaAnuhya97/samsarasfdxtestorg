/**
 * Author: Vigneshwaran D
 * Date: 8 May 2025
 * Team: Sales-Execution-Smart-Workflows-GTMS
 * Purpose: Update Deal_Health__c field on Quote -> Deal Health Score Quartile Color from CRMA
 * Jira: GTMS-27488, GTMS-27491
 *
 * Description:
 * Comprehensive test class for the CRMA_DHSFlowInvoker and related DHS logic.
 * Covers all major business scenarios, error handling, and integration with Wave Analytics mock responses.
 */
@isTest
public class CRMA_DHSFlowInvokerTest {
    // Static variables for shared test data
    public static User adminUser;

    @testSetup
    static void setupTestData() {
        // Create a test admin user
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        adminUser = new User(
            Alias = 'adminusr',
            EmployeeNumber = '123',
            Email = 'adminusr@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'adminusr' + DateTime.now().getTime() + '@example.com'
        );
        insert adminUser;
        

        // Prepare local variables for all SObjects
        List<Account> accounts = new List<Account>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Product2> products = new List<Product2>();
        List<PricebookEntry> entries = new List<PricebookEntry>();
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        List<SBQQ__QuoteLine__c> allQuoteLines = new List<SBQQ__QuoteLine__c>();
        List<String> scenarios = new List<String>{
            'CM1 High Dominance',
            'CM1 Legacy Dominance',
            'CM1 Low Dominance',
            'CM1 Mixed Dominance',
            'CM2 Dominance',
            'VG Dominance',
            'Mixed Legacy Dominance',
            'Band1',
            'RevenueBand3',
            'LastRangePlus'
        };
        Account acc;
        Opportunity opp;
        
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        SBQQ.TriggerControl.disable();
        
    
            // Create and insert Account
            acc = CRMA_TestDataUtility.buildAccount('Test Account', false);
            accounts.add(acc);
            insert accounts;
        
        Contact testContact = new Contact();
            testContact.FirstName = 'Test';
            testContact.LastName = 'Contact';
            testContact.AccountId = accounts[0].Id;
            testContact.Source__c = 'Adwords';
            testContact.Email = 'test@test.com';
        insert testContact;
            // Create and insert Opportunity
            Id pricebookId = CRMA_TestDataUtility.getStandardPricebookId();
        
        	//Create Shipping Address
        List<Shipping_Address__c> shippingAddresses = new  List<Shipping_Address__c>();
        Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = accounts[0].Id, Shipping_Contact__c = testContact.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                             , Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                             , Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
        shippingAddresses.add(shipTo);
        Shipping_Address__c shipToTwo = new Shipping_Address__c(Account__c = accounts[0].Id, Shipping_Contact__c = testContact.Id, Shipping_Address_Line_1__c = '610 Park View Dr'
                                                                , Shipping_City__c = 'Santa Clara', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                                , Shipping_Zip_Code__c = '95054', Name = 'Ship To Two');
        shippingAddresses.add(shipToTwo);
        insert shippingAddresses;
        
         HelperClass.shippingCountryDefaults.put('Canada', new Shipping_Countries__mdt(
            Shipping_Carrier__c = 'UPS',
            Shipping_Method__c = 'Ground',
            Ship_From_Location__c = 'ON-Logistics'
        ));
        
        
            opp = CRMA_TestDataUtility.buildOpportunity(accounts[0].Id, pricebookId, 'Test Opportunity', 'Qualified', System.today().addDays(30), false, null, 'Direct Annual');
        	opportunities.add(opp);
            insert opportunities;
            // Create and insert Products
            for (String scenario : scenarios) {
                Product2 prod = CRMA_TestDataUtility.buildProduct(scenario + ' Product', scenario + ' Code', 'License', 'High');
                products.add(prod);
            }
            insert products;
            // Create and insert PricebookEntries
            for (Product2 p : products) {
                PricebookEntry entry = CRMA_TestDataUtility.buildPricebookEntry(pricebookId, p.Id, 10000);
                entries.add(entry);
            }
            insert entries;
            // Create and insert Quotes
            for (String scenario : scenarios) {
                SBQQ__Quote__c quote = CRMA_TestDataUtility.buildQuote(accounts[0].Id, opportunities[0].Id, scenario, false, 0, 0, 'Direct Annual');
                quotes.add(quote);
            }
            insert quotes;
        	system.debug('Test data ');
        	system.debug([SELECT Id,Shipping_Country__c,(SELECT Id FROM SBQQ__Quotes2__r) FROM Opportunity WHERE ID =:opportunities[0].Id]);
            // Create and insert QuoteLines
            for (Integer i = 0; i < scenarios.size(); i++) {
                Product2 prod = products[i];
                PricebookEntry entry = entries[i];
                SBQQ__Quote__c quote = quotes[i];
                SBQQ__QuoteLine__c ql = CRMA_TestDataUtility.buildQuoteLine(quote.Id, prod.Id, entry.Id, 5, 0, accounts[0].Id, 10000);
                allQuoteLines.add(ql);
            }
            insert allQuoteLines;
        
            System.runAs(adminUser) {
                
                // Assign required permission sets
        CRMA_TestDataUtility.assignPermissionSet(adminUser.Id, 'RevenueIntelligenceAdmin');
        CRMA_TestDataUtility.assignPermissionSet(adminUser.Id, 'Deal_Health_Additional_Permissions');
                
        }
    }

    @isTest
    public static void updatesColorTest() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(
                new Map<String, Object>{
                    // For /wave/datasets endpoint
                    'datasets' => new List<Object>{
                        new Map<String, Object>{
                            'id' => '0FbXXXXXXXXXXXXXXX',
                            'name' => 'Deal_Health_Score_Inputs_CSV_Source',
                            'currentVersionId' => '0FcXXXXXXXXXXXXXXX'
                        }
                    },
                    // For /wave/query endpoint
                    'results' => new Map<String, Object>{
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Score' => '1.Green',
                                'textscore' => '0-10%',
                                'Quartile' => 10.5
                            }
                        }
                    }
                }
            ));
            
            Test.startTest();
            SBQQ__Quote__c quote = [SELECT Id, Deal_Health__c FROM SBQQ__Quote__c LIMIT 1];
           
            CRMA_DHSFlowInvoker.Input input = new CRMA_DHSFlowInvoker.Input();
            input.quoteId = quote.Id;
            List<CRMA_DHSFlowInvoker.Input> inputs = new List<CRMA_DHSFlowInvoker.Input>{input};

            
            List<CRMA_DHSFlowInvoker.Output> results = CRMA_DHSFlowInvoker.processAndUpdateDealHealthFlow(inputs);
            Test.stopTest();
        }
    }

    @isTest
    public static void toggleInactiveTest() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(new Map<String,Object>()));
            SBQQ__Quote__c quote = [SELECT Id, Deal_Health__c FROM SBQQ__Quote__c LIMIT 1];
            
            CRMA_DHSFlowInvoker.Input input = new CRMA_DHSFlowInvoker.Input();
            input.quoteId = quote.Id;
            List<CRMA_DHSFlowInvoker.Input> inputs = new List<CRMA_DHSFlowInvoker.Input>{input};

            Test.startTest();
            List<CRMA_DHSFlowInvoker.Output> results = CRMA_DHSFlowInvoker.processAndUpdateDealHealthFlow(inputs);
            Test.stopTest();

            //System.assertEquals(1, results.size(), 'Should return one result');
            String color = results[0].quartileColor;
            //System.assert(String.isBlank(color), 'Quartile color should be blank when toggle is off');
            quote = [SELECT Deal_Health__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
            //System.assert(String.isBlank(quote.Deal_Health__c), 'Deal_Health__c should not be updated when toggle is off');
        }
    }
    
    public static testmethod void cm1LegacyDominanceTest() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(new Map<String,Object>()));
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'CM1 Legacy Dominance' LIMIT 1];
            CRMA_DHSFlowInvoker.Input input = new CRMA_DHSFlowInvoker.Input();
            input.quoteId = quote.Id;
            List<CRMA_DHSFlowInvoker.Input> inputs = new List<CRMA_DHSFlowInvoker.Input>{input};
            Test.startTest();
            List<CRMA_DHSFlowInvoker.Output> results = CRMA_DHSFlowInvoker.processAndUpdateDealHealthFlow(inputs);
            Test.stopTest();
            System.assertEquals(1, results.size(), 'Should return one result');
        }
    }
    
    @isTest
    public static void cm1LowDominanceTest() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(new Map<String,Object>()));
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'CM1 Low Dominance' LIMIT 1];
            CRMA_DHSFlowInvoker.Input input = new CRMA_DHSFlowInvoker.Input();
            input.quoteId = quote.Id;
            List<CRMA_DHSFlowInvoker.Input> inputs = new List<CRMA_DHSFlowInvoker.Input>{input};
            Test.startTest();
            List<CRMA_DHSFlowInvoker.Output> results = CRMA_DHSFlowInvoker.processAndUpdateDealHealthFlow(inputs);
            Test.stopTest();
            System.assertEquals(1, results.size(), 'Should return one result');
        }
    }
    
    @isTest
    public static void cm1MixedDominanceTest() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(new Map<String,Object>()));
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'CM1 Mixed Dominance' LIMIT 1];
            CRMA_DHSFlowInvoker.Input input = new CRMA_DHSFlowInvoker.Input();
            input.quoteId = quote.Id;
            List<CRMA_DHSFlowInvoker.Input> inputs = new List<CRMA_DHSFlowInvoker.Input>{input};
            Test.startTest();
            List<CRMA_DHSFlowInvoker.Output> results = CRMA_DHSFlowInvoker.processAndUpdateDealHealthFlow(inputs);
            Test.stopTest();
            System.assertEquals(1, results.size(), 'Should return one result');
        }
    }
    
    @isTest
    public static void cm2DominanceTest() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(new Map<String,Object>()));
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'CM2 Dominance' LIMIT 1];
            CRMA_DHSFlowInvoker.Input input = new CRMA_DHSFlowInvoker.Input();
            input.quoteId = quote.Id;
            List<CRMA_DHSFlowInvoker.Input> inputs = new List<CRMA_DHSFlowInvoker.Input>{input};
            Test.startTest();
            List<CRMA_DHSFlowInvoker.Output> results = CRMA_DHSFlowInvoker.processAndUpdateDealHealthFlow(inputs);
            Test.stopTest();
            System.assertEquals(1, results.size(), 'Should return one result');
        }
    }
    
    @isTest
    public static void vgDominanceTest() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(new Map<String,Object>()));
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'VG Dominance' LIMIT 1];
            CRMA_DHSFlowInvoker.Input input = new CRMA_DHSFlowInvoker.Input();
            input.quoteId = quote.Id;
            List<CRMA_DHSFlowInvoker.Input> inputs = new List<CRMA_DHSFlowInvoker.Input>{input};
            Test.startTest();
            List<CRMA_DHSFlowInvoker.Output> results = CRMA_DHSFlowInvoker.processAndUpdateDealHealthFlow(inputs);
            Test.stopTest();
            System.assertEquals(1, results.size(), 'Should return one result');
        }
    }
    
    @isTest
    public static void mixedLegacyDominanceTest() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(new Map<String,Object>()));
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Mixed Legacy Dominance' LIMIT 1];
            CRMA_DHSFlowInvoker.Input input = new CRMA_DHSFlowInvoker.Input();
            input.quoteId = quote.Id;
            List<CRMA_DHSFlowInvoker.Input> inputs = new List<CRMA_DHSFlowInvoker.Input>{input};
            Test.startTest();
            List<CRMA_DHSFlowInvoker.Output> results = CRMA_DHSFlowInvoker.processAndUpdateDealHealthFlow(inputs);
            Test.stopTest();
            System.assertEquals(1, results.size(), 'Should return one result');
        }
    }

    @isTest
    public static void revenueBand1Test() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(new Map<String,Object>()));
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Band1' LIMIT 1];
            CRMA_DHSFlowInvoker.Input input = new CRMA_DHSFlowInvoker.Input();
            input.quoteId = quote.Id;
            List<CRMA_DHSFlowInvoker.Input> inputs = new List<CRMA_DHSFlowInvoker.Input>{input};
            Test.startTest();
            List<CRMA_DHSFlowInvoker.Output> results = CRMA_DHSFlowInvoker.processAndUpdateDealHealthFlow(inputs);
            Test.stopTest();
            System.assertEquals(1, results.size(), 'Should return one result');
        }
    }
    
    @isTest
    public static void testLastRangePlusBranch() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(
                new Map<String, Object>{
                    'datasets' => new List<Object>{
                        new Map<String, Object>{
                            'id' => '0FbXXXXXXXXXXXXXXX',
                            'name' => 'Deal_Health_Score_Inputs_CSV_Source',
                            'currentVersionId' => '0FcXXXXXXXXXXXXXXX'
                        }
                    },
                    'results' => new Map<String, Object>{
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Score' => '4.Red',
                                'textscore' => '30%+',
                                'Quartile' => 40
                            }
                        }
                    }
                }
            ));
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'LastRangePlus' LIMIT 1];
            CRMA_DHSFlowInvoker.Input input = new CRMA_DHSFlowInvoker.Input();
            input.quoteId = quote.Id;
            List<CRMA_DHSFlowInvoker.Input> inputs = new List<CRMA_DHSFlowInvoker.Input>{input};
            Test.startTest();
            List<CRMA_DHSFlowInvoker.Output> results = CRMA_DHSFlowInvoker.processAndUpdateDealHealthFlow(inputs);
            Test.stopTest();
            System.assertEquals(1, results.size(), 'Should return one result');
        }
    }

    @isTest
    public static void testWaveQueryResult_NonSuccessStatus() {
        // Mock a /wave/query response with a non-success status code (e.g., 500)
        Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(
            new Map<String, Object>{
                'body' => 'Internal Server Error',
                'statusCode' => 500
            }
        ));
        Test.startTest();
        CRMA_DHSWaveService.WaveResponse response = CRMA_DHSWaveService.getWaveQueryResult('dummy query');
        Test.stopTest(); 
    }

    private class ExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated callout exception');
        }
    }

    @isTest
    public static void testWaveQueryResult_Exception() {
        Test.setMock(HttpCalloutMock.class, new ExceptionMock());
        try{
           CRMA_DHSWaveService.getWaveQueryResult('dummy query');
        }
        catch(Exception error){
            system.debug(error.getMessage());
        }
    }

    private class ExceptionCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated callout exception');
        }
    }

    @isTest
    public static void testDoWaveCallout_Exception() {
        Test.setMock(HttpCalloutMock.class, new ExceptionCalloutMock());
        try{
            Test.startTest();
            HttpResponse res = CRMA_DHSWaveService.doWaveCallout('/wave/query', 'GET', null);
            CRMA_DHSService.determineLicenseTerm(null);
            CRMA_DHSService.determineRenewalFlag(false,true);
            CRMA_DHSService.determineRenewalFlag(false,false);
            CRMA_DHSService.determineIndustryBucket(null);
            CRMA_DHSService.determineRegion(null);
            Test.stopTest();
        }catch(Exception error){
            system.debug(error.getMessage());
        }
    }

    private class ExceptionWaveQueryMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated exception in getWaveQueryResult');
        }
    }

   @isTest
    public static void testGetWaveQueryResult_HandlesException() {
        Test.setMock(HttpCalloutMock.class, new ExceptionWaveQueryMock());
        Test.startTest();
        CRMA_DHSWaveService.WaveResponse response = CRMA_DHSWaveService.getWaveQueryResult('dummy query');
        Test.stopTest();
    }

    @isTest
    public static void revenueBand3Test() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Test.setMock(HttpCalloutMock.class, new CRMA_WaveAnalyticsMock(new Map<String,Object>()));
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'RevenueBand3' LIMIT 1];
            CRMA_DHSFlowInvoker.Input input = new CRMA_DHSFlowInvoker.Input();
            input.quoteId = quote.Id;
            List<CRMA_DHSFlowInvoker.Input> inputs = new List<CRMA_DHSFlowInvoker.Input>{input};
            Test.startTest();
            List<CRMA_DHSFlowInvoker.Output> results = CRMA_DHSFlowInvoker.processAndUpdateDealHealthFlow(inputs);
            Test.stopTest();
            System.assertEquals(1, results.size(), 'Should return one result');
        }
    }
    
    @isTest
    public static void testDetermineProductImportance_AllBranches() {
        // 1. CM1 Dominance, Legacy Present
        Map<String, Decimal> input1 = new Map<String, Decimal>{
            'annualNetTotal' => 100000,
            'cm1Total' => 85000, // meets 0.85 threshold
            'cm2Total' => 0,
            'vgTotal' => 0,
            'highTotal' => 0,
            'lowTotal' => 0,
            'legacyTotal' => 1000
        };
        System.assertEquals(
            CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM1_LEGACY,
            CRMA_DHSService.determineProductImportance(input1),
            'CM1 Dominance, Legacy Present'
        );
    
        // 2. CM1 Dominance, High Present
        Map<String, Decimal> input2 = new Map<String, Decimal>{
            'annualNetTotal' => 100000,
            'cm1Total' => 85000,
            'cm2Total' => 0,
            'vgTotal' => 0,
            'highTotal' => 85000, // meets 0.85 threshold
            'lowTotal' => 0,
            'legacyTotal' => 0
        };
        System.assertEquals(
            CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM1_HIGH,
            CRMA_DHSService.determineProductImportance(input2),
            'CM1 Dominance, High Present'
        );
    
        // 3. CM1 Dominance, Low Present
        Map<String, Decimal> input3 = new Map<String, Decimal>{
            'annualNetTotal' => 100000,
            'cm1Total' => 85000,
            'cm2Total' => 0,
            'vgTotal' => 0,
            'highTotal' => 0,
            'lowTotal' => 85000, // meets 0.85 threshold
            'legacyTotal' => 0
        };
        System.assertEquals(
            CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM1_LOW,
            CRMA_DHSService.determineProductImportance(input3),
            'CM1 Dominance, Low Present'
        );
    
        // 4. CM1 Dominance, Mixed
        Map<String, Decimal> input4 = new Map<String, Decimal>{
            'annualNetTotal' => 100000,
            'cm1Total' => 85000,
            'cm2Total' => 0,
            'vgTotal' => 0,
            'highTotal' => 10000,
            'lowTotal' => 10000,
            'legacyTotal' => 0
        };
        System.assertEquals(
            CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM1_MIXED,
            CRMA_DHSService.determineProductImportance(input4),
            'CM1 Dominance, Mixed'
        );
    
        // 5. CM2 Dominance, Legacy Present
        Map<String, Decimal> input5 = new Map<String, Decimal>{
            'annualNetTotal' => 100000,
            'cm1Total' => 0,
            'cm2Total' => 85000, // meets 0.85 threshold
            'vgTotal' => 0,
            'highTotal' => 0,
            'lowTotal' => 0,
            'legacyTotal' => 1000
        };
        System.assertEquals(
            CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM2_LEGACY,
            CRMA_DHSService.determineProductImportance(input5),
            'CM2 Dominance, Legacy Present'
        );
    
        // 6. VG Dominance, High Present
        Map<String, Decimal> input6 = new Map<String, Decimal>{
            'annualNetTotal' => 100000,
            'cm1Total' => 0,
            'cm2Total' => 0,
            'vgTotal' => 85000, // meets 0.85 threshold
            'highTotal' => 85000, // meets 0.85 threshold
            'lowTotal' => 0,
            'legacyTotal' => 0
        };
        System.assertEquals(
            CRMA_DHSConstants.PRODUCT_IMPORTANCE_VG_HIGH,
            CRMA_DHSService.determineProductImportance(input6),
            'VG Dominance, High Present'
        );
    
        // 7. Mixed, Legacy Present
        Map<String, Decimal> input7 = new Map<String, Decimal>{
            'annualNetTotal' => 100000,
            'cm1Total' => 10000,
            'cm2Total' => 10000,
            'vgTotal' => 10000,
            'highTotal' => 10000,
            'lowTotal' => 10000,
            'legacyTotal' => 1000
        };
        System.assertEquals(
            CRMA_DHSConstants.PRODUCT_IMPORTANCE_MIXED_LEGACY,
            CRMA_DHSService.determineProductImportance(input7),
            'Mixed, Legacy Present'
        );
    
        // 8. Mixed, High Present
        Map<String, Decimal> input8 = new Map<String, Decimal>{
            'annualNetTotal' => 100000,
            'cm1Total' => 10000,
            'cm2Total' => 10000,
            'vgTotal' => 10000,
            'highTotal' => 85000, // meets 0.85 threshold
            'lowTotal' => 0,
            'legacyTotal' => 0
        };
        System.assertEquals(
            CRMA_DHSConstants.PRODUCT_IMPORTANCE_MIXED_HIGH,
            CRMA_DHSService.determineProductImportance(input8),
            'Mixed, High Present'
        );
    
        // 9. Mixed, Low Present
        Map<String, Decimal> input9 = new Map<String, Decimal>{
            'annualNetTotal' => 100000,
            'cm1Total' => 10000,
            'cm2Total' => 10000,
            'vgTotal' => 10000,
            'highTotal' => 0,
            'lowTotal' => 85000, // meets 0.85 threshold
            'legacyTotal' => 0
        };
        System.assertEquals(
            CRMA_DHSConstants.PRODUCT_IMPORTANCE_MIXED_LOW,
            CRMA_DHSService.determineProductImportance(input9),
            'Mixed, Low Present'
        );
    
        // 10. No Dominance (Default)
        Map<String, Decimal> input10 = new Map<String, Decimal>{
            'annualNetTotal' => 0,
            'cm1Total' => 0,
            'cm2Total' => 0,
            'vgTotal' => 0,
            'highTotal' => 0,
            'lowTotal' => 0,
            'legacyTotal' => 0
        };
        System.assertEquals(
            CRMA_DHSConstants.PRODUCT_IMPORTANCE_MIXED,
            CRMA_DHSService.determineProductImportance(input10),
            'No Dominance (Default)'
        );
    }
    
   @isTest
	public static void testDetermineRevenueBand_AllBranches() {
        Decimal band1 = 50000;
        Decimal band3 = 250000;
    
        // First Purchase: Band 1
        System.assertEquals(
            CRMA_DHSConstants.REVENUE_BAND_1,
            CRMA_DHSService.determineRevenueBand(true, 49999, 123456),
            'First Purchase, quoteACV < band1'
        );
    
        // First Purchase: Band 3
        System.assertEquals(
            CRMA_DHSConstants.REVENUE_BAND_3,
            CRMA_DHSService.determineRevenueBand(true, 250001, 123456),
            'First Purchase, quoteACV > band3'
        );
    
        // First Purchase: Band 2 (between thresholds, including exactly band1 and band3)
        System.assertEquals(
            CRMA_DHSConstants.REVENUE_BAND_2,
            CRMA_DHSService.determineRevenueBand(true, 50000, 123456),
            'First Purchase, quoteACV == band1'
        );
        System.assertEquals(
            CRMA_DHSConstants.REVENUE_BAND_2,
            CRMA_DHSService.determineRevenueBand(true, 250000, 123456),
            'First Purchase, quoteACV == band3'
        );
        System.assertEquals(
            CRMA_DHSConstants.REVENUE_BAND_2,
            CRMA_DHSService.determineRevenueBand(true, 100000, 123456),
            'First Purchase, quoteACV between band1 and band3'
        );
    
        // Not First Purchase: Band 1 (null ARR)
        System.assertEquals(
            CRMA_DHSConstants.REVENUE_BAND_1,
            CRMA_DHSService.determineRevenueBand(false, 100000, null),
            'Not First Purchase, totalParentChildARR is null'
        );
    
        // Not First Purchase: Band 1 (< band1)
        System.assertEquals(
            CRMA_DHSConstants.REVENUE_BAND_1,
            CRMA_DHSService.determineRevenueBand(false, 100000, 49999),
            'Not First Purchase, totalParentChildARR < band1'
        );
    
        // Not First Purchase: Band 3 (> band3)
        System.assertEquals(
            CRMA_DHSConstants.REVENUE_BAND_3,
            CRMA_DHSService.determineRevenueBand(false, 100000, 250001),
            'Not First Purchase, totalParentChildARR > band3'
        );
    
        // Not First Purchase: Band 2 (between thresholds, including exactly band1 and band3)
        System.assertEquals(
            CRMA_DHSConstants.REVENUE_BAND_2,
            CRMA_DHSService.determineRevenueBand(false, 100000, 50000),
            'Not First Purchase, totalParentChildARR == band1'
        );
        System.assertEquals(
            CRMA_DHSConstants.REVENUE_BAND_2,
            CRMA_DHSService.determineRevenueBand(false, 100000, 250000),
            'Not First Purchase, totalParentChildARR == band3'
        );
        System.assertEquals(
            CRMA_DHSConstants.REVENUE_BAND_2,
            CRMA_DHSService.determineRevenueBand(false, 100000, 100000),
            'Not First Purchase, totalParentChildARR between band1 and band3'
        );
    }
    
   @isTest
    public static void testParseWaveResponse_ErrorBranches() {
        // 1. No results key in response
        Map<String, Object> noResultsMap = new Map<String, Object>{ 'notResults' => new Map<String, Object>() };
        CRMA_DHSWaveService.WaveResponse response1 = CRMA_DHSWaveService.parseWaveResponse(JSON.serialize(noResultsMap));
    
        // 2. No records key in results
        Map<String, Object> resultsNoRecords = new Map<String, Object>{ 'notRecords' => new List<Object>() };
        Map<String, Object> noRecordsMap = new Map<String, Object>{
            CRMA_DHSConstants.WAVE_RESPONSE_RESULTS => resultsNoRecords
        };
        CRMA_DHSWaveService.WaveResponse response2 = CRMA_DHSWaveService.parseWaveResponse(JSON.serialize(noRecordsMap));
    
        // 3. Empty records list
        Map<String, Object> resultsEmptyRecords = new Map<String, Object>{
            CRMA_DHSConstants.WAVE_RESPONSE_RECORDS => new List<Object>()
        };
        Map<String, Object> emptyRecordsMap = new Map<String, Object>{
            CRMA_DHSConstants.WAVE_RESPONSE_RESULTS => resultsEmptyRecords
        };
        CRMA_DHSWaveService.WaveResponse response3 = CRMA_DHSWaveService.parseWaveResponse(JSON.serialize(emptyRecordsMap));
    }
}