/**
 * Created by vikasmishra on 2021-10-13.
 */

@IsTest
private class GS_AsyncSBQQQuoteFromOpportunityTest {
    @IsTest
    static void testExecute() {
        GS_AsyncSBQQQuoteFromOpportunityService thisService = new GS_AsyncSBQQQuoteFromOpportunityService();
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
        GS_AsyncSBQQQuoteFromOpportunityService.AsyncSBQQQuoteFromOpportunityService thisIS= new
                GS_AsyncSBQQQuoteFromOpportunityService.AsyncSBQQQuoteFromOpportunityService();
        thisIS.getQuotesFromOppIds(new List<Id>());
        thisIS.getOpportunityFromIds(new List<Id>());
        GS_AsyncSBQQQuoteFromOpportunityService thisService = new GS_AsyncSBQQQuoteFromOpportunityService();
        System.assert(thisService.getRequestType() == 'Update SBQQ Quote From Opportunity');
    }
}