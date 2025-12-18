public class UpdateSplitACVValuesController {
    @AuraEnabled
    public static String updateACVValues(Id recordId) {
        try {
            if (recordId == null) {
                throw new AuraHandledException('Record ID is required.');
            }
            JobPopulateOpprtunitySplitData job = new JobPopulateOpprtunitySplitData(null, recordId);
            ID batchProcessId = Database.executeBatch(job, 1);
            
            return 'Batch job submitted successfully with ID: ' + batchProcessId;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to initiate batch job: ' + e.getMessage());
        }
    }
}