public class JsonToSFDCMapper {
    
    // ---- NULL-SAFE UTILITIES ----
    private static Boolean isNull(Object obj) {      
        return obj == null;
    }
    
    private static Boolean isEmpty(List<Object> payloadList) {
        return payloadList == null || payloadList.isEmpty();
    }
    
    @TestVisible
    private static Boolean isNullOrEmpty(Object obj) {
        if (obj == null) return true;
        
        if (obj instanceof OrderPayload.ShippingAddress) {
            OrderPayload.ShippingAddress shippingAddr = (OrderPayload.ShippingAddress) obj;
            return String.isBlank(shippingAddr?.shippingCountry);
        }
        
        return false;
    }
    
    // ---- ACCOUNT MAPPING ----
    public static Account mapAccountData(OrderPayload payload) {
        if (isNull(payload) || isNull(payload.account)) return null;
        
        Account acc = new Account();
        acc.Id = (payload.order != null) ? payload.order.account_id : null;
        
        return acc;
    }
    
    private static void populateBillingFields(Account acc, OrderPayload.Account accountData) {
        if (acc == null || accountData == null) return;
        
        if(String.isNotBlank(accountData.billingCity)) { acc.BillingCity = accountData.billingCity; }
        if(String.isNotBlank(accountData.billingState)) { acc.BillingState = accountData.billingState; }
        if(String.isNotBlank(accountData.billingStreet)) { acc.BillingStreet = accountData.billingStreet; }
        if(String.isNotBlank(accountData.billingCountry)) { acc.BillingCountry = accountData.billingCountry; }
        if(String.isNotBlank(accountData.billingEmail)) { acc.Billing_Email__c = accountData.billingEmail; }
        if(String.isNotBlank(accountData.billingPhone)) { acc.Billing_Phone__c = accountData.billingPhone; }
        if(String.isNotBlank(accountData.billingPostalCode)) { acc.BillingPostalCode = accountData.billingPostalCode; }
        if(String.isNotBlank(accountData.billingLastName)) { acc.Billing_Last_Name__c = accountData.billingLastName; }
        if(String.isNotBlank(accountData.billingFirstName)) { acc.Billing_First_Name__c = accountData.billingFirstName; }
    }
    
    public static Account mapFirstTimePurchaseAccountData(OrderPayload payload) {
        Account acc = mapAccountData(payload);
        if (acc == null) return null;
        
        populateBillingFields(acc, payload.account);
        return acc;
    }
    
    public static Account mapDigitalRenewalAccountData(OrderPayload payload) {
        Account acc = mapAccountData(payload);
        if (acc == null) return null;
        acc.Auto_Renewal_Opt_Out__c = payload.account.autoRenewalOptOut;
        populateBillingFields(acc, payload.account);
        return acc;
    }
    
     public static Account mapCommercialCheckoutAccountData(OrderPayload payload) {
        Account acc = mapAccountData(payload);
        if (acc == null) return null;
        
        populateBillingFields(acc, payload.account);
        return acc;
    }
    
    // ---- OPPORTUNITY MAPPING ----
    public static Opportunity mapOpportunityData(OrderPayload payload) {
        if (isNull(payload) || isNull(payload.opportunity)) return null;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = payload.order != null ? payload.order.account_id : null;
        opp.StageName = payload.opportunity.stageName;
        opp.Name = payload.opportunity.name;
        opp.CloseDate = payload.opportunity.closeDate;
        opp.Small_Fleet_Opportunity__c = payload.opportunity.smallFleetOpportunity;
        opp.Pricebook2Id = payload.opportunity.pricebook2Id;
        opp.License_Term__c = payload.opportunity.licenseTerm;
        opp.CurrencyIsoCode = payload.opportunity.currencyIsoCode;
        opp.Can_Create__c = payload.opportunity.canCreate;
        opp.Exclude_from_Xactly__c = payload.opportunity.excludeFromXactly;
        opp.Is_Webstore_Upsell_Opportunity__c = payload.opportunity.isWebstoreUpsellOpportunity;
        opp.Initial_Payment_Terms__c = payload.opportunity.initialPaymentTerms;
        opp.Payment_Terms__c = payload.opportunity.paymentTerms;
        opp.Configuration_Segment__c = payload.opportunity.configurationSegment;
        opp.Webstore_Metadata__c = payload.opportunity.notes;
        return opp;
    }
    
    public static Opportunity mapMidMarketPlusCheckoutOpportunityData(OrderPayload payload) {
        if (isNull(payload) || isNull(payload.opportunity)) return null;
        
        Opportunity opp = new Opportunity();
        opp.Id = payload.opportunity.id;
        opp.Amount_Received__c = payload.opportunity.amountReceived;
        opp.Payment_Token__c = payload.opportunity.paymentToken;
        opp.Payment_Method__c = payload.opportunity.paymentMethod;
        opp.Stripe_Charge_Id__c = payload.opportunity.stripeChargeId;
        opp.Stripe_Intent_Id__c = payload.opportunity.stripeIntentId;
        opp.VAT_Number__c = payload.opportunity.vatNumber;
        opp.VAT_Validation_Status__c = payload.opportunity.vatValidationStatus;
        opp.Webstore_Metadata__c = payload.opportunity.notes;
        opp.Shipping_and_Handling_Manual__c = payload.opportunity.shippingAndHandlingManual;
        opp.Express_Agreement_Accepted_Date__c = payload.opportunity.expressAgreementAcceptedDate != null? Date.valueOf(payload.opportunity.expressAgreementAcceptedDate) : null;
        mapCloseDateForDigitalRenewals(opp, payload.opportunity, payload.shipping_address);
        return opp;
    }
    
    public static Opportunity mapCommercialCheckoutOpportunityData(OrderPayload payload) {
        if (isNull(payload) || isNull(payload.opportunity)) return null;
        
        Opportunity opp = new Opportunity();
        opp.Id = payload.opportunity.id;
        opp.Webstore_Metadata__c = payload.opportunity.notes;
        mapCloseDateForDigitalRenewals(opp, payload.opportunity, payload.shipping_address);
        return opp;
    }
    
    public static Opportunity mapDigitalRenewalOpportunityData(OrderPayload payload) {
        if (isNull(payload) || isNull(payload.opportunity)) return null;
        
        Opportunity opp = new Opportunity();
        opp.Id = payload.opportunity.id;
        opp.Webstore_Metadata__c = payload.opportunity.notes;
        opp.Express_Agreement_Accepted_Date__c = payload.opportunity.expressAgreementAcceptedDate != null? Date.valueOf(payload.opportunity.expressAgreementAcceptedDate) : null;
        return opp;
    }
  
    public static void mapCloseDateForDigitalRenewals(Opportunity opp, OrderPayload.Opportunity oppty, OrderPayload.ShippingAddress shippingAddress) {
        if(isNull(oppty)) return;
    
        String notesSF = oppty.notes;
        Date eAAD = null;
        if (String.isNotBlank(oppty.expressAgreementAcceptedDate)) {
            eAAD = Date.valueOf(oppty.expressAgreementAcceptedDate);
        }
        
        Order_Processing_Settings__mdt orderProcessingSettings = OrderUtil.getOrderProcessingSettings();
     
        if (orderProcessingSettings == null) {
            return;
        }

        Boolean isShippingAddressNullOrEmpty = isNullOrEmpty(shippingAddress);
        String selfServe = orderProcessingSettings.isSelfServe__c;
        String autoRenewal = orderProcessingSettings.isAutoRenewal__c;
        Boolean hasValidNotes = String.isNotBlank(notesSF);
        Boolean hasValidSelfServe = String.isNotBlank(selfServe);
        Boolean hasValidAutoRenewal = String.isNotBlank(autoRenewal);
        Boolean notesContainKey = hasValidNotes && (
        (hasValidSelfServe && notesSF.containsIgnoreCase(selfServe)) ||
        (hasValidAutoRenewal && notesSF.containsIgnoreCase(autoRenewal))
        );
        
        if(((eAAD!= null && notesContainKey) || isShippingAddressNullOrEmpty) ){
          Opportunity oppy = OrderProcessorSingleton.getInstance().queryOpportunity(oppty.id);
            if (oppy != null) {
                Boolean hasPrimaryQuoteContract = (oppy.SBQQ__PrimaryQuote__r != null
                                                && oppy.SBQQ__PrimaryQuote__r.Co_Term_Contract__c != null);
                Boolean noRenewedContractDate = (oppy.SBQQ__RenewedContract__r == null
                                                || oppy.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c == null);
        
            
                if(hasPrimaryQuoteContract && noRenewedContractDate && oppy?.closeDate<Date.today() 
                    && oppy?.Probability <= 95 && oppy?.stageName != 'Closed Lost'){
                    opp.CloseDate = Date.valueOf(eAAD);                    
                }

                opp.Shipping_Address_NEW__c = oppy.shipping_address_new__c;
                opp.Shipping_Country__c = oppy.Shipping_Country__c;
            } 
        }
        opp.Shipping_Country__c = String.isNotBlank(shippingAddress.shippingCountry) ? shippingAddress.shippingCountry?.trim() : opp.Shipping_Country__c;
    }
    
    public static Opportunity mapFreeTrialOpportunityData(OrderPayload payload) {
        if (isNull(payload) || isNull(payload.opportunity)) return null;
        
        Opportunity freeTrialOpportunity = new Opportunity();
        freeTrialOpportunity.AccountId = payload.order != null ? payload.order.account_id : null;
        freeTrialOpportunity.StageName = payload.opportunity.stageName;
        freeTrialOpportunity.Name = payload.opportunity.name;
        freeTrialOpportunity.CurrencyIsoCode = payload.opportunity.currencyIsoCode;
        freeTrialOpportunity.Trial_Goal_1__c = payload.opportunity.trialGoal1;
        freeTrialOpportunity.Trial_Goal_2__c = payload.opportunity.trialGoal2;
        freeTrialOpportunity.Trial_Goal_3__c = payload.opportunity.trialGoal3;
        freeTrialOpportunity.CloseDate = payload.opportunity.closeDate.addDays(3);
        freeTrialOpportunity.Pricebook2Id = payload.opportunity.pricebook2Id;
        // Free Trial specific fields
       
        freeTrialOpportunity.Trial_Period__c = payload.opportunity.trialPeriod != null ? payload.opportunity.trialPeriod : freeTrialOpportunity.Trial_Period__c;
        freeTrialOpportunity.Trial_Agreement_Acceptance_Date__c = payload.opportunity.trialAgreementAcceptanceDate;
        freeTrialOpportunity.Planned_Trial_Installation_Date__c = freeTrialOpportunity.Trial_Agreement_Acceptance_Date__c.addDays(3);
        freeTrialOpportunity.Trial_Agreement_Accepted__c = payload.opportunity.trialAgreementAccepted;
        freeTrialOpportunity.Webstore_Metadata__c = payload.opportunity.notes;
        freeTrialOpportunity.TrialResolutionOppty__c = payload.opportunity.trialResolutionOppty; // Link to revenue opportunity
        //freeTrialOpportunity.Trial_Status__c = 'Open';
        freeTrialOpportunity.Type = 'Free Trial Opportunity';
        freeTrialOpportunity.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId();

        /*
        freeTrialOpportunity.Small_Fleet_Opportunity__c = payload.opportunity.smallFleetOpportunity;
        freeTrialOpportunity.License_Term__c = payload.opportunity.licenseTerm;
        freeTrialOpportunity.Can_Create__c = payload.opportunity.canCreate;
        freeTrialOpportunity.Exclude_from_Xactly__c = payload.opportunity.excludeFromXactly;
        freeTrialOpportunity.Is_Webstore_Upsell_Opportunity__c = payload.opportunity.isWebstoreUpsellOpportunity;
        freeTrialOpportunity.Initial_Payment_Terms__c = payload.opportunity.initialPaymentTerms;
        freeTrialOpportunity.Payment_Terms__c = payload.opportunity.paymentTerms;
        freeTrialOpportunity.Configuration_Segment__c = payload.opportunity.configurationSegment;
        freeTrialOpportunity.Amount = opportunity.Amount;
        freeTrialOpportunity.CurrencyIsoCode = opportunity.CurrencyIsoCode;
        freeTrialOpportunity.LeadSource = opportunity.LeadSource;
        freeTrialOpportunity.CampaignId = opportunity.CampaignId;
        */
        
        return freeTrialOpportunity;
    }
    
    // ---- SHIPPING ADDRESS MAPPING ----
    public static Shipping_Address__c mapShippingAddress(OrderPayload payload) {
        if (isNull(payload) || isNull(payload.shipping_address)) return null;
        
        OrderPayload.ShippingAddress sa = payload.shipping_address;
        
        // Check if all relevant fields are blank
    	List<String> fieldsToCheck = new List<String>{
            sa.shippingAddressLine1,
            sa.shippingAddressLine2,
            sa.shippingCity,
            sa.shippingState,
            sa.shippingZipCode,
            sa.shippingCountry,
            sa.shippingEmail,
            sa.shippingPhone,
            sa.shippingLastName,
            sa.shippingFirstName
    	};
        if (isAllBlank(fieldsToCheck)) {
              return null;
        }
        
        // Map fields
        Shipping_Address__c result = new Shipping_Address__c();
        result.Shipping_Address_Line_1__c = sa.shippingAddressLine1;
        result.Shipping_Address_Line_2__c = sa.shippingAddressLine2;
        result.Shipping_City__c = sa.shippingCity;
        result.Shipping_State__c = sa.shippingState;
        result.Shipping_Zip_Code__c = sa.shippingZipCode;
        result.Shipping_Country__c = sa.shippingCountry;
        result.Shipping_Email__c = sa.shippingEmail;
        result.Shipping_Phone__c = sa.shippingPhone;
        result.Shipping_LastName__c = sa.shippingLastName;
        result.Shipping_FirstName__c = sa.shippingFirstName;
        result.Account__c = payload.order != null ? payload.order.account_id : null;
        
        return result;
    }
    
    private static Boolean isAllBlank(List<String> values) {
        for (String val : values) {
            if (!String.isBlank(val)) {
                return false;
            }
        }
        return true;
    } 
            
    // ---- QUOTE MAPPING ----
    private static void mapCommonQuoteFields(SBQQ__Quote__c quote, OrderPayload.Quote q) {
        if (isNull(q)) return;
        quote.VATId__c = q.vatId;
        quote.Amount_Received__c = q.amountReceived;
        quote.Payment_Token__c = q.paymentToken;
        quote.Payment_Method__c = q.paymentMethod;
        quote.Stripe_Charge_Id__c = q.stripeChargeId;
        quote.Stripe_Intent_Id__c = q.stripeIntentId;
        quote.Shipping_And_Handling_Manual__c = q.shippingAndHandlingManual;
        quote.Express_Agreement_Accepted_Date__c = q.expressAgreementAcceptedDate;
    }
    
    public static SBQQ__Quote__c mapQuoteData(OrderPayload payload) {
        if (isNull(payload) || isNull(payload.quote)) return null;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Selected_Payment_Type__c = payload.quote.selectedPaymentType;
        quote.Checkout_Discount__c = payload.quote.checkoutDiscount;
        quote.Shipping_Method__c = payload.quote.shippingMethod;
        quote.PO_Number__c = payload.quote.poNumber;
        quote.SBQQ__Status__c = payload.quote.status;
        quote.SBQQ__PaymentTerms__c = payload.quote.paymentTerms;
        quote.Express_Selected_Discount__c = payload.quote.expressSelectedDiscount;
        return quote;
    }
    
    public static SBQQ__Quote__c mapFreeTrialQuoteData(OrderPayload payload) {
        if (isNull(payload) || isNull(payload.quote)) return null;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        
        // Map basic quote fields
        quote.Shipping_Method__c = payload.quote.shippingMethod;
        //quote.SBQQ__Primary__c = payload.quote.primary;
        quote.SBQQ__Status__c = payload.quote.status;
        quote.CurrencyIsoCode = payload.quote.currencyIsoCode;
        quote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Free Trial').getRecordTypeId();
        return quote;
    }
    
    public static SBQQ__Quote__c mapAmendmenteQuoteData(OrderPayload payload) {
        SBQQ__Quote__c quote = mapQuoteData(payload);
        if (quote == null) return null;
        quote.Billing_Emails__c = payload.quote.billingEmails;
    
        if(payload.quote.proratedAmount!=null){
            quote.Prorated_Amount__c = payload.quote.proratedAmount;
        }
        
        mapCommonQuoteFields(quote, payload.quote);
        return quote;
    }
    
    public static SBQQ__Quote__c mapFirstTimePurchaseQuoteData(OrderPayload payload) {
        SBQQ__Quote__c quote = mapQuoteData(payload);
        if (quote == null) return null;
        mapCommonQuoteFields(quote, payload.quote);
        
        quote.Quote_Name__c = payload.quote.name;
        quote.Configuration_Segment__c = payload.quote.configurationSegment;
        quote.CurrencyIsoCode = payload.quote.currencyIsoCode;
        quote.SBQQ__PricebookId__c = payload.quote.pricebook2Id;
        
        return quote;
    }
    
    public static SBQQ__Quote__c mapDigitalRenewalQuoteData(OrderPayload payload) {
        if (isNull(payload) || isNull(payload.quote)) return null;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Status__c = payload.quote.status;
        quote.SBQQ__Primary__c = payload.quote.primary;
        quote.Selected_Payment_Type__c = payload.quote.selectedPaymentType;
        mapCommonQuoteFields(quote, payload.quote);
        return quote;
    }
    
    public static SBQQ__Quote__c mapCommercialCheckoutQuoteData(OrderPayload payload) {
        if (isNull(payload) || isNull(payload.quote)) return null;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Selected_Payment_Type__c = payload.quote.selectedPaymentType;
        quote.Checkout_Discount__c = payload.quote.checkoutDiscount;
        mapCommonQuoteFields(quote, payload.quote);
        return quote;
    }
    
    // ---- QUOTE LINE MAPPING ----
    public static List<SBQQ__QuoteLine__c> mapQuoteLines(OrderPayload payload) {
        List<OrderPayload.QuoteLine> quoteLines = (payload != null && payload.quote != null) ? payload.quote.quoteLines : null;
        if (isEmpty(quoteLines)) return null;
        
        List<SBQQ__QuoteLine__c> result = new List<SBQQ__QuoteLine__c>();
        for (OrderPayload.QuoteLine item : quoteLines) {
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Product__c = item.product;
            ql.SBQQ__PricebookEntryId__c = item.pricebookEntryId;
            ql.CurrencyIsoCode = item.CurrencyIsoCode;
            ql.SBQQ__ListPrice__c = item.listPrice;
            ql.SBQQ__Discount__c = item.discount;
            ql.SBQQ__Quantity__c = item.quantity;
            result.add(ql);
        }
        return result;
    }
    
    public static List<SBQQ__QuoteLine__c> mapFreeTrialQuoteLines(OrderPayload payload) {
        List<OrderPayload.QuoteLine> quoteLines = (payload != null && payload.quote != null) ? payload.quote.quoteLines : null;
        if (isEmpty(quoteLines)) return null;
        
        List<SBQQ__QuoteLine__c> result = new List<SBQQ__QuoteLine__c>();
        for (OrderPayload.QuoteLine item : quoteLines) {
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Product__c = item.product;
            ql.SBQQ__Quantity__c = item.quantity;
            ql.SBQQ__PricebookEntryId__c = item.pricebookEntryId;
            ql.CurrencyIsoCode = item.currencyIsoCode;
            ql.SBQQ__ListPrice__c = item.listPrice;
            ql.SBQQ__Quantity__c = item.quantity;
            result.add(ql);
        }
        return result;
    }
}