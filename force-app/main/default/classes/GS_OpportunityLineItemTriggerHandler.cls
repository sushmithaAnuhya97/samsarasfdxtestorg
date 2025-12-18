/* 
 * Created By : Groundswell - Suman Kundu
 * @Date September 21, 2021
 *
 * @description : This Opportunity Line Item Trigger Handler is created as part of the Audit Optimization. 
 * It will only call Opportunity Line Item Service Class
 */  
public class GS_OpportunityLineItemTriggerHandler extends TriggerHandler{
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Opportunity.SObjectType,
        Async_Request__c.SObjectType
    };
    private Map<Id, OpportunityLineItem > oldOliMap;
    private Map<Id, OpportunityLineItem > newOliMap;
    private List<OpportunityLineItem > newOliList;
    private List<OpportunityLineItem > oldOliList;
    Private UnitOfWork uow ;
    Private GS_OpportunityLineItemService.TriggerContext oliTriggerContext;
    public GS_OpportunityLineItemTriggerHandler() {
        this.oldOliMap = (Map<Id, OpportunityLineItem>) Trigger.oldMap;
        this.newOliMap = (Map<Id, OpportunityLineItem>) Trigger.newMap;
        this.newOliList = (List<OpportunityLineItem>) Trigger.new;
        this.oldOliList = (List<OpportunityLineItem>) Trigger.old;
        oliTriggerContext = new GS_OpportunityLineItemService.TriggerContext(newOliList, oldOliList, newOliMap, oldOliMap);
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
	}
    
    public override void beforeInsert() {
        Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
			thisSamsaraLoggerService.logger.logTrace('Entering in OpportunityLineItem Trigger Before Insert');
            oliTriggerContext.handleBeforeInsertOperations();
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in OpportunityLineItem Trigger Before Insert::', new SamsaraLoggerObjectMVP(ex, newOliList));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****BeforeInsert> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
    
    public override void afterInsert(){
        Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
			thisSamsaraLoggerService.logger.logTrace('Entering in OpportunityLineItem Trigger After Insert');
            oliTriggerContext.handleAfterInsertOperations();
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in OpportunityLineItem Trigger After Insert::',new SamsaraLoggerObjectMVP(ex, newOliList));
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
			thisSamsaraLoggerService.logger.logTrace('Entering in OpportunityLineItem Trigger Before Update');
            oliTriggerContext.handleBeforeUpdateOperations();
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in OpportunityLineItem Trigger Before Update::', new SamsaraLoggerObjectMVP(ex, newOliMap.keySet()));
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
			thisSamsaraLoggerService.logger.logTrace('Entering in OpportunityLineItem Trigger After Update');
            oliTriggerContext.handleAfterUpdateOperations();
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in OpportunityLineItem Trigger After Update::', new SamsaraLoggerObjectMVP(ex, newOliMap.keySet()));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****AfterUpdate> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    public override void afterDelete() {
        Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
			thisSamsaraLoggerService.logger.logTrace('Entering in OpportunityLineItem Trigger After Delete');
            oliTriggerContext.handleAfterDeleteOperations();
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in OpportunityLineItem Trigger After Delete::', new SamsaraLoggerObjectMVP(ex, newOliMap.keySet()));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****AfterDelete> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    /*public override void afterUndelete() {
		Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
			thisSamsaraLoggerService.logger.logTrace('Entering in OpportunityLineItem Trigger After Undelete');
            oliTriggerContext.handleAfterUndeleteOperations();
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in OpportunityLineItem Trigger After Undelete::', new SamsaraLoggerObjectMVP(ex, newOliMap.keySet()));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****AfterDelete> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }
	}*/

    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
}