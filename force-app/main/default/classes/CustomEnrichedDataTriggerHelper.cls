/**
 * Helper class for handling Custom Enriched Data (CED) trigger logic.
 */
public inherited sharing class CustomEnrichedDataTriggerHelper {

    @TestVisible
    private static Boolean IS_MOCK_SOURCE_VALUE = false;  // vaiable to mock the test class logic
    
    @TestVisible
    private static final String INVALID_SOURCE_FIELD_VALUE = 'TestValueSamsaraSource'; // vaiable to mock the test class logic

    /**
     * Updates the Origination Source field on the Account object based on the Custom Enriched Data (CED) records.
     *
     * @param newCEDMap A map of new Custom Enriched Data (CED) records.
     * @param oldCEDMap A map of old Custom Enriched Data (CED) records.
     */
    public static void updateOriginationSourceAccount(Map<Id, Custom_Enriched_Data__c> newCEDMap, Map<Id, Custom_Enriched_Data__c> oldCEDMap) {
        Set<Id> accountIds = new Set<Id>();

        List<Custom_Enriched_Data__c> cedList = Trigger.isDelete ? oldCEDMap.values() : newCEDMap.values();
        
        for (Custom_Enriched_Data__c ced : cedList) {
            Custom_Enriched_Data__c oldCED = oldCEDMap != null ? oldCEDMap.get(ced.Id) : null;
            if (ced.Sub_Type__c == 'Account Origination' 
            || (oldCED != null && oldCED.Sub_Type__c == 'Account Origination')) {
                
                if (Trigger.isDelete
                    || oldCED == null 
                    || oldCED.Sub_Type__c != ced.Sub_Type__c 
                    || oldCED.Source__c != ced.Source__c) {
                    
                        accountIds.add(ced.Related_Account__c);
                }
            }
        }

        if(accountIds.isEmpty()) return;

        try {
            List<Account> listOfAccounts = [SELECT 
                                            Id, 
                                            Fleet_Seek_Number__c,
                                            (SELECT Id,  Source__c FROM Custom_Enriched_Datas__r WHERE Sub_Type__c = 'Account Origination' Order BY CreatedDate ASC LIMIT 1)
                                        FROM
                                            Account 
                                        WHERE 
                                            Id IN :accountIds
                                        WITH SECURITY_ENFORCED LIMIT 50000];
            
            if(listOfAccounts.isEmpty()) return;

            for (Account acc : listOfAccounts) {
                Boolean isCERRecordsExists = acc.Custom_Enriched_Datas__r.size()>0;
                    
                if(isCERRecordsExists){ //handle for after insert, after update and after undelete
                    String source = !IS_MOCK_SOURCE_VALUE ? acc.Custom_Enriched_Datas__r[0].Source__c : INVALID_SOURCE_FIELD_VALUE;
                    acc.Fleet_Seek_Number__c = source; 
                }else{ //handle for after delete
                    acc.Fleet_Seek_Number__c = null;
                }
            }

            Database.SaveResult[] srList = Database.update(listOfAccounts, false);

            Map<Id, String> accIdErrorMessage =  new Map<Id, String>();
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    // Operation failed, so get first error
                    accIdErrorMessage.put(sr.getId(), sr.getErrors()[0].getMessage());
                }
            }

            for (Custom_Enriched_Data__c ced : cedList) {
                if (accIdErrorMessage.containsKey(ced.Related_Account__c)) {
                    ced.addError(System.Label.ADR_Incentive_LWC_Generic_error);
                    System.debug('CustomEnrichedDataTriggerHelper ->>'+accIdErrorMessage.get(ced.Related_Account__c));
                }
            } 
            
        } catch (Exception e) {
            System.debug('CustomEnrichedDataTriggerHelper ->>'+e.getMessage());
        }
    }
}