/**
 * @author      Unnat Shrestha
 * @story       
 * @description Platform Event Trigger for Quote update
 *              This event will be triggered during Remorse Refund processing when Mulesoft sets the status to Completed.
 *              The event will update the counter, which will trigger the CPQ calculation cycle.
 *              
 */

trigger QuoteEventTrigger on QuoteEvent__e (After Insert) {
    system.debug('====== Entered QuoteEventTrigger');
    QuoteEventTriggerHandler quoteEventHandler = new QuoteEventTriggerHandler();
    quoteEventHandler.processPlatformEvent(Trigger.New);
}