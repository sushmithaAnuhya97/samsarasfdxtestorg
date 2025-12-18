@isTest
private class AssignInboundLeadExistingContactTest {
    static testMethod void newInboundTaskPool() {
        User pool = [select Id from User where Name = 'SFDC Pool'];
        
        Account a = new Account (Name = 'Han', OwnerId = pool.Id, Phone = '415 555 5255', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California');
        insert a;
        
        Contact c = new Contact (FirstName = 'Han', LastName = 'Solo', email='han@falcon.com',
                              Phone = '415 555 5255', Status__c = 'New', 
                              Source__c = 'Free Trial Request Form', AccountId=a.Id, OwnerId = pool.Id);
        insert c;
                              
        Task t = new Task (Subject='Submitted Form "2016 06 24 Online Ads - Facebook Lead Gen 10- Test" ', Status='Open', Description='First Name: JR Last Name: JohnsonEmail: jrj6621@gmail.com Lead Source: Facebook Form', WhoId = c.Id);
        insert t;
        
        //System.assertNotEquals('SFDC Pool', [SELECT Owner.Name FROM Contact WHERE email = 'han@falcon.com' LIMIT 1].Owner.Name);
        
        Account a2 = new Account (Name = 'Surf Co', OwnerId = pool.Id, Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California');
        insert a2;
        
        Contact c2 = new Contact (FirstName = 'John', LastName = 'Slater', email='jslater@surfco.com',
                              Phone = '415 533 5122', Status__c = 'New', 
                              Source__c = 'Facebook Form', AccountId=a2.Id, OwnerId = pool.Id);
        insert c2;
                              
        Task t2 = new Task (Subject='Submitted Form "2016 06 24 Online Ads - Facebook Lead Gen 10- Test" ', Description='First Name: JR Last Name: JohnsonEmail: jrj6621@gmail.com Lead Source: Facebook Form', WhoId = c.Id);
        insert t2;
    }
    static testMethod void newInboundTaskUser() {
        User pool = [select Id from User where Name = 'Alex Fisher'];
        Account a = new Account (Name = 'Han', OwnerId = pool.Id, Phone = '415 555 5255', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California');
        insert a;
        
        Contact c = new Contact (FirstName = 'Han', LastName = 'Solo', email='han@falcon.com',
                              Phone = '415 555 5255', Status__c = 'New', 
                              Source__c = 'Free Trial Request Form', AccountId=a.Id, OwnerId = pool.Id);
        insert c;
                              
        Task t = new Task (Subject='Submitted Form "2016 06 24 Online Ads - Facebook Lead Gen 10- Test" ', Description='First Name: JR Last Name: JohnsonEmail: jrj6621@gmail.com Lead Source: Facebook Form', WhoId = c.Id);
        insert t;
        
        System.assertEquals('Alex Fisher', [SELECT Owner.Name FROM Contact WHERE email = 'han@falcon.com' LIMIT 1].Owner.Name);
    }
    static testMethod void sourceList() {
        User pool = [select Id from User where Name = 'Alex Fisher'];
        Account a = new Account (Name = 'Han', OwnerId = pool.Id, Phone = '415 555 5255', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California');
        insert a;
        
        Contact c = new Contact (FirstName = 'Han', LastName = 'Solo', email='han@falcon.com',
                              Phone = '415 555 5255', Status__c = 'New', 
                              Source__c = 'List Import (no prior engagement)', AccountId=a.Id, OwnerId = pool.Id);
        insert c;
                              
        Task t = new Task (Subject='Submitted Form "2016 06 24 Online Ads - Facebook Lead Gen 10- Test" ', Description='First Name: JR Last Name: JohnsonEmail: jrj6621@gmail.com Lead Source: Facebook Form', WhoId = c.Id);
        insert t;
        
        //System.assertEquals('Facebook Form', [SELECT Owner.Name, Source__c FROM Contact WHERE email = 'han@falcon.com' LIMIT 1].Source__c);
    }
    
}