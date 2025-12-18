/**
 * GTMS-28592: Batch class to process Expiring Next Quarter field for all eligible accounts
 * Runs as both batch and schedulable job to maintain field accuracy
 * 
 * Query Configuration:
 * - The SOQL query is stored in custom label: Contract_Expiring_Next_Quarter_Batch_Query
 * - Query targets Accounts with eligible contracts to avoid duplicate processing
 * - Query is complete and ready to use - no placeholders or formatting needed
 * - To modify query criteria, update the custom label without code deployment
 * - For ad-hoc execution, simply update the custom label and execute the batch
 */
public class ContractExpiringNextQuarterBatch implements Database.Batchable<SObject>, Schedulable {
    
    /**
     * Batch start method - queries all eligible accounts using configurable query from custom label
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Get query directly from custom label - no formatting or dependencies needed
        String query = System.Label.Contract_Expiring_Next_Quarter_Batch_Query;
        
        return Database.getQueryLocator(query);
    }
    
    /**
     * Batch execute method - processes accounts in chunks
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Cast to Account records and collect account IDs
        List<Account> accounts = (List<Account>) scope;
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        // Process the accounts
        if (!accountIds.isEmpty()) {
            ContractHelper helper = new ContractHelper();
            helper.processExpiringNextQuarter(accountIds);
        }
    }
    
    /**
     * Batch finish method - logs completion
     */
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems 
                           FROM AsyncApexJob WHERE Id = :bc.getJobId()];
    }
    
    /**
     * Schedulable execute method - allows this class to be scheduled
     */
    public void execute(SchedulableContext sc) {
        // Execute the batch with a reasonable batch size
        Database.executeBatch(new ContractExpiringNextQuarterBatch(), 200);
    }
    
    /**
     * Utility method to schedule this job
     * @param cronExpression Cron expression for scheduling (e.g., '0 0 2 * * ?' for daily at 2 AM)
     */
    public static String scheduleJob(String cronExpression) {
        String jobName = 'Contract Expiring Next Quarter Update - ' + DateTime.now().format('yyyy-MM-dd HH:mm:ss');
        return System.schedule(jobName, cronExpression, new ContractExpiringNextQuarterBatch());
    }
}