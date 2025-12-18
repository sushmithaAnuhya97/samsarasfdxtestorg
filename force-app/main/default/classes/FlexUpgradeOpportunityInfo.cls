/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class FlexUpgradeOpportunityInfo {
    
    @AuraEnabled(cacheable=true)
    public static List<Contract> getContractInfo(List<String> contractIds) {
        try {
            return [
                SELECT Id, 
                       ContractNumber, 
                       StartDate, 
                       EndDate, 
                       Status
                FROM Contract 
                WHERE Id IN :contractIds
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving contract information: ' + e.getMessage());
        }
    }
}