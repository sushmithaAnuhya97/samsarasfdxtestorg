/*
* Test Class   :   BatchCreateTrialReturnTest
* Coverage     :   100%
* Description  :   This batch apex updates ACV_Bookings__c, Opportunity_Stage__c fields on OpportunityContactRole
* Related Jira :   GTMS-1515
* *************************************************************************************************************
* 8/12/20 Satya - (GTMS-1515): Created
*************************************************************************************************************
* Modification: GTMS-4041 = Email functionality set up in Finish method and stateful added. @Apisero Team
*/
global class BatchCreateTrialReturn implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    public integer countOfSuccessOpp = 0;
    public integer countOfSuccessOppLines = 0;
    public integer countOfErrorOpp = 0;
    public integer countOfErrorOppLines = 0;
    
    global Database.Querylocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(System.Label.Query_Create_Return_Trial_Return_Opps);
    } 
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        Map<Id, Opportunity> mapTrialOpps = new Map<Id, Opportunity>();
        Map<Id, List<OpportunityLineItem>> mapLines = new Map<Id, List<OpportunityLineItem>>();
        
        for(Opportunity opp : scope) {
            Opportunity trialOpp = opp.clone(false, true);
            trialOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
            trialOpp.Name = trialOpp.Name + '- RTN';
            trialOpp.CloseDate = System.today();
            trialOpp.StageName = 'Return Created';
            trialOpp.Probability = 10;
            trialOpp.Type = 'Free Trial Return';
            trialOpp.Return_Products_To__c = 'Operations';
            trialOpp.Tracking_Number__c = '';
            trialOpp.Shipmate_Preference__c = 'ShippingPreference-000010';
            trialOpp.Returning_Opportunity__c = opp.Id;
            trialOpp.Shipping_Address_NEW__c = opp.Shipping_Address_NEW__c;
            trialOpp.Pricebook2Id = opp.Pricebook2Id;
            trialOpp.AccountId = opp.AccountId;
            trialOpp.OwnerId = opp.OwnerId;
            trialOpp.CurrencyIsoCode  = opp.CurrencyIsoCode;
            mapTrialOpps.put(opp.Id, trialOpp);
            mapLines.put(opp.Id, opp.OpportunityLineItems);
        }
        if(!mapTrialOpps.isEmpty()) {
            Database.saveresult[] listResult =  Database.insert(mapTrialOpps.values(),false);
            for(Database.SaveResult result : listResult) {
                if (result.isSuccess()) {
                    countOfSuccessOpp++;
                }
                else {
                    countOfErrorOpp++;
                }
            }
        }
        List<OpportunityLineItem> newoppLinesList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oppLinesListClone = new List<OpportunityLineItem>();
        for(Id oppId : mapTrialOpps.keySet()) {
            Opportunity opp = mapTrialOpps.get(oppId);
            newoppLinesList = mapLines.get(oppId);
            for(OpportunityLineItem oli : newoppLinesList) {
                OpportunityLineItem olic = oli.clone();
                olic.OpportunityId = opp.Id;
                olic.PricebookEntryId = oli.PricebookEntryId; 
                olic.Quantity = -oli.Quantity; 
                olic.Ship_To__c = oli.Ship_To__c;
                olic.Ship_Frm_Address__c = oli.Ship_Frm_Address__c;
                oppLinesListClone.add(olic);
            }
        }
        
        if (!oppLinesListClone.isEmpty()) {
            Database.saveresult[] listResult =  Database.insert(oppLinesListClone,false);
            for(Database.SaveResult result : listResult) {
                if (result.isSuccess()) {
                    countOfSuccessOppLines++;
                }
                else {
                    countOfErrorOppLines++;
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        AutoRejectRemorseRefunds autoRejectRemorseRefund = new AutoRejectRemorseRefunds();
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id =: BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> listOfAddresses = new List<String>();
        listOfAddresses.addAll(System.Label.BatchCreateTrialReturnEmailAddress.split(';'));
        mail.setToAddresses(listOfAddresses);
        mail.setSubject('Apex Job status is ' + apexJob.Status);
        String body = 'Number of batched processed is '+apexJob.TotalJobItems+'. Below is status of batches processed: <br></br><br></br>';
        body += 'Number of success opportunity records : '+countOfErrorOpp+'<br></br>';
        body += 'Number of failed opportunity records : '+countOfSuccessOpp+'<br></br>';
        body += 'Number of success opportunity line items records : '+countOfSuccessOppLines+'<br></br>';
        body += 'Number of failed opportunity line items records : '+countOfErrorOppLines+'<br></br><br></br>';
        body += 'Regards,<br></br>';
        body += 'Samsara Salesforce Support Team';
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        Database.executebatch(autoRejectRemorseRefund, 5);
    }
    
    global void execute(SchedulableContext sc)
    {
        BatchCreateTrialReturn b = new BatchCreateTrialReturn();
        database.executebatch(b, 5);
    }
}