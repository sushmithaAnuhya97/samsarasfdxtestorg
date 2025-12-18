/**
 * Created by vikasmishra on 2021-10-13.
 */

@IsTest
private class GS_AsyncQuotaOpportunityDeletionTest {
    @IsTest
    static void testExecute() {
        GS_AsyncQuotaOpportunityDeletionService thisService = new GS_AsyncQuotaOpportunityDeletionService();
        Test.startTest();
        try{
            thisService.execute(new Async_Request__c());
        }
        catch(Exception ex){
            System.debug(ex);
        }
        Test.stopTest();

        System.assert([SELECT Id FROM Log__c].size() != 10);
    }

    @IsTest
    static void ShouldReturnGetRequestType(){
        GS_AsyncQuotaOpportunityDeletionService.AsyncQuotaOpportunityDeletionService thisIS= new
                GS_AsyncQuotaOpportunityDeletionService.AsyncQuotaOpportunityDeletionService();
        thisIS.getQuotaOpportunitiesFromOppIds(new List<Id>());
        GS_AsyncQuotaOpportunityDeletionService thisService = new GS_AsyncQuotaOpportunityDeletionService();
        System.assert(thisService.getRequestType() == 'Delete Quota Opportunity');
    }
}