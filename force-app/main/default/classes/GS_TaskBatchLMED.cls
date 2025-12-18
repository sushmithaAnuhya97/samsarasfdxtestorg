/*
 * Description:- This batch job is used to populate the LastContacted & LastMeaningfulEngagementDate(LMED) on Account from Task
 * This job updates LMED & LastContacted for those which are not correctly populated by the batch GS_TaskRollupBatch
 * 10/3/2022 - Rajesh  GTMS-6499 
 * 
 * 
 * System.schedule('Scheduled Job GS_TaskBatchLMED 12:05', '05 12 * * * ?', new GS_TaskBatchLMED());
 */

global class GS_TaskBatchLMED implements Database.Batchable<sObject> ,Schedulable, Database.Stateful
{    
    Integer totalAcntsUpdated = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
        String strQuery = Label.Task_Batch_Job_Query;
        strQuery += ' lastmodifieddate = ' + (Test.IsRunningTest() ? 'TODAY' : 'YESTERDAY');
        //strQuery += ' day_only(lastmodifieddate) = 2022-10-04';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext bc, List<Task> scope)
    {
        Map<Id,Account> acntsToUpdate = new Map<Id,Account>();
        for(Task t : scope)
        {
            if(t.AccountId == null)
                continue;

            Account a;
            system.debug('RajLastContacted' + t.Account.Last_Contacted__c  + ', created=' + t.CreatedDate);
            if((t.CallDurationInSeconds > 0 
                    || (String.isNotBlank(t.Subject) && (t.Subject.containsIgnoreCase('Email') || t.Subject.containsIgnoreCase('[Gong In]') || t.Subject.containsIgnoreCase('[Gong Out]')))) 
                && (t.Account.Last_Contacted__c == null || t.Account.Last_Contacted__c < t.CreatedDate)){
                    If(acntsToUpdate.containsKey(t.AccountId)
                        && (acntsToUpdate.get(t.AccountId).Last_Contacted__c == null 
                            || acntsToUpdate.get(t.AccountId).Last_Contacted__c < t.CreatedDate)){
                        a = acntsToUpdate.get(t.AccountId);
                        a.Last_Contacted__c = t.CreatedDate;
                    }
                    else {
                        a = new Account(id=t.AccountId,Last_Contacted__c=t.CreatedDate);
                        acntsToUpdate.put(t.AccountId,a);
                    }
            }

            if((t.CallDurationInSeconds >= 90 
                    //|| t.SalesLoft1__SalesLoft_Unique_View_Count__c > 0 
                    //|| t.SalesLoft1__SalesLoft_Unique_Reply_Count__c > 0 
                    || (String.isNotBlank(t.Subject) && t.Subject.containsIgnoreCase('reply')))
                && (t.Account.Last_Meaningful_Engagement_Date__c == null || t.Account.Last_Meaningful_Engagement_Date__c < t.CreatedDate.date())){
                    If(acntsToUpdate.containsKey(t.AccountId)
                        && (acntsToUpdate.get(t.AccountId).Last_Meaningful_Engagement_Date__c == null 
                            || acntsToUpdate.get(t.AccountId).Last_Meaningful_Engagement_Date__c < t.CreatedDate.date())){
                        a = acntsToUpdate.get(t.AccountId);
                        a.Last_Meaningful_Engagement_Date__c = t.CreatedDate.date();
                    }
                    else {
                        a = new Account(id=t.AccountId,Last_Meaningful_Engagement_Date__c = t.CreatedDate.date());
                        acntsToUpdate.put(t.AccountId,a);
                    }
            }
        }

        Database.SaveResult[] updatedaccountslist = Database.update(acntsToUpdate.values(),false);
        totalAcntsUpdated += acntsToUpdate.values().size();
    }
    
    global void finish(Database.BatchableContext bc)
    {
        // for future use case to update the timestamp of successful run, so we can use it in the next run for delta changes
        gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
        gslib_ILogger thisLogger = thisModuleLogger.getLogger();
        thisLogger.logError('Total Number of Accounts to update=' + totalAcntsUpdated);
        thisLogger.dispatch();
    }

    global void execute(SchedulableContext SC) 
    {
        database.executebatch(new GS_TaskBatchLMED(),integer.valueOf(500));
    }
}