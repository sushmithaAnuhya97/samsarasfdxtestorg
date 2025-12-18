/* 
* Class Created: 14/16/19 - @author: Harsha
*/

/* Created the class to schedule the same for everyday run */
global class ScheduledAssociateQuotaTransferLog implements Schedulable {
   global void execute(SchedulableContext sc) {

       System.debug('CPU time before the job for the class <ScheduledAssociateQuotaTransferLog> is scheduled: ' +  Limits.getCpuTime());
       AssociateQuotaTransferLog quotaTransferLog = new AssociateQuotaTransferLog();
       quotaTransferLog.mapQuotaAndTransferLogs();
       System.debug('CPU time after the job for the class <ScheduledAssociateQuotaTransferLog> is completed: ' +  Limits.getCpuTime());
       
   }
}