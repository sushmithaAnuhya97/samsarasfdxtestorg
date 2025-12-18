@isTest(SeeAllData=false)
private class TrialOpptyUpdaterTest {

    @TestSetup static void testData() {
        
        byPassMethods();
        Global_Automation_Settings__c gas = Global_Automation_Settings__c.getInstance();
        if (gas == null) {
            gas = new Global_Automation_Settings__c(SetupOwnerId = UserInfo.getOrganizationId());
        }
        gas.Skip_Specific_Triggers__c = 'Account Contact Product2 OpportunityLineItem OrderItem ShippingAddress';
        upsert gas;
        Account a = new Account (Name = 'Trial Oppty Updater Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;

        Contact c = new Contact(AccountId = a.Id, LastName = 'blah', Email = 'test@test.test');
        insert c;

        List<Opportunity> opptiesToInsert = new List<Opportunity>();

        // create rev oppty
        Opportunity rev = new Opportunity(AccountId = a.Id, Name = 'Trial Oppty Updater Rev',
                CloseDate = System.today() + 90, StageName = 'Incubate', Type = 'Revenue Opportunity');
        setShipping(rev, c);
        opptiesToInsert.add(rev);

        RecordType trialType = [
                SELECT Id
                FROM RecordType
                WHERE SObjectType = 'Opportunity'
                AND Name = 'Trial'
                LIMIT 1
        ];

        // create trials
        Opportunity trial = new Opportunity(AccountId = a.Id, Name = 'Trial Oppty Updater Free Trial',
                CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
                Probability = 0, StageName = 'Incubate', type = 'Free Trial Opportunity');
        setShipping(trial, c);
        opptiesToInsert.add(trial);
        Opportunity trial2 = new Opportunity(AccountId = a.Id, Name = 'Trial Oppty Updater Free Trial2',
                CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
                Probability = 0, StageName = 'Incubate', type = 'Free Trial Opportunity');
        setShipping(trial2, c);
        opptiesToInsert.add(trial2);

        insert opptiesToInsert;
    }
    
    static testMethod void testTrialPurchase() {
        // Query our oppties
        
   	    List<Opportunity> oppties = [
                SELECT Id, Name, Type, StageName, Probability,
                        Trial_Agreement_Accepted__c,
                        TrialResolutionOppty__c, FT_Return__c,
                        Returning_Opportunity__c
                FROM Opportunity
                WHERE Name LIKE '%Trial Oppty Updater%'
                LIMIT 3
        ];
        Opportunity rev;
        Opportunity trial;
        Opportunity trial2;
        List<Opportunity> trials = new List<Opportunity>();

        // Assign names to trials
        for (Opportunity oppty : oppties) {
            if (oppty.Name.contains('Rev')) {
                rev = oppty;
            }
            else if (oppty.Name.contains('Trial2')) {
                trial2 = oppty;
            }
            else {
                trial = oppty;
            }
        }

        // ship trial
        trial.Trial_Agreement_Accepted__c = true;
        trial.Probability = 100;
        trial.StageName = 'Closed Won';
        trial.TrialResolutionOppty__c = rev.Id;

        // Commit trial update first so TrialResolutionOppty__c is visible in DB
        byPassMethods();
        update trial;

        test.startTest();
        OpportunityTriggerHandlerContext.maxRuns = 3; // allow multiple phases
        // Now commit revenue Closed Won so handleRevenueUpdate sees DB-mapped trials
        rev.StageName = 'Closed Won';
        rev.Probability = 100;
        byPassMethods();
        update rev;
        system.debug('revOpp***' + [Select id, stageName, type FROM Opportunity WHERE Id = :rev.Id]);
        System.assertEquals('Purchased', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].Trial_Status__c);
        test.stopTest();
    }

    static testMethod void testMultipleTrialPurchase() {
        OpportunityTriggerHandlerContext.maxRuns = 4; // Inorder to complete the third cycle 3 time update in test class

        // Query our oppties
        List<Opportunity> oppties = [
                SELECT Id, Name, Type, StageName, Probability,
                        Trial_Agreement_Accepted__c,
                        TrialResolutionOppty__c, FT_Return__c,
                        Returning_Opportunity__c
                FROM Opportunity
                WHERE Name LIKE '%Trial Oppty Updater%'
                LIMIT 3
        ];
        Opportunity rev;
        Opportunity trial;
        Opportunity trial2;

        // Assign names to trials
        for (Opportunity oppty : oppties) {
            if (oppty.Name.contains('Rev')) {
                rev = oppty;
            }
            else if (oppty.Name.contains('Trial2')) {
                trial2 = oppty;
            }
            else {
                trial = oppty;
            }
        }

        // ship trials and link to revenue in first commit
        trial.Trial_Agreement_Accepted__c = true;
        trial.Probability = 100;
        trial.StageName = 'Closed Won';
        trial.TrialResolutionOppty__c = rev.Id;
        trial2.TrialResolutionOppty__c = rev.Id;
        List<Opportunity> trials = new List<Opportunity>{trial, trial2};

        // commit trial links first (outside startTest)
        byPassMethods();
        update trials;

        Test.startTest();
        // now close-won the revenue so handleRevenueUpdate sets both to Purchased
        rev.StageName = 'Closed Won';
        rev.Probability = 100;
        byPassMethods();
        update rev;

        Test.stopTest();
        System.assertEquals('Purchased', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].Trial_Status__c);
        System.assertEquals('Purchased', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :trial2.Id LIMIT 1].Trial_Status__c);
    }

    static testMethod void testTrialReturn1() {
        OpportunityTriggerHandlerContext.maxRuns = 5;
        // Query our oppties
        List<Opportunity> oppties = [
                SELECT Id, Name, Type, StageName, Probability,
                        Trial_Agreement_Accepted__c,
                        TrialResolutionOppty__c, FT_Return__c,
                        Returning_Opportunity__c
                FROM Opportunity
                WHERE Name LIKE '%Trial Oppty Updater%'
                LIMIT 3
        ];
        Opportunity rev;
        Opportunity trial;
        Opportunity trial2;
        List<Opportunity> lstTrials = new List<Opportunity>();

        // Assign names to trials
        for (Opportunity oppty : oppties) {
            if (oppty.Name.contains('Rev')) {
                rev = oppty;
            }
            else if (oppty.Name.contains('Trial2')) {
                trial2 = oppty;
            }
            else {
                trial = oppty;
            }
        }

        // ship trial and link to revenue
        trial.Trial_Agreement_Accepted__c = true;
        trial.Probability = 100;
        trial.StageName = 'Closed Won';
        trial.TrialResolutionOppty__c = rev.Id;

        // commit trial ship + link (outside startTest)
        byPassMethods();
        update trial;

        // make rev oppty closed-lost (outside startTest)
        rev.StageName = 'Closed Lost';
        rev.Probability = 0;
        byPassMethods();
        update rev;

        Test.startTest();
        System.assertEquals('Open', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].Trial_Status__c);

        Account a = [
                SELECT Id
                FROM Account
                WHERE Name LIKE '%Trial Oppty Updater%'
                LIMIT 1
        ];

        

        System.debug(LoggingLevel.INFO, 'test: ' + trial.Id);

        // Creat free trial return oppty
        Opportunity ret = new Opportunity(AccountId = a.Id, Name = 'Trial Oppty Return', CloseDate = System.today() + 90,
                StageName = 'Return Created', Probability = 10, type = 'Free Trial Return', Returning_Opportunity__c = trial.Id);
        
        byPassMethods();
        insert ret; // afterInsert sets FT_Return__c on trial
        
        // Trial opp's 'free trial return' = Trial return's 'returning opp'
        ret = [
                SELECT Id, Returning_Opportunity__c
                FROM Opportunity
                WHERE Name = 'Trial Oppty Return'
                LIMIT 1
        ];
        trial = [
                SELECT Id, FT_Return__c, Trial_Status__c
                FROM Opportunity
                WHERE Id = :trial.Id
        ];
        System.assertEquals(trial.FT_Return__c, ret.Id);
        System.assertEquals(ret.Returning_Opportunity__c, trial.Id);

        // Move return to next stage inside startTest
        ret.StageName = 'Return Label Sent';
        ret.Probability = 35;
        byPassMethods();
        update ret;
        Test.stopTest();
        System.assertEquals('Return In Process', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].Trial_Status__c);
    }
    
    static testMethod void testTrialReturn2() {
        OpportunityTriggerHandlerContext.maxRuns = 5;
        // Query our oppties
        List<Opportunity> oppties = [
                SELECT Id, Name, Type, StageName, Probability,
                        Trial_Agreement_Accepted__c,
                        TrialResolutionOppty__c, FT_Return__c,
                        Returning_Opportunity__c
                FROM Opportunity
                WHERE Name LIKE '%Trial Oppty Updater%'
                LIMIT 3
        ];
        Opportunity rev;
        Opportunity trial;
        Opportunity trial2;
        List<Opportunity> lstTrials = new List<Opportunity>();

        // Assign names to trials
        for (Opportunity oppty : oppties) {
            if (oppty.Name.contains('Rev')) {
                rev = oppty;
            }
            else if (oppty.Name.contains('Trial2')) {
                trial2 = oppty;
            }
            else {
                trial = oppty;
            }
        }

        // ship trial and link to revenue
        trial.Trial_Agreement_Accepted__c = true;
        trial.Probability = 100;
        trial.StageName = 'Closed Won';
        trial.TrialResolutionOppty__c = rev.Id;

        // commit trial ship + link (outside startTest)
        byPassMethods();
        update trial;

        // make rev oppty closed-lost (outside startTest)
        rev.StageName = 'Closed Lost';
        rev.Probability = 0;
        byPassMethods();
        update rev;

        Test.startTest();

        Account a = [
                SELECT Id
                FROM Account
                WHERE Name LIKE '%Trial Oppty Updater%'
                LIMIT 1
        ];

        
        System.debug(LoggingLevel.INFO, 'test: ' + trial.Id);

        // Creat free trial return oppty
        Opportunity ret = new Opportunity(AccountId = a.Id, Name = 'Trial Oppty Return', CloseDate = System.today() + 90,
                StageName = 'Return Created', Probability = 10, type = 'Free Trial Return', Returning_Opportunity__c = trial.Id);
        byPassMethods();
        insert ret;

        // Trial opp's 'free trial return' = Trial return's 'returning opp'
        ret = [
                SELECT Id, Returning_Opportunity__c
                FROM Opportunity
                WHERE Name = 'Trial Oppty Return'
                LIMIT 1
        ];
        trial = [
                SELECT Id, FT_Return__c, Trial_Status__c
                FROM Opportunity
                WHERE Id = :trial.Id
        ];
        System.assertEquals(trial.FT_Return__c, ret.Id);
        System.assertEquals(ret.Returning_Opportunity__c, trial.Id);

        // Move to Returned inside startTest
        ret.StageName = 'Refunded - Closed';
        ret.Probability = 100;
        byPassMethods();
        update ret;
        
        Test.stopTest();
        System.assertEquals('Returned', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].Trial_Status__c);
    }

    static testMethod void testAssignmentAfterResolutionClose() {
        OpportunityTriggerHandlerContext.maxRuns = 5; // Inorder to complete the third cycle 4 time update in test class

        // Query our oppties
        List<Opportunity> oppties = [
                SELECT Id, Name, Type, StageName, Probability,
                        Trial_Agreement_Accepted__c,
                        TrialResolutionOppty__c, FT_Return__c,
                        Returning_Opportunity__c
                FROM Opportunity
                WHERE Name LIKE '%Trial Oppty Updater%'
                LIMIT 3
        ];
        Opportunity rev;
        Opportunity trial;
        Opportunity trial2;
        List<Opportunity> trialList = new List<Opportunity>();

        // Assign names to trials
        for (Opportunity oppty : oppties) {
            if (oppty.Name.contains('Rev')) {
                rev = oppty;
            }
            else if (oppty.Name.contains('Trial2')) {
                trial2 = oppty;
            }
            else {
                trial = oppty;
            }
        }

        // ship trial
        trial.Trial_Agreement_Accepted__c = true;
        trial.Probability = 100;
        trial.StageName = 'Closed Won';
        
        // Close-win rev outside startTest to reduce governor pressure
        byPassMethods();
        rev.StageName = 'Closed Won';
        rev.Probability = 100;
        update rev;

        test.startTest();
        byPassMethods();
        // Associate trial with already-won revenue oppty inside startTest
        trial.TrialResolutionOppty__c = rev.Id;
        update trial;
        System.assertEquals('Purchased', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].Trial_Status__c);
        test.stopTest();
    }

    static testMethod void testDelete() {
        OpportunityTriggerHandlerContext.maxRuns = 8;

        // Query our oppties
        List<Opportunity> oppties = [
                SELECT Id, Name, Type, StageName, Probability,
                        Trial_Agreement_Accepted__c,
                        TrialResolutionOppty__c, FT_Return__c,
                        Returning_Opportunity__c
                FROM Opportunity
                WHERE Name LIKE '%Trial Oppty Updater%'
                LIMIT 3
        ];
        Opportunity rev;
        Opportunity trial;
        Opportunity trial2;
        List<Opportunity> lstTrials = new List<Opportunity>();

        // Assign names to trials
        for (Opportunity oppty : oppties) {
            if (oppty.Name.contains('Rev')) {
                rev = oppty;
            }
            else if (oppty.Name.contains('Trial2')) {
                trial2 = oppty;
            }
            else {
                trial = oppty;
            }
        }

        // ship trial
        trial.Probability = 100;
        trial.StageName = 'Closed Won';
        trial.Trial_Agreement_Accepted__c = true;
        DiagnosticsInstrumentation.debug('Updating trial to Closed Won');
        System.debug('Updating trial to closed won');
        
        Test.startTest();
        byPassMethods();
        //lstTrials.add(trial);
        //update trial;
        //System.assertEquals('Open', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].Trial_Status__c);

        // Associate trial with revenue oppty
        trial.TrialResolutionOppty__c = rev.Id;
        DiagnosticsInstrumentation.debug('Associating trial with rev opp');
        byPassMethods();
        lstTrials.add(trial);
        //System.assertEquals('Open', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].Trial_Status__c);

        // make rev oppty closed-won
        rev.StageName = 'Closed Won';
        rev.Probability = 100;
        DiagnosticsInstrumentation.debug('Updating rev opp to closed won');
        System.debug(LoggingLevel.INFO, 'Updating rev opp to closed won');
        byPassMethods();
        lstTrials.add(rev);
        update lstTrials;
		//System.assertEquals('Purchased', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].Trial_Status__c);

        // delete rev
        DiagnosticsInstrumentation.debug('Deleting rev opp');
        byPassMethods();
        delete rev;
        System.assertEquals('Open', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].Trial_Status__c);
        System.assertEquals(Null, [SELECT TrialResolutionOppty__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].TrialResolutionOppty__c);
        
        Test.stopTest();
    }

    static private void setShipping(Opportunity o, Contact c) {
        o.Shipping_Contact__c = c.Id;

        o.Shipping_Address_Line_1__c = 'x';
        o.Shipping_City__c = 'x';
        o.Shipping_State__c = 'x';
        o.Shipping_Zip_Code__c = 'x';
        o.Shipping_Country__c = 'Canada';
    }
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        return randStr;
    }

    static private void addOpptyProducts(Opportunity o) {

        Product2 prod = new Product2(Name = 'Laptop X200', Family = 'Hardware');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry standardPrice = new PricebookEntry(
                Pricebook2Id = pricebookId, Product2Id = prod.Id,
                UnitPrice = 10000, IsActive = true);
        insert standardPrice;

        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=o.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        Test.startTest();
        insert li;
        Test.stopTest();
    }
    
    public static void byPassMethods(){
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        // Keep Opportunity triggers active
        //TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        //TriggerHandler.bypass('OpportunityTriggerHandler');

        // Bypass high-chatter related handlers to avoid extra queries
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('Product2TriggerHandler');
        TriggerHandler.bypass('OrderItemTriggerHandler');
        TriggerHandler.bypass('ShippingAddressHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
    }
}