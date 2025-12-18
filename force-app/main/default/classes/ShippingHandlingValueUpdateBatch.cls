/**
 * @description       : Batch class to update Shipping_and_Handling_Value__c field on SBQQ__Quote__c records
 *                      by copying values from Shipping_and_Handling__c field for records where 
 *                      Shipping_and_Handling__c != null and Shipping_and_Handling_Value__c = null
 * @last modified on  : 09-30-2025
 * @last modified by  : shivam goyal
 **/
public without sharing class ShippingHandlingValueUpdateBatch implements Database.Batchable<SObject> {
    
    private Set<Id> quoteIds;
    
    public ShippingHandlingValueUpdateBatch(Set<Id> quoteIds) {
        this.quoteIds = quoteIds;
    }
    
    public ShippingHandlingValueUpdateBatch() {
        this.quoteIds = null;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        logMessage('start', 'Starting batch job');
        
        String query = 'SELECT Id, Shipping_and_Handling__c, Shipping_and_Handling_Value__c ' +
               'FROM SBQQ__Quote__c ';
        
        if (quoteIds != null && !quoteIds.isEmpty()) {
                query += ' WHERE Id IN :quoteIds';
        }else if(!Test.isRunningTest()){
            query += 'WHERE Shipping_and_Handling__c != null and Shipping_and_Handling__c != 0 AND Shipping_and_Handling_Value__c = null ';        
        }  

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<SBQQ__Quote__c> scope) {
        Logger.setFunctionalityType('ShippingHandlingValueUpdate');
        logMessage('execute', 'Processing batch of ' + scope.size() + ' records');
        
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        Integer recordsProcessed = 0;
        Integer recordsUpdated = 0;
        Integer recordsFailed = 0;
        
        try {
            BuyoutQuoteLineQueueable.byPassTriggers();
            
            for (SBQQ__Quote__c quote : scope) {
                recordsProcessed++;
                if (quote.Shipping_and_Handling__c != null) {
                    quote.Shipping_and_Handling_Value__c = quote.Shipping_and_Handling__c;
                    quotesToUpdate.add(quote);
                }
            }
            
            if (!quotesToUpdate.isEmpty()) {
                Database.SaveResult[] results = Database.update(quotesToUpdate, false);
                
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (result.isSuccess()) {
                        recordsUpdated++;
                    } else {
                        recordsFailed++;
                        String errorMsg = 'Error updating Quote ID: ' + quotesToUpdate[i].Id + ' - ';
                        for (Database.Error error : result.getErrors()) {
                            errorMsg += error.getMessage() + '; ';
                        }
                        logError('execute', errorMsg);
                    }
                }
            }
            
        } catch (Exception e) {
            recordsFailed = recordsProcessed; // If exception occurs, all processed records are considered failed
            String errorMsg = 'Exception in execute method: ' + e.getMessage() + ' at line ' + e.getLineNumber();
            logError('execute', errorMsg);
        } finally {
            BuyoutQuoteLineQueueable.clearByPassTrigger();
        }
        
        logMessage('execute', 'Batch completed. Processed: ' + recordsProcessed + 
                ', Updated: ' + recordsUpdated + ', Failed: ' + recordsFailed);
    }
    
    public void finish(Database.BatchableContext bc) {
        logMessage('finish', 'ShippingHandlingValueUpdateBatch job completed');
    }
    
    /**
     * @description Helper method to handle repetitive logging (Info level)
     * @param methodName Name of the method calling the logger
     * @param message Message to log
     */
    @TestVisible
    private void logMessage(String methodName, String message) {
        LOGGER.atInfo().setMethod(methodName).setCLassName('ShippingHandlingValueUpdateBatch')
            .setExceptionOrMessage(message);
        Logger.insertMasterLogs();
    }
    
    /**
     * @description Helper method to handle repetitive logging (Error level)
     * @param methodName Name of the method calling the logger
     * @param message Message to log
     */
    @TestVisible
    private void logError(String methodName, String message) {
        LOGGER.atError().setMethod(methodName).setCLassName('ShippingHandlingValueUpdateBatch')
            .setExceptionOrMessage(message);
        Logger.insertMasterLogs();
    }
}