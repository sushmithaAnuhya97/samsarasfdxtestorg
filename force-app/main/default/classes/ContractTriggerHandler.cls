/**
 * Created by vikasmishra on 2020-10-20.
 * Aug-23-2022 Rajesh GTMS-6067 - Commented the method call activateContractAfterInsert() and used platform events to activate contract
 * Nov-15-2022 Rajesh GTMS-10451. Uncommented the method call activateContractAfterInsert()
 */

public with sharing class ContractTriggerHandler extends TriggerHandler {
    private Map<Id, Contract> oldContractMap;
    private Map<Id, Contract> newContractMap;
    private List<Contract> newContractList;
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Account.SObjectType,
        Contract.SObjectType
    };
    private UnitOfWork uow ;
    ContractHelper contractHelper ;

    public ContractTriggerHandler() {
        this.oldContractMap = (Map<Id, Contract>) Trigger.oldMap;
        this.newContractMap = (Map<Id, Contract>) Trigger.newMap;
        this.newContractList = (List<Contract>) Trigger.new;

        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        contractHelper = new ContractHelper();

    }

    public override void afterInsert() {
        contractHelper.calculateAllRollUpsToAccount(newContractList, null);
        contractHelper.activateContractAfterInsert(newContractList); //GTMS-6067
        
        // GTMS-28592: Check toggle before processing expiring next quarter
        if (System.Label.Contract_Expiring_Next_Quarter_Enabled == 'true') {
            contractHelper.processExpiringNextQuarter(newContractList);
        }
    }
    //GTMS-14430 Abu Saleh Khan --> Added Null as a Parameter in beforeInsertUpdate method
    public override void beforeInsert() {
        contractHelper.beforeInsertUpdate(newContractList,null,null);
        contractHelper.beforeInsert(newContractList);
    }    
	//GTMS-14430 Abu Saleh Khan --> Added Null as a Parameter in beforeInsertUpdate method
    public override void beforeUpdate() {
        contractHelper.beforeInsertUpdate(newContractList,oldContractMap,newContractMap);
        contractHelper.runSubscriptionRollup(this.newContractMap);
    }

    public override void afterUpdate() {
        contractHelper.EndDatePushtoWebstore(newContractList, oldContractMap);
        contractHelper.afterUpdate(newContractList, oldContractMap,newContractMap);
        contractHelper.calculateAllRollUpsToAccount(newContractList, oldContractMap);
        
        // GTMS-28592: Check toggle before processing expiring next quarter
        if (System.Label.Contract_Expiring_Next_Quarter_Enabled == 'true') {
            contractHelper.processExpiringNextQuarter(newContractList, oldContractMap);
        }
    }
        

    public override void afterdelete() {
        contractHelper.calculateAllRollUpsToAccount(oldContractMap.values(), null);
        
        // GTMS-28592: Check toggle before processing expiring next quarter
        if (System.Label.Contract_Expiring_Next_Quarter_Enabled == 'true') {
            contractHelper.processExpiringNextQuarter(oldContractMap.values());
        }
    }

    public override void afterUndelete() {
        contractHelper.calculateAllRollUpsToAccount(newContractList, null);
        
        // GTMS-28592: Check toggle before processing expiring next quarter
        if (System.Label.Contract_Expiring_Next_Quarter_Enabled == 'true') {
            contractHelper.processExpiringNextQuarter(newContractList);
        }
    }

    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
}