public with sharing class GS_TriggerRecursionManager {
    private static Map<String, Map<String, Set<Id>>> triggerContextMap = new Map<String, Map<String, Set<Id>>>();
    
    // Below method checks if trigger context records already went through same event and getting called recursively. 
    public static Map<Id, SObject> getNonRecursiveRecords(String objectName, String event, Map<Id, SObject> recordMap) {
        // Checking if object not yet executed in trigger
        if (!triggerContextMap.containsKey(objectName)) {
            triggerContextMap.put(objectName, new Map<String, Set<Id>>());
        }
        // Checking if object's event not yet executed in trigger
        if (!triggerContextMap.get(objectName).containsKey(event)) {
            triggerContextMap.get(objectName).put(event, new Set<Id>());
        }
        Set<Id> processedRecordIds = triggerContextMap.get(objectName).get(event);
        Map<Id, SObject> resultant = new Map<Id, SObject>();
        for (Id currentContextRecordId : recordMap.keySet()) {
            // Checking if current context record Id is not yet processed, add in resultant list
            if (!processedRecordIds.contains(currentContextRecordId)) {
                resultant.put(currentContextRecordId, recordMap.get(currentContextRecordId));
                processedRecordIds.add(currentContextRecordId);
            }
        }
        return resultant;
    }
}