/**
 * description: Test Class for Global Automation Settings (GAS) Trigger Toggle
 * author: Patrick Fischer, Groundswell Cloud solutions, Inc.
 * date: 2021-04-10
 */
@IsTest
public class GAS_TriggerToggleTest {
    
    @isTest
    private static void triggerStatusWithSkipAutomationSetting() {
        
        // Disable Triggers via Custom Setting here
        insert new Global_Automation_Settings__c(Skip_Trigger__c = true);

        Test.startTest();
        Boolean triggerIsEnabled = GAS_TriggerToggle.triggerStatus('');
        Test.stopTest();
        
        System.assert(!triggerIsEnabled, 'Expecting trigger to be disabled due to custom setting');
    }
    
    @isTest
    private static void triggerStatusWithSettingActive() {

        // Keep Triggers active via Custom Setting - set to false
        insert new Global_Automation_Settings__c(Skip_Trigger__c = false);

        Test.startTest();
        Boolean triggerIsEnabled = GAS_TriggerToggle.triggerStatus(null);
        Test.stopTest();
        
        System.assert(triggerIsEnabled, 'Expecting trigger to be active/execute');
    }
    
    @isTest
    private static void triggerStatusWithDefaultSetting() {

        Test.startTest();
        Boolean triggerIsEnabled = GAS_TriggerToggle.triggerStatus('');
        Test.stopTest();
        
        System.assert(triggerIsEnabled, 'Expecting trigger to be active/execute');
    }
    
    @isTest
    private static void triggerStatusSkipSpecificTrigger() {

        // Keep Triggers active via Custom Setting - set to false
        insert new Global_Automation_Settings__c(Skip_Trigger__c = false, Skip_Specific_Triggers__c = 'SBQQQuote OpportunityLineItem');

        Test.startTest();
        Boolean triggerIsEnabled_opp = GAS_TriggerToggle.triggerStatus('Opportunity');
        Boolean triggerIsEnabled_oli = GAS_TriggerToggle.triggerStatus('OpportunityLineItem');
        Test.stopTest();
        
        System.assert(triggerIsEnabled_opp, 'Expecting trigger to be active/execute');
        System.assert(!triggerIsEnabled_oli, 'Expecting trigger to be active/execute');
    }
    
    @isTest
    private static void testAllowTriggerHandlerSelection() {

        // Keep Triggers active via Custom Setting - set to false
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true, Skip_Trigger__c = false, Skip_Specific_Triggers__c = 'Opportunity');

        Test.startTest();
        Boolean allowsTriggerSelection = GAS_TriggerToggle.allowTriggerHandlerSelection();
        Test.stopTest();
        
        System.assert(allowsTriggerSelection, 'Expecting trigger to not be selectable');
    }
    
    @isTest
    private static void coverTriggerHandlerRunnerConfig() {

        new GS_TriggerHandlerRunnerConfig().createHandler('Opportunity');

        // Keep Triggers active via Custom Setting - set to false
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true, Skip_Trigger__c = false, Skip_Specific_Triggers__c = 'Opportunity');
        
        Test.startTest();
        // Clear custom settings cache
        Global_Automation_Settings__c setting = [SELECT Id, Allow_Handler_Selection__c FROM Global_Automation_Settings__c];
        
        new GS_TriggerHandlerRunnerConfig().createHandler('Opportunity');
        Test.stopTest();
    }
}