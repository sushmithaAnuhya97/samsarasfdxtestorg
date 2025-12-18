/*
* Test Class   :   BatchUpdateContactTest
* Coverage     :   100%
* Description  :   This batch apex updates ACV_Bookings__c, Opportunity_Stage__c fields on OpportunityContactRole
* Related Jira :   GTMS-1099
* *************************************************************************************************************
* 8/12/20 Satya - (GTMS-1099): Created
* 9/15/20 Satya - (GTMS-1564): Adding some conditional filtering to handle duplicate records
*/
global class BatchUpdateContact implements Database.Batchable<sObject>, Schedulable {
    
    global Database.Querylocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(System.Label.Update_Contact_Cadence_Fields_Query);
    } 
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        
        for(Opportunity opp : scope) {
            if(opp.Related_Contact__c != null) {
                if(contactMap.containsKey(opp.Related_Contact__r.Id)) {
                    if(opp.Account.First_Purchase_Date__c == null && contactMap.get(opp.Related_Contact__r.Id).ACV_Bookings__c < opp.ACV_Bookings__c) {
                        contactMap.get(opp.Related_Contact__r.Id).ACV_Bookings__c = opp.ACV_Bookings__c;
                        contactMap.get(opp.Related_Contact__r.Id).Opportunity_Stage__c = opp.StageName;
                    }
                    else if(opp.CloseDate == opp.Account.First_Purchase_Date__c){
                        contactMap.get(opp.Related_Contact__r.Id).ACV_Bookings__c = opp.ACV_Bookings__c;
                        contactMap.get(opp.Related_Contact__r.Id).Opportunity_Stage__c = opp.StageName;
                    }
                }
                else {
                    contactMap.put(opp.Related_Contact__r.Id, new Contact(
                        Id = opp.Related_Contact__r.Id,
                        ACV_Bookings__c = opp.ACV_Bookings__c, 
                        Opportunity_Stage__c = opp.StageName
                    ));
                }
                
            }
        }
        if(!contactMap.isEmpty()) {
            update contactMap.values();
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
    global void execute(SchedulableContext sc)
    {
        BatchUpdateContact b = new BatchUpdateContact();
        database.executebatch(b);
    }
}