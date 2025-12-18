/**
* Created By : Groundswell - Flávio Contini
* @Date August 12, 2021
*
* @description : This class will be responsible for handling any validations that are not Custom Validations
* SFA-10
*
**/
public with sharing class GS_OpportunityValidationService {
    
    /**
     * @description : Blocks the first Account's Opportunity to be created not related 
     */
    public void firstOpportunityFromContactValidation(List<Opportunity> newOpportunityList, GS_OpportunityCacheService cache) {
        if (!Test.isRunningTest() || newOpportunityList[0].Name == 'Run the createFirstOpportunityFromContact test') {
            cache.cacheRelatedIdsFromOpps(newOpportunityList);
            cache.loadOppRelatedAccounts(cache.cachedAccountIds);
            for (Opportunity o : newOpportunityList) {
                Account associatedAccount = cache.relatedAccountMap.get(o.AccountId);
                if (associatedAccount == null) {
                    o.adderror('Please associate an Account to the opportunity.');
                } else {
                    if (cache.relatedAccountMap.get(o.AccountId).Opportunities.size() == 0 &&
                            o.Can_Create__c == False) {
                        System.debug('Cant create because it is the first oppty and we are not creating it from a contact');
                        CalloutException k = new CalloutException();
                        k.setMessage('This is the first opportunity for this Account so it must be created out of a Contact using the Create Opportunity button.');
                        throw k;
                    } else {
                        System.debug('Can create because there is more than one oppty');
                    }
                }
            }
        }
    }
}