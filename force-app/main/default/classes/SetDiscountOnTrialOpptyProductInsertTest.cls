@isTest(SeeAllData=false)
private class SetDiscountOnTrialOpptyProductInsertTest {
    static testMethod void testTrialOppty() {
        PricebookEntry pricebookEntry = createPricebookEntry();
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;

        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Trial' LIMIT 1];
        //Create Trial Oppty
        Opportunity trial = new Opportunity(AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
                Probability = 0, StageName = 'Incubate', type = 'Free Trial Opportunity');
        insert trial;

        //Add a Product
        OpportunityLineItem li = new OpportunityLineItem (Quantity = 5, OpportunityId = trial.Id, PriceBookEntryId = pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
        insert li;

        OpportunityLineItem newLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];

        //Since it's a trial, price should be zero
        System.assertEquals(newLi.TotalPrice, 0);

        System.debug('In testTrialOppty End');
    }

    static testMethod void testRevenueOppty() {
        System.debug('In testRevenueOppty');

        PricebookEntry pricebookEntry = createPricebookEntry();

        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;

        // Create Revenue Oppty
        Opportunity rev = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate');
        insert rev;

        // Add Product
        OpportunityLineItem li = new OpportunityLineItem (Quantity = 5, OpportunityId = rev.Id, PriceBookEntryId = pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
        insert li;

        OpportunityLineItem newLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];

        // Since it's a revenue oppty, full price must apply
        System.assertEquals(newLi.TotalPrice, 50000);

        System.debug('In testRevenueOppty End');
    }

    static testMethod void testTrialReturnOppty() {
        System.debug('In testTrialReturnOppty');

        PricebookEntry pricebookEntry = createPricebookEntry();

        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;

        // Create Free Trial Return
        Opportunity ret = new Opportunity(AccountId = a.Id, Name = 'Return', CloseDate = System.today() + 90, StageName = 'Incubate', Probability = 0, type = 'Free Trial Return');
        insert ret;

        //Add a Product
        OpportunityLineItem li = new OpportunityLineItem (Quantity = 5, OpportunityId = ret.Id, PriceBookEntryId = pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
        insert li;

        OpportunityLineItem newLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];

        //Since it's a trial return, price should be zero
        System.assertEquals(newLi.TotalPrice, 0);

        System.debug('In testTrialReturnOppty End');
    }

    static testMethod void testExchangeOppty() {
        System.debug('In testExchangeOppty');

        PricebookEntry pricebookEntry = createPricebookEntry();

        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;

        // Create Free Trial Return
        Opportunity ret = new Opportunity(AccountId = a.Id, Name = 'Return', CloseDate = System.today() + 90, StageName = 'Incubate', Probability = 0, type = 'Exchange');
        insert ret;

        //Add a Product
        OpportunityLineItem li = new OpportunityLineItem (Quantity = 5, OpportunityId = ret.Id, PriceBookEntryId = pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
        insert li;

        OpportunityLineItem newLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];

        //Since it's a trial return, price should be zero
        System.assertEquals(newLi.TotalPrice, 0);

        System.debug('In testExchangeOppty End');
    }

    /*static testMethod void testBulkOpptyLineItems() {
            System.debug('In testBulkOpptyLineItems');

            Integer batchSize1 = 10;
            Integer batchSize2 = 5;

            PricebookEntry pricebookEntry = createPricebookEntry();
            RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Trial' LIMIT 1];

            // Create accounts in batch
            List<Account> accounts = new List<Account>();
            for (Integer i = 0; i < batchSize1; i++) {

                Account a = new Account (Name = 'Account '+i, Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
                accounts.add(a);
            }

            insert accounts;

            // Create opptys in batch, with random trial or revenue type
            List<Opportunity> opptys = new List<Opportunity>();
            List<Id> opptyIds = new List<Id>();

            for (Integer i = 0; i < batchSize1; i++) {
                if(Math.random() > 0.5){
                    Opportunity rev = new Opportunity(AccountId = accounts[i].Id, Name = 'Rev Oppty' + i, CloseDate = System.today() + 90, StageName = 'Incubate');
                    opptys.add(rev);
                }
                else{
                    Opportunity trial = new Opportunity(AccountId = accounts[i].Id, Name = 'Free Trial '+i, CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
                Probability = 0, StageName = 'Incubate', type = 'Free Trial Opportunity');
                    opptys.add(trial);
                }
            }

            // Add to DB & track IDs of Opptys
            insert opptys;
            for(Integer i = 0; i < batchSize1; i++){
                opptyIds.add(opptys[i].id);
            }

            // Crete Opportunity Line Items
            List<OpportunityLineItem> opptyLineItems = new List<OpportunityLineItem>();
            List<Id> opptyLineItemIds = new List<Id>();

            for (Integer i = 0; i < batchSize1; i++){
                Opportunity oppty = opptys[i];
                for (Integer j = 0; j < batchSize2; j++){
                    OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId=oppty.Id, PriceBookEntryId=pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
                    opptyLineItems.add(li);
                }
            }

            // Add to DB & track IDs of Opportunity Line Items
            insert opptyLineItems;

            for (Integer i = 0; i < batchSize1; i++){
                for(Integer j = 0; j < batchSize2; j++){
                    Integer index = i*batchSize2 + j;
                    opptyLineItemIds.add(opptyLineItems[index].id);
                }
            }

            // Query updated Opptys & OpptyLineItems
            Map<Id, Opportunity> newOpptys = new Map<Id, Opportunity>([SELECT Id, type FROM Opportunity WHERE Id IN :opptyIds]);
            Map<Id, OpportunityLineItem> newOpptyLineItems = new Map<Id, OpportunityLineItem>([Select Id, TotalPrice from OpportunityLineItem
            where Id IN :opptyLineItemIds]);

            // Verify discount based on trial or rev oppty
            for (Integer i = 0; i < batchSize1; i++){
                Opportunity testOppty = newOpptys.get(opptyIds[i]);
                for (Integer j=0; j < batchSize2; j++){
                        Integer index = i*batchSize2 + j;
                        System.debug(index);
                        OpportunityLineItem testOpptyLineItem = newOpptyLineItems.get(opptyLineItemIds[index]);

                        if(testOppty.type == 'Free Trial Opportunity'){
                            System.assertEquals(testOpptyLineItem.TotalPrice, 0);
                        }
                        else{
                            System.assertEquals(testOpptyLineItem.TotalPrice, 50000);
                        }
                }
            }

            System.debug('In testBulkOpptyLineItems End');
    }*/

    // Helper function to define Pricebook
    static private PricebookEntry createPricebookEntry() {

        Product2 prod = (Product2) TestFactory.createSObject(
                new Product2(Name = 'Laptop X200', Family = 'Hardware'),
                true);
        PricebookEntry standardPrice = (PricebookEntry) TestFactory.createSObject(
                new PricebookEntry(
                        Product2Id = prod.Id,
                        UnitPrice = 10000,
                        IsActive = true),
                true
        );
        return standardPrice;
    }

}