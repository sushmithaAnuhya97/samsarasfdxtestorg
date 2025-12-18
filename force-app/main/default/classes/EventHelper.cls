/*
 * May-31-2023 Siddharth (GTMS-12786): Prevent Contact Status field from being changed if it is in 'Inactive - No Longer There'
*/
public class EventHelper {
    @TestVisible private static Id recordType = Schema.SObjectType.Event.getRecordTypeInfosByName().get('Demo').getRecordTypeId();

    public static void beforeInsertUpdate(List<Event> newEventList, Map<Id, Event> oldEventMap){
        
        for(Event e: newEventList){
            if(e.RecordTypeId == recordType){
                if(oldEventMap == null){
                    if( e.Demo_Status__c.contains('Completed')){
                        e.OwnerId = System.UserInfo.getUserId();
                    }
                }
                else{
                    Event oldEvent = oldEventMap.get(e.Id);
                    if( e.Demo_Status__c.contains('Completed') 
                        && !(oldEvent.Demo_Status__c.contains('Completed'))){
                        e.OwnerId = System.UserInfo.getUserId();
                    }
                }
            }  
        }
    }

    public static void postEventcreationContactUpdate(List<Event> newEventList)  {
        List<Id> ctcid = new List<Id>(); 
        
        for(Event ev: newEventList){
            ctcid.add(ev.Related_Contact__c);
        }

        Map<Id, Contact> updateContact = new Map<Id, Contact>([ SELECT  Id, 
                                                                    Status__c, Inbound_Reason_Faulty__c,
                                                                    Description 
                                                            FROM Contact 
                                                            WHERE Id IN: ctcid]);

        for(Event e: newEventList){
            if(e.RecordTypeId == recordType){
                if(e.Type == 'Standard Demo' && e.Related_Contact__c <> null){
                    Contact ct = updateContact.get(e.Related_Contact__c);
                    	//GTMS-12786
                    //commented as part of GTMS-25351
                    //if(ct.Status__c!='Inactive - No Longer There')	
                    if(ct.Inbound_Reason_Faulty__c!='Inactive - No Longer There')
                        {
                            ct.Status__c = 'Demo Scheduled';
                        }                        
                        ct.Description = String.format('{0}\n\n{1}', new List<String>{e.Description, ct.Description});
                }
            }
        }

        if(updateContact.size() > 0){
            update updateContact.values();
        }
    }

    /*
    public static void attachopptodemo(List<Opportunity> newoppList){
        List<Id> ctcId = new List<Id>();

        for(Opportunity opp: newoppList){
            ctcid.add(opp.Related_Contact__c);
        }

        List<Event> demo = [SELECT Id, 
                                   WhatId, 
                                   WhoId, 
                                   Related_Contact__c
                            FROM Event 
                            WHERE RecordType.Name = 'Demo' 
                            AND WhatId = NULL 
                            AND (WhoId IN : ctcId OR Related_Contact__c IN : ctcId) 
                            ORDER BY CreatedDate DESC];

        for(Opportunity opp: newoppList){
            if(demo.size() > 0 ){
                for(Event dm: demo){
                    if((opp.Related_Contact__c == dm.WhoId) || (opp.Related_Contact__c == dm.Related_Contact__c)){
                        dm.WhatId = opp.Id;
                    }
                }
            }
        }
        update demo;
    }
    */
}