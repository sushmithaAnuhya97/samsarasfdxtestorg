/**
 * @description       : Service class for handing the logic realted to RETURN( SWAP ) opportunities.
 * @author            : hitesh.garg
 * @group             : 
 * @last modified on  : 09-01-2025
 * @last modified by  : hitesh.garg
**/
public inherited sharing class ReturnOpportunityService {

    private static final String SUB_TYPE_UPGRADE    =   'Upgrade Opportunity';
    private static final String ERROR_MESSAGE       =   System.Label.Error_Message_for_SWAP_Opportunity;

    /**
    * @description  This method is used to validate anf throw an error if there is NO related opportunity 
                    with subtype = Upgrade exists on the return opportunity.
    * @author hitesh.garg | 08-29-2025 
    * @param returnOppIdToOppRecMap 
    **/
    public void validateSwapOpportunity( Map< Id, Opportunity > returnOppIdToOppRecMap  ) {

        if( returnOppIdToOppRecMap == null || returnOppIdToOppRecMap.isEmpty() ){
            return;
        }
        
        Map< Id, Integer > oppIdToRelatedOppCountMap    =   getRelatedOpportunityCountBySubtype( 
                                                                returnOppIdToOppRecMap.keySet(), 
                                                                SUB_TYPE_UPGRADE 
                                                            );

        if( oppIdToRelatedOppCountMap.isEmpty() ){
            returnOppIdToOppRecMap.values().get(0).addError( ERROR_MESSAGE );
            return;
        }

        for( Opportunity returnOppRec : returnOppIdToOppRecMap.values() ) {

            Integer relatedOppCount =   oppIdToRelatedOppCountMap.get( returnOppRec.Id );
            // Validate and add errors for opportunities without related records
            if( relatedOppCount == null || relatedOppCount == 0) {
                returnOppRec.addError( ERROR_MESSAGE );
                break;
            }
        }
    }

    /**
    * @description  This method is used to get Related_Opportunity__c aggregated count 
                    grouped by Associated_Opportunity__c( return opportunity )
    * @author hitesh.garg | 08-29-2025 
    * @param associatedOppIdSet 
    * @param subType 
    * @return Map<Id, Integer> 
    **/
    private Map< Id, Integer > getRelatedOpportunityCountBySubtype( Set< Id > associatedOppIdSet, 
                                                                    String subType ) {
        List< AggregateResult > aggregatedResultList    =   [
                                                                SELECT Associated_Opportunity__c, 
                                                                COUNT(Id) recordCount
                                                                FROM Related_Opportunity__c 
                                                                WHERE Associated_Opportunity__c IN :associatedOppIdSet
                                                                AND Revenue_Opportunity__c != null
                                                                AND Sub_Type__c = :subType
                                                                GROUP BY Associated_Opportunity__c
                                                            ];
        
        Map< Id, Integer > oppIdToRelatedOppCountMap = new Map< Id, Integer >();

        for( AggregateResult result : aggregatedResultList ) {

            Id oppId = (Id) result.get('Associated_Opportunity__c');
            Integer count = (Integer) result.get('recordCount');

            oppIdToRelatedOppCountMap.put( oppId, count );

        }
        
        return oppIdToRelatedOppCountMap;
    }

    
}