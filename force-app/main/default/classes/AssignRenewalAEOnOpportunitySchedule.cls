/**
 * @description       : 
 * @author            : Priyank
 * @group             : 
 * @last modified on  : 03-08-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class AssignRenewalAEOnOpportunitySchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        AssignRenewalAEOnOpportunityBatch b = new AssignRenewalAEOnOpportunityBatch(); 
        Database.executeBatch(b, 100);
     }
}