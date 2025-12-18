/**
* Created By : Groundswell - Suman Kundu
* @Date September 21, 2021
*
* @description : This class will be responsible for handling all OpportunityLineItem Service Operations
*
**/
public inherited sharing class GS_OpportunityLineItemService {
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    
    public GS_OpportunityLineItemService() {}
    
    private static Boolean objectReparenting(OpportunityLineItem thisOLI, OpportunityLineItem OldOLI, String parentField) {
		return (thisOLI.get(parentField) != OldOLI.get(parentField));
	}

    private static Set<Id> getEligibleRollupOpportunities(List<OpportunityLineItem> OliList, Map<Id, OpportunityLineItem> OldOliMap) {
		Map<String, Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Opportunity', 'OpportunityLineItem');
        Set<Id> targetRollupOppSet = new Set<Id>();
        if (OldOliMap == null) {
			Callable callInstance = (Callable) Type.forName('OpportunityLineItemHelper').newInstance();
			for (integer i = 0; i < OliList.size(); i++) {

				for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
					Object result = callInstance.call(rollUpField, new map<String, Object>{
						'newRecord' => OliList[i]
					});
					if (result == null) continue;
					if ((Boolean) result) {
						if (OliList[i].OpportunityId != null)
							targetRollupOppSet.add(OliList[i].OpportunityId);
						break;
					}
				}
			}
		} else {
			for (integer i = 0; i < OliList.size(); i++) {

				for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
					if (ObjectReparenting(OliList[i], OldOliMap.get(OliList[i].id), 'OpportunityId')) {
						if (OldOliMap.get(OliList[i].id).OpportunityId != null)
							targetRollupOppSet.add(OldOliMap.get(OliList[i].id).OpportunityId);
						if (OliList[i].OpportunityId != null)
							targetRollupOppSet.add(OliList[i].OpportunityId);
					} else {
						Callable callInstance = (Callable) Type.forName('OpportunityLineItemHelper').newInstance();

						object result = callInstance.call(rollUpField + 'PreCheck', new map<String, Object>{
							'newRecord' => OliList[i], 'oldRecord' => OldOliMap.get(OliList[i].id)
						});
						if (result == null) continue;
						if ((Boolean) result) {
							if (OliList[i].OpportunityId != null)
								targetRollupOppSet.add(OliList[i].OpportunityId);
							break;
						}
					}
				}
			}
		}
        return targetRollupOppSet;
	}

    public inherited sharing class TriggerContext{
        List<OpportunityLineItem> newList;
        List<OpportunityLineItem> oldList;
        Map<Id, OpportunityLineItem> newMap;
        Map<Id, OpportunityLineItem> oldMap;

        public TriggerContext(List<OpportunityLineItem> newList, List<OpportunityLineItem> oldList, Map<Id, OpportunityLineItem> newMap, Map<Id, OpportunityLineItem> oldMap){
            this.newList = newList;
            this.oldList = oldList;
            this.newMap = newMap;
            this.oldMap = oldMap;
        }

        public void handleBeforeInsertOperations(){
            thisLogger.logDebug('handleBeforeInsertOperations OpportunityLineItem List ::', newList);
            OpportunityLineItemHelper.setDiscountForOppType(newList, 100);
            OpportunityLineItemHelper.beforeUpdateUpkeep(newList, newMap, oldMap);
            OpportunityLineItemHelper.salesPriceUpdateForRenewalLines(newList);
            //new GS_SBQQQuoteWorkflowService(oldMap, newMap, newList).performWorkflowActions();
        }
        
        public void handleAfterInsertOperations(){
            thisLogger.logDebug('handleAfterInsertOperations OpportunityLineItem List ::', newList);
            //OpportunityLineItemHelper.calculateAllRollUpsToOpportunity(newList, null);
            Set<Id> targetRollupOppSet = getEligibleRollupOpportunities(newList, null);
            System.debug('****targetRollupOppSet> '+targetRollupOppSet);
            if (targetRollupOppSet.size() > 0) {
                DMLWrapper.doInsert(new GS_OpportunityLineItemServiceAsync().prepareAsyncRequests(
                    JSON.serialize(new GS_OpportunityLineItemServiceAsync.Options('calculateAllRollUpsToOpportunity')), 
                    targetRollupOppSet
                ));
            }
        }

        public void handleBeforeUpdateOperations(){
            thisLogger.logDebug('handleBeforeUpdateOperations New OpportunityLineItem List ::', newList);
            thisLogger.logDebug('handleBeforeUpdateOperations Old OpportunityLineItem Map ::', oldMap.values());
            Map<Id, SObject> unprocessedRecords = GS_TriggerRecursionManager.getNonRecursiveRecords(
                'OpportunityLineItem', 'before_update', newMap
            );
            if (unprocessedRecords.size() == 0) {
                thisLogger.logDebug('handleBeforeUpdateOperations All OpportunityLineItem are already executed, so exiting the trigger.');
                return;
            }
            OpportunityLineItemHelper.beforeUpdateUpkeep(newList, newMap, oldMap);
            //new GS_SBQQQuoteWorkflowService(oldMap, newMap, newList).performWorkflowActions();
        }
        
        public void handleAfterUpdateOperations(){
            thisLogger.logDebug('handleAfterUpdateOperations New OpportunityLineItem List ::', newList);
            thisLogger.logDebug('handleAfterUpdateOperations Old OpportunityLineItem Map ::', oldMap.values());
            
            Map<Id, SObject> unprocessedRecords = GS_TriggerRecursionManager.getNonRecursiveRecords(
                'OpportunityLineItem', 'after_update', newMap
            );
            if (unprocessedRecords.size() == 0) {
                thisLogger.logDebug('handleBeforeUpdateOperations All OpportunityLineItems are already executed, so exiting the trigger.');
                return;
            }
            //OpportunityLineItemHelper.calculateAllRollUpsToOpportunity(newList, oldMap);
            Set<Id> targetRollupOppSet = getEligibleRollupOpportunities(newList, oldMap);
            System.debug('****targetRollupOppSet> '+targetRollupOppSet);
            if (targetRollupOppSet.size() > 0) {
                DMLWrapper.doInsert(new GS_OpportunityLineItemServiceAsync().prepareAsyncRequests(
                    JSON.serialize(new GS_OpportunityLineItemServiceAsync.Options('calculateAllRollUpsToOpportunity')), 
                    targetRollupOppSet
                ));
            }
        }

        public void handleAfterDeleteOperations(){
            thisLogger.logDebug('afterDeleteOperations Old OpportunityLineItem List ::', oldList);
            //OpportunityLineItemHelper.calculateAllRollUpsToOpportunity(oldList, null);
            Set<Id> targetRollupOppSet = getEligibleRollupOpportunities(oldList, null);
            System.debug('****targetRollupOppSet> '+targetRollupOppSet);
            if (targetRollupOppSet.size() > 0) {
                DMLWrapper.doInsert(new GS_OpportunityLineItemServiceAsync().prepareAsyncRequests(
                    JSON.serialize(new GS_OpportunityLineItemServiceAsync.Options('calculateAllRollUpsToOpportunity')), 
                    targetRollupOppSet
                ));
            }
        }

        /*public void handleAfterUndeleteOperations(){
            thisLogger.logDebug('afterUndeleteOperations Old OpportunityLineItem List ::', newList);
            //OpportunityLineItemHelper.calculateAllRollUpsToOpportunity(newList, null);
            Set<Id> targetRollupOppSet = getEligibleRollupOpportunities(newList, null);
            System.debug('****targetRollupOppSet> '+targetRollupOppSet);
            if (targetRollupOppSet.size() > 0) {
                DMLWrapper.doInsert(new GS_OpportunityLineItemServiceAsync().prepareAsyncRequests(
                    JSON.serialize(new GS_OpportunityLineItemServiceAsync.Options('calculateAllRollUpsToOpportunity')), 
                    targetRollupOppSet
                ));
            }
        }*/
    }
}