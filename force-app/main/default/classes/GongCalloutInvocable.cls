public with sharing class GongCalloutInvocable {
    
    
    /**
     * Input class for the invocable method
     */
    public class GongFlowInput {
        @InvocableVariable(required=true label='Contact ID' description='Salesforce Contact ID')
        public String contactId;
    }
    
    /**
     * Output class for the invocable method
     */
    public class GongFlowOutput {
        @InvocableVariable(label='Success' description='Whether the callout was successful')
        public Boolean success;
        
        @InvocableVariable(label='Message' description='Success or error message')
        public String message;
        
        @InvocableVariable(label='Response Body' description='Gong API response body')
        public String responseBody;
    }
    
    /**
     * Invocable method to assign prospect to Gong flow
     * Can be called from Process Builder, Flow, or other automation
     */
    @InvocableMethod(label='Assign Contact to Gong Flow' 
                     description='Assigns a Salesforce Contact to a Gong Flow for engagement tracking')
    public static List<GongFlowOutput> assignContactToGongFlow(List<GongFlowInput> inputs) {
        // Validate that only one input is provided (typical Flow usage)
        if (inputs == null || inputs.isEmpty()) {
            throw new CalloutException('No input provided');
        }
        
        if (inputs.size() > 1) {
            throw new CalloutException('Only one contact can be processed at a time');
        }
        
        GongFlowInput input = inputs[0];
        GongFlowOutput output = new GongFlowOutput();
        
        try {
            // Validate input
            if (String.isBlank(input.contactId)) {
                output.success = false;
                output.message = 'Contact ID is required';
                return new List<GongFlowOutput>{output};
            }
            
            // Create Samsara log for tracking (DML only)
            String samsaraLogId = createSamsaraLog(input.contactId);
            
            // Log API call start (DML only)
            createSamsaraLogEntry(samsaraLogId, 'INFO', 'Gong API Call Started', 'Initiating Gong flow assignment for contact: ' + input.contactId, input.contactId);
            
            // Queue the callout for async execution - flowId will be loaded from metadata in the queueable
            System.enqueueJob(new GongApiCalloutQueueable(samsaraLogId, input.contactId));
            
            // Return immediate response
            output.success = true;
            output.message = 'Gong flow assignment initiated. Processing in background.';
            output.responseBody = '{"status": "queued", "logId": "' + samsaraLogId + '"}';
            
        } catch (Exception e) {
            output.success = false;
            output.message = 'Error: ' + e.getMessage();
            output.responseBody = '';
            
            System.debug('Gong Flow Assignment Failed: ' + e.getMessage());
        }
        
        return new List<GongFlowOutput>{output};
    }
    
    
    
    
    /**
     * Create Samsara log for tracking Gong API calls
     */
    private static String createSamsaraLog(String contactId) {
        try {
            SamsaraLog__c samsaraLog = new SamsaraLog__c(
                Functionality_Type__c = 'Gong Integration',
                Functionality_Sub_Type__c = 'Flow Assignment',
                Context_User__c = UserInfo.getUserId(),
                RecordId__c = contactId
            );
            insert samsaraLog;
            return samsaraLog.Id;
        } catch (Exception e) {
            System.debug('Error creating Samsara Log: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Create Samsara log entry for detailed tracking
     */
    private static void createSamsaraLogEntry(String samsaraLogId, String level, String exceptionType, String message, String contactId) {
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