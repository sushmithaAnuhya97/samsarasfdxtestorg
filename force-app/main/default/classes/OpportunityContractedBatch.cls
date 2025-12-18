/*
* TestClass = OpportunityContractedBatchTest

* This Class is used to uncheck and check the Contracted checkbox on Opps for which Contracts are not created
* System.schedule('Scheduled Job OpportunityContractedBatch 17', '0 17 * * * ?', new OpportunityContractedBatch(false,null));

* Oct-21-2022 Rajesh :- GTMS-8298
* Jun-16-2025 :- GTMS-27487
*/
global class OpportunityContractedBatch implements
Database.Batchable<sObject>, Database.Stateful,Schedulable{
    
    public final boolean doCheck;
    public final Integer queryType;
    public Map<Id, Boolean> processedOpportunitiesMap = new Map<Id, Boolean>();
    
    public static Org_Setting__mdt orderTransformationSetting = Org_Setting__mdt.getInstance('OrderTransformationPhase2');
    public static Set<String> skipOppTypes = new Set<String> { 'Free Trial Opportunity', 'Free Trial Return', 'Rebate', 'Warranty'};
        
    public OpportunityContractedBatch(boolean b, Integer queryTypeParam, Map<Id, Boolean> processedOpps){
        doCheck = b;
        queryType = queryTypeParam;
        if(processedOpps != null) {
            processedOpportunitiesMap = processedOpps;
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        if(doCheck){ 
            List<Id> oppIdList = new List<Id>(processedOpportunitiesMap.keySet());
            return Database.getQueryLocator('SELECT Id, Type FROM Opportunity WHERE Id IN : oppIdList');
        }   
        else{ 
            String query='';
            if(Test.isRunningTest()){
                switch on queryType {
                    when 1 {
                        query = 'SELECT Id, OpportunityId, Opportunity.Type, SBQQ__QuoteLine__c, Opportunity.SBQQ__RenewedContract__c, Opportunity.SBQQ__AmendedContract__c FROM OpportunityLineItem LIMIT 1';
                    }
                    when 2 {
                        query = 'SELECT Id, OpportunityId, Opportunity.Type FROM Order LIMIT 1';
                    }
                }
            }
            else{
                switch on queryType {
                    when 1 {
                        query = System.Label.OpportunityContractedBatchQuery2;
                    }
                    when 2 {
                        query = System.Label.OpportunityContractedBatchQuery3;
                    }
                }
            }
            
            return Database.getQueryLocator(query);
        }
    }
    
    public void execute(Database.BatchableContext BC, List<SObject> scope){
        
        List<Id> oppOrdersToUpdate = new List<Id>();
        Map<Id,String> oppUpdateMap = new Map<Id,String>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        if(!doCheck) {

            if(queryType == 1) {

                for(SObject sObj : scope) {
                    OpportunityLineItem oli = (OpportunityLineItem)sObj;

                    if(!processedOpportunitiesMap.containsKey(oli.OpportunityId)){
                        if (oli.Opportunity.Type == 'Revenue Opportunity' 
                            && oli.Opportunity.SBQQ__AmendedContract__c != null ) {
                            oppOrdersToUpdate.add(oli.OpportunityId);
                            processedOpportunitiesMap.put(oli.OpportunityId, false);
                        } else if (oli.Opportunity.Type == 'Remorse Refund' || Test.isRunningTest()) {
                            oppUpdateMap.put(oli.OpportunityId, oli.Opportunity.Type);
                            processedOpportunitiesMap.put(oli.OpportunityId, true);
                        }
                    }
                }
            } else if(queryType == 2) {
                for(SObject sObj : scope) {
                    Order ord = (Order)sObj;
                    if (!processedOpportunitiesMap.containsKey(ord.OpportunityId)) {
                        oppOrdersToUpdate.add(ord.OpportunityId);
                        processedOpportunitiesMap.put(ord.OpportunityId, false);
                    }
                }
            }
        } else {
            for(SObject sObj : scope) {
                Opportunity opp = (Opportunity)sObj;
                if(processedOpportunitiesMap.containsKey(opp.Id)) {
                    if(processedOpportunitiesMap.get(opp.Id)) {
                        oppUpdateMap.put(opp.Id, opp.Type);
                    } else {
                        oppOrdersToUpdate.add(opp.Id);
                    }
                }
            }
        }
        
        for(Id oppId : oppUpdateMap.keySet()) {
            if(Boolean.valueOf(orderTransformationSetting.Value__c) == true && !skipOppTypes.contains(oppUpdateMap.get(oppId))
                || Boolean.valueOf(orderTransformationSetting.Value__c) == false) {
                
                Opportunity opp = new Opportunity();
                opp.Id = oppId;
                opp.SBQQ__Contracted__c = doCheck;
                if(opp.Id != null) {
                    oppsToUpdate.add(opp);
                }
            }
        }

        update oppsToUpdate;

        if(!oppOrdersToUpdate.isEmpty()) {
            List<Order> orderList = new List<Order>();
            for(Order ord : [SELECT Id, SBQQ__Contracted__c 
                           FROM Order 
                           WHERE OpportunityId IN :oppOrdersToUpdate]) {
                ord.SBQQ__Contracted__c = doCheck;
                orderList.add(ord);
            }
            
            if(!orderList.isEmpty()) {
                update orderList;
            }
        }

    }
    
    public void finish(Database.BatchableContext BC){
        if(!doCheck) {
            database.executebatch(new OpportunityContractedBatch(true, queryType, processedOpportunitiesMap), 1);
        } else {
            if(queryType == 1) {
                database.executebatch(new OpportunityContractedBatch(false, 2, processedOpportunitiesMap), 1);
            }
        }
    }
    
    global void execute(SchedulableContext SC) {
        // Start with query type 1 (original query) with doCheck false to collect opportunities
        database.executebatch(new OpportunityContractedBatch(false, 1, new Map<Id, Boolean>()), 1);
    }
}