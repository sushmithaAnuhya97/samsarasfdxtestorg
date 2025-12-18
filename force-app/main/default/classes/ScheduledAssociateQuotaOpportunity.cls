/* 
* Class Created: 10/19/18 - Epic SS-8 @author: Harsha
*/

/* Created the class to schedule the same for everyday run */
global class ScheduledAssociateQuotaOpportunity implements Schedulable {
   global void execute(SchedulableContext sc) {

       System.debug('CPU time before the job for the class <ScheduledAssociateQuotaOpportunity> is scheduled: ' +  Limits.getCpuTime());
       AssociateQuotaOpportunity quotaOpportunity = new AssociateQuotaOpportunity();
       quotaOpportunity.mapQuotaAndOpportunities();
       System.debug('CPU time after the job for the class <ScheduledAssociateQuotaOpportunity> is completed: ' +  Limits.getCpuTime());
       
   }
}