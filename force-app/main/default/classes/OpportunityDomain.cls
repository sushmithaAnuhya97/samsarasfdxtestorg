/**
 * Created by henryzhao on 2020-01-27.
 * 5/14/20 Harsha - (GTMS-828): updateDiscountOnOpptyTypeChange (Commented out the method after discussing it with the business)
 */

public class OpportunityDomain {

    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
            Opportunity.SObjectType,
            OpportunityLineItem.SObjectType,
            Quote.SObjectType,
            QuoteLineItem.SObjectType,
            Account.SObjectType
    };
    public static void onOpportunityTrigger() {
        try {
            OpportunityStateManager store = OpportunityStateManager.getInstance();
            UnitOfWork uow = new UnitOfWork(MY_SOBJECTS);
            switch on Trigger.operationType {
                when AFTER_UPDATE {
                    Integer soqlLim = Limits.getQueries();
                    Integer dmlLim = Limits.getDmlStatements();
                    TrialOpportunityService.emailOnTrialAgreementAcceptance(
                            store,
                            uow,
                            (Map<Id, Opportunity>) Trigger.oldMap,
                            (Map<Id, Opportunity>) Trigger.newMap);
                    //DiscountService.updateDiscountOnOpptyTypeChange(
                    //        store,
                    //        uow,
                    //        (Map<Id, Opportunity>) Trigger.oldMap,
                    //        (Map<Id, Opportunity>) Trigger.newMap);
                /* OpportunityQuoteService.expressCheckoutQuoteCreator(
                        store,
                        uow,
                        (Map<Id, Opportunity>) Trigger.oldMap,
                        (Map<Id, Opportunity>) Trigger.newMap); */

                    System.debug(LoggingLevel.INFO, '##### OpportunityDomain -> onOpportunityTrigger -> added queries: ' + String.valueOf(Limits.getQueries() - soqlLim));
                    System.debug(LoggingLevel.INFO, '##### OpportunityDomain -> onOpportunityTrigger -> added dml: ' + String.valueOf(Limits.getDmlStatements() - dmlLim));
                }
            }
            uow.commitWork();

        } catch (Exception e) {
//                    ErrorLogger.publishError(e.getStackTraceString(), e.getMessage(), 'AFTER_UPDATE Exception');
            throw e;
        }
    }
}