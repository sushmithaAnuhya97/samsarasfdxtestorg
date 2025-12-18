@isTest
public class OpportunityContractDeleteStageTest {

    static Account createAccount() {
        Account account = new Account();
        account.Name = 'MyTestAccount';
        account.Type = 'Fleet';
        account.Industry = 'Other';
        account.organization_size__c = '1 - 99';
        account.billingstreet = '123 Main St, San Francisco CA, 94110';
        account.billingstate = 'California';
        account.billingcountry = 'United States';
        account.billingcity = 'San Francisco';
        account.billingPostalCode = '94110';
        account.shippingstreet = '123 Main St, San Francisco CA, 94110';
        account.shippingstate = 'California';
        account.shippingcountry = 'United States';
        account.shippingcity = 'San Francisco';
        account.shippingPostalCode = '94110';
        return account;
    }

    static void satisfyAvalara() {
        
    }

    @isTest
    static void testStageIsDeleted() {

        satisfyAvalara();

        Account acct = createAccount();
        insert acct;

        Opportunity opp = new Opportunity();
        opp.CloseDate = Date.today();
        opp.License_End_Date__c = Date.today();
        opp.Name = 'My Opp';
        opp.StageName = 'Closed Won';
        opp.AccountId = acct.Id;    
        insert opp;

        OpportunityContractAccount__c stage = new OpportunityContractAccount__c();
        stage.Account__c = acct.Id;
        insert stage;

        System.Test.startTest();
        Database.executeBatch(new OpportunityContractDeleteStage(),200);
        System.Test.stopTest();

        List<OpportunityContractAccount__c> stages = [select Id from OpportunityContractAccount__c where Id = :stage.Id];
        System.assertEquals(0, stages.size(), 'Stage was not deleted');
    }

    @isTest
    static void testReturnStageIsDeleted() {

        satisfyAvalara();

        Account acct = createAccount();
        insert acct;

        Opportunity opp = new Opportunity();
        opp.CloseDate = Date.today();
        opp.License_End_Date__c = Date.today();
        opp.Name = 'My Opp';
        opp.StageName = 'Closed Won';
        opp.AccountId = acct.Id;       
        insert opp;

        OpportunityContractReturnAccount__c stage = new OpportunityContractReturnAccount__c();
        stage.Account__c = acct.Id;
        insert stage;

        System.Test.startTest();
        Database.executeBatch(new OpportunityContractReturnDeleteStage(),200);
        System.Test.stopTest();

        List<OpportunityContractReturnAccount__c> stages = [select Id from OpportunityContractReturnAccount__c where Id = :stage.Id];
        System.assertEquals(0, stages.size(), 'Stage was not deleted');
    }

}