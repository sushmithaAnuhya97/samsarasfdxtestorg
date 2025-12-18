/**
 * WebstoreOrderPayload class holds the structure of the data payload for an order placed in the webstore.
 * It contains various nested classes that represent key information related to an order, account, opportunity, quote, shipping address, and related entities. This structure is used for processing 
 * and handling order-related data within the system.
 * 
 * The class includes:
 * - `Order`: Represents the order details such as transaction type, payment status, and associated account information.
 * - `Account`: Represents the account details associated with the order, including payment processing and renewal options.
 * - `Opportunity`: Represents the opportunity related to the order, including the stage, close date, and other opportunity-specific details.
 * - `Quote`: Represents the quote details, including selected payment type, discounts, shipping method, and other terms.
 * - `QuoteLine`: Represents individual quote lines, including product details, pricebook entries, and quantity.
 * - `ShippingAddress`: Represents the shipping address for the order, including contact information and address details.
 * 
 * This class is typically used to capture the complete information related to an order and its associated entities in the webstore.
 */
public class OrderPayload {

    public Order order;
    public Account account;
    public Opportunity opportunity;
    public Quote quote;
    public ShippingAddress shipping_address;
    
    public class Order {
        public String id;
        public Boolean is_enterprise;
        public String transaction_type;
        public String account_id;
        public String docusign_envelope_id;
        public String payment_status;
    }
    
    public class Account {
        public Boolean autoRenewalOptOut;
        public String billingCity;
        public String billingState;
        public String billingStreet;
        public String billingCountry;
        public String billingEmail;
        public String billingPhone;
        public String billingPostalCode;
        public String billingLastName;
        public String billingFirstName;
    }
    
    public class Opportunity {
        public String id;
        public String stageName;
        public String name;
        public Date closeDate;
        public Boolean smallFleetOpportunity;
        public String pricebook2Id;
        public Double licenseTerm;
        public String currencyIsoCode;
        public Boolean canCreate;
        public Boolean excludeFromXactly;
        public Boolean isWebstoreUpsellOpportunity;
        public String initialPaymentTerms;
        public String paymentTerms;
        public String configurationSegment;
        public String notes;
        public String purchaseType;
        public String expressAgreementAcceptedDate;
        public Decimal amountReceived;
        public String paymentToken;
        public String paymentMethod;
        public String stripeChargeId;
        public String stripeIntentId;
        public String vatNumber;  
        public String vatValidationStatus;  
        public Decimal shippingAndHandlingManual;
        // Free Trial specific fields
        public Integer trialPeriod;
        public String trialGoal1;
        public String trialGoal2;
        public String trialGoal3;
        public Date trialAgreementAcceptanceDate;
        public Boolean trialAgreementAccepted;
        public String trialResolutionOppty;
    }
    
    public class Quote {
        public String id;
        public String name;
        public String selectedPaymentType;
        public Decimal checkoutDiscount;
        public String shippingMethod;
        public String paymentTerms;
        public String poNumber;
        public Boolean primary;
        public String status;
        public Date expressAgreementAcceptedDate;
        public Decimal amountReceived;
        public String paymentToken;
        public String paymentMethod;
        public String stripeChargeId;
        public String stripeIntentId;
        public Decimal shippingAndHandlingManual;
        public String configurationSegment;
        public String account;
        public String opportunity;
        public String pricebook2Id;
        public String currencyIsoCode;
        public String vatId;
        public Decimal expressSelectedDiscount;
        public String billingEmails;
        public Decimal proratedAmount; 
        public List<QuoteLine> quoteLines;
    }
    
    public class QuoteLine {
        //public String id;
        public String product;
        public String pricebookEntryId;
        public String currencyIsoCode;
        public Decimal listPrice;
        public Decimal discount;
        public Decimal quantity;
    }
    
    public class ShippingAddress {
        public String shippingCity;
        public String shippingEmail;
        public String shippingPhone;
        public String shippingState;
        public String shippingCountry;
        public String shippingContact;
        public String shippingLastName;
        public String shippingZipCode;
        public String shippingFirstName;
        public String shippingAddressLine1;
        public String shippingAddressLine2;
        public String account;
    }
}