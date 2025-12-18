public without sharing class GS_QuoteEventService {
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    Static Map<Id, Quote_Save__e > quoteSaveEvents = new Map<Id, Quote_Save__e >();
    public static boolean recursionCheck = false;
    /**
     * Publish the QuoteEvent
     * @param lineIds
     */
    public static void publishQuoteEvent(set<Id> QuoteIds) {
        System.debug('====== publishQuoteEvent');
        //Set<Id> ids = new Set<Id>(QuoteIds);
        QuoteEvent__e event = new QuoteEvent__e(Event_Data__c = Json.serialize(QuoteIds));
        List<QuoteEvent__e> eventList = new List<QuoteEvent__e>();
        eventList.add(event);
        List<Database.SaveResult> results = EventBus.publish(eventList);
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                thisLogger.logDebug('Successfully published QuoteEvent__e event.');
                return;
            } else {
                thisLogger.logDebug('Failed to publish QuoteEvent__e event.');
            }
        }
    }
    public void createQuoteSavePE(List<SBQQ__Quote__c> quoteList) {
        for(SBQQ__Quote__c q : quoteList) {
            if(!recursionCheck && q.SBQQ__Primary__c && !quoteSaveEvents.containsKey(q.Id)) {
                quoteSaveEvents.put(q.Id, new Quote_Save__e(Quote_Id__c = q.Id));
            }
        }
        system.debug('******quoteSaveEvents***** ' + quoteSaveEvents);
        if(!quoteSaveEvents.values().isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(quoteSaveEvents.values());
            recursionCheck = true;
        }
    }
}