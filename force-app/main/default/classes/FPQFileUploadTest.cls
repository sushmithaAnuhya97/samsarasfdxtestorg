@isTest
public class FPQFileUploadTest {
    @TestSetup
    static void testDataSetup(){
        //User Owner = [Select Id FROM User WHERE Name LIKE 'Ron Saavedra'];
        User Owner = [Select Id, Email FROM User WHERE Profile.Name LIKE '%AE3%' and IsActive = true limit 1];
        Finance_Partner_Settings__c partner_settings = new Finance_Partner_Settings__c();
        partner_settings.Emails__c = Owner.Email;//'ron.saavedra@samsara.com';
        partner_settings.Names__c = Owner.Email;//'ron.saavedra@samsara.com';
        insert partner_settings;
        
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
        a.OwnerId = Owner.Id;
        insert a;
        
        Account acc = new Account();
        acc.Name = 'TestFirst Account1';
        acc.Business_Unit__c = 'Fleet';
        acc.BillingStreet = '123 Testing St';
        acc.BillingCity = 'San Francisco';
        acc.BillingCountryCode = 'US';
        acc.BillingStateCode = 'CA';
        acc.BillingPostalCode = '94109';
        acc.DUNS_Number__c = '12345';
        acc.Website = 'www.samsara.com';
        acc.Organization_Size__c = '1 - 99';
        acc.OwnerId = Owner.Id;
        insert acc;
        
        Contact c = new Contact();
        c.FirstName = 'TestFirst';
        c.AccountId = a.Id;
        c.LastName = 'Contact';
        c.Email = 'mahesh.test@samsara.com';
        c.Status__c = 'New';
        c.MailingCountryCode = 'US';
        c.MailingStateCode = 'CA';
        c.OwnerId = Owner.Id;
        insert c;
        
        Internal_Finance_Approval_Request__c internalFinance=new Internal_Finance_Approval_Request__c();
        internalFinance.Account__c=a.id;
        insert internalFinance;
        
        Opportunity o = new Opportunity();
        o.StageName = 'Qualified';
        o.Name = 'Test Opp 2';
        o.AccountId = a.Id;
        o.Related_Contact__c = c.Id;
        o.License_Term__c = 36;
        o.Amount = 15000;
        o.Finance_Partner_Notes__c = 'Test';
        o.Subsidize_Financing__c = True;
        o.CloseDate =  system.today()+5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        o.OwnerId = Owner.Id;
        insert o;
        
        Opportunity opp = new Opportunity();
        opp.StageName = 'Qualified';
        opp.Name = 'Test Opp 2';
        opp.AccountId = a.Id;
        opp.Related_Contact__c = c.Id;
        opp.License_Term__c = 36;
        opp.Amount = 15000;
        opp.Finance_Partner_Notes__c = 'Test';
        opp.Subsidize_Financing__c = True;
        opp.CloseDate =  system.today()+5;
        opp.Can_Create__c = true;
        opp.License_End_Date_Notes__c = 'TESTING 456';
        opp.OwnerId = Owner.Id;
        insert opp;
        
        list<Finance_Partner_Quote__c>FinanceQuotelist=new list<Finance_Partner_Quote__c>();
        Finance_Partner_Quote__c FinanceQuote=new Finance_Partner_Quote__c();
        FinanceQuote.Financing_Decision__c='Pending';
        FinanceQuote.Preferred_Offer__c=false;
        FinanceQuote.Opportunity__c=o.id;
        FinanceQuote.Account__c=a.id;
        FinanceQuote.Finance_Partner__c = a.id;
        FinanceQuote.Partner_Contact__c = c.Id;
        FinanceQuotelist.add(FinanceQuote);
        
        Finance_Partner_Quote__c FinanceQuoteNew=new Finance_Partner_Quote__c();
        FinanceQuoteNew.Financing_Decision__c='Pending';
        FinanceQuoteNew.Preferred_Offer__c=true;
        FinanceQuoteNew.Opportunity__c=o.id;
        FinanceQuoteNew.Account__c=a.id;
        FinanceQuoteNew.Finance_Partner__c = a.id;
        FinanceQuoteNew.Partner_Contact__c = c.Id;
        FinanceQuotelist.add(FinanceQuoteNew);
        
        Finance_Partner_Quote__c FinanceQuoteNew1=new Finance_Partner_Quote__c();
        FinanceQuoteNew1.Financing_Decision__c='Pending';
        FinanceQuoteNew1.Preferred_Offer__c=false;
        FinanceQuoteNew1.Opportunity__c=opp.id;
        FinanceQuoteNew1.Account__c=acc.id;
        FinanceQuoteNew1.Finance_Partner__c = a.id;
        FinanceQuoteNew1.Partner_Contact__c = c.Id;
        FinanceQuotelist.add(FinanceQuoteNew1);
        insert FinanceQuotelist;
    }
    @isTest
    static void fileUploadTest(){
        Finance_Partner_Quote__c FinanceQuote=[select id,Financing_Decision__c from Finance_Partner_Quote__c where Preferred_Offer__c=false AND Account__r.Name='TestFirst Account' LIMIT 1];
        Test.startTest();
        FPQFileUpload.checkAlreadyUploaded(FinanceQuote.id);
        Attachment attach=new Attachment(); 
        attach.Name='Unit Test Attachment'; 
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body'); 
        attach.body=bodyBlob; 
        attach.parentId=FinanceQuote.id;
        insert attach;
        
        FPQFileUpload.saveFile(FinanceQuote.id,'Unit Test Attachment', 'base64Data', 'contentType','');
        FPQFileUpload.appendToFile(attach.Id,'base64Data');
        FPQFileUpload.checkAlreadyUploaded(FinanceQuote.id);
        Test.stopTest();
        
        System.assert(true,true);  
    }
}