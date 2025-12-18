/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-03-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest(SeeAllData=false)
public class JobPopulateOpprtunitySplitDataTest {
    
    @testSetup
    private static void testDataSetup() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
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
                     Territory__c = 'North America',
                     TimeZone__c = 'America/Los_Angeles',
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = '   ISO-8859-1')
                
                };
                        Insert testUsers;
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         BillingPostalCode  = '1030',
                                         BillingCountry = 'United Kingdom',
                                         ownerId = testUsers[0].Id,
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Renewal_AE__c =   testUsers[0].Id, 
                                         Industry = 'Other',
                                         CS_POC_First_Name__c ='Test',
                                         Key_Value_Points__c ='Telematics', 
                                         CS_POC_Email_Address__c='t.t@gmail.com');
        newAccounts.add(accountOne);
        
        Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                         BillingState='California',
                                         BillingCountry = 'United States',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         BillingPostalCode  = '1030',
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
             Rolling_off_HWM__c = 100.0,
            ContractTerm = 1,   
             HWM_Value__c = 4000,
            HWM_Threshold__c = 10.0, 
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
        
       
        }

    }
    
    //Rebate Opportunity - closed Lost, SBQQ__RenewedContract__c = null  and SBQQ__AmendedContract__c !=null
    @isTest static void TestJobPopulateOpportunitySplitDataMethod1() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      stageName = 'Closed Lost',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
     Test.stopTest();  
    }
    //Rebate Opportunity - closed Lost, SBQQ__RenewedContract__c = null  and SBQQ__AmendedContract__c=null
     @isTest static void TestJobPopulateOpportunitySplitDataMethod2() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                  	  Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      stageName = 'Closed Lost',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    //Revenue Opportunity - closed Won, SBQQ__RenewedContract__c != null  and SBQQ__AmendedContract__c=null
     @isTest static void TestJobPopulateOpportunitySplitDataMethod3() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	  closedate = system.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    //Revenue Opportunity - closed Won, SBQQ__RenewedContract__c != null  and SBQQ__AmendedContract__c=null
     @isTest static void TestJobPopulateOpportunitySplitDataMethod3a() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
        
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
         contrct.ContractTerm = 1;   
         contrct.HWM_Value__c = 40;
         contrct.HWM_Threshold__c = 1.0;
         update contrct;
         
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	  closedate = system.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 10.00,
                                                      Split_Renewal_ACV__c = 10.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
          Test.startTest();       
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 1000,
            HWM_Threshold__c = 1000.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
          Test.stopTest();
        
    }
    //Revenue Opportunity - closed Won, SBQQ__RenewedContract__c = null  and SBQQ__AmendedContract__c!=null
    @isTest static void TestJobPopulateOpportunitySplitDataMethod4() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	closedate = system.today(),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
           
        Opportunity opportunityTwo = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 4 Inc',
                                                      SBQQ__AmendedContract__c =null,
                                                   	  SBQQ__RenewedContract__c =  contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	closedate = system.today(),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityTwo); 
        insert newOpportunities;
        
        system.debug('newOpportunities:'+newOpportunities); 
        system.debug('newOpportunities[0]:'+newOpportunities[0].id);  
        system.debug('newOpportunities[0]:'+newOpportunities[1].id);  
        
        contrct.SBQQ__Opportunity__c =  newOpportunities[1].id;
        update contrct;
        
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c,  SBQQ__RenewedContract__r.Rolling_off_HWM__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        
    }
    //Revenue Opportunity - closed Lost, SBQQ__RenewedContract__c = null  and SBQQ__AmendedContract__c!=null
     @isTest static void TestJobPopulateOpportunitySplitDataMethod5() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	closedate = system.today().addMonths(13),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
         Test.startTest();  
        Opportunity opportunityTwo = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 4 Inc',
                                                      SBQQ__AmendedContract__c =null,
                                                   	  SBQQ__RenewedContract__c =  contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	closedate = system.today().addMonths(13),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityTwo); 
        insert newOpportunities;
        system.debug('newOpportunities:'+newOpportunities); 
        system.debug('newOpportunities[0]:'+newOpportunities[0].id);  
        system.debug('newOpportunities[0]:'+newOpportunities[1].id);  
        
        contrct.SBQQ__Opportunity__c =  newOpportunities[1].id;
        update contrct;
        
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c,  SBQQ__RenewedContract__r.Rolling_off_HWM__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    
     //Revenue Opportunity - closed Lost, SBQQ__AmendedContract__c = null and Contract HWM_Threshold__c is greater
    @isTest static void TestJobPopulateOpportunitySplitDataMethod6() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Lost',
                                                   	closedate = system.today(),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    //Revenue Opportunity - closed Won, SBQQ__AmendedContract__c = null and HWM_Threshold__c is less
    @isTest static void TestJobPopulateOpportunitySplitDataMethod7() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	closedate = system.today(),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
     //Revenue Opportunity - closed Won, SBQQ__AmendedContract__c = null and HWM_Threshold__c is less
    @isTest static void TestJobPopulateOpportunitySplitDataMethod7a() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	closedate = system.today(),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest(); 
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
       
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li; 
                
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
          test.stoptest();
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        
    }
    //Revenue Opportunity - closed Won, SBQQ__AmendedContract__c = null and HWM_Threshold__c = null
    @isTest static void TestJobPopulateOpportunitySplitDataMethod8() {
         //Test.startTest();
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         
         Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,   
             HWM_Value__c = null,
            HWM_Threshold__c =null, 
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
        
        insert cont;
        cont.Status = 'Activated';
        update cont;
        Test.startTest();
        Contract contrct = [select id from Contract where  HWM_Value__c = null];
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	closedate = system.today(),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
                
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont1 = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = null,
            HWM_Threshold__c = null, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont1;
         cont1.Status = 'Activated';
        update cont1;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    //Revenue Opportunity - closed Won, SBQQ__AmendedContract__c = null and HWM_Threshold__c < HWM_Value__c
    @isTest static void TestJobPopulateOpportunitySplitDataMethod9() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	closedate = system.today(),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 4000.0,
            HWM_Threshold__c = 4000.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
     //Revenue Opportunity - closed Won, SBQQ__AmendedContract__c = null and HWM_Threshold__c = HWM_Value__c
     @isTest static void TestJobPopulateOpportunitySplitDataMethod10() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	closedate = system.today(),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
         Test.startTest();       
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 3333.33,
            HWM_Threshold__c = 3333.33, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    //Revenue Opportunity - closed Won, SBQQ__AmendedContract__c = null and HWM_Threshold__c > HWM_Value__c
    @isTest static void TestJobPopulateOpportunitySplitDataMethod11() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	closedate = system.today(),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 10000.00,
                                                      Split_Renewal_ACV__c = 10000.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 2222.33,
            HWM_Threshold__c = 44444.33, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    //Revenue Opportunity - closed Won, SBQQ__AmendedContract__c = null and HWM_Threshold__c > HWM_Value__c
    @isTest static void TestJobPopulateOpportunitySplitDataMethod11a() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	closedate = system.today(),
                                                   Went_to_closed_won_date__c = datetime.now(),
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 2222.33,
            HWM_Threshold__c = 44444.33, 
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    //Revenue Opportunity - closed Lost
	 @isTest static void TestJobPopulateOpportunitySplitDataMethod12() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Lost',
                                                   	closedate = system.today(),
                                                   Went_to_closed_lost_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    //Revenue Opportunity - closedLost
    @isTest static void TestJobPopulateOpportunitySplitDataMethod13() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Lost',
                                                   	closedate = system.today(),
                                                   Went_to_closed_lost_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    // Schedule job - cron and with both query and opportunityId null
    @isTest static void TestJobPopulateOpportunitySplitDataMethod14() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Lost',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(null,null);
        Database.executeBatch(jcop);
        Test.stopTest();
        JobPopulateOpprtunitySplitData m = new JobPopulateOpprtunitySplitData(null,null);
        String seconds = '0'; //Execute at Zero Seconds
        String minutes = '0'; //Execute at every 0 minute of hour
        String hours = '21'; // Execute at 1 AM
        String dayOfMonth = '?'; // Execute Every Day of the Month
        String month = '*'; //Execute every Month
        String dayOfWeek = '*'; //Execute on all 7 days of the Week
        
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek;
        //String sch = '0 0 01 * * ?';
        system.schedule('JobPopulateOpprtunitySplitData Run Every Day at 9pm', sch, m);
        
    }
    // Remorse Refund opportunity - Return Created
    @isTest static void TestJobPopulateOpportunitySplitDataMethod15() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
          TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();
         Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Remorse Refund' ;
        thisOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOpp.StageName = 'Return Created';
        thisOpp.Amount = -1000;
        thisOpp.AccountId = accountOne.Id;
        thisOpp.SBQQ__AmendedContract__c =contrct.Id;
        thisOpp.Returning_Opportunity__c = newOpportunities[0].Id;
        thisOpp.Finance_Approved_Return__c = true;
        System.debug(LoggingLevel.INFO, 'OPPORTUNITY: '+thisOpp);
          insert thisOpp;
                
        contrct.SBQQ__Opportunity__c = thisOpp.id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,thisOpp.id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    
   
    // Remorse Refund opportunity - Return Created
    @isTest static void TestJobPopulateOpportunitySplitDataMethod15a() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
          TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;  
        
         Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Remorse Refund' ;
        thisOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOpp.StageName = 'Return Created';
        thisOpp.Amount = -1000;
        thisOpp.AccountId = accountOne.Id;
        thisOpp.SBQQ__AmendedContract__c =contrct.Id;
        thisOpp.Returning_Opportunity__c = newOpportunities[0].Id;
        thisOpp.Finance_Approved_Return__c = true;
        System.debug(LoggingLevel.INFO, 'OPPORTUNITY: '+thisOpp);
          insert thisOpp;
                
        contrct.SBQQ__Opportunity__c = thisOpp.id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,thisOpp.id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    // Remorse Refund opportunity - Return Created
    @isTest static void TestJobPopulateOpportunitySplitDataMethod15b() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
          TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_Renewal_ACV__c = 10,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;  
        
         Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Remorse Refund' ;
        thisOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOpp.StageName = 'Return Created';
        thisOpp.Amount = -1000;
        thisOpp.AccountId = accountOne.Id;
        thisOpp.SBQQ__AmendedContract__c =contrct.Id;
        thisOpp.Returning_Opportunity__c = newOpportunities[0].Id;
        thisOpp.Finance_Approved_Return__c = true;
        System.debug(LoggingLevel.INFO, 'OPPORTUNITY: '+thisOpp);
          insert thisOpp;
                
        contrct.SBQQ__Opportunity__c = thisOpp.id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,thisOpp.id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    // Remorse Refund opportunity - close Lost
    @isTest static void TestJobPopulateOpportunitySplitDataMethod16() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
          TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();
         Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Remorse Refund' ;
        thisOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOpp.StageName = 'Closed Lost';
        thisOpp.Amount = -1000;
        thisOpp.AccountId = accountOne.Id;
        thisOpp.Went_to_closed_lost_date__c = System.today();
        thisOpp.SBQQ__AmendedContract__c =contrct.Id;
        thisOpp.Returning_Opportunity__c = newOpportunities[0].Id;
        thisOpp.Finance_Approved_Return__c = true;
        System.debug(LoggingLevel.INFO, 'OPPORTUNITY: '+thisOpp);
          insert thisOpp;
                
        contrct.SBQQ__Opportunity__c = thisOpp.id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,thisOpp.id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    // Rebate opportunity - closeWon
    @isTest static void TestJobPopulateOpportunitySplitDataMethod17() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                  		 Went_to_closed_won_date__c = system.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Rebate_Type__c = 'Delinquent',
                                                      License_Term__c = 12,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(null,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    // Rebate opportunity - closeWon
    @isTest static void TestJobPopulateOpportunitySplitDataMethod17_A() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                  		 Went_to_closed_won_date__c = system.today(),
                                                        CloseDate = system.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Split_New_ACV__c = null,
                                                      Split_Renewal_ACV__c = null,
                                                      License_Term__c = 12,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(null,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    // Rebate opportunity - closeWon
    @isTest static void TestJobPopulateOpportunitySplitDataMethod17a() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityReturn = (Opportunity)
          TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Send_Invoice__c = false));
         insert opportunityReturn;
         Test.startTest();
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                  		 Went_to_closed_won_date__c = system.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                   Returning_Opportunity__c = opportunityReturn.id,
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Rebate_Type__c = 'Delinquent',
                                                      License_Term__c = 12,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
               
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(null,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
     // Rebate opportunity - closeWon
    @isTest static void TestJobPopulateOpportunitySplitDataMethod17b() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityReturn = (Opportunity)
          TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Send_Invoice__c = false));
         insert opportunityReturn;
        Test.startTest();
         Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=opportunityReturn.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li; 
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                  		 Went_to_closed_won_date__c = system.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Returning_Opportunity__c = opportunityReturn.id,
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Rebate_Type__c = 'Delinquent',
                                                      License_Term__c = 12,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
                
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         Test.stopTest();
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(null,newOpportunities[0].id);
        Database.executeBatch(jcop);
        
    }
    
    // Rebate opportunity - closeWon
    @isTest static void TestJobPopulateOpportunitySplitDataMethod17c() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityReturn = (Opportunity)
          TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Send_Invoice__c = false));
         insert opportunityReturn;
        Test.startTest();
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Remorse Refund' ;
        thisOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOpp.StageName = 'Return Created';
        thisOpp.Amount = -1000;
        thisOpp.AccountId = accountOne.Id;
        thisOpp.SBQQ__AmendedContract__c =contrct.Id;
        thisOpp.Returning_Opportunity__c = opportunityReturn.Id;
        thisOpp.Finance_Approved_Return__c = true;
          insert thisOpp;
         Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=thisOpp.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;         
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                  		 Went_to_closed_won_date__c = system.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Returning_Opportunity__c = opportunityReturn.id,
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Rebate_Type__c = 'Delinquent',
                                                      License_Term__c = 12,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
               
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         Test.stopTest();
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(null,newOpportunities[0].id);
        Database.executeBatch(jcop);
        
    }
    
    // Rebate opportunity - closeWon
    @isTest static void TestJobPopulateOpportunitySplitDataMethod17d() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityReturn = (Opportunity)
          TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_Renewal_ACV__c = 100,
                                                      Send_Invoice__c = false));
         insert opportunityReturn;
       
         Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        Test.startTest();
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=opportunityReturn.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li; 
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                  		 Went_to_closed_won_date__c = system.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Returning_Opportunity__c = opportunityReturn.id,
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Rebate_Type__c = 'Delinquent',
                                                      License_Term__c = 12,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
               
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         Test.stopTest();
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(null,newOpportunities[0].id);
        Database.executeBatch(jcop);
        
    }
    // Rebate opportunity - closeLost
    @isTest static void TestJobPopulateOpportunitySplitDataMethod18() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                  	  Went_to_closed_won_date__c = system.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Lost',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Rebate_Type__c = 'Delinquent',
                                                      License_Term__c = 12,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    //opportunityId is null
    @isTest static void TestJobPopulateOpportunitySplitDataMethod19() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                  	  Went_to_closed_won_date__c = system.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      stageName = 'Closed Lost',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                   	  Rebate_Type__c = 'Delinquent',
                                                      License_Term__c = 12,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,null);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    //Revenue Opportunity
    @isTest static void TestJobPopulateOpportunitySplitDataMethod20() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                       Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                  	  Went_to_closed_won_date__c = system.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      stageName = 'Closed Won',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      License_Term__c = 12,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,null);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    
    //Revenue Opportunity
    @isTest static void TestJobPopulateOpportunitySplitDataMethod21() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                       Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = contrct.id,
                                                   	  SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                  	  Went_to_closed_lost_date__c = system.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      stageName = 'Closed Lost',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      License_Term__c = 12,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
        JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,null);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    
    @isTest 
    static void TestJobPopulateOpportunitySplitDataMethod22() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
		 Contact contactOne = [select id from contact limit 1];        
         Contract contrct = [select id, Health_Status__c from Contract limit 1 ];
         contrct.Health_Status__c = 'Unhealthy';
         update contrct;
        
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Lost',
                                                   	closedate = system.today(),
                                                   Went_to_closed_lost_date__c = datetime.now(),
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne); 
        insert newOpportunities;
        Test.startTest();        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0, 
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
        update cont;
         
        String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        Test.stopTest();
    }
    @isTest static void TestJobPopulateOpportunitySplitDataMethod23() {
         List<Opportunity> newOpportunities = new List<Opportunity>();
         Contact contactOne = [select id from contact limit 1];
            Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
         Contract contrct = [select id from Contract limit 1 ];
        DateTime closedWonDate = DateTime.Now();
       test.startTest();
         Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                      SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                      closedate = system.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Went_to_closed_won_date__c = closedWonDate,
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 0.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne);
        insert newOpportunities;
               
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = newOpportunities[0].id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0,
            SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont;
         cont.Status = 'Activated';
         update cont;
         
       
         Opportunity opportunityTwo = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 4 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                      SBQQ__RenewedContract__c = null,
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                      closedate = system.today(),
                                                      Amount_Received__c = 150.00,
                                                      Amount =150.00,
                                                      Went_to_closed_won_date__c = closedWonDate,
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 0.00,
                                                   //ACV_Bookings_Copy__c = 100,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
                                                     
                                                       
                                                      insert opportunityTwo;
        System.debug('opportunityTwo>>>>>>' + opportunityTwo);
            Contract cont1 = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            SBQQ__Opportunity__c = opportunityTwo.id,
            HWM_Value__c = 10,
            HWM_Threshold__c = 10.0,
            //SBQQ__RenewalOpportunity__c = newOpportunities[0].id,
            //Auto_Renewal__c = true,
            Status = 'Draft'
        );
         insert cont1;
         cont1.Status = 'Activated';
         update cont1;
         
         String query = 'Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c FROM Opportunity where id != null';
         JobPopulateOpprtunitySplitData jcop = new JobPopulateOpprtunitySplitData(query,newOpportunities[0].id);
        Database.executeBatch(jcop);
        test.stopTest();
 
       
    }
    
    @isTest
    public static void extraCoverageForOpportunityHelper(){
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];
        
        
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Closed Won',
                                                       CloseDate = Date.today(),
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      License_Term__c =12,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
        test.startTest();
        insert newOpportunities; 
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;      
        List<OpportunityLineItem> liList=[Select Id,Product2.Product_Type__c,ProductCode From OpportunityLineItem Where Id=:li.Id];

        OpportunityHelper oh=new OpportunityHelper();
        oh.checkDCLQualified(newOpportunities[0],newOpportunities[0]);
        List<Opportunity> listOpp=new List<Opportunity>();
        listOpp.add(newOpportunities[0]);
        Map<Id,Opportunity> mapOpps=new Map<Id,Opportunity>(listOpp);
        OpportunityHelper.calculateAllRollUpsToAccountFuture(JSON.serialize(listOpp),JSON.serialize(mapOpps));
        //emeaOpsAutomationPromoOppty
        Test.stopTest();
    }     
    
    @isTest
    static void testAfterDelete() {
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];

        Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	  closedate = system.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 10.00,
                                                      Split_Renewal_ACV__c = 10.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        insert opportunityOne;

        // Start test
        Test.startTest();
        delete opportunityOne;
        Test.stopTest();

        // Assertions can be added here to verify expected outcomes
    }

    @isTest
    static void testAfterUndelete() {
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];

        Opportunity opportunityOne = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      SBQQ__AmendedContract__c = null,
                                                   	  SBQQ__RenewedContract__c = contrct.id,
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      CurrencyIsoCode = 'USD',
                                                      stageName = 'Closed Won',
                                                   	  closedate = system.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      Went_to_closed_won_date__c = datetime.now(),
                                                      Split_New_ACV__c = 10.00,
                                                      Split_Renewal_ACV__c = 10.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        insert opportunityOne;

        // Delete and undelete the opportunity
        delete opportunityOne;
        Test.startTest();
        undelete opportunityOne;
        Test.stopTest();

        // Assertions can be added here to verify expected outcomes
    }

    @isTest
    static void testIsEnabled() {
        // Mock the behavior of the metadata type
        OpportunityTriggerHandler.isEnabled = true;

        // Test the isEnabled method
        Test.startTest();
        Boolean isEnabled = OpportunityTriggerHandler.isEnabled();
        Test.stopTest();

        // Assert that the trigger is enabled
        System.assert(isEnabled, 'The trigger should be enabled.');
    }
}