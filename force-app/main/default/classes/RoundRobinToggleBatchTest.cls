@isTest
private class RoundRobinToggleBatchTest {
    @testSetup
    static void setup() {
        //Role - 00E4p000000uE46EAE
       List<User> Usr = [SELECT Id, UserRole.Name FROM user WHERE IsActive = true AND Inbound_ADR_Out_Of_Office__c = false AND UserRole.Name LIKE 'Fleet ADR IB NA US Team 3' LIMIT 2];
        RR_Assignment_Rule__c rule = new RR_Assignment_Rule__c(Active__c=true, Object__c = 'Account',  
            Category__c = 'Lane Four', Rule_Description__c='Test',
            Order__c=1, Type__c='Other');
        insert rule;

        RR_Assignment_Rule__c ruleException = new RR_Assignment_Rule__c(Active__c=true, Object__c = 'Account',  
        Category__c = 'Lane Four', Rule_Description__c='TestException',
        Order__c=1, Type__c='Other');
        insert ruleException;
        //5AMBatch
        RR_Assignment_Mapping__c rrMappings = new RR_Assignment_Mapping__c(
            Active__c=true, Type__c='Other', Field_To_Assign__c = 'User', Pause_Assignment__c=false, User__c = Usr[0].Id,
            //User__c = TestFactory.getFakeId(User.getSObjectType()), 
            Assignment_Rule__c =  rule.Id, Order__c=1);
        insert rrMappings;
        //5PMBatch
        RR_Assignment_Mapping__c rrMapException = new RR_Assignment_Mapping__c(
            Active__c=true, Type__c='Other', Field_To_Assign__c = 'User', Pause_Assignment__c=true, User__c = Usr[1].Id,
            Assignment_Rule__c =  ruleException.Id, Order__c=1);
        insert rrMapException;
    }
    @isTest static void batch5PMTest() {
        Test.startTest();
        Id batchId = Database.executeBatch(new RoundRobinToggle_Batch5PM(),10);
        Test.stopTest();
        RR_Assignment_Mapping__c rr = [SELECT Id, Pause_Assignment__c FROM RR_Assignment_Mapping__c LIMIT 1];
        System.assertEquals(true, rr.Pause_Assignment__c);
    }
    @isTest static void batch5AMTest() {
        Test.startTest();
        Id batchId = Database.executeBatch(new RoundRobinToggle_Batch5AM(),10);
        Test.stopTest();
        RR_Assignment_Mapping__c rr = [SELECT Id, Pause_Assignment__c FROM RR_Assignment_Mapping__c LIMIT 1];
        System.assertEquals(false, rr.Pause_Assignment__c);
    }
}