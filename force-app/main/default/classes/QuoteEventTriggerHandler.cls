/**
 * @author      Unnat Shrestha
 * @story       
 * @description Platform Event Handler for Quote update
 *              This event will be triggered during Remorse Refund processing when Mulesoft sets the status to Completed.
 *              The event will update the counter, which will trigger the CPQ calculation cycle.
 *              
 */

public class QuoteEventTriggerHandler {
    
    //handle event
    public void processPlatformEvent(List<QuoteEvent__e> newQuoteList) {
        system.debug('====== Entered QuoteEventTriggerHandler ==> processPlatformEvent :: QuoteIds ==> '+ newQuoteList);
        set<Id> quoteIds = new set<Id>();
        List<QuoteEvent__e> events = newQuoteList;
        for (QuoteEvent__e event: events){
            quoteIds.addAll((set<Id>)Json.deserialize(event.Event_Data__c, set<Id>.class));
        }
        
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Mulesoft_Status__c, Retrigger_CPQ_Calculation__c FROM SBQQ__Quote__c WHERE Id IN: quoteIds];
        for(SBQQ__Quote__c qt: quoteList){
            qt.Retrigger_CPQ_Calculation__c = qt.Retrigger_CPQ_Calculation__c + 1;
            system.debug('====== QuoteEventTriggerHandler ==> processPlatformEvent :: Retrigger_CPQ_Calculation__c :: '+ qt.Retrigger_CPQ_Calculation__c);
        }
        update quoteList;
    }
}