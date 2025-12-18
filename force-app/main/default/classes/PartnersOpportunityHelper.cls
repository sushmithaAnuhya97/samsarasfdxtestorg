/**********************************************************************
Name: PartnersOpportunityHelper
Test Class: PartnerOpportunityHelper_TEST
-----------------------------------------------------------------------
Purpose: This class contains the logic related to Partners related Opportunities.
-----------------------------------------------------------------------
History  
TICKET		AUTHOR			DATE		DETAIL
GTMS-26731 	Vijaychandra	3/24/25		Added Rebate Opportunity creation
GTMS-26110	Rodrigo Carpio	3/24/25	    To add logic to send Paid Influence notification
***********************************************************************/ 
public class PartnersOpportunityHelper {
    public PartnersOpportunityHelper() {

    }
    //3/24/25 Vijaychandra AMARANENI --START-- (GTMS-26731)
    /*************************************************
     * Description: Logic to segregarte moved to closing Opportunities to create Rebate Opportunities for all CR which are eligible for payout.
     * newOpptyList:  Trigger.New
     * oldOppMap: Trigger.oldMap
	*/
    public static void opptyAfterClosing(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap){
        Map<Id,Opportunity> closingOpptyMap = new Map<Id,Opportunity>();
        for(Opportunity oppty : newOppList){
            if(oppty.StageName == 'Closing' && oppty.StageName <> oldOppMap.get(oppty.Id).StageName && oppty.Type == 'Revenue Opportunity'){
                closingOpptyMap.put(oppty.Id,oppty);
            }
        }
        if(!closingOpptyMap.isEmpty()){
            //sendPaidInfluenceNotification(closingOpptyMap);Commented as per rodrigos suggestion
            if(!System.isQueueable() && !System.isScheduled() && !System.isFuture() && !System.isBatch()){
                System.enqueueJob(new rebateCreationQueuable(new List<Id>(closingOpptyMap.keySet())), 1);
            }
            else{
                createRebateOpportunities(new List<Id>(closingOpptyMap.keySet()));
            }
        }
    }
    //3/24/25 --END-- (GTMS-26731)

    
    //3/24/25 Vijaychandra AMARANENI --START-- (GTMS-26731)
    /*************************************************
     * Description: Logic to create Rebate Opportunities for all CR which are eligible for payout.
     * oppIdList:  opportunity Ids
	*/
    public static void createRebateOpportunities(List<Id> OppIdList){
        List<Opportunity> opptyListToInsert = new List<Opportunity>();
        List<Channel_Relationship__c> crList = new List<Channel_Relationship__c>([SELECT Id,Channel_Partner__c,Opportunity__c,Close_Date__c,Eligible_For_Payout__c,Customer_Account__c,Opportunity__r.CurrencyIsoCode,Opportunity__r.Notes__c, Opportunity__r.Account.Name,Opportunity__r.Probability, Channel_Partner__r.CurrencyIsoCode 
                                                                                    FROM Channel_Relationship__c WHERE Opportunity__c IN :oppIdList AND Opportunity__r.Probability >=95 AND Eligible_For_Payout__c = 'Yes']);
        

        Set<Id> partnerIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        Map<String, Opportunity> partnerOpptyMap = new Map<String, Opportunity>();
        List<Opportunity>  rebateOpptyList = new List<Opportunity>();
        Opportunity rebateOppty;
        string returnRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Return_Opportunity').getRecordTypeId();  
        for(Channel_Relationship__c cr:crList){
            oppIdSet.add(cr.Opportunity__c);
            partnerIdSet.add(cr.Channel_Partner__c);
        }
        for(Opportunity o:[SELECT id,Returning_Opportunity__c,Referral_Partner__c FROM Opportunity WHERE Returning_Opportunity__c IN: oppIdSet AND Referral_Partner__c IN:partnerIdSet AND RecordTypeId =:returnRecordTypeId AND Type=:'Rebate']){
            string keyString = o.Returning_Opportunity__c + '-' + o.Referral_Partner__c;
            partnerOpptyMap.put(keyString, o);
        }

        for(Channel_Relationship__c cr:crList){
            string keyString = cr.Opportunity__c + '-' + cr.Channel_Partner__c;
            if(!partnerOpptyMap.containsKey(keyString) && cr.Opportunity__r.Probability >=95 && cr.Eligible_For_Payout__c == 'Yes'){
                rebateOppty = new Opportunity();
                rebateOppty.Name = cr.Opportunity__r.Account.Name+' Rebate Partner Payout';
                rebateOppty.AccountId = cr.Customer_Account__c;
                rebateOppty.Can_Create__c = true;
                rebateOppty.CloseDate=cr.Close_Date__c;
                rebateOppty.CurrencyIsoCode= cr.Channel_Partner__r.CurrencyIsoCode;
                rebateOppty.Exclude_from_Xactly__c = true;
                rebateOppty.Notes__c = cr.Opportunity__r.Notes__c;
                rebateOppty.Overwrite_Validation_Rule__c = true;
                rebateOppty.OwnerId = SYSTEM.LABEL.Return_Oppty_OwnerId;
                rebateOppty.Rebate_Type__c = system.Label.Partner_Referral;
                rebateOppty.RecordTypeId = returnRecordTypeId;
                rebateOppty.Referral_Partner__c = cr.Channel_Partner__c;
                rebateOppty.StageName = 'Return Created';
                rebateOppty.Type= 'Rebate';
                rebateOppty.Returning_Opportunity__c = cr.Opportunity__c;

                rebateOpptyList.add(rebateOppty);
            }
        }
        if(rebateOpptyList.size() > 0){
            insert rebateOpptyList;
        }    

    }

    public class rebateCreationQueuable implements Queueable {
        private List<Id> oppIdList;
        public rebateCreationQueuable(List<Id> oppIdList){
            this.oppIdList = oppIdList;
        }
        public void execute(QueueableContext context) {
            createRebateOpportunities(oppIdList);
        }
    }
    //3/24/25 --END-- (GTMS-26731)
    
    /* commented below cosed as part Rodrigo's suggestion
    // added for GTMS-26110
    public static void sendPaidInfluenceNotification(Map<Id, Opportunity> newOppMap){
        List<AggregateResult> lstCR = [SELECT Opportunity__c 
                                       FROM Channel_Relationship__c 
                                       WHERE Opportunity__c IN : newOppMap.keySet() AND Partner_Interaction_Type__c = 'Partner Influenced'
                                       AND CR_Status__c != 'AE Confirmed' AND CR_Status__c != 'AE Rejected' 
                                       AND CR_Status__c != 'Denied at Close' group by Opportunity__c];
        List<Task> taskToBeCreated = new List<Task>();
        CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Paid_Influence_Notification'];
        FOR(AggregateResult ar : lstCR) {
            string cnTypeId = System.Label.Paid_Influence_Custom_Notification;
            
            String recordId = (String)ar.get('Opportunity__c');
            
            Opportunity oppty = newOppMap.get(recordId);
            Id userId = oppty.OwnerId;
            Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
            customNotificationObj.setBody('opportunity with a paid influence deal registration');
            customNotificationObj.setTitle('opportunity with a paid influence');
            customNotificationObj.setNotificationTypeId(cnType.Id);
            
            customNotificationObj.setTargetId(recordId);
            customNotificationObj.send(new Set<String> {userId});
            
            Task forCreate = new Task();
            forCreate.WhatId = recordId;
            forCreate.ActivityDate = System.Today();
            forCreate.Priority = 'High';
            forCreate.Status = 'Open';
            forCreate.Description = 'opportunity with a paid influence deal registration';
            forCreate.Subject = 'opportunity with a paid influence';
            forCreate.IsReminderSet = true;
            forCreate.OwnerId = oppty.OwnerId;
            taskToBeCreated.add(forCreate);
        }
        if(taskToBeCreated != null && taskToBeCreated.size()>0)
            insert taskToBeCreated;
    }
    */
}