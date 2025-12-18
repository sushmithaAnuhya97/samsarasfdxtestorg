@isTest(SeeAllData=false) 
private class addDemoDateAccountTest {

    static testMethod void addDemoDateAccount() {
    
        // insert account
        Account a = new Account (Name = 'Slater Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', ADR_Transfer__c = false);
        insert a;
        
        // insert contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'John', LastName = 'Florence', email = 'john@slater.com');            
        insert cntc;
        
        // insert contact
        Contact cntc2 = new Contact(AccountId = a.Id, FirstName = 'Kelly', LastName = 'Slater', email = 'kelly@slater.com');            
        insert cntc2;
        
        // check if contact demo default is null
        System.assertEquals(null, [SELECT  Demo_Date__c FROM Contact WHERE email = 'john@slater.com' LIMIT 1].Demo_Date__c);
        System.assertEquals(null, [SELECT  Demo_Date__c FROM Contact WHERE email = 'kelly@slater.com' LIMIT 1].Demo_Date__c);
        
        // check if account first demo date is null
        System.assertEquals(null, [SELECT  First_Demo_Date__c FROM Account WHERE Name = 'Slater Co' LIMIT 1].First_Demo_Date__c);

        // update contact demo date
        cntc.Demo_Date__c = System.today();
        update cntc;
        
        // check if account has demo date set
        System.assertEquals(System.today(), [SELECT  First_Demo_Date__c FROM Account WHERE Name = 'Slater Co' LIMIT 1].First_Demo_Date__c);
        
        // check if contact demo date was set
        System.assertEquals(System.today(), [SELECT  Demo_Date__c FROM Contact WHERE email = 'john@slater.com' LIMIT 1].Demo_Date__c);
        
        cntc2.Demo_Date__c = System.today() + 30;
        update cntc2;
        
        //make sure account didn't get updated
        System.assertEquals(System.today(), [SELECT  First_Demo_Date__c FROM Account WHERE Name = 'Slater Co' LIMIT 1].First_Demo_Date__c);
    
    }
    
    
    }