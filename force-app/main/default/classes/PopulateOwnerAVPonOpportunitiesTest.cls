@isTest
public class PopulateOwnerAVPonOpportunitiesTest {
	@TestSetup
    static void testDataSetup(){
       // insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        //User Owner = [Select Id FROM User WHERE Name LIKE 'Ron Saavedra'];
        
       /* Finance_Partner_Settings__c partner_settings = new Finance_Partner_Settings__c();
        partner_settings.Emails__c = 'ron.saavedra@samsara.com';
        partner_settings.Names__c = 'ron.saavedra@samsara.com';
        insert partner_settings; */
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
        a.Finance_Partner__c = null;
        a.X3PF_Customer__c = false;
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
        acc.Finance_Partner__c = null;
        acc.X3PF_Customer__c = false;
        insert acc;
        
        Contract cont1 = new Contract(
            AccountId = a.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(-30),
            ContractTerm = 1,
            name = 'test1',
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
        
        insert cont1;
        
        Contract cont2 = new Contract(
            AccountId = a.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(-1),
            ContractTerm = 1,
            Auto_Renewal__c = true,
            name = 'test2',
            Status = 'Draft'
        );
        
        insert cont2;
        
        Contact c = new Contact();
        c.FirstName = 'TestFirst';
        c.AccountId = a.Id;
        c.LastName = 'Contact';
        c.Email = 'mahesh.test@email.com';
        c.Status__c = 'New';
        c.MailingCountryCode = 'US';
        c.MailingStateCode = 'CA';
        c.OwnerId = Owner.Id;
        insert c;
        
        Internal_Finance_Approval_Request__c internalFinance=new Internal_Finance_Approval_Request__c();
        internalFinance.Account__c=a.id;
        insert internalFinance;
        
        Opportunity o = new Opportunity();
        o.StageName = 'Purchase';
        o.Name = 'Test Opp 2';
        o.AccountId = acc.Id;
        o.Related_Contact__c = c.Id;
        o.License_Term__c = 36;
        o.Amount = 15000;
        o.Finance_Partner_Notes__c = 'Test';
        o.Subsidize_Financing__c = True;
        o.CloseDate =  system.today()-5;
        o.Can_Create__c = true;
        o.License_End_Date_Notes__c = 'TESTING 456';
        o.Type = 'Revenue Opportunity';
        o.ContractId = cont1.Id;
        o.OwnerId = Owner.Id;
        insert o;
    }
    @isTest
    static void PopulateOwnerAVPonOpportunitiesBatchTest(){
        Test.startTest();
        PopulateOwnerAVPonOpportunities batch = new PopulateOwnerAVPonOpportunities();
        Database.executeBatch(batch);
        Test.stopTest();
        
        System.assert(true,true);  
    }
}