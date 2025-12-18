@isTest(SeeAllData=true)
private class UserTests {
    
    @isTest
    static void UserTests() {
        
        testCallPauseAssignment();
        
        /*List<User> updateuser = new List<user>();
List<LFBN__Round_Robin_Assignment__c> rrinsert = new List<LFBN__Round_Robin_Assignment__c>();
Id rrid;

LFBN__Round_Robin__c rr = new LFBN__Round_Robin__c(Name = 'Testing RR',
LFBN__Active__c = True, 
LFBN__For_Account__c = True, 
LFBN__Rank__c = 1,
LFBN__Owner__c = UserInfo.getUserId());
insert rr;

List<User> users = [SELECT Id, Inbound_ADR_Out_Of_Office__c, IsActive FROM User WHERE (UserRole.Name LIKE 'Fleet ADR IB%' OR UserRole.Name LIKE '%Inbound%')];

List<LFBN__Round_Robin__c> rrtest = [SELECT Id FROM LFBN__Round_Robin__c WHERE Id =: rr.Id];

for(LFBN__Round_Robin__c rriter: rrtest){
rrid = rriter.Id;
}

for(User u: users){
Integer i = 0;
i++;
LFBN__Round_Robin_Assignment__c rrassign = new LFBN__Round_Robin_Assignment__c(LFBN__Active__c = True, 
LFBN__Round_Robin__c = rrid, 
LFBN__User__c = u.Id);
rrinsert.add(rrassign);                                                                               

if(math.mod(i, 2) == 0){
u.Inbound_ADR_Out_Of_Office__c = true;
}
else{
u.Inbound_ADR_Out_Of_Office__c = false;
}

updateuser.add(u);
}
insert rrinsert;
update updateuser;    
*/
    }
    @isTest
    static void createUser(){
        string ProfileId = [SELECT Id FROM Profile WHERE Name LIKE 'Samsara Sales - NA%' LIMIT 1].Id;
        User testManager = new User();
        
        testManager.ProfileId = ProfileId;
        testManager.LastName = 'testManager';
        testManager.Email = 'testManager@samsara.com';
        testManager.Username = 'testmanager@siigroup.com';
        testManager.Alias = 'Mngr';
        testManager.CompanyName = 'Samsara';
        testManager.TimeZoneSidKey='America/New_York';
        testManager.EmailEncodingKey='UTF-8';
        testManager.LanguageLocaleKey='en_US';
        testManager.LocaleSidKey='en_US';
        testManager.EmployeeNumber = '12345';
        
        insert testManager;
    }
    
    @isTest
    static void validatePartnerContactEmail(){
        List<Account> newAccounts = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        newAccounts.add(account);
        insert newAccounts;
        Map<Id, User> myUserMap = new Map<Id, User>([SELECT Id, UserType, IsPortalEnabled, IsActive, Email, FirstName, LastName FROM User 
                                                     WHERE UserType = 'PowerPartner' and ContactId = null Limit 10]);
        if(myUserMap.size()==0) {
            myUserMap = new Map<Id, User>([SELECT Id, UserType, IsPortalEnabled, IsActive, Email, FirstName, LastName FROM User 
                                                     WHERE UserType = 'Standard' and ContactId = null Limit 10]);
        }
        List<Contact> conInsert = New List<Contact>();
        FOR(User userO : myUserMap.values()) {
            Contact toAdd = new Contact();
            toAdd.AccountId = newAccounts[0].Id;
            toAdd.LastName = userO.LastName;
            toAdd.FirstName = userO.FirstName;
            toAdd.Email = userO.Email;
            
            conInsert.add(toAdd);
        }
        insert conInsert;
        UserHelper.validatePartnerContactEmail(myUserMap);
        String newUserListJson = JSON.serialize(myUserMap);
        UserHelper.validatePartnerContactEmail(newUserListJson);
        UserHelper.addPartnerUserToLibraryGroup(myUserMap.values());
    }
    
    @isTest
    static void validatePartnerContactId(){
        List<Account> newAccounts = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        newAccounts.add(account);
        insert newAccounts;
        Map<Id, User> myUserMap = new Map<Id, User>([SELECT Id, UserType, IsPortalEnabled, IsActive, ContactId, Email, FirstName, LastName FROM User 
                                                     WHERE UserType = 'PowerPartner' and ContactId != null Limit 10]);
        List<Contact> conInsert = New List<Contact>();
        FOR(User userO : myUserMap.values()) {
            Contact toAdd = new Contact();
            toAdd.AccountId = newAccounts[0].Id;
            toAdd.LastName = userO.LastName;
            toAdd.FirstName = userO.FirstName;
            toAdd.Email = userO.Email;
            
            conInsert.add(toAdd);
        }
        insert conInsert;
        UserHelper.validatePartnerContactId(myUserMap);
        String newUserListJson = JSON.serialize(myUserMap);
        UserHelper.validatePartnerContactIdFuture(newUserListJson);
        UserHelper.addPartnerUserToLibraryGroup(myUserMap.values());
    }
    
    static void testCallPauseAssignment(){
        //Role - 00E4p000000uE46EAE      
        List<User> updateuser = new List<user>();
        List<RR_Assignment_Mapping__c> rrinsert = new List<RR_Assignment_Mapping__c>();
        Id rrid;
        
        RR_Assignment_Rule__c rr = new RR_Assignment_Rule__c( Active__c=true, Object__c = 'Account',  
                                                             Category__c = 'Lane Four', Rule_Description__c='Test',
                                                             Order__c=1, Type__c='Other');
        insert rr;
        
        List<User> users = [SELECT Id, Inbound_ADR_Out_Of_Office__c, IsActive, UserRoleId FROM User WHERE 
                            (UserRole.Name LIKE '%Fleet ADR IB%' OR UserRole.Name LIKE '%Inbound%')];
        
        List<RR_Assignment_Rule__c> rrtest = [SELECT Id FROM RR_Assignment_Rule__c WHERE Id =: rr.Id];
        
        for(RR_Assignment_Rule__c rriter: rrtest){
            rrid = rriter.Id;
        }
        
        for(User u: users){
            Integer i = 0;
            i++;
            RR_Assignment_Mapping__c rrassign = new RR_Assignment_Mapping__c(Active__c=true, Type__c='Other', Field_To_Assign__c = 'User', Pause_Assignment__c=false, 
                                                                             User__c = u.Id, Assignment_Rule__c = rrid, Order__c=1);
            rrinsert.add(rrassign);                                                                               
            
            if(math.mod(i, 2) == 0){
                u.Inbound_ADR_Out_Of_Office__c = true;
                u.Enable_ADR_Leads__c = false;
            }
            else{
                u.Inbound_ADR_Out_Of_Office__c = false;
                u.Enable_ADR_Leads__c = true;
            }
            
            updateuser.add(u);
        }
        insert rrinsert;
        update updateuser;
    }
    
    @IsTest
    static void addPartnerUserToLibraryGroup_TEST(){
        Test.startTest();
        User objProfileAE3 = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara Sales - NA US AE3' order by Id limit 1];
        User objProfileADR = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara ADRs' order by Id limit 1];
        String partnerId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        User objRoleENT = [select Id, IsActive, UserRole.Name from User where IsActive = true and UserRole.Name like '%Fleet ENT AE NA US%' limit 1];
        Profile pf = [SELECT Id,Name FROM Profile WHERE name = 'Samsara Partner Community Login License Admin'];
        Id roleId = [SELECT Id,Name FROM UserRole WHERE Name = 'Millennium Technologies Partner User'].Id;
        Book_Of_Business__c book2 = new Book_Of_Business__c(Name='Book Two', AE__c=objProfileAE3.Id, ADR__c=objProfileADR.Id, Active__c=true);
        Account account5 = new Account (Name = 'Test Account RODRIGO USA - Partner', Organization_Size__c = '5000+', BillingCountry = 'United States', 
                                        RecordTypeId=partnerId,Partner_Type__c='Insurance', Program_Type__c='Paid Referral;Resale',Books_Of_Business__c = book2.Id,Partner_Description__c = 'Insurance Carrier',
                                        BillingStateCode='TX', Industry = 'Other', OwnerId=objRoleENT.Id, Account_Lifetime_ACV__c=40000, ServicesIntegration_Program_Type__c = 'Installation',
                                        CSM_Initial_onboarding_completed_Time__c = datetime.now());
        insert account5;
        
        Contact con = new Contact();
        con.Firstname = 'Partner';
        con.LastName = 'Test';
        con.Email = 'partnerTest@samsara.com';
        con.AccountId = account5.Id;
        insert con;
        
        String orgId=UserInfo.getOrganizationId(); 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-',''); 
        
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=orgId+RandomId; 
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser){
            User uu=new User(firstname = 'Test AE3 Role', 
                             lastName = 'Test AE3 Role', 
                             email = uniqueName + '@test' + orgId + '.org', 
                             Username = uniqueName + 'AE3@test' + orgId + '.org', 
                             EmailEncodingKey = 'ISO-8859-1', 
                             Alias = string.valueof(RandomId), //uniqueName.substring(18, 23), 
                             TimeZoneSidKey = 'America/Los_Angeles', 
                             LocaleSidKey = 'en_US', 
                             LanguageLocaleKey = 'en_US', 
                             ProfileId = pf.Id, 
                             //UserRoleId = roleId,
                             contactid = con.Id,
                             isActive=true);
            
            insert uu;
            
            Test.StopTest();
            
            List<GroupMember> gmList = [SELECT Id,UserOrGroupId FROM GroupMember WHERE UserOrGroupId =:uu.Id];
            //System.Assert(gmList.size()>0,'Users are not added as group Members');
        }
    }  
    
    
    @isTest
    private static void UserFieldsPushtoWebstoreTest(){
        UserHelper.UserFieldsPushtoWebstore(null,null);
    }
    
    @isTest
    static void ownerNameChange(){
        string ProfileId = [SELECT Id FROM Profile WHERE Name LIKE 'Samsara Sales - NA%' LIMIT 1].Id;
        User testManager = new User();
        
        testManager.ProfileId = ProfileId;
        
        testManager.LastName = 'testManager';
        testManager.Email = 'testManager@samsara.com';
        testManager.Username = 'testmanager@siigroup.com';
        testManager.Alias = 'Mngr';
        testManager.CompanyName = 'Samsara';
        testManager.TimeZoneSidKey='America/New_York';
        testManager.EmailEncodingKey='UTF-8';
        testManager.LanguageLocaleKey='en_US';
        testManager.LocaleSidKey='en_US';
        testManager.EmployeeNumber = '12345';
        testManager.IsActive  = true;
        
        insert testManager;
            
        Account act = new Account(Name = 'Test Account',Current_Owner_Email__c='testgi.uu@gmail.com',Which_Written_Language__c='English',BigCommerce_Id__c='TEST-123456789',CurrencyIsoCode='USD',Segment_Text_Stamped__c='Management',
                                 SAM_Number_Undecorated__c='C6ERU7RTSN',Billing_Email__c='r.r@rrrrrrrrrrrrr.com',Billing_First_Name__c='aaaaaaaa',Billing_Last_Name__c='bbbbbbbbb',
                                  Organization_Size__c='1 - 99',
                                 BillingCountry='United States',BillingState='Alaska',Ownerid=testManager.id);
        Insert act;
        
        List<SetupEntityAccess> setupEntityAccess = [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName = 'Validation_Rule_Exemption') Limit 10];
        Set<Id> newIds = new Set<Id>();
        for(SetupEntityAccess Ids :setupEntityAccess){
            newIds.add(Ids.ParentId);
        }
        List<User> userList = [SELECT Id, Username, FirstName, LastName FROM User WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN : newIds) and IsActive = true and Profile.Name like '%system Admin%' limit 1];
        
        system.runAs(userList[0]){
            try {
            Test.startTest();
            testManager.LastName = 'Pool';
            update testManager;
            Test.stopTest();
        }catch(Exception ex){
            System.debug('User Failing');
        }
        }
    }
    
    @isTest
    static void testUserActivationTerminationDates() {
        // Get a profile for creating test users
        string ProfileId = [SELECT Id FROM Profile WHERE Name LIKE 'Samsara Sales - NA%' LIMIT 1].Id;
        Test.startTest();
        // Create test user - initially inactive
        User testUser = new User();
        testUser.ProfileId = ProfileId;
        testUser.LastName = 'TestUser';
        testUser.Email = 'testuser@samsara.com';
        testUser.Username = 'testuser@siigroup.com';
        testUser.Alias = 'TUser';
        testUser.CompanyName = 'Samsara';
        testUser.TimeZoneSidKey = 'America/New_York';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmployeeNumber = '12346';
        testUser.IsActive = false;
        
        insert testUser;
        
        testUser.IsActive = true;
        update testUser;
        // Verify activation date is set
        User activatedUser = [SELECT Id, IsActive, User_Activation_Date__c, User_Termination_Date__c FROM User WHERE Id = :testUser.Id];
        System.debug('activatedUser: ' + activatedUser);
        System.assertEquals(System.today(), activatedUser.User_Activation_Date__c, 'User activation date should be set to today');        
      
        activatedUser.IsActive = false;
        update activatedUser;
        
        // Verify termination date is set
        User deactivatedUser = [SELECT Id, IsActive, User_Activation_Date__c, User_Termination_Date__c FROM User WHERE Id = :testUser.Id];
        System.assertEquals(System.today(), deactivatedUser.User_Termination_Date__c, 'User termination date should be set to today');

        Test.stopTest();
    }
}