@isTest
public class Batch_ReturnOpptyDataFix_Test 
{
    @testSetup
    private static void testSetup()
    {
    }
    @isTest private static void testMethod001()
    {
        
        Account acc = new Account(Name = 'TestAccount',
                                  BillingState='California',
                                  BillingCountry = 'United States',
                                  Organization_Size__c = '100 - 499');
        insert acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Remorse Refund',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Refunded - Closed',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      CloseDate = Date.today().adddays(-1)));
        Insert oppty;
        
        Product2 prod = new Product2(Name= 'LIC-Test', ProductCode = 'LIC-Test', Family = 'Test');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pb;
        
        OpportunityLineItem ol = new OpportunityLineItem (OpportunityId=oppty.Id, Quantity=-1, PricebookEntryId=pb.Id, UnitPrice=pb.UnitPrice);
        Insert ol;
        
                  
        Contract contract = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(100),
            ContractTerm = 12);
        insert contract;       
        
        Opportunity retOppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      ContractId = contract.Id ));
        Insert retOppty;
        
        oppty.Returning_Opportunity__c = retOppty.Id;
        Update oppty;
        
        test.startTest();
        Batch_ReturnOpptyDataFix bc  = new Batch_ReturnOpptyDataFix();
        bc.execute(null);
        test.stopTest();
        
        
    }
    @isTest private static void testMethod002()
    {
        
        Account acc = new Account(Name = 'TestAccount',
                                  BillingState='California',
                                  BillingCountry = 'United States',
                                  Organization_Size__c = '100 - 499');
        insert acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Remorse Refund',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Refunded - Closed',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      CloseDate = Date.today().adddays(-1)));
        Insert oppty;
        
        Product2 prod = new Product2(Name= 'LIC-Test', ProductCode = 'LIC-Test', Family = 'Test');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pb;
        
        OpportunityLineItem ol = new OpportunityLineItem (OpportunityId=oppty.Id, Quantity=1, PricebookEntryId=pb.Id, UnitPrice=pb.UnitPrice);
        Insert ol;
        
        
        Contract contract = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(100),
            ContractTerm = 12);
        insert contract;
        Opportunity retOppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      SBQQ__AmendedContract__c = contract.Id ));
        Insert retOppty;
        
        oppty.Returning_Opportunity__c = retOppty.Id;
        Update oppty;
        
        test.startTest();
        Batch_ReturnOpptyDataFix bc  = new Batch_ReturnOpptyDataFix();
        bc.execute(null);
        test.stopTest();
        
        
    }
    @isTest private static void testMethod003()
    {
        
        Account acc = new Account(Name = 'TestAccount',
                                  BillingState='California',
                                  BillingCountry = 'United States',
                                  Organization_Size__c = '100 - 499');
        insert acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Remorse Refund',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Refunded - Closed',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      CloseDate = Date.today().adddays(-1)));
        Insert oppty;
        
        Product2 prod = new Product2(Name= 'LIC-Test', ProductCode = 'LIC-Test', Family = 'Test');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pb;
        
        OpportunityLineItem ol = new OpportunityLineItem (OpportunityId=oppty.Id, Quantity=1, PricebookEntryId=pb.Id, UnitPrice=pb.UnitPrice);
        Insert ol;
        
        Opportunity retOppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert retOppty;
        
        Contract contract1 = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(100),
            ContractTerm = 12,
            SBQQ__Opportunity__c = retOppty.Id);
        insert contract1;
        
        Contract contract2 = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(100),
            ContractTerm = 12,
            SBQQ__Opportunity__c = retOppty.Id);
        insert contract2;
        
        oppty.Returning_Opportunity__c = retOppty.Id;
        Update oppty;
        
        test.startTest();
        Batch_ReturnOpptyDataFix bc  = new Batch_ReturnOpptyDataFix();
        bc.execute(null);
        test.stopTest();
        
        
    }
    @isTest private static void testMethod004()
    {
        
        Account acc = new Account(Name = 'TestAccount',
                                  BillingState='California',
                                  BillingCountry = 'United States',
                                  Organization_Size__c = '100 - 499');
        insert acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Remorse Refund',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Refunded - Closed',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      CloseDate = Date.today().adddays(-1)));
        Insert oppty;
        
        Product2 prod = new Product2(Name= 'LIC-Test', ProductCode = 'LIC-Test', Family = 'Test');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pb;
        
        OpportunityLineItem ol = new OpportunityLineItem (OpportunityId=oppty.Id, Quantity=1, PricebookEntryId=pb.Id, UnitPrice=pb.UnitPrice);
        Insert ol;
        
        
        
        Opportunity retOppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert retOppty;
        
        oppty.Returning_Opportunity__c = retOppty.Id;
        Update oppty;
        
        test.startTest();
        Batch_ReturnOpptyDataFix bc  = new Batch_ReturnOpptyDataFix();
        bc.execute(null);
        test.stopTest();
        
        
    }
    @isTest private static void testMethod005()
    {
        test.startTest();
        Batch_ReturnOpptyDataFix bc  =new Batch_ReturnOpptyDataFix();
        bc.emailErrors('Test');
        test.stopTest();
    }
}