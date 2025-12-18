global class BatchAutoApproveSchedular implements Schedulable {
    Integer batchSize = integer.valueof(system.label.batchAutoApprovalBatchSize);
    global void execute(SchedulableContext sc) {
       /* Datetime currentDateTime = Datetime.now();
        String dayOfWeek = currentDateTime.format('EEEE'); // gives the full day name
        if(dayOfWeek=='Saturday'||dayofWeek=='Sunday'){
            return;
        }*/
        
        // Run the batch
        BatchAutoApproveApprovals batch = new BatchAutoApproveApprovals();
        Database.executeBatch(batch,batchSize);
       
    }
    
}