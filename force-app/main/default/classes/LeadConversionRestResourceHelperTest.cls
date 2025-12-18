/**
 * Created by vikasmishra on 2021-07-06.
 */

@IsTest
private class LeadConversionRestResourceHelperTest {
    
    
    
    public static Account createAccount(String accountName, string paymentType, string userId, string currencyVal){
        Account testAccount = new Account();
        testAccount.Name = accountName;
        testAccount.Industry = 'Biotechnology';
        testAccount.Organization_Size__c = '500 - 999';
        testAccount.BillingStreet = '123 main';
        testAccount.BillingCity = 'Missoula';
        testAccount.BillingState = 'California';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingPostalCode = '59801';
        testAccount.Billing_Email__c = 'foo@bar.com';
        testAccount.Approved_Payment_Type__c = 'Direct Monthly';
        testAccount.ownerid = userId;
        testAccount.CurrencyIsoCode = currencyVal;
        testAccount.Approved_Payment_Type__c = paymentType;
        return testAccount;
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
    
    @istest
    Public static void partnerTest(){
        String orgId = UserInfo.getOrganizationId();
        string paRT = sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Partner_Application').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Channel Registration' LIMIT 1];
        Lead paLead1 = new Lead (Title = 'Mr', FirstName = 'Test1', LastName = 'Test Client', Is_Deal_Registration__c= false, Email = 'dealreglead@test.com'+orgId,
                                      RecordTypeId = paRT, phone = '+1234567890', Company = 'Test company', Business_unit__c = 'Fleet',
                                      LeadSource = 'Partner Application Form', Country='United States', State='Texas',
                                      Status = 'New');
        insert paLead1;
        Id accountPartnerRT = sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Account' and Name = 'Partner' LIMIT 1]; 
        Account partnerAccount = new Account(Name='Partner Account', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', RecordTypeId = accountPartnerRT);
        insert partnerAccount;
                
        //Create Partner Contact
        Id contactPartnerRT = sObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Contact' and Name = 'Partner' LIMIT 1]; 
        Contact partnerContact = new Contact(FirstName = 'Partner', LastName = 'Contact', AccountId = partnerAccount.Id, Email = 'partner@test.com'+orgId);
        insert partnerContact;
        
        LeadConversionRestResourceHelper thisHelper = new LeadConversionRestResourceHelper();
        String payload = '[ { "leadId":"' +paLead1.Id+
                 +
                '", "status": "success", "accountId":"'+partnerAccount.Id+'","contactId":"'+partnerContact.id+'", "errorMessage":""} ]';

        thisHelper.setPayLoadString(payload)
                .processPayloadForConversion().updateConvertedAccountAsPartner().create_PA_PR_Creation()/*doProcessUserProvisioning('Samsara Partner Community Login License Admin')*/;
        
        thisHelper.doProcessUserProvisioning('Samsara Partner Community Login License Admin');
        LeadConversionRestResourceHelper.invokeUserProvision(new List<List<Id>>{new List<Id>{partnerContact.Id}});
        
    }
    
    @istest
    Public static void channelRegistrationTest(){
        String orgId = UserInfo.getOrganizationId();
        string paRT = sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Channel_Registration').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Channel Registration' LIMIT 1];
        
        Id accountPartnerRT = sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Account' and Name = 'Partner' LIMIT 1]; 
        Account partnerAccount = new Account(Name='Partner Account', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', RecordTypeId = accountPartnerRT);
        insert partnerAccount;
                
        //Create Partner Contact
        Id contactPartnerRT = sObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Contact' and Name = 'Partner' LIMIT 1]; 
        Contact partnerContact = new Contact(FirstName = 'Partner', LastName = 'Contact', AccountId = partnerAccount.Id, Email = 'partner@test.com'+orgId);
        insert partnerContact;
        
        Lead paLead1 = new Lead (LastName = 'Test Client', Is_Deal_Registration__c= true, Email = 'dealreglead@test.com'+orgId,
                                      RecordTypeId = paRT, phone = '+1234567890', Company = 'Test company', Business_unit__c = 'Fleet',
                                      LeadSource = 'Deal Reg Form', Country='United States', State='Texas', ConvertedAccountId = partnerAccount.Id,
                                      IsConverted = true, Status = 'New', Partner_Account_lr__c = partnerAccount.Id,Partner_Contact_lr__c = partnerContact.Id );
        insert paLead1;
        
        RecordType accountChannelRT = [Select Id from RecordType Where SObjectType = 'Account' and DeveloperName = 'Fleet' LIMIT 1]; 
        Account channelAccount = new Account(Name='Channel Account', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', RecordTypeId = accountChannelRT.Id);
        insert channelAccount;
        
        
                
        //Create Partner Contact
        RecordType contactChannelRT = [Select Id from RecordType Where SObjectType = 'Contact' and DeveloperName = 'Fleet' LIMIT 1]; 
        Contact channelContact = new Contact(FirstName = 'Contact', LastName = 'Channel', AccountId = partnerAccount.Id, Email = 'channel@test.com'+orgId, RecordTypeId = contactChannelRT.Id);
        insert channelContact;
        
        LeadConversionRestResourceHelper thisHelper = new LeadConversionRestResourceHelper();
        String payload = '[ { "leadId":"' +paLead1.Id+
                 +
                '", "status": "success", "accountId":"'+channelAccount.Id+'","contactId":"'+channelContact.id+'", "errorMessage":""} ]';
        LeadConversionRestResourceHelper.DealRegistrationService dealRegService = new LeadConversionRestResourceHelper.DealRegistrationService();
		dealRegService.createOppsForDealRegLeads(new List<Lead>{paLead1});
        //thisHelper.setPayLoadString(payload)
                //.processPayloadForConversion().processDealRegistration()/*doProcessUserProvisioning('Samsara Partner Community Login License Admin')*/;
        
        //thisHelper.doProcessUserProvisioning('Samsara Partner Community Login License Admin');
        //LeadConversionRestResourceHelper.invokeUserProvision(new List<List<Id>>{new List<Id>{partnerContact.Id}});
        
    }
    


    @IsTest
    static void shouldProcessJSONString() {
        LeadConversionServiceMock thisLCMock = new LeadConversionServiceMock();
        LeadConversionRestResourceHelper.thisLCService = thisLCMock;

        UserProvisioningServiceMock thisUPSMock = new UserProvisioningServiceMock();
        LeadConversionRestResourceHelper.thisUserProvisioningService = thisUPSMock;

        profileSelectorMock thisPSelectorMock = new profileSelectorMock();
        LeadConversionRestResourceHelper.thisProfileSelector = thisPSelectorMock;

        AccountDMLHelperMock thisAccountDMLHelperMock = new AccountDMLHelperMock();
        LeadConversionRestResourceHelper.accountDMLHelper = thisAccountDMLHelperMock;

        LeadConversionRestResourceHelper thisHelper = new LeadConversionRestResourceHelper();
        String payload = '[ { "leadId":"' +
                LeadConversionRestResourceHelperTest.generateId(Lead.SObjectType, 101) +
                '", "status": "success", "accountId": null ,"contactId":null, "errorMessage":""} ]';

        thisHelper.setPayLoadString(payload)
                .processPayloadForConversion().updateConvertedAccountAsPartner().create_PA_PR_Creation()/*doProcessUserProvisioning('Samsara Partner Community Login License Admin')*/;
        System.assert(thisLCMock.processIncomingLeadsMethodCalled, 'Should process lead');
        System.assert(thisLCMock.setIdToLeadMapMethodCalled, 'Should process lead');
        System.assert(thisLCMock.doConversionMethodCalled, 'Should process lead');
        System.assert(thisLCMock.collectConversionErrorsMethodCalled, 'Should process lead');
        LeadConversionRestResourceHelper lchelper = new LeadConversionRestResourceHelper();
        lchelper.processDealRegistration();

    }

    @IsTest
    static void shouldDOAccountDMLHelperTest() {
        LeadConversionRestResourceHelper.AccountDMLHelper thisAccHelper =
                new LeadConversionRestResourceHelper.AccountDMLHelper();

        System.assert(thisAccHelper.updateObjects(
                new List<Account>(), true).isEmpty(),
                'Should have empty list'
        );
    }

    @IsTest
    static void shouldDOProfileSelectorTest() {
        LeadConversionRestResourceHelper.ProfileSelector thisProfileSelector =
                new LeadConversionRestResourceHelper.ProfileSelector();

        System.assert(
                thisProfileSelector.getProfileByName('test').isEmpty(),
                'Should have empty list'
        );
    }
    @IsTest
    static void checkDupUsername(){
        Profile sysAdmin = [SELECT id, Name FROM Profile where name = 'System Administrator' ].get(0); 
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert r;
                User u = new User(firstname= 'Test',
                          lastname='XXXX',
                          Alias='Test',
                          email = 'Test@admin0001.com',
                          username= 'Test@admin0001.com', 
                          profileId= sysAdmin.id, 
                          emailencodingkey='UTF-8',
                          languagelocalekey='en_US',
                          localesidkey='en_US',
                          timezonesidkey='America/Los_Angeles', EmployeeNumber = '0000');
                insert u;    
       Id p = [select Id from profile where name='Samsara Partner Community Login License Admin'].id;
       Account ac = new Account(name ='testPartnerUser', Organization_Size__c = '1 - 99', BillingState = 'California', BillingCountry = 'United States') ;
       Contact con = new Contact(LastName ='testCon',AccountId = ac.Id);
       
       System.runAs(u){
           insert ac;
           insert con;
           
       }
              
        List<User> userList = new List<User>{new User (alias = 'test003', email='test003@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing003', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, UserRoleId = r.Id, country='United States',IsActive =true,
                ContactId = con.Id, timezonesidkey='America/Los_Angeles', username='test003@noemail.com'),
        new User (alias = 'test004', email='test004@noemail.com',
                        emailencodingkey='UTF-8', lastname='Testing004', languagelocalekey='en_US',
                        localesidkey='en_US', profileid = p, UserRoleId = r.Id, country='United States',IsActive =true,
                        ContactId = con.Id, timezonesidkey='America/Los_Angeles', username='test003@noemail.com')};  
        Test.startTest();
            LeadConversionRestResourceHelper.verifyDupUsername(userList);
        Test.stopTest();
    }
    
    

    public class LeadConversionServiceMock implements LeadConversionService.IService{
        public Boolean setIdToLeadMapMethodCalled = false;
        public Boolean processIncomingLeadsMethodCalled = false;
        public Boolean doConversionMethodCalled = false;
        public Boolean collectConversionErrorsMethodCalled = false;
        public Boolean rollbackChangesMethodCalled = false;
        public Boolean getConvertedLeadMethodCalled = false;

        public LeadConversionService.IService setIdToLeadMap(Map<Id, Lead> idToLeadMap){
            setIdToLeadMapMethodCalled = true;
            return this;
        }
        public LeadConversionService.IService processIncomingLeads (){
            processIncomingLeadsMethodCalled = true;
            return this;
        }
        public LeadConversionService.IService doConversion (){
            doConversionMethodCalled = true;
            return this;
        }
        public LeadConversionService.IService collectConversionErrors(List<Lead> leadsWithError){
            collectConversionErrorsMethodCalled = true;
            return this;
        }
        public void rollbackChanges(List<Lead> leadsWithError){
            rollbackChangesMethodCalled = true;
        }
        public List<Lead> getConvertedLead(){
            getConvertedLeadMethodCalled = true;
            return new List<Lead>();
        }
    }

    public class UserProvisioningServiceMock implements UserProvisioningService.IService{
        public Boolean doProvisionFromLeadIdsMethodCalled = false;
        public Boolean doProvisionFromLeadsMethodCalled = false;
        public Boolean setDefaultProfileMethodCalled = false;
        public Boolean insertUsersMethodCalled = false;
        public Boolean insertUsersMethodCalled1 = false;
        public Boolean assignPermissionSetMethodCalled = false;

        public List<User> doProvisionFromLeadIds(Set<Id> ids){
            doProvisionFromLeadIdsMethodCalled = true;
            return new List<User>();
        }
        
        public List<User> doProvisionFromContactIds(Set<Id> ids){
            doProvisionFromLeadIdsMethodCalled = true;
            return new List<User>();
        }
        
        public List<User> doProvisionFromLeads (List<Lead> leadList){
            doProvisionFromLeadsMethodCalled = true;
            return new List<User>();
        }
        
        public List<User> doProvisionFromContacts (List<Contact> contactList){
            doProvisionFromLeadsMethodCalled = true;
            return new List<User>();
        }
        public void setDefaultProfile(Id thisProfileId){
            setDefaultProfileMethodCalled = true;
        }
        public Database.SaveResult[] insertUsers(List<User> users){
            insertUsersMethodCalled = true;
            return new List<Database.SaveResult>();
        }
        public void assignPermissionSet (Database.SaveResult[] saveResults, String permissionSetName){
            assignPermissionSetMethodCalled = true;
        }
        public Database.SaveResult[] insertUsers(List<User> users, Boolean allOrNone){
            insertUsersMethodCalled = true;
            return new List<Database.SaveResult>();
        }
    }

    public class profileSelectorMock implements LeadConversionRestResourceHelper.ISelector{
       public Boolean methodCalled = false;
        public  List<Profile> getProfileByName(String profileName){
            methodCalled = true;
            return new List<Profile>{
                    new Profile(
                            Id = LeadConversionRestResourceHelperTest.generateId(
                                    Profile.SObjectType,
                                    101),
                            Name = 'Samsara Partner Community Login License Admin'
                    )
            };
        }
    }

    public class AccountDMLHelperMock implements LeadConversionRestResourceHelper.IDMLHelper{
        public Boolean methodCalled = false;
       public  Database.SaveResult[] updateObjects(List<Account> accountList, Boolean allOrNothing){
           methodCalled = true;
           return new List<Database.SaveResult>();
       }
    }

    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
}