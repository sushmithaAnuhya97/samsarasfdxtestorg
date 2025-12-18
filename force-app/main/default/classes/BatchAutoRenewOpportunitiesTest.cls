@isTest
public class BatchAutoRenewOpportunitiesTest {
	@testSetup 
    public static void dataSetup() {
        // add products to Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        
        // Get pricebook entries to use later
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
        PricebookEntry ag45 = getPricebookEntry(pricebookId, 'LIC-AG45');
        
        Account accountOne = new Account(
            Name                  = 'Testers 1 Inc',
            BillingCountry        = 'United Kingdom',
            Organization_Size__c  = '100 - 499',
            Industry              = 'Other',
            Renewal_AE__c         = '0051a000002kBFS',
            OwnerId               = [SELECT Id FROM User WHERE IsActive = true AND UserRole.DeveloperName LIKE '%AE1%' LIMIT 1].Id,
            Quarantine_Enabled__c = False
        );
    	insert accountOne;

        Contact contactOne = (Contact)TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        insert contactOne;

        Contract contract = new Contract(
            AccountId = accountOne.Id,
            StartDate = Date.today(),
            ContractTerm = 12,
            EndDate = Date.today().addDays(365)
        );
        insert contract;

        Shipping_Address__c sa = new Shipping_Address__c(
            Shipping_Zip_Code__c       = '94105',
            Shipping_Contact__c        = contactOne.Id,
            Shipping_Address_Line_1__c = '1 Dolores, Dallas',
            Shipping_City__c           = 'Dallas',
            Shipping_Country__c        = 'United States',
            Shipping_State__c          = 'Texas',
            Name                       = 'Test',
            Account__c                 = accountOne.Id
        );
        insert sa;

        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity rev = new Opportunity(
            AccountId                = accountOne.Id, 
            Name                     = 'Opp Testers 1 Inc',
            StageName                = 'Decision',
            RecordTypeId             = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId(),
            Shipping_Contact__c      = contactOne.Id, 
            Type                     = 'Revenue Opportunity',
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c       = 'Standard',
            Amount                   = 505000,
            Renewal__c               = true,
            CloseDate                = system.today(),
            OwnerId                  = '0051a000002k4I5',
            SBQQ__RenewedContract__c = contract.Id,
            Original_License_Term__c = 36,
            Configuration_Segment__c = 'Express'
        );
        oppList.add(rev);
        
        Opportunity originalRev = new Opportunity(
            AccountId                = accountOne.Id, 
            Name                     = 'Opp Testers 1 Inc',
            StageName                = 'Decision',
            RecordTypeId             = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId(),
            Shipping_Contact__c      = contactOne.Id, 
            Type                     = 'Revenue Opportunity',
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c       = 'Standard',
            Amount                   = 505000,
            Renewal__c               = true,
            Send_Invoice__c          = false,
            Related_Contact__c       = contactOne.Id,
            CloseDate                = system.today(),
            OwnerId                  = '0051a000002k4I5',
            Original_License_Term__c = 36
        );
        oppList.add(originalRev);
        insert oppList;

        oppList[0].Configuration_Segment__c = 'Express';
        update oppList[0];
        
        contract.Original_Contracted_Opportunity__c = originalRev.Id;
        update contract;
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
        Opportunity opp = [select Id from Opportunity where Name = 'Opp Testers 1 Inc' limit 1];
        BatchAutoRenewOpportunities b = new BatchAutoRenewOpportunities();
        database.executebatch(b,1);
        Test.stopTest();
        BatchAutoRenewOpportunities sc = new BatchAutoRenewOpportunities();   
        String chron = '0 0 23 * * ?';        
        system.schedule('Test Sched', chron, sc);
        
    }

    @isTest
    public static void testExecution(){
        Test.startTest();
        Database.executeBatch(new BatchAutoRenewOpportunities(), 10);
        Test.stopTest();
        
        Opportunity processedOpp = [
            SELECT Id,CloseDate, Name, Renewal__c, ContractId, SBQQ__RenewedContract__r.Original_Contracted_Opportunity__c, 
            Payment_Terms__c, Selected_Payment_Type__c, Original_License_Term__c, Shipping_Contact__c, PO_Number__c, SBQQ__PrimaryQuote__c
            FROM Opportunity
            WHERE Configuration_Segment__c = 'Express'
            LIMIT 1
        ];

        //System.assert(processedOpp.Name.startsWith('Evergreen -'));
    }

    @isTest
    public static void testExecution_fireError(){
        Opportunity processedOpp = [
            SELECT Id,CloseDate, Name, Renewal__c, ContractId, SBQQ__RenewedContract__r.Original_Contracted_Opportunity__c, 
            Payment_Terms__c, Selected_Payment_Type__c, Original_License_Term__c, Shipping_Contact__c, PO_Number__c, SBQQ__PrimaryQuote__c
            FROM Opportunity
            WHERE Configuration_Segment__c = 'Express'
            LIMIT 1
        ];

        // Forcing for the next update to this record to throw an error.
        Test.setCreatedDate(processedOpp.Id, System.now().addDays(30));

        Test.startTest();
        Database.executeBatch(new BatchAutoRenewOpportunities(), 10);
        Test.stopTest();
        
        processedOpp = [
            SELECT Id, Name
            FROM Opportunity
            WHERE Configuration_Segment__c = 'Express'
            LIMIT 1
        ];

        System.assert(!(processedOpp.Name.startsWith('Evergreen -')));
        System.assertEquals(1, [SELECT COUNT() FROM Log__c WHERE ClassName__c = 'BatchAutoRenewOpportunities']);
    }
}