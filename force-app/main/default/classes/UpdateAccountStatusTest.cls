@isTest
private class UpdateAccountStatusTest {

static Account a;
static Contact cntc;
static Contact cntc2;
    
    @testSetup
    private static void avalaraSetup() {
        
    }

    /*@testSetup static void setup() {
    
        // Create account
        Account a = new Account (Name = 'Sarah Comp', Organization_Size__c =' 1 - 99', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'Texas');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Sarah', LastName = 'Johns');            
        insert cntc;
        
        // Create a contact
        Contact cntc2 = new Contact(AccountId = a.Id, FirstName = 'Tomas', LastName = 'Johns');            
        insert cntc2;
    }*/

    static testMethod void UpdateStatusDemoRetouch() {
    
        // Create account
        Account a = new Account (Name = 'Sarah Comp', Organization_Size__c =' 1 - 99', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'Texas');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Sarah', LastName = 'Johns');            
        insert cntc;
        
        // Create a contact
        Contact cntc2 = new Contact(AccountId = a.Id, FirstName = 'Tomas', LastName = 'Johns');            
        insert cntc2;
            
        cntc.Status__c='Demo Scheduled';
        update cntc;
        cntc2.Status__c='Attempting';
        update cntc2;
        Account account_updated = [Select Id, Status__c From Account where Id=:a.Id];
        System.assertEquals(account_updated.Status__c, 'Demo Scheduled');
        
        
        cntc2.Status__c='Retouch - Confirmed No Opportunity';
        update cntc2;
        Account account_updated2 = [Select Id, Status__c From Account where Id=:a.Id];
        System.assertEquals(account_updated2.Status__c, 'Retouch - Confirmed No Opportunity');
        
    }
    
    static testMethod void UpdateStatusDeleteQualified() {
    
        // Create account
        Account a = new Account (Name = 'Sarah Comp', Organization_Size__c =' 1 - 99', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'Texas');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Sarah', LastName = 'Johns');            
        insert cntc;
        
        // Create a contact
        Contact cntc2 = new Contact(AccountId = a.Id, FirstName = 'Tomas', LastName = 'Johns');            
        insert cntc2;
        
        
        cntc2.Status__c='Delete Account';
        update cntc2;
        Account account_updated3 = [Select Id, Status__c From Account where Id=:a.Id];
        System.assertEquals(account_updated3.Status__c, 'Delete');
        
        
        cntc2.Status__c='Qualified';
        update cntc2;
        Account account_updated4 = [Select Id, Status__c From Account where Id=:a.Id];
        System.assertEquals(account_updated4.Status__c, 'Qualified');
        
    
    }
    
    static testMethod void UpdateOpptyStatus() {
    
        // Create account
        Account a = new Account (Name = 'Sarah Comp', Organization_Size__c =' 1 - 99', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'Texas');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Sarah', LastName = 'Johns');            
        insert cntc;
        
        // Create a contact
        Contact cntc2 = new Contact(AccountId = a.Id, FirstName = 'Tomas', LastName = 'Johns');            
        insert cntc2;
    
        
        Opportunity o = new Opportunity (Name = 'Opportunity Test', StageName='Incubate', AccountId=a.Id, CloseDate=date.today());
        insert o;
        cntc2.Status__c='New';
        update cntc2;
        Account account_updated5 = [Select Id, Status__c From Account where Id=:a.Id];
        System.assertEquals(account_updated5.Status__c, 'Open Opportunity');
        
        Test.startTest();
        
        Opportunity o2 = new Opportunity (Name = 'Opportunity Test 2', StageName='Incubate', AccountId=a.Id, CloseDate=date.today());
        insert o2;
        cntc2.Status__c='New';
        update cntc2;
        o2.StageName='Closed Won';
        update o2;
        Account account_updated6 = [Select Id, Status__c From Account where Id=:a.Id];
        System.assertEquals(account_updated6.Status__c, 'Existing Customer');
        Test.stopTest();
    }
}