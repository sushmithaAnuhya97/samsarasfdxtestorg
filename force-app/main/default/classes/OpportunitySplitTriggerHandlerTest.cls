@isTest(SeeAllData=false)
public class OpportunitySplitTriggerHandlerTest {
    
    @testSetup
    private static void testDataSetup() {
        system.debug('**********testDataSetup:');
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
          User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        system.debug('thisUser:'+thisUser);
        System.runAs (thisUser) {
        List<User> testUsers = new List<User>{
            new User(lastName = 'Tyler McGrath',
                     Alias = 'test1',
                     Email = 'tuser@test1.com',
                     Username = 'tuser@test001tests.com',
                     CommunityNickname = 'User16529768062775798018',
                     UserRoleId = [select Id,name from UserRole where name like '%AE3%' limit 1].id,
                     ProfileId = [select Id,name from Profile where name like '%Samsara Sales Management - New System%' limit 1].id,
                     EmployeeNumber = '9000134',
                     managerId= thisUser.id,
                     Territory__c = 'North America',
                     TimeZone__c = 'America/Los_Angeles',
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = '   ISO-8859-1')
                
                };
                        Insert testUsers;
        system.debug('testUsers:'+testUsers);
        system.debug('**************insertUser');
        
         
        system.debug('testUsers:'+testUsers[0].Id);
        system.debug('testUsers:'+testUsers[0].userrole.name);
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         BillingPostalCode  = '1030',
                                         BillingCountry = 'United Kingdom',
                                         ownerId = testUsers[0].Id,
                                         Exclude_HWM__c = false,
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Renewal_AE__c =   testUsers[0].Id, 
                                         Industry = 'Other');
        newAccounts.add(accountOne);
        
        Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                         BillingState='California',
                                         BillingCountry = 'United States',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         BillingPostalCode  = '1030',
                                          Exclude_HWM__c = false,
                                         ownerId = testUsers[0].Id,
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Renewal_AE__c =   testUsers[0].Id,
                                         Approved_Payment_Type__c = 'Direct Monthly',
                                         Industry = 'Other');
        newAccounts.add(accountTwo);
        
        insert newAccounts;
        
        
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
        
        insert cont;
        cont.Status = 'Activated';
        update cont;
        
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        newContacts.add(contactOne);
        
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'test@test.com'));
        newContacts.add(contactTwo);
        
        insert newContacts;
        
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
        shippingAddressList.add(sa);
        Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = accountOne.Id);
        shippingAddressList.add(sa2);
        Shipping_Address__c sa3 = new Shipping_Address__c(Shipping_Zip_Code__c = 'C.P. 45610', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Adolf B Horn 1737-1', Shipping_City__c='San Pedro Tlaquepaque, Jal', Shipping_Country__c='Mexico', Name='Test Mexico', Account__c = accountOne.Id);
        shippingAddressList.add(sa3);
        
        insert shippingAddressList;
        
        
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        }

    }
    @isTest static void opportunityHelperMethod1() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc' and Segment__c = 'AE3'];
        system.debug('accountOne:'+accountOne);
        
           Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                      closedate = system.today().adddays(30),
                                                   	Went_to_closed_won_date__c = datetime.now().adddays(30),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                       License_Term__c = 12,
                                                      Amount = 10000,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne);             
        Test.startTest();
        insert newOpportunities;
        List<Opportunity> oppList = [SELECT Id,Split_New_ACV__c,Account.OwnerId,OwnerId FROM Opportunity where id != null and  Account.Exclude_HWM__c=false  AND (((Type='Remorse Refund' OR (Type='Rebate' AND Rebate_Type__c ='Delinquent')) AND IsWon=true) OR Type='Revenue Opportunity') AND ACV_Bookings_SOT__c !=0 AND CurrencyIsoCode IN ('USD','CAD','MXN') AND Account.Segment__c IN ('Enterprise','AE3') AND CloseDate>=2024-02-04 AND CloseDate<=Next_N_DAYS:365 AND ((Split_New_ACV__c != null AND Split_New_ACV__c!=0) OR (Split_Renewal_ACV__c != null AND Split_Renewal_ACV__c !=null))];
        system.debug('oppList:'+oppList);
        Test.stopTest();
       
        
    }
    @isTest static void opportunityHelperMethod2() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc' and Segment__c = 'AE3'];
        system.debug('accountOne:'+accountOne);
        
           Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                      closedate = system.today().adddays(30),
                                                   	Went_to_closed_won_date__c = datetime.now().adddays(30),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                       License_Term__c = 12,
                                                      Amount = 10000,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne);             
        Test.startTest();
        insert newOpportunities;
        List<Opportunity> oppList = [SELECT Id FROM Opportunity where id != null and  Account.Exclude_HWM__c=false  AND (((Type='Remorse Refund' OR (Type='Rebate' AND Rebate_Type__c ='Delinquent')) AND IsWon=true) OR Type='Revenue Opportunity') AND ACV_Bookings_SOT__c !=0 AND CurrencyIsoCode IN ('USD','CAD','MXN') AND Account.Segment__c IN ('Enterprise','AE3') AND CloseDate>=2024-02-04 AND CloseDate<=Next_N_DAYS:365 AND ((Split_New_ACV__c != null AND Split_New_ACV__c!=0) OR (Split_Renewal_ACV__c != null AND Split_Renewal_ACV__c !=null))];
        system.debug('oppList:'+oppList);
        Test.stopTest();
        String query = 'SELECT Id,IsSplit,isClosed,Split_New_ACV__c,Split_Renewal_ACV__c,Account.Owner.Name,Account.Owner.Email,Account.Owner.UserRole.Name,Account.Renewal_AE__r.Name,Account.Renewal_AE__r.Email,Account.Renewal_AE__r.UserRole.Name,CloseDate,Owner.name,Owner.Email,Owner.UserRole.Name,Owner_Manager_Name_Copy__r.Name,Owner_Manager_Name_Copy__r.Email,Owner_Manager_Name_Copy__r.UserRole.Name,Owner_Director_Name_Copy__r.Name,Owner_Director_Name_Copy__r.Email,Owner_Director_Name_Copy__r.UserRole.Name,Amount FROM Opportunity where id != null';
        Opportunity newOpportunity = [SELECT id,AccountId from Opportunity where StageName = 'Closed Won' LIMIT 1];
         string oppId = newOpportunity.Id;
      
        
    }
 
}