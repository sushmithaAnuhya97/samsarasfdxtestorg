public without sharing class AccountPoolReassignController { 
    public class EligibilityResult {
        @AuraEnabled public Boolean isInboundAdr;
        @AuraEnabled public Boolean isOwnedByPool;
        @AuraEnabled public String recordName;
        @AuraEnabled public String error;
    }
    public class ReassignResult {
        @AuraEnabled public List<String> messages;
        public ReassignResult() {
            messages = new List<String>();
        }
    }


    @TestVisible private static String testOverridePoolOwnerId;
    @TestVisible private static List<String> testOverrideInboundAdrProfileIds;

    // Shared helpers
    private static List<String> getInboundAdrProfileIds() {
        List<String> inboundAdrProfileIds = new List<String>();
        if (Test.isRunningTest() && testOverrideInboundAdrProfileIds != null) {
            inboundAdrProfileIds.addAll(testOverrideInboundAdrProfileIds);
        } else {
            String inboundAdrProfileIdsStr = System.Label.Samsara_Inbound_ADR_Id;
            if (inboundAdrProfileIdsStr != null) {
                inboundAdrProfileIds = inboundAdrProfileIdsStr.split(',');
            }
        }
        return inboundAdrProfileIds;
    }

    private static String getPoolOwnerId() {
        return (Test.isRunningTest() && !String.isBlank(testOverridePoolOwnerId))
            ? testOverridePoolOwnerId
            : System.Label.Shark_Tank_User_Id;
    }

    private static EligibilityResult buildEligibility(Id recordId) {
        EligibilityResult result = new EligibilityResult();
        if (recordId == null) {
            result.error = 'No record Id provided.';
            return result;
        }

        List<String> inboundAdrProfileIds = getInboundAdrProfileIds();
        Id currentUserProfileId = UserInfo.getProfileId();
        result.isInboundAdr = inboundAdrProfileIds.contains(String.valueOf(currentUserProfileId));

        String poolOwnerId = getPoolOwnerId();

        SObjectType sObjectType = recordId.getSObjectType();
        if (sObjectType != Account.SObjectType && sObjectType != Contact.SObjectType) {
            result.error = 'Unsupported record type for Id ' + recordId;
            return result;
        }

        String sobjectApiName = sObjectType.getDescribe().getName();
        SObject genericRecord = Database.query('SELECT Id, Name, OwnerId FROM ' + sobjectApiName + ' WHERE Id = :recordId LIMIT 1');
        result.recordName = (String)genericRecord.get('Name');
        result.isOwnedByPool = String.valueOf(genericRecord.get('OwnerId')) == poolOwnerId;

        if (!result.isInboundAdr) {
            result.error = 'Only users with the Samsara Inbound ADRs profile can reassign records';
            return result;
        }

        if (!result.isOwnedByPool) {
            String nameForMsg = String.isBlank(result.recordName) ? 'This record' : result.recordName;
            result.error = nameForMsg + ' is not owned by the SFDC Shark Tank User and cannot be reassigned.';
            return result;
        }
        return result;
    }


    @AuraEnabled(cacheable=true)
    public static EligibilityResult checkEligibility(Id recordId) {
        return buildEligibility(recordId);
    }

    @AuraEnabled
    public static ReassignResult reassignFromPool(List<Id> recordIds) {
        ReassignResult result = new ReassignResult();

        if (recordIds == null || recordIds.isEmpty()) {
            result.messages.add('No record Ids provided.');
            return result;
        }

        Id currentUserId = UserInfo.getUserId();

        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Id recordId : recordIds) {
            SObjectType recordSObjectType = recordId.getSObjectType();
            if (recordSObjectType == Account.SObjectType) {
                accountIds.add(recordId);
            } else if (recordSObjectType == Contact.SObjectType) {
                contactIds.add(recordId);
            } else {
                result.messages.add('Unsupported record type for Id ' + recordId);
            }
        }

        if (!accountIds.isEmpty()) {
            reassignPoolOwnedRecords(accountIds, Account.SObjectType, currentUserId, result);
        }

        if (!contactIds.isEmpty()) {
            reassignPoolOwnedRecords(contactIds, Contact.SObjectType, currentUserId, result);
        }

        return result;
    }



    private static void reassignPoolOwnedRecords(Set<Id> recordIds, SObjectType recordSObjectType, Id newOwnerId, ReassignResult result) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }
        String poolOwnerId = getPoolOwnerId();
        String sobjectApiName = recordSObjectType.getDescribe().getName();
        List<SObject> recordsToUpdate = Database.query('SELECT Id FROM ' + sobjectApiName + ' WHERE Id IN :recordIds AND OwnerId = :poolOwnerId');
        for (SObject rec : recordsToUpdate) {
            rec.put('OwnerId', newOwnerId);
        }
        try {
            update recordsToUpdate;
        } catch (Exception e) {
            gslib_ILogger logger = gslib_LoggerService.getModuleLogger('GTMS').getLogger();
            logger.logError('AccountPoolReassignController failed', 
                        new SamsaraLoggerObjectMVP(e.getMessage(), 'AccountPoolReassignController'));
            logger.dispatch();
            result.messages.add(e.getMessage());
        }
    }
}