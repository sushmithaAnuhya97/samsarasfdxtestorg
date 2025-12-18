/*
 * Class Created - @Harsha 
 * Test Class - ScheduledFreeTrialInvoicesTest
 * 8/03/20 Harsha - (GTMS-1330) Scheduled on daily basis to trigger emails on FTs.
 * 9/03/20 Harsha - (GTMS-1508) Changed the query criteria.
 */
global class ScheduledFreeTrialInvoices implements Schedulable {
    global void execute(SchedulableContext sc) {
       //System.debug('CPU time before the job for the class <ScheduledFreeTrialInvoices> is scheduled: ' +  Limits.getCpuTime());
       String trialRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(); 
       Integer count = Integer.valueof(System.Label.FreeTrialInvoiceLimit);
       Set<String> segments = new Set<String> { 'industrial', 'connected worker' };
       List<Opportunity> queriedOpportunities = new List<Opportunity>([SELECT Send_Invoice__c FROM Opportunity 
                                                                       WHERE RecordType.ID =: trialRecordTypeId AND Trial_End_Date__c < TODAY 
                                                                       AND (NOT Account.Segment__c LIKE :segments) AND Send_Invoice__c = false 
                                                                       AND Free_Trial_Extension_Status__c != 'Pending' AND Account.Lifetime_Purchases_Currency__c <= 0 
                                                                       AND (Trial_Status__c = 'Open' OR Trial_Status__c = 'Return In Process') AND Deactivate__c = false  
                                                                       AND Industrial_Oppty__c = false AND StageName ='Closed Won' AND (NOT Finance_Segment__c LIKE :segments) 
                                                                       LIMIT :count]);
        List<Opportunity> updatedOpps = new List<Opportunity>();
        for(Opportunity opportunity : queriedOpportunities){
            opportunity.Send_Invoice__c = true; 
            updatedOpps.add(opportunity);
        }
        if(updatedOpps.size() > 0){
            List<Database.SaveResult> SR = Database.update(updatedOpps, false);
        }
        //System.debug('CPU time after the job for the class <ScheduledFreeTrialInvoices> is completed: ' +  Limits.getCpuTime());
        BatchCreateTrialReturn b = new BatchCreateTrialReturn();database.executebatch(b);
    }
}