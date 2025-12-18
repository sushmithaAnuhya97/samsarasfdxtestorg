@isTest
public class OppAutoRenewalControllerTest {
    @TestSetup static void setupRecords() {
                        
        // add products to Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        
        // Get pricebook entries to use later
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
        PricebookEntry ag45 = getPricebookEntry(pricebookId, 'LIC-AG45');
        
        User user = [Select id from User where Id = :UserInfo.getUserId()];
        
        // Create account
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other');
        insert a;
        
        Contact c = new Contact (FirstName = 'Juan', LastName = 'Perez', Email = 'juan@a.com', AccountId=a.Id);
        insert c;
        
        Contract ctr = new Contract(AccountId = a.Id, StartDate = Date.today(), ContractTerm = 24, EndDate = Date.today() + 720);
        insert ctr;
    
        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Return Opportunity' LIMIT 1];
                      
        // Create Revenue Oppty
        Map<String, Opportunity> oppsInsert = new Map<String, Opportunity>(); 
        Opportunity originalRev = new Opportunity(Owner_Role_Copy__c = 'My Role', AccountId = a.Id, Name = 'originalRev', CloseDate = System.today() + 90, StageName = 'Closed Won', OwnerId = user.Id, Amount = 1000);    
        Opportunity rev = new Opportunity(Owner_Role_Copy__c = 'My Role', AccountId = a.Id, Name = 'rev', CloseDate = System.today() + 90, StageName = 'Incubate', OwnerId = user.Id, Amount = 1000, netsuite_conn__From_Contract__c  = ctr.Id, Renewal__c = true, Shipping_Contact__c = c.Id, Original_License_Term__c = 24);    
        
        oppsInsert.put('rev', rev);
        oppsInsert.put('originalRev', originalRev);
        Test.startTest();
            insert oppsInsert.values();
        Test.stopTest();
        ctr.Original_Contracted_Opportunity__c = originalRev.Id;
        update ctr;
        
        
        
        // Add Revenue Oppty products
        Map<String, OpportunityLineItem> items = new Map<String, OpportunityLineItem>();
        OpportunityLineItem ol = new OpportunityLineItem(Quantity=10, OpportunityId=rev.Id, PriceBookEntryId=vg33.Id, UnitPrice = vg33.UnitPrice, Original_List_Rate__c = 1000, Original_Quantity__c = 10);
        items.put('revVg33', ol);
        ol = new OpportunityLineItem(Quantity=13, OpportunityId=originalRev.Id, PriceBookEntryId=vg33.Id, UnitPrice = vg33.UnitPrice);
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
    @isTest static void testConvertToEvergreen() {
        Opportunity rev = [SELECT Id, Order_Number__c, AccountId, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'rev' LIMIT 1];
        ApexPages.StandardController stdController = new ApexPages.StandardController(rev);
        Test.startTest();
        OppAutoRenewalController ctrl = new OppAutoRenewalController(stdController);
        OppAutoRenewalController.convertToEverGreen();
        OppAutoRenewalController.updateEvergreen(rev.Id);
        Test.stopTest();
    }
}