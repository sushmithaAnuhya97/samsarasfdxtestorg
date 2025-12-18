global class DeletePlatformEventMonitorRecords implements Database.Batchable<sObject>,Schedulable { 
    global String query;
    global DeletePlatformEventMonitorRecords(String query){
        this.query=query;
    }
    
    global Database.QueryLocator start(Database.BatchableContext info){ 
        return Database.getQueryLocator(query); 
    }    
    
    global void execute(Database.BatchableContext info, List<Platform_Events_Monitor__c> scope){
        Delete scope;
        Database.emptyRecycleBin(scope);  
    }   
    
    global void finish(Database.BatchableContext info){} 
    
    /**
     * 	String query = 'Select id,createddate,Object_Name__c from Platform_Events_Monitor__c where createddate<=LAST_N_DAYS:15'; 
        String nextFireTime = '0 0 22 * * ? *'; //10PM daily
        
        DeletePlatformEventMonitorRecords s = new DeletePlatformEventMonitorRecords(query); 
        System.schedule('Job Started At ' + String.valueOf(Datetime.now()), nextFireTime, s);
	*/
    global void execute(SchedulableContext sc)  {   
        Database.executeBatch(new DeletePlatformEventMonitorRecords(this.query));
    }
}