/*
 * 
 * 13-April-2022 - Rajesh :- GTMS-6625 Move Last_Contacted__c field update on Contact & Account to batch
 * As part of this story we commented the method call updateLastContacted.
 */
public class GS_TaskTriggerHandler extends TriggerHandler{
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();

    private List<Task> newTaskList;
    private Map<Id, Task> newTaskMap;
    private Map<Id, Task> oldTaskMap;
    private static boolean isEnabled;
    public static GS_TaskCacheService cacheService = new GS_TaskCacheService();
    public GS_TaskService taskService = new GS_TaskService(cacheService);
    public static boolean alreadyRan = false;
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
            Call_log__c.SobjectType,
            CampaignMember.SobjectType,
            Account.SobjectType,
            Contact.SObjectType,
            Case.SObjectType
    };
    private UnitOfWork uow;


    public GS_TaskTriggerHandler() {
        this.newTaskList = (List<Task>) Trigger.new;
        this.newTaskMap = (Map<Id, Task>) Trigger.newMap;
        this.oldTaskMap = (Map<Id, Task>) Trigger.oldMap;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }

    public override void beforeInsert() {
        Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
            thisSamsaraLoggerService.logger.logTrace('Entering in Task Trigger Before Insert');

            taskService.prepopulateFields(newTaskList, null);       
            taskService.handleTaskUpdate(newTaskList);
            //GTMS-6625 changes. Commented below line
            //taskService.updateLastContacted();
            taskService.runInsertWorkflows(newTaskList);
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Task Trigger Before Insert::', new SamsaraLoggerObjectMVP(ex, newTaskList));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****BeforeInsert> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    //
    public override void afterInsert() {
        Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
            thisSamsaraLoggerService.logger.logTrace('Entering in Task Trigger After Insert');
           // taskService.handleContactStatusUpdate(newTaskList, oldTaskMap);  //GTMS-25398
            taskService.calculateIRTCampaign(newTaskList);
            taskService.salesLoftToContact(newTaskList);
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Task Trigger After Insert::',new SamsaraLoggerObjectMVP(ex, newTaskList));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****AfterInsert> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    public override void beforeUpdate() {
        Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
            thisSamsaraLoggerService.logger.logTrace('Entering in Task Trigger Before Update');

            taskService.prepopulateFields(newTaskList, oldTaskMap);
            taskService.handleTaskUpdate(newTaskList);
            taskService.runUpdateWorkflows(newTaskList, oldTaskMap);
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Task Trigger Before Update::', new SamsaraLoggerObjectMVP(ex, newTaskMap.keySet()));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****BeforeUpdate> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }


    public override void afterUpdate() {
        Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
            thisSamsaraLoggerService.logger.logTrace('Entering in Task Trigger After Update');
           // taskService.handleContactStatusUpdate(newTaskList, oldTaskMap);  //GTMS-25398
            taskService.calculateIRTCampaign(newTaskList);
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Task Trigger After Update::', new SamsaraLoggerObjectMVP(ex, newTaskMap.keySet()));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****AfterUpdate> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }

    }

    // Logics for before delete, after delete and undelete removed as the only meaningful update would be the rollups, that are now moved to the batch.
    /* public override void beforeDelete(){
        Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
            thisSamsaraLoggerService.logger.logTrace('Entering in Task Trigger Before Delete');

            taskService.beforeDeleteAfterUndeleteUpkeep(oldTaskMap.values());
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Task Trigger Before Delete::',new SamsaraLoggerObjectMVP(ex, newTaskList));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****BeforeDelete> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }

    } */

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-08-28
    * Not yet deployed for Production
    * GTMS-1497
    */
    /* public override void afterDelete() {
        Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
            thisSamsaraLoggerService.logger.logTrace('Entering in Task Trigger After Delete');

            /* taskService.calculateAllRollUpsToContact(oldTaskMap.values(), null);
            taskService.calculateAllRollUpsToAccount(oldTaskMap.values(), null); /
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Task Trigger After Delete::',new SamsaraLoggerObjectMVP(ex, newTaskList));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****AfterDelete> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }
    } */

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-08-28
    * Not yet deployed for Production
    * GTMS-1497
    /
    public override void afterUndelete() {

        Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
            thisSamsaraLoggerService.logger.logTrace('Entering in Task Trigger After Undelete');

            taskService.beforeDeleteAfterUndeleteUpkeep(newTaskList);

            /* taskService.calculateAllRollUpsToContact(newTaskList, null);
            taskService.calculateAllRollUpsToAccount(newTaskList, null); /
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Task Trigger After Undelete::',new SamsaraLoggerObjectMVP(ex, newTaskList));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****AfterUndelete> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }
        

    }
    */

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