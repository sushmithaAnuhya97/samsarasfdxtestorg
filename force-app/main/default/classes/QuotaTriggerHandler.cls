/**
* 
* 06/14/21 Lavanya - (GTMS-3540) beforeInsert, beforeUpdate (Added an additional Boolean variable)
* 9/19/2022 Siddharth Kumar Mishra - (GTMS-9362) process builder conversion to Trigger('Set the Quota on the User' to 'quotaTrigger')
* 02/18/2025 Ravindra - (GTMS-25663) Set Trial+Quota on User record
**/

public class QuotaTriggerHandler extends TriggerHandler {
    private List<Quota__c> newQuotaList;
    private Map<Id, Quota__c> oldQuotaMap;
    private Map<Id, Quota__c> newQuotaMap;
    
    private static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Account.SObjectType,
            Quota_Junction__c.SObjectType
            };
                private UnitOfWork uow;
    private QuotaDefaults quotaDefaults;
    
    public QuotaTriggerHandler() {
        this.newQuotaList = (List<Quota__c>) Trigger.new;
        this.oldQuotaMap = (Map<Id, Quota__c>) Trigger.oldMap;
        this.newQuotaMap = (Map<Id, Quota__c>) Trigger.newMap;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        this.quotaDefaults = new QuotaDefaults(this.newQuotaList);
    }
    
    public override void afterInsert() {
        QuotaHelper.quotaJunctionCreation(newQuotaList);
        
        //GTMS-9362
        List<Quota__c> newADRQuotaList = new List<Quota__c>();
        List<Id> newADRQuotaIdList = new List<Id>();        
        List<Quota__c> newAEQuotaList = new List<Quota__c>();
        List<Id> newAEQuotaIdList = new List<Id>();
        Set<Id> trialQuotaSetIds = new Set<Id>();
        for(Quota__c quota : this.newQuotaList)
        {
            if(quota.ADR_Quota__c != null && (quota.Quota__c == null || quota.Quota__c == 0))
            {
                //newADRQuotaList.add(quota);
                newADRQuotaIdList.add(quota.Id);
            }
            else if(quota.Quota__c != null && (quota.ADR_Quota__c == null || quota.Quota__c == 0))
            {
                //newAEQuotaList.add(quota);
                newAEQuotaIdList.add(quota.Id);
            }
            if(quota.Trial_Quota__c!=null && quota.Fiscal_Period_End_Date__c!=null && quota.Fiscal_Period_Start_Date__c!=null && (System.today()<=quota.Fiscal_Period_End_Date__c) && (System.today()>=quota.Fiscal_Period_Start_Date__c)){
                trialQuotaSetIds.add(quota.Id);					//GTMS-25663
            }
        }
        if(!newADRQuotaIdList.isEmpty())
        {
            QuotaHelper.setNewADRQuotaOnUser(newADRQuotaIdList);
        }
        else if(!newAEQuotaIdList.isEmpty())
        {
            QuotaHelper.setNewAEQuotaOnUser(newAEQuotaIdList);            
        }
        if(!trialQuotaSetIds.isEmpty()){						//GTMS-25663
            QuotaHelper.setTrialQuotaOnUser(trialQuotaSetIds);
        }
    }
    
    public override void beforeInsert() {
        quotaDefaults.setDefaults(newQuotaList);//GTMS - 11971
        for (Quota__c quota : (List<Quota__c>) Trigger.new) {
            this.quotaDefaults.onApplyDefaults(quota,null);
        }
    }
    
    public override void beforeUpdate() {
		quotaDefaults.setDefaults(newQuotaList); //GTMS - 11971       
        for (Quota__c quota : (List<Quota__c>) Trigger.new) {
            Quota__c oldQuota = (quota__c)Trigger.oldMap.get(quota.Id);
            this.quotaDefaults.onApplyDefaults(quota,oldQuota);
        }
    }
    
    public override void afterUpdate() { 
        //GTMS-9362
        List<Id> AEQuotaChangeIDList = new List<Id>();
        List<Id> ADRQuotaChangeIDList = new List<Id>();
        Set<Id> trialQuotaSetIds = new Set<Id>();
        for (Quota__c quota : (List<Quota__c>) Trigger.new) 
        {
            if(quota.Quota__c!=null && (quota.ADR_Quota__c == null || quota.ADR_Quota__c == 0) && ((this.oldQuotaMap.get(quota.id).Quota__c!=quota.Quota__c)||(this.oldQuotaMap.get(quota.id).CurrencyIsoCode!=quota.CurrencyIsoCode)))
            {
                AEQuotaChangeIDList.add(quota.Id);                
            }
            else if(quota.ADR_Quota__c!=null && (quota.Quota__c == null || quota.Quota__c == 0) && ((this.oldQuotaMap.get(quota.id).ADR_Quota__c!=quota.ADR_Quota__c)||(this.oldQuotaMap.get(quota.id).CurrencyIsoCode!=quota.CurrencyIsoCode)))
            {
                ADRQuotaChangeIDList.add(quota.Id);
            }
            if(quota.Trial_Quota__c!=null && quota.Fiscal_Period_End_Date__c!=null && quota.Fiscal_Period_Start_Date__c!=null && (this.oldQuotaMap.get(quota.id).Trial_Quota__c!=quota.Trial_Quota__c) && (System.today()<=quota.Fiscal_Period_End_Date__c) && (System.today()>=quota.Fiscal_Period_Start_Date__c)){
                trialQuotaSetIds.add(quota.Id);			//GTMS-25663
            }
        }
        if(!AEQuotaChangeIDList.isEmpty())
        {
            QuotaHelper.setChangedAEQuotaOnUser(AEQuotaChangeIDList);
        }
        else if(!ADRQuotaChangeIDList.isEmpty())
        {
            QuotaHelper.setChangedADRQuotaOnUser(ADRQuotaChangeIDList);
        }
        if(!trialQuotaSetIds.isEmpty()){					//GTMS-25663
            QuotaHelper.setTrialQuotaOnUser(trialQuotaSetIds);
        }
    }
    
    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
}