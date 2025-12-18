@isTest
private class GS_OpportunitySendEmailTests {
    @TestSetup
    static void setup(){
        GS_GlobalAutomationSettingsTest.createAutomationTestSetting();
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
        
        //Alekya
        // Assign the PermissionSet to the user
        /*PermissionSet validationRuleExemptionPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'Validation Rule Exemption' LIMIT 1];
        
        PermissionSetAssignment permAssign = new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = validationRuleExemptionPermSet.Id
        );
        insert permAssign; */
        
        a.CSM__c = u.Id;
        a.SIC__c = u.Id;
        update a;
        
        Contact c = new Contact();
        c.FirstName = 'TestFirst';
        c.AccountId = a.Id;
        c.LastName = 'Contact';
        c.Email = 'saavedra.test@email.com';
        c.Status__c = 'New';
        c.MailingCountryCode = 'US';
        c.MailingStateCode = 'CA';
        insert c;
        
        Shipping_Address__c sh= new Shipping_Address__c();
        sh.Account__c=a.Id;
        sh.Shipping_Contact__c = c.Id;
        sh.Shipping_Address_Line_1__c='Test Line';
        sh.Shipping_City__c='Test City';
        sh.Shipping_State__c='Ontario';
        sh.Shipping_Country__c='Canada';
        sh.Shipping_Zip_Code__c='879231';
        sh.Name='Test CAN';
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
        
        o.Resend_Return_Email__c = true;
        o.Shipping_Country__c = 'Canada';
        update o;
        
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
        
        //Test.startTest();
        
        (new GS_OpportunitySendEmailAsync()).execute(new Async_Request__c( 
            Params__c = o.Id+';',
            Options__c = JSON.serialize(new GS_OpportunitySendEmailAsync.Options('SEND_RETURN_EMAIL_OPERATIONS'))
        ));
        
        Opportunity oppInfo = [SELECT  Id,Shipping_Address_NEW__c,
                               Return_Label_Attachment__c,
                               Account.Which_written_language__c
                               FROM Opportunity WHERE Name='Test Opp return'];
        
        system.assertEquals(attach.Id+','+attach2.Id, oppInfo.Return_Label_Attachment__c);
        Test.stopTest();
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
        
        o.Resend_Return_Email__c = true;
        o.StageName = 'Return Label Sent';
        update o;
        
        
        
        Test.startTest();
        (new GS_OpportunitySendEmailAsync()).execute(new Async_Request__c( 
            Params__c = o.Id+';',
            Options__c = JSON.serialize(new GS_OpportunitySendEmailAsync.Options('SEND_RETURN_EMAIL_OPERATIONS'))
        ));
        
        Opportunity oppInfo = [SELECT  Id,Shipping_Address_NEW__c,
                               Return_Label_Attachment__c,
                               Account.Which_written_language__c
                               FROM Opportunity WHERE Name='Test Opp return'];
        
        
        Test.stopTest();
    }
    
    @isTest
    static void testRemorseRefundOpportunity(){
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
        o.Type = 'Remorse Refund';
        o.CloseDate =  system.today()+5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        o.Return_Label_Sent_At__c = System.Today().addDays(-21);
        insert o;
        
        
        o.Resend_Return_Email__c = true;
        o.Shipping_Country__c = 'Canada';
        update o;
        
        
        
        Test.startTest();
        (new GS_OpportunitySendEmailAsync()).execute(new Async_Request__c( 
            Params__c = o.Id+';',
            Options__c = JSON.serialize(new GS_OpportunitySendEmailAsync.Options('SEND_RETURN_EMAIL_OPERATIONS'))
        ));
        Test.stopTest();
    }
    
    @isTest
    static void testWarrantyExchangOpportunity(){
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
        o.Type = 'Remorse Refund';
        o.CloseDate =  system.today()+5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        o.Return_Label_Sent_At__c = System.Today().addDays(-21);
        insert o;
        
        
        
        Test.startTest();
        (new GS_OpportunitySendEmailAsync()).execute(new Async_Request__c( 
            Params__c = o.Id+';',
            Options__c = JSON.serialize(new GS_OpportunitySendEmailAsync.Options('SEND_RETURN_EMAIL_OPERATIONS'))
        ));
        Test.stopTest();
    }
    
    //Alekya
    @isTest
    static void testSendReturnLabelEmail() {
        
        // Create an Account
        Account a = new Account();
        a.Name = 'Test Account';
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
        
        // Create a Contact
        Contact c = new Contact();
        c.FirstName = 'TestFirst';
        c.AccountId = a.Id;
        c.LastName = 'Contact';
        c.Email = 'saavedra.test@email.com';
        c.Status__c = 'New';
        c.MailingCountryCode = 'US';
        c.MailingStateCode = 'CA';
        insert c;
        
        // Create a Shipping Address
        Shipping_Address__c sh = new Shipping_Address__c();
        sh.Account__c = a.Id;
        sh.Shipping_Contact__c = c.Id;
        sh.Shipping_Address_Line_1__c = 'Test Line';
        sh.Shipping_City__c = 'Test City';
        sh.Shipping_State__c = 'Ontario';
        sh.Shipping_Country__c = 'Canada';
        sh.Shipping_Zip_Code__c = '879231';
        sh.Name = 'Test CAN';
        insert sh;
        
        
        // Create an Opportunity with necessary fields
        Opportunity o = new Opportunity();
        o.StageName = 'Qualified';
        o.Name = 'Test Opp return';
        o.AccountId = a.Id;
        o.Related_Contact__c = c.Id;
        o.License_Term__c = 36;
        o.Amount = 15000;
        o.Shipping_Address_NEW__c = sh.Id;
        o.Type = 'Exchange';
        o.Finance_Partner_Notes__c = 'Test';
        o.Subsidize_Financing__c = true;
        o.CloseDate = system.today() + 5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        o.Return_Label_Sent_At__c = System.Today().addDays(-21);
        o.StageName = 'Return Label Sent';
        insert o;
        
        // Create old map for comparison
        Map<Id, Opportunity> oldOpportunityMap = new Map<Id, Opportunity>([SELECT Id, StageName, Return_Label_Attachment__c, Resend_Return_Email__c 
                                                                           FROM Opportunity WHERE Id = :o.Id]);
        
        // Update the Opportunity to meet the criteria for sending a return label email
        o.Return_Label_Attachment__c = null;
        o.Resend_Return_Email__c = true;
        o.Tracking_Number__c = '1Z12345';
        update o;
        
        // Test: Call the method to test
        Test.startTest();
        GS_OpportunitySendEmailAsync sendEmailAsync = new GS_OpportunitySendEmailAsync();
        sendEmailAsync.sendReturnLabelEmail(oldOpportunityMap, new List<Opportunity>{o});
        Test.stopTest();
    }
    
}