public class AdrTransferOpportunityLinkScheduled Implements Schedulable {
    
    public void execute(SchedulableContext sc){
        Integer size = System.Label.ADR_Opp_Link_Batch_Size == null || Test.isRunningTest() ? 200 : Integer.valueOf(System.Label.ADR_Opp_Link_Batch_Size);
        AdrTransferOpportunityLinkBatch adrTransferOppLinkBatch = new AdrTransferOpportunityLinkBatch();
        Database.executeBatch(adrTransferOppLinkBatch, size);
    }
}