@isTest
public class BatchAssignAccountToOriginalOwnerTest {
    
    @testSetup 
    public static void dataSetup() {
        List<Account> accList = new List<Account>();
        List<Contact> conList = new List<Contact>();
        User aeUser = [SELECT Id FROM User WHERE UserRole.Name LIKE '%AE%' LIMIT 1];
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                         BillingCountry = 'United Kingdom',
                                         Organization_Size__c = '100 - 499',
                                         Original_Owner_for_Recycling_Campaign__c  = aeUser.Id,
                                         Account_Assignment_Date__c = system.today().addDays(-15),
                                         Industry = 'Other');
        Account accountTwo = new Account(Name = 'Testers 2 Inc',
                                         BillingCountry = 'United Kingdom',
                                         Original_Owner_for_Recycling_Campaign__c  = aeUser.Id,
                                         Organization_Size__c = '100 - 499',
                                         Account_Assignment_Date__c = system.today().addDays(-15),
                                         Industry = 'Other');
        accList.add(accountOne);
        accList.add(accountTwo);
        insert accList;
        accountOne.Account_Assignment_Date__c = system.today().addDays(-15);
        accountTwo.Account_Assignment_Date__c = system.today().addDays(-15);
        update accList;
        Contact contactOne = new Contact(AccountId = accountOne.Id, 
                                         FirstName = 'test2', 
                                         LastName = 'name', 
                                         Email = 'test@mail.com',
                                         Hashtag__c  = 'projectYOYO testing');
        Contact contactTwo = new Contact(AccountId = accountTwo.Id, 
                                         FirstName = 'test1', 
                                         LastName = 'name', 
                                         Email = 'test@mail.com',
                                         Hashtag__c  = 'projectYOYO testing');
        conList.add(contactOne);
        conList.add(contactTwo);
        insert conList;
    }
    @isTest
    public static void testMethod1() {
        Test.startTest();
        BatchAssignAccountToOriginalOwner b = new BatchAssignAccountToOriginalOwner();
        database.executebatch(b);
        
        BatchAssignAccountToOriginalOwner sc = new BatchAssignAccountToOriginalOwner();   
        String chron = '0 0 23 * * ?';        
        system.schedule('Test Sched', chron, sc);
        Test.stopTest();
    }
    
    
}