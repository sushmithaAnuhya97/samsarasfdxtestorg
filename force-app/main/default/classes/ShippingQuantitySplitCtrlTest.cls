/*
* Classes Covered
* ******************************************
* ShippingQuantitySplitCtrl
* SetShippingQuantityQueue
* 
*/
@IsTest
public class ShippingQuantitySplitCtrlTest {
    
    @TestSetup static void setupRecords() {
        Test.startTest();
        TestData.ProductsAndPriceBooks productsAndPricebooks = TestData.createProductsAndPricebookEntries();
        Map<String, PricebookEntry> pricebookEntries = productsAndPricebooks.pricebookEntries;
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        update standardPricebook;
        User user = [Select id from User where Id = :UserInfo.getUserId()];
        
        // Create account
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;
        
        Contact c = new Contact (FirstName = 'Juan', LastName = 'Perez', Email = 'juan@a.com', AccountId = a.Id);
        insert c;
        
        
        Shipping_Address__c shippingAddress = new Shipping_Address__c ();
        shippingAddress.Account__c = a.Id;
        shippingAddress.Shipping_Contact__c = c.Id;
        shippingAddress.Shipping_Address_Line_1__c = '110 Park St';
        shippingAddress.Shipping_City__c = 'Santa Clara';
        shippingAddress.Shipping_State__c = 'California';
        shippingAddress.Shipping_Country__c = 'United States';
        shippingAddress.Shipping_Zip_Code__c = '95050';
        shippingAddress.Name = 'Shipping Address';
        Shipping_Address__c shippingAddress1 = new Shipping_Address__c ();
        shippingAddress.Account__c = a.Id;
        shippingAddress.Shipping_Contact__c = c.Id;
        shippingAddress.Shipping_Address_Line_1__c = '110 Park St';
        shippingAddress.Shipping_City__c = 'Santa Clara';
        shippingAddress.Shipping_State__c = 'California';
        shippingAddress.Shipping_Country__c = 'United States';
        shippingAddress.Shipping_Zip_Code__c = '95050';
        shippingAddress.Name = 'Shipping Address1';
        List<Shipping_Address__c> shipAddress = new List<Shipping_Address__c>{
            shippingAddress, shippingAddress1
                };
                    insert shipAddress;
        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Trial' LIMIT 1];
        // Create Revenue Oppty
        Map<String, Opportunity> oppsInsert = new Map<String, Opportunity>();
        Opportunity rev1 = new Opportunity(Owner_Role_Copy__c = 'My Role', AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate', OwnerId = user.Id, Amount = 1000,
                                           Shipping_Address_NEW__c = shippingAddress.Id);
        // create trial associated with revenue oppty - this one will be shipped
        Opportunity rev = new Opportunity();
        rev = TestFactory.initializeOpportunity ('Rev');
        rev.Type = 'Revenue Opportunity' ;
        rev.StageName = 'Qualified';
        rev.AccountId = a.Id;
        rev.Shipping_Address_NEW__c =  shippingAddress.Id;
        rev.Amount = 1000;
        Opportunity o = new Opportunity();
        o = TestFactory.initializeOpportunity ('Free Trial');
        o.Type = 'Free Trial Opportunity' ;
        o.StageName = 'Qualified';
        o.Trial_Status__c = 'Open';
        o.AccountId = a.Id;
        o.RecordTypeId = trialType.Id;
        o.Shipping_Address_NEW__c =  shippingAddress.Id;
        o.TrialResolutionOppty__c = rev.Id;
        o.Amount = 1000;
        Opportunity o1 = new Opportunity(Owner_Role_Copy__c = 'My Role', AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
                                         Probability = 100, StageName = 'Closed Won', type = 'Free Trial Opportunity', Trial_Status__c = 'Open', TrialResolutionOppty__c = rev.Id, OwnerId = user.Id, Amount = 1000, Shipping_Address_NEW__c = shippingAddress.Id);
        //oppsInsert.put('trialShipped1', o1);
        oppsInsert.put('trialShipped', o);
        oppsInsert.put('rev', rev);
        //oppsInsert.put('rev1', rev1);
        
        List<SetupEntityAccess> setupEntityAccess = [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName = 'Validation_Rule_Exemption') Limit 10];
        Set<Id> newIds = new Set<Id>();
        for(SetupEntityAccess Ids :setupEntityAccess){
            newIds.add(Ids.ParentId);
        }
        List<User> userList = [SELECT Id, Username, FirstName, LastName FROM User WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN : newIds) and IsActive = true and Profile.Name like '%system Admin%' limit 1];
        system.runAs(userList[0]){
            insert oppsInsert.values();
            Test.stopTest();
            
            // Add Revenue Oppty products
            Map<String, OpportunityLineItem> items = new Map<String, OpportunityLineItem>();
            OpportunityLineItem ol = new OpportunityLineItem (Quantity = 10, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice, Ship_To__c = shippingAddress1.Id,Ship_From_Location__c='Estafeta');
            items.put('revVg33', ol);
            ol = new OpportunityLineItem (Quantity = 13, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice, Ship_To__c = shippingAddress1.Id,Ship_From_Location__c='VCK');
            items.put('revVg33', ol);
            ol = new OpportunityLineItem (Quantity = 13, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice, Ship_To__c = shippingAddress.Id,Ship_From_Location__c='Estafeta');
            items.put('revVg33', ol);
            ol = new OpportunityLineItem (Quantity = 7, OpportunityId = o.Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice, Ship_To__c = shippingAddress.Id, Ship_From_Location__c = 'Free Trial');
            items.put('revVg33FT', ol);
            ol = new OpportunityLineItem (Quantity = 10, OpportunityId = o.Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice, Ship_To__c = shippingAddress.Id, Ship_From_Location__c = 'Free Trial');
            items.put('revVg33FT', ol);
            ol = new OpportunityLineItem (Quantity = 10, OpportunityId = o.Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice, Ship_To__c = shippingAddress1.Id, Ship_From_Location__c = 'Free Trial');
            items.put('revVg33FT', ol);
            ol = new OpportunityLineItem (Quantity = 10, OpportunityId = o.Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice, Ship_To__c = shippingAddress1.Id, Ship_From_Location__c = 'Free Trial');
            items.put('revVg33FT', ol);
            
            insert items.values();
            
            //System.debug(LoggingLevel.INFO, 'here are the line items inserted: ' + items);
            //Test.startTest();
            // ship trial
            Opportunity oppToUpdate = new Opportunity();
            oppToUpdate = oppsInsert.get('trialShipped');
            oppToUpdate.Trial_Agreement_Accepted__c = true;
            oppToUpdate.Probability = 100;
            oppToUpdate.StageName = 'Closed Won';
            update oppToUpdate;
            oppsInsert.put('trialShipped', oppToUpdate);
        }
        //Test.stopTest();      
    }
    
    @isTest static void testSubmit() {
        Test.startTest();
        Opportunity rev = [SELECT Id, Order_Number__c, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name LIKE 'Rev%' LIMIT 1];
        Opportunity freeTrial = [SELECT Id, Order_Number__c, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name LIKE 'Free Trial%' LIMIT 1];
        List<SetupEntityAccess> setupEntityAccess = [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName = 'Validation_Rule_Exemption') Limit 10];
        Set<Id> newIds = new Set<Id>();
        for(SetupEntityAccess Ids :setupEntityAccess){
            newIds.add(Ids.ParentId);
        }
        List<User> userList = [SELECT Id, Username, FirstName, LastName FROM User WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN : newIds) and IsActive = true and Profile.Name like '%system Admin%' limit 1];
        system.runAs(userList[0]){
            ShippingQuantitySplitCtrl controller = new ShippingQuantitySplitCtrl(new ApexPages.StandardController(rev));
            
            OpportunityLineItem oli = [SELECT Id, Product_Code_Copy__c,Ship_To__c,Related_Order_Number__c FROM OpportunityLineItem WHERE OpportunityId = :rev.Id LIMIT 1];
            controller.selectedAddress = oli.Id;
            controller.selectedProductCode = oli.Product_Code_Copy__c;
            controller.incrementVarRef = '1';
            controller.ShipToaddressId = oli.Ship_To__c;
            controller.orderNumber = oli.Related_Order_Number__c;
            
            controller.updateTrialUnitsOnAddressChange();
            controller.splitTrailItems();
            
            ShippingQuantitySplitCtrl qtyController1 = new ShippingQuantitySplitCtrl(new ApexPages.StandardController(freeTrial));
            
            Test.stopTest();
        }
    }
    @isTest static void testQuantityValidation() {
        Test.startTest();
        Opportunity rev = [SELECT Id FROM Opportunity WHERE Name LIKE 'Rev%' LIMIT 1];
        List<SetupEntityAccess> setupEntityAccess = [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName = 'Validation_Rule_Exemption') Limit 10];
        Set<Id> newIds = new Set<Id>();
        for(SetupEntityAccess Ids :setupEntityAccess){
            newIds.add(Ids.ParentId);
        }
        List<User> userList = [SELECT Id FROM User WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN : newIds) and IsActive = true and Profile.Name like '%system Admin%' limit 1];
        
        system.runAs(userList[0]){
            ShippingQuantitySplitCtrl controller = new ShippingQuantitySplitCtrl(new ApexPages.StandardController(rev));
            
            // Test quantity validation
            controller.quantity = 100;
            controller.toPurchase = 50;
            controller.availableinTarget = 75;
            controller.trailValidation();
            
            // Test zero quantity
            controller.quantity = 0;
            controller.trailValidation();
            
            // Test negative quantity
            controller.quantity = -1;
            controller.trailValidation();
        }
        Test.stopTest();
    }
   
   @isTest static void testShipFromLocationScenarios() {
        Test.startTest();
        Opportunity rev = [SELECT Id FROM Opportunity WHERE Name LIKE 'Rev%' LIMIT 1];
        List<SetupEntityAccess> setupEntityAccess = [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName = 'Validation_Rule_Exemption') Limit 10];
        Set<Id> newIds = new Set<Id>();
        for(SetupEntityAccess Ids :setupEntityAccess){
            newIds.add(Ids.ParentId);
        }
        List<User> userList = [SELECT Id FROM User WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN : newIds) and IsActive = true and Profile.Name like '%system Admin%' limit 1];
        
        system.runAs(userList[0]){
            // Get a sample OLI to use as template
            OpportunityLineItem templateOli = [
                SELECT Id, Product_Code_Copy__c, Ship_To__c, Related_Order_Number__c, 
                       Quantity, Ship_From_Location__c, Product2Id, PricebookEntryId,
                       UnitPrice, Purchased_From_Trial__c, To_Purchase_From_Trial__c
                FROM OpportunityLineItem 
                WHERE OpportunityId = :rev.Id
                LIMIT 1
            ];
            
            // Create new OLIs for different locations
            OpportunityLineItem vckOli = new OpportunityLineItem(
                OpportunityId = rev.Id,
                Product_Code_Copy__c = templateOli.Product_Code_Copy__c,
                Ship_To__c = templateOli.Ship_To__c,
                //Related_Order_Number__c = templateOli.Related_Order_Number__c,
                PricebookEntryId = templateOli.PricebookEntryId,
                UnitPrice = templateOli.UnitPrice,
                Quantity = 20,
                Ship_From_Location__c = 'VCK'
            );
            
            OpportunityLineItem ukOli = new OpportunityLineItem(
                OpportunityId = rev.Id,
                Product_Code_Copy__c = templateOli.Product_Code_Copy__c,
                Ship_To__c = templateOli.Ship_To__c,
                //Related_Order_Number__c = templateOli.Related_Order_Number__c,
                PricebookEntryId = templateOli.PricebookEntryId,
                UnitPrice = templateOli.UnitPrice,
                Quantity = 15,
                Ship_From_Location__c = 'Samsara UK'
            );
            
            OpportunityLineItem estafetaOli = new OpportunityLineItem(
                OpportunityId = rev.Id,
                Product_Code_Copy__c = templateOli.Product_Code_Copy__c,
                Ship_To__c = templateOli.Ship_To__c,
//Related_Order_Number__c = templateOli.Related_Order_Number__c,
                PricebookEntryId = templateOli.PricebookEntryId,
                UnitPrice = templateOli.UnitPrice,
                Quantity = 25,
                Ship_From_Location__c = 'Estafeta'
            );
            
            insert new List<OpportunityLineItem>{vckOli, ukOli, estafetaOli};
            
            // Initialize controller and test each scenario
            ShippingQuantitySplitCtrl controller = new ShippingQuantitySplitCtrl(new ApexPages.StandardController(rev));
            
            // Test VCK location
            controller.selectedAddress = vckOli.Id;
            controller.selectedProductCode = vckOli.Product_Code_Copy__c;
            controller.ShipToaddressId = vckOli.Ship_To__c;
            controller.orderNumber = vckOli.Related_Order_Number__c;
            controller.incrementVarRef = '1';
            controller.quantity = 10;
            controller.toPurchase = 5;
            controller.availableinTarget = vckOli.Quantity;
            controller.updateTrialUnitsOnAddressChange();
            controller.splitTrailItems();
           // controller.save();
            
            // Test Samsara UK location
            controller.selectedAddress = ukOli.Id;
            controller.selectedProductCode = ukOli.Product_Code_Copy__c;
            controller.ShipToaddressId = ukOli.Ship_To__c;
            controller.orderNumber = ukOli.Related_Order_Number__c;
            controller.incrementVarRef = '1';
            controller.quantity = 8;
            controller.toPurchase = 4;
            controller.availableinTarget = ukOli.Quantity;
            controller.updateTrialUnitsOnAddressChange();
            controller.splitTrailItems();
           // controller.save();
            
            // Test Estafeta location
            controller.selectedAddress = estafetaOli.Id;
            controller.selectedProductCode = estafetaOli.Product_Code_Copy__c;
            controller.ShipToaddressId = estafetaOli.Ship_To__c;
            controller.orderNumber = estafetaOli.Related_Order_Number__c;
            controller.incrementVarRef = '1';
            controller.quantity = 15;
            controller.toPurchase = 7;
            controller.availableinTarget = estafetaOli.Quantity;
            controller.updateTrialUnitsOnAddressChange();
            controller.splitTrailItems();
            //controller.save();
            
            // Test quantity calculation scenarios
            controller.selectedAddress = vckOli.Id;
            controller.quantity = 25;  // Greater than available quantity
            controller.updateTrialUnitsOnAddressChange();
            controller.splitTrailItems();
            //controller.save();
            
            controller.quantity = 5;   // Less than available quantity
            controller.updateTrialUnitsOnAddressChange();
            controller.splitTrailItems();
            //controller.save();
            
            controller.quantity = vckOli.Quantity;  // Equal to available quantity
            controller.updateTrialUnitsOnAddressChange();
            controller.splitTrailItems();
           
            
                       
            
        }
        Test.stopTest();
    }
  @isTest static void testDisabledProductRecalculation() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name LIKE '%system Admin%' AND IsActive = true LIMIT 1];
        
        system.runAs(testUser){
            // Get Revenue and Trial opportunities
            Opportunity rev = [SELECT Id FROM Opportunity WHERE Name LIKE 'Rev%' LIMIT 1];
            Opportunity freeTrial = [SELECT Id FROM Opportunity WHERE Name LIKE 'Free Trial%' AND Trial_Status__c = 'Open' LIMIT 2];
            
            // Query existing OLIs
            List<OpportunityLineItem> revenueOlis = [
                SELECT Id, Product_Code_Copy__c, Ship_To__c, Ship_From_Location__c, 
                       Product2Id, Product2.ProductCode, PricebookEntryId, UnitPrice, 
                       SBQQ__QuoteLine__c, Quantity, Related_Order_Number__c,Discount
                FROM OpportunityLineItem 
                WHERE OpportunityId = :rev.Id
                AND (Is_Hardware__c = True OR Is_Accessory__c = True)
                LIMIT 1
            ];
            
            List<OpportunityLineItem> trialOlis = [
                SELECT Id, Product_Code_Copy__c, Ship_To__c, Ship_From_Location__c, 
                       Product2Id, Product2.ProductCode, PricebookEntryId, UnitPrice, 
                       Quantity, Related_Order_Number__c
                FROM OpportunityLineItem 
                WHERE OpportunityId = :freeTrial.Id
                AND (Is_Hardware__c = True OR Is_Accessory__c = True)
                LIMIT 2
            ];
            
            if(!revenueOlis.isEmpty() && !trialOlis.isEmpty()) {
                OpportunityLineItem revOli = revenueOlis[0];
                OpportunityLineItem trialOli = trialOlis[0];
                trialOli.Ship_To__c=revOli.Ship_To__c;
                  ShippingQuantitySplitCtrl controller = new ShippingQuantitySplitCtrl(new ApexPages.StandardController(rev));
                
                // Create initial wrapper
                ShippingQuantitySplitCtrl.OLIWrapper oliWrapperRev = new ShippingQuantitySplitCtrl.OLIWrapper(revOli, 10, 0, 10);
                
                controller.lstOLIWrapperOriginal.add(oliWrapperRev);
                
                // Create trial wrapper with specific conditions to match the code path
                ShippingQuantitySplitCtrl.OLIWrapper oliWrapperTrail = new ShippingQuantitySplitCtrl.OLIWrapper(trialOli, 5, 3, controller.shippingAddressMap.get(revOli.Id), 1,'',0,5);
                oliWrapperTrail.isDiabled = true;
                
                oliWrapperTrail.selectedAddress = revOli.Ship_To__c;
                controller.lstOLIWrapperTrail.add(oliWrapperTrail);
                
                
          
                // Create metadata for product code mapping
                SetShippingProdcutCode__mdt testMetadata = new SetShippingProdcutCode__mdt(
                    MasterLabel = revOli.Product2.ProductCode,
                    OldProdcutCode__c = trialOli.Product2Id
                );
                
                Test.startTest();
                // Call reCalculateQty to trigger the specific code path
                controller.reCalculateQty();
                Test.stopTest();
              
            }
        }
    }

@isTest 
    static void testSplitTrailItemsConditionalLogic() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name LIKE '%system Admin%' AND IsActive = true LIMIT 1];
        
        system.runAs(testUser){
            // Get Revenue opportunity
            Opportunity rev = [SELECT Id FROM Opportunity WHERE Name LIKE 'Rev%' LIMIT 1];
            
            // Query existing OLI with all necessary fields
            OpportunityLineItem sourceOli = [
                SELECT Id, Product_Code_Copy__c, Ship_To__c, Ship_From_Location__c, 
                       Product2Id, Product2.ProductCode, PricebookEntryId, UnitPrice, 
                       SBQQ__QuoteLine__c, Quantity, Ship_To__r.Name,Related_Order_Number__c
                FROM OpportunityLineItem 
                WHERE OpportunityId = :rev.Id
                AND (Is_Hardware__c = True OR Is_Accessory__c = True)
                LIMIT 1
            ];
            
            Test.startTest();
            
            // Create controller
            ShippingQuantitySplitCtrl controller = new ShippingQuantitySplitCtrl(new ApexPages.StandardController(rev));
            
            // Create multiple shipping addresses to ensure addressCount.size() is different from selectOptionOli.size()
            List<SelectOption> addressOptions = new List<SelectOption>();
            addressOptions.add(new SelectOption(sourceOli.Id, sourceOli.Ship_To__r.Name));
            addressOptions.add(new SelectOption('dummy1', 'Address 1'));
            addressOptions.add(new SelectOption('dummy2', 'Address 2'));
            controller.picklistOptions=addressOptions;
            // Create trial wrapper with specific values to trigger the condition
            ShippingQuantitySplitCtrl.OLIWrapper trialWrapperToSplit = new ShippingQuantitySplitCtrl.OLIWrapper(
                sourceOli,       // oli
                20,             // availableQty (high enough to allow split)
                5,              // trailToPurchase (less than availableQty-tempVarCount)
                addressOptions, // selectOptionOli (size = 3)
                1 ,'',0 ,20            // incrementVar
            );
            controller.OLIWrapperLineItem=trialWrapperToSplit;
            // Set up the wrapper with required values
            trialWrapperToSplit.selectedAddress = sourceOli.Id;
            trialWrapperToSplit.availableQty = 20;
            trialWrapperToSplit.trailToPurchase = 5;
            trialWrapperToSplit.incrementVar=1;
            // Add the wrapper to controller's list
            controller.lstOLIWrapperTrail = new List<ShippingQuantitySplitCtrl.OLIWrapper>();
            controller.lstOLIWrapperTrail.add(trialWrapperToSplit);
            controller.selectedProductCode=trialWrapperToSplit.oli.Product_Code_Copy__c;
            controller.ShipToaddressId=trialWrapperToSplit.oli.Ship_To__c;
              controller.orderNumber=trialWrapperToSplit.oli.Related_Order_Number__c;
            // Set controller properties to match the condition
            controller.toPurchase = -1;  // Less than (availableQty-tempVarCount)
            controller.quantity = 20;    // Total available quantity
             controller.incrementVarRef='1';
            
            controller.splitTrailItems();
            
              
            Test.stopTest();
        }
    }
      @isTest static void testRecalculateQuantityUnassignedKey() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name LIKE '%system Admin%' AND IsActive = true LIMIT 1];
        
        system.runAs(testUser){
            // Get Revenue opportunity
            Opportunity rev = [SELECT Id, AccountId FROM Opportunity WHERE Name LIKE 'Rev%' LIMIT 1];
            
            // Query existing OLI
            OpportunityLineItem sourceOli = [
                SELECT Id, Product_Code_Copy__c, Ship_To__c, Ship_From_Location__c, 
                       Product2Id, Product2.ProductCode, PricebookEntryId, UnitPrice, 
                       SBQQ__QuoteLine__c, Quantity
                FROM OpportunityLineItem 
                WHERE OpportunityId = :rev.Id
                AND (Is_Hardware__c = True OR Is_Accessory__c = True)
                LIMIT 1
            ];
            
            Test.startTest();
            
            // Create shipping address for testing
            Shipping_Address__c shippingAddress = new Shipping_Address__c(
                Account__c = rev.AccountId,
               
                Shipping_Address_Line_1__c = '110 Park Street',
                Shipping_City__c = 'Santa Clara',
                Shipping_State__c = 'California',
                Shipping_Country__c = 'United States',
                Shipping_Zip_Code__c = '95050',
                Name = 'Test Address'
            );
            insert shippingAddress;
            
            // Create test OLI with the shipping address
            OpportunityLineItem testOli = new OpportunityLineItem(
                OpportunityId = rev.Id,
                PricebookEntryId = sourceOli.PricebookEntryId,
                UnitPrice = sourceOli.UnitPrice,
                Quantity = 50,
                Ship_To__c = shippingAddress.Id,
                Ship_From_Location__c = 'VCK',
                Product2Id = sourceOli.Product2Id,
                Product_Code_Copy__c = sourceOli.Product_Code_Copy__c
            );
            insert testOli;
            
            // Create controller
            ShippingQuantitySplitCtrl controller = new ShippingQuantitySplitCtrl(new ApexPages.StandardController(rev));
            
            // Create revenue wrapper (oliWRev)
            ShippingQuantitySplitCtrl.OLIWrapper revenueWrapper = new ShippingQuantitySplitCtrl.OLIWrapper(testOli, 50, 15, 35);
            revenueWrapper.billedQty = 50;
            revenueWrapper.trailUnitpurchasedQty = 15;
            revenueWrapper.qtyToShip = 35;
            revenueWrapper.oli = testOli;
            
            // Create trial wrapper (oliW)
            ShippingQuantitySplitCtrl.OLIWrapper trialWrapper = new ShippingQuantitySplitCtrl.OLIWrapper(testOli, 50, 10, 40);
            //trialWrapper.isAssigned = false;
            trialWrapper.selectedAddress = testOli.Id;
            trialWrapper.trailToPurchase = 10;
            trialWrapper.oli = testOli;
            trialWrapper.availableQty = 50;
            
            // Add wrappers to controller's lists
            controller.lstOLIWrapperOriginalNew = new List<ShippingQuantitySplitCtrl.OLIWrapper>();
            controller.lstOLIWrapperOriginalNew.add(revenueWrapper);
            
            controller.lstOLIWrapperTrail = new List<ShippingQuantitySplitCtrl.OLIWrapper>();
            controller.lstOLIWrapperTrail.add(trialWrapper);
            
            
            // Set up controller properties
            controller.selectedAddress = testOli.Id;
            controller.selectedProductCode = testOli.Product_Code_Copy__c;
            controller.ShipToaddressId = shippingAddress.Id;
            
            // Create the key that will be used in recalculateQuantity
            String key = testOli.Product2Id + '_' + shippingAddress.Id;
            Test.stopTest();
        }
    }
      @isTest static void testSaveMethodExecution() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name LIKE '%system Admin%' AND IsActive = true LIMIT 1];
        
        system.runAs(testUser){
            // Get Revenue and Trial opportunities
            Opportunity rev = [SELECT Id FROM Opportunity WHERE Name LIKE 'Rev%' LIMIT 1];
            Opportunity freeTrial = [SELECT Id FROM Opportunity WHERE Name LIKE 'Free Trial%' AND Trial_Status__c = 'Open' LIMIT 1];
            
            // Query existing OLIs with Discount field added
            List<OpportunityLineItem> revenueOlis = [
                SELECT Id, Product_Code_Copy__c, Ship_To__c, Ship_From_Location__c, 
                       Product2Id, Product2.ProductCode, PricebookEntryId, UnitPrice, 
                       SBQQ__QuoteLine__c, Quantity, Related_Order_Number__c, Discount
                FROM OpportunityLineItem 
                WHERE OpportunityId = :rev.Id
                AND (Is_Hardware__c = True OR Is_Accessory__c = True)
                LIMIT 1
            ];
            
            List<OpportunityLineItem> trialOlis = [
                SELECT Id, Product_Code_Copy__c, Ship_To__c, Ship_From_Location__c, 
                       Product2Id, Product2.ProductCode, PricebookEntryId, UnitPrice, 
                       Quantity, Related_Order_Number__c, Discount,SBQQ__QuoteLine__c
                FROM OpportunityLineItem 
                WHERE OpportunityId = :freeTrial.Id
                AND (Is_Hardware__c = True OR Is_Accessory__c = True)
                LIMIT 1
            ];
            
            if(!revenueOlis.isEmpty() && !trialOlis.isEmpty()) {
                OpportunityLineItem revOli = revenueOlis[0];
                OpportunityLineItem trialOli = trialOlis[0];
                
                Test.startTest();
                
                // Create controller and set up initial data before constructor's automatic save
                ShippingQuantitySplitCtrl controller = new ShippingQuantitySplitCtrl(new ApexPages.StandardController(rev));
                
                // Setup revenue wrapper with non-zero quantities
                ShippingQuantitySplitCtrl.OLIWrapper revenueWrapper = new ShippingQuantitySplitCtrl.OLIWrapper(revOli, 20, 5, 15);
                revenueWrapper.qtyToShip = 15;
                revenueWrapper.billedQty = 20;
                revenueWrapper.trailUnitpurchasedQty = 5;
                controller.lstOLIWrapperOriginalNew.clear(); // Clear any existing wrappers
                controller.lstOLIWrapperOriginalNew.add(revenueWrapper);
                
                // Setup trial wrapper with non-zero quantities
                ShippingQuantitySplitCtrl.OLIWrapper trialWrapper = new ShippingQuantitySplitCtrl.OLIWrapper(trialOli, 10, 5, controller.shippingAddressMap.get(revOli.Id), 1,'',0,10);
                trialWrapper.selectedAddress = revOli.Id;
                trialWrapper.trailToPurchase = 5;
                trialWrapper.availableQty = 10;
                controller.lstOLIWrapperTrailNew.clear(); // Clear any existing wrappers
                controller.lstOLIWrapperTrailNew.add(trialWrapper);
                
                // Setup map entries with non-zero quantities
                String key = revOli.Product2Id + '_' + revOli.Ship_To__c;
                 ShippingQuantitySplitCtrl.OLIWrapper mapWrapper = new ShippingQuantitySplitCtrl.OLIWrapper(revOli, 5, trialOli);
                 
                // Update necessary controller properties
                controller.selectedAddress = revOli.Id;
                controller.selectedProductCode = revOli.Product2.ProductCode;
                controller.ShipToaddressId = trialOli.Ship_To__c;
                controller.orderNumber = trialOli.Related_Order_Number__c;
                controller.incrementVarRef = '1';
                PageReference result = controller.save();
              
                       
                     }
        }
    }
    @isTest static void testSetShippingQuantityQueue() {
        // Get test data from existing setup
        Opportunity rev = [SELECT Id FROM Opportunity WHERE Name LIKE 'Rev%' LIMIT 1];
        Opportunity freeTrial = [SELECT Id FROM Opportunity WHERE Name LIKE 'Free Trial%' AND Trial_Status__c = 'Open' LIMIT 1];
        List<OpportunityLineItem> existingOLIs = [
            SELECT Id, Product_Code_Copy__c, Ship_To__c, Ship_From_Location__c, 
                   Product2Id, Product2.ProductCode, PricebookEntryId, UnitPrice, 
                   Quantity,OpportunityId, Related_Order_Number__c, Discount,SBQQ__QuoteLine__c
            FROM OpportunityLineItem 
            WHERE OpportunityId = :rev.Id
            AND (Is_Hardware__c = True OR Is_Accessory__c = True)
        ];
        
        // Create test data for queue processing
        List<OpportunityLineItem> testOLIs = new List<OpportunityLineItem>();
        
        // Create an OLI to be deleted (Quantity = 0)
        OpportunityLineItem oliToDelete = existingOLIs[0].clone(false, true, false, false);
        oliToDelete.Quantity = 0;  // Set to 0 to trigger deletion
        testOLIs.add(oliToDelete);
        
        // Create an OLI to be upserted (Quantity > 0)
        OpportunityLineItem oliToUpsert = existingOLIs[0].clone(false, true, false, false);
        oliToUpsert.Quantity = 5;
        testOLIs.add(oliToUpsert);
        
        // Create list of trial opportunities to update
        List<Opportunity> trialOpps = new List<Opportunity>{freeTrial};
        
        Test.startTest();
        
        
        // Create and enqueue the job
        SetShippingQuantityQueue queueJob = new SetShippingQuantityQueue(testOLIs, rev.Id, trialOpps);
        System.enqueueJob(queueJob);
        
        Test.stopTest();
          }
}