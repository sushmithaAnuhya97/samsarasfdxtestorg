/**
 * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
 * @date 2020-08-24
 * @lastModified 2020-08-25
 */
// * 12/02/22 Ranadheer - (GTMS-10171) Restricting recursions of trigger methods. Added decision box to all methods to check if that method ran already.
public with sharing class ADR_Transfer_LogTriggerHandler extends TriggerHandler 
{
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
                                                            Opportunity.SObjectType
                                                        };

    private List<ADR_Transfer_Log__c> newADRTransferList;
    private Map<Id, ADR_Transfer_Log__c> oldADRTransferMap;
    private Map<Id, ADR_Transfer_Log__c> newADRTransferMap;
    private UnitOfWork uow;
    private ADR_Transfer_LogHelper adrService;
    @TestVisible private static Integer maxRuns = 1;
    @TestVisible private static Map<String, Integer> methodsCalled = new Map<String, Integer>();

    public ADR_Transfer_LogTriggerHandler() 
    {
        this.newADRTransferList = (List<ADR_Transfer_Log__c>) Trigger.new;
        this.newADRTransferMap = (Map<Id, ADR_Transfer_Log__c>) Trigger.newMap;
        this.oldADRTransferMap = (Map<Id, ADR_Transfer_Log__c>) Trigger.oldMap;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        this.adrService = new ADR_Transfer_LogHelper();
    }
    
    public override void beforeInsert() 
    {   
        if (timesCalled('beforeInsert') < maxRuns){
            addCall('beforeInsert');
            adrService.copyTransferPoints(newADRTransferList);
        }    
    }

    public override void afterInsert() 
    {
        if (timesCalled('afterInsert') < maxRuns){
            addCall('afterInsert');
        adrService.rollupAdrOnOpportunity(newADRTransferList);
        }
    }

    public override void beforeUpdate() 
    {
        if (timesCalled('beforeUpdate') < maxRuns){
            addCall('beforeUpdate');
        }    
    }

    public override void afterUpdate() 
    {
        if (timesCalled('afterUpdate') < maxRuns){
            addCall('afterUpdate');
            adrService.rollupAdrOnOpportunity(oldADRTransferMap, newADRTransferList);
        }    
    }

    public override void afterDelete() 
    {
        if (timesCalled('afterDelete') < maxRuns){
            addCall('afterDelete');
            adrService.rollupAdrOnOpportunity(oldADRTransferMap.values());   
        }    
    }

    public override void afterUnDelete() 
    {
        if (timesCalled('afterUnDelete') < maxRuns){
            addCall('afterUnDelete');
            adrService.rollupAdrOnOpportunity(newADRTransferList);   
        }    
    }

    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }

    public static void resetAll() {
        methodsCalled = new Map<string, integer>();
    }


    public static integer timesCalled(String Input) {

        if (!methodsCalled.containsKey(Input)) {
            return 0;
        } else {
            return methodsCalled.get(Input);
        }

    }

    public static integer addCall(String Input) {

        if (!methodsCalled.containsKey(Input)) {
            methodsCalled.put(input, 1);
        } else {
            Integer i = methodsCalled.get(input) + 1;
            methodsCalled.put(input, i);
        }

        return methodsCalled.get(input);
    }    
   
}