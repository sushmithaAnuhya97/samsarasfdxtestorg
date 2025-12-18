/**
 * @description       : 
 * @author            : Priyank
 * @group             : 
 * @last modified on  : 12-06-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class AssignRenewalAEOnAccountSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        //RoundRobinHandler.resetRuleMappingTotalValue('ARR');
        AssignRenewalAEOnAccountBatch b = new AssignRenewalAEOnAccountBatch(); 
        Database.executeBatch(b, 50);
     }
}