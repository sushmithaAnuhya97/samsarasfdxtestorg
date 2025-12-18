//Test Vertex batch call from Flow
global class CallVertexBatch {
   @InvocableMethod(Label='Call Vertex Batch')
   public static void invokeVertexBatch(List<String> names) {

      Integer batchSize = 1;
      List<QuoteSettings__mdt> quoteSettings = [select id, DeveloperName, Label, ValueSmall__c,ValueLong__c from QuoteSettings__mdt where Type__c ='Vertex' AND DeveloperName='BatchSize'];
      if(quoteSettings[0].DeveloperName == 'BatchSize'){
         batchSize = Integer.valueOf(quoteSettings[0].ValueSmall__c);
      }

      List<String> names2 = new List<String>();
      names2.addAll(names);

      if(!Test.isRunningTest()){
          database.executebatch(new VertexBatch(),batchSize);
      }
   }
}