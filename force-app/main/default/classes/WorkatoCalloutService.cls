public with sharing class WorkatoCalloutService {
    
    // Workato API Configuration - using Named Credential
    private static String apiPath;
    
    /**
     * Make Workato callout - called from ContactEmailGeneratorController
     */
    @AuraEnabled
    public static String makeWorkatoCallout(String contactId, String logEntryId) {
        try {
            // Validate parameters
            if (String.isBlank(contactId) || String.isBlank(logEntryId)) {
                throw new CalloutException('Contact ID and Log Entry ID are required');
            }
            
            // Queue the callout for async execution to avoid DML + Callout issues
            System.enqueueJob(new WorkatoCalloutQueueable(contactId, logEntryId));
            
            return 'Callout queued successfully';
            
        } catch (Exception e) {
            throw new CalloutException('Error queuing Workato callout: ' + e.getMessage());
        }
    }
    
    /**
     * Make the actual callout to Workato API to trigger recipe
     */
    private static String executeWorkatoCallout(String contactId, String logId) {
        
        // Load Workato configuration from metadata
        loadWorkatoConfiguration();

        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            // Build endpoint using Named Credential
            String endpoint = 'callout:Workato_Integration' + apiPath;
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000); // 2 minutes timeout
            
            // Prepare request body with contact and log data
            Map<String, Object> requestBody = new Map<String, Object>{
                'contactId' => contactId,
                'logEntryId' => logId
            };
            
            // Set request body
            request.setBody(JSON.serialize(requestBody));
            

            
            // Debug logging
            System.debug('Callout URL: ' + endpoint);
            
            // Send request
            HttpResponse response = http.send(request);
            
            // Debug response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Body: ' + response.getBody());
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 202) {
                return 'Workato callout successful: ' + response.getBody();
            } else {
                throw new CalloutException('Workato callout failed: ' + response.getStatusCode() + ' - ' + response.getBody());
            }
            
        } catch (Exception e) {
            throw new CalloutException('Error making Workato callout: ' + e.getMessage());
        }
    }
    
    /**
     * Queueable class to handle Workato callout separately from DML operations
     */
    public class WorkatoCalloutQueueable implements Queueable, Database.AllowsCallouts {
        private String contactId;
        private String logEntryId;
        
        public WorkatoCalloutQueueable(String contactId, String logEntryId) {
            this.contactId = contactId;
            this.logEntryId = logEntryId;
        }
        
        public void execute(QueueableContext context) {
            try {
                // Make the callout to Workato using Named Credential
                executeWorkatoCallout(contactId, logEntryId);
                
                // Update log entry to INFO for success using ContactEmailGeneratorController
                ContactEmailGeneratorController.updateLogEntryStatus(logEntryId, 'INFO','Callout successful from Salesforce', 'Preparing Data');
                
            } catch (Exception e) {
                // Update log entry to ERROR using ContactEmailGeneratorController
                ContactEmailGeneratorController.updateLogEntryStatus(logEntryId, 'ERROR', 'Error: ' + e.getMessage(),'Salesforce to Workato Callout failed');
                
                // Log the error to debug
                System.debug('Error in WorkatoCalloutQueueable: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Load Workato configuration from metadata based on environment
     */
    private static void loadWorkatoConfiguration() {
        // Determine if we're in sandbox or production
        Boolean isSandbox = isSandboxEnvironment();
        String configDeveloperName = isSandbox ? 'Workato_Smartflow_Credentials_Sandbox' : 'Workato_Smartflow_Credentials_Production';
        
        Smart_Flow_API_Configuration__mdt config = [SELECT Details__c FROM Smart_Flow_API_Configuration__mdt WHERE DeveloperName = :configDeveloperName LIMIT 1];
        String jsonString = config.Details__c;
        Map<String, Object> configMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        
        // Load configuration values (only API path needed now)
        apiPath = (String) configMap.get('API_Path');
    }
    
    /**
     * Helper method to determine if we're running in a sandbox environment
     */
    private static Boolean isSandboxEnvironment() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
}