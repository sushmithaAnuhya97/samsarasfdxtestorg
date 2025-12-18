@isTest
public class OrderAutomationServiceTest {
    
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
    public static void getProductCodesByCountryAndTypeTest() {
        
        OrderAutomationService.getProductCodesByCountryAndType('United States', 'Revenue Opportunity');
        OrderAutomationService.getProductCodesByCountryAndType('Canada', 'Revenue Opportunity');
        OrderAutomationService.getProductCodesByCountryAndType('Mexico', 'Revenue Opportunity');
        OrderAutomationService.getProductCodesByCountryAndType('United Kingdom', 'Revenue Opportunity');
        
        OrderAutomationService.getProductCodesByCountryAndType('United States', 'Free Trial Opportunity');
        OrderAutomationService.getProductCodesByCountryAndType('Canada', 'Free Trial Opportunity');
        OrderAutomationService.getProductCodesByCountryAndType('Mexico', 'Free Trial Opportunity');
        OrderAutomationService.getProductCodesByCountryAndType('United Kingdom', 'Free Trial Opportunity');
        
        OrderAutomationService.getProductCodesByCountryAndType('United States', 'Promo Opportunity');
        OrderAutomationService.getProductCodesByCountryAndType('Canada', 'Promo Opportunity');
        OrderAutomationService.getProductCodesByCountryAndType('Mexico', 'Promo Opportunity');
        OrderAutomationService.getProductCodesByCountryAndType('United Kingdom', 'Promo Opportunity');
    }
    
    @isTest
    public static void validatePoBoxTest() {
        
        Opportunity opp = [Select Id, Shipping_Country__c, Concatenated_Shipping_Address__c From Opportunity limit 1];
        OrderAutomationService.validatePoBox(opp);
    }
    
    @isTest
    public static void satisfyShipFromLocationTest() {
        
        Opportunity opp = [Select Id, Shipping_Country__c, Ship_From_Location__c From Opportunity limit 1];
        OrderAutomationService.satisfyShipFromLocation(opp);
    }
    
    @isTest
    public static void satisfyRevenueOwnerSegmentConditionsTest() {
        
        Opportunity opp = [Select Id, Shipping_Country__c, Ship_From_Location__c, Owner_Segment__c, Segment_Sales_Role__c,
                           name, Free_Trial_Purchase__c, CurrencyIsoCode, Amount From Opportunity limit 1];
        OrderAutomationService.satisfyRevenueOwnerSegmentConditions(opp);
    }
    
    @isTest
    public static void satisfyRevenueAE1ConditionsTest() {
        
        Opportunity opp = [Select Id, Shipping_Country__c, Ship_From_Location__c, Owner_Segment__c, Segment_Sales_Role__c,
                           name, Free_Trial_Purchase__c, CurrencyIsoCode, Amount From Opportunity limit 1];
        OrderAutomationService.satisfyRevenueAE1Conditions(opp);
    }
    
    @isTest
    public static void satisfyRevenueAe2Ae3EntConditionsTest() {
        
        Opportunity opp = [Select Id, Shipping_Country__c, Ship_From_Location__c, Owner_Segment__c, Segment_Sales_Role__c,
                           name, Free_Trial_Purchase__c, CurrencyIsoCode, Amount From Opportunity limit 1];
        OrderAutomationService.satisfyRevenueAe2Ae3EntConditions(opp);
    }
    
    @isTest
    public static void satisfyCurrencyISOCodeTest() {
        
        Opportunity opp = [Select Id, Shipping_Country__c, Ship_From_Location__c, Owner_Segment__c, Segment_Sales_Role__c,
                           name, Free_Trial_Purchase__c, CurrencyIsoCode, Amount From Opportunity limit 1];
        opp.Shipping_Country__c = 'United States';
        opp.CurrencyIsoCode = 'USD';
        OrderAutomationService.satisfyCurrencyISOCode(opp);
        
        opp.Shipping_Country__c = 'Canada';
        opp.CurrencyIsoCode = 'CAD';
        OrderAutomationService.satisfyCurrencyISOCode(opp);
        
        opp.Shipping_Country__c = 'Mexico';
        opp.CurrencyIsoCode = 'MXN';
        OrderAutomationService.satisfyCurrencyISOCode(opp);
        
        opp.Shipping_Country__c = 'United Kingdom';
        opp.CurrencyIsoCode = 'EUR';
        OrderAutomationService.satisfyCurrencyISOCode(opp);
    }
    
}