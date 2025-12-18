/**
 * Created by vikasmishra on 2021-10-13.
 */

@IsTest
private class GS_AsyncDisconnectTrialOppServiceTest {
    @IsTest
    static void testExecute() {
        GS_AsyncDisconnectTrialOppService thisService = new GS_AsyncDisconnectTrialOppService();
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
        GS_AsyncDisconnectTrialOppService thisService = new GS_AsyncDisconnectTrialOppService();
        System.assert(thisService.getRequestType() == 'Trial Opportunity Disconnections');
    }
}