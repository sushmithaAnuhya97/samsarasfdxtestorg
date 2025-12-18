public with sharing class GS_OpportunityEventPublisherService {

    @TestVisible private static Boolean hasPublishedAnEvent = false;

    public void createR2ShipCWPlatformEvent(Map<Id, Opportunity> platformOpps){
        List<R2Ship_CW_Opportunity__e> r2ShipCWs = new List<R2Ship_CW_Opportunity__e>();
        List<Database.SaveResult> results;

        for(Opportunity o: platformOpps.values()){

            if((o.Type == 'Revenue Opportunity' || o.Type == 'Parent Opportunity') && o.StageName == 'Orders Processing'){
                R2Ship_CW_Opportunity__e r2ShipCW = new R2Ship_CW_Opportunity__e(   Is_Closed_Won__c = false,
                                                                                    Revenue_Opportunity__c = true, // THis will hold true for 'Parent/Revenue' types
                                                                                    AccountId__c = o.AccountId,
                                                                                    OpportunityId__c = o.Id,
                                                                                    Send_Virtual_Bell__c = o.Send_Virtual_Bell__c);
    
                r2ShipCWs.add(r2ShipCW);
            }
        }
        if(r2ShipCWs.size() > 0){
            results = EventBus.publish(r2ShipCWs);
            hasPublishedAnEvent = true;
        }

        if(results != null && results.size() > 0){
            for(Database.SaveResult sr : results){
                if(sr.isSuccess()){
                    System.debug(LoggingLevel.INFO, 'Successful Event Publish');
                }
                else{
                    for(Database.Error err: sr.getErrors()){
                        System.debug(LoggingLevel.INFO, 'Error Returned: '+err.getStatusCode()+' - '+err.getMessage());
                    }
                }
            }
        }
    }
}