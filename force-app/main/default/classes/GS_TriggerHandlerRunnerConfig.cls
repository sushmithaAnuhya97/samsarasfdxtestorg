/**
 * Created by vikasmishra on 2021-08-16.
 */

public with sharing class GS_TriggerHandlerRunnerConfig {
    static Map<String, String> MAP_OF_DEFAULT_HANDLERS_BY_OBJECT = new Map<String, String>{
            'Account' => 'GS_AccountTriggerHandler',
            'Contact' => 'ContactTriggerHandler',
            'Opportunity' => 'OpportunityTriggerHandlerContext',
            'SBQQQuote' => 'GS_SBQQQuoteTriggerHandler',
            'OpportunityLineItem' => 'OpportunityLineItemTriggerHandler',
            'Task' => 'TaskTriggerHandler',
            'InternalFinanceRequest' => 'InternalFinanceRequestTriggerHandler',
            'OpportunitySplit' => 'OpportunitySplitTriggerHandler',
            'Product2' => 'Product2TriggerHandler',
            'Customer360' => 'Customer360TriggerHandler',
            'Lead' => 'LeadTriggerHandler',
            'RequestTracker' => 'RequestTrackerTriggerHandler',
            'CustomEnrichedData' => 'CustomEnrichedDataTriggerHandler',
            'SBQQQuoteLine' => 'SBQQQuoteLineTriggerHandler',
            'OrderItem' => 'OrderItemTriggerHandler',
            'ShippingAddress' => 'ShippingAddressHandler',
            'PartnerRegistration' => 'PartnerRegistrationHandler'
    };
    public static boolean oppNewTrigger = false ; 
   //  add it in new test class GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
 
    public TriggerHandler createHandler(String sobjectName){
        //SamsaraAuditToggleMdtSelector thisSamsaraAuditToggleMdtSelector = new SamsaraAuditToggleMdtSelector();
		/*if(Test.isRunningTest() && sobjectName=='Opportunity'){
            if(!GS_TriggerHandlerRunnerConfig.oppNewTrigger){
             	//insert new Global_Automation_Settings__c(SetupOwnerId =UserInfo.getUserId() ,Name = 'Test_Automation_Settings',Allow_Handler_Selection__c = false);
            	GS_TriggerHandlerRunnerConfig.MAP_OF_DEFAULT_HANDLERS_BY_OBJECT.put('Opportunity','OpportunityTriggerHandler');   
            }
            Type type = Type.forName(MAP_OF_DEFAULT_HANDLERS_BY_OBJECT.get(sobjectName));
        	return (TriggerHandler) type.newInstance();
        }*/
        
        if (!GAS_TriggerToggle.triggerStatus(sobjectName)) return new NoTriggerHandler();

        if(GAS_TriggerToggle.allowTriggerHandlerSelection()){
            Type type = Type.forName(new SamsaraAuditToggleMdtSelector().getInstanceByDeveloperName(sobjectName).Trigger_Handler__c);
            return (TriggerHandler) type.newInstance();
        }
        Type type = Type.forName(MAP_OF_DEFAULT_HANDLERS_BY_OBJECT.get(sobjectName));
        return (TriggerHandler) type.newInstance();
    }

    public class NoTriggerHandler extends TriggerHandler{}

    // Flavio - Logic to print any changes to the record. This is a temporary logic to debug the Renewal Forecasting timeout issue
    /* public static void printChanges(List<SObject> newRecordsList, List<SObject> oldRecordsList){
        // testing
        //if (true) return;
        try{
            String prefix = '#CHANGES# ';
            String debugFormat = '{0} Field: {1} {4} To: {2} {4} From: {3}';
            
            // Find out the object
            SObject record = newRecordsList[0];
            Schema.DescribeSObjectResult sobjectDescribe = record.getSObjectType().getDescribe();
            
            System.debug(prefix+' Changes for '+sobjectDescribe.getLabel());

            if (oldRecordsList == null || !Trigger.isUpdate){
                System.debug(String.format('{0} IS NOT UPDATE: Insert({1}) Delete({2}) Undelete({3}) Context({4})', new List<Object>{
                    prefix,
                    Trigger.isInsert,
                    Trigger.isDelete,
                    Trigger.isUndelete,
                    (Trigger.isBefore ? 'BEFORE' : 'AFTER')
                }));
                System.debug('#########');
                return;
            }

            SObject oldRecord = oldRecordsList[0];
            for (String fieldName : sobjectDescribe.fields.getMap().keySet()){
                // Is Changed?
                if (record.get(fieldName) != oldRecord.get(fieldName)){
                    System.debug(String.format(debugFormat, new List<Object>{
                        prefix,
                        fieldName,
                        record.get(fieldName),
                        oldRecord.get(fieldName),
                        '///'
                    }));
                }
            }

            System.debug('#########');
        }catch(Exception ex){
            System.debug('Failed to log changes: '+ex.getMessage()+' || '+ex.getStackTraceString());
        }
    } */

}