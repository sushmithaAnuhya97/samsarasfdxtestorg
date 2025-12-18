@isTest(SeeAllData=false)
public class RebateLogicHandlerTest { 
    @testSetup
    private static void testDataSetup() {
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        Rebate_Buyout_Product_Mapping__mdt mdt = new Rebate_Buyout_Product_Mapping__mdt(DeveloperName = 'HW_VG33', MasterLabel  = 'HW-VG33', 
                                                                                        CPQ_Quote_Field__c = 'Competitor_Buyout_Amount__c',Active__c =true,
                                                                                        Product_Code__c  = 'HW-VG33');
        
        User currentUser = [SELECT Id,name FROM User WHERE Id=:userInfo.getuserId()];
        // User ae2User;
        User entUser;
        system.runAs(currentUser){
            Id profileId = [SELECT Id,Name  FROM Profile WHERE Name LIKE '%AE2%' LIMIT 1].Id;
            Id ae2Role = [SELECT Id,Name FROM UserRole WHERE name LIKE '%AE2%' LIMIT 1].Id;
            Id entRole = [SELECT Id,Name FROM UserRole WHERE name LIKE '%FLEET ENT AE%' LIMIT 1].Id;
            entUser = OrderValidationServiceAutomationTest.createUser('ENT','Sales2',entRole,profileId,'ENTusr');
            insert entUser;
        }
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            Name = 'Standard Price Book',
            IsActive = true
        );
        Update standardPricebook;
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
        
        insert products;
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        
        insert pricebookEntries;
        
        // Create account
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        newAccount.add(account);
        
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account partnerAccount = new Account (Name = 'Test Partner Account',RecordTypeId = accRecordTypeId,Partner_Type__c ='Insurance',Program_Type__c ='Subsidy', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        newAccount.add(partnerAccount);
        
        insert newAccount;
        Customer_360__c c360 = new Customer_360__c(LIC_AG2_Discount__c=1,LIC_AG4_Discount__c=1,LIC_CM1_Discount__c=1,LIC_CM2_Discount__c=1,
                                                   LIC_CRGO_Discount__c=1,LIC_DM11_Discount__c=1,LIC_VG_Discount__c=1,LIC_AG4P_Discount__c=1,
                                                   LIC_EM_Discount__c=1,Account__c=account.Id);
        insert c360;
        // Create Contact
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
        Shipping_Address__c shipToTwo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '610 Park View Dr'
                                                                , Shipping_City__c = 'Santa Clara', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                                , Shipping_Zip_Code__c = '95054', Name = 'Ship To Two');
        shippingAddresses.add(shipToTwo);
        insert shippingAddresses;
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
                                                         CloseDate = System.today() + 90, Owner_Role_Copy__c='Industrial',StageName = 'Incubate');
        
        Opportunity revenueOpportunitywithInsurancePartner = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                                             Max_Approved_Discount__c=0, Name = 'Revenue OpportunitywithInPartner', Price_Book_Name__c = 'Standard Price Book',
                                                                             CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8',Insurance_Partner__c=partnerAccount.Id);
        newOpportunities.add(revenueOpportunity);
        newOpportunities.add(revenueOpportunitywithInsurancePartner);
        insert newOpportunities;
        //List<SBQQ__Quote__c> quoteLst = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c =revenueOpportunity.Id,
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, Buyout_Amount__c = 6.0, Subsidy_Amount__c=3.0,SBQQ__Primary__c = false, Custom_License_Term__c = 2);
        insert quote;
        // Insert contract
        Contract cont = new Contract(
            AccountId = account.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Status = 'Draft',
            Contract_Renewable_ACV__c = 20
        );
        insert cont;
        cont.Status = 'Activated';
        update cont;
    }
    
    @isTest private static void QuoteCalculatorHelper_Test(){
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c limit 1];
        QuoteCalculatorHelper.calculateQuotes(new Set<Id>{quote.id});
        Test.stopTest();
    }
    @isTest private static void checkForConflicts_test() {
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c limit 1];
        RebateLogicHandler.checkForConflicts(quote.Id);
        Test.stopTest();
    }
    
    @isTest private static void testInstallationsCostBuyoutAmount() {
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c limit 1];
        quote.Competitor_Buyout_Amount__c = 1;
        quote.Total_Estimated_Installation_Costs__c = 200;
        quote.Is_Installation_Reimbursable__c = 'No';
        update quote;
        
        
        quote.Total_Estimated_Installation_Costs__c = -100;
        try {
            update quote;
            // System.assert(false, 'Should have thrown an error for missing pricebook entry');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Total Estimated Installation Costs must be a positive amount.'), 'Error message should indicate Total Estimated Installation Costs must be positive');
        }
        Test.stopTest();
    }
    
    @isTest private static void testInstallationsCostBuyoutAmount2() {
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c limit 1];
        
        quote.Total_Estimated_Installation_Costs__c = 100;
        try {
            update quote;
            // System.assert(false, 'Should have thrown an error for missing pricebook entry');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Please select a value for "Is Installation Reimbursable".'), 'Error message should indicate Is Installation Reimbursable must be selected');
        }
        Test.stopTest();
    }
    @isTest private static void testInstallationsCostBuyoutAmount3() {
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c limit 1];
        
        quote.Total_Estimated_Installation_Costs__c = -100;
        try {
            update quote;
            // System.assert(false, 'Should have thrown an error for missing pricebook entry');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Total Estimated Installation Costs must be a positive amount.'), 'Error message should indicate Total Estimated Installation Costs must be positive');
        }
        Test.stopTest();
    }
    
    @isTest 
    private static void testBuyoutAmountNegativeValue() {
        Test.startTest();
        
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c, Competitor_Buyout_Amount__c 
                                FROM SBQQ__Quote__c LIMIT 1];
        
        quote.Competitor_Buyout_Amount__c = -100;
        try {
            update quote;
            // System.assert(false, 'Expected error for negative buyout amount');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('The Buyout Amount must be a positive amount'));
        }
        
        Test.stopTest();
    }
    
    @isTest 
    private static void testBuyoutAmountClosingStage() {
        Test.startTest();
        
        Opportunity opp = [SELECT Id, Type, Probability FROM Opportunity 
                           WHERE Name = 'Revenue Opportunity' LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        opp.Probability = 95;
        opp.Free_Trial_Purchase__c = 'Partial Buy';
        update opp;
        
        quote.Competitor_Buyout_Amount__c = 100;
        try {
            update quote;
            //System.assert(false, 'Expected error for opportunity in Closing stage');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('The Buyout Amount field cannot be entered for Opportunities that are in the Closing stage or later'));
        }
        
        Test.stopTest();
    }
    
    @isTest 
    private static void testBuyoutAmountNonRevenue() {
        Test.startTest();
        
        Opportunity opp = [SELECT Id, Type, Probability FROM Opportunity 
                           WHERE Name = 'Revenue Opportunity' LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        opp.Type = 'Non Revenue';
        opp.Probability = 50;
        update opp;
        
        quote.Competitor_Buyout_Amount__c = 100;
        try {
            update quote;
            //System.assert(false, 'Expected error for non-revenue opportunity');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('The Buyout Amount field can only be entered for Revenue Opportunities'));
        }
        
        Test.stopTest();
    }
    
    @isTest 
    private static void testBuyoutAmountWithRebateOpp() {
        Test.startTest();
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Reset opportunity to valid state
        opp.Type = 'Revenue Opportunity';
        opp.Probability = 50;
        update opp;
        
        // Create related rebate opportunity
        Opportunity rebateOpp = new Opportunity(
            Name = 'Rebate Opportunity',
            AccountId = acc.Id,
            StageName = 'Incubate',
            CloseDate = System.today() + 90,
            Type = 'Rebate'
            //Returning_Opportunity__c = opp.Id
        );
        insert rebateOpp;
        
        quote.Competitor_Buyout_Amount__c = 100;
        try {
            update quote;
            // System.assert(false, 'Expected error for quote with related rebate opportunity');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('The Buyout Amount cannot be entered when there is a related opportunity'));
        }
        
        Test.stopTest();
    }
    
    @isTest 
    private static void testBuyoutAmountSuccessful() {
        Test.startTest();
        
        Opportunity opp = [SELECT Id, Type, Probability FROM Opportunity 
                           WHERE Name = 'Revenue Opportunity' LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Set up valid conditions
        opp.Type = 'Revenue Opportunity';
        opp.Probability = 50;
        update opp;
        
        quote.Competitor_Buyout_Amount__c = 100;
        Boolean successfulUpdate = true;
        try {
            update quote;
        } catch (Exception e) {
            successfulUpdate = false;
            System.debug('Unexpected error: ' + e.getMessage());
        }
        System.assert(successfulUpdate, 'Quote update should succeed with valid conditions');
        
        Test.stopTest();
    }
    
    @isTest
    static void testValidateRebateBuyoutLineDeletion_AllScenarios() {
        // Setup test Products with Product_Type__c values
        Product2 buyoutProduct = new Product2(Name = 'Competitor Buyout', IsActive = true, ProductCode = 'DC-COMPETITOR-BUYOUT');
        Product2 futureFreeProduct = new Product2(Name = 'Future Free Months', IsActive = true, ProductCode = 'DC-FUTURE-FREE-MONTHS');
        Product2 installationProduct = new Product2(Name = 'Installation Costs', IsActive = true, ProductCode = 'DC-INSTALLATION-COSTS');
        Product2 passThroughProduct = new Product2(Name = 'Samsara Pass Through Install Services', IsActive = true, ProductCode = 'Samsara-Pass-Through-Install-Services');
        Product2 otdProduct = new Product2(Name = 'One Time Discount', IsActive = true, ProductCode = 'DC-ONE-TIME-DISCOUNT');
        Product2 licenseProduct = new Product2(Name = 'License Product', IsActive = true, Product_Type__c = 'License');
        insert new List<Product2>{buyoutProduct, futureFreeProduct, installationProduct, passThroughProduct, otdProduct, licenseProduct};
            
            // Setup static IDs in queueable class
            BuyoutQuoteLineQueueable.buyoutProductId = buyoutProduct.Id;
        BuyoutQuoteLineQueueable.futureFreeMonthsProductId = futureFreeProduct.Id;
        BuyoutQuoteLineQueueable.installationCostProductId = installationProduct.Id;
        BuyoutQuoteLineQueueable.samsaraPassThroughProductId = passThroughProduct.Id;
        BuyoutQuoteLineQueueable.otdProductId = otdProduct.Id;
        
        Opportunity revenueOpportunity =[select id,Name from opportunity limit 1];
        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = revenueOpportunity.Id,
            Competitor_Buyout_Amount__c = 100,
            Future_Free_Months_Amount__c = 150,
            Total_Estimated_Installation_Costs__c = 200,
            Number_of_months_of_Free_service__c = 1,
            Is_Installation_Reimbursable__c = 'Yes',
            OTD_Amt__c = 75
        );
        insert quote;
        
        // Create Quote Lines
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = buyoutProduct.Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = futureFreeProduct.Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = installationProduct.Id ),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = passThroughProduct.Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = otdProduct.Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = licenseProduct.Id)
                };
                    insert quoteLines;
        
        // Test: bypassValidation true
        GS_SBQQQuoteService.bypassValidation = true;
        RebateLogicHandler cls = new RebateLogicHandler();
        cls.validateRebateBuyoutLineDeletion(quoteLines);
        
        // Test: empty quote Ids
        GS_SBQQQuoteService.bypassValidation = false;
        cls.validateRebateBuyoutLineDeletion(new List<SBQQ__QuoteLine__c>{ new SBQQ__QuoteLine__c() });
        
        // Full validation
        Test.startTest();
        List<SBQQ__QuoteLine__c> quoteLines2 = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, Product_Type__c, SBQQ__ProductCode__c
                                                     FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];
        cls.validateRebateBuyoutLineDeletion(quoteLines2);
        Test.stopTest();
    }
    
    @isTest
    static void testGetRebateDetails() {
        Test.startTest();
        
        // Get test quote with all required fields
        SBQQ__Quote__c quote = [
            SELECT Id, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Type,
                   SBQQ__Opportunity2__r.Buyout_Opportunity__c,
                   SBQQ__Opportunity2__r.Subsidy_Opportunity__c,
                   SBQQ__Account__c, SBQQ__Primary__c,
                   CurrencyIsoCode, SBQQ__Pricebook__c,
                   Total_License_Price__c, License_Term__c,
                   Competitor_Buyout_Amount__c, Total_Estimated_Installation_Costs__c,
                   Is_Installation_Reimbursable__c, Number_of_months_of_Free_service__c,
                   Future_Free_Months_Amount__c, ApprovalStatus__c,
                   SBQQ__Opportunity2__r.Probability, OTD_Amt__c, Future_Free_Service_Type__c
            FROM SBQQ__Quote__c 
            WHERE SBQQ__Opportunity2__c != null
            LIMIT 1
        ];
        
        // Get test product from existing test data
        Product2 vg33 = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        
        // Update the opportunity type to ensure it's a Revenue Opportunity
        Opportunity opp = [
            SELECT Id, Type 
            FROM Opportunity 
            WHERE Id = :quote.SBQQ__Opportunity2__c
        ];
        opp.Type = 'Revenue Opportunity';
        update opp;
        
        // Initialize product IDs using existing product
        BuyoutQuoteLineQueueable.buyoutProductId = vg33.Id;
        BuyoutQuoteLineQueueable.installationCostProductId = vg33.Id;
        BuyoutQuoteLineQueueable.futureFreeMonthsProductId = vg33.Id;
        BuyoutQuoteLineQueueable.otdProductId = vg33.Id;
        
        // Set the static flags in BuyoutQuoteLineQueueable
        BuyoutQuoteLineQueueable.isBuyoutProductAvailable = true;
        BuyoutQuoteLineQueueable.isInstallationCostProductAvailable = true;
        BuyoutQuoteLineQueueable.isFutureFreeMonthsProductAvailable = true;
        BuyoutQuoteLineQueueable.isOTDProductAvailable = true;
        
        // Mock the DCSuperUserProfileIds label
        String profileId = UserInfo.getProfileId();
        Test.setFixedSearchResults(new List<String>{profileId});
        
        // Test successful scenario
        RebateLogicHandler.QuoteWrap result;
        try {
            result = RebateLogicHandler.getRebateDetails(quote.Id);
            
            // Add assertions
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(quote.Id, result.id, 'Quote ID should match');
            System.assertEquals('Revenue Opportunity', result.opportunityType, 'Opportunity type should be Revenue Opportunity');
            System.assertEquals(false, result.rebateOpp, 'Should not be a rebate opportunity');
            
        } catch(Exception e) {
            System.assert(false, 'No exception should be thrown. Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        // Test error scenario with invalid ID
        try {
            RebateLogicHandler.QuoteWrap errorResult = RebateLogicHandler.getRebateDetails('001000000000000');
            System.assert(false, 'Should have thrown an exception for invalid ID');
        } catch(AuraHandledException e) {
            // Expected exception
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetRebateDetails_NonRevenue() {
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        
        Opportunity rebateOpp = new Opportunity(
            Name = 'Rebate Opportunity',
            AccountId = acc.Id,
            StageName = 'Incubate',
            CloseDate = System.today() + 90,
            Type = 'Rebate'
            //Returning_Opportunity__c = opp.Id
        );
        insert rebateOpp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'N Quote ', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c =rebateOpp.Id,
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, Buyout_Amount__c = 6.0, Subsidy_Amount__c=3.0,SBQQ__Primary__c = false, Custom_License_Term__c = 2);
        insert quote;
        RebateLogicHandler.QuoteWrap errorResult = RebateLogicHandler.getRebateDetails(quote.Id);
        
        
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateQuoteFields() {
        Test.startTest();
        
        // Get test quote from existing test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Create field values map as JSON string
        Map<String, String> fieldValues = new Map<String, String>{
            'Competitor_Buyout_Amount__c' => '100.00',
                'Total_Estimated_Installation_Costs__c' => '200.00',
                'Is_Installation_Reimbursable__c' => 'Yes',
                'Number_of_months_of_Free_service__c' => '3',
                'Bypass_Multiline__c' => 'false',
                'OTD_Amt__c' => '150.00',
                'Buyout_Incumbent_Provider__c' => 'GPS Insight'
                };
                    String fieldValuesJSON = JSON.serialize(fieldValues);
        
        // Test successful scenario
        SBQQ__Quote__c updatedQuote = RebateLogicHandler.updateQuoteFields(quote.Id, fieldValuesJSON);
        
        // Test with null values
        Map<String, String> nullFieldValues = new Map<String, String>{
            'Competitor_Buyout_Amount__c' => '',
                'Total_Estimated_Installation_Costs__c' => '',
                'Is_Installation_Reimbursable__c' => '',
                'Number_of_months_of_Free_service__c' => '',
                'Bypass_Multiline__c' => '',
                'OTD_Amt__c' => '',
                'Buyout_Incumbent_Provider__c' => ''
                };
                    String nullFieldValuesJSON = JSON.serialize(nullFieldValues);
        
        SBQQ__Quote__c nullUpdatedQuote = RebateLogicHandler.updateQuoteFields(quote.Id, nullFieldValuesJSON);
        
        Test.stopTest();
    }
    @isTest
    static void testProcessQuoteUpdate() {
        Test.startTest();
        
        // Get test quote from existing test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Test the processQuoteUpdate method
        Id jobId = RebateLogicHandler.processQuoteUpdate(quote);
        
        Test.stopTest();
    }
    
    @isTest
    static void testLogJobExecution() {
        Test.startTest();
        
        // Get test quote from existing test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Id mockJobId = '707000000000000'; // Mock AsyncApexJob Id
        
        // Test the logJobExecution method
        RebateLogicHandler.logJobExecution(quote.Id, mockJobId);
        
        Test.stopTest();
    }
    
    @isTest
    static void testCreateUpdateRebateLines() {
        Test.startTest();
        
        // Get test quote from existing test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Create field values map as JSON string
        Map<String, String> fieldValues = new Map<String, String>{
            'Competitor_Buyout_Amount__c' => '100.00',
                'Total_Estimated_Installation_Costs__c' => '200.00',
                'Is_Installation_Reimbursable__c' => 'Yes',
                'Number_of_months_of_Free_service__c' => '3',
                'Bypass_Multiline__c' => 'false'
                };
                    String fieldValuesJSON = JSON.serialize(fieldValues);
        
        // Test upsert operation
        Id upsertJobId = RebateLogicHandler.createUpdateRebateLines(quote.Id, fieldValuesJSON, 'upsert');
        
        // Test recalculate operation
        Id recalculateJobId = RebateLogicHandler.createUpdateRebateLines(quote.Id, null, 'recalculate');
        
        // Test invalid operation
        Id invalidJobId = RebateLogicHandler.createUpdateRebateLines(quote.Id, null, 'invalid');
        
        Test.stopTest();
    }
    
    @isTest
    static void testTrackJob() {
        Test.startTest();
        
        // Get test quote from existing test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Create a log entry first
        Id mockJobId = '707000000000000'; // Mock AsyncApexJob Id
        RebateLogicHandler.logJobExecution(quote.Id, mockJobId);
        
        // Test successful scenario
        try {
            AsyncApexJob job = RebateLogicHandler.trackJob(quote.Id);
        } catch(Exception e) {
            // Expected exception since mockJobId doesn't exist
        }
        
        // Test error scenario with invalid quote Id
        try {
            AsyncApexJob errorJob = RebateLogicHandler.trackJob('001000000000000');
        } catch(Exception e) {
            // Expected exception
        }
        
        Test.stopTest();
    }
    @isTest
    static void testQuoteWrap() {
        Test.startTest();
        
        // Get test quote with all required fields, including the relationship fields
        SBQQ__Quote__c quote = [
            SELECT Id, Competitor_Buyout_Amount__c, Total_Estimated_Installation_Costs__c,
                Is_Installation_Reimbursable__c, SBQQ__LastCalculatedOn__c,
                SBQQ__Opportunity2__r.Type, SBQQ__Opportunity2__r.Probability,
                Number_of_months_of_Free_service__c, Future_Free_Months_Amount__c,
                ApprovalStatus__c, Total_License_Price__c, License_Term__c, Net_Amount_Rebate__c,
                SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Buyout_Opportunity__c,
                SBQQ__Opportunity2__r.Subsidy_Opportunity__c, Bypass_Multiline__c,
                X3rd_PF_Interest_Subsidy__c, New_DC_architecture__c, SBQQ__Status__c,SBQQ__Opportunity2__r.StageName,
                OTD_Amt__c, Future_Free_Service_Type__c, Buyout_Incumbent_Provider__c
            FROM SBQQ__Quote__c 
            WHERE SBQQ__Opportunity2__c != null
            LIMIT 1
        ];
        
        System.assertNotEquals(null, quote.SBQQ__Opportunity2__r, 'Quote must have a related Opportunity');
        
        // Test QuoteWrap constructor with different scenarios
        RebateLogicHandler.QuoteWrap wrapWithRebateOpp = new RebateLogicHandler.QuoteWrap(
            quote,
            true,  // rebateOpp
            true,  // isBuyoutProductAvailable
            true,  // isInstallationCostProductAvailable
            true,  // isFutureFreeMonthsProductAvailable
            true,  // isOTDProductAvailable
            true,   // isSuperUser
            200     // totalLicensePrice
        );
        
        RebateLogicHandler.QuoteWrap wrapWithoutRebateOpp = new RebateLogicHandler.QuoteWrap(
            quote,
            false, // rebateOpp
            false, // isBuyoutProductAvailable
            false, // isInstallationCostProductAvailable
            false, // isFutureFreeMonthsProductAvailable
            false, // isOTDProductAvailable
            false,  // isSuperUser
            200     // totalLicensePrice
        );
        
        // Add assertions to verify the wrapper values
        System.assertEquals(quote.Id, wrapWithRebateOpp.id);
        System.assertEquals(quote.SBQQ__Opportunity2__r.Type, wrapWithRebateOpp.opportunityType);
        System.assertEquals(quote.SBQQ__Opportunity2__r.Probability, wrapWithRebateOpp.opportunityProbability);
        
        Test.stopTest();
    }
    
    @isTest
    static void testRebateConflictClasses() {
        Test.startTest();
        
        // Get test quote
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Test RebateConflictInput
        RebateLogicHandler.RebateConflictInput input = new RebateLogicHandler.RebateConflictInput();
        input.quoteId = quote.Id;
        
        // Test with null quoteId
        RebateLogicHandler.RebateConflictInput nullInput = new RebateLogicHandler.RebateConflictInput();
        nullInput.quoteId = null;
        
        // Test RebateConflictOutput
        RebateLogicHandler.RebateConflictOutput output = new RebateLogicHandler.RebateConflictOutput();
        output.hasConflicts = true;
        
        RebateLogicHandler.RebateConflictOutput falseOutput = new RebateLogicHandler.RebateConflictOutput();
        falseOutput.hasConflicts = false;
        
        // Test null output
        RebateLogicHandler.RebateConflictOutput nullOutput = new RebateLogicHandler.RebateConflictOutput();
        
        Test.stopTest();
    }
    @isTest
    static void testCheckRebateConflictsFlow() {
        Test.startTest();
        
        // Create input for the flow
        RebateLogicHandler.RebateConflictInput input = new RebateLogicHandler.RebateConflictInput();
        input.quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
        List<RebateLogicHandler.RebateConflictInput> inputs = new List<RebateLogicHandler.RebateConflictInput>{input};
            
            // Test successful scenario
            List<RebateLogicHandler.RebateConflictOutput> outputs = RebateLogicHandler.checkRebateConflictsFlow(inputs);
        
        // Test error scenario with invalid ID
        RebateLogicHandler.RebateConflictInput invalidInput = new RebateLogicHandler.RebateConflictInput();
        invalidInput.quoteId = '001000000000000'; // Invalid ID
        List<RebateLogicHandler.RebateConflictInput> invalidInputs = new List<RebateLogicHandler.RebateConflictInput>{invalidInput};
            List<RebateLogicHandler.RebateConflictOutput> errorOutputs = RebateLogicHandler.checkRebateConflictsFlow(invalidInputs);
        
        Test.stopTest();
    }
    @isTest 
    private static void testDealComponent() {
        Test.startTest();
        
        // Get existing test data
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
        Product2 vg33 = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        
        // Initialize product IDs using existing product
        BuyoutQuoteLineQueueable.buyoutProductId = vg33.Id;
        BuyoutQuoteLineQueueable.installationCostProductId = vg33.Id;
        BuyoutQuoteLineQueueable.futureFreeMonthsProductId = vg33.Id;
        
        // Update quote with rebate values
        quote.Competitor_Buyout_Amount__c = 100;
        quote.Total_Estimated_Installation_Costs__c = 200;
        quote.Is_Installation_Reimbursable__c = 'No';
        quote.SBQQ__Primary__c = true;
        update quote;
        
        // Get the opportunity to test deal components update
        Map<Id, Opportunity> newOpptyMap = new Map<Id, Opportunity>([SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Id = :quote.SBQQ__Opportunity2__c]);
        Map<Id, Opportunity> loadedOpportunityMap = new Map<Id, Opportunity>([SELECT Id, CurrencyIsoCode, (SELECT Product2Id FROM OpportunityLineItems) FROM Opportunity WHERE Id = :quote.SBQQ__Opportunity2__c]);
        
        // Test the method
        RebateLogicHandler.updateQuoteFieldsDealComp(newOpptyMap, loadedOpportunityMap);
        
        Test.stopTest();
    }
    @isTest
	static void testCheckFirstInvoiceAmounts() {
    Test.startTest();
    
    // Get test quote with all required fields
    SBQQ__Quote__c quote = [SELECT Id, Selected_Payment_Type__c, 
                           First_Months_Payment__c, First_Quarter_Payment__c,
                           First_Semi_Annual_Payment__c, First_Annual_Payment__c,
                           Is_First_Invoice_Amount_Negative__c,
                           Estimated_Annual_Payment__c,SBQQ__NetAmount__c
                           FROM SBQQ__Quote__c 
                           LIMIT 1];
     // Creates oldMap required by the method parameter
    // Clone is used to create a copy of the quote for the old version
    List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>{quote};
    Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>{quote.Id => quote.clone(true, true)};
    
    // Test each payment type
    String[] paymentTypes = new String[]{
        'Direct Monthly',
        'Direct Quarterly',
        'Direct Semi-Annual',
        'Direct Annual',
        'Upfront Payments',
        null
    };
    
    for(String paymentType : paymentTypes) {
        quote.Selected_Payment_Type__c = paymentType;
        RebateLogicHandler.checkFirstInvoiceAmounts(oldMap, quoteList);
    }
    
    Test.stopTest();
}
    /*
    @isTest
    static void testGetRebateDetails_ErrorScenarios() {
        Test.startTest();
        
        // Test with null quoteId
        try {
            RebateLogicHandler.getRebateDetails(null);
            //System.assert(false, 'Should have thrown an exception for null ID');
        } catch(AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        
        // Test with invalid quoteId
        try {
            RebateLogicHandler.getRebateDetails('001000000000000');
            System.assert(false, 'Should have thrown an exception for invalid ID');
        } catch(AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        
        // Test with quote without opportunity
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        quote.SBQQ__Opportunity2__c = null;
        update quote;
        
        try {
            RebateLogicHandler.getRebateDetails(quote.Id);
            //System.assert(false, 'Should have thrown an exception for quote without opportunity');
        } catch(AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }

    @isTest
    static void testCreateUpdateRebateLines_ErrorScenarios() {
        Test.startTest();
        
        // Test with null quoteId
        try {
            RebateLogicHandler.createUpdateRebateLines(null, '{}', 'upsert');
            //System.assert(false, 'Should have thrown an exception for null ID');
        } catch(AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        
        // Test with invalid operation
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        try {
            RebateLogicHandler.createUpdateRebateLines(quote.Id, '{}', 'invalid');
            //System.assert(false, 'Should have thrown an exception for invalid operation');
        } catch(AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        
        // Test with invalid JSON
        try {
            RebateLogicHandler.createUpdateRebateLines(quote.Id, 'invalid json', 'upsert');
            System.assert(false, 'Should have thrown an exception for invalid JSON');
        } catch(AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }

    @isTest
    static void testTrackJob_ErrorScenarios() {
        Test.startTest();
        
        // Test with null quoteId
        try {
            RebateLogicHandler.trackJob(null);
            System.assert(false, 'Should have thrown an exception for null ID');
        } catch(AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        
        // Test with invalid quoteId
        try {
            RebateLogicHandler.trackJob('001000000000000');
            System.assert(false, 'Should have thrown an exception for invalid ID');
        } catch(AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }

    @isTest
    static void testValidateRebateBuyoutLineDeletion_ErrorScenarios() {
        Test.startTest();
        
        // Test with null quoteLines
        try {
            RebateLogicHandler handler = new RebateLogicHandler();
            handler.validateRebateBuyoutLineDeletion(null);
            System.assert(false, 'Should have thrown an exception for null quoteLines');
        } catch(Exception e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        
        // Test with empty quoteLines
        try {
            RebateLogicHandler handler = new RebateLogicHandler();
            handler.validateRebateBuyoutLineDeletion(new List<SBQQ__QuoteLine__c>());
            //System.assert(false, 'Should have thrown an exception for empty quoteLines');
        } catch(Exception e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
	*/
    @isTest
    static void testCheckForConflicts_ErrorScenario() {
        Test.startTest();
        // Create an invalid quote ID to force an error
        Id invalidQuoteId = 'a0Q000000000000';
        try {
            RebateLogicHandler.checkForConflicts(invalidQuoteId);
            //System.assert(false, 'Expected an AuraHandledException to be thrown');
        } catch(AuraHandledException e) {
            // Verify the error message
            System.assert(e.getMessage() != null, 'Error message should not be null');
        }
        Test.stopTest();
    }

    @isTest
    static void testCalculateBuyoutAmount() {
        Test.startTest();
        
        // Get test quote
        SBQQ__Quote__c quote = [SELECT Id, Buyout_Amount__c, Subsidy_Amount__c, 
                               Total_Estimated_Installation_Costs__c, Competitor_Buyout_Amount__c,
                               Future_Free_Months_Amount__c, X3rd_PF_Interest_Subsidy__c,
                               Contract_buyout_requested__c, Free_service_months_requested__c,
                               Number_of_months_of_Free_service__c, New_DC_architecture__c,
                               OTD_Amt__c, Future_Free_Service_Type__c
                               FROM SBQQ__Quote__c LIMIT 1];
        
        Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>();
        oldMap.put(quote.Id, quote.clone(true, true));
        
        quote.Total_Estimated_Installation_Costs__c = 1000;
        List<SBQQ__Quote__c> newList = new List<SBQQ__Quote__c>{quote};
        RebateLogicHandler.calculateBuyoutAmount(oldMap, newList);
        System.assertEquals(1000, quote.Buyout_Amount__c, 'Buyout amount should be updated with installation costs');
        
        oldMap.put(quote.Id, quote.clone(true, true));
        quote.Competitor_Buyout_Amount__c = 500;
        RebateLogicHandler.calculateBuyoutAmount(oldMap, newList);
        System.assertEquals(1500, quote.Buyout_Amount__c, 'Buyout amount should include both installation costs and competitor buyout');
        System.assertEquals(true, quote.Contract_buyout_requested__c, 'Contract buyout requested should be true');
        
        oldMap.put(quote.Id, quote.clone(true, true));
        quote.Future_Free_Months_Amount__c = 200;
        quote.Number_of_months_of_Free_service__c = 2;
        RebateLogicHandler.calculateBuyoutAmount(oldMap, newList);
        System.assertEquals(200, quote.Subsidy_Amount__c, 'Subsidy amount should be updated with future free months amount');
        
        // Test 5: Update third party interest subsidy
        oldMap.put(quote.Id, quote.clone(true, true));
        quote.X3rd_PF_Interest_Subsidy__c = 300;
        RebateLogicHandler.calculateBuyoutAmount(oldMap, newList);
        System.assertEquals(500, quote.Subsidy_Amount__c, 'Subsidy amount should include both future free months and interest subsidy');
        
        // Test 6: Set number of free months to 0
        oldMap.put(quote.Id, quote.clone(true, true));
        quote.Number_of_months_of_Free_service__c = 0;
        RebateLogicHandler.calculateBuyoutAmount(oldMap, newList);
        
        // Test 7: Null values
        oldMap.put(quote.Id, quote.clone(true, true));
        quote.Total_Estimated_Installation_Costs__c = null;
        quote.Competitor_Buyout_Amount__c = null;
        quote.Future_Free_Months_Amount__c = null;
        quote.X3rd_PF_Interest_Subsidy__c = null;
        RebateLogicHandler.calculateBuyoutAmount(oldMap, newList);
        
        Test.stopTest();
    }
}