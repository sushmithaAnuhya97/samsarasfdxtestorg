public class TaskTriggerHandler extends TriggerHandler{
	private List<Task> newTaskList;
	private Map<Id, Task> newTaskMap;
	private Map<Id, Task> oldTaskMap;
	private static boolean isEnabled;
	public static boolean alreadyRan = false;
	public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
			Call_log__c.SobjectType,
			CampaignMember.SobjectType,
			Account.SobjectType,
			Contact.SObjectType
	};
	private UnitOfWork uow;

/* 	public static boolean isEnabled() {
        if (isEnabled == true) {
            return true;
        }
        List<Trigger_Setting__mdt> taskTriggerSettings = [SELECT Enabled__c FROM Trigger_Setting__mdt WHERE MasterLabel = 'Task' LIMIT 1];
        if (taskTriggerSettings.isEmpty()) {
            return true;
        }
        return taskTriggerSettings.get(0).Enabled__c;
    }
 */
	public TaskTriggerHandler() {
		this.newTaskList = (List<Task>) Trigger.new;
		this.newTaskMap = (Map<Id, Task>) Trigger.newMap;
		this.oldTaskMap = (Map<Id, Task>) Trigger.oldMap;
		DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
	}

	public override void beforeInsert() {
		TaskHelper.beforeInsertUpdateUpkeep(newTaskList);		
		TaskHelper.handleTaskUpdate(newTaskList);
	}

	public override void beforeUpdate() {
		TaskHelper.beforeInsertUpdateUpkeep(newTaskList);
		TaskHelper.handleTaskUpdate(newTaskList);
	}

	//
	public override void afterInsert() {
		TaskHelper.calculateIRTCampaign(newTaskList);
		TaskHelper.salesLoftToContact(newTaskList);

		//@author Groundswell - Vikasm - vikas@gscloudsolutions.com
		//@date 2020-08-28
		//GTMS-1497
		TaskHelper.calculateAllRollUpsToContact(newTaskList, null);
		TaskHelper.calculateAllRollUpsToAccount(newTaskList, null);

		TaskHelper.updateContacts();
		TaskHelper.updateAccounts();
	}

	public override void afterUpdate() {
		if (!alreadyRan) {
			TaskHelper.calculateIRTCampaign(newTaskList);

			//@author Groundswell - Vikasm - vikas@gscloudsolutions.com
			//@date 2020-08-28
			//GTMS-1497
			TaskHelper.calculateAllRollUpsToContact(newTaskList, oldTaskMap);
			TaskHelper.calculateAllRollUpsToAccount(newTaskList, oldTaskMap);
			TaskHelper.updateContacts();
			TaskHelper.updateAccounts();
			alreadyRan = true;
		}

	}

	public override void beforeDelete(){
		TaskHelper.beforeDeleteAfterUndeleteUpkeep(oldTaskMap.values());

	}

	/**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-08-28
	* Not yet deployed for Production
	* GTMS-1497
    */
	public override void afterDelete() {
		TaskHelper.calculateAllRollUpsToContact(oldTaskMap.values(), null);
		TaskHelper.calculateAllRollUpsToAccount(oldTaskMap.values(), null);
	}

	/**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-08-28
	* Not yet deployed for Production
	* GTMS-1497
    */
	public override void afterUndelete() {
		TaskHelper.beforeDeleteAfterUndeleteUpkeep(newTaskList);
		TaskHelper.calculateAllRollUpsToContact(newTaskList, null);
		TaskHelper.calculateAllRollUpsToAccount(newTaskList, null);

	}

	/**
   * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
   * @date 2020-09-04
   * Not yet deployed for Production
   * GTMS-1471
   */
	public override void publishDMLs() {
		uow = DMLWrapper.uow;
		DMLWrapper.publishDML(uow);
	}
}