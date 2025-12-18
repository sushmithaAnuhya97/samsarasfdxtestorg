@isTest
private class GS_ReferralsTest {


    @TestSetup static void setupRecords(){
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);           
        List<Contact> insertContacts = new List<Contact>();
		List<Account> insertAcct = new List<Account>();

        Account a1 = new Account (Name = 'Testing Acct1', 
                                Organization_Size__c =' 1 - 99', 
                                BillingCountry = 'United States', 
                                Industry = 'Other', 
                                ADR_Transfer__c = false, 
                                BillingState = 'California',
                                SAM_Number_Undecorated__c = 'CJR9XHRRCB',
                                OwnerId = UserInfo.getUserId());
        insertAcct.add(a1);



        Account a2 = new Account (Name = 'Testing Acct2', 
                                Organization_Size__c =' 1 - 99', 
                                BillingCountry = 'United States', 
                                Industry = 'Other', 
                                ADR_Transfer__c = false, 
                                BillingState = 'California',
                                SAM_Number_Undecorated__c = 'CJ89XTVCBP', 
                                OwnerId = UserInfo.getUserId());
        insertAcct.add(a2);
        
        insert insertAcct;

        
        Contact ctc1 = new Contact(FirstName = 'Testing', 
                                  LastName = 'Contact 123',
                                  Description = 'Hello world...', 
                                  Email = 'testing123@email.com', 
                                  Phone = '1234560011',
                                  Status__c = 'Assigned',
                                  AccountId = a1.Id,
                                  OwnerId = UserInfo.getUserId());
        insertContacts.add(ctc1);

        Contact ctc2 = new Contact(FirstName = 'Testing', 
                                  LastName = 'Contact 456',
                                  Description = 'Hello world...', 
                                  Email = 'testing789@email.com', 
                                  Phone = '0987654321',
                                  Status__c = 'Assigned',
                                  AccountId = a2.Id,
                                  OwnerId = UserInfo.getUserId());
        insertContacts.add(ctc2);
        
        insert insertContacts;

    }

     @isTest
    static void referralsTestInsert() {
        Account referredAccount = [SELECT Id FROM Account WHERE Name = : 'Testing Acct2'];

        Account referringAccount = [SELECT Id, SAM_Number_Undecorated__c FROM Account WHERE Name =: 'Testing Acct1'];
        Contact referringCustomer= [SELECT Email FROM Contact WHERE Email = 'testing123@email.com'];
		
        Contact referredCustomer = new Contact(FirstName = 'Testing', 
                                  LastName = 'Contact 456',
                                  Description = 'Hello world...', 
                                  Email = 'testing456@email.com', 
                                  Phone = '0987654321',
                                  Status__c = 'Assigned',
                                  AccountId = referredAccount.Id,
                                  Referring_Customer_Id__c = referringAccount.SAM_Number_Undecorated__c,
                                  Customer_Referral_Email__c = referringCustomer.Email,
                                  OwnerId = UserInfo.getUserId());

        Test.startTest();
        insert referredCustomer;
        Test.stopTest();

        List<Referral__c> newReferral = new List<Referral__c>([ SELECT  Id, 
                                                                        Referring_Customer__c 
                                                                FROM Referral__c 
                                                                WHERE Referring_Customer__c = : referringCustomer.Id
                                                                AND Referring_Customer_Accountv2__c = : referringAccount.Id]);

        System.assertEquals(1, newReferral.size());
    }

    @isTest
    static void referralUpdate() {

        Contact referredCustomer = [SELECT Id, Referring_Customer_Id__c, Phone, New_Inbound_Lead__c FROM Contact WHERE Email = :'testing789@email.com'];
        
        Account referringAccount = [SELECT Id, SAM_Number_Undecorated__c FROM Account WHERE Name =: 'Testing Acct1'];
        Contact referringCustomer = [SELECT Id, Email FROM Contact WHERE Email = :'testing123@email.com'];


        referredCustomer.Customer_Referral_Email__c = referringCustomer.Email;
        referredCustomer.Referring_Customer_Id__c = referringAccount.SAM_Number_Undecorated__c;
        referredCustomer.New_Inbound_Lead__c = true;

        Test.startTest();
        upsert referredCustomer;
        Test.stopTest();

        List<Referral__c> newReferral = new List<Referral__c>([ SELECT  Id, 
                                                                        Referring_Customer__c 
                                                                FROM Referral__c 
                                                                WHERE Referring_Customer__c = : referringCustomer.Id
                                                                AND Referring_Customer_Accountv2__c = : referringAccount.Id]);

        System.assertEquals(1, newReferral.size());
    }

    @isTest
    static void referralUpdateNoEmailMatch() {

        Contact referredCustomer = [SELECT Id, Referring_Customer_Id__c, Customer_Referral_Email__c, New_Inbound_Lead__c FROM Contact WHERE Email = :'testing789@email.com'];
        
        Account referringAccount = [SELECT Id, SAM_Number_Undecorated__c FROM Account WHERE Name =: 'Testing Acct1'];

        referredCustomer.Customer_Referral_Email__c = 'testing909@email.com';
        referredCustomer.Referring_Customer_Id__c = referringAccount.SAM_Number_Undecorated__c;
        referredCustomer.New_Inbound_Lead__c = true;

        Test.startTest();
        update referredCustomer;
        Test.stopTest();

        List<Referral__c> newReferral = new List<Referral__c>([ SELECT  Id, 
                                                                        Referring_Customer__c 
                                                                FROM Referral__c 
                                                                WHERE Referring_Customer_Accountv2__c = : referringAccount.Id]);

        System.assertEquals(1, newReferral.size());
    }
}