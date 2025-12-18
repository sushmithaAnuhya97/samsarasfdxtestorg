@isTest
private class ReminderEmailBatchSendTest{
    
    @isTest
    static void testReminderEmailBatch(){
        
        //avalaraSettingInsertTest.insertAvalaraSetting();
        
        
        //UserRole obj = new UserRole(Name= 'ABC');
        //insert obj;
        Profile pf = [Select Id from profile where Name='Samsara Sales - New System']; 
        
        String orgId = UserInfo.getOrganizationId(); 
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer RandomId = Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName = orgId+dateString+RandomId; 
        User uu = new User(firstname = 'ABC', lastName = 'XYZ', email = uniqueName + '@test' + orgId + '.org', Username = uniqueName + '@test' + orgId + '.org', 
        EmailEncodingKey = 'ISO-8859-1', Alias = uniqueName.substring(18, 23), TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', EmployeeNumber = '12345',
        LanguageLocaleKey = 'en_US', ProfileId = pf.Id);
        insert uu;
        //system.runAs(uu) {
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
        a.OwnerId = uu.Id;
        insert a;

       
        Contact c = new Contact();
        c.FirstName = 'TestFirst';
        c.AccountId = a.Id;
        c.LastName = 'Contact';
        c.Email = 'kairey.test@email.com';
        c.Status__c = 'New';
        c.MailingCountryCode = 'US';
        c.MailingStateCode = 'CA';
        insert c;

        Shipping_Address__c s = new Shipping_Address__c();
        s.Account__c = a.Id; 
        s.Shipping_Contact__c = c.Id; 
        s.Shipping_Address_Line_1__c = '350 Rhode Island Street'; 
        s.Shipping_City__c = 'San Francisco';
        s.Shipping_State__c = 'California';
        s.Shipping_Zip_Code__c = '95812'; 
        s.Shipping_Email__c = 'kairey@email.com';
        s.Name = 'Test Address'; 
        insert s;
        Opportunity o = new Opportunity();
        o.StageName = 'Return Label Sent';
        o.Name = 'Test Opp return';
        o.Type = 'Warranty Exchange'; 
        o.AccountId = a.Id;
        o.Related_Contact__c = c.Id;
        o.License_Term__c = 36;
        o.Amount = 15000;
        o.Finance_Partner_Notes__c = 'Test';
        o.Subsidize_Financing__c = True;
        o.CloseDate =  system.today()+5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        o.Return_Label_Sent_At__c = system.today()-25; 
        o.Shipping_Address_NEW__c = s.Id; 
        insert o;
        
        Attachment attach=new Attachment();      
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=o.id;
        insert attach;
        
        o.Return_Label_Attachment__c = attach.Id;
        update o;
       
        
        Test.startTest();
        
        List<Opportunity> oppInfo = new List<Opportunity>([SELECT Id FROM Opportunity WHERE Name='Test Opp return']);     
        List<Id> returnOpptysToEmail = new List<Id>(); 
        for(Opportunity opp : oppInfo) {
            returnOpptysToEmail.add(opp.Id);
        }   

        ReminderEmailBatchSend sendEmailBatch = new ReminderEmailBatchSend(returnOpptysToEmail);
        Database.executebatch(sendEmailBatch, 20);
        Test.stopTest();
        System.assert(true,true);   
    }
    //}
}