/**
 * @description       : 
 * @author            : Priyank
 * @group             : 
 * @last modified on  : 12-06-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

@IsTest
public class AssignRenewalAEOnAccountBatchTest {
    private static String FREE_TRIAL_OPP_NAME = 'Opp Testers 1 Inc';
    private static String REVENUE_OPPORTUNITY = 'Opp Testers 2 Inc';
    private static String RESOLUTION_OPP_NAME = 'Resolution Opp';
    @TestSetup
    static void setup() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
        List<Contract> newContracts = new List<Contract>();
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        newAccounts.add(accountOne);
        
        Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                BillingState='California',
                                BillingCountry = 'United States',
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                //Renewal_AE__c = Userinfo.getUserId(),
                                Industry = 'Other');
        newAccounts.add(accountTwo);

        insert newAccounts;
        
        Contract OneC = new Contract(AccountId=newAccounts[0].Id, Status='Draft', StartDate=System.today(), Health_Status__c='Healthy',
                                     EndDate=System.today()+90, ContractTerm=24, Contract_Renewal_ACV__c=1000);
        newContracts.add(OneC);
        Contract TwoC = new Contract(AccountId=newAccounts[1].Id, Status='Draft', StartDate=System.today(), Health_Status__c='Unhealthy',
                                     EndDate=System.today()+90, ContractTerm=24, Contract_Renewal_ACV__c=2000);
        newContracts.add(TwoC);
        
        insert newContracts;
    }

    @isTest
    public static void test_assignRenewalAE(){
        try {
            Test.startTest();
            Database.executeBatch(new AssignRenewalAEOnAccountBatch());

            
            Test.stopTest();
            // Batch Apex job executes here


        } catch(Exception e) {
            // Catch any exceptions thrown in the batch job
        }
        Test.getEventBus().deliver();
    }
}