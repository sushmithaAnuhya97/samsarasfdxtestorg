@isTest
public class OrderAutomationLoggingServiceTest {

    @testSetup
    public static void createData() {
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert new Global_Automation_Settings__c(Name = 'Automation_Settings',Allow_Handler_Selection__c = true);
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<OpportunityLineItem> newOpportunityLineItems = new List<OpportunityLineItem>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<Shipping_Address__c> newShipAdd = new List<Shipping_Address__c>();
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Product2> products = new List<Product2>();
        Product2 accProd = new Product2(Name= 'ACC-2A12-W1', ProductCode = 'ACC-2A12-W1', Family = 'Test');
        products.add(accProd);
        insert products;
        
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry accPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = accProd.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(accPB);
        insert pricebookEntries;
        
        Account usAcc = new Account(Name = 'Testers 1 Inc',
                                    BillingStreet = '26 Napier Street',
                                    BillingCity = 'Dallas',
                                    BillingState = 'Idaho',
                                    BillingPostalCode  = '1030',
                                    BillingCountry = 'United States',
                                    Billing_Email__c  = 'qdasdas@gmail.com',
                                    Organization_Size__c = '100 - 499',
                                    Industry = 'Other');
        
        newAccounts.add(usAcc);
        
        insert newAccounts;
        
        Contact usCon = (Contact) TestFactory.createSObject(new Contact(AccountId = usAcc.Id));
        newContacts.add(usCon);
        
        insert newContacts;
        
        Shipping_Address__c usShipAdd = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=usCon.Id, 
                                                                Shipping_Address_Line_1__c='1 Dolores, Dallas', 
                                                                Shipping_Country__c='United States', Shipping_City__c='Dallas', Shipping_State__c='Idaho', Name='US SA', Account__c = usAcc.Id);
        newShipAdd.add(usShipAdd);
        
        insert newShipAdd;
        
        Opportunity revUSOpp = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = usAcc.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'US Revenue Opportunity',
                                                      StageName = 'Proposal',
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Monthly',
                                                      Shipping_Address_NEW__c = usShipAdd.Id,
                                                      Probability = 0.95,
                                                      Owner_Role_Copy__c = 'AE2'));
        newOpportunities.add(revUsOpp);
        
        insert newOpportunities;
        
        OpportunityLineItem li1 = new OpportunityLineItem (Quantity=1, OpportunityId=revUSOpp.Id, PriceBookEntryId=accPB.Id, UnitPrice = 10000);
        newOpportunityLineItems.add(li1);
        
        insert newOpportunityLineItems;
    }
    
    @isTest
    public static void evaluateRevenueUSAutomationErrorsTest() {
        
        List<Opportunity> newOppList = new List<Opportunity>();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        
        Opportunity oldOpp = [Select Id, name, stagename, type, sub_Type__c, Amount, Shipping_Country__c, Shipping_Method__c,
                              CurrencyIsoCode, Free_Trial_Purchase__c, Ship_From_Location__c,
                              Owner_Segment__c, Segment_Sales_Role__c, Sales_Tax__c, Balance_Due__c, Shipping_and_Handling__c, 
                              Shipping_and_Handling_Manual__c, Shipping_and_Handling_Amount__c, Multi_Line_Shipping__c, 
                              Order_Ops_Notes__c, Shipping_Address_NEW__c, Shipping_Instructions__c,
                              Internal_RFO_Notes__c, Hold_Reason__c, Price_Book_Name__c, Concatenated_Shipping_Address__c,
                              (Select Id, ProductCode, quantity, Ship_To_Country__c, Product2.Product_Type__c from OpportunityLineItems) 
                              From Opportunity 
                              Where Name = 'US Revenue Opportunity' LIMIT 1];
        
        oldOppMap.put(oldOpp.Id, oldOpp);
        
        OpportunityHelperContext.oppFields = oldOppMap;
        
        Opportunity newOpp = oldOpp.clone(true, true, false, false);
        newOpp.stageName = 'Orders Processing';
        newOpp.Free_Trial_Purchase__c = 'No Purchase';
        newOpp.Hold_Reason__c = 'Out of Stock';
        newOpp.Shipping_Instructions__c = 'Test';
        newOpp.Internal_RFO_Notes__c = 'Test';
        newOpp.Ship_From_Location__c = 'DCL';
        newOpp.Order_Ops_Notes__c = 'Test';
        newOpp.Sub_Type__c = 'Virtual Return';
        newOpp.Shipping_Method__c = 'Next Day Air';
        newOpp.amount = 1000000;
        newOppList.add(newOpp);
        
        OrderAutomationLoggingService.evaluateAutomationErrors(newOppList, oldOppMap);        
        
    }
    
    @isTest
    public static void evaluateRevenueMexicoAutomationErrorsTest() {
        
        List<Opportunity> newOppList = new List<Opportunity>();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        
        Opportunity oldOpp = [Select Id, name, stagename, type, sub_Type__c, Amount, Shipping_Country__c, Shipping_Method__c,
                              CurrencyIsoCode, Free_Trial_Purchase__c, Ship_From_Location__c,
                              Owner_Segment__c, Segment_Sales_Role__c, Sales_Tax__c, Balance_Due__c, Shipping_and_Handling__c, 
                              Shipping_and_Handling_Manual__c, Shipping_and_Handling_Amount__c, Multi_Line_Shipping__c, 
                              Order_Ops_Notes__c, Shipping_Address_NEW__c, Shipping_Instructions__c,
                              Internal_RFO_Notes__c, Hold_Reason__c, Price_Book_Name__c, Concatenated_Shipping_Address__c,
                              (Select Id, ProductCode, quantity, Ship_To_Country__c, Product2.Product_Type__c from OpportunityLineItems) 
                              From Opportunity 
                              Where Name = 'US Revenue Opportunity' LIMIT 1];
        
        oldOppMap.put(oldOpp.Id, oldOpp);
        
        OpportunityHelperContext.oppFields = oldOppMap;
        
        Opportunity newOpp = oldOpp.clone(true, true, false, false);
         newOpp.stageName = 'Orders Processing';
        newOpp.Free_Trial_Purchase__c = 'No Purchase';
        newOpp.Shipping_Country__c = 'Mexico';
        newOpp.CurrencyIsoCode = 'MXN';
        newOpp.Ship_From_Location__c = 'Estafeta';
        newOpp.amount = 3000000;
        newOppList.add(newOpp);
        
        OrderAutomationLoggingService.evaluateAutomationErrors(newOppList, oldOppMap);        
        
    }
    
    @isTest
    public static void evaluateRevenueEmeaAutomationErrorsTest() {
        
        List<Opportunity> newOppList = new List<Opportunity>();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        
        Opportunity oldOpp = [Select Id, name, stagename, type, sub_Type__c, Amount, Shipping_Country__c, Shipping_Method__c,
                              CurrencyIsoCode, Free_Trial_Purchase__c, Ship_From_Location__c,
                              Owner_Segment__c, Segment_Sales_Role__c, Sales_Tax__c, Balance_Due__c, Shipping_and_Handling__c, 
                              Shipping_and_Handling_Manual__c, Shipping_and_Handling_Amount__c, Multi_Line_Shipping__c, 
                              Order_Ops_Notes__c, Shipping_Address_NEW__c, Shipping_Instructions__c,
                              Internal_RFO_Notes__c, Hold_Reason__c, Price_Book_Name__c, Concatenated_Shipping_Address__c,
                              (Select Id, ProductCode, quantity, Ship_To_Country__c, Product2.Product_Type__c from OpportunityLineItems) 
                              From Opportunity 
                              Where Name = 'US Revenue Opportunity' LIMIT 1];
        
        oldOppMap.put(oldOpp.Id, oldOpp);
        
        OpportunityHelperContext.oppFields = oldOppMap;
        
        Opportunity newOpp = oldOpp.clone(true, true, false, false);
         newOpp.stageName = 'Orders Processing';
        newOpp.Free_Trial_Purchase__c = null;
        newOpp.Shipping_Country__c = 'United Kingdom';
        newOpp.CurrencyIsoCode = 'EUR';
        newOpp.Ship_From_Location__c = 'DCL';
        newOpp.Order_Ops_Notes__c = 'Test';
        newOpp.Sub_Type__c = 'Virtual Return';
        newOpp.Shipping_Method__c = 'Next Day Air';
        newOpp.amount = 1000000;
        newOppList.add(newOpp);
        
        OrderAutomationLoggingService.evaluateAutomationErrors(newOppList, oldOppMap);        
        
    }
    
    @isTest
    public static void evaluateFreeTrialAutomationErrorsTest() {
        
        List<Opportunity> newOppList = new List<Opportunity>();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        
        Opportunity oldOpp = [Select Id, name, stagename, type, sub_Type__c, Amount, Shipping_Country__c, Shipping_Method__c,
                              CurrencyIsoCode, Free_Trial_Purchase__c, Ship_From_Location__c,
                              Owner_Segment__c, Segment_Sales_Role__c, Sales_Tax__c, Balance_Due__c, Shipping_and_Handling__c, 
                              Shipping_and_Handling_Manual__c, Shipping_and_Handling_Amount__c, Multi_Line_Shipping__c, 
                              Order_Ops_Notes__c, Shipping_Address_NEW__c, Shipping_Instructions__c,
                              Internal_RFO_Notes__c, Hold_Reason__c, Price_Book_Name__c, Concatenated_Shipping_Address__c,
                              (Select Id, ProductCode, quantity, Ship_To_Country__c, Product2.Product_Type__c from OpportunityLineItems) 
                              From Opportunity 
                              Where Name = 'US Revenue Opportunity' LIMIT 1];
        
        oldOppMap.put(oldOpp.Id, oldOpp);
        
        OpportunityHelperContext.oppFields = oldOppMap;
        
        Opportunity newOpp = oldOpp.clone(true, true, false, false);
        newOpp.stageName = 'Orders Processing';
        newOpp.type = 'Free Trial Opportunity';
        newOpp.Free_Trial_Purchase__c = 'No Purchase';
        newOpp.Ship_From_Location__c = 'DCL-LA';
        newOpp.Order_Ops_Notes__c = 'Test';
        newOppList.add(newOpp);
        
        OrderAutomationLoggingService.evaluateAutomationErrors(newOppList, oldOppMap);        
        
    }
    
    @isTest
    public static void evaluatePromoAutomationErrorsTest() {
        
        List<Opportunity> newOppList = new List<Opportunity>();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        
        Opportunity oldOpp = [Select Id, name, stagename, type, sub_Type__c, Amount, Shipping_Country__c, Shipping_Method__c,
                              CurrencyIsoCode, Free_Trial_Purchase__c, Ship_From_Location__c,
                              Owner_Segment__c, Segment_Sales_Role__c, Sales_Tax__c, Balance_Due__c, Shipping_and_Handling__c, 
                              Shipping_and_Handling_Manual__c, Shipping_and_Handling_Amount__c, Multi_Line_Shipping__c, 
                              Order_Ops_Notes__c, Shipping_Address_NEW__c, Shipping_Instructions__c,
                              Internal_RFO_Notes__c, Hold_Reason__c, Price_Book_Name__c, Concatenated_Shipping_Address__c,
                              (Select Id, ProductCode, quantity, Ship_To_Country__c, Product2.Product_Type__c from OpportunityLineItems) 
                              From Opportunity 
                              Where Name = 'US Revenue Opportunity' LIMIT 1];
        
        oldOppMap.put(oldOpp.Id, oldOpp);
        
        OpportunityHelperContext.oppFields = oldOppMap;
        
        Opportunity newOpp = oldOpp.clone(true, true, false, false);
        newOpp.stageName = 'Orders Processing';
        newOpp.type = 'Promo Opportunity';
        newOppList.add(newOpp);
        
        OrderAutomationLoggingService.evaluateAutomationErrors(newOppList, oldOppMap);        
        
    }
}