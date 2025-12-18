/**
 * description: Global Automation Settings (GAS) Trigger Toggle to include in your trigger framework
 * author: Patrick Fischer, Groundswell Cloud solutions, Inc.
 * date: 2021-04-10
 */
public with sharing class GAS_TriggerToggle {

    /**
     * @description To check if the trigger is deactivated or not
     * @return (boolean) true if triggers are enabled, false if disabled
     */
    public static Boolean triggerStatus(String sobjectName){

        Boolean isEnabled = true;
        
        Global_Automation_Settings__c setting = Global_Automation_Settings__c.getInstance();
        if(setting != null && (setting.Skip_Trigger__c || shouldSkipSpecificTrigger(setting, sobjectName))) {
            isEnabled = false;
        }
        
        return isEnabled;
    }

    private static Boolean shouldSkipSpecificTrigger(Global_Automation_Settings__c setting, String sobjectName){
        return (
            String.isBlank(setting.Skip_Specific_Triggers__c)
        ? 
            false
        :
            Pattern.matches('.*?(?:\\s|^)'+sobjectName+'(?:\\s|$).*?', setting.Skip_Specific_Triggers__c)
        );
    }

    public static Boolean allowTriggerHandlerSelection(){
        Boolean allowHandlerSelection = false;
        system.debug('Allow handler Selection@@'+Global_Automation_Settings__c.getInstance());
        if(Global_Automation_Settings__c.getInstance()?.Allow_Handler_Selection__c) {
            allowHandlerSelection = true;
        }
        return allowHandlerSelection;
    }

}