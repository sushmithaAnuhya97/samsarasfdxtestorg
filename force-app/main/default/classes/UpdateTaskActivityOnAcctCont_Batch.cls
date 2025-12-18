/**
 * @author: Naved Khan
 * @description: Batch class to update Call and Email Activity on Account and Contact records.
 * This batch processes completed Tasks and updates the Last Call and Last Sales Activity fields
 * on related Account and Contact records.
 */
public class UpdateTaskActivityOnAcctCont_Batch implements Database.Batchable<SObject>, Database.Stateful {

    private Integer totalTasksProcessed;
    private Integer totalAccountsUpdated;
    private Integer totalContactsUpdated;
    private Integer totalBatchesProcessed;
    private List<String> notificationEmails;
    private Set<Id> accountToProcessIdSet;
    private Map<String, String> failedRecordsMap; // Map to store failed records with their error messages
    private static final String BATCH_NAME = 'UpdateTaskActivityOnAcctCont_Batch';
    private Integer BATCH_SIZE;
    
    // Progress tracking variables
    private String lastProcessedAccountId;
    private String finalProcessedAccountId;
    private Boolean hasError;
    private String errorMessage;
    private Batch_Execution_Progress__c progressRecord;
    // private Boolean isFirstBatch; // Flag to track if this is the first batch execution

    // For checking exception in Test Class.
    private Boolean checkException;


    public UpdateTaskActivityOnAcctCont_Batch(List<String> emailAddresses) {
        this(emailAddresses, null);
    }

    public UpdateTaskActivityOnAcctCont_Batch(List<String> emailAddresses, Set<Id> accountIdSet) {
        this(emailAddresses, accountIdSet, null, false);
    }

    public UpdateTaskActivityOnAcctCont_Batch(List<String> emailAddresses, Set<Id> accountIdSet, String lastAccountId, Boolean errorCheck) {
        notificationEmails = emailAddresses != null ? emailAddresses : new List<String>();
        accountToProcessIdSet = accountIdSet != null ? new Set<Id>(accountIdSet) : null;
        lastProcessedAccountId = lastAccountId;
        totalTasksProcessed = 0;
        totalAccountsUpdated = 0;
        totalContactsUpdated = 0;
        totalBatchesProcessed = 0;
        failedRecordsMap = new Map<String, String>();
        hasError = false;
        errorMessage = '';
        // isFirstBatch = (lastAccountId == null);
        checkException = errorCheck;
        BATCH_SIZE = Integer.valueOf(System.Label.Custom_Batch_Size);
        
        // Initialize or get progress record
        initializeProgressRecord();
    }

    private void initializeProgressRecord() {
        try {
            List<Batch_Execution_Progress__c> existingRecords = [
                SELECT Id, Name, Last_Processed_Account_Id__c, Is_Active__c, LastModifiedDate
                FROM Batch_Execution_Progress__c 
                WHERE Name = :BATCH_NAME AND Is_Active__c = True
                LIMIT 1
            ];
            
            if (!existingRecords.isEmpty()) {
                progressRecord = existingRecords[0];

                if (String.isNotEmpty(progressRecord.Last_Processed_Account_Id__c)) {
                    lastProcessedAccountId = progressRecord.Last_Processed_Account_Id__c;
                }

            } 
            else {
                // Create new progress record
                progressRecord = new Batch_Execution_Progress__c();
                progressRecord.Name = BATCH_NAME;
                progressRecord.Last_Processed_Account_Id__c = lastProcessedAccountId;
                // progressRecord.Total_Records_Processed__c = 0;
                progressRecord.Is_Active__c = true;
                // progressRecord.Error_Message__c = '';
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error initializing progress record: ' + e.getMessage());
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            String baseQuery = 
                'SELECT Id, AccountId, WhoId, WhatId, Subject, Status, CallDurationInSeconds, ' +
                'CreatedBy.UserRole.Name, CreatedDate, Is_Email__c, CompletedDateTime, ' +
                'Account.CreatedDate ' +
                'FROM Task ' +
                'WHERE AccountId != null ' +
                'AND Status = \'Completed\' ' +
                'AND (CallDurationInSeconds >= 0 OR (Subject LIKE \'%Email%\'AND Is_Email__c = \'Email\')OR ' +'(Subject LIKE \'%[Gong In]%\' AND Is_Email__c = \'Gong In\') OR ' +'(Subject LIKE \'%[Gong Out]%\' AND Is_Email__c = \'Gong Out\')) ' +
                'AND ((' +
                //Filter By CreatedBy User
                'CreatedBy.Name != \'Gong Bot API User\' ' +
                'AND (' +
                    'CreatedBy.UserRole.Name LIKE \'% CML %\' OR CreatedBy.UserRole.Name LIKE \'CML %\' OR CreatedBy.UserRole.Name LIKE \'% CML\' OR ' +
                    'CreatedBy.UserRole.Name LIKE \'% MM %\' OR CreatedBy.UserRole.Name LIKE \'MM %\' OR CreatedBy.UserRole.Name LIKE \'% MM\' OR ' +
                    'CreatedBy.UserRole.Name LIKE \'% COR %\' OR CreatedBy.UserRole.Name LIKE \'COR %\' OR CreatedBy.UserRole.Name LIKE \'% COR\' OR ' +
                    'CreatedBy.UserRole.Name LIKE \'% SEL %\' OR CreatedBy.UserRole.Name LIKE \'SEL %\' OR CreatedBy.UserRole.Name LIKE \'% SEL\' OR ' +
                    'CreatedBy.UserRole.Name LIKE \'% STR %\' OR CreatedBy.UserRole.Name LIKE \'STR %\' OR CreatedBy.UserRole.Name LIKE \'% STR\' OR ' +
                    'CreatedBy.UserRole.Name LIKE \'% ADR %\' OR CreatedBy.UserRole.Name LIKE \'ADR %\' OR CreatedBy.UserRole.Name LIKE \'% ADR\' OR ' +
                	'CreatedBy.UserRole.Name LIKE \'% Renewal %\' OR CreatedBy.UserRole.Name LIKE \'Renewal %\' OR CreatedBy.UserRole.Name LIKE \'% Renewal\' OR ' +
                    'CreatedBy.UserRole.Name LIKE \'% ENT %\' OR CreatedBy.UserRole.Name LIKE \'ENT %\' OR CreatedBy.UserRole.Name LIKE \'% ENT\'' +
                ') ' +
                'AND (' +
                    '(NOT CreatedBy.UserRole.Name LIKE \'% Director %\') AND (NOT CreatedBy.UserRole.Name LIKE \'Director %\') AND (NOT CreatedBy.UserRole.Name LIKE \'% Director\') AND ' +
                    '(NOT CreatedBy.UserRole.Name LIKE \'% Management %\') AND (NOT CreatedBy.UserRole.Name LIKE \'Management %\') AND (NOT CreatedBy.UserRole.Name LIKE \'% Management\') AND ' +
                    '(NOT CreatedBy.UserRole.Name LIKE \'% ISD %\') AND (NOT CreatedBy.UserRole.Name LIKE \'ISD %\') AND (NOT CreatedBy.UserRole.Name LIKE \'% ISD\') AND ' +
                    '(NOT CreatedBy.UserRole.Name LIKE \'% AVP %\') AND (NOT CreatedBy.UserRole.Name LIKE \'AVP %\') AND (NOT CreatedBy.UserRole.Name LIKE \'% AVP\') AND ' +
                    '(NOT CreatedBy.UserRole.Name LIKE \'% VP %\') AND (NOT CreatedBy.UserRole.Name LIKE \'VP %\') AND (NOT CreatedBy.UserRole.Name LIKE \'% VP\')' +
                '))' +
                // Filter By Assigned To User
                ' OR ('+
                'CreatedBy.Name = \'Gong Bot API User\' ' +
                ' AND (' +
                    'Owner.UserRole.Name LIKE \'% CML %\' OR Owner.UserRole.Name LIKE \'CML %\' OR Owner.UserRole.Name LIKE \'% CML\' OR ' +
                    'Owner.UserRole.Name LIKE \'% MM %\' OR Owner.UserRole.Name LIKE \'MM %\' OR Owner.UserRole.Name LIKE \'% MM\' OR ' +
                    'Owner.UserRole.Name LIKE \'% COR %\' OR Owner.UserRole.Name LIKE \'COR %\' OR Owner.UserRole.Name LIKE \'% COR\' OR ' +
                    'Owner.UserRole.Name LIKE \'% SEL %\' OR Owner.UserRole.Name LIKE \'SEL %\' OR Owner.UserRole.Name LIKE \'% SEL\' OR ' +
                    'Owner.UserRole.Name LIKE \'% STR %\' OR Owner.UserRole.Name LIKE \'STR %\' OR Owner.UserRole.Name LIKE \'% STR\' OR ' +
                    'Owner.UserRole.Name LIKE \'% ADR %\' OR Owner.UserRole.Name LIKE \'ADR %\' OR Owner.UserRole.Name LIKE \'% ADR\' OR ' +
                	'Owner.UserRole.Name LIKE \'% Renewal %\' OR Owner.UserRole.Name LIKE \'Renewal %\' OR Owner.UserRole.Name LIKE \'% Renewal\' OR ' +
                    'Owner.UserRole.Name LIKE \'% ENT %\' OR Owner.UserRole.Name LIKE \'ENT %\' OR Owner.UserRole.Name LIKE \'% ENT\'' +
                ') ' +
                'AND (' +
                    '(NOT Owner.UserRole.Name LIKE \'% Director %\') AND (NOT Owner.UserRole.Name LIKE \'Director %\') AND (NOT Owner.UserRole.Name LIKE \'% Director\') AND ' +
                    '(NOT Owner.UserRole.Name LIKE \'% Management %\') AND (NOT Owner.UserRole.Name LIKE \'Management %\') AND (NOT Owner.UserRole.Name LIKE \'% Management\') AND ' +
                    '(NOT Owner.UserRole.Name LIKE \'% ISD %\') AND (NOT Owner.UserRole.Name LIKE \'ISD %\') AND (NOT Owner.UserRole.Name LIKE \'% ISD\') AND ' +
                    '(NOT Owner.UserRole.Name LIKE \'% AVP %\') AND (NOT Owner.UserRole.Name LIKE \'AVP %\') AND (NOT Owner.UserRole.Name LIKE \'% AVP\') AND ' +
                    '(NOT Owner.UserRole.Name LIKE \'% VP %\') AND (NOT Owner.UserRole.Name LIKE \'VP %\') AND (NOT Owner.UserRole.Name LIKE \'% VP\')' +
                ')))';

            // Add resume logic if we have a last processed account
            if (lastProcessedAccountId != null) {
                baseQuery += ' AND AccountId >= :lastProcessedAccountId';
            }

            // Add specific task filter if provided
            if (accountToProcessIdSet != null && !accountToProcessIdSet.isEmpty()) {
                baseQuery += ' AND AccountId IN :accountToProcessIdSet';
            }

            // Add ordering by Account.CreatedDate only
            baseQuery += ' ORDER BY AccountId ASC';

            // Add LIMIT to ensure we only process 100,000 records per batch
            baseQuery += ' LIMIT ' + BATCH_SIZE;

            return Database.getQueryLocator(baseQuery);
        } catch (Exception e) {
            throw e;
        }
    }

    public void execute(Database.BatchableContext bc, List<Task> scope) {
        try {
            totalBatchesProcessed += 1;
            totalTasksProcessed += scope.size();

            // Store the first AccountId from this batch for progress tracking
            // This ensures we can resume from exactly where we left off
            if (!scope.isEmpty()) {
                Task firstTask = scope[0];
                lastProcessedAccountId = firstTask.AccountId;
                finalProcessedAccountId = scope[scope.size()-1].AccountId;
                
                // Update progress record immediately to save the checkpoint
                updateProgressRecord();
                
                System.debug(LoggingLevel.INFO, 'Batch ' + totalBatchesProcessed + ' started processing from Account: ' + 
                           lastProcessedAccountId + ' (Created: ' + firstTask.Account.CreatedDate + ')');
            }

            Set<Id> accountIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            
            // First pass: Collect all relevant IDs
            for (Task taskData : scope) {
                if(taskData.CreatedDate != taskData.CompletedDateTime) {
                    if(Math.abs(taskData.CreatedDate.getTime()-taskData.CompletedDateTime.getTime()) > 2000) {
                        continue;
                    }
                }
                accountIds.add(taskData.AccountId);
                if (taskData.WhoId != null && String.valueOf(taskData.WhoId).startsWith('003')) {
                    contactIds.add(taskData.WhoId);
                }
            }

            // Query accounts and contacts in bulk
            Map<Id, Account> accMap = new Map<Id, Account>();
            Map<Id, Contact> conMap = new Map<Id, Contact>();
            
            if (!accountIds.isEmpty()) {
                accMap = new Map<Id, Account>([
                    SELECT Id, Last_Sales_Activity__c, Last_Call__c 
                    FROM Account 
                    WHERE Id IN :accountIds
                ]);
            }
            
            if (!contactIds.isEmpty()) {
                conMap = new Map<Id, Contact>([
                    SELECT Id, Last_Call__c 
                    FROM Contact 
                    WHERE Id IN :contactIds
                ]);
            }

            Map<Id, Account> acctToUpdateMap = new Map<Id, Account>();
            Map<Id, Contact> contactToUpdateMap = new Map<Id, Contact>();

            // Second pass: Process tasks and update records
            for (Task taskData : scope) {
                if(taskData.CreatedDate != taskData.CompletedDateTime) {
                    continue;
                }

                Account acct = accMap.get(taskData.AccountId);
                if (acct == null) continue;

                Boolean isCall = taskData.CallDurationInSeconds >= 0;
                Boolean isEmail = taskData.Subject != null && 
                                taskData.Subject.containsIgnoreCase('Email') && 
                                taskData.Is_Email__c == 'Email';
                Boolean isGong =  taskData.Subject != null && 
                                (taskData.Subject.startsWith('[Gong In]') || taskData.Subject.startsWith('[Gong Out]'))&& 
                                (taskData.Is_Email__c == 'Gong In' || taskData.Is_Email__c == 'Gong Out');

                if (isCall) {
                    processCallActivity(taskData, acct, acctToUpdateMap, accMap);
                    
                    if (taskData.WhoId != null && conMap.containsKey(taskData.WhoId)) {
                        Contact con = conMap.get(taskData.WhoId);
                        if (con.Last_Call__c == null || taskData.CompletedDateTime > con.Last_Call__c) {
                            con.Last_Call__c = taskData.CompletedDateTime;
                            contactToUpdateMap.put(con.Id, con);
                            conMap.put(con.Id, con);
                        }
                    }
                } else if (isEmail || isGong) {
                    if (acct.Last_Sales_Activity__c == null || taskData.CompletedDateTime > acct.Last_Sales_Activity__c) {
                        acct.Last_Sales_Activity__c = taskData.CompletedDateTime;
                        acctToUpdateMap.put(acct.Id, acct);
                        accMap.put(acct.Id, acct);
                    }
                }
            }

            // Perform DML operations with error handling
            // If any error occurs, abort the job and stop execution completely
            if (!acctToUpdateMap.isEmpty()) {

                if(Test.isRunningTest() && checkException) {
                    Account faultyAccount = acctToUpdateMap.values()[0];
                    faultyAccount.Name = null;
                    acctToUpdateMap.put(faultyAccount.Id, faultyAccount);
                }

                List<Database.SaveResult> accountResults = Database.update(acctToUpdateMap.values(), false);
                if (!processSaveResults(accountResults, 'Account')) {
                    // If there are errors, abort the job and stop execution
                    hasError = true;
                    errorMessage = 'Error updating Account records. Check failed records for details.';
                    updateProgressRecord();
                    System.debug(LoggingLevel.ERROR, 'Account update failed. Aborting job. Error: ' + errorMessage);
                    System.abortJob(bc.getJobId());
                    finishJob();
                    return;
                }
                totalAccountsUpdated += acctToUpdateMap.size();
            }

            if (!contactToUpdateMap.isEmpty()) {

                List<Database.SaveResult> contactResults = Database.update(contactToUpdateMap.values(), false);
                if (!processSaveResults(contactResults, 'Contact')) {
                    // If there are errors, abort the job and stop execution
                    hasError = true;
                    errorMessage = 'Error updating Contact records. Check failed records for details.';
                    updateProgressRecord();
                    System.debug(LoggingLevel.ERROR, 'Contact update failed. Aborting job. Error: ' + errorMessage);
                    System.abortJob(bc.getJobId());
                    finishJob();
                    return;
                }
                totalContactsUpdated += contactToUpdateMap.size();
            }

            // Update progress record after successful batch processing
            // updateProgressRecord();
            
            System.debug(LoggingLevel.INFO, 'Batch ' + totalBatchesProcessed + ' completed successfully. ' +
                       'Processed: ' + scope.size() + ' tasks, Updated: ' + acctToUpdateMap.size() + 
                       ' accounts, ' + contactToUpdateMap.size() + ' contacts');

        } catch (Exception e) {
            hasError = true;
            errorMessage = 'Exception in execute method: ' + e.getMessage() + '\n' + e.getStackTraceString();
            Logger.atError()
                .setClassName(BATCH_NAME)
                .setMethod('execute')
                .setRecordId(null)
                .setExceptionOrMessage(e);
            Logger.insertMasterLogs();
            updateProgressRecord();
            System.debug(LoggingLevel.ERROR, 'Exception in execute method: ' + errorMessage);
            System.abortJob(bc.getJobId());
            // throw e;
        }
    }

    private void updateProgressRecord() {
        try {
            if (progressRecord != null) {
                progressRecord.Last_Processed_Account_Id__c = lastProcessedAccountId;
                // progressRecord.Total_Records_Processed__c = totalTasksProcessed;
                if (hasError) {
                    // progressRecord.Error_Message__c = errorMessage;
                    progressRecord.Is_Active__c = false;
                }
                
                // Update the custom setting record
                upsert progressRecord;
                System.debug(LoggingLevel.INFO, 'Progress Record Updated: ' + JSON.serialize(progressRecord));
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating progress record: ' + e.getMessage());
        }
    }

    private void processCallActivity(Task taskData, Account acct, Map<Id, Account> acctToUpdateMap, Map<Id, Account> accMap) {
        Boolean isChanged = false;
        if (acct.Last_Call__c == null || taskData.CompletedDateTime > acct.Last_Call__c) {
            acct.Last_Call__c = taskData.CompletedDateTime;
            isChanged = true;
        }
        if (acct.Last_Sales_Activity__c == null || taskData.CompletedDateTime > acct.Last_Sales_Activity__c) {
            acct.Last_Sales_Activity__c = taskData.CompletedDateTime;
            isChanged = true;
        }
        if(isChanged) {
            acctToUpdateMap.put(acct.Id, acct);
            accMap.put(acct.Id, acct);
        }
    }

    private Boolean processSaveResults(List<Database.SaveResult> results, String objectType) {
        Boolean hasErrors = false;
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                hasErrors = true;
                for (Database.Error err : sr.getErrors()) {
                    String errorKey = objectType + '|' + sr.getId();
                    String errorValue = err.getMessage();
                    failedRecordsMap.put(errorKey, errorValue);
                }
            }
        }
        return !hasErrors;
    }
    
    public void finish(Database.BatchableContext bc) {
        try {
            System.debug(LoggingLevel.INFO, 'Finish method started. Total batches processed: ' + totalBatchesProcessed);
            
            finishJob();

            // // Check if there was an error and restart the batch from the last processed account
            // if (hasError) {
            //     System.debug(LoggingLevel.INFO, 'Batch encountered an error. Restarting from last processed account: ' + lastProcessedAccountId);
                
            //     // Restart the batch from where it left off
            //     UpdateTaskActivityOnAcctCont_Batch restartBatch = new UpdateTaskActivityOnAcctCont_Batch(
            //         notificationEmails, 
            //         accountToProcessIdSet, 
            //         lastProcessedAccountId
            //     );
                
            //     Database.executeBatch(restartBatch, BATCH_SIZE);
            //     return;
            // }

            
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in finish method: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    private void finishJob() {
        if(totalTasksProcessed == null || totalTasksProcessed == 0) {
                return;
            }
            
            // Check if there are more records to process
            Boolean remainingRecords = totalTasksProcessed < BATCH_SIZE ? false : true;
            if (!hasError && remainingRecords && progressRecord != null) {
                System.debug(LoggingLevel.INFO, 'More records to process: ' + 'Starting next batch of ' + BATCH_SIZE + ' records.');

                progressRecord.Last_Processed_Account_Id__c = finalProcessedAccountId;
                update progressRecord;
                
                // Start next batch from where we left off
                UpdateTaskActivityOnAcctCont_Batch nextBatch = new UpdateTaskActivityOnAcctCont_Batch(
                    notificationEmails, 
                    null, 
                    null,
                    false
                );
                
                Database.executeBatch(nextBatch, 2000);
            }

            if(!hasError && !remainingRecords && progressRecord != null){
                progressRecord.Is_Active__c = false;
                update progressRecord;
            }
            
            // All processing complete, send notification
            System.debug(LoggingLevel.INFO, 'All records processed successfully. Sending completion notification.');
            
            if (notificationEmails.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'No email recipients provided. Skipping notification.');
                return;
            }

            String subject = 'Batch Job Completed: ' + BATCH_NAME;
            String body = 'Hello,\n\n' +
                'The batch job to update Last Call and Last Sales Activity on Account and Contact records has completed successfully.\n\n' +
                'Summary:\n' +
                'Total Tasks Processed: ' + totalTasksProcessed + '\n' +
                'Total Accounts Updated: ' + totalAccountsUpdated + '\n' +
                'Total Contacts Updated: ' + totalContactsUpdated + '\n' +
                'Total Batches Processed: ' + totalBatchesProcessed + '\n' +
                'Batch Size Used: ' + BATCH_SIZE + ' records per batch\n\n';

            body += '\nRegards,\n' + UserInfo.getName();

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(notificationEmails);
            email.setSubject(subject);
            email.setPlainTextBody(body);
            System.debug(LoggingLevel.INFO, 'Email prepared for sending to: ' + notificationEmails);

            // Generate and attach CSV file if there are failed records
            if (!failedRecordsMap.isEmpty()) {
                String csvHeader = 'Record ID,Object Type,Error Message\n';
                String csvBody = '';
                System.debug(LoggingLevel.INFO, 'Generating CSV file for failed records.');
                
                for (String key : failedRecordsMap.keySet()) {
                    String[] parts = key.split('\\|');
                    String objectType = parts[0];
                    String recordId = parts[1];
                    String errorMessage = failedRecordsMap.get(key);
                    csvBody += recordId + ',' + objectType + ',"' + errorMessage + '"\n';
                }
                
                String csvContent = csvHeader + csvBody;
                
                Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
                csvAttachment.setFileName('Failed_Records.csv');
                csvAttachment.setBody(Blob.valueOf(csvContent));
                csvAttachment.setContentType('text/csv');
                
                email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
                System.debug(LoggingLevel.INFO, 'CSV file attached to the email.');
            }

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            // Mark progress record as completed
            // if (progressRecord != null) {
            //     progressRecord.Is_Active__c = false;
            //     // progressRecord.Error_Message__c = 'Batch completed successfully';
            //     upsert progressRecord;
            //     System.debug(LoggingLevel.INFO, 'Progress Record Completed: ' + JSON.serialize(progressRecord));
            // }
    }
    
    // private Integer getRemainingRecordCount() {
    //     try {
    //         String countQuery = 
    //             'SELECT COUNT() ' +
    //             'FROM Task ' +
    //             'WHERE AccountId != null ' +
    //             'AND Status = \'Completed\' ' +
    //             'AND (CallDurationInSeconds >= 0 OR (Subject LIKE \'%Email%\'AND Is_Email__c = \'Email\')OR ' +'(Subject LIKE \'%[Gong In]%\' AND Is_Email__c = \'Gong In\') OR ' +'(Subject LIKE \'%[Gong Out]%\' AND Is_Email__c = \'Gong Out\')) ' +
    //             'AND ((' +
    //             //Filter By CreatedBy User
    //             'CreatedBy.Name != \'Gong Bot API User\' ' +
    //             'AND (' +
    //                 'CreatedBy.UserRole.Name LIKE \'% CML %\' OR CreatedBy.UserRole.Name LIKE \'CML %\' OR CreatedBy.UserRole.Name LIKE \'% CML\' OR ' +
    //                 'CreatedBy.UserRole.Name LIKE \'% MM %\' OR CreatedBy.UserRole.Name LIKE \'MM %\' OR CreatedBy.UserRole.Name LIKE \'% MM\' OR ' +
    //                 'CreatedBy.UserRole.Name LIKE \'% COR %\' OR CreatedBy.UserRole.Name LIKE \'COR %\' OR CreatedBy.UserRole.Name LIKE \'% COR\' OR ' +
    //                 'CreatedBy.UserRole.Name LIKE \'% SEL %\' OR CreatedBy.UserRole.Name LIKE \'SEL %\' OR CreatedBy.UserRole.Name LIKE \'% SEL\' OR ' +
    //                 'CreatedBy.UserRole.Name LIKE \'% STR %\' OR CreatedBy.UserRole.Name LIKE \'STR %\' OR CreatedBy.UserRole.Name LIKE \'% STR\' OR ' +
    //                 'CreatedBy.UserRole.Name LIKE \'% ADR %\' OR CreatedBy.UserRole.Name LIKE \'ADR %\' OR CreatedBy.UserRole.Name LIKE \'% ADR\' OR ' +
    //             	'CreatedBy.UserRole.Name LIKE \'% Renewal %\' OR CreatedBy.UserRole.Name LIKE \'Renewal %\' OR CreatedBy.UserRole.Name LIKE \'% Renewal\' OR ' +
    //                 'CreatedBy.UserRole.Name LIKE \'% ENT %\' OR CreatedBy.UserRole.Name LIKE \'ENT %\' OR CreatedBy.UserRole.Name LIKE \'% ENT\'' +
    //             ') ' +
    //             'AND (' +
    //                 '(NOT CreatedBy.UserRole.Name LIKE \'% Director %\') AND (NOT CreatedBy.UserRole.Name LIKE \'Director %\') AND (NOT CreatedBy.UserRole.Name LIKE \'% Director\') AND ' +
    //                 '(NOT CreatedBy.UserRole.Name LIKE \'% Management %\') AND (NOT CreatedBy.UserRole.Name LIKE \'Management %\') AND (NOT CreatedBy.UserRole.Name LIKE \'% Management\') AND ' +
    //                 '(NOT CreatedBy.UserRole.Name LIKE \'% ISD %\') AND (NOT CreatedBy.UserRole.Name LIKE \'ISD %\') AND (NOT CreatedBy.UserRole.Name LIKE \'% ISD\') AND ' +
    //                 '(NOT CreatedBy.UserRole.Name LIKE \'% AVP %\') AND (NOT CreatedBy.UserRole.Name LIKE \'AVP %\') AND (NOT CreatedBy.UserRole.Name LIKE \'% AVP\') AND ' +
    //                 '(NOT CreatedBy.UserRole.Name LIKE \'% VP %\') AND (NOT CreatedBy.UserRole.Name LIKE \'VP %\') AND (NOT CreatedBy.UserRole.Name LIKE \'% VP\')' +
    //             '))' +
    //             // Filter By Assigned To User
    //             ' OR ('+
    //             'CreatedBy.Name = \'Gong Bot API User\' ' +
    //             ' AND (' +
    //                 'Owner.UserRole.Name LIKE \'% CML %\' OR Owner.UserRole.Name LIKE \'CML %\' OR Owner.UserRole.Name LIKE \'% CML\' OR ' +
    //                 'Owner.UserRole.Name LIKE \'% MM %\' OR Owner.UserRole.Name LIKE \'MM %\' OR Owner.UserRole.Name LIKE \'% MM\' OR ' +
    //                 'Owner.UserRole.Name LIKE \'% COR %\' OR Owner.UserRole.Name LIKE \'COR %\' OR Owner.UserRole.Name LIKE \'% COR\' OR ' +
    //                 'Owner.UserRole.Name LIKE \'% SEL %\' OR Owner.UserRole.Name LIKE \'SEL %\' OR Owner.UserRole.Name LIKE \'% SEL\' OR ' +
    //                 'Owner.UserRole.Name LIKE \'% STR %\' OR Owner.UserRole.Name LIKE \'STR %\' OR Owner.UserRole.Name LIKE \'% STR\' OR ' +
    //                 'Owner.UserRole.Name LIKE \'% ADR %\' OR Owner.UserRole.Name LIKE \'ADR %\' OR Owner.UserRole.Name LIKE \'% ADR\' OR ' +
    //             	'Owner.UserRole.Name LIKE \'% Renewal %\' OR Owner.UserRole.Name LIKE \'Renewal %\' OR Owner.UserRole.Name LIKE \'% Renewal\' OR ' +
    //                 'Owner.UserRole.Name LIKE \'% ENT %\' OR Owner.UserRole.Name LIKE \'ENT %\' OR Owner.UserRole.Name LIKE \'% ENT\'' +
    //             ') ' +
    //             'AND (' +
    //                 '(NOT Owner.UserRole.Name LIKE \'% Director %\') AND (NOT Owner.UserRole.Name LIKE \'Director %\') AND (NOT Owner.UserRole.Name LIKE \'% Director\') AND ' +
    //                 '(NOT Owner.UserRole.Name LIKE \'% Management %\') AND (NOT Owner.UserRole.Name LIKE \'Management %\') AND (NOT Owner.UserRole.Name LIKE \'% Management\') AND ' +
    //                 '(NOT Owner.UserRole.Name LIKE \'% ISD %\') AND (NOT Owner.UserRole.Name LIKE \'ISD %\') AND (NOT Owner.UserRole.Name LIKE \'% ISD\') AND ' +
    //                 '(NOT Owner.UserRole.Name LIKE \'% AVP %\') AND (NOT Owner.UserRole.Name LIKE \'AVP %\') AND (NOT Owner.UserRole.Name LIKE \'% AVP\') AND ' +
    //                 '(NOT Owner.UserRole.Name LIKE \'% VP %\') AND (NOT Owner.UserRole.Name LIKE \'VP %\') AND (NOT Owner.UserRole.Name LIKE \'% VP\')' +
    //             ')))';

    //         // Add resume logic if we have a last processed account
    //         if (lastProcessedAccountId != null) {
    //             countQuery += ' AND AccountId > :lastProcessedAccountId';
    //         }

    //         if (accountToProcessIdSet != null && !accountToProcessIdSet.isEmpty()) {
    //             countQuery += ' AND Id IN :accountToProcessIdSet';
    //         }

    //         return Database.countQuery(countQuery);
    //     } catch (Exception e) {
    //         System.debug(LoggingLevel.ERROR, 'Error getting remaining record count: ' + e.getMessage());
    //         return 0;
    //     }
    // }
}