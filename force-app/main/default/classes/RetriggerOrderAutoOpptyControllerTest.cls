@isTest
public with sharing class RetriggerOrderAutoOpptyControllerTest {
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        Account testAccount = new Account(Name = 'Testers 6 Inc',
                                          BillingState='California',
                                          BillingCountry = 'United States',
                                          BillingStreet = '26 Napier Street',
                                          BillingCity = 'London',
                                          BillingPostalCode  = '1030',
                                          Billing_Email__c  = 'qdasdas@gmail.com',
                                          Organization_Size__c = '100 - 499',
                                          Approved_Payment_Type__c = 'Direct Monthly',
                                          Industry = 'Other');
        insert testAccount;
        Contact contact = (Contact) TestFactory.createSObject(new Contact(AccountId = testAccount.Id));
        insert contact;
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contact.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = testAccount.Id);
        insert sa;
        
        // Create test opportunities
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = testAccount.Id,
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Orders processing',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contact.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Trial_Agreement_Accepted__c = true,
                                                      Ship_From_Location__c = 'DCL-KY',
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne);
        Opportunity opportunityTwo = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = testAccount.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 2 Inc',
                                                      StageName = 'Orders processing',
                                                      Shipping_Contact__c = contact.Id,
                                                      
                                                      Ship_From_Location__c = 'DCL-LA',
                                                       Shipping_Method__c = 'Ground',
                                                      
                                                      Shipping_Carrier__c = 'UPS',
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityTwo);
        Opportunity opportunityThree = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = testAccount.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      StageName = 'Decision',
                                                      Shipping_Contact__c = contact.Id,
                                                      //added by sandeep
                                                      
                                                      Ship_From_Location__c = 'DCL-LA',
                                                      
                                                      Shipping_Method__c = 'UK Standard',
                                                      
                                                      Shipping_Carrier__c = 'DHL',
                                                      
                                                      //ends here                                         
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityThree);
        Opportunity opportunityFour = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = testAccount.Id,
                                                      Type = 'Promo Opportunity',
                                                      Name = 'Opp Testers 4 Inc',
                                                      StageName = 'Purchase',
                                                      Promo_Reason__c='Exchange'
                                                     ));
        newOpportunities.add(opportunityFour);
        Opportunity opportunityFive = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = testAccount.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 5 Inc',
                                                      StageName = 'Orders processing',
                                                      Shipping_Contact__c = contact.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Monthly',
                                                      Probability = 0.95));
        newOpportunities.add(opportunityFive);
        Test.startTest();
        insert newOpportunities;
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-MEM-ENT',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;
        Test.stopTest();
    }
    
    @IsTest
    static void testGetOpportunitiesInProcessing() {
        Test.startTest();
        List<Opportunity> opportunities = RetriggerOrderAutomationOpptyController.getOpportunitiesInProcessing();
        Test.stopTest();
        
        //System.assertNotEquals(0, opportunities.size(), 'Should return opportunities in processing');
    }
    
     @IsTest
    static void testProcessOpportunityProducts() {
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Id conId = [SELECT Id FROM Contact LIMIT 1].Id;
        List<Opportunity> opps = [SELECT Id FROM Opportunity order by createddate desc];
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        opps[0].Shipping_Country__c = 'United Kingdom';
        update opps[0];
        TriggerHandler.clearAllBypasses();
        Test.startTest();
         Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=conId, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='London', Shipping_Country__c='United Kingdom', Name='Test2', Account__c = accId);
        insert sa2;
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'HW-VG55-NA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=opps[1].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000, Ship_To__c = sa2.Id);
        insert li;
        List<String> oppIds = new List<String>{opps[0].Id, opps[1].Id, opps[2].Id};
        RetriggerOrderAutomationOpptyController.processOpportunityProducts(oppIds);
        Test.stopTest();
    }   
}