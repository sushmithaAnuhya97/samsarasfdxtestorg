public with sharing class InsertFreeTrialQuoteLineJob extends QueueableChainJob {
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    private String stepStatus;
    
    public InsertFreeTrialQuoteLineJob(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        this.stepStatus = stepStatus;
    }
    
    public override void processJob() {
        try {
            createLog('Started processing: Insert Free Trial Quote Lines Job.');
            OrderUtil.initializeUnitOfWork();
            
            // Validate quote ID from tracker
            if (String.isBlank(tracker?.Quote_Id__c)) {
                throw new RequestTrackerException('Quote ID is missing in tracker. Cannot proceed with free trial quote line insertion.');
            }
            
            // Get the quote
            SBQQ__Quote__c quote = OrderProcessorSingleton.getInstance().queryQuote(tracker.Quote_Id__c);
            if (quote == null) {
                throw new RequestTrackerException('Quote not found with ID: ' + tracker.Quote_Id__c);
            }
            
            // Create quote lines if available in payload
            if (payload?.quote?.quoteLines != null && !payload.quote.quoteLines.isEmpty()) {
                createFreeTrialQuoteLines(quote);
            } else {
                createLog('No quote lines found in payload. Skipping quote line creation.');
            }
            SBQQ.TriggerControl.disable();
            DMLWrapper.publishDML();
            SBQQ.TriggerControl.enable();
            
            createLog('Finished processing: Insert Free Trial Quote Lines.');
        } catch (RequestTrackerException e) {
            throw e;
        } catch (Exception e) {
            throw new RequestTrackerException('Insert Free Trial Quote Lines Job Failed.retryCount:'+retryCount + 'Error Body:' + JSON.serialize(e.getMessage()));
        }
    }
    
    private void createFreeTrialQuoteLines(SBQQ__Quote__c quote) {
        createLog('Creating Free Trial Quote Lines for Quote: ' + quote.Id);
        
        List<SBQQ__QuoteLine__c> quoteLines = JsonToSFDCMapper.mapFreeTrialQuoteLines(payload);
        
        if (quoteLines == null || quoteLines.isEmpty()) {
            createLog('No quote lines found in payload. Skipping quote line creation.');
            return;
        }
        
        // Set quote reference for all quote lines
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            quoteLine.Account__c = payload.order.account_id;
            quoteLine.SBQQ__Quote__c = tracker.Quote_Id__c;
            quoteLine.Ship_To__c = tracker.Shipping_Address_Id__c;
        }
        
        insertQuoteLines(quoteLines);
    }

    public void insertQuoteLines(List<SBQQ__QuoteLine__c> quoteLines) {
        try {
            createLog('QuoteLines before creation: ' + quoteLines.size() + ' records');
            
            // Use DML insert with allOrNone=true for transaction safety
            DMLWrapper.doInsert(quoteLines);
      
            createLog('QuoteLines created successfully via DML. Inserted ' + quoteLines.size() + ' records.');
            
            // Log the created record IDs for debugging
            List<String> createdIds = new List<String>();
            for (SBQQ__QuoteLine__c ql : quoteLines) {
                createdIds.add(ql.Id);
            }
            createLog('Created Quote Line IDs: ' + String.join(createdIds, ', '));
            
        } catch (DmlException e) {
            createLog('Insert QuoteLines Job Failed. RetryCount: ' + retryCount + ', Error: ' + e.getMessage());
            throw new RequestTrackerException('Insert QuoteLines Job Failed. RetryCount: ' + retryCount + ', Error: ' + e.getMessage());
        } catch (Exception e) {
            createLog('Unexpected error in Insert QuoteLines Job. RetryCount: ' + retryCount + ', Error: ' + e.getMessage());
            throw new RequestTrackerException('Unexpected error in Insert QuoteLines Job. RetryCount: ' + retryCount + ', Error: ' + e.getMessage());
        }
    }
    
    @TestVisible
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new InsertFreeTrialQuoteLineJob(tracker, stepStatus, payload, retryCount);
    }
    
    private void createLog(String logMessage) {
        DateTime now = DateTime.now();
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, now, now);
    }
}