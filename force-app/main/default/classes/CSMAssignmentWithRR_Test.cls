@isTest
private class CSMAssignmentWithRR_Test {
    
   @TestSetup
    private static void testDataSetup() {

        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        List<Account> lstAcc = new List<Account>();
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'HW-VG33');

        RR_Assignment_Rule__c rrRule=new RR_Assignment_Rule__c(Rule_Description__c='Test Rule',Field_To_Assign_User__c='CSM__c',Which_Written_Language__c='English',
                                                               Active__c=True,Type__c='Other',Order__c=1,CS_Tier__c='Starter',Customer_ARR__c='8000');
        
       String fleetRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Fleet').getRecordTypeId();
        
        Account a1 = new Account(Status__c = 'Existing Customer',Name = 'Test Acc1',Industry = 'Unknown', RecordTypeId = fleetRecordTypeId,
                                 Organization_Size__c = '1 - 99',BillingState = 'Connecticut',CS_Tier__c= 'Starter', Send_to_My_ADR__c = true,
                                 BillingCountry = 'United States', Global_Geography__c = 'United States East', Customer_ARR__c = 500000);
		
        insert a1;
        
        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        setting.Skip_Trigger__c = false;
        update setting; 
        delete setting;
        Opportunity opp = new Opportunity(AccountId = a1.Id,Name = a1.Name,CloseDate = system.today()-1,StageName = 'Closed Won', Type = 'Revenue Opportunity', Amount = 500000);
        insert opp;
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 40,PriceBookEntryId = vg33.Id,UnitPrice = vg33.UnitPrice);
        insert oli;
        
    }
     
 @isTest   
private static void TestMethod1() {
    Test.startTest();
user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];
    Account acc = [SELECT Id,OwnerId,CS_Tier__c FROM Account LIMIT 1];
     acc.CS_Tier__c = 'Starter';
     acc.OwnerId=targetUser.Id;
	
    
      Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
    update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new CSMAssignmentWithRR(), 100);
    Test.stopTest();
}

    @isTest
    static void testCSMAssignmentWithRRSchedulable() {
        Test.startTest();
        String jobId = System.schedule('TestScheduledJob', '0 0 12 * * ?', new CSMAssignmentWithRR());
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('0 0 12 * * ?', ct.CronExpression, 'The cron expression should match the one provided.');
    }
    
    
     static private void addProducts(Id pricebookId){
        
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
        insert products;
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        insert pricebookEntries;
    }
    static private PricebookEntry getPricebookEntry(Id pricebookId, String productCode){
        PricebookEntry entry = [Select Id, UnitPrice, Pricebook2Id, ProductCode from PricebookEntry where ProductCode = :productCode and Pricebook2Id = :pricebookId LIMIT 1];
        return entry;
    }
}