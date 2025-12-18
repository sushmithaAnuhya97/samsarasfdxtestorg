/**
 * Created by henryzhao on 2020-01-16.
 */

public class DiscountService {

    final static public String APPROVED = 'Approved';
    final static private Set<String> AVAILABLE_TRIAL_OPP_TYPES = new Set<String>{
            'Free Trial Opportunity',
            'Promo Opportunity',
            'Free Trial Return',
            'Exchange',
            'Warranty Exchange'
    };
    public final static List<String> DISCOUNTED_EXPRESS_PAYMENTS = new List<String>{
            'Direct Annual', 'Upfront Payments'
    };

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-02-03
    *
    * @description Resets discount approval status if necessary
    * https://samsarasalessystems.atlassian.net/browse/SS-286
    *
    * Not yet deployed for Production
    */
//    public static void nullDiscountApprovalStatus(
//            OpportunityStateManager store,
//            UnitOfWork uow,
//            Map<Id, Opportunity> oldOpps,
//            Map<Id, Opportunity> newOpps) {
//
//        for (Opportunity newOpp : newOpps.values()) {
//            if (!(newOpp.IsClosed == FALSE)) {
//                continue;
//            }
//            final Opportunity oldOpp = oldOpps.get(newOpp.Id);Opportunity toUpdate = (Opportunity) uow.getUpdateableDirty(newOpp);
//            Decimal approvedDiscount = toUpdate.Approved_Discount__c;
//            if (toUpdate.Express_Discount_Applied__c != null && approvedDiscount != null) {
////                this means express discount was applied
//                approvedDiscount -= toUpdate.Express_Discount_Applied__c;
//            }
//            if ((approvedDiscount < toUpdate.Blended_Discount__c || approvedDiscount == null) && oldOpp.Discount_Approval_Status__c == APPROVED) {
//                toUpdate.Discount_Approval_Status__c = null;
//                System.debug(LoggingLevel.INFO, '##### DiscountService -> nullDiscountApprovalStatus -> updating');
//
//                uow.registerDirty(toUpdate);
//            }
//        }
//    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-01-30
    *
    * @description If Selected_Payment_Type__c changed to a value that we expect, set the new approved discount
    *
    * Not yet deployed to Production
    */
//    public static void setExpressDiscountApplied(
//            OpportunityStateManager store,
//            UnitOfWork uow,
//            Map<Id, Opportunity> oldOpps,
//            Map<Id, Opportunity> newOpps) {
//        for (Opportunity newOpp : newOpps.values()) {
//            final Opportunity oldOpp = oldOpps.get(newOpp.Id);
//            Opportunity toUpdate = (Opportunity) uow.getUpdateableDirty(newOpp);
//            /** check if express payment has been updated **/
//            if (toUpdate.Selected_Payment_Type__c == oldOpp.Selected_Payment_Type__c) {
//                continue;
//            }
//
//            /** we need to apply express payment discount  **/
////            check if express payment type is expected, check if express discount has been applied before
//            if (DISCOUNTED_EXPRESS_PAYMENTS.contains(toUpdate.Selected_Payment_Type__c)
//                    && isDecimalBlank(oldOpp.Express_Discount_Applied__c) && isDecimalBlank(toUpdate.Express_Discount_Applied__c)) {
//                switch on toUpdate.Selected_Payment_Type__c {
//                    when 'Direct Annual' {
//                        toUpdate.Express_Discount_Applied__c = toUpdate.Express_Annual_Discount__c;
//                    }
//                    when 'Upfront Payments' {
//                        toUpdate.Express_Discount_Applied__c = toUpdate.Express_Upfront_Discount__c;
//                    }
//                }
//
//                if (toUpdate.Approved_Discount__c != null) {
//                    toUpdate.Approved_Discount__c += toUpdate.Express_Discount_Applied__c;
//                } else {
//                    toUpdate.Approved_Discount__c = toUpdate.Express_Discount_Applied__c;
//                }
//                uow.registerDirty(toUpdate);
//            }
//        }
//
//    }
//
//    private static Boolean isDecimalBlank(Decimal val) {
//        return val == null || val == 0;
//    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-02-03
    *
    * @description Updates Approved Discount depending on Express Payment Type selected
    * https://samsarasalessystems.atlassian.net/browse/SS-286
    *
    * Not yet deployed to production.
    */
//    public static void expressSetAnnualDiscountLineItem(
//            OpportunityStateManager store,
//            UnitOfWork uow,
//            Map<Id, Opportunity> oldOppMap,
//            Map<Id, Opportunity> newOppMap) {
//        Map<Id, Opportunity> extendedOpportunityMap = store.selectExtendedOpportunityMap(newOppMap.keySet());
//
//        // Iterate thru all opp products related to these opps
//        for (Opportunity newOpp : newOppMap.values()) {
//            Opportunity oldOpp = oldOppMap.get(newOpp.Id);
//            // Update all oppty line items
//            if (oldOpp.Selected_Payment_Type__c != newOpp.Selected_Payment_Type__c) {
//                for (OpportunityLineItem oli : extendedOpportunityMap.get(newOpp.Id).OpportunityLineItems) {
//                    if (newOpp.Selected_Payment_Type__c == 'Direct Annual') {
//
//                        oli.Express_Annual_Discount__c = (((newOpp.Total_License_Due__c - (newOpp.Total_License_Due__c * (1 - (newOpp.Express_Annual_Discount__c / 100)))) / (newOpp.Total_License_Due__c / (1 - (newOpp.Express_Selected_Discount__c / 100)))) * 100);
//
//                        if (newOpp.Express_Selected_Discount__c != null) {
//                            oli.Discount = newOpp.Express_Selected_Discount__c + oli.Express_Annual_Discount__c;
//                        } else if (oli.Discount != null) {
//                            oli.Discount = oli.Discount + oli.Express_Annual_Discount__c;
//                        } else {
//                            oli.Discount = oli.Express_Annual_Discount__c;
//                        }
//
//                        if (newOpp.License_Term__c != null) {
//                            oli.Selected_Sales_Price__c = oli.UnitPrice * (100 - oli.Discount) / (newOpp.License_Term__c * 100);
//                        } else {
//                            oli.Selected_Sales_Price__c = oli.UnitPrice * (100 - oli.Discount) / (36 * 100);
//                        }
//
//                    } else if (newOpp.Selected_Payment_Type__c == 'Upfront Payments') {
//
//                        oli.Express_Upfront_Discount__c = (((newOpp.Total_License_Due__c - (newOpp.Total_License_Due__c * (1 - (newOpp.Express_Upfront_Discount__c / 100)))) / (newOpp.Total_License_Due__c / (1 - (newOpp.Express_Selected_Discount__c / 100)))) * 100);
//
//                        if (newOpp.Express_Selected_Discount__c != null) {
//                            oli.Discount = newOpp.Express_Selected_Discount__c + oli.Express_Upfront_Discount__c;
//                        } else if (oli.Discount != null) {
//                            oli.Discount = oli.Discount + oli.Express_Upfront_Discount__c;
//                        } else {
//                            oli.Discount = oli.Express_Upfront_Discount__c;
//                        }
//
//                        if (newOpp.License_Term__c != null) {
//                            oli.Selected_Sales_Price__c = oli.UnitPrice * (100 - oli.Discount) / (newOpp.License_Term__c * 100);
//                        } else {
//                            oli.Selected_Sales_Price__c = oli.UnitPrice * (100 - oli.Discount) / (36 * 100);
//                        }
//
//                    } else {
//                        oli.Express_Annual_Discount__c = 0;
//
//                        if (newOpp.Express_Selected_Discount__c != null) {
//                            oli.Discount = newOpp.Express_Selected_Discount__c + oli.Express_Annual_Discount__c;
//                        } else if (oli.Discount != null) {
//                            oli.Discount = oli.Discount + oli.Express_Annual_Discount__c;
//                        } else {
//                            oli.Discount = oli.Express_Annual_Discount__c;
//                        }
//
//                        if (newOpp.License_Term__c != null) {
//                            oli.Selected_Sales_Price__c = oli.UnitPrice * (100 - oli.Discount) / (newOpp.License_Term__c * 100);
//                        } else {
//                            oli.Selected_Sales_Price__c = oli.UnitPrice * (100 - oli.Discount) / (36 * 100);
//                        }
//                    }
//                    uow.registerDirty(oli);
//                }
//            }
//        }
//    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-02-03
    *
    * @description
    * https://samsarasalessystems.atlassian.net/browse/SS-297
    */
    public static void updateDiscountOnOpptyTypeChange(
            OpportunityStateManager store,
            UnitOfWork uow,
            Map<Id, Opportunity> oldOppMap,
            Map<Id, Opportunity> newOppMap) {
        List<Opportunity> opptyToUpdateToTrial = new List<Opportunity>();
        List<OpportunityLineItem> lineItemsToUpdateToTrial = new List<OpportunityLineItem>();
//
        List<Opportunity> opptyToUpdateFromTrial = new List<Opportunity>();
        List<OpportunityLineItem> lineItemsToUpdateFromTrial = new List<OpportunityLineItem>();

        // Get Oppty IDs that meet criteria & have to be updated - also track if they are updated to or from a trial
        for (Opportunity newOpp : newOppMap.values()) {
            final Opportunity OLD_OPP = oldOppMap.get(newOpp.Id);
            if (newOpp.Type != OLD_OPP.Type
                    && (AVAILABLE_TRIAL_OPP_TYPES.contains(newOpp.Type) ||
                    AVAILABLE_TRIAL_OPP_TYPES.contains(OLD_OPP.Type))
                    && newOpp.HasOpportunityLineItem) {
                // Trigger if Oppty type changes, and TO or FROM Free Trial Opportunity or Promo Opportunity
                if (AVAILABLE_TRIAL_OPP_TYPES.contains(newOpp.Type)) {
                    // Change TO Free Trial Opportunity or Promo Opportunity or Free Trial Return or Exchange
                    opptyToUpdateToTrial.add(newOpp);
                } else if (AVAILABLE_TRIAL_OPP_TYPES.contains(OLD_OPP.Type)) {
                    // Change FROM Free Trial Opportunity or Promo Opportunity or Free Trial Return or Exchange
                    opptyToUpdateFromTrial.add(newOpp);
                }
            }
        }
        Map<Id, Opportunity> extendedOpportunityMap;
        if (!opptyToUpdateToTrial.isEmpty() || !opptyToUpdateFromTrial.isEmpty()) {
            extendedOpportunityMap = store.selectExtendedOpportunityMap(newOppMap.keySet());
        }
        // If Oppty IDs are not empty, query for child Oppty Line Items
        if (opptyToUpdateToTrial.isEmpty() == false) {
            for (Opportunity toTrial : opptyToUpdateToTrial) {
                lineItemsToUpdateToTrial.addAll(extendedOpportunityMap.get(toTrial.Id).OpportunityLineItems);
            }
        }

        if (opptyToUpdateFromTrial.isEmpty() == false) {
            for (Opportunity fromTrial : opptyToUpdateFromTrial) {
                lineItemsToUpdateFromTrial.addAll(extendedOpportunityMap.get(fromTrial.Id).OpportunityLineItems);
            }
        }

        // Set Discounts based on to/from trial change
        for (OpportunityLineItem li : lineItemsToUpdateToTrial) {
            System.debug(LoggingLevel.INFO, '##### DiscountService -> updateDiscountOnOpptyTypeChange -> Updating ' + li.Id + ' to 100%');
            li.Discount = 100;
        }

        for (OpportunityLineItem li : lineItemsToUpdateFromTrial) {
            System.debug(LoggingLevel.INFO, '##### DiscountService -> updateDiscountOnOpptyTypeChange -> Updating ' + li.Id + ' to 0%');
            li.Discount = 0;
        }

        // Update Oppty Line Items in DB
        if (lineItemsToUpdateToTrial.isEmpty() == false) {
            uow.registerDirty(lineItemsToUpdateToTrial);
        }

        if (lineItemsToUpdateFromTrial.isEmpty() == false) {
            uow.registerDirty(lineItemsToUpdateFromTrial);
        }
    }
}