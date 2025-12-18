@isTest
public with sharing class BatchAssignADRfromContactTest {
    @testSetup 
    public static void dataSetup() {
        UserRole ur = [Select id,name from Userrole where Name ='Enterprise - UK - AE'];
        User usr = new User(
         ProfileId = [SELECT Id FROM Profile WHERE Name = 'Samsara Sales - NA US AE3'].Id,
         LastName = 'last',
         Email = 'puser000@amamama.com',
         Username = 'puser000@amamama.com' + System.currentTimeMillis(),
         CompanyName = 'TEST',
         Title = 'title',
         Alias = 'alias',
         TimeZoneSidKey = 'America/Los_Angeles',
         EmailEncodingKey = 'UTF-8',
         LanguageLocaleKey = 'en_US',
         LocaleSidKey = 'en_US',
         UserRoleId = ur.Id,
         EmployeeNumber = '12345876'
        );
        insert usr;
        system.runAs(usr) {
            Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other',
                                Customer_ARR__c = 5,
                                Quarantine_Enabled__c = false);
            Account accountTwo = new Account(Name = 'Testers 2 Inc',
                                    BillingCountry = 'United kingdom',
                                    Organization_Size__c = '100 - 499',
                                    Industry = 'Other',
                                    Customer_ARR__c = 5,
                                    Quarantine_Enabled__c = false,
                                    ownerId = usr.Id);
            insert accountOne;
            insert accountTwo;
            Contact contactOne = (Contact)TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
            contactOne.New_Inbound_Lead__c = True;
            contactOne.Most_Recent_Source__c = 'Sites webinar registration form';
            insert contactOne;
            Contact contactTwo = (Contact)TestFactory.createSObject(new Contact(AccountId = accountTwo.Id));
            contactTwo.New_Inbound_Lead__c = True;
            contactTwo.Most_Recent_Source__c = 'Sites webinar registration form';
            insert contactTwo;
            User u = [SELECT Id FROM User WHERE UserRole.Name ='Fleet ADR NA US Team 1 - Manager' LIMIT 1];
            AccountTeamMember atm  = new AccountTeamMember(TeamMemberRole = 'Sites Account Development Representative', AccountId = accountTwo.id, userId = u.id);
            insert atm;
            AccountTeamMember atmTwo  = new AccountTeamMember(TeamMemberRole = 'Sites Account Development Representative', AccountId = accountOne.id, userId = u.id);
            insert atmTwo;
        }
        
    }


    @isTest static void runNonEntr(){
        Test.startTest();
        Database.executeBatch(new BatchAssignADRfromContact());
        Map<Id, Id> UserContactMap = new Map<Id, Id>();
        Map<Id, Id> accIdContactId = new Map<Id, Id>();
        Map<Id, Id> AccountToADRMap = new Map<Id, Id>();
        Map<Id, Integer> mapUserCount = new Map<Id, Integer>();
        List <Account> lstacc = [Select Id,(Select Id, UserId, AccountId from AccountTeamMembers),(Select Id,AccountId from Contacts) from Account];
        For(Account ac: LstAcc){
            for(AccountTeamMember atm : ac.AccountTeamMembers) {
                AccountToADRMap.put(atm.AccountId, atm.UserId);
                mapUserCount.put(atm.UserId, 0);
            }
            for(Contact c : ac.Contacts) {
                accIdContactId.put(c.AccountId, c.Id);
            }
        }
        for(Id accId: AccountToADRMap.keySet()){
            UserContactMap.put(accIdContactId.get(accId),AccountToADRMap.get(accId));
        }
        BatchAssignADRfromContactHelper.InsertADRs(lstacc[0].contacts,mapUserCount,UserContactMap);
        Test.stopTest();
    }
}