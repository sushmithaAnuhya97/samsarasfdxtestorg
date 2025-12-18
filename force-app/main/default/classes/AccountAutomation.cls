public class AccountAutomation implements Database.Batchable<sObject>{
    private final String query;
    private final Boolean chainFlag;
    private final Integer daysAgo;

    public AccountAutomation(String query, Boolean chainFlag, Integer daysAgo) {
        this.query = query;
        this.chainFlag = chainFlag;
        this.daysAgo = daysAgo == null ? 0 : daysAgo;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Task> scope){
        Map<Id, Account> updatedAccounts = new Map<Id, Account>();
        for(Task task : scope){
            if(!updatedAccounts.containsKey(task.AccountId) && (task.Account.Last_Meaningful_Engagement_Date__c == null || task.Account.Last_Meaningful_Engagement_Date__c < task.CreatedDate)){
                updatedAccounts.put(task.AccountId, new Account(Id = task.AccountId, Last_Meaningful_Engagement_Date__c = Date.today() - daysAgo));
            }
        }
        if(updatedAccounts.size() > 0){
                update updatedAccounts.values();
        }
    }
    
    public void finish(Database.BatchableContext bc){
        if(chainFlag){
        	System.debug('CPU time before the job for the class <ActivityAutomation> is scheduled: ' +  Limits.getCpuTime());
        	System.debug('CPU time after the job for the class <ActivityAutomation> is completed: ' +  Limits.getCpuTime());
        } 
    }
}