@isTest
private class ExpressExtensionTests {
    private static final Id TEST_PRICEBOOK_ID = Test.getStandardPricebookId();

    @TestSetup static void setupRecords() {
        TestData.ProductsAndPriceBooks productsAndPriceBook = TestData.createProductsAndPricebookEntries();
        PriceBook2 expressPB = new PriceBook2(Name='Samsara Express', IsActive=true);
        insert expressPB;

		List<Product2> products = new List<Product2>([SELECT Id FROM Product2 WHERE Family =: 'Test']);
		List<PriceBookEntry> pbEntries = new List<PriceBookEntry>();
		
        for(Product2 product: products){
			pbEntries.add(new PriceBookEntry(PriceBook2Id = expressPB.Id, Product2Id = product.Id, UnitPrice = 10000, IsActive=true));
		}
		insert pbEntries;

        Account a = (Account) TestFactory.createSObject(
                new Account(
                        Organization_Size__c = '5000+',
                        Industry = 'Other'),
                true);

        Opportunity revExpress = (Opportunity) TestFactory.createSObject(
                new Opportunity(
                        AccountId = a.Id,
                        License_Term__c = 36,
                        Pricebook2Id = expressPB.Id,
                        Max_Approved_Discount__c = 0,
                        Name = 'Revenue Opportunity',
                        CloseDate = System.today() + 90,
                        StageName = 'Incubate'),
				true);
		List<PriceBookEntry> pbEntriesList = [SELECT Price_Book_Entry_id__c FROM PricebookEntry WHERE PriceBook2.Name =: 'Samsara Express'];
		List<OpportunityLineItem> oppLines = new List<OpportunityLineItem>();

		for(PriceBookEntry pbEntry: pbEntriesList){
			oppLines.add(new OpportunityLineItem(OpportunityId=revExpress.Id, PriceBookEntryId=pbEntry.Id, Quantity=1, UnitPrice=10000));
		}
		insert oppLines;
//        Map<String, PricebookEntry> pricebookEntries = productsAndPriceBook.pricebookEntries;
//
//        List<Account> newAccount = new List<Account>();
//        // Create account
//        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
//        newAccount.add(a);
//        Account accountCotermed = new Account (Name = 'Acme Co CoTerm', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Co_Term_Account__c = true);
//        newAccount.add(accountCotermed);
//        Account accountCotermedTwo = new Account (Name = 'Acme Co CoTerm n Date', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Co_Term_Account__c = true, Co_Term_License_Date__c = Date.today());
//        newAccount.add(accountCotermedTwo);
//        insert newAccount;
//
//        List<Contact> newContacts = new List<Contact>();
//        Contact c = new Contact (FirstName = 'Juan', LastName = 'Perez', Email = 'juan@a.com', AccountId = a.Id);
//        newContacts.add(c);
//        Contact contactTwo = new Contact (FirstName = 'Juan', LastName = 'Perez Ho', Email = 'juan@aa.com', AccountId = accountCotermed.Id);
//        newContacts.add(contactTwo);
//        Contact contactThree = new Contact (FirstName = 'Juan', LastName = 'Perez Ho II', Email = 'juan@aaa.com', AccountId = accountCotermedTwo.Id);
//        newContacts.add(contactThree);
//        insert newContacts;
//
//        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Trial' LIMIT 1];
//
//        List<Opportunity> newOpportunities = new List<Opportunity>();
//        Opportunity rev = new Opportunity(AccountId = a.Id, License_Term__c = 36, Pricebook2Id = TEST_PRICEBOOK_ID, Max_Approved_Discount__c = 0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', CloseDate = System.today() + 90, StageName = 'Incubate');
//        newOpportunities.add(rev);
//        Opportunity revLeadSource = new Opportunity(AccountId = a.Id, License_Term__c = 40, Pricebook2Id = TEST_PRICEBOOK_ID, Max_Approved_Discount__c = 0, Name = 'Revenue Opportunity 40 LS', Price_Book_Name__c = 'Standard Price Book', CloseDate = System.today() + 90, StageName = 'Incubate', LeadSource = 'Deal Reg Form');
//        newOpportunities.add(revLeadSource);
//        Opportunity revLicense84 = new Opportunity(AccountId = a.Id, License_Term__c = 84, Pricebook2Id = TEST_PRICEBOOK_ID, Max_Approved_Discount__c = 0, Name = 'Revenue Opportunity 84', Price_Book_Name__c = 'Standard Price Book', CloseDate = System.today() + 90, StageName = 'Incubate');
//        newOpportunities.add(revLicense84);
//        Opportunity revLicense60 = new Opportunity(AccountId = a.Id, License_Term__c = 60, Pricebook2Id = TEST_PRICEBOOK_ID, Max_Approved_Discount__c = 0, Name = 'Revenue Opportunity 60', Price_Book_Name__c = 'Standard Price Book', CloseDate = System.today() + 90, StageName = 'Incubate');
//        newOpportunities.add(revLicense60);
//        Opportunity cotermedOpp = new Opportunity(AccountId = accountCotermed.Id, License_Term__c = 60, Pricebook2Id = TEST_PRICEBOOK_ID, Max_Approved_Discount__c = 0, Name = 'Revenue Opportunity CoTermed', Price_Book_Name__c = 'Standard Price Book', CloseDate = System.today() + 90, StageName = 'Incubate');
//        newOpportunities.add(cotermedOpp);
//        Opportunity closedOpportunity = new Opportunity(AccountId = accountCotermed.Id, License_Term__c = 60, Pricebook2Id = TEST_PRICEBOOK_ID, Max_Approved_Discount__c = 0, Name = 'Revenue Opportunity Closed', Price_Book_Name__c = 'Standard Price Book', CloseDate = System.today(), StageName = 'Closed Won');
//        newOpportunities.add(closedOpportunity);
//        Opportunity cotermedOppTwo = new Opportunity(AccountId = accountCotermedTwo.Id, License_Term__c = 60, Pricebook2Id = TEST_PRICEBOOK_ID, Max_Approved_Discount__c = 0, Name = 'Revenue Opportunity CoTermed II', Price_Book_Name__c = 'Standard Price Book', CloseDate = System.today() + 90, StageName = 'Incubate');
//        newOpportunities.add(cotermedOppTwo);
//        Opportunity freeTrialOpportunity = new Opportunity(AccountId = accountCotermedTwo.Id, RecordTypeId = trialType.Id, License_Term__c = 60, Pricebook2Id = TEST_PRICEBOOK_ID, Max_Approved_Discount__c = 0, Name = 'Free Trial Opportunity', Price_Book_Name__c = 'Standard Price Book', CloseDate = System.today() + 90, StageName = 'Incubate');
//        newOpportunities.add(freeTrialOpportunity);
//        insert newOpportunities;
//
//        Map<String, OpportunityLineItem> items = new Map<String, OpportunityLineItem>();
//        OpportunityLineItem ol = new OpportunityLineItem (Quantity = 5, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice, Discount = 2);
//        items.put('revVg33', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('em11').Id, UnitPrice = pricebookEntries.get('em11').UnitPrice, Discount = 2);
//        items.put('revEm11', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('vgLicense').Id, UnitPrice = pricebookEntries.get('vgLicense').UnitPrice, Discount = 2);
//        items.put('revVgLicense', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice, Discount = 2);
//        items.put('revEmLicense', ol);
//
//        ol = new OpportunityLineItem (Quantity = 1, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('mkKit').Id, UnitPrice = pricebookEntries.get('mkKit').UnitPrice, Discount = 0);
//        items.put('mkKit', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = revLicense84.Id, PriceBookEntryId = pricebookEntries.get('em11').Id, UnitPrice = pricebookEntries.get('em11').UnitPrice, Discount = 2);
//        items.put('revEm11-84', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = revLicense84.Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice, Discount = 2);
//        items.put('revEmLicense-84', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = revLicense60.Id, PriceBookEntryId = pricebookEntries.get('em11').Id, UnitPrice = pricebookEntries.get('em11').UnitPrice, Discount = 2);
//        items.put('revEm11-60', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = revLicense60.Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice, Discount = 2);
//        items.put('revEmLicense-60', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = revLeadSource.Id, PriceBookEntryId = pricebookEntries.get('em11').Id, UnitPrice = pricebookEntries.get('em11').UnitPrice, Discount = 2);
//        items.put('revEm11-40', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = revLeadSource.Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice, Discount = 2);
//        items.put('revEmLicense-40', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = cotermedOpp.Id, PriceBookEntryId = pricebookEntries.get('em11').Id, UnitPrice = pricebookEntries.get('em11').UnitPrice, Discount = 2);
//        items.put('revEm11-CT', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = cotermedOpp.Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice, Discount = 2);
//        items.put('revEmLicense-CT', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = cotermedOppTwo.Id, PriceBookEntryId = pricebookEntries.get('em11').Id, UnitPrice = pricebookEntries.get('em11').UnitPrice, Discount = 2);
//        items.put('revEm11-CT2', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = cotermedOppTwo.Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice, Discount = 2);
//        items.put('revEmLicense-CT2', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = freeTrialOpportunity.Id, PriceBookEntryId = pricebookEntries.get('em11').Id, UnitPrice = pricebookEntries.get('em11').UnitPrice, Discount = 0);
//        items.put('revEm11-CT2', ol);
//
//        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = freeTrialOpportunity.Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice, Discount = 0);
//        items.put('revEmLicense-CT2', ol);
//
//        insert items.values();
//
    }

    @isTest static void testGetItems() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c, Price_Book_Name__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        system.debug('Rev: '+rev.Price_Book_Name__c);
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        productExtension.cotermed_account = true;
        productExtension.free_trial_opportunity = false;
        Test.stopTest();
    }

    @isTest static void testInsertItems() {
        Opportunity rev = [
                SELECT id, Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> selectedLineItems = [SELECT Price_Book_Entry_id__c FROM PricebookEntry WHERE PriceBook2.Name =: 'Samsara Express'];
        system.debug('Selected Line Items ' + selectedLineItems);
        List<String> selectedLineItemsIDs = new List<String>();
        system.debug('String List ' + selectedLineItemsIDs);
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        productExtension.oppty = rev;
        productExtension.insertSelectedLineItems(selectedLineItemsIDs);
        Test.stopTest();
    }

    @isTest static void testBack() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        PageReference pg = productExtension.back();
        Test.stopTest();
    }

    @isTest static void testGetInputPrices() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        productExtension.getInputPrices();
        Test.stopTest();
    }

    @isTest static void testGetInputRemovals() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        productExtension.getInputRemovals();
        Test.stopTest();
    }

    @isTest static void testSaveAndBack() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.saveAndReturn();
        Test.stopTest();
    }

    @isTest static void testSave() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c, (
                        Select Id, Ship_To__c, Deal_Reg_Discount__c, PricebookEntry.Name, Product_Code_Copy__c, License_Term_Copy__c,
                                ACV_Total_Price_Bookings__c, Quantity, ListPrice, UnitPrice, Discount, TotalPrice, Suggested_Sales_Price__c,
                                Suggested_Line_Price__c, Selected_Sales_Price__c,Express_Annual_Discount__c, Express_Selected_Discount__c
                        from OpportunityLineItems
                        ORDER BY CreatedDate DESC
                )
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
		];
        Test.startTest();
		AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
		productExtension.express_discount = 0;
		productExtension.getInputQuantities();
        PageReference pgr = productExtension.save();
        Test.stopTest();
    }


    @isTest static void testGetInputQuantities() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        productExtension.getInputQuantities();
        Test.stopTest();

    }

    @isTest static void testRandom() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        String [] testStrings = new String[]{
                'USA'
        };
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        productExtension.setSelectedhardwares(testStrings);
        productExtension.setSelectedLicenses(testStrings);
        productExtension.setSelectedAccesories(testStrings);
        String[] results = productExtension.getSelectedHardwares();
        results = productExtension.getSelectedLicenses();
        results = productExtension.getSelectedAccesories();
        Test.stopTest();
    }

    @isTest static void testGetAccessories() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        List<SelectOption> options = productExtension.getAccesories();
        Test.stopTest();
    }


    @isTest static void testAddProducts() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        PageReference pgr = productExtension.addProducts();
        Test.stopTest();
    }

    @isTest static void testGetHardwares() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        productExtension.pricebook_name = 'Samsara Express';
        List<PricebookEntry> selectedLineItems = [Select ProductCode,Price_Book_Entry_id__c from PricebookEntry];
        productExtension.pricebook_entries = selectedLineItems;
        List<SelectOption> options = productExtension.getHardwares();
        Test.stopTest();
    }
    //testCoverage Class
    @isTest static void testCoverage() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        productExtension.testCoverage();
    }

    @isTest static void testGetLicenses() {
        Opportunity rev = [
                SELECT Account.Id,Shipping_Address_NEW__c,CurrencyIsoCode, Express_Selected_Discount__c, License_Term__c,
                        LeadSource, Type, Amount, CloseDate, Pricebook2.Name, ACV_Bookings_SOT__c
                FROM Opportunity
                WHERE Name = 'Revenue Opportunity'
                LIMIT 1
        ];
        Test.startTest();
        AddProductsAndLicensesExpressExtension productExtension = new AddProductsAndLicensesExpressExtension(new ApexPages.StandardController(rev));
        productExtension.pricebook_name = 'Samsara Express';
        List<PricebookEntry> selectedLineItems = [Select ProductCode,Price_Book_Entry_id__c from PricebookEntry];
        productExtension.pricebook_entries = selectedLineItems;
        List<SelectOption> options = productExtension.getLicenses();
        Test.stopTest();
    }
}