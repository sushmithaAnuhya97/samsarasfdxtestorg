/**
 * @description       : Helper class for recalculating quotes in Salesforce CPQ.
 *                      This class provides a method to trigger recalculation of quotes by updating the Recalculate_Quote__c field.
 * @author            : mausam.singh@samsara.com
 * @group             : 
 * @last modified on  : 03-18-2025
 * @last modified by  : Mausam Singh
**/
public with sharing class QuoteCalculatorHelper {

    @future
    public static void calculateQuotes(Set<Id> quoteIds) {
        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();
        for (Id quoteId : quoteIds) {
            quoteMap.put(quoteId, new SBQQ__Quote__c(Id = quoteId, Recalculate_Quote__c = true));     
        }
        if (!quoteMap.isEmpty()) {
            GS_SBQQQuoteServiceAsync.asyncContext = 'CopyQuoteFieldsToOppty';
            update quoteMap.values();
        }
    }
}