/**
* Created By : Groundswell - Suman Kundu
* @Date September 10, 2021
*
* @description : This class will be responsible for handling all Quote to Oppotunity Mapping queries / SOQLs
*
**/
public inherited sharing class GS_QuoteToOpportunityMappingSelector extends GS_SObjectBaseSelector{

    public GS_QuoteToOpportunityMappingSelector(Boolean checkFatalError){
        super(checkFatalError);
    }
     
    public GS_QuoteToOpportunityMappingSelector checkFatalError(){
        return (GS_QuoteToOpportunityMappingSelector) super.validateFatalError();
    }

    /**
     * Return the Opportunity by Id with the base fields to get the resolution status
     * @param List<id> idList
     */
    public List<Quote_To_Opportunity_Mapping__mdt> getFieldMapping(){
        return [
            SELECT Id, Opportunity_Field__c, Quote_Field__c, Type__c, Null_Check__c, Bypass__c, Owner_Segment__c 
            FROM Quote_To_Opportunity_Mapping__mdt
        ];
    }
}