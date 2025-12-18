/*
 * Class Created: 09/04/25 - Account Contract Renewal Batch
 * Purpose: Updates Account Contract_Renewed_On__c field with the next upcoming contract end date + 1 day
 * Test Class: AccountContractRenewalBatchTest
 * 
 * Use Cases: 
 * 1. Accounts with null Contract_Renewed_On__c and active non-Free Trial contracts
 * 2. Accounts with expired Contract_Renewed_On__c (past or today)
 * 3. Accounts with future Contract_Renewed_On__c matching closed opportunity renewal dates
 * 
 * Logic: 
 * - Processes accounts sequentially by criteria (1 → 2 → 3) to avoid query row limits
 * - Each batch processes one criteria and chains to the next via finish method
 * - Criteria processing:
 *   1. Contract_Renewed_On__c is null and has active contracts (non-Free Trial)
 *   2. Contract_Renewed_On__c is not null and <= TODAY
 *   3. Contract_Renewed_On__c > TODAY and matches closed opportunities (non-Free Trial)
 * - Sets Contract_Renewed_On__c = next contract end date + 1 day
 * - Sets to null if no future contracts exist
 */

 global class AccountContractRenewalBatch implements Database.Batchable<sObject> {
    
    List<Id> accountIds = new List<Id>(); // Only used for criteria 3
    Integer currentCriteria = 1; // 1, 2, or 3
    
    // Default constructor - will process all accounts starting with criteria 1
    public AccountContractRenewalBatch() {
        this.currentCriteria = 1;
    }
    
    // Constructor to specify which criteria to process
    public AccountContractRenewalBatch(Integer criteriaNumber) {
        this.currentCriteria = criteriaNumber;
    }
    
    global Database.QueryLocator start(Database.BatchableContext batchContext) {
        try {
            if(currentCriteria == 3 && (accountIds == null || accountIds.size() == 0)) {
                // Criteria 3: Pre-collect account IDs that match renewal date + closed opportunities
                Set<Id> targetAccountIds = new Set<Id>();
                
                try {
                    for(Account acc : [SELECT Id, Contract_Renewed_On__c,
                                      (SELECT Id, SBQQ__RenewedContract__r.EndDate 
                                       FROM Opportunities 
                                       WHERE isClosed = true 
                                       AND Type != 'Free Trial Opportunity'
                                       AND SBQQ__RenewedContract__r.EndDate != null)
                                      FROM Account 
                                      WHERE Contract_Renewed_On__c > TODAY AND Id IN (SELECT AccountId FROM Opportunity 
                                      WHERE isClosed = true AND Type != 'Free Trial Opportunity') 
                                      ORDER BY Contract_Renewed_On__c ASC LIMIT 50000]) {
                        
                        // Process matching logic in memory
                        if(acc.Opportunities != null) {
                            for(Opportunity opp : acc.Opportunities) {
                                if(opp.SBQQ__RenewedContract__r != null && opp.SBQQ__RenewedContract__r.EndDate != null) {
                                    Date renewalDate = opp.SBQQ__RenewedContract__r.EndDate.addDays(1);
                                    if(acc.Contract_Renewed_On__c == renewalDate) {
                                        targetAccountIds.add(acc.Id);
                                        break; // Found a match, no need to check other opportunities for this account
                                    }
                                }
                            }
                        }
                    }
                } catch(QueryException e) {
                    System.debug('Error in Criteria 3 query: ' + e.getMessage());
                }
                
                // Convert Set to List for the query
                this.accountIds = new List<Id>(targetAccountIds);
            }
            
            // Build dynamic WHERE clause and ORDER BY based on current criteria
            String whereClause;
            String orderClause = '';
            
            if(currentCriteria == 1) {
                // Criteria 1: Contract_Renewed_On__c = null and has active contracts
                 whereClause = 'Contract_Renewed_On__c = null AND Id IN (SELECT AccountId FROM Contract WHERE Is_Active__c = true AND EndDate > TODAY AND RecordType.Name != \'Free Trial\' AND SBQQ__RenewalOpportunity__r.isClosed = FALSE)';
            }
            else if(currentCriteria == 2) {
                // Criteria 2: Contract_Renewed_On__c != null and <= TODAY
                whereClause = 'Contract_Renewed_On__c != null AND Contract_Renewed_On__c <= TODAY';
                orderClause = ' ORDER BY Contract_Renewed_On__c ASC';
            }
            else if(currentCriteria == 3) {
                // Criteria 3: Use pre-collected account IDs
                if(accountIds == null || accountIds.size() == 0) {
                    // No matching accounts found
                    whereClause = 'Id = null';
                } else {
                    whereClause = 'Id IN :accountIds';
                }
                orderClause = ' ORDER BY Contract_Renewed_On__c ASC';
            }
            else {
                // Invalid criteria - return empty result
                whereClause = 'Id = null';
            }
            
            // Build complete dynamic query
            String query = 'SELECT Id, Contract_Renewed_On__c, ' +
                          '(SELECT Id, EndDate FROM Contracts ' +
                          'WHERE Is_Active__c = true AND EndDate > TODAY AND RecordType.Name != \'Free Trial\' ' +
                          'AND SBQQ__RenewalOpportunity__r.IsClosed = false ORDER BY EndDate ASC LIMIT 1) ' +
                          'FROM Account WHERE ' + whereClause + orderClause;
            
            System.debug('Processing Criteria ' + currentCriteria + ' with query');
            return Database.getQueryLocator(query);
            
        } catch(Exception e) {
            LOGGER.atError().setCLassName('AccountContractRenewalBatch').setExceptionOrMessage(e.getMessage());
            LOGGER.setFunctionalityType('Account Contract Renewal Batch'); 
            LOGGER.insertMasterLogs();
            // Return empty query to prevent batch failure
            return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null');
        }
    }
    
    global void execute(Database.BatchableContext batchContext, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();
        
        try {
            for(Account acc : scope) {
                Date newRenewalDate = null;
                
                // Check if account has any future contracts
                if(acc.Contracts != null && acc.Contracts.size() > 0) {
                    // Get the earliest future contract end date + 1 day
                    Contract nextContract = acc.Contracts[0]; // Already ordered by EndDate ASC
                    
                    // Additional null check for contract end date
                    if(nextContract != null && nextContract.EndDate != null) {
                        newRenewalDate = nextContract.EndDate.addDays(1);
                    } 
                }
                
                // Only update if the renewal date has changed
                if(acc.Contract_Renewed_On__c != newRenewalDate) {
                    Account accountToUpdate = new Account();
                    accountToUpdate.Id = acc.Id;
                    accountToUpdate.Contract_Renewed_On__c = newRenewalDate;
                    accountsToUpdate.add(accountToUpdate);
                }
            }
            
            if(accountsToUpdate.size() > 0) {
                Database.SaveResult[] results = Database.update(accountsToUpdate, false);
                
                // Log only failures
                for(Integer i = 0; i < results.size(); i++) {
                    if(!results[i].isSuccess()) {
                        String errorMsg = 'Failed to update Account';
                        if(results[i].getErrors().size() > 0) {
                            errorMsg = results[i].getErrors()[0].getMessage();
                        }
                        LOGGER.atError().setCLassName('AccountContractRenewalBatch').setExceptionOrMessage('Failed to update Account ' + accountsToUpdate[i].Id + ': ' + errorMsg);
                        LOGGER.setFunctionalityType('Account Contract Renewal Batch');
                        LOGGER.setRecordId(accountsToUpdate[i].Id);
                    }
                }
                LOGGER.insertMasterLogs();
            }
            
        } catch(Exception e) {
            LOGGER.atError().setCLassName('AccountContractRenewalBatch').setExceptionOrMessage(e.getMessage()); LOGGER.setFunctionalityType('Account Contract Renewal Batch'); LOGGER.insertMasterLogs();
        }
    }
    
    global void finish(Database.BatchableContext batchContext) {
        System.debug('AccountContractRenewalBatch Criteria ' + currentCriteria + ' completed successfully. Job ID: ' + batchContext.getJobId());
        
        // Check if there are more criteria to process
        if(currentCriteria < 3) {
            Integer nextCriteria = currentCriteria + 1;
            System.debug('Starting next criteria: ' + nextCriteria);
            
            try {
                // Start the next criteria batch - always process all accounts for each criteria
                AccountContractRenewalBatch nextBatch = new AccountContractRenewalBatch(nextCriteria);
                
                Database.executeBatch(nextBatch, Integer.valueOf(Label.AccountContractRenewalBatchSize));
                
            } catch(Exception e) {
                LOGGER.atError().setCLassName('AccountContractRenewalBatch').setExceptionOrMessage(e.getMessage()); LOGGER.setFunctionalityType('Account Contract Renewal Batch'); LOGGER.insertMasterLogs();
            }
        } else {
            System.debug('All AccountContractRenewalBatch criteria processing completed successfully!');
        }
    }
    
    @InvocableMethod(label='Update Account Contract Renewal Dates' 
                     description='Triggers batch job to update Contract_Renewed_On__c field. Processes accounts using sequential criteria (1→2→3).')
    public static List<FlowResponse> updateAccountContractRenewalDates() {
        List<FlowResponse> responses = new List<FlowResponse>();
        
        try {
            // Note: Account ID filtering is handled by the batch class criteria logic
            
            // Execute the batch job - always start with default constructor (criteria 1)
            AccountContractRenewalBatch batchJob = new AccountContractRenewalBatch();
            
            Id jobId = Database.executeBatch(batchJob, Integer.valueOf(Label.AccountContractRenewalBatchSize)); // Process 10 records at a time
            
            // Create response
            FlowResponse response = new FlowResponse();
            response.batchJobId = jobId;
            response.success = true;
            response.message = 'Account Contract Renewal batch job started successfully. Job ID: ' + jobId;
            responses.add(response);
            
        } 
        catch(Exception e) { FlowResponse response = new FlowResponse(); response.success = false; response.message = 'Failed to start batch job: ' + e.getMessage(); responses.add(response);
        }
        
        return responses;
    }
    
    // Output wrapper class for the invocable method
    public class FlowResponse {
        @InvocableVariable(label='Batch Job ID' description='ID of the started batch job')
        public Id batchJobId;
        
        @InvocableVariable(label='Success' description='Whether the batch job started successfully')
        public Boolean success;
        
        @InvocableVariable(label='Message' description='Success or error message')
        public String message;
    }
}