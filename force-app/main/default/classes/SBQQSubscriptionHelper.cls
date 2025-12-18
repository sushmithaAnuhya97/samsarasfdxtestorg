/**
 * @description       : 
 * @author            : Navees Ahmed
 * @group             : 
 * @last modified on  : 01-11-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc * 
 * 02/10/2023 GTMS-10848 Siddharth Kumar Mishra: Contract_Renewable_ACV__C(on contract)  is calculated and evaluated everytime a new subscription is added according to the renewal price and the quantity on the Subscription
 * 09/03/2023 GTMS-12083 Siddharth Kumar Mishra: Changed Database.update() to DMLWrapper.doUpdate()
**/
public with sharing class SBQQSubscriptionHelper {
    public static Set<String> skippMethod=new Set<String>();
    //https://samsaradev.atlassian.net/browse/GTMS-10174
    //https://samsaradev.atlassian.net/browse/GTMS-10458
    public void beforeInsertUpdate(List<SBQQ__Subscription__c> sbqqSubscriptionList){
        if(sbqqSubscriptionList!=null && sbqqSubscriptionList.size()>0){
            Set<Id> qlIDs = new Set<Id>();
            Date createdDateFilter= Date.newinstance(2023, 1, 1);
            for(SBQQ__Subscription__c s:sbqqSubscriptionList){
                if(s.SBQQ__QuoteLine__c!=null && s.CreatedDate>=createdDateFilter && (s.SBQQ__SubscriptionStartDate__c != null || s.SBQQ__SubscriptionEndDate__c != null)){
                    qlIDs.add(s.SBQQ__QuoteLine__c);
                }
                if(s.SBQQ__BundledQuantity__c!=null){
                   s.SBQQ__BundledQuantity__c=null;
                }
            }
            if(qlIDs.size()>0){
                Map<Id,SBQQ__QuoteLine__c> mapQL=new Map<Id,SBQQ__QuoteLine__c>([Select Id,SBQQ__Quote__c,SBQQ__Quote__r.SBQQ__Opportunity2__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.License_Start_Date__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.License_End_Date__c From SBQQ__QuoteLine__c Where Id=:qlIDs]); 
                for(SBQQ__Subscription__c s:sbqqSubscriptionList){
                    if(s.SBQQ__QuoteLine__c!=null && mapQL.containsKey(s.SBQQ__QuoteLine__c)){
                        SBQQ__QuoteLine__c ql=mapQL.get(s.SBQQ__QuoteLine__c);
                        if(ql.SBQQ__Quote__r.SBQQ__Opportunity2__c!=null){
                            if(s.SBQQ__SubscriptionStartDate__c!=null){
                                s.SBQQ__SubscriptionStartDate__c=ql.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_Start_Date__c!=null?ql.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_Start_Date__c:s.SBQQ__SubscriptionStartDate__c;  
                            }
                            /*GTMS - 27220*/
                            if(s.SBQQ__SubscriptionEndDate__c != null){
                                if(Boolean.valueOf(System.Label.Nullify_SubscriptionEndDate)){
                                    s.SBQQ__SubscriptionEndDate__c = null;
                                } else {
                                    s.SBQQ__SubscriptionEndDate__c = ql.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_End_Date__c != null ? 
                                                                    ql.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_End_Date__c : 
                                                                    s.SBQQ__SubscriptionEndDate__c;   
                                }
                            }
                            /*GTMS - 27220 Ends*/
                        }
                        
                    }
                }               
            }              
        }
    }    
    //https://samsaradev.atlassian.net/browse/GTMS-7967
    public void updateRelatedContract(List<SBQQ__Subscription__c> sbqqSubscriptionList){
        if(sbqqSubscriptionList!=null && sbqqSubscriptionList.size()>0){
            Map<Id,Contract> mapContractsToBeUpdated=new Map<Id,Contract>();
            for(SBQQ__Subscription__c s:sbqqSubscriptionList){
                if(s.SBQQ__Contract__c!=null && !SBQQSubscriptionHelper.skippMethod.contains('updateRelatedContract'+s.SBQQ__Contract__c))
                {
                    mapContractsToBeUpdated.put(s.SBQQ__Contract__c,new Contract(Id=s.SBQQ__Contract__c));
                                                                                 //Contract_Renewable_ACV__c = (Contract_Renewable_ACV__c!=null?Contract_Renewable_ACV__c:0) + (s.SBQQ__Quantity__c*s.SBQQ__RenewalPrice__c)));
                    SBQQSubscriptionHelper.skippMethod.add('updateRelatedContract'+s.SBQQ__Contract__c);
                }
            }   
            if(mapContractsToBeUpdated.size()>0){
                DMLWrapper.doUpdate(mapContractsToBeUpdated.values());
                //DMLWrapper.publishDML();
            }
        }
    }
    
    //GTMS-10848
    public void populateContractRenewableACV(List<SBQQ__Subscription__c> sbqqSubscriptionList,Map<Id, SBQQ__Subscription__c> oldMap)
    {
        List<id> contractsIdsToUpdate = new List<id>();
        List<Contract> contractsToUpdate = new List<Contract>();
        Map<id,list<SBQQ__Subscription__c>> contractidSubListMap = new Map<id,list<SBQQ__Subscription__c>>();
        Map<id,contract> contractidContractMap = new Map<id,contract>();
        Set<id> contractIds = new Set<id>();
        //Map<id,Contract> contractsMap = new Map<id,Contract>();
        List<SBQQ__Subscription__c> allSubsList = new List<SBQQ__Subscription__c>();
        if(sbqqSubscriptionList!=null && sbqqSubscriptionList.size()>0)
        {
            for(SBQQ__Subscription__c s:sbqqSubscriptionList)
            {
                if(!contractIds.contains(s.SBQQ__Contract__c))
                {
                    contractIds.add(s.SBQQ__Contract__c);
                }
                
            }
            if(!contractIds.isEmpty())
            {
                Map<id,Contract> contractsMap = new Map<id,contract>([Select id,Contract_Renewable_ACV__c, Billing_Contract_Line_Id__c,Billing_Contract_Id__c from Contract where id in:contractIds]);
                allSubsList=[Select id,SBQQ__Quantity__c,SBQQ__RenewalPrice__c,SBQQ__CustomerPrice__c,SBQQ__Contract__c,Billing_Contract_Id__c, Billing_Contract_Line_Id__c, SBQQ__TerminatedDate__c from SBQQ__Subscription__c where SBQQ__Contract__c IN:contractIds order by createddate desc];
                for(SBQQ__Subscription__c s:allSubsList)
                {
                    if(contractidContractMap.containsKey(s.SBQQ__Contract__c))
                    {
                        contractidContractMap.get(s.SBQQ__Contract__c).Contract_Renewable_ACV__c+=(s.SBQQ__Quantity__c*(s.SBQQ__RenewalPrice__c!=null?s.SBQQ__RenewalPrice__c:(s.SBQQ__CustomerPrice__c!=null?s.SBQQ__CustomerPrice__c:0)));
                        
                    }
                    else
                    {
                        contractidContractMap.put(s.SBQQ__Contract__c,new contract(id = s.SBQQ__Contract__c,
                                                                                               Contract_Renewable_ACV__c=s.SBQQ__Quantity__c*(s.SBQQ__RenewalPrice__c!=null?s.SBQQ__RenewalPrice__c:(s.SBQQ__CustomerPrice__c!=null?s.SBQQ__CustomerPrice__c:0))));
                    }

                    contractidContractMap.get(s.SBQQ__Contract__c).Billing_Contract_Line_Id__c = s.Billing_Contract_Line_Id__c != null && s.SBQQ__TerminatedDate__c == null && s.SBQQ__Quantity__c > 0 ? s.Billing_Contract_Line_Id__c : contractidContractMap.get(s.SBQQ__Contract__c).Billing_Contract_Line_Id__c;                      
                    contractidContractMap.get(s.SBQQ__Contract__c).Billing_Contract_Id__c = s.Billing_Contract_Id__c != NULL &&  s.SBQQ__TerminatedDate__c == null && s.SBQQ__Quantity__c > 0 ? s.Billing_Contract_Id__c : contractidContractMap.get(s.SBQQ__Contract__c).Billing_Contract_Id__c;  
                }
                for(contract c:contractsMap.values())
                {
                    if(c.Contract_Renewable_ACV__c==contractidContractMap.get(c.id).Contract_Renewable_ACV__c && c.Billing_Contract_Line_Id__c == contractidContractMap.get(c.Id).Billing_Contract_Line_Id__c && c.Billing_Contract_Id__c == contractidContractMap.get(c.Id).Billing_Contract_Id__c)
                    {
                        contractidContractMap.remove(c.id);
                    }
                }
            }
            if(!contractidContractMap.isEmpty())
            {
               DMLWrapper.doUpdate(contractidContractMap.values());
            }
           
        }
        
    }
    //GTMS-27602
    /* public void handleDealComponentProducts(List<SBQQ__Subscription__c> sbqqSubscriptionList) {
        if(sbqqSubscriptionList == null || sbqqSubscriptionList.isEmpty()){
            return;
        }
        Set<Id> productIds = new Set<Id>();
        for(SBQQ__Subscription__c s : sbqqSubscriptionList){
            if(s.SBQQ__Product__c != null){
                productIds.add(s.SBQQ__Product__c);
            }
        }

        if(productIds.isEmpty()){
            return;
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, Product_Type__c FROM Product2 WHERE Id IN :productIds AND Product_Type__c = 'Deal Component'
        ]);
        for(SBQQ__Subscription__c s:sbqqSubscriptionList){
            if(s.SBQQ__Product__c != null && productMap.containsKey(s.SBQQ__Product__c)){
                s.SBQQ__RenewalPrice__c = 0;
                s.SBQQ__TerminatedDate__c = s.CreatedDate != null ? s.CreatedDate.date() : Date.today();
            }
        }
    } */
}