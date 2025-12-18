@isTest
public class BatchCSMRRAssignmentTest {


    @TestSetup
    private static void testDataSetup() {

        Test.startTest();
        
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        List<Account> lstAcc = new List<Account>();
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'HW-VG33');

        Account a1 = new Account(Status__c = 'Existing Customer',Name = 'Test Acc1',Industry = 'Unknown', RecordTypeId = '0121a000000VeLe',
                                 Organization_Size__c = '1 - 99',BillingState = 'Connecticut',CS_Tier__c = 'Starter', Send_to_My_ADR__c = true,
                                 BillingCountry = 'United States', Global_Geography__c = 'East', Customer_ARR__c = 500000);

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        insert a1;
        setting.Skip_Trigger__c = false;
        update setting; 
        delete setting;
        Opportunity opp = new Opportunity(AccountId = a1.Id,Name = a1.Name,CloseDate = system.today(),StageName = 'Closed Won', Type = 'Revenue Opportunity', Amount = 500000);
        insert opp;
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 40,PriceBookEntryId = vg33.Id,UnitPrice = vg33.UnitPrice);
        insert oli;
        
        Test.stopTest();
    }
    /*
    @isTest static void runCSM() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        acc.ownerId = targetUser.Id;
        update acc;

        setting.Skip_Trigger__c = false;
        update setting;       
        
        Test.startTest();
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    
    @isTest static void runCSM2() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.CS_Tier__c = 'Plus';
        acc.Customer_ARR__c = 100000;
        acc.ownerId = targetUser.Id;

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;        
       
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
   
    @isTest static void runCSM1() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.BillingCountry = 'Canada';
        acc.BillingState = 'Alberta';
        acc.Customer_ARR__c = 100000;
        acc.ownerId = targetUser.Id;

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }

    @isTest static void runCSM3() {
        Test.startTest();
                                 
        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.Global_Geography__c = 'Central';
        acc.ownerId = targetUser.Id;
        acc.CSM_Status__c='Onboarding';
        acc.CS_Tier__c='Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
   
*/
    @isTest static void runCSMMexicoStarter() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.Global_Geography__c = 'Central';
        acc.VATId__c = '100010';
        acc.BillingCountry = 'Mexico';
        acc.BillingState = 'Chiapas';
        acc.ownerId = targetUser.Id;
        acc.CS_Tier__c='Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }

     @isTest static void runCSMMexicoPlus() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.Global_Geography__c = 'Central';
        acc.VATId__c = '100010';
        acc.BillingCountry = 'Mexico';
        acc.BillingState = 'Chiapas';
        acc.ownerId = targetUser.Id;
        acc.CS_Tier__c='Plus';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }

	@isTest static void runCSMUSPlus() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.Global_Geography__c = 'Central';
        acc.VATId__c = '100010';
        acc.CS_Tier__c = 'Plus';
        acc.ownerId = targetUser.Id;

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    
    @isTest static void runCSMMexicoStarterJulia() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        User managerUser=[Select id,Name from User WHERE Name LIKE '%Julia Monroy%' LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];
		user targetUser1 = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];
        targetUser1.ManagerId=managerUser.id;
       update targetUser1;
        
        acc.Global_Geography__c = 'Central';
        acc.VATId__c = '100010';
        acc.BillingCountry = 'Mexico';
        acc.BillingState = 'Chiapas';
        acc.CS_Tier__c = 'Starter';
        acc.ownerId = targetUser1.Id;

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }

    
    @isTest static void runCSMMexicoPlusJulia() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        User managerUser=[Select id,Name from User WHERE Name LIKE '%Julia Monroy%' LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];
		user targetUser1 = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];
        targetUser1.ManagerId=managerUser.id;
       update targetUser1;
        
        acc.Global_Geography__c = 'Central';
        acc.VATId__c = '100010';
        acc.BillingCountry = 'Mexico';
        acc.BillingState = 'Chiapas';
        acc.CS_Tier__c = 'Plus';
        acc.ownerId = targetUser1.Id;

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    
      @isTest static void runCSMMexicoStarterOldRoles() {
          Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA CA%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.Global_Geography__c = 'Central';
        acc.VATId__c = '100010';
        acc.BillingCountry = 'Canada';
        acc.BillingState = 'Manitoba';
        acc.Customer_ARR__c = 3000;
        acc.CS_Tier__c = 'Starter';
        acc.ownerId = targetUser.Id;

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
  
        @isTest static void runCSMStarterMexicoOldRoles() {
          Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA CA%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.Global_Geography__c = 'Central';
        acc.VATId__c = '100010';
        acc.BillingCountry = 'Mexico';
        acc.Customer_ARR__c = 3000;
        acc.CS_Tier__c = 'Select Basic';
        acc.ownerId = targetUser.Id;

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
  
   
    @isTest static void runCSMMexicoPlusOld() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%IT%' AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.VATId__c = '100010';
        acc.BillingCountry = 'Canada';
        acc.ownerId = targetUser.Id;
        acc.CS_Tier__c='Core Basic';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }


    @isTest static void runCSMCanadaStarter() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.Global_Geography__c = 'Central';
        acc.VATId__c = '100010';
        acc.BillingCountry = 'Canada';
        acc.BillingState = 'Manitoba';
        acc.Customer_ARR__c = 3000;
        acc.ownerId = targetUser.Id;

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }

    @isTest static void runCSMCanadaPlus() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        user targetUser = [SELECT Id FROM User WHERE UserRole.Name Like '%NA CA%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.Global_Geography__c = 'Central';
        acc.VATId__c = '100010';
        acc.BillingCountry = 'Canada';
        acc.BillingState = 'Manitoba';
        acc.Customer_ARR__c = 3000;
        acc.CS_Tier__c = 'Plus';
        acc.ownerId = targetUser.Id;

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }

    @isTest static void runCanadaFrenchIC() { //Canada French IC
		Test.startTest();
        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA CA%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];
	//	 BatchCSMRRAssignment.lstUserConfig = new list<CSM_RR_User_Config__mdt>{new CSM_RR_User_Config__mdt(MasterLabel = 'test123',User_Id__c = usr.Id, Type__c = 'Canada French IC')};
        system.debug('usr==>'+usr);
        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'French';
        acc.BillingCountry = 'Canada';
       
        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;

        
       
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }

    @isTest static void runPlusSpanishIC() { //Plus Spanish IC
		Test.startTest();
        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SLED%') AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.CS_Tier__c = 'Plus';
        acc.which_written_language__c = 'Spanish';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;

        
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }

    @isTest static void runStarterSpanishIC() { //Starter Spanish IC
		Test.startTest();
        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SLED%') AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.CS_Tier__c = 'Starter';
        acc.which_written_language__c = 'Spanish';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;

       // Test.startTest();
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }

    @isTest static void runCanadaStarterWestIC() {

        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA CA%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'Canada West';
        acc.CS_Tier__c = 'Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;

        setting.Skip_Trigger__c = false;
        update setting;  

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }

    @isTest static void runCanadaStarterEastIC() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA CA%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'Canada East';
        acc.CS_Tier__c = 'Starter';
                                    
        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update acc;  

        setting.Skip_Trigger__c = false;
        update setting;

        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
/*
    @isTest static void runAllCanadaStarter() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA CA%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'Canada West';
        acc.CS_Tier__c = 'Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
*/
    @isTest static void runPubSecStarterWestIC() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%SLED%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'West';
        acc.CS_Tier__c = 'Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    /*
    @isTest static void runPubSecStarterEastIC() { //PubSec Starter East IC

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%SLED%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'East';
        acc.CS_Tier__c = 'Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Test.startTest();
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    
    @isTest static void runPubSecStarterCentral() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%SLED%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'United States Central';
        acc.CS_Tier__c = 'Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    */
    @isTest static void runPubSecPlusCentral() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%SLED%' AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.CS_Tier__c = 'Plus';
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'United States Central';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
/*    
    @isTest static void runPubSecPlusWest() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%SLED%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.CS_Tier__c = 'Plus';
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'West';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    
    @isTest static void runPubSecPlusEast() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%SLED%' AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.CS_Tier__c = 'Plus';
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'East';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    */
    @isTest static void runStarterSpanish() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SLED%') AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'Spanish';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    
    @isTest static void runDigitalOnboarding() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true ORDER BY createddate desc LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'English';
        acc.Customer_ARR__c = 3000;
        acc.CS_Tier__c='Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
        BatchCSMRRAssignment batchCSM=new BatchCSMRRAssignment();
        
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    
    @isTest static void runStarterICWest() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SLED%') AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'West';
        acc.Customer_ARR__c = 35000;
        acc.CS_Tier__c = 'Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    /*
    @isTest static void runStarterICEast() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SLED%') AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'East';
        acc.Customer_ARR__c = 35000;
        acc.CS_Tier__c = 'Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }
    
    @isTest static void runPlusICEast() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SLED%') AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'East';
        acc.Customer_ARR__c = 75000;
        acc.CS_Tier__c = 'Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }*/
    
    @isTest static void runPlusICWest() {
        Test.startTest();

        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SLED%') AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];

        acc.ownerId = usr.Id;
        acc.which_written_language__c = 'English';
        acc.global_geography__c = 'West';
        acc.Customer_ARR__c = 75000;
        acc.CS_Tier__c = 'Starter';

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;
        
        update acc;

        setting.Skip_Trigger__c = false;
        update setting; 
         
        Database.executeBatch(new BatchCSMRRAssignment());
        Test.stopTest();
    }

    @isTest static void runMethod() {
        Test.startTest();
        User usr = [SELECT Id FROM User WHERE UserRole.Name Like '%NA US%' AND (NOT UserRole.Name Like '%SLED%') AND (NOT UserRole.Name Like '%SEL%') AND (NOT UserRole.Name Like '%COR%') AND (NOT UserRole.Name Like '%STR%') AND IsActive = true LIMIT 1];
        List<Account> account = new List<Account>([SELECT Id, CSM__c FROM Account]);
        Map<Id, Integer> userMap = new Map<Id, Integer>();
        userMap.put(usr.Id, 13);
       // test.startTest();
        BatchCSMRRAssignment batchClass = new BatchCSMRRAssignment();
        batchClass.csmRRAssignment(account, userMap,'Test Account');
        test.stopTest();
    }
    
    
    public static testMethod void testschedule() {
        Test.StartTest();
        BatchCSMRRAssignment sh1 = new BatchCSMRRAssignment();
        String sch = '0 0 23 * * ?'; system.schedule('Test Territory Check', sch, sh1); 
        Test.stopTest();
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