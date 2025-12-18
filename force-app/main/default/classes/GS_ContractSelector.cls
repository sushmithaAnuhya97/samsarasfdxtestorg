/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 05, 2021
*
* @description : This class will be responsible for handling all the Contract Related Queries
* SFA-10
*
**/
public with sharing class GS_ContractSelector {
    
    /**
     * Retrieves the Contracts with Related Opportunity data by Id
     * @param List<Id> idList
     */
    public List<Contract> getContractsWithOppDataById(List<Id> idList){
        return [
            SELECT Id, StartDate, EndDate, ContractNumber, Original_Reseller_ID__c,
                  SBQQ__Opportunity__r.Shipping_Contact__c, SBQQ__Opportunity__r.Payment_Terms__c, SBQQ__Opportunity__r.Selected_Payment_Type__c,
                  SBQQ__Opportunity__r.Approved_Discount__c, SBQQ__Opportunity__r.Reseller__c, SBQQ__Opportunity__r.Finance_Partner__c, 
                  SBQQ__Opportunity__r.Shipping_Address_NEW__c, SBQQ__Opportunity__r.OwnerId, SBQQ__Opportunity__c, Account.Name ,Original_Approved_Discount__c
            FROM Contract
            WHERE Id IN :idList
        ];
    }

    /**
     * Retrieves the Contracts for provided Ids
     * @param Set<Id> contractIds
     */
    public Map<Id, Contract> getContractData(Set<Id> contractIds){
        return new Map<Id, Contract>([
            SELECT Id, EndDate, Auto_Renewal__c 
            FROM Contract 
            WHERE ID IN : contractIds
        ]);      
   }
}