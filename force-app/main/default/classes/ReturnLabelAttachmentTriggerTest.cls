@isTest
private class ReturnLabelAttachmentTriggerTest {
    
    /*@isTest
    private static void testReturnLabelBatch() {
        
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;

        Contact c = new Contact (email='test@test.test', LastName='test', AccountId = a.Id);
        insert c;

        Product2 prod = new Product2(Name = 'Laptop X200', Family = 'Hardware');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;

        List<Opportunity> opptyToInsert = new List<Opportunity>();

        // create rev oppty
        Opportunity rev = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate');            
        opptyToInsert.add(rev);
        
        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Trial' LIMIT 1];
        
        // create trial
        Opportunity trial = new Opportunity(AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
            Probability = 0, StageName = 'Incubate', type = 'Revenue Opportunity');
        setShipping(trial, c);
        opptyToInsert.add(trial);

        // Create return oppty
        Opportunity ret = new Opportunity(AccountId = a.Id, Name = 'Return', CloseDate = System.today() + 90,
            StageName = 'Return Created', Probability = 10, type = 'Free Trial Return');            
        opptyToInsert.add(ret);

        insert opptyToInsert;
        

        // ship trial
        List<Opportunity> updateList = new List<Opportunity>();
        trial.Trial_Agreement_Accepted__c = true;
        trial.Probability = 100;
        trial.StageName = 'Closed Won';
        trial.TrialResolutionOppty__c = rev.Id;
        updateList.add(trial);
 
        // make rev oppty closed-lost
        setShipping(rev, c);
        rev.StageName = 'Closed Lost';
        rev.Probability = 0;
        rev.Closed_Lost_Reason__c = 'Test Lost Reason';
        updateList.add(rev);

        update updateList;  

        //Alekya
 		Test.startTest();
        // Assign return to trial
        trial.TrialResolutionOppty__c = ret.Id;
        update trial;
        
        zkmulti__MCShipment__c  shipment = new zkmulti__MCShipment__c();
        shipment.zkmulti__Tracking_Number__c = '1z1w7w420374732280';
        shipment.Opportunity__c = ret.Id;
        insert shipment;

        List<Attachment> attachmentList = new List<Attachment>();

        Attachment attach=new Attachment();    
        attach.Name='ReturnLabel-01.PDF';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=shipment.id;
        attachmentList.add(attach);

        Attachment attach2=new Attachment();    
        attach2.Name='International-Forms.PDF';
        Blob bodyBlob2=Blob.valueOf('Unit Test Attachment Body');
        attach2.body=bodyBlob2;
        attach2.parentId=shipment.id;
        attachmentList.add(attach2);

        insert attachmentList;
        
        Test.stopTest();

        System.assertEquals(attach.Id+','+attach2.Id, [SELECT Return_Label_Attachment__c FROM Opportunity WHERE Id = :ret.Id LIMIT 1].Return_Label_Attachment__c);
        
    }*/

    @isTest
    private static void testReturnLabelSingularRecord() {
        
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;

        Contact c = new Contact (email='test@test.test', LastName='test', AccountId = a.Id);
        insert c;

        Product2 prod = new Product2(Name = 'Laptop X200', Family = 'Hardware');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;

        List<Opportunity> opptyToInsert = new List<Opportunity>();

        // create rev oppty
        Opportunity rev = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate');            
        opptyToInsert.add(rev);
        
        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Trial' LIMIT 1];
        
        // create trial
        Opportunity trial = new Opportunity(AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
            Probability = 0, StageName = 'Incubate', type = 'Revenue Opportunity');
        setShipping(trial, c);
        opptyToInsert.add(trial);

        // Create return oppty
        Opportunity ret = new Opportunity(AccountId = a.Id, Name = 'Return', CloseDate = System.today() + 90,
            StageName = 'Return Created', Probability = 10, type = 'Free Trial Return');            
        opptyToInsert.add(ret);

        insert opptyToInsert;
 
        // ship trial
        List<Opportunity> updateList = new List<Opportunity>();
        trial.Trial_Agreement_Accepted__c = true;
        trial.Probability = 100;
        trial.StageName = 'Closed Won';
        trial.TrialResolutionOppty__c = rev.Id;
        updateList.add(trial);
 
        // make rev oppty closed-lost
        setShipping(rev, c);
        rev.StageName = 'Closed Lost';
        rev.Closed_Lost_Reason__c = 'Test Lost Reason';
        rev.Probability = 0;
        updateList.add(rev);

        update updateList;      

        Test.startTest();
        
        // Assign return to trial
        trial.TrialResolutionOppty__c = ret.Id;
        update trial;
        
        zkmulti__MCShipment__c  shipment = new zkmulti__MCShipment__c();

        shipment.zkmulti__Tracking_Number__c = '1z1w7w420374732280';
        shipment.Opportunity__c = ret.Id;
        insert shipment;

        Attachment attach=new Attachment();    
        attach.Name='ReturnLabel-01.PDF';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=shipment.id;
        insert attach;

        Attachment attach2=new Attachment();    
        attach2.Name='International-Forms.PDF';
        Blob bodyBlob2=Blob.valueOf('Unit Test Attachment Body');
        attach2.body=bodyBlob2;
        attach2.parentId=shipment.id;
        insert attach2;


        Test.stopTest();

        System.assertEquals(attach.Id+','+attach2.Id, [SELECT Return_Label_Attachment__c FROM Opportunity WHERE Id = :ret.Id LIMIT 1].Return_Label_Attachment__c);
        
    }
 
    private static void setShipping(Opportunity o, Contact c) {
        o.Shipping_Contact__c = c.Id;
       
        o.Shipping_Address_Line_1__c = 'x';
        o.Shipping_City__c = 'x';
        o.Shipping_State__c = 'x'; 
        o.Shipping_Zip_Code__c = 'x';
        o.Shipping_Country__c = 'Canada';     
    }    
}