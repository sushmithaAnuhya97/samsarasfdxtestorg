public class LogManager {
    private static List<Api_Logger__c> logBuffer = new List<Api_Logger__c>();

    /**
     * Adds a log entry to the buffer.
     *
     * @param trackerId       - Unique ID of the tracker.
     * @param transactionType - Type of transaction being logged.
     * @param stepStatus      - Status of the step (e.g., SUCCESS, FAILED).
     * @param startTime       - Start time of the process.
     * @param endTime         - End time of the process.
     * @param request         - (Optional) The request payload.
     * @param response        - (Optional) The response payload.
     */
    public static void log(String trackerId, String transactionType, String stepStatus, String response, DateTime startTime, DateTime endTime) {
        logBuffer.add(createLogEntry(trackerId, transactionType, stepStatus, null,response, startTime, endTime));
    }
        
    public static void log(String stepStatus, String request, String response, DateTime startTime, DateTime endTime) {
        logBuffer.add(createLogEntry('2nd method-1', '2nd method-2', stepStatus, request, response, startTime, endTime));
    }
    
     public static void log(String stepStatus, String request, DateTime startTime, DateTime endTime) {
        logBuffer.add(createLogEntry('3rd Method-1', '3rd Method-2', stepStatus, request,null, startTime, endTime));
    }

    /**
     * Creates a log entry instance.
     */
    private static Api_Logger__c createLogEntry(String trackerId, String transactionType, String stepStatus, String request, String response, DateTime startTime, DateTime endTime) {
        return new Api_Logger__c(
            Request_Tracker_Id__c = trackerId,
            Transaction_Type__c = transactionType,
            Step_Status__c = stepStatus,
            Start_Time__c = startTime,
            End_Time__c = endTime,
            Request__c = request,
            Response__c = response,
            Duration__c = (startTime != null && endTime != null) ? (endTime.getTime() - startTime.getTime()) : 0
        );
    }

    /**
     * Inserts all buffered logs in bulk for better performance.
     * Uses partial insert to prevent total failure.
     */
    public static void flushLogs() {
        if (logBuffer.isEmpty()) {
            return;
        }

        try {
            Database.SaveResult[] results = Database.insert(logBuffer, false);

            // Capture failed logs for debugging
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Log Insertion Failed: ' + error.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error inserting logs: ' + e.getMessage());
        } finally {
            logBuffer.clear();  // Clear buffer after attempted insert
        }
    }
}