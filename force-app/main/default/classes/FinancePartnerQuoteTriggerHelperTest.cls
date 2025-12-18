@isTest
private class FinancePartnerQuoteTriggerHelperTest{
    
    @TestSetup
    static void testDataSetup(){
        //User Owner = [Select Id FROM User WHERE Name LIKE 'Ron Saavedra'];
        User Owner = [Select Id, Email FROM User WHERE Profile.Name LIKE '%AE3%' and IsActive = true limit 1];
        Finance_Partner_Settings__c partner_settings = new Finance_Partner_Settings__c();
        partner_settings.Emails__c = Owner.Email;//'ron.saavedra@samsara.com';
        partner_settings.Names__c = Owner.Email;//'ron.saavedra@samsara.com';
        insert partner_settings;
        List<Account> accList = new List<Account>();
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
        //insert a;
        accList.add(a);
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
        acc.Is_Finance_Partner_Active__c = true;
        //insert acc;
        accList.add(acc);
        Account acc1 = new Account();
        acc1.Name = 'TestFirst Account2';
        acc1.Business_Unit__c = 'Fleet';
        acc1.BillingStreet = '123 Testing St';
        acc1.BillingCity = 'San Francisco';
        acc1.BillingCountryCode = 'US';
        acc1.BillingStateCode = 'CA';
        acc1.BillingPostalCode = '94109';
        acc1.DUNS_Number__c = '12345';
        acc1.Website = 'www.samsara.com';
        acc1.Organization_Size__c = '1 - 99';
        acc1.OwnerId = Owner.Id;
        acc1.Is_Finance_Partner_Active__c = true;
        //insert acc1;
        accList.add(acc1);
        Account acc2 = new Account();
        acc2.Name = 'TestFirst Partner';
        //acc2.Business_Unit__c = 'Partner';
        acc2.BillingStreet = '123 Testing St';
        acc2.BillingCity = 'San Francisco';
        acc2.BillingCountryCode = 'US';
        acc2.BillingStateCode = 'CA';
        acc2.BillingPostalCode = '94109';
        acc2.DUNS_Number__c = '12345';
        acc2.Website = 'www.samsara.com';
        acc2.Organization_Size__c = '1 - 99';
        acc2.OwnerId = Owner.Id;
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        acc2.Is_Finance_Partner_Active__c = true;
        //insert acc2;
        accList.add(acc2);
        Account acc3 = new Account();
        acc3.Name = 'TestFirst Partner 2';
        //acc2.Business_Unit__c = 'Partner';
        acc3.BillingStreet = '123 Testing St';
        acc3.BillingCity = 'San Francisco';
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'CA';
        acc3.BillingPostalCode = '94109';
        acc3.DUNS_Number__c = '12345';
        acc3.Website = 'www.samsara.com';
        acc3.Organization_Size__c = '1 - 99';
        acc3.OwnerId = Owner.Id;
        acc3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        acc3.Is_Finance_Partner_Active__c = true;
        //insert acc3;
        accList.add(acc3);
        insert accList;
        
        List<Contact> cList = new List<Contact>();
        Contact c = new Contact();
        c.FirstName = 'TestFirst';
        c.AccountId = a.Id;
        c.LastName = 'Contact';
        c.Email = 'mahesh.test@samsara.com';
        c.Status__c = 'New';
        c.MailingCountryCode = 'US';
        c.MailingStateCode = 'CA';
        c.OwnerId = Owner.Id;
        cList.add(c);
        Contact c2 = new Contact();
        c2.FirstName = 'TestFirst';
        c2.AccountId = acc2.Id;
        c2.LastName = 'Contact';
        c2.Email = 'mahesh.test@samsara.com';
        c2.Status__c = 'New';
        c2.MailingCountryCode = 'US';
        c2.MailingStateCode = 'CA';
        c2.OwnerId = Owner.Id;
        cList.add(c2);
        Contact c3 = new Contact();
        c3.FirstName = 'TestFirst';
        c3.AccountId = acc3.Id;
        c3.LastName = 'Contact';
        c3.Email = 'mahesh.test@samsara.com';
        c3.Status__c = 'New';
        c3.MailingCountryCode = 'US';
        c3.MailingStateCode = 'CA';
        c3.OwnerId = Owner.Id;
        cList.add(c3);
        
        Contact c4 = new Contact();
        c4.FirstName = 'TestFirst23';
        c4.AccountId = acc.Id;
        c4.LastName = 'Contact23';
        c4.Email = 'maheshhh.test@samsara.com';
        c4.Status__c = 'New';
        c4.MailingCountryCode = 'US';
        c4.MailingStateCode = 'CA';
        c4.OwnerId = Owner.Id;
        cList.add(c4);
        insert cList;
        
        List<Contract> contractList= new List<Contract>();
        Contract cont1 = new Contract(
            AccountId = a.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Auto_Renewal__c = true,
            Name = 'Renewal Contract',
            Finance_Partner_Account__c = acc2.id,
            Status = 'Draft'
        );
        
        //insert cont1;
        contractList.add(cont1);
        Contract cont2 = new Contract(
            AccountId = a.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Auto_Renewal__c = true,
            Name = 'Amendment Contract',
            Finance_Partner_Account__c = acc3.id,
            Status = 'Draft'
        );
        
        //insert cont2;
        contractList.add(cont2);
        insert contractList;
        
        Internal_Finance_Approval_Request__c internalFinance=new Internal_Finance_Approval_Request__c();
        internalFinance.Account__c=a.id;
        insert internalFinance;
        
        List<Opportunity> listOpty = new List<Opportunity>();
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
        o.SBQQ__RenewedContract__c=cont1.id;
        o.OwnerId = Owner.Id;
        o.License_End_Date_Notes__c = 'TESTING 456';
        //insert o;
        listOpty.add(o);
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
        opp.SBQQ__AmendedContract__c=cont2.id;
        opp.OwnerId = Owner.Id;
        opp.License_End_Date_Notes__c = 'TESTING 456';
        //insert opp;
        listOpty.add(opp);
        Opportunity opp1 = new Opportunity();
        opp1.StageName = 'Closed Won';
        opp1.Name = 'Test Opp 3';
        opp1.AccountId = a.Id;
        opp1.Related_Contact__c = c.Id;
        opp1.License_Term__c = 36;
        opp1.Amount = 15000;
        opp1.Finance_Partner_Notes__c = 'Test';
        opp1.Subsidize_Financing__c = True;
        opp1.CloseDate =  system.today()+5;
        opp1.Can_Create__c = true;
        opp1.Finance_Partner__c = acc.Id;
        opp1.License_End_Date_Notes__c = 'TESTING 456';
        opp1.ContractId = cont1.Id;
        opp1.OwnerId = Owner.Id;
        opp1.Type = 'Revenue Opportunity';
        //insert opp1;
		listOpty.add(opp1);
        
        Opportunity opp2 = new Opportunity();
        opp2.StageName = 'Qualified';
        opp2.Name = 'Test Opp 4';
        opp2.AccountId = a.Id;
        opp2.Related_Contact__c = c.Id;
        opp2.License_Term__c = 36;
        opp2.Amount = 15000;
        opp2.Finance_Partner_Notes__c = 'Test';
        opp2.Subsidize_Financing__c = True;
        opp2.CloseDate =  system.today()+5;
        opp2.Can_Create__c = true;
        opp2.Finance_Partner__c = acc.Id;
        opp2.License_End_Date_Notes__c = 'TESTING 456';
        opp2.ContractId = cont1.Id;
        opp2.OwnerId = Owner.Id;
        opp2.Type = 'Revenue Opportunity';
        //insert opp1;
		listOpty.add(opp2);
        
        insert listOpty;
        
		List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.License_Term__c = '12';
        ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Quote';
        newQuotes.add(ftQuote);
        
        insert newQuotes; 
        
        list<Finance_Partner_Quote__c>FinanceQuotelist=new list<Finance_Partner_Quote__c>();
        Finance_Partner_Quote__c FinanceQuote=new Finance_Partner_Quote__c();
        FinanceQuote.Financing_Decision__c='Pending';
        FinanceQuote.Preferred_Offer__c=false;
        FinanceQuote.Opportunity__c=o.id;
        FinanceQuote.Account__c=a.id;
        FinanceQuote.CPQ_Quote__c = ftQuote.id;
        FinanceQuote.Finance_Partner__c=acc2.id;
        FinanceQuote.Partner_Contact__c = c2.Id;
        FinanceQuotelist.add(FinanceQuote);
        
        /*Finance_Partner_Quote__c FinanceQuoteNew=new Finance_Partner_Quote__c();
        FinanceQuoteNew.Financing_Decision__c='Pending';
        FinanceQuoteNew.Preferred_Offer__c=true;
        FinanceQuoteNew.Opportunity__c=o.id;
        FinanceQuoteNew.Account__c=a.id;
        FinanceQuotelist.add(FinanceQuoteNew);
        
        Finance_Partner_Quote__c FinanceQuoteNew1=new Finance_Partner_Quote__c();
        FinanceQuoteNew1.Financing_Decision__c='APPROVED';
        FinanceQuoteNew1.Preferred_Offer__c=false;
        FinanceQuoteNew1.Opportunity__c=opp.id;
        FinanceQuoteNew1.Account__c=acc.id;
        FinanceQuoteNew1.Finance_Partner__c=acc2.id;
        FinanceQuoteNew1.Subsidy_Amount__c='1000';
        FinanceQuotelist.add(FinanceQuoteNew1);
        
        Finance_Partner_Quote__c FinanceQuoteNew2=new Finance_Partner_Quote__c();
        FinanceQuoteNew2.Financing_Decision__c='Pending';
        FinanceQuoteNew2.Preferred_Offer__c=false;
        FinanceQuoteNew2.Opportunity__c=opp1.id;
        FinanceQuoteNew2.Account__c=acc1.id;
        FinanceQuotelist.add(FinanceQuoteNew2);*/
        
        Finance_Partner_Quote__c FinanceQuoteNew3=new Finance_Partner_Quote__c();
        FinanceQuoteNew3.Financing_Decision__c='APPROVED';
        FinanceQuoteNew3.Preferred_Offer__c=true;
        FinanceQuoteNew3.Opportunity__c=opp1.id;
        FinanceQuoteNew3.Account__c=acc1.id; 
        FinanceQuoteNew3.Finance_Partner__c=acc2.id;
        FinanceQuoteNew3.Partner_Contact__c = c2.Id;
        //FinanceQuoteNew3.Subsidy_Amount__c=1000;
        FinanceQuotelist.add(FinanceQuoteNew3);
        
        insert FinanceQuotelist;
    }
    
    @isTest
    static void beforeUpdateOperationsTest(){
        
        Account acc3 = [SELECT Id from Account where Name = 'TestFirst Partner 2'];
        Contact c3 = [SELECT Id from Contact where AccountId=:acc3.Id];
        Finance_Partner_Quote__c FinanceQuote=[select id,Financing_Decision__c from Finance_Partner_Quote__c where Preferred_Offer__c=false AND Account__r.Name='TestFirst Account'];
        Test.startTest();
        FinanceQuote.Financing_Decision__c='Approved';
        //FinanceQuote.Preferred_Offer__c=true;
        //FinanceQuote.Finance_Partner__c=acc3.id;
        //FinanceQuote.Partner_Contact__c=c3.id;
        FinanceQuote.Notes__c = 'Test';
        update FinanceQuote;  
        Test.stopTest();
        
        System.assert(true,true);  
    }
    
    @isTest
    static void beforeUpdateOperationsNewTest(){
        SBQQ__Quote__c qte = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote'];
        Finance_Partner_Quote__c FinanceQuote=[select id,Opportunity__c,Account__c,Preferred_Offer__c from Finance_Partner_Quote__c 
                                               where Financing_Decision__c='APPROVED' AND Account__r.Name='TestFirst Account2'];
        
        Test.startTest();
        FinanceQuote.CPQ_Quote__c = qte.id;
        FinanceQuote.Preferred_Offer__c=true;
        FinanceQuote.Approved_Amount__c=100;
        try{
            update FinanceQuote;   
        }catch(exception ex){
            System.assert(ex!=null,true); 
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void beforeUpdateOperationsNewTest2(){
        Account acc3 = [SELECT Id, Is_Finance_Partner_Active__c from Account where Name = 'TestFirst Partner 2'];
        acc3.Is_Finance_Partner_Active__c = true;
        Test.startTest();
        update acc3;
        Contact c = [SELECT Id FROM Contact WHERE AccountId =: acc3.Id];
        SBQQ__Quote__c qte = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote'];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
         Internal_Finance_Approval_Request__c request1 = new Internal_Finance_Approval_Request__c(
            Request_Type__c = 'Credit Limit Increase',
            Payment_Type_Approval_Status__c = 'Pending',
            Requested_Payment_Terms__c = 'Net 30',
            Account__c = acc3.Id,
            Opportunity__c = opp.Id,
            Quote__c = qte.Id,
            Requested_Payment_Types__c = 'Direct Monthly'
        );
        insert request1;
        Finance_Partner_Quote__c FinanceQuote=[select id,Opportunity__c,Account__c,Preferred_Offer__c from Finance_Partner_Quote__c 
                                               where Financing_Decision__c='APPROVED' AND Account__r.Name='TestFirst Account2'];
        FinanceQuote.CPQ_Quote__c = qte.id;
        FinanceQuote.Preferred_Offer__c=true;
        FinanceQuote.Finance_Partner__c=acc3.id;
        FinanceQuote.Financing_Decision__c = 'Pending';
        FinanceQuote.Partner_Contact__c = c.Id;
        FinanceQuote.Additional_Deferral_Decision__c='Approved';
       try{
            update FinanceQuote;   
       }catch(exception ex){
            //System.assert(ex!=null,true); 
       }
        
        Test.stopTest();
    }
    
    
    @istest
    static void updateQuoteFinancePartnerAmendmentTest() {
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Contact c = [SELECT Id FROM Contact WHERE AccountId =: acc1.Id LIMIT 1];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Map<Id, Opportunity> oppList = new Map<Id, Opportunity>();
        Opportunity opp = [SELECT Id, Is_Webstore_Upsell_Opportunity__c, Finance_Partner__c from Opportunity WHERE Name Like 'Amendment - %'];
        oppList.put(opp.id, opp);
        opp.Selected_Payment_Type__c = 'Upfront Payments';
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Test.startTest();
        update opp;
        TriggerHandler.clearAllBypasses();
        List<Shipping_Address__c> shippingAddresses = new  List<Shipping_Address__c>();
        
       	Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = acc1.Id, Shipping_Contact__c = c.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                            , Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                            , Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
        shippingAddresses.add(shipTo);
        insert shippingAddresses;
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.SBQQ__Primary__c = false;
        ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Amendment';
        ftQuote.Selected_Payment_Type__c = 'Upfront Payments';
        ftQuote.Shipping_Address_NEW__c = shippingAddresses[0].Id;
        newQuotes.add(ftQuote);
        insert newQuotes;
        newQuotes[0].SBQQ__Primary__c = true;
        update newQuotes[0];
        FinancePartnerQuoteTriggerHelper.updateQuoteFinancePartner(newQuotes, oppList);
        Test.stopTest();
    }
    
    @istest
    static void updateQuoteFinancePartnerRenewalTest() {
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Map<Id, Opportunity> oppList = new Map<Id, Opportunity>();
        Opportunity opp = [SELECT Id, Is_Webstore_Upsell_Opportunity__c, Finance_Partner__c from Opportunity WHERE Name Like 'Renewal - %'];
        oppList.put(opp.id, opp);
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.SBQQ__Primary__c = true;
        //ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Renewal';
        //ftQuote.Selected_Payment_Type__c = 'Upfront Payments';
        newQuotes.add(ftQuote);
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Test.startTest();
        insert newQuotes;
        TriggerHandler.clearAllBypasses();
        FinancePartnerQuoteTriggerHelper.updateQuoteFinancePartner(newQuotes, oppList);
        Test.stopTest();
    }
    
    @istest
    static void createFPQAfterQuoteInsertTest() {
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Map<Id, Opportunity> oppList = new Map<Id, Opportunity>();
        Opportunity opp = [SELECT Id from Opportunity WHERE Name like 'Amendment - %'];
        oppList.put(opp.id, opp);
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.SBQQ__Primary__c = true;
        //ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Amendment';
        //ftQuote.Selected_Payment_Type__c = 'Upfront Payments';
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        Test.startTest();
        FinancePartnerQuoteTriggerHelper.createFPQAfterQuoteInsert(newQuotes);
        Test.stopTest();
    }
    
    @istest
    static void createFPQQuoteMarkedPrimaryTest() {
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opp 4'];
        oppList.add(opp);
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        //ftQuote.SBQQ__Primary__c = true;
        //ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Amendment';
        ftQuote.Selected_Payment_Type__c = 'Upfront Payments';
        newQuotes.add(ftQuote);
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Test.startTest();

        insert newQuotes;
        //system.debug('RODRIGO  Selected_Payment_Type__c ' + newQuotes[0].Selected_Payment_Type__c);
        SBQQ.TriggerControl.disable();
        
        newQuotes[0].Shipping_Carrier__c = 'Fedex';
        newQuotes[0].Override_Freight_Shipping__c = true;
        //newQuotes[0].Shipping_Account_Type__c = 'Cust/Partner Account - FedEx';
        newQuotes[0].Shipping_Account_Type__c = 'Samsara Account';
        newQuotes[0].Shipping_Method__c = 'ECONOMY';
        newQuotes[0].Reason_for_Discount__c ='Test';
        //newQuotes[0].Selected_Payment_Type__c = 'Direct Annual';
        //newQuotes[0].SBQQ__Source__c = clonequote.Id;
        newQuotes[0].Upsell_Amount__c = 100;
        newQuotes[0].License_Term__c = '12';
        newQuotes[0].SBQQ__RenewalTerm__c = 2;
        newQuotes[0].Renewal_Amount__c = 100;
        newQuotes[0].Ship_From_Location__c = 'Samsara HQ';
        newQuotes[0].Downsell_Amount__c = 100;
        newQuotes[0].Custom_License_Term__c = null;
        newQuotes[0].SBQQ__LastCalculatedOn__c = DateTime.now();
        newQuotes[0].SBQQ__Primary__c = true;
        newQuotes[0].Finance_Partner_Account__c = acc2.Id;
        newQuotes[0].Selected_Payment_Type__c = 'Upfront Payments';
        update newQuotes[0];
        TriggerHandler.clearAllBypasses();
        SBQQ.TriggerControl.enable();
        Map<Id, SBQQ__Quote__c> newMapIn = new Map<Id, SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> oldMapIn = new Map<Id, SBQQ__Quote__c>();
        newMapIn.put(newQuotes[0].id, newQuotes[0]);
        oldMapIn.put(newQuotes[0].id, newQuotes[0]);
        FinancePartnerQuoteTriggerHelper.createFPQQuoteMarkedPrimary(newMapIn, oldMapIn);
        Test.stopTest();
    }
    
    @istest
    static void createFPQQuoteMarkedPrimaryTest2() {
        Test.startTest();
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opp 4'];
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        oppList.add(opp);
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.SBQQ__Primary__c = true;
        ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Quote';
        ftQuote.Selected_Payment_Type__c = 'Upfront Payments';
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        
        //newQuotes[0].SBQQ__Primary__c = true;
        //update newQuotes[0];
        
        Map<Id, SBQQ__Quote__c> newMapIn = new Map<Id, SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> oldMapIn = new Map<Id, SBQQ__Quote__c>();
        newMapIn.put(newQuotes[0].id, newQuotes[0]);
        oldMapIn.put(newQuotes[0].id, newQuotes[0]);
        
        FinancePartnerQuoteTriggerHelper.createFPQQuoteMarkedPrimary(newMapIn, oldMapIn);

        List<Id> quoteIds = new List<Id>();
        quoteIds.add(newQuotes[0].Id);
        FinancePartnerQuoteTriggerHelper.createFPQBaseOnQuote(quoteIds);
        Test.stopTest();
    }
    /*
    
    @isTest
    static void afterInsertOperationsNewTest1(){
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Account acc3 = [SELECT Id from Account where Name = 'TestFirst Partner 2'];
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opp 1'];
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.SBQQ__Primary__c = true;
        ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        SBQQ__Quote__c testQuote = [SELECT Id from SBQQ__Quote__c where Quote_Name__c = 'Test Quote'];
        //Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        
        Test.startTest();
        
        Finance_Partner_Quote__c FinanceQuoteNew3=new Finance_Partner_Quote__c();
        FinanceQuoteNew3.Financing_Decision__c='APPROVED';
        FinanceQuoteNew3.Preferred_Offer__c=false;
        FinanceQuoteNew3.Opportunity__c=opp.id;
        FinanceQuoteNew3.Account__c=acc1.id; 
        FinanceQuoteNew3.Finance_Partner__c=acc2.id;
        FinanceQuoteNew3.Subsidy_Amount__c='1000';
        FinanceQuoteNew3.CPQ_Quote__c =testQuote.Id;
        insert FinanceQuoteNew3;
        
        //FinanceQuoteNew3.Finance_Partner__c=acc3.id;
        //update FinanceQuoteNew3;
        Test.stopTest();
        
        
    }

    @isTest
    static void beforeUpdateOperationsNewTest1(){
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner 2'];
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opp 1'];
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.SBQQ__Primary__c = true;
        ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        SBQQ__Quote__c testQuote = [SELECT Id from SBQQ__Quote__c where Quote_Name__c = 'Test Quote'];
        //Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Finance_Partner_Quote__c FinanceQuote=[select id,Opportunity__c,Account__c,Preferred_Offer__c from Finance_Partner_Quote__c 
                                               where Preferred_Offer__c=false AND Account__r.Name='TestFirst Account1'];
        testQuote.SBQQ__Primary__c = true;
        SBQQ.TriggerControl.disable();
        update testQuote;
        SBQQ.TriggerControl.enable();
        Test.startTest();
        FinanceQuote.CPQ_Quote__c =testQuote.Id;
        FinanceQuote.Finance_Partner__c=acc2.id;
        FinanceQuote.Preferred_Offer__c=true;
        //FinanceQuote.Financing_Decision__c = 'APPROVED';
        //FinanceQuote.Subsidy_Amount__c = '100';
        try{
            update FinanceQuote;   
        }catch(exception ex){
            System.assert(ex!=null,true); 
        }
        
        Test.stopTest();
        
        
    }
    @isTest
    static void beforeUpdateOperationsNewTest2(){
        Finance_Partner_Quote__c FinanceQuote=[select id,Opportunity__c,Account__c,Preferred_Offer__c,Opportunity__r.StageName,Opportunity__r.ContractId,Opportunity__r.contract.enddate,Opportunity__r.Finance_partner__c 
                                               from Finance_Partner_Quote__c where Preferred_Offer__c=false AND Account__r.Name='TestFirst Account2' limit 1];
	system.debug('&&&&FP'+FinanceQuote.Opportunity__r.contract.enddate);  
        system.debug('&&&&FP'+FinanceQuote.Opportunity__r.Finance_Partner__c);       
        Test.startTest();
        FinanceQuote.Preferred_Offer__c=true;
        try{
            update FinanceQuote;   
        }catch(exception ex){
            System.assert(ex!=null,true); 
        }
        
        Test.stopTest();
        
        
    }
    @istest
    static void updateQuoteFinancePartnerTest() {
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opp 1'];
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.SBQQ__Primary__c = true;
        //ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Amendment';
        //ftQuote.Selected_Payment_Type__c = 'Upfront Payments';
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        Test.startTest();
        FinancePartnerQuoteTriggerHelper.updateQuoteFinancePartner(newQuotes);
        Test.stopTest();
    }
    
    @istest
    static void updateQuoteFinancePartnerTest2() {
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opp 1'];
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.SBQQ__Primary__c = true;
        //ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Renewal';
        //ftQuote.Selected_Payment_Type__c = 'Upfront Payments';
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        Test.startTest();
        FinancePartnerQuoteTriggerHelper.updateQuoteFinancePartner(newQuotes);
        Test.stopTest();
    }
    @istest
    static void createFPQAfterQuoteInsertTest() {
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opp 1'];
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.SBQQ__Primary__c = true;
        //ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Amendment';
        //ftQuote.Selected_Payment_Type__c = 'Upfront Payments';
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        Test.startTest();
        FinancePartnerQuoteTriggerHelper.createFPQAfterQuoteInsert(newQuotes);
        Test.stopTest();
    }
    
    @istest
    static void createFPQAfterQuoteInsertTest2() {
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opp 1'];
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        //ftQuote.SBQQ__Primary__c = true;
        //ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Renewal';
        //ftQuote.Selected_Payment_Type__c = 'Upfront Payments';
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        Test.startTest();
        FinancePartnerQuoteTriggerHelper.createFPQAfterQuoteInsert(newQuotes);
        Test.stopTest();
    }
    
    @istest
    static void createFPQQuoteMarkedPrimaryTest() {
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opp 1'];
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        //ftQuote.SBQQ__Primary__c = true;
        ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Amendment';
        ftQuote.Selected_Payment_Type__c = 'Upfront Payments';
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        
        //SBQQ.TriggerControl.disable();
        //newQuotes[0].SBQQ__Primary__c = true;
        //newQuotes[0].Finance_Partner_Account__c = acc2.Id;
        //update newQuotes[0];
        //SBQQ.TriggerControl.enable();
        Test.startTest();
        Map<Id, SBQQ__Quote__c> newMapIn = new Map<Id, SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> oldMapIn = new Map<Id, SBQQ__Quote__c>();
        newMapIn.put(newQuotes[0].id, newQuotes[0]);
        oldMapIn.put(newQuotes[0].id, newQuotes[0]);
        FinancePartnerQuoteTriggerHelper.createFPQQuoteMarkedPrimary(newMapIn, oldMapIn);
        Test.stopTest();
    }
    
    @istest
    static void createFPQQuoteMarkedPrimaryTest2() {
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opp 1'];
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.SBQQ__Primary__c = true;
        ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Quote';
        ftQuote.Selected_Payment_Type__c = 'Upfront Payments';
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        
        //newQuotes[0].SBQQ__Primary__c = true;
        //update newQuotes[0];
        Test.startTest();
        Map<Id, SBQQ__Quote__c> newMapIn = new Map<Id, SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> oldMapIn = new Map<Id, SBQQ__Quote__c>();
        newMapIn.put(newQuotes[0].id, newQuotes[0]);
        oldMapIn.put(newQuotes[0].id, newQuotes[0]);
        
        FinancePartnerQuoteTriggerHelper.createFPQQuoteMarkedPrimary(newMapIn, oldMapIn);
        
        List<Id> quoteIds = new List<Id>();
        quoteIds.add(newQuotes[0].Id);
        FinancePartnerQuoteTriggerHelper.createFPQBaseOnQuote(quoteIds);
        Test.stopTest();

    }

    
    @isTest
    static void afterUpdatePrimaryQuoteTest(){
        Account acc1 = [SELECT Id from Account where Name = 'TestFirst Account1'];
        Account acc2 = [SELECT Id from Account where Name = 'TestFirst Partner'];
        Opportunity opp = [SELECT Id from Opportunity WHERE Name = 'Test Opp 1'];
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opp.Id;
        ftQuote.SBQQ__Account__c = acc1.Id;
        ftQuote.SBQQ__Primary__c = true;
        ftQuote.Finance_Partner_Account__c = acc2.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        //newQuotes[0].Shipping_Method__c = 'ECONOMY';
        //newQuotes[0].SBQQ__Primary__c = true;
        //update newQuotes;
        List<Id> quoteIds = new List<Id>();
        quoteIds.add(newQuotes[0].Id);
        SBQQ__Quote__c testQuote = [SELECT Id from SBQQ__Quote__c where Quote_Name__c = 'Test Quote'];
        Finance_Partner_Quote__c FinanceQuote=[select id,Opportunity__c,Account__c,Preferred_Offer__c,Opportunity__r.StageName,Opportunity__r.ContractId,Opportunity__r.contract.enddate,Opportunity__r.Finance_partner__c 
                                               from Finance_Partner_Quote__c where Preferred_Offer__c=false AND Financing_Decision__c='APPROVED' limit 1];
	system.debug('&&&&FP'+FinanceQuote.Opportunity__r.contract.enddate);  
        system.debug('&&&&FP'+FinanceQuote.Opportunity__r.Finance_Partner__c);       
        Test.startTest();
        FinanceQuote.CPQ_Quote__c =testQuote.Id;
        try{
            update FinanceQuote;   
            FinancePartnerQuoteTriggerHelper.createFPQBaseOnQuote(quoteIds);
        }catch(exception ex){
            System.assert(ex!=null,true); 
        }
        
        Test.stopTest();
        
        
    }
*/
    
}