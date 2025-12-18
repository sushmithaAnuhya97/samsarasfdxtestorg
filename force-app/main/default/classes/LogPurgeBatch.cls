/**
 * @description       : Batch class to purge old samsara log records based on retention period
 * @author            : shivam.goyal@samsara.com
 * @group             : 
 * @last modified on  : 06-05-2025
 * @last modified by  : shivam.goyal@samsara.com
**/
//Apex batch class to purge old samsara log records based on retention period

/*CRON :
        LogPurgeBatch b= new LogPurgeBatch();
		String seconds = '0'; //Execute at Zero Seconds
        String minutes = '0'; //Execute at every 0 minute of hour
        String hours = '2'; // Execute at 2 AM
        String dayOfMonth = '?'; // Execute Every Day of the Month
        String month = '*'; //Execute every Month
        String dayOfWeek = '*'; //Execute on all 7 days of the Week

		String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek;
		system.schedule('LogPurgeBatch Run Every Day at 2am', sch,b); 
*/ 

public class LogPurgeBatch implements Database.Batchable<sObject>, Schedulable {
    
    private DateTime cutoffDateTime;
    
    public LogPurgeBatch() {
        Integer retentionDays = Integer.valueOf(System.Label.Log_Retention_Days);
        this.cutoffDateTime = System.now().addDays(-retentionDays);
    }
    
    /**
     * @description Start method of the batch
     * @param BC Batch context
     * @return Database.QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            'SELECT Id FROM SamsaraLog__c WHERE CreatedDate < :cutoffDateTime'
        );
    }
    
    /**
     * @description Execute method of the batch
     * @param BC Batch context
     * @param scope List of records to process
     */
    public void execute(Database.BatchableContext BC, List<SamsaraLog__c> scope) {
        if (!scope.isEmpty()) {
            delete scope;
        }
    }
    
    /**
     * @description Finish method of the batch
     * @param BC Batch context
     */
    public void finish(Database.BatchableContext BC) {
        Logger.atInfo()
            .setClassName('LogPurgeBatch')
            .setMethod('finish')
            .setExceptionOrMessage('Batch completed successfully');
        Logger.insertMasterLogs();
    }
    
    /**
     * @description Execute method for schedulable interface
     * @param SC Schedulable context
     */
    public void execute(SchedulableContext SC) {
        Database.executeBatch(this, 200);
    }
}