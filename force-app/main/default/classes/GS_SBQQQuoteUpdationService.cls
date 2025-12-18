/**
 * Created by vikasmishra on 2021-09-16.
 */

public with sharing class GS_SBQQQuoteUpdationService implements IService{

    SamsaraLoggerService thisLoggerService = new SamsaraLoggerService();
    public Map<Id, Opportunity> targetOpportunityIdsForQuoteUpdate = new Map<Id, Opportunity>();
    @TestVisible
    Boolean transactionTypeAsync = true;
    @TestVisible
    static IInternalService thisGS_UpdateQuoteFromOpportunity = new GS_UpdateQuoteFromOpportunity();

    public void shouldUpdateSBQQQuoteInSync (){
        transactionTypeAsync = false;
    }

    public void updateSBQQQuotesFromOpportunity(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){
        processQuoteFromOpportunities(oldOppMap, newOppList);
        if(transactionTypeAsync){
            invokeAsyncSBQQQuoteProcess();
        }
        else{
            invokeSBQQQuoteProcess();
        }

    }

    public void updateSBQQQuotesFromOpportunity(Map<Id, Opportunity> opportunityMap, Map<Id, SBQQ__Quote__c> quoteMap){
        thisGS_UpdateQuoteFromOpportunity.processQuoteForUpdate(opportunityMap, quoteMap);
    }

    @TestVisible
    private void invokeSBQQQuoteProcess() {
        updateSBQQQuotesFromOpportunity(
                targetOpportunityIdsForQuoteUpdate,
                getQuotesFromOppIds(targetOpportunityIdsForQuoteUpdate.keySet())
        );
    }

    @TestVisible
    private Map<Id,SBQQ__Quote__c> getQuotesFromOppIds(Set<Id> ids) {
        return new Map<Id, SBQQ__Quote__c>(
                new GS_SBQQQuoteSelector(true)
                .checkFatalError()
                .getQuoteFromOpportunityIds(new Set<Id>(ids))
        );
    }

    @TestVisible
    private void invokeAsyncSBQQQuoteProcess() {
        DMLWrapper.doInsert (
                (List<SObject>) new GS_AsyncSBQQQuoteFromOpportunityService()
                        .prepareAsyncRequests(
                                targetOpportunityIdsForQuoteUpdate.keySet()
                        )
        );
    }

    @TestVisible
    private void processQuoteFromOpportunities(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList) {
        Boolean isUpdate = oldOppMap != null && !oldOppMap.isEmpty();
        for(Opportunity thisOpp : newOppList){
            Opportunity oldOpp;
            if(isUpdate){
                if(oldOppMap.containsKey(thisOpp.Id)){
                    oldOpp = oldOppMap.get(thisOpp.Id);
                }
                else{
                    throw new GS_SBQQQuoteUpdationServiceException('No element found in old Map.');
                }
            }
            else {
                throw new GS_SBQQQuoteUpdationServiceException('Old Map is null. This method is only getting called in After Update Context.');
            }
            if (ShouldUpdateSBQQQuote(thisOpp, oldOpp)){
                collectTargetOpportunityIds(thisOpp);
            }
        }

    }

    private Boolean ShouldUpdateSBQQQuote(Opportunity newOpp, Opportunity oldOpp) {

       return hasVatNumberChanged(newOpp, oldOpp)
               || hasResellerChanged(newOpp, oldOpp)
               || hasClosedDateChanged(newOpp, oldOpp)
               || hasInsurancePartnerChanged(newOpp, oldOpp)
               || hasResellerPartnerChanged(newOpp, oldOpp)
               || hasReferralPartnerChanged(newOpp, oldOpp);
    }
@TestVisible
    private Boolean hasInsurancePartnerChanged(Opportunity newOpp, Opportunity oldOpp) {
        return isNotNullValue(newOpp, 'Insurance_Partner__c')
                && hasFieldValuesChanged(newOpp, oldOpp, 'Insurance_Partner__c');
    }
    @TestVisible
    private Boolean hasResellerPartnerChanged(Opportunity newOpp, Opportunity oldOpp) {
        return isNotNullValue(newOpp, 'Reseller_Partner__c')
                && hasFieldValuesChanged(newOpp, oldOpp, 'Reseller_Partner__c');
    }
    @TestVisible
    private Boolean hasReferralPartnerChanged(Opportunity newOpp, Opportunity oldOpp) {
        return isNotNullValue(newOpp, 'Referral_Partner__c')
                && hasFieldValuesChanged(newOpp, oldOpp, 'Referral_Partner__c');
    }
    @TestVisible
    private Boolean hasVatNumberChanged(Opportunity newOpp, Opportunity oldOpp){
        return isNotNullValue(newOpp, 'VAT_Number__c')
                && hasFieldValuesChanged(newOpp, oldOpp, 'VAT_Number__c');
    }
    @TestVisible
    private Boolean hasResellerChanged(Opportunity newOpp, Opportunity oldOpp){
        return isNotNullValue(newOpp, 'Reseller__c')
                && hasFieldValuesChanged(newOpp, oldOpp, 'Reseller__c');
    }
    @TestVisible
    private Boolean hasClosedDateChanged(Opportunity newOpp, Opportunity oldOpp){
        return isNotNullValue(newOpp, 'CloseDate')
                && hasFieldValuesChanged(newOpp, oldOpp, 'CloseDate');
    }
    @TestVisible
    private Boolean hasFieldValuesChanged(Opportunity newOpp, Opportunity oldOpp, String targetFieldApiName){
        return newOpp.get(targetFieldApiName) != oldOpp.get(targetFieldApiName);
    }
    @TestVisible
    private Boolean isNotNullValue(Opportunity thisOpp, String field){
        return thisOpp.get(field) != null;
    }
    @TestVisible
    private void collectTargetOpportunityIds(Opportunity thisOpp) {
        targetOpportunityIdsForQuoteUpdate.put(thisOpp.Id, thisOpp);
    }

    public class GS_SBQQQuoteUpdationServiceException extends Exception{

    }

    public class GS_UpdateQuoteFromOpportunity implements IInternalService{

        public GS_UpdateQuoteFromOpportunity(){

        }
        public void processQuoteForUpdate(Map<Id, Opportunity> mapOfOpportunities, Map<Id, SBQQ__Quote__c> mapOfQuote){
            List<SObjectField> dirtyFields = new List<SObjectField>();
            for(SBQQ__Quote__c thisQuote: mapOfQuote.values()){
                dirtyFields = new List<SObjectField>();
                Opportunity thisOpp = mapOfOpportunities.get(thisQuote.SBQQ__Opportunity2__c);
                if(hasInsurancePartner(thisOpp)){
                    thisQuote.SBQQ__Partner__c = thisOpp.Insurance_Partner__c;
                    dirtyFields.add(SBQQ__Quote__c.SBQQ__Partner__c);
                }
                else if(hasResellerPartner(thisOpp)){
                    thisQuote.SBQQ__Partner__c = thisOpp.Reseller_Partner__c;
                    dirtyFields.add(SBQQ__Quote__c.SBQQ__Partner__c);
                }
                else if(hasReferralPartner(thisOpp)){
                    thisQuote.SBQQ__Partner__c = thisOpp.Referral_Partner__c;
                    dirtyFields.add(SBQQ__Quote__c.SBQQ__Partner__c);
                }

                if(customContractValidation(thisOpp)){
                    thisQuote.SBQQ__StartDate__c = thisOpp.CloseDate + 15;
                    dirtyFields.add(SBQQ__Quote__c.SBQQ__StartDate__c);
                }

                if(! dirtyFields.isEmpty()){
                    thisQuote.Recalculate_Quote__c = true;
                    dirtyFields.add(SBQQ__Quote__c.Recalculate_Quote__c);
                    DMLWrapper.doUpdate(thisQuote, dirtyFields );
                }
            }
        }

        @TestVisible
        private Boolean hasInsurancePartner(Opportunity thisOpp){
           return isNotNullValue(thisOpp, 'Insurance_Partner__c');
        }
        @TestVisible
        private Boolean hasResellerPartner(Opportunity thisOpp){
            return isNotNullValue(thisOpp, 'Reseller_Partner__c');
        }
        @TestVisible
        private Boolean hasReferralPartner(Opportunity thisOpp){
            return isNotNullValue(thisOpp, 'Referral_Partner__c');
        }
        @TestVisible
        private Boolean hasCloseDate(Opportunity thisOpp){
            return isNotNullValue(thisOpp, 'CloseDate');
        }
        @TestVisible
        private Boolean hasSBQQAmendedContract(Opportunity thisOpp){
            return isNotNullValue(thisOpp, 'SBQQ__AmendedContract__c');
        }
        @TestVisible
        private Boolean isNotNullValue(Opportunity thisOpp, String field){
            return thisOpp.get(field) != null;
        }

        @TestVisible
        private Boolean customContractValidation(Opportunity thisOpp){
          return  (thisOpp.Probability < 99)
                  && (thisOpp.Probability >= 10)
                  && (thisOpp.Type == 'Revenue Opportunity')
                  && hasSBQQAmendedContract(thisOpp)
                  && hasCloseDate(thisOpp)
                  && (thisOpp.CPQ_Opportunity__c == true);
        }

    }

    public interface IService{
        void shouldUpdateSBQQQuoteInSync ();
        void updateSBQQQuotesFromOpportunity(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList);
        void updateSBQQQuotesFromOpportunity(Map<Id, Opportunity> opportunityMap, Map<Id, SBQQ__Quote__c> quoteMap);
    }

    public interface IInternalService{
        void processQuoteForUpdate(Map<Id, Opportunity> mapOfOpportunities, Map<Id, SBQQ__Quote__c> mapOfQuote);
    }
}