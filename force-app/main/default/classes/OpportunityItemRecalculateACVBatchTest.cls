@IsTest
public without sharing class OpportunityItemRecalculateACVBatchTest {
    
    // Required for finding the report in question. The records are overriden to make sure the data processed is the one created in this test.
    @IsTest (SeeAllData = true)
    static void testStartMethod(){
        SBQQ.TriggerControl.disable();
        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(
            SetupOwnerId = UserInfo.getUserId(),
            Allow_Handler_Selection__c = true,
            Skip_Specific_Triggers__c = 'Account Contact Opportunity SBQQQuote SBQQQuoteLine Task'
        );
        insert setting;
        Id pricebookId = Test.getStandardPricebookId();
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name = 'LIC-VG33', ProductCode = 'LIC-VG33', Family = 'Test');
        products.add(vg33);
        insert products;
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 1000, IsActive = true);
        pricebookEntries.add(vg33PB);
        insert pricebookEntries;

        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        insert accountOne;
        
        Opportunity opp = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 2 Inc',
                                                      StageName = 'Qualified',
                                                      Price_Book_Name__c = 'Standard',
                                                      Renewal__c = true,
                                                      License_Term__c = 36,
                                                      CloseDate = System.today(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        insert opp;

        delete setting;
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 100,
            PriceBookEntryId = vg33PB.Id,
            UnitPrice = vg33pb.UnitPrice,
            is_acv__c = true
        );
        insert oli;

        opp.License_Term__c = 14;
        update opp;

        // ASSERTING THAT THE ISSUE PERSISTS, THEREFORE THE BATCH IS STILL REQUIRED TO RUN.
        OpportunityLineItem truth = [SELECT ACV_Total_Price_Bookings__c, ACV_Total_Price_Stamp__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        System.assertNotEquals(truth.ACV_Total_Price_Bookings__c.setScale(2), truth.ACV_Total_Price_Stamp__c.setScale(2));

        OpportunityItemRecalculateACVBatch.TEST_RECORDS_OVERRIDE = new List<String>{String.valueOf(opp.Id)};
        Test.startTest();
            Database.executeBatch(new OpportunityItemRecalculateACVBatch(), 10);
        Test.stopTest();

        truth = [SELECT ACV_Total_Price_Bookings__c, ACV_Total_Price_Stamp__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        System.assertEquals(truth.ACV_Total_Price_Bookings__c.setScale(2), truth.ACV_Total_Price_Stamp__c.setScale(2));

        new OpportunityItemRecalculateACVBatch().execute(null);
    }
}