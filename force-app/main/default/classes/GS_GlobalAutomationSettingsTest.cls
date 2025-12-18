@isTest
public with sharing class GS_GlobalAutomationSettingsTest {
    
    public static void createAutomationTestSetting(){
        insert new Global_Automation_Settings__c(
            SetupOwnerId = UserInfo.getUserId(),
            Allow_Handler_Selection__c = true
        );
    }
}