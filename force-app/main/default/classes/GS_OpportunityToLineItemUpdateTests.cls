@IsTest
public class GS_OpportunityToLineItemUpdateTests {

    @testSetup
    private static void testDataSetup() {
       insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
       List<Opportunity> newOpportunities = new List<Opportunity>();
       List<Account> newAccounts = new List<Account>();
       List<Contact> newContacts = new List<Contact>();
       List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
        
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        newAccounts.add(accountOne);
        
        Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                BillingState='California',
                                BillingCountry = 'United States',
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                Industry = 'Other');
        newAccounts.add(accountTwo);

        insert newAccounts;
        
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        newContacts.add(contactOne);
        
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'test@test.com'));
        newContacts.add(contactTwo);

        insert newContacts;
        
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
        shippingAddressList.add(sa);
        Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = accountOne.Id);
        shippingAddressList.add(sa2);

        insert shippingAddressList;

        
    }

    static private PricebookEntry getPricebookEntry(Id pricebookId, String productCode) {
        PricebookEntry entry = [Select Id, UnitPrice, Pricebook2Id, ProductCode from PricebookEntry where ProductCode = :productCode and Pricebook2Id = :pricebookId LIMIT 1];
        return entry;
    }

    static private void addProducts(Id pricebookId) {

        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name = 'LIC-VG33', ProductCode = 'LIC-VG33', Family = 'Test');
        Product2 vG34 = new Product2(Name= 'HW-VG34', ProductCode = 'HW-VG34', Family = 'Test');
        products.add(vg33);
        products.add(vG34);
        
        insert products;
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry vG34PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vG34.Id, UnitPrice = 10000, IsActive = true);

        pricebookEntries.add(vg33PB);
        pricebookEntries.add(vG34PB);
        insert pricebookEntries;

    }
    
    @isTest static void testExpressSetAnnualDiscountLineItem() {
      List<Opportunity> newOpportunities = new List<Opportunity>();
      Account accountOne = [Select id from Account where Name = 'Testers 1 Inc'];
      Contact contactOne = [Select id from Contact where AccountId =: accountOne.id];
      Shipping_Address__c sa = [Select id from Shipping_Address__c where Shipping_Contact__c =: contactOne.Id Limit 1];
                Opportunity freeTrialOpp = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Webstore Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Shipping_Address_NEW__c = sa.Id,
                                                      Shipping_Country__c = 'United States',
                                                      CurrencyISOCode = 'USD',
                                                      Ship_From_Location__c = 'DCL-KY',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        
        
        newOpportunities.add(freeTrialOpp); 
        
        Opportunity freeTrialOpp2 = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Webstore Inc 2',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Shipping_Address_NEW__c = sa.Id,
                                                      Shipping_Country__c = 'United States',
                                                      CurrencyISOCode = 'USD',
                                                      Ship_From_Location__c = 'DCL-KY',
                                                      Selected_Payment_Type__c = 'Upfront Payments'));
        
         newOpportunities.add(freeTrialOpp2); 
        
        Opportunity freeTrialOppWithoutSelectedPaymentType = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Webstore Inc 3',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Shipping_Address_NEW__c = sa.Id,
                                                      Shipping_Country__c = 'United States',
                                                      CurrencyISOCode = 'USD'));
        
         newOpportunities.add(freeTrialOppWithoutSelectedPaymentType); 
        
         Test.startTest();
        
        insert newOpportunities;
        
        Opportunity thisOpp = [SELECT Id, Express_Selected_Discount__c, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE id=: freeTrialOpp.Id];
		Opportunity thisOpp2 = [SELECT Id, Express_Selected_Discount__c, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE Name='Webstore Inc 2'];
		Opportunity thisOpp3 = [SELECT Id, Express_Selected_Discount__c, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE Name='Webstore Inc 3'];

        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
    
        
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        OpportunityLineItem olivg33 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, Discount = 10.0);
        oliList.add(olivg33);
        
        OpportunityLineItem olivg33UpfrontOpptyLineItem = new OpportunityLineItem(OpportunityId = thisOpp2.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, Discount = 10.0);
	    oliList.add(olivg33UpfrontOpptyLineItem);
       
        OpportunityLineItem olivg33OpptyLineItem = new OpportunityLineItem(OpportunityId = thisOpp3.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, Discount = 10.0);
	    oliList.add(olivg33OpptyLineItem);
        
        insert oliList;
       
        List<OpportunityLineItem> updateOliList = new List<OpportunityLineItem>();
		olivg33.UnitPrice = 1000;
        olivg33.Discount = 10.0;
        updateOliList.add(olivg33);
            
        olivg33UpfrontOpptyLineItem.UnitPrice = 1000;
        olivg33UpfrontOpptyLineItem.Discount = 10.0;
        updateOliList.add(olivg33UpfrontOpptyLineItem);
        update updateOliList;
        
        Test.stopTest();

        
        
        
        thisOpp = [SELECT Id, License_Term__c, Express_Annual_Discount__c, Express_Selected_Discount__c, Total_License_Due__c, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE id =: thisOpp.Id];
                
        thisOpp2 = [SELECT Id, License_Term__c, Express_Upfront_Discount__c, Express_Annual_Discount__c, Total_License_Due__c, Express_Selected_Discount__c, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE id =: thisOpp2.Id];
        
        thisOpp.StageName = 'Orders Processing';
        thisOpp.Shipping_Method__c = '3 Day Select';
        thisOpp.Unique_Shipping_Addresses__c = 1;
        thisOpp.Configuration_Segment__c = 'Express';
        thisOpp.Probability = 50;
            
        update thisOpp;
        

        new GS_OpportunityToLineItemUpdateAsync().execute(new Async_Request__c(
            Params__c = thisOpp.Id+';'+thisOpp2.Id+';'+thisOpp3.Id+';'
        ));
       
       olivg33 = [SELECT Id, Selected_Sales_Price__c, UnitPrice, Express_Annual_Discount__c, TotalPrice, Discount FROM OpportunityLineItem WHERE id =: olivg33.Id LIMIT 1];
       olivg33UpfrontOpptyLineItem = [SELECT Id, Express_Upfront_Discount__c,Selected_Sales_Price__c, UnitPrice, Express_Annual_Discount__c, TotalPrice, Discount FROM OpportunityLineItem WHERE id =: olivg33UpfrontOpptyLineItem.Id LIMIT 1];
       Decimal expressSelectedDiscount = thisOpp.Express_Selected_Discount__c != null ? thisOpp.Express_Selected_Discount__c : 0;

        system.assertEquals(10, olivg33.Express_Annual_Discount__c);
        

        system.assertEquals(thisOpp.Express_Selected_Discount__c + olivg33.Express_Annual_Discount__c
                            , olivg33.Discount);
        
        system.assertEquals(olivg33.UnitPrice * (100 - olivg33.Discount) / (thisOpp.License_Term__c * 100)
                            , olivg33.Selected_Sales_Price__c);

        
        expressSelectedDiscount = thisOpp2.Express_Selected_Discount__c != null ? thisOpp2.Express_Selected_Discount__c : 0;
        
       system.assertEquals((((thisOpp2.Total_License_Due__c - (thisOpp2.Total_License_Due__c * (1 - (thisOpp2.Express_Upfront_Discount__c / 100)))) / (thisOpp2.Total_License_Due__c / (1 - (expressSelectedDiscount / 100)))) * 100)
                           , olivg33UpfrontOpptyLineItem.Express_Upfront_Discount__c);
       
       system.assertEquals(olivg33UpfrontOpptyLineItem.UnitPrice * (100 - olivg33UpfrontOpptyLineItem.Discount) / (thisOpp2.License_Term__c * 100)
                            , olivg33UpfrontOpptyLineItem.Selected_Sales_Price__c);
       system.assertEquals(thisOpp2.Express_Selected_Discount__c + olivg33UpfrontOpptyLineItem.Express_Upfront_Discount__c
                           , olivg33UpfrontOpptyLineItem.Discount);
    }
    
    
    @isTest static void testprodCodesToDispatchMap() {
      List<Opportunity> newOpportunities = new List<Opportunity>();
      Account accountOne = [Select id from Account where Name = 'Testers 1 Inc'];
      Contact contactOne = [Select id from Contact where AccountId =: accountOne.id];
      Shipping_Address__c sa = [Select id from Shipping_Address__c where Shipping_Contact__c =: contactOne.Id Limit 1];
                Opportunity freeTrialOpp = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Webstore Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Shipping_Address_NEW__c = sa.Id,
                                                      Shipping_Country__c = 'United States',
                                                      CurrencyISOCode = 'USD',
                                                      Ship_From_Location__c = 'DCL-KY',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        
        
        newOpportunities.add(freeTrialOpp); 
        
        insert newOpportunities;
        
        Opportunity thisOpp = [SELECT Id, Express_Selected_Discount__c, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE Name='Webstore Inc'];
		Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg34 = getPricebookEntry(pricebookId, 'HW-VG34');
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        OpportunityLineItem olivG34 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 1, PriceBookEntryId = vg34.Id, UnitPrice = vg34.UnitPrice);
		oliList.add(olivG34); 
        insert oliList;

         olivG34 = [Select TotalPrice from OpportunityLineItem where id =: olivG34.Id];
        Test.setMock(HttpCalloutMock.class, new DclHttpCalloutMock());

        Test.startTest();
        thisOpp.StageName = 'Orders Processing';
        thisOpp.Shipping_Method__c = '3 Day Select';
        thisOpp.Unique_Shipping_Addresses__c = 1;
        thisOpp.Configuration_Segment__c = 'Express';
        thisOpp.Probability = 50;
            
        update thisOpp;
        Test.stopTest();
        

        thisOpp = [SELECT Id, Express_Selected_Discount__c, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE id =: thisOpp.Id];
        system.assertEquals('DCL', thisOpp.Ship_From_Location__c);
        system.assertEquals('UPS', thisOpp.Shipping_Carrier__c);
        
        
                   
    }
    
       //Creating new Opportunity product to test of_Accessories__c & of_Serialized_Products__c
    public static OpportunityLineItem createOppProduct(Id opportunityId, Id addedProductId, Boolean isAccessory, String productCode, Id pbeId) {
        OpportunityLineItem testOpportunityProduct = new OpportunityLineItem();
        testOpportunityProduct.OpportunityId = opportunityId;
        testOpportunityProduct.Product2Id = addedProductId;
        testOpportunityProduct.UnitPrice = 1;
        testOpportunityProduct.Quantity = 4;
        testOpportunityProduct.Is_Accessory__c = isAccessory;
        testOpportunityProduct.Product_Code_Copy__c = productCode;
        testOpportunityProduct.PricebookEntryId = pbeId;
        return testOpportunityProduct;
    }
}