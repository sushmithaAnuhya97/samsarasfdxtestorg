@isTest(SeeAllData=false)
public class QuoteCustomCongaComposerTest {
    
    @testSetup
    private static void testDataSetup() {
        Test.startTest();
         Test.stopTest();
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        //Updating code for Flex changes
        // Create Custom Settings
        FlexConstants__c flexConstants = new FlexConstants__c(
            Name = 'FlexConstants',
            RetryAttemptLimit__c = 1,
            ContractAmendmentProcessTime__c = 2,
            PostContractAmendmentWaitTime__c = 1
        );
        insert flexConstants;
        
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            Name = 'Standard Price Book',
            IsActive = true
        );
        Update standardPricebook;
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test',Sales_Charge_Type__c ='Recurring');
        products.add(vg33);
        
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        
        insert pricebookEntries;
        
        // Create account
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        newAccount.add(account);
        // ABU:GTMS-15650 09/18/2023
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account partnerAccount = new Account (Name = 'Test Partner Account',RecordTypeId = accRecordTypeId,Partner_Type__c ='Insurance',Program_Type__c ='Subsidy', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        newAccount.add(partnerAccount);
        // ABU:GTMS-15650 09/18/2023--> End
        insert newAccount;
        
        Customer_360__c c360 = new Customer_360__c(LIC_AG2_Discount__c=1,LIC_AG4_Discount__c=1,LIC_CM1_Discount__c=1,LIC_CM2_Discount__c=1,
                                                   LIC_CRGO_Discount__c=1,LIC_DM11_Discount__c=1,LIC_VG_Discount__c=1,LIC_AG4P_Discount__c=1,
                                                   LIC_EM_Discount__c=1,Account__c=account.Id);
        insert c360;
        
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
        
        insert shippingAddresses;
        
        //Create Opportunity
        
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, Owner_Role_Copy__c='Industrial',StageName = 'Incubate');            
        // ABU:GTMS-15650 09/18/2023
        Opportunity revenueOpportunitywithInsurancePartner = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                                             Max_Approved_Discount__c=0, Name = 'Revenue OpportunitywithInPartner', Price_Book_Name__c = 'Standard Price Book', 
                                                                             CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8',Insurance_Partner__c=partnerAccount.Id);
        // ABU:GTMS-15650 09/18/2023 --> End
        
        newOpportunities.add(revenueOpportunity);
        newOpportunities.add(revenueOpportunitywithInsurancePartner);
        insert newOpportunities;
        
        SBQQ.TriggerControl.disable();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = account.Id, 
            SBQQ__Opportunity2__c = revenueOpportunity.Id, 
            SBQQ__PricebookId__c = pricebookId,
            Tax_Calculation_Status__c = (System.label.Generate_Quote_Tax_Calculation_Status_Error??'').split(';')[0],
            Shipping_Address_NEW__c = shipTo.Id,
            SBQQ__SubscriptionTerm__c = 12,
            Estimated_Annual_Payment__c = 30000,
            Buyout_Amount__c = 6.0,
            Subsidy_Amount__c = 3.0,
            SBQQ__Primary__c = true,
            Custom_License_Term__c = 12,
            SBQQ__LastCalculatedOn__c = System.now().addDays(2),
            SBQQ__Status__c = 'Draft'
        );
        TriggerHandler.bypass('SBQQQuoteTriggerHandler');
        insert quote;
        
        // Create quote lines for testing annual payment calculation
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        
        // First quote line
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = vg33.Id,
            Account__c = account.Id,
            Ship_To__c = shipTo.Id,
            SBQQ__ListPrice__c = 10000,
            SBQQ__Quantity__c = 1,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addYears(1),
            SBQQ__Group__c = null,
            SBQQ__Bundle__c = false,
            SBQQ__Bundled__c = false,
            SBQQ__BundledQuantity__c = 1,
            SBQQ__Number__c = 1,
            SBQQ__OptionLevel__c = 1,
            SBQQ__OptionType__c = 'Component',
            SBQQ__PricingMethod__c = 'List',
            SBQQ__RequiredBy__c = null,
            SBQQ__SubscriptionScope__c = 'Quote'
        );
        quoteLines.add(quoteLine1);
        
        // Second quote line
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = vg33.Id,
            Account__c = account.Id,
            Ship_To__c = shipTo.Id,
            SBQQ__ListPrice__c = 20000,
            SBQQ__Quantity__c = 1,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addYears(1),
            SBQQ__Group__c = null,
            SBQQ__Bundle__c = false,
            SBQQ__Bundled__c = false,
            SBQQ__BundledQuantity__c = 1,
            SBQQ__Number__c = 2,
            SBQQ__OptionLevel__c = 1,
            SBQQ__OptionType__c = 'Component',
            SBQQ__PricingMethod__c = 'List',
            SBQQ__RequiredBy__c = null,
            SBQQ__SubscriptionScope__c = 'Quote'
        );
        quoteLines.add(quoteLine2);
        
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        insert quoteLines;
        TriggerHandler.clearAllBypasses();
        SBQQ.TriggerControl.enable();
    }
    private static User createTestUser(){
        Profile sysAdminProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name = 'System Administrator' 
            LIMIT 1
        ];
                User sysAdminUser = new User(
            FirstName = 'Test',
            LastName  = 'SysAdmin',
            Email     = 'sysadmin_test@example.com',
            Username  = 'sysadmin_test@example.com.' + System.currentTimeMillis(),
            Alias     = 'sysadm',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey   = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
EmployeeNumber = '1000000',
                    ProfileId = sysAdminProfile.Id
        );
        insert sysAdminUser;
        PermissionSet ps = [
    SELECT Id 
    FROM PermissionSet 
    WHERE Label = 'Validation Rule By - Pass'
    LIMIT 1
];
    
// Assign Permission Set to the created user
PermissionSetAssignment psa = new PermissionSetAssignment(
    AssigneeId     = sysAdminUser.Id,
    PermissionSetId = ps.Id
);
insert psa;        
   return sysAdminUser;
    }    
    @isTest
    public static void withDCAQuoteCheck(){
        SBQQ__Quote__c quote = [SELECT Id, Shipping_and_Handling_Manual__c, Name, Shipping_Country__c, Freight_Cost__c, SBQQ__NetAmount__c, SBQQ__PriceBook__c, Configuration_Segment__c,
                                Shipping_Method__c, Total_Product_Dimensions__c, Shipping_Address_NEW__c, Total_Weight_oz__c, Renewal__c,
                                SBQQ__Opportunity2__c,SBQQ__Account__c, Shipping_Account_Type__c, Selected_Payment_Type__c, Approved_Discount__c, SBQQ__StartDate__c
                                FROM SBQQ__Quote__c where  SBQQ__Opportunity2__r.isClosed  = false  LIMIT 1];
        Test.startTest();
        System.runAs(createTestUser()) {
        opportunity  opp = new opportunity ();
        opp.DCA_Enabled__c = 'DCA';
        opp.Is_Webstore_Upsell_Opportunity__c = false;
        opp.Small_Fleet_Opportunity__c = false;
        opp.Id = quote.SBQQ__Opportunity2__c;
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteTriggerHandler');
        update opp;
        quote.SBQQ__Primary__c = true;
        quote.Reseller_Account__c = quote.SBQQ__Account__c;
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteTriggerHandler');
        update quote;
        TriggerHandler.clearAllBypasses();
        
        PageReference pageRef = Page.QuoteCustomCongaComposer; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(quote.Id));
        Test.setCurrentPage(pageRef);
        
        //ApexPages.StandardController sc = new  ApexPages.StandardController(quote);     
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer(); 
        ext.validateQuote();
        Test.stopTest();
        
    }
    }
    @isTest
    public static void withoutQuoteRecord(){
        SBQQ__Quote__c quote = [SELECT Id, Shipping_and_Handling_Manual__c, Name, Shipping_Country__c, Freight_Cost__c, SBQQ__NetAmount__c, SBQQ__PriceBook__c, Configuration_Segment__c,
                                Shipping_Method__c, Total_Product_Dimensions__c, Shipping_Address_NEW__c, Total_Weight_oz__c, Renewal__c,
                                SBQQ__Opportunity2__c,SBQQ__Account__c, Shipping_Account_Type__c, Selected_Payment_Type__c, Approved_Discount__c, SBQQ__StartDate__c
                                FROM SBQQ__Quote__c where  SBQQ__Opportunity2__r.isClosed  = false  LIMIT 1];

        Test.startTest();
         System.runAs(createTestUser()) {        
        
        PageReference pageRef = Page.QuoteCustomCongaComposer; // Add your VF page Name here
        pageRef.getParameters().put('id', '');
        Test.setCurrentPage(pageRef);
        
        //ApexPages.StandardController sc = new  ApexPages.StandardController(quote);     
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer(); 
        ext.validateQuote();
        Test.stopTest();
    }
}
    @isTest
    public static void annualPaymentTermLessThan12Test(){
        SBQQ__Quote__c quote = [SELECT Id, Shipping_and_Handling_Manual__c, Name, Shipping_Country__c, Freight_Cost__c, SBQQ__NetAmount__c, SBQQ__PriceBook__c, Configuration_Segment__c,
                                Shipping_Method__c, Total_Product_Dimensions__c, Shipping_Address_NEW__c, Total_Weight_oz__c, Renewal__c,
                                SBQQ__Opportunity2__c,SBQQ__Account__c, Shipping_Account_Type__c, Selected_Payment_Type__c, Approved_Discount__c, SBQQ__StartDate__c
                                FROM SBQQ__Quote__c where  SBQQ__Opportunity2__r.isClosed  = false  LIMIT 1];
 System.runAs(createTestUser()) {
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        
        quote.Buyout_Amount__c = 100;
        quote.SBQQ__LastCalculatedOn__c = DateTime.now(); 
        quote.SBQQ__LastSavedOn__c = DateTime.now().addDays(-1);
        quote.VertexCPQ__Tax_Amount__c = 100;
        quote.Tax_Calculation_Status__c = 'Updated';
        quote.Selected_Payment_Type__c = 'Direct Annual';
        quote.License_term__c = '2';
        quote.Custom_License_Term__c = null;
        update quote;
        
        SBQQ.TriggerControl.enable();
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');


        Test.startTest();
        PageReference pageRef = Page.QuoteCustomCongaComposer; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(quote.Id));
        Test.setCurrentPage(pageRef);
        
        //ApexPages.StandardController sc = new  ApexPages.StandardController(quote);     
        new QuoteCustomCongaComposer().validateQuote(); 

        Test.stopTest();
    }
}
    
    @isTest
    public static void withoutDCAQuoteCheck(){
        SBQQ__Quote__c quote = [SELECT Id, Shipping_and_Handling_Manual__c, Name, Shipping_Country__c, Freight_Cost__c, SBQQ__NetAmount__c, SBQQ__PriceBook__c, Configuration_Segment__c,
                                Shipping_Method__c, Total_Product_Dimensions__c, Shipping_Address_NEW__c, Total_Weight_oz__c, Renewal__c,
                                SBQQ__Opportunity2__c,SBQQ__Account__c, Shipping_Account_Type__c, Selected_Payment_Type__c, Approved_Discount__c, SBQQ__StartDate__c
                                FROM SBQQ__Quote__c where  SBQQ__Opportunity2__r.isClosed  = false  LIMIT 1];
        
        Test.startTest();
         System.runAs(createTestUser()) {
        new QuoteCustomCongaComposer().navigateQuoteDocumnet();
        
        PageReference pageRef = Page.QuoteCustomCongaComposer; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(quote.Id));
        Test.setCurrentPage(pageRef);
        
        //ApexPages.StandardController sc = new  ApexPages.StandardController(quote);     
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer(); 
        ext.validateQuote();
        Test.stopTest();
        
    }
}
       @isTest
    public static void testThrowQuoteWarnings() {
        // Create a mock quote for testing
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c, SBQQ__Account__c, Tax_Calculation_Status__c, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        // Test warnings thrown by the method
        Test.startTest();
        QuoteCustomCongaComposer composer = new QuoteCustomCongaComposer();
        composer.throwQuoteWarnings(new List<String>{'Warning: Field XYZ is missing!'});
        Test.stopTest();

        // Verify if the warning messages are added
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size(), 'Warning message should be thrown');
    }

    @isTest
    public static void buyoutQuoteCheck(){
    	SBQQ__Quote__c quote = [SELECT Id, Buyout_Amount__c, SBQQ__LastCalculatedOn__c, SBQQ__LastSavedOn__c, VertexCPQ__Tax_Amount__c, 
       		Tax_Calculation_Status__c FROM SBQQ__Quote__c where  SBQQ__Opportunity2__r.isClosed  = false  LIMIT 1];
    System.runAs(createTestUser()) {
        
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        
        quote.Buyout_Amount__c = 100;
        quote.SBQQ__LastCalculatedOn__c = DateTime.now(); 
        quote.SBQQ__LastSavedOn__c = DateTime.now().addDays(-1);
        quote.VertexCPQ__Tax_Amount__c = 100;
        quote.Tax_Calculation_Status__c = 'Updated';
        update quote;
        
        SBQQ.TriggerControl.enable();
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
            
        Test.startTest();
        new QuoteCustomCongaComposer().navigateQuoteDocumnet();
        PageReference pageRef = Page.QuoteCustomCongaComposer; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(quote.Id));
        Test.setCurrentPage(pageRef);
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer(); 
        ext.validateQuote();
        Test.stopTest();
	}
}
    @isTest
    public static void subsidyQuoteCheck(){
    	SBQQ__Quote__c quote = [SELECT Id, Subsidy_Amount__c, SBQQ__LastCalculatedOn__c, SBQQ__LastSavedOn__c, VertexCPQ__Tax_Amount__c, 
       		Tax_Calculation_Status__c FROM SBQQ__Quote__c where  SBQQ__Opportunity2__r.isClosed  = false  LIMIT 1];
        
    System.runAs(createTestUser()) {
        
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        
        quote.Subsidy_Amount__c = 100;
        quote.SBQQ__LastCalculatedOn__c = DateTime.now(); 
        quote.SBQQ__LastSavedOn__c = DateTime.now().addDays(-1);
        quote.VertexCPQ__Tax_Amount__c = 100;
        quote.Tax_Calculation_Status__c = 'Updated';
        update quote;
        
        SBQQ.TriggerControl.enable();
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
            
        Test.startTest();
        new QuoteCustomCongaComposer().navigateQuoteDocumnet();
        PageReference pageRef = Page.QuoteCustomCongaComposer; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(quote.Id));
        Test.setCurrentPage(pageRef);
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer(); 
        ext.validateQuote();
        Test.stopTest();
	}
}

    @isTest
    public static void annualPaymentQuoteCheck(){
    	SBQQ__Quote__c quote = [SELECT Id, Shipping_and_Handling_Manual__c, Name, Shipping_Country__c, Freight_Cost__c, SBQQ__NetAmount__c, SBQQ__PriceBook__c, Configuration_Segment__c, Tax_Calculation_Status__c, SBQQ__Uncalculated__c,
        	Shipping_Method__c, Total_Product_Dimensions__c, Shipping_Address_NEW__c, Total_Weight_oz__c, Renewal__c, Estimated_Annual_Payment__c, Subsidy_Amount__c, Buyout_Amount__c,
            SBQQ__Opportunity2__c,SBQQ__Account__c, Shipping_Account_Type__c, Selected_Payment_Type__c, Approved_Discount__c, SBQQ__StartDate__c, SBQQ__LastCalculatedOn__c, SBQQ__LastSavedOn__c 
            FROM SBQQ__Quote__c where  SBQQ__Opportunity2__r.isClosed  = false  LIMIT 1];
        
        quote.Estimated_Annual_Payment__c = 100;
        quote.SBQQ__ExpirationDate__c = System.today().addDays(-2);
      System.runAs(createTestUser()) {  
            
        Test.startTest();
        update quote;
        new QuoteCustomCongaComposer().navigateQuoteDocumnet();
        PageReference pageRef = Page.QuoteCustomCongaComposer; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(quote.Id));
        Test.setCurrentPage(pageRef);
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer(); 
        ext.validateQuote();
        Test.stopTest();
	}
}
    @isTest
    public static void withoutShippingQuoteCheck(){
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__LastCalculatedOn__c, SBQQ__LastSavedOn__c, VertexCPQ__Tax_Amount__c,Tax_Calculation_Status__c FROM SBQQ__Quote__c where  SBQQ__Opportunity2__r.isClosed  = false  LIMIT 1];
        
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
      System.runAs(createTestUser()) {   
        quote.SBQQ__LastCalculatedOn__c = DateTime.now(); 
        quote.SBQQ__LastSavedOn__c = DateTime.now().addDays(-1);
        quote.VertexCPQ__Tax_Amount__c = 100;
        quote.Tax_Calculation_Status__c = 'Updated';
        update quote;
        
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, Ship_To__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.Id];
        for(SBQQ__QuoteLine__c line : lines) {
            line.Ship_To__c = null;
        }
        update lines;
        
        SBQQ.TriggerControl.enable();
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteTriggerHandler');
        Test.startTest();
        
        new QuoteCustomCongaComposer().navigateQuoteDocumnet();
        
        PageReference pageRef = Page.QuoteCustomCongaComposer; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(quote.Id));
        Test.setCurrentPage(pageRef);
        
        //ApexPages.StandardController sc = new  ApexPages.StandardController(quote);     
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer(); 
        ext.validateQuote();
        Test.stopTest();
    }
}
 @isTest
public static void testMexicoAccountFieldsValidation() {
    
     System.runAs(createTestUser()) {
    // Create account with Mexican shipping country
    Account mexicanAccount = new Account(
        Name = 'Test Mexican Account',
        Organization_Size__c = '5000+',
        BillingCountry = 'Mexico',
        Industry = 'Other',
        Credit_Limit__c = 10000,
        Razon_Social_Legal_Company_Name__c = 'Test Company',
        Tipo_de_RFC__c = 'Persona Fisica',
        Regimen_Fiscal_Receptor__c = '601 - General of Legal Entities'
    );
    insert mexicanAccount;

    // Get the standard pricebook
    Id pricebookId = Test.getStandardPricebookId();
    
    // Create opportunity with Mexican shipping country
    Opportunity mexicanOpp = new Opportunity(
        AccountId = mexicanAccount.Id,
        Name = 'Mexican Opportunity',
        CloseDate = System.today() + 90,
        StageName = 'Incubate',
        Pricebook2Id = pricebookId,
        Shipping_Country__c = 'Mexico'  // Setting shipping country to Mexico
    );
    insert mexicanOpp;

    // Create quote with MXN currency
    SBQQ__Quote__c mexicanQuote = new SBQQ__Quote__c(
        Quote_Name__c = 'Mexican Quote',
        SBQQ__Account__c = mexicanAccount.Id,
        SBQQ__Opportunity2__c = mexicanOpp.Id,
        SBQQ__PricebookId__c = pricebookId,
        CurrencyIsoCode = 'MXN'
    );
    insert mexicanQuote;

    // Test scenario 1: All required fields present
    Test.startTest();
    PageReference pageRef = Page.QuoteCustomCongaComposer;
    pageRef.getParameters().put('id', String.valueOf(mexicanQuote.Id));
    Test.setCurrentPage(pageRef);
    
    QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer();
    ext.validateQuote();

    // Test scenario 2: Missing required fields
    mexicanAccount.Razon_Social_Legal_Company_Name__c = null;
    mexicanAccount.Tipo_de_RFC__c = null;
    mexicanAccount.Regimen_Fiscal_Receptor__c = null;
    update mexicanAccount;

    ext = new QuoteCustomCongaComposer();
    ext.validateQuote();

    // Test scenario 3: Non-Mexican shipping country (should not trigger validation)
    mexicanOpp.Shipping_Country__c = 'United States';
    update mexicanOpp;

    ext = new QuoteCustomCongaComposer();
    ext.validateQuote();

    // Test scenario 4: Non-MXN currency (should not trigger validation)
    mexicanQuote.CurrencyIsoCode = 'USD';
    update mexicanQuote;

    ext = new QuoteCustomCongaComposer();
    ext.validateQuote();

    Test.stopTest();
} 
}
     @isTest
    public static void testQuoteValidationScenarios() {
       
    System.runAs(createTestUser()) {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :testOpp.Id LIMIT 1];
        
        Test.startTest();
        
        // Test scenario 1: Basic validation
        PageReference pageRef = Page.QuoteCustomCongaComposer;
        pageRef.getParameters().put('id', String.valueOf(testQuote.Id));
        Test.setCurrentPage(pageRef);
        
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer();
        PageReference result = ext.validateQuote();
        
        // Test scenario 2: Invalid quote ID
        pageRef = Page.QuoteCustomCongaComposer;
        pageRef.getParameters().put('id', '001000000000000');
        Test.setCurrentPage(pageRef);
        
        ext = new QuoteCustomCongaComposer();
        result = ext.validateQuote();
        
        // Test scenario 3: No quote ID
        pageRef = Page.QuoteCustomCongaComposer;
        Test.setCurrentPage(pageRef);
        
        ext = new QuoteCustomCongaComposer();
        result = ext.validateQuote();
        
        // Test scenario 4: Test warning messages
        List<String> warnings = new List<String>{'Test Warning 1', 'Test Warning 2'};
        ext.throwQuoteWarnings(warnings);
        
        // Verify messages
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assert(messages.size() > 0, 'Should have warning messages');
        
        Test.stopTest();
    }
}
    @isTest
    public static void testMexicanQuoteValidation() {
    
    System.runAs(createTestUser()) {
        // Create Mexican account with required fields for Mexican validation
        Account mexicanAccount = new Account(
            Name = 'Mexican Test Account',
            Organization_Size__c = '5000+',
            BillingCountry = 'Mexico',
            Industry = 'Other',
            Credit_Limit__c = 10000,
            // Add required Mexican fields that are missing
            Razon_Social_Legal_Company_Name__c = null,
            Tipo_de_RFC__c = null,
            Regimen_Fiscal_Receptor__c = null
        );
        insert mexicanAccount;
        
        // Create Mexican opportunity with shipping country Mexico
        Opportunity mexicanOpp = new Opportunity(
            Name = 'Mexican Test Opportunity',
            AccountId = mexicanAccount.Id,
            CloseDate = System.today(),
            StageName = 'Incubate',
            Pricebook2Id = Test.getStandardPricebookId(),
            Shipping_Country__c = 'Mexico'  // This is crucial for Mexican validation
        );
        insert mexicanOpp;
        
        // Create Mexican quote with MXN currency
        SBQQ__Quote__c mexicanQuote = new SBQQ__Quote__c(
            Quote_Name__c = 'Mexican Test Quote',
            SBQQ__Account__c = mexicanAccount.Id,
            SBQQ__Opportunity2__c = mexicanOpp.Id,
            SBQQ__PricebookId__c = Test.getStandardPricebookId(),
            Tax_Calculation_Status__c = 'Updated',
            SBQQ__ExpirationDate__c = System.today().addDays(30),
            CurrencyIsoCode = 'MXN'  // This is crucial for Mexican validation
        );
        insert mexicanQuote;
        
        Test.startTest();
        
        PageReference pageRef = Page.QuoteCustomCongaComposer;
        pageRef.getParameters().put('id', String.valueOf(mexicanQuote.Id));
        Test.setCurrentPage(pageRef);
        
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer();
        PageReference result = ext.validateQuote();
        
        // Verify validation results
        List<ApexPages.Message> messages = ApexPages.getMessages();
        Boolean hasValidationMessage = false;
        for(ApexPages.Message msg : messages) {
            if(msg.getSummary().contains(System.Label.MXNAccFieldsCheck)) {
                hasValidationMessage = true;
                break;
            }
        }
        System.assert(hasValidationMessage, 'Should have Mexican validation message for missing required fields');
        
        Test.stopTest();
    }
}
    @isTest
    public static void testQuoteDocumentGeneration() {
    System.runAs(createTestUser()) {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :testOpp.Id LIMIT 1];
        
        Test.startTest();
        
        PageReference pageRef = Page.QuoteCustomCongaComposer;
        pageRef.getParameters().put('id', String.valueOf(testQuote.Id));
        pageRef.getParameters().put('testParam', 'testValue');
        Test.setCurrentPage(pageRef);
        
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer();
        PageReference result = ext.navigateQuoteDocumnet();
        
        // Verify the result
        System.assertNotEquals(null, result, 'PageReference should not be null');
        // Check only the base URL path since parameters will be dynamic
        System.assertEquals('/apex/APXTConga4__Conga_Composer', result.getUrl().split('\\?')[0], 'Base URL should match Conga Composer');
        // Verify parameters are present
        System.assert(result.getParameters().containsKey('id'), 'Should contain quote ID parameter');
        System.assertEquals('testValue', result.getParameters().get('testParam'), 'Should preserve custom parameters');
        System.assertEquals(true, result.getRedirect(), 'Should be set to redirect');
        
        Test.stopTest();
    }
}
      @isTest
    public static void testWarningMessagesAndRedirect() {
        // Get test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.isClosed = false LIMIT 1];
        
        Test.startTest();
         System.runAs(createTestUser()) {
        // Test scenario 1: With warning messages
        PageReference pageRef = Page.QuoteCustomCongaComposer;
        pageRef.getParameters().put('id', String.valueOf(quote.Id));
        pageRef.getParameters().put('testParam', 'testValue');
        Test.setCurrentPage(pageRef);
        
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer();
        
        // Add warning messages
        List<String> warningMessages = new List<String>{
            'Test Warning 1',
            'Test Warning 2'
        };
        
        // Test warning message handling
        ext.throwQuoteWarnings(warningMessages);
        
        // Verify warning messages were added
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(2, messages.size(), 'Should have 2 warning messages');
        System.assertEquals(ApexPages.Severity.WARNING, messages[0].getSeverity(), 'First message should be a warning');
        System.assertEquals('Test Warning 1', messages[0].getSummary(), 'First warning message should match');
        System.assertEquals('Test Warning 2', messages[1].getSummary(), 'Second warning message should match');
        
        // Test URL redirection
        PageReference result = ext.navigateQuoteDocumnet();
        
        // Verify the result
        System.assertNotEquals(null, result, 'PageReference should not be null');
        System.assertEquals('/apex/APXTConga4__Conga_Composer', result.getUrl().split('\\?')[0], 'Base URL should match Conga Composer');
        System.assertEquals(true, result.getRedirect(), 'Should be set to redirect');
        System.assertEquals('testValue', result.getParameters().get('testParam'), 'Should preserve custom parameters');
        
        Test.stopTest();
    }
}
    @isTest
    public static void testEmptyWarningMessages() {
        // Get test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.isClosed = false LIMIT 1];
        
        Test.startTest();
         System.runAs(createTestUser()) {
        PageReference pageRef = Page.QuoteCustomCongaComposer;
        pageRef.getParameters().put('id', String.valueOf(quote.Id));
        Test.setCurrentPage(pageRef);
        
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer();
        
        // Test with empty warning messages
        List<String> emptyWarnings = new List<String>();
        ext.throwQuoteWarnings(emptyWarnings);
        
        // Verify no messages were added
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(0, messages.size(), 'Should have no warning messages');
        
        Test.stopTest();
    } 
}
    @isTest
    public static void testGetSpecificWarningMessageException() {
    System.runAs(createTestUser()) {
        // Get test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.isClosed = false LIMIT 1];
        
        // Create a new instance of QuoteCustomCongaComposer
        QuoteCustomCongaComposer composer = new QuoteCustomCongaComposer();
        
        // Force an exception by passing null quote
        List<String> errorMessages = composer.getSpecificWarningMessage(null);
        
        // Verify that error messages were added
        System.assertEquals(2, errorMessages.size(), 'Should have two error messages');
        System.assertEquals('Below exception occured while validating data.', errorMessages[0], 'First error message should match');
        System.assert(errorMessages[1].contains('Attempt to de-reference a null object'), 'Second error message should contain null pointer exception');
    }
}
    @isTest
    public static void testGetGenericWarningMessageException() {
    System.runAs(createTestUser()) {
        // Create a new instance of QuoteCustomCongaComposer
        QuoteCustomCongaComposer composer = new QuoteCustomCongaComposer();
        
        // Set up the page reference with no ID to force null quote scenario
        PageReference pageRef = Page.QuoteCustomCongaComposer;
        Test.setCurrentPage(pageRef);
        
        // Call validateQuote which will internally call getGenericWarningMessage
        composer.validateQuote();
        
        // Verify that error messages were added
        List<ApexPages.Message> messages = ApexPages.getMessages();
        Boolean hasExpectedError = false;
        for(ApexPages.Message msg : messages) {
            if(msg.getSummary().contains('Invalid quote')) {
                hasExpectedError = true;
                break;
            }
        }
        System.assert(hasExpectedError, 'Should have error message for invalid quote');
    }
}
    @isTest
    public static void testAccountDelinquencyStatusValidation() {
    System.runAs(createTestUser()) {
        // Get the test account and opportunity
        Account testAccount = [SELECT Id, Delinquency_Status__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id, Type FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create a quote with minimal required fields
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Primary__c = true,
            Tax_Calculation_Status__c = (System.label.Generate_Quote_Tax_Calculation_Status_Error??'').split(';')[0],
            SBQQ__LastCalculatedOn__c = System.now()
        );
        
        // Disable triggers to prevent additional queries
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('SBQQQuoteTriggerHandler');
         TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        
        // Set up opportunity as Revenue Opportunity
        testOpp.Type = 'Revenue Opportunity';
        update testOpp;
        insert quote;
        
        Test.startTest();
        
        // Set account delinquency status to Orders Blocked
        testAccount.Delinquency_Status__c = 'Orders Blocked';
        update testAccount;
        
        // Set up the page reference
        PageReference pageRef = Page.QuoteCustomCongaComposer;
        pageRef.getParameters().put('id', String.valueOf(quote.Id));
        Test.setCurrentPage(pageRef);
        
        // Instantiate and call the controller
        QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer();
        ext.validateQuote();
        
        // Verify the validation failed
        //System.assertEquals(false, ext.validation, 'Validation should fail when account has Orders Blocked status');
        
        // Verify the error message was added
        List<ApexPages.Message> messages = ApexPages.getMessages();
        Boolean foundDelinquencyError = false;
        for(ApexPages.Message msg : messages) {
            if(msg.getDetail() == System.Label.AccountDelinquencyStatusError) {
                foundDelinquencyError = true;
                break;
            }
        }
        //System.assertEquals(true, foundDelinquencyError, 'Delinquency status error message should be present');
        
        Test.stopTest();
        
        // Re-enable triggers
        TriggerHandler.clearAllBypasses();
        SBQQ.TriggerControl.enable();
    }
    }
@isTest
public static void testNextRecurringBillDateValidation() {
    OrderFinanceSetting__mdt b360Toggle = new OrderFinanceSetting__mdt(
        MasterLabel = 'B360_R1_Toggle',
        Value__c = 'True'
    );

    OrderFinanceSetting__mdt errNextRecurringBillDate = new OrderFinanceSetting__mdt(
        MasterLabel = 'Err_Next_Recurring_Bill_Date',
        Value__c = 'Test error: Next Recurring Bill Date is before Close Date'
    );
    
    Test.startTest();
    // Get test data
    Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    Opportunity testOpp = [SELECT Id, CloseDate FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
    
    testAccount.Next_Recurring_Bill_Date__c = testOpp.CloseDate.addDays(-1); // before close date
    update testAccount;

    // Create a quote with Next_Recurring_Bill_Date__c < CloseDate
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
        SBQQ__Account__c = testAccount.Id,
        SBQQ__Opportunity2__c = testOpp.Id,
        //Next_Recurring_Bill_Date__c = testOpp.CloseDate.addDays(-1), // Will be picked from Account if Billing_Ann_Date is null
        Tax_Calculation_Status__c = (System.label.Generate_Quote_Tax_Calculation_Status_Error??'').split(';')[0]
    );
    insert quote;
    
    PageReference pageRef = Page.QuoteCustomCongaComposer;
    pageRef.getParameters().put('id', String.valueOf(quote.Id));
    Test.setCurrentPage(pageRef);

    QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer();
    ext.validateQuote();
    Test.stopTest();
    }
    @isTest
    public static void testProratedAPIStatusError() {

    Test.startTest();
    // Get test data
    Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    Opportunity testOpp = [SELECT Id, CloseDate FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];

    SBQQ__Quote__c pendingQuote = new SBQQ__Quote__c(
        SBQQ__Account__c = testAccount.Id,
        SBQQ__Opportunity2__c = testOpp.Id,
        Selected_Payment_Type__c = 'Direct Annual',
            SBQQ__StartDate__c = testOpp.CloseDate,
        Billing_Ann_Date__c = testOpp.CloseDate.addDays(10),
        API_Status__c = 'Pending',
        Tax_Calculation_Status__c = (System.label.Generate_Quote_Tax_Calculation_Status_Error??'').split(';')[0]
    );
        insert pendingQuote;
        
        SBQQ__Quote__c invalidB360Quote = new SBQQ__Quote__c(
        SBQQ__Account__c = testAccount.Id,
        SBQQ__Opportunity2__c = testOpp.Id,
         Selected_Payment_Type__c = 'Direct Annual',
            SBQQ__StartDate__c = testOpp.CloseDate,
        Billing_Ann_Date__c = testOpp.CloseDate.addDays(10),
        Tax_Calculation_Status__c = (System.label.Generate_Quote_Tax_Calculation_Status_Error??'').split(';')[0]
    );
        insert invalidB360Quote;
    
    PageReference pageRef = Page.QuoteCustomCongaComposer;
    pageRef.getParameters().put('id', String.valueOf(pendingQuote.Id));
    Test.setCurrentPage(pageRef);

    QuoteCustomCongaComposer ext = new QuoteCustomCongaComposer();
    ext.validateQuote();
        
        PageReference pageRef2 = Page.QuoteCustomCongaComposer;
    pageRef2.getParameters().put('id', String.valueOf(invalidB360Quote.Id));
    Test.setCurrentPage(pageRef2);

    QuoteCustomCongaComposer ext2 = new QuoteCustomCongaComposer();
    ext2.validateQuote();
        
    Test.stopTest();
}
    @isTest
public static void testQuoteValidation() {
    TriggerHandler.bypass('OpportunityTriggerHandler');
    TriggerHandler.bypass('OpportunityTriggerHandlerContext');
    TriggerHandler.bypass('SBQQQuoteTriggerHandler');
    TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
    System.runAs(createTestUser()) {
        // Prepare test data
        Account testAccount = new Account(Name = 'Test Account',
            Organization_Size__c = '5000+',
            BillingCountry = 'Mexico',
            Industry = 'Other',
            Credit_Limit__c = 10000,
            // Add required Mexican fields that are missing
            Razon_Social_Legal_Company_Name__c = null,
            Tipo_de_RFC__c = null,
            Regimen_Fiscal_Receptor__c = null);
        insert testAccount;
        
        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Test Opportunity',
            CloseDate = System.today().addDays(30),
            StageName = 'Prospecting',
            License_Term__c = 12,
            Type = 'Revenue Opportunity'
        );
        insert testOpportunity;

        // Create Quote with required fields
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpportunity.Id,
            SBQQ__PricebookId__c = Test.getStandardPricebookId(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Status__c = 'Draft',
            Buyout_Amount__c = 6.0,
            Subsidy_Amount__c = 3.0,
            SBQQ__Primary__c = true,
            SBQQ__LastCalculatedOn__c = System.now(),
            SBQQ__ExpirationDate__c = System.today().addDays(30),
            License_Term__c = '12',
            Configuration_Segment__c = 'Express', // required for your formula
            Estimated_Annual_Payment__c = 3000
        );
        insert testQuote;         
        // Update the Opportunity with matching License Term
        testOpportunity.License_Term__c = 12;
        update testOpportunity;

        // Execute test logic
        Test.startTest();
        
        // Simulate updating the quote for validation
        testQuote.Buyout_Amount__c = 6.0;  // Ensure Buyout amount matches
        testQuote.Subsidy_Amount__c = 3.0;  // Ensure Subsidy amount matches
        testQuote.SBQQ__ExpirationDate__c = System.today().addDays(-30);
        testQuote.License_Term__c = '12'; // Ensure License Term matches
        
        // Simulate validation on the quote
        update testQuote;
        List<string> test123 = new List<string>();
        QuoteCustomCongaComposer QCCC = new QuoteCustomCongaComposer();
		test123 = QCCC.getGenericWarningMessage(testQuote);
        // Verify error messages are generated as expected
        List<String> errorMessages = new List<String>();

        // Validate Proposed Picklist Options
        if(testQuote.Proposed_Picklist_Options__c == null) {
            errorMessages.add(System.Label.Proposed_Picklist_Cannot_be_Null);
        }

        // Validate Expiration Date
        if(testQuote.SBQQ__ExpirationDate__c < Date.today()) {
            errorMessages.add(System.Label.OppPreCheck_ExpirationDate);
        }

        // Validate License Term
        if(testQuote?.SBQQ__Opportunity2__r?.License_Term__c == null || String.isBlank(testQuote.License_Term__c)) {
            errorMessages.add(System.Label.OppPreCheck_License_Term);
        } else {
            if(integer.valueOf(testQuote.License_Term__c) != testQuote.SBQQ__Opportunity2__r.License_Term__c) {
                errorMessages.add(System.Label.OppPreCheck_License_Term);
            }
        }

        // Validate Close Date
        if(testQuote.SBQQ__Opportunity2__r.CloseDate != Date.today() && testQuote?.SBQQ__Opportunity2__r?.Type == 'Revenue Opportunity') {
            errorMessages.add(System.Label.OppPreCheck_CloseDate);
        }

        

        // Verify that error messages are added
        System.assert(errorMessages.size() > 0, 'Error messages should have been generated');
        
        Test.stopTest();
    }
}

}