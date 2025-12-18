@isTest
private class ValidateProductQuantityCalloutTest {

    private static final String TEST_OPP_NAME = 'Opp Testers 1 Inc';

    @TestSetup
    private static void testDataSetup() {
        System.runAs(new User(Id = UserInfo.getUserId())){
            //(new PermissionSetAssignmentService()).assignPermissionSetByName(new List<Id>{UserInfo.getUserId()}, 'Validation_Rule_By_Pass');
            //PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Validation_Rule_By_Pass'];
            //insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        }

        System.runAs(new User(Id = UserInfo.getUserId())){        
            List<Opportunity> newOpportunities = new List<Opportunity>();
            List<Account> newAccounts = new List<Account>();
            List<Contact> newContacts = new List<Contact>();
            List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();

            Account accountOne = new Account(Name = 'Testers 6 Inc',
                BillingState = 'California',
                BillingCountry = 'United States',
                Organization_Size__c = '100 - 499',
                Approved_Payment_Type__c = 'Direct Monthly',
                Industry = 'Other'
            );
            newAccounts.add(accountOne);

            insert newAccounts;

            Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id, Email = 'test@test.com'));
            newContacts.add(contactOne);
            insert newContacts;

            Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c = contactOne.Id, Shipping_Address_Line_1__c = '1 Dolores, Dallas', Shipping_City__c = 'Dallas', Shipping_Country__c = 'United States', Shipping_State__c = 'Texas', Name = 'Test', Account__c = accountOne.Id);
            shippingAddressList.add(sa);
            insert shippingAddressList;

            Opportunity opportunityOne = (Opportunity)
                TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                    Type = 'Free Trial Opportunity',
                    Name = TEST_OPP_NAME,
                    StageName = 'Ready to Ship',
                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                    Shipping_Contact__c = contactOne.Id,
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Selected_Payment_Type__c = 'Direct Annual',
                    Price_Book_Name__c = 'Standard',
                    Trial_Period__c = 10,
                    CloseDate = System.today().addDays(10),
                    Trial_Primary_Contact__c = contactOne.Id,
                    Trial_Goal_1__c = ' First Goal',
                    Shipping_and_Handling_Manual__c = 10,
                    Planned_Trial_Installation_Date__c = System.today(),
                    Owner_Role_Copy__c = 'AE Role',
                    Send_Invoice__c = false
                )
            );
            newOpportunities.add(opportunityOne);

            Opportunity opportunityTwo = (Opportunity) TestFactory.createSObject(
                new Opportunity(
                    AccountId                = accountOne.Id,
                    Name                     = TEST_OPP_NAME+'2',
                    Type                     = 'Revenue Opportunity',
                    StageName                = 'Ready to Ship',
                    RecordTypeId             = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                    Shipping_Contact__c      = contactOne.Id,
                    Pricebook2Id             = Test.getStandardPricebookId(),
                    Selected_Payment_Type__c = 'Direct Annual',
                    Price_Book_Name__c       = 'Standard',
                    CloseDate                = System.today().addDays(10),
                    Shipping_and_Handling_Manual__c = 10,
                    Owner_Role_Copy__c = 'AE Role',
                    Planned_Trial_Installation_Date__c = System.today()
                )
            );
            newOpportunities.add(opportunityTwo);
            insert newOpportunities;

            //Create Products
            List<Product2> productList = new List<Product2>{
                (Product2) TestFactory.createSObject(new Product2(Name = 'HW-VG34',                  ProductCode = 'HW-VG34',                  Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'HW-CM-TestProduct',        ProductCode = 'HW-CM-TestProduct',        Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'CBL-VG--TestProduct',      ProductCode = 'CBL-VG--TestProduct',      Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'HW-AG46-TestProduct',      ProductCode = 'HW-AG46-TestProduct',      Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'CBL-AG--TestProduct',      ProductCode = 'CBL-AG--TestProduct',      Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'HW-EM-TestProduct',        ProductCode = 'HW-EM-TestProduct',        Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'LIC-CM-TestProduct',       ProductCode = 'LIC-CM-TestProduct',       Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'LIC-EM-TestProduct',       ProductCode = 'LIC-EM-TestProduct',       Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'LIC-AG4P-ENT-TestProduct', ProductCode = 'LIC-AG4P-ENT-TestProduct', Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'HW-AG46P-TestProduct',     ProductCode = 'HW-AG46P-TestProduct',     Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'HW--TestProduct',          ProductCode = 'HW--TestProduct',          Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'ACC--TestProduct',         ProductCode = 'ACC--TestProduct',         Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'CBL--TestProduct',         ProductCode = 'CBL--TestProduct',         Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'HW-AG46',                  ProductCode = 'HW-AG46',                  Family = 'Test'), false),
                (Product2) TestFactory.createSObject(new Product2(Name = 'HW-ZEROVALUE',             ProductCode = 'HW-ZEROVALUE',             Family = 'Test'), false)
            };
            insert productList;

            //Create PriceBookEntries
            List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
            for (Product2 product : productList){
                pricebookEntries.add(
                    (PricebookEntry) TestFactory.createSObject(
                        new PricebookEntry(Product2Id = product.Id, UnitPrice = 1000, IsActive = true, Pricebook2Id = Test.getStandardPricebookId())
                    )
                );
            }
            insert pricebookEntries;
            
            List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
            for (Opportunity opp : newOpportunities){
                for (Integer it = 0; it < productList.size(); it++){
                    oppLineItemList.add(
                        new OpportunityLineItem(
                            OpportunityId = opp.Id,
                            Product2Id = productList[it].Id,
                            UnitPrice = (!productList[it].Name.endsWith('ZEROVALUE') ? 1000 : 0),
                            Quantity = 1,
                            PricebookEntryId = pricebookEntries[it].Id
                        )
                    );
                }
            }
            Test.startTest();
            TriggerHandler.bypass('AccountTriggerHandler');
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            TriggerHandler.bypass('OpportunityTriggerHandlerContext');
            insert oppLineItemList;
            TriggerHandler.clearAllBypasses();
            Test.stopTest();
        }
    }

    @isTest
    public static void fetchProductQuantity_directCallTest(){
        System.runAs(new User(Id = UserInfo.getUserId())){
            Opportunity opp = [SELECT Id,Shipping_Country__c, (SELECT Id, ProductCode FROM OpportunityLineItems) FROM Opportunity WHERE Name = :TEST_OPP_NAME+'2' LIMIT 1];

            String oppLineItemProductCode = '';
            for (OpportunityLineItem item : opp.OpportunityLineItems){
                oppLineItemProductCode += (oppLineItemProductCode.length() > 0 ? ',' : '')+item.ProductCode;
            }

            Map<String, String> oppToProductCodeMap = new Map<String, String>{ opp.Id => oppLineItemProductCode };

            Test.setMock(HttpCalloutMock.class, new DclHttpCalloutMock());
            Test.startTest();
            ValidateProductQuantityFuture.fetchProductQuantity(oppToProductCodeMap);
            ValidateProductQuantityQueueable que = new ValidateProductQuantityQueueable(oppToProductCodeMap);
            System.enqueueJob(que);
            Test.stopTest();
            // Nothing was changed here, no assertions needs to be made (no callout performed, but all items should have been accounted for).
        }
    }

    @isTest
    public static void fetchProductQuantity_directCallTest_Trial(){ 
        System.runAs(new User(Id = UserInfo.getUserId())){
            Opportunity opp = [SELECT Id,Shipping_Country__c, (SELECT Id, ProductCode FROM OpportunityLineItems) FROM Opportunity WHERE Name = :TEST_OPP_NAME
            LIMIT 1];

            String oppLineItemProductCode = '';
            for (OpportunityLineItem item : opp.OpportunityLineItems){
                oppLineItemProductCode += (oppLineItemProductCode.length() > 0 ? ',' : '')+item.ProductCode;
            }

            Map<String, String> oppToProductCodeMap = new Map<String, String>{ opp.Id => oppLineItemProductCode };

            Test.setMock(HttpCalloutMock.class, new DclHttpCalloutMock());
            Test.startTest();
            ValidateProductQuantityFuture.fetchProductQuantity(oppToProductCodeMap);
            ValidateProductQuantityQueueable que = new ValidateProductQuantityQueueable(oppToProductCodeMap);
            System.enqueueJob(que);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void fetchProductQuantityVCKTest(){
        System.runAs(new User(Id = UserInfo.getUserId())){
            Opportunity opp = [SELECT Id, Shipping_Country__c, (SELECT Id, ProductCode FROM OpportunityLineItems) FROM Opportunity WHERE Name = :TEST_OPP_NAME+'2' LIMIT 1];

            String oppLineItemProductCode = '';
            for (OpportunityLineItem item : opp.OpportunityLineItems){
                oppLineItemProductCode += (oppLineItemProductCode.length() > 0 ? ',' : '')+item.ProductCode;
            }
            Map<String, String> oppToProductCodeMap = new Map<String, String>{ opp.Id => oppLineItemProductCode };

            Test.setMock(HttpCalloutMock.class, new VCKHttpCalloutMock());
            Test.startTest();
            ValidateProductQuantityVCKFuture.fetchVCKProductQuantity(oppToProductCodeMap);        
            ValidateProductQuantityVCKQueueable que = new ValidateProductQuantityVCKQueueable(oppToProductCodeMap);
            System.enqueueJob(que);
            Test.stopTest();
            // Nothing was changed here, no assertions needs to be made (no callout performed, but all items should have been accounted for).
        }
    }
    
    @isTest
    public static void fetchProductQuantityVCKTestMoreQty(){
        System.runAs(new User(Id = UserInfo.getUserId())){
            Opportunity opp = [SELECT Id, Shipping_Country__c, (SELECT Id, ProductCode FROM OpportunityLineItems) FROM Opportunity WHERE Name = :TEST_OPP_NAME+'2' LIMIT 1];

            String oppLineItemProductCode = '';
            for (OpportunityLineItem item : opp.OpportunityLineItems){
                oppLineItemProductCode += (oppLineItemProductCode.length() > 0 ? ',' : '')+item.ProductCode;
            }
            Map<String, String> oppToProductCodeMap = new Map<String, String>{ opp.Id => oppLineItemProductCode };

            Test.setMock(HttpCalloutMock.class, new VCKHttpCalloutMockMoreQty());
            Test.startTest();
            ValidateProductQuantityVCKFuture.fetchVCKProductQuantity(oppToProductCodeMap);        
            ValidateProductQuantityVCKQueueable que = new ValidateProductQuantityVCKQueueable(oppToProductCodeMap);
            System.enqueueJob(que);
            Test.stopTest();
            // Nothing was changed here, no assertions needs to be made (no callout performed, but all items should have been accounted for).
        }
    }
    
    @isTest
    public static void isRePushToolTest(){ 
        System.runAs(new User(Id = UserInfo.getUserId())){
            Opportunity opp = [SELECT Id, Shipping_Country__c, (SELECT Id, ProductCode FROM OpportunityLineItems) FROM Opportunity WHERE Name = :TEST_OPP_NAME+'2' LIMIT 1];
            TriggerHandler.bypass('OpportunityTriggerHandlerContext');
            TriggerHandler.bypass('AccountTriggerHandler');
            TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
            String oppLineItemProductCode = '';
            for (OpportunityLineItem item : opp.OpportunityLineItems){
                oppLineItemProductCode += (oppLineItemProductCode.length() > 0 ? ',' : '')+item.ProductCode;
            }

            Map<String, String> oppToProductCodeMap = new Map<String, String>{ opp.Id => oppLineItemProductCode };

            Test.setMock(HttpCalloutMock.class, new DclHttpCalloutMock());
            Test.startTest();
            ValidateProductQuantityQueueable que = new ValidateProductQuantityQueueable(oppToProductCodeMap, true);
            System.enqueueJob(que);
            TriggerHandler.clearAllBypasses();
            Test.stopTest();
        }
    }
    
    @isTest
    public static void mexicoTest(){ 
        System.runAs(new User(Id = UserInfo.getUserId())){
            Opportunity opp = [SELECT Id, Shipping_Country__c, (SELECT Id, ProductCode FROM OpportunityLineItems) FROM Opportunity WHERE Name = :TEST_OPP_NAME+'2' LIMIT 1];
            opp.Shipping_Country__c = 'Mexico';
            TriggerHandler.bypass('OpportunityTriggerHandlerContext');
            TriggerHandler.bypass('AccountTriggerHandler');
            TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
            update opp;
            String oppLineItemProductCode = '';
            for (OpportunityLineItem item : opp.OpportunityLineItems){
                oppLineItemProductCode += (oppLineItemProductCode.length() > 0 ? ',' : '')+item.ProductCode;
            }

            Map<String, String> oppToProductCodeMap = new Map<String, String>{ opp.Id => oppLineItemProductCode };

            Test.setMock(HttpCalloutMock.class, new DclHttpCalloutMock());
            Test.startTest();
            ValidateProductQuantityQueueable que = new ValidateProductQuantityQueueable(oppToProductCodeMap, true);
            System.enqueueJob(que);
            TriggerHandler.clearAllBypasses();
            Test.stopTest();
        }
    }

    @isTest
    public static void EMEATest(){ 
        System.runAs(new User(Id = UserInfo.getUserId())){
            Opportunity opp = [SELECT Id, Shipping_Country__c, (SELECT Id, ProductCode FROM OpportunityLineItems) FROM Opportunity WHERE Name = :TEST_OPP_NAME+'2' LIMIT 1];
            opp.Shipping_Country__c = 'United Kingdom';
            TriggerHandler.bypass('OpportunityTriggerHandlerContext');
            TriggerHandler.bypass('AccountTriggerHandler');
            TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
            update opp;
            String oppLineItemProductCode = '';
            for (OpportunityLineItem item : opp.OpportunityLineItems){
                oppLineItemProductCode += (oppLineItemProductCode.length() > 0 ? ',' : '')+item.ProductCode;
            }

            Map<String, String> oppToProductCodeMap = new Map<String, String>{ opp.Id => oppLineItemProductCode };

            Test.setMock(HttpCalloutMock.class, new DclHttpCalloutMock());
            Test.startTest();
            ValidateProductQuantityQueueable que = new ValidateProductQuantityQueueable(oppToProductCodeMap, true);
            System.enqueueJob(que);
            TriggerHandler.clearAllBypasses();
            Test.stopTest();
        }
    }
    
    
    
// GTMS-27362 start
    public class VCKHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"results":[{"qtyAvailable":30}]}');
            return res;
        }
    }
    // GTMS-27362 End
   // GTMS-27362 start
    public class VCKHttpCalloutMockMoreQty implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"results":[{"qtyAvailable":300}]}');
            return res;
        }
    }
    // GTMS-27362 End
}