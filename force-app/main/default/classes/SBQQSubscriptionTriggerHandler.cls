/**
 * @description       : 
 * @author            : Navees Ahmed
 * @group             : 
 * @last modified on  : 01-11-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class SBQQSubscriptionTriggerHandler  extends TriggerHandler {
    private Map<Id, SBQQ__Subscription__c> oldSBQQSubscriptionMap;
    private Map<Id, SBQQ__Subscription__c> newSBQQSubscriptionMap;
    private List<SBQQ__Subscription__c> newSBQQSubscriptionList;
    public static List<Schema.SObjectType> dmlSObjects = new List<Schema.SObjectType>{
        SBQQ__Subscription__c.SObjectType,
        Contract.SObjectType,
        Account.SObjectType
    };
    private UnitOfWork uow ;
    SBQQSubscriptionHelper sbqqSubscriptionHelper ;

    public SBQQSubscriptionTriggerHandler() {
        this.oldSBQQSubscriptionMap = (Map<Id, SBQQ__Subscription__c>) Trigger.oldMap;
        this.newSBQQSubscriptionMap = (Map<Id, SBQQ__Subscription__c>) Trigger.newMap;
        this.newSBQQSubscriptionList = (List<SBQQ__Subscription__c>) Trigger.new;

        DMLWrapper.intializeUnitOfWork(dmlSObjects);
        sbqqSubscriptionHelper = new SBQQSubscriptionHelper();
    }
    public override void beforeInsert() {
        //sbqqSubscriptionHelper.beforeInsert(this.newSBQQSubscriptionList);
        //sbqqSubscriptionHelper.handleDealComponentProducts(this.newSBQQSubscriptionList);
        sbqqSubscriptionHelper.beforeInsertUpdate(this.newSBQQSubscriptionList);
    }

    public override void beforeUpdate() {
        sbqqSubscriptionHelper.beforeInsertUpdate(this.newSBQQSubscriptionList);
    }    
    public override void afterInsert() {
        sbqqSubscriptionHelper.updateRelatedContract(this.newSBQQSubscriptionList);
        sbqqSubscriptionHelper.populateContractRenewableACV(this.newSBQQSubscriptionList,null);
    }

    public override void afterUpdate() {
        sbqqSubscriptionHelper.updateRelatedContract(this.newSBQQSubscriptionList);
        sbqqSubscriptionHelper.populateContractRenewableACV(this.newSBQQSubscriptionList,this.oldSBQQSubscriptionMap);
    }

    public override void afterdelete() {
        sbqqSubscriptionHelper.updateRelatedContract(this.oldSBQQSubscriptionMap.values());
    }

    public override void afterUndelete() {
        sbqqSubscriptionHelper.updateRelatedContract(this.newSBQQSubscriptionList);
    }

    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML();
    }    
}