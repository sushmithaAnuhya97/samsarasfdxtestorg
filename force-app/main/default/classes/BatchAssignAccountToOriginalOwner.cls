/*
* Test Class   :   BatchAssignAccountToOriginalOwnerTest
* Coverage     :   100%
* Description  :   This batch apex account owner back to Original_Owner_for_Recycling_Campaign__c
* Related Jira :   GTMS-537
* *************************************************************************************************************
* 9/15/20 Satya - (GTMS-537): Created
*/
global class BatchAssignAccountToOriginalOwner implements Database.Batchable<sObject>, Schedulable {
    
    global Database.Querylocator start(Database.BatchableContext BC) {
        Date sevenDaysAgo = system.today() - 7;
        return Database.getQueryLocator(System.Label.Query_BatchAssignAccountToOriginalOwner);
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> scope) {
        
        Map<Id, Account> mapAccounts = new Map<Id, Account>();
        for(Contact con : scope) {
            Integer daysSinceLastContact = con.Account.Account_Assignment_Date__c <> null ? HelperClass.calculateWorkingDays(con.Account.Account_Assignment_Date__c.date(), System.Today()) : 0;
            if(daysSinceLastContact >= 7) {
                if(!mapAccounts.containsKey(con.AccountId))
                mapAccounts.put(con.AccountId,
                    new Account(
                        Id = con.Account.Id, 
                        OwnerId = con.Account.Original_Owner_for_Recycling_Campaign__c, 
                        Original_Owner_for_Recycling_Campaign__c = null
                    ));
            }
        }
        if(!mapAccounts.isEmpty()) {
            update mapAccounts.values();
        }   
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
    global void execute(SchedulableContext sc)
    {
        BatchAssignAccountToOriginalOwner b = new BatchAssignAccountToOriginalOwner();
        database.executebatch(b);
    }

}