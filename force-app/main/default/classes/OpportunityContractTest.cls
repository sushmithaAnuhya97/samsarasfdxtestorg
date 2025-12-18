@isTest
public with sharing class OpportunityContractTest {

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
        insert account;
        
        return account;
    }
    
    
    static void satisfyAvalara() {
        
    }
    
    @testSetup
    static void testRecords(){
        
        satisfyAvalara();
        OpportunityTriggerHandler.isEnabled = false;

        Account account = createAccount();

        OpportunityTriggerHandler.isEnabled = true;
        
        List<Contract> newContracts = new List<Contract>();

        Contract contractEarlierEndDate = new Contract();
        contractEarlierEndDate.AccountId = account.Id;
        contractEarlierEndDate.StartDate = Date.today();
        contractEarlierEndDate.ContractTerm = 1;
        contractEarlierEndDate.EndDate = Date.today() + 30;
        newContracts.add(contractEarlierEndDate);

        Contract contractMostInTheFuture = new Contract();
        contractMostInTheFuture.AccountId = account.Id;
        contractMostInTheFuture.StartDate = Date.today();
        contractMostInTheFuture.ContractTerm = 24;
        contractMostInTheFuture.EndDate = Date.today() + 720;
        newContracts.add(contractMostInTheFuture);

        insert newContracts;

    }

    @isTest
    static void testLicenseEndDateIsPopulatedWithMostRecentContractEndDateInTheSameAccountWhenAccountFirstPurchaseDateIsPopulated() {

        satisfyAvalara();
        Account account = [Select id from Account where Name='MyTestAccount'];
        Contract contractEarlierEndDate = [select EndDate from Contract where ContractTerm = 1];
        Contract contractMostInTheFuture = [select EndDate from Contract where ContractTerm = 24];
        
        System.assert(contractMostInTheFuture.EndDate > contractEarlierEndDate.EndDate
                , 'test data not accurate - most in the future: ' + formatDate(contractMostInTheFuture.EndDate) + ', earlier end date: ' + formatDate(contractEarlierEndDate.EndDate)
        );
		
        Test.startTest();
        Opportunity opp = new Opportunity();
        opp.CloseDate = Date.today();
        opp.Name = 'My Opp 1';
        opp.StageName = 'Qualified';
        opp.AccountId = account.Id;
        opp.Type = 'Revenue Opportunity';
        opp.Amount = 100;
        insert opp;
		Test.stopTest();
        
        opp = [select License_End_Date__c from Opportunity where Id = :opp.Id];
        System.assertEquals(contractMostInTheFuture.EndDate, opp.License_End_Date__c, 'License End Date was not populated with the most recent Contract End Date');
    }

    private static String formatDate(Date dt) {
        return ((Datetime)dt).format('MMM-dd-yyyy');
    }

}