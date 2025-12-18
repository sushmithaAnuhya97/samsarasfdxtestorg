/**
 * 11-3-2022 Rajesh GTMS-10103:- created
 */
 
@isTest
public with sharing class ContractAmenderTest {
    @testSetup
    private static void testDataSetup() {
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
        
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
        insert contact;

        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        insert contract;
    }

    @IsTest
    private static void testAmender() {
        Contract contract = [SELECT id, StartDate FROM Contract LIMIT 1];
        ContractAmender.Load(New List<id>{contract.Id});
        
    }
}