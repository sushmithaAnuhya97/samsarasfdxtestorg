/*
* TestClass = OpportunityEquipmentACVBatchTest

NOTE: This should run batch size ONE , as we are hardcoding the index

* This Class is used to update the Equipment ACV amount on Opp based on QLs amount. 
* System.schedule('Scheduled Job OpportunityEquipmentACVBatch 17Mins', '0 17 * * * ?', new OpportunityEquipmentACVBatch());

* Feb-3-2023 Rajesh :- GTMS-11183
* Apr-2-2024 Zakeer : GTMS-18033
*/
global class OpportunityEquipmentACVBatch implements
    Database.Batchable<sObject>, Schedulable{
 
   static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
   static gslib_ILogger thisLogger = thisModuleLogger.getLogger();

   public Database.QueryLocator start(Database.BatchableContext BC){
      String query = System.Label.OpportunityEquipmentACVBatch;
      if(Test.isRunningTest()){
            query = 'SELECT id,SBQQ__PrimaryQuote__c,Equipment_Bookings_ACV__c, Forms_ACV__c FROM Opportunity LIMIT 1';
      }
      return Database.getQueryLocator(query);
   }
    
   public void execute(Database.BatchableContext BC, List<Opportunity> scope){
      //For AGs & Sensors equipmentACV
      List<String> prodCodes = (System.Label.OpptyEquipACVAGSensors+','+System.Label.OpptyEquipACVAGSensors_2).replace(',,',',').replace(',null','').split(',');
      List<String> formsACVCodes = System.Label.OpptyEquipFormsACV.split(',');
      
      //List<String> prodCodes = System.Label.Connected_Equipment_Product_Codes.split(',');//combining these ProdCodes with AGSensors Label
      List<SBQQ__QuoteLine__c> quoteLineList;
      
      if(Test.isRunningTest()){
         quoteLineList = [SELECT Id, Name, Total_Annual_Price__c, ACV_Total_Price_Stamp__c, SBQQ__ProductCode__c, 
                                                SBQQ__Product__r.Sub_Family__c, SBQQ__Quantity__c, 
                                                SBQQ__Product__r.Product_Type__c, SBQQ__Product__r.ProductCode, SBQQ__RequiredBy__c, 
                                                SBQQ__Quote__r.id, 
                                                SBQQ__Quote__r.SBQQ__Opportunity2__c, SBQQ__Quote__r.SBQQ__LineItemCount__c
                                                FROM SBQQ__QuoteLine__c WHERE ((SBQQ__Product__r.ProductCode IN : prodCodes) OR (SBQQ__Product__r.ProductCode IN: formsACVCodes) )];
      }
      else{
         quoteLineList = [SELECT Id, Name, Total_Annual_Price__c, ACV_Total_Price_Stamp__c, SBQQ__ProductCode__c, 
                                                SBQQ__Product__r.Sub_Family__c, SBQQ__Quantity__c, 
                                                SBQQ__Product__r.Product_Type__c, SBQQ__Product__r.ProductCode, SBQQ__RequiredBy__c, 
                                                SBQQ__Quote__r.id, 
                                                SBQQ__Quote__r.SBQQ__Opportunity2__c, SBQQ__Quote__r.SBQQ__LineItemCount__c
                                                FROM SBQQ__QuoteLine__c 
                                                WHERE SBQQ__Quote__c =: scope[0].sbqq__primaryquote__c
                                                AND SBQQ__EffectiveQuantity__c <> 0
                                                AND ((SBQQ__Product__r.ProductCode IN : prodCodes) OR (SBQQ__Product__r.ProductCode IN: formsACVCodes) )];
      }
      
      List<Opportunity> oppsToUpdate = new List<Opportunity>();
     Opportunity newOpp = new Opportunity(Id=scope[0].Id); 
      if(!quoteLineList.isEmpty()) {
         
         Double rollupAmountForAG_Sensors = 0;
         Double rollupAmountForForms = 0;
        
         for(SBQQ__QuoteLine__c ql:quoteLineList) { 
            //GTMS-12278-July19-2023:
            if(ql.SBQQ__ProductCode__c != NULL && prodCodes.contains(ql.SBQQ__ProductCode__c)){
                 rollupAmountForAG_Sensors += ql.ACV_Total_Price_Stamp__c <> null ? ql.ACV_Total_Price_Stamp__c : 0;
            } else if(ql.SBQQ__ProductCode__c != NULL && formsACVCodes.contains(ql.SBQQ__ProductCode__c)){
                 rollupAmountForForms += ql.ACV_Total_Price_Stamp__c <> null ? ql.ACV_Total_Price_Stamp__c : 0;
            }
         }
         
         //GTMS-12278 - July19-2023 -- added if block to check for AG & Sensors products and assign ACV with TotalRollup
             if( rollupAmountForAG_Sensors <> scope[0].Equipment_Bookings_ACV__c){
                    newOpp.Equipment_Bookings_ACV__c = rollupAmountForAG_Sensors;
                 //oppsToUpdate.add(new Opportunity(Id = scope[0].Id, Equipment_Bookings_ACV__c = rollupAmountForAG_Sensors));
             }
             if( rollupAmountForForms <> scope[0].Forms_ACV__c){
                 newOpp.Forms_ACV__c = rollupAmountForForms;
             }
             
         oppsToUpdate.add(newOpp);
      } else {//GTMS-16119
          if(scope[0].Equipment_Bookings_ACV__c <> 0){
              newOpp.Equipment_Bookings_ACV__c =0;
          }
          if(scope[0].Forms_ACV__c <> 0) {//GTMS-18033
          newOpp.Forms_ACV__c =0;
          }
          oppsToUpdate.add(newOpp);
      }
      
        Database.SaveResult[] updatedOpps = Database.update(oppsToUpdate,false);
         for(Integer i = 0; i < updatedOpps.size(); i++){
            if(!updatedOpps[i].isSuccess()){
               for(Database.Error err : updatedOpps[i].getErrors())
               {
                     thisLogger.logError(err.getStatusCode() + ': ' + err.getMessage() + ', Opp fields that affected this error: ' + err.getFields());
               }
               thisLogger.dispatch();
            }
         }  
   }
 
   public void finish(Database.BatchableContext BC){
      
   }

   global void execute(SchedulableContext SC) {
      database.executebatch(new OpportunityEquipmentACVBatch(),1);
   }
}