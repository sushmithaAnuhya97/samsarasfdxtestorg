/* 
 * Created By : Groundswell - Suman Kundu
 * @Date September 10, 2021
 *
 * @description : This Quote Trigger Handler is created as part of the Audit Optimization. It will only call Quote Service Class
 */  
public class GS_SBQQQuoteTriggerHandler extends TriggerHandler{
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        SBQQ__QuoteLine__c.SObjectType,
        Opportunity.SObjectType,
        Async_Request__c.SObjectType,
        Account.SObjectType
    };
    private Map<Id, SBQQ__Quote__c > oldSbqqQuoteMap;
    private Map<Id, SBQQ__Quote__c > newSbqqQuoteMap;
    private List<SBQQ__Quote__c > newSbqqQuoteList;
    private List<SBQQ__Quote__c > oldSbqqQuoteList;
    Private UnitOfWork uow ;
    Private GS_SBQQQuoteService.TriggerContext quoteTriggerContext;
    public GS_SBQQQuoteTriggerHandler() {
        this.oldSbqqQuoteMap = (Map<Id, SBQQ__Quote__c>) Trigger.oldMap;
        this.newSbqqQuoteMap = (Map<Id, SBQQ__Quote__c>) Trigger.newMap;
        this.newSbqqQuoteList = (List<SBQQ__Quote__c>) Trigger.new;
        this.oldSbqqQuoteList = (List<SBQQ__Quote__c>) Trigger.old;
        quoteTriggerContext = new GS_SBQQQuoteService.TriggerContext(newSbqqQuoteList, oldSbqqQuoteList, newSbqqQuoteMap, oldSbqqQuoteMap);
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }
    
    public override void beforeInsert() {
        Long startTime, endTime;
        try {
            startTime = DateTime.now().getTime();
            thisSamsaraLoggerService.logger.logTrace('Entering in Quote Trigger Before Insert');
            quoteTriggerContext.handleBeforeInsertOperations();
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Quote Trigger Before Insert::', new SamsaraLoggerObjectMVP(ex, newSbqqQuoteList));
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
            thisSamsaraLoggerService.logger.logTrace('Entering in Quote Trigger After Insert');
            quoteTriggerContext.handleAfterInsertOperations();
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Quote Trigger After Insert::',new SamsaraLoggerObjectMVP(ex, newSbqqQuoteList));
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
            thisSamsaraLoggerService.logger.logTrace('Entering in Quote Trigger Before Update');
            quoteTriggerContext.handleBeforeUpdateOperations();
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Quote Trigger Before Update::', new SamsaraLoggerObjectMVP(ex, newSbqqQuoteMap.keySet()));
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
            thisSamsaraLoggerService.logger.logTrace('Entering in Quote Trigger After Update');
            quoteTriggerContext.handleAfterUpdateOperations();
        } catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Quote Trigger After Update::', new SamsaraLoggerObjectMVP(ex, newSbqqQuoteMap.keySet()));
            throw ex;
        } finally {
            endTime = DateTime.now().getTime();
            System.debug('****AfterUpdate> '+(endTime - startTime)+' ms');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        system.debug('uow****'+uow);
        DMLWrapper.publishDML();
    }

}