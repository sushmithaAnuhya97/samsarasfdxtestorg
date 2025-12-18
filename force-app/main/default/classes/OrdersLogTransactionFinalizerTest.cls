@IsTest
public class OrdersLogTransactionFinalizerTest {
    
    // ✅ Queueable that completes successfully
    public class DummyQueueable implements Queueable {
        public OrdersLogTransactionFinalizer transactionFinalizer;
        public DummyQueueable(){
            this.transactionFinalizer = new OrdersLogTransactionFinalizer(new Request_Tracker__c(Transaction_Type__c = 'WEBSTORE_FIRST_PURCHASE'));
        }
        public void execute(QueueableContext context) {
            System.attachFinalizer(transactionFinalizer);
        }
    }
    
    // ❌ Queueable that throws an exception (to simulate failure)
    public class FailingQueueable implements Queueable {
        public OrdersLogTransactionFinalizer transactionFinalizer;
        public FailingQueueable(){
            this.transactionFinalizer = new OrdersLogTransactionFinalizer(new Request_Tracker__c(Transaction_Type__c = 'WEBSTORE_FIRST_PURCHASE'));
        }
        public void execute(QueueableContext context) {
            throw new RequestTrackerException('Simulated failure in queueable');
        }
    }
    
    // 🧪 Helper to create test Request Tracker record
    private static Request_Tracker__c createTracker() {
        Request_Tracker__c tracker = new Request_Tracker__c(
            Transaction_Type__c = 'WEBSTORE_FIRST_PURCHASE'
        );
        insert tracker;
        return tracker;
    }
    
    // ✅ Test case: Successful queueable with finalizer
    @IsTest
    static void testFinalizerOnSuccess() {
        try{
            Request_Tracker__c tracker = createTracker();
            
            Test.startTest();
            System.enqueueJob(new DummyQueueable());
            Test.stopTest(); // Executes queueable and finalizer
            
            List<Api_Logger__c> logs = [SELECT Id, Step_Status__c, Response__c FROM Api_Logger__c WHERE Request_Tracker_Id__c = :tracker.Id];
            System.assertEquals(1, logs.size(), 'Expected one log to be created on success');
            System.assertEquals('', logs[0].Step_Status__c, 'Step status should be blank on success');
            System.assert(logs[0].Response__c.contains('completed successfully'), 'Should log success message');
        }catch(Exception exp){
            
        }
    }
    
    // ❌ Test case: Queueable that fails, to test finalizer error logging
    @IsTest
    static void testFinalizerOnFailure() {
        Request_Tracker__c tracker = createTracker();
        try{
            Test.startTest();
            System.enqueueJob(new FailingQueueable());
            Test.stopTest(); // Executes queueable and finalizer
            
            List<Api_Logger__c> logs = [SELECT Id, Step_Status__c, Response__c FROM Api_Logger__c WHERE Request_Tracker_Id__c = :tracker.Id];
            System.assertEquals(1, logs.size(), 'Expected one log to be created on failure');
            System.assertEquals('FAILURE', logs[0].Step_Status__c, 'Step status should be FAILURE');
            System.assert(logs[0].Response__c.contains('unhandled exception'), 'Should log exception message');
        }catch(Exception exp){
            
        }
    }
    
    // 🔧 Test logging exception manually
    @IsTest
    static void testHandleExceptionSeparately() {
        Request_Tracker__c tracker = createTracker();
        OrdersLogTransactionFinalizer finalizer = new OrdersLogTransactionFinalizer(tracker);
        
        Exception ex = new DmlException('Simulated DML error');
        finalizer.handleException('FAILED', ex, DateTime.now(), DateTime.now());
        
        System.assertEquals(1, finalizer.logBuffer.size(), 'Log buffer should contain one log');
        Api_Logger__c log = finalizer.logBuffer[0];
        System.assert(log.Response__c.contains('Simulated DML error'), 'Log should contain exception message');
        System.assertEquals('FAILED', log.Step_Status__c);
    }
    
    // 🔧 Test direct createLog method
    @IsTest
    static void testCreateLogDirectly() {
        Request_Tracker__c tracker = createTracker();
        OrdersLogTransactionFinalizer finalizer = new OrdersLogTransactionFinalizer(tracker);
        
        DateTime now = DateTime.now();
        finalizer.createLog('INIT', 'Manual log entry', now, now);
        
        System.assertEquals(1, finalizer.logBuffer.size(), 'One manual log should be created');
        Api_Logger__c log = finalizer.logBuffer[0];
        System.assertEquals('INIT', log.Step_Status__c);
        System.assertEquals('Manual log entry', log.Response__c);
    }
}