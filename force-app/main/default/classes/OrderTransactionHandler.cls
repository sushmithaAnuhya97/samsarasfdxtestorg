/**
 * Abstract class that defines the template for handling order transactions.
 * 
 * This class implements the **Template Method Design Pattern**, which defines the skeleton of an order processing algorithm while allowing subclasses to implement 
 * specific steps of the algorithm (order validation and transaction processing).
 * 
 * The main process for handling an order is as follows:
 * 1. **Order Validation**: The `processOrder` method checks if the order is valid by calling  the `isOrderValid` method (which must be implemented by the subclasses).
 * 2. **Transaction Processing**: If the order is valid, the `processTransaction` method is called to process the order transaction (this method must also be implemented by subclasses).
 * 
 * Subclasses should implement:
 * 1. `isOrderValid(Request_Tracker__c tracker)`: To define the specific business logic for validating an order.
 * 2. `processTransaction(Request_Tracker__c tracker)`: To define the specific logic for processing the transaction (e.g., updating order status, charging customer, etc.).
 *
 */
public abstract class OrderTransactionHandler {
    
    /**
     * Template method that processes the order.
     * 
     * This method defines the overall flow of order processing. It first validates the order and, if valid, proceeds to process the transaction. 
     * 
     * Subclasses will not override this method, as the order processing flow is fixed. 
     * However, they must implement the `isOrderValid` and `processTransaction` methods to customize validation and transaction logic.
     * 
     * @param tracker The order tracking record containing order details
     */
    public void processOrder(Request_Tracker__c tracker) {  
        
        // Validate the order payload-business validations
        Boolean isValidOrder = isOrderValid(tracker);
        
        // Process the transaction if validation is successful
        if (isValidOrder) {
            processTransaction(tracker);
        }
    }
    
    /**
     * Abstract method to validate the order payload.
     * 
     * Subclasses must implement this method to define the business logic for validating
     * the order based on specific conditions or criteria.
     * 
     * @param tracker The order tracking record containing order details
     * @return Boolean indicating whether the order is valid or not
     */
    @TestVisible
    protected abstract Boolean isOrderValid(Request_Tracker__c tracker);
    
    /**
     * Abstract method to process the transaction.
     * 
     * Subclasses must implement this method to define the specific logic for processing 
     * the transaction once the order is validated (e.g., charging the customer, updating 
     * order status, etc.).
     * 
     * @param tracker The order tracking record containing order details
     */
    protected abstract void processTransaction(Request_Tracker__c tracker);
    
}