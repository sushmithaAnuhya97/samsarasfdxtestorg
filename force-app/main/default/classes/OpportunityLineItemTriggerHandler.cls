public class OpportunityLineItemTriggerHandler extends TriggerHandler {

	private List<OpportunityLineItem> newOppLineItemList;
    private List<OpportunityLineItem> oldOppLineItemList;
	private Map<Id, OpportunityLineItem > oldOppLineItemMap;
	private Map<Id, OpportunityLineItem > newOppLineItemMap;
	private UnitOfWork uow;
    private List<OpportunityLineItem> renewalOrRemorseRefundLst = new List<OpportunityLineItem>();
	public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
			Opportunity.SObjectType
	};

	public OpportunityLineItemTriggerHandler() {
		this.newOppLineItemList = (List<OpportunityLineItem>) Trigger.new;
        this.oldOppLineItemList = (List<OpportunityLineItem>) Trigger.old;
		this.oldOppLineItemMap = (Map<Id, OpportunityLineItem>) Trigger.oldMap;
		this.newOppLineItemMap = (Map<Id, OpportunityLineItem>) Trigger.newMap;
		DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
	}
    

	public override void beforeInsert() {
		// Assign 100% discount to 5 opp types. 
		// Since we store the opp results in a static variable, we only execute one SOQL statement, 
		// regardless of how many times the method is run.
		System.debug('CPU limit before beforeInsertOperation for OpportunityLineItemTrigger: ' +Limits.getCpuTime());
		OpportunityLineItemHelper.setDiscountForOppType(newOppLineItemList, 100);
		OpportunityLineItemHelper.beforeUpdateUpkeep(newOppLineItemList, newOppLineItemMap, oldOppLineItemMap);
		OpportunityLineItemHelper.salesPriceUpdateForRenewalLines(newOppLineItemList);
		System.debug('CPU limit after beforeInsertOperation for OpportunityLineItemTrigger: ' + Limits.getCpuTime());
	}

	public override void beforeDelete() {
		//6/24/25 Vijaychandra AMARANENI --START--  (GTMS-28353): Added this method to create or void Channel Relationship records based on OpportunityLineItem data
		OpportunityLineItemHelper.createOrVoidChannelRelationship(oldOppLineItemMap, true);
		//6/24/25 Vijaychandra AMARANENI --END--  (GTMS-28353): Added this method to create or void Channel Relationship records based on OpportunityLineItem data
	}

	public override void beforeUpdate() {
		System.debug('CPU limit before beforeUpdateOperation for OpportunityLineItemTrigger: ' + Limits.getCpuTime());
		OpportunityLineItemHelper.beforeUpdateUpkeep(newOppLineItemList, newOppLineItemMap, oldOppLineItemMap);
		System.debug('CPU limit after beforeUpdateOperation for OpportunityLineItemTrigger: ' + Limits.getCpuTime());
	}

	public override void afterInsert() {
        //6/24/25 Vijaychandra AMARANENI --START--  (GTMS-28353): Added this method to create or void Channel Relationship records based on OpportunityLineItem data
		OpportunityLineItemHelper.createOrVoidChannelRelationship(newOppLineItemMap, false);
		//6/24/25 Vijaychandra AMARANENI --END--  (GTMS-28353): Added this method to create or void Channel Relationship records based on OpportunityLineItem data
        //GTMS-13327 - Cross Sell Purchase type logic
		//GTMS-13327 - Edit on
		   
        for(OpportunityLineItem oppLineItem : newOppLineItemList){
            if(oppLineItem.Opportunity_Type__c == 'Revenue Opportunity' || oppLineItem.Opportunity_Type__c == 'Remorse Refund'  ){
                renewalOrRemorseRefundLst.add(oppLineItem);
            }
        }
        system.debug('renewalOrRemorseRefundLst:'+renewalOrRemorseRefundLst);
        if(!renewalOrRemorseRefundLst.isEmpty()){
           String JsonNewOppList = JSON.serialize(renewalOrRemorseRefundLst);
            OpportunityLineItemHelper.updateAccountPROSkuFields(JsonNewOppList,null);
        }
       
        //GTMS-13327 - Edit End   
		
        //OpportunityLineItemHelper.updateAccountPROSkuFields(newOppLineItemList);
	}
    

	public override void afterUpdate() {
	}

	public override void afterDelete() {
        String JsonOldOppList = JSON.serialize(oldOppLineItemList);
		OpportunityLineItemHelper.updateAccountPROSkuFields(null,JsonOldOppList);
	}

	public override void afterUndelete() {
	}

	public override void publishDMLs() {
		uow = DMLWrapper.uow;
		DMLWrapper.publishDML(uow);
	}
}