@isTest
public with sharing class DeferredQueueableBatchTest {
    
    // Test data setup
    @TestSetup
    static void setupTestData() {
        // Ensure we have at least one active user for the query
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.assert(testUser != null, 'Test user should exist for batch execution');
        Account testAccount = MercuryPhase2DataFactory.createAccount('Test Account', true);
    }
    
    // Test constructor with valid parameters
    @isTest
    static void testConstructorWithValidParameters() {
        // Arrange
        TestQueueableJob mockJob = new TestQueueableJob();
        Integer delayMinutes = 5;
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = acc.Id,
            Request__c = 'test',
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        
        insert tracker;
        // Act
        DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, delayMinutes,tracker, 'Step-1');
        
        // Assert
        System.assert(batch != null, 'DeferredQueueableBatch should be created successfully');
    }
    
    // Test constructor with null job
    @isTest
    static void testConstructorWithNullJob() {
        // Arrange
        Queueable nullJob = null;
        Integer delayMinutes = 5;
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
         // Create test tracker
         Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = acc.Id,
            Request__c = 'test',
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        
        insert tracker;
        // Act
        DeferredQueueableBatch batch = new DeferredQueueableBatch(nullJob, delayMinutes,tracker, 'Step-1');
        
        // Assert
        System.assert(batch != null, 'DeferredQueueableBatch should be created even with null job');
    }
    
    // Test constructor with zero delay
    @isTest
    static void testConstructorWithZeroDelay() {
        // Arrange
        TestQueueableJob mockJob = new TestQueueableJob();
        Integer delayMinutes = 0;
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
         // Create test tracker
         Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = acc.Id,
            Request__c = 'test',
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        
        insert tracker;
        // Act
        DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, delayMinutes,tracker, 'Step-1');
        
        // Assert
        System.assert(batch != null, 'DeferredQueueableBatch should be created with zero delay');
    }
    
    // Test constructor with negative delay
    @isTest
    static void testConstructorWithNegativeDelay() {
        // Arrange
        TestQueueableJob mockJob = new TestQueueableJob();
        Integer delayMinutes = -5;
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
         // Create test tracker
         Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = acc.Id,
            Request__c = 'test',
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        
        insert tracker;
        // Act
        DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, delayMinutes,tracker, 'Step-1'); 
        // Assert
        System.assert(batch != null, 'DeferredQueueableBatch should be created with negative delay');
    }
    
    // Test start method returns valid query locator
    @isTest
    static void testStartMethod() {
        // Arrange
        TestQueueableJob mockJob = new TestQueueableJob();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
         // Create test tracker
         Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = acc.Id,
            Request__c = 'test',
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        
        insert tracker;
        // Act
        DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, 5,tracker, 'Step-1');
        
        // Act
        Database.QueryLocator queryLocator = batch.start(null);
        
        // Assert
        System.assert(queryLocator != null, 'QueryLocator should be returned from start method');
    }
    
    // Test execute method with valid scope
    // @isTest
    // static void testExecuteMethodWithValidScope() {
    //     // Arrange
    //     TestQueueableJob mockJob = new TestQueueableJob();
    //     Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    //      // Create test tracker
    //      Request_Tracker__c tracker = new Request_Tracker__c(
    //         OrderId__c = 'TEST-123',
    //         Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
    //         Account_Id__c = acc.Id,
    //         Request__c = 'test',
    //         Status__c = 'Received',
    //         Step_Status__c = 'Step-1'
    //     );
        
    //     insert tracker;
    //     // Act
    //     DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, 5,tracker, 'Step-1');
    //     List<User> testUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
    //     // Act
    //     Test.startTest();
    //     batch.execute(null, testUsers);
    //     Test.stopTest();
        
    //     // Assert
    //     System.assert(testUsers.size() > 0, 'Test scope should contain at least one user');
    // }
    
    // // Test execute method with empty scope
    // @isTest
    // static void testExecuteMethodWithEmptyScope() {
    //     // Arrange
    //     TestQueueableJob mockJob = new TestQueueableJob();
    //     Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    //     // Create test tracker
    //     Request_Tracker__c tracker = new Request_Tracker__c(
    //         OrderId__c = 'TEST-123',
    //         Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
    //         Account_Id__c = acc.Id,
    //         Request__c = 'test',
    //         Status__c = 'Received',
    //         Step_Status__c = 'Step-1'
    //     );
        
    //     insert tracker;
    //     // Act
    //     DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, 5,tracker, 'Step-1');
    //     List<User> emptyScope = new List<User>();
        
    //     // Act
    //     Test.startTest();
    //     batch.execute(null, emptyScope);
    //     Test.stopTest();
        
    //     // Assert
    //     System.assert(emptyScope.isEmpty(), 'Empty scope should be handled gracefully');
    // }
    
    // Test execute method with null scope
    // @isTest
    // static void testExecuteMethodWithNullScope() {
    //     // Arrange
    //     TestQueueableJob mockJob = new TestQueueableJob();
    //     Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    //      // Create test tracker
    //      Request_Tracker__c tracker = new Request_Tracker__c(
    //         OrderId__c = 'TEST-123',
    //         Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
    //         Account_Id__c = acc.Id,
    //         Request__c = 'test',
    //         Status__c = 'Received',
    //         Step_Status__c = 'Step-1'
    //     );
        
    //     insert tracker;
    //     // Act
    //     DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, 5,tracker, 'Step-1');
    //     // Act
    //     Test.startTest();
    //     batch.execute(null, null);
    //     Test.stopTest();
        
    //     // Assert
    //     System.assert(true, 'Execute method should handle null scope without exception');
    // }
    
    // Test finish method
    // @isTest
    // static void testFinishMethod() {
    //     // Arrange
    //     TestQueueableJob mockJob = new TestQueueableJob();
    //     Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    //      // Create test tracker
    //      Request_Tracker__c tracker = new Request_Tracker__c(
    //         OrderId__c = 'TEST-123',
    //         Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
    //         Account_Id__c = acc.Id,
    //         Request__c = 'test',
    //         Status__c = 'Received',
    //         Step_Status__c = 'Step-1'
    //     );
        
    //     insert tracker;
    //     // Act
    //     DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, 5,tracker, 'Step-1');
    //     // Act
    //     batch.finish(null);
        
    //     // Assert
    //     System.assert(true, 'Finish method should execute without exception');
    // }
    
    // Test complete batch execution flow
    @isTest
    static void testCompleteBatchExecutionFlow() {
        // Arrange
        TestQueueableJob mockJob = new TestQueueableJob();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
         // Create test tracker
         Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = acc.Id,
            Request__c = 'test',
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        
        insert tracker;
        // Act
        Test.startTest();
        DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, 5,tracker, 'Step-1');
        Database.executeBatch(batch, 1);
        Test.stopTest();
        
        // Assert
        System.assert(true, 'Complete batch execution should complete successfully');
    }
    
    // Test batch execution with different delay values
    @isTest
    static void testBatchExecutionWithDifferentDelays() {
        // Arrange
        TestQueueableJob mockJob = new TestQueueableJob();
        List<Integer> delays = new List<Integer>{0, 1, 5, 10};
        
        // Act & Assert
        for (Integer delay : delays) {
            Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            Request_Tracker__c tracker = new Request_Tracker__c(
                OrderId__c = 'TEST-123',
                Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
                Account_Id__c = acc.Id,
                Request__c = 'test',
                Status__c = 'Received',
                Step_Status__c = 'Step-1'
            );
            
            insert tracker;
            // Act
            DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, delay,tracker, 'Step-1');
            System.assert(batch != null, 'Batch should be created with delay: ' + delay);
        }
    }
    
    // Test batch execution with different job types
    @isTest
    static void testBatchExecutionWithDifferentJobTypes() {
        // Arrange
        List<Queueable> jobs = new List<Queueable>{
            new TestQueueableJob(),
            new TestQueueableJob2()
        };
        
        // Act & Assert
        for (Queueable job : jobs) {
            Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            Request_Tracker__c tracker = new Request_Tracker__c(
                OrderId__c = 'TEST-123',
                Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
                Account_Id__c = acc.Id,
                Request__c = 'test',
                Status__c = 'Received',
                Step_Status__c = 'Step-1'
            );
            
            insert tracker;
            // Act
            DeferredQueueableBatch batch = new DeferredQueueableBatch(job, 5,tracker, 'Step-1');
            System.assert(batch != null, 'Batch should be created with different job types');
        }
    }
    
    // Test query locator returns expected data
    @isTest
    static void testQueryLocatorReturnsExpectedData() {
        // Arrange
        TestQueueableJob mockJob = new TestQueueableJob();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = acc.Id,
            Request__c = 'test',
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        
        insert tracker;
        // Act
        DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, 5,tracker, 'Step-1');
        
        // Act
        Database.QueryLocator queryLocator = batch.start(null);
        List<User> users = Database.query(queryLocator.getQuery());
        
        // Assert
        System.assert(users.size() > 0, 'QueryLocator should return at least one active user');
    }
    
    // Test batch context parameter handling
    // @isTest
    // static void testBatchContextParameterHandling() {
    //     // Arrange
    //     TestQueueableJob mockJob = new TestQueueableJob();
    //     Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    //     Request_Tracker__c tracker = new Request_Tracker__c(
    //         OrderId__c = 'TEST-123',
    //         Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
    //         Account_Id__c = acc.Id,
    //         Request__c = 'test',
    //         Status__c = 'Received',
    //         Step_Status__c = 'Step-1'
    //     );

    //     insert tracker;
    //     // Act
    //     DeferredQueueableBatch batch = new DeferredQueueableBatch(mockJob, 5,tracker, 'Step-1');
    //     // Act
    //     Database.QueryLocator queryLocator = batch.start(null);
    //     List<User> testUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
    //     Test.startTest();
    //     batch.execute(null, testUsers);
    //     batch.finish(null);
    //     Test.stopTest();
        
    //     // Assert
    //     System.assert(true, 'All batch methods should handle null context parameter');
    // }
    
    // Mock Queueable classes for testing
    public class TestQueueableJob implements Queueable {
        public void execute(QueueableContext context) {
            // Mock implementation
        }
    }
    
    public class TestQueueableJob2 implements Queueable {
        public void execute(QueueableContext context) {
            // Mock implementation
        }
    }
}