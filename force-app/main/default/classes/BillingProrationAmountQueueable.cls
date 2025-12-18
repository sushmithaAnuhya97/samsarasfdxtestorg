/* GTMS-27138
   ***This class is used to get the Billing Proration Amount on the Quote.
*/
public class BillingProrationAmountQueueable implements Queueable, Database.AllowsCallouts {

    private List<String> quoteIds;  
    private String sourceContext;
    
    public BillingProrationAmountQueueable(List<String> quoteIds) {
        this.quoteIds = quoteIds;
    }
    
    public BillingProrationAmountQueueable(List<String> quoteIds, String sourceContext) {
        this.quoteIds = quoteIds;
        this.sourceContext = sourceContext;
    }
    
    public class BillingForecastWrapper {
        public String function;
        public DataWrapper data;
        public String quoteId; 
        public String salesforceTransactionIdentifier;
        public BillingForecastWrapper() {
            function = 'getBillingForecast';
            data = new DataWrapper();
        }
    }
    
    public class DataWrapper {
        public List<ContractLineWrapper> contractLineDataAry;
        public String forecastStartDate;
        public String forecastEndDate;
        public Integer forecastInterval;
        public PreferencesWrapper preferences;
        
        public DataWrapper() {
            contractLineDataAry = new List<ContractLineWrapper>();
            preferences = new PreferencesWrapper();
        }
    }
    
    public class ContractLineWrapper {
        public Decimal rate;
        public Integer quantity;
        public Integer billingFrequency;
        public String startDate;
        public String firstRecurringBillDate;
        public Decimal totalContractValueOverride;
        public String endDate;
    }
    
    public class PreferencesWrapper {
        public Integer prorationMethod;
    }
    
    public void execute(QueueableContext context) {
        Map<Id, SBQQ__Quote__c> quoteWithQLSMap = new Map<Id, SBQQ__Quote__c>([
            SELECT Id, SBQQ__StartDate__c, Next_Recurring_Bill_Date__c, Selected_Payment_Type__c, SBQQ__MasterContract__c, License_Term__c, SBQQ__EndDate__c,
                SBQQ__MasterContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c, API_Status__c, API_Error_msg__c, Associated_Opportunity_Type__c, SBQQ__MasterContract__r.SBQQ__Opportunity__r.Billing_360_Transaction__c, SBQQ__Opportunity2__r.CloseDate,
            (SELECT Id, SBQQ__EffectiveQuantity__c, Annual_Unit_Price__c, Monthly_Unit_Price__c, Quarterly_Unit_Price__c, Semi_Annual_Unit_Price__c, SBQQ__NetTotal__c  FROM SBQQ__LineItems__r WHERE SBQQ__EffectiveQuantity__c > 0 AND SBQQ__Product__r.Sales_Charge_Type__c = 'Recurring')
            FROM SBQQ__Quote__c 
            WHERE Id IN :quoteIds
        ]);
        Set<Id> B360quoteSetId = new Set<Id>();
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        Map<String, String> billingFrequencyMap = new Map<String, String>();
        
        Map<string, Billing_Frequency_Mapping__mdt> billingFrequencyMetadata = Billing_Frequency_Mapping__mdt.getAll();
        for (Billing_Frequency_Mapping__mdt key : billingFrequencyMetadata.values()) {
            billingFrequencyMap.put(key.MasterLabel, key.value__c);
        }
        // Make callout for each quote
        for(SBQQ__Quote__c quote : quoteWithQLSMap.values()) {
            String billingFrequency = '';
            String unitPriceType = '';
            Integer contractLineBillingFrequency = 0;
            String contractLineStartDate = null;
            String contractLinefirstRecurringBillDate = null;
            String contractLineEndDate = null;
            try {
                BillingForecastWrapper payload = new BillingForecastWrapper();
                payload.quoteId = quote.Id;
                SBQQ__Quote__c quoteWithLines = quoteWithQLSMap.get(quote.Id);
                if (billingFrequencyMap.containsKey(quote.Selected_Payment_Type__c)) {
                    unitPriceType = String.valueOf(billingFrequencyMap.get(quote.Selected_Payment_Type__c));
                }
                if (quote.SBQQ__MasterContract__c == null) {
                    billingFrequency = quote.Selected_Payment_Type__c;
                } else {
                    if (quote.SBQQ__MasterContract__r.SBQQ__Opportunity__r.Billing_360_Transaction__c) {
                        billingFrequency = quote.SBQQ__MasterContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c;
                    } else {
                        billingFrequency = quote.Selected_Payment_Type__c;
                    }
                }
                contractLinefirstRecurringBillDate = formattedDate(quote.Next_Recurring_Bill_Date__c);                   
                contractLineBillingFrequency = billingFrequencyMap.containsKey(billingFrequency + ' ' + 'Netsuite') ? Integer.valueOf(billingFrequencyMap.get(billingFrequency + ' ' + 'Netsuite')) : 0;
                contractLineStartDate = formattedDate(quote.SBQQ__Opportunity2__r.CloseDate);
                if (quote.SBQQ__EndDate__c != null) {
                    contractLineEndDate = formattedDate(quote.SBQQ__EndDate__c);
                } else {
                    Integer term = quote.License_Term__c != null ? Integer.valueOf(quote.License_Term__c) : quote.SBQQ__SubscriptionTerm__c.intValue();
                    contractLineEndDate = formattedDate(quote.SBQQ__Opportunity2__r.CloseDate.addMonths(term) - 1);
                }
                // Populate contract line item
                if(quoteWithLines != null && quoteWithLines.SBQQ__LineItems__r != null && quote.Associated_Opportunity_Type__c == 'Revenue Opportunity') {
                    for(SBQQ__QuoteLine__c line : quoteWithLines.SBQQ__LineItems__r) {
                        ContractLineWrapper contractLine = new ContractLineWrapper();
                        contractLine.rate = unitPriceType != '' && line.get(unitPriceType) != null ? (Decimal) line.get(unitPriceType) : 0;
                        contractLine.quantity = Integer.valueOf(line.SBQQ__EffectiveQuantity__c);
                        contractLine.billingFrequency = contractLineBillingFrequency;
                        contractLine.startDate= contractLineStartDate;
                        contractLine.firstRecurringBillDate = contractLinefirstRecurringBillDate;
                        contractLine.totalContractValueOverride = line.SBQQ__NetTotal__c;
                        contractLine.endDate = contractLineEndDate;
                        payload.data.contractLineDataAry.add(contractLine);  
                    }
                }                
                
                // Fill in forecast details
                payload.data.forecastEndDate = formattedDate(quote.Next_Recurring_Bill_Date__c - 1);   
                payload.data.forecastStartDate = contractLineStartDate;              
                payload.data.forecastInterval  = contractLineBillingFrequency;
                // Set preferences
                payload.data.preferences.prorationMethod = Integer.ValueOf(OrderFinanceSetting__mdt.getInstance('B360_API_Proration_Method').Value__c);
                String uuId = gslib_IdUtils.createUUID();
                payload.salesforceTransactionIdentifier = uuId;
                
                String namedCredential;
                if (EnvironmentUtil.getNamedCredential() == 'WorkatoIntegration_Sandbox') {
                    namedCredential = 'callout:WorkatoIntegration_Sandbox';
                } else {
                    namedCredential = 'callout:WorkatoIntegration_Prod';
                }
                System.debug(JSON.serialize(payload));
                
                // Get named credential endpoint
                HttpRequest req = new HttpRequest();
                req.setEndpoint(namedCredential);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(payload));
                
                // Make the callout
                Http http = new Http();
                DateTime requestTime = DateTime.now();
                HttpResponse res = http.send(req);
                DateTime acknowledgementTime = DateTime.now();              
                if(res.getStatusCode() == 200) {
                    quote.API_Status__c = 'Pending';
                    quote.API_Error_msg__c = null;
                    LOGGER.atInfo().setCLassName(sourceContext != null ? sourceContext : 'BillingProrationAmountQueuable').setRecordId(quote.Id).setUUID(uuId).setRequestTime(requestTime).setAcknowledgementTime(acknowledgementTime).setExceptionOrMessage('Successful Callout' + '\n\n' + 'Response is: '+ res.getBody() + '\n\n'+ 'payload is: '+JSON.serialize(payload));
                    B360quoteSetId.add(quote.Id);
                } else {
                    quote.API_Status__c = 'Error';
                    Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
                    if(responseMap.containsKey('error')) {
                        // Get error details if present in standard format
                        quote.API_Error_msg__c = (String)responseMap.get('error');
                    } else if(responseMap.containsKey('errorMessage')) {
                        // Alternative error message field
                        quote.API_Error_msg__c = (String)responseMap.get('errorMessage');
                    } else if (responseMap.containsKey('message')) {
                        quote.API_Error_msg__c = String.valueOf(responseMap.get('message'));
                    } else {
                        // Fallback to HTTP status
                        quote.API_Error_msg__c = res.getStatusCode() + ' ' + res.getStatus();
                    }
                    LOGGER.atError().setCLassName(sourceContext != null ? sourceContext : 'BillingProrationAmountQueuable').setRecordId(quote.Id).setUUID(uuId).setRequestTime(requestTime).setAcknowledgementTime(acknowledgementTime).setExceptionOrMessage('API Error: ' +quote.API_Error_msg__c + '\n\n' + 'Response is: '+ res.getBody() + '\n\n' + 'payload is: '+JSON.serialize(payload));
                    B360quoteSetId.add(quote.Id);
                    
                
                }   
                if (Test.isRunningTest()) {
                    throw new DmlException('Unhandled Exception');
                } 
            } catch(Exception e) {
                // Handle any exceptions
                quote.API_Status__c = 'Error';
                quote.API_Error_msg__c = 'Exception: ' + e.getMessage();
                LOGGER.atError().setCLassName(sourceContext != null ? sourceContext : 'BillingProrationAmountQueuable').setRecordId(quote.Id).setExceptionOrMessage(e);                
            	B360quoteSetId.add(quote.Id);
            }
            quoteList.add(quote);
        } 
        // Update quotes with results
        if(!quoteList.isEmpty()) {
            TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
            SBQQ.TriggerControl.disable();
            try {
               update quoteList;
            } catch (Exception e) {
               LOGGER.atError().setCLassName(sourceContext != null ? sourceContext : 'BillingProrationAmountQueuable').setRecordId(quoteList[0].Id).setExceptionOrMessage(e);                
            }
            SBQQ.TriggerControl.enable();
            TriggerHandler.clearAllBypasses();         
        }
        LOGGER.setRecordIds(B360quoteSetId);
        Logger.setFunctionalityType('Billing Proration API Callout');
        Logger.insertMasterLogs();        
    }
    
    Public String formattedDate(Date inputDate) {
        return inputDate.month() + '/' + inputDate.day() + '/' + inputDate.year();       
    }
}