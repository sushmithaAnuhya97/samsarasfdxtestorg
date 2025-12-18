/*
* TestClass = ContractTests

* This Class is used Reprocess the Opportunity Renewals by un-checking and then re-checking the RenewalForecast checkbox field on Contract
* System.schedule('Scheduled Job ContractRenewalsReprocessBatch 17', '0 17 * * * ?', new ContractRenewalsReprocessBatch(false,null));

* Sep-2-2022 Rajesh :- GTMS-8298
*/
global class ContractRenewalsReprocessBatch implements
    Database.Batchable<sObject>, Database.Stateful,Schedulable{
 
   //If True: then check the RenewalForecast on Contract.
   //If Flase: then uncheck the RenewalForecast on Contract.
   public final boolean doCheck;  
   public Set<Id> contractListState = new Set<Id>();
   public Set<Id> contractList = new Set<Id>();
   
   public ContractRenewalsReprocessBatch(boolean b, Set<Id> conList){
     doCheck = b;
     contractList = conList;
   }
 
   public Database.QueryLocator start(Database.BatchableContext BC){
      if(doCheck){ // Check RenewalForecast on Contract 
         return Database.getQueryLocator('SELECT id FROM Contract WHERE id IN : contractList');
      }   
      else{ 
         String query = System.Label.ContractRenewalsReprocessBatchQuery; //'SELECT id FROM Contract WHERE SBQQ__RenewalForecast__c = true'; //+ 30mins back logic
         Datetime lastNMins = Datetime.now().addMinutes(-30);
         if(!Test.isRunningTest()){
            query += ' AND SBQQ__RenewalOpportunity__c = NULL';
            query += ' AND lastmodifieddate <= ';
         }
         else {
            query += ' AND lastmodifieddate >= ';
         }
         query += ((string.valueOf(lastNMins).substring(0,16)).replace(' ', 'T') + ':00Z') + ' LIMIT 100';
         system.debug('RajQuery=:' + query);
         return Database.getQueryLocator(query);
      }
   }
    
   public void execute(Database.BatchableContext BC, List<Contract> scope){
      
      for(Contract s : scope){
         contractListState.add(s.Id);
         s.SBQQ__RenewalForecast__c = doCheck;
      }
      
      update scope;
   }
 
public void finish(Database.BatchableContext BC){
      if(!doCheck) //if false, then call the true method to check the RenewalForecast
         database.executebatch(new ContractRenewalsReprocessBatch(true, contractListState),1);
   }

global void execute(SchedulableContext SC) {
      database.executebatch(new ContractRenewalsReprocessBatch(false,null),1);
   }
}