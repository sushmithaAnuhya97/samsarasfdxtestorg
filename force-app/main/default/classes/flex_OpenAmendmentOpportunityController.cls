/**
 * @description       : 
 * @author            :
 * @group             : 
 * @last modified on  : 01-17-2025
 * @last modified by  : Anurag Bhatt
**/
public with sharing class flex_OpenAmendmentOpportunityController {
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getAmendmentOpportunities(List<Id> lstContractIds) {
      
        // Query opportunities for each contractId and add them to the list
       /* List<Opportunity> contractOpportunities = [
                SELECT Id, Name, StageName, CloseDate, Amount, ContractId, ACV_Amount_Multi_Currency__c,
                       Owner.Name,SBQQ__AmendedContract__c, SBQQ__AmendedContract__r.ContractNumber
                FROM Opportunity
                WHERE SBQQ__AmendedContract__c IN :lstContractIds and IsClosed = false];
        

        return contractOpportunities;*/
        List<Opportunity> contractOpportunities = new List<Opportunity>();
        Set<Opportunity> setOfOpportunity = new Set<Opportunity>();
        Set<Id> opptyidFromquoteline = new Set<Id>();
        List<Opportunity> licProductOppty = [SELECT Id, Name, StageName, CloseDate, Amount, ContractId, ACV_Bookings_SOT__c,
                       Owner.Name,SBQQ__AmendedContract__c, SBQQ__AmendedContract__r.ContractNumber FROM Opportunity WHERE SBQQ__AmendedContract__c IN :lstContractIds AND IsClosed=false AND of_LIC_Products__c!=0];
  
        // List<SBQQ__QuoteLine__c> qotlineRecOfLicProduct = [SELECT SBQQ__Quote__r.SBQQ__Opportunity2__c FROM SBQQ__QuoteLine__c WHERE SBQQ__ProductCode__c LIKE 'LIC%' 
	  	// 										 AND  SBQQ__Quote__r.SBQQ__Opportunity2__r.IsClosed=false AND
     	// 										 SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c IN : lstContractIds];
        // for(SBQQ__QuoteLine__c qotLine: qotlineRecOfLicProduct){
        //     opptyidFromquoteline.add(qotLine.SBQQ__Quote__r.SBQQ__Opportunity2__c);
        // }
        
        List<Opportunity> opptyIdToCheckForLicProduct = [SELECT Id, Name, StageName, CloseDate, Amount, ContractId, ACV_Bookings_SOT__c,
                       Owner.Name,SBQQ__AmendedContract__c, SBQQ__AmendedContract__r.ContractNumber FROM Opportunity WHERE SBQQ__AmendedContract__c IN :lstContractIds AND IsClosed=false AND Id IN :opptyidFromquoteline];
  	    setOfOpportunity.addAll(licProductOppty);
        setOfOpportunity.addAll(opptyIdToCheckForLicProduct);
        contractOpportunities.addAll(setOfOpportunity);
        return contractOpportunities;
        }
}