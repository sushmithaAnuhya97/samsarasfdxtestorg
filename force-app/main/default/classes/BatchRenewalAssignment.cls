/*
* Test Class   :   BatchRenewalAssignmentTest
* Coverage     :   TBD
* Description  :   This batch apex updates Renewal AE ownership from the Renewal Pool at the 180 day mark from Contract End Date
* Related Jira :   GTMS
* *************************************************************************************************************
* 3/2/2021 Ron - Created
*/
global class BatchRenewalAssignment implements Database.Batchable<sObject>, Schedulable{
    global Database.Querylocator start(Database.BatchableContext BC) {
        system.debug(Logginglevel.INFO, 'batchRenewalQuery'+System.Label.Renewal_Assignment_Batch_Query);
        return Database.getQueryLocator(System.Label.Renewal_Assignment_Batch_Query);
    } 
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        system.debug(Logginglevel.INFO, 'batchRenewalScope'+scope);
        Map<Id, Opportunity> oppAssignmentMap = new Map<Id, Opportunity>();
        for(Opportunity opp : scope) {
            Integer daysBetween = (System.Today().daysBetween(Date.valueOf(opp.SBQQ__RenewedContract__r.EndDate)));
            system.debug(Logginglevel.INFO, 'daysBetween'+daysBetween);
            system.debug(Logginglevel.INFO, 'Opp ID '+opp.Id);
            if(daysBetween <= 180){
                opp.OwnerId = opp.Account.Renewal_AE__c;
                oppAssignmentMap.put(opp.Id, opp);
            }
        }

        Database.Update(oppAssignmentMap.values(), false);
    }
    
    global void finish(Database.BatchableContext BC) {
        
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id =: BC.getJobId()];
        
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'no-reply@samsara.com'];
		
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {System.Label.Email_Auto_Renewal_Batch, 'harsha.kanikicherla@samsara.com'};
        mail.setToAddresses(toAddress);
        mail.setOrgWideEmailAddressId(owea.get(0).Id);
        mail.setSubject('BatchRenewalAssignment Apex Job status is ' + apexJob.Status);
        mail.setPlainTextBody('Hello Team,\n\nThe BatchRenewalAssignment batch Apex job processed ' + 
                              apexJob.TotalJobItems + ' batches with '+ 
                              apexJob.NumberOfErrors + 
                              ' failures.\n\nPlease refer to this Report: https://samsara--renewaluat.lightning.force.com/lightning/r/Report/00O7e000000vEh1EAE/view\n\nThanks\nGTMS Team');
        
        if(apexJob.NumberOfErrors > 0)
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    global void execute(SchedulableContext sc)
    {
        BatchAutoRenewOpportunities b = new BatchAutoRenewOpportunities();
        database.executebatch(b, 1);
    }
}