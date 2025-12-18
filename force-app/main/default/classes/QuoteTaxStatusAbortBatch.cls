/*
* TestClass = QuoteTaxStatusAbortBatchTest

* This Class is used to set the CalculationStatus to Abort for which we got the error while processing Vertex Tax
* This batch is expected to run every 5 minutes to set the Calculation status to Abort, so that Reps can work with Tax team
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 00mins', '0 00 * * * ?', new QuoteTaxStatusAbortBatch());
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 05mins', '0 05 * * * ?', new QuoteTaxStatusAbortBatch());
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 10mins', '0 10 * * * ?', new QuoteTaxStatusAbortBatch());
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 15mins', '0 15 * * * ?', new QuoteTaxStatusAbortBatch());
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 20mins', '0 20 * * * ?', new QuoteTaxStatusAbortBatch());
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 25mins', '0 25 * * * ?', new QuoteTaxStatusAbortBatch());
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 30mins', '0 30 * * * ?', new QuoteTaxStatusAbortBatch());
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 35mins', '0 35 * * * ?', new QuoteTaxStatusAbortBatch());
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 40mins', '0 40 * * * ?', new QuoteTaxStatusAbortBatch());
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 45mins', '0 45 * * * ?', new QuoteTaxStatusAbortBatch());
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 50mins', '0 50 * * * ?', new QuoteTaxStatusAbortBatch());
* System.schedule('Scheduled Job QuoteTaxStatusAbortBatch 55mins', '0 55 * * * ?', new QuoteTaxStatusAbortBatch());

* Nov-15-2023 Rajesh :- GTMS-16392
*/
global class QuoteTaxStatusAbortBatch implements
    Database.Batchable<sObject>, Schedulable{
 
   global Datetime last5Mins;
   global Datetime last10Mins;
   public Database.QueryLocator start(Database.BatchableContext BC){
      
      String query='';
      Integer StartMins;
      Integer EndMins;
      List<QuoteSettings__mdt> quoteSettings = [select id, DeveloperName, Label, ValueSmall__c,ValueLong__c from QuoteSettings__mdt 
                                    where DeveloperName ='QuoteTaxStatusAbortBatchQuery' OR DeveloperName ='QuoteTaxStatusAbortBatchLastNMins' OR DeveloperName='QuoteTaxStatusAbortBatchStartMins'];
      for(QuoteSettings__mdt qs : quoteSettings){
            if(qs.DeveloperName == 'QuoteTaxStatusAbortBatchQuery'){
               query = qs.ValueLong__c;
            }
            else if(qs.DeveloperName == 'QuoteTaxStatusAbortBatchStartMins'){
               StartMins = integer.valueof(qs.ValueSmall__c);
            }
            else if(qs.DeveloperName == 'QuoteTaxStatusAbortBatchLastNMins'){
               EndMins = integer.valueof(qs.ValueSmall__c);
            }
      }
      /*last10Mins  = Datetime.now().addMinutes(0 - StartMins); //-10
      last5Mins = Datetime.now().addMinutes(0 - EndMins); //-5
      query += ' AND lastmodifieddate >= ';
      query += ((string.valueOf(last10Mins).substring(0,19)).replace(' ', 'T') + '.000+0000');
      query += ' AND lastmodifieddate <= ';
      query += ((string.valueOf(last5Mins).substring(0,19)).replace(' ', 'T') + '.000+0000');
      query += ' ORDER BY LastModifiedDate';*/
      system.debug('RajQuery=:' + query);

      if(Test.isRunningTest()){
            query = 'select Id from SBQQ__Quote__c LIMIT 1';
      }
         
      return Database.getQueryLocator(query);
   }
    
   public void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> scope){
      List<SBQQ__Quote__c> qList = new List<SBQQ__Quote__c>();
      for(SBQQ__Quote__c q : scope){
            qList.add(new SBQQ__Quote__c(Id = q.Id ,Tax_Calculation_Status__c = 'Aborted', VertexCPQ__Tax_Status__c = NULL));
       }
      
      update qList;
   }
 
public void finish(Database.BatchableContext BC){
      //
   }

global void execute(SchedulableContext SC) {
      database.executebatch(new QuoteTaxStatusAbortBatch(),1);
   }
}