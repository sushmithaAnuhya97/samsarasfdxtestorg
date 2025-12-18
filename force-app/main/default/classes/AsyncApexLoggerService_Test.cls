/**********************************************************************
Test Class: AsyncApexLoggerService_Test
Name: AsyncApexLoggerService
----------------------------------------------------------------------
Purpose: This class contains the test case methods for creating Async Apex loggers
----------------------------------------------------------------------
History  

Ticket           AUTHOR              DATE               DETAIL                                      
GTMS-20016  `	Vijaychandra        4/3/24            Created as part of OVA full launch Hypercare ticket to test the creation Async Apex loggers
**********************************************************************/
@IsTest
public class AsyncApexLoggerService_Test {
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
    	}       
        
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
        
        insert dRec;
        
        //createFiles(dRec.Id);
        
        return dRec.Id;
    } 
    @IsTest
    static void ovaAsyncLogTest(){
        List<Opportunity> oppList = [SELECT Id, Name, OwnerId, Owner.Name, Owner.Region__c, Amount, Notes__c,
            StageName, Payment_Terms__c, Initial_Payment_Terms__c, CloseDate,PO_Number__c,Overwrite_Validation_Rule__c,
            Finance_Kickback_Reason__c, Finance_Kickback_Resolution__c,Shipping_and_Handling__c,Bypass_Validation_rule__c,
            License_Term__c, License_Term_CPQ__c, Amount_Received__c,Payment_Method__c,of_LIC_Products__c,
            Buyout_Amount__c, Buyout_Opportunity__c, Subsidy_Amount__c,Payment_Token__c,Probability,Owner_Role_Copy__c,
            Subsidy_Opportunity__c, Sales_Tax__c, Sales_Tax_Amount__c, Credit_Analyst_Kickback_Note__c,Owner_Manager_Role_Copy__c,
            Shipping_and_Handling_Manual__c, CurrencyIsoCode, CM_Unit_Count__c, VG_unit_count__c, of_HW_Products__c,
            VAT_Validation_Status__c, CVS_Review__c, Finance_Segment__c,Shipping_Zip_Code__c,SBQQ__Renewal__c,Blended_Discount__c,
            Is_Webstore_Upsell_Opportunity__c, Custom_Schedule__c, Camera_Only_Deal__c,
            Selected_Payment_Type__c, Payment_Type__c, First_Invoice_Total__c, Payment_Processing_Fee__c, First_Purchase__c,
            Hardware_Sales_Tax__c, License_Sales_Tax__c, Sbqq__PrimaryQuote__c, Total_Hardware_Due__c, Total_License_Due__c,/*GTMS-19053*/DCA_Enabled__c,CreatedDate,Account.Customer_require_PO_for_invoicing__c,/*GTMS-19053*/
            SBQQ__PrimaryQuote__r.Name,SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c,SBQQ__PrimaryQuote__r.License_Term__c,/*GTMS-19277*/SBQQ__PrimaryQuote__r.Consolidated_Billing_Email__c,SBQQ__PrimaryQuote__r.CreatedDate,/*GTMS-19277*/
            SBQQ__PrimaryQuote__r.CalculatedSubscriptionTerm__c, License_Sales_Tax_CPQ__c,Hardware_Sales_Tax_CPQ__c,/*GTMS-17786*/SBQQ__PrimaryQuote__r.of_Accessories__c,/*GTMS-17786*/
            SBQQ__PrimaryQuote__r.SBQQ__Status__c, SBQQ__PrimaryQuote__r.Close_Date__c,/*(GTMS-16314)*/SBQQ__PrimaryQuote__r.CurrencyIsoCode,/*(GTMS-16314)*/ /*GTMS-16121*/SBQQ__PrimaryQuote__r.Shipping_And_Handling__c,/*GTMS-16121*/
            SBQQ__PrimaryQuote__r.Latest_Close_Date__c, SBQQ__PrimaryQuote__r.SBQQ__Primary__c,/*GTMS-17284*/SBQQ__PrimaryQuote__r.Payment_Terms__c,/*GTMS-17284*/Sales_Tax_Rate_NEW__c,
            SBQQ__PrimaryQuote__r.of_HW_Products__c, SBQQ__PrimaryQuote__r.Of_LIC_Products__c, SBQQ__PrimaryQuote__r.Sales_Tax__c, SBQQ__PrimaryQuote__r.AccountName__c,SBQQ__PrimaryQuote__r.Selected_Payment_Type__c,
            /*GTMS-16637*/Owner_Manager_Name_Copy__c, Owner_Director_Name_Copy__c, SBQQ__PrimaryQuote__r.Bill_To_Account__r.Name, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingStreet, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCity,
            SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingState, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCountry, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingPostalCode,SBQQ__PrimaryQuote__r.Bill_To_Account__r.Billing_Email__c,SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Email, 
            SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Name, SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Title,SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Phone, SBQQ__PrimaryQuote__r.Bill_To_Account__r.Phone,SBQQ__PrimaryQuote__r.DCA_Validation__c, SBQQ__PrimaryQuote__r.Customer_Preferred_Payment_Method__c,/*GTMS-16637*/
            /*GTMS-16035*/Account.Billing_Stripe_Customer_Id__c,Owner_Segment__c,/*GTMS-16035*//*GTMS-16028*/SBQQ__RenewedContract__c,Type,Account.VAT_Validation_Status__c, Account.First_Purchase_Opportunity__r.Shipping_Country__c,
            Shipping_Country__c, VAT_Number__c,Account.First_Purchase_Opportunity__c, Account.First_Purchase_Opportunity__r.VAT_Number__c,Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c,/*GTMS-16028*/
            /*GTMS-16312*/Account.First_Purchase_Opportunity__r.Payment_Terms__c, Account.First_Purchase_Opportunity__r.Initial_Payment_Terms__c,/*GTMS-16312*/
            /*GTMS-19686*/Account.Payment_Terms__c,/*GTMS-19686*//*GTMS-19973*/SBQQ__PrimaryQuote__r.Total_Hardware_Due__c, SBQQ__PrimaryQuote__r.Total_License_Due__c,/*GTMS-19973*/
            (SELECT ID, First_invoice_line_amount__c from OpportunityLineItems),
            (SELECT Id, Name, dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c, dsfs__DocuSign_Status__c.dsfs__Opportunity__c, dsfs__DocuSign_Status__c.License_Term__c,
             dsfs__DocuSign_Status__c.Account_Name__c, dsfs__DocuSign_Status__c.of_HW_Products__c,/*GTMS-16121*/dsfs__Docusign_Status__c.Shipping_And_Handling__c,/*GTMS-16121*/
             dsfs__DocuSign_Status__c.of_LIC_Products__c, dsfs__DocuSign_Status__c.Payment_Terms__c, dsfs__Company__r.name,dsfs__Docusign_Status__c.Opp_Currency__c,//(GTMS-16314)
             /*GTMS-16637*/dsfs__DocuSign_Status__c.Bill_To_Contact_Name__c, dsfs__DocuSign_Status__c.Bill_To_Contact_Phone__c, dsfs__DocuSign_Status__c.Bill_To_Contact_Title__c, dsfs__DocuSign_Status__c.Billing_City__c,
             dsfs__DocuSign_Status__c.Billing_Company_Name__c, dsfs__DocuSign_Status__c.Billing_Country__c, dsfs__DocuSign_Status__c.Billing_Email__c,dsfs__DocuSign_Status__c.Customer_Preferred_Payment_Method__c,
             dsfs__DocuSign_Status__c.Billing_Postal_Code__c,dsfs__DocuSign_Status__c.Billing_State__c, dsfs__DocuSign_Status__c.Billing_Street__c,dsfs__DocuSign_Status__c.Bill_To_Contact_Email__c,/*GTMS-16637*/
             dsfs__DocuSign_Status__c.Sales_Tax_Amount__c,dsfs__DocuSign_Status__c.Selected_Payment_Type__c
             FROM R00N80000002fD9vEAE__r WHERE dsfs__DocuSign_Status__c.dsfs__Opportunity__c != null AND dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c = 'Completed'),
            AccountId, Account.Name, Account.Further_information_required__c, Account.CurrencyIsoCode, Account.BillingCountry, Account.New_Billing_Process_Approved__c,
            SBQQ__RenewedContract__r.Name, SBQQ__RenewedContract__r.AccountId,Opportunity_Tracking__c, Owner_AVP_Name_Copy__c 
            FROM Opportunity];
        Test.startTest();
        AsyncApexLoggerService async = new AsyncApexLoggerService();
        async.createAsyncApexLogger('testJobId','testJobName','Batch Apex');
        Map<Id,Id> loggerMap = async.createAsyncApexLogger('testOpptyJobId','testOpptyJobName','testJob',oppList);
        Map<Id,String> errorMap = new Map<Id,String>();
        errorMap.put(oppList[0].Id,'test error Map');
        async.updateOVAFailuresInAsyncLogger(loggerMap.values(),errorMap);
        async.updateAsyncLogger(new Async_Apex_Logger__c(),oppList[0],new List<String>(), new List<String>(),null);
        Test.stopTest();
    }    
    
}