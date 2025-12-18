@IsTest
private class QuantityControllerExtensionRTest {

    @TestSetup static void setupRecords() {
        
        
                
        // add products to Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        
        // Get pricebook entries to use later
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'HW-VG33');
        PricebookEntry em11 = getPricebookEntry(pricebookId, 'HW-EM11');
        PricebookEntry vgLicense = getPricebookEntry(pricebookId, 'LIC-VG-36MO');
        PricebookEntry emLicense = getPricebookEntry(pricebookId, 'LIC-EM-36MO');   
        
        User user = [Select id from User where Id = :UserInfo.getUserId()];
        
        // Create account
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other');
        insert a;
        
        Contact c = new Contact (FirstName = 'Juan', LastName = 'Perez', Email = 'juan@a.com', AccountId=a.Id);
        insert c;
        
        Shipping_Address__c shippingAddress = new Shipping_Address__c ();
        shippingAddress.Account__c  = a.Id;
        shippingAddress.Shipping_Contact__c = c.Id;
        shippingAddress.Shipping_Address_Line_1__c = '110 Park St';
        shippingAddress.Shipping_City__c = 'Santa Clara';
        shippingAddress.Shipping_State__c = 'California';
        shippingAddress.Shipping_Country__c = 'United States';
        shippingAddress.Shipping_Zip_Code__c = '95050';
        shippingAddress.Name = 'Shipping Address';
        
        insert shippingAddress;
		
        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Trial' LIMIT 1];
                      
        // Create Revenue Oppty
        Map<String, Opportunity> oppsInsert = new Map<String, Opportunity>(); 
        Opportunity rev = new Opportunity(Owner_Role_Copy__c = 'My Role', AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate', OwnerId = user.Id, Amount = 1000,
                                         Shipping_Address_NEW__c = shippingAddress.Id);            
        insert rev;
        
      
        // create trial associated with revenue opportunity - first one is not shipped
        Opportunity o = new Opportunity(Owner_Role_Copy__c = 'My Role', AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id, 
            Probability = 0, StageName = 'Ready To Ship', Trial_Status__c = 'Open', type = 'Free Trial Opportunity', TrialResolutionOppty__c = rev.Id, Planned_Trial_Installation_Date__c = System.today()+5, 
            Trial_Goal_1__c  = 'Test', Trial_Period__c=30, Trial_Start_Date__c=System.today(), Trial_Primary_Contact__c=c.Id, OwnerId = user.Id, Amount = 1000, Shipping_Address_NEW__c = shippingAddress.Id);
        oppsInsert.put('trialNotShipped', o);
        // create trial associated with revenue oppty - this one will be shipped
        o = new Opportunity(Owner_Role_Copy__c = 'My Role', AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id, 
            Probability = 0, StageName = 'Ready To Ship', type = 'Free Trial Opportunity', Trial_Status__c = 'Open', TrialResolutionOppty__c = rev.Id, OwnerId = user.Id, Amount = 1000, Shipping_Address_NEW__c = shippingAddress.Id);        
        oppsInsert.put('trialShipped', o);
        insert oppsInsert.values();

        Test.startTest();
        
        // Add Revenue Oppty products
        Map<String, OpportunityLineItem> items = new Map<String, OpportunityLineItem>();
        OpportunityLineItem ol = new OpportunityLineItem (Quantity=5, OpportunityId=rev.Id, PriceBookEntryId=vg33.Id, UnitPrice = vg33.UnitPrice, Ship_To_Address_Concatenated__c ='x');
        items.put('revVg33', ol);
        
        ol = new OpportunityLineItem (Quantity=5, OpportunityId=rev.Id, PriceBookEntryId=vg33.Id, UnitPrice = vg33.UnitPrice, Ship_To_Address_Concatenated__c ='y');
        items.put('revVg33Y', ol);
        
        ol = new OpportunityLineItem (Quantity=5, OpportunityId=rev.Id, PriceBookEntryId=em11.Id, UnitPrice = em11.UnitPrice, Ship_To_Address_Concatenated__c ='x');
        items.put('revEm11', ol);
        
        ol = new OpportunityLineItem (Quantity=1, OpportunityId=rev.Id, PriceBookEntryId=em11.Id, UnitPrice = em11.UnitPrice, Ship_From_Location__c='Free Trial');
        items.put('revEm11FT', ol);
        
        ol = new OpportunityLineItem (Quantity=5, OpportunityId=rev.Id, PriceBookEntryId=vgLicense.Id, UnitPrice = vgLicense.UnitPrice);
        items.put('revVgLicense', ol);
        
        ol = new OpportunityLineItem (Quantity=5, OpportunityId=rev.Id, PriceBookEntryId=emLicense.Id, UnitPrice = emLicense.UnitPrice);
        items.put('revEmLicense', ol);

        // add products to not shipped trial
        ol = new OpportunityLineItem (Quantity=2, OpportunityId=oppsInsert.get('trialNotShipped').Id, PriceBookEntryId=em11.Id, UnitPrice = em11.UnitPrice, Ship_To_Address_Concatenated__c ='x');
        items.put('trialNotShippedEm11', ol);
        
        ol = new OpportunityLineItem (Quantity=2, OpportunityId=oppsInsert.get('trialNotShipped').Id, PriceBookEntryId=emLicense.Id, UnitPrice = emLicense.UnitPrice);
        items.put('trialNotShippedEmLicense', ol);

        // add products to shipped trial
        ol = new OpportunityLineItem (Quantity=1, OpportunityId=oppsInsert.get('trialShipped').Id, PriceBookEntryId=vg33.Id, UnitPrice = vg33.UnitPrice, Ship_To_Address_Concatenated__c ='x', Trial_Order_Number__c  = 'S-1');
        items.put('trailShippedVg33', ol);
        
        ol = new OpportunityLineItem (Quantity=1, OpportunityId=oppsInsert.get('trialShipped').Id, PriceBookEntryId=em11.Id, UnitPrice = em11.UnitPrice, Ship_To_Address_Concatenated__c ='x', Trial_Order_Number__c  = 'S-1');
        items.put('trailShippedEm11', ol);
        
        ol = new OpportunityLineItem (Quantity=1, OpportunityId=oppsInsert.get('trialShipped').Id, PriceBookEntryId=vgLicense.Id, UnitPrice = vgLicense.UnitPrice);
        items.put('trialShippedVgLicense', ol);

        ol = new OpportunityLineItem (Quantity=1, OpportunityId=oppsInsert.get('trialShipped').Id, PriceBookEntryId=emLicense.Id, UnitPrice = emLicense.UnitPrice);
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
    }


    @isTest static void testLocationOptions() {
        Opportunity rev = [SELECT Id, Order_Number__c, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtensionRefactored qtyController = new QuantityControllerExtensionRefactored(new ApexPages.StandardController(rev));
        List<SelectOption> shipLocations = qtyController.getLocationOption();
        system.assertEquals(2,shipLocations.size());
        Test.stopTest();
    }
    
    @isTest static void testNonFreeTrailCount() {
        Opportunity rev = [SELECT Id, Order_Number__c, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtensionRefactored qtyController = new QuantityControllerExtensionRefactored(new ApexPages.StandardController(rev));
        Map<String, Decimal> nonFreeTrails = qtyController.getNonFreeTrialCount();
        system.assertEquals(2,nonFreeTrails.size());
        Test.stopTest();
    }
    
    @isTest static void testFreeTrailCount() {
        Opportunity rev = [SELECT Id, Order_Number__c, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtensionRefactored qtyController = new QuantityControllerExtensionRefactored(new ApexPages.StandardController(rev));
        Map<String, Decimal> freeTrails = qtyController.getFreeTrialCount();
        system.assertNotEquals(4,freeTrails.size());
        Test.stopTest();
    }

    @isTest static void testRefresh() {
        Opportunity rev = [SELECT Id, Order_Number__c, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtensionRefactored qtyController = new QuantityControllerExtensionRefactored(new ApexPages.StandardController(rev));
        PageReference pr = qtyController.refresh();
        Test.stopTest();
    }

    @isTest static void testReturnToOpportunity() {
        Opportunity rev = [SELECT Id, Order_Number__c, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtensionRefactored qtyController = new QuantityControllerExtensionRefactored(new ApexPages.StandardController(rev));
        PageReference pr  = qtyController.returnToOpportunity();
        Test.stopTest();
    }
    
    @isTest static void testOpportunityStageFlag() {
        Opportunity rev = [SELECT Id, Order_Number__c, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtensionRefactored qtyController = new QuantityControllerExtensionRefactored(new ApexPages.StandardController(rev));
        Boolean stageFlag  = qtyController.getOpportunityStageFlag();
        system.assertEquals(false,stageFlag);
        Test.stopTest();
    }
    
    @isTest static void testOpportunityStageFlagOther() {
        Opportunity rev = [SELECT Id, Order_Number__c, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Free Trial' AND StageName='Closed won' LIMIT 1];
        Test.startTest();
        QuantityControllerExtensionRefactored qtyController = new QuantityControllerExtensionRefactored(new ApexPages.StandardController(rev));
        Boolean stageFlag  = qtyController.getOpportunityStageFlag();
        system.assertEquals(true,stageFlag);
        Test.stopTest();
    }
    
    @isTest static void testSubmit() {
        Opportunity rev = [SELECT Id, Order_Number__c, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Rev' LIMIT 1];
        Test.startTest();
        QuantityControllerExtensionRefactored qtyController = new QuantityControllerExtensionRefactored(new ApexPages.StandardController(rev));
        PageReference pr  = qtyController.submit();
        Test.stopTest();
    }
    

    static private PricebookEntry getPricebookEntry(Id pricebookId, String productCode){
        PricebookEntry entry = [Select Id, UnitPrice, Pricebook2Id, ProductCode from PricebookEntry where ProductCode = :productCode and Pricebook2Id = :pricebookId LIMIT 1];
        return entry;
    }
    
    static private void addProducts(Id pricebookId){
        
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
        Product2 em11 = new Product2(Name= 'HW-EM11', ProductCode = 'HW-EM11', Family = 'Test');
        products.add(em11);
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
        products.add(vgLicense);
        Product2 emLicense = new Product2(Name= 'LIC-EM-36MO', ProductCode = 'LIC-EM-36MO', Family = 'Test');
        products.add(emLicense);
        
        insert products;
        
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        PricebookEntry em11PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = em11.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(em11PB);
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        PricebookEntry emLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = emLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(emLicensePB);
        
        insert pricebookEntries;
    }
}