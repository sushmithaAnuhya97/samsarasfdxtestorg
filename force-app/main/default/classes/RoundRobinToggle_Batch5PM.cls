global class RoundRobinToggle_Batch5PM implements Database.Batchable<Sobject>, Database.Stateful, Schedulable {
    //manage State to add up all errors during execution for each iteration
    Exception[] errors = new Exception[0];

    global Database.QueryLocator start(Database.BatchableContext bc){
        //Removed RR_RoleIds as part of GTMS-22259
       // List<String> RoleIds = System.Label.RR_RoleIds.split(',');
        List<String> RuleIds = System.Label.RR_RuleIds.split(',');
        
        //List<User> activeUsers = [SELECT Id FROM user WHERE IsActive = true AND Inbound_ADR_Out_Of_Office__c = false AND UserRoleId =: RoleIds ]
        List<User> activeUsers = [SELECT Id FROM user WHERE IsActive = true AND Inbound_ADR_Out_Of_Office__c = false];
        return Database.getQueryLocator([SELECT Id, Pause_Assignment__c, Assignment_Rule__c FROM RR_Assignment_Mapping__c WHERE Assignment_Rule__r.Category__c= 'Lane Four' AND Assignment_Rule__r.Name !=: RuleIds AND User__c =: activeUsers AND Pause_Assignment__c = false]);

    }
    global void execute(Database.BatchableContext bc,List<RR_Assignment_Mapping__c> rrList){
        
        for(RR_Assignment_Mapping__c rr : rrList){
            rr.Pause_Assignment__c = true;
        }

        try {
            Database.Update(rrList, false);
        } catch(Exception e){
            errors.add(e);
        }
        
    }
    global void finish(Database.BatchableContext bc){
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, ExtendedStatus, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id =: bc.getJobId()];
        
        OrgWideEmailAddress[] orgWideEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'no-reply@samsara.com'];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {System.Label.RoundRobinBatch_Email};
        mail.setToAddresses(toAddress);
        mail.setOrgWideEmailAddressId(orgWideEmail.get(0).Id);
        mail.setSubject('RoundRobinToggle_Batch Job status is ' + apexJob.Status);
        mail.setPlainTextBody('Hi Team,\n\nThe Round Robin Batch job processed ' + 
                              apexJob.TotalJobItems + ' batches with '+ 
                              apexJob.NumberOfErrors +
                              ' failures.' + 
                              '\n\nExtended Status: '+apexJob.ExtendedStatus + '\n\nException Errors: '+errors);
        
        if(apexJob.NumberOfErrors > 0)
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    global void execute(SchedulableContext sc){
        RoundRobinToggle_Batch5PM b = new RoundRobinToggle_Batch5PM();
        database.executebatch(b,200);
    }
}