public with sharing class QuoteOpptyOwnerPnPPilotController {
    @AuraEnabled
    public static void updatePilotOnQuote(Id quoteId) {
       system.debug('***updatePilotOnQuote***');
        SBQQ__Quote__c  quote = [SELECT Id, SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Owner.P_P_Pilot__c,Oppty_Owner_PnP_Pilot__c FROM SBQQ__Quote__c  WHERE SBQQ__Opportunity2__c!=null AND Id = :quoteId LIMIT 1];
        
       system.debug('***quote***'+quote);
        if (quote.SBQQ__Opportunity2__c  != null) {
            system.debug('quote.Oppty_Owner_PnP_Pilot__c:'+quote.Oppty_Owner_PnP_Pilot__c);
             system.debug('quote.SBQQ__Opportunity2__r.Owner.P_P_Pilot__c:'+quote.SBQQ__Opportunity2__r.Owner.P_P_Pilot__c);
            // Oppty Owner field update on the Quote 
            if(quote.Oppty_Owner_PnP_Pilot__c != quote.SBQQ__Opportunity2__r.Owner.P_P_Pilot__c){
                quote.Oppty_Owner_PnP_Pilot__c  = quote.SBQQ__Opportunity2__r.Owner.P_P_Pilot__c;
                TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
                update quote ;
                system.debug('*** after quote***'+quote);
                system.debug('*** after quote.Oppty_Owner_PnP_Pilot__c***'+quote.Oppty_Owner_PnP_Pilot__c);
                TriggerHandler.clearBypass('GS_SBQQQuoteTriggerHandler');
            }
        }
    }
}