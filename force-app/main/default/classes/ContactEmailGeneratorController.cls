public with sharing class ContactEmailGeneratorController {
    
    @AuraEnabled
    public static String generateEmailForContact(String contactId) {
        SamsaraLogEntries__c logEntry = null;
        
        try {
            // Validate contact ID
            if (String.isBlank(contactId)) {
                throw new CalloutException('Contact ID is required');
            }
            
            // Create Samsara Log record
            SamsaraLog__c samsaraLog = createSamsaraLog(contactId);
            
            // Create Samsara Log Entry record with INFO status
            logEntry = createLogEntry(samsaraLog.Id, contactId, 'INFO','Callout initiated' ,'Thinking');
            
            // Call the Workato service with the log entry ID
            String result = WorkatoCalloutService.makeWorkatoCallout(contactId, logEntry.Id);
            
            return 'Email generation initiated successfully. Log Entry ID: ' + logEntry.Id + '. Callout queued for processing.';
            
        } catch (Exception e) {
            // Update log entry to ERROR if it exists
            if (logEntry != null) {
                updateLogEntryStatus(logEntry.Id, 'ERROR', 'Error: ' + e.getMessage(),'Salesforce to Workato Callout failed');
            }
            
            logError('ContactEmailGeneratorController.generateEmailForContact', e.getMessage(), contactId);
            throw new AuraHandledException('Error initiating email generation: ' + e.getMessage());
        }
    }
    
    /**
     * Get current log entry status for LWC monitoring
     */
    @AuraEnabled
    public static Map<String, String> getLogEntryStatus(String logEntryId) {
        try {
            SamsaraLogEntries__c logEntry = [
                SELECT Id, Level__c, Message__c, Exception_Type__c, CreatedDate 
                FROM SamsaraLogEntries__c 
                WHERE Id = :logEntryId 
                LIMIT 1
            ];
            
            return new Map<String, String>{
                'status' => logEntry.Level__c,
                'message' => logEntry.Message__c,
                'exceptionType' => logEntry.Exception_Type__c,
                'createdDate' => logEntry.CreatedDate.format()
            };
            
        } catch (Exception e) {
            return new Map<String, String>{
                'status' => 'ERROR',
                'message' => 'Error retrieving log entry: ' + e.getMessage(),
                'exceptionType' => 'ERROR',
                'createdDate' => ''
            };
        }
    }

    
    /**
     * Create Samsara Log record
     */
    private static SamsaraLog__c createSamsaraLog(String contactId) {
        try {
            SamsaraLog__c samsaraLog = new SamsaraLog__c(
                Functionality_Type__c = 'Email Generation',
                Functionality_Sub_Type__c = 'Workato Integration',
                Context_User__c = UserInfo.getUserId(),
                RecordId__c = contactId
            );
            insert samsaraLog;
            return samsaraLog;
        } catch (Exception e) {
            throw new CalloutException('Error creating Samsara Log: ' + e.getMessage());
        }
    }
    
    /**
     * Create Samsara Log Entry record
     */
    private static SamsaraLogEntries__c createLogEntry(String samsaraLogId, String contactId, String level, String message,String exceptionType) {
        try {
            SamsaraLogEntries__c logEntry = new SamsaraLogEntries__c(
                SamsaraLog__c = samsaraLogId,
                RecordId__c = contactId,
                Level__c = level,
                Message__c = message,
                Method__c = 'ContactEmailGeneratorController.generateEmailForContact',
                SourceMetadataType__c = 'Apex',
                sourceApiName__c = 'ContactEmailGenerator',
                Exception_Type__c = exceptionType,
                CreatedDate = System.now()
            );
            insert logEntry;
            return logEntry;
        } catch (Exception e) {
            throw new CalloutException('Error creating Log Entry: ' + e.getMessage());
        }
    }
    
    /**
     * Update Log Entry status
     */
    public static void updateLogEntryStatus(String logEntryId, String level, String message, String exceptionType) {
        try {
            SamsaraLogEntries__c logEntry = [SELECT Id FROM SamsaraLogEntries__c WHERE Id = :logEntryId LIMIT 1];
            logEntry.Level__c = level;
            logEntry.Message__c = message;
            logEntry.Exception_Type__c = exceptionType;
            update logEntry;
        } catch (Exception e) {
            System.debug('Error updating log entry: ' + e.getMessage());
        }
    }
    


    
    @AuraEnabled
    public static Map<String, Object> getLastLogStatus(String contactId) {
        try {
            if (String.isBlank(contactId)) {
                return new Map<String, Object>{
                    'hasError' => true,
                    'message' => 'Contact ID is required',
                    'canGenerate' => false
                };
            }

            // Query the last SamsaraLogEntries__c record for this contact
            List<SamsaraLogEntries__c> lastLogEntries = [
                SELECT Id, Level__c, Exception_Type__c, Message__c, CreatedDate,CreatedById, RecordId__c
                FROM SamsaraLogEntries__c 
                WHERE RecordId__c = :contactId  AND sourceApiName__c = 'ContactEmailGenerator'
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];

            if (lastLogEntries.isEmpty()) {
                // No previous logs - allow generation
                return new Map<String, Object>{
                    'hasError' => false,
                    'message' => 'No previous logs found',
                    'canGenerate' => true,
                    'lastLogStatus' => null
                };
            }

            SamsaraLogEntries__c lastLog = lastLogEntries[0];
            Boolean canGenerate = false;
            String statusMessage = '';

            // Check the outcome based on Level__c and Exception_Type__c
            if (lastLog.Level__c == 'INFO' && lastLog.Exception_Type__c == 'Completed') {
                // Success case - enable button
                canGenerate = true;
                statusMessage = 'Last email generation completed successfully';
            } else if (lastLog.Level__c == 'ERROR') {
                // Error case - enable button (user can retry)
                canGenerate = true;
                statusMessage = 'Last email generation failed - you can try again';
            } else {
                // Other cases (like in progress) - disable button
                canGenerate = false;
                statusMessage = 'Email generation is currently in progress';
            }
            
            User u = [Select Id, Name from User where Id=:lastLog.CreatedById limit 1];
            return new Map<String, Object>{
                'hasError' => false,
                'message' => statusMessage,
                'canGenerate' => canGenerate,
                'lastLogStatus' => new Map<String, Object>{
                    'level' => lastLog.Level__c,
                    'exceptionType' => lastLog.Exception_Type__c,
                    'message' => lastLog.Message__c,
                    'createdDate' => lastLog.CreatedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),
                    'createdUser' => u.Name
                }
            };

        } catch (Exception e) {
            return new Map<String, Object>{
                'hasError' => true,
                'message' => 'Error checking log status: ' + e.getMessage(),
                'canGenerate' => false
            };
        }
    }

    private static void logError(String methodName, String errorMessage, String contactId) {
        // Placeholder for Samsara logging - will be implemented when you provide the details
        System.debug('Error in ' + methodName + ': ' + errorMessage + ' for Contact: ' + contactId);
    }


    @AuraEnabled(cacheable=true)
    public static Map<String, String> getGongDetails() {
        try {
            // Determine if we're in sandbox or production
            Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            String configDeveloperName = isSandbox ? 'Gong_Smartflow_Credentials_Sandbox' : 'Gong_Smartflow_Credentials_Production';
            
            Smart_Flow_API_Configuration__mdt config = [SELECT Details__c FROM Smart_Flow_API_Configuration__mdt WHERE DeveloperName = :configDeveloperName LIMIT 1];
            String jsonString = config.Details__c;
            Map<String, Object> configMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            
            // Return the Gong Base URL for the Launch Gong button
            return new Map<String, String>{
                'gongUrl' => (String) configMap.get('Gong_Base_URL')
            };
            
        } catch (Exception e) {
            // Return default URL if configuration not found
            return new Map<String, String>{
                'gongUrl' => 'https://engage.gong.io'
            };
        }
    }

    /**
     * Validate contact for Smart Flow generation
     * Checks email, opt-out status, and Gong flow status
     */
    @AuraEnabled
    public static Map<String, Object> validateContactForSmartFlow(String contactId) {
        try {
            if (String.isBlank(contactId)) {
                return new Map<String, Object>{
                    'canGenerate' => false,
                    'tooltipMessage' => 'Contact ID is required'
                };
            }

            // Single query for all validation fields
            // TODO: Replace with Gong fields when package is available in production:
            // Gong__Actively_Being_in_a_Flow__c, Gong__Engage_Flow_Owner__c
            Contact contact = [
                SELECT Id, Email, Sales_Email_Opt_Out__c, HasOptedOutOfEmail,
                       Gong__Actively_Being_in_a_Flow__c , Gong__Engage_Flow_Owner__c 
                FROM Contact 
                WHERE Id = :contactId 
                LIMIT 1
            ];

            // 1. Check email null
            if (String.isBlank(contact.Email)) {
                return new Map<String, Object>{
                    'canGenerate' => false,
                    'tooltipMessage' => 'Smart Flow unavailable',
                    'validationDetails' => new List<String>{
                        'Contact email is missing'
                    }
                };
            }

            // 2. Check email format
            if (!isValidEmailFormat(contact.Email)) {
                return new Map<String, Object>{
                    'canGenerate' => false,
                    'tooltipMessage' => 'Smart Flow unavailable',
                    'validationDetails' => new List<String>{
                        'Contact email format is invalid'
                    }
                };
            }

            // 3. Check Gong flow status - using temporary fields until Gong package is available
            // TODO: Replace with Gong__Actively_Being_in_a_Flow__c when package is available
            if (contact.Gong__Actively_Being_in_a_Flow__c  == true) {
                String ownerName = String.isNotBlank(contact.Gong__Engage_Flow_Owner__c ) 
                    ? contact.Gong__Engage_Flow_Owner__c 
                    : 'Unknown User';
                
                return new Map<String, Object>{
                    'canGenerate' => false,
                    'tooltipMessage' => 'Smart Flow unavailable',
                    'validationDetails' => new List<String>{
                        'Contact is active in Gong Flow',
                        'Owner: ' + ownerName,
                        'Remove from existing Flow to proceed'
                    }
                };
            }

            // 4. Check opt-out status
            if (contact.Sales_Email_Opt_Out__c == true || contact.HasOptedOutOfEmail == true) {
                return new Map<String, Object>{
                    'canGenerate' => false,
                    'tooltipMessage' => 'Smart Flow unavailable',
                    'validationDetails' => new List<String>{
                        'Contact has opted out of emails'
                    }
                };
            }

            // All validations passed
            return new Map<String, Object>{
                'canGenerate' => true,
                'tooltipMessage' => 'Click to generate AI-powered email for the contact.'
            };

        } catch (Exception e) {
            return new Map<String, Object>{
                'canGenerate' => false,
                'tooltipMessage' => 'Error validating contact: ' + e.getMessage()
            };
        }
    }

    /**
     * Helper method to validate email format
     * Validates against common email patterns and rejects invalid TLDs like .invalid
     */
    private static Boolean isValidEmailFormat(String email) {
        if (String.isBlank(email)) {
            return false;
        }
        
        // Basic email format validation using regex
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        
        if (!emailPattern.matcher(email).matches()) {
            return false;
        }
        
        // Additional validation for invalid TLDs
        List<String> invalidTlds = new List<String>{
            'invalid', 'test'
        };
        
        String domain = email.substringAfter('@').toLowerCase();
        for (String invalidTld : invalidTlds) {
            if (domain.endsWith('.' + invalidTld)) {
                return false;
            }
        }
        
        return true;
    }

}