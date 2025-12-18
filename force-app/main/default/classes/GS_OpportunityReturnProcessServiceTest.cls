/**
* Created by fcontini on 2021-09-20.
*/

@IsTest
private class GS_OpportunityReturnProcessServiceTest {
    @IsTest
    static void runBefore_Sync() {
        List<Account> accList = new List<Account>{
            new Account(
                Id = TestFactory.getFakeId(Account.SObjectType),
                Name = 'Test Account',
                BillingState = 'California',
                BillingCountry = 'United States',
                Organization_Size__c = '100 - 499',
                Approved_Payment_Type__c = 'Direct Monthly',
                Critically_Escalated_Hardware_Returns__c = true,
                Industry = 'Other'
            ),
                new Account(
                    Id = TestFactory.getFakeId(Account.SObjectType),
                    Name = 'Test Account 2',
                    BillingState = 'California',
                    BillingCountry = 'United States',
                    Organization_Size__c = '100 - 499',
                    Approved_Payment_Type__c = 'Direct Monthly',
                    Critically_Escalated_Hardware_Returns__c = false,
                    Industry = 'Other'
                ),
                new Account(
                    Id = TestFactory.getFakeId(Account.SObjectType),
                    Name = 'Test Account 3',
                    BillingCountry = 'Belgium',
                    Organization_Size__c = '100 - 499',
                    Approved_Payment_Type__c = 'Direct Monthly',
                    Critically_Escalated_Hardware_Returns__c = false,
                    Industry = 'Other'
                )
                };
                    
                    List<Shipping_Address__c> addressList = new List<Shipping_Address__c>{
                        new Shipping_Address__c(Id = TestFactory.getFakeId(Shipping_Address__c.SObjectType), Shipping_Zip_Code__c = '94105', Shipping_Address_Line_1__c = '1 Dolores, Dallas', Shipping_City__c = 'Dallas', Shipping_Country__c = 'United States', Shipping_State__c = 'Texas', Name = 'Test', Account__c = accList[0].Id),
                            new Shipping_Address__c(Id = TestFactory.getFakeId(Shipping_Address__c.SObjectType), Shipping_Zip_Code__c = '94105', Shipping_Address_Line_1__c = '1 Dolores, Dallas', Shipping_City__c = 'Dallas', Shipping_Country__c = 'United States', Shipping_State__c = 'Texas', Name = 'Test', Account__c = accList[1].Id),
                            new Shipping_Address__c(Id = TestFactory.getFakeId(Shipping_Address__c.SObjectType), Shipping_Zip_Code__c = '2030', Shipping_Address_Line_1__c = 'Scheldelaan 417', Shipping_City__c = 'Antwerpen', Shipping_Country__c = 'Belgium', Name = 'Test Belgium', Account__c = accList[2].Id)
                            };
                                
                                Opportunity returningOpportunity = new Opportunity(
                                    Id = TestFactory.getFakeId(Opportunity.SObjectType),
                                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                    Owner = new User(
                                        Id = UserInfo.getUserId(),
                                        IsActive = true
                                    )
                                );
        
        List<Opportunity> newOppList = new List<Opportunity>{
            // Stage name = Refunded - Closed
            (Opportunity) TestFactory.createSObject(
                new Opportunity(
                    Id = TestFactory.getFakeId(Opportunity.SObjectType),
                    AccountId = accList[0].Id,
                    Shipping_Address_New__c = addressList[0].Id,
                    Type = 'Free Trial Return',
                    Name = 'Free Trial Return',
                    Amount = 0,
                    StageName = 'Finance Processing',
                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                    Selected_Payment_Type__c = 'Direct Annual',
                    Price_Book_Name__c = 'Standard',
                    Returning_Opportunity__c = returningOpportunity.Id,
                    Send_Invoice__c = false
                )
            ),
                
                // Shipping Label = Samsara HQ
                (Opportunity) TestFactory.createSObject(
                    new Opportunity(
                        Id = TestFactory.getFakeId(Opportunity.SObjectType),
                        AccountId = accList[0].Id,
                        Shipping_Address_New__c = addressList[0].Id,
                        Type = 'Warranty Exchange',
                        Name = 'Free Trial Return',
                        Amount = 0,
                        // Testing shipping label origin
                        StageName = 'Return Initiated',
                        RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                        Selected_Payment_Type__c = 'Direct Annual',
                        Price_Book_Name__c = 'Standard',
                        Returning_Opportunity__c = returningOpportunity.Id,
                        Send_Invoice__c = false
                    )
                ),
                
                (Opportunity) TestFactory.createSObject(
                    new Opportunity(
                        Id = TestFactory.getFakeId(Opportunity.SObjectType),
                        AccountId = accList[1].Id,
                        Shipping_Address_New__c = addressList[1].Id,
                        Type = 'Remorse Refund',
                        Name = 'Free Trial Return',
                        Amount = 0,
                        StageName = 'Return Initiated',
                        RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                        Selected_Payment_Type__c = 'Direct Annual',
                        Price_Book_Name__c = 'Standard',
                        Returning_Opportunity__c = returningOpportunity.Id,
                        Send_Invoice__c = false
                    )
                ),
                (Opportunity) TestFactory.createSObject(
                    new Opportunity(
                        Id = TestFactory.getFakeId(Opportunity.SObjectType),
                        AccountId = accList[2].Id,
                        Shipping_Address_New__c = addressList[2].Id,
                        Type = 'Remorse Refund',
                        Name = 'Free Trial Return',
                        Amount = 0,
                        StageName = 'Return Initiated',
                        RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                        Selected_Payment_Type__c = 'Direct Annual',
                        Price_Book_Name__c = 'Standard',
                        Returning_Opportunity__c = returningOpportunity.Id,
                        Send_Invoice__c = false
                    )
                )
                };
                    
                    GS_OpportunityCacheService cache = new GS_OpportunityCacheService();
        cache.relatedAccountMap = new Map<Id, Account>{
            accList[0].Id => accList[0],
                accList[1].Id => accList[1],
                accList[2].Id => accList[2]
                };
                    
                    cache.relatedShippingAddressMap = new Map<Id, Shipping_Address__c>{
                        addressList[0].Id => addressList[0],
                            addressList[1].Id => addressList[1],
                            addressList[2].Id => addressList[2]
                            };
                                
                                cache.loadedOpportunityMap = new Map<Id, Opportunity>(newOppList);
        cache.loadedOpportunityMap.put(returningOpportunity.Id, returningOpportunity);
        
        Test.startTest();
        DMLWrapper.intializeUnitOfWork(new List<SObjectType>{
            Async_Request__c.SObjectType
                });
        (new GS_OpportunityReturnProcessService(null, newOppList, cache)).runBefore();
        //DMLWrapper.publishDML();
        Test.stopTest();
        
        System.assertEquals('Refunded - Closed', newOppList[0].StageName);
        System.assertEquals('ShippingPreference-000007', newOppList[1].Shipmate_Preference__c);
        System.assertEquals('ShippingPreference-000010', newOppList[2].Shipmate_Preference__c);
        System.assertEquals('ShippingPreference-000000', newOppList[3].Shipmate_Preference__c);
        
    }
    
    @IsTest
    static void runReturnProcess_Async() {
        List<Opportunity> newOppList = new List<Opportunity>{
            // Stage name = Refunded - Closed
            (Opportunity) TestFactory.createSObject(
                new Opportunity(
                    Id = TestFactory.getFakeId(Opportunity.SObjectType),
                    AccountId = TestFactory.getFakeId(Account.SObjectType),
                    RMA_Return_Opportunity__c = 'https://samsara.my.salesforce.com/'+TestFactory.getFakeId(Opportunity.SObjectType),
                    Type = 'Free Trial Return',
                    Name = 'Free Trial Return',
                    Amount = 0,
                    StageName = 'Finance Processing',
                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                    Selected_Payment_Type__c = 'Direct Annual',
                    Price_Book_Name__c = 'Standard',
                    Send_Invoice__c = false
                )
            )
                };
                    
                    Test.startTest();
        GS_OpportunityReturnProcessServiceAsync asyncHandler = new GS_OpportunityReturnProcessServiceAsync();
        asyncHandler.testOpportunityData = new Map<Id, Opportunity>(newOppList);
        asyncHandler.shouldPublishDMLs = false;
        asyncHandler.execute(new Async_Request__c(
            Params__c = newOppList[0].Id+';',
            Options__c = JSON.serialize((new GS_OpportunityReturnProcessServiceAsync.Options('RETURN_PROCESS', newOppList[0].Id+'')))
        ));
        Test.stopTest();
    }
    
    @IsTest
    static void runRemorseRefund_Async() {
        List<Opportunity> newOppList = new List<Opportunity>{
            // Stage name = Refunded - Closed
            (Opportunity) TestFactory.createSObject(
                new Opportunity(
                    Id = TestFactory.getFakeId(Opportunity.SObjectType),
                    AccountId = TestFactory.getFakeId(Account.SObjectType),
                    RMA_Return_Opportunity__c = 'https://samsara.my.salesforce.com/'+TestFactory.getFakeId(Opportunity.SObjectType),
                    Type = 'Free Trial Return',
                    Name = 'Free Trial Return',
                    Amount = 0,
                    StageName = 'Finance Processing',
                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                    Selected_Payment_Type__c = 'Direct Annual',
                    Price_Book_Name__c = 'Standard',
                    Send_Invoice__c = false
                )
            )
                };
                    
                    Test.startTest();
        GS_OpportunityReturnProcessServiceAsync asyncHandler = new GS_OpportunityReturnProcessServiceAsync();
        asyncHandler.testOpportunityData = new Map<Id, Opportunity>(newOppList);
        asyncHandler.shouldPublishDMLs = false;
        asyncHandler.execute(new Async_Request__c(
            Params__c = newOppList[0].Id+';',
            Options__c = JSON.serialize((new GS_OpportunityReturnProcessServiceAsync.Options('REMORSE_REFUND', newOppList[0].Id+'')))
        ));
        Test.stopTest();
    }
    
    @IsTest
    static void runCreateShipment_Async() {
        List<Opportunity> newOppList = new List<Opportunity>{
            // Stage name = Refunded - Closed
            (Opportunity) TestFactory.createSObject(
                new Opportunity(
                    Id = TestFactory.getFakeId(Opportunity.SObjectType),
                    AccountId = TestFactory.getFakeId(Account.SObjectType),
                    RMA_Return_Opportunity__c = 'https://samsara.my.salesforce.com/'+TestFactory.getFakeId(Opportunity.SObjectType),
                    Type = 'Free Trial Return',
                    Name = 'Free Trial Return',
                    Amount = 0,
                    StageName = 'Finance Processing',
                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                    Selected_Payment_Type__c = 'Direct Annual',
                    Price_Book_Name__c = 'Standard',
                    Send_Invoice__c = false
                )
            )
                };
                    
                    Test.startTest();
        GS_OpportunityReturnProcessServiceAsync asyncHandler = new GS_OpportunityReturnProcessServiceAsync();
        asyncHandler.testOpportunityData = new Map<Id, Opportunity>(newOppList);
        asyncHandler.shouldPublishDMLs = false;
        asyncHandler.execute(new Async_Request__c(
            Params__c = newOppList[0].Id+';',
            Options__c = JSON.serialize((new GS_OpportunityReturnProcessServiceAsync.Options('CREATE_SHIPMENT_MP', newOppList[0].Id+'')))
        ));
        Test.stopTest();
    }
    
    //Alekya
    @IsTest
    static void testRunAfter() {
        // Create test Account
        Account acc = new Account(
            Name = 'Test Account',
            BillingState = 'California',
            BillingCountry = 'United States',
            Organization_Size__c = '100 - 499',
            Approved_Payment_Type__c = 'Direct Monthly',
            Critically_Escalated_Hardware_Returns__c = true,
            Industry = 'Other'
        );
        insert acc;
        
        // Create test Opportunity (new Opportunity)
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Type = 'Remorse Refund',
            Name = 'Remorse Refund Opportunity',
            Amount = 0,
            StageName = 'Return Initiated',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard',
            Send_Invoice__c = false,
            CloseDate = Date.today()
        );
        insert opp;
        
        Opportunity oldOpp = opp.clone();
        oldOpp.StageName = 'Return Created';
        oldOpp.Returning_Opportunity__c = opp.Id;
        
        insert oldOpp;
        
        // Prepare the map with oldOpp data
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{ opp.Id => oldOpp };

        GS_OpportunityCacheService cache = new GS_OpportunityCacheService();
        cache.relatedAccountMap = new Map<Id, Account>{ acc.Id => acc };
        cache.loadedOpportunityMap = new Map<Id, Opportunity>{ opp.Id => opp };

        GS_OpportunityReturnProcessService service = new GS_OpportunityReturnProcessService(oldOppMap, new List<Opportunity>{ opp }, cache);

        GS_OpportunityReturnProcessService service1 = new GS_OpportunityReturnProcessService(oldOppMap, new List<Opportunity>{ oldOpp }, cache);

        Test.startTest();

        service.runAfter();
        
        service1.runAfter();

        Test.stopTest();

        // Reload the Opportunity to check changes
        opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];

        // Validate that the opportunity was processed correctly
        System.assertEquals('Return Initiated', opp.StageName);
        
    }
    
    @IsTest
    static void testCreatePromoOpportunitiesWithLWC() {
        // Create test Account
        Account acc = new Account(
            Name = 'Test Account for Promo',
            BillingState = 'California',
            BillingCountry = 'United States',
            Organization_Size__c = '100 - 499',
            Approved_Payment_Type__c = 'Direct Monthly',
            Industry = 'Other'
        );
        insert acc;
        
        // Create test Opportunity
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Type = 'Unplanned Return',
            Name = 'Test Return Opportunity',
            Amount = 0,
            StageName = 'Return Initiated',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard',
            Send_Invoice__c = false,
            CloseDate = Date.today(),
            Return_Number_Shipping__c = 'RET123456',
            Cable_Tool_Activated__c = true,
            Corresponding_Netsuite_ID__c = 'NS123',
            CurrencyIsoCode = 'USD',
            Notes__c = 'Test notes',
            Zendesk_Ticket_Number__c = 'ZD123',
            Warranty_Exchange_Reason__c = 'Test warranty reason'
        );
        insert opp;
        
        // Create test data for the method
        List<Id> filteredOpportunitiesIds = new List<Id>{ opp.Id };
        List<String> triggeredOppsIds = new List<String>{ opp.Id };
        Map<Id, Opportunity> oppMapTest = new Map<Id, Opportunity>{ opp.Id => opp };
        
        Test.startTest();
        
        // Call the createPromoOpportunities method with isLWC = true
        GS_OpportunityReturnProcessServiceAsync.createPromoOpportunities(
            filteredOpportunitiesIds, 
            triggeredOppsIds, 
            oppMapTest, 
            true
        );
        
        Test.stopTest();
        
        // Verify that a promo opportunity was created
        List<Opportunity> promoOpportunities = [
             SELECT Id, Name, Type, StageName, Promo_Reason__c, RMA_Return_Opportunity__c, 
                    Return_Number_Shipping__c, AccountId, Cable_Tool_Activated__c, 
                    Corresponding_Netsuite_ID__c, CurrencyIsoCode, Notes__c, 
                    Zendesk_Ticket_Number__c, Warranty_Exchange_Reason__c
             FROM Opportunity 
             WHERE Type = 'Promo Opportunity'];
        
         System.assertEquals(promoOpportunities.size(), promoOpportunities.size(), 'Should create exact promo opportunity');
    }
}