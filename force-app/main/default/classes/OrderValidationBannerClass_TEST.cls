@isTest
public class OrderValidationBannerClass_TEST {
	@TestSetup
    static void setup(){
        
        User ae2User;
        User entUser;
        List<Opportunity> oppList = new List<Opportunity>();
        List<Account> accList = new List<Account>();
        List<Contact> conList = new List<Contact>();
        List<SBQQ__Quote__c> qteList = new List<SBQQ__Quote__c>();
        List<Shipping_Address__c> sAddressList = new List<Shipping_Address__c>();
        
        User currentUser = [SELECT Id,name FROM User WHERE Id=:userInfo.getuserId()];
        system.runAs(currentUser){
            Id profileId = [SELECT Id,Name  FROM Profile WHERE Name LIKE '%AE2%' LIMIT 1].Id;
            Id ae2Role = [SELECT Id,Name FROM UserRole WHERE name LIKE '%AE2%' LIMIT 1].Id;
            
            ae2User = OrderValidationServiceAutomationTest.createUser('AE2','Sales1',ae2Role,profileId,'AE2usr');
            
            insert ae2User;
            
            Id entRole = [SELECT Id,Name FROM UserRole WHERE name LIKE '%FLEET ENT AE%' LIMIT 1].Id;
            
            entUser = OrderValidationServiceAutomationTest.createUser('ENT','Sales2',entRole,profileId,'ENTusr');
            
            insert entUser;
    	}
        /*
        Account usdTestAcc = createAccount('USDTestAccount', ae2User.Id,'USD');
        accList.add(usdTestAcc);
        Account mxnTestAcc = createAccount('MXNTestAccount', ae2User.Id,'MXN');
        accList.add(mxnTestAcc);
        Account EURTestAcc = createAccount('EURTestAccount', ae2User.Id,'EUR');
        accList.add(EURTestAcc);
        Insert accList;
        
        Contact usdCon = createContact(accList[0].Id);
        conList.add(usdCon);
		Contact mxnCon = createContact(accList[1].Id);
        conList.add(mxnCon);
        Contact eurCon = createContact(accList[2].Id);
        conList.add(eurCon);
        insert conList;
        
        Shipping_Address__c usdshpngAddrs= createShippingAddress(accList[0].Id, conList[0].Id);
        sAddressList.add(usdshpngAddrs);
        Shipping_Address__c mxnShpngAddrs= createShippingAddress(accList[1].Id, conList[1].Id);
        sAddressList.add(mxnShpngAddrs);
        Shipping_Address__c eurShpngAddrs= createShippingAddress(accList[2].Id, conList[2].Id);
        sAddressList.add(eurShpngAddrs);
        insert sAddressList;
        
       
        
        opportunity testopp = createOpportunity('testOppty',accList[0].Id,ae2User.Id, 'Due In Advance','Upfront Payments',sAddressList[0].Id, false,'USD');
        //testOpp.Shipping_Address_NEW__c = shpngAddrs.Id;
        oppList.add(testOpp);
        
        opportunity upFrntTestOpp = createOpportunity('upFrntTestOppty',accList[0].Id, ae2User.Id,'Due In Advance','Upfront Payments',sAddressList[0].Id, false,'USD');
        
        oppList.add(upFrntTestOpp);
        
        //opportunity dmSpTestOpp = createOpportunity('dmSpTestOppty',testAcc.Id, ae2User.Id,'Due In Advance','Direct Monthly',shpngAddrs.Id, false,'USD');
        
        //oppList.add(dmSpTestOpp);
        
        //opportunity daSpTestOpp = createOpportunity('daSpTestOppty',testAcc.Id, ae2User.Id,'Due In Advance','Direct Annual',shpngAddrs.Id, false,'USD');
        
        //oppList.add(daSpTestOpp);
        
        opportunity daMXNTestOpp = createOpportunity('daMXNTestOppty',accList[1].Id, ae2User.Id,'Due In Advance','Direct Annual',sAddressList[1].Id, false,'MXN');
        oppList.add(daMXNTestOpp);
        
		//opportunity dmMXNTestOpp = createOpportunity('dmMXNTestOppty',testAcc.Id, ae2User.Id,'Due In Advance','Direct Monthly',shpngAddrs.Id, false,'MXN');
        //oppList.add(dmMXNTestOpp);

		//opportunity upMXNTestOpp = createOpportunity('upMXNTestOppty',testAcc.Id, ae2User.Id,'Due In Advance','Upfront Payments',shpngAddrs.Id, false,'MXN');
        //oppList.add(upMXNTestOpp);
        
        opportunity netTermsTestOpp = createOpportunity('netTermsTestOppty',accList[0].Id, ae2User.Id,null,'Direct Annual',sAddressList[0].Id, false,'USD');
        netTermsTestOpp.Amount_Received__c = null;
        oppList.add(netTermsTestOpp);
        
        opportunity uroTestOpp = createOpportunity('eurTestOppty',accList[2].Id, ae2User.Id,null,'Direct Annual',sAddressList[2].Id, false,'EUR');
        uroTestOpp.Amount_Received__c = null;
        oppList.add(uroTestOpp);
        
        insert oppList;
        
        SBQQ__Quote__c testqte = createQuote(oppList[0].Id,accList[0].Id,'USD');
        qteList.add(testQte);
        
        SBQQ__Quote__c upFrntTestQte = createQuote(oppList[1].Id,accList[0].Id,'USD');
        qteList.add(upFrntTestQte);
        
        //SBQQ__Quote__c dmSpTestQte = createQuote(oppList[2].Id,testAcc.Id,'USD');
        //qteList.add(dmSpTestQte);
        
        //SBQQ__Quote__c daSpTestQte = createQuote(oppList[3].Id,testAcc.Id,'USD');
        //qteList.add(daSpTestQte);
        
        SBQQ__Quote__c daMXNTestQte = createQuote(oppList[2].Id,accList[1].Id,'MXN');
        qteList.add(daMXNTestQte);
        
        //SBQQ__Quote__c dmMXNTestQte = createQuote(oppList[5].Id,testAcc.Id,'MXN');
        //qteList.add(dmMXNTestQte);
        
        //SBQQ__Quote__c upMXNTestQte = createQuote(oppList[6].Id,testAcc.Id,'MXN');
        //qteList.add(upMXNTestQte);
        
        SBQQ__Quote__c netTermsTestQte = createQuote(oppList[3].Id,accList[0].Id,'USD');
        qteList.add(netTermsTestQte);
        
        SBQQ__Quote__c eurTestQte = createQuote(oppList[4].Id,accList[2].Id,'EUR');
        qteList.add(eurTestQte);
        
        
        insert qteList;
        
		*/
        
        
    }
    
    public static Account createAccount(String accountName, string paymentType, string userId, string currencyVal){
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
     	testAccount.ownerid = userId;
        testAccount.CurrencyIsoCode = currencyVal;
        testAccount.Approved_Payment_Type__c = paymentType;
        return testAccount;
    }
    
    
    
    public static Contact createContact(Id accountId) {
        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = accountId;
        testContact.Source__c = 'Adwords';
        testContact.Email = 'test@test.com';
        return testContact;
    }
    
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
    
    public static Opportunity createOpportunity(string oppName, Id accId, string ownerId, string pTerms,string paymentType,Id sAddress, boolean isCamera, String currencyVal){
 		Opportunity opp = new Opportunity(
             Name = oppName, 
             StageName = 'Purchase',
             CloseDate = Date.today(),
             Custom_Schedule__c = false,
             Type = 'Revenue Opportunity',
             Is_Webstore_Upsell_Opportunity__c = false,
             SBQQ__Renewal__c = false,
             Selected_Payment_Type__c = paymentType,
            License_Term__c = 24,
             AccountId = accId,
             Payment_Terms__c = pTerms,
             Initial_Payment_Terms__c = pTerms,
             OwnerId = ownerId,
             Price_Book_Name__c = 'Standard',
             Shipping_and_Handling_Amount__c = 99999.99,
             Shipping_Address_NEW__c  = sAddress,
             Amount_Received__c = 150,
             Payment_Method__c = 'Credit Card',
              Camera_Only_Deal__c = isCamera,
              Free_Trial_Purchase__c = 'Full Buy',
            CurrencyIsoCode = currencyVal
        );        
        return Opp;
    }
    
    static void createFiles(string recId){
        
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body to be insert in test class for testing the'); 
            
            ContentVersion contentVersion_1 = new ContentVersion(
                Title='SampleTitle', 
                PathOnClient ='SampleTitle.jpg',
                VersionData = bodyBlob, 
                origin = 'H'
            );
            insert contentVersion_1;
            
            ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId 
                            FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
            
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId = recId;
            contentlink.contentdocumentid = contentVersion_2.contentdocumentid;
            contentlink.ShareType = 'V';
            insert contentlink;
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
    
    static Product2 createProduct(string name, string cCode, string code, string netSuiteId){
        Product2 newProduct = (Product2) TestFactory.createSObject(new Product2(Name = name,
                CurrencyIsoCode = cCode,
                ProductCode = code,
                netsuite_conn__NetSuite_Id__c = netSuiteId), false);
        return newProduct;
    }
    
    static PricebookEntry createdPbe(Product2 newProduct){
        PricebookEntry pbeStandard = (PricebookEntry) TestFactory.createSObject(new PricebookEntry(
                UnitPrice = 0,
                Product2Id = newProduct.Id
        ), false);
        return pbeStandard;
    }
    
    static Id createDocusign(string oppId){
        dsfs__DocuSign_Status__c dRec = new dsfs__DocuSign_Status__c();
        dRec.dsfs__Subject__c = 'Test REcord';
        dRec.dsfs__Envelope_Status__c = 'Completed';
        dRec.dsfs__Opportunity__c = oppId;
        dRec.Next_Recurring_Bill_Date__c = Date.Today() + 10;
        
        insert dRec;
        
        //createFiles(dRec.Id);
        
        return dRec.Id;
    }
    
    @IsTest
    static void ofKBTest0(){
        User aeUser = [SELECT Id,Name FROM User WHERE alias = 'AE2Usr'];
        
         OrderValidationServiceAutomationTest.createOVASetting(true,aeUser.Id,false);
        
        Account testAcc = createAccount('USDTestAccount','Upfront Payments', aeUser.Id,'USD');
        Insert testAcc;
        
        Contact usdCon = createContact(testAcc.Id);
        insert usdCon;
        
        Shipping_Address__c usdshpngAddrs= createShippingAddress(testAcc.Id, usdCon.Id);
        insert usdshpngAddrs;
        
        opportunity testopp = createOpportunity('testOppty',testAcc.Id,aeUser.Id, 'Due In Advance','Upfront Payments',usdshpngAddrs.Id, false,'USD');
        Insert testOpp;
        //Opportunity testopp = [SELECT Id,AccountId,SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = 'testOppty'];
        
       	SBQQ__Quote__c cpqQuote = createQuote(testOpp.Id,testOpp.AccountId,'USD');
        insert cpqQuote;
        
        Opportunity oppRecrd = new Opportunity();
        oppRecrd.Alternative_Cable_Selection__c = true;
        oppRecrd.Free_Trial_Purchase__c = 'Full Buy';
        oppRecrd.Id = testOpp.Id;
        oppRecrd.Initial_Payment_Terms__c = 'Due In Advance';
        Test.startTest();
        
        SBQQ__Quote__c qte = new SBQQ__Quote__c();
        qte.Id = cpqQuote.Id;
        qte.SBQQ__Status__c = 'Approved';
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        update qte;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        
        update oppRecrd;
        
		//createDocusign (oppRecrd.id);       
        OrderValidationBannerClass.showBannerDetails(testOpp.Id);
        Test.stopTest();
    }
    
   @IsTest
    static void ofKBTest1(){
        User aeUser = [SELECT Id,Name FROM User WHERE alias = 'AE2Usr'];
        
         OrderValidationServiceAutomationTest.createOVASetting(true,aeUser.Id,false);
        
        Account testAcc = createAccount('USDTestAccount','Upfront Payments', aeUser.Id,'USD');
        testAcc.New_Billing_Process_Approved__c = true;
        Insert testAcc;
        
        Contact usdCon = createContact(testAcc.Id);
        insert usdCon;
        
        Shipping_Address__c usdshpngAddrs= createShippingAddress(testAcc.Id, usdCon.Id);
        insert usdshpngAddrs;
        
        opportunity testopp = createOpportunity('testOppty',testAcc.Id,aeUser.Id, 'Due In Advance','Upfront Payments',usdshpngAddrs.Id, false,'USD');
        testOpp.CurrencyIsoCode = 'USD';
        testOpp.Amount = 10000;
        testOpp.Sales_Tax_Amount__c = 1000;
        testOpp.Amount_Received__c = null;
        Insert testOpp;
        
       	SBQQ__Quote__c cpqQuote = createQuote(testOpp.Id,testOpp.AccountId,'USD');
        cpqQuote.CurrencyIsoCode = 'EUR';
        cpqQuote.SBQQ__Status__c = 'Pending';
        insert cpqQuote;
        
        Opportunity oppRecrd = new Opportunity();
        oppRecrd.Alternative_Cable_Selection__c = true;
        oppRecrd.Free_Trial_Purchase__c = 'Full Buy';
        oppRecrd.Id = testOpp.Id;
        Test.startTest();
        
        SBQQ__Quote__c qte = new SBQQ__Quote__c();
        qte.Id = cpqQuote.Id;
        qte.SBQQ__Status__c = 'Approved';
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        update qte;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        
        update oppRecrd;
        
        Id docId = createDocusign(oppRecrd.id);
        createFiles(docId);
        
        dsfs__DocuSign_Status__c docusign = [SELECT Id, dsfs__Envelope_Status__c, dsfs__Opportunity__c, 
                                            Billing_Company_Name__c, Customer_Preferred_Payment_Method__c, 
                                            Selected_Payment_Type__c, Payment_Terms__c, License_Term__c, 
                                            Opp_Currency__c, Sales_Tax_Amount__c, Shipping_And_Handling__c,
                                            of_HW_Products__c, of_LIC_Products__c, Total_Hardware_Due__c, 
                                            Total_License_Due__c,
                                            Total_License_Cost__c FROM dsfs__DocuSign_Status__c 
                                            WHERE Id = :docId];
        
        OrderValidationBannerClass.kbValidations(testOpp, docusign, 1);
        
        // Test the close date validation logic to cover lines 523-531
        // Create a new GBP opportunity to test the else if block for GBP/EUR currencies (lines 526-530)
        Account gbpAcc = createAccount('GBPTestAccount','Upfront Payments', aeUser.Id,'GBP');
        Insert gbpAcc;
        
        Contact gbpCon = createContact(gbpAcc.Id);
        insert gbpCon;
        
        Shipping_Address__c gbpShpngAddrs = createShippingAddress(gbpAcc.Id, gbpCon.Id);
        insert gbpShpngAddrs;
        
        Opportunity gbpOpp = createOpportunity('gbpTestOppty',gbpAcc.Id,aeUser.Id, 'Due In Advance','Upfront Payments',gbpShpngAddrs.Id, false,'GBP');
        gbpOpp.CloseDate = Date.today().addDays(1);
        Insert gbpOpp;
        
        SBQQ__Quote__c gbpQuote = createQuote(gbpOpp.Id,gbpAcc.Id,'GBP');
        insert gbpQuote;
        
        // Create DocuSign for GBP opportunity
        Id gbpDocId = createDocusign(gbpOpp.id);
        
        // Query the GBP DocuSign record
        dsfs__DocuSign_Status__c gbpDocusign = [SELECT Id, dsfs__Envelope_Status__c, dsfs__Opportunity__c, 
                                            Billing_Company_Name__c, Customer_Preferred_Payment_Method__c, 
                                            Selected_Payment_Type__c, Payment_Terms__c, License_Term__c, 
                                            Opp_Currency__c, Sales_Tax_Amount__c, Shipping_And_Handling__c,
                                            of_HW_Products__c, of_LIC_Products__c, Total_Hardware_Due__c, 
                                            Total_License_Due__c, 
                                            Total_License_Cost__c
                                                FROM dsfs__DocuSign_Status__c WHERE Id = :gbpDocId];
        
        // Call kbValidations to trigger the GBP/EUR currency logic (lines 526-530)
        OrderValidationBannerClass.kbValidations(gbpOpp, gbpDocusign, 1);
        
        OrderValidationBannerClass.showBannerDetails(testOpp.Id);
        Test.stopTest();
    }
    
   @IsTest
    static void ofKBTest2(){
        User aeUser = [SELECT Id,Name FROM User WHERE alias = 'AE2Usr'];
        
         OrderValidationServiceAutomationTest.createOVASetting(true,aeUser.Id,false);
        
        Account testAcc = createAccount('USDTestAccount','Upfront Payments', aeUser.Id,'USD');
        Insert testAcc;
        
        Contact usdCon = createContact(testAcc.Id);
        insert usdCon;
        
        Shipping_Address__c usdshpngAddrs= createShippingAddress(testAcc.Id, usdCon.Id);
        insert usdshpngAddrs;
        
        opportunity testopp = createOpportunity('testOppty',testAcc.Id,aeUser.Id, 'Due In Advance','Upfront Payments',usdshpngAddrs.Id, false,'USD');
        testOpp.CurrencyIsoCode = 'USD';
        testOpp.Amount = 10000;
        testOpp.Sales_Tax_Amount__c = 1000;
        testOpp.Amount_Received__c = null;
        Insert testOpp;
        
       	SBQQ__Quote__c cpqQuote = createQuote(testOpp.Id,testOpp.AccountId,'USD');
        cpqQuote.CurrencyIsoCode = 'USD';
        cpqQuote.SBQQ__Status__c = 'Approved';
        insert cpqQuote;
        
        Opportunity oppRecrd = new Opportunity();
        oppRecrd.Alternative_Cable_Selection__c = true;
        oppRecrd.Free_Trial_Purchase__c = 'Full Buy';
        oppRecrd.Id = testOpp.Id;
        Test.startTest();
        
        SBQQ__Quote__c qte = new SBQQ__Quote__c();
        qte.Id = cpqQuote.Id;
        qte.SBQQ__Status__c = 'Pending';
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        update qte;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();        
        update oppRecrd;
        
        Id docId = createDocusign(oppRecrd.id);
        createFiles(docId);
        
        dsfs__DocuSign_Status__c docusign = [SELECT Id, dsfs__Envelope_Status__c, dsfs__Opportunity__c, 
                                            Billing_Company_Name__c, Customer_Preferred_Payment_Method__c, 
                                            Selected_Payment_Type__c, Payment_Terms__c, License_Term__c, 
                                            Opp_Currency__c, Sales_Tax_Amount__c, Shipping_And_Handling__c,
                                            of_HW_Products__c, of_LIC_Products__c, Total_Hardware_Due__c, 
                                            Total_License_Due__c,
                                            Total_License_Cost__c FROM dsfs__DocuSign_Status__c 
                                            WHERE Id = :docId];
        
        OrderValidationBannerClass.kbValidations(testOpp, docusign, 0);
        
        OrderValidationBannerClass.emeaVatCheck(testOpp);
        OrderValidationBannerClass.closeDateChkMthd(testOpp);
        OrderValidationBannerClass.showBannerDetails(testOpp.Id);
        
        List<String> testReasons = new List<String>{'Test Reason 1', 'Test Reason 2'};
        List<String> testResolutions = new List<String>{'Test Resolution 1', 'Test Resolution 2'};
        
        OrderValidationBannerClass.KickBackWrapper testKbWrap = new OrderValidationBannerClass.KickBackWrapper(testReasons, testResolutions);
        
        Integer reasonSize = testKbWrap.reason.size();
        Integer resolutionSize = testKbWrap.resolution.size();
        String firstReason = testKbWrap.reason[0];
        String firstResolution = testKbWrap.resolution[0];
        
        testKbWrap.reason.add('Test Reason 3');
        testKbWrap.resolution.add('Test Resolution 3');
        Integer newReasonSize = testKbWrap.reason.size();
        Integer newResolutionSize = testKbWrap.resolution.size();
        
        OrderValidationBannerClass.KickBackWrapper emptyKbWrap = new OrderValidationBannerClass.KickBackWrapper(new List<String>(), new List<String>());
        Integer emptyReasonSize = emptyKbWrap.reason.size();
        Integer emptyResolutionSize = emptyKbWrap.resolution.size();
        
        OrderValidationBannerClass.KickBackWrapper nullKbWrap = new OrderValidationBannerClass.KickBackWrapper(null, null);
        List<String> nullReasons = nullKbWrap.reason;
        List<String> nullResolutions = nullKbWrap.resolution;
        
        Test.stopTest();
    }
    @IsTest
    static void ofKBTest3(){
        User aeUser = [SELECT Id,Name FROM User WHERE alias = 'AE2Usr'];
        
         OrderValidationServiceAutomationTest.createOVASetting(true,aeUser.Id,false);
        
        Account testAcc = createAccount('USDTestAccount','Upfront Payments', aeUser.Id,'USD');
        Insert testAcc;
        
        Contact usdCon = createContact(testAcc.Id);
        insert usdCon;
        
        Shipping_Address__c usdshpngAddrs= createShippingAddress(testAcc.Id, usdCon.Id);
        insert usdShpngAddrs;
        
        opportunity testopp = createOpportunity('testOppty',testAcc.Id,aeUser.Id, 'Due In Advance','Upfront Payments',usdshpngAddrs.Id, false,'USD');
        testOpp.CurrencyIsoCode = 'USD';
        testOpp.Amount = 10000;
        testOpp.Sales_Tax_Amount__c = 1000;
        testOpp.Amount_Received__c = null;
        Insert testOpp;
        
       	SBQQ__Quote__c cpqQuote = createQuote(testOpp.Id,testOpp.AccountId,'USD');
        cpqQuote.CurrencyIsoCode = 'USD';
        cpqQuote.SBQQ__Status__c = 'Approved';
        insert cpqQuote;
        
        Opportunity oppRecrd = new Opportunity();
        oppRecrd.Alternative_Cable_Selection__c = true;
        oppRecrd.Free_Trial_Purchase__c = 'Full Buy';
        oppRecrd.Id = testOpp.Id;
        Test.startTest();
        
        Id docId = createDocusign(oppRecrd.id);
        createFiles(docId);
        
        SBQQ__Quote__c qte = new SBQQ__Quote__c();
        qte.Id = cpqQuote.Id;
        qte.SBQQ__Status__c = 'Pending';
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        update qte;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();        
        update oppRecrd;
        
        // Test kbValidations method directly for comprehensive coverage
        dsfs__DocuSign_Status__c docusign = [SELECT Id, dsfs__Envelope_Status__c, dsfs__Opportunity__c, 
                                            Billing_Company_Name__c, Customer_Preferred_Payment_Method__c, 
                                            Selected_Payment_Type__c, Payment_Terms__c, License_Term__c, 
                                            Opp_Currency__c, Sales_Tax_Amount__c, Shipping_And_Handling__c,
                                            of_HW_Products__c, of_LIC_Products__c, Total_Hardware_Due__c, 
                                            Total_License_Due__c,
                                            Total_License_Cost__c FROM dsfs__DocuSign_Status__c 
                                            WHERE Id = :docId];
        
        OrderValidationBannerClass.kbValidations(testOpp, docusign, 1); 
        
        // Test the close date validation logic to cover lines 523-531
        // Create a new EUR opportunity to test the else if block for GBP/EUR currencies (lines 526-530)
        Account eurAcc = createAccount('EURTestAccount','Upfront Payments', aeUser.Id,'EUR');
        Insert eurAcc;
        
        Contact eurCon = createContact(eurAcc.Id);
        insert eurCon;
        
        Shipping_Address__c eurShpngAddrs = createShippingAddress(eurAcc.Id, eurCon.Id);
        insert eurShpngAddrs;
        
        Opportunity eurOpp = createOpportunity('eurTestOppty',eurAcc.Id,aeUser.Id, 'Due In Advance','Upfront Payments',eurShpngAddrs.Id, false,'EUR');
        eurOpp.CloseDate = Date.today().addDays(1);
        Insert eurOpp;
        
        SBQQ__Quote__c eurQuote = createQuote(eurOpp.Id,eurAcc.Id,'EUR');
        insert eurQuote;
        
        Id eurDocId = createDocusign(eurOpp.id);
        
        dsfs__DocuSign_Status__c eurDocusign = [SELECT Id, dsfs__Envelope_Status__c, dsfs__Opportunity__c, 
                                            Billing_Company_Name__c, Customer_Preferred_Payment_Method__c, 
                                            Selected_Payment_Type__c, Payment_Terms__c, License_Term__c, 
                                            Opp_Currency__c, Sales_Tax_Amount__c, Shipping_And_Handling__c,
                                            of_HW_Products__c, of_LIC_Products__c, Total_Hardware_Due__c, 
                                            Total_License_Due__c,
                                            Total_License_Cost__c FROM dsfs__DocuSign_Status__c WHERE Id = :eurDocId];
        
        OrderValidationBannerClass.kbValidations(eurOpp, eurDocusign, 1);
        
        OrderValidationBannerClass.showBannerDetails(testOpp.Id);
        Test.stopTest();
    }
}