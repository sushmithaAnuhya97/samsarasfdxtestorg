/*
 * Description:- This batch job is used to populate the rollups on contact & account from Task
 * 2/1/2022 - Rajesh :- GTMS-5782 Stabilization - Reduce System Impacts for Task Rollups
 * 8/24/2022 - Siddharth Kumar Mishra (GTMS-8004) - Changed the order by field from whoid to CreatedDate
 * 
 * 
 * System.schedule('Scheduled Job GS_TaskRollupBatch 17', '0 17 * * * ?', new GS_TaskRollupBatch(8));
 */

global class GS_TaskRollupBatch implements Database.Batchable<sObject> ,Schedulable
{    
    public integer hours;

    public GS_TaskRollupBatch(integer ahours){
        if(ahours<>null)            
            this.hours = ahours;
    }
    
    /*    
        Create a schedule to be run daily once. When this batch job runs, it processes the previous days tasks modified
        
        /*SELECT Id,CallType ,CallDisposition ,OwnerId ,Old_Account_Contact__c , AccountId, Related_Contact__c,Account.Number_of_Calls__c,Account.Number_of_Calls_by_Current_Owner__c, 
            Account.Last_Meaningful_Engagement_Date__c, SalesLoft1__SalesLoft_Unique_View_Count__c, CallDurationInSeconds,
            Related_Contact__r.Number_of_Calls_by_Current_Owner_Roll_Up__c,CreatedDate,LastModifiedDate,
            whoid,whatid,Call_Logged_to_Contact__c,Related_Contact__r.Number_of_Calls__c,Subject,
            Related_Contact__r.AccountId,Related_Contact__r.Account.First_Revenue_Oppty_Creation_Date__c,
            Account.Last_Contacted__c,Related_Contact__r.Last_Contacted__c,Related_Contact__r.Last_Call__c
            FROM Task WHERE id = '00T6s00000AcalcEAB'*/
            
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
        String strQuery = Label.Task_Batch_Job_Query;

        system.debug('hours=' + this.hours);

        Datetime lastNHours = Datetime.now().addHours(0-(this.hours + 1)); 
        //Datetime lastNHours = Datetime.now().addDays(-200); 
        system.debug('lastNHours=' + lastNHours);
        strQuery += ' lastmodifieddate >= ';
        strQuery += ((string.valueOf(lastNHours).substring(0,13)).replace(' ', 'T') + ':00:00Z') + ' ORDER BY CreatedDate,AccountId'; //GTMS-8004
		//strquery+=((string.valueOf(lastNHours).substring(0,13)).replace(' ', 'T') + ':00:00Z') + 'AND id IN (\'00T8A00000GaATRUA3\',\'00T1P0000280EAZUA2\') ' + ' ORDER BY whoid';
        system.debug('strQuery=' + strQuery);
        
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext bc, List<Task> scope)
    {
        GS_TaskRollupHelper.startRollupProcessing(scope);
    }
    
    global void finish(Database.BatchableContext bc)
    {
        // for future use case to update the timestamp of successful run, so we can use it in the next run for delta changes
    }

    global void execute(SchedulableContext SC) 
    {
        database.executebatch(new GS_TaskRollupBatch(hours),integer.valueOf(Label.Task_Batch_Size));
    }
}