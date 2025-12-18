/**
 * Created by henryzhao on 2020-01-29.
 * 7/11/20 Harsha - (GTMS-1307) shouldSendExpressAgreement (Changes to Remove Avalara References)
 */

public class OpportunityQuoteService {
    public class OpportunityQuoteServiceException extends Exception {
    }

    private static Boolean shouldSendExpressAgreement(Opportunity opp) {
        Boolean priceBookNameExpress;
        if(opp.Price_Book_Name__c <> null){
            priceBookNameExpress = opp.Price_Book_Name__c.contains('Express')? true:false;
        }
        else{
            pricebookNameExpress = false;
        }

        return (priceBookNameExpress && opp.Express_Agreement_Accepted_Date__c <> null);
    }

    public static void expressCheckoutQuoteCreator(
            OpportunityStateManager store,
            UnitOfWork uow,
            Map<Id, Opportunity> oldOppMap,
            Map<Id, Opportunity> newOppMap) {
        //System.debug(LoggingLevel.INFO, '##### OpportunityQuoteService -> expressCheckoutQuoteCreator -> OpportunityStateManager.methodCanRun(\'expressCheckoutQuoteCreator\') -> ' + OpportunityStateManager.methodCanRun('expressCheckoutQuoteCreator'));

        if (!OpportunityStateManager.methodCanRun('expressCheckoutQuoteCreator')) {
            System.debug(LoggingLevel.INFO, '##### OpportunityQuoteService -> expressCheckoutQuoteCreator -> already ran, skipping');
            return;
        }

        List<Quote> quotesToInsert = new List<Quote>();
        List<ExpressCheckout.EmailParameters> emailsToSend = new List<ExpressCheckout.EmailParameters>();
        store.addToAccountMap(newOppMap.values());
        store.addToUserMap(newOppMap.values());


        for (Opportunity o : newOppMap.values()) {
            final Opportunity OLD_OPP = oldOppMap.get(o.Id);

            Boolean newOppShouldSend = shouldSendExpressAgreement(o);
            if (newOppShouldSend
                    && shouldSendExpressAgreement(OLD_OPP) != newOppShouldSend
                    && o.IsClosed == FALSE
                    && o.HasOpportunityLineItem) {
                Account a = store.accountInformationMap.get(o.AccountId);
                if (a == null) {
                    throw new OpportunityQuoteServiceException('There is no associated account to this Opportunity: ' + o.Id);
                }
                if (String.isBlank(store.userInformationMap.get(o.OwnerId).Email)) {
                    throw new OpportunityQuoteServiceException('The Owner\'s email is blank! User: ' + o.OwnerId);
                }
                Quote q = new Quote();
                q.Name = 'Quote-' + o.Name;
                q.OpportunityId = o.Id;
                q.Pricebook2Id = o.Pricebook2Id;
                q.ContactId = o.Shipping_Contact__c;
                q.Email = a.Billing_Email__c;

                quotesToInsert.add(q);
            }
        }

        Map<Id, Opportunity> extendedOpportunityMap;
        if (!quotesToInsert.isEmpty()) {
            /** We must do a raw DML insert because we have a future method
             * that is depending on these IDs being populated.**/
            insert quotesToInsert;
            extendedOpportunityMap = store.selectExtendedOpportunityMap(newOppMap.keySet());
            System.debug(LoggingLevel.INFO, '##### OpportunityQuoteService -> expressCheckoutQuoteCreator -> registering run');
            OpportunityStateManager.methodRan('expressCheckoutQuoteCreator');
        } else {
//            we found nothing to take action on
            return;
        }

        for (Quote q : quotesToInsert) {
            final Opportunity o = newOppMap.get(q.OpportunityId);
            final Account a = store.accountInformationMap.get(o.AccountId);


            // Update our opp line items
            for (OpportunityLineItem oli : extendedOpportunityMap.get(q.OpportunityId).OpportunityLineItems) {
                QuoteLineItem qLine = new QuoteLineItem();
                qLine.QuoteId = q.Id;
                qLine.Quantity = oli.Quantity;
                qLine.UnitPrice = oli.UnitPrice;
                qLine.Discount = oli.Discount;
                qLine.PricebookEntryId = oli.PricebookEntryId;

                uow.registerNew(qLine, QuoteLineItem.QuoteId, q);
            }

            // Info to send email
            String contactId;
            if (o.Shipping_Contact__c != null) {
                contactId = o.Shipping_Contact__c;
            } else {
                // TODO: hzhz - remove hard coded value
                contactId = '0031a00000MWtFD';
            }

            emailsToSend.add(new ExpressCheckout.EmailParameters(q.Id,
                    contactId,
                    store.userInformationMap.get(o.OwnerId).Email,
                    o.Selected_Payment_Type__c,
                    o.Express_1_Year__c,
                    o.Camera_Only_Deal__c,
                    a.BillingCountry,
                    q.Email, a.Which_written_language__c));
        }

        /** Future method to send bulk email, because we can't invoke VF Page to create
         * attachments in a Trigger
         *
         * Must serialize it because future methods doesn't accept wrapper class**/
        if (!emailsToSend.isEmpty()) {
            if (System.isFuture()) {
                ExpressCheckout.sendBulkEmail(JSON.serialize(emailsToSend));
            } else {
                ExpressCheckout.sendBulkEmailFuture(JSON.serialize(emailsToSend));
            }
        }
    }
}