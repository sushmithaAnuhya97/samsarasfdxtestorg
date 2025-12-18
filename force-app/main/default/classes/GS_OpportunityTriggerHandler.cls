/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 06, 2021
*
* @description : This Opportunity Handler is created as part of the Audit Optimization. It will only call Opportunity Service Class
* SFA-11
*
**/
public class GS_OpportunityTriggerHandler extends TriggerHandler{
    private Map<Id, Opportunity> oldOpportunityMap;
    private Map<Id, Opportunity> newOpportunityMap;
    private List<Opportunity> newOpportunityList;
    private List<Opportunity> oldOpportunityList;
    private Set<Id> OldOpportunitySet;
    public static Boolean alreadyRan = false;
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Opportunity.SObjectType,
        OpportunityLineItem.SObjectType,
        Contact.SobjectType,
        Quota_Opportunity__c.SObjectType,
        ADR_Transfer_Log__c.SobjectType,
        Account.SObjectType,
        User.SObjectType,
        Contract.SObjectType,
        SBQQ__Quote__c.SObjectType,
        Async_Request__c.SobjectType
    };
    
    Private UnitOfWork uow ;
    private GS_OpportunityService.OpportunityTriggerContext oppTrigContext;
    
    public GS_OpportunityTriggerHandler() {
        this.oldOpportunityMap = (Map<Id, Opportunity>) Trigger.oldMap;
        this.newOpportunityMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.newOpportunityList = (List<Opportunity>) Trigger.new;
        this.oldOpportunityList = (List<Opportunity>) Trigger.old;
		
        oppTrigContext = new GS_OpportunityService.OpportunityTriggerContext();
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }

    public override void beforeInsert() {
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Opportunity Trigger Before Insert');
            oppTrigContext.runBeforeInsert(this.newOpportunityList);
        }catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Opportunity Trigger Before Insert::', new SamsaraLoggerObjectMVP(
                ex, this.newOpportunityList
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
        
    }
    
    public override void afterInsert() {
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Opportunity Trigger After Insert');
            oppTrigContext.runAfterInsert(this.newOpportunityList);
        }catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Opportunity Trigger After Insert::', new SamsaraLoggerObjectMVP(
                ex, this.newOpportunityList
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    public override void beforeUpdate() {
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Opportunity Trigger Before Update');
            oppTrigContext.runBeforeUpdate(this.newOpportunityList, this.oldOpportunityMap);
        }catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Opportunity Trigger Before Update::', new SamsaraLoggerObjectMVP(
                ex, this.newOpportunityList
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
        
    }

    public override void afterUpdate() {
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Opportunity Trigger After Update');
            oppTrigContext.runAfterUpdate(this.newOpportunityList, this.oldOpportunityMap);
        }catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Opportunity Trigger After Update::', new SamsaraLoggerObjectMVP(
                ex, this.newOpportunityList
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
        
    }

    public override void beforeDelete() {
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Opportunity Trigger Before Delete');
            oppTrigContext.runBeforeDelete(this.oldOpportunityMap);
        }catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Opportunity Trigger Before Delete::', new SamsaraLoggerObjectMVP(
                ex, this.oldOpportunityMap.keySet()
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-08-31
    * Not yet deployed for Production
    * GTMS-1471
    */
    public override void afterdelete() {
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Opportunity Trigger After Delete');
            oppTrigContext.runAfterdelete(this.oldOpportunityMap);
        }catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Opportunity Trigger After Delete::', new SamsaraLoggerObjectMVP(
                ex, this.oldOpportunityMap.keySet()
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-08-31
    * Not yet deployed for Production
    * GTMS-1471
    */
    public override void afterUndelete() {
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Opportunity Trigger After UnDelete');
            oppTrigContext.runAfterUndelete(this.newOpportunityList);
        }catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Opportunity Trigger After UnDelete::', new SamsaraLoggerObjectMVP(
                ex, this.newOpportunityList
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    public override void publishDMLs() {
        thisSamsaraLoggerService.logger.logTrace('Exiting Opportunity Trigger Context');
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
}