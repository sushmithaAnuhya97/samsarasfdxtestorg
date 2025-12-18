@isTest
private class AccountUpdateInvocable_Test {
    
    @TestSetup
    static void makeData(){
        List<Account> acctList = new List<Account>();

        acctList.add((Account) TestFactory.createSObject(new Account(Name='Blah1', Website='test.test')));
        if(!acctList.isEmpty()) {
            insert acctList;
        }
    }

    @isTest
    static void testAccountUpdate() {

        Account acct1 = [SELECT Id FROM Account WHERE Name = 'Blah1'];

        AccountUpdateInvocable.FlowInput flowInput1 = new AccountUpdateInvocable.FlowInput();
        flowInput1.accountId = acct1.Id;
        flowInput1.numberOfVehicles = 1000;  // Update vehicle count
        flowInput1.numberOfPoweredAssets = 10000;  // Update powered assets count
        flowInput1.numberOfUnpoweredAssets = 10000;  // Update powered assets count

        List<AccountUpdateInvocable.FlowInput> flowInputs = new List<AccountUpdateInvocable.FlowInput>{ flowInput1 };

        Test.startTest();
        List<Account> updatedAccounts = AccountUpdateInvocable.updateAccountData(flowInputs);
        Test.stopTest();
    }
}