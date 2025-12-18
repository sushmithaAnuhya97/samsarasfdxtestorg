/*
* NOV 15th, 2021 Anil bogadi(GTMS-5013) Send ADR demo emails after 48 hours
*/
global class ADRTransferDemoScheduledBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date nextTwoDays = System.today().addDays(-2);
        Date nextThreeDays = System.today().addDays(-3);
        system.debug('nextTwoDays -------> '+nextTwoDays);
        system.debug('nextThreeDays -------> '+nextThreeDays);
        String query = 'SELECT Id, AE_Demo_Transfer_To__c, AE_Manager_Name_Copy_at_Transfer__c, AE_Demo_Transfer_To__r.Email FROM ADR_Transfer_Log__c';
        query += ' WHERE ADR_Transfer_Status__c = \'Demo Scheduled\' AND ADR_Demo_Date__c <=: nextTwoDays AND ADR_Demo_Date__c >: nextThreeDays';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<ADR_Transfer_Log__c> ADRTransferLogs){
        Map<String, String> userNameEmailMap = new Map<String, String>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        String templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName='ADR_Transfer_Log_Demo_Scheduled'].Id;
        List<String> toAddresses = new List<String>();
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'no-reply@samsara.com' LIMIT 1];
        List<User> users = [SELECT Id, Name, Email FROM User WHERE IsActive = true];
        for(User usr : users){
            userNameEmailMap.put(usr.Name, usr.Email);  
        }
        if(ADRTransferLogs.size() > 0){
            for(ADR_Transfer_Log__c ADRLog : ADRTransferLogs){
                toAddresses = new List<String>();
                if(ADRLog.AE_Demo_Transfer_To__c != null){
                    if(ADRLog.AE_Demo_Transfer_To__r.Email != null){
                        toAddresses.add(ADRLog.AE_Demo_Transfer_To__r.Email);      
                    }
                }
                if(ADRLog.AE_Manager_Name_Copy_at_Transfer__c != null){
                    if(userNameEmailMap.get(ADRLog.AE_Manager_Name_Copy_at_Transfer__c) != null){
                        toAddresses.add(userNameEmailMap.get(ADRLog.AE_Manager_Name_Copy_at_Transfer__c));
                    }
                }
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                if ( owea.size() > 0 ) {
               email.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                email.setToAddresses(toAddresses);
                email.setTemplateID(templateId);
                email.setSaveAsActivity(false);
                email.setTargetObjectId(ADRLog.AE_Demo_Transfer_To__c);
                email.setWhatId(ADRLog.Id);
                mails.add(email);
            }
            if(mails.size() > 0){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);  
            }
                 
        }
        
    }
    global void finish(Database.BatchableContext BC){
        
    }
}