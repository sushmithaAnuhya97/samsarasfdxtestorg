@isTest
private class ShippingHandlingCalculationsTest {
    
    @TestSetup
    static void setupTestData() {
        User AEUser = [select Id, IsActive, Profile.Name, UserRole.Name from User where IsActive = true and UserRole.Name like '%AE1%' limit 1];
        List<Shipping_Configuration__c> shList = new List<Shipping_Configuration__c>();
        Shipping_Configuration__c sh = new Shipping_Configuration__c(Name='United States - Next Day Air',Scenario__c='Next Day Air',Multiplier__c=1, 
                                                                     Go_Live_Date__c=System.Today(),Minimum_Charge__c=30, Type__c='Shipping Method');
        shList.add(sh);
        Shipping_Configuration__c sh2 = new Shipping_Configuration__c(Name='United States',Scenario__c='Next Day Air',Multiplier__c=1, 
                                                                     Go_Live_Date__c=System.Today(),Minimum_Charge__c=30);
        shList.add(sh2);
        Shipping_Configuration__c sh3 = new Shipping_Configuration__c(Name='United States',Scenario__c='All Other Segment',Multiplier__c=1, 
                                                                     Go_Live_Date__c=System.Today(),Minimum_Charge__c=30, Type__c='Sales Motion');
        shList.add(sh3);
        insert shList;
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        // Create test data for Accounts, Opportunities, and Quotes
        Account testAccount = new Account(
            Name = 'Testers 1 Inc',
            BillingState='California',
            BillingCountry = 'United States',
            Organization_Size__c = '100 - 499',
            Industry = 'Other',
            CurrencyIsoCode='USD',
            OwnerId = AEUser.Id
        );
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Freight_Cost__c = 200,
            CurrencyIsoCode='USD',
            Type = 'Revenue Opportunity',
            Shipping_Country__c = 'United States',
            Shipping_Method__c = 'Next Day Air',
            Shipping_and_Handling_Manual__c = null,
            CreatedDate = Date.today().addDays(-10)
        );
        insert testOpportunity;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = testOpportunity.Id,
            Shipping_Country__c = 'United States',
            Shipping_Method__c = 'Next Day Air',
            CreatedDate = Date.today().addDays(-5),
            of_HW_Products__c = 4,
            of_Accessories__c = 5,
            CurrencyIsoCode='USD',
            Configuration_Segment__c = 'Express',
            Freight_Cost__c = 500
        );
        insert testQuote;

        TestData.ProductsAndPriceBooks productsAndPricebooks = TestData.createProductsAndPricebookEntries();
        Map<String, PricebookEntry> pricebookEntries = productsAndPricebooks.pricebookEntries;
		Map<String, Product2> Product2Entries = productsAndPricebooks.products;
        Map<String, OpportunityLineItem> items = new Map<String, OpportunityLineItem>();
        OpportunityLineItem ol = new OpportunityLineItem (Quantity = 5, OpportunityId = testOpportunity.Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice, Discount = 2);
        items.put('revVg33', ol);

        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = testOpportunity.Id, PriceBookEntryId = pricebookEntries.get('em11').Id, UnitPrice = pricebookEntries.get('em11').UnitPrice, Discount = 2);
        items.put('revEm11', ol);

        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = testOpportunity.Id, PriceBookEntryId = pricebookEntries.get('vgLicense').Id, UnitPrice = pricebookEntries.get('vgLicense').UnitPrice, Discount = 2, Created_From_NS__c = true);
        items.put('revVgLicense', ol);

        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = testOpportunity.Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice, Discount = 2);
        items.put('revEmLicense', ol);

        insert items.values();
        
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = testQuote.Id, SBQQ__PricebookEntryId__c = pricebookEntries.get('vg33').Id, SBQQ__Quantity__c  = 5,
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = Product2Entries.get('vg33').Id, accountLookupTest__c = testAccount.Id);
        insert quoteLineOne;
        TriggerHandler.clearBypass('GS_OpportunityTriggerHandler');
        TriggerHandler.clearBypass('OpportunityTriggerHandlerContext');
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.clearBypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.clearBypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.clearBypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearBypass('GS_AccountTriggerHandler');
        TriggerHandler.clearBypass('ContractTriggerHandler');
        TriggerHandler.clearBypass('GS_ContactTriggerHandler');
        TriggerHandler.clearBypass('ContactTriggerHandler'); 
        
        SBQQ.TriggerControl.enable();
    }

    @isTest
    static void testUpdateShippingAndHandlingForOpportunity() {
        List<Opportunity> opportunities = [SELECT Id,SBQQ__PrimaryQuote__c , Segment_Sales_Role__c, Shipping_Country__c, CloseDate, Probability, CreatedDate, Freight_Cost__c, of_Accessories__c, of_HW_Products__c, Shipping_and_Handling_Amount__c, Shipping_and_Handling_Manual__c, Shipping_and_Handling_Value__c, Shipping_Method__c, Type, Shipping_Account_Type__c FROM Opportunity WHERE Name = 'Test Opportunity'];
        Test.startTest();
        ShippingHandlingCalculations.runningTestClass =true;
        ShippingHandlingCalculations.updateShippingAndHandlingForOpportunity(opportunities);
        ShippingHandlingCalculations.performShippingHandlingCalculationsForOpportunity(opportunities);
        Test.stopTest();
    }

    @isTest
    static void calculateShippingAndHandlingForOpportunity() {
        Opportunity opp = [SELECT Id, SBQQ__PrimaryQuote__c,CurrencyIsoCode , CPQ_Opportunity__c, Segment_Sales_Role__c, Shipping_Country__c, CloseDate, Probability, CreatedDate, Freight_Cost__c, of_Accessories__c, of_HW_Products__c, Segment__c, Shipping_and_Handling_Amount__c, Shipping_and_Handling_Manual__c, Shipping_and_Handling_Value__c, Shipping_Method__c, Type FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        List<OpportunityLineItem> oliList = [SELECT Id, Product_Type_Copy__c, Product_Code_Copy__c, ProductCode, Product2.Baseline_Cost__c, Quantity  from OpportunityLineItem WHERE OpportunityId=:opp.id ];
		Test.startTest();
        ShippingHandlingCalculations.runningTestClass =true;
        //ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(opp, oliList);
        ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(null, opp, oliList);
        ShippingHandlingCalculations.newCutoffDate = System.Today();
        ShippingHandlingCalculations.newOpptyCutoffDate = System.Today();
        ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(null, opp, oliList);
        Test.stopTest();
    }
    
    @isTest
    static void calculateShippingFieldForQuote() {
        List<SBQQ__Quote__c> quotes = [SELECT Id, CurrencyIsoCode , SBQQ__Opportunity2__r.Segment_Sales_Role__c, Shipping_Method__c, Associated_Opportunity_Type__c, Configuration_Segment__c, CreatedDate,Est_Shipping_Cost__c, 
                                      Shipping_Account_Type__c, SBQQ__Opportunity2__c, Freight_Cost__c, Shipping_and_Handling_Value__c, Shipping_Country__c, 
                                      of_Accessories__c, of_HW_Products__c, Shipping_and_Handling_Manual__c,SBQQ__Opportunity2__r.Shipping_Method__c, SBQQ__Opportunity2__r.Shipping_Country__c, SBQQ__Opportunity2__r.CloseDate, SBQQ__Opportunity2__r.Probability 
                                      FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c != null];
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Product_Type__c, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__Product__r.Baseline_Cost__c 
                                               from SBQQ__QuoteLine__c  where SBQQ__Quote__c=:quotes[0].id];
        Test.startTest();
        ShippingHandlingCalculations.runningTestClass =true;
        ShippingHandlingCalculations.getShippingConfigurations();
        ShippingHandlingCalculations.calculateShippingFieldForQuote(null, quoteLines, quotes[0], null, 0);
        ShippingHandlingCalculations.newCutoffDate = System.Today();
        ShippingHandlingCalculations.newOpptyCutoffDate = System.Today();
        ShippingHandlingCalculations.calculateShippingFieldForQuote(null, quoteLines, quotes[0], null, 0);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateShippingAndHandlingForQuote() {
        List<SBQQ__Quote__c> quotes = [SELECT Id, CurrencyIsoCode , SBQQ__Opportunity2__r.Segment_Sales_Role__c, Shipping_Method__c, SBQQ__Opportunity2__r.Shipping_Method__c, SBQQ__Opportunity2__r.Shipping_Country__c, SBQQ__Opportunity2__r.CloseDate, SBQQ__Opportunity2__r.Probability, 
                                       Associated_Opportunity_Type__c, Configuration_Segment__c, CreatedDate,Est_Shipping_Cost__c, 
                                       Shipping_Account_Type__c, SBQQ__Opportunity2__c, Freight_Cost__c, Shipping_and_Handling_Value__c, 
                                       Shipping_Country__c, of_Accessories__c, of_HW_Products__c, Shipping_and_Handling_Manual__c 
                                       FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c != null];
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(
            [SELECT Id, CreatedDate, Freight_Cost__c, of_Accessories__c, of_HW_Products__c, 
            Shipping_and_Handling_Amount__c, Shipping_and_Handling_Manual__c, 
            Shipping_and_Handling_Value__c, Shipping_Method__c, Type, Segment__c,
            Shipping_Account_Type__c, Shipping_Country__c, SBQQ__PrimaryQuote__c  
            FROM Opportunity 
            WHERE Name = 'Test Opportunity']
        );
        Test.startTest();
        ShippingHandlingCalculations.updateShippingAndHandlingForQuote(quotes, opportunityMap);
        ShippingHandlingCalculations.performShippingHandlingCalculationsForQuote(quotes, opportunityMap);
        Test.stopTest();

        // Assert the expected values
        /*for (SBQQ__Quote__c quote : quotes) {
            System.assertNotEquals(null, quote.Shipping_and_Handling_Value__c, 'Shipping and Handling should be calculated');
        }*/
    }

    @isTest
    static void testCalculateSAndHPreCutoffOpp() {
        // Test for Non-Revenue Opportunity or Zero Products or Cust/Partner Account
        Opportunity opp = new Opportunity(
            Type = 'Non-Revenue Opportunity'
        );
        // Use the setReadOnlyFields method to set the read-only fields
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 0,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise',
            'CPQ_Opportunity__c' => false
        });
        Decimal result = ShippingHandlingCalculations.calculateSAndHPreCutoffOpp(opp);
        System.assertEquals(0, result, 'Expected 0 for non-revenue opportunity or zero products');

        // Test for Valid Freight Cost
        opp = new Opportunity(
            Type = 'Revenue Opportunity',
            Freight_Cost__c = 200.00
        );
        result = ShippingHandlingCalculations.calculateSAndHPreCutoffOpp(opp);
        System.assertEquals(200.00, result, 'Expected valid freight cost');

        // Test for Invalid Freight Cost
        opp = new Opportunity(
            Type = 'Revenue Opportunity',
            Freight_Cost__c = 99999.99
        );
        result = ShippingHandlingCalculations.calculateSAndHPreCutoffOpp(opp);
        System.assertEquals(99999.99, result, 'Expected invalid freight cost value');
    }

    @isTest
    static void testCalculateSAndHFirstCutoffOpp() {
        // Test for Revenue Opportunity in US or Canada
        Opportunity opp = new Opportunity(
            Type = 'Revenue Opportunity',
            Shipping_Country__c = 'United States',
            Shipping_Method__c = 'ground'
        );
        // Use setReadOnlyFields to set read-only fields
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        Decimal result = ShippingHandlingCalculations.calculateSAndHFirstCutoffOpp(opp, 0.0);
        System.assert(result > 0, 'Expected calculated shipping cost for revenue opportunity in US');

        // Test for Zero Products
        opp = new Opportunity(
            Type = 'Revenue Opportunity',
            Shipping_Country__c = 'United States'
        );
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 0,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateSAndHFirstCutoffOpp(opp, 0.0);
        System.assertEquals(0, result, 'Expected 0 for zero products');

        // Test for Cust/Partner Account
        opp = new Opportunity(
            Type = 'Revenue Opportunity',
            Shipping_Country__c = 'United States',
            Shipping_Account_Type__c = 'Cust/Partner Account'
        );
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateSAndHFirstCutoffOpp(opp, 0.0);
        System.assertEquals(0, result, 'Expected 0 for Cust/Partner account');

        // Test for Non-Revenue Opportunity
        opp = new Opportunity(
            Type = 'Non-Revenue Opportunity',
            Shipping_Country__c = 'United States'
        );
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateSAndHFirstCutoffOpp(opp, 0.0);
        System.assertEquals(0, result, 'Expected 0 for non-revenue opportunity');

        // Test for Valid Freight Cost
        opp = new Opportunity(
            Type = 'Revenue Opportunity',
            Shipping_Country__c = 'United States',
            Freight_Cost__c = 200.00
        );
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateSAndHFirstCutoffOpp(opp, 0.0);

        // Test for Invalid Freight Cost
        opp = new Opportunity(
            Type = 'Revenue Opportunity',
            Shipping_Country__c = 'United States',
            Freight_Cost__c = 99999.99
        );
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateSAndHFirstCutoffOpp(opp, 0.0);
    }

    @isTest
    static void testCalculateSAndHSecondCutoff() {
        Opportunity opp = [SELECT Id, CreatedDate, Freight_Cost__c, of_Accessories__c, of_HW_Products__c, Segment__c, Shipping_and_Handling_Amount__c, Shipping_and_Handling_Manual__c, Shipping_and_Handling_Value__c, Shipping_Method__c, Type FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Test.startTest();
        Decimal result = ShippingHandlingCalculations.calculateSAndHSecondCutoff(opp, opp.Segment__c, 0.0);
        Test.stopTest();

        // Assert the expected result
        System.assert(result >= 0, 'Shipping and Handling should be calculated');
    }

    @isTest
    static void testCalculateShippingFieldForQuote() {
        Date secondCutoffDate = Date.valueOf(Label.Cut_off_Date_for_S_H_calculcation);
        Date cutoffDate = Date.newInstance(2024, 12, 12);

        // Test for Quote Created After Second Cutoff Date
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            CreatedDate = secondCutoffDate.addDays(1),
            Shipping_Country__c = 'United States'
        );
        // Use the setReadOnlyFields method to set the read-only field
        quote = (SBQQ__Quote__c) setReadOnlyFields(quote, new Map<String, Object>{
            'Associated_Opportunity_Type__c' => 'Revenue Opportunity'
        });
        Opportunity opp = new Opportunity();
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'Segment__c' => 'Enterprise'
        });
        Decimal result = ShippingHandlingCalculations.calculateShippingFieldForQuote(quote, opp.Segment__c, 0.0);
        System.assert(result > 0, 'Expected calculated shipping and handling for quote after second cutoff date');

        // Test for Manual Shipping and Handling
        quote = new SBQQ__Quote__c(
            Shipping_and_Handling_Manual__c = 100.00
        );
        result = ShippingHandlingCalculations.calculateShippingFieldForQuote(quote, opp.Segment__c, 0.0);

        // Test for Quote Created After Cutoff Date
        quote = new SBQQ__Quote__c(
            CreatedDate = cutoffDate.addDays(1),
            Shipping_Country__c = 'United States'
        );
        result = ShippingHandlingCalculations.calculateShippingFieldForQuote(quote, opp.Segment__c, 0.0);

        // Test for Default Case
        quote = new SBQQ__Quote__c(
            CreatedDate = cutoffDate.addDays(-1),
            Shipping_Country__c = 'United States'
        );
        result = ShippingHandlingCalculations.calculateShippingFieldForQuote(quote, opp.Segment__c, 0.0);
        System.assert(result >= 0, 'Expected calculated shipping and handling for quote before cutoff date');
    }

    @isTest
    static void testCalculateSAndHFirstCutoffQuote() {
        SBQQ__Quote__c quote = [SELECT  Id, Associated_Opportunity_Type__c, Configuration_Segment__c, CreatedDate,Est_Shipping_Cost__c, Shipping_Account_Type__c, SBQQ__Opportunity2__c, Freight_Cost__c, Shipping_and_Handling_Value__c, Shipping_Country__c, of_Accessories__c, of_HW_Products__c, Shipping_and_Handling_Manual__c, Shipping_Method__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c != null LIMIT 1];
        Test.startTest();
        Decimal result = ShippingHandlingCalculations.calculateSAndHFirstCutoffQuote(quote, 0.0);
        Test.stopTest();

        // Assert the expected result
        System.assert(result >= 0, 'Shipping and Handling should be calculated');
    }

    @isTest
    static void testCalculateSAndHPreCutoffQuote() {
        // Test for Cust/Partner Account or Non-Revenue Opportunity or Zero Products
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        // Use the setReadOnlyFields method to set the read-only fields
        quote = (SBQQ__Quote__c) setReadOnlyFields(quote, new Map<String, Object>{
            'Associated_Opportunity_Type__c' => 'Non-Revenue Opportunity',
            'of_HW_Products__c' => 0,
            'of_Accessories__c' => 0
        });
        Decimal result = ShippingHandlingCalculations.calculateSAndHPreCutoffQuote(quote, 0.0);
        System.assertEquals(0, result, 'Expected 0 for non-revenue opportunity or zero products');

        // Test for Manual Shipping and Handling
        quote = (SBQQ__Quote__c) setReadOnlyFields(quote, new Map<String, Object>{
            'Associated_Opportunity_Type__c' => 'Revenue Opportunity',
            'of_HW_Products__c' => 10,
            'of_Accessories__c' => 20,
            'Shipping_and_Handling_Manual__c' => 100.00
        });
        result = ShippingHandlingCalculations.calculateSAndHPreCutoffQuote(quote, 0.0);

        // Test for Estimated Shipping Cost
        quote = new SBQQ__Quote__c();
        quote = (SBQQ__Quote__c) setReadOnlyFields(quote, new Map<String, Object>{
            'Associated_Opportunity_Type__c' => 'Revenue Opportunity',
            'of_HW_Products__c' => 10,
            'of_Accessories__c' => 20,
            'Est_Shipping_Cost__c' => 150.00
        });
        result = ShippingHandlingCalculations.calculateSAndHPreCutoffQuote(quote, 0.0);

        // Test for Valid Freight Cost
        quote = new SBQQ__Quote__c();
        quote = (SBQQ__Quote__c) setReadOnlyFields(quote, new Map<String, Object>{
            'Associated_Opportunity_Type__c' => 'Revenue Opportunity',
            'of_HW_Products__c' => 10,
            'of_Accessories__c' => 20,
            'Freight_Cost__c' => 200.00,
            'Configuration_Segment__c' => 'Express'
        });
        result = ShippingHandlingCalculations.calculateSAndHPreCutoffQuote(quote, 0.0);

        // Test for Invalid Freight Cost
        quote = new SBQQ__Quote__c();
        quote = (SBQQ__Quote__c) setReadOnlyFields(quote, new Map<String, Object>{
            'Associated_Opportunity_Type__c' => 'Revenue Opportunity',
            'of_HW_Products__c' => 10,
            'of_Accessories__c' => 20,
            'Freight_Cost__c' => 99999.99
        });
        result = ShippingHandlingCalculations.calculateSAndHPreCutoffQuote(quote, 0.0);
    }

    @isTest
    static void testCalculateFreightCostForExpress() {
        SBQQ__Quote__c quote = [SELECT Id, Associated_Opportunity_Type__c, Configuration_Segment__c, CreatedDate, of_Accessories__c, of_HW_Products__c, Shipping_Account_Type__c, SBQQ__Opportunity2__c, Freight_Cost__c, Shipping_and_Handling_Value__c, Shipping_and_Handling_Manual__c, Est_Shipping_Cost__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c != null LIMIT 1];
        Test.startTest();
        Decimal result = ShippingHandlingCalculations.calculateFreightCostForExpress(quote, 0.0);
        Test.stopTest();

        // Assert the expected result
        System.assert(result >= 0, 'Freight cost should be calculated');
    }

    @isTest
    static void testCalculateShippingCostBasedOnMethod() {
        // Test for 'ground' or 'worldwide expedited'
        Opportunity opp = new Opportunity(Shipping_Method__c = 'ground');
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        Decimal result = ShippingHandlingCalculations.calculateShippingCostBasedOnMethod(opp, 0.0);

        opp = new Opportunity(Shipping_Method__c = 'worldwide expedited');
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 10,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateShippingCostBasedOnMethod(opp, 0.0);
        System.assert(result > 15, 'Expected calculated cost for worldwide expedited shipping');

        // Test for 'economy'
        opp = new Opportunity(Shipping_Method__c = 'economy');
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 3,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateShippingCostBasedOnMethod(opp, 0.0);
        System.assertEquals(15, result, 'Expected minimum cost for economy shipping');

        opp = new Opportunity(Shipping_Method__c = 'economy');
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 10,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateShippingCostBasedOnMethod(opp, 0.0);
        System.assert(result > 15, 'Expected calculated cost for economy shipping');

        // Test for 'next day air' or 'ups_next_day_air'
        opp = new Opportunity(Shipping_Method__c = 'next day air');
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateShippingCostBasedOnMethod(opp, 0.0);
        System.assertEquals(60, result, 'Expected minimum cost for next day air shipping');

        opp = new Opportunity(Shipping_Method__c = 'ups_next_day_air');
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 10,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateShippingCostBasedOnMethod(opp, 0.0);
        System.assert(result > 60, 'Expected calculated cost for UPS next day air shipping');

        // Test for an unsupported shipping method
        opp = new Opportunity(Shipping_Method__c = 'unsupported method');
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateShippingCostBasedOnMethod(opp, 0.0);
        System.assertEquals(0, result, 'Expected cost of 0 for unsupported shipping method');
    }

    @isTest
    static void testGetTotalProducts() {
        Opportunity opp = [SELECT Id, CreatedDate, Freight_Cost__c, of_Accessories__c, of_HW_Products__c, Shipping_and_Handling_Amount__c, Shipping_and_Handling_Manual__c, Shipping_and_Handling_Value__c, Shipping_Method__c, Type FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Test.startTest();
        Decimal totalProducts = ShippingHandlingCalculations.getTotalProducts(opp);
        Test.stopTest();

        // Assert the expected result
        //System.assert(totalProducts > 0, 'Total products should be greater than zero');
    }

    @isTest
    static void testGetShippingMethod() {
        Opportunity opp = [SELECT Id, CreatedDate, Freight_Cost__c, of_Accessories__c, of_HW_Products__c, Shipping_and_Handling_Amount__c, Shipping_and_Handling_Manual__c, Shipping_and_Handling_Value__c, Shipping_Method__c, Type FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Test.startTest();
        String shippingMethod = ShippingHandlingCalculations.getShippingMethod(opp);
        Test.stopTest();

        // Assert the expected result
        System.assertNotEquals('', shippingMethod, 'Shipping method should not be empty');
    }

    @isTest
    static void testIsStandardShippingMethod() {
        Test.startTest();
        Boolean isStandard = ShippingHandlingCalculations.isStandardShippingMethod('ground');
        Test.stopTest();

        // Assert the expected result
        System.assert(isStandard, 'Ground should be a standard shipping method');
    }

    @isTest
    static void testIsCustPartnerAccount() {
        Opportunity opp = [SELECT Id, CreatedDate, Freight_Cost__c, of_Accessories__c, of_HW_Products__c, Shipping_Account_Type__c, Shipping_and_Handling_Amount__c, Shipping_and_Handling_Manual__c, Shipping_and_Handling_Value__c, Shipping_Method__c, Type FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Test.startTest();
        Boolean isCustPartner = ShippingHandlingCalculations.isCustPartnerAccount(opp);
        Test.stopTest();

        // Assert the expected result
        System.assert(!isCustPartner, 'Test opportunity should not be a Cust/Partner account');
    }

    @isTest
    static void testIsValidFreightCost() {
        Test.startTest();
        Boolean isValid = ShippingHandlingCalculations.isValidFreightCost(100.00);
        Test.stopTest();

        // Assert the expected result
        System.assert(isValid, 'Freight cost should be valid');
    }

    @isTest
    static void testIsInvalidFreightCost() {
        Test.startTest();
        Boolean isInvalid = ShippingHandlingCalculations.isInvalidFreightCost(99999.99);
        Test.stopTest();

        // Assert the expected result
        System.assert(isInvalid, 'Freight cost should be invalid');
    }

    @isTest
    static void testIsUSOrCanada() {
        Test.startTest();
        Boolean isUSOrCanada = ShippingHandlingCalculations.isUSOrCanada('United States');
        Test.stopTest();

        // Assert the expected result
        System.assert(isUSOrCanada, 'Country should be US or Canada');
    }

    @isTest
    static void testIsZeroProducts() {
        Opportunity opp = [SELECT Id, CreatedDate, Freight_Cost__c, of_Accessories__c, of_HW_Products__c, Shipping_and_Handling_Amount__c, Shipping_and_Handling_Manual__c, Shipping_and_Handling_Value__c, Shipping_Method__c, Type FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Test.startTest();
        Boolean isZero = ShippingHandlingCalculations.isZeroProducts(opp);
        Test.stopTest();

        // Assert the expected result
        //System.assert(!isZero, 'Test opportunity should not have zero products');
    }

    @isTest
    static void testCalculateShippingAndHandlingForOpportunity() {
        Date cutoffDate = Date.newInstance(2024, 12, 12);
        Date secondCutoffDate = Date.valueOf(Label.Cut_off_Date_for_S_H_calculcation);

        // Test for CPQ Opportunity
        Opportunity opp = new Opportunity(
            Shipping_and_Handling_Amount__c = 150.00
        );
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'CPQ_Opportunity__c' => true,
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        Decimal result = ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(opp, null);
        System.assertEquals(150.00, result, 'Expected shipping and handling amount for CPQ opportunity');

        // Test for Manual Shipping and Handling
        opp = new Opportunity(
            Shipping_and_Handling_Manual__c = 100.00
        );
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(opp, null);
        System.assertEquals(100.00, result, 'Expected manual shipping and handling value');

        // Test for Created Date Before Cutoff Date
        opp = new Opportunity(
            CreatedDate = cutoffDate.addDays(-1),
            Type = 'Revenue Opportunity'
        );
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(opp, null);
        System.assert(result >= 0, 'Expected calculated shipping and handling for opportunity before cutoff date');

        // Test for Created Date Before Second Cutoff Date
        opp = new Opportunity(
            CreatedDate = secondCutoffDate.addDays(-1),
            Type = 'Revenue Opportunity'
        );
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(opp, null);
        System.assert(result >= 0, 'Expected calculated shipping and handling for opportunity before second cutoff date');

        // Test for US or Canada Revenue Opportunity
        opp = new Opportunity(
            CreatedDate = secondCutoffDate.addDays(1),
            Type = 'Revenue Opportunity',
            Shipping_Country__c = 'United States'
        );
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(opp, null);
        System.assert(result >= 0, 'Expected calculated shipping and handling for US or Canada revenue opportunity');

        // Test for Default Case
        opp = new Opportunity(
            CreatedDate = secondCutoffDate.addDays(1),
            Type = 'Revenue Opportunity',
            Shipping_Country__c = 'Other'
        );
        opp = (Opportunity) setReadOnlyFields(opp, new Map<String, Object>{
            'of_HW_Products__c' => 5,
            'of_Accessories__c' => 0,
            'Segment__c' => 'Enterprise'
        });
        result = ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(opp, null);
        System.assert(result >= 0, 'Expected calculated shipping and handling for default case');
    }
    
    @isTest
    static void testCalculateFreightCostForExpress2() {
        SBQQ__Quote__c quote = [SELECT Id, Associated_Opportunity_Type__c, Configuration_Segment__c, CreatedDate, of_Accessories__c, of_HW_Products__c, Shipping_Account_Type__c, SBQQ__Opportunity2__c, Freight_Cost__c, Shipping_and_Handling_Value__c, Shipping_and_Handling_Manual__c, Est_Shipping_Cost__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c != null LIMIT 1];
        Test.startTest();
        quote = (SBQQ__Quote__c) setReadOnlyFields(quote, new Map<String, Object>{
            'Freight_Cost__c' => 200.00,
            'Configuration_Segment__c' => 'Express'
        });
        Decimal result = ShippingHandlingCalculations.calculateFreightCostForExpress(quote, 0.0);
        Test.stopTest();

        // Assert the expected result
        System.assert(result >= 0, 'Freight cost should be calculated');
    }
    
    @isTest
    static void testCalculateFreightCostForExpress3() {
        SBQQ__Quote__c quote = [SELECT Id, Associated_Opportunity_Type__c, Configuration_Segment__c, CreatedDate, of_Accessories__c, of_HW_Products__c, Shipping_Account_Type__c, SBQQ__Opportunity2__c, Freight_Cost__c, Shipping_and_Handling_Value__c, Shipping_and_Handling_Manual__c, Est_Shipping_Cost__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c != null LIMIT 1];
        Test.startTest();
        quote = (SBQQ__Quote__c) setReadOnlyFields(quote, new Map<String, Object>{
            'Freight_Cost__c' => 200.00,
            'Configuration_Segment__c' => 'Express',
            'of_HW_Products__c' => 25,
            'of_Accessories__c' => 30
        });
        Decimal result = ShippingHandlingCalculations.calculateFreightCostForExpress(quote, 0.0);
        Test.stopTest();

        // Assert the expected result
        System.assert(result >= 0, 'Freight cost should be calculated');
    }
    
    @isTest
    static void testCalculateFreightCostForExpress4() {
        SBQQ__Quote__c quote = [SELECT Id, Associated_Opportunity_Type__c, Configuration_Segment__c, CreatedDate, of_Accessories__c, of_HW_Products__c, Shipping_Account_Type__c, SBQQ__Opportunity2__c, Freight_Cost__c, Shipping_and_Handling_Value__c, Shipping_and_Handling_Manual__c, Est_Shipping_Cost__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c != null LIMIT 1];
        Test.startTest();
        quote = (SBQQ__Quote__c) setReadOnlyFields(quote, new Map<String, Object>{
            'Freight_Cost__c' => 200.00,
            'Configuration_Segment__c' => 'Express',
            'of_HW_Products__c' => 100,
            'of_Accessories__c' => 30
        });
        Decimal result = ShippingHandlingCalculations.calculateFreightCostForExpress(quote, 0.0);
        Test.stopTest();

        // Assert the expected result
        System.assert(result >= 0, 'Freight cost should be calculated');
    }
    
    @isTest
    static void testCalculateFreightCostForExpress5() {
        SBQQ__Quote__c quote = [SELECT Id, Associated_Opportunity_Type__c, Configuration_Segment__c, CreatedDate, of_Accessories__c, of_HW_Products__c, Shipping_Account_Type__c, SBQQ__Opportunity2__c, Freight_Cost__c, Shipping_and_Handling_Value__c, Shipping_and_Handling_Manual__c, Est_Shipping_Cost__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c != null LIMIT 1];
        Test.startTest();
        quote = (SBQQ__Quote__c) setReadOnlyFields(quote, new Map<String, Object>{
            'Freight_Cost__c' => 200.00,
            'Configuration_Segment__c' => 'Express',
            'of_HW_Products__c' => 250,
            'of_Accessories__c' => 350
        });
        Decimal result = ShippingHandlingCalculations.calculateFreightCostForExpress(quote, 0.0);
        Test.stopTest();

        // Assert the expected result
        System.assert(result >= 0, 'Freight cost should be calculated');
    }

    // Method to set read-only fields
    public static SObject setReadOnlyFields(SObject record, Map<String, Object> changesToFields) {
        String serializedRecord = JSON.serialize(record);
        Map<String, Object> deserializedRecordMap = (Map<String, Object>) JSON.deserializeUntyped(serializedRecord);

        for (String sObjectField : changesToFields.keySet()) {
            deserializedRecordMap.put(sObjectField, changesToFields.get(sObjectField));
        }

        serializedRecord = JSON.serialize(deserializedRecordMap);
        return (SObject) JSON.deserialize(serializedRecord, SObject.class);
    }
}