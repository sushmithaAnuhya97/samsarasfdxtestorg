@isTest
public class Product2TriggerTests {
 @TestSetup
     static void testDataSetUp(){
        
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        // Create Product
        List<Product2> products = new List<Product2>();
        Product2 vg33Bundle = new Product2(Name= 'VG33-BUNDLE New', ProductCode = 'VG33-BUNDLE', Family = 'Test', Weight_oz__c = 22, Product_Status__c ='GA', IsActive = true);
        products.add(vg33Bundle);
        
        Product2 vg33 = new Product2(Name= 'HW-VG33 New', ProductCode = 'HW-VG33', Family = 'Test', Weight_oz__c = 12, Product_Status__c ='GA', IsActive = true);
        products.add(vg33);
        
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO New', ProductCode = 'LIC-VG-36MO', Family = 'Test', Weight_oz__c = 16, Product_Status__c ='GA', IsActive = true);
        products.add(vgLicense);
        
        Product2 em11Bundle = new Product2(Name= 'EM11-Bundle New', ProductCode = 'EM11-Bundle', Family = 'Test', Weight_oz__c = 20, Product_Status__c ='GA', IsActive = true);
        products.add(em11Bundle);
        
        Product2 em11 = new Product2(Name= 'HW-EM11 New', ProductCode = 'HW-EM11', Family = 'Test', Weight_oz__c = 24, Product_Status__c ='GA', IsActive = true);
        products.add(em11);
        
        Product2 emLicense = new Product2(Name= 'LIC-EM-36MO New', ProductCode = 'LIC-EM-36MO', Family = 'Test', Weight_oz__c = 26, Product_Status__c ='GA', IsActive = true);
        products.add(emLicense);
        
        Product2 vgCable = new Product2(Name= 'CBL-VG-BTSLA3-19 New', ProductCode = 'CBL-VG-BTSLA3-19', Family = 'Test', Weight_oz__c = 32, Product_Status__c ='GA', IsActive = true);
        products.add(vgCable);
        
        insert products;

	}
    @isTest 
    static void TestProdHelper() {
        
        Product2 getProd = [SELECT Id, ProductCode, Family, Product_Type__c,IsActive,
                           Weight_oz__c,Dimensions_cm3__c, Product_Status__c FROM Product2 LIMIT 1];
        
        getProd.ProductCode = 'NPS-Update';
        Test.startTest();
        update getProd;      
 
        Test.stopTest();
        
    }
     @isTest
    static void testDeleteProd(){
        
        Product2 DelProd = [SELECT Id, ProductCode, Family, Product_Type__c,IsActive,
                           Weight_oz__c,Dimensions_cm3__c, Product_Status__c FROM Product2 LIMIT 1];
        
        Test.startTest();
            delete DelProd;     
        Test.stopTest();
    }

    @isTest
    static void testPlatformEventPublishing() {
        // Get a product from test setup
        Product2 testProduct = [SELECT Id, ProductCode, Family, Product_Type__c, IsActive,
                               Weight_oz__c, Dimensions_cm3__c, Product_Status__c, 
                               Push_to_Webstore__c, BigCommerce_Id__c, Webstore_Sync_Error__c
                               FROM Product2 LIMIT 1];
        
        // Test platform event publishing on insert
        Test.startTest();
        
        // Test insert scenario - create a new product that should trigger platform event
        Product2 newProduct = new Product2(
            Name = 'Test Platform Event Product',
            ProductCode = 'TEST-PE-001',
            Family = 'Test',
            Weight_oz__c = 10,
            Product_Status__c = 'GA',
            IsActive = true,
            Push_to_Webstore__c = false,
            BigCommerce_Id__c = 'test-bc-id'
        );
        
        insert newProduct;
        
        // Test update scenario - update product to trigger platform event
        testProduct.Push_to_Webstore__c = true;
        testProduct.BigCommerce_Id__c = 'updated-bc-id';
        
        Map<Id, Product2> oldProductMap = new Map<Id, Product2>();
        oldProductMap.put(testProduct.Id, testProduct.clone(true, true, true, true));
        
        update testProduct;
        
        Test.stopTest();
        
        // Verify platform events were published
        // Note: In test context, platform events are not actually published to the event bus
        // but we can verify the logic executed without errors
        
        // Verify the product was updated correctly
        Product2 updatedProduct = [SELECT Id, Push_to_Webstore__c, BigCommerce_Id__c 
                                 FROM Product2 WHERE Id = :testProduct.Id];
        System.assertEquals(true, updatedProduct.Push_to_Webstore__c, 'Push_to_Webstore__c should be set to true');
    }

    @isTest
    static void testIsRecordModifiedByMulesoft() {
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            ProfileId = p.Id,
            LastName = 'TestUser',
            Email = 'testuser@test.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'Test',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            EmployeeNumber = 'TEST001'
        );
        insert testUser;
        
        // Get a product from test setup
        Product2 testProduct = [SELECT Id, ProductCode, Family, Product_Type__c, IsActive,
                               Weight_oz__c, Dimensions_cm3__c, Product_Status__c, 
                               Push_to_Webstore__c, BigCommerce_Id__c, Webstore_Sync_Error__c,
                               Push_to_Netsuite__c
                               FROM Product2 LIMIT 1];
        
        Test.startTest();
        
        // Test as regular user without permission set (should return false)
        System.runAs(testUser) {
            Product2 oldProduct = testProduct.clone(true, true, true, true);
            testProduct.Push_to_Netsuite__c = !testProduct.Push_to_Netsuite__c;
            
            Boolean result = Product2TriggerHelper.isRecordModifiedByMulesoft(testProduct, oldProduct);
            System.assertEquals(false, result, 'Should return false for user without permission set');
        }
        
        // Assign the NetSuite Service User Permission to the test user
        PermissionSet netSuitePermissionSet = [SELECT Id FROM PermissionSet 
                                             WHERE Name = 'NetSuite_Service_User_Permission' 
                                             LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = netSuitePermissionSet.Id
        );
        insert psa;
        
        // Test as user with permission set (should return true)
        System.runAs(testUser) {
            Product2 oldProduct = testProduct.clone(true, true, true, true);
            testProduct.Push_to_Netsuite__c = !testProduct.Push_to_Netsuite__c;
            
            Boolean result = Product2TriggerHelper.isRecordModifiedByMulesoft(testProduct, oldProduct);
            System.assertEquals(true, result, 'Should return true for user with permission set');
        }
        
        Test.stopTest();
    }

}