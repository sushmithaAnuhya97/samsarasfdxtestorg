/* 
 * Test Class: ScheduledAssociateQuotaOpportunity
 * Class Created: 5/7/20 - @author: Kai-Rey (GTMS-743/GTMS-803)
 * 9/17/2020 - @author: Teja (GTMS-1489) removed (-15,-30) for Return_Label_Sent_At__c to just (-25)
 */

/* Created the class to schedule the same for everyday run */
global class ScheduledExchangeReminderEmailer implements Schedulable {
   global void execute(SchedulableContext sc) {

        System.debug('CPU time before the job for the class <ScheduledExchangeReminderEmailer> is scheduled: ' +  Limits.getCpuTime());
        Date labelDate = System.Today().addDays(-25);
        Date labelDate2 = System.Today().addDays(-40);
        
        System.debug(labelDate); 
        List<Id> returnOpptysToEmail = new List<Id>();
        List<Opportunity> exchanges = [SELECT Id FROM Opportunity WHERE (Type = 'Warranty Exchange' OR Type = 'Exchange') AND 
                                       StageName = 'Return Label Sent' AND (Return_Label_Sent_At__c = :labelDate OR Return_Label_Sent_At__c = :labelDate2)];
       if(exchanges.size() > 0){ 
          for(Opportunity o : exchanges) {
              returnOpptysToEmail.add(o.Id);
          }

          ReminderEmailBatchSend sendEmailBatch = new ReminderEmailBatchSend(returnOpptysToEmail);
          Database.executebatch(sendEmailBatch, 5);
       }
        System.debug('CPU time after the job for the class <ScheduledExchangeReminderEmailer> is completed: ' +  Limits.getCpuTime());
       
   }
}