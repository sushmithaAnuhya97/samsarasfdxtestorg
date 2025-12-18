@isTest
public class BatchCreateTrialReturnTest {
    @testSetup 
    public static void dataSetup() {
        
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        
        // Get pricebook entries to use later
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
        PricebookEntry ag45 = getPricebookEntry(pricebookId, 'LIC-AG45');
        
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        insert accountOne;
        Contact contactOne = (Contact)TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        insert contactOne;
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
        insert sa;
        Opportunity opportunityOne = new Opportunity(AccountId = accountOne.Id, 
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 505000,
                                                      Send_Invoice__c = true,
                                                      Related_Contact__c = contactOne.Id,
                                                      CloseDate = system.today()-100,
                                                      Deactivation_Date__c = system.today()+1,
                                                      Deactivate__c = true,
                                                      Shipping_Address_NEW__c = sa.Id
                                                    );
        insert opportunityOne;
        Map<String, OpportunityLineItem> items = new Map<String, OpportunityLineItem>();
        OpportunityLineItem ol = new OpportunityLineItem(Quantity=10, OpportunityId=opportunityOne.Id, PriceBookEntryId=vg33.Id, UnitPrice = vg33.UnitPrice, Original_List_Rate__c = 1000, Original_Quantity__c = 10);
        items.put('revVg33', ol);
        ol = new OpportunityLineItem(Quantity=13, OpportunityId=opportunityOne.Id, PriceBookEntryId=vg33.Id, UnitPrice = vg33.UnitPrice, Original_List_Rate__c = 1000, Original_Quantity__c = 10);
        items.put('rev1Vg33', ol);
        insert items.values();
        
    }
    
    static private PricebookEntry getPricebookEntry(Id pricebookId, String productCode){
        PricebookEntry entry = [Select Id, UnitPrice, Pricebook2Id, ProductCode from PricebookEntry where ProductCode = :productCode and Pricebook2Id = :pricebookId LIMIT 1];
        return entry;
    }
    
    static private void addProducts(Id pricebookId){
        
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'LIC-VG33', ProductCode = 'LIC-VG33', Family = 'Test');
        products.add(vg33);
        Product2 ag45 = new Product2(Name= 'LIC-AG45', ProductCode = 'LIC-AG45', Family = 'Test');
        products.add(ag45);
        insert products;
        
        
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        PricebookEntry ag45PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = ag45.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(ag45PB);
        insert pricebookEntries;
        
    }
    
    @isTest
    public static void testMethod1() {
        Test.startTest();
        BatchCreateTrialReturn b = new BatchCreateTrialReturn();
        database.executebatch(b,200);
        Test.stopTest();
        BatchCreateTrialReturn sc = new BatchCreateTrialReturn();   
         String chron = '0 0 23 * * ?';        
         system.schedule('Test Sched', chron, sc);
    }
}