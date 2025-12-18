@IsTest
private class QuantityControllerExtensionTest {

    @TestSetup static void setupRecords() {


        System.debug('In testShipQty');


        TestData.ProductsAndPriceBooks productsAndPriceBook = TestData.createProductsAndPricebookEntries();
        Map<String, PricebookEntry> pricebookEntries = productsAndPriceBook.pricebookEntries;

        // Create account
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;

        Contact c = new Contact (FirstName = 'Juan', LastName = 'Perez', Email = 'juan@a.com', AccountId = a.Id);
        insert c;

        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Trial' LIMIT 1];

        // Create Revenue Oppty
        Map<String, Opportunity> oppsInsert = new Map<String, Opportunity>();
        Opportunity rev = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate');
        insert rev;

        // create trial associated with revenue opportunity - first one is not shipped
        Opportunity o = new Opportunity(AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
                Probability = 0, StageName = 'Incubate', Trial_Status__c = 'Open', type = 'Free Trial Opportunity', TrialResolutionOppty__c = rev.Id, Planned_Trial_Installation_Date__c = System.today() + 5, Trial_Goal_1__c = 'Test', Trial_Period__c = 30, Trial_Start_Date__c = System.today(), Trial_Primary_Contact__c = c.Id);
        oppsInsert.put('trialNotShipped', o);
        // create trial associated with revenue oppty - this one will be shipped
        o = new Opportunity(AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
                Probability = 0, StageName = 'Incubate', type = 'Free Trial Opportunity', Trial_Status__c = 'Open', TrialResolutionOppty__c = rev.Id);
        //setShipping(o);
        oppsInsert.put('trialShipped', o);
        insert oppsInsert.values();

        Test.startTest();

        // Add Revenue Oppty products
        Map<String, OpportunityLineItem> items = new Map<String, OpportunityLineItem>();
        OpportunityLineItem ol = new OpportunityLineItem (Quantity = 5, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice);
        items.put('revVg33', ol);

        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('em11').Id, UnitPrice = pricebookEntries.get('em11').UnitPrice);
        items.put('revEm11', ol);

        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('vgLicense').Id, UnitPrice = pricebookEntries.get('vgLicense').UnitPrice);
        items.put('revVgLicense', ol);

        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice);
        items.put('revEmLicense', ol);

        // add products to not shipped trial
        ol = new OpportunityLineItem (Quantity = 2, OpportunityId = oppsInsert.get('trialNotShipped').Id, PriceBookEntryId = pricebookEntries.get('em11').Id, UnitPrice = pricebookEntries.get('em11').UnitPrice);
        items.put('trialNotShippedEm11', ol);

        ol = new OpportunityLineItem (Quantity = 2, OpportunityId = oppsInsert.get('trialNotShipped').Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice);
        items.put('trialNotShippedEmLicense', ol);

        // add products to shipped trial
        ol = new OpportunityLineItem (Quantity = 1, OpportunityId = oppsInsert.get('trialShipped').Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice);
        items.put('trailShippedVg33', ol);

        ol = new OpportunityLineItem (Quantity = 1, OpportunityId = oppsInsert.get('trialShipped').Id, PriceBookEntryId = pricebookEntries.get('vgLicense').Id, UnitPrice = pricebookEntries.get('vgLicense').UnitPrice);
        items.put('trialShippedVgLicense', ol);

        ol = new OpportunityLineItem (Quantity = 1, OpportunityId = oppsInsert.get('trialShipped').Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice);
        items.put('trialShippedVgLicense', ol);

        insert items.values();
        //System.debug(LoggingLevel.INFO, 'here are the line items inserted: ' + items);

        // ship trial
        Opportunity oppToUpdate = new Opportunity();
        oppToUpdate = oppsInsert.get('trialShipped');
        oppToUpdate.Trial_Agreement_Accepted__c = true;
        oppToUpdate.Probability = 100;
        oppToUpdate.StageName = 'Closed Won';
        update oppToUpdate;
        oppsInsert.put('trialShipped', oppToUpdate);

        Test.stopTest();

        //System.assertEquals('Open', [SELECT Trial_Status__c FROM Opportunity WHERE Id = :oppsInsert.get('trialShipped').Id LIMIT 1].Trial_Status__c);

        // create trial associated with revenue oppty - this one will be shipped too
        //Opportunity trialShipped2 = new Opportunity(AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id, 
        //Probability = 0, StageName = 'Incubate', type = 'Free Trial Opportunity', TrialResolutionOppty__c = rev.Id, Planned_Trial_Installation_Date__c = System.today()+5, Trial_Goal_1__c  = 'Test', Trial_Period__c=30, Trial_Start_Date__c=System.today(), Trial_Primary_Contact__c=c.Id);
        //setShipping2(trialShipped2);
        //insert trialShipped2;

        //OpportunityLineItem trailShipped2Vg33 = new OpportunityLineItem (Quantity=1, OpportunityId=trialShipped2.Id, PriceBookEntryId=pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice);
        //insert trailShipped2Vg33;

        // ship trial
        //trialShipped2.Trial_Agreement_Accepted__c = true;
        //trialShipped2.Probability = 100;
        //trialShipped2.StageName = 'Closed Won';
        //System.debug(LoggingLevel.INFO, '108');
        //update trialShipped2;
    }

    @isTest static void testRevControllerLoad() {
        Opportunity rev = [SELECT Id, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtension qtyController = new QuantityControllerExtension(new ApexPages.StandardController(rev));
        Test.stopTest();
    }

    @isTest static void testTrialControllerLoad() {
        Opportunity trial = [SELECT Id, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Free Trial' LIMIT 1];
        Test.startTest();
        QuantityControllerExtension qtyController = new QuantityControllerExtension(new ApexPages.StandardController(trial));
        Test.stopTest();
    }

    @IsTest static void testShipQty() {
        // Start testing quantities page
        Opportunity rev = [SELECT Id, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtension qtyController = new QuantityControllerExtension(new ApexPages.StandardController(rev));

        Map<String, Decimal> trialQuantities = qtyController.getTrialQuantities();

        PageReference submitted = qtyController.submit();

        System.assertEquals(submitted.getUrl(), '/' + rev.id);

        /*
        List<OpportunityLineItem> revLineItems = [Select Id, OpportunityId, Shipped_Quantity__c, Product_Code_Copy__c from OpportunityLineItem where OpportunityId = :rev.Id];
        for (OpportunityLineItem revLi : revLineItems){
            if (revLi.Product_Code_Copy__c == 'HW-VG33'){
                System.assertEquals(revLi.Shipped_Quantity__c, 3);
            }
            else if (revLi.Product_Code_Copy__c == 'LIC-VG-36MO'){
                System.assertEquals(revLi.Shipped_Quantity__c, 4);
            }
            else if (revLi.Product_Code_Copy__c == 'HW-EM11'){
                System.assertEquals(revLi.Shipped_Quantity__c, 5);
            }
            else if (revLi.Product_Code_Copy__c == 'LIC-EM-36MO'){
                System.assertEquals(revLi.Shipped_Quantity__c, 5);
            }
        }
        */

        PageReference back = qtyController.backToOppty();

        System.assertEquals(submitted.getUrl(), '/' + rev.id);


        System.debug('In testShipQty End');
        Test.stopTest();
    }
    @isTest static void testTrialQuantities() {
        Opportunity rev = [SELECT Id, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtension qtyController = new QuantityControllerExtension(new ApexPages.StandardController(rev));
        Map<String, Decimal> testMap = qtyController.getPurchasedTrialQuantities();
        Map<String, Decimal> trialQuantities = qtyController.getTrialQuantities();
        for (String s : trialQuantities.keySet()) {
            trialQuantities.put(s, 1.0);
        }
        qtyController.shipQuantities = trialQuantities;
        PageReference pr = qtyController.refresh();
        Test.stopTest();
    }

    @isTest static void testTetShipLocations() {
        Opportunity rev = [SELECT Id, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtension qtyController = new QuantityControllerExtension(new ApexPages.StandardController(rev));
        Map<String, String> shipLocations = qtyController.getShipLocations();
        Test.stopTest();
    }

    @isTest static void testInputQuantities() {
        Opportunity rev = [SELECT Id, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtension qtyController = new QuantityControllerExtension(new ApexPages.StandardController(rev));
        Map<String, Decimal> inputQuantities = qtyController.getInputQuantities();
        for (String s : inputQuantities.keySet()) {
            inputQuantities.put(s, 1.0);
        }
        qtyController.inputQuantityMap = inputQuantities;
        PageReference pr = qtyController.submit_rep();
        Test.stopTest();
    }

    @isTest static void testRefresh() {
        Opportunity rev = [SELECT Id, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtension qtyController = new QuantityControllerExtension(new ApexPages.StandardController(rev));
        PageReference pr = qtyController.refresh();
        Test.stopTest();
    }

    @isTest static void testValidate() {
        Opportunity rev = [SELECT Id, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtension qtyController = new QuantityControllerExtension(new ApexPages.StandardController(rev));
        Boolean boo = qtyController.validate_form();
        Test.stopTest();
    }

    static private void setShipping(Opportunity o) {
        Contact c = new Contact (email = 'test@test.com', LastName = 'x');
        insert c;
        o.Shipping_Contact__c = c.Id;

        o.Shipping_Address_Line_1__c = 'x';
        o.Shipping_City__c = 'x';
        o.Shipping_State__c = 'x';
        o.Shipping_Zip_Code__c = 'x';
        o.Shipping_Country__c = 'Canada';
    }

    static private void setShipping2(Opportunity o) {
        Contact c = new Contact (email = 'yyy@test.com', LastName = 'yyy');
        insert c;
        o.Shipping_Contact__c = c.Id;

        o.Shipping_Address_Line_1__c = 'x';
        o.Shipping_City__c = 'x';
        o.Shipping_State__c = 'x';
        o.Shipping_Zip_Code__c = 'x';
        o.Shipping_Country__c = 'Canada';
    }
}