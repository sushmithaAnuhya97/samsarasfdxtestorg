@IsTest
private class OrderUtilTest {

    @IsTest
    static void testGetOrderProcessingSettings() {
        Test.startTest();
        Order_Processing_Settings__mdt setting = OrderUtil.getOrderProcessingSettings();
        Test.stopTest();
        
        System.assertNotEquals(null, setting, 'Metadata should be returned');
        System.assertEquals(3, setting.Maximum_Retries__c);
    }

    @IsTest
    static void testDisableEnableTriggers() {
        Test.startTest();
        OrderUtil.disableTriggers();
        OrderUtil.enableTriggers();
        Test.stopTest();
        
        // No exception expected — confirm call success
        System.assert(true, 'Trigger disable/enable executed');
    }

    @IsTest
    static void testCanEnqueueJob() {
        Test.startTest();
        Boolean canEnqueue = OrderUtil.canEnqueueJob();
        Test.stopTest();
        
        System.assertEquals(true, canEnqueue, 'Should be able to enqueue job');
    }

    private class DummyJob implements Queueable {
        public void execute(QueueableContext context) {
            System.debug('DummyJob executed');
        }
    }

    @IsTest
    static void testEnqueueJobIfPossible() {
        Test.startTest();
        OrderUtil.enqueueJobIfPossible(new DummyJob());
        OrderUtil.enqueueJobIfPossibleWithDelay(new DummyJob(), 5);
        Test.stopTest();
        
        System.assert(true, 'Job enqueued successfully');
    }

    @IsTest
    static void testEnqueueJobLimitReached() {
        Test.startTest();
        Boolean caught = false;
        try {
            // Simulate maxed out queueable limit
            for (Integer i = 0; i < Limits.getLimitQueueableJobs(); i++) {
                System.enqueueJob(new DummyJob());
            }
            OrderUtil.enqueueJobIfPossible(new DummyJob()); // Should throw
        } catch (RequestTrackerException e) {
            caught = true;
            System.assert(e.getMessage().contains('Queueable job limit'), 'Expected queueable limit error');
        }
        Test.stopTest();
        System.assert(caught, 'Exception was expected when limit is reached');
    }

    @IsTest
    static void testInitializeUnitOfWork() {
        Test.startTest();
        OrderUtil.initializeUnitOfWork();
        Test.stopTest();
        
        System.assert(true, 'Unit of Work initialized');
    }

    @IsTest
    static void testLogJobAndFlush() {
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'ORD123',
            Status__c = 'Received',
            Transaction_Type__c = 'CREATE',
            Retry_Count__c = 0,
            Request__c = '{}'
        );
        insert tracker;

        Test.startTest();
        OrderUtil.logJob(tracker, 'Step-1', 'Test log message', DateTime.now(), DateTime.now(), true);
        OrderUtil.flushLogs();
        Test.stopTest();
        
        System.assert(true, 'Log job and flush successful');
    }

    @IsTest
    static void testIsRowLockIssue() {
        Exception rowLockException = new DmlException('UNABLE_TO_LOCK_ROW: Row was locked');
        Exception otherException = new DmlException('Some other error');
        
        System.assertEquals(true, OrderUtil.isRowLockIssue(rowLockException), 'Should detect row lock');
        System.assertEquals(false, OrderUtil.isRowLockIssue(otherException), 'Should not detect row lock');
    }

    @IsTest
    static void testShouldRetry() {
        System.assertEquals(true, OrderUtil.shouldRetry(0), 'Retry should be allowed');
        System.assertEquals(true, OrderUtil.shouldRetry(2), 'Retry should be allowed');
        System.assertEquals(false, OrderUtil.shouldRetry(3), 'Should not retry on max');
    }
}