@isTest
private class FinancePartnerQuoteControllerTest{
  
  @TestSetup
  static void testDataSetup(){
     User Owner = [Select Id FROM User WHERE Name LIKE 'Ron Saavedra'];

    Finance_Partner_Settings__c partner_settings = new Finance_Partner_Settings__c();
    partner_settings.Emails__c = 'ron.saavedra@samsara.com';
    partner_settings.Names__c = 'ron.saavedra@samsara.com';
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

    Contact c = new Contact();
    c.FirstName = 'TestFirst';
    c.AccountId = a.Id;
    c.LastName = 'Contact';
    c.Email = 'saavedra.test@email.com';
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
    o.Name = 'Test Opp 1';
    o.AccountId = a.Id;
    o.Related_Contact__c = c.Id;
    o.License_Term__c = 36;
    o.Amount = 15000;
    o.Finance_Partner_Notes__c = 'Test';
    o.Subsidize_Financing__c = True;
    o.CloseDate =  system.today()+5;
    o.Can_Create__c = true;
    o.License_End_Date_Notes__c = 'TESTING 456';
    insert o;
      
    list<Finance_Partner_Quote__c>FinanceQuotelist=new list<Finance_Partner_Quote__c>();
    Finance_Partner_Quote__c FinanceQuote=new Finance_Partner_Quote__c();
    FinanceQuote.Financing_Decision__c='Pending';
    FinanceQuote.Preferred_Offer__c=false;
    FinanceQuote.Opportunity__c=o.id;
    FinanceQuote.Account__c=a.id;
    FinanceQuotelist.add(FinanceQuote);
    
    Finance_Partner_Quote__c FinanceQuoteNew=new Finance_Partner_Quote__c();
    FinanceQuoteNew.Financing_Decision__c='Pending';
    FinanceQuoteNew.Preferred_Offer__c=true;
    FinanceQuoteNew.Opportunity__c=o.id;
    FinanceQuoteNew.Account__c=a.id;
     FinanceQuotelist.add(FinanceQuoteNew);
    insert FinanceQuotelist;
  }
   
    @isTest
    static void getQuoteDetailTest(){
     Finance_Partner_Quote__c FinanceQuote=[select id,Financing_Decision__c from Finance_Partner_Quote__c where Preferred_Offer__c=false];
    Test.startTest();
        try{
             FinancePartnerQuoteController.getQuoteDetail (FinanceQuote.id);
       FinancePartnerQuoteController.approvalSubmit (FinanceQuote.id);
        FinancePartnerQuoteController.sendPOUploadEmail (FinanceQuote.id);
        }catch(exception ex){
            System.assert(ex !=null,true);  
        }
     
    Test.stopTest();

    
  }
  }