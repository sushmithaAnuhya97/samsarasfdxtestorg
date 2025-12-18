/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-11-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class FlexSelectedContractDetails {
    @AuraEnabled(cacheable=true)
    public static List<Contract> getContractDetails(List<String> contractIds) {
        try {
            return [
                SELECT Id, ContractNumber, StartDate, EndDate, CurrencyIsoCode, Contract_Renewable_ACV__c, Status
                FROM Contract 
                WHERE Id IN :contractIds
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving contract details: ' + e.getMessage());
        }
    }
}