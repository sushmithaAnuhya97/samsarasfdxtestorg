@isTest
private class FlowAccountFinderTest {
   // Setup test data
   @testSetup
    private static void testDataSetup(){
        //create two test accounts
        List<Account> newAccounts = new List<Account>();
        newAccounts.add(new Account (Name = 'Super Crazy Test Account',Website='www.crazytestaccount1.com',Domain_Name__c='crazytestaccount1.com',Alternative_Domains__c='["crazytestaccount1.com","crazytestaccount.com"]', Organization_Size__c = '5000+', Phone='123-456-7890',BillingCountry = 'United States',DUNS_Number__c='048244101',BillingStreet = '123 crazy kids lane #1',BillingState = 'Alabama',BillingPostalCode = '12345', Industry = 'Passenger Transit'));
        newAccounts.add(new Account (Name = 'Super Crazy Test Account 31234',Alternative_Domains__c='["crazytestaccount1.com","crazytestaccount.com"]', Organization_Size__c = '5000+',BillingCountry = 'United Kingdom',DUNS_Number__c='048244101', Industry = 'Passenger Transit'));
        insert newAccounts;
    }
   // Methods for testing
   @isTest static void doASearch() {
      // get the first super crazy test account
      Account testAccount = [SELECT Name,Website,Domain_Name__c,Alternative_Domains__c,Phone,BillingCity,BillingCountry,BillingState,BillingStreet,BillingPostalCode,DUNS_Number__c,RecordTypeId,Id FROM Account WHERE Website='www.crazytestaccount1.com' LIMIT 1];
      Account secondAccount = [SELECT Id,Website,Domain_Name__c,BillingStreet,BillingState,BillingCity,Phone FROM Account WHERE Name='Super Crazy Test Account 31234' LIMIT 1];
      Test.startTest();

      List<Account> accounts = new List<Account>();
      accounts.add(testAccount);
      List<List<Account>> accounts_list = new List<List<Account>>();
      accounts_list.add(accounts);
      List<List<SObject>> results = FlowAccountFinder.searchForAccounts(accounts_list);
      Boolean test_result = false;
      for(Integer i = 0;i<results[0].size();i++){
          System.debug(results[0][i]);
          if(secondAccount.Id == results[0][i].Id){
              test_result=true;
              //cast result as an account instead of sObject
              Account a = (Account)results[0][i];
              System.assert(true,(String.isBlank(secondAccount.Website) && a.Website==''));
              System.assert(true,(String.isBlank(secondAccount.Domain_Name__c) && a.Domain_Name__c==''));
              System.assert(true,(String.isBlank(secondAccount.BillingStreet) && a.BillingStreet==''));
              System.assert(true,(String.isBlank(secondAccount.BillingState) && a.BillingState==''));
              System.assert(true,(String.isBlank(secondAccount.BillingCity) && a.BillingCity==''));
              System.assert(true,(String.isBlank(secondAccount.Phone) && a.Phone==''));
          }
      }
      System.assert(true,test_result);
      Test.stopTest();
   }
}