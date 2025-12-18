/**********************************************************************
Name: ContractSubscriptionRollupBatch

============================================================================================================
Purpose: This is a schedular class for ContractSubscriptionRollupBatch which runs at 2:00 AM                              
============================================================================================================
History  
                                                                                                                    
  VERSION             AUTHOR                   DATE                 DETAIL                       
   1.0                Abu                    03/26/2021        INITIAL DEVELOPMENT

***********************************************************************/  

global class ContractSubscriptionRollupBatchSchedular implements Schedulable {
    Integer batchSize = integer.valueof(system.label.ContractSubscriptionRollupBatchSize);
    global void execute(SchedulableContext sc) {
      ContractSubscriptionRollupBatch b = new ContractSubscriptionRollupBatch(); 
      database.executebatch(b,batchSize);
   }
}