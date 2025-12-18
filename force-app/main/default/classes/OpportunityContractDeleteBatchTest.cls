@isTest
public class OpportunityContractDeleteBatchTest {

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

    @isTest
    static void testContractsAreDeleted() {

        Account account = createAccount();
        insert account;

        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        insert contract;

        System.Test.startTest();
        Database.executeBatch(new OpportunityContractDeleteBatch(),200);
        System.Test.stopTest();

        List<Contract> contracts = [select Id from Contract where Id = :contract.Id];
        System.assertEquals(0, contracts.size(), 'Contracts were not deleted');
    }

}