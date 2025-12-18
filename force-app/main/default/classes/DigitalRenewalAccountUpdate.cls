public class DigitalRenewalAccountUpdate extends QueueableChainJob {
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    private String stepStatus;

    public DigitalRenewalAccountUpdate(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        this.stepStatus = stepStatus;
    }

    public override void processJob() {
        createLog('Started processing: Digital Renewal Account Update Job.');
        OrderUtil.initializeUnitOfWork();

        Account newAccount = JsonToSFDCMapper.mapDigitalRenewalAccountData(payload);
        if (newAccount == null) {
            createLog('No account data to process.');
            return;
        }

        Account existingAccount = OrderProcessorSingleton.getInstance().queryAccount(newAccount.Id);
        processAccount(newAccount, existingAccount);
    
        try {
            SBQQ.TriggerControl.disable();
            DMLWrapper.publishDML();
            SBQQ.TriggerControl.enable();
            createLog('Finished processing: Update Account.');
        } catch (Exception e) {
            createLog('Error updating account: ' + e.getMessage());
            throw new RequestTrackerException('Digital Renewal Account Update Job Failed.retryCount:'+retryCount + 'Error Body:' + JSON.serialize(e.getMessage()));
        }
    }

    private void processAccount(Account newAccount, Account existingAccount) {
        if (!hasFieldChanged(existingAccount, newAccount)) {
            createLog('Nothing to update on Account. Field values remain the same. ' + newAccount.Id);
            return;
        }
        DMLWrapper.doUpdate(newAccount);
        createLog('Account Updated: ' + newAccount.Id); 
    }

    @testVisible
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new UpdateAccount(tracker, stepStatus, payload, retryCount);
    }

    public static Boolean hasFieldChanged(SObject oldRecord, SObject newRecord) {
        if (oldRecord == null || newRecord == null) return true;

        Map<String, Object> oldMap = oldRecord.getPopulatedFieldsAsMap();
        Map<String, Object> newMap = newRecord.getPopulatedFieldsAsMap();

        for (String field : newMap.keySet()) {
            Object oldVal = oldMap.get(field);
            Object newVal = newMap.get(field);
            if (oldVal != newVal && (oldVal == null || !oldVal.equals(newVal))) {
                return true;
            }
        }
        return false;
    }

    private void createLog(String logMessage) {
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, DateTime.now(), DateTime.now());
    }
}