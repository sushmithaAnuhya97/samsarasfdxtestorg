//Batch class to update Contact ADR Assignments based on Account ADR 
public class ContactADRAssignmentBatch implements Database.Batchable<sObject> {
    private Set<Id> accountIds;

    public ContactADRAssignmentBatch(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, 
                   AccountId,
                   ADR_Assignment__c,
                   ADR_Assignment__r.UserRole.Name, 
                   Account.ADRAssignment__c, 
                   Account.ADRAssignment__r.UserRole.Name,
                   Account.OwnerId,
                   OwnerId,
                   Owner.UserRole.Name
            FROM Contact 
            WHERE AccountId IN :accountIds
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Contact> scope) {
        try {
            List<Contact> contactsToUpdate = new List<Contact>();
            for (Contact con : scope) {
                Id oldADRId = con?.ADR_Assignment__c;
                Id newADRId = con.Account?.ADRAssignment__c;

                if (oldADRId != null && newADRId != null && oldADRId == newADRId) {
                    continue;
                }

                // Update the ADR assignment to the new Account ADR assignment
                con.ADR_Assignment__c = newADRId;

                if (newADRId != null) {
                    Boolean currentOwnerRoleIsADR = isADRRole(con.Owner?.UserRole?.Name);
                    Boolean newADRRoleIsADR = isADRRole(con.Account?.ADRAssignment__r?.UserRole?.Name);

                    Id newOwnerId = assignNewContactOwner(con, oldADRId, currentOwnerRoleIsADR, newADRRoleIsADR);
                    if (newOwnerId != null) {
                        con.OwnerId = newOwnerId;
                    }
                }

                contactsToUpdate.add(con);
            }

            if (contactsToUpdate.isEmpty()) return;

            List<Api_Logger__c> apiLoggers = new List<Api_Logger__c>();
            Database.SaveResult[] saveResults = Database.update(contactsToUpdate, false);
            for (Integer i = 0; i < saveResults.size(); i++) {
                Contact contact = contactsToUpdate[i];
                if (!saveResults[i].isSuccess()) {
                    Database.Error error = saveResults[i].getErrors()[0];
                    Api_Logger__c logger = logError(contact.AccountId, error.getMessage(), error);
                    apiLoggers.add(logger);
                }
            }
            if (!apiLoggers.isEmpty()) {
                insert apiLoggers;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating contacts: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Contact ADR Assignment batch job completed');
    }

    /**
     * Helper method to assign new owner to a contact based on ADR role scenarios
     * @param con The contact record to update
     * @param oldAdrId The old ADR ID
     * @param currentOwnerIsADR Boolean indicating if current owner has ADR role
     * @param newUserIsADR Boolean indicating if new user has ADR role
     * @return Id The ID of the new owner to be assigned
     */
    private static Id assignNewContactOwner(Contact con, Id oldAdrId, Boolean currentOwnerIsADR, Boolean newUserIsADR) {
        // Skip if contact's current owner wasn't the assigned ADR
        if (!isCurrentOwnerOldADR(con, oldAdrId)) return null;

        // Determine new owner based on ADR role scenarios
        return shouldAssignToNewADR(currentOwnerIsADR, newUserIsADR) 
            ? con.ADR_Assignment__c    // Assign to new ADR
            : con.Account.OwnerId;    // Assign to Account Owner
    }

    /**
     * Helper method to check if contact's current owner is the old ADR
     * @param con The contact record to check
     * @param oldAdrId The old ADR ID
     * @return Boolean indicating if current owner matches old ADR
     */
    private static Boolean isCurrentOwnerOldADR(Contact con, Id oldAdrId) {
        return con.OwnerId == oldAdrId;
    }

    /**
     * Helper method to determine if contact should be assigned to new ADR
     * @param currentOwnerIsADR Boolean indicating if current owner has ADR role
     * @param newUserIsADR Boolean indicating if new user has ADR role
     * @return Boolean indicating if contact should be assigned to new ADR
     */
    @TestVisible
    private static Boolean shouldAssignToNewADR(Boolean currentOwnerIsADR, Boolean newUserIsADR) {
        return currentOwnerIsADR && newUserIsADR;
    }

    /**
     * Helper method to determine if a role is an ADR role
     * @param roleName The name of the role to check
     * @return Boolean indicating if the role is an ADR role
     */
    @TestVisible
    private static Boolean isADRRole(String roleName) {
        return roleName != null && roleName.containsIgnoreCase('ADR');
    }

    /**
     * Logs an error encountered during the batch update process.
     *
     * @param accountId The ID of the account associated with the contact that failed to update.
     * @param message A descriptive error message detailing the cause of the failure.
     * @param err The Database.Error object containing detailed error information.
     * @return An instance of Api_Logger__c containing the error details for logging purposes.
     *
     * This method creates an Api_Logger__c record with the error details, including the account ID,
     * error message, and a serialized representation of the error object. The logger instance can be
     * used to insert the error log into the database for further analysis and troubleshooting.
     */
    @TestVisible
    private static Api_Logger__c logError(Id accountId, String message, Database.Error err) {
        Api_Logger__c aplog = new Api_Logger__c();
        aplog.Name =  ContactADRAssignmentBatch.class.getName() + System.now();
        apLog.Exception_Message__c = message;
        Map<String, Object> requestParams = new Map<String, Object>();
        requestParams.put('accountId', accountId);
        apLog.Request__c = JSON.serialize(requestParams);
        apLog.Response__c= JSON.serializePretty(err, true);
        return apLog;
    }
}