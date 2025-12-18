public class ADRIncentiveBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    @testVisible private date fiscalMonthStartDate;
    @testVisible private date fiscalMonthEndDate;
    private boolean initiatedByAgent = false;
    @testVisible private string userId;
    @testVisible private string recordId;

    //Constructor
    public ADRIncentiveBatch(){}
    
    //Paramterised Constructor
    public ADRIncentiveBatch(String userId, boolean initiatedByAgent, string recordId){
        this.initiatedByAgent = initiatedByAgent;
        this.userId = userId;
        this.recordId = recordId;
    }

    //Schedule Apex Method
    public void execute(System.schedulableContext sc){
        Database.executeBatch(new ADRIncentiveBatch());
    }

    //LWC Invocation
    @AuraEnabled
    public static boolean invokeADRIncentiveBatchFromLWC(String userId, boolean initiatedByAgent, string recordId){

        return checkAndExecuteBatch(userId, initiatedByAgent, recordId);

        // return (string)database.executeBatch(new ADRIncentiveBatch(userId, true, recordId));
    }

    /*******************BATCH METHODS****************/

    public Database.QueryLocator start(Database.BatchableContext BC) {

        Period fiscalMonth = [SELECT StartDate, EndDate FROM Period WHERE StartDate <= TODAY AND EndDate >= TODAY AND Type = 'Month'];

        fiscalMonthStartDate = fiscalMonth.StartDate;
        fiscalMonthEndDate = fiscalMonth.EndDate;

        String query = 'SELECT Id, ADR_Transfer_Qualified_Date__c, Pipeline_Threshold_Date__c, Transfer_Points_At_Transfer_Copy__c, Opportunity__c, OwnerId, ADR_Accepted_Date__c, ';
        query += 'Opportunity__r.ACV_Bookings__c, Opportunity__r.First_Purchase__c, Owner.UserRole.Name, Owner_ADR_Segment_Alignment__c, Opportunity__r.Went_to_Qualified__c, ';
        query += 'Transfer_Points_at_Trial__c, Opportunity__r.ACV_Less_Subsidy_Buyout__c, owner.UserRoleId, ';
        query += 'Opportunity__r.Went_to_Trial__c, Opportunity__r.Went_to_Proposal__c, Opportunity__r.Went_to_Decision__c, Opportunity__r.Went_to_Purchase__c, Opportunity__r.Went_to_Closing__c, Opportunity__r.Went_to_Orders_Processing__c, ';
        query += 'Opportunity__r.Went_to_Ready_to_Ship__c, Opportunity__r.Went_to_Closed_Won__c, ';
        query += 'Opportunity__r.Went_to_Trial_Date__c, Opportunity__r.Went_to_Proposal_Date__c, Opportunity__r.Went_to_Decision_Date__c, Opportunity__r.Went_to_Purchase_Date__c, Opportunity__r.Went_to_Closing_Date__c, ';
        query += 'Opportunity__r.Went_to_Orders_Processing_Date__c, Opportunity__r.Went_to_Ready_to_Ship_Date__c, Opportunity__r.Went_to_Closed_Won_Date__c, ';
        query += 'Opportunity_Trial_Date__c FROM ADR_Transfer_Log__c ';
        
        // Append the custom label condition
        query += Label.ADRIncentiveBatch_Query_Filter != null ? 'WHERE ' + Label.ADRIncentiveBatch_Query_Filter : '';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<ADR_Transfer_Log__c> scope) {

        Map<Id, ADR_Transfer_Log__c> adrToUpdateMap = new Map<Id, ADR_Transfer_Log__c>();

        // -------------------- GTMS-29029 SKIP LOGIC START --------------------
        Set<Id> adrIds = new Map<Id, ADR_Transfer_Log__c>(scope).keySet();

        List<ADR_Transfer_Log__History> recentUpdates = [
            SELECT CreatedBy.Profile.Name, CreatedBy.UserRole.Name, Field, NewValue, CreatedDate, ParentId, parent.CreatedDate
            FROM ADR_Transfer_Log__History
            WHERE ParentId IN :adrIds
            AND Field = 'Transfer_Points_At_Transfer_Copy__c'
            ORDER BY CreatedDate DESC
        ];

        Set<Id> skipUpdateIds = new Set<Id>();

        for (ADR_Transfer_Log__History hist : recentUpdates) {

            if(hist.parent.CreatedDate == hist.CreatedDate){
                continue;
            }
            // Check if update is by System Admin or Sales Ops
            if (hist.CreatedBy.Profile.Name == 'System Administrator' 
            || hist.CreatedBy.Profile.Name == 'Sales Ops Profile') {
                skipUpdateIds.add(hist.ParentId);
            } 
        }
        // -------------------- GTMS-29029 SKIP LOGIC END --------------------

        for(ADR_Transfer_Log__c adrRec :scope){

            //Based on the ADR & its opty, decide if the threshold is met
            boolean thresholdMet = meetsACVThreshold(adrRec.Owner.UserRole.Name??'', adrRec.Opportunity__r.ACV_Less_Subsidy_Buyout__c??0, adrRec.Opportunity__r.First_Purchase__c);

            //Process only when the ADR Transfer Record is in the current Fiscal Month
            if(adrInFiscalMonth(adrRec)) updateTransferPointAtTransferCopy(adrRec, adrToUpdateMap, thresholdMet, skipUpdateIds); // Jira 24160
            
            //When Transfer_Points_at_Trial__c is 0 and the threshold is met, process the ADR Transfer Record.
            if(thresholdMet && adrRec.Transfer_Points_at_Trial__c != 1) updateTransferPointsAtTrialPlus(adrRec, adrToUpdateMap); // Jira 24161
        }
        
        if (!adrToUpdateMap.isEmpty()) {
            update adrToUpdateMap.values();
            updateTrailForQuotaTransferLogs(adrToUpdateMap);
        }

    }

    public void finish(Database.BatchableContext bc) {
        if (!initiatedByAgent) return;

        AsyncApexJob asyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId() LIMIT 1];

        notifyUser(asyncJob.NumberOfErrors, (String)asyncJob.Id);
    }

    /*******************BATCH METHODS END****************/

    /**********************HELPER METHODS*******************/

    private void updateTransferPointAtTransferCopy(ADR_Transfer_Log__c adrRec, Map<Id, ADR_Transfer_Log__c> adrToUpdateMap, boolean thresholdMet, Set<Id> skipUpdateIds) {

        // If threshold is met and transfer is 1 OR threshold is not met and transfer is 0, update not requried
        if(thresholdMet && adrRec.Transfer_Points_At_Transfer_Copy__c == 1
        || !thresholdMet && (adrRec.Transfer_Points_At_Transfer_Copy__c == 0 || adrRec.Transfer_Points_At_Transfer_Copy__c == null))
        return;

        // GTMS-29029 skip logic
        if (adrRec.Id != null && !skipUpdateIds.contains(adrRec.Id)) {
            adrToUpdateMap.put(adrRec.Id, new ADR_Transfer_Log__c (Id = adrRec.Id, Transfer_Points_At_Transfer_Copy__c = thresholdMet ? 1 : 0));
        }
        
        // When Pipeline Threshold Date is empty, populate it with current date.
        if(adrRec.Pipeline_Threshold_Date__c == null){
            if(!adrToUpdateMap.containsKey(adrRec.Id)) {
                adrToUpdateMap.put(adrRec.Id, new ADR_Transfer_Log__c (Id = adrRec.Id));
            }
            adrToUpdateMap.get(adrRec.Id).Pipeline_Threshold_Date__c = System.now();
        }
    }
    
    @testVisible private void updateTransferPointsAtTrialPlus(ADR_Transfer_Log__c adrRec, Map<Id, ADR_Transfer_Log__c> adrToUpdateMap) {
        
        // When the opportunity does not progress, skip the record
        if(!adrRec.Opportunity__r.Went_to_Trial__c && !adrRec.Opportunity__r.Went_to_Proposal__c && !adrRec.Opportunity__r.Went_to_Decision__c && 
            !adrRec.Opportunity__r.Went_to_Purchase__c && !adrRec.Opportunity__r.Went_to_Closing__c && !adrRec.Opportunity__r.Went_to_Orders_Processing__c && 
            !adrRec.Opportunity__r.Went_to_Ready_to_Ship__c && !adrRec.Opportunity__r.Went_to_Closed_Won__c) 
            return;

        //If the record already exists, update the field, else add the record in the map.
        if(adrToUpdateMap.containsKey(adrRec.Id)) adrToUpdateMap.get(adrRec.Id).Transfer_Points_at_Trial__c = 1;
        else adrToUpdateMap.put(adrRec.Id, new ADR_Transfer_Log__c(Id = adrRec.Id, Transfer_Points_at_Trial__c = 1));

        populateOpportunityTrailDate(adrRec, adrToUpdateMap);
        
    }
    
    @testVisible private boolean adrInFiscalMonth(ADR_Transfer_Log__c adrRec){
        
        //When Fiscal Month Start Date & End Date do not have valid data, do not proceed.
        if(fiscalMonthStartDate == null || fiscalMonthEndDate == null || fiscalMonthStartDate > fiscalMonthEndDate) return false;
        
        return adrRec.ADR_Transfer_Qualified_Date__c >= fiscalMonthStartDate && adrRec.ADR_Transfer_Qualified_Date__c <= fiscalMonthEndDate;
    }
    
    
    @testVisible private boolean meetsACVThreshold(String roleName, Decimal acv, Boolean isFirstPurchase) {
        
        return isFirstPurchase ? 
            (roleName.contains(' CA ') && acv >= 12000)
            || (roleName.contains(' SLED ') && acv >= 10000)
            || (roleName.contains(' MX ') && acv >= 10000)
            || (roleName.contains(' US ') && acv >= 17000)
            : acv >= 2000;
    }

    @testVisible private void populateOpportunityTrailDate(ADR_Transfer_Log__c adrRec, Map<Id, ADR_Transfer_Log__c> adrToUpdateMap){

        List<DateTime> dateTimeList = new List<DateTime>();

        if(adrRec.Opportunity__r.Went_to_Trial_Date__c != null) dateTimeList.add(adrRec.Opportunity__r.Went_to_Trial_Date__c);
        if(adrRec.Opportunity__r.Went_to_Proposal_Date__c != null) dateTimeList.add(adrRec.Opportunity__r.Went_to_Proposal_Date__c);
        if(adrRec.Opportunity__r.Went_to_Decision_Date__c != null) dateTimeList.add(adrRec.Opportunity__r.Went_to_Decision_Date__c);
        if(adrRec.Opportunity__r.Went_to_Purchase_Date__c != null) dateTimeList.add(adrRec.Opportunity__r.Went_to_Purchase_Date__c);
        if(adrRec.Opportunity__r.Went_to_Closing_Date__c != null) dateTimeList.add(adrRec.Opportunity__r.Went_to_Closing_Date__c);
        if(adrRec.Opportunity__r.Went_to_Orders_Processing_Date__c != null) dateTimeList.add(adrRec.Opportunity__r.Went_to_Orders_Processing_Date__c);
        if(adrRec.Opportunity__r.Went_to_Ready_to_Ship_Date__c != null) dateTimeList.add(adrRec.Opportunity__r.Went_to_Ready_to_Ship_Date__c);
        if(adrRec.Opportunity__r.Went_to_Closed_Won_Date__c != null) dateTimeList.add(adrRec.Opportunity__r.Went_to_Closed_Won_Date__c);

        dateTimeList.sort();

        if(!dateTimeList.isEmpty()) {
            if(!adrToUpdateMap.containsKey(adrRec.Id)) {
                adrToUpdateMap.put(adrRec.Id, new ADR_Transfer_Log__c (Id = adrRec.Id));
            }
            adrToUpdateMap.get(adrRec.Id).Opportunity_Trial_Date__c = dateTimeList[0];
        }
    }

    @testVisible private void updateTrailForQuotaTransferLogs(Map<Id, ADR_Transfer_Log__c> adrMap){

        List<Quota_Transfer_Log__c> quoteTransferLogList = [SELECT Id, ADR_Transfer_Log__c, ADR_Transfer_Points_At_Transfer_Copy__c, ADR_Transfer_Points_at_Trial__c 
                                                            FROM Quota_Transfer_Log__c WHERE ADR_Transfer_Log__c in :adrMap.keyset()];

        if(quoteTransferLogList.isEmpty()) return;

        for(Quota_Transfer_Log__c quotaTransferRec :quoteTransferLogList){

            if(adrMap.get(quotaTransferRec.ADR_Transfer_Log__c).Transfer_Points_At_Transfer_Copy__c != null) quotaTransferRec.ADR_Transfer_Points_At_Transfer_Copy__c = adrMap.get(quotaTransferRec.ADR_Transfer_Log__c).Transfer_Points_At_Transfer_Copy__c;

            if(adrMap.get(quotaTransferRec.ADR_Transfer_Log__c).Transfer_Points_at_Trial__c != null) quotaTransferRec.ADR_Transfer_Points_at_Trial__c = adrMap.get(quotaTransferRec.ADR_Transfer_Log__c).Transfer_Points_at_Trial__c;
        }

        update quoteTransferLogList;
    }

    @testVisible private void notifyUser(Integer numberOfFailures, String jobId){

        string errorMessage;

        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType 
                                                        WHERE DeveloperName='Generic_Notification' LIMIT 1];
       
        Quota__c quotaRecord = [SELECT Name FROM Quota__c WHERE Id = :recordId LIMIT 1];

        if(numberOfFailures > 0) errorMessage = '\n The job has '+String.valueOf(numberOfFailures)+
                                        ' failures, please reach out to your admin and pass this Id:'+jobId+'.';

        Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
        customNotificationObj.setBody(Label.ADR_Incentive_Batch_Notification_message.replace('[Record Name]', quotaRecord.Name)); // Custom Label
        customNotificationObj.setTitle(System.label.ADR_Incentive_Batch_Notification_Title+(String.isBlank(errorMessage)?'':errorMessage)); // Custom Label
        customNotificationObj.setNotificationTypeId(notificationType.Id);
        customNotificationObj.setSenderId(userId);
        customNotificationObj.setTargetId(recordId);
        customNotificationObj.send(new Set<String> {userId});
    }

    @testVisible private static boolean checkAndExecuteBatch(String userId, boolean initiatedByAgent, string recordId){

        Automation_Settings__c adrConfig = Automation_Settings__c.getValues('ADR Incentive');
        System.debug('adrConfig-->'+adrConfig);

        Map<String, Object> configData = new Map<String, Object>();
        
        if(String.isNotBlank(adrConfig?.Data__c)) configData = (Map<String, Object>) JSON.deserializeUntyped(adrConfig.data__c);

        //If ADR Incentive Automation settings is not available or the data__c field in the custom setting is emtpy, run the batch
        if(configData.isEmpty()) return runBatchAndReturnTrue(adrConfig, configData, userId, initiatedByAgent, recordId);
        
        String jobId = (String)configData.get('lastRunJobId');

        //If no Id is configured in ADR Incentive Custom Setting, run the batch
        if(String.isBlank(jobId)) return runBatchAndReturnTrue(adrConfig, configData, userId, initiatedByAgent, recordId);

        List<AsyncApexJob> previousJobList= [SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        //If no AsyncApexjob found with the Id configured in ADR Incentive Custom Setting, run the batch
        if(previousJobList.size() != 1) return runBatchAndReturnTrue(adrConfig, configData, userId, initiatedByAgent, recordId);

        String previousJobStatus = previousJobList[0]?.Status;

        //If the previous batch job is either completed or aborted or failed, run the batch.
        if(new list<String>{'Aborted','Completed'}.contains(previousJobStatus))
            return runBatchAndReturnTrue(adrConfig, configData, userId, initiatedByAgent, recordId);
        
        return false;
    }

    @testVisible private static boolean runBatchAndReturnTrue(Automation_Settings__c adrConfig, Map<String, Object> configData, String userId, boolean initiatedByAgent, string recordId){

        //When the custom setting is not available, create a new instance of the custom setting
        if(adrConfig == null || configData == null) adrConfig = createADRIncentiveAutomatonSetting();

        Id currentJobId = database.executeBatch(new ADRIncentiveBatch(userId, initiatedByAgent, recordId));

        if(configData == null) configData = new Map<String, Object>();
        
        configData.put('lastRunJobId', (String) currentJobId);

        adrConfig.Data__c = JSON.serialize(configData);

        update adrConfig;

        return true;
    }

    @testVisible private static Automation_Settings__c createADRIncentiveAutomatonSetting(){

        Automation_Settings__c adrSetting = new Automation_Settings__c(name = 'ADR Incentive', Data__c = '{"lastRunJobId":"707Wr000016siJYIAY"}');

        insert adrSetting;
        return adrSetting;
    }
}