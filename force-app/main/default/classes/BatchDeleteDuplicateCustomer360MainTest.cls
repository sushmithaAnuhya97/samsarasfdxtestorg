@isTest
public class BatchDeleteDuplicateCustomer360MainTest {
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
    static List<Customer_360__c> createListCustomer360() 
    {
        List<Customer_360__c> cus=new List<Customer_360__c>();
        Customer_360__c cus1=new Customer_360__c();
        Account acc=createAccount();
        cus1.Account__c=acc.id;
        Customer_360__c cus2=new Customer_360__c();
        cus2.Account__c=acc.id;
        cus.add(cus2);
        cus.add(cus1);
        insert cus;
        return cus;
        
    }
    
    @isTest
    static void BatchDeleteDuplicateCustomer360MainTestMethod()
    {
        List<Customer_360__c> dataForBatch=createListCustomer360();
        System.Test.startTest();
        Database.executeBatch(new BatchDeleteDuplicateCustomer360Main(),1);
        System.Test.stopTest();
        
    }
    
}