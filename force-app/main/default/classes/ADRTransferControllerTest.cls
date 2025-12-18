@isTest(SeeAllData=false) 
private class ADRTransferControllerTest {
    
    @testSetup
    static void setupData() {

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            // Create a role
            UserRole role = new UserRole(Name = 'Fleet ADR OB NA US Test');
            insert role;

            currentUser.UserRoleId = role.Id;
            update currentUser;

            // Create a role
            UserRole role1 = new UserRole(Name = 'MM ADR OB NA US Test');
            insert role1;

            // Pick a profile
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

            // Create a user with that role
            User u = new User(
                FirstName = 'Test', LastName = 'User',
                Email = 'testuser@example.com', Username = 'testuser@example.com.' + System.currentTimeMillis(),
                Alias = 'tuser', TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
                ProfileId = p.Id, UserRoleId = role1.Id, EmployeeNumber = '1234567890'
            );
            insert u;
        }

         List<user> testUsers = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        RR_Assignment_Rule__c testRR = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'NA Connected Sites AE2', SLED__c=true, SLED_Check__c=true,
                                                                  Type__c = 'Other', Object__c='Account', Order__c = 2, Active__c=true, Min_Value__c=0,
                                                                  Max_Value__c = 150000, Next_Assignment__c=testUsers[0].Id, Always_Use_Next_Assignment__c=true,
                                                                  Billing_Country__c='Mexico',Account_Hashtag__c='test', Number_of_Vehicles__c='==0', 
                                                                  Number_of_Powered_Assets__c='> 0',Number_of_Unpowered_Assets__c='>=0',
                                                                  Number_of_Students__c='<=0', Number_of_Citizens__c='< 0', Organization_Size__c='1 - 99');
        
        Insert testRR;
        
        RR_Assignment_Mapping__c testRRA = new RR_Assignment_Mapping__c(Assignment_Rule__c=testRR.Id, User__c=testUsers[0].Id, Order__c = 4, 
                                                                        Active__c=true, Type__c='Other', Value_Total__c=10000, Max_Value__c=2000000);
        Insert testRRA;
        
         Insert  New EMEA_Countries__c(Name ='Names',Named_List_Geo__c ='UK & I, Iberia, France, Benelux, DACH');
        List<Enterprise_Routing_Default__c> erouList = new List<Enterprise_Routing_Default__c>();
        
         Enterprise_Routing_Default__c  e1 = new Enterprise_Routing_Default__c (Name  = 'Madison Williams', Region__c = 'Industrial');
        erouList.add(e1);
        Enterprise_Routing_Default__c  e2 = new Enterprise_Routing_Default__c (Name  = 'Gbaderin Adewole', Region__c = 'EMEA');
        erouList.add(e2);
        Enterprise_Routing_Default__c  e3 = new Enterprise_Routing_Default__c (Name  = 'Catherine Wallace', Region__c = 'North America');
        erouList.add(e3);
        insert erouList;
    }
    
    static testMethod void standardAdrTransfer() {
        User owner = [SELECT Id, Name, Profile.Name, UserRole.Name, IsActive FROM User WHERE IsActive = true AND UserRole.Name LIKE '%MM Fleet IS AE%' AND Profile.Name = 'Samsara Sales - NA US AE2' LIMIT 1];
        // Create account
        Account a = new Account (Name = 'Frank Corp Testing 123', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'Texas',Global_Geography__c = 'Central', OwnerId = owner.id,Original_Owner_for_Recycling_Campaign__c=owner.Id);
        insert a;
        
        AccountTeamMember testATM1 = new AccountTeamMember(AccountId = a.Id, 
                                                           UserId = owner.Id, 
                                                           TeamMemberRole = 'Account Executive',
                                                           AccountAccessLevel = 'Edit',
                                                           OpportunityAccessLevel = 'Edit',
                                                           CaseAccessLevel = 'Read');
        insert testATM1;
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Jack', LastName = 'Masella', email='jack@acme.com',ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId=owner.id);            
        insert cntc;
        
        Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
        insert cmp;
       
        PageReference pageRef = Page.ADR_Transfer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('currentContactID', cntc.Id);
        pageRef.getParameters().put('selectedValue', 'Fleet');
        
        // create the controller
        ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
        
        // set the user from the roundorbin that will receive the adr transfer
        qtyController.transferLog.ADR_Demo_Date__c = Date.today();
        qtyController.setRoundRobinUser();
        //System.assertEquals(firstFieldUserRoundRobin.Id, qtyController.geographicRoundRobin.selected_user.Id);
        // call the submit button method
        PageReference submitted = qtyController.submit();
        //System.assertEquals(submitted.getURL(),'/flow/ADR_Transfer?recordId='+cntc.Id+'&retURL='+cntc.Id);
        
        // if user clicks cancel
        PageReference back = qtyController.backToContact();
        
    }
    static testMethod void enterpriseTransfer() {
        
        Schema.DescribeFieldResult fieldResult = Account.Enterprise_Assignment__c.getDescribe();
        List<Schema.PicklistEntry> enterpriseAssignment = fieldResult.getPicklistValues();
        
        User u = [SELECT Id, Name, UserRole.Name FROM User WHERE Name = : enterpriseAssignment[0].getValue() AND ISACTIVE = TRUE LIMIT 1];
        // Create account
        Account a = new Account (Name = 'Jane Corp', Organization_Size__c ='5000+', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'Texas', Enterprise_Assignment__c = 'Andrew Tate',ownerId = u.Id);
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Jane', LastName = 'Goodall', ADR_Transfer_Status__c = 'Demo Scheduled');            
        insert cntc;
        
        Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
        insert cmp;
        PageReference pageRef = Page.ADR_Transfer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('currentContactID', cntc.Id);
        pageRef.getParameters().put('selectedValue', 'SitesOnly');
        // create the controller
        ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
        
        // set the user from the roundorbin that will receive the adr transfer
        qtyController.transferLog.ADR_Demo_Date__c = Date.today();
        qtyController.setRoundRobinUser();
        //System.assertEquals(secondFieldUserRoundRobin.Id, qtyController.geographicRoundRobin.selected_user.Id);
        // call the submit button method
        if(qtyController.u != null)
            system.runas(qtyController.u){
                PageReference submitted = qtyController.submit();
                //System.assertEquals(submitted.getURL(),'/flow/ADR_Transfer?recordId='+cntc.Id+'&retURL='+cntc.Id);
                
                // if user clicks cancel
                PageReference back = qtyController.backToContact();
            }
       
    }
    static testMethod void enterpriseEMEADefaultTransfer() {
        // Create account
        Account a = new Account (Name = 'James Corp Testing 456', Organization_Size__c ='5000+', BillingCountry = 'United Kingdom', Industry = 'Other', ADR_Transfer__c = false, Enterprise_Assignment__c = 'ENT Pool');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'James', LastName = 'Dean', ADR_Transfer_Status__c = 'Demo Scheduled');            
        insert cntc;
        
        Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
        insert cmp;      
        
        PageReference pageRef = Page.ADR_Transfer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('currentContactID', cntc.Id);
        
        // create the controller
        ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
        
        // set the user from the roundorbin that will receive the adr transfer
        qtyController.transferLog.ADR_Demo_Date__c = Date.today();
        qtyController.setRoundRobinUser();
        System.Debug(LoggingLevel.INFO, 'User Detail EMEA: '+qtyController.u);
        //System.assertEquals(secondFieldUserRoundRobin.Id, qtyController.geographicRoundRobin.selected_user.Id);
        // call the submit button method
        PageReference submitted = qtyController.submit();
        //System.assertEquals(submitted.getURL(),'/flow/ADR_Transfer?recordId='+cntc.Id+'&retURL='+cntc.Id);
        
        // if user clicks cancel
        PageReference back = qtyController.backToContact();
        System.assertEquals(back.getUrl(),'/'+cntc.id);        
        
    }

    static testMethod void testMMADRRequiredFields() {

        User ADRTestUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];

        System.runAs(ADRTestUser) {
            // Create account
        Account a = new Account (Name = 'Santana Corp', Organization_Size__c ='5000+', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'Texas', Enterprise_Assignment__c = 'ENT Pool');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Carlos', LastName = 'Santana', ADR_Transfer_Status__c = 'Demo Scheduled');            
        insert cntc;
        
        Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
        insert cmp;
     
        PageReference pageRef = Page.ADR_Transfer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('currentContactID', cntc.Id);
        // create the controller
        ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
        
        // set the user from the roundorbin that will receive the adr transfer
        qtyController.setRoundRobinUser();
        System.Debug(LoggingLevel.INFO, 'User Detail NA: '+qtyController.u);
        //System.assertEquals(secondFieldUserRoundRobin.Id, qtyController.geographicRoundRobin.selected_user.Id);
        // call the submit button method
        PageReference submitted = qtyController.submit();
        //System.assertEquals(submitted.getURL(),'/flow/ADR_Transfer?recordId='+cntc.Id+'&retURL='+cntc.Id);
        }
       
    }

    static testMethod void enterpriseNADefaultTransfer() {
        // Create account
        Account a = new Account (Name = 'Santana Corp', Organization_Size__c ='5000+', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'Texas', Enterprise_Assignment__c = 'ENT Pool');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Carlos', LastName = 'Santana', ADR_Transfer_Status__c = 'Demo Scheduled');            
        insert cntc;
        
        Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
        insert cmp;
     
        PageReference pageRef = Page.ADR_Transfer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('currentContactID', cntc.Id);
        // create the controller
        ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
        
        // set the user from the roundorbin that will receive the adr transfer
        qtyController.setRoundRobinUser();
        System.Debug(LoggingLevel.INFO, 'User Detail NA: '+qtyController.u);
        //System.assertEquals(secondFieldUserRoundRobin.Id, qtyController.geographicRoundRobin.selected_user.Id);
        // call the submit button method
        PageReference submitted = qtyController.submit();
        //System.assertEquals(submitted.getURL(),'/flow/ADR_Transfer?recordId='+cntc.Id+'&retURL='+cntc.Id);
        
        // if user clicks cancel
        PageReference back = qtyController.backToContact();
        System.assertEquals(back.getUrl(),'/'+cntc.id);
       
    }
   static testMethod void recycleCampaign() {
       // Select an appropriate test user who can bypass the validation rule
    User u = [SELECT Id, Name FROM User WHERE Role_Start_Date__c < YESTERDAY LIMIT 1];
    User uADR = [SELECT Id, Name FROM User WHERE Isactive = TRUE and (UserRole.Name LIKE 'Fleet ADR OB%' OR (UserRole.Name LIKE '%ADR%')) LIMIT 1];
    
    // Create an account and ensure it can bypass the validation rule by setting the necessary fields
    Account a = new Account(
        Name = 'Winston Corp',
        Organization_Size__c = '5000+',
        BillingCountry = 'United States',
        Industry = 'Other',
        ADR_Transfer__c = false,
        BillingState = 'Texas',
        OwnerId = uADR.Id,
        Original_Owner_for_Recycling_Campaign__c = u.Id,
        Overwrite_Validation_Rule__c = true  // Set to bypass the validation rule
    );
    insert a;

    // Create a contact associated with the account
    Contact cntc = new Contact(
        AccountId = a.Id,
        FirstName = 'Winston',
        LastName = 'Churchill',
        ADR_Transfer_Status__c = 'Demo Scheduled'
    );
    insert cntc;

    // Create a campaign
    Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status = 'In Progress', StartDate = System.Date.today());
    insert cmp;

    // Start the test
    Test.StartTest();
    
    // Run as the ADR user to simulate the scenario
    system.runas(uADR) {
        // Setup page reference and parameters
        PageReference pageRef = Page.ADR_Transfer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('currentContactID', cntc.Id);
        pageRef.getParameters().put('selectedValue', 'Fleet');

        // Create the controller
        ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));

        // Set the transfer log demo date and simulate round-robin user selection
        qtyController.setRoundRobinUser();
        
        System.Debug(LoggingLevel.INFO, 'User Detail recycle: ' + qtyController.u);

        // Submit the form
        PageReference submitted = qtyController.submit();

        // Assert the result of the submission
        //System.assertNotEquals(null, submitted, 'Submit should not return null');
        
        // Test cancellation
        PageReference back = qtyController.backToContact();
        System.assertEquals('/' + cntc.Id, back.getUrl(), 'Back to contact URL should be correct');
    }

    Test.StopTest();

    }
    static testmethod void testError(){
        try{
            /*
for (User user : [select Geography__c from user where Geography__c = 'Central']) {
user.Geography__c = 'Southeast';
update user;
} */
            
            User owner = [SELECT Id FROM User WHERE Name LIKE '%Jasvir%' LIMIT 1];
            
            Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, OwnerId = owner.Id, BillingState = 'Texas');
            insert a;
            
            Contact cntc2 = new Contact(AccountId = a.Id, FirstName = 'Artu', LastName = 'Ditu', email='artu@acme.com', ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId = owner.Id);            
            insert cntc2; 
            
            // create the controller
            ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc2));
            
            // set the user from the roundorbin that will receive the adr transfer
            PageReference pageRef = Page.ADR_Transfer;
            Test.setCurrentPage(pageRef);
            qtyController.setRoundRobinUser();
            
            // call the submit button method
            PageReference submitted = qtyController.submit();
            System.assertEquals(submitted.getURL(),'/flow/ADR_Transfer?recordId='+cntc2.Id+'&retURL='+cntc2.Id);
        } catch(Exception ex){
            
        } 
    }
    static testMethod void ADRTransfertoAccOwner() {
        // User testUser = [SELECT Id FROM User WHERE Name = 'Parsan Zar' LIMIT 1];
        User owner = [SELECT Id,Profile.Name,UserRole.name FROM User WHERE profile.Name ='Samsara ADRs' and UserRole.Name LIKE 'Fleet ADR OB%' and isActive = true LIMIT 1];
        System.runAs(owner) {
            // Create account
            Book_Of_Business__c bbs=new Book_Of_Business__c();
            bbs.AE__c=owner.Id;
            insert bbs;
            Account a = new Account (Name = 'Frank Corp Testing 123', Books_Of_Business__c=bbs.Id,Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',OwnerId = owner.id);
            insert a;
            
            // Create a contact
            Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Jack', LastName = 'Masella', email='jack@acme.com',ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId=owner.id);            
            insert cntc;
            
            Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
            insert cmp;    
            
            PageReference pageRef = Page.ADR_Transfer;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('currentContactID', cntc.Id);
            pageRef.getParameters().put('selectedValue', 'Fleet');
            
            // create the controller
            ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
            
            // set the user from the roundorbin that will receive the adr transfer
            qtyController.transferLog.ADR_Demo_Date__c = Date.today();
            qtyController.setRoundRobinUser();
            //System.assertEquals(firstFieldUserRoundRobin.Id, qtyController.geographicRoundRobin.selected_user.Id);
            // call the submit button method
            PageReference submitted = qtyController.submit();
            //System.assertEquals(submitted.getURL(),'/flow/ADR_Transfer?recordId='+cntc.Id+'&retURL='+cntc.Id);
            
            // if user clicks cancel
            PageReference back = qtyController.backToContact();
            //System.assertEquals(back.getUrl(),'/'+cntc.id);
            
        }
    }
    
    static testMethod void Sitesonlyselection() {
        // User testUser = [SELECT Id FROM User WHERE Name = 'Parsan Zar' LIMIT 1];        
        User owner = [SELECT Id, Name, Profile.Name, UserRole.Name, IsActive FROM User WHERE IsActive = true AND UserRole.Name LIKE '%MM Fleet IS AE%' AND Profile.Name = 'Samsara Sales - NA US AE2' LIMIT 1];
        System.runAs(owner) {
            // Create account
            Account a = new Account (Name = 'Frank Corp Testing 123', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',OwnerId = owner.id);
            insert a;
            
            // Create a contact
            Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Jack', LastName = 'Masella', email='jack@acme.com',ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId=owner.id);            
            insert cntc;
            
            Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
            insert cmp;    
           
            
            PageReference pageRef = Page.ADR_Transfer;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('currentContactID', cntc.Id);
            pageRef.getParameters().put('selectedValue', 'SitesOnly');
            
            // create the controller
            ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
            
            // set the user from the roundorbin that will receive the adr transfer
            qtyController.transferLog.ADR_Demo_Date__c = Date.today();
            qtyController.setRoundRobinUser();
            system.runas(owner){
                //System.assertEquals(firstFieldUserRoundRobin.Id, qtyController.geographicRoundRobin.selected_user.Id);
                // call the submit button method
                PageReference submitted = qtyController.submit();
                //System.assertEquals(submitted.getURL(),'/flow/ADR_Transfer?recordId='+cntc.Id+'&retURL='+cntc.Id);
                
                // if user clicks cancel
                PageReference back = qtyController.backToContact();
                //System.assertEquals(back.getUrl(),'/'+cntc.id);
               
            }
        }
    }
    static testMethod void Sitedefault() {
        // Get a system admin user to assign the permission set
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        // Get the test user
        User owner = [SELECT Id,Profile.Name,UserRole.name FROM User WHERE UserRole.name like '%ADR%' and IsActive =true LIMIT 1];
        
        // Use System.runAs() to assign the permission set in a separate transaction
        System.runAs(adminUser) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Account_Owner_Overwrite' LIMIT 1];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = owner.Id,
                PermissionSetId = ps.Id
            );
            insert psa;
        }
        
        // Now run the actual test as the owner user
        System.runAs(owner) {
            // Create account
            Account a = new Account (Name = 'Frank Corp Testing 123', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',OwnerId = owner.id);
            insert a;
            
            // Create a contact
            Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Jack', LastName = 'Masella', email='jack@acme.com',ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId=owner.id);            
            insert cntc;
            
            Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
            insert cmp;
                  
            PageReference pageRef = Page.ADR_Transfer;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('currentContactID', cntc.Id);
            pageRef.getParameters().put('selectedValue', 'SitesOnly');
            
            // create the controller
            ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
            
            // set the user from the roundorbin that will receive the adr transfer
            qtyController.transferLog.ADR_Demo_Date__c = Date.today();
            qtyController.setRoundRobinUser();
            //System.assertEquals(firstFieldUserRoundRobin.Id, qtyController.geographicRoundRobin.selected_user.Id);
            // call the submit button method
            PageReference submitted = qtyController.submit();
            //System.assertEquals(submitted.getURL(),'/flow/ADR_Transfer?recordId='+cntc.Id+'&retURL='+cntc.Id);
            
            // if user clicks cancel
            PageReference back = qtyController.backToContact();
            //System.assertEquals(back.getUrl(),'/'+cntc.id);
        }
    }
    static testMethod void Sitesspecialst() {
        // Get a system admin user to assign the permission set
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        // Get the test user
        User owner = [SELECT Id,Profile.Name,UserRole.name FROM User WHERE UserRole.name like '%ADR%' and IsActive =true LIMIT 1];
        
        // Use System.runAs() to assign the permission set in a separate transaction
        System.runAs(adminUser) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Account_Owner_Overwrite' LIMIT 1];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = owner.Id,
                PermissionSetId = ps.Id
            );
            insert psa;
        }
        
        // Now run the actual test as the owner user
        System.runAs(owner) {
            // Create account
            Account a = new Account (Name = 'Frank Corp Testing 123', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',OwnerId = owner.id,Sites_Specialist__c = '0054p000003n9iwAAA');
            insert a;
            
            // Create a contact
            Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Jack', LastName = 'Masella', email='jack@acme.com',ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId=owner.id);            
            insert cntc;
            
            Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
            insert cmp;
            
            PageReference pageRef = Page.ADR_Transfer;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('currentContactID', cntc.Id);
            pageRef.getParameters().put('selectedValue', 'SitesOnly');
            
            // create the controller
            ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
            
            // set the user from the roundorbin that will receive the adr transfer
            qtyController.transferLog.ADR_Demo_Date__c = Date.today();
            qtyController.setRoundRobinUser();
            //System.assertEquals(firstFieldUserRoundRobin.Id, qtyController.geographicRoundRobin.selected_user.Id);
            // call the submit button method
            PageReference submitted = qtyController.submit();
            //System.assertEquals(submitted.getURL(),'/flow/ADR_Transfer?recordId='+cntc.Id+'&retURL='+cntc.Id);
            
            // if user clicks cancel
            PageReference back = qtyController.backToContact();
            //System.assertEquals(back.getUrl(),'/'+cntc.id);
        }
    }
    static testMethod void enterpriseIndustrialTransfer() {
        Id industrialRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Industrial').getRecordTypeId();
        // Create account
        Account a = new Account (Name = 'Betty Corp', Organization_Size__c ='5000+', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'Texas', RecordTypeId = industrialRecordType,Enterprise_Assignment__c = 'ENT Pool',Territory__c= 'Manufacturing - Patch C');
        insert a;
        String terr = a.Territory__c;
        ADRTransferController.getRegionAssignment(terr);
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Betty', LastName = 'White', ADR_Transfer_Status__c = 'Demo Scheduled');            
        insert cntc;
        
        Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
        insert cmp;
      
        PageReference pageRef = Page.ADR_Transfer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('currentContactID', cntc.Id);
        pageRef.getParameters().put('selectedValue', 'Fleet');
        
        // create the controller
        ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
        
        // set the user from the roundorbin that will receive the adr transfer
        qtyController.setRoundRobinUser();
        System.Debug(LoggingLevel.INFO, 'User Detail industrial: '+qtyController.u);
        //System.assertEquals(secondFieldUserRoundRobin.Id, qtyController.geographicRoundRobin.selected_user.Id);
        // call the submit button method
        system.runas(qtyController.u){
            PageReference submitted = qtyController.submit();
            //System.assertEquals(submitted.getURL(),'/flow/ADR_Transfer?recordId='+cntc.Id+'&retURL='+cntc.Id);
            
            // if user clicks cancel
            PageReference back = qtyController.backToContact();
            System.assertEquals(back.getUrl(),'/'+cntc.id);
        }
       
    }
    static testMethod void SitesonlyselectionTest3() {
        User u;
        //User owner = [SELECT Id,Profile.Name,UserRole.name FROM User WHERE Name LIKE '%Delwin Lam%' LIMIT 1];
        User owner = [SELECT Id, Name, Profile.Name, UserRole.Name, IsActive FROM User WHERE IsActive = true AND UserRole.Name LIKE '%MM Fleet IS AE%' AND Profile.Name = 'Samsara Sales - NA US AE2' LIMIT 1];
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Samsara SE Connected Worker' LIMIT 1];
        UserRole ur =[SELECT Id from UserRole WHERE name Like 'Sites IS AE2%' LIMIT 1];
        User currUser = [SELECT Id from User WHERE ID =: UserInfo.getUserID()];
        
        system.runas(currUser){
            u = new User(
                ProfileId = p.Id,
                Alias = 'testu',
                Email = 'test@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'IS Pool',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey='America/Los_Angeles',
                UserName='test1'+ Math.random()*100 +'@unitingambition.com',
                UserRoleId = ur.Id,
                EmployeeNumber = '122223'
            );
            INSERT u;
            
            // Create account
            Account a = new Account (Name = 'Frank Corp Testing 123', Organization_Size__c ='1000 - 4999',Inside_Sales_Assignment__c='IS Pool', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',OwnerId = owner.id,Sites_Specialist__c =u.Id);
            insert a;
            // Create a contact
            Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Jack', LastName = 'Masella', email='jack@acme.com',ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId=owner.id);            
            insert cntc;
            
            Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
            insert cmp;
         
            // User testUser = [SELECT Id FROM User WHERE Name = 'Parsan Zar' LIMIT 1];
            PageReference pageRef = Page.ADR_Transfer;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('currentContactID', cntc.Id);
            pageRef.getParameters().put('selectedValue', 'SitesOnly');
            
            // create the controller
            ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
            
            // set the user from the roundorbin that will receive the adr transfer
            qtyController.transferLog.ADR_Demo_Date__c = Date.today();
            qtyController.setRoundRobinUser();
            //System.assertEquals(firstFieldUserRoundRobin.Id, qtyController.geographicRoundRobin.selected_user.Id);
            // call the submit button method
            PageReference submitted = qtyController.submit();
             // if user clicks cancel
            PageReference back = qtyController.backToContact();
            //System.assertEquals(back.getUrl(),'/'+cntc.id);
        }
    }
    
  static testMethod void SitesonlyselectionTest2() {
        User u;
        //User owner = [SELECT Id,Profile.Name,UserRole.name FROM User WHERE Name LIKE '%Delwin Lam%' LIMIT 1];
        User owner = [SELECT Id, Name, Profile.Name, UserRole.Name, IsActive FROM User WHERE IsActive = true AND UserRole.Name LIKE '%MM Fleet IS AE%' AND Profile.Name = 'Samsara Sales - NA US AE2' LIMIT 1];
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Samsara SE Connected Worker' LIMIT 1];
        UserRole ur =[SELECT Id from UserRole WHERE name Like 'Sites IS AE2%' LIMIT 1];
        User currUser = [SELECT Id from User WHERE ID =: UserInfo.getUserID()];
        
        system.runas(currUser){
            u = new User(
                ProfileId = p.Id,
                Alias = 'testu',
                Email = 'test@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'ENT Pool',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey='America/Los_Angeles',
                UserName='test'+ Math.random()*100 +'@unitingambition.com',
                UserRoleId = ur.Id,
                EmployeeNumber = '122222'
            );
            INSERT u;
            // Create account
            Account a = new Account (Name = 'Frank Corp Testing 123',Enterprise_Assignment__c ='ENT Pool', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',OwnerId = owner.id,Sites_Specialist__c =u.Id);
            insert a;
            // Create a contact
            Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Jack', LastName = 'Masella', email='jack@acme.com',ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId=owner.id);            
            insert cntc;
            
            Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
            insert cmp;
           PageReference pageRef = Page.ADR_Transfer;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('currentContactID', cntc.Id);
            pageRef.getParameters().put('selectedValue', 'SitesOnly');
            
            // create the controller
            ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
            
            // set the user from the roundorbin that will receive the adr transfer
            qtyController.transferLog.ADR_Demo_Date__c = Date.today();
            qtyController.setRoundRobinUser();
             PageReference submitted = qtyController.submit();
             PageReference back = qtyController.backToContact();
           
        }
    }
    static testMethod void testIndustrialRecordTypeCondition() {
    // Fetch the Industrial RecordTypeId for Account
    RecordType industrialRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Industrial' LIMIT 1];
    // Create a user for the test
    User testUser = [SELECT Id FROM User WHERE UserRole.Name LIKE '%Sales%' LIMIT 1]; // Ensure this user can bypass any validation rule if needed

    // Set up a test account with the Industrial RecordType and other necessary fields
    Account industrialAccount = new Account(
        Name = 'Industrial Test Account',
        Organization_Size__c = '5000+',
        BillingCountry = 'United States',
        Industry = 'Manufacturing',
        RecordTypeId = industrialRecordType.Id, BillingState = 'Texas',
        OwnerId = testUser.Id
       
    );
    insert industrialAccount;
    // Create a contact related to the industrial account
    Contact industrialContact = new Contact(
        AccountId = industrialAccount.Id,
        FirstName = 'Test',
        LastName = 'Contact',
        ADR_Transfer_Status__c = 'Demo Scheduled',
        OwnerId = testUser.Id
    );
    insert industrialContact;

        Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
        insert cmp;
       
    // Set up the page reference for the ADR Transfer process
    PageReference pageRef = Page.ADR_Transfer;
    Test.setCurrentPage(pageRef);
    pageRef.getParameters().put('currentContactID', industrialContact.Id);
    pageRef.getParameters().put('selectedValue', 'Fleet');

    // Create the controller and execute the logic
    Test.startTest();
   // System.runAs(testUser) {
        ADRTransferController controller = new ADRTransferController(new ApexPages.StandardController(industrialContact));
      controller.enterprise = false;
 controller.setRoundRobinUser();

    //}
    Test.stopTest();
}
     static testMethod void ADRTransfertoAccOwnerSiteOnly() {
       
        User owner = [SELECT Id,Profile.Name,UserRole.name FROM User WHERE profile.Name ='Samsara ADRs' and isActive = true LIMIT 1];
        System.runAs(owner) {
            // Create account
            Book_Of_Business__c bbs=new Book_Of_Business__c();
            bbs.AE__c=owner.Id;
            insert bbs;
            Account a = new Account (Name = 'Frank Corp Testing 123',Books_Of_Business__c=bbs.Id,Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',OwnerId = owner.id);
            insert a;
            
            // Create a contact
            Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Jack', LastName = 'Masella', email='jack@acme.com',ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId=owner.id);            
            insert cntc;
            
            Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
            insert cmp;    
            
            PageReference pageRef = Page.ADR_Transfer;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('currentContactID', cntc.Id);
            pageRef.getParameters().put('selectedValue', 'SitesOnly');
            ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
            qtyController.transferLog.ADR_Demo_Date__c = Date.today();
            qtyController.setRoundRobinUser();
            PageReference submitted = qtyController.submit();
             PageReference back = qtyController.backToContact();
           
        }
    }
     static testMethod void ADRTransfertoAccOwnerSiteOnly1() {
        
        User owner = [SELECT Id,Profile.Name,UserRole.name FROM User WHERE profile.Name ='Samsara ADRs' and isActive = true LIMIT 1];
        if (owner == null) {
        return;
    }
         System.runAs(owner) {
           Account a = new Account (Name = 'Frank Corp Testing 123', Inside_Sales_Assignment__c='Evan Richards',Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',OwnerId = owner.id);
            insert a;
           Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Jack', LastName = 'Masella', email='jack@acme.com',ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId=owner.id);            
            insert cntc;
            
            Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
            insert cmp;    
            
           PageReference pageRef = Page.ADR_Transfer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('currentContactID', cntc.Id);
        pageRef.getParameters().put('selectedValue', 'SitesOnly');
        
        // Create the controller
        ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
        
        // Ensure transfer log is populated
        qtyController.setRoundRobinUser();
        
         PageReference submitted = qtyController.submit();
         PageReference back = qtyController.backToContact();
       
    }
     }
   
     static testMethod void enterpriseIndustrialTransfer1() {
        User owner = [SELECT Id,Profile.Name,UserRole.name,Region__c FROM User WHERE Region__c='EMEA' and isActive = true LIMIT 1];
       Account a = new Account (Name = 'Betty Corp Test',ownerId=owner.Id,Global_Geography__c='Test Global', Organization_Size__c ='5000+', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'Texas');
        insert a;
        String terr = a.Territory__c;
        ADRTransferController.getRegionAssignment(terr);
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Betty', LastName = 'White', ADR_Transfer_Status__c = 'Demo Scheduled');            
        insert cntc;
        
        Campaign cmp = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
        insert cmp;
      
        PageReference pageRef = Page.ADR_Transfer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('currentContactID', cntc.Id);
        pageRef.getParameters().put('selectedValue', 'Fleet');
        ADRTransferController qtyController = new ADRTransferController(new ApexPages.StandardController(cntc));
         qtyController.setRoundRobinUser();
        PageReference submitted = qtyController.submit();
            PageReference back = qtyController.backToContact();
            System.assertEquals(back.getUrl(),'/'+cntc.id);
       
    }
    
    @isTest 
    static void testADRIBAndCMLUserRoleLogic() {

        RecordType acctfleetRecordType = [SELECT Id, Name, SobjectType FROM RecordType WHERE Name = 'Fleet' AND SobjectType = 'Account'];
        RecordType contfleetRecordType = [SELECT Id, Name, SobjectType FROM RecordType WHERE Name = 'Fleet' AND SobjectType = 'Contact'];

        User cmlUser = [SELECT Id, Name, FirstName, LastName, Profile.Name, UserRole.Name FROM User WHERE UserRole.Name LIKE 'CML %' AND UserRole.Name LIKE '% US %' AND isActive = true LIMIT 1];
        User adrIbUser = [SELECT Id, Name, FirstName, LastName, Profile.Name, UserRole.Name FROM User WHERE UserRole.Name LIKE '%ADR IB%' AND UserRole.Name LIKE '% US %' AND isActive = true LIMIT 1];
        
        // Create account with CML user as owner
        Account testAccount = new Account(
            Name = 'CML Test Account',
            Organization_Size__c = '1000 - 4999',
            BillingCountry = 'United States',
            Industry = 'Other',
            BillingState = 'California',
            OwnerId = CmlUser.Id,
            RecordTypeId = acctfleetRecordType.Id
        );
        insert testAccount;
        Account AccountRec = [SELECT Id, Name, OwnerId, Owner.Profile.Name, Owner.UserRole.Name FROM Account WHERE Id = :testAccount.Id];
        
        // Create contact with ADR IB user as owner
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@test.com',
            OwnerId = AdrIbUser.Id,
            RecordTypeId = contfleetRecordType.Id
        );
        insert testContact;
        testContact.AccountId = testAccount.Id;
        update testContact;
        
        Contact contactRec = [SELECT Id, Name, OwnerId, Owner.Profile.Name, Owner.UserRole.Name FROM Contact WHERE Id = :testContact.Id];
        
        // Create campaign
        Campaign testCampaign = new Campaign(
            Name = 'Test Campaign (Child) ADR',
            Status = 'In Progress',
            StartDate = System.Date.today()
        );
        insert testCampaign;
        
        // Set up page reference
        PageReference pageRef = Page.ADR_Transfer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('currentContactID', testContact.Id);
        pageRef.getParameters().put('selectedValue', 'Fleet');
        
        // Create the controller and test the logic
        ADRTransferController controller = new ADRTransferController(new ApexPages.StandardController(testContact));
        
        // Call setRoundRobinUser to trigger the logic
        controller.setRoundRobinUser();
        
        // Verify that the ADR IB + CML logic worked correctly
        System.assertEquals(CmlUser.Id, controller.transferOwner, 'Transfer owner should be set to the CML account owner');
        System.assertEquals(CmlUser.FirstName + ' ' + CmlUser.LastName, controller.transferOwnerName, 'Transfer owner name should match the CML account owner name');
        
        // Test the submit functionality
        controller.transferLog.ADR_Demo_Date__c = Date.today();
        PageReference result = controller.submit();
        System.assertNotEquals(null, result, 'Submit should return a page reference');
        
        // Test back to contact
        PageReference backResult = controller.backToContact();
        System.assertEquals('/' + testContact.Id, backResult.getUrl(), 'Back to contact should return correct URL');

        // Insert ADR Transfer Log.
        ADR_Transfer_Log__C transferLog = new ADR_Transfer_Log__C();
        transferLog.ADR_Transfer_Date__c = System.now();
        transferLog.ADR_Transfer_By__c = UserInfo.getUserId();
        transferLog.Account__c = testAccount.Id;
        transferLog.Contact__c = testContact.Id;
        transferLog.ADR_Transfer_Status__c = 'Demo Scheduled';
        transferLog.ADR_Notes__c = 'Test Notes 1';
        transferLog.Samsara_Product_Interest__c = 'Fleet';
        transferLog.ADR_Transfer_Date__c = System.today().addDays(-1);
        transferLog.ADR_Transfer__C = false;
        insert transferLog;

        ADRTransferController controllerNew = new ADRTransferController(new ApexPages.StandardController(testContact));
    }

    @isTest 
    static void testBooksOfBusinessValidAEStatusLogic() {
        // Get user with specific profile for testing
        User accountBookADRUser = [SELECT Id, Name, Profile.Name, UserRole.Name FROM User 
                                WHERE Profile.Name = 'Samsara Account Book ADRs' AND IsActive = true LIMIT 1];
        
        // Create AE user for the Book of Business
        User aeUser = [SELECT Id, Name FROM User 
                    WHERE Profile.Name LIKE '%AE%' AND IsActive = true LIMIT 1];
        
        // Create Book of Business with valid AE status ('Primary: In seat')
        Book_Of_Business__c bookOfBusiness = new Book_Of_Business__c(
            Name = 'Test Book of Business',
            AE__c = aeUser.Id,
            Account_Book_Status__c = 'Primary: In seat',
            Active__c = true
        );
        insert bookOfBusiness;
        
        // Create Account with the Book of Business
        Account testAccount = new Account(
            Name = 'Test Account for Books of Business',
            Books_Of_Business__c = bookOfBusiness.Id,
            Organization_Size__c = '1000 - 4999',
            BillingCountry = 'United States',
            Industry = 'Other',
            ADR_Transfer__c = false,
            BillingState = 'California',
            OwnerId = aeUser.Id
        );
        insert testAccount;
        
        // Create Contact
        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact',
            ADR_Transfer_Status__c = 'Demo Scheduled',
            OwnerId = aeUser.Id
        );
        insert testContact;
        
        // Create Campaign
        Campaign testCampaign = new Campaign(
            Name = 'Test Campaign (Child) ADR',
            Status = 'In Progress',
            StartDate = System.Date.today()
        );
        insert testCampaign;
        
        Test.startTest();
        
        System.runAs(accountBookADRUser) {
            PageReference pageRef = Page.ADR_Transfer;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('currentContactID', testContact.Id);
            pageRef.getParameters().put('selectedValue', 'Fleet');
            
            ADRTransferController controller = new ADRTransferController(new ApexPages.StandardController(testContact));
            
            // Set demo date and trigger the logic
            controller.transferLog.ADR_Demo_Date__c = Date.today();
            controller.setRoundRobinUser();
            
            // Verify that transferOwner is set to the AE from Book of Business
            System.assertEquals(aeUser.Id, controller.transferOwner, 
                'Transfer owner should be set to the AE from Book of Business for Account Book ADR user');
            System.assertEquals(aeUser.Name, controller.transferOwnerName, 
                'Transfer owner name should match the AE name from Book of Business');
            
            // Test submit functionality
            PageReference submitted = controller.submit();
            System.assertNotEquals(null, submitted, 'Submit should return a page reference');
            
            // Test back to contact
            PageReference back = controller.backToContact();
            System.assertEquals('/' + testContact.Id, back.getUrl(), 'Back to contact should return correct URL');
        }
        
        Test.stopTest();
    }
   
}