public class ContactStatusUpdateScheduler implements Schedulable {
    private Id contactId;
    private DateTime taskTime;
    
    public ContactStatusUpdateScheduler(Id contactId, DateTime taskTime) {
        this.contactId = contactId;
        this.taskTime = taskTime;
    }
    
    public void execute(SchedulableContext sc) {
        try {
            // Query the contact
            Contact contact = [SELECT Id, Status__c 
                               FROM Contact 
                               WHERE Id = :contactId LIMIT 1];
            
            if(contact == null) {
                return;
            }
            
            // Check if status is already Demo Scheduled
            if(contact.Status__c == 'Demo Scheduled') {
                return;
            }
            
            // Query ADR Transfer Logs created only between task time and scheduled time
            List<ADR_Transfer_Log__c> recentLogs = [
                SELECT Id 
                FROM ADR_Transfer_Log__c 
                WHERE Contact__c = :contactId 
                AND CreatedDate >= :taskTime
                AND CreatedDate <= :taskTime.addHours(24)
                ORDER BY CreatedDate DESC LIMIT 1
            ];
            
            // Only update if no ADR transfer logs exist in the time window
            if(recentLogs.isEmpty()) {
                contact.Status__c = 'Retouch - Confirmed No Opportunity';
                update contact;
            } else {
                System.debug('ADR transfer log found during the 24-hours window, skipping status update');
            }
            
        } catch(Exception e) {
            System.debug('Error in ContactStatusUpdateScheduler: ' + e.getMessage() + '\n' + e.getStackTraceString());
        } 
    }
}