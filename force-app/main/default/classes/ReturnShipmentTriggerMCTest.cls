@isTest
private class ReturnShipmentTriggerMCTest {
    @testSetup
    private static void avalaraSetup() {
        
    }
    
    static testMethod void testReturnOppty() {
        
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;

        Contact c = new Contact(AccountId = a.Id, LastName='Test', Email='test@test.test');
        insert c;

        List<Opportunity> opptyToInsert = new List<Opportunity>();
        // create rev oppty
        Opportunity rev = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate');            
        opptyToInsert.add(rev);
        
        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Trial' LIMIT 1];
        
        // create trial
        Opportunity trial = new Opportunity(AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
            Probability = 0, StageName = 'Incubate', type = 'Free Trial Opportunity');
        setShipping(trial, c);
        opptyToInsert.add(trial);

        // Create return oppty
        Opportunity ret = new Opportunity(AccountId = a.Id, Name = 'Return', CloseDate = System.today() + 90,
            StageName = 'Return Created', Probability = 10, type = 'Free Trial Return');            
        opptyToInsert.add(ret);

        insert opptyToInsert;
       
        // ship trial
        trial.Trial_Agreement_Accepted__c = true;
        trial.Probability = 100;
        trial.StageName = 'Closed Won';
        trial.TrialResolutionOppty__c = rev.Id;
       // update trial;

        Test.startTest();
 
        // make rev oppty closed-lost
        setShipping(rev, c);
        rev.StageName = 'Closed Lost';
        rev.Probability = 0;
        
        //New UPS Multi-carrier package
        zkmulti__MCShipment__c shipment = new zkmulti__MCShipment__c();
        shipment.Opportunity__c = ret.Id;
        shipment.zkmulti__Tracker_Id__c = '1z1w7w420374732280';
        
        insert shipment;
        Test.stopTest();
        
    }
    
    static testMethod void testRevenueOppty() {
        
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;

        Contact c = new Contact(AccountId = a.Id, LastName='Test', Email='test@test.test');
        insert c;

        // create rev oppty
        Opportunity rev = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate',Type = 'Remorse Refund');            
        insert rev;
        
        //New UPS Multi-carrier package
        zkmulti__MCShipment__c shipment = new zkmulti__MCShipment__c();
        shipment.Opportunity__c = rev.Id;
        shipment.zkmulti__Tracker_Id__c = '1z1w7w420374732280';
        
        insert shipment;
        
        //GTMS-6069
        ReturnShipmentTriggerHandler.ExecuteBlock=false;
        
        //New UPS Multi-carrier package
        zkmulti__MCShipment__c shipment1 = new zkmulti__MCShipment__c();
        shipment1.Opportunity__c = rev.Id;
        shipment1.zkmulti__Tracker_Id__c = '1z1w7w420374732280';
        insert shipment1;
    }
    
    static testMethod void testTrialOppty() {
        
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;

        Contact c = new Contact(AccountId = a.Id, LastName='Test', Email='test@test.test');
        insert c;

        // create rev oppty
        Opportunity rev = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate');            
        insert rev;

        
        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Trial' LIMIT 1];
        
        // create trial
        Opportunity trial = new Opportunity(AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
            Probability = 0, StageName = 'Incubate', type = 'Free Trial Opportunity');
        setShipping(trial, c);
        insert trial;

        
        // Associate trial with revenue oppty
        trial.TrialResolutionOppty__c = rev.Id;
        update trial;
        //New UPS Multi-carrier package
        zkmulti__MCShipment__c shipment = new zkmulti__MCShipment__c();
        shipment.Opportunity__c = trial.Id;
        shipment.zkmulti__Tracker_Id__c = '1z1w7w420374732280';
        
        insert shipment;
        
        System.assertEquals(Null, [SELECT Tracking_Number__c FROM Opportunity WHERE Id = :trial.Id LIMIT 1].Tracking_Number__c);
    }
    
    static private void addOpptyProducts(Opportunity o) {
      
        Product2 prod = new Product2(Name = 'Laptop X200', Family = 'Hardware');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;

        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=o.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;
     }
     
    static private void setShipping(Opportunity o, Contact c) {
        o.Shipping_Contact__c = c.Id;
       
        o.Shipping_Address_Line_1__c = 'x';
        o.Shipping_City__c = 'x';
        o.Shipping_State__c = 'x'; 
        o.Shipping_Zip_Code__c = 'x';
        o.Shipping_Country__c = 'Canada';     
    }
    
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
    
}