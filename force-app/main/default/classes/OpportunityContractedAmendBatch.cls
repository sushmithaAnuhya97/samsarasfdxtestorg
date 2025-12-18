/*
* TestClass = OpportunityContractedAmendBatchTest

* This Class is used to uncheck and check the Contracted checkbox on Opps for which Contracts are not created
* System.schedule('Scheduled Job OpportunityContractedAmendBatch 17', '0 17 * * * ?', new OpportunityContractedAmendBatch(false,null));

* Nov-17-2022 Rajesh :- GTMS-10058
*/
global class OpportunityContractedAmendBatch implements
    Database.Batchable<sObject>, Database.Stateful,Schedulable{
 
   public Set<Id> OppListState = new Set<Id>();
   public static Org_Setting__mdt orderTransformationSetting = Org_Setting__mdt.getInstance('OrderTransformationPhase2');
   public static Set<String> skipOppTypes = new Set<String> {'Revenue Opportunity', 'Free Trial Opportunity', 'Free Trial Return', 'Remore Refund', 'Rebate', 'Warranty'};        
   
   public Database.QueryLocator start(Database.BatchableContext BC){
      
     String query='';
     if(Test.isRunningTest()){
         query = 'SELECT id,SBQQ__Quote__r.SBQQ__Opportunity2__c, SBQQ__Quote__r.SBQQ__Opportunity2__r.Type FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.SBQQ__Opportunity2__r.Type NOT IN:skipOppTypes LIMIT 1';
      }
      else{
         query = System.Label.OpportunityContractedAmendBatchQuery; //'SELECT id FROM Contract WHERE SBQQ__RenewalForecast__c = true';
      }
      
      return Database.getQueryLocator(query);
       
   }
    
   public void execute(Database.BatchableContext BC, List<SBQQ__QuoteLine__c> scope){
      List<Opportunity> oppList = new List<Opportunity>();
      for(SBQQ__QuoteLine__c s : scope){
         if(!OppListState.contains(s.SBQQ__Quote__r.SBQQ__Opportunity2__c) && 
            (Boolean.valueOf(orderTransformationSetting.Value__c) == true && !skipOppTypes.contains(s.SBQQ__Quote__r.SBQQ__Opportunity2__r.Type) 
              || Boolean.valueOf(orderTransformationSetting.Value__c) == false)){
             oppList.add(new Opportunity(Id = s.SBQQ__Quote__r.SBQQ__Opportunity2__c ,SBQQ__Contracted__c = false));
             OppListState.add(s.SBQQ__Quote__r.SBQQ__Opportunity2__c);
         }
      }
      
      if(!Test.isRunningTest())
          update oppList;
      
      for(Opportunity o : oppList){
          o.SBQQ__Contracted__c = true;
      }
      
      if(!Test.isRunningTest())
          update oppList;
   }
 
public void finish(Database.BatchableContext BC){
      //
   }

global void execute(SchedulableContext SC) {
      database.executebatch(new OpportunityContractedAmendBatch(),1);
   }
}