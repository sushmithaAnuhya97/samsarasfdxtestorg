@isTest
public class Customer360StagingTriggerHandlerTest {

    @TestSetup
    static void makeData(){
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('Active_Growth_Campaigns_Count');
        acc.Book_Of_Business__c = 'Core';

        TriggerHandler.bypass('GS_AccountTriggerHandler');
        
        insert acc;
        
        TriggerHandler.clearAllBypasses();
        
        insert new Customer_360__c(Account__c = acc.Id, SOT__c = true, LIC_CRGO_Discount__c = 12);
        insert new Customer_360_Staging__c(Account__c = acc.Id, LIC_CRGO_Discount__c = 5);
    }

    @isTest static void C360StagingApprovedTest1(){

        Customer_360_Staging__c c360StagingRec = [SELECT Id, Account__c, LIC_CRGO_Discount__c FROM Customer_360_Staging__c LIMIT 1];

        c360StagingRec.Approved__c = true;

        update c360StagingRec;

        List<Customer_360__c> c360ListRetrieved = [SELECT Id, SOT__c, LIC_CRGO_Discount__c FROM Customer_360__c WHERE Account__c = :c360StagingRec.Account__c];

        Assert.areEqual(1, c360ListRetrieved.size(), 'There should Only be 1 Customer 360 record to be processed');
        
        Customer_360__c c360Rec = c360ListRetrieved[0];

        Assert.areEqual(c360StagingRec.LIC_CRGO_Discount__c, c360Rec.LIC_CRGO_Discount__c, 'Discount for LIC_CRGO_Discount__c must be copied from C360 Staging');
        Assert.isTrue(c360Rec.SOT__c, 'There should Only be 1 Customer 360 record to be processed');
    }
}