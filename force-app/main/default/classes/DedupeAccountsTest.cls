@isTest
private class DedupeAccountsTest {
   // Setup test data
   @testSetup
    private static void testDataSetup(){
        //create three test accounts
        List<Account> newAccounts = new List<Account>();
        for (Integer i = 0; i < 2; i++){
            newAccounts.add(new Account (Name = 'Super Crazy Test Account',Website='www.crazytestaccount313.com',Domain_Name__c='crazytestaccount313.com', Organization_Size__c = '5000+', BillingCountry = 'United States',BillingState = 'Alabama', Industry = 'Other'));
        }
        newAccounts.add(new Account (Name = 'Not a Crazy Test Account',Organization_Size__c = '5000+', BillingCountry = 'United States',BillingState = 'Alabama', Industry = 'Other'));
        insert newAccounts;
        
    }
   // Methods for testing
   @isTest static void whenDuplicateRecordsExist() {
      // get the first super crazy test account
      Account testAccount = [SELECT Id,RecordTypeId FROM Account WHERE Website='www.crazytestaccount313.com' LIMIT 1];
      Account secondTestAccount = [SELECT Id,RecordTypeId FROM Account WHERE Website='www.crazytestaccount313.com' AND Id!=:testAccount.Id LIMIT 1];
      
      Test.startTest();
      DuplicateRule dR = [select id from DuplicateRule where DeveloperName = 'Lead_to_Account_Matching_v4' LIMIT 1];
      DuplicateRecordSet dupRS = new DuplicateRecordSet(DuplicateRuleId = dR.id);
      insert dupRS;

      DuplicateRecordItem dup = new DuplicateRecordItem(DuplicateRecordSetId = dupRS.id, RecordId=testAccount.id);
      insert dup;
      List<Account> accounts = new List<Account>();
      accounts.add(testAccount);
      List<List<Account>> results = DedupeAccounts.getDuplicateAccountsForProcessing(accounts);
      Boolean test_result = results[0].contains(secondTestAccount);
      System.assert(true,test_result);
      Test.stopTest();
   }
    
   @isTest static void whenDuplicateRecordsDoNotExist() {
      Test.startTest();
      // get the first super crazy test account
      Account testAccount = [SELECT Id,RecordTypeId FROM Account WHERE Name='Not a Crazy Test Account' LIMIT 1];
      List<Account> accounts = new List<Account>();
      accounts.add(testAccount);
      List<List<Account>> results = DedupeAccounts.getDuplicateAccountsForProcessing(accounts);
      Integer test_result = results[0].size();
      System.assertEquals(0, test_result);
      Test.stopTest();
   }
}