/**
 * Created By: Pankaj
 * @Date: 01/10/25
 *
 * @description:
 * - This batch updates the 'First Purchase Opportunity' field on the Account object.
 * - It identifies the first 'Closed Won' Opportunity of type 'Revenue Opportunity' for each Account.
 * - The earliest qualifying Opportunity is selected based on the Close Date.
 * - The 'First_Purchase_Opportunity__c' field on the Account is updated with the ID of the first qualifying Opportunity.
 */
 
global class BatchAccountFirstPurchaseOpptyUpdate implements Database.Batchable<sObject>, Schedulable {
    
    // Logger initialization following org pattern
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS'); // Account First Purchase Opportunity
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    
    // Error message template
    static String LOG_ERROR_TEMPLATE = 'Account First Purchase Opportunity update failed in record {0} / Errors: {1}';
        
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(System.Label.Query_AccountFirstPurchaseOpptyUpdate);
    }
    
    /**
     * @description: Processes each batch of Accounts, identifies the first qualifying Opportunity, and updates the Account.
     * @param Database.BatchableContext BC
     * @param List<sObject> scope
     */
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        try {
            List<Account> accountsToUpdate = new List<Account>();
            
            for(sObject sobj : scope) {
                Account acc = (Account)sobj;
                List<Opportunity> opportunities = acc.getSObjects('Opportunities');
                
                if(opportunities != null && !opportunities.isEmpty()) {
                    accountsToUpdate.add(new Account(
                        Id = acc.Id,
                        First_Purchase_Opportunity__c = opportunities[0].Id
                    ));
                }
            }
            
            if(!accountsToUpdate.isEmpty()) {
                this.executeDmlAndLogErrors(accountsToUpdate);
            }
            
        } catch(Exception ex) {
            thisLogger.logError('Error processing Account First Purchase Opportunity batch: {0} / Stack trace: {1}', 
                new List<Object>{ ex.getMessage(), ex.getStackTraceString() });
            throw ex;
        } finally {
            thisLogger.dispatch();
        }
    }
    
    /**
    * @description : Execute the DML & log any errors with the logging framework
    * @param List<SObject> scope
    */
    @TestVisible
    private void executeDmlAndLogErrors(List<SObject> scope) {
        List<Database.SaveResult> resultList = Database.update(scope, false);
        for (Integer it = 0; it < resultList.size(); it++) {
            if (!resultList[it].isSuccess()) {
                thisLogger.logError(String.format(LOG_ERROR_TEMPLATE, new List<Object>{
                    scope[it].Id,
                    getErrorList(resultList[it].getErrors())
                }));
            }
        }
    }
    
    /**
    * @description : Receives a List of Database Errors and return the messages in a single string separated by "; "
    * @param List<Database.Error> errors
    * @return String errors in a single line
    */
    @TestVisible
    private String getErrorList(List<Database.Error> errors) {
        String err = '';
        for (Database.Error error : errors)
            err += (String.isBlank(err) ? '' : '; ') + error.message;
        return err;
    }
    
    global void finish(Database.BatchableContext BC) {
    }
        
    /**
     * @description: Schedules the batch to run.
     * @param SchedulableContext sc
     */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchAccountFirstPurchaseOpptyUpdate());
    }
}