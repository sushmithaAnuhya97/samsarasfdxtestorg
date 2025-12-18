//@Description : GTMS - 12367  -   Modify logic to account for negative lines
@isTest
public class Batch_UpdateContractRenewableACV_Test 
{
    @testSetup
    private static void testSetup()
    {
    }
    @isTest private static void testMethod001()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ContractAccount');
        insert acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert oppty;
        Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(100),
                ContractTerm = 12,Deactivated__c = true
        );
        insert contract;

        Product2 prod = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        insert prod;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pb;

        list<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = contract.id,
            SBQQ__Account__c = acc.id,
            SBQQ__Product__c = prod.id

        );
        subList.add(sub1);
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = -1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = contract.id,
            SBQQ__Account__c = acc.id,
            SBQQ__Product__c = prod.id

        );
        subList.add(sub2);
        SBQQ__Subscription__c sub3 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 10,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = contract.id,
            SBQQ__Account__c = acc.id,
            SBQQ__Product__c = prod.id

        );
        subList.add(sub3);
        insert subList;
        

        test.startTest();
        Database.executebatch((new Batch_UpdateContractRenewableACV()),5);
        test.stopTest();
        
        contract con1 = [SELECT id,Contract_Renewable_ACV__c FROM Contract limit 1];
        
    }
}