public class LeadTriggerHandler extends TriggerHandler{
	private List<Lead> newLeadList;
	private Map<Id, Lead> oldLeadMap;
	private Map<Id, Lead> newLeadMap;
	private UnitOfWork uow;
	public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
			Account.SObjectType
	};

	public LeadTriggerHandler() {
		this.newLeadList = (List<Lead>) Trigger.new;
		this.newLeadMap = (Map<Id, Lead>) Trigger.newMap;
		this.oldLeadMap = (Map<Id, Lead>) Trigger.oldMap;
		DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
	}

	public override void beforeInsert() {
		LeadHelper.beforeInsertOnly(newLeadList);
		LeadHelper.beforeInsertandUpdate(oldLeadMap, newLeadList);
	}

	public override void beforeUpdate() {
		LeadHelper.beforeInsertandUpdate(oldLeadMap, newLeadList);
	}
	public override void afterInsert(){
		LeadHelper.acctHashtag(oldLeadMap, newLeadList);
		LeadHelper.leadToAccount(oldLeadMap, newLeadList, false);
		LeadHelper.updateAccounts();
	}

	public override void afterUpdate() {
		LeadHelper.acctHashtag(oldLeadMap, newLeadList);
		LeadHelper.leadToAccount(oldLeadMap, newLeadList, true);
		LeadHelper.updateAccounts();
	}

	public override void publishDMLs() {
		uow = DMLWrapper.uow;
		DMLWrapper.publishDML(uow);
	}
}