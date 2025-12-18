/**
 * Created by vikasmishra on 2021-09-16.
 */

public with sharing class GS_QuotaOpportunitySelector extends GS_SObjectBaseSelector{
    public GS_QuotaOpportunitySelector(Boolean checkFatalError){
        super(checkFatalError);
    }

    public GS_QuotaOpportunitySelector checkFatalError(){
        return (GS_QuotaOpportunitySelector) super.validateFatalError();
    }

    public List<Quota_Opportunity__c> getQuotaOpportunitiesFromOpportunityIds(Set<Id> opportunityIds){
        return [SELECT Id
        FROM Quota_Opportunity__c
        WHERE Opportunity__c IN :opportunityIds];
    }

}