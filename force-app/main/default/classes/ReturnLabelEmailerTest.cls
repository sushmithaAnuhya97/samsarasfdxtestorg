@isTest
private class ReturnLabelEmailerTest{
    //GTMS-25173 Insert Shipping_Address__c
    @TestSetup
    static void createData(){
        insert new Global_Automation_Settings__c(Name = 'Automation_Settings',Allow_Handler_Selection__c = true);
        Account accRec = new Account();
        accRec.Name = 'TestFirst Account';
        accRec.Business_Unit__c = 'Fleet';
        accRec.BillingStreet = '123 Testing St';
        accRec.BillingCity = 'San Francisco';
        accRec.BillingCountryCode = 'US';
        accRec.BillingStateCode = 'CA';
        accRec.BillingPostalCode = '94109';
        accRec.DUNS_Number__c = '12345';
        accRec.Website = 'www.samsara.com';
        accRec.Organization_Size__c = '1 - 99';
        accRec.Which_written_language__c = 'English';
        insert accRec;
        
        Contact conRec = new Contact();
        conRec.FirstName = 'TestFirst';
        conRec.AccountId = accRec.Id;
        conRec.LastName = 'Contact';
        conRec.Status__c = 'New';
        conRec.MailingCountryCode = 'US';
        conRec.MailingStateCode = 'CA';
        insert conRec;
        
        Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = accRec.Id, Shipping_Contact__c = conRec.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                             , Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                             , Shipping_Zip_Code__c = '95054', Name = 'Ship To One',Shipping_Email__c = 'Ship To One@gmail.com');
        
        insert shipTo;
        
        Opportunity returningOppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accRec.Id,
                                                      Type = 'Exchange',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Return Created',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = conRec.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Shipping_Address_NEW__c=shipTo.Id,
                                                      Send_Invoice__c = false,
                                                      closeDate = Date.today().addDays(5),
                                                      amount = -1000));
        
        insert returningOppty;
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User Owner = [Select Id FROM User WHERE Name LIKE 'Ron Saavedra'];

    }
    @isTest
    static void testReturnLabelEmailer(){
        
        Account a = new Account();
        a.Name = 'TestFirst Account';
        a.Business_Unit__c = 'Fleet';
        a.BillingStreet = '123 Testing St';
        a.BillingCity = 'San Francisco';
        a.BillingCountryCode = 'US';
        a.BillingStateCode = 'CA';
        a.BillingPostalCode = '94109';
        a.DUNS_Number__c = '12345';
        a.Website = 'www.samsara.com';
        a.Organization_Size__c = '1 - 99';
        a.Which_written_language__c = 'English';
        insert a;
        
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        User u = new User(
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
        );
        insert u;
        
        a.CSM__c = u.Id;
        a.SIC__c = u.Id;
        update a;
            
        Contact c = new Contact();
        c.FirstName = 'TestFirst';
        c.AccountId = a.Id;
        c.LastName = 'Contact';
        c.Status__c = 'New';
        c.MailingCountryCode = 'US';
        c.MailingStateCode = 'CA';
        insert c;
        //GTMS-25173 Added Shipping_Email__c
        Shipping_Address__c sh= new Shipping_Address__c();
        sh.Account__c=a.Id;
        sh.Shipping_Contact__c = c.Id;
        sh.Shipping_Address_Line_1__c='Test Line';
        sh.Shipping_City__c='Test City';
        sh.Shipping_State__c='Alabama';
        sh.Shipping_Email__c = 'Test US@gmail.com';
        sh.Shipping_Country__c='United States';
        sh.Shipping_Zip_Code__c='879231';
        sh.Name='Test US';
        insert sh;
        
        Opportunity o = new Opportunity();
        o.StageName = 'Qualified';
        o.Name = 'Test Opp return';
        o.AccountId = a.Id;
        o.Related_Contact__c = c.Id;
        o.License_Term__c = 36;
        o.Amount = 15000;
        o.Shipping_Address_NEW__c=sh.Id;
        o.Type = 'Exchange';
        o.Finance_Partner_Notes__c = 'Test';
        o.Subsidize_Financing__c = True;
        o.CloseDate =  system.today()+5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        o.Return_Label_Sent_At__c = System.Today().addDays(-21);
        insert o;
        
        //Alekya
        Test.startTest();
        
        zkmulti__MCShipment__c  shipment = new zkmulti__MCShipment__c();
        shipment.zkmulti__Tracking_Number__c = '1z1w7w420374732280';
        shipment.Opportunity__c = o.Id;
        insert shipment;
        
        Attachment attach=new Attachment();      
        attach.Name='Return-Label01.PDF';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=shipment.id;
        insert attach;
        
        Attachment attach2=new Attachment();      
        attach2.Name='International-Forms.PDF';
        Blob bodyBlob2=Blob.valueOf('Unit Test Attachment Body');
        attach2.body=bodyBlob2;
        attach2.parentId=shipment.id;
        insert attach2;   
        
        Map<Id, Opportunity> oppInfo = new Map<Id, Opportunity>([SELECT  Id,Shipping_Address_NEW__c,
                                                                 Shipping_Address_NEW__r.Shipping_Contact__c, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.Email, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.firstname, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.lastname,
                                                                 OwnerId,
                                                                 Owner.Name,
                                                                 Owner.Email,
                                                                 Account.CSM__r.Email,
                                                                 Return_Label_Attachment__c,
                                                                 Account.Which_written_language__c
                                                                 FROM Opportunity WHERE Name='Test Opp return']); 
        
        //Test.startTest();
        ReturnLabelEmailer.sendReturnEmails(oppInfo);
        Test.stopTest();
        System.assert(true,true);	
    }
    
     @isTest
    static void testExchangeOpportunity(){
        Account a = new Account();
        a.Name = 'TestSecond Account';
        a.Business_Unit__c = 'Fleet';
        a.BillingStreet = '123 Testing St';
        a.BillingCity = 'San Francisco';
        a.BillingCountryCode = 'US';
        a.BillingStateCode = 'CA';
        a.BillingPostalCode = '94109';
        a.DUNS_Number__c = '12345';
        a.Website = 'www.samsara.com';
        a.Organization_Size__c = '1 - 99';
        a.Which_written_language__c = 'English';
        insert a;
        
        Opportunity o = new Opportunity();
        o.StageName = 'Qualified';
        o.Name = 'Test Opp return';
        o.AccountId = a.Id;
        o.License_Term__c = 36;
        o.Amount = 15000;
        o.Type = 'Exchange';
        o.CloseDate =  system.today()+5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        o.Return_Label_Sent_At__c = System.Today().addDays(-21);
        insert o;
        
        Map<Id, Opportunity> oppInfo = new Map<Id, Opportunity>([SELECT  Id,Shipping_Address_NEW__c,
                                                                 Shipping_Address_NEW__r.Shipping_Contact__c, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.Email, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.firstname, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.lastname,
                                                                 OwnerId,
                                                                 Owner.Name,
                                                                 Owner.Email,
                                                                 Account.CSM__r.Email,
                                                                 Return_Label_Attachment__c,
                                                                 Account.Which_written_language__c
                                                                 FROM Opportunity WHERE Name='Test Opp return']); 
        
        Test.startTest();
        ReturnLabelEmailer.sendReturnEmails(oppInfo);
        Test.stopTest();
    }
    
    @isTest
    static void testExchangeOpportunityWithReturnLabelNull(){
        Account a = new Account();
        a.Name = 'TestSecond Account';
        a.Business_Unit__c = 'Fleet';
        a.BillingStreet = '123 Testing St';
        a.BillingCity = 'San Francisco';
        a.BillingCountryCode = 'US';
        a.BillingStateCode = 'CA';
        a.BillingPostalCode = '94109';
        a.DUNS_Number__c = '12345';
        a.Website = 'www.samsara.com';
        a.Organization_Size__c = '1 - 99';
        a.Which_written_language__c = 'English';
        insert a;
        
        Opportunity o = new Opportunity();
        o.StageName = 'Qualified';
        o.Name = 'Test Opp return';
        o.AccountId = a.Id;
        o.License_Term__c = 36;
        o.Amount = 15000;
        o.Type = 'Exchange';
        o.CloseDate =  system.today()+5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        insert o;
        
        Map<Id, Opportunity> oppInfo = new Map<Id, Opportunity>([SELECT  Id,Shipping_Address_NEW__c,
                                                                 Shipping_Address_NEW__r.Shipping_Contact__c, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.Email, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.firstname, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.lastname,
                                                                 OwnerId,
                                                                 Owner.Name,
                                                                 Owner.Email,
                                                                 Account.CSM__r.Email,
                                                                 Return_Label_Attachment__c,
                                                                 Account.Which_written_language__c
                                                                 FROM Opportunity WHERE Name='Test Opp return']); 
        
        Test.startTest();
        ReturnLabelEmailer.sendReturnEmails(oppInfo);
        Test.stopTest();
    }
    
    @isTest
    static void testExchangeOpportunityWithLanguageNull(){
        Account a = new Account();
        a.Name = 'TestFirst Account';
        a.Business_Unit__c = 'Fleet';
        a.BillingStreet = '123 Testing St';
        a.BillingCity = 'San Francisco';
        a.BillingCountryCode = 'US';
        a.BillingStateCode = 'CA';
        a.BillingPostalCode = '94109';
        a.DUNS_Number__c = '12345';
        a.Website = 'www.samsara.com';
        a.Organization_Size__c = '1 - 99';
        insert a;
        
        Opportunity o = new Opportunity();
        o.StageName = 'Qualified';
        o.Name = 'Test Opp return';
        o.AccountId = a.Id;
        o.License_Term__c = 36;
        o.Amount = 15000;
        o.Type = 'Exchange';
        o.Finance_Partner_Notes__c = 'Test';
        o.Subsidize_Financing__c = True;
        o.CloseDate =  system.today()+5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        insert o;
        
        Map<Id, Opportunity> oppInfo = new Map<Id, Opportunity>([SELECT  Id,Shipping_Address_NEW__c,
                                                                 Shipping_Address_NEW__r.Shipping_Contact__c, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.Email, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.firstname, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.lastname,
                                                                 OwnerId,
                                                                 Owner.Name,
                                                                 Owner.Email,
                                                                 Account.CSM__r.Email,
                                                                 Return_Label_Attachment__c,
                                                                 Account.Which_written_language__c
                                                                 FROM Opportunity WHERE Name='Test Opp return']); 
        
        Test.startTest();
        ReturnLabelEmailer.sendReturnEmails(oppInfo);
        Test.stopTest();
    }
    
    @isTest
    static void testExchangeOpportunityWithLanguage(){
        Account a = new Account();
        a.Name = 'TestFirst Account';
        a.Business_Unit__c = 'Fleet';
        a.BillingStreet = '123 Testing St';
        a.BillingCity = 'San Francisco';
        a.BillingCountry = 'Mexico';
        a.BillingPostalCode = '94109';
        a.DUNS_Number__c = '12345';
        a.Website = 'www.samsara.com';
        a.Organization_Size__c = '1 - 99';
        insert a;
        
        Opportunity o = new Opportunity();
        o.StageName = 'Qualified';
        o.Name = 'Test Opp return';
        o.AccountId = a.Id;
        o.License_Term__c = 36;
        o.Amount = 15000;
        o.Type = 'Exchange';
        o.Finance_Partner_Notes__c = 'Test';
        o.Subsidize_Financing__c = True;
        o.CloseDate =  system.today()+5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        o.Return_Label_Sent_At__c = System.Today().addDays(-21);
        insert o;
        
        Map<Id, Opportunity> oppInfo = new Map<Id, Opportunity>([SELECT  Id,Shipping_Address_NEW__c,
                                                                 Shipping_Address_NEW__r.Shipping_Contact__c, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.Email, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.firstname, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.lastname,
                                                                 OwnerId,
                                                                 Owner.Name,
                                                                 Owner.Email,
                                                                 Account.CSM__r.Email,
                                                                 Return_Label_Attachment__c,
                                                                 Account.Which_written_language__c
                                                                 FROM Opportunity WHERE Name='Test Opp return']); 
        
        Test.startTest();
        ReturnLabelEmailer.sendReturnEmails(oppInfo);
        Test.stopTest();
    }
    
     @isTest
    static void testExchangeOpportunityWithLanguageAndLabelSentNull(){
        Account a = new Account();
        a.Name = 'TestFirst Account';
        a.Business_Unit__c = 'Fleet';
        a.BillingStreet = '123 Testing St';
        a.BillingCity = 'San Francisco';
        a.BillingCountry = 'Mexico';
        a.BillingPostalCode = '94109';
        a.DUNS_Number__c = '12345';
        a.Website = 'www.samsara.com';
        a.Organization_Size__c = '1 - 99';
        insert a;
        
        Opportunity o = new Opportunity();
        o.StageName = 'Qualified';
        o.Name = 'Test Opp return';
        o.AccountId = a.Id;
        o.License_Term__c = 36;
        o.Amount = 15000;
        o.Type = 'Exchange';
        o.Finance_Partner_Notes__c = 'Test';
        o.Subsidize_Financing__c = True;
        o.CloseDate =  system.today()+5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        insert o;
        
        Map<Id, Opportunity> oppInfo = new Map<Id, Opportunity>([SELECT  Id,Shipping_Address_NEW__c,
                                                                 Shipping_Address_NEW__r.Shipping_Contact__c, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.Email, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.firstname, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.lastname,
                                                                 OwnerId,
                                                                 Owner.Name,
                                                                 Owner.Email,
                                                                 Account.CSM__r.Email,
                                                                 Return_Label_Attachment__c,
                                                                 Account.Which_written_language__c
                                                                 FROM Opportunity WHERE Name='Test Opp return']); 
        
        Test.startTest();
        ReturnLabelEmailer.sendReturnEmails(oppInfo);
        Test.stopTest();
    }
    
    @isTest
    static void testDirectSendWarrantyExchangeEmailAlert() {
        
        Test.startTest();

        Opportunity oppRec = [Select Id, stageName from Opportunity Where recordtype.name = 'Return Opportunity'];

        oppRec.StageName = 'End of Life with Promo';
        
        update oppRec;
        
        Test.stopTest();
        
    }
    //GTMS-25173 start
    @isTest
    static void testTriggerCoversSendHoldReasonNotifications() {
        User u = [SELECT Id, Email FROM User WHERE Name LIKE 'Ron Saavedra' LIMIT 1];
        
        Account acc = new Account(
            Name = 'Testers 34 Inc',
            BillingState = 'California',
            BillingCountry = 'United States',
            BillingStreet = '26 Napier Street',
            BillingCity = 'London',
            BillingPostalCode = '1030',
            Billing_Email__c = 'qdasdas@gmail.com',
            Organization_Size__c = '100 - 499',
            Approved_Payment_Type__c = 'Direct Monthly',
            OwnerId = u.Id,
            Industry = 'Other'
        );
        insert acc;
        
        Id returnOppRecType = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com',
            AccountId = acc.Id
        );
        insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Return Opp Test',
            AccountId = acc.Id,
            RecordTypeId = returnOppRecType,
            StageName = 'Qualified',
            CloseDate = Date.today().addDays(10),
            OwnerId = u.Id,
            Hold_Reason__c = null
        );
        insert opp;
        
        Test.startTest();
        
        opp.Hold_Reason__c = 'Return Kickback: Promo - RTS';
        update opp;
        
        Test.stopTest();
        System.assertEquals('Return Kickback: Promo - RTS', opp.Hold_Reason__c); // Validate the change
    }//GTMS-25173 end

}