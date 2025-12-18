@isTest
private class AddProductsAndLicensesExtensionTests {

    private static final Id pricebookId = Test.getStandardPricebookId();
    private static List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
    
    @TestSetup 
    static void setupRecords() {
        // add products to Pricebook
        system.debug(LoggingLevel.INFO, 'Price Book Id: '+pricebookId);

        // Get pricebook entries to use later
        //TestData.ProductsAndPriceBooks productsAndPriceBook = TestData.createProductsAndPricebookEntries();
        addProducts(pricebookId);
        Account a = (Account) TestFactory.createSObject(
                new Account(
                        Name = 'Acme Co',
                        Organization_Size__c = '5000+',
                        Industry = 'Other'),
                true);
        Opportunity rev = (Opportunity) TestFactory.createSObject(
                new Opportunity(
                        AccountId = a.Id,
                        License_Term__c = 36,
                        Pricebook2Id = pricebookId,
                        Max_Approved_Discount__c = 0,
                        Name = 'Revenue Opportunity',
                        Configuration_Segment__c = 'Non Express',
                        CloseDate = System.today() + 90,
                        StageName = 'Incubate'),
                true);
        List<PriceBookEntry> pbEntries = [SELECT Id, Name, ProductCode FROM PriceBookEntry WHERE PriceBook2Id = :pricebookId];
        system.debug(LoggingLevel.INFO, 'PriceBookEntriesSize: '+String.valueOf(pbEntries.size()));

        addOpportunityProduct('LIC-VG34-36MO', rev.Id, 2, 10);
        addOpportunityProduct('HW-VG34', rev.Id, 0, 10);
        addOpportunityProduct('LIC-CM32-36MO', rev.Id, 2, 10);
        addOpportunityProduct('HW-CM32', rev.Id, 0, 10);
        addOpportunityProduct('ACC-BDH', rev.Id, 0, 5);
        insert oppProducts;
    }

    static private void addProducts(Id pricebookId){
        
        List<Product2> products = new List<Product2>();
        Product2 vg34 = new Product2(Name= 'HW-VG34', ProductCode = 'HW-VG34', Family = 'Fleet');
        products.add(vg34);
        Product2 cm32 = new Product2(Name= 'HW-CM32', ProductCode = 'HW-CM32', Family = 'Safety');
        products.add(cm32);
        Product2 vgLicense = new Product2(Name= 'LIC-VG34-36MO', ProductCode = 'LIC-VG34-36MO', Family = 'Fleet');
        products.add(vgLicense);
        Product2 cmLicense = new Product2(Name= 'LIC-CM32-36MO', ProductCode = 'LIC-CM32-36MO', Family = 'Safety');
        products.add(cmLicense);
        Product2 accBDH = new Product2(Name= 'ACC-BDH', ProductCode = 'ACC-BDH', Family = 'Accessories');
        products.add(accBDH);
        Product2 marketingKit = new Product2(Name= 'KIT', ProductCode = 'MK-KT', Family = 'Test');
        products.add(marketingKit);
        
        insert products;
        
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg34PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg34.Id, UnitPrice = 0, IsActive = true);
        pricebookEntries.add(vg34PB);
        PricebookEntry cm32PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = cm32.Id, UnitPrice = 0, IsActive = true);
        pricebookEntries.add(cm32PB);
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        PricebookEntry cmLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = cmLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(cmLicensePB);
        PricebookEntry accBDHPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = accBDH.Id, UnitPrice = 0, IsActive = true);
        pricebookEntries.add(accBDHPB);
        PricebookEntry mkKitPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = marketingKit.Id, UnitPrice = 0, IsActive = true);
        pricebookEntries.add(mkKitPB);
        
        insert pricebookEntries;
    }

    static private void addOpportunityProduct(String productType, Id oppId, Decimal discount, Integer quantity){
        PricebookEntry entry = [SELECT Id, UnitPrice, Pricebook2Id, ProductCode FROM PricebookEntry WHERE ProductCode = :productType AND Pricebook2Id = :pricebookId LIMIT 1];
        system.debug(LoggingLevel.INFO, 'PriceBookEntryQuery: '+'SELECT Id, UnitPrice, Pricebook2Id, ProductCode FROM PricebookEntry WHERE ProductCode = '+productType+' AND Pricebook2Id = '+pricebookId+' LIMIT 1');
        if(entry != null){
            system.debug(LoggingLevel.INFO, 'PriceBookEntry: '+entry.ProductCode);
            OpportunityLineItem ol = new OpportunityLineItem (OpportunityId=oppId, Quantity=quantity, PricebookEntryId=entry.Id, UnitPrice=entry.UnitPrice, Discount=discount);
            oppProducts.add(ol);
        }
    }

    @isTest static void testGetItems() {
        Opportunity rev = [SELECT   Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode,Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        productExtension.cotermed_account =true;
        productExtension.free_trial_opportunity =false;
        productExtension.getItems();
        Test.stopTest();
    }
    
    @isTest static void testInsertItems() {
        Opportunity rev = [SELECT Id, Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> selectedLineItems = [Select Price_Book_Entry_id__c from PricebookEntry];
        system.debug('Selected Line Items ' +selectedLineItems);
        List<String> selectedLineItemsIDs = new List<String>();
        system.debug('String List '+selectedLineItemsIDs);
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
            productExtension.oppty = rev;
        productExtension.insertSelectedLineItems(selectedLineItemsIDs);
        Test.stopTest();
    }
    
    @isTest static void testBack() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                                    LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pg = productExtension.back();
        Test.stopTest();
    }
    
    @isTest static void testCalculateOverDiscount() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        productExtension.calculateOverDiscount();
        Test.stopTest();        
    }
    
    @isTest static void testGetInputPrices() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        productExtension.getInputPrices();
        Test.stopTest();
    }
    
    @isTest static void testGetInputRemovals() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        productExtension.getInputRemovals();
        Test.stopTest();
    }
    
    @isTest static void testGetInputDiscounts() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        productExtension.getInputDiscounts();
        Test.stopTest();
    }
    
    @isTest static void testRefresh() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.refresh();
        Test.stopTest();
    }
    
    @isTest static void testSaveAndBack() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.saveAndBack();
        Test.stopTest();        
    }
    
    @isTest static void testSave() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.save();
        Test.stopTest();
    }
    
    @isTest static void testTerms() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        List<SelectOption> options = productExtension.getTerms();
        Test.stopTest();
    }
    
    @isTest static void testDelete() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        productExtension.Del();
        Test.stopTest();
    }
    
    @isTest static void testGetInputQuantities() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        productExtension.getInputQuantities();
        Test.stopTest();
    }
    
    @isTest static void testRandom() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        String [] testStrings = new String[]{'USA'};
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        productExtension.setSelectedTerms(testStrings);
        productExtension.setSelectedhardwares(testStrings);
        productExtension.setSelectedLicenses(testStrings);
        productExtension.setSelectedAccesories(testStrings);
        String[] results = productExtension.getSelectedTerms();
        results = productExtension.getSelectedHardwares();
        results = productExtension.getSelectedLicenses();
        results = productExtension.getSelectedAccesories();
        Test.stopTest(); 
    }
    
    @isTest static void testGetAccessories() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        List<SelectOption> options = productExtension.getAccesories();
        Test.stopTest();
    }
    
    @isTest static void testCotermStatus() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.saveCotermStatus();
        Test.stopTest();
    }
    
    @isTest static void testSwitchEditableMode() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.switchEditableMode();
        Test.stopTest();
    }
    
    @isTest static void testLicenseTermSelectList() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.setLicenseTermSelectList();
        Test.stopTest();
    }
    
    @isTest static void testLicenseTermFromExpress() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.defaultLicenseTermFromExpress();
        Test.stopTest();
    }
    
    @isTest static void testLicenseTermInputField() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.setLicenseTermInputField();
        Test.stopTest();
    }
    
    @isTest static void testSetLicenseTermFromCotermed() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.setLicenseTermFromCotermed();
        Test.stopTest();
    }
    
    @isTest static void testLicenseTermFromCotermed() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.defaultLicenseTermFromCotermed();
        Test.stopTest();
    }

    @isTest static void testAddProducts() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.addProducts();
        Test.stopTest();
    }
    
    @isTest static void testGetHardwares() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        productExtension.pricebook_name = 'Samsara Standard';
        List<PricebookEntry> selectedLineItems = [Select ProductCode,Price_Book_Entry_id__c from PricebookEntry];
        productExtension.pricebook_entries = selectedLineItems;
        List<SelectOption> options = productExtension.getHardwares();
        Test.stopTest();
    }
    
    @isTest static void testGetLicenses() {
        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                            LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        productExtension.pricebook_name = 'Samsara Express';
        List<PricebookEntry> selectedLineItems = [Select ProductCode,Price_Book_Entry_id__c from PricebookEntry];
        productExtension.pricebook_entries = selectedLineItems;
        List<SelectOption> options = productExtension.getLicenses();
        Test.stopTest();
    }
    
    @isTest static void testGeneral() {

        Id pricebookId = Test.getStandardPricebookId();

        Account a = [SELECT Id FROM Account WHERE Name = 'Acme Co' LIMIT 1];
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revLicense84 = new Opportunity(AccountId = a.Id, License_Term__c =84, Pricebook2Id = pricebookId, Max_Approved_Discount__c=0, Name = 'Revenue Opportunity 84', Configuration_Segment__c = 'Non Express', CloseDate = System.today() + 90, StageName = 'Incubate');            
        newOpportunities.add(revLicense84);
        Opportunity revLicense60 = new Opportunity(AccountId = a.Id, License_Term__c =60, Pricebook2Id = pricebookId, Max_Approved_Discount__c=0, Name = 'Revenue Opportunity 60', Configuration_Segment__c = 'Non Express', CloseDate = System.today() + 90, StageName = 'Incubate');         
        newOpportunities.add(revLicense60);
        Test.startTest(); 
        insert newOpportunities;

        Opportunity rev84 = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                                LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity 84' LIMIT 1];
        Opportunity rev60 = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                                LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity 60' LIMIT 1];  

                               
        AddProductsAndLicensesExtension productExtension = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev84));
        productExtension.setLicenseTermAndResetPrices(84);
        AddProductsAndLicensesExtension productExtensionTwo = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev60));
        productExtensionTwo.setLicenseTermAndResetPrices(60);   
        Test.stopTest();
    }
      
    @isTest static void testGeneralCont() {

        Id pricebookId = Test.getStandardPricebookId();
        Test.startTest(); 

        Account accountCotermed = new Account (Name = 'Acme Co CoTerm', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Co_Term_Account__c=true);
        insert accountCotermed;
        Account accountCotermedTwo = new Account (Name = 'Acme Co CoTerm n Date', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Co_Term_Account__c=true, Co_Term_License_Date__c = Date.today());
        insert accountCotermedTwo;

        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Trial' LIMIT 1];

        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity cotermedOpp = new Opportunity(AccountId = accountCotermed.Id, License_Term__c =60, Pricebook2Id = pricebookId, Max_Approved_Discount__c=0, Name = 'Revenue Opportunity CoTermed', Configuration_Segment__c = 'Non Express', CloseDate = System.today() + 90, StageName = 'Incubate');          
        newOpportunities.add(cotermedOpp);
        Opportunity cotermedOppTwo = new Opportunity(AccountId = accountCotermedTwo.Id, License_Term__c =60, Pricebook2Id = pricebookId, Max_Approved_Discount__c=0, Name = 'Revenue Opportunity CoTermed II', Configuration_Segment__c = 'Non Express', CloseDate = System.today() + 90, StageName = 'Incubate');           
        newOpportunities.add(cotermedOppTwo);
        Opportunity freeTrialOpportunity = new Opportunity(AccountId = accountCotermedTwo.Id, RecordTypeId=trialType.Id, License_Term__c =60, Pricebook2Id = pricebookId, Max_Approved_Discount__c=0, Name = 'Free Trial Opportunity', Configuration_Segment__c = 'Non Express', CloseDate = System.today() + 90, StageName = 'Incubate');           
        newOpportunities.add(freeTrialOpportunity);
        
        
        insert newOpportunities;

        Opportunity revCoterm = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                                LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity CoTermed' LIMIT 1];
        Opportunity revCotermTwo = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                                LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity CoTermed II' LIMIT 1];
        Opportunity freeTrialOpp = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                                LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Free Trial Opportunity' LIMIT 1];

        //Test.startTest();
        AddProductsAndLicensesExtension productExtensionFive= new AddProductsAndLicensesExtension(new ApexPages.StandardController(revCoterm));
        AddProductsAndLicensesExtension productExtensionSix= new AddProductsAndLicensesExtension(new ApexPages.StandardController(revCotermTwo));
        AddProductsAndLicensesExtension productExtensionSeven= new AddProductsAndLicensesExtension(new ApexPages.StandardController(freeTrialOpp));
        Test.stopTest();
    }
    
    @isTest static void testGeneralContTwo() {

        Id pricebookId = Test.getStandardPricebookId();

        Account a = [SELECT Id FROM Account WHERE Name = 'Acme Co' LIMIT 1];
        
        Test.startTest(); 
        Opportunity revLeadSource = new Opportunity(AccountId = a.Id, License_Term__c =40, Pricebook2Id = pricebookId, Max_Approved_Discount__c=0, Name = 'Revenue Opportunity 40 LS', Configuration_Segment__c = 'Non Express', CloseDate = System.today() + 90, StageName = 'Incubate', LeadSource='Deal Reg Form');         
        insert revLeadSource;

        Opportunity rev = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                                LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        Opportunity rev40 = [SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c, 
                                LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c FROM Opportunity WHERE Name = 'Revenue Opportunity 40 LS' LIMIT 1];

        //Test.startTest();
        AddProductsAndLicensesExtension productExtensionThree = new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev));
        productExtensionThree.setLicenseTermAndResetPrices(36);
        AddProductsAndLicensesExtension productExtensionFour= new AddProductsAndLicensesExtension(new ApexPages.StandardController(rev40));
        productExtensionFour.setLicenseTermAndResetPrices(40);
        Test.stopTest();
    }
}