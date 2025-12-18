/*
* 12-Dec-2023 Alekya Added logic for GTMS-16223.

*/
public class FinancePartnerQuoteTriggerHandler extends TriggerHandler{
    
    private Map<Id, Finance_Partner_Quote__c  > oldEventMap;
    private Map<Id, Finance_Partner_Quote__c  > newEventMap;
    private List<Finance_Partner_Quote__c  > newEventList;
    
    public FinancePartnerQuoteTriggerHandler() {
        this.oldEventMap = (Map<Id, Finance_Partner_Quote__c  >) Trigger.oldMap;
        this.newEventMap = (Map<Id, Finance_Partner_Quote__c  >) Trigger.newMap;
        this.newEventList = (List<Finance_Partner_Quote__c  >) Trigger.new;
    }

    public override void afterInsert() {
        //system.debug('RODRIGO quoteIdList afterInsertOperations before');
        FinancePartnerQuoteTriggerHelper.afterInsertOperations(oldEventMap, newEventList); // GTMS-16223
    }
    
    public override void afterUpdate() {
        FinancePartnerQuoteTriggerHelper.afterUpdateOperations(oldEventMap, newEventMap);
        FinancePartnerQuoteTriggerHelper.notifyWithChangedFields(oldEventMap, newEventList);
        FinancePartnerQuoteTriggerHelper.clearDoesApprovalRequiredonCPQ(oldEventMap, newEventList);
    }
     public override void beforeUpdate() {
        FinancePartnerQuoteTriggerHelper.beforeUpdateOperations(oldEventMap, newEventList);
        //FinancePartnerQuoteTriggerHelper.populateContractEndDate(oldEventMap, newEventList);
    }
}