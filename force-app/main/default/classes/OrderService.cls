public class OrderService {
    
    // Save the Request Tracker record and return the Tracker ID
    public static Request_Tracker__c findRequestTrackerCount(String orderId) {
        if(String.isBlank(orderId)) return null;
        
        List<Request_Tracker__c> trackerList = [SELECT Id,Retry_Count__c FROM Request_Tracker__c WHERE OrderId__c = :orderId and Status__c!='Completed' LIMIT 1];
        return trackerList.isEmpty() ? null : trackerList[0];
    }
    
    // Save the Request Tracker record and return the Tracker ID
    public static Id saveRequestTracker(Request_Tracker__c requestTracker) {
        try {
            // Insert the Request Tracker record
            Database.UpsertResult upsertResult = Database.upsert(requestTracker);
            
            if (upsertResult.isSuccess()) {     
                // Log entry for the request
                createLogEntry(upsertResult.getId(), requestTracker.Transaction_Type__c, requestTracker.Status__c, OrderUtil.STEP_1 + ': Info');
                
                // Return the ID of the newly created Request Tracker record
                return upsertResult.getId();
            } else {
                throw new RequestTrackerException(OrderUtil.ERROR_SAVING_REQUEST);
            }
        } catch (DMLException ex) {
            throw new RequestTrackerException(OrderUtil.ERROR_DATABASE + ex.getMessage());
        } catch(Exception ex){
            throw new RequestTrackerException(ex.getMessage());
        }
    }
    
    // Create a log entry in the Api_Logger__c object
    public static void createLogEntry(Id requestTrackerId, String transactionType, String message,String stepStatus) {
        LogManager.log(requestTrackerId,transactionType,stepStatus,message,DateTime.now(), DateTime.now()); 
        LogManager.flushLogs();
    }
}