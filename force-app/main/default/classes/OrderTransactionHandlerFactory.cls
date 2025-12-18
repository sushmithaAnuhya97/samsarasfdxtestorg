public class OrderTransactionHandlerFactory {
    
   private static final Map<String, Type> HANDLERS_MAP = new Map<String, Type>{
        TransactionType.WEBSTORE_FIRST_PURCHASE.name() => FirstTimePurchaseHandler.class,
        TransactionType.WEBSTORE_ADD_ON_PURCHASE.name() => AmendmentHandler.class,
        TransactionType.WEBSTORE_DIGITAL_RENEWAL.name() => DigitalRenewalCheckoutHandler.class,
        TransactionType.WEBSTORE_COMMERCIAL_CHECKOUT_LINK.name() => CommercialCheckoutHandler.class,
        TransactionType.WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK.name() => MidMarketPlusCheckoutHandler.class,
        TransactionType.WEBSTORE_FREE_TRIAL.name() => FreeTrialHandler.class
    };

    public static OrderTransactionHandler getHandler(String transactionType) {
        try {
            if (String.isBlank(transactionType)) {
                System.debug(LoggingLevel.WARN, 'OrderTransactionHandlerFactory: Empty transaction type provided');
                return null;
            }
            
            Type handlerClass = HANDLERS_MAP.get(transactionType.toUpperCase());
            if (handlerClass == null) {
                System.debug(LoggingLevel.WARN, 'OrderTransactionHandlerFactory: No handler found for transaction type: ' + transactionType);
                return null;
            }
            
            return (OrderTransactionHandler) handlerClass.newInstance();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'OrderTransactionHandlerFactory: Error creating handler for type ' + transactionType + ': ' + e.getMessage());
            return null;
        }
    }
}