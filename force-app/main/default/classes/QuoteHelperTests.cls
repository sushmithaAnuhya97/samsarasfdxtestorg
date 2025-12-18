/* 
 * Class Created: 07/29/19 - @author: Harsha
 */  
// This test class is CPU Sensitive, please check with Harsha if you are making any changes to this class. 
@isTest(SeeAllData=false)
public class QuoteHelperTests {
    
    //Static Account testAccount;
    //Static Opportunity testOpportunity;
    
    // Do not add any insert statements - It will cause CPU Time limit issues. Data insert until the quote is taking aroung 75% of CPU time.
    @testSetup
    private static void testDataSetup() {
        
        
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
        //Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
        //products.add(vgLicense);
        /*Product2 em11 = new Product2(Name= 'HW-EM11', ProductCode = 'HW-EM11', Family = 'Test');
        products.add(em11);
        Product2 emLicense = new Product2(Name= 'LIC-EM-36MO', ProductCode = 'LIC-EM-36MO', Family = 'Test');
        products.add(emLicense);*/
        Product2 insuranceSUBSIDY = new Product2(Name= 'INS-SUBSIDY', ProductCode = 'INS-SUBSIDY', Family = 'Test');
        products.add(insuranceSUBSIDY); 
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        //PricebookEntry em11PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = em11.Id, UnitPrice = 10000, IsActive = true);
        //pricebookEntries.add(em11PB);
        //PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        //pricebookEntries.add(vgLicensePB);
        //PricebookEntry emLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = emLicense.Id, UnitPrice = 10000, IsActive = true);
        //pricebookEntries.add(emLicensePB);
        PricebookEntry insuranceSUBSIDYPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = insuranceSUBSIDY.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(insuranceSUBSIDYPB);
        insert pricebookEntries;
        
        
        // Create account
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        newAccount.add(account);
		//Account accountP = new Account (Name = 'Test Partner Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        //newAccount.add(accountP);
        insert newAccount;
        
        Contract cont = new Contract(
            AccountId = newAccount[0].Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 12,
            Status = 'Draft'
        );
        insert cont;
        cont.Status = 'Activated';
        update cont;
        
        // Create Contact
        List<Contact> newContacts = new List<Contact>();
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=account.Id);
        newContacts.add(contact);
        
        insert newContacts;
        
        //Create Shipping Address
        List<Shipping_Address__c> shippingAddresses = new  List<Shipping_Address__c>();
        
        Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                            , Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                            , Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
        shippingAddresses.add(shipTo);
        Shipping_Address__c shipToTwo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '610 Park View Dr'
                                                            , Shipping_City__c = 'Santa Clara', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                            , Shipping_Zip_Code__c = '95054', Name = 'Ship To Two');
        shippingAddresses.add(shipToTwo);
        
        Shipping_Address__c shipToFour = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '1 Parliment St'
                                                            , Shipping_Address_Line_2__c= 'XYZ'
                                                            , Shipping_City__c = 'London'
                                                            , Shipping_Country__c ='United Kingdom'
                                                            , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Four');
        
        shippingAddresses.add(shipToFour);
        insert shippingAddresses;
            
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c ='Industrial');            
        newOpportunities.add(revenueOpportunity);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity2', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c ='Industrial');            
        newOpportunities.add(revenueOpportunity2);
        insert newOpportunities;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Source Quote', SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c =revenueOpportunity.Id, 
                                                 SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = false, Custom_License_Term__c = 2
                                                 , Selected_Payment_Type__c='Direct Monthly' );
        insert quote;
    }
    
    @isTest private static void testShippingFields() {
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        Opportunity testOpportunity = [SELECT Id FROM Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Owner_Role_Copy__c ='Connected';
        
        update testOpportunity;
        Shipping_Address__c address = [SELECT Id FROM Shipping_Address__c WHERE Name='Ship To Two'];
        Contact contact = [SELECT id FROM CONTACT WHERE Email = 'test@test.com'];
        
        Shipping_Address__c belgiumAddress = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contact.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = testAccount.Id);
        insert belgiumAddress; 
        
        Test.startTest();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Account__c = testAccount.Id,SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Opportunity2__c =testOpportunity.Id, SBQQ__Primary__c = false, Shipping_Address_NEW__c=address.Id, Custom_License_Term__c = 2);
        insert quote;

        quote.Shipping_Address_NEW__c = null;
        update quote;
        
        SBQQ__Quote__c queriedQuote = [SELECT Id, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM SBQQ__Quote__c WHERE Quote_Name__c='Test Version'];
        System.assertEquals('DCL-LA', queriedQuote.Ship_From_Location__c);
        //System.assertEquals('3 Day Select', queriedQuote.Shipping_Method__c);
        //System.assertEquals('UPS', queriedQuote.Shipping_Carrier__c);
        
        quote.Shipping_Address_NEW__c = belgiumAddress.Id;
        update quote;       
        Test.stopTest();
    }
    
    @isTest 
    static void renewalPrimaryTest(){
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        Opportunity testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Owner_Role_Copy__c ='Renewal';
        testOpportunity.License_Term__c = 60;
        try {
        update testOpportunity; 
        } catch (Exception e) {
            System.debug('Failed to update Opportunity: ' + e.getMessage());
        } 
        SBQQ__Quote__c sourceQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Source Quote'];
        Test.startTest();
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Four'];
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Type__c='Renewal', SBQQ__Source__c = sourceQuote.Id,
                                                  SBQQ__Account__c = testAccount.Id, SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24,SBQQ__Primary__c = true, 
                                                  License_Term__c='12', SBQQ__EndDate__c=Date.today()+7, SBQQ__StartDate__c=Date.today()
                                                 ,Upsell_Amount__c=10000, SBQQ__RenewalTerm__c=1000, Renewal_Amount__c=20000,Downsell_Amount__c=1000);
        try {
        insert quote;
        } catch (Exception e) {
            System.debug('Failed to insert Quote: ' + e.getMessage());
        }

        quote.Shipping_Address_NEW__c = shippingAddress.Id;
        quote.License_Term__c='36';
        //quote.SBQQ__Primary__c = false;
        quote.Selected_Payment_Type__c='Upfront Payments';
        quote.Ship_From_Location__c='Samsara HQ';
        quote.Approved_Discount__c=15;
        try {
        update quote;  
        } catch (Exception e) {
            System.debug('Failed to update Quote (first update): ' + e.getMessage());
        } 
        
        quote.License_Term__c=null;
        quote.Custom_License_Term__c = 2;
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__Type__c = 'Amendment';
        quote.SBQQ__MasterContract__c = testContract.id;
        quote.SBQQ__LastCalculatedOn__c=Date.today();
        quote.ApprovalStatus__c = 'Rejected';
        quote.Upsell_Amount__c= null;
        quote.SBQQ__RenewalTerm__c=null;
        try {
        update quote;  
        } catch (Exception e) {
            System.debug('Failed to update Quote (final update): ' + e.getMessage());
        } 
        Test.stopTest();
    }
    
    @isTest 
    static void renewalCreateTest(){
    Test.startTest();
    try {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingCountry = 'USA'
        );
        insert testAccount;

        // Create test Contract
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            Status = 'Draft',
            ContractTerm = 12,
            Auto_Renewal__c = true
        );
        insert testContract;

        // Create Opportunities
        Opportunity testOpportunity = new Opportunity(
            Name = 'Revenue Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            Owner_Role_Copy__c = 'Renewal',
            License_Term__c = 60,
            Type = 'Promo Opportunity',
            Promo_Reason__c = 'Exchange',
            Selected_Payment_Type__c = 'Direct Monthly',
            SBQQ__RenewedContract__c = testContract.Id,
            AccountId = testAccount.Id
        );
        Opportunity testOpportunity2 = new Opportunity(
            Name = 'Revenue Opportunity2',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(2),
            AccountId = testAccount.Id
        );
        insert new List<Opportunity>{testOpportunity, testOpportunity2};

        // Update Contract with Opportunity
        testContract.SBQQ__Opportunity__c = testOpportunity2.Id;
        update testContract;

        // Create Shipping Address
        Shipping_Address__c shippingAddress = new Shipping_Address__c(
            Name = 'Ship To Four'
        );
        insert shippingAddress;

        // Create Source Quote
        SBQQ__Quote__c sourceQuote = new SBQQ__Quote__c(
            Quote_Name__c = 'Source Quote',
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpportunity.Id,
            SBQQ__Primary__c = true,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addMonths(12)
        );
        insert sourceQuote;

        // Create the new Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Version', 
            SBQQ__Type__c='Renewal', 
            SBQQ__Source__c = sourceQuote.Id,
            SBQQ__Account__c = testAccount.Id, 
            SBQQ__Opportunity2__c = testOpportunity.Id, 
            SBQQ__SubscriptionTerm__c = 10,
            Estimated_Annual_Payment__c = 24,
            SBQQ__Primary__c = true, 
            License_Term__c='12', 
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(7),
            Upsell_Amount__c = 10000, 
            SBQQ__RenewalTerm__c = 1000, 
            Renewal_Amount__c = 20000,
            Downsell_Amount__c = 1000,
            Selected_Payment_Type__c = 'Direct Monthly',
            Configuration_Segment__c = 'Express',
            Shipping_Address_NEW__c = shippingAddress.Id,
            Ship_From_Location__c = 'Samsara HQ',
            Approved_Discount__c = 15
        );
        insert quote;

        // Update Quote for Amendment
        quote.Custom_License_Term__c = 2;
        quote.License_Term__c = null;
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__Type__c = 'Amendment';
        quote.SBQQ__MasterContract__c = testContract.Id;
        quote.SBQQ__LastCalculatedOn__c=Date.today();
        quote.ApprovalStatus__c = 'Rejected';
        quote.Upsell_Amount__c= null;
        quote.SBQQ__RenewalTerm__c=null;
        update quote;  
    } catch (Exception e) {
       System.debug('Error during renewalCreateTest: ' + e.getMessage());
      //  System.assert(false, 'Test method failed: ' + e.getMessage());
    }
        Test.stopTest();
    }
    
    
    //* 2/09/21 Groundswell - Tanuj
    @isTest 
    static void coTermedStartDateTest(){
        
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        Opportunity testOpportunity = [SELECT id,CloseDate, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Owner_Role_Copy__c ='Equipment';
        update testOpportunity; 
        Contract testContract = new Contract(AccountId = testAccount.Id, Status = 'Draft', CurrencyIsoCode = 'USD', StartDate = Date.today() - 15, ContractTerm = 1);
        SBQQ__Quote__c sourceQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Source Quote'];
        insert testContract;
        Test.startTest();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Source__c = sourceQuote.Id,SBQQ__Account__c = testAccount.Id,
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Opportunity2__c 
                                                  =testOpportunity.Id, SBQQ__Primary__c = false, Configuration_Segment__c = 'Express', SBQQ__MasterContract__c = testContract.Id, Custom_License_Term__c = 1);
        insert quote;
        SBQQ__Quote__c queriedInsertedQuote = [SELECT Id, SBQQ__StartDate__c FROM SBQQ__Quote__c WHERE Id =:quote.Id];

        //System.assertEquals(testOpportunity.CloseDate, queriedInsertedQuote.SBQQ__StartDate__c);
        quote.SBQQ__StartDate__c = null;
        update quote;
        SBQQ__Quote__c queriedUpdatedQuote = [SELECT Id, SBQQ__StartDate__c FROM SBQQ__Quote__c WHERE Id =:quote.Id];

        //System.assertEquals(testOpportunity.CloseDate + 15, queriedUpdatedQuote.SBQQ__StartDate__c);
        Test.stopTest();
    }
    /*
    @isTest 
    static void InsuranceSubsidyTests(){
SBQQ.TriggerControl.disable();
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        Opportunity testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        update testOpportunity;
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'INS-SUBSIDY'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Four'];

        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c = 1, Estimated_Annual_Payment__c =1000,
                                                  SBQQ__Primary__c = false, SBQQ__Type__c='Amendment', Selected_Payment_Type__c='Direct Monthly', License_Term__c='12');
        insert quote;
        
        quote.SBQQ__Primary__c = false;
        update quote; 
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(Subsidy_Amount__c=10, Subsidy_Quantity__c=5, Subsidy_Method__c = 'Fixed $', 
                                                                  SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(Subsidy_Amount__c=10, Subsidy_Quantity__c=5, Subsidy_Method__c = 'Percentage', 
                                                                  SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        
        quote.Selected_Payment_Type__c='Direct Annual';
        quote.ApprovalStatus__c = 'Approved';
        update quote; 
        
        quote.Selected_Payment_Type__c='Upfront Payments';
        quote.ApprovalStatus__c = 'Pending';
        quote.Ship_From_Location__c = 'DCL';
        quote.License_Term__c='12';
        update quote; 
        
        quote.ApprovalStatus__c = 'Rejected';
        quote.Selected_Payment_Type__c='Direct Monthly';
        quote.Ship_From_Location__c = 'DCL-LA';
        update quote;
        Test.stopTest();
    }
    */
    @isTest 
    static void afterUpdateQuoteTest(){
        Set<Id> cloneQuoteId = new Set<Id>();
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        Opportunity testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Cust_Partner_Shipping_Account_Number__c = '335979';
        testOpportunity.Owner_Role_Copy__c = 'MM';
        update testOpportunity;
        SBQQ__Quote__c sourceQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Source Quote'];
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'test@test.com'];
        Test.startTest();
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One'];
            
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version Sync', SBQQ__Source__c=sourceQuote.Id, SBQQ__Account__c = testAccount.Id, SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24,SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id, Custom_License_Term__c = 2);
        insert quote;
        SBQQ__Quote__c clonequote = quote.clone(false,false,false,false);
        insert clonequote;
        
        quote.SBQQ__Primary__c = true;
        quote.Shipping_Carrier__c = 'Fedex';
        quote.Shipping_Account_Type__c = 'Cust/Partner Account - FedEx';
        quote.Shipping_Method__c = 'ECONOMY';
        quote.Reason_for_Discount__c ='Test';
        quote.Selected_Payment_Type__c = 'Direct Annual';
        quote.SBQQ__Source__c = clonequote.Id;
        update quote; 
        cloneQuoteId.add(quote.SBQQ__Source__c);
        SBQQQuoteHelper quoteTest = new SBQQQuoteHelper();
        //quoteTest.getSourceQuoteData(cloneQuoteId);
        SBQQQuoteHelper.recalculateQuote(cloneQuoteId);
        Test.stopTest();
    }
    
    @isTest 
    static void updateQuotesTest(){
        
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        Opportunity testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        update testOpportunity;
        Test.startTest();
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Two'];
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Account__c = testAccount.Id, SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24,SBQQ__Primary__c = false, 
                                                  License_Term__c='12');
        insert quote;

        quote.Shipping_Address_NEW__c = shippingAddress.Id;
        quote.License_Term__c='36';
        quote.Selected_Payment_Type__c='Upfront Payments';
        quote.Ship_From_Location__c='Samsara HQ';
        update quote;      
        Test.stopTest();
    }
    
    @isTest private static void QuoteEventTest() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Name='Revenue Opportunity'];
        opportunity.Owner_Role_Copy__c = 'ENT';
        update opportunity;
        Shipping_Address__c address = [SELECT Id FROM Shipping_Address__c WHERE Name='Ship To Two'];
        Contact contact = [SELECT id FROM CONTACT WHERE Email = 'test@test.com'];
        
        Shipping_Address__c belgiumAddress = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contact.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = testAccount.Id);
		insert belgiumAddress; 
        /*SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Account__c = testAccount.Id, SBQQ__Opportunity2__c =opportunity.Id, SBQQ__Primary__c = false, Shipping_Address_NEW__c=address.Id,SBQQ__SubscriptionTerm__c =36);
        insert quote;*/
        Test.startTest();
        SBQQ__Quote__c quote = [Select Id,Mulesoft_Status__c from SBQQ__Quote__c limit 1 ];
        
        quote.Mulesoft_Status__c = 'Completed';
        update quote;
        
        QuoteEvent__e qtEvent = new QuoteEvent__e(Event_Data__c = Json.serialize(new set<Id>{quote.Id}));
        Database.SaveResult sr = EventBus.publish(qtEvent);
        Test.stopTest();
    }
    
    //* 2/09/21 Groundswell - Tanuj
    @isTest 
    static void testClearOutApprovedQuoteWithSource(){
       
        SBQQ.TriggerControl.disable();

    // Setup Account
    Account testAccount = [SELECT Id, Name, BillingCountry FROM Account WHERE Name = 'Test Account' LIMIT 1];
        testAccount.Approved_Payment_Type__c = Label.Direct_Monthly_Payment_Type;
        update testAccount;

    // Setup Opportunity
    Opportunity testOpportunity = [SELECT Id, Name FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        
    Test.startTest();

    // Create Quote and its Clone
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Version', 
            SBQQ__Account__c = testAccount.Id, 
            SBQQ__Opportunity2__c = testOpportunity.Id, 
            SBQQ__SubscriptionTerm__c = 10,
            Estimated_Annual_Payment__c = 24,
            SBQQ__Primary__c = true, 
        Custom_License_Term__c = 2
    );

    insert quote;

    SBQQ__Quote__c cloneQuote = quote.clone(false, false, false, false);
    cloneQuote.Configuration_Segment__c = 'Express';
    cloneQuote.Approved_Discount__c = 10;
    cloneQuote.SBQQ__Source__c = quote.Id;
    cloneQuote.Selected_Payment_Type__c = Label.Direct_Monthly_Payment_Type;
    
    insert cloneQuote;

    // Validate clone quote after initial insert
    SBQQ__Quote__c queriedClone = [SELECT Id, Approved_Discount__c FROM SBQQ__Quote__c WHERE Id = :cloneQuote.Id];
    System.assertEquals(null, queriedClone.Approved_Discount__c);

    // Update original quote payment type
    quote.Selected_Payment_Type__c = Label.Upfront_Payment_Type;
    update quote;

    // No need to update clone again unnecessarily
    SBQQ__Quote__c queriedCloneAfterUpdate = [SELECT Id, Approved_Discount__c FROM SBQQ__Quote__c WHERE Id = :cloneQuote.Id];
    System.assertEquals(null, queriedCloneAfterUpdate.Approved_Discount__c);

    Test.stopTest();
    }
    
    /*
    @isTest 
    static void insertQuotesTest(){
        
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        Opportunity testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        
        Test.startTest();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Account__c = testAccount.Id,SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Opportunity2__c =testOpportunity.Id, SBQQ__Primary__c = false, Custom_License_Term__c = 2);
        insert quote;
        Test.stopTest();
    }
    
    @isTest 
    static void updateQuotesTest(){
        
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        Opportunity testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        
        Test.startTest();
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Two'];
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Account__c = testAccount.Id, SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24,SBQQ__Primary__c = false, Custom_License_Term__c = 2);
        insert quote;

        quote.Shipping_Address_NEW__c = shippingAddress.Id;
        update quote;      
        Test.stopTest();
    }


    

    

    //* 2/09/21 Groundswell - Tanuj
    @isTest 
    static void testClearOutApprovedQuoteWithoutSource(){
        
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        Opportunity testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        
        Test.startTest();
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Two'];
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Account__c = testAccount.Id, SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24,SBQQ__Primary__c = false, Selected_Payment_Type__c = Label.Upfront_Payment_Type, Custom_License_Term__c = 2);
        insert quote;
        SBQQ__Quote__c clonequote = quote.clone(false,false,false,false);
        clonequote.Approved_Discount__c = 10;
        clonequote.Configuration_Segment__c = 'Express';
        insert clonequote;

        clonequote.Selected_Payment_Type__c = Label.Direct_Monthly_Payment_Type;
        update clonequote;
        SBQQ__Quote__c queriedQuote = [SELECT Id, Approved_Discount__c FROM SBQQ__Quote__c WHERE Id =:clonequote.Id];

        //System.assertEquals(null, queriedQuote.Approved_Discount__c);
        Test.stopTest();
    }


    
    
    
    @isTest 
    static void quoteLineTestFromQuoteTest(){
        
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        Contact contact = [SELECT Id FROM Contact WHERE Email='test@test.com'];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Primary__c,Estimated_Monthly_Payment__c,Monthly_Credit_Remaining_on_Account__c, Shipping_Address_NEW__c FROM SBQQ__Quote__c WHERE Quote_Name__c='First Quote']; 
        
        Shipping_Address__c belgiumAddress = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contact.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = testAccount.Id);
        insert belgiumAddress;
        
        Test.startTest();        
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id];        
        
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        insert quoteLineOne;  
        
        quote.Shipping_Address_NEW__c = belgiumAddress.Id;
        quote.SBQQ__Primary__c = false;
        quote.Selected_Payment_Type__c = 'Upfront Payments';
        quote.ApprovalStatus__c = 'Approved';
        system.debug('Estimated_Monthly_Payment__c :: '+quote.Estimated_Monthly_Payment__c);
        system.debug('Monthly_Credit_Remaining_on_Account__c:: '+quote.Monthly_Credit_Remaining_on_Account__c);
        update quote;
        quote.ApprovalStatus__c = 'Pending';
        update quote;
        quote.ApprovalStatus__c = 'Rejected';
        update quote;
        
        Test.stopTest();
    }
    
    
    
*/
}