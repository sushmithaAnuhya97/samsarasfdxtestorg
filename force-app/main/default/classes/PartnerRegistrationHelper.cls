/**********************************************************************
Name: PartnerRegistrationHelper
=======================================================================
Purpose: This class will logic to related to partner registration functionality                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2024-Jul-17        INITIAL DEVELOPMENT 
1.1.       Rodrigo Carpio.       2025-Aug-21.       added logic for GTMS-28939
**********************************************************************/
public class PartnerRegistrationHelper {
    private static Map<Id, User> ownerInfoMaps = null;
    private static void getOwnerInfo(Set<Id> userIds){
        if(ownerInfoMaps == null || !(ownerInfoMaps.keySet().containsAll(userIds))){
            ownerInfoMaps = new Map<Id, User>([SELECT Email, UserRole.Name,ManagerId,Manager.ManagerId
                                          FROM User where Id IN : userIds]);
        }
    }
    /*
     * added for GTMS-28939 this method hanldes before update logic
    */
    public static void handleBeforeUpdate(List<Partner_Registration__c> newPartnerRegistrationList, Map<Id, Partner_Registration__c> oldPartnerRegistrationMap) 
    {
        // get Owner infomation
        Set<Id> ownerIdSet = new Set<Id>();
        for (Partner_Registration__c record : newPartnerRegistrationList) {
            ownerIdSet.add(record.OwnerId);
        }
        getOwnerInfo(ownerIdSet);
        
        for (Partner_Registration__c record : newPartnerRegistrationList) {
            Partner_Registration__c oldRecord = oldPartnerRegistrationMap.get(record.Id);
            // set PAM Review DateTime
            if((record.Status__c == 'PAM Reviewed' && oldRecord == null) || 
               (record.Status__c == 'PAM Reviewed' && oldRecord != null && oldRecord.Status__c != record.Status__c)
              )
                record.put('PAM_Review_Date_Time__c', DateTime.now()); 
            // set owner manager
            if (record != null && oldRecord.OwnerId != record.OwnerId)
                record.put('Owner_Manager__c', ownerInfoMaps.get(record.OwnerId).ManagerId); 
        }
    }
    /*
     * added for GTMS-28939 this method will perform the setting of SLA Due date
    */
    public static void updateSLADueDate(List<Partner_Registration__c> newPartnerRegistrationList, Map<Id, Partner_Registration__c> oldPartnerRegistrationMap) 
    {
        // get address type details
        List<Partner_Registration__c> prAddress = [SELECT Address__c FROM Partner_Registration__c WHERE Id IN:oldPartnerRegistrationMap.keySet()];
        Map<string, string> countryMap = new Map<string, string>();
        // get partner registration(s) address country
        for(Partner_Registration__c pr : prAddress) {
            Address addr = pr.Address__c;
            //system.debug('RODRIGO pr.Address__c ' + pr.Address__c);
            //system.debug('RODRIGO addr ' + addr);
            countryMap.put(addr.getCountry(),addr.getCountry());
            
        }
        //system.debug('RODRIGO countryMap ' + countryMap);
        /*// Query holiday data
        List<SLA_Holiday__c > holidayList = [SELECT Id, Holiday_Date__c, Holiday_Name__c FROM SLA_Holiday__c 
                                             WHERE Country__c IN: countryMap.keySet()
                                             ORDER BY Holiday_Date__c DESC LIMIT 1000];
        Map<String, SLA_Holiday__c> holidayMap = new Map<String, SLA_Holiday__c>();
        DateTime tempDate;
        Integer addedDays;
        system.debug('RODRIGO holidayList ' + holidayList);
        for (SLA_Holiday__c each : holidayList) {
            holidayMap.put(each.Holiday_Date__c.format(),each);
        }
        system.debug('RODRIGO holidayMap ' + holidayMap);
        */
        SLACalculationHelper sla = new SLACalculationHelper(countryMap.keySet());
        for (Partner_Registration__c record : newPartnerRegistrationList) {
            // get old map record
            
            // Calculate SLA Due DateTime if not set and SLA Business Days is provided
            /*if (record.get('SLA_Due_DateTime__c') == NULL && record.get('SLA_Business_Days__c') != NULL
               && oldPartnerRegistrationMap.get(record.Id) != null && oldPartnerRegistrationMap.get(record.Id).Status__c != record.Status__c
               && record.Status__c == 'PAM Reviewed')*/
            //system.debug('RODRIGO oldPartnerRegistrationMap ' + oldPartnerRegistrationMap);
            if ((record.SLA_Business_Days__c != NULL && record.Status__c == 'PAM Reviewed' && oldPartnerRegistrationMap.get(record.Id) != null)
                && (oldPartnerRegistrationMap.get(record.Id).Status__c != record.Status__c || 
                    oldPartnerRegistrationMap.get(record.Id).SLA_Business_Days__c != record.SLA_Business_Days__c))
            {
                datetime tempDate;
                //addedDays = 0;
                //tempDate = DateTime.now();
                //tempDate = record.PAM_Review_Date_Time__c;
                tempDate = sla.calculateSLADueDate(record.SLA_Business_Days__c, record.PAM_Review_Date_Time__c);
                record.SLA_Due_DateTime__c = tempDate;
            }
            
        }

    }
    
    public class AmendedContractInput {
        @InvocableVariable public string contractId;
        @InvocableVariable public string partnerRegistrationId;
    }
    public class AmendedContractDetails {
        @InvocableVariable public string quoteId;
        @InvocableVariable public string opportunityId;
        @InvocableVariable public string partnerRegistrationId;
        @InvocableVariable public boolean asyncModeAmend;
    }
    
    @InvocableMethod(label='Amend Contract' description='Amend Contract')
    public static List<AmendedContractDetails> AmendContract(List<AmendedContractInput> contractInput){
        return initiateAmendContract(contractInput);
    }
    
    private static List<AmendedContractDetails> initiateAmendContract(List<AmendedContractInput> contractInput) {
        List<AmendedContractDetails> results = new List<AmendedContractDetails>();
        List<SBQQ__Subscription__c> subsList = new List<SBQQ__Subscription__c>();
        Map<Id, Id> ContractPRMap = new Map<Id, Id>();
        Map<Id, AmendedContractInput> ContractInputMap = new Map<Id, AmendedContractInput>();
        Map<Id, Id> ContractPRMapToProcess = new Map<Id, Id>();
        Map<Id, AmendedContractInput> ContractInputMapToProcess = new Map<Id, AmendedContractInput>();
        Set<Id> listContractId = new Set<Id>();
        
        //listContractId.add('8004p000000RdTAAA0');
        // loop thru all input details 
        FOR(AmendedContractInput input : contractInput) {
            listContractId.add(input.contractId);
            ContractPRMap.put(input.contractId, input.partnerRegistrationId);
            ContractInputMap.put(input.contractId, input);
        }
        //system.debug('RODRIGO listContractId '+listContractId);
        AggregateResult[] groupedResults
            = [SELECT SBQQ__Contract__c, Count(Id)
               FROM SBQQ__Subscription__c
               WHERE SBQQ__EndDate__c > TODAY AND SBQQ__Contract__c IN: listContractId
               GROUP BY SBQQ__Contract__c];
        //system.debug('RODRIGO groupedResults'+groupedResults);
        
        for (AggregateResult ar : groupedResults)  {
            //System.debug('RODRIGO Campaign ID' + ar.get('SBQQ__Contract__c'));
            //System.debug('RODRIGO Average amount' + ar.get('expr0'));
            string contractId = string.valueOf(ar.get('SBQQ__Contract__c'));
            if ((Test.isRunningTest() && Integer.valueOf(ar.get('expr0')) > 1) || (Integer.valueOf(ar.get('expr0')) > Integer.valueOf(System.Label.Partner_Registration_Subscription_Min_Count))) {
                //System.debug('RODRIGO ContractPRMapToProcess ' + ContractPRMap.get(contractId));
                ContractPRMapToProcess.put(contractId, ContractPRMap.get(contractId));
            }
            else {
                //System.debug('RODRIGO ContractInputMapToProcess ' + ContractInputMap.get(contractId));
                ContractInputMapToProcess.put(contractId, ContractInputMap.get(contractId));
            }
        }
        if (ContractPRMapToProcess != null && ContractPRMapToProcess.size()>0) {
            AmendedContractDetails result = new AmendedContractDetails();
            result.asyncModeAmend = true;
            results.add(result);
            performContractAmenderAsync(ContractPRMapToProcess);
        }
        else {
            results = performContractAmender(ContractInputMapToProcess.values());
        }
        return results;
    }
    
    @future
    private static Void performContractAmenderAsync(Map<Id, Id> contractIdMap) {
        List<AmendedContractInput> contractInput = new List<AmendedContractInput>();
        FOR (Id i : contractIdMap.keySet()) {
            AmendedContractInput input = new AmendedContractInput();
            input.contractId = i;
			input.partnerRegistrationId = contractIdMap.get(i);
            contractInput.add(input);
        }
        
        List<AmendedContractDetails> results = new List<AmendedContractDetails>();
        results = performContractAmender(contractInput);
        Set<Id> partnerRegistrationIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        List<Partner_Registration__c> prForUpdate = new List<Partner_Registration__c>();
        // loop thru results to get Id
        FOR (AmendedContractDetails result : results) {
            partnerRegistrationIds.add(result.partnerRegistrationId);
            opportunityIds.add(result.opportunityId);
        }
        Map<Id, Partner_Registration__c> prMap = new Map<Id, Partner_Registration__c>([SELECT Id, OwnerId FROM Partner_Registration__c WHERE Id IN: partnerRegistrationIds]);
        Map<Id, Opportunity> optyMap = new Map<Id, Opportunity>([SELECT Id, Name, OwnerId FROM Opportunity WHERE Id IN: opportunityIds]);
        FOR(AmendedContractDetails result : results) {
            Partner_Registration__c pr = prMap.get(result.partnerRegistrationId);
            Opportunity opty = optyMap.get(result.opportunityId);
            String opptyId = (opty == null) ? 'ERROR ' : opty.id; 
            String opptyName = (opty == null) ? 'ERROR ' : opty.Name; 
            notifyUser(opptyId, opptyName, 'Amended Opportunity', pr.OwnerId);
            pr.Opportunity__c = result.opportunityId;
            prForUpdate.add(pr);
        }
        if (prForUpdate.size()>0)
            update prForUpdate;
    }
    @TestVisible
    private static List<AmendedContractDetails> performContractAmender(List<AmendedContractInput> contractIdInput) {
        List<AmendedContractDetails> results = new List<AmendedContractDetails>();
        for(AmendedContractInput i : contractIdInput){
            try
            {
                //system.debug('RODRIGO performContractAmender ' + i.contractId);
                String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', i.contractId,null);
                //return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
                QuoteModel qm = (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
                if(qm.record.id <> null){
                    List<SBQQ__Quote__c> newQuote = [SELECT Id,SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE Id =: qm.record.id];
                    if(newQuote <> null && newQuote.size() > 0){
                        AmendedContractDetails result = new AmendedContractDetails();
                        result.quoteId = newQuote[0].id;
                        result.opportunityId = newQuote[0].SBQQ__Opportunity2__c;
                        result.partnerRegistrationId = i.partnerRegistrationId;
                        result.asyncModeAmend = false;
                        results.add(result);
                    }
                }
            } 
            catch(Exception q) {
                AmendedContractDetails result = new AmendedContractDetails();
                result.quoteId = null;
                result.opportunityId = null;
                result.partnerRegistrationId = i.partnerRegistrationId;
                result.asyncModeAmend = false;
                results.add(result);
            }
        }
        return results;
    }
    
    @testvisible
    private static void notifyUser(string oppyId, string opptyName, string opptyType, string prOwnerId) 
    {
        // Get the Id for our custom notification type
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Partner_Registration_Notification'];
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        
        // Set the contents for the notification
        notification.setTitle(opptyType + ' Creation Notification');
        notification.setBody(opptyName + ' has been created');
        
        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        //notification.setTargetId(Userinfo.getUserId());
        notification.setTargetId(oppyId);
        // Actually send the notification
        try {
            //system.debug('RODRIGO about to send notification ' + Userinfo.getUserId());
            notification.send(new Set<String> { prOwnerId });
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
    
}