public class AdrOppLinkBatchInvoker {

    @InvocableMethod(label='AdrTransferOpportunityLinkBatch')
    public static void launch() {
        Integer size = System.Label.ADR_Opp_Link_Batch_Size == null || Test.isRunningTest() ? 200 : Integer.valueOf(System.Label.ADR_Opp_Link_Batch_Size);
        Database.executeBatch(new AdrTransferOpportunityLinkBatch(), size);
    }
}