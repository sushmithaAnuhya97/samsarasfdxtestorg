public class GongApiCalloutQueueable implements Queueable, Database.AllowsCallouts {
    
    private String samsaraLogId;
    private String contactId;
    private String flowId; // Will be loaded from metadata
    private String contactEmail; // Will be loaded from metadata
    private String apiPath; // Will be loaded from metadata
    
    public GongApiCalloutQueueable(String samsaraLogId, String contactId) {
        this.samsaraLogId = samsaraLogId;
        this.contactId = contactId;
    }
    
    public void execute(QueueableContext context) {
        try {
            System.debug('GongApiCalloutQueueable executing for contact: ' + contactId);
            
            // Load configuration from metadata
            loadGongConfiguration();
            
            // Make the API callout
            HttpResponse response = makeGongApiCallout();
            
            // Process response and update log
            if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                // Success
                createSamsaraLogEntry(samsaraLogId, 'INFO', 'Gong API Call Success', 
                    'Contact successfully assigned to Gong flow. Response: ' + response.getBody());
                System.debug('Gong API call successful: ' + response.getBody());
            } else {
                // API Error
                createSamsaraLogEntry(samsaraLogId, 'ERROR', 'Gong API Error', 
                    'API call failed with status ' + response.getStatusCode() + '. Response: ' + response.getBody());
                System.debug('Gong API call failed: ' + response.getStatusCode() + ' - ' + response.getBody());
            }
            
        } catch (Exception e) {
            // Exception occurred
            createSamsaraLogEntry(samsaraLogId, 'ERROR', 'Gong API Exception', 
                'Exception occurred: ' + e.getMessage() + '. Stack trace: ' + e.getStackTraceString());
            System.debug('Gong API call exception: ' + e.getMessage());
        }
    }
    
    /**
     * Make the actual Gong API callout
     */
    private HttpResponse makeGongApiCallout() {
        // Create HTTP request using Named Credential
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Gong_Integration' + apiPath);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000); // 30 seconds timeout
        
        // Prepare request body - Gong API expects crmProspectsIds array and flowInstanceOwnerEmail
        Map<String, Object> requestBody = new Map<String, Object>{
            'crmProspectsIds' => new List<String>{contactId},
            'flowId' => flowId,
            'flowInstanceOwnerEmail' => contactEmail
        };
        
        req.setBody(JSON.serialize(requestBody));
        
        // Log the request
        System.debug('Gong API Request: ' + req.getBody());
        
        // Make the callout
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        // Log the response
        System.debug('Gong API Response: ' + response.getBody());
        
        return response;
    }
    
    /**
     * Load Gong configuration from metadata based on environment
     */
    private void loadGongConfiguration() {
        // Determine if we're in sandbox or production
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String configDeveloperName = isSandbox ? 'Gong_Smartflow_Credentials_Sandbox' : 'Gong_Smartflow_Credentials_Production';
        
        Smart_Flow_API_Configuration__mdt config = [SELECT Details__c FROM Smart_Flow_API_Configuration__mdt WHERE DeveloperName = :configDeveloperName LIMIT 1];
        String jsonString = config.Details__c;
        Map<String, Object> configMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        
        // Load configuration values
        flowId = (String) configMap.get('FlowId');
        apiPath = (String) configMap.get('API_Path');
        
        // Get the last Workato record creator email and format it based on environment
        contactEmail = getFormattedWorkatoCreatorEmail(isSandbox);
    }
    
    /**
     * Get the last Workato record creator email and format it based on environment
     */
    private String getFormattedWorkatoCreatorEmail(Boolean isSandbox) {
        try {
            // Query the last Workato log entry for this contact
            List<SamsaraLogEntries__c> lastWorkatoLogs = [
                SELECT CreatedBy.Email 
                FROM SamsaraLogEntries__c 
                WHERE RecordId__c = :contactId 
                AND sourceApiName__c = 'ContactEmailGenerator'
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            
            if (lastWorkatoLogs.isEmpty()) {
                // Fallback to current user if no Workato logs found
                return formatEmailForEnvironment(UserInfo.getUserEmail(), isSandbox);
            }
            
            String creatorEmail = lastWorkatoLogs[0].CreatedBy.Email;
            return formatEmailForEnvironment(creatorEmail, isSandbox);
            
        } catch (Exception e) {
            System.debug('Error getting Workato creator email: ' + e.getMessage());
            // Fallback to current user email
            return formatEmailForEnvironment(UserInfo.getUserEmail(), isSandbox);
        }
    }
    
    /**
     * Format email based on environment
     * Sandbox: user+sandbox@domain.com
     * Production: user@domain.com
     */
    private String formatEmailForEnvironment(String email, Boolean isSandbox) {
        if (String.isBlank(email)) {
            return email;
        }
        
        if (isSandbox) {
            // Add +sandbox before @ for sandbox
            if (email.contains('@')) {
                String[] emailParts = email.split('@');
                return emailParts[0] + '+sandbox@' + emailParts[1];
            }
        }
        
        // For production, return email as-is
        return email;
    }
    
    
    /**
     * Create Samsara log entry for detailed tracking
     */
    private void createSamsaraLogEntry(String samsaraLogId, String level, String exceptionType, String message) {
        try {
            if (String.isNotBlank(samsaraLogId)) {
                SamsaraLogEntries__c logEntry = new SamsaraLogEntries__c(
                    SamsaraLog__c = samsaraLogId,
                    Level__c = level,
                    Exception_Type__c = exceptionType,
                    Message__c = message,
                    RecordId__c = contactId
                );
                insert logEntry;
            }
        } catch (Exception e) {
            System.debug('Error creating Samsara Log Entry: ' + e.getMessage());
        }
    }
}