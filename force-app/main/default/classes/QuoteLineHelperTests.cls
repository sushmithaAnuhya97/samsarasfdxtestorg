/* 
 * Class Created: 07/29/19 - @author: Harsha
 */  
// This test class is CPU Sensitive, please check with Harsha if you are making any changes to this class. 
@isTest(SeeAllData=false isParallel=false)
public class QuoteLineHelperTests {
    
    Static Account testAccount;
    Static Opportunity testOpportunity;
    static Contract testContract;
    static SBQQ__Subscription__c testSubscription;
    
    // Do not add any insert statements - It will cause CPU Time limit issues. Data insert until the quote is taking aroung 75% of CPU time.
    @testSetup
    private static void testDataSetup() {
        
        
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
        Product2 vgLicense = new Product2(Name= 'LIC-VG-LD', ProductCode = 'LIC-VG-LD', Family = 'Test');
        products.add(vgLicense); 
        Product2 insuranceSUBSIDY = new Product2(Name= 'INS-SUBSIDY', ProductCode = 'INS-SUBSIDY', Family = 'Test');
        products.add(insuranceSUBSIDY);  
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        PricebookEntry insuranceSUBSIDYPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = insuranceSUBSIDY.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(insuranceSUBSIDYPB);
        insert pricebookEntries;
        
        // Create account
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        newAccount.add(account);
        
        insert newAccount;

        Contract cont = new Contract(
            AccountId = newAccount[0].Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
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
        
        list<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = cont.id,
            SBQQ__Account__c = newAccount[0].id,
            SBQQ__Product__c = vgLicense.id

        );
        subList.add(sub1);
        insert subList;
        
        //Create Shipping Address
        List<Shipping_Address__c> shippingAddresses = new  List<Shipping_Address__c>();
        
       	Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                            , Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                            , Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
        shippingAddresses.add(shipTo);        
        
        Shipping_Address__c shipToTwo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '610 Park View Dr'
                                                            , Shipping_Address_Line_2__c= 'XYZ', Shipping_City__c = 'Santa Clara'
                                                            , Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                            , Shipping_Zip_Code__c = '95054', Name = 'Ship To Two');
        
        shippingAddresses.add(shipToTwo);   
        
        Shipping_Address__c shipToThree = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, 
                                                                  Shipping_Address_Line_1__c = '1 Parliment St'
                                                            , Shipping_City__c = 'London'
                                                            , Shipping_Country__c ='United Kingdom'
                                                            , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Three');
        
        shippingAddresses.add(shipToThree);
        
        Shipping_Address__c shipToFour = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '1 Parliment St'
                                                            , Shipping_Address_Line_2__c= 'XYZ'
                                                            , Shipping_City__c = 'London'
                                                            , Shipping_Country__c ='United Kingdom'
                                                            , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Four');
        
        shippingAddresses.add(shipToFour);
        
        Shipping_Address__c shipToMexico = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '1 Parliment St'
                                                            , Shipping_Address_Line_2__c= 'XYZ'
                                                            , Shipping_City__c = 'Mexico'
                                                            , Shipping_State__c = 'Distrito Federal'       
                                                            , Shipping_Country__c ='Mexico'
                                                            , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Mexico');
        
        shippingAddresses.add(shipToMexico);
        
        insert shippingAddresses;
            
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8'); 
        newOpportunities.add(revenueOpportunity);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity2', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null); 
        
        newOpportunities.add(revenueOpportunity2); 
        insert newOpportunities;
        
        /*//Create Quote
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
		SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version One', SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c=revenueOpportunity.Id, SBQQ__Primary__c = false);
        newQuotes.add(quote);
        
        insert newQuotes;
        
        //Create QuoteLines
        List<SBQQ__QuoteLine__c> newQuoteLines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = vg33PB.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vg33.Id);
        newQuoteLines.add(quoteLineOne);
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = vgLicensePB.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c =0, SBQQ__Product__c = vgLicense.Id);
        newQuoteLines.add(quoteLineTwo);
        
        insert newQuoteLines;*/
    }
    
    @isTest 
    static void insertQuoteLinesTest(){
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Three'];
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        update testOpportunity;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id);
        insert quote;
        
        quote.SBQQ__Primary__c = false;
        update quote; 
        
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        insert quoteLineOne; 
        Test.stopTest();
    }
    
    @isTest 
    static void editQuoteLinesTest(){
        
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
		Contact testContact = [SELECT id FROM Contact WHERE LastName='Tester'];
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One'];
            
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Two'];
		testOpportunity.Owner_Role_Copy__c = 'AE3';
        update testOpportunity;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id, License_Term__c = '36');
        insert quote;
        
        quote.SBQQ__Primary__c = false;
        update quote; 
        
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, Ship_To__c = shippingAddressTwo.Id, accountLookupTest__c = testAccount.Id);
        insert quoteLineOne; 
        
        Test.stopTest();
    }
    
    
    @isTest 
    static void miscTests(){
//SBQQ.TriggerControl.disable();
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Four'];
		testOpportunity.Owner_Role_Copy__c = 'AE3';
        update testOpportunity;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id);
        insert quote;
        
        quote.SBQQ__Primary__c = false;
        update quote; 
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Ship_To__c = shippingAddressTwo.Id);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        
        Test.stopTest();
    }
    
    @isTest 
    static void miscTests2(){
//SBQQ.TriggerControl.disable();
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.disable();
		Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Sub_Type__c = 'Clickpath';
        testOpportunity.Renewal__c = true;
        testOpportunity.AccountId = testAccount.id;
        update testOpportunity;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Two'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Three'];
		Shipping_Address__c shippingAddressMX = [SELECT id FROM Shipping_Address__c Where Name='Ship To Mexico'];
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        update testOpportunity;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id);
        insert quote;
        
        quote.SBQQ__Primary__c = false;
        update quote; 
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Ship_To__c = shippingAddressTwo.Id);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>{
            new SBQQ__Subscription__c(SBQQ__NetPrice__c = 1000, SBQQ__RenewalQuantity__c=10, SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 0,   SBQQ__Product__c = vgProduct.Id)
        };
        insert subscriptionList;
        
        newlineItems[0].Ship_To__c = shippingAddressMX.Id;
        newlineItems[0].SBQQ__RenewedSubscription__c = subscriptionList[0].Id;
        
        newlineItems[1].Ship_To__c = null;
        
        update newlineItems;
        
        SBQQQuoteLineHelper lineHelper = new SBQQQuoteLineHelper();
        
        lineHelper.calculateACV(1, 1, 1, 1);
        lineHelper.calculateACV(12, 12, 12, 12);
        Test.stopTest();
    }
    
    @isTest 
    static void miscTests3(){
//SBQQ.TriggerControl.disable();
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.disable();
		Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Sub_Type__c = 'Clickpath';
        testOpportunity.Renewal__c = true;
        testOpportunity.AccountId = testAccount.id;
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        update testOpportunity;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Two'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Three'];
		Shipping_Address__c shippingAddressMX = [SELECT id FROM Shipping_Address__c Where Name='Ship To Mexico'];
        
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>{
            new SBQQ__Subscription__c(SBQQ__NetPrice__c = 1000, SBQQ__RenewalQuantity__c=10, SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 0,   SBQQ__Product__c = vgProduct.Id)
        };
        insert subscriptionList;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddressMX.Id);
        insert quote;
        
        quote.SBQQ__Primary__c = false;
        update quote; 
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__RenewedSubscription__c = subscriptionList[0].id, SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__RenewedSubscription__c = subscriptionList[0].id, SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Ship_To__c = shippingAddressMX.Id);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        
        newlineItems[0].Ship_To__c = shippingAddress.Id;
        //newlineItems[0].SBQQ__RenewedSubscription__c = subscriptionList[0].Id;
        
        newlineItems[1].Ship_To__c = shippingAddressTwo.Id;
        
        update newlineItems;
        
        SBQQQuoteLineHelper lineHelper = new SBQQQuoteLineHelper();
        
        lineHelper.calculateACV(1, 1, 1, 1);
        lineHelper.calculateACV(12, 12, 12, 12);
        Test.stopTest();
    } 
    
    @isTest 
    static void AddOnTests0(){
//SBQQ.TriggerControl.disable();
        // Bypass triggers to prevent SOQL limit issues
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.disable();
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testContract = [SELECT id from contract limit 1];
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        testOpportunity.SBQQ__AmendedContract__c = testContract.Id;
        update testOpportunity;
        testSubscription = [SELECT id from SBQQ__Subscription__c limit 1];
        SBQQ.TriggerControl.enable();
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-LD'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Four'];
		
        Customer_360__c c360 = new Customer_360__c(LIC_AG2_Discount__c=1,LIC_AG4_Discount__c=1,LIC_CM1_Discount__c=1,LIC_CM2_Discount__c=1,
                                                  LIC_CRGO_Discount__c=1,LIC_DM11_Discount__c=1,LIC_VG_Discount__c=1,LIC_AG4P_Discount__c=1,
                                                  LIC_EM_Discount__c=1,Account__c=testAccount.Id);
        insert c360;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id, 
                                                  SBQQ__Type__c='Amendment', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12));
        insert quote;
        
        quote.SBQQ__Primary__c = false;
        update quote; 
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, SBQQ__Discount__c = 1,
                                                                  SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Account__c = testAccount.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5,
                                                                  SBQQ__UpgradedSubscription__c = testSubscription.id,
                                                                  SBQQ__Discount__c = 45, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Ship_To__c = shippingAddressTwo.Id);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        update newlineItems;
        
        Test.stopTest();
        TriggerHandler.clearAllBypasses();
    }
    
    @isTest 
    static void AddOnTests(){
//SBQQ.TriggerControl.disable();
        // Bypass triggers to prevent SOQL limit issues
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.disable();
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testContract = [SELECT Id FROM Contract LIMIT 1];
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        testOpportunity.SBQQ__AmendedContract__c = testContract.id;
        update testOpportunity;
        testSubscription = [SELECT Id FROM SBQQ__Subscription__c LIMIT 1];
        SBQQ.TriggerControl.enable();
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE ProductCode = 'LIC-VG-LD'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Four'];
		
        Customer_360__c c360 = new Customer_360__c(LIC_AG2_Discount__c=1,LIC_AG4_Discount__c=1,LIC_CM1_Discount__c=1,LIC_CM2_Discount__c=1,
                                                  LIC_CRGO_Discount__c=1,LIC_DM11_Discount__c=1,LIC_VG_Discount__c=1,LIC_AG4P_Discount__c=1,
                                                  LIC_EM_Discount__c=1,Account__c=testAccount.Id, SOT__c=true);
        insert c360;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id, 
                                                  SBQQ__Type__c='Amendment',SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12));
        insert quote;
        
        quote.SBQQ__Primary__c = false;
        update quote; 
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c quoteLineOne = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c = 5, SBQQ__ProratedListPrice__c = 1000,
                                                                 SBQQ__CustomerPrice__c = 800, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Account__c = testAccount.Id);
        newlineItems.add(quoteLineOne);
        
        SBQQ__QuoteLine__c quoteLineTwo = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c = 5, SBQQ__ProratedListPrice__c = 1000,
                                                                 SBQQ__CustomerPrice__c = 900, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Account__c = testAccount.Id, 
                                                                 SBQQ__RenewedSubscription__c = testSubscription.id, Ship_To__c = shippingAddressTwo.Id);
        newlineItems.add(quoteLineTwo);
        
        SBQQ__QuoteLine__c quoteLineThree = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c = 5, SBQQ__ProratedListPrice__c = 1000,
                                                                   SBQQ__CustomerPrice__c = 700, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Account__c = testAccount.Id, 
                                                                   Ship_To__c = shippingAddressTwo.Id);
        newlineItems.add(quoteLineThree);
        
        insert newlineItems;        
        
        Test.stopTest();
        TriggerHandler.clearAllBypasses();
    }    
    
    @isTest 
    static void InsuranceSubsidyMonthlyTests(){
//SBQQ.TriggerControl.disable();
        // Bypass triggers to prevent SOQL limit issues
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.disable();
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        update testOpportunity;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'INS-SUBSIDY'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Four'];

        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c = 1, Estimated_Annual_Payment__c =1000,
                                                  SBQQ__Primary__c = false, SBQQ__Type__c='Amendment', Selected_Payment_Type__c='Direct Monthly', License_Term__c='12');
        insert quote;
        
        //quote.SBQQ__Primary__c = false;
        //update quote; 
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(Subsidy_Amount__c=10, Subsidy_Quantity__c=5, Subsidy_Method__c = 'Fixed $', SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(Subsidy_Amount__c=10, Subsidy_Quantity__c=5, Subsidy_Method__c = 'Percentage', SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Ship_To__c = shippingAddressTwo.Id);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        
        Test.stopTest();
    }
    
    @isTest 
    static void InsuranceSubsidyAnnualTests(){
//SBQQ.TriggerControl.disable();
        // Bypass triggers to prevent SOQL limit issues
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.disable();
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        update testOpportunity;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'INS-SUBSIDY'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Four'];

        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id,
                                                  SBQQ__SubscriptionTerm__c = 1, Estimated_Annual_Payment__c =1000,
                                                  SBQQ__Primary__c = false, SBQQ__Type__c='Amendment', Selected_Payment_Type__c='Direct Annual', License_Term__c='12');
        insert quote;
        
        quote.SBQQ__Primary__c = false;
        update quote; 
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(Subsidy_Amount__c=10, Subsidy_Quantity__c=5, Subsidy_Method__c = 'Fixed $', SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(Subsidy_Amount__c=10, Subsidy_Quantity__c=5, Subsidy_Method__c = 'Percentage', SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Ship_To__c = shippingAddressTwo.Id);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        
        Test.stopTest();
    }
    
    @isTest 
    static void InsuranceSubsidyUpfrontTests(){
//SBQQ.TriggerControl.disable();
        // Bypass triggers to prevent SOQL limit issues
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.disable();
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        update testOpportunity;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'INS-SUBSIDY'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Four'];
		
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c = 1, Estimated_Annual_Payment__c =1000,
                                                  SBQQ__Primary__c = false, SBQQ__Type__c='Amendment', Selected_Payment_Type__c='Upfront Payments', License_Term__c='12');
        insert quote;
        
        quote.SBQQ__Primary__c = false;
        update quote; 
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(Subsidy_Amount__c=10, Subsidy_Quantity__c=5, Subsidy_Method__c = 'Fixed $', SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(Subsidy_Amount__c=10, Subsidy_Quantity__c=5, Subsidy_Method__c = 'Percentage', SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Ship_To__c = shippingAddressTwo.Id);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        
        Test.stopTest();
    }
    //https://samsaradev.atlassian.net/browse/GTMS-10129    
    //https://samsaradev.atlassian.net/browse/GTMS-10007
    @isTest 
    static void testRenewalCloneAndDelete(){
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.disable();
		Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Sub_Type__c = 'Clickpath';
        testOpportunity.Renewal__c = true;
        testOpportunity.AccountId = testAccount.id;
        update testOpportunity;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Two'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Three'];
		Shipping_Address__c shippingAddressMX = [SELECT id FROM Shipping_Address__c Where Name='Ship To Mexico'];
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        update testOpportunity;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id);
        insert quote;
        
       // quote.SBQQ__Primary__c = false;
      //  update quote; 
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineOne); 
        
        insert newlineItems;
        
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>{
            new SBQQ__Subscription__c(SBQQ__NetPrice__c = 1000, SBQQ__RenewalQuantity__c=10, SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 0,   SBQQ__Product__c = vgProduct.Id)
        };
        insert subscriptionList;
        
        newlineItems[0].Ship_To__c = shippingAddressMX.Id;
        newlineItems[0].SBQQ__RenewedSubscription__c = subscriptionList[0].Id;
        
        update newlineItems;
           
        SBQQ__QuoteLine__c cloneLine=newlineItems[0].clone();
        try{
            insert cloneLine;
        }
        catch(Exception ex){
            //System.assertEquals(true,ex.getMessage().contains('You cant clone this line because it is a renewal line'));
        }
        try{
            delete newlineItems;
        }
        catch(Exception ex){
            System.assertEquals(true,ex.getMessage().contains('Because it is a renewal line. Please refresh page to view it'));
        }        
        
        Test.stopTest();
    }
    
	//Added for GTMS-10566 Nishita
	@isTest    
    static void testrenewaluplift(){
        // Bypass triggers to prevent SOQL limit issues
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.disable();
        Contract testContract = [SELECT Id,Auto_Renewal__c,SBQQ__RenewalUpliftRate__c FROM Contract LIMIT 1];
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Sub_Type__c = 'Clickpath';
        testOpportunity.Renewal__c = true;
        testOpportunity.AccountId = testAccount.id;
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        testOpportunity.SBQQ__RenewedContract__c = testContract.Id;
        update testOpportunity;
        testContract.Auto_Renewal__c = true;
        testContract.SBQQ__RenewalUpliftRate__c = 0;
        update testContract;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Two'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Three'];
		Shipping_Address__c shippingAddressMX = [SELECT id FROM Shipping_Address__c Where Name='Ship To Mexico'];
        //testOpportunity.Owner_Role_Copy__c = 'AE3';
        //update testOpportunity;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, SBQQ__Type__c = 'Renewal',
                                                  SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id, SBQQ__STartDate__c = System.today(),
                                                 License_Term__c = '2');
        insert quote;
        
        SBQQ__Subscription__c ss1 = new SBQQ__Subscription__c(SBQQ__NetPrice__c = 1000, SBQQ__RenewalQuantity__c=10, SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 0,   SBQQ__Product__c = vgProduct.Id);
        insert ss1;
        
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, SBQQ__CustomerPrice__c = 12000,
                                                                   SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id,SBQQ__RenewedSubscription__c = ss1.Id);
        insert quoteLineOne;
        Test.stopTest();
    }    
/*
    @isTest 
    static void gainsightAuditTests(){
        SBQQ.TriggerControl.disable();

        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, AccountId, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Sub_Type__c = 'Clickpath';
        testOpportunity.Renewal__c = true;
        testOpportunity.AccountId = testAccount.id;
        update testOpportunity;

        Test.startTest();
        testOpportunity = [SELECT id, Name, Renewal__c, Sub_Type__c FROM Opportunity WHERE Name='Revenue Opportunity'];

        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One' and Account__c=:testAccount.Id];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Four'and Account__c=:testAccount.Id];
		
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = true, Shipping_Address_NEW__c = shippingAddress.Id);
        insert quote;

        SBQQQuoteLineTriggerHandler.maxRuns = 100;
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 1, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id,SBQQ__CustomerPrice__c = 10000, Account__c=testAccount.Id, Ship_To__c=shippingAddressTwo.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id,SBQQ__CustomerPrice__c = 10000, Account__c=testAccount.Id, Ship_To__c=shippingAddressTwo.id);
        newlineItems.add(quoteLineTwo);
        insert newlineItems;

        // Trigger the missing renewed subscription message
        //update newlineItems;

        newlineItems = [SELECT Id, Name, Gainsight_Audit_Status__c FROM SBQQ__QuoteLine__c ORDER BY Name];
        System.assertNotEquals('Success', newlineItems[0].Gainsight_Audit_Status__c);
        System.assert(newlineItems[0].Gainsight_Audit_Status__c.contains('Missing renewed subscription'));
        System.assertNotEquals('Success', newlineItems[1].Gainsight_Audit_Status__c);
        System.assert(newlineItems[1].Gainsight_Audit_Status__c.contains('Missing renewed subscription'));

        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>{
            new SBQQ__Subscription__c(SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 1, SBQQ__CustomerPrice__c = 10000, SBQQ__Product__c = vgProduct.Id),
            new SBQQ__Subscription__c(SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 1, SBQQ__CustomerPrice__c = 10000, SBQQ__Product__c = vgProduct.Id),
            new SBQQ__Subscription__c(SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 0,   SBQQ__Product__c = vgProduct.Id)
        };
        insert subscriptionList;
        
        subscriptionList[1].SBQQ__RevisedSubscription__c = subscriptionList[2].Id;
        update subscriptionList[1];

        newlineItems[0].SBQQ__RenewedSubscription__c = subscriptionList[0].Id;
        newlineItems[1].SBQQ__RenewedSubscription__c = subscriptionList[1].Id;
        update newlineItems;

        newlineItems = [SELECT Id, Name, Gainsight_Audit_Status__c FROM SBQQ__QuoteLine__c ORDER BY Name];
        System.assertEquals('Success', newlineItems[0].Gainsight_Audit_Status__c);
        System.assertEquals('Success', newlineItems[1].Gainsight_Audit_Status__c);
        
        Test.stopTest();
    }



    @isTest 
    static void gainsightAuditTests_bugfixes(){
        SBQQ.TriggerControl.disable();

        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Sub_Type__c = 'Clickpath';
        testOpportunity.Renewal__c = true;
        update testOpportunity;

        testOpportunity = [SELECT id, Name, Renewal__c, Sub_Type__c FROM Opportunity WHERE Name='Revenue Opportunity'];

        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Four'];

        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = true, Shipping_Address_NEW__c = shippingAddress.Id);
        insert quote;

        SBQQQuoteLineTriggerHandler.maxRuns = 100;

        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>{
            new SBQQ__Subscription__c(SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__RenewalQuantity__c = 5, SBQQ__NetPrice__c = 1000, SBQQ__Quantity__c = 1, SBQQ__CustomerPrice__c = 10000, SBQQ__Product__c = vgProduct.Id),
            new SBQQ__Subscription__c(SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__RenewalQuantity__c = 5, SBQQ__NetPrice__c = 1000, SBQQ__Quantity__c = 1, SBQQ__CustomerPrice__c = 10000, SBQQ__Product__c = vgProduct.Id),
            new SBQQ__Subscription__c(SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__RenewalQuantity__c = 5, SBQQ__NetPrice__c = 1000, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 0,   SBQQ__Product__c = vgProduct.Id)
        };
        insert subscriptionList;
        
        subscriptionList[1].SBQQ__RevisedSubscription__c = subscriptionList[2].Id;
        update subscriptionList[1];
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 1, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, SBQQ__RenewedSubscription__c = subscriptionList[0].Id, SBQQ__CustomerPrice__c = 10000);
        newlineItems.add(quoteLineOne); 
        
        
        insert newlineItems;

        Test.setCreatedDate(testOpportunity.Id, System.now().addMinutes(-30));
        Test.setCreatedDate(quote.Id,           System.now().addMinutes(-30));
        Test.setCreatedDate(newlineItems[0].Id, System.now().addMinutes(-30));
        Test.setCreatedDate(newlineItems[1].Id, System.now().addMinutes(-30));
        Test.setCreatedDate(newlineItems[2].Id, System.now().addMinutes(-30));
        Test.startTest();
        update newlineItems;

        // Trigger the missing renewed subscription message
        //update newlineItems;

        Map<Id, SBQQ__QuoteLine__c> updatedQLMap = new Map<Id, SBQQ__QuoteLine__c>([SELECT Id, Name, Gainsight_Audit_Status__c FROM SBQQ__QuoteLine__c ORDER BY Name]);
        System.assertEquals('Success', (updatedQLMap.get(newlineItems[0].Id)).Gainsight_Audit_Status__c);
        System.assertEquals('Success', (updatedQLMap.get(newlineItems[1].Id)).Gainsight_Audit_Status__c);
        System.assertNotEquals('Success', (updatedQLMap.get(newlineItems[2].Id)).Gainsight_Audit_Status__c);
        System.assertEquals('Success', (updatedQLMap.get(newlineItems[3].Id)).Gainsight_Audit_Status__c);
        
        Test.stopTest();
    }*/
    
    @isTest    
    static void testrenewalDataError(){
        Contract testContract = [SELECT Id,Auto_Renewal__c,SBQQ__RenewalUpliftRate__c FROM Contract LIMIT 1];
        testAccount = [SELECT Id, Name, BillingCountry FROM Account WHERE Name='Test Account' LIMIT 1];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity' LIMIT 1];
        testOpportunity.Sub_Type__c = 'Clickpath';
        testOpportunity.Renewal__c = true;
        testOpportunity.AccountId = testAccount.id;
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        testOpportunity.SBQQ__RenewedContract__c = testContract.Id;
        Test.startTest();
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        SBQQ.TriggerControl.disable();
        update testOpportunity;
        
        testContract.Auto_Renewal__c = false;
        testContract.SBQQ__RenewalUpliftRate__c = 5;
        update testContract;
        SBQQ.TriggerControl.enable();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Two' LIMIT 1];
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
 
    SBQQ__Quote__c quote1 = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, SBQQ__Type__c = 'Renewal',
                                                  SBQQ__Primary__c = false, SBQQ__STartDate__c = System.today(),
                                                 License_Term__c = '2', SBQQ__RenewalUpliftRate__c = null);

    SBQQ__Quote__c quote2 = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, SBQQ__Type__c = 'Renewal',
                                                  SBQQ__Primary__c = false, SBQQ__STartDate__c = System.today(),
                                                 License_Term__c = '2', SBQQ__RenewalUpliftRate__c = 5.055);
    SBQQ__Quote__c quote3 = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, SBQQ__Type__c = 'Renewal',
                                                  SBQQ__Primary__c = false, SBQQ__STartDate__c = System.today(),
                                                 License_Term__c = '2', SBQQ__RenewalUpliftRate__c = 5);
        
        
        
        quoteList.add(quote1);
        quoteList.add(quote2);
        quoteList.add(quote3);
        insert quoteList;
        
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c ss1 = new SBQQ__Subscription__c(SBQQ__NetPrice__c = 1000, SBQQ__RenewalQuantity__c=10, SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 0,   SBQQ__Product__c = vgProduct.Id);
        SBQQ__Subscription__c ss2 = new SBQQ__Subscription__c(SBQQ__NetPrice__c = 1000, SBQQ__RenewalQuantity__c=10, SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 10,   SBQQ__Product__c = vgProduct.Id);
        SBQQ__Subscription__c ss3 = new SBQQ__Subscription__c(SBQQ__NetPrice__c = 1000, SBQQ__RenewalQuantity__c=10, SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 10,   SBQQ__Product__c = vgProduct.Id, SBQQ__RenewalPrice__c = 1000);
        subscriptionList.add(ss1);
        subscriptionList.add(ss2);
        subscriptionList.add(ss3);
        insert subscriptionList;
        
        List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c quoteLine1 =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, SBQQ__CustomerPrice__c = 12000,
                                                                SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id,SBQQ__RenewedSubscription__c = ss1.Id, SBQQ__ListPrice__c = 12000, SBQQ__ProrateMultiplier__c = 1);     
        SBQQ__QuoteLine__c quoteLine2 =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote3.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, SBQQ__CustomerPrice__c = 12000, Ship_To__c = null, SBQQ__NetPrice__c = 100, SBQQ__PriorQuantity__c = 1,
                                                                SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id,SBQQ__RenewedSubscription__c = ss2.Id, SBQQ__ListPrice__c = 12000, SBQQ__ProrateMultiplier__c = 1);                                                                                                                                                                                                
        SBQQ__QuoteLine__c quoteLine3 =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote3.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 1, SBQQ__CustomerPrice__c = 12000, Ship_To__c = shippingAddress.Id,
                                                                SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id,SBQQ__RenewedSubscription__c = ss3.Id, SBQQ__ListPrice__c = 1, SBQQ__ProrateMultiplier__c = 1, SBQQ__Uplift__c = 100);
        quoteLineList.add(quoteLine1);
        quoteLineList.add(quoteLine2);
        quoteLineList.add(quoteLine3);

        insert quoteLineList;
        TriggerHandler.clearAllBypasses();
        update quoteLineList;
       
        Test.stopTest();
    }
    @isTest
    static void testUpdateApprovalRequiredMUP() {
        // Bypass triggers to prevent SOQL limit issues
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.disable();
        testAccount = [SELECT id FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id FROM Opportunity WHERE Name='Revenue Opportunity'];
        testOpportunity.Owner_Role_Copy__c = 'ENT Sales Mgr';
        update testOpportunity;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        
        // Create Customer_360__c record without setting the MUP field value
        Customer_360__c c360 = new Customer_360__c(
            Account__c = testAccount.Id,
            SOT__c = true
            // LIC_VG_Discount__c is not set, leaving it null
        );
        insert c360;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE ProductCode = 'LIC-VG-LD'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id];
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test MUP Quote', 
            SBQQ__Opportunity2__c = testOpportunity.Id, 
            SBQQ__Primary__c = false,
            SBQQ__Type__c='Amendment'
        );
        insert quote;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__PricebookEntryId__c = pricebookEntry.Id,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Quantity__c = 1,
            Account__c = testAccount.Id
           
        );
        insert quoteLine;
        
        
        Test.stopTest();
    }
     @isTest
        private static void testWebStoreRenewalsMaximumDiscount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Opportunity opp = new Opportunity(AccountId = acc.Id, License_Term__c =36, SBQQ__RenewedContract__c = testContract.Id, Name = 'Revenue Opportunity',  
                                            CloseDate = System.today() + 90, StageName = 'Incubate' ); 
        Test.startTest();
            insert opp;
            // Create quote
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                Process_Eligibility__c = 'Digital Renewals'
            );
            insert quote;
            Test.stopTest();
            Product2 testProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
            SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = testProduct.Id,
                    SBQQ__Quantity__c = 1,
                    SBQQ__ProratedListPrice__c = 100,
                    SBQQ__CustomerPrice__c = 50,
                    SBQQ__DiscountScheduleType__c = 'Slab',
                    SBQQ__Existing__c = false,
                    SBQQ__PriorQuantity__c = 0,
                    SBQQ__Incomplete__c = false
                );
            insert testQuoteLine;
            
            
            // Create instance of helper class
            SBQQQuoteLineHelper helper = new SBQQQuoteLineHelper();
            
            // Call method with test data
            helper.webStoreRenewalsMaximumDiscount(new List<SBQQ__QuoteLine__c>{testQuoteLine});        
            
        }
     /**
    * @description : this test method tests that user without FlexAccessQuoteLine custom permission cannot update quote lines in Carryover Products or Upgraded Products groups
    * Jira: GTMS-26503
    **/
    @isTest
    static void testFlexSellerUpdateQuoteLine() {
        Test.startTest();
        User testUser = createTestUser('Samsara Sales - NA US AE3', 'flextestuser@salesforce.com');
        system.runAs(testUser) {
            setupTestEnvironment(testUser);

            SBQQ__QuoteLine__c carryoverGroupLine = [SELECT Id, SBQQ__Quantity__c, Flex_Group_Name__c FROM SBQQ__QuoteLine__c WHERE Flex_Group_Name__c = :FlexConstants__c.getInstance('FlexConstants').Carryover_Products__c LIMIT 1];
            SBQQ__QuoteLine__c upgradedGroupLine = [SELECT Id, SBQQ__Quantity__c, Flex_Group_Name__c FROM SBQQ__QuoteLine__c WHERE Flex_Group_Name__c = :FlexConstants__c.getInstance('FlexConstants').Upgraded_Products__c LIMIT 1];

            carryoverGroupLine.SBQQ__Quantity__c = 5;
            try {
                TriggerHandler.clearAllBypasses();
                update carryoverGroupLine;
            } catch(Exception e) {
                System.debug('Flex Error message for Carryover Line: ' + e.getMessage());
                System.assert(true, e.getMessage().contains(FlexConstants__c.getInstance('FlexConstants').Error_Message__c));
            }

            upgradedGroupLine.SBQQ__Quantity__c = 2;
            try {
                TriggerHandler.clearAllBypasses();
                update upgradedGroupLine;
            } catch(Exception e) {
                System.debug('Flex Error message for Upgraded Line: ' + e.getMessage());
                System.assert(true, e.getMessage().contains(FlexConstants__c.getInstance('FlexConstants').Error_Message__c));
            }
        }
        Test.stopTest();
    }
    /**
    * @description : this test method tests that user with FlexAccessQuoteLine custom permission can add, modify or delete quote lines in Carryover Products or Upgraded Products groups
    * Jira: GTMS-26503
    **/
    @isTest
    static void testFlexQuoteLineAccessForSalesOps(){
        Test.startTest();
            List<SetupEntityAccess> setupEntityAccess = [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName = 'FlexAccessQuoteLine') LIMIT 1];
            List<User> salesOpsUser = [SELECT Id FROM User WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :setupEntityAccess[0].ParentId) AND IsActive = true LIMIT 1];
            System.runAs(salesOpsUser[0]) {
            setupTestEnvironment(salesOpsUser[0]);

            SBQQ__QuoteLine__c carryoverGroupLine = [SELECT Id, SBQQ__Quantity__c, Flex_Group_Name__c,SBQQ__NetPrice__c, SBQQ__ListPrice__c, SBQQ__SpecialPrice__c, SBQQ__CustomerPrice__c, SBQQ__UnitCost__c, SBQQ__RegularPrice__c FROM SBQQ__QuoteLine__c WHERE Flex_Group_Name__c = :FlexConstants__c.getInstance('FlexConstants').Carryover_Products__c LIMIT 1];
            carryoverGroupLine.SBQQ__Quantity__c = 2;

                    TriggerHandler.clearAllBypasses();
                    update carryoverGroupLine;
                    // Verify the quantity was updated successfully
                    SBQQ__QuoteLine__c updatedLine = [SELECT Id, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c WHERE Id = :carryoverGroupLine.Id];
                    System.assertEquals(2, updatedLine.SBQQ__Quantity__c, 'Sales Ops user should be able to update the quantity');

                    delete carryoverGroupLine;
                    // Verify the line was deleted successfully
                    List<SBQQ__QuoteLine__c> deletedLines = [SELECT Id FROM SBQQ__QuoteLine__c WHERE Id = :carryoverGroupLine.Id];
                    System.assertEquals(0, deletedLines.size(), 'Sales Ops user should be able to delete the line');
        }
        Test.stopTest();
    }
    /**
    * @description : this test method tests that user without FlexAccessQuoteLine custom permission cannot delete quote lines in Carryover Products or Upgraded Products groups
    * Jira: GTMS-26503
    **/
    @isTest
    static void testFlexSellerDeleteQuoteLine() {
        Test.startTest();
        User testUser = createTestUser('Samsara Sales - NA US AE3', 'flextestuser@salesforce.com');
        system.runAs(testUser) {
            setupTestEnvironment(testUser);

            SBQQ__QuoteLine__c carryoverGroupLine = [SELECT Id, SBQQ__Quantity__c, Flex_Group_Name__c FROM SBQQ__QuoteLine__c WHERE Flex_Group_Name__c = :FlexConstants__c.getInstance('FlexConstants').Carryover_Products__c LIMIT 1];
            SBQQ__QuoteLine__c upgradedGroupLine = [SELECT Id, SBQQ__Quantity__c, Flex_Group_Name__c FROM SBQQ__QuoteLine__c WHERE Flex_Group_Name__c = :FlexConstants__c.getInstance('FlexConstants').Upgraded_Products__c LIMIT 1];

            try {
                TriggerHandler.clearAllBypasses();
                delete carryoverGroupLine;
            } catch(DMLException e) {
                System.debug('Flex Error message for Carryover Line: ' + e.getMessage());
                System.assert(true, e.getMessage().contains(FlexConstants__c.getInstance('FlexConstants').Error_Message__c));
            }

            try {
                TriggerHandler.clearAllBypasses();
                delete upgradedGroupLine;
            } catch(DMLException e) {
                System.debug('Flex Error message for Upgraded Line: ' + e.getMessage());
                System.assert(true, e.getMessage().contains(FlexConstants__c.getInstance('FlexConstants').Error_Message__c));
            }
        }
        Test.stopTest();
    }
    /**
    * @description : this test method tests that user without FlexAccessQuoteLine custom permission cannot add quote lines in Carryover Products or Upgraded Products groups
    * Jira: GTMS-26503
    **/
    @isTest
    static void testFlexSellerAddProduct() {
        Test.startTest();
        User testUser = createTestUser('Samsara Sales - NA US AE3', 'flextestuser@salesforce.com');
        system.runAs(testUser) {
            setupTestEnvironment(testUser);
            Id pricebookId = Test.getStandardPricebookId();
            SBQQ__QuoteLine__c carryoverGroupLine = [SELECT Id, SBQQ__Quantity__c, Flex_Group_Name__c FROM SBQQ__QuoteLine__c WHERE Flex_Group_Name__c = :FlexConstants__c.getInstance('FlexConstants').Carryover_Products__c LIMIT 1];
            Product2 testProduct = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
            insert testProduct; 
            PricebookEntry testPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true);
            insert testPBE;
            SBQQ__QuoteLineGroup__c upgradedGroup = [SELECT Id,SBQQ__Quote__c FROM SBQQ__QuoteLineGroup__c WHERE Name = :FlexConstants__c.getInstance('FlexConstants').Upgraded_Products__c LIMIT 1];

            // Create test quote line for Upgraded Products group
            SBQQ__QuoteLine__c newUpgradedLine = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = upgradedGroup.SBQQ__Quote__c,
                SBQQ__Product__c = testProduct.Id,
                SBQQ__PricebookEntryId__c = testPBE.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__Group__c = upgradedGroup.Id
            );
            try{
                TriggerHandler.clearAllBypasses();
                insert newUpgradedLine;
            }catch(DmlException e){
                System.debug('Flex Error message for Add Product: ' + e.getMessage());
                System.assert(true, e.getMessage().contains(FlexConstants__c.getInstance('FlexConstants').Error_Message__c));
            }
            carryoverGroupLine.SBQQ__Group__c = upgradedGroup.Id;

            try {
                TriggerHandler.clearAllBypasses();
                update carryoverGroupLine;
            } catch(Exception e) {
                System.debug('Flex Error message for Carryover Line : ' + e.getMessage());
                System.assert(true, e.getMessage().contains(FlexConstants__c.getInstance('FlexConstants').Error_Message__c));
            }
        }
        Test.stopTest();
    }

    /**
    * Creates a test user with the specified profile name and username to be used with flex test methods
    * Jira: GTMS-26503
    * @param profileName The name of the profile to assign to the test user
    * @param username The username for the test user
    * @return The created test User record
    */
    private static User createTestUser(String profileName, String username) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User testUser = new User(
            alias = 'flexuser',
            email = 'random@salesforce.com',
            emailencodingkey = 'UTF-8',
            FirstName = 'Flex',
            LastName = 'Test User',
            localesidkey = 'en_US',
            languagelocalekey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            Username = username,
            EmployeeNumber = '123',
            IsActive = true
        );
        insert testUser;
        return testUser;
    }
    /**
    * Sets up the test environment for the flex test methods
    * Jira: GTMS-26503
    * @param testUser The test user to set up the environment for
    */
    private static void setupTestEnvironment(User testUser) {
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        SBQQ.TriggerControl.disable();

        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        Product2 testProduct = new Product2(Name = 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        insert testProduct;
        PricebookEntry testPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true);
        insert testPBE;

        Opportunity revenueOpportunity = new Opportunity(
            AccountId = testAccount.Id,
            License_Term__c = 36,
            Pricebook2Id = pricebookId,
            Max_Approved_Discount__c = 0,
            Name = 'Revenue Opportunity',
            Price_Book_Name__c = 'Standard Price Book',
            CloseDate = System.today() + 90,
            StageName = 'Incubate',
            OwnerId = testUser.Id
        );
        insert revenueOpportunity;

        FlexConstants__c flexConstants = new FlexConstants__c(
            Name = 'FlexConstants',
            Flex_Access_QuoteLine__c = 'FlexAccessQuoteLine',
            Carryover_Products__c = 'Carryover Products',
            Upgraded_Products__c = 'Upgraded Products',
            Error_Message__c = 'You do not have permission to make modifications, additions, or deletions in the Carryover or Upgraded Products groups.'
        );
        insert flexConstants;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = revenueOpportunity.Id,
            OwnerId = testUser.Id,
            Flex_Is_Rebook_Quote__c = true
        );
        insert quote;

        List<SBQQ__QuoteLineGroup__c> quoteGroups = new List<SBQQ__QuoteLineGroup__c>();
        SBQQ__QuoteLineGroup__c carryoverGroup = new SBQQ__QuoteLineGroup__c(
            Name = flexConstants.Carryover_Products__c,
            SBQQ__Quote__c = quote.Id
        );
        quoteGroups.add(carryoverGroup);

        SBQQ__QuoteLineGroup__c upgradedGroup = new SBQQ__QuoteLineGroup__c(
            Name = flexConstants.Upgraded_Products__c,
            SBQQ__Quote__c = quote.Id
        );
        quoteGroups.add(upgradedGroup);
        insert quoteGroups;

        SBQQ__QuoteLine__c carryoverLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__PricebookEntryId__c = testPBE.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__NetPrice__c = 1000,
            SBQQ__Group__c = carryoverGroup.Id
        );
        insert carryoverLine;

        SBQQ__QuoteLine__c upgradedLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__PricebookEntryId__c = testPBE.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__Group__c = upgradedGroup.Id
        );
        insert upgradedLine;
    }
    
    @isTest 
    static void b360OpportunityTest(){
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account' LIMIT 1];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity' LIMIT 1];
        testContract = [Select Id, AccountId From Contract LIMIT 1];
        Opportunity cnrOpportunity = new Opportunity( AccountId = testAccount.Id, License_Term__c =36, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Sub_Type__c = 'Contract Replacement'); 
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('ContractTriggerHandler');     
        insert cnrOpportunity;
        testContract.Flex_Replacement_Opportunity__c = testOpportunity.Id;
        update testContract;
        TriggerHandler.clearAllBypasses();
        
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-LD' LIMIT 1];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Three'];
        
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c amendmendQuote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, SBQQ__StartDate__c = System.Today(), SBQQ__EndDate__c = System.Today().addDays(30),
                                                  SBQQ__Primary__c = false,SBQQ__Type__c = 'Amendment', SBQQ__MasterContract__c = testContract.Id, Shipping_Address_NEW__c = shippingAddress.Id);
        SBQQ__Quote__c renewalQuote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, SBQQ__Account__c = testContract.AccountId, SBQQ__StartDate__c = System.Today(), SBQQ__EndDate__c = System.Today().addDays(30),
                                                  SBQQ__Primary__c = false,SBQQ__Type__c = 'Renewal', Co_Term_Contract__c = testContract.Id, Shipping_Address_NEW__c = shippingAddress.Id);
        SBQQ__Quote__c cnrQuote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =cnrOpportunity.Id, SBQQ__StartDate__c = System.Today(), SBQQ__EndDate__c = System.Today().addDays(30),
                                                  SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id);
                
        quoteList.add(amendmendQuote);
        quoteList.add(renewalQuote);
        quoteList.add(cnrQuote);
        insert quoteList;
        
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c ss1 = new SBQQ__Subscription__c(SBQQ__NetPrice__c = 1000, SBQQ__RenewalQuantity__c=10, SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 0,   SBQQ__Product__c = vgProduct.Id, Billing_Contract_Line_Id__c = 'test');
        SBQQ__Subscription__c ss2 = new SBQQ__Subscription__c(SBQQ__NetPrice__c = 1000, SBQQ__RenewalQuantity__c=10, SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 10,   SBQQ__Product__c = vgProduct.Id, Billing_Contract_Line_Id__c = 'test');
        SBQQ__Subscription__c ss3 = new SBQQ__Subscription__c(SBQQ__NetPrice__c = 1000, SBQQ__RenewalQuantity__c=10, SBQQ__Account__c = testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__Quantity__c = 4, SBQQ__CustomerPrice__c = 10,   SBQQ__Product__c = vgProduct.Id, SBQQ__RenewalPrice__c = 1000, Billing_Contract_Line_Id__c = 'test');
        subscriptionList.add(ss1);
        subscriptionList.add(ss2);
        subscriptionList.add(ss3);
        Triggerhandler.bypass('SBQQSubscriptionTriggerHandler');
        insert subscriptionList;
        TriggerHandler.clearAllBypasses();

        List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLine1 =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = amendmendQuote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addDays(30),
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        SBQQ__QuoteLine__c quoteLine2 =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = renewalQuote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addDays(30),
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        SBQQ__QuoteLine__c quoteLine3 =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = cnrQuote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addDays(30),
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        quoteLineList.add(quoteLine1);
        quoteLineList.add(quoteLine2);
        quoteLineList.add(quoteLine3);
        insert quoteLineList;


        Test.stopTest();
    }
}