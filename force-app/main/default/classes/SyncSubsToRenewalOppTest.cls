@isTest
public class SyncSubsToRenewalOppTest {
    @isTest
    public static void testContractService() {
        List<Id> contIds = new List<Id>();
        Account account = new Account(Name = 'Testing Class Account', 
                                      Organization_Size__c = '1 - 99', 
                                      Industry = 'Food & Beverage',
                                      Website = 'TestClassByHarsha.com', 
                                      BillingCountry = 'United States', 
                                      BillingState = 'California');
        insert account;
                        
        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        insert contract;
        
        contIds.add(contract.Id);
        
        SyncSubsToRenewalOpp.syncSubsToRenewalOpps(contIds);
    }
}