@isTest(SeeAllData=false)
public class Batch_AccountHierarchyOneTimeTest {
    Static Account testAccount;
    public static integer testCount=0;
    public static boolean isDUNSTest= false;

    @isTest static void testAccount_batchExeContractDNBmdt()
    {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        
        Account account = new Account (Name = 'Test Account RODRIGO Canada', Organization_Size__c = '5000+', Record_Type_Stamp_for_Dupes__c = 'Fleet', 
                                       Number_of_Powered_Assets__c = 200,
                                       BillingCountry = 'Canada', Industry = 'Other', Account_Lifetime_ACV__c=1001, Customer_ARR__c=1000,
                                       Quarantine_Enabled__c = false ,SAM_Number_Undecorated__c='abcabc',DUNS_Number__c = '1122',
                                       Justification_for_the_Relationship__c = '',Number_of_Vehicles__c=0
                                       );
         
        Account account2 = new Account (Name = 'Test Account RODRIGO Canada', Organization_Size__c = '5000+', Record_Type_Stamp_for_Dupes__c = 'Fleet', 
                                       Number_of_Powered_Assets__c = 200,
                                       BillingCountry = 'Canada', Industry = 'Other', Account_Lifetime_ACV__c=1001, Customer_ARR__c=1000,
                                       Quarantine_Enabled__c = false ,SAM_Number_Undecorated__c='abcabc',DUNS_Number__c = '1122',
                                       Justification_for_the_Relationship__c = '',Number_of_Vehicles__c = 0
                                       );
        
        newAccount.add(account);
        newAccount.add(account2);
        insert newAccount;
       
        List<Account> newAccountList = [select id, Latest_Active_Contract__c from Account limit 2];
               system.debug('Jaya test class newAccountList...'+newAccountList);
         
         Contract contract = new Contract(
                AccountId = newAccountList[0].Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(1),
                ContractTerm = 12
        );
        insert contract;
                Contract contract1 = [select id from Contract];
       system.debug('Jaya test class contract1...'+contract1);

            newAccountList[0].Latest_Active_Contract__c = contract1.id;
            update newAccountList[0];
        testCount = 0;
        database.executeBatch(new Batch_AccountHierarchyOneTime(), 1);
        testCount = 1;
        database.executeBatch(new Batch_AccountHierarchyOneTime(), 1);
        testCount = 2;
        database.executeBatch(new Batch_AccountHierarchyOneTime(), 1);
        isDUNSTest = false;
        database.executeBatch(new Batch_AccountHierarchyOneTime(), 1);
        isDUNSTest = true;
        database.executeBatch(new Batch_AccountHierarchyOneTime(), 1);
 
        Test.stopTest();
    }
 @isTest static void testAccount_batchExeContact3()
    {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        
        Account account = new Account (Name = 'Test Account RODRIGO Canada', Organization_Size__c = '5000+', Record_Type_Stamp_for_Dupes__c = 'Fleet', 
                                       Number_of_Powered_Assets__c = 200,
                                       BillingCountry = 'Canada', Industry = 'Other', Account_Lifetime_ACV__c=1001, Customer_ARR__c=1000,
                                       Quarantine_Enabled__c = false,
                                       Justification_for_the_Relationship__c = ''
                                       );
         
        Account account2 = new Account (Name = 'Test Account RODRIGO Canada', Organization_Size__c = '5000+', Record_Type_Stamp_for_Dupes__c = 'Fleet', 
                                       Number_of_Powered_Assets__c = 200,
                                       BillingCountry = 'Canada', Industry = 'Other', Account_Lifetime_ACV__c=1001, Customer_ARR__c=1000,
                                       Quarantine_Enabled__c = false ,
                                       Justification_for_the_Relationship__c = ''
                                       );
        newAccount.add(account);
        newAccount.add(account2);
        insert newAccount;
        
        list<Contact> newContacts = new list<Contact>();
        list<Account> newAccountList = [select id, Latest_Active_Contract__c from Account limit 2];
               system.debug('Jaya test class newAccount1...'+newAccountList);
        
        list<Contract> contractList = new list<Contract>();
        for(Account acc: newAccountList){
            Contract contract = new Contract(
                    AccountId = acc.Id,
                    StartDate = Date.today(),
                    EndDate = Date.today().adddays(1),
                    ContractTerm = 12
            );
            contractList.add(contract);
            
        }
        insert contractList;
        
        Contract contract1 = [select id from Contract limit 1];
        system.debug('Jaya test class contract1...'+contract1);
        
        Contact con = new Contact (FirstName = 'TestClass', LastName = 'Tester', Email = 'ttester@a.com', AccountId=newAccountList[0].Id);
        newContacts.add(con);
        insert newContacts;
        
        Contact con1 = [select id from contact limit 1];
        newAccountList[0].Billing_Contact__c = con1.id;
        update newAccountList[0];
         testCount = 0;
        database.executeBatch(new Batch_AccountHierarchyOneTime(), 1);
        testCount = 1;
        database.executeBatch(new Batch_AccountHierarchyOneTime(), 1);
        testCount = 2;
        database.executeBatch(new Batch_AccountHierarchyOneTime(), 1);
        Test.stopTest();
    }
     @isTest static void testAccount_batchExeDUNSNum4()
    {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        
        Account account = new Account (Name = 'Test Account RODRIGO Canada', Organization_Size__c = '5000+', Record_Type_Stamp_for_Dupes__c = 'Fleet', 
                                       Number_of_Powered_Assets__c = 200,
                                       BillingCountry = 'Canada', Industry = 'Other', Account_Lifetime_ACV__c=1001, Customer_ARR__c=1000,
                                       Quarantine_Enabled__c = false,
                                       Justification_for_the_Relationship__c = ''
                                       );
         
        Account account2 = new Account (Name = 'Test Account RODRIGO Canada', Organization_Size__c = '5000+', Record_Type_Stamp_for_Dupes__c = 'Fleet', 
                                       Number_of_Powered_Assets__c = 200,
                                       BillingCountry = 'Canada', Industry = 'Other', Account_Lifetime_ACV__c=1001, Customer_ARR__c=1000,
                                       Quarantine_Enabled__c = false ,
                                       Justification_for_the_Relationship__c = ''
                                       );
        newAccount.add(account);
        newAccount.add(account2);
        insert newAccount;
        
        list<Contact> newContacts = new list<Contact>();
        list<Account> newAccountList = [select id, Latest_Active_Contract__c from Account limit 2];
               system.debug('Jaya test class newAccount1...'+newAccountList);
        
        list<Contract> contractList = new list<Contract>();
        for(Account acc: newAccountList){
            Contract contract = new Contract(
                    AccountId = acc.Id,
                    StartDate = Date.today(),
                    EndDate = Date.today().adddays(1),
                    ContractTerm = 12
            );
            contractList.add(contract);
            
        }
        insert contractList;
        
        Contract contract1 = [select id from Contract limit 1];
        system.debug('Jaya test class contract1...'+contract1);
        
        Contact con = new Contact (FirstName = 'TestClass', LastName = 'Tester', Email = 'ttester@a.com', AccountId=newAccountList[0].Id);
        newContacts.add(con);
        insert newContacts;
        
        Contact con1 = [select id from contact limit 1];
        newAccountList[0].Billing_Contact__c = con1.id;
        update newAccountList[0];
        testCount = 0;
        database.executeBatch(new Batch_AccountHierarchyOneTime(), 1);
        testCount = 1;
        database.executeBatch(new Batch_AccountHierarchyOneTime(), 1);
        testCount = 2;
        database.executeBatch(new Batch_AccountHierarchyOneTime(), 1);
        Test.stopTest();
    }
}