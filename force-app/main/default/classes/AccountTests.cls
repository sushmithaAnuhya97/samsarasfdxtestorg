@isTest
private class AccountTests {

    @TestSetup
    static void makeData(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Profile adrProfile = [SELECT Id FROM Profile WHERE Name = 'Samsara Inbound ADRs'];
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        // Create all users in a single transaction
        List<User> usersToCreate = new List<User>();
        
        User managerUser = new User(lastName = 'Manager',
                                  FirstName = 'Test',
                                  email = uniqueName + '.mgr@test' + orgId + '.org',
                                  Username = uniqueName + '.mgr@test' + orgId + '.org',
                                  EmailEncodingKey = 'ISO-8859-1',
                                  Alias = 'tmgr',
                                  TimeZoneSidKey = 'America/Los_Angeles',
                                  LocaleSidKey = 'en_US',
                                  LanguageLocaleKey = 'en_US',
                                  ProfileId = p.Id,
                                  EmployeeNumber='123');
        insert managerUser;
        
        System.runAs(managerUser) {
            // Create test accounts
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
        }
    }

    public static Opportunity createOppty(String shippingCarrier, String returnType, Id accountId){
        Opportunity testOppty = new Opportunity();
        testOppty.Can_Create__c = true;
        testOppty.ForecastCategoryName = 'Forecast';
        testOppty.Shipping_Method__c = 'Will Call';
        testOppty.Type = returnType;
        testOppty.Shipping_Email_Sent_bypassed__c = false;
        testOppty.Shipping_Country__c = 'Canada';
        testOppty.Shipping_Carrier__c = shippingCarrier;

        testOppty.Name = 'TestAccountTest -';
        testOppty.AccountId = accountId;
        testOppty.Amount = 1000000;
        testOppty.CloseDate = Date.today();
        testOppty.ACV_Commissionable_Dollars_Copy__c = 0;
        testOppty.Internal_Finance__c = 'Approved';
        testOppty.Internal_Financing_Response_Timestamp__c = Datetime.now();
        testOppty.LeadSource = 'Other';
        testOppty.Lead_Source_Encoded__c = 2019072519;
        testOppty.netsuite_conn__Order_Type__c = 'Contract - New';
        testOppty.Owner_Role_Copy__c = 'Management';
        testOppty.Selected_Payment_Type__c = 'Upfront Payments';
        testOppty.Shipping_Address_New_Concatenated__c = ',';
        testOppty.StageName = 'Closed Won';

        return testOppty;
    }

    public static Contact createContact(Id accountId) {
        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = accountId;
        testContact.Source__c = 'Adwords';
        testContact.Email = 'test@test.com';
        return testContact;
    }

    @isTest static void testAccountInsertsAndUpdate() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'Manager' LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Contact shippingContact = createContact(acc.Id);
        insert shippingContact;

        Opportunity o = createOppty('UPS', 'Revenue Opportunity', acc.Id);
        o.Shipping_Contact__c = shippingContact.Id;
        
        insert o;
        List<Account> updateList = new List<Account>();
        Map<ID, Schema.RecordTypeInfo> rt_Map = Account.sObjectType.getDescribe().getRecordTypeInfosById();
        for(Account a : [SELECT Id, RecordTypeId, CSM_First_30d_Stage__c FROM Account]) {
            a.RecordTypeId = rt_Map.values()[0].getRecordTypeId();
            a.OwnerId = testUser.Id;
            a.Overwrite_Validation_Rule__c = true;
            a.Record_Type_Stamp_for_Dupes__c = 'Fleet';
            a.Unload_Account__c = true;
            a.Status__c = 'Existing Customer';
            a.Global_Geography__c = 'West';

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
            
            update updateList;
        }
        Test.stopTest();
    }

    // Groundswell-Tanuj (GTMS-3000)- Changes for Workflow Conversion
    @isTest static void testworkflowConversions() {
        
        List<Account> aList = new List<Account>();
        
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', Record_Type_Stamp_for_Dupes__c = 'Fleet',Industry = 'Unknown',Enable_Delinquency_Process__c = false, Current_Telematics_Provider__c = 'Azuga', Number_of_Vehicles__c= 101);
        insert a;

        Opportunity o = createOppty('UPS', 'Revenue Opportunity', a.Id);
        o.StageName = 'Decision';
        insert o;

        Test.startTest();
        // Switch Account Status to Closed Lost Opportunity 
        o.Closed_Lost_Reason__c = 'Test Class';
        o.StageName = 'Closed Lost';
        update o;

        Account aa = [SELECT Id, SBQQ__CoTerminationEvent__c, SBQQ__ContractCoTermination__c, SBQQ__RenewalModel__c, SBQQ__RenewalPricingMethod__c FROM Account WHERE Id =: a.Id LIMIT 1];
        system.assertEquals(Label.PicklistValueAsNone, aa.SBQQ__CoTerminationEvent__c);
        system.assertEquals(Label.PicklistValueAsNone, aa.SBQQ__ContractCoTermination__c);
        system.assertEquals(Label.ContractBasedValue, aa.SBQQ__RenewalModel__c);
        system.assertEquals(Label.SameValue, aa.SBQQ__RenewalPricingMethod__c);

        //Unload Account True
        aa.Unload_Account__c = true;
        aa.New_Billing_Process_Approved__c = true;
        update aa;
        Account updatedAccount = [SELECT Id, Status__c, Churn_Payment_Status__c, Enable_Delinquency_Process__c, Quarantine_Enabled__c,Delinquent_As_Of__c, Unload_Account__c,CSM__c FROM Account WHERE Id =: aa.Id LIMIT 1];
        
        // Switch Account Status to Closed Lost Opportunity 
        system.assertEquals('Closed Lost Opportunity',updatedAccount.Status__c);

        //Unload Account True
        system.assertEquals(False, updatedAccount.Unload_Account__c);
        
        // WF Rule - Territory Field Update with Industry
        updatedAccount.Record_Type_Stamp_for_Dupes__c = Label.RecordTypeStampForDupesIndustrial;
        updatedAccount.Industry = Label.AccountIndustry_EducationalServices;

        update updatedAccount;
        
        //WF Rule - Account: Microfleet new billing
        updatedAccount.Micro_Fleet_Support_Tier__c = true;
        
        updatedAccount.Current_Trailer_Telematics_Provider__c = 'Verizon';

        update updatedAccount;
        Account updatedAccountAfterMultiFlows = [SELECT Id, AG_Upsell_Updates__c, New_Billing_Process_Approved__c, Enrichment_Complete_Date__c, Segment__c,Segment_Text_stamped__c,Initiate_Round_Robin__c,Suspension_Grace_Days__c,Quarantine_Enabled_At__c, Delinquent_As_Of__c, Unload_Account__c,CSM__c, Churn_Payment_Status__c, Enable_Delinquency_Process__c FROM Account WHERE Id =: updatedAccount.Id LIMIT 1];
        
        // WF Rule - Territory Field Update
        //system.assertEquals(True, updatedAccountAfterMultiFlows.Initiate_Round_Robin__c);
        
        // WF Rule - Account: Microfleet new billing
        system.assertEquals(true,updatedAccountAfterMultiFlows.New_Billing_Process_Approved__c);
        // WF Rule - Enrichment Complete Date Stamp
        // As Enrichment_Complete__c is a formula field to set it true ,Formula (Number_of_Vehicles__c > 100 AND ,Current Telematics Provider must not be null)
        system.assertEquals(system.today(),updatedAccountAfterMultiFlows.Enrichment_Complete_Date__c);

        system.assertEquals(true,updatedAccountAfterMultiFlows.AG_Upsell_Updates__c);
         
        Account updatedAccountAfterUpsellUpdates = [SELECT Id, AG_Upsell_Updates__c, Initiate_Round_Robin__c, Suspension_Grace_Days__c, Quarantine_Enabled_At__c FROM Account WHERE Id =: updatedAccountAfterMultiFlows.Id LIMIT 1];
        
        updatedAccountAfterUpsellUpdates.Current_Construction_Equip_Telematics__c = 'Geoforce';
        update updatedAccountAfterUpsellUpdates;

        Account updatedAccountAfterUpsellUpdatesTwo = [SELECT Id, AG_Upsell_Updates__c FROM Account WHERE Id =: updatedAccountAfterUpsellUpdates.Id LIMIT 1];
        system.assertEquals(true,updatedAccountAfterUpsellUpdatesTwo.AG_Upsell_Updates__c);

        updatedAccountAfterUpsellUpdatesTwo.Description = 'Long Text Area';
        update updatedAccountAfterUpsellUpdatesTwo;

        Account updatedAccountAfterUpsellUpdatesThree = [SELECT Id, AG_Upsell_Updates__c FROM Account WHERE Id =: updatedAccountAfterUpsellUpdatesTwo.Id LIMIT 1];
        system.assertEquals(true,updatedAccountAfterUpsellUpdatesThree.AG_Upsell_Updates__c);

        updatedAccountAfterUpsellUpdatesThree.Number_of_Powered_Assets__c = 10;
        update updatedAccountAfterUpsellUpdatesThree;

        Account updatedAccountAfterUpsellUpdatesFour = [SELECT Id, AG_Upsell_Updates__c FROM Account WHERE Id =: updatedAccountAfterUpsellUpdatesThree.Id LIMIT 1];
        system.assertEquals(true,updatedAccountAfterUpsellUpdatesFour.AG_Upsell_Updates__c);

        Test.stopTest();
    }

    // Groundswell-Tanuj : Changes for Delinquency Workflow Conversion
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
        system.assertEquals(Label.Churn_Payment_Status_Delinquent, accTwoAfterInsert.Churn_Payment_Status__c);
        system.assertEquals(true, accTwoAfterInsert.Enable_Delinquency_Process__c);
        
        insert new Delinquency_Defaults__c(Delinquency_Default_Grace_Period__c=60);
        
        
        a.Enable_Delinquency_Process__c = false;
        a.Delinquent__c = true;
        
        update a;
        
        Account aa = [SELECT Id, Delinquent_As_Of__c,SBQQ__CoTerminationEvent__c, Quarantine_Enabled__c, Enable_Delinquency_Process__c, Churn_Payment_Status__c, SBQQ__ContractCoTermination__c, SBQQ__RenewalModel__c, SBQQ__RenewalPricingMethod__c FROM Account WHERE Id =: a.Id LIMIT 1];

        
        //Delinquent Timestamp
        //system.assertNotEquals(null, aa.Delinquent_As_Of__c);
        //Delinquency Unset
        //system.assertEquals(Label.Churn_Payment_Status_Current, aa.Churn_Payment_Status__c);
        system.assertEquals(false, aa.Enable_Delinquency_Process__c);
        system.assertEquals(false, aa.Quarantine_Enabled__c);
        
        aa.Delinquent__c = false;
        
        aa.Unload_Account__c = true;
        aa.New_Billing_Process_Approved__c = true;
        aa.Enable_Delinquency_Process__c = true;
        aa.Quarantine_Enabled__c = true;
        update aa;
        Account updatedAccount = [SELECT Id,Churn_Payment_Status__c, Suspension_Grace_Days__c, Quarantine_Enabled_At__c, Enable_Delinquency_Process__c, Quarantine_Enabled__c,Delinquent_As_Of__c, Unload_Account__c,CSM__c FROM Account WHERE Id =: aa.Id LIMIT 1];
        
        //Clear Delinquent Timestamp
        system.assertEquals(null, updatedAccount.Delinquent_As_Of__c);
        
        system.assertEquals(False, updatedAccount.Unload_Account__c);

        // WF Rule - Delinquency Setter with Enable_Delinquency_Process__c & Suspension_Grace_Days__c as null
        updatedAccount.Enable_Delinquency_Process__c = true;
        
       // WF Rule - Delinquency Starter
        
        updatedAccount.Churn_Payment_Status__c = Label.Churn_Payment_Status_Delinquent;
        updatedAccount.New_Billing_Process_Approved__c = false;
        
        update updatedAccount;
        Account updatedAccountAfterDelinquencyFlows = [SELECT Id, Segment__c,Segment_Text_stamped__c,Initiate_Round_Robin__c,Suspension_Grace_Days__c,Quarantine_Enabled_At__c, Delinquent_As_Of__c, Unload_Account__c,CSM__c, Churn_Payment_Status__c, Enable_Delinquency_Process__c FROM Account WHERE Id =: updatedAccount.Id LIMIT 1];
        
        //Delinquency Setter
        system.assertEquals(60, updatedAccountAfterDelinquencyFlows.Suspension_Grace_Days__c);
        system.assertEquals(Date.today().AddDays(60), updatedAccountAfterDelinquencyFlows.Quarantine_Enabled_At__c);
       
        system.assertEquals(Label.Churn_Payment_Status_Delinquent, updatedAccountAfterDelinquencyFlows.Churn_Payment_Status__c);
        system.assertEquals(True, updatedAccountAfterDelinquencyFlows.Enable_Delinquency_Process__c);

        updatedAccountAfterDelinquencyFlows.Suspension_Grace_Days__c = 30;
        updatedAccountAfterDelinquencyFlows.BillingCountry = 'United States';
        updatedAccountAfterDelinquencyFlows.BillingCountryCode = 'US';
        updatedAccountAfterDelinquencyFlows.BillingStateCode = 'CA';
        update updatedAccountAfterDelinquencyFlows;
        Account updatedAccountAfterBillingDetailsChanged = [SELECT Id, Segment__c,Segment_Text_stamped__c,Initiate_Round_Robin__c,Suspension_Grace_Days__c,Quarantine_Enabled_At__c, Delinquent_As_Of__c, Unload_Account__c,CSM__c, Churn_Payment_Status__c, Enable_Delinquency_Process__c FROM Account WHERE Id =: updatedAccount.Id LIMIT 1];
        
        //Delinquency Setter
        system.assertEquals(30, updatedAccountAfterBillingDetailsChanged.Suspension_Grace_Days__c);
        system.assertEquals(Date.today().AddDays(30), updatedAccountAfterBillingDetailsChanged.Quarantine_Enabled_At__c);

        //Delinquency or Quarantine Clear
        updatedAccountAfterBillingDetailsChanged.Enable_Delinquency_Process__c = false;
        updatedAccountAfterBillingDetailsChanged.Quarantine_Enabled__c = false;
        
        update updatedAccountAfterBillingDetailsChanged;
       
        Account updatedAccountAfterQuarantineClear = [SELECT Id, Quarantine_Enabled__c,Enable_Delinquency_Process__c,Quarantine_Enabled_At__c,Suspension_Grace_Days__c FROM Account WHERE Id =: updatedAccountAfterBillingDetailsChanged.Id LIMIT 1];
        
        system.assertEquals(false,updatedAccountAfterQuarantineClear.Quarantine_Enabled__c);
        system.assertEquals(false,updatedAccountAfterQuarantineClear.Enable_Delinquency_Process__c);
        system.assertEquals(null,updatedAccountAfterQuarantineClear.Quarantine_Enabled_At__c);
        system.assertEquals(null,updatedAccountAfterQuarantineClear.Suspension_Grace_Days__c);
        

        Test.stopTest();
    }
    
    // Groundswell-Tanuj (GTMS-3000)- Changes for Workflow Conversion
    @isTest static void testcompleteCsmOnboarding() {
	User managerUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'Manager' LIMIT 1];
        
        System.runAs(managerUser) {
            Account aa = new Account(Name='blah', Organization_Size__c='1 - 99', 
                                   BillingCountry='Belgium', BillingCountryCode = 'BE', 
                                   Record_Type_Stamp_for_Dupes__c = 'Fleet');
            insert aa;
            
            Test.startTest();
            
            aa.Unload_Account__c = true;
            aa.CSM_Initial_onboarding_completed_Time__c = null;
            aa.CSM_Sub_Status__c = Label.Onboarding_Complete;
            aa.CSM_Status__c = Label.Account_Management;
            aa.CSM_First_30d_Stage__c = Label.Initial_onboarding_complete;
            update aa;
            
            Test.stopTest();
            
            Account accountWithCSM = [SELECT Id, Delinquent_As_Of__c, CSM_who_completed_onboarding__c 
                                    FROM Account WHERE Id =: aa.Id LIMIT 1];
            
        }
    }
    
    @isTest 
    static void preApproveAndDeclineSamsaraStatusTest(){
        User managerUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'Manager' LIMIT 1];
        
        System.runAs(managerUser) {
            Account aa = new Account(Name='blah', Organization_Size__c='1 - 99', 
                                   BillingCountry='Belgium', BillingCountryCode = 'BE', 
                                   Record_Type_Stamp_for_Dupes__c = 'Fleet', 
                                   Unload_Account__c = true);
            insert aa;
            
            Test.startTest();
            
            aa.Overwrite_Validation_Rule__c = true;
            aa.DNBI_Data_Available__c = true;
            aa.DNBI_Recommended_Credit_Limit__c = 100;
            aa.DNBI_Trade_Experiences_Count__c = 6;
            aa.DNBI_Commercial_Credit_Percentage__c = 10;
            aa.DNBI_SlowNegExpCount__c = 5;
            aa.DNBI_Financial_Stress_Score__c = 10;
            aa.DNBI_PAYDEX__c = 90;
            update aa;
            
            Account updatedAccountAfterDecline = [SELECT Id, Samsara_PreApproval_Status__c, Credit_Scorecard_Score__c 
                                                FROM Account WHERE Id =: aa.Id LIMIT 1];
            system.assertEquals(Label.SamsaraPreApprovalDeclined, updatedAccountAfterDecline.Samsara_PreApproval_Status__c);
            
            updatedAccountAfterDecline.DNBI_Commercial_Credit_Percentage__c = 90;
            updatedAccountAfterDecline.DNBI_SlowNegExpCount__c = 50;
            updatedAccountAfterDecline.DNBI_Financial_Stress_Score__c = 95;
            updatedAccountAfterDecline.DNBI_PAYDEX__c = 90;
            update updatedAccountAfterDecline;
            
            Test.stopTest();
            
            Account updatedAccountAfterApproval = [SELECT Id, Samsara_PreApproval_Status__c, Credit_Scorecard_Score__c 
                                                 FROM Account WHERE Id =: updatedAccountAfterDecline.Id LIMIT 1];
            system.assertEquals(Label.SamsaraPreApprovalApproved, updatedAccountAfterApproval.Samsara_PreApproval_Status__c);
        }
    }

    //Groundswell: Nilesh Jain : Workflow changes related test method.
    @isTest static void testWorkflowChanges() {

        User managerUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'Manager' LIMIT 1];
        
        System.runAs(managerUser) {
            Account aa = new Account(Name='blah', Organization_Size__c='1 - 99',Industry='Government',
                                   BillingCountry='Belgium', BillingCountryCode = 'BE', 
                                   Record_Type_Stamp_for_Dupes__c = 'Fleet', 
                                   Micro_Fleet_Support_Tier__c = true);
            insert aa;
            
            Test.startTest();
            
            aa.Overwrite_Validation_Rule__c = true;
            aa.Industry = 'Educational Services';
            aa.Quarantine_Enabled__c = true;
            aa.Suspension_Grace_Days__c = 10;
            aa.Enable_Delinquency_Process__c = true;
            aa.Support_Priority_Override__c = 's0';
            aa.Name = 'bhah1';
            aa.DelightedInc__NPS__c = 100;
            update aa;
            
            Test.stopTest();
            
            Account updatedAccount = [SELECT Id, Quarantine_Enabled__c, Enable_Delinquency_Process__c,
                                    Quarantine_Enabled_At__c, Suspension_Grace_Days__c,
                                    Support_Phone_Number__c, Stamp_Delighted_Score_Date_Change__c 
                                    FROM Account WHERE Id =: aa.Id LIMIT 1];
            
            system.assertNotEquals(updatedAccount.Stamp_Delighted_Score_Date_Change__c, null);
            system.assertEquals('(415) 329-6879', updatedAccount.Support_Phone_Number__c);
        }
    }
    //Groundswell - Nilesh Jain : Test Mid MKT workflow and small fleets workflow method
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
            system.assertEquals(tags.Zendesk_Tags__c, 'Account_' + tags.Support_Priority__c + ', ' + tags.BillingCountry); //small fleets workflow
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
            accountOne.Support_Priority_Override__c = 's1';
            update accountOne;
            Account updatedAccount = [SELECT Id, Zendesk_Tags__c, Support_Priority__c, BillingCountry, Support_Phone_Number__c FROM Account WHERE Id =: accountOne.Id LIMIT 1];
            // system.assertEquals(updatedAccount.Support_Phone_Number__c, '(415) 688-4286'); //Mid Mkt workflow
            // system.assertEquals(updatedAccount.Zendesk_Tags__c, 'Account_' + updatedAccount.Support_Priority__c + ', ' + updatedAccount.BillingCountry); //small fleets workflow
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
            // update accountOne;
            Account updatedAccount = [SELECT Id, Support_Phone_Number__c FROM Account WHERE Id =: accountOne.Id LIMIT 1];
            // system.assertEquals(updatedAccount.Support_Phone_Number__c, '(415) 799-3279');
            // system.assertEquals(updatedAccount.Support_Phone_Number__c, System.label.Workflow_SMB);
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

        Contact shippingContact = createContact(a.Id);
        insert shippingContact;

        Opportunity o = createOppty('UPS', 'Revenue Opportunity', a.Id);
        o.Shipping_Contact__c = shippingContact.Id;

        insert o;

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
        
        Test.startTest();
        aa.OwnerId = u.Id;
        update aa;

        Test.stopTest();
    }

    @isTest
    static void ownerChange(){

        List<Account> aList = new List<Account>();

        User u = [SELECT Id, Name, UserRole.Name FROM User WHERE IsActive = true AND ((UserRole.Name LIKE '%ENT%' AND Level__c LIKE '%AE%') OR (UserRole.Name LIKE '%Enterprise%' AND UserRole.Name LIKE '%AE%')) LIMIT 1];
        User u2 = [SELECT Id, Name, UserRole.Name FROM User WHERE Name = 'SFDC Pool'];

        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='United States', BillingState = 'California', Number_of_Vehicles__c = 1, OwnerId = u.Id, Record_Type_Stamp_for_Dupes__c = 'Fleet', Overwrite_Validation_Rule__c = true);
        insert a;

        Account aa = [SELECT Id FROM Account WHERE Id =: a.Id LIMIT 1];

        Test.startTest();
        aa.OwnerId = u2.Id;  
        update aa;
        Test.stopTest();
    }

    @isTest
    static void microFleet(){

        List<Account> aList = new List<Account>();

        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='United States', BillingState = 'California', Number_of_Vehicles__c = 1, Record_Type_Stamp_for_Dupes__c = 'Fleet');
        insert a;

        Contact shippingContact = createContact(a.Id);
        insert shippingContact;

        Opportunity o = createOppty('UPS', 'Revenue Opportunity', a.Id);
        o.Shipping_Contact__c = shippingContact.Id;

        insert o;

        Account aa = [SELECT Id FROM Account WHERE Id =: a.Id LIMIT 1];

        Test.startTest();
        aa.Number_of_Vehicles__c = 50;
        update aa;

        Test.stopTest();
    }

    @isTest
    static void testSAMNumberGeneration(){
        Account acc = new Account ( Name = 'Testing 123', Industry = 'Unknown', Organization_Size__c = '100 - 499',
                                    BillingState = 'California', BillingCountry = 'United States');
        Test.startTest();
        insert acc;
        Test.stopTest();

        Account newAcct = [SELECT Id, SAM_Number_Undecorated__c FROM Account WHERE Id = : acc.Id LIMIT 1];

        system.assert(newAcct.SAM_Number_Undecorated__c <> null);
    }
    
    @isTest
    static void testcopyBillingInfo() {
        test.startTest();
        Map<Id, Account> ownerRoleAccIds = new Map<Id, Account>();
        Account acc = new Account ( Name = 'Testing 123', Industry = 'Unknown', Organization_Size__c = '100 - 499',
                                    BillingState = 'California', BillingCountry = 'United States');
        insert acc;
        Contact con = new Contact (FirstName = 'Test', LastName = 'Contact', Source__c = 'Adwords', AccountId = acc.Id, Email = 'test@test.com', Phone = '123456');
        insert con;
        acc.Billing_Contact__c = con.Id;
        update acc;
        Contact con1 = new Contact (FirstName = 'Test1', LastName = 'Contact1', Source__c = 'Adwords', AccountId = acc.Id, Email = 'test@test.com', Phone = '123456');
        insert con1;
        //test.startTest();
        Account a = [select id, Billing_Contact__c from Account where id = :acc.Id];
        a.Billing_Contact__c = con1.Id;
        update a;
        test.stopTest();
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
    }

    @isTest static void testValidEvent() {
        
        Account newAccount = [SELECT Id FROM Account LIMIT 1];
        Account_Sync_event__e syncEvent = new Account_Sync_event__e(Id__c = newAccount.Id);
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(syncEvent);
        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());
    }
    @isTest
    static void testUpdateADRAssignmentFromBooks() {
        // Create a test User or ADR record
        User testADR = new User(
            FirstName = 'Test',
            LastName = 'ADR',
            Email = 'testadr@test.com',
            Username = 'testadr@test.com' + System.currentTimeMillis(),
            Alias = 'tadr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            EmployeeNumber = 'BHR-001'
        );
        insert testADR;

        // Create Book_Of_Business__c with valid ADR__c (User Id)
        Book_Of_Business__c book = new Book_Of_Business__c(Name = 'Book 1', ADR__c = testADR.Id);
        insert book;
        
        Account acc = [SELECT Id, Books_Of_Business__c FROM Account LIMIT 1];
        Account accUpdated = new Account(Id = acc.Id, Books_Of_Business__c = book.Id);
        Map<Id, Account> oldMap = new Map<Id, Account>{acc.Id => acc};
        List<Account> newList = new List<Account>{accUpdated};
        
        Test.startTest();
        AccountHelper.updateADRAssignmentFromBooks(oldMap, newList);
        Test.stopTest();
        // Verify that the ADRAssignment__c field is updated correctly
        Account updatedAcc = [SELECT ADRAssignment__c FROM Account WHERE Id = :acc.Id];

    }

}