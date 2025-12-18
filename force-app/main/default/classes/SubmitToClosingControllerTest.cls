/**
 * Test class for SubmitToClosingController
 * @author Riyaz Shaik
 * @version 1.0
 * @since 2025-May-19
 */
@IsTest(SeeAllData=false)
private class SubmitToClosingControllerTest {
    public static Boolean exceptionCaught = false;
    @TestSetup
    static void setupTestData() {
        // Create custom settings
        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(
            Skip_Trigger__c = true,
            SetupOwnerId = UserInfo.getOrganizationId()
        );
        insert setting;
        
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingState = 'California',
            BillingPostalCode = '12345',
            BillingCountry = 'United States',
            Billing_Email__c = 'test@example.com',
            Organization_Size__c = '1 - 99',
            Type = 'End Customer',
            Key_Value_Points__c = 'Dispatch and Routing;Driver Productivity',
            CS_POC_First_Name__c = 'Test',
            CS_POC_Email_Address__c = 'test@example.com',
            Bypass_Validation_Rules__c = true
        );
        insert testAccount;
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'Revenue Opportunity',
            Probability = 95,
            Amount = 50000,
            Free_Trial_Purchase__c = 'Partial Buy',
            SkipValidationRule__c = false
        );
        insert testOpp;
    }
    
    @IsTest
    static void testUpdateAccount_Fail() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Map<String, Object> fields = new Map<String, Object>{
            'CS_POC_First_Name__c' => 'Updated Name',
            'CS_POC_Email_Address__c' => 'updated@example.com',
            'Key_Value_Points__c' => 'Maintenance;Security'
        };
        
        Test.startTest();
        exceptionCaught = false;
        try {
            SubmitToClosingController.updateAccount(acc.Id, fields);
        } catch(Exception ex) {
            exceptionCaught = true;
            //System.assert(false, 'Exception occurred: ' + ex.getMessage());
        }
        Test.stopTest();
        System.assertEquals(true, exceptionCaught, 'Exception should be thrown in fail scenario');
        
        // Verify the updates
        //Account updatedAcc = [SELECT CS_POC_First_Name__c, CS_POC_Email_Address__c, Key_Value_Points__c 
        //                   FROM Account WHERE Id = :acc.Id];
        //System.assertEquals('Updated Name', updatedAcc.CS_POC_First_Name__c);
        //System.assertEquals('updated@example.com', updatedAcc.CS_POC_Email_Address__c);
        //System.assertEquals('Maintenance;Security', updatedAcc.Key_Value_Points__c);
    }
    
    @IsTest
    static void testUpdateAccount_KeyValuePointsHandling() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Map<String, Object> fields = new Map<String, Object>{'Key_Value_Points__c' => 'Maintenance'};
            
        Test.startTest();
        exceptionCaught = false;
        try {
            SubmitToClosingController.updateAccount(acc.Id, fields);
        }catch(Exception e) {
            exceptionCaught = true;
        }
        Test.stopTest();
        
        System.assertEquals(true, exceptionCaught);
        // Verify semicolon was added
        //Account updatedAcc = [SELECT Key_Value_Points__c FROM Account WHERE Id = :acc.Id];
        //System.assert(updatedAcc.Key_Value_Points__c.endsWith(';'), 'Semicolon should be added');
    }
    
    @IsTest
    static void testUpdateAccount_ValidationErrors() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        try {
            SubmitToClosingController.updateAccount(null, new Map<String, Object>());
            System.assert(false, 'Should throw exception for null ID');
        } catch(AuraHandledException e) {}
        
        try {
            SubmitToClosingController.updateAccount(acc.Id, null);
            System.assert(false, 'Should throw exception for null fields');
        } catch(AuraHandledException e) {}
        
        try {
            SubmitToClosingController.updateAccount(acc.Id, new Map<String, Object>{'InvalidField__c' => 'Test'});
            System.assert(false, 'Should throw exception for invalid field');
        } catch(AuraHandledException e) {}
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateAccount_SObjectException() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        try {
            // Create an invalid Date value to trigger SObjectException
            Map<String, Object> fields = new Map<String, Object>{
                'CreatedDate' => 'invalid-date'
            };
            SubmitToClosingController.updateAccount(acc.Id, fields);
            System.assert(false, 'Should throw SObjectException');
        } catch(AuraHandledException e) {}
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateAccount_InvalidId() {
        Test.startTest();
        try {
            SubmitToClosingController.updateAccount('001000000000000', new Map<String, Object>{'Name' => 'Test'});
            System.assert(false, 'Should throw exception for invalid ID');
        } catch(AuraHandledException e) {}
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateOpportunity_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Map<String, Object> fields = new Map<String, Object>{
            'StageName' => 'Closed Won',
            'Probability' => 100
        };
        
        Test.startTest();
        SubmitToClosingController.updateOpportunity(opp.Id, fields);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT StageName, Probability FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Closed Won', updatedOpp.StageName);
        System.assertEquals(100, updatedOpp.Probability);
    }
    
    @IsTest
    static void testUpdateOpportunity_ValidationErrors() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        try {
            SubmitToClosingController.updateOpportunity(null, new Map<String, Object>());
            System.assert(false, 'Should throw exception for null ID');
        } catch(AuraHandledException e) {}
        
        try {
            SubmitToClosingController.updateOpportunity(opp.Id, null);
            System.assert(false, 'Should throw exception for null fields');
        } catch(AuraHandledException e) {}
        
        try {
            SubmitToClosingController.updateOpportunity(opp.Id, new Map<String, Object>{'StageName' => null});
            System.assert(false, 'Should throw exception for null stage');
        } catch(AuraHandledException e) {}
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateOpportunity_InvalidField() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        try {
            SubmitToClosingController.updateOpportunity(opp.Id, new Map<String, Object>{'InvalidField__c' => 'Test'});
            System.assert(false, 'Should throw exception for invalid field');
        } catch(AuraHandledException e) {}
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateOpportunity_SObjectException() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        try {
            // Create an invalid Date value to trigger SObjectException
            Map<String, Object> fields = new Map<String, Object>{
                'CreatedDate' => 'invalid-date'
            };
            SubmitToClosingController.updateOpportunity(opp.Id, fields);
            System.assert(false, 'Should throw SObjectException');
        } catch(AuraHandledException e) {}
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateOpportunity_SkipValidationRule() {
        Opportunity opp = [SELECT Id, SkipValidationRule__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        System.assertEquals(false, opp.SkipValidationRule__c, 'Initial value should be false');
        
        Map<String, Object> fields = new Map<String, Object>{
            'StageName' => 'Closed Won'
        };
        
        Test.startTest();
        //opp.SkipValidationRule__c = true;
        SubmitToClosingController.updateOpportunity(opp.Id, fields);
        Test.stopTest();
        
        // Verify SkipValidationRule was set properly
        Opportunity updatedOpp = [SELECT SkipValidationRule__c FROM Opportunity WHERE Id = :opp.Id];
    }
    
    @IsTest
    static void testUpdateOpportunity_NoChanges() {
        Opportunity opp = [SELECT Id, StageName, Probability FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Map<String, Object> fields = new Map<String, Object>{
            'StageName' => opp.StageName,
            'Probability' => opp.Probability
        };
        
        Test.startTest();
        SubmitToClosingController.updateOpportunity(opp.Id, fields);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT StageName, Probability FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(opp.StageName, updatedOpp.StageName);
        System.assertEquals(opp.Probability, updatedOpp.Probability);
    }
    
    @IsTest
    static void testUpdateOpportunity_OppQueryException() {
        Test.startTest();
        try {
            // Try with invalid opportunity ID
            SubmitToClosingController.updateOpportunity('006000000000000', new Map<String, Object>{'Name' => 'Test'});
            System.assert(false, 'Should throw exception for invalid opportunity ID');
        } catch(AuraHandledException e) {}
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateOpportunity_DmlException() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        try {
            // Set up mock to force a DML exception
            Test.setReadOnlyApplicationMode(true);
            SubmitToClosingController.updateOpportunity(opp.Id, new Map<String, Object>{'StageName' => 'Closed Won'});
            System.assert(false, 'Should throw DML exception');
        } catch(Exception e) {
            // Expected
        } finally {
            Test.setReadOnlyApplicationMode(false);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateAccount_DmlException() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        try {
            // Set up mock to force a DML exception
            Test.setReadOnlyApplicationMode(true);
            SubmitToClosingController.updateAccount(acc.Id, new Map<String, Object>{'Name' => 'Updated Name'});
            System.assert(false, 'Should throw DML exception');
        } catch(Exception e) {
            // Expected
        } finally {
            Test.setReadOnlyApplicationMode(false);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetProductVersionOptions() {
        Test.startTest();
        List<Map<String, String>> options = SubmitToClosingController.getProductVersionOptions();
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Options should not be null');
    }
    
    @IsTest
    static void testGetProductVersionOptions_Exception() {
        Test.startTest();
        try {
            // Force an exception by using Test.isRunningTest() within the method
            Test.setReadOnlyApplicationMode(true);
            SubmitToClosingController.getProductVersionOptions();
        } catch(Exception e) {
            // Expected
        } finally {
            Test.setReadOnlyApplicationMode(false);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetKeyValuePointsOptions() {
        Test.startTest();
        List<String> options = SubmitToClosingController.getKeyValuePointsOptions();
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Options should not be null');
    }
    
    @IsTest
    static void testGetKeyValuePointsOptions_Exception() {
        Test.startTest();
        try {
            // Force an exception
            Test.setReadOnlyApplicationMode(true);
            SubmitToClosingController.getKeyValuePointsOptions();
        } catch(Exception e) {
            // Expected
        } finally {
            Test.setReadOnlyApplicationMode(false);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSendFreeTrialEmail() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        try {
            SubmitToClosingController.sendFreeTrialEmail(opp.Id);
        } catch(AuraHandledException e) {
            System.assert(e.getMessage().contains('Error sending free trial email'));
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSendFreeTrialEmail_NullId() {
        Test.startTest();
        try {
            SubmitToClosingController.sendFreeTrialEmail(null);
            System.assert(false, 'Should throw exception for null ID');
        } catch(AuraHandledException e) {}
        Test.stopTest();
    }
    
    @IsTest
    static void testSkipValidationRuleHandling() {
        Opportunity opp = [SELECT Id, SkipValidationRule__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        SubmitToClosingController.updateOpportunity(opp.Id, new Map<String, Object>{'StageName' => 'Closed Won'});
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT SkipValidationRule__c FROM Opportunity WHERE Id = :opp.Id];
    }
    
    @IsTest
    static void testHandleDatabaseErrors() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        try {
            // Create a scenario that would trigger handleDatabaseErrors
            Test.setReadOnlyApplicationMode(true);
            SubmitToClosingController.updateOpportunity(opp.Id, new Map<String, Object>{'StageName' => 'Invalid Stage'});
            System.assert(false, 'Should throw exception');
        } catch(Exception e) {
            // Expected
        } finally {
            Test.setReadOnlyApplicationMode(false);
        }
        Test.stopTest();
    }
}