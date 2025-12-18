public without sharing class SubmitToClosingController {
    private static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    private static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    private static final String CLASS_NAME = 'Submit to Closing Flow New UI';
    
    @AuraEnabled
    public static void updateAccount(Id accountId, Map<String, Object> fields) {
        try {
            // Validate input parameters
            if (accountId == null || String.isBlank(String.valueOf(accountId))) {
                throw newMessageException('Account ID cannot be null');
            }
            if (fields == null || fields.isEmpty()) {
                throw newMessageException('No fields provided for update');
            }

            // Verify account exists and is accessible
            List<Account> accounts = [SELECT Id FROM Account WHERE Id = :accountId ];
            if (accounts.isEmpty()) {
                throw newMessageException('Account not found or not accessible');
            }
            
            // Create a new Account instance for the update
            Account accToUpdate = new Account(Id = accountId);
            
            // Process each field
            for(String fieldName : fields.keySet()) {
                Object value = fields.get(fieldName);
                
                // Special handling for Key Value Points field
                if (fieldName == 'Key_Value_Points__c' && value instanceof String) {
                    String strValue = (String)value;
                    // Ensure proper format for multi-select picklist
                    if (!strValue.contains(';') && !String.isBlank(strValue)) {
                        strValue += ';';
                    }
                    accToUpdate.put(fieldName, strValue);
                } else {
                    accToUpdate.put(fieldName, value);
                }
            }
            
            // Perform the update with sharing rules
            Database.SaveResult result = Database.update(accToUpdate, false);
            
            if (!result.isSuccess()) {
                String errorMsg = 'Failed to update Account: ';
                for(Database.Error err : result.getErrors()) {
                    errorMsg += err.getMessage() + '; ';
                }
                if (String.isBlank(errorMsg)) {
                    errorMsg = 'Unknown error occurred while updating Account.';
                }
                
                throw newMessageException(errorMsg);
            }
            
        } catch(Exception e) {
            String msg = 'Unexpected error: ' + e.getMessage();
            logWithCustomClassName(
                'Unexpected Error in SubmitToClosingController: ' + msg,
                new SamsaraLoggerObjectMVP(e, accountId)
            );
            throw newMessageException(msg);
        } finally {
            thisLogger.dispatch();
        }
    }

    @AuraEnabled
    public static void updateOpportunity(Id opportunityId, Map<String, Object> fields) {
        Savepoint sp = Database.setSavepoint();
        try {
            // Input validation
            if (opportunityId == null) {
                throw newMessageException('Opportunity ID cannot be null');
            }
            if (fields == null || fields.isEmpty()) {
                throw newMessageException('No fields provided for update');
            }

            // First check if the running user has a verified email
            User currentUser = [SELECT Email, IsActive FROM User WHERE Id = :UserInfo.getUserId()];
            if (currentUser.Email == null || !currentUser.IsActive) {
                throw newMessageException('Current user must have a verified email address to perform this operation.');
            }

            // Query the opportunity with all relevant fields
            String query = 'SELECT Id, Name, SkipValidationRule__c';
            for(String fieldName : fields.keySet()) {
                query += ', ' + String.escapeSingleQuotes(fieldName);
            }
            query += ' FROM Opportunity WHERE Id = :opportunityId';
            
            Opportunity existingOpp;
            try {
                system.debug('Query-->'+query);
                existingOpp = Database.query(query);
                            } catch(QueryException qe) {
                    String msg = 'Failed to retrieve Opportunity: ' + qe.getMessage();
                    logWithCustomClassName(
                        'Query Error in SubmitToClosingController: ' + msg,
                        new SamsaraLoggerObjectMVP(qe, opportunityId)
                    );
                    throw newMessageException(msg);
                }

            // Check if any values have actually changed
            Boolean hasChanges = false;
            for(String fieldName : fields.keySet()) {
                Object newValue = fields.get(fieldName);
                Object existingValue = existingOpp.get(fieldName);
                
                // Convert values to strings for comparison
                String newValueStr = String.valueOf(newValue);
                String existingValueStr = String.valueOf(existingValue);
                
                if (newValueStr != existingValueStr) {
                    hasChanges = true;
                    break;
                }
            }

            // If no changes, return early
            if (!hasChanges) {
                return;
            }
            
            // Set SkipValidationRule__c to true before main update (if not already true)
            if (existingOpp.SkipValidationRule__c != true) {
                try {
                    Opportunity skipValidationUpdate = new Opportunity(
                        Id = opportunityId,
                        SkipValidationRule__c = true
                    );
                    Database.SaveResult skipResult = Database.update(skipValidationUpdate, false);
                    if (!skipResult.isSuccess()) {
                        handleDatabaseErrors(skipResult.getErrors(), 'Failed to set SkipValidationRule to true', opportunityId);
                    }
                } catch (Exception e) {
                    handleUpdateException(e, 'Error setting SkipValidationRule to true', opportunityId);
                }
            }
            
            // Create opportunity for main update
            Opportunity oppToUpdate = new Opportunity(Id = opportunityId);
            
            // Process each field with validation
            for(String fieldName : fields.keySet()) {
                try {
                    Object value = fields.get(fieldName);
                    
                    // Special handling for specific fields if needed
                    if(fieldName == 'StageName' && value == null) {
                        throw newMessageException('Stage cannot be null');
                    }
                    
                    // Validate field exists on Opportunity object
                    Schema.SObjectField field = Opportunity.SObjectType.getDescribe().fields.getMap().get(fieldName);
                    if(field == null) {
                        throw newMessageException('Invalid field name: ' + fieldName);
                    }
                    
                    oppToUpdate.put(fieldName, value);
                } catch(SObjectException se) {
                    String msg = 'Error setting field ' + fieldName + ': ' + se.getMessage();
                    throw newMessageException(msg);
                }
            }
            
            // Perform the main update
            try {
                Database.SaveResult result = Database.update(oppToUpdate, false);
                if (!result.isSuccess()) {
                    handleDatabaseErrors(result.getErrors(), 'Failed to update Opportunity', opportunityId);
                }
            } catch (Exception e) {
                handleUpdateException(e, 'Error updating Opportunity', opportunityId);
            }

            // Set SkipValidationRule__c to false after main update (if not already false)
            if (existingOpp.SkipValidationRule__c != false) {
                try {
                    Opportunity skipValidationUpdate = new Opportunity(
                        Id = opportunityId,
                        SkipValidationRule__c = false
                    );
                    Database.SaveResult skipResult = Database.update(skipValidationUpdate, false);
                    if (!skipResult.isSuccess()) {
                        handleDatabaseErrors(skipResult.getErrors(), 'Failed to set SkipValidationRule to false', opportunityId);
                    }
                } catch (Exception e) {
                    handleUpdateException(e, 'Error setting SkipValidationRule to false', opportunityId);
                }
            }
            
        } catch(AuraHandledException e) {
            Database.rollback(sp);
            throw e;
        } catch(Exception e) {
            Database.rollback(sp);
            String msg = e.getMessage();
            if (String.isBlank(msg)) {
                msg = 'Unexpected error occurred in updateOpportunity.';
            }
            logWithCustomClassName(
                'Unexpected Error in SubmitToClosingController: ' + msg,
                new SamsaraLoggerObjectMVP(e, opportunityId)
            );
            throw newMessageException(msg);
        } finally {
            thisLogger.dispatch();
        }
    }
    
    private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }

    private static void handleDatabaseErrors(List<Database.Error> errors, String context, Id recordId) {
        if (errors != null && !errors.isEmpty()) {
            String errorMsg = context + ': ';
            for(Database.Error err : errors) {
                String fields = String.join(err.getFields(), ', ');
                errorMsg += 'Field(s): ' + (String.isBlank(fields) ? 'None' : fields);
                errorMsg += ', Error: ' + err.getMessage();
            }
           
            throw newMessageException(errorMsg);
        }
    }

    private static void handleUpdateException(Exception e, String context, Id recordId) {
        String errorMsg = context + ': ' + e.getMessage();
        logWithCustomClassName(
            'Update Error in SubmitToClosingController: ' + errorMsg,
            new SamsaraLoggerObjectMVP(e, recordId)
        );
        throw newMessageException(errorMsg);
    }
    
    /**
     * Custom logging method that overrides the class name with the CLASS_NAME constant
     */
    private static void logWithCustomClassName(String message, SamsaraLoggerObjectMVP logObject) {
        // Create a custom gslib_Log object with our custom class name
        gslib_Log customLog = new gslib_Log();
        customLog.className = CLASS_NAME;
        customLog.message = message;
        customLog.contextUser = UserInfo.getUserId();
        customLog.sessionKey = UserInfo.getSessionId() == null ? 'Automated User' : EncodingUtil.base64Encode(Blob.valueOf(UserInfo.getSessionId()));
        customLog.timeStamp = System.now();
        customLog.type = 'Error';
        customLog.logLevel = gslib_LogLevel.Error;
        customLog.severity = gslib_LogSeverity.Major;
        
        // Get the current stack trace to set the method name
        String stackTrace = new DmlException().getStackTraceString();
        if (String.isNotBlank(stackTrace)) {
            List<String> lines = stackTrace.split('\n');
            for (String line : lines) {
                if (line.contains('SubmitToClosingController.') && !line.contains('logWithCustomClassName')) {
                    // Extract method name from stack trace
                    String methodName = line.substringAfter('SubmitToClosingController.').substringBefore(':');
                    customLog.method = methodName;
                    break;
                }
            }
        }
        
        // If we couldn't determine the method, set a default
        if (String.isBlank(customLog.method)) {
            customLog.method = 'Unknown';
        }
        
        // Use the Samsara_AsyncDatabaseAppender directly to log with our custom class name
        Samsara_AsyncDatabaseAppender appender = new Samsara_AsyncDatabaseAppender();
        appender.log(customLog, logObject);
        appender.dispatch();
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getProductVersionOptions() {
        try {
            List<Map<String, String>> options = new List<Map<String, String>>();
            
            // Get the picklist values for Product_Version__c field
            Schema.DescribeFieldResult fieldResult = Opportunity.Product_Version__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry picklistValue : picklistValues) {
                if (picklistValue.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => picklistValue.getLabel(),
                        'value' => picklistValue.getValue()
                    });
                }
            }
            
            return options;
        } catch(Exception e) {
            String msg = 'Error getting product version options: ' + e.getMessage();
            logWithCustomClassName(
                'Product Version Options Error in SubmitToClosingController: ' + msg,
                new SamsaraLoggerObjectMVP(e, null)
            );
            throw newMessageException(msg);
        } finally {
            thisLogger.dispatch();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getKeyValuePointsOptions() {
        try {
            Schema.DescribeFieldResult fieldResult = Account.Key_Value_Points__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            List<String> options = new List<String>();
            
            for(Schema.PicklistEntry entry : ple) {
                options.add(entry.getValue());
            }
            
            return options;
        } catch(Exception e) {
            String msg = 'Error getting key value points options: ' + e.getMessage();
            logWithCustomClassName(
                'Key Value Points Options Error in SubmitToClosingController: ' + msg,
                new SamsaraLoggerObjectMVP(e, null)
            );
            throw newMessageException(msg);
        } finally {
            thisLogger.dispatch();
        }
    }
    
    @AuraEnabled
    public static void sendFreeTrialEmail(Id opportunityId) {
        try {
            if (opportunityId == null) {
                throw newMessageException('Opportunity ID cannot be null');
            }
            
            EmailFreeTrialOpportunityHandler.sendFreeTrialEmail(new List<Id>{opportunityId});
        } catch(Exception e) {
            String msg = 'Error sending free trial email: ' + e.getMessage();
            logWithCustomClassName(
                'Free Trial Email Error in SubmitToClosingController: ' + msg,
                new SamsaraLoggerObjectMVP(e, opportunityId)
            );
            throw newMessageException(msg);
        } finally {
            thisLogger.dispatch();
        }
    }
}