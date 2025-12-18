/**
 * Created by vikasmishra on 2020-10-21.
 * Nov-9-2022 Rajesh GTMS-10282:- Added method testOpportunityContractedBatch()
 */
@isTest
public with sharing class OpportunityContractedBatchTest {
    @testSetup
    private static void testDataSetup() {
        // Create account using TestFactory
        Account acc = (Account) TestFactory.createSObject(
            new Account(Name = 'ContractAccount'),
            true
        );

        // Create contact using TestFactory
        Contact contactOne = (Contact) TestFactory.createSObject(
            new Contact(AccountId = acc.Id),
            true
        );

        // Create contract
        Contract contract = (Contract) TestFactory.createSObject(
            new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(130),
                ContractTerm = 12
            ),
            true
        );

        // Create product using TestFactory
        Product2 testProduct = (Product2) TestFactory.createSObject(
            new Product2(
                Name = 'Test Product',
                IsActive = true,
                ProductCode = 'TEST-PROD-001',
                Family = 'Test'
            ),
            true
        );

        // Create pricebook entry using TestFactory
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = (PricebookEntry) TestFactory.createSObject(
            new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = testProduct.Id,
                UnitPrice = 100,
                IsActive = true
            ),
            true
        );

        // Create multiple opportunities using TestFactory.createSObjectList
        List<Opportunity> opportunities = new List<Opportunity>();

        // Create Revenue Opportunity
        Opportunity revenueOpp = (Opportunity) TestFactory.createSObject(
            new Opportunity(
                AccountId = acc.Id,
                Name = 'Opp Testers Revenue',
                StageName = 'Proposal',
                CloseDate = Date.today().addDays(30),
                Type = 'Revenue Opportunity',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                Shipping_Contact__c = contactOne.Id,
                Selected_Payment_Type__c = 'Direct Annual',
                Price_Book_Name__c = 'Standard',
                Send_Invoice__c = false,
                SBQQ__AmendedContract__c = contract.Id
            ),
            true
        );
        opportunities.add(revenueOpp);

        // Create quote and quote lines for the revenue opportunity
        SBQQ__Quote__c quote = (SBQQ__Quote__c) TestFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = revenueOpp.Id,
                SBQQ__Primary__c = false
            ),
            true
        );

        // Disable SBQQ triggers to prevent governor limit issues
        //SBQQ.TriggerControl.disable();
        
        SBQQ__QuoteLine__c quoteLine = (SBQQ__QuoteLine__c) TestFactory.createSObject(
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = testProduct.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__ListPrice__c = 100,
                SBQQ__NetPrice__c = 100
            ),
            true
        );


        // Create orders for both opportunities
        List<Order> orders = new List<Order>();
        for(Opportunity opp : opportunities) {
            orders.add((Order) TestFactory.createSObject(
                new Order(
                    AccountId = acc.Id,
                    OpportunityId = opp.Id,
                    EffectiveDate = Date.today(),
                    Status = 'Draft',
                    Pricebook2Id = pricebookId
                ),
                true
            ));
        }
    }

    //GTMS-10282
  /*  @IsTest
    private static void testOpportunityContractedBatch() {
        String chron = '0 1 * * * ?';
        Test.startTest();
	        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
            SBQQ__Quote__c quote = [SELECT Id,SBQQ__Primary__c FROM SBQQ__Quote__c LIMIT 1];
            quote.SBQQ__Primary__c = true;
            update quote;
       		TriggerHandler.clearAllBypasses();
            OpportunityContractedBatch myClass = new OpportunityContractedBatch(false,1,new Map<Id, Boolean>()); 
            system.schedule('Test Sched', chron, myClass);
        Test.stopTest();
    }*/
    
    @IsTest
    private static void testOpportunityContractedBatchOppList() {
        Map<Id, Boolean> oppIdMap = new Map<Id, Boolean>();
        Opportunity opp = [Select Id from Opportunity where Type = 'Revenue Opportunity' limit 1];
        Account acc = [Select Id from Account limit 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id from SBQQ__QuoteLine__c limit 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        oppIdMap.put(opp.Id,false);
        String chron = '0 1 * * * ?';
        Test.startTest();
        OpportunityLineItem oli = (OpportunityLineItem) TestFactory.createSObject(
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100,
                Account__c = acc.Id,
                SBQQ__QuoteLine__c = quoteLine.Id
            ),
            true
        );
            OpportunityContractedBatch myClass = new OpportunityContractedBatch(true,1,oppIdMap); 
            system.schedule('Test Sched', chron, myClass);
        Test.stopTest();
    }
    
     @IsTest
    private static void testOpportunityContractedBatchRemorse() {
        Map<Id, Boolean> oppIdMap = new Map<Id, Boolean>();
        Opportunity opp = [Select Id, Type from Opportunity where Type = 'Revenue Opportunity' limit 1];
        opp.Type = 'Remorse Refund';
        Account acc = [Select Id from Account limit 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id from SBQQ__QuoteLine__c limit 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        oppIdMap.put(opp.Id,false);
        String chron = '0 1 * * * ?';
        Test.startTest();
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        update opp;
        OpportunityLineItem oli = (OpportunityLineItem) TestFactory.createSObject(
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100,
                Account__c = acc.Id,
                SBQQ__QuoteLine__c = quoteLine.Id
            ),
            true
        );
        TriggerHandler.clearAllBypasses();
        OpportunityContractedBatch myClass = new OpportunityContractedBatch(false,1,oppIdMap); 
        system.schedule('Test Sched', chron, myClass);
        Test.stopTest();
    }
}