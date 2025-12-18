/**********************************************************************
Name: OpptyLineitemDiscountBatch

============================================================================================================
Purpose: This is a schedular class for OpptyLineitemDiscountBatch which runs 2 times in a day at 7.00 AM and 7 PM.                              
============================================================================================================
History  
                                                                                                                    
  VERSION             AUTHOR                   DATE                 DETAIL                       
   1.0                ANIL                    03/26/2021        INITIAL DEVELOPMENT

***********************************************************************/  

global class OpptyLineitemDiscountBatchSchedular implements Schedulable {
   Integer batchSize = integer.valueof(system.label.OppLineItemDiscountBatchSize);
   global void execute(SchedulableContext sc) {
      OpptyLineitemDiscountBatch b = new OpptyLineitemDiscountBatch(); 
      database.executebatch(b,batchSize);
   }
}