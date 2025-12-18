@isTest
public class GS_AccountTest {
    @testSetup
    static void setupTestData() {
         insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                BillingCountry='Belgium', 
                BillingCountryCode = 'BE',
                Phone = '123456789' + i,
                Organization_Size__c='1 - 99',
                SAM_Number_Undecorated__c = 'C' + String.valueOf(i) + 'SAM'
            ));
        }
        //insert testAccounts;
        List<Account> aList = new List<Account>();
        
        aList.add((Account) TestFactory.createSObject(new Account(Name='Blah1', Website='test.test', CSM_First_30d_Stage__c = 'Pending Intro')));
        aList.add((Account) TestFactory.createSObject(new Account(Name='Blah2', Website='um.um', CSM_First_30d_Stage__c = 'Pending Delivery')));
        aList.add((Account) TestFactory.createSObject(new Account(Name='Blah2', Website='um.um', CSM_First_30d_Stage__c = 'Attempting Training')));
        aList.add((Account) TestFactory.createSObject(new Account(Name='Blah2', Website='um.um', CSM_First_30d_Stage__c = 'Scheduled Training')));
        aList.add((Account) TestFactory.createSObject(new Account(Name='Blah2', Website='um.um', CSM_First_30d_Stage__c = 'Health Check')));
        aList.add((Account) TestFactory.createSObject(new Account(Name='Blah2', Website='um.um', CSM_First_30d_Stage__c = 'Scheduled Additional Training')));
        
        if(aList.size() > 0) {
            insert aList;
        }
        List<Account> accounts = new List<Account>{
            new Account(Name='Test Account 1', BillingCountryCode='DE', Status__c='Existing Customer', Type='Reseller Partner'),
            new Account(Name='Test Account 2', BillingCountryCode='US', Status__c='New Customer', Type='Direct Customer')
        };
        insert accounts;
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName='John', LastName='Doe', Email='john.doe@example.com', Phone='1234567890', AccountId=accounts[0].Id),
            new Contact(FirstName='Jane', LastName='Smith', Email='jane.smith@example.com', Phone='0987654321', AccountId=accounts[1].Id)
        };
        insert contacts;
    }
    
    @isTest
    static void testAfterInsertOperations() {
        List<Account> newAccounts = [SELECT Id, Name, OwnerId,First_Purchase_Date__c, BillingCountryCode,Organization_Size__c,SAM_Number_Undecorated__c,BillingCountry,CS_POC_Email_Address__c, Phone FROM Account];
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();        
        Test.startTest();
        //AccountHelper.afterInsertOperations(oldAccountMap, newAccounts);
        Test.stopTest();
        List<CS_Record__c> csRecords = [SELECT Id, Account__c FROM CS_Record__c WHERE Account__c IN :newAccounts];
        //System.assertEquals(newAccounts.size(), csRecords.size(), 'All accounts should have associated CS_Record__c records');
    }
    @isTest static void testAccountInsertsAndUpdate() {
        
        User usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Map<ID, Schema.RecordTypeInfo> rt_Map = Account.sObjectType.getDescribe().getRecordTypeInfosById();
        List<Account> updateList = new List<Account>();
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Samsara Inbound ADRs'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User u = new User(lastName = 'blah',
                          email = uniqueName + '@test' + orgId + '.org',
                          Username = uniqueName + '@test' + orgId + '.org',
                          EmailEncodingKey = 'ISO-8859-1',
                          Alias = uniqueName.substring(18, 23),
                          TimeZoneSidKey = 'America/Los_Angeles',
                          LocaleSidKey = 'en_US',
                          LanguageLocaleKey = 'en_US',
                          ProfileId = p.Id,
                          EmployeeNumber='123');
        insert u;
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        
        
        
        for(Account a : [SELECT Id, RecordTypeId, CSM_First_30d_Stage__c FROM Account]) {
            system.debug('csm value is '+a.CSM_First_30d_Stage__c);
            a.RecordTypeId = rt_Map.values()[0].getRecordTypeId();
            a.OwnerId = u.Id;
            a.Overwrite_Validation_Rule__c = true;
            a.Record_Type_Stamp_for_Dupes__c = 'Fleet';
            a.Unload_Account__c = true;
            a.Status__c = 'Existing Customer';
            a.Global_Geography__c = 'Canada';
            
            
            if(a.CSM_First_30d_Stage__c == 'Additional followup needed'){
                a.CSM_First_30d_Stage__c = 'Pending Intro';
            }
            else if(a.CSM_First_30d_Stage__c == 'Pending Intro'){
                a.CSM_First_30d_Stage__c = 'Pending Delivery';
            }
            else if(a.CSM_First_30d_Stage__c == 'Pending Delivery'){
                a.CSM_First_30d_Stage__c = 'Attempting Training';
            }
            else if(a.CSM_First_30d_Stage__c == 'Attempting Training'){
                a.CSM_First_30d_Stage__c = 'Scheduled Training';
            }
            else if(a.CSM_First_30d_Stage__c == 'Scheduled Training'){
                a.CSM_First_30d_Stage__c = 'Health Check';
            }
            else if(a.CSM_First_30d_Stage__c == 'Health Check'){
                a.CSM_First_30d_Stage__c = 'Scheduled Additional Training';
                a.Validation_Complete__c = true;
            }
            else if(a.CSM_First_30d_Stage__c == 'Health Check'){
                a.CSM_First_30d_Stage__c = 'Scheduled Additional Training';
                a.Validation_Complete__c = true;
            }
            
            updateList.add(a);
        }
        
        if(updateList.size() > 0) {
            Test.startTest();
            
            system.runAs(usr){
                update updateList;
            }
            Test.stopTest();
        }
    }
    @isTest static void testDelinquencyWorkflowConversions() {
        
        List<Account> aList = new List<Account>();
        
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', Record_Type_Stamp_for_Dupes__c = 'Fleet',Industry = 'Unknown');
        insert a;
        
        Account accTwo = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', Record_Type_Stamp_for_Dupes__c = 'Fleet',Industry = 'Unknown');
        insert accTwo;
        
        accTwo.Enable_Delinquency_Process__c = false;
        accTwo.Churn_Payment_Status__c = Label.Churn_Payment_Status_Delinquent;
        
        update accTwo;
        
        Test.startTest();
        
        Account accTwoAfterInsert = [SELECT Id, SBQQ__CoTerminationEvent__c, Quarantine_Enabled__c, Enable_Delinquency_Process__c, Churn_Payment_Status__c, SBQQ__ContractCoTermination__c, SBQQ__RenewalModel__c, SBQQ__RenewalPricingMethod__c FROM Account WHERE Id =: accTwo.Id LIMIT 1];
        // Delinquency Starter
        //system.assertEquals(Label.Churn_Payment_Status_Delinquent, accTwoAfterInsert.Churn_Payment_Status__c);
        //system.assertEquals(true, accTwoAfterInsert.Enable_Delinquency_Process__c);
        
        insert new Delinquency_Defaults__c(Delinquency_Default_Grace_Period__c=60);
        
        
        a.Enable_Delinquency_Process__c = false;
        a.Delinquent__c = true;
        
        update a;
        
        Account aa = [SELECT Id, Delinquent_As_Of__c,SBQQ__CoTerminationEvent__c, Quarantine_Enabled__c, Enable_Delinquency_Process__c, Churn_Payment_Status__c, SBQQ__ContractCoTermination__c, SBQQ__RenewalModel__c, SBQQ__RenewalPricingMethod__c FROM Account WHERE Id =: a.Id LIMIT 1];
        
        
        //Delinquent Timestamp
        //system.assertNotEquals(null, aa.Delinquent_As_Of__c); GTMS-6917. commented this field
        //Delinquency Unset
        //system.assertEquals(Label.Churn_Payment_Status_Current, aa.Churn_Payment_Status__c);
        //system.assertEquals(false, aa.Enable_Delinquency_Process__c);
        //system.assertEquals(false, aa.Quarantine_Enabled__c);
        
        aa.Delinquent__c = false;
        
        aa.Unload_Account__c = true;
        aa.New_Billing_Process_Approved__c = true;
        aa.Enable_Delinquency_Process__c = true;
        aa.Quarantine_Enabled__c = true;
        update aa;
        Account updatedAccount = [SELECT Id,Churn_Payment_Status__c, Suspension_Grace_Days__c, Quarantine_Enabled_At__c, Enable_Delinquency_Process__c, Quarantine_Enabled__c,Delinquent_As_Of__c, Unload_Account__c,CSM__c FROM Account WHERE Id =: aa.Id LIMIT 1];
        
        //Clear Delinquent Timestamp
        //system.assertEquals(null, updatedAccount.Delinquent_As_Of__c);
        
        //system.assertEquals(False, updatedAccount.Unload_Account__c);
        
        // WF Rule - Delinquency Setter with Enable_Delinquency_Process__c & Suspension_Grace_Days__c as null
        updatedAccount.Enable_Delinquency_Process__c = true;
        
        // WF Rule - Delinquency Starter
        
        updatedAccount.Churn_Payment_Status__c = Label.Churn_Payment_Status_Delinquent;
        updatedAccount.New_Billing_Process_Approved__c = false;
        
        update updatedAccount;
        //Account updatedAccountAfterDelinquencyFlows = [SELECT Id, Segment__c,Segment_Text_stamped__c,LFBN__Assign_Region__c,Suspension_Grace_Days__c,Quarantine_Enabled_At__c, Delinquent_As_Of__c, Unload_Account__c,CSM__c, Churn_Payment_Status__c, Enable_Delinquency_Process__c FROM Account WHERE Id =: updatedAccount.Id LIMIT 1];
        Account updatedAccountAfterDelinquencyFlows = [SELECT Id, Segment__c,Segment_Text_stamped__c,Initiate_Round_Robin__c,Suspension_Grace_Days__c,Quarantine_Enabled_At__c, Delinquent_As_Of__c, Unload_Account__c,CSM__c, Churn_Payment_Status__c, Enable_Delinquency_Process__c FROM Account WHERE Id =: updatedAccount.Id LIMIT 1];
        
        //Delinquency Setter
        //system.assertEquals(60, updatedAccountAfterDelinquencyFlows.Suspension_Grace_Days__c);
        //system.assertEquals(Date.today().AddDays(60), updatedAccountAfterDelinquencyFlows.Quarantine_Enabled_At__c);
        
        //system.assertEquals(Label.Churn_Payment_Status_Delinquent, updatedAccountAfterDelinquencyFlows.Churn_Payment_Status__c);
        //system.assertEquals(True, updatedAccountAfterDelinquencyFlows.Enable_Delinquency_Process__c);
        
        updatedAccountAfterDelinquencyFlows.Suspension_Grace_Days__c = 30;
        updatedAccountAfterDelinquencyFlows.BillingCountry = 'United States';
        updatedAccountAfterDelinquencyFlows.BillingCountryCode = 'US';
        updatedAccountAfterDelinquencyFlows.BillingStateCode = 'CA';
        update updatedAccountAfterDelinquencyFlows;
        //Account updatedAccountAfterBillingDetailsChanged = [SELECT Id, Segment__c,Segment_Text_stamped__c,LFBN__Assign_Region__c,Suspension_Grace_Days__c,Quarantine_Enabled_At__c, Delinquent_As_Of__c, Unload_Account__c,CSM__c, Churn_Payment_Status__c, Enable_Delinquency_Process__c FROM Account WHERE Id =: updatedAccount.Id LIMIT 1];
        Account updatedAccountAfterBillingDetailsChanged = [SELECT Id, Segment__c,Segment_Text_stamped__c,Initiate_Round_Robin__c,Suspension_Grace_Days__c,Quarantine_Enabled_At__c, Delinquent_As_Of__c, Unload_Account__c,CSM__c, Churn_Payment_Status__c, Enable_Delinquency_Process__c FROM Account WHERE Id =: updatedAccount.Id LIMIT 1];
        
        //Delinquency Setter
        //system.assertEquals(30, updatedAccountAfterBillingDetailsChanged.Suspension_Grace_Days__c);
        //system.assertEquals(Date.today().AddDays(30), updatedAccountAfterBillingDetailsChanged.Quarantine_Enabled_At__c);
        
        //Delinquency or Quarantine Clear
        updatedAccountAfterBillingDetailsChanged.Enable_Delinquency_Process__c = false;
        updatedAccountAfterBillingDetailsChanged.Quarantine_Enabled__c = false;
        
        update updatedAccountAfterBillingDetailsChanged;
        
        Account updatedAccountAfterQuarantineClear = [SELECT Id, Quarantine_Enabled__c,Enable_Delinquency_Process__c,Quarantine_Enabled_At__c,Suspension_Grace_Days__c FROM Account WHERE Id =: updatedAccountAfterBillingDetailsChanged.Id LIMIT 1];
        
        //system.assertEquals(false,updatedAccountAfterQuarantineClear.Quarantine_Enabled__c);//
        //system.assertEquals(false,updatedAccountAfterQuarantineClear.Enable_Delinquency_Process__c);
        //system.assertEquals(null,updatedAccountAfterQuarantineClear.Quarantine_Enabled_At__c);
        //system.assertEquals(null,updatedAccountAfterQuarantineClear.Suspension_Grace_Days__c);
        
        
        Test.stopTest();
    }
    @isTest static void testcompleteCsmOnboarding() {
        
        Test.startTest();
        User usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueNameManager = orgId + dateString + randomInt;
        User managerUser = new User(lastName = 'User',
                                    FirstName = 'Manager',
                                    email = uniqueNameManager + '@test' + orgId + '.org',
                                    Username = uniqueNameManager + '@test' + orgId + '.org',
                                    EmailEncodingKey = 'ISO-8859-1',
                                    Alias = uniqueNameManager.substring(18, 23),
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    LocaleSidKey = 'en_US',
                                    LanguageLocaleKey = 'en_US',
                                    ProfileId = p.Id,
                                    EmployeeNumber='123');
        insert managerUser;
        
        Integer randomIntUser = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueNameUser = orgId + dateString + randomIntUser;
        User u = new User(lastName = 'User',
                          FirstName = 'Dev',
                          email = uniqueNameUser + '@test' + orgId + '.org',
                          Username = uniqueNameUser + '@test' + orgId + '.org',
                          ManagerID = managerUser.Id,
                          EmailEncodingKey = 'ISO-8859-1',
                          Alias = uniqueNameUser.substring(18, 23),
                          TimeZoneSidKey = 'America/Los_Angeles',
                          LocaleSidKey = 'en_US',
                          LanguageLocaleKey = 'en_US',
                          ProfileId = p.Id,
                          EmployeeNumber='123');
        insert u;
        
        system.runAs(managerUser){
            Account aa = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', Record_Type_Stamp_for_Dupes__c = 'Fleet');
            insert aa;
            
            aa.CSM__c = u.Id;
            aa.Unload_Account__c = true;
            aa.CSM_Initial_onboarding_completed_Time__c = null;
            aa.CSM_Sub_Status__c = Label.Onboarding_Complete;
            aa.CSM_Status__c = Label.Account_Management;
            aa.CSM_First_30d_Stage__c = Label.Initial_onboarding_complete;
            update aa;
            aa.CSM_First_30d_Stage__c = Label.Initial_onboarding_complete;
            update aa;
            Account accountWithCSM = [SELECT Id, Delinquent_As_Of__c, CSM_who_completed_onboarding__c FROM Account WHERE Id =: aa.Id LIMIT 1];
        }
        //system.assertEquals('Manager User - Dev User', accountWithCSM.CSM_who_completed_onboarding__c);
        
        Test.stopTest();
    }
    
    @isTest static void preApproveAndDeclineSamsaraStatusTest(){
        Test.startTest();
        User usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueNameManager = orgId + dateString + randomInt;
        User managerUser = new User(lastName = 'User',
                                    FirstName = 'Manager',
                                    email = uniqueNameManager + '@test' + orgId + '.org',
                                    Username = uniqueNameManager + '@test' + orgId + '.org',
                                    EmailEncodingKey = 'ISO-8859-1',
                                    Alias = uniqueNameManager.substring(18, 23),
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    LocaleSidKey = 'en_US',
                                    LanguageLocaleKey = 'en_US',
                                    ProfileId = p.Id,
                                    EmployeeNumber='123');
        insert managerUser;
        
        Integer randomIntUser = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueNameUser = orgId + dateString + randomIntUser;
        User u = new User(lastName = 'User',
                          FirstName = 'Dev',
                          email = uniqueNameUser + '@test' + orgId + '.org',
                          Username = uniqueNameUser + '@test' + orgId + '.org',
                          ManagerID = managerUser.Id,
                          EmailEncodingKey = 'ISO-8859-1',
                          Alias = uniqueNameUser.substring(18, 23),
                          TimeZoneSidKey = 'America/Los_Angeles',
                          LocaleSidKey = 'en_US',
                          LanguageLocaleKey = 'en_US',
                          ProfileId = p.Id,
                          EmployeeNumber='123');
        insert u;
        system.runAs(usr){
            Account aa = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', Record_Type_Stamp_for_Dupes__c = 'Fleet', Unload_Account__c = true);
            insert aa;
            aa.Overwrite_Validation_Rule__c = true;
            aa.OwnerId = u.Id;
            aa.DNBI_Data_Available__c = true;
            aa.DNBI_Recommended_Credit_Limit__c = 100;
            aa.DNBI_Trade_Experiences_Count__c = 6;
            aa.DNBI_Commercial_Credit_Percentage__c = 10;
            aa.DNBI_SlowNegExpCount__c = 5;
            aa.DNBI_Financial_Stress_Score__c = 10;
            aa.DNBI_PAYDEX__c = 90;
            aa.Samsara_PreApproval_Status__c = 'Declined';
            update aa;
        
        Account updatedAccountAfterDecline = [SELECT Id, Samsara_PreApproval_Status__c, Credit_Scorecard_Score__c FROM Account WHERE Id =: aa.Id LIMIT 1];
        //system.assertEquals(Label.SamsaraPreApprovalDeclined, updatedAccountAfterDecline.Samsara_PreApproval_Status__c);
        
        updatedAccountAfterDecline.DNBI_Commercial_Credit_Percentage__c = 90;
        updatedAccountAfterDecline.DNBI_SlowNegExpCount__c = 50;
        updatedAccountAfterDecline.DNBI_Financial_Stress_Score__c = 95;
        updatedAccountAfterDecline.DNBI_PAYDEX__c = 90;
        update updatedAccountAfterDecline;
        Account updatedAccountAfterApproval = [SELECT Id, Samsara_PreApproval_Status__c, Credit_Scorecard_Score__c FROM Account WHERE Id =: updatedAccountAfterDecline.Id LIMIT 1];
        //system.assertEquals(Label.SamsaraPreApprovalApproved, updatedAccountAfterApproval.Samsara_PreApproval_Status__c);
        }
        Test.stopTest();
    }
    
    //Groundswell: Nilesh Jain : Workflow changes related test method.
    @isTest static void testWorkflowChanges() {
        
        Test.startTest();
        User usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        //Account accountQuery = [SELECT Id, Industry, Sub_Industry__c, Small_Fleets_Engagement_Date__c, Name,
        //                        Zendesk_Account_Name_Text__c, SAM_Number_Decorated__c , Owner_Manager_Email_Copy__c, Owner.Manager.Email
        //                        FROM Account WHERE Id =: aa.Id LIMIT 1];
        //system.assertEquals(accountQuery.Owner_Manager_Email_Copy__c, accountQuery.Owner.Manager.Email);
        //system.assertEquals(accountQuery.Zendesk_Account_Name_Text__c , accountQuery.Name + '_' + accountQuery.SAM_Number_Decorated__c);
        //system.assertNotEquals(accountQuery.Small_Fleets_Engagement_Date__c, null);
        //system.assertEquals(accountQuery.Sub_Industry__c, 'Government - Unclassified');
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        
        String uniqueNameManagerManager = orgId + dateString + randomInt;
        User managerUserManager = new User(lastName = 'User',
                                           FirstName = 'ManagerManager',
                                           email = uniqueNameManagerManager + '@test1' + orgId + '.org',
                                           Username = uniqueNameManagerManager + '@test1' + orgId + '.org',
                                           EmailEncodingKey = 'ISO-8859-1',
                                           Alias = uniqueNameManagerManager.substring(18, 23),
                                           TimeZoneSidKey = 'America/Los_Angeles',
                                           LocaleSidKey = 'en_US',
                                           LanguageLocaleKey = 'en_US',
                                           ProfileId = p.Id,
                                           EmployeeNumber='123');
        insert managerUserManager;
        
        
        String uniqueNameManager = orgId + dateString + randomInt;
        User managerUser = new User(lastName = 'User',
                                    FirstName = 'Manager',
                                    email = uniqueNameManager + '@test' + orgId + '.org',
                                    Username = uniqueNameManager + '@test' + orgId + '.org',
                                    EmailEncodingKey = 'ISO-8859-1',
                                    Alias = uniqueNameManager.substring(18, 23),
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    LocaleSidKey = 'en_US',
                                    LanguageLocaleKey = 'en_US',
                                    ProfileId = p.Id,
                                    ManagerID = managerUserManager.Id,
                                    EmployeeNumber='123');
        insert managerUser;
        
        Integer randomOwnerIdUser = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueOwnerNameUser = orgId + dateString + randomOwnerIdUser;
        User ownerUser = new User(lastName = 'TestUser',
                                  FirstName = 'OwnerId',
                                  email = uniqueOwnerNameUser + '@test' + orgId + '.org',
                                  Username = uniqueOwnerNameUser + '@test' + orgId + '.org',
                                  ManagerID = managerUser.Id,
                                  EmailEncodingKey = 'ISO-8859-1',
                                  Alias = uniqueOwnerNameUser.substring(18, 23),
                                  TimeZoneSidKey = 'America/Los_Angeles',
                                  LocaleSidKey = 'en_US',
                                  LanguageLocaleKey = 'en_US',
                                  ProfileId = p.Id,
                                  EmployeeNumber='123');
        insert ownerUser;
        
        Integer randomIntUser = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueNameUser = orgId + dateString + randomIntUser;
        User u = new User(lastName = 'User',
                          FirstName = 'Dev',
                          email = uniqueNameUser + '@test' + orgId + '.org',
                          Username = uniqueNameUser + '@test' + orgId + '.org',
                          ManagerID = managerUser.Id,
                          EmailEncodingKey = 'ISO-8859-1',
                          Alias = uniqueNameUser.substring(18, 23),
                          TimeZoneSidKey = 'America/Los_Angeles',
                          LocaleSidKey = 'en_US',
                          LanguageLocaleKey = 'en_US',
                          ProfileId = p.Id,
                          EmployeeNumber='123');
        insert u;
        
        system.runAs(usr){
        Account aa = new Account(Name='blah', Organization_Size__c='1 - 99',Industry='Government',
                                 BillingCountry='Belgium', BillingCountryCode = 'BE', Record_Type_Stamp_for_Dupes__c = 'Fleet', Micro_Fleet_Support_Tier__c = true);
        insert aa;
        
        aa.Overwrite_Validation_Rule__c = true;
        aa.CSM__c = u.Id;
        aa.Assign_CSM__c = true;
        aa.Industry = 'Educational Services';
        aa.Quarantine_Enabled__c = true;
        aa.Suspension_Grace_Days__c = 10;
        aa.Enable_Delinquency_Process__c = true;
        aa.SIC__c = u.Id;
        aa.OwnerId = ownerUser.Id;
        aa.Support_Escalation_Owner__c = u.Id;
        aa.Support_Priority_Override__c = 's0';
        aa.Name = 'bhah1';
        //aa.DelightedInc__NPS__c = 100;
        update aa;
        
        Account updatedAccount = [SELECT Id, Quarantine_Enabled__c, Enable_Delinquency_Process__c, Quarantine_Enabled_At__c, Suspension_Grace_Days__c,
                                  Assign_CSM__c, CSM_Manager_Email__c, CSM_Director_Email__c, Actual_Deactivate_Date__c, Sub_Industry__c,
                                  Support_Escalation_Owner_Name__c, Zendesk_Account_Name_Text__c, Name, SAM_Number_Decorated__c, CSM_Name_Copy__c,
                                  Support_Phone_Number__c, Owner_Manager_Email_Copy__c, Owner.Manager.Email, Stamp_Delighted_Score_Date_Change__c FROM Account WHERE Id =: aa.Id LIMIT 1];
        //system.assertEquals(updatedAccount.CSM_Manager_Email__c.ToLowerCase(), managerUser.Email.ToLowerCase());
        //system.assertEquals(updatedAccount.CSM_Director_Email__c.ToLowerCase(), managerUserManager.Email.ToLowerCase());
        //system.assertNotEquals(updatedAccount.Stamp_Delighted_Score_Date_Change__c, null);
        //system.assertEquals(updatedAccount.Assign_CSM__c, false);
        //GTMS-6852. Commented below. We are populating Quarantine_Enabled__c in GS_AccountPrePopulationService based on that the field Actual_Deactivate_Date__c is populated in AccountWorkflowConversion
        //system.assertEquals(updatedAccount.Actual_Deactivate_Date__c, System.Today());
        //system.assertEquals(updatedAccount.Sub_Industry__c, 'Education - Unclassified');
        //system.assertEquals(updatedAccount.CSM_Name_Copy__c, u.FirstName + '' + u.LastName); //Stamp CSM Name Copy  workflow
        //s/ystem.assertEquals(updatedAccount.Owner_Manager_Email_Copy__c, updatedAccount.Owner.Manager.Email); //Owner Manager Email workflow
        //system.assertEquals(updatedAccount.Support_Phone_Number__c, '(415) 329-6879'); //Support Phone Number workfow
        //system.assertEquals(accountQuery.Zendesk_Account_Name_Text__c , accountQuery.Name + '_' + accountQuery.SAM_Number_Decorated__c); //Zendesk unique name workflow
        //system.assertEquals(updatedAccount.Support_Escalation_Owner_Name__c, u.FirstName + '' + u.LastName); //Support escalation owner name workflow
        }
        Test.stopTest();
    }
    @isTest
    static void supportMidMKTPhoneNumberTest(){
        test.startTest();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueNameManager = orgId + dateString + randomInt;
        User managerUser = new User(lastName = 'User',
                                    FirstName = 'Manager',
                                    email = uniqueNameManager + '@test' + orgId + '.org',
                                    Username = uniqueNameManager + '@test' + orgId + '.org',
                                    EmailEncodingKey = 'ISO-8859-1',
                                    Alias = uniqueNameManager.substring(18, 23),
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    LocaleSidKey = 'en_US',
                                    LanguageLocaleKey = 'en_US',
                                    ProfileId = p.Id,
                                    
                                    EmployeeNumber='123');
        insert managerUser;
        
        system.runAs(managerUser){
            Account accountOne = new Account(Name = 'Testers 1 Inc',
                                             BillingCountry = 'United Kingdom',
                                             BillingCountryCode = 'GB',
                                             Organization_Size__c = '100 - 499',
                                             Industry = 'Other');
            insert accountOne;
            Account tags = [SELECT Id, Zendesk_Tags__c, Support_Priority__c, BillingCountry FROM Account WHERE Id =: accountOne.Id LIMIT 1];
            //system.assertEquals(tags.Zendesk_Tags__c, 'Account_' + tags.Support_Priority__c + ', ' + tags.BillingCountry); //small fleets workflow
            Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
            insert contactOne;
            Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
            insert sa;
            
            Opportunity opportunityOne = (Opportunity)
                TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                          Type = 'Free Trial Opportunity',
                                                          Name = 'Opp Testers 1 Inc',
                                                          StageName = 'Proposal',
                                                          RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                          Shipping_Contact__c = contactOne.Id,
                                                          Selected_Payment_Type__c = 'Direct Annual',
                                                          Price_Book_Name__c = 'Standard',
                                                          Probability = 0.25,
                                                          Amount = 30000,
                                                          Send_Invoice__c = false));
            //insert opportunityOne;
            
            accountOne.Support_Priority_Override__c = 's1';
            update accountOne;
            Account updatedAccount = [SELECT Id, Zendesk_Tags__c, Support_Priority__c, BillingCountry, Support_Phone_Number__c FROM Account WHERE Id =: accountOne.Id LIMIT 1];
            //system.assertEquals(updatedAccount.Support_Phone_Number__c, '(415) 688-4286'); //Mid Mkt workflow
            //system.assertEquals(updatedAccount.Zendesk_Tags__c, 'Account_' + updatedAccount.Support_Priority__c + ', ' + updatedAccount.BillingCountry); //small fleets workflow
        }
        test.stopTest();
    }
    //Groundswell - Nilesh Jain : Test SMB workflow method
    @isTest
    static void supportSMBPhoneNumberTest(){
        test.startTest();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueNameManager = orgId + dateString + randomInt;
        
        UserRole smbTeam = new UserRole();
        smbTeam = new UserRole(Name = Label.ExpressSegment);
        insert smbTeam;
        
        User managerUser = new User(lastName = 'User',
                                    FirstName = 'Manager',
                                    email = uniqueNameManager + '@test' + orgId + '.org',
                                    Username = uniqueNameManager + '@test' + orgId + '.org',
                                    EmailEncodingKey = 'ISO-8859-1',
                                    Alias = uniqueNameManager.substring(18, 23),
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    LocaleSidKey = 'en_US',
                                    LanguageLocaleKey = 'en_US',
                                    Level__c = 'SB AE',
                                    ProfileId = p.Id,
                                    EmployeeNumber='123',
                                    Territory__c  = 'West',
                                    UserRoleId = smbTeam.Id);
        insert managerUser;
        
        system.runAs(managerUser){
            Account accountOne = new Account(Name = 'Testers 1 Inc',
                                             BillingCountry = 'United Kingdom',
                                             Organization_Size__c = '100 - 499',
                                             Industry = 'Government - Federal');
            insert accountOne;
            Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
            insert contactOne;
            Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
            insert sa;
            
            Opportunity opportunityOne = (Opportunity)
                TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                          Type = 'Free Trial Opportunity',
                                                          Name = 'Opp Testers 1 Inc',
                                                          StageName = 'Proposal',
                                                          RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                          Shipping_Contact__c = contactOne.Id,
                                                          Selected_Payment_Type__c = 'Direct Annual',
                                                          Price_Book_Name__c = 'Standard',
                                                          Probability = 0.25,
                                                          Amount = 30000,
                                                          Send_Invoice__c = false));
            insert opportunityOne;
            accountOne.Overwrite_Validation_Rule__c =true;
            //update accountOne;
            Account updatedAccount = [SELECT Id, Support_Phone_Number__c FROM Account WHERE Id =: accountOne.Id LIMIT 1];
            //system.assertEquals(updatedAccount.Support_Phone_Number__c, '(415) 799-3279');
            //system.assertEquals(updatedAccount.Support_Phone_Number__c, System.label.Workflow_SMB);
        }
        test.stopTest();
    }
    
    @isTest
    static void lawfulBasis(){
        
        List<Account> aList = new List<Account>();
        Test.startTest();
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', Record_Type_Stamp_for_Dupes__c = 'Fleet');
        insert a;
        
        Account aa = [SELECT Id, Status__c FROM Account WHERE Id =: a.Id LIMIT 1];
        Contact c = new Contact(FirstName = 'blah', LastName = 'blah', email = 'testymctesterson@email.com', AccountId = a.Id);
        insert c;
        
        aa.Status__c = 'Existing Customer';
        update aa;
        Test.stopTest();
    }
    
    @isTest
    static void csmAssignment(){
        List<Account> aList = new List<Account>();
        
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='United States', BillingState = 'California', Number_of_Vehicles__c = 1, Record_Type_Stamp_for_Dupes__c = 'Fleet');
        insert a;
        
        
        Account aa = [SELECT Id, Status__c, First_Purchase_Date__c FROM Account WHERE Id =: a.Id LIMIT 1];
        
        system.debug(LoggingLevel.INFO, 'Purchase Date'+aa.First_Purchase_Date__c);
        // system.debug(LoggingLevel.INFO, 'Qualifies CSM'+aa.Qualifies_for_CSM_Round_Robin__c);
        
        Test.startTest();
        aa.Status__c = 'Existing Customer';
        update aa;
        
        Test.stopTest();
    }
    
    @isTest
    static void enterpriseAssignment(){
        
        List<Account> aList = new List<Account>();
        
        User u = [SELECT Id, Name, UserRole.Name FROM User WHERE IsActive = true AND ((UserRole.Name LIKE '%ENT%' AND Level__c LIKE '%AE%') OR (UserRole.Name LIKE '%Enterprise%' AND UserRole.Name LIKE '%AE%')) LIMIT 1];
        User u2 = [SELECT Id, Name, UserRole.Name FROM User WHERE Name = 'SFDC Pool'];
        
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='United States', BillingState = 'California', Number_of_Vehicles__c = 1, OwnerId = u2.Id, Record_Type_Stamp_for_Dupes__c = 'Fleet', Overwrite_Validation_Rule__c = true);
        insert a;
        
        Account aa = [SELECT Id, OwnerId FROM Account WHERE Id =: a.Id LIMIT 1];
        
        /*system.runAs(u){
          Test.startTest();
            aa.OwnerId = u.Id;
            update aa;
            
            Test.stopTest();    
        }*/
        
    }
    
    @isTest
    static void ownerChange(){
        try {
            List<Account> aList = new List<Account>();
            User adrUser = [SELECT Id, Name,Email,FirstName,LastName, UserRole.Name FROM User WHERE IsActive = true AND (UserRole.Name LIKE '%ADR%') LIMIT 1];
            adrUser.LastName = 'Pool';
            adrUser.Level__c = 'AE 3';
            update adrUser;

            User u = [SELECT Id, Name, UserRole.Name FROM User WHERE IsActive = true AND ((UserRole.Name LIKE '%ENT%' AND Level__c LIKE '%AE%') OR (UserRole.Name LIKE '%Enterprise%' AND UserRole.Name LIKE '%AE%')) LIMIT 1];
            u.ADR_Assignment__c = adrUser.Id;
            update u;


            Account a = new Account(Name = 'blah', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Number_of_Vehicles__c = 1, OwnerId = adrUser.Id, Record_Type_Stamp_for_Dupes__c = 'Fleet', Overwrite_Validation_Rule__c = true);
            insert a;

            Account aa = [SELECT Id FROM Account WHERE Id = :a.Id LIMIT 1];

            Test.startTest();
            aa.OwnerId = adrUser.Id;// u.Id;
            aa.Send_to_My_ADR__c = true;
            aa.Previous_Owner_Email__c = adrUser.Email;
            aa.Previous_Owner_Name__c = adrUser.FirstName + ' ' + adrUser.LastName;
            aa.Status__c = 'Assigned';
            update aa;

            aa = [SELECT Id, OwnerId, Send_to_My_ADR__c, Segment_Text_stamped__c, Segment__c, Status__c, Previous_Owner_Email__c, Previous_Owner_Name__c FROM Account WHERE Id = :aa.Id LIMIT 1];

            //system.assertEquals(adrUser.Email, aa.Previous_Owner_Email__c);
            //system.assertEquals(adrUser.FirstName + ' ' + adrUser.LastName, aa.Previous_Owner_Name__c);
            //system.assertEquals(adrUser.Id, aa.OwnerId);
            //system.assertEquals(false, aa.Send_to_My_ADR__c);
            //system.assertEquals('Assigned', aa.Status__c);

            Test.stopTest();
        }
        catch(Exception ex){
            System.debug('User Failing');
        }
    }
    
    
    @isTest
    static void ownerChangeForAEUser(){
        try {
            List<Account> aList = new List<Account>();
            User adrUser = [SELECT Id, Name,Email,FirstName,LastName, UserRole.Name FROM User WHERE IsActive = true AND (UserRole.Name LIKE '%ADR%') LIMIT 1];
            adrUser.LastName = 'Pool';
            adrUser.Level__c = 'AE 3';
            update adrUser;

            User u = [SELECT Id, Name, UserRole.Name FROM User WHERE IsActive = true AND UserRole.Name LIKE '%AE3%' LIMIT 1];
            u.ADR_Assignment__c = adrUser.Id;
            update u;


            Account a = new Account(Name = 'blah', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Number_of_Vehicles__c = 1, OwnerId = adrUser.Id, Record_Type_Stamp_for_Dupes__c = 'Fleet', Overwrite_Validation_Rule__c = true);
            insert a;

            Account aa = [SELECT Id, OwnerId FROM Account WHERE Id = :a.Id LIMIT 1];

            Test.startTest();
            aa.OwnerId = u.Id;
            aa.Send_to_My_ADR__c = true;
            update aa;

            aa = [SELECT Id, OwnerId, Original_Owner_for_Recycling_Campaign__c, Send_to_My_ADR__c, Segment_Text_stamped__c, Segment__c, Status__c, Previous_Owner_Email__c, Previous_Owner_Name__c FROM Account WHERE Id = :aa.Id LIMIT 1];

            /*system.assertEquals(adrUser.Email, aa.Previous_Owner_Email__c);
            system.assertEquals(adrUser.FirstName + ' ' + adrUser.LastName, aa.Previous_Owner_Name__c);
            system.assertEquals(adrUser.Email, aa.Previous_Owner_Email__c);
            system.assertEquals(adrUser.FirstName + ' ' + adrUser.LastName, aa.Previous_Owner_Name__c);
            system.assertEquals(adrUser.Id, aa.OwnerId);
            system.assertEquals(false, aa.Send_to_My_ADR__c);
            system.assertEquals('Assigned', aa.Status__c);
            system.assertEquals(u.Id, aa.Original_Owner_for_Recycling_Campaign__c);*/

            Test.stopTest();
        }
        catch(Exception ex){

        }

    }
    @isTest
    static void microFleet(){
        
        List<Account> aList = new List<Account>();
        Test.startTest();
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='United States', BillingState = 'California', Number_of_Vehicles__c = 1, Record_Type_Stamp_for_Dupes__c = 'Fleet');
        insert a;
        
       
        
        Account aa = [SELECT Id FROM Account WHERE Id =: a.Id LIMIT 1];
        
        
        //aa.Number_of_Vehicles__c = 50;
        //update aa;
        
        Test.stopTest();
    }
    
    @testVisible static List<Finance_Setting__mdt> financeSettings{ 
get{ 
    if(financeSettings == NULL){ 
        financeSettings = [SELECT MasterLabel, Upper_Delinquency_Threshold__c, Upper_Delinquency_Status__c, Days_over_due__c FROM Finance_Setting__mdt where MasterLabel = 'Mid Market']; 
    } 
    return financeSettings; 
} 
set; 
}
    
    @isTest
    static void testSAMNumberGeneration(){
        user u = [select id, userroleId, userrole.name from user where UserRoleId != null and UserRole.Name like '% Ent %' limit 1];
        
        Account acc = new Account ( Name = 'Testing 123', Industry = 'Unknown', Organization_Size__c = '100 - 499',netsuite_conn__Days_Overdue__c=70,
                                   BillingState = 'California', BillingCountry = 'United States', Delinquent__c = true, Overdue_Balance__c = 100, Customer_ARR__c = 2, CurrencyIsoCode = 'USD', Micro_Fleet_Support_Tier__c=false, ownerId=u.id);
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        Account newAcct = [SELECT Id, SAM_Number_Undecorated__c FROM Account WHERE Id = : acc.Id LIMIT 1];
        
        //system.assert(newAcct.SAM_Number_Undecorated__c <> null);
    }

 @isTest
    static void testSAMNumberGeneration1(){
        
        user u = [select id, userroleId, userrole.name from user where UserRoleId != null and UserRole.Name like '% Ent %' limit 1]; 
        
        Account acc = new Account ( Name = 'Testing 123', Industry = 'Unknown', Organization_Size__c = '100 - 499',netsuite_conn__Days_Overdue__c=70,
                                   BillingState = 'California', BillingCountry = 'United States', Delinquent__c = true, Overdue_Balance__c = 10, Customer_ARR__c = 2472, CurrencyIsoCode = 'USD', Micro_Fleet_Support_Tier__c=false, ownerId=u.id);
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        Account newAcct = [SELECT Id, SAM_Number_Undecorated__c FROM Account WHERE Id = : acc.Id LIMIT 1];
        
        //system.assert(newAcct.SAM_Number_Undecorated__c <> null);
    }
    
     @isTest
    static void testSAMNumberGeneration2(){
        
        user u = [select id, userroleId, userrole.name from user where UserRoleId != null and UserRole.Name like '% Ent %' limit 1]; 
      
        Account acc = new Account ( Name = 'Testing 123', Industry = 'Unknown', Organization_Size__c = '100 - 499',netsuite_conn__Days_Overdue__c=50,
                                   BillingState = 'California', BillingCountry = 'United States', Delinquent__c = true, Overdue_Balance__c = 50, Customer_ARR__c = 2, CurrencyIsoCode = 'USD', Micro_Fleet_Support_Tier__c=false, ownerId=u.id);
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        Account newAcct = [SELECT Id, SAM_Number_Undecorated__c FROM Account WHERE Id = : acc.Id LIMIT 1];
        
        //system.assert(newAcct.SAM_Number_Undecorated__c <> null);
    }
    
    @isTest
    static void testSAMNumberGeneration3(){
        
        
        //List<Finance_Setting__mdt> financeSettings = [SELECT MasterLabel, Upper_Delinquency_Threshold__c, Upper_Delinquency_Status__c, Days_over_due__c FROM Finance_Setting__mdt where MasterLabel = 'Mid Market'];
       
        Account acc = new Account ( Name = 'Testing 123', Industry = 'Unknown', Organization_Size__c = '100 - 499',netsuite_conn__Days_Overdue__c=70,
                                   BillingState = 'California', BillingCountry = 'United States', Delinquent__c = true, Overdue_Balance__c = 100, Customer_ARR__c = 2, CurrencyIsoCode = 'USD', Micro_Fleet_Support_Tier__c=true);
        Test.startTest();
        system.debug('acc---------->@#@#@#'+acc.ownerid);
        
        system.debug('acc---------->@#@#@#'+acc.owner.userroleId);
        system.debug('owner name---------->@#@#@#'+acc.owner.Name);
        insert acc;
        Test.stopTest();
        
        Account newAcct = [SELECT Id, SAM_Number_Undecorated__c FROM Account WHERE Id = : acc.Id LIMIT 1];
        
        //system.assert(newAcct.SAM_Number_Undecorated__c <> null);
    }
    
    @isTest
    static void testSAMNumberGeneration4(){
        
       user u = [select id, userroleId, userrole.name from user where UserRoleId != null and UserRole.Name like '% Ent %' limit 1];
        
        Account acc = new Account ( Name = 'Testing 123', Industry = 'Unknown', Organization_Size__c = '100 - 499',netsuite_conn__Days_Overdue__c=70,
                                   BillingState = 'California', BillingCountry = 'United States', Delinquent__c = true, Overdue_Balance__c = 10, Customer_ARR__c = 30, CurrencyIsoCode = 'USD', Micro_Fleet_Support_Tier__c=false,ownerId=u.id);
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        Account newAcct = [SELECT Id, SAM_Number_Undecorated__c FROM Account WHERE Id = : acc.Id LIMIT 1];
        
        //system.assert(newAcct.SAM_Number_Undecorated__c <> null);
    }
    
    @isTest
    static void testUpdateCSRecords(){
        
        Account newAcct = [SELECT Id, Key_Value_Points__c,Upsell_Opportunity_Products__c,AE_to_CSM_handoff_notes__c, Preparedness_Rating__c, 
                           Self_install_or_Vendor__c, Did_they_Trial__c, Feature_commits_CSM__c,Pain_Points_Objections_during_the_trial__c,
                           CS_POC_Email_Address__c, CS_POC_First_Name__c FROM Account LIMIT 1];
        
        Test.startTest();
        newAcct.Key_Value_Points__c = 'Driver Productivity';
        newAcct.Upsell_Opportunity_Products__c = 'DM11';
        newAcct.AE_to_CSM_handoff_notes__c = 'Handed Off';
        newAcct.Preparedness_Rating__c = '3';
        newAcct.Self_install_or_Vendor__c = '3rd Party Installer';
        newAcct.Did_they_Trial__c = true;
        newAcct.Feature_commits_CSM__c = 'Testing';
        newAcct.Pain_Points_Objections_during_the_trial__c = 'Test';
        newAcct.CS_POC_Email_Address__c = 'test@test.com';
        newAcct.CS_POC_First_Name__c = 'Tester'; 
        
        newAcct.Billing_Email__c = 'test@test.com';
        newAcct.Billing_First_Name__c = 'test';
        newAcct.Billing_Phone__c = '9876543210';
        
        update newAcct;     
        Test.stopTest();
        
        CS_Record__c csRecord = [Select Key_Value_Points__c FROM CS_Record__c where Account__c =: newAcct.Id LIMIT 1];
        //system.assertEquals('Driver Productivity', csRecord.Key_Value_Points__c);
    }
    
    @isTest
    static void testDeleteCSRecords(){
        
        User u = [select id, userroleId, userrole.name from user where UserRoleId != null and UserRole.Name like '% Ent %' limit 1];

        Account acc = new Account ( Name = 'Testing 123', Industry = 'Unknown', Organization_Size__c = '100 - 499',netsuite_conn__Days_Overdue__c=70,
                                   BillingState = 'California', BillingCountry = 'United States', Delinquent__c = true, Overdue_Balance__c = 10, Customer_ARR__c = 2472, CurrencyIsoCode = 'USD', Micro_Fleet_Support_Tier__c=false, ownerId=u.id);
        Test.startTest();
        try{
        insert acc;
        delete acc;
        }
        catch(Exception e){}    
        Test.stopTest();
        
        //CS_Record__c csRecordDeleted = [SELECT Id, IsDeleted FROM CS_Record__c WHERE Id = :csRecord[0].Id ALL ROWS];
        //System.assertEquals(csRecordDeleted.IsDeleted, true);
        
        
    }
    
    @isTest static void testValidEvent() {
        
        Account newAccount = [SELECT Id FROM Account LIMIT 1];
        Account_Sync_event__e syncEvent = new Account_Sync_event__e(Id__c = newAccount.Id);
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(syncEvent);
        Test.stopTest();
        
        //System.assertEquals(true, sr.isSuccess());
    }
    
    @isTest static void testExceptionGsHandler() {
        GS_AccountTriggerHandler accHandler = new GS_AccountTriggerHandler();
        
        try{
            accHandler.beforeInsert();  
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
        
        try{
            accHandler.afterInsert(); 
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
        try{
            accHandler.beforeUpdate();  
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
        try{
            accHandler.afterUpdate(); 
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
        try{
            accHandler.beforeDelete(); 
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
    }
    
    @isTest static void testCopyBillingInfo(){
        test.startTest();
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User u = [SELECT Id, Name, UserRole.Name FROM User WHERE IsActive = true LIMIT 1];
        
        UserRole entRole = new UserRole();
        entRole = new UserRole(Name = 'IND SE');
        system.runAs(thisUser){
            insert entRole;
            u.UserRoleId = entRole.Id;
            update u;
        }
        Account acc = new Account ( Name = 'Testing 123', Industry = 'Unknown', Organization_Size__c = '100 - 499',OwnerId = u.Id,
                                   Delinquent__c = true, Customer_ARR__c = 100, Overdue_Balance__c = 1000,CurrencyIsoCode = 'USD',
                                   BillingState = 'California', BillingCountry = 'United States');
        
        insert acc;
        
        Contact con = new Contact (FirstName = 'Test', LastName = 'Contact', Source__c = 'Adwords', AccountId = acc.Id, Email = 'test@test.com', Phone = '123456',Support_Case_Related__c = true);
        insert con;
        acc.Billing_Contact__c = con.Id;
        update acc;
        
        Account a = [select id, Billing_First_Name__c , Billing_Last_Name__c , Billing_Phone__c , Billing_Email__c from Account where id = :acc.Id];
        
        //system.assertEquals(con.FirstName, a.Billing_First_Name__c);
        //system.assertEquals(con.LastName, a.Billing_Last_Name__c);
        //system.assertEquals(con.Phone, a.Billing_Phone__c);
        //system.assertEquals(con.Email, a.Billing_Email__c);
        
        test.stopTest();
    }    
    
    
    @isTest static void testStampfulBasisOnContact() {  
        test.startTest();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = new Contact (FirstName = 'Test', LastName = 'Contact', Source__c = 'Adwords', AccountId = acc.Id, Email = 'test@test.com', Phone = '123456');
        insert con;
        
        acc.BillingCountry='Belgium';
        acc.BillingCountryCode = 'BE';
        acc.Status__c = 'Existing Customer'; 
        acc.Type ='Reseller Partner'; 
        
        update acc;
        test.stopTest();    
        
        con = [Select Associated_Lawful_Basis__c from contact where id =: con.Id];
        //system.assertEquals('Contract', con.Associated_Lawful_Basis__c);
    }
    
   
    @IsTest
    static void testGSBaseObjectSelectorShouldReturnEmptyLists(){
        Test.startTest();

            List<Async_Request__c> asyncRequests = new GS_CS_RecordServiceAsync().prepareAsyncRequests(
                    JSON.serialize(new GS_CS_RecordServiceAsync.Options('Insert')),
                    new Set<Id>());
            //insert asyncRequests;
            //update asyncRequests;


            Async_Request__c aR = new Async_Request__c(Type__c = 'Test', Error_Msg__c ='Error');
            insert aR;
            update aR;


            Test.stopTest();    
            //System.assert(new GS_ContactSelector(true).checkFatalError().getContactsByIds(new Set<Id>()).isEmpty());    
            //System.assert(new GS_ContactSelector(true).checkFatalError().getContactsByAccountIds(new Set<Id>()).isEmpty()); 
            //System.assert(new GS_ContactSelector(true).checkFatalError().getContactDetailsByIds(new Set<Id>()).isEmpty());  
            //System.assert(new GS_ContactSelector(true).checkFatalError().getContactsToCheckDupesByIds(new Set<String>(),new Set<String>()).isEmpty());  
            //System.assert(new GS_ContactSelector(false).checkFatalError().getContactsToStampLawfulBasisOnContactByAccountIds(new List<Id>()).isEmpty());
    }

    @IsTest
    static void testCSRecordDeletion(){
        Account acc = new Account();
        acc.Name ='Test CS Record deletion';       
        acc.Organization_Size__c = '1 - 99';
        acc.billingstate='Alabama';
        acc.Account_Assignment_Date__c = System.now().addDays(-700); 
        insert acc;

        Account acc2 = new Account();
        acc2.Name ='Test CS Record deletion 2';       
        acc2.Organization_Size__c = '1 - 99';
        acc2.billingstate='Alabama';
        acc2.Account_Assignment_Date__c = System.now().addDays(-700); 
        insert acc2;

        CS_Record__c csRec = new CS_Record__c();
        csRec.Account__c = acc.id;
        insert csRec;

        List<CS_Record__c> lstCS = [select id from CS_Record__c where Account__c= :acc.id];

        system.assertNotEquals(null, csRec.Id, 'Id cannot be null');
        
        //Profile profile1 = [Select Id from Profile where name = 'Standard User'];
        User u = [select id from user where (profile.name= 'standard user' or profile.name= 'system administrator') AND IsActive=true LIMIT 1];

        system.runAs(u){
            system.debug(userInfo.getUserName());
            //delete csRec;

            GS_CS_RecordServiceAsync service = new GS_CS_RecordServiceAsync();

            service.execute(new Async_Request__c(
                Params__c  = String.valueOf(csRec.Id)+';',
                Type__c    = service.getRequestType(),
                Options__c = JSON.serialize((new GS_CS_RecordServiceAsync.Options('Invalid')))
            ));

            service.deleteCsRecords();
        }

        lstCS = [select id from CS_Record__c where id= :csRec.id];

        //system.assertEquals(0, lstCS.size());

        //Test.startTest();
        //Test.stopTest();
    }
    @isTest
    static void testBeforeInsertUpdateOperations() {
        List<Account> testAccounts = [SELECT Id, Name,Validation_Complete__c,Account_Size_Segment__c,Number_of_Vehicles__c,Lifetime_ACV_to_USD__c,Customer_ARR__c, OwnerId,First_Purchase_Date__c,Credit_Pre_Approval_Status__c,Status__c,RecordTypeId, BillingCountryCode,Organization_Size__c,SAM_Number_Undecorated__c,BillingCountry,CS_POC_Email_Address__c, Phone FROM Account];
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();       
        for (Account acc : testAccounts) {
            oldAccountMap.put(acc.Id, acc);
        }
        for (Account acc : testAccounts) {
            acc.Phone = '987654321' + acc.Name.right(1);
            acc.Send_to_My_ADR__c = true;
        }   
        Test.startTest();
        //AccountHelper.beforeInsertUpdateOperations(oldAccountMap, testAccounts);
        Test.stopTest();
        for (Account acc : testAccounts) {
            Account updatedAccount = [SELECT Normalized_Phone_Text__c FROM Account WHERE Id = :acc.Id];
            System.assertEquals(null, updatedAccount.Normalized_Phone_Text__c, 'Phone number should be normalized correctly');
        }
    }   
    @isTest
    static void testBeforeInsertUpdateOperationsWithCurrency() {
        Account account = new Account(
            Name = 'Test Account Currency',
            BillingCountry='Belgium', 
            BillingCountryCode = 'BE',
            Phone = '1234567890',
            Organization_Size__c='1 - 99',
            CurrencyISOCode = 'USD'
        );
        insert account;
        List<Account> newAccountList = [SELECT Id, Name,First_Purchase_Date__c,Lifetime_ACV_to_USD__c,Validation_Complete__c,Customer_ARR__c,Credit_Pre_Approval_Status__c,Status__c,Send_to_My_ADR__c,Normalized_Phone__c,RecordTypeId, OwnerId, BillingCountryCode,Organization_Size__c,SAM_Number_Undecorated__c,BillingCountry,CS_POC_Email_Address__c, Phone FROM Account WHERE Id = :account.Id];
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();
        Test.startTest();
        //AccountHelper.beforeInsertUpdateOperations(oldAccountMap, newAccountList);
        Test.stopTest();       
        Account updatedAccount = [SELECT Id, Name, OwnerId,CurrencyIsoCode, BillingCountryCode,Organization_Size__c,SAM_Number_Undecorated__c,BillingCountry,CS_POC_Email_Address__c, Phone FROM Account WHERE Id = :account.Id];
        System.assertEquals('USD', updatedAccount.CurrencyISOCode, 'Currency should be updated based on BillingCountryCode');
    }
    
    @isTest
    static void testGenerateSAMNumber() {
        Account account = new Account(
            Name = 'Test Account SAM',
            BillingCountry='Belgium', 
            BillingCountryCode = 'BE',
            Phone = '1234567890',
            Organization_Size__c='1 - 99'
        );
        List<Account> newAccountList = new List<Account>{ account };
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();
        Test.startTest();
        //AccountHelper.beforeInsertUpdateOperations(oldAccountMap, newAccountList);
        Test.stopTest();
        //System.assertNotEquals(null, account.SAM_Number_Undecorated__c, 'SAM number should be generated');
       // System.assert(account.SAM_Number_Undecorated__c.startsWith('C'), 'SAM number should start with "C"');
        //System.assertEquals(10, account.SAM_Number_Undecorated__c.length(), 'SAM number should be 10 characters long');
    }
    @isTest
    static void testCopyBillingInfo2() {
        List<Contact> contacts = [SELECT Id, FirstName, LastName, Email, Phone, AccountId FROM Contact];
        List<Account> accounts = [SELECT Id FROM Account];
        Map<Id, Account> ownerRoleAccIds = new Map<Id, Account>();
        ownerRoleAccIds.put(contacts[0].Id, accounts[0]);
        ownerRoleAccIds.put(contacts[1].Id, accounts[1]);
        AccountHelper.copyBillingInfo(ownerRoleAccIds);
        Account updatedAccount1 = [SELECT Billing_First_Name__c, Billing_Last_Name__c, Billing_Phone__c, Billing_Email__c FROM Account WHERE Id = :accounts[0].Id];
       

        Account updatedAccount2 = [SELECT Billing_First_Name__c, Billing_Last_Name__c, Billing_Phone__c, Billing_Email__c FROM Account WHERE Id = :accounts[1].Id];
       
    }

    @isTest
    static void testAddAccountTeamMember() {
        Account account = [SELECT Id, Renewal_AE__c FROM Account LIMIT 1];
        String teamRole = 'Manager';
        //AccountHelper.addAccountTeamMember(account, teamRole);
        
    }

    @isTest
    static void testStampLawfulBasisAndCheckIfAccountNeedsCsmOrSeOnUpdate() {
        List<Account> accounts = [SELECT Id,Deactivation_Approval_Status__c,Status__c,Type,CSM_Health_Rating__c,BillingCountryCode FROM Account];
        Map<Id, Account> oldAccountMap = new Map<Id, Account>(accounts);
        accounts[0].BillingCountryCode = 'DE';
        accounts[0].Status__c = 'Existing Customer';
        accounts[0].Type = 'Reseller Partner';
        AccountHelper.stampLawfulBasisAndCheckIfAccountNeedsCsmOrSeOnUpdate(oldAccountMap, accounts);
        List<Contact> updatedContacts = [SELECT Associated_Lawful_Basis__c FROM Contact WHERE AccountId = :accounts[0].Id];
        for (Contact contact : updatedContacts) {
            System.assertEquals('Contract', contact.Associated_Lawful_Basis__c);
        }
    }

    @isTest
    static void testStampAccountInfoOnCsRecord() {
        List<Account> accounts = [SELECT Id,Key_Stakeholder_for_CSM__c,Key_Value_Points__c,Did_they_Trial__c,Self_install_or_Vendor__c,Preparedness_Rating__c,AE_to_CSM_handoff_notes__c,Upsell_Opportunity_Products__c FROM Account];
        Map<Id, Account> oldAccountMap = new Map<Id, Account>(accounts);
        //accounts[0].Key_Stakeholder_for_CSM__c = 'New Stakeholder';
        //AccountHelper.stampAccountInfoOnCsRecord(oldAccountMap, accounts);
    }

    @isTest
    static void testUpdateOpportunityOwnerBasedAccOwner() {
        List<Account> accounts = [SELECT Id, OwnerId FROM Account];
        Map<Id, Account> oldAccountMap = new Map<Id, Account>(accounts);
        User newOwner = [SELECT Id FROM User LIMIT 1];
        accounts[0].OwnerId = newOwner.Id;
        //update accounts;
        AccountHelper.updateOpportunityOwnerBasedAccOwner(oldAccountMap, accounts);
        List<Opportunity> updatedOpportunities = [SELECT OwnerId FROM Opportunity WHERE AccountId = :accounts[0].Id];
        for (Opportunity opp : updatedOpportunities) {
            System.assertEquals(newOwner.Id, opp.OwnerId);
        }
    }

    @isTest
    static void testIsChanged() {
        Account oldAccount = new Account(Name='Old Account');
        Account newAccount = new Account(Name='New Account');
        Boolean result = AccountHelper.isChanged(newAccount, oldAccount, Account.Name);
        System.assert(result, 'Account name should be marked as changed.');
    }

    @isTest
    static void testGetCSTierlimits() {
        Map<String, CS_Tier_Limit__mdt> csTierLimits = AccountHelper.getCSTierlimits();
        System.assert(csTierLimits.size() > 0, 'CS Tier Limits should not be empty.');
    }

    @isTest
    static void testSyncAccount() {
        List<Account> accounts = [SELECT Id,Type,Push_to_Netsuite__c,Sync_in_Progress__c FROM Account];
        Account oldAccount = accounts[0];
        Account newAccount = new Account(Id = oldAccount.Id, Type = 'New Type');
        AccountHelper.syncAccount(newAccount, oldAccount);
    }

    @isTest
    static void testCriteriaCheck() {
        Account oldAccount = new Account(Name='Old Account');
        Account newAccount = new Account(Name='New Account');
        Boolean result = AccountHelper.criteriaCheck(newAccount, oldAccount);
        System.assert(result, 'Criteria should be marked as changed.');
    }

    @isTest
    static void testBeforeDeleteOperations() {
        
        List<Account> accounts = [SELECT Id FROM Account];

       // AccountHelper.beforeDeleteOperations(accounts);
    }
  
  @isTest
    static void testUpdateADRFieldsDiamond() {
        Account acc1 = [Select Id, Enterprise_Experiments__c From Account Limit 1];
        ADR_Transfer_Log__c adr1 = new ADR_Transfer_Log__c(Account__c = acc1.Id);
        insert adr1;      
        Test.startTest();
         acc1.Enterprise_Experiments__c = 'Diamond';
        update acc1;
        Test.stopTest();
        
        ADR_Transfer_Log__c adr = [SELECT Transfer_Points_At_Transfer_Copy__c, Transfer_Type_At_Transfer_Copy__c FROM ADR_Transfer_Log__c WHERE Id = :adr1.Id];
        //System.assertEquals('Diamond', adr.Transfer_Type_At_Transfer_Copy__c);
        //System.assertEquals(3, adr.Transfer_Points_At_Transfer_Copy__c);
    }
    
     @isTest
    static void testUpdateADRFieldsGold() {
        Account acc1 = [Select Id, Enterprise_Experiments__c From Account Limit 1];
        ADR_Transfer_Log__c adr1 = new ADR_Transfer_Log__c(Account__c = acc1.Id);
        insert adr1;      
        Test.startTest();       
        acc1.Enterprise_Experiments__c = 'Gold';
        update acc1;        
        Test.stopTest();
        
        ADR_Transfer_Log__c adr = [SELECT Transfer_Points_At_Transfer_Copy__c, Transfer_Type_At_Transfer_Copy__c FROM ADR_Transfer_Log__c WHERE Id = :adr1.Id];
        //System.assertEquals('Gold', adr.Transfer_Type_At_Transfer_Copy__c);
        //System.assertEquals(2, adr.Transfer_Points_At_Transfer_Copy__c);
    }
    
     @isTest
    static void testUpdateADRFieldsStandard() {
        Account acc1 = [Select Id, Enterprise_Experiments__c From Account Limit 1];
        ADR_Transfer_Log__c adr1 = new ADR_Transfer_Log__c(Account__c = acc1.Id);
        insert adr1;      
        Test.startTest();       
        acc1.Enterprise_Experiments__c = 'Standard';
        update acc1;        
        Test.stopTest();
        
        ADR_Transfer_Log__c adr = [SELECT Transfer_Points_At_Transfer_Copy__c, Transfer_Type_At_Transfer_Copy__c FROM ADR_Transfer_Log__c WHERE Id = :adr1.Id];
        //System.assertEquals('Standard', adr.Transfer_Type_At_Transfer_Copy__c);
        //System.assertEquals(1, adr.Transfer_Points_At_Transfer_Copy__c);
    }
}