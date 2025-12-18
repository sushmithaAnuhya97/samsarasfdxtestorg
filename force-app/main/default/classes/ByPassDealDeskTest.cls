@isTest
private class ByPassDealDeskTest {
    @TestSetup
    static void setupTestData() {
        // Create test users with different roles
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        List<User>userList=new List<User>();
         UserRole directorRole = new UserRole(
            Name = 'Sales Director',
            DeveloperName = 'Sales_Director'
        );
        insert directorRole;
        // Create a user with Director role
        User directorUser = new User(
            Alias = 'director',
            Email = 'director@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Director',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'director1@ste1st.com',
            By_Pass_Deal_Desk_Approval__c = true,
            EmployeeNumber='123',
            UserRoleId = directorRole.Id
        );
        userList.add(directorUser);
        User directorUser2 = new User(
            Alias = 'dir2',
            Email = 'dir2@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Director',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'dir2@ste1st.com',
            By_Pass_Deal_Desk_Approval__c = true,
            EmployeeNumber='12387'
        );
        userList.add(directorUser2);
        //create a user with bypass flag as false
        User directorUser0 = new User(
            Alias = 'dir0',
            Email = 'dir0@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Director',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'dir0@ste1st.com',
            By_Pass_Deal_Desk_Approval__c = false,
            EmployeeNumber='129387',
            UserRoleId = directorRole.Id
        );
         userList.add(directorUser0);
        // Create a user with Manager role
        User managerUser = new User(
            Alias = 'manager',
            Email = 'manager@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'manager2@ste1st.com',
            ManagerId = directorUser.Id,
            EmployeeNumber='1234'
        );
        userList.add(managerUser);
        
        // Create a regular user
        User regularUser = new User(
            Alias = 'regular',
            Email = 'regular@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Regular',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'regular3@ste1st.com',
            ManagerId = managerUser.Id,
            EmployeeNumber='1235',
            isActive=false
        );
        userList.add(regularUser);
        insert userList;
          
    }
    
    @isTest
    static void testGetSalesDirectorBypassFlag_DirectorUser() {
        User directorUser = [SELECT Id FROM User WHERE UserName = 'director1@ste1st.com'];
        
        Test.startTest();
        String result = ByPassDealDeskUserHierarchy.getSalesDirectorBypassFlag(directorUser.Id);
        Test.stopTest();
        
        System.assertEquals(directorUser.Id, result, 'Should return director user ID');
    }

    @isTest
    static void testGetBypassFlagValue_noManager() {
        User directorUser = [SELECT Id FROM User WHERE UserName = 'dir2@ste1st.com'];
        List<Id> userIds = new List<Id>{directorUser.Id};
        
        Test.startTest();
        List<String> result = ByPassDealDeskUserHierarchy.getBypassFlagValue(userIds);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list for user with no manager');
    }
     @isTest
    static void testGetBypassFlagValueManagerNoBypass() {
        User directorUser = [SELECT Id FROM User WHERE UserName = 'dir0@ste1st.com'];
        List<Id> userIds = new List<Id>{directorUser.Id};
        
        Test.startTest();
        List<String> result = ByPassDealDeskUserHierarchy.getBypassFlagValue(userIds);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testGetBypassFlagValue_SingleUser() {
        User regularUser = [SELECT Id FROM User WHERE UserName = 'regular3@ste1st.com'];
        List<Id> userIds = new List<Id>{regularUser.Id};
        
        Test.startTest();
        List<String> result = ByPassDealDeskUserHierarchy.getBypassFlagValue(userIds);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list for inactive user');
    }

    @isTest
    static void testNotificationEmailToSalesDirector() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'regular3@ste1st.com'];

        Test.startTest();
        Account acc = new Account(
            Name = 'TEST_ACCOUNT_NAME_STRING',
            BillingStreet = '26 Napier Street',
            BillingCity = 'London',
            BillingPostalCode = '1030',
            BillingCountry = 'United Kingdom',
            Billing_Email__c = 'qdasdas@gmail.com',
            Organization_Size__c = '100 - 499',
            Payment_Terms__c = 'Net 45',
            Industry = 'Other'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'TEST_OPPORTUNITY_NAME_STRING', 
            StageName = 'Qualified', 
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id);
        insert quote;
        
        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Approved',
            Requested_Payment_Terms__c = 'Net 30',
            Auto_Approved__c = false,
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id,
            Requested_Payment_Types__c = 'Direct Monthly',
            Notes_from_Requester__c = 'For a quicker resolution and to avoid further iterations with Deal Desk please respond to all relevant questions in the Text Field below.'
        );
        insert request;

        Internal_Finance_Approval_Request__c testIFR = [SELECT Id FROM Internal_Finance_Approval_Request__c LIMIT 1];
        IFREmailHandler.FromFlow flowInput = new IFREmailHandler.FromFlow();
        flowInput.ifrId = testIFR.Id;
        flowInput.salesDirectorId = testUser.Id;
        IFREmailHandler.notificationEmailToSalesDirector(new List<IFREmailHandler.FromFlow>{flowInput});
        Test.stopTest();
    }

    @isTest
    static void testHandleInboundEmailApproval() {
        Test.startTest();
        Account acc = new Account(
            Name = 'TEST_ACCOUNT_NAME_STRING',
            BillingStreet = '26 Napier Street',
            BillingCity = 'London',
            BillingPostalCode = '1030',
            BillingCountry = 'United Kingdom',
            Billing_Email__c = 'qdasdas@gmail.com',
            Organization_Size__c = '100 - 499',
            Payment_Terms__c = 'Net 45',
            Industry = 'Other'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'TEST_OPPORTUNITY_NAME_STRING', 
            StageName = 'Qualified', 
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id);
        insert quote;
        
        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Approved',
            Requested_Payment_Terms__c = 'Net 30',
            Auto_Approved__c = false,
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id,
            Requested_Payment_Types__c = 'Direct Monthly'
        );
        insert request;

        Internal_Finance_Approval_Request__c request1 = [SELECT Id, Name FROM Internal_Finance_Approval_Request__c LIMIT 1];
         
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Approval Requested: Payment Type Request for Test Account - ' + request1.Name;
        email.plainTextBody = 'APPROVE\nThis is a test approval email approved for Semi-Annual\n';

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        IFREmailHandler handler = new IFREmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
    }

    @isTest
    static void testHandleInboundEmailRejection() {
        Test.startTest();
        Account acc = new Account(
            Name = 'TEST_ACCOUNT_NAME_STRING1',
            BillingStreet = '26 Napier Street',
            BillingCity = 'London',
            BillingPostalCode = '1030',
            BillingCountry = 'United Kingdom',
            Billing_Email__c = 'qdasdas@gmail.com',
            Organization_Size__c = '100 - 499',
            Payment_Terms__c = 'Net 45',
            Industry = 'Other'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'TEST_OPPORTUNITY_NAME_STRING1', 
            StageName = 'Qualified', 
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id);
        insert quote;
        
        Internal_Finance_Approval_Request__c request = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Change in Payment Terms',
            Payment_Type_Approval_Status__c = 'Rejected',
            Requested_Payment_Terms__c = 'Net 30',
            Auto_Approved__c = false,
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Quote__c = quote.Id,
            Requested_Payment_Types__c = 'Direct Monthly'
        );
        insert request;
       
        Internal_Finance_Approval_Request__c request1 = [SELECT Id, Name FROM Internal_Finance_Approval_Request__c LIMIT 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Approval Requested: Payment Type Request for Test Account - ' + request1.Name;
        email.plainTextBody = 'Reject\n.Update the financial comments\n';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        IFREmailHandler handler = new IFREmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
    }
}