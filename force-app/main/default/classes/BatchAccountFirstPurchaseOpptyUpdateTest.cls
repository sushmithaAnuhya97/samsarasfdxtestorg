@isTest
public class BatchAccountFirstPurchaseOpptyUpdateTest {
    
    @TestSetup
    static void setupTestData() {
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account Inc',
            BillingCountry = 'United States',
            BillingState = 'Texas',
            Organization_Size__c = '100 - 499',
            Industry = 'Other'
        );
        insert testAccount;
        
        // Create Opportunities
        List<Opportunity> testOpportunities = new List<Opportunity>();
        
        // First qualifying opportunity (earlier date)
        Opportunity opp1 = (Opportunity) TestFactory.createSObject(new Opportunity(
            AccountId = testAccount.Id,
            Type = 'Revenue Opportunity',
            Name = 'First Qualifying Opp',
            StageName = 'Closed Won',
            CloseDate = System.today().addDays(-20),
            Selected_Payment_Type__c = 'Direct Annual'
        ));
        testOpportunities.add(opp1);
        
        // Second qualifying opportunity (later date)
        Opportunity opp2 = (Opportunity) TestFactory.createSObject(new Opportunity(
            AccountId = testAccount.Id,
            Type = 'Revenue Opportunity',
            Name = 'Second Qualifying Opp',
            StageName = 'Closed Won',
            CloseDate = System.today().addDays(-10),
            Selected_Payment_Type__c = 'Direct Annual'
        ));
        testOpportunities.add(opp2);
        
        // Non-qualifying opportunity (wrong type)
        Opportunity opp3 = (Opportunity) TestFactory.createSObject(new Opportunity(
            AccountId = testAccount.Id,
            Type = 'Other',
            Name = 'Non-Qualifying Opp - Type',
            StageName = 'Closed Won',
            CloseDate = System.today().addDays(-5),
            Selected_Payment_Type__c = 'Direct Annual'
        ));
        testOpportunities.add(opp3);
        
        // Non-qualifying opportunity (wrong stage)
        Opportunity opp4 = (Opportunity) TestFactory.createSObject(new Opportunity(
            AccountId = testAccount.Id,
            Type = 'Revenue Opportunity',
            Name = 'Non-Qualifying Opp - Stage',
            StageName = 'Decision',
            CloseDate = System.today().addDays(-5),
            Selected_Payment_Type__c = 'Direct Annual'
        ));
        testOpportunities.add(opp4);
        
        insert testOpportunities;
    }
    
    @isTest 
    private static void testRunBatch() {
        Test.startTest();
        
        BatchAccountFirstPurchaseOpptyUpdate b = new BatchAccountFirstPurchaseOpptyUpdate();
        Database.executeBatch(b, 200);
        
        // Schedule the batch
        String CRON_EXP = '0 0 0 ? * * *';
        String jobId = System.schedule('BatchAccFirstPurchaseOpptyUpdateTest', 
                                       CRON_EXP, 
                                       new BatchAccountFirstPurchaseOpptyUpdate());
        
        Test.stopTest();
        
        // Verify results
        List<Account> updatedAccounts = [
            SELECT Id, First_Purchase_Opportunity__c, 
            (SELECT Id, CloseDate 
             FROM Opportunities 
             WHERE Type = 'Revenue Opportunity' 
             AND StageName = 'Closed Won'
             ORDER BY CloseDate ASC 
             LIMIT 1)
            FROM Account
        ];
        
        for(Account acc : updatedAccounts) {
            if(!acc.Opportunities.isEmpty()) {
                System.assertEquals(acc.Opportunities[0].Id, 
                                    acc.First_Purchase_Opportunity__c,
                                    'First Purchase Opportunity should match earliest qualifying opportunity');
            }
        }
    }
    
    @isTest
    static void testExecuteDmlAndLogErrorsMethod() {
        // Create a test account with a field value that will trigger a validation rule
        Account acc = new Account(
            Name = 'Test Account Error',
            Organization_Size__c = '100 - 499',
            BillingState = 'Texas', 
            Industry = 'Other'
        );
        insert acc;
        
        // Introduce an error by setting an invalid value for a required field
        acc.First_Purchase_Opportunity__c = '000000000000000000'; // Invalid ID to trigger an error
        
        // Start the test
        Test.startTest();
    
        BatchAccountFirstPurchaseOpptyUpdate batch = new BatchAccountFirstPurchaseOpptyUpdate();
        batch.executeDmlAndLogErrors(new List<SObject>{ acc });
        
        // End the test
        Test.stopTest();
    }
}