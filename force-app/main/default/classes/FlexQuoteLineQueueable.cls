/*******************************************************************************************************************************************
 * @Test class: 
* Date      	- Project#          - Developer/ Company      	       - Description
* ------------------------------------------------------------------------------------------------------------------------------------------
* 01/21/2025    - GTMS-25877        - Manglesh Kumar/ Accenture 	   - Initial creation to handle email notification for Flex Log records
*											
*/
public class FlexQuoteLineQueueable implements Queueable, Database.AllowsCallouts {
    private List<Flex_Log__c> logRecordList;
    
    public FlexQuoteLineQueueable(List<Flex_Log__c> logRecordList) {
        this.logRecordList = logRecordList;
    }

    public void execute(QueueableContext context) {
        
        Set<Id> logRecordIdSet = new Set<Id>();
        for (Flex_Log__c logRecord : logRecordList) {
            logRecordIdSet.add(logRecord.Id);
        }

        try {
            System.debug('All jobs have finished: ' + logRecordList);
            // Query records based on the extracted IDs
            List<Flex_Log__c> logsToUpdateList = [ SELECT Id, Status__c, AmendFutureMethodId__c, ErrorMessage__c, AccountId__c, ContractId__c, RevenueOpportunityId__c, RevenueQuoteId__c, AmendedOpportunityId__c, AmendedQuoteId__c 
                                                   FROM Flex_Log__c WHERE Id IN :logRecordIdSet ORDER BY CreatedDate ASC];
            System.debug('Logs to update: ' + logsToUpdateList);
            if (!logsToUpdateList.isEmpty()) {
                System.debug(logsToUpdateList[0].AccountId__c);
                
                FlexLogNotifier.notifyByEmail(logsToUpdateList);
            }
        } catch (Exception e) {
            handleException( e.getMessage(), e.getStackTraceString(),  logRecordIdSet);
        }
    }
    public static void handleException(String errorMessage,String errorStackTrace, Set<Id> logRecordIdSet) {
        // Query the latest Flex_Log__c records for error handling
        List<Flex_Log__c> latestLogRecordList = [ SELECT Id, AccountId__c, ErrorMessage__c, Status__c FROM Flex_Log__c 
                                                  WHERE Id IN :logRecordIdSet ORDER BY CreatedDate DESC];

        // Handle the error
        FlexCancelReplaceHelper.handleError(latestLogRecordList, 'Failed in FlexQuoteLineQueueable: ', errorMessage + '\r\n' + errorStackTrace);
        System.debug('Exception encountered: ' + errorMessage + '\r\n' + errorStackTrace);
    }
}