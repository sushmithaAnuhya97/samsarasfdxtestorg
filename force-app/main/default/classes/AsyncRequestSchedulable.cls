/**
* Created By : Groundswell - Flávio Contini
* @Date September 12, 2022
*
* @description : This class will be handle the Schedulable interface for the AsyncRequestQueueable class.
* The schedulable interface should start off Queueable threads for AsyncRequestQueueable if there are any pending jobs that are unlikely to yet be processed
**/
public without sharing class AsyncRequestSchedulable implements Schedulable {

    public void execute(SchedulableContext ctx){
        Integer numberOfPendingRecords = [
            SELECT COUNT()
              FROM Async_Request__c
             WHERE Error_Msg__c = NULL
               AND TimeInQueue__c >= :AsyncRequestQueueable.MINIMUM_MINUTES_IN_QUEUE_FOR_SCHEDULABLE
        ];

        System.debug('Number of Async Request records pending to process over '+AsyncRequestQueueable.MINIMUM_MINUTES_IN_QUEUE_FOR_SCHEDULABLE+' minutes in queue: '+numberOfPendingRecords);
        
        if (numberOfPendingRecords > 0){
            AsyncRequestQueueable.startJob(false);
        }
    }
}