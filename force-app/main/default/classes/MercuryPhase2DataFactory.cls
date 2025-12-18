@isTest
public class MercuryPhase2DataFactory {
    
    /**
     * Creates a test account with basic information
     * @param name The name of the account
     * @param shouldInsert Whether to insert the record or not
     * @return Account The created test account
     */
    public static Account createAccount(String name, Boolean shouldInsert) {
        // Ensure name doesn't contain quotes as per validation rule
        String sanitizedName = name.replace('"', '');
        
        Account acc = new Account(
            Name = sanitizedName,
            BillingStreet = '1570 Dean Forrest Road',
            BillingCity = 'Garden City',
            BillingState = 'Georgia',
            BillingPostalCode = '31408',
            BillingCountry = 'United States',
            Organization_Size__c = '1 - 99',
            Type = 'End Customer',
            Bypass_Validation_Rules__c = false,
            Industry = 'Technology',  // Adding Industry as it's referenced in validation rules
            Territory__c = 'North America'  // Adding Territory as it's referenced in validation rules
        );
        if (shouldInsert) {
            insert acc;
        }
        return acc;
    }
    
    /**
     * Creates a test contact for an account
     * @param accountId The ID of the account to associate the contact with
     * @param shouldInsert Whether to insert the record or not
     * @return Contact The created test contact
     */
    public static Contact createContact(Id accountId, Boolean shouldInsert) {
        Contact con = new Contact(
            FirstName = 'Earl S.',
            LastName = 'Perry',
            Email = 'esp1361@gmail.com',  // More realistic email format
            AccountId = accountId,
            Phone = '9123089885',  // Adding phone number
            Title = 'Test Title',  // Adding title
            MailingStreet = '1570 Dean Forrest Road',
            MailingCity = 'Garden City',
            MailingState = 'Georgia',
            MailingPostalCode = '31408',
            MailingCountry = 'United States'
        );
        if (shouldInsert) {
            insert con;
        }
        return con;
    }
    
    /**
     * Creates a test shipping address
     * @param accountId The ID of the account to associate the shipping address with
     * @param contactId The ID of the contact to associate the shipping address with
     * @param shouldInsert Whether to insert the record or not
     * @return Shipping_Address__c The created test shipping address
     */
    public static Shipping_Address__c createShippingAddress(Id accountId, Id contactId, Boolean shouldInsert) {
        Shipping_Address__c shippingAddress = new Shipping_Address__c(
            Account__c = accountId,
            Shipping_Contact__c = contactId,
            Shipping_Address_Line_1__c = '1570 Dean Forrest Road',
            Shipping_City__c = 'Garden City',
            Shipping_State__c = 'Georgia',
            Shipping_Zip_Code__c = '31408',
            Shipping_Country__c = 'United States',
            Shipping_FirstName__c = 'Earl S.',
            Shipping_LastName__c = 'Perry',
            Shipping_Email__c = 'esp1361@gmail.com',
            Shipping_Phone__c = '9123089885',
            Type__c = 'HQ'  // Changed from 'Shipping' to 'HQ' to match valid picklist value
        );
        if (shouldInsert) {
            insert shippingAddress;
        }
        return shippingAddress;
    }
    
    /**
     * Creates a test contract
     * @param accountId The ID of the account to associate the contract with
     * @param shouldInsert Whether to insert the record or not
     * @return Contract The created test contract
     */
    public static Contract createContract(Id accountId, Boolean shouldInsert) {
        Contract con = new Contract(
            AccountId = accountId,
            Status = 'Draft',  // Changed from 'Activated' to 'Draft' as it's a valid initial status
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1),
            ContractTerm = 12  // Adding contract term in months
        );
        if (shouldInsert) {
            insert con;
        }
        return con;
    }
    
    /**
     * Creates a test subscription
     * @param accountId The ID of the account to associate the subscription with
     * @param contractId The ID of the contract to associate the subscription with
     * @param quoteLineId The ID of the quote line to associate the subscription with
     * @param shouldInsert Whether to insert the record or not
     * @return SBQQ__Subscription__c The created test subscription
     */
    public static SBQQ__Subscription__c createSubscription(Id accountId, Id contractId, Id quoteLineId, Boolean shouldInsert) {
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
            SBQQ__Account__c = accountId,
            SBQQ__Contract__c = contractId,
            SBQQ__Quantity__c = 1,
            SBQQ__Product__c = null,
            SBQQ__ListPrice__c = 100,
            SBQQ__NetPrice__c = 100,
            SBQQ__RegularPrice__c = 100,
            SBQQ__QuoteLine__c = quoteLineId
        );
        
        if (shouldInsert) {
            insert sub;
        }
        return sub;
    }

    public static Opportunity createOpportunity(string oppName, Id accId, string ownerId, string pTerms,string paymentType,Id sAddress, String currencyVal, boolean isCamera, boolean isInsert){
 		
        Opportunity opp = new Opportunity(
            Name = oppName, 
            StageName = 'Purchase',
            CloseDate = Date.today(),
            Custom_Schedule__c = false,
            Type = 'Revenue Opportunity',
            Is_Webstore_Upsell_Opportunity__c = false,
            SBQQ__Renewal__c = false,
            Selected_Payment_Type__c = paymentType,
            License_Term__c = 24,
            AccountId = accId,
            Payment_Terms__c = pTerms,
            Initial_Payment_Terms__c = pTerms,
            OwnerId = ownerId,
            Price_Book_Name__c = 'Standard',
            Shipping_and_Handling_Amount__c = 99999.99,
            Shipping_Address_NEW__c  = sAddress,
            Amount_Received__c = 150,
            Payment_Method__c = 'Credit Card/ACH Debit',
            Camera_Only_Deal__c = isCamera,
            Free_Trial_Purchase__c = 'Full Buy',
            CurrencyIsoCode = currencyVal
        ); 

        if(isInsert){
            insert opp;
        }
        return opp;
    }
    
    /**
     * Generates a mock Salesforce 18-digit record ID
     * @return String A mock 18-digit Salesforce record ID
     */
    public static String generateMockId() {
        String prefix = '00Q';  // Using 00Q as prefix for Order
        String timestamp = String.valueOf(Datetime.now().getTime()).right(12);
        return prefix + timestamp;
    }

    /**
     * Creates a test request tracker for first time purchase
     * @param accountId The ID of the account to associate the request tracker with
     * @param shouldInsert Whether to insert the record or not
     * @return Request_Tracker__c The created test request tracker
     */
    public static Request_Tracker__c createFirstTimePurchaseTracker(Id accountId, Boolean shouldInsert) {
        Request_Tracker__c tracker = new Request_Tracker__c(
            Transaction_Type__c = TransactionType.WEBSTORE_FIRST_PURCHASE.name(),
            Request__c = '{"order":{"transaction_type":"WEBSTORE_FIRST_PURCHASE","account_id":"' + accountId + '"}}',
            OrderId__c = generateMockId(),
            Requestor__c = UserInfo.getUserId(),
            Step_Status__c = 'Step1 Success',
            Status__c = 'Received'
        );
        if (shouldInsert) {
            insert tracker;
        }
        return tracker;
    }
    
    /**
     * Creates a test request tracker for amendment
     * @param accountId The ID of the account to associate the request tracker with
     * @param shouldInsert Whether to insert the record or not
     * @return Request_Tracker__c The created test request tracker
     */
    public static Request_Tracker__c createAmendmentTracker(String accountId, String shippingContactId, String pricebookId, String productId, Boolean shouldInsert) {
        OrderPayload fullRequest = createAmmendmentPayload(accountId, shippingContactId, productId, pricebookId);

        Request_Tracker__c tracker = new Request_Tracker__c(
            Account_Id__c = accountId,
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            OrderId__c = '79243',
            Request__c = JSON.serialize(fullRequest)
        );
        
        if (shouldInsert) {
            insert tracker;
        }
        return tracker;
    }

    public static OrderPayload createAmmendmentPayload(String accountId, String shippingContactId, String productId, String pricebookId) {
        OrderPayload payload = new OrderPayload();
        
        // Set Order details
        OrderPayload.Order orderDetails = new OrderPayload.Order();
        orderDetails.id = generateMockId();
        orderDetails.transaction_type = 'WEBSTORE_ADD_ON_PURCHASE';
        orderDetails.account_id = accountId;
        orderDetails.docusign_envelope_id = 'a8655d69-35f7-42c1-9316-ba103371dbc0';
        orderDetails.payment_status = null;
        orderDetails.is_enterprise = true;
        payload.order = orderDetails;
        
        // Set Account details
        OrderPayload.Account accountDetails = new OrderPayload.Account();
        accountDetails.autoRenewalOptOut = true;
        accountDetails.billingCity = 'Garden City';
        accountDetails.billingState = 'Georgia';
        accountDetails.billingStreet = '1570 Dean Forrest Road';
        accountDetails.billingCountry = 'United States';
        accountDetails.billingEmail = 'esp1361@gmail.com';
        accountDetails.billingPhone = '9123089885';
        accountDetails.billingPostalCode = '31408';
        accountDetails.billingLastName = 'Perry';
        accountDetails.billingFirstName = 'Earl S.';
        payload.account = accountDetails;
        
        // Set Opportunity details
        OrderPayload.Opportunity oppDetails = new OrderPayload.Opportunity();
        oppDetails.stageName = 'Qualified';
        oppDetails.name = 'Amendment - Test Account - 00232878';
        oppDetails.closeDate = Date.today();
        oppDetails.smallFleetOpportunity = false;
        oppDetails.pricebook2Id = pricebookId;
        oppDetails.licenseTerm = 3;
        oppDetails.currencyIsoCode = 'USD';
        oppDetails.canCreate = true;
        oppDetails.excludeFromXactly = false;
        oppDetails.isWebstoreUpsellOpportunity = true;
        oppDetails.initialPaymentTerms = 'Net 30';
        oppDetails.paymentTerms = 'Net 30';
        oppDetails.configurationSegment = 'Non Express';
        oppDetails.notes = '<p>Arcadian Checkout V2</p><p>Webstore redesign variant, variant VGCM cross-sell</p><p><br></p>Order placed by - <p>First name: Earl</p><p>Last name: Perry</p><p>Email address: safety@beelinec.com</p><p>Order ID: 79243</p>';
        payload.opportunity = oppDetails;
        
        // Set Quote details
        OrderPayload.Quote quoteDetails = new OrderPayload.Quote();
        quoteDetails.selectedPaymentType = 'Upfront Payments';
        quoteDetails.checkoutDiscount = 0;
        quoteDetails.shippingMethod = 'Ground';
        quoteDetails.paymentTerms = 'Net 30';
        quoteDetails.poNumber = null;
        quoteDetails.primary = true;
        quoteDetails.currencyIsoCode = 'USD';
        quoteDetails.status = 'Approved';
        quoteDetails.expressAgreementAcceptedDate = Date.today();
        quoteDetails.amountReceived = 0;
        quoteDetails.paymentToken = 'pm_1IEf3FIbzZlMbYFSvAbpRda3';
        quoteDetails.paymentMethod = '';
        quoteDetails.stripeChargeId = '';
        quoteDetails.stripeIntentId = 'seti_1QxBxbIbzZlMbYFSV9Xtbsnk';
        quoteDetails.shippingAndHandlingManual = 15;
        quoteDetails.configurationSegment = 'Non Express';
        quoteDetails.account = accountId;
        quoteDetails.pricebook2Id = pricebookId;
        quoteDetails.expressSelectedDiscount = 0;
        
        // Set Quote Lines
        List<OrderPayload.QuoteLine> quoteLines = new List<OrderPayload.QuoteLine>();
        OrderPayload.QuoteLine quoteLine = new OrderPayload.QuoteLine();
        quoteLine.product = productId;
        quoteLine.pricebookEntryId = pricebookId;
        quoteLine.currencyIsoCode = 'USD';
        quoteLine.listPrice = 55;
        quoteLine.discount = 0;
        quoteLine.quantity = 1;
        quoteLines.add(quoteLine);
        quoteDetails.quoteLines = quoteLines;
        payload.quote = quoteDetails;
        
        // Set Shipping Address details
        OrderPayload.ShippingAddress shippingDetails = new OrderPayload.ShippingAddress();
        shippingDetails.shippingCity = 'Garden City';
        shippingDetails.shippingEmail = 'esp1361@gmail.com';
        shippingDetails.shippingPhone = '9123089885';
        shippingDetails.shippingState = 'Georgia';
        shippingDetails.shippingCountry = 'United States';
        shippingDetails.shippingContact = shippingContactId;
        shippingDetails.shippingLastName = 'Perry';
        shippingDetails.shippingZipCode = '31408';
        shippingDetails.shippingFirstName = 'Earl S.';
        shippingDetails.shippingAddressLine1 = '1570 Dean Forrest Road';
        shippingDetails.shippingAddressLine2 = '';
        shippingDetails.account = accountId;
        payload.shipping_address = shippingDetails;
        
        return payload;
    }
    

    /**
     * Creates a test quote
     * @param accountId The ID of the account to associate the quote with
     * @param opportunityId The ID of the opportunity to associate the quote with
     * @param shouldInsert Whether to insert the record or not
     * @return SBQQ__Quote__c The created test quote
     */
    public static SBQQ__Quote__c createQuote(Id accountId, Id opportunityId, Boolean shouldInsert) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = accountId,
            SBQQ__Opportunity2__c = opportunityId,
            SBQQ__Primary__c = true,
            SBQQ__Status__c = 'Approved',
            Selected_Payment_Type__c = 'Direct Annual',
            SBQQ__Type__c = 'Amendment',
            Configuration_Segment__c  = 'Express',
            SBQQ__StartDate__c = Date.today(),
            Customer_Preferred_Payment_Method__c = 'Credit Card/ACH Debit',
            SBQQ__EndDate__c = Date.today().addYears(1)
        );
        
        if (shouldInsert) {
            insert quote;
        }
        return quote;
    }

    /**
     * Creates a test quote line
     * @param quoteId The ID of the quote to associate the quote line with
     * @param productId The ID of the product to associate with the quote line
     * @param shouldInsert Whether to insert the record or not
     * @return SBQQ__QuoteLine__c The created test quote line
     */
    public static SBQQ__QuoteLine__c createQuoteLine(Id quoteId, Id productId, Boolean shouldInsert) {
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId,
            SBQQ__Product__c = productId,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 100,
            SBQQ__NetPrice__c = 100,
            SBQQ__RegularPrice__c = 100,
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addYears(1)
        );
        
        if (shouldInsert) {
            insert quoteLine;
        }
        return quoteLine;
    }


    public static SBQQ__QuoteLine__c createQuoteLines(Id accountId, Id quoteId, String shippingAddressId, String productId, String pricebookEntryId, Decimal listPrice, Decimal quantity, boolean isInsert) {
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c  = quoteId;
        quoteLine.SBQQ__Product__c  = productId;
        quoteLine.Account__c = accountId; 
        quoteLine.Ship_To__c  = shippingAddressId;
        quoteLine.SBQQ__PricebookEntryId__c = pricebookEntryId;
        quoteLine.SBQQ__ListPrice__c = listPrice;
        quoteLine.SBQQ__Quantity__c  = quantity;
        if(isInsert){
            insert quoteLine;
        }
        return quoteLine;
    }

    /**
     * Creates a test product
     * @param shouldInsert Whether to insert the record or not
     * @return Product2 The created test product
     */
    public static Product2 createProduct(Boolean shouldInsert) {
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33-BUNDLE', Family = 'Test', Geo_Availablity__c='USA');
        if (shouldInsert) {
            insert vg33;
        }
        return vg33;
    }

    public static OrderPayload createDigitalRenewalPayload(String accountId, String opportunityId, String quoteId, String paymentToken, String stripeIntentId) {
        OrderPayload payload = new OrderPayload();
        
        // Set Order details
        OrderPayload.Order orderDetails = new OrderPayload.Order();
        orderDetails.id = '79059';
        orderDetails.transaction_type = 'WEBSTORE_DIGITAL_RENEWAL';
        orderDetails.account_id = accountId;
        orderDetails.docusign_envelope_id = '61745b7c-06a9-437f-a323-09eae0c57b6a';
        orderDetails.payment_status = null;
        payload.order = orderDetails;
        
        // Set Account details
        OrderPayload.Account accountDetails = new OrderPayload.Account();
        accountDetails.autoRenewalOptOut = false;
        accountDetails.billingCity = 'Garden City';
        accountDetails.billingState = 'Georgia';
        accountDetails.billingStreet = '1570 Dean Forrest Road';
        accountDetails.billingCountry = 'United States';
        accountDetails.billingEmail = 'esp1361@gmail.com';
        accountDetails.billingPhone = '9123089885';
        accountDetails.billingPostalCode = '31408';
        accountDetails.billingLastName = 'Perry';
        accountDetails.billingFirstName = 'Earl S.';
        payload.account = accountDetails;
        
        // Set Opportunity details
        OrderPayload.Opportunity oppDetails = new OrderPayload.Opportunity();
        oppDetails.stageName = 'Qualified';
        oppDetails.name = 'Digital Renewal';
        oppDetails.closeDate = Date.today();
        oppDetails.currencyIsoCode = 'USD';
        oppDetails.notes = '<p>Arcadian Checkout V2</p>';
        oppDetails.expressAgreementAcceptedDate = String.valueOf(Date.today());
        payload.opportunity = oppDetails;
        
        // Set Quote details
        OrderPayload.Quote quoteDetails = new OrderPayload.Quote();
        quoteDetails.id = quoteId;
        quoteDetails.selectedPaymentType = 'Direct Annual';
        quoteDetails.checkoutDiscount = 0;
        quoteDetails.shippingMethod = 'Ground';
        quoteDetails.paymentTerms = 'Net 30';
        quoteDetails.primary = true;
        quoteDetails.status = 'Approved';
        quoteDetails.currencyIsoCode = 'USD';
        quoteDetails.expressAgreementAcceptedDate = Date.today();
        quoteDetails.amountReceived = 0;
        quoteDetails.paymentToken = paymentToken;
        quoteDetails.paymentMethod = '';
        quoteDetails.stripeChargeId = '';
        quoteDetails.stripeIntentId = stripeIntentId;
        quoteDetails.shippingAndHandlingManual = 15;
        quoteDetails.configurationSegment = 'Non Express';
        quoteDetails.account = accountId;
        quoteDetails.pricebook2Id = Test.getStandardPricebookId();
        quoteDetails.expressSelectedDiscount = 0;
        payload.quote = quoteDetails;
        
        // Set Shipping Address details
        OrderPayload.ShippingAddress shippingDetails = new OrderPayload.ShippingAddress();
        shippingDetails.shippingCity = 'Garden City';
        shippingDetails.shippingEmail = 'esp1361@gmail.com';
        shippingDetails.shippingPhone = '9123089885';
        shippingDetails.shippingState = 'Georgia';
        shippingDetails.shippingCountry = 'United States';
        shippingDetails.shippingLastName = 'Perry';
        shippingDetails.shippingZipCode = '31408';
        shippingDetails.shippingFirstName = 'Earl S.';
        shippingDetails.shippingAddressLine1 = '1570 Dean Forrest Road';
        shippingDetails.shippingAddressLine2 = '';
        shippingDetails.account = accountId;
        payload.shipping_address = shippingDetails;
        
        return payload;
    }

    public static OrderPayload createMidMarketPlusPayload(Id accountId, Id opportunityId, String paymentToken, String stripeIntentId, String stripeChargeId) {
        OrderPayload payload = new OrderPayload();
        
        // Set Order details
        OrderPayload.Order orderDetails = new OrderPayload.Order();
        orderDetails.id = '1';
        orderDetails.transaction_type = 'WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK';
        orderDetails.is_enterprise = true;
        orderDetails.account_id = accountId;
        orderDetails.docusign_envelope_id = '051f6908-0b32-442b-80bd-dc8f06e61bce';
        orderDetails.payment_status = 'succeeded';
        payload.order = orderDetails;
        
        // Set Account details
        OrderPayload.Account accountDetails = new OrderPayload.Account();
        accountDetails.autoRenewalOptOut = true;
        accountDetails.billingCity = 'Garden City';
        accountDetails.billingState = 'Georgia';
        accountDetails.billingStreet = '1570 Dean Forrest Road';
        accountDetails.billingCountry = 'United States';
        accountDetails.billingEmail = 'esp1361@gmail.com';
        accountDetails.billingPhone = '9123089885';
        accountDetails.billingPostalCode = '31408';
        accountDetails.billingLastName = 'Perry';
        accountDetails.billingFirstName = 'Earl S.';
        payload.account = accountDetails;
        
        // Set Opportunity details
        OrderPayload.Opportunity oppDetails = new OrderPayload.Opportunity();
        oppDetails.stageName = 'Qualified';
        oppDetails.name = 'Mid Market Plus';
        oppDetails.closeDate = Date.today();
        oppDetails.currencyIsoCode = 'USD';
        oppDetails.amountReceived = 0;
        oppDetails.paymentToken = paymentToken;
        oppDetails.paymentMethod = 'card';
        oppDetails.stripeChargeId = stripeChargeId;
        oppDetails.stripeIntentId = stripeIntentId;
        oppDetails.Id = opportunityId;
        oppDetails.shippingAndHandlingManual = 362.6;
        oppDetails.expressAgreementAcceptedDate = String.valueOf(Date.today());
        payload.opportunity = oppDetails;
        
        // Set Quote details
        OrderPayload.Quote quoteDetails = new OrderPayload.Quote();
        quoteDetails.selectedPaymentType = 'Direct Annual';
        quoteDetails.checkoutDiscount = 0;
        quoteDetails.shippingMethod = 'Ground';
        quoteDetails.paymentTerms = 'Net 30';
        quoteDetails.primary = true;
        quoteDetails.status = 'Approved';
        quoteDetails.currencyIsoCode = 'USD';
        quoteDetails.expressAgreementAcceptedDate = Date.today();
        quoteDetails.amountReceived = 0;
        quoteDetails.paymentToken = paymentToken;
        quoteDetails.paymentMethod = 'card';
        quoteDetails.stripeChargeId = stripeChargeId;
        quoteDetails.stripeIntentId = stripeIntentId;
        quoteDetails.shippingAndHandlingManual = 362.6;
        quoteDetails.configurationSegment = 'Non Express';
        quoteDetails.account = accountId;
        quoteDetails.pricebook2Id = Test.getStandardPricebookId();
        quoteDetails.expressSelectedDiscount = 0;
        payload.quote = quoteDetails;
        
        // Set Shipping Address details
        OrderPayload.ShippingAddress shippingDetails = new OrderPayload.ShippingAddress();
        shippingDetails.shippingCity = 'Garden City';
        shippingDetails.shippingEmail = 'esp1361@gmail.com';
        shippingDetails.shippingPhone = '9123089885';
        shippingDetails.shippingState = 'Georgia';
        shippingDetails.shippingCountry = 'United States';
        shippingDetails.shippingLastName = 'Perry';
        shippingDetails.shippingZipCode = '31408';
        shippingDetails.shippingFirstName = 'Earl S.';
        shippingDetails.shippingAddressLine1 = '1570 Dean Forrest Road';
        shippingDetails.shippingAddressLine2 = '';
        shippingDetails.account = accountId;
        payload.shipping_address = shippingDetails;
        
        return payload;
    }

    public static OrderPayload createCommercialCheckoutPayload(Id accountId, Id opportunityId, String paymentToken, String stripeIntentId, String stripeChargeId, String shippingContactId) {
        OrderPayload payload = new OrderPayload();
        
        // Set Order details
        OrderPayload.Order orderDetails = new OrderPayload.Order();
        orderDetails.id = '79355';
        orderDetails.transaction_type = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK';
        orderDetails.account_id = accountId;
        orderDetails.docusign_envelope_id = 'fdbd01f2-2e1b-4f17-9fd3-3f41dc8432f7';
        orderDetails.payment_status = null;
        payload.order = orderDetails;
        
        // Set Account details
        OrderPayload.Account accountDetails = new OrderPayload.Account();
        accountDetails.autoRenewalOptOut = true;
        accountDetails.billingCity = 'Garden City';
        accountDetails.billingState = 'Georgia';
        accountDetails.billingStreet = '1570 Dean Forrest Road';
        accountDetails.billingCountry = 'United States';
        accountDetails.billingEmail = 'esp1361@gmail.com';
        accountDetails.billingPhone = '9123089885';
        accountDetails.billingPostalCode = '31408';
        accountDetails.billingLastName = 'Perry';
        accountDetails.billingFirstName = 'Earl S.';
        payload.account = accountDetails;
        
        // Set Opportunity details
        OrderPayload.Opportunity oppDetails = new OrderPayload.Opportunity();
        oppDetails.id = opportunityId;
        oppDetails.stageName = 'Qualified';
        oppDetails.name = 'Commercial Checkout';
        oppDetails.closeDate = Date.today();
        oppDetails.currencyIsoCode = 'USD';
        oppDetails.amountReceived = 0;
        oppDetails.paymentToken = paymentToken;
        oppDetails.paymentMethod = 'card';
        oppDetails.stripeChargeId = stripeChargeId;
        oppDetails.stripeIntentId = stripeIntentId;
        oppDetails.shippingAndHandlingManual = 15;
        oppDetails.expressAgreementAcceptedDate = String.valueOf(Date.today());
        payload.opportunity = oppDetails;
        
        // Set Quote details
        OrderPayload.Quote quoteDetails = new OrderPayload.Quote();
        quoteDetails.selectedPaymentType = 'Direct Annual';
        quoteDetails.checkoutDiscount = 0;
        quoteDetails.shippingMethod = 'Ground';
        quoteDetails.paymentTerms = 'Net 30';
        quoteDetails.primary = true;
        quoteDetails.status = 'Approved';
        quoteDetails.currencyIsoCode = 'USD';
        quoteDetails.expressAgreementAcceptedDate = Date.today();
        quoteDetails.amountReceived = 0;
        quoteDetails.paymentToken = paymentToken;
        quoteDetails.paymentMethod = 'card';
        quoteDetails.stripeChargeId = stripeChargeId;
        quoteDetails.stripeIntentId = stripeIntentId;
        quoteDetails.shippingAndHandlingManual = 15;
        quoteDetails.configurationSegment = 'Non Express';
        quoteDetails.account = accountId;
        quoteDetails.pricebook2Id = Test.getStandardPricebookId();
        quoteDetails.expressSelectedDiscount = 0;
        payload.quote = quoteDetails;
        
        // Set Shipping Address details
        OrderPayload.ShippingAddress shippingDetails = new OrderPayload.ShippingAddress();
        shippingDetails.shippingCity = 'Garden City';
        shippingDetails.shippingEmail = 'esp1361@gmail.com';
        shippingDetails.shippingPhone = '9123089885';
        shippingDetails.shippingState = 'Georgia';
        shippingDetails.shippingCountry = 'United States';
        shippingDetails.shippingContact = shippingContactId;
        shippingDetails.shippingLastName = 'Perry';
        shippingDetails.shippingZipCode = '31408';
        shippingDetails.shippingFirstName = 'Earl S.';
        shippingDetails.shippingAddressLine1 = '1570 Dean Forrest Road';
        shippingDetails.shippingAddressLine2 = '';
        shippingDetails.account = accountId;
        payload.shipping_address = shippingDetails;
        
        return payload;
    }
    
    public static OrderPayload createFreeTrialPayload(String accountId, String trialResolutionOpptyId, String productId, String pricebookId) {
        OrderPayload payload = new OrderPayload();
        
        // Set Order details
        OrderPayload.Order orderDetails = new OrderPayload.Order();
        orderDetails.id = generateMockId();
        orderDetails.transaction_type = 'WEBSTORE_FREE_TRIAL';
        orderDetails.account_id = accountId;
        orderDetails.docusign_envelope_id = null;
        orderDetails.payment_status = null;
        orderDetails.is_enterprise = false;
        payload.order = orderDetails;
        
        // Set Account details
        OrderPayload.Account accountDetails = new OrderPayload.Account();
        accountDetails.autoRenewalOptOut = false;
        accountDetails.billingCity = 'San Francisco';
        accountDetails.billingState = 'California';
        accountDetails.billingStreet = '123 Main St';
        accountDetails.billingCountry = 'United States';
        accountDetails.billingEmail = 'john.doe@example.com';
        accountDetails.billingPhone = '+1-555-123-4567';
        accountDetails.billingPostalCode = '94105';
        accountDetails.billingLastName = 'Doe';
        accountDetails.billingFirstName = 'John';
        payload.account = accountDetails;
        
        // Set Opportunity details
        OrderPayload.Opportunity oppDetails = new OrderPayload.Opportunity();
        oppDetails.stageName = 'Qualified';
        oppDetails.name = 'Webstore Opportunity - ' + Date.today().format() + ' - ' + trialResolutionOpptyId + ' - 12345';
        oppDetails.closeDate = Date.today();
        oppDetails.pricebook2Id = pricebookId;
        oppDetails.currencyIsoCode = 'USD';
        oppDetails.trialPeriod = 60;
        oppDetails.trialGoal1 = 'Evaluate product performance';
        oppDetails.trialGoal2 = 'Test integration capabilities';
        oppDetails.trialGoal3 = 'Assess user experience';
        oppDetails.trialAgreementAcceptanceDate = Date.today().addDays(30);
        oppDetails.trialAgreementAccepted = true;
        oppDetails.notes = 'Order placed via webstore - Free trial evaluation';
        oppDetails.trialResolutionOppty = trialResolutionOpptyId;
        payload.opportunity = oppDetails;
        
        // Set Quote details
        OrderPayload.Quote quoteDetails = new OrderPayload.Quote();
        quoteDetails.shippingMethod = 'Ground';
        quoteDetails.primary = true;
        quoteDetails.status = 'Approved';
        quoteDetails.selectedPaymentType = 'Free Trial';
        quoteDetails.checkoutDiscount = 0;
        quoteDetails.paymentTerms = 'Net 30';
        quoteDetails.poNumber = null;
        quoteDetails.currencyIsoCode = 'USD';
        quoteDetails.expressAgreementAcceptedDate = Date.today();
        quoteDetails.amountReceived = 0;
        quoteDetails.paymentToken = null;
        quoteDetails.paymentMethod = null;
        quoteDetails.stripeChargeId = null;
        quoteDetails.stripeIntentId = null;
        quoteDetails.shippingAndHandlingManual = 0;
        quoteDetails.configurationSegment = 'Free Trial';
        quoteDetails.account = accountId;
        quoteDetails.pricebook2Id = pricebookId;
        quoteDetails.expressSelectedDiscount = 0;
        
        // Set Quote Lines
        List<OrderPayload.QuoteLine> quoteLines = new List<OrderPayload.QuoteLine>();
        OrderPayload.QuoteLine quoteLine = new OrderPayload.QuoteLine();
        quoteLine.product = productId;
        quoteLine.pricebookEntryId = pricebookId;
        quoteLine.currencyIsoCode = 'USD';
        quoteLine.listPrice = 0; // Free trial - no charge
        quoteLine.discount = 0;
        quoteLine.quantity = 50;
        quoteLines.add(quoteLine);
        quoteDetails.quoteLines = quoteLines;
        payload.quote = quoteDetails;
        
        // Set Shipping Address details
        OrderPayload.ShippingAddress shippingDetails = new OrderPayload.ShippingAddress();
        shippingDetails.shippingEmail = 'john.doe@example.com';
        shippingDetails.shippingPhone = '+1-555-123-4567';
        shippingDetails.shippingFirstName = 'John';
        shippingDetails.shippingLastName = 'Doe';
        shippingDetails.shippingAddressLine1 = '123 Main St';
        shippingDetails.shippingAddressLine2 = 'Suite 100';
        shippingDetails.shippingCity = 'San Francisco';
        shippingDetails.shippingState = 'California';
        shippingDetails.shippingCountry = 'United States';
        shippingDetails.shippingZipCode = '94105';
        shippingDetails.shippingContact = null;
        shippingDetails.account = accountId;
        payload.shipping_address = shippingDetails;
        
        return payload;
    }
}