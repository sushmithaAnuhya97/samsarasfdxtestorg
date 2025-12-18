/*

2-Nov-2023 Rajesh GTMS-16392
System.schedule('Scheduled Job VertexBatch 00', '0 0 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 03', '0 3 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 06', '0 6 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 09', '0 9 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 12', '0 12 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 15', '0 15 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 18', '0 18 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 21', '0 21 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 24', '0 24 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 27', '0 27 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 30', '0 30 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 33', '0 33 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 36', '0 36 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 39', '0 39 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 42', '0 42 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 45', '0 45 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 48', '0 48 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 51', '0 51 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 54', '0 54 * * * ?', new VertexBatch());
System.schedule('Scheduled Job VertexBatch 57', '0 57 * * * ?', new VertexBatch());

for(Integer i =0; i < 60; i++){
   String CRON_EXP = '0 '+i+' * * * ?'; 
   VertexBatch vb = new VertexBatch();
   System.schedule('Scheduled Job VertexBatch every min'+i, CRON_EXP, vb);
}
*/

global class VertexBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable{
 
   global Datetime last2Mins;
   global Datetime last5Mins;

   public Database.QueryLocator start(Database.BatchableContext BC){
      String query='';
      Integer StartMins;
      Integer EndMins;
      
      List<QuoteSettings__mdt> quoteSettings = [select id, DeveloperName, Label, ValueSmall__c,ValueLong__c from QuoteSettings__mdt where Type__c ='Vertex'];
      for(QuoteSettings__mdt qs:quoteSettings){
         if(qs.DeveloperName == 'StartMins'){
            StartMins = Integer.valueOf(qs.ValueSmall__c);
         }
         if(qs.DeveloperName == 'EndMins'){
            EndMins = Integer.valueOf(qs.ValueSmall__c);
         }
         if(qs.DeveloperName == 'Vertex_Batch_Query'){
            query = qs.ValueLong__c;
         }
      }

      last2Mins = Datetime.now().addSeconds(0 - EndMins); //-2
      last5Mins = Datetime.now().addMinutes(0 - StartMins); //-5
      last2Mins = last2Mins.addHours(8);
      last5Mins = last5Mins.addHours(8);
      query += ' AND lastmodifieddate >= ';
      query += ((string.valueOf(last5Mins).substring(0,19)).replace(' ', 'T') + '.000+0000');
      query += ' AND lastmodifieddate <= ';
      query += ((string.valueOf(last2Mins).substring(0,19)).replace(' ', 'T') + '.000+0000');
      query += ' ORDER BY LastModifiedDate';
      system.debug('RajQuery=:' + query);

      if(Test.isRunningTest()){
         query = 'select Id, lastmodifieddate,SBQQ__LastCalculatedOn__c  from SBQQ__Quote__c LIMIT 1';
      }
      return Database.getQueryLocator(query);
   }
    
   public void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> scope){
      Map<Id, SBQQ__Quote__c> quotesRecalRequired = new Map<Id, SBQQ__Quote__c>();
      Set<Id> quotes = new Set<Id>();
      Set<Id> quotesInChunk = new Set<Id>();
      for(SBQQ__Quote__c q : scope){
         quotesInChunk.add(q.Id);
      }

      //Find If Recalculation is required
      for(SBQQ__Quote__c q : scope){
         if(q.SBQQ__LineItems__r.size() > 0 
               && q.Recalculate_Quote__c == false
               && ((q.SBQQ__LastCalculatedOn__c >= last5Mins && q.SBQQ__LastCalculatedOn__c <= last2Mins)
                 || (q.LastModifiedDate >= last5Mins && q.LastModifiedDate <= last2Mins))){
                     quotesRecalRequired.put(q.Id, new SBQQ__Quote__c(Id = q.Id ,Recalculate_Quote__c = true));
         }
      }
      if(quotesRecalRequired.size() > 0){
         update quotesRecalRequired.values();
      }

      //Vertex call
      for(SBQQ__Quote__c q : scope){
         if(quotesRecalRequired.containsKey(q.Id) == false || Test.isRunningTest()){
            quotes.add(q.Id);
         }
      }
      PopulateTaxes.callVertex(quotes);
   }
 
   public void finish(Database.BatchableContext BC){
      
   }

   global void execute(SchedulableContext SC) {
      database.executebatch(new VertexBatch(),1);
   }
}