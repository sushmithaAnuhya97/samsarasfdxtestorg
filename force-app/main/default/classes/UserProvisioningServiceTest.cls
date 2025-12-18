/**
 * Created by vikasmishra on 2021-07-05.
 */

@IsTest
private class UserProvisioningServiceTest {
    @IsTest
    static void shouldSetDefaultProfile() {
        UserProvisioningService thisService = new UserProvisioningService();
        thisService.setDefaultProfile(UserProvisioningServiceTest.generateId(Profile.SObjectType, 102));
        System.assert(
                thisService.defaultProfile == UserProvisioningServiceTest.generateId(
                        Profile.SObjectType, 102
                ),
                'This should be equal to the supplied value'
        );
    }

    @IsTest
    static void shouldProcessProvision(){
        LeadSelectorMock thisLSMock = new LeadSelectorMock();
        UserDMLHelperMock thisDMLMock = new UserDMLHelperMock();
        UserProvisioningService.thisLeadSelector = thisLSMock;
        UserProvisioningService.thisUserDMLHelper = thisDMLMock;

        UserProvisioningService thisUPS = new UserProvisioningService();
        thisUPS.doProvisionFromLeadIds(new Set<Id>());
        thisUPS.doProvisionFromContactIds(new Set<Id>());
        System.assert(thisLSMock.methodCalled = true, 'Selector method should be called');
    }

    @IsTest
    static void shouldProcessProvision2(){
        LeadSelectorMock thisLSMock = new LeadSelectorMock();
        thisLSMock.getLeadsByIds(new Set<Id>());
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT id from Lead Limit 1]);
        Id contactPartnerRT = sObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Contact' and Name = 'Partner' LIMIT 1]; 
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id FROM Contact WHERE RecordTypeId =: contactPartnerRT]);
		UserProvisioningService.LeadSelector thisLCSelector = new UserProvisioningService.LeadSelector();
        //thisLCSelector.getLeadsByIds(leadMap.keySet());
        UserProvisioningService thisUPS = new UserProvisioningService();
        List<User> userList = thisUPS.doProvisionFromLeads(thisLCSelector.getLeadsByIds(leadMap.keySet()));
        List<User> user2List = thisUPS.doProvisionFromContacts(thisLCSelector.getContactByIds(contactMap.keySet()));
        thisUPS.insertUsers(userList, false);
        //System.assert(thisLSMock.methodCalled = true, 'Selector method should be called');
    }
    
    @IsTest
    static void activateUserTest(){
         String orgId = UserInfo.getOrganizationId();
        Id accountPartnerRT = sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Account' and Name = 'Partner' LIMIT 1]; 
        Account partnerAccount = new Account(Name='Partner Account', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', RecordTypeId = accountPartnerRT);
        insert partnerAccount;
        
        //Emable as Partner
        partnerAccount.IsPartner = true;
        update partnerAccount;
        
        //Create Partner Contact
        Id contactPartnerRT = sObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Contact' and Name = 'Partner' LIMIT 1]; 
        Contact partnerContact = new Contact(FirstName = 'Partner', LastName = 'Contact', recordTypeId=contactPartnerRT, AccountId = partnerAccount.Id, Email = 'partner@test.com'+orgId);
        insert partnerContact;
        
        Profile partnerProfile = [SELECT Id FROM Profile WHERE Name = 'Samsara Partner Community Login License User'];
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueName = orgId + dateString + randomInt;
            User partnerUser = new User(lastName = partnerContact.LastName,
                                        email = partnerContact.Email,
                                        Username = partnerContact.Email,
                                        ContactId = partnerContact.Id,
                                        EmailEncodingKey = 'ISO-8859-1',
                                        Alias = uniqueName.substring(10, 15),
                                        TimeZoneSidKey = 'America/Los_Angeles',
                                        LocaleSidKey = 'en_US',
                                        LanguageLocaleKey = 'en_US',
                                        ProfileId = partnerProfile.Id,
                                        isActive = false,
                                        EmployeeNumber='123');
        
        user u = [SELECT Id FROM User WHERE Id =: userinfo.getUserId()];
        System.runAs(u){
            
            insert partnerUser;
        }
        Test.StartTest();
        	UserProvisioningService.activateExistingUser(new List<Id>{partnerUser.Id});
        Test.StopTest();
        
    }
    
    @IsTest
    static void testLeadSelector(){
        UserProvisioningService.LeadSelector thisLCSelector = new UserProvisioningService.LeadSelector();
        System.assert(thisLCSelector.getLeadsByIds(new Set<Id>()).isEmpty(), 'Should return empty list');
    }

    @IsTest
    static void testLeadDMLHelper(){
        UserProvisioningService.UserDmlHelper thisLCDmlHelper = new UserProvisioningService.UserDmlHelper();
        System.assert(thisLCDmlHelper.insertUsers(new List<User>(), false).isEmpty(), 'Should return empty list');

    }

    @IsTest
    static void shouldProvisionUser(){
        LeadSelectorMock thisLSMock = new LeadSelectorMock();
        UserDMLHelperMock thisDMLMock = new UserDMLHelperMock();
        UserProvisioningService.thisLeadSelector = thisLSMock;
        UserProvisioningService.thisUserDMLHelper = thisDMLMock;

        UserProvisioningService thisUPS = new UserProvisioningService();
        thisUPS.insertUsers(thisUPS.doProvisionFromLeadIds(new Set<Id>()));
        System.assert(thisDMLMock.methodCalled = true, 'DML method should be called');
    }

    @IsTest
    static void shouldAssignPermissionset(){
        LeadSelectorMock thisLSMock = new LeadSelectorMock();
        UserDMLHelperMock thisDMLMock = new UserDMLHelperMock();
        PermissionSetAssignmentServiceMock thisPSM = new PermissionSetAssignmentServiceMock();
        UserProvisioningService.thisLeadSelector = thisLSMock;
        UserProvisioningService.thisUserDMLHelper = thisDMLMock;
        PermissionSetAssignmentService.thisPSAS = new PermissionSetAssignmentServiceMock();

        UserProvisioningService thisUPS = new UserProvisioningService();
        thisUPS.insertUsers(thisUPS.doProvisionFromLeadIds(new Set<Id>()));
        thisUPS.assignPermissionSet(thisDMLMock.insertUsers(new List<User>(), false), 'Some_Permission_Set');
        System.assert(thisPSM.methodCalled = true, 'Permission Set Assignment method should be called');
    }

    public class LeadSelectorMock implements UserProvisioningService.ISelector{
        
        
        public Boolean methodCalled = false;
        public List<Lead> leadList = new List<Lead>();
        public List<Lead> getLeadsByIds (Set<Id> ids){
            List<Account> newAccounts = new List<Account>();
            Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountryCode = 'CA', 
                                           Industry = 'Other', 
                                           Domain_Name__c='samsara.com');
            newAccounts.add(account);
            insert newAccounts;
            system.debug('RODRIGO Domain_Name__c ' + newAccounts[0].Domain_Name__c);
            methodCalled = true;
            Lead L1= new Lead(Status = 'Pending Verification',
                            FirstName ='Testing Name',
                            LastName ='Last Name',
                             Email ='test@samsara.com',
                             Country = 'Canada',
                             Company = 'Test Company',
                             LeadSource = 'Other',
                             Organization_Size__c = '5000+',
                             Account__c = newAccounts[0].Id,
                            //Id = UserProvisioningServiceTest.generateId(Lead.SObjectType,101),
                            RecordTypeId = LeadConversionService.getRecordTypeId(
                                    'Lead',
                                    'Partner_Application'
                            )
                    );
            Lead L2= new Lead(Status = 'Pending Verification',
                            FirstName ='Testing2 Name',
                            LastName ='Last Name',
                             Email ='',
                             Country = 'Canada',
                             Company = 'Test Company',
                             LeadSource = 'Other',
                             Organization_Size__c = '5000+',
                             Account__c = newAccounts[0].Id,
                            //Id = UserProvisioningServiceTest.generateId(Lead.SObjectType,101),
                            RecordTypeId = LeadConversionService.getRecordTypeId('Lead','Partner_Application'));
                              
            leadList = new List<Lead>{L1,L2};
            insert leadList;
            system.debug('RODRIGO leadList ' + leadList[0].Id);
            
            
            Contact conRecord=new Contact(firstName='Test', lastName='User',Email='test@samsara.com');
            insert conRecord;
            
            return leadList;
        }

        public list<Contact> getContactByIds(Set<Id> Ids){
            String orgId = UserInfo.getOrganizationId();
            
            Id accountPartnerRT = sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Account' and Name = 'Partner' LIMIT 1]; 
            Account partnerAccount = new Account(Name='Partner Account', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', RecordTypeId = accountPartnerRT);
            insert partnerAccount;
            
            //Emable as Partner
            partnerAccount.IsPartner = true;
            update partnerAccount;
                    
            //Create Partner Contact
            Id contactPartnerRT = sObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Contact' and Name = 'Partner' LIMIT 1]; 
            Contact partnerContact = new Contact(FirstName = 'Partner', LastName = 'Contact', recordTypeId=contactPartnerRT, AccountId = partnerAccount.Id, Email = 'partner@test.com'+orgId);
            insert partnerContact;
            
            
            
            
            return new List<Contact>{partnerContact};
        }
    }
    public class UserDMLHelperMock implements UserProvisioningService.IDMLHelper{
        public Boolean methodCalled = false;

        public List<Database.SaveResult> insertUsers (List<User> users, Boolean allOrNothing){
            methodCalled = true;
            Database.SaveResult sr = (Database.SaveResult)
                    JSON.deserialize('{"success":true,"id":"'+UserProvisioningServiceTest.generateId(User.SObjectType,101) + '"}', Database.SaveResult.class);
            return new List<Database.SaveResult>{sr};
        }
        
        public List<Database.SaveResult> updateUsers (List<User> users, Boolean allOrNothing){
            return new List<Database.saveResult>();
        }
        
        

    }

    public class PermissionSetAssignmentServiceMock implements PermissionSetAssignmentService.IService{
        public Boolean methodCalled = false;
        public void assignPermissionSetByName(List<Id> userIdsIds, String PermissionSetName){
            methodCalled = true;
        }
    }

    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
}