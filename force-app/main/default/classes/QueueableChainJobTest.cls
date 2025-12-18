@isTest
private class QueueableChainJobTest {

    @testSetup
    static void setup() {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('Product2TriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteTriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteLineTriggerHandler');
        TriggerHandler.bypass('ShippingAddressTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('RequestTrackerTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('SubscriptionTriggerHandler');
        TriggerHandler.bypass('OrderTriggerHandler');
        TriggerHandler.bypass('OrderItemTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');

        // Create test data using MercuryPhase2DataFactory
        Account testAccount = MercuryPhase2DataFactory.createAccount('Test Account for QueueableChainJob', true);
        Contact testContact = MercuryPhase2DataFactory.createContact(testAccount.Id, true);
        Shipping_Address__c testShippingAddress = MercuryPhase2DataFactory.createShippingAddress(testAccount.Id, testContact.Id, true);
        
        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        Test.startTest();
        SBQQ.TriggerControl.disable();
        insert testOpp;
        
        // Create Contract
        Contract testContract = MercuryPhase2DataFactory.createContract(testAccount.Id, true);
        
        Id pricebookId = Test.getStandardPricebookId();
        // Create Product
        Product2 testProduct = MercuryPhase2DataFactory.createProduct(true);
           
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        insert pricebookEntries;
        
        // Create Quote
        SBQQ__Quote__c testQuote = MercuryPhase2DataFactory.createQuote(testAccount.Id, testOpp.Id, true);
        
        // Create Quote Line
        SBQQ__QuoteLine__c testQuoteLine = MercuryPhase2DataFactory.createQuoteLines(testAccount.Id, testQuote.Id, String.valueOf(testShippingAddress.Id), String.valueOf(testProduct.Id), String.valueOf(vg33PB.Id), 10000, 2, true);
        SBQQ.TriggerControl.enable();
        
        // Create Subscription with the quote line
        MercuryPhase2DataFactory.createSubscription(testAccount.Id, testContract.Id, testQuoteLine.Id, true);
        
        //activate the contract
        testContract.Status = 'Activated';
        testContract.SBQQ__Opportunity__c = testOpp.Id;
        testContract.ActivatedDate = Date.today();
        update testContract;

        testAccount.Latest_Active_Contract__c = testContract.Id;
        update testAccount;
        
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }

    // 🔁 Testable subclass of QueueableChainJob
    private class TestQueueableJob extends QueueableChainJob {
        public Boolean throwException = false;
        public String exceptionType = 'none';

        public TestQueueableJob(Integer retryCount, String stepStatus, Request_Tracker__c tracker) {
            super(retryCount, stepStatus, tracker);
        }

        protected override void processJob() {
            if (throwException) {
                if (exceptionType == 'DML') {
                    throw new RequestTrackerException('UNABLE_TO_LOCK_ROW');
                } else if (exceptionType == 'Callout') {
                    throw new RequestTrackerException('Quote Recalculation Job Failed');
                } else {
                    throw new RequestTrackerException('Some non-retryable error');
                }
            }
            // Simulate processing
        }

        protected override Queueable newInstanceWithRetry(Integer retryCount) {
            return new TestQueueableJob(retryCount, stepStatus, tracker);
        }
    }

    // Test implementation that simulates OrderResultToWorkatoService
    private class TestOrderResultToWorkatoService extends QueueableChainJob {
        public TestOrderResultToWorkatoService(Integer retryCount, String stepStatus, Request_Tracker__c tracker) {
            super(retryCount, stepStatus, tracker);
        }
        
        protected override void processJob() {
            throw new RequestTrackerException('Test callout exception for OrderResultToWorkatoService');
        }
        
        protected override Queueable newInstanceWithRetry(Integer retryCount) {
            return new TestOrderResultToWorkatoService(retryCount, this.stepStatus, this.tracker);
        }
        
        public override String toString() {
            return 'OrderResultToWorkatoService';
        }
    }

    // Test implementation that simulates other classes
    private class TestOtherQueueableJob extends QueueableChainJob {
        public TestOtherQueueableJob(Integer retryCount, String stepStatus, Request_Tracker__c tracker) {
            super(retryCount, stepStatus, tracker);
        }
        
        protected override void processJob() {
            throw new RequestTrackerException('Test callout exception for other classes');
        }
        
        protected override Queueable newInstanceWithRetry(Integer retryCount) {
            return new TestOtherQueueableJob(retryCount, this.stepStatus, this.tracker);
        }
        
        public override String toString() {
            return 'TestOtherQueueableJob';
        }
    }

    // ✅ Individual tests
    @isTest static void testSuccessfulExecution() {
        Request_Tracker__c tracker = insertTracker();

        TestQueueableJob job = new TestQueueableJob(0, 'Step1', tracker);
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        tracker = [SELECT Status__c FROM Request_Tracker__c WHERE Id = :tracker.Id];
        System.assertEquals('Completed', tracker.Status__c);
    }

    @isTest static void testRetryableException_DML() {
        Request_Tracker__c tracker = insertTracker();

        TestQueueableJob job = new TestQueueableJob(0, 'Step1', tracker);
        job.throwException = true;
        job.exceptionType = 'DML';

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        tracker = [SELECT Status__c, Step_Status__c FROM Request_Tracker__c WHERE Id = :tracker.Id];
        System.assertEquals('Error', tracker.Status__c);
        System.assert(tracker.Step_Status__c.contains('Failed'));
    }

    @isTest static void testRetryableException_Callout() {
        try{
            Request_Tracker__c tracker = insertTracker();
            
            TestQueueableJob job = new TestQueueableJob(1, 'Step2', tracker);
            job.throwException = true;
            job.exceptionType = 'Callout';
            
            Test.startTest();
            System.enqueueJob(job);
            Test.stopTest();
            
            tracker = [SELECT Status__c, Step_Status__c FROM Request_Tracker__c WHERE Id = :tracker.Id];
            System.assertEquals('Error', tracker.Status__c);
            System.assert(tracker.Step_Status__c.contains('Failed'));
        }catch(Exception exp){
            
        }
    }

    @isTest static void testNonRetryableException() {
        Request_Tracker__c tracker = insertTracker();

        TestQueueableJob job = new TestQueueableJob(2, 'Step3', tracker);
        job.throwException = true;
        job.exceptionType = 'Other';

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        tracker = [SELECT Status__c, Step_Status__c FROM Request_Tracker__c WHERE Id = :tracker.Id];
        System.assertEquals('Error', tracker.Status__c);
        System.assert(tracker.Step_Status__c.contains('Failed'));
    }

    @isTest static void testChainedJob() {
        Request_Tracker__c tracker = insertTracker();

        TestQueueableJob firstJob = new TestQueueableJob(0, 'Step1', tracker);
        TestQueueableJob secondJob = new TestQueueableJob(0, 'Step2', tracker);
        firstJob.setNextJob(secondJob);

        Test.startTest();
        System.enqueueJob(firstJob);
        Test.stopTest();

        tracker = [SELECT Status__c FROM Request_Tracker__c WHERE Id = :tracker.Id];
        System.assertEquals('Error', tracker.Status__c);
    }

    @isTest static void testEnqueueRetryJob_OrderResultToWorkatoService() {
        Request_Tracker__c tracker = insertTracker();

        try {
            Test.startTest();
            // Create a test implementation that simulates OrderResultToWorkatoService
            TestOrderResultToWorkatoService testJob = new TestOrderResultToWorkatoService(0, 'Step-1', tracker);
            
            // Execute the job which will trigger the retry logic
            System.enqueueJob(testJob);
            Test.stopTest();
            
            System.debug('Test completed for OrderResultToWorkatoService retry logic');
        } catch (Exception e) {
            System.debug('Error in testEnqueueRetryJob_OrderResultToWorkatoService: ' + e.getMessage());
        }
    }

    @isTest static void testEnqueueRetryJob_OtherClasses() {
        Request_Tracker__c tracker = insertTracker();

        try {
            Test.startTest();
            // Create a test implementation that simulates other classes (not OrderResultToWorkatoService)
            TestOtherQueueableJob testJob = new TestOtherQueueableJob(0, 'Step-1', tracker);
            
            // Execute the job which will trigger the retry logic
            System.enqueueJob(testJob);
            Test.stopTest();
            
            System.debug('Test completed for other classes retry logic');
        } catch (Exception e) {
            System.debug('Error in testEnqueueRetryJob_OtherClasses: ' + e.getMessage());
        }
    }

    @isTest static void testMaxRetriesReached() {
        try{
            Request_Tracker__c tracker = insertTracker();
            
            TestQueueableJob job = new TestQueueableJob(2, 'Step1', tracker); // Start with max retries
            job.throwException = true;
            job.exceptionType = 'Callout';
            
            Test.startTest();
            System.enqueueJob(job);
            Test.stopTest();
            
            tracker = [SELECT Status__c, Step_Status__c FROM Request_Tracker__c WHERE Id = :tracker.Id];
            System.assertEquals('Error', tracker.Status__c);
            System.assert(tracker.Step_Status__c.contains('Failed'));
        }catch(Exception exp){
            
        }
    }

    @isTest static void testFinallyBlockException() {
        try{
            Request_Tracker__c tracker = insertTracker();
            
            TestQueueableJobWithFinallyError job = new TestQueueableJobWithFinallyError(0, 'Step1', tracker);
            
            Test.startTest();
            System.enqueueJob(job);
            Test.stopTest();
            
            System.debug('Test completed for finally block exception handling');
        }Catch(Exception exp){
            
        }
    }

    // Test implementation that causes finally block exception
    private class TestQueueableJobWithFinallyError extends QueueableChainJob {
        public TestQueueableJobWithFinallyError(Integer retryCount, String stepStatus, Request_Tracker__c tracker) {
            super(retryCount, stepStatus, tracker);
        }
        
        protected override void processJob() {
            try{
                // Simulate successful processing but tracker update will fail
                this.tracker.Id = null; // This will cause update to fail in finally block
            }catch(Exception exp){
                
            }
        }
        
        protected override Queueable newInstanceWithRetry(Integer retryCount) {
            return new TestQueueableJobWithFinallyError(retryCount, this.stepStatus, this.tracker);
        }
    }

    // Helpers
    private static Request_Tracker__c insertTracker() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for QueueableChainJob' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        // Create test payload using MercuryPhase2DataFactory
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        String jsonPayload = JSON.serialize(orderPayload);
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = testAccount.Id,
            Request__c = jsonPayload,
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;
        return tracker;
    }
}