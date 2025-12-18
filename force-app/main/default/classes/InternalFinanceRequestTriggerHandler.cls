public class InternalFinanceRequestTriggerHandler extends TriggerHandler
{
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>
    {
        	Internal_Finance_Approval_Request__c.SObjectType,    
        	Opportunity.SObjectType, 
            Account.SObjectType,
            User.SObjectType,
            SBQQ__Quote__c.SObjectType
    };
        
    private Map<Id, Internal_Finance_Approval_Request__c> OldRequestMap;
    private Map<Id, Internal_Finance_Approval_Request__c> newRequestMap;
    private List<Internal_Finance_Approval_Request__c> newRequestList;
    private InternalFinanceRequestHelper requestHelper;
    Private UnitOfWork uow ;
    
    
    public InternalFinanceRequestTriggerHandler() 
    {
        requestHelper = new InternalFinanceRequestHelper();
        this.OldRequestMap = (Map<Id, Internal_Finance_Approval_Request__c>) Trigger.oldMap;
        this.newRequestMap = (Map<Id, Internal_Finance_Approval_Request__c>) Trigger.newMap;
        this.newRequestList = (List<Internal_Finance_Approval_Request__c>) Trigger.new;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);

    }
    
    public override void beforeInsert() 
    {
        requestHelper.beforeInsertOnly(newRequestList);
    }

    public override void afterInsert() 
    {
        requestHelper.afterInsertOrUpdate(newRequestList, oldRequestMap);
    }

    public override void beforeUpdate() 
    {
        
    }

    public override void afterUpdate() 
    {
        requestHelper.afterInsertOrUpdate(newRequestList, oldRequestMap);
    }

    public override void beforeDelete() 
    {
        
    }
    
    public override void afterdelete() 
    {
        
    }

    public override void afterUndelete() 
    {
        
    }

    public override void publishDMLs() 
    {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
}