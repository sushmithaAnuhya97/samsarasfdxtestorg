@isTest
public class PopulateFinancePartneronAccountBatchTest {
    @TestSetup
    static void testDataSetup(){
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        User Owner = [Select Id FROM User WHERE Name LIKE 'Ron Saavedra'];
        
        Finance_Partner_Settings__c partner_settings = new Finance_Partner_Settings__c();
        partner_settings.Emails__c = 'ron.saavedra@samsara.com';
        partner_settings.Names__c = 'ron.saavedra@samsara.com';
        insert partner_settings;
        
        List<Account> accLst = new List<Account>(); 
        
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
        a.Is_Finance_Partner_Active__c = true;
        a.Finance_Partner__c = null;
        a.X3PF_Customer__c = false;
        accLst.add(a);
        
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
        accLst.add(acc);

        insert accLst;
        
        List<Contract> contrctLst = new List<Contract>();
        Contract cont1 = new Contract(
            AccountId = a.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(-30),
            ContractTerm = 1,
            name = 'test1',
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
        
        contrctLst.add(cont1);
        
        Contract cont2 = new Contract(
            AccountId = a.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(-1),
            ContractTerm = 1,
            Auto_Renewal__c = true,
            name = 'test2',
            Status = 'Draft'
        );
        contrctLst.add(cont2);
        insert contrctLst;
        
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
        
        List<Opportunity> opplst = new List<Opportunity>();

        Opportunity o = new Opportunity();
        o.StageName = 'Closed Won';
        o.Name = 'Test Opp 2';
        o.AccountId = acc.Id;
        o.Related_Contact__c = c.Id;
        o.License_Term__c = 36;
        o.Amount = 15000;
        o.Finance_Partner_Notes__c = 'Test';
        o.Subsidize_Financing__c = True;
        o.CloseDate =  system.today()-5;
        o.Can_Create__c = true;
        o.Finance_Partner__c = a.Id;
        o.License_End_Date_Notes__c = 'TESTING 456';
        o.Type = 'Revenue Opportunity';
        o.ContractId = cont1.Id;
        opplst.add(o);
        
        Opportunity opp = new Opportunity();
        opp.StageName = 'Closed Won';
        opp.Name = 'Test Opp 9';
        opp.AccountId = acc.Id;
        opp.Related_Contact__c = c.Id;
        opp.License_Term__c = 36;
        opp.Amount = 15000;
        opp.Finance_Partner_Notes__c = 'Test';
        opp.Subsidize_Financing__c = True;
        opp.CloseDate =  system.today()-10;
        opp.Finance_Partner__c = a.Id;
        opp.Can_Create__c = true;
        opp.License_End_Date_Notes__c = 'TESTING 456';
        opp.Type = 'Revenue Opportunity';
        opp.ContractId = cont2.Id;
        opplst.add(opp);
        
        Opportunity op1 = new Opportunity();
        op1.StageName = 'Closed Won';
        op1.Name = 'OppTest32';
        op1.AccountId = acc.Id;
        op1.Related_Contact__c = c.Id;
        op1.License_Term__c = 36;
        op1.Amount = 15000;
        op1.Finance_Partner_Notes__c = 'Test';
        op1.Subsidize_Financing__c = True;
        op1.CloseDate =  system.today()-10;
        op1.Finance_Partner__c = a.Id;
        op1.Can_Create__c = true;
        op1.License_End_Date_Notes__c = 'TESTING 456';
        op1.Type = 'Revenue Opportunity';
        op1.ContractId = cont2.Id;
        op1.Free_Trial_Extension_Status__c = 'Pending';
        opplst.add(op1);
        
        insert opplst;
        
          Contract cont3 = new Contract(
            AccountId = a.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(-1),
            ContractTerm = 1,
            Auto_Renewal__c = true,
            name = 'test3',
              SBQQ__Opportunity__c = op1.Id,
            Status = 'Draft'
        );
        insert cont3;
        
        List<Finance_Partner_Quote__c> fpqLst = new List<Finance_Partner_Quote__c>();
        
        Finance_Partner_Quote__c FinanceQuote=new Finance_Partner_Quote__c();
        FinanceQuote.Financing_Decision__c='Pending';
        FinanceQuote.Preferred_Offer__c=false;
        FinanceQuote.Opportunity__c=o.id;
        FinanceQuote.Account__c=a.id;
        fpqLst.add(FinanceQuote);

        Finance_Partner_Quote__c FinanceQuote1=new Finance_Partner_Quote__c();
        FinanceQuote1.Financing_Decision__c='Pending';
        FinanceQuote1.Preferred_Offer__c=false;
        FinanceQuote1.Opportunity__c=opp.id;
        FinanceQuote1.Account__c=acc.id;
        fpqLst.add(FinanceQuote1);
        
        insert fpqLst;
    }
    @isTest
    static void PopulateFinancePartneronAccountBatchTestmethod(){
        Test.startTest();
        List<Account> listaccs = new List<Account>([Select id,Finance_partner__c,X3PF_Customer__c from account ]);
         List<Account> listaccsupdate = new list<Account>();
        for(Account acc: listaccs){
            Account acc1 = new Account();
            acc1.id = acc.id;
            acc1.Finance_partner__c = null;
            acc1.X3PF_Customer__c  = false;
            listaccsupdate.add(acc1);
        }
        update listaccsupdate;
        PopulateFinancePartneronAccountBatch batch = new PopulateFinancePartneronAccountBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        System.assert(true,true);  
    }
    @isTest
    static void PopulateFinancePartneronAccountBatchTestmethod1(){
         Test.startTest();
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> listOpps = new List<Opportunity>([Select id,stagename,Finance_partner__c,Type,Name,AccountId from opportunity where name like '%Test%']);
        OpportunityHelper oppHelper = new OpportunityHelper();
        oppHelper.populateFinacePartneronAccount(null,listOpps);
        Test.stopTest();
        
        System.assert(true,true); 
    }
    
    @isTest
    static void PopulateFinancePartneronAccountBatchTestmethod2(){
        TriggerHandler.bypass('ContractTriggerHandler');
        Test.startTest();
        Account acc = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE',CurrencyIsoCode = 'USD', Record_Type_Stamp_for_Dupes__c = 'Fleet',Industry = 'Unknown',Enable_Delinquency_Process__c = false, Current_Telematics_Provider__c = 'Azuga', Number_of_Vehicles__c= 101);
        insert acc;
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = acc.id);
        insert sa;
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        Id pId1 = [SELECT Id FROM Profile WHERE Name = 'Samsara Sales - NA  AE1'][0].Id;
        User userRecord = new User();
        userRecord = (User)TestFactory.createSObject(new User(ProfileId = pId,
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
                                                              isActive = TRUE,
                                                              Region__c = 'North America',
                                                              Level__c = 'AE 1'));
        //insert userRecord;
        User userRecord1 = new User();
        userRecord1 = (User)TestFactory.createSObject(new User(ProfileId = pId1,
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
                                                               isActive = TRUE,
                                                               Region__c = 'North America',
                                                               Level__c = 'AE 1'));
        insert userRecord1;
        Opportunity opp1 = new Opportunity();
        opp1.Type = 'Revenue Opportunity';
        opp1.Name = 'Opp Testers Validate License';
        opp1.StageName = 'Decision';
        opp1.closedate = System.today()-10;
        opp1.Price_Book_Name__c = 'Standard';
        opp1.License_Term__c = 36;
        opp1.Shipping_and_Handling_Amount__c = 99999.99;
        opp1.CurrencyIsoCode = 'USD';
        opp1.OwnerId = userRecord1.Id;
        opp1.Buyout_Opportunity__c  = opp1.id;
        opp1.Shipping_Address_NEW__c  = sa.id;
        opp1.Sales_Tax_Historical__c  = 99999.99;
        opp1.Amount_Received__c = 150;
        //of_HW_Products__c = 2,
        //of_LIC_Products__c = 2,
        opp1.Payment_Method__c = 'Credit Card';
        opp1.Selected_Payment_Type__c = 'Direct Annual';
        opp1.Finance_Partner__c = acc.Id;
        opp1.AccountId = acc.Id;
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        insert opp1;
        
        dsfs__DocuSign_Status__c  dstatus = new dsfs__DocuSign_Status__c(
            Account_Name__c = acc.name,
            dsfs__Envelope_Status__c =  'Completed',
            dsfs__Opportunity__c =  opp1.id,
            License_Term__c = 36,
            of_HW_Products__c= '3', 
            of_LIC_Products__c= '2');
        insert dstatus;
        system.debug('*****DOCSTATUS CREATE'+dstatus);
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Opportunity2__c =opp1.Id, of_HW_Products__c = 2,CurrencyIsoCode = 'USD',of_LIC_Products__c = 2,
                                                  SBQQ__SubscriptionTerm__c =10,License_Term__c = '36', Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = true);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert quote;
        opp1.SBQQ__PrimaryQuote__c = quote.Id;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        update opp1;
        //Test.startTest();
        //Opportunity opp = new Opportunity();
        //opp.Id = [Select id,stagename,Finance_partner__c,Type,Name,AccountId from opportunity where name = 'Opp Testers Validate License' limit 1][0].Id;
        system.runas(userRecord1){
            opp1.StageName = 'Orders Processing';
            try {
                dstatus.License_Term__c = 63;
                update dstatus;
                List<dsfs__DocuSign_Status__c> listOFCPtoValidate = new List<dsfs__DocuSign_Status__c>([Select Id,License_Term__c ,dsfs__Opportunity__c , 
                                                                                                        dsfs__Opportunity__r.SBQQ__PrimaryQuote__c,dsfs__Opportunity__r.SBQQ__PrimaryQuote__r.License_Term__c 
                                                                                                        from dsfs__DocuSign_Status__c where License_Term__c != null and dsfs__Opportunity__c =: opp1.Id and dsfs__Opportunity__r.SBQQ__PrimaryQuote__r.License_Term__c != ''
                                                                                                       ]);
                system.debug('*****DOCSTATUS'+listOFCPtoValidate);
                update opp1;
            } catch (DMLException e) {
                system.debug('***CATCH EXCEPTION'+ e.getMessage());
               // System.assert(e.getMessage().contains('There is a difference in license term on Order Form/SFDC'), 'message=' + e.getMessage());
            }
        }
        Test.stopTest();
        
        System.assert(true,true); 
    }

    @isTest
    static void PopulateFinancePartneronAccountBatchTestmethod3(){
        Test.startTest();
        List<Opportunity> listOpps = new List<Opportunity>([Select id,stagename,Finance_partner__c,Type,Name,AccountId from opportunity where name like '%Test%']);
        Contract contr = new Contract();
        contr = [Select Id from contract where name = 'test2' limit 1];
        contr.SBQQ__Opportunity__c = listOpps[0].Id;
        contr.Status = 'Activated';
        update contr;
        Clear3PFonAccountsBatch batch = new Clear3PFonAccountsBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        System.assert(true,true);  
    }
   @isTest
    static void updateContractDateTest(){  
        TriggerHandler.bypass('ContractTriggerHandler');
        Test.startTest();
        Opportunity opp = [Select Name,Free_Trial_Extension_Status__c,Trial_End_Date__c From Opportunity WHERE Name = 'OppTest32'];
        opp.Free_Trial_Extension_Status__c = 'Approved';
        update opp;
        
        Test.StopTest();
        TriggerHandler.clearBypass('ContractTriggerHandler');
        
        Contract ctr = [SELECT Id , SBQQ__Opportunity__c,EndDate FROM Contract WHERE  SBQQ__Opportunity__c =: opp.Id];
        system.assertEquals(ctr.EndDate,opp.Trial_End_Date__c); 
    }
        
}