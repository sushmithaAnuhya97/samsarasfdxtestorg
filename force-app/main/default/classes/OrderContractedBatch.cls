/*
* TestClass = OrderContractedBatchTest

* This Class is used to uncheck and check the Contracted checkbox on Opps for which Contracts are not created
* System.schedule('Scheduled Job OrderContractedBatch 17', '0 17 * * * ?', new OrderContractedBatch(false,null));

* Oct-21-2022 Rajesh :- GTMS-8298
*/
global class OrderContractedBatch implements
    Database.Batchable<sObject>, Database.Stateful,Schedulable{
 
   //If True: then check the RenewalForecast on Contract.
   //If Flase: then uncheck the RenewalForecast on Contract.
   public final boolean doCheck;  
   public Set<Id> OppListState = new Set<Id>();
   public Set<Id> OppList = new Set<Id>();
   
   public OrderContractedBatch(boolean b, Set<Id> oList){
     doCheck = b;
     OppList = oList;
   }
 
   public Database.QueryLocator start(Database.BatchableContext BC){
      if(doCheck){ // Check Contracted on Opp 
         return Database.getQueryLocator('SELECT id FROM Order WHERE id IN : OppList');
      }   
      else{ 
         String query='';
         if(Test.isRunningTest()){
             query = 'SELECT id FROM Order LIMIT 1';
          }
          else{
             query = System.Label.OrderContractedBatchQuery;
          }
          
          return Database.getQueryLocator(query);
       }
   }
    
   public void execute(Database.BatchableContext BC, List<Order> scope){
      
      for(Order s : scope){
         OppListState.add(s.Id);
         s.SBQQ__Contracted__c = doCheck;
      }
      
      update scope;
   }
 
public void finish(Database.BatchableContext BC){
      if(!doCheck) //if false, then call the true method to check the Contracted
         database.executebatch(new OrderContractedBatch(true, OppListState),1);
   }

global void execute(SchedulableContext SC) {
      database.executebatch(new OrderContractedBatch(false,null),1);
   }
}