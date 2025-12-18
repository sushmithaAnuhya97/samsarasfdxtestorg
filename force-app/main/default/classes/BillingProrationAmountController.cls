public class BillingProrationAmountController {
    
    public Class InputQuoteIdsWrapper {
        @InvocableVariable 
        public string quoteId;
    }
    public Class OutputErroMessageWrapper {
        @InvocableVariable 
        public string errorMessage;
    }
    // Invoked from Quote For Approval Flow
    @InvocableMethod(label='Prorated Amount API Callout' description='Makes async callout to Billing Proration system')
    public static List<OutputErroMessageWrapper> makeCallout(List<InputQuoteIdsWrapper> quoteIds) {
        Map<String, OrderFinanceSetting__mdt> mapOrderFinanceSettings = OrderFinanceSetting__mdt.getAll();
        //OrderFinanceSetting__mdt billing360Enabled = OrderFinanceSetting__mdt.getInstance('B360_R1_Toggle');
        //OrderFinanceSetting__mdt billing360APIEnabled = OrderFinanceSetting__mdt.getInstance('BillingProrationAPIToggle');
        List<String> quoteSet = new List<String>();
        //List<SBQQ__Quote__c> updateQuoteList = new List<SBQQ__Quote__c>();
        List<OutputErroMessageWrapper> responseDataList = new List<OutputErroMessageWrapper>();
        OutputErroMessageWrapper responseData = new OutputErroMessageWrapper();
        Map<Id, SBQQ__Quote__c> sourceQuoteData = new Map<Id, SBQQ__Quote__c>();
        Set<Id> quoteIdSet = new Set<Id>();
        if (mapOrderFinanceSettings.get('B360_R1_Toggle').Value__c.equalsIgnoreCase('True') && mapOrderFinanceSettings.get('BillingProrationAPIToggle').Value__c.equalsIgnoreCase('True')) {
            for (InputQuoteIdsWrapper quote : quoteIds) {
                quoteIdSet.add((Id)quote.quoteId);
            }
            String validationError = '';
            sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesAndQuoteLinesById(quoteIdSet);
            
            for (Id quoteId : quoteIdSet) {
                SBQQ__Quote__c quote = sourceQuoteData.get(quoteId);
                if (quote.SBQQ__Opportunity2__r.Billing_360_Transaction__c && quote.Associated_Opportunity_Type__c == 'Revenue Opportunity' && quote.Next_Recurring_Bill_Date__c != null) {
                    //Check BAD validations
                    if (quote.Billing_Ann_Date__c != null) {
                        validationError = B360LogicHandler.returnValidationMessage(quote, sourceQuoteData.get(quoteId).SBQQ__Opportunity2__r, sourceQuoteData.get(quoteId).SBQQ__Account__r, mapOrderFinanceSettings);              
                        if (String.isNotBlank(validationError)) {
                            responseData.errorMessage = validationError;
                            responseDataList.add(responseData);
                            return responseDataList;
                        }
                    }          
                    //Check Next Recurring Bill Date Validation
                    if (quote.Next_Recurring_Bill_Date__c < Date.today() && !FeatureManagement.checkPermission('Bypass_B360_Validations')) {
                        //OrderFinanceSetting__mdt nextRecurringBillDateError = OrderFinanceSetting__mdt.getInstance('NextRecurringBillDateError');
                        responseData.errorMessage = mapOrderFinanceSettings.get('NextRecurringBillDateError').Value__c;
                        responseDataList.add(responseData);
                        return responseDataList;
                    }
                    //Check Proration API citeria
                    if (callBillingProration(quote, quote.SBQQ__LineItems__r)) {
                        quoteSet.add(quote.Id); 
                        continue;
                    }
                }
            }
            // Enqueue the callout
            if (!Test.isRunningTest() && !quoteSet.isEmpty()) {
                System.enqueueJob(new BillingProrationAmountQueueable(quoteSet));
            }
        }    
        responseData.errorMessage = '';
        responseDataList.add(responseData);
        return responseDataList;
    }
    
    // Called from GS_SBQQQuoteService When the Start Date/BAD/PrimaryQuote changed on Approved Quote
    public static void handleStartDateChange(Map<Id, SBQQ__Quote__c> quoteMap, set<Id> billingProrationQuoteIdSet) {
        Set<Id> B360SetId = new Set<Id>();
        Map<String, OrderFinanceSetting__mdt> mapOrderFinanceSettings = OrderFinanceSetting__mdt.getAll();
        List<String> quoteIds = new List<String>();
        String validationError = '';
        for (Id quoteId : billingProrationQuoteIdSet) {
            if (!quoteMap.containsKey(quoteId)) {
                continue;
            }
            SBQQ__Quote__c updatedQuote = quoteMap.get(quoteId);    
            if (updatedQuote.SBQQ__Opportunity2__r.Billing_360_Transaction__c && updatedQuote.Associated_Opportunity_Type__c == 'Revenue Opportunity' && updatedQuote.Next_Recurring_Bill_Date__c != null) {    
                //BAD validation
                if (updatedQuote.Billing_Ann_Date__c != null) {
                    validationError = B360LogicHandler.returnValidationMessage(updatedQuote, updatedQuote.SBQQ__Opportunity2__r, updatedQuote.SBQQ__Account__r, mapOrderFinanceSettings);        
                    if (String.isNotBlank(validationError)) {
                        //quote.addError(validationError);
                        //break;
                        LOGGER.atError().setCLassName('BillingProrationAmountController').setRecordId(updatedQuote.Id).setExceptionOrMessage('BAD Validation is failed on the Approved Quote: '+ validationError);
                        B360SetId.add(updatedQuote.Id);
                    }      
                }
                //Check Proration API citeria
                if (callBillingProration(updatedQuote, updatedQuote.SBQQ__LineItems__r)) {
                    quoteIds.add(updatedQuote.Id);
                }
            }
        }
        LOGGER.setRecordIds(B360SetId);
        Logger.setFunctionalityType('BillingProrationAmountController'); 
        Logger.insertMasterLogs();
        // call Queueable to make the callout
        if (!Test.isRunningTest() && !quoteIds.isEmpty()) {
            //Database.executeBatch(new BillingProrationAmountBatch(quoteSet));
            System.enqueueJob(new BillingProrationAmountQueueable(quoteIds, 'BillingProrationAmountQueueable Close Date Change'));
        }
    }
    
    //Method to check if criteria for calling Proration API matches
    public static Boolean callBillingProration(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> quoteLines) {
        //Get allowed Payment Types for Billing 360
        OrderFinanceSetting__mdt billingPaymentTypes = OrderFinanceSetting__mdt.getInstance('Billing360PaymentTypes');
        List<String> paymentTypes = billingPaymentTypes.Value__c.split(',');
        String selectedPaymentType = '';
        Decimal totalContractRate = 0;
        
        if (quote.SBQQ__MasterContract__r.SBQQ__Opportunity__r.Billing_360_Transaction__c) {
            selectedPaymentType = quote.SBQQ__MasterContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c;
        } else {
            selectedPaymentType = quote.Selected_Payment_Type__c;
        }
        
        if (String.isNotBlank(selectedPaymentType) && paymentTypes.contains(selectedPaymentType) && (quote.License_Term__c != null || quote.SBQQ__SubscriptionTerm__c != null)) {
            for(SBQQ__QuoteLine__c line : quoteLines) {
                if(line.SBQQ__EffectiveQuantity__c > 0 && line.SBQQ__Product__r.Sales_Charge_Type__c == 'Recurring' && line.Total_Annual_Price__c != null && line.Total_Annual_Price__c > 0) {
                    return true;                                      
                }
            }           
        }
        return false;       
    }
    
    @AuraEnabled
    public static Boolean eligibleForBillingProrationAPICallout(List<String> quoteIdList) {
        OrderFinanceSetting__mdt billing360Enabled = OrderFinanceSetting__mdt.getInstance('B360_R1_Toggle');
        OrderFinanceSetting__mdt billing360APIEnabled = OrderFinanceSetting__mdt.getInstance('BillingProrationAPIToggle');
        if (billing360Enabled.Value__c.equalsIgnoreCase('True') && billing360APIEnabled.Value__c.equalsIgnoreCase('True') && !FeatureManagement.checkPermission('Bypass_B360_Validations')) {
            Set<Id> quoteIdSet = new Set<Id>();
            Map<Id, SBQQ__Quote__c> sourceQuoteData = new Map<Id, SBQQ__Quote__c>();
            for (String quoteId : quoteIdList) {
                quoteIdSet.add(quoteId);
            }
            sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesAndQuoteLinesById(quoteIdSet);
            for (String quoteId : quoteIdList) {
                SBQQ__Quote__c quote = sourceQuoteData.get(quoteId);
                OrderFinanceSetting__mdt billingPaymentTypes = OrderFinanceSetting__mdt.getInstance('Billing360PaymentTypes');
        		List<String> paymentTypes = billingPaymentTypes.Value__c.split(',');
                if (quote.SBQQ__Opportunity2__r.Billing_360_Transaction__c && quote.Associated_Opportunity_Type__c == 'Revenue Opportunity' 
                    && quote.Next_Recurring_Bill_Date__c != null && paymentTypes.contains(quote.Selected_Payment_Type__c)) {       
                    //Check Proration API citeria
                    if (callBillingProration(quote, quote.SBQQ__LineItems__r)) {
                        if (quote.API_Status__c == null && quote.Prorated_Amount__c == null && !quote.SBQQ__Opportunity2__r.Is_Webstore_Upsell_Opportunity__c) {
                            return true;
                        } 
                    }
                }
            }
        }
        return false;       
    }
    
    @AuraEnabled
    public static void retryBillingProration(String quoteId) {
        // Call the same controller method that's called from Flow
        List<InputQuoteIdsWrapper> quoteIds = new List<InputQuoteIdsWrapper>();
        InputQuoteIdsWrapper wrapper = new InputQuoteIdsWrapper();
        wrapper.quoteId = quoteId;
        quoteIds.add(wrapper);        
        //List<String> quoteIds = new List<String>{quoteId};
        makeCallout(quoteIds);       
    }
    
    @AuraEnabled(cacheable=true)
    public static String getPrefixErrorMessage() {
        OrderFinanceSetting__mdt billingProrationAPIPrefix = OrderFinanceSetting__mdt.getInstance('BillingProration_API_Prefix_Error_Msg');
        return billingProrationAPIPrefix.Value__c;       
    }
    
    @AuraEnabled(cacheable=true)
    public static String getSuffixErrorMessage() {
        OrderFinanceSetting__mdt billingProrationAPISuffix = OrderFinanceSetting__mdt.getInstance('Billing_Proration_API_Suffix_Error_Msg');
        return billingProrationAPISuffix.Value__c;
    }
    @AuraEnabled(cacheable=true)
    public static String getPaymentTypeMismatchWarning() {
        OrderFinanceSetting__mdt msg = OrderFinanceSetting__mdt.getInstance('QuotePaymentTermsMismatchWarning');
        return msg != null ? String.valueOf(msg.Value__c) : '';
    }      
}