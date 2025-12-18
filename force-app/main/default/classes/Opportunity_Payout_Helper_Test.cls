@IsTest
public class Opportunity_Payout_Helper_Test {
	@TestSetup
    static void setup(){
        
        Id partnerAccRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        Id fleetAccRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fleet').getRecordTypeId();
        Id partnerConRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        Id fleetConRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Fleet').getRecordTypeId();
        Id returnOpptyRecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Return_Opportunity').getRecordTypeId();
        Account partnerAccount = createAccount('Test Partner Account',partnerAccRecordTypeId);
        partnerAccount.Partner_Status__c = 'Transacting Partner';
        
        insert partnerAccount;
        
        
        Contact partnerContact = createContact(partnerAccount.Id, partnerConRecordTypeId);
        insert partnerContact;
        
        Account fleetAccount = createAccount('Test Fleet Account1', fleetAccRecordTypeId);
        Account fleetAccount2 = createAccount('Test Fleet Account2', fleetAccRecordTypeId);
        List<Account> accList = new List<Account>{fleetAccount,fleetAccount2};
        insert accList;
        
        Contact fleetContact = createContact(accList[0].Id, fleetConRecordTypeId);
        insert fleetContact;
        
        Partner_Program__c partnerProgram = createPartnerProgram();
        insert partnerProgram;
        
        Partner_Program_Enrollment__c programEnrollment = createProgramEnrollment(partnerProgram.Id, partnerAccount.Id, partnerContact.Id);
        insert programEnrollment;
        
        
        
        Opportunity scndOppty = createOpportunity('secndOppty',accList[0].Id,'Net 30');
        scndOppty.StageName = 'Closed Won';
        Opportunity sourceOppty = createOpportunity('sourceOppty',accList[0].Id,'Net 30');
        Opportunity scndAccSrcOppty = createOpportunity('scndAccSrcOppty',accList[1].Id,'Net 30');
        List<Opportunity> oppList = new List<Opportunity>{scndOppty,sourceOppty,scndAccSrcOppty};
        insert oppList;
        
        Channel_Relationship__c crRec2 = createCRRecord(oppList[0].Id, partnerAccount.id, accList[0].Id, partnerProgram.Id, programEnrollment.Id);
        crRec2.Partner_Payout__c = 100;
        crRec2.Is_Deal_Registration__c = true;
        crRec2.Partner_Interaction_Type__c = 'Partner Sourced';
        
        Channel_Relationship__c crRec = createCRRecord(oppList[1].Id, partnerAccount.id, accList[0].Id, partnerProgram.Id, programEnrollment.Id);
        
        Channel_Relationship__c scndAccSrcOpptyCr = createCRRecord(oppList[2].Id, partnerAccount.id, accList[1].Id, partnerProgram.Id, programEnrollment.Id);
        scndAccSrcOpptyCr.Partner_Payout__c = 100;
        scndAccSrcOpptyCr.Is_Deal_Registration__c = true;
        scndAccSrcOpptyCr.Partner_Interaction_Type__c = 'Partner Sourced';
        
        List<Channel_Relationship__c> crList = new List<Channel_Relationship__c>{crRec2, crRec, scndAccSrcOpptyCr};
        
        insert crList;
        
        Opportunity returnOppty = new Opportunity();
        returnOppty.Returning_Opportunity__c = crList[1].Opportunity__c;
        returnOppty.Referral_Partner__c = crList[1].Channel_partner__c;
        returnOppty.Stagename = 'Return Created';
        returnOppty.type = 'Rebate';
        returnOppty.RecordtypeId = returnOpptyRecordTypeId;
        returnOppty.Name = 'test return oppty';
        returnOppty.CloseDate = Date.today();
        returnOppty.CurrencyisoCode = 'EUR';
        
        Opportunity returnOppty2 = new Opportunity();
        returnOppty2.Returning_Opportunity__c = crList[2].Opportunity__c;
        returnOppty2.Referral_Partner__c = crList[2].Channel_partner__c;
        returnOppty2.Stagename = 'Return Created';
        returnOppty2.type = 'Rebate';
        returnOppty2.RecordtypeId = returnOpptyRecordTypeId;
        returnOppty2.Name = 'test return oppty2';
        returnOppty2.CloseDate = Date.today();
        returnOppty2.CurrencyIsoCode = 'EUR';
        
        List<Opportunity> returnOppList = new List<Opportunity>{returnOppty,returnOppty2};
        insert returnOppList;
        
        DatedConversionRate dcr = new DatedConversionRate();
        dcr.ConversionRate = 0.8999;
        dcr.IsoCode = 'EUR';
        dcr.StartDate = Date.Today();
        
        //insert dcr;
    }
	
    public static User createUser(string firstName, string lastName, string roleId, string profileId, string alias){
        User activeUser = new User(
                LastName = firstName,
                FirstName = lastName,
                Email = firstName+'.'+lastname+'@samsara.com',
                Username = firstName+'.'+lastname+'@samsara.com.test',
                ManagerId = UserInfo.getUserId(),
                UserRoleId = roleId,
                CompanyName = 'TEST',
                Title = 'title',
                Alias = alias,
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profileId,
                EmployeeNumber = 'abcdefg',
                IsActive = true   
        );
        return activeUser;
    }
    
    public static Account createAccount(String accountName, string recordTypeId){
        Account testAccount = new Account();
        testAccount.Name = accountName;
        testAccount.Industry = 'Biotechnology';
        testAccount.Organization_Size__c = '500 - 999';
        testAccount.BillingStreet = '123 main';
        testAccount.BillingCity = 'Missoula';
        testAccount.BillingState = 'California';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingPostalCode = '59801';
        testAccount.Billing_Email__c = 'foo@bar.com';
        testAccount.Approved_Payment_Type__c = 'Direct Monthly';
        testAccount.RecordTypeId = recordTypeId;
        testAccount.CurrencyIsoCode = 'EUR';
        return testAccount;
    }

    public static Contact createContact(Id accountId,string recordTypeId) {
        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = accountId;
        testContact.Source__c = 'Adwords';
        testContact.Email = 'test@test.com';
        testContact.recordTypeId = recordTypeId;
        return testContact;
    }
    /*
    public static Shipping_Address__c createShippingAddress(Id accountId, Id contactId) {
        Shipping_Address__c shippingAddress = new Shipping_Address__c();
        shippingAddress.Account__c = accountId;
        shippingAddress.Shipping_Contact__c = contactId;
        shippingAddress.Shipping_Address_Line_1__c = '111 Test Drive';
        shippingAddress.Shipping_City__c = 'Testington';
        shippingAddress.Shipping_Country__c = 'Canada';
        shippingAddress.Name = 'Test';

        return shippingAddress;
    }
    
    static Product2 createProduct(string name, string cCode, string code, string netSuiteId){
        Product2 prod = new Product2();
        prod.Name = name;
                prod.CurrencyIsoCode = cCode;
                prod.ProductCode = code;                                                       
                prod.netsuite_conn__NetSuite_Id__c = netSuiteId;
        return prod;
    }
    
    static PricebookEntry createPbe(string prodId){
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbeStandard = new PricebookEntry();
        pbeStandard.Pricebook2Id = pricebookId;
        pbeStandard.UnitPrice = 100;
        pbeStandard.Product2Id = prodId;
        pbeStandard.isActive = true;
        return pbeStandard;
    }
    */
    public static Opportunity createOpportunity(string oppName, Id accId, string pTerms){
         Opportunity opp = new Opportunity(
             Name = oppName, 
             StageName = 'Purchase',
             CloseDate = Date.today(),
             Custom_Schedule__c = false,
             Type = 'Revenue Opportunity',
             Is_Webstore_Upsell_Opportunity__c = false,
             SBQQ__Renewal__c = false,
             currencyIsoCode = 'EUR',
             Selected_Payment_Type__c = 'Upfront Payments',
             AccountId = accId,
             Payment_Terms__c = pTerms,
             Initial_Payment_Terms__c = pTerms
             
        );
        return Opp;
    }
    
     static SBQQ__Quote__c createQuote(string oppId, string accId,string currencyVal){
        
        SBQQ__Quote__c qte = new SBQQ__Quote__c();
        qte.Quote_Name__c = 'Test Quote';
        qte.SBQQ__Opportunity2__c = oppId;
        qte.SBQQ__Primary__c = true;
        qte.SBQQ__Status__c='Approved';
        qte.SBQQ__StartDate__c = Date.today();
        qte.SBQQ__EndDate__c = Date.today().addMonths(12);
        qte.CurrencyIsoCode = currencyVal;
        return qte;
    }
    /*
    static SBQQ__QuoteLine__c createQLI(string quoteId, string pbeId, string productId){
        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
        qli.SBQQ__Quote__c = quoteId;
        qli.SBQQ__PricebookEntryId__c = pbeId;
        qli.SBQQ__Quantity__c  = 5;
        qli.SBQQ__Discount__c = 0;
        qli.SBQQ__Product__c = productId;
        qli.SBQQ__ListPrice__c=100;
        
        return qli;
    }
	
    
    static Contract createContract(string fleetAccountId,string oppId, string quoteId){
        Contract Ctrct = new Contract();
        Ctrct.AccountId = fleetAccountId;
        Ctrct.StartDate = Date.today();
        Ctrct.EndDate = Date.today().adddays(365);
        Ctrct.ContractTerm = 12;
        ctrct.SBQQ__Opportunity__c = OppId;
        ctrct.SBQQ__Quote__c = quoteId;
        
        return ctrct;
    }
	
    
    static SBQQ__Subscription__c createSubscription(string contractId, string ProductId,string qliId){
         SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c();
            subscription1.SBQQ__QuoteLine__c=qliId;
            subscription1.SBQQ__Quantity__c = 1;
            subscription1.SBQQ__Product__c = ProductId;
            subscription1.SBQQ__Contract__c = contractId;
            subscription1.SBQQ__RenewalQuantity__c = -5;
			subscription1.SBQQ__NetPrice__c = 10;
            subscription1.SBQQ__SubscriptionStartDate__c = Date.today();
            subscription1.SBQQ__SubscriptionEndDate__c=Date.today().adddays(365);
            
        return subscription1;
    }
    */
    static Channel_Relationship__c createCRRecord(string OppId, string partnerAccId, string customerAccId, string programId, string enrollmentId){
        Channel_Relationship__c crRec = new Channel_Relationship__c();
        crRec.Channel_Partner__c = partnerAccId;
        crRec.Customer_Account__c = customerAccId;
        crRec.Is_Deal_Registration__c = true;
        crRec.Opportunity__c = oppId;
        crRec.Partner_Program__c = programId;
        crRec.Partner_Enrollment__c = enrollmentId;
        crRec.Partner_Payout__c = 0;
        return crRec;
    }
    
    static Partner_Program__c createPartnerProgram(){
        Partner_Program__c program = new Partner_Program__c();
        program.Name = 'Test Program';
        program.Allow_Enrollment__c = 'Yes';
        program.Approvals_Required__c = 'No';
        program.Program_Status__c = 'Active';
        program.Member_Review_Period__c = 'Evergreen';
        program.Sourced_Payout_Model__c = 'Percentage';
        program.Sourced_Payout_Percentage__c = 10;
        program.Sourced_Payout_Fee__c = 1000;
        program.Sourced_Payout_Cap__c = 75000;
        program.Influence_Payout_Model__c = 'Percentage';
        program.Influence_Payout_Percentage__c = 10;
        program.Influence_Payout_Fee__c = 500;
        program.Influence_Payout_Cap__c = 5000;
        program.Partner_Discount__c = 20;
        program.SalesProgramType__c = 'Paid Referral';
        return program;        
    }
    
    static Partner_Program_Enrollment__c createProgramEnrollment(string programId, string partnerAccId, string partnerConId){
        Partner_Program_Enrollment__c enrollment = new Partner_Program_Enrollment__c();
        enrollment.Partner_Program__c = programId;
        enrollment.Partner_Account__c = partnerAccId;
        enrollment.Partner_Contact__c = partnerConId;
        enrollment.Member_Status__c = 'Active';
        enrollment.Sourced_Payout_Model__c = 'Percentage';
        enrollment.Sourced_Payout_Percentage__c = 10;
        enrollment.Sourced_Payout_Fee__c = 1000;
        enrollment.Sourced_Payout_Cap__c = 75000;
        enrollment.Influence_Payout_Model__c = 'Percentage';
        enrollment.Influence_Payout_Percentage__c = 10;
        enrollment.Influence_Payout_Fee__c = 500;
        enrollment.Influence_Payout_Cap__c = 5000;
        enrollment.Program_Compensation_Model__c = 'Paid';
        enrollment.Rebate_Timeline_Eligibility__c = '1 Year';
        return enrollment;
    }
    
    
    @IsTest
    static void SourceOpptyTest(){
       
        
        Channel_Relationship__c cr = [SELECT Id,Opportunity__c,Partner_Payout__c,Partner_Sourced_Opportunity__c,Eligible_For_Payout__c,
                                         Influence_Payout_Fee__c,Influence_Payout_Model__c,Influence_Payout_Percentage__c,Sourced_Payout_Fee__c,
                                         Sourced_Payout_Model__c,Sourced_Payout_Percentage__c,Primary_Record__c,Channel_Partner__c,
                                         Partner_Program__c,Partner_Enrollment__c,Partner_Interaction_Type__c,Opportunity__r.AccountId,Opportunity__r.ACV_Bookings_SOT__c,
                                         Partner_Enrollment__r.Member_Status__c,Partner_Enrollment__r.Sourced_Payout_Cap__c,Partner_Enrollment__r.Sourced_Payout_Fee__c,
                                         Partner_Enrollment__r.Sourced_Payout_Model__c,  Partner_Enrollment__r.Influence_Payout_Cap__c,Calculate_Rebate_From__c,Partner_Enrollment__r.Rebate_Timeline_Eligibility__c,
                                         Partner_Enrollment__r.Influence_Payout_Fee__c, Partner_Enrollment__r.Influence_Payout_Model__c,Opportunity__r.Blended_Discount__c, 
                                         Channel_Partner__r.Partner_Status__c,Opportunity__r.Account.Latest_Active_Contract_End_Date__c,Customer_Account__c,Customer_Account__r.Latest_Active_Contract_End_Date__c,
                                         Opportunity__r.SBQQ__AmendedContract__c, Opportunity__r.SBQQ__Renewal__c,Partner_Program__r.Paid_for_new_business__c, Partner_Program__r.Paid_for_Add_Ons__c,
                                         Partner_Program__r.Paid_for_Renewals__c,Is_Deal_Registration__c, Opportunity__r.CloseDate,CreatedDate, Partner_Enrollment__r.Program_Compensation_Model__c,
                                         Opportunity_Currency__c, Opportunity_Currency_Conversion_Rate__c, Partner_Payout_In_Opportunity_Currency__c, Partner_Currency__c                                             
                                         FROM Channel_Relationship__c WHERE Customer_Account__r.Name = 'Test Fleet Account2' LIMIT 1];
        Id fleetAccRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fleet').getRecordTypeId();                              
        Account customerAcc = [SELECT Id, (SELECT Id,CloseDate 
                                                         FROM Opportunities 
                                                         WHERE Type = 'Revenue Opportunity'                                                         
                                                         Order By CloseDate ASC LIMIT 1)
                                                        FROM Account
                                                        WHERE 
                                                        REcordTypeId =: fleetAccRecordTypeId
                              							AND Name = 'Test Fleet Account2'];
		Opportunity sourceOppty = [SELECT Id,Name,stageName FROM Opportunity WHERE Type = 'Revenue Opportunity' AND Account.Name = 'Test Fleet Account2' and StageName != 'Closed Won' LIMIT 1];
        
        //sourceOppty.StageName = 'Closed Won';
		Test.StartTest();
        	//update sourceOppty;
        	Opportunity_Payout_Calculation_Helper.calculatePayout(new List<Id>{sourceOppty.Id});
        	Opportunity_Payout_Calculation_Helper.calculateAmendPayoutAndReason(cr,customerAcc,new Opportunity_Payout_Calculation_Helper.PayoutWrapper(0,0));
        	Opportunity_Payout_Calculation_Helper.calculateRenewalPayoutAndReason(cr,customerAcc,new Opportunity_Payout_Calculation_Helper.PayoutWrapper(0,0));
        	Opportunity_Payout_Calculation_Helper.fetchExistingPayoutValues(new Set<String>{cr.Customer_Account__c}, new Set<String>{cr.Channel_Partner__c}, new List<Id>());
        	Opportunity_Payout_Calculation_helper.updateRebateOpportunities(new List<Channel_Relationship__c>{cr}, new Map<Id,Channel_Relationship__c>{cr.Id => cr});
        Test.stopTest();
    }
    
    @IsTest
    static void InfluenceOpptyTest(){
       
        
        Channel_Relationship__c cr = [SELECT Id,Opportunity__c,Partner_Payout__c,Partner_Sourced_Opportunity__c,Eligible_For_Payout__c,
                                         Influence_Payout_Fee__c,Influence_Payout_Model__c,Influence_Payout_Percentage__c,Sourced_Payout_Fee__c,
                                         Sourced_Payout_Model__c,Sourced_Payout_Percentage__c,Primary_Record__c,Channel_Partner__c,
                                         Partner_Program__c,Partner_Enrollment__c,Partner_Interaction_Type__c,Opportunity__r.AccountId,Opportunity__r.ACV_Bookings_SOT__c,
                                         Partner_Enrollment__r.Member_Status__c,Partner_Enrollment__r.Sourced_Payout_Cap__c,Partner_Enrollment__r.Sourced_Payout_Fee__c,
                                         Partner_Enrollment__r.Sourced_Payout_Model__c,  Partner_Enrollment__r.Influence_Payout_Cap__c,Calculate_Rebate_From__c,Partner_Enrollment__r.Rebate_Timeline_Eligibility__c,
                                         Partner_Enrollment__r.Influence_Payout_Fee__c, Partner_Enrollment__r.Influence_Payout_Model__c,Opportunity__r.Blended_Discount__c, 
                                         Channel_Partner__r.Partner_Status__c,Opportunity__r.Account.Latest_Active_Contract_End_Date__c,Customer_Account__c,Customer_Account__r.Latest_Active_Contract_End_Date__c,
                                         Opportunity__r.SBQQ__AmendedContract__c, Opportunity__r.SBQQ__Renewal__c,Partner_Program__r.Paid_for_new_business__c, Partner_Program__r.Paid_for_Add_Ons__c,
                                         Partner_Program__r.Paid_for_Renewals__c,Is_Deal_Registration__c, Opportunity__r.CloseDate,CreatedDate, Partner_Enrollment__r.Program_Compensation_Model__c,
                                         Opportunity_Currency__c, Opportunity_Currency_Conversion_Rate__c, Partner_Payout_In_Opportunity_Currency__c, Partner_Currency__c                                             
                                         FROM Channel_Relationship__c WHERE Customer_Account__r.Name = 'Test Fleet Account1' LIMIT 1];
        Id fleetAccRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fleet').getRecordTypeId();                              
        Account customerAcc = [SELECT Id, (SELECT Id,CloseDate 
                                                         FROM Opportunities 
                                                         WHERE Type = 'Revenue Opportunity'                                                         
                                                         Order By CloseDate ASC LIMIT 1)
                                                        FROM Account
                                                        WHERE 
                                                        REcordTypeId =: fleetAccRecordTypeId
                              							AND Name = 'Test Fleet Account1'];
		Opportunity sourceOppty = [SELECT Id,Name,stageName FROM Opportunity WHERE Type = 'Revenue Opportunity' AND Account.Name = 'Test Fleet Account1' and StageName != 'Closed Won' LIMIT 1];
        //sourceOppty.StageName = 'Closed Won';
		Test.StartTest();
        	//update sourceOppty;
        	Opportunity_Payout_Calculation_Helper.calculatePayout(new List<Id>{sourceOppty.Id});
        	Opportunity_Payout_Calculation_Helper.calculateAmendPayoutAndReason(cr,customerAcc,new Opportunity_Payout_Calculation_Helper.PayoutWrapper(0,0));
        	Opportunity_Payout_Calculation_Helper.calculateRenewalPayoutAndReason(cr,customerAcc,new Opportunity_Payout_Calculation_Helper.PayoutWrapper(0,0));
        	Opportunity_Payout_Calculation_Helper.fetchExistingPayoutValues(new Set<String>{cr.Customer_Account__c}, new Set<String>{cr.Channel_Partner__c}, new List<Id>());
        	Opportunity_Payout_Calculation_helper.updateRebateOpportunities(new List<Channel_Relationship__c>{cr}, new Map<Id,Channel_Relationship__c>{cr.Id => cr});
        Test.stopTest();
    }
    
}