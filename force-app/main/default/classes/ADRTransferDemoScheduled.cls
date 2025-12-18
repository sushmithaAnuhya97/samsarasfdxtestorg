/*
* NOV 15th, 2021 Anil bogadi(GTMS-5013) Create new field on Opportunity object called "Deployment Type" for Sites Deals
*/
global class ADRTransferDemoScheduled Implements Schedulable{
    global void execute(SchedulableContext sc){
        Database.executeBatch(new ADRTransferDemoScheduledBatch(), 1);
    }
}