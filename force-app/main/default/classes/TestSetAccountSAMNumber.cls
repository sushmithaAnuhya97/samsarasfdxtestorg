@isTest
public class TestSetAccountSAMNumber {
  static testMethod void insertNewAccount() {
        Account a = new Account();
        
        a.Name = 'test';
        a.Type = 'Fleet';
        a.Industry = 'Other';
        a.organization_size__c = '1 - 99';
        a.billingstreet = '123 Main St, San Francisco CA, 94110';
        a.billingstate = 'California';
        a.billingcountry = 'United States';
        a.billingcity = 'San Francisco';
        a.billingPostalCode = '94110';
        a.shippingstreet = '123 Main St, San Francisco CA, 94110';
        a.shippingstate = 'California';
        a.shippingcountry = 'United States';
        a.shippingcity = 'San Francisco';
        a.shippingPostalCode = '94110';
        insert a;
    }
 }