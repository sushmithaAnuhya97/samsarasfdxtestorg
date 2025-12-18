/****************************************************************************************************************************
 * @Test class: FlexAccountCancelReplaceControllerTest
* Date      	- Project#       - Developer/ Company      	       - Description
* -----------------------------------------------------------------------------------------------------------------------------------------
* 01/06/2025    - GTMS-25705     - Anas Siddiquee/ Accenture 	   - Handles Cancel & Replace Upgraded & Amendment Quotes, QLIs, Opp creation
* 01/20/2025    - GTMS-25970     - Anas Siddiquee/ Accenture 	   - Added Logging for C&R processing
*/
public without sharing class FlexCancelAndReplaceHandler {

    /**
     * @description - Calls the Amender API to create and update the amendment quote and related records
    * @param - Each Contract Id, start date for the cancelled quote, Upgraded opportunity Id
    */
    @future(callout = true)
    public static void callAmenderApi(String contractId, Date startDate, String replacementOppId, Boolean isRebook) {
        Savepoint sp = Database.setSavepoint(); // Set a savepoint to rollback in case of error
        try {
            Id relatedOppId;
            QuoteModel model = FlexCancelReplaceHelper.load(contractId); // Call CPQ Amendment API returning created quote
            System.debug('Enter model '+ model);
            // Update the cancellation opportunity with relevant details like Type, Stage, Close Date, etc.
            if (model.record.SBQQ__Opportunity2__c != null) {
                relatedOppId = FlexCancelReplaceHelper.updateCancellationOpp(model.record.SBQQ__Opportunity2__c, replacementOppId, startDate);          
            }
            model = (model != null) ? FlexCancelReplaceHelper.updateCancellationQuote(model, startDate, isRebook, relatedOppId) : null; // Update the cancellation quote and qli
            System.debug('Enter outside updateCancellationQuote '+contractId);

            // Update replacement quote with the Related opp Id
            // if(relatedOppId != null && replacementQuoteId != null){
            //     FlexCancelReplaceHelper.updateReplacementQuote(replacementQuoteId, relatedOppId);
            // }

            // Update the log records with the amended opp and quote
            Flex_Log__c queueableLog = [SELECT Id FROM Flex_Log__c WHERE ContractId__c = :contractId ORDER BY CreatedDate DESC LIMIT 1];
            System.debug('Enter model.record.Id '+ model.record.Id);
            queueableLog.AmendedQuoteId__c = model.record.Id;
            queueableLog.AmendedOpportunityId__c = model.record.SBQQ__Opportunity2__c;
            queueableLog.AccountId__c = model.record.SBQQ__Account__c;
            update queueableLog;
            
            //Update the Contract_C_R_In_Progress__c on the contract to true
            TriggerHandler.bypass('ContractTriggerHandler');
            Contract contract = [SELECT Id, Contract_C_R_In_Progress__c FROM Contract WHERE Id = :contractId LIMIT 1];
            contract.Contract_C_R_In_Progress__c = true;
            System.debug('Enter isRebook '+isRebook);
            if(isRebook){
                contract.Flex_Is_Rebook__c = true;
            }
            update contract;
            
        } catch (Exception e) {
            System.debug('Error in callAmenderApi: ' + e.getMessage());
            // Rollback to the savepoint
            Database.rollback(sp);
            
            // Update the log with the error message
            handleApiError(e, contractId);
        }
    }

    private static void handleApiError(Exception e, String contractId) {
        System.debug('Failed in FlexCancelAndReplaceHandler: ' + e.getMessage() + ' ' + 'Stack Trace: ' + e.getStackTraceString());
        Flex_Log__c queueableLog = [SELECT Id, ErrorMessage__c, Status__c FROM Flex_Log__c WHERE ContractId__c = :contractId ORDER BY CreatedDate DESC LIMIT 1];
        queueableLog.Status__c = 'Failed';
        if (queueableLog.ErrorMessage__c != null) {
            queueableLog.ErrorMessage__c += '. ' + '\n\n' + 'Failed in FlexCancelAndReplaceHandler: ' + '\n' + e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString();
        } else {
            queueableLog.ErrorMessage__c = 'Failed in FlexCancelAndReplaceHandler: ' + '\n' + e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString();
        }
        update queueableLog;
    }



}