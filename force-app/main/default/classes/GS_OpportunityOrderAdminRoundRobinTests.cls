@isTest(SeeAllData=false)
public class GS_OpportunityOrderAdminRoundRobinTests {

    @testSetup
    private static void testDataSetup() {
       insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
       List<Opportunity> newOpportunities = new List<Opportunity>();
       List<Account> newAccounts = new List<Account>();
       List<Contact> newContacts = new List<Contact>();
       List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
        
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        newAccounts.add(accountOne);
        
        Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                BillingState='California',
                                BillingCountry = 'United States',
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                Industry = 'Other');
        newAccounts.add(accountTwo);

        insert newAccounts;
        
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        newContacts.add(contactOne);
        
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'test@test.com'));
        newContacts.add(contactTwo);

        insert newContacts;
        
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
        shippingAddressList.add(sa);
        Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = accountOne.Id);
        shippingAddressList.add(sa2);

        insert shippingAddressList;



        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 2 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactTwo.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne);     
         
        insert newOpportunities;
    }
    
    @isTest private static void testOrderAdminAssignment() {

        Test.startTest();
        // Create 4 order admin users
        List<User> uList = new List<User>();
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        for(Integer i = 0; i < 4; i++) {
            uList.add(new User(
                                EmployeeNumber = '123',
                                ProfileId = pId,
                                LastName = 'last',
                                Email = 'puser000@amamama.com',
                                Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
                                CompanyName = 'TEST',
                                Title = 'title',
                                Alias = 'alias',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                EmailEncodingKey = 'UTF-8',
                                LanguageLocaleKey = 'en_US',
                                LocaleSidKey = 'en_US',
                                Order_Admin_Available__c = TRUE,
                                isActive = TRUE
            ));
        }

        insert uList;
        Opportunity o = [ SELECT Id FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
        o.Probability = 98;        
        update o;
        
        new GS_OpportunityOrderAdminRoundRobinAsync().execute(new Async_Request__c(
            Params__c = uList[0].Id+';'
        ));
            
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Order_Admin__c FROM Opportunity WHERE Name='Opp Testers 2 Inc']);
        List<User> userList = new List<User>([SELECT Id, Order_Admin_Oppty_Date__c FROM User WHERE Id = :oppList[0].Order_Admin__c]);

        // Make sure admin users were assigned and updated
        System.assertEquals(System.now().day(), userList[0].Order_Admin_Oppty_Date__c.day());
        Test.stopTest();
    }
     
    @isTest private static void testOrderAdminAssignmentUK() {

        Test.startTest();
        // Create 4 order admin users
        List<User> uList = new List<User>();
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        for(Integer i = 0; i < 4; i++) {
            uList.add(new User(
                                EmployeeNumber = '123',
                                ProfileId = pId,
                                LastName = 'last',
                                Email = 'puser000@amamama.com',
                                Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
                                CompanyName = 'TEST',
                                Title = 'title',
                                Alias = 'alias',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                EmailEncodingKey = 'UTF-8',
                                LanguageLocaleKey = 'en_US',
                                LocaleSidKey = 'en_US',
                                Order_Admin_Available__c = TRUE,
                                isActive = TRUE,
                                Entity__c = 'Samsara UK'
            ));
        }
        insert uList;

        Opportunity o = [ SELECT Id FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
        o.Probability = 98; 
        o.Shipping_Country__c = 'United Kingdom';
        update o;
        
        new GS_OpportunityOrderAdminRoundRobinAsync().execute(new Async_Request__c(
            Params__c = uList[0].Id+';'
        ));
        
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Order_Admin__c FROM Opportunity WHERE Name='Opp Testers 2 Inc']);
        List<User> userList = new List<User>([SELECT Id, Order_Admin_Oppty_Date__c FROM User WHERE Id = :oppList[0].Order_Admin__c]);

        // Make sure admin users were assigned and updated
        System.assertEquals(System.now().day(), userList[0].Order_Admin_Oppty_Date__c.day());
        Test.stopTest();
    }


    @isTest private static void testOrderAdminFallback() {
        
        Test.startTest();
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Opportunity o = [ SELECT Id FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
        
        system.runAs(thisUser){
            List<User> ordrAdminList = [SELECT Id, Order_Admin_Oppty_Date__c, Entity__c FROM User WHERE Order_Admin_Available__c = TRUE AND isActive = TRUE];
            List<User> makeordrAdminInactive = new List<User>();
            for(User userObj : ordrAdminList){
                userObj.isActive = False;
                makeordrAdminInactive.add(userObj);
            }
            update makeordrAdminInactive;
        }
        // Create an order admin fallback user
        List<User> uList = new List<User>();
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        uList.add(new User(
            ProfileId = pId,
            EmployeeNumber = '123',
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Order_Admin_Fallback_User__c = TRUE,
            isActive = TRUE
        ));
        insert uList;
        
        o.Probability = 98;
        update o;
        
        new GS_OpportunityOrderAdminRoundRobinAsync().execute(new Async_Request__c(
            Params__c = uList[0].Id+';'
        ));
        
        // Check on the opps' assigned order admins
        for(Opportunity oppOrder : [SELECT Id, Order_Admin__c FROM Opportunity]) {
            System.debug(LoggingLevel.INFO, 'oppOrder updated: ' + oppOrder.Order_Admin__c);
        }
        
        // Make sure fallback user was assigned and updated     
        for(User orderAdmin : [SELECT Id, Order_Admin_Oppty_Date__c, Name FROM User WHERE Order_Admin_Fallback_User__c = TRUE AND Email = 'puser000@amamama.com']) {
            System.debug(LoggingLevel.INFO, 'orderAdmin user = ' + orderAdmin);
            //  if(orderAdmin.Order_Admin_Oppty_Date__c != NULL) {
            System.assertEquals(System.now().day(), orderAdmin.Order_Admin_Oppty_Date__c.day());
            //  }
        }
        Test.stopTest();
    }
}