/* 
 * Class Created:  08/08/2022
 * 08/03/22 Raghav - (GTMS-6072) Consolidated multiple unmanaged trigger, workflow field updates and process builder into one
 */ 
trigger AccountSyncSubscriber on Account_Sync_Event__e (after insert) {
	Set<Id> accIds = new Set<Id>();
    for(Account_Sync_Event__e accSyncEvent : Trigger.NEW){
        accIds.add(accSyncEvent.Id__c);
    }
    
    List<Account> accountsToSync = new List<Account>();
    Map<Id, Account> accountsToSyncMap = new Map<Id, Account>();
    if(accIds.isEmpty()){
        return;
    }

    accountsToSync = [SELECT Id, Sync_in_Progress__c, Push_to_Netsuite__c, Netsuite_Id__c
                      FROM Account
                      WHERE Id in :accIds 
                      and sync_in_progress__c = false 
                      and Push_to_Netsuite__c = false];
    
    if(accountsToSync.isEmpty()){
       return; 
    }

    for(Account accToSync : accountsToSync){
        accToSync.Push_to_Netsuite__c = true;
        accountsToSyncMap.put(accToSync.Id, accToSync);
    }
    try{
		 //GTMS-16269
		 //Database.update(accountsToSync);
		 Database.update(accountsToSyncMap.values());
    }
    catch(Exception ex){
        
    }
   
}