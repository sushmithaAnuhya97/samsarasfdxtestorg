/* 
 * Class Created: 07/03/19 - @author: Harsha
 * 7/11/20 Harsha - (GTMS-1307) afterUpdate (Removed the deprecated method)
 * March-6-2023 Rajesh - GTMS-11201 Renewals phase2.0 changes
 * June-21-2023 Rajesh GTMS-13039 Added method call to setIsACV
 * April-02-2025 Rushikesh GTMS-26503 Added method call to preventProductAdditionToProtectedGroups
 */  
public class SBQQQuoteLineTriggerHandler extends TriggerHandler{
    @TestVisible private static Map<String,Integer> methodsCalled = new Map<String,Integer>();
    @TestVisible private static Integer maxRuns = 2;
                 private Map<Id, SBQQ__QuoteLine__c> oldSbqqQuoteLineMap;
                 private Map<Id, SBQQ__QuoteLine__c> newSbqqQuoteLineMap;
                 private List<SBQQ__QuoteLine__c> newSbqqQuoteLineList;
                 private List<SBQQ__QuoteLine__c> oldDeleteQuoteLineList;
                 private SBQQQuoteLineHelper sbqqQuoteLineHelper;
    
    public static Boolean bypassQuoteLineMethod = false; //GTMS-26503
    
    
    public SBQQQuoteLineTriggerHandler(){
        sbqqQuoteLineHelper = new SBQQQuoteLineHelper();
        this.oldSbqqQuoteLineMap = (Map<Id, SBQQ__QuoteLine__c>) Trigger.oldMap;
        this.newSbqqQuoteLineMap = (Map<Id, SBQQ__QuoteLine__c>) Trigger.newMap;
        this.newSbqqQuoteLineList = (List<SBQQ__QuoteLine__c>) Trigger.new;
        this.oldDeleteQuoteLineList=(List<SBQQ__QuoteLine__c>) Trigger.old;
    }
    
     public override void beforeInsert() {
        System.debug('TriggerHandler beforeInsert Start');
        sbqqQuoteLineHelper.quoteLineBeforeInsertOperations(oldSbqqQuoteLineMap, newSbqqQuoteLineList);
        sbqqQuoteLineHelper.setIsACV(newSbqqQuoteLineList); // GTMS-13039
        sbqqQuoteLineHelper.setACV(newSbqqQuoteLineList);
        if(!FlexCnRTriggerBypass__c.getInstance().Bypass_Sync_and_Flag_Reset_Logic__c && bypassQuoteLineMethod == false){
            sbqqQuoteLineHelper.preventProductAdditionToProtectedGroups(newSbqqQuoteLineList);//GTMS-26503
        }
    }
    
    public override void afterInsert(){
      System.debug('TriggerHandler afterInsert Start');
      

      if( timesCalled('afterInsert') < maxRuns ) { //GTMS-11201
           addCall('afterInsert');
           //sbqqQuoteLineHelper.setACV(newSbqqQuoteLineList);
        }
    }

    public override void beforeUpdate(){
        System.debug('TriggerHandler beforeUpdate Start');
        sbqqQuoteLineHelper.webStoreRenewalsMaximumDiscount(newSbqqQuoteLineList); // GTMS-21125 
       if( timesCalled('beforeUpdate') < maxRuns ) {
           addCall('beforeUpdate');
           sbqqQuoteLineHelper.quoteLineBeforeUpdateOperations(oldSbqqQuoteLineMap, newSbqqQuoteLineMap, newSbqqQuoteLineList);
           sbqqQuoteLineHelper.setIsACV(newSbqqQuoteLineList); // GTMS-13039 
           sbqqQuoteLineHelper.setACV(newSbqqQuoteLineList);
           if(System.Label.quoteLineValidationCheck.equalsIgnoreCase('true')){	
               sbqqQuoteLineHelper.populateStatusPLForRenewalsValidation(newSbqqQuoteLineList);//GTMS-22224
           }
        }
    }

    public override void afterUpdate(){
        System.debug('TriggerHandler afterUpdate Start');
      //if( timesCalled('afterUpdate') < maxRuns ) { //GTMS-11201
           addCall('afterUpdate');  
           //sbqqQuoteLineHelper.setACV(newSbqqQuoteLineList);
        //}
    }
    public override void beforeDelete() {
        sbqqQuoteLineHelper.beforeDeleteOperations(oldDeleteQuoteLineList);
       RebateLogicHandler rebateLogicHandler = new RebateLogicHandler();
       rebateLogicHandler.validateRebateBuyoutLineDeletion(oldDeleteQuoteLineList);
    }    
    //Helper methods to avoid recursion
    public static void resetAll() {
        methodsCalled = new Map<string,integer>();   
    }
    
    public static integer timesCalled(String input) {         
        if (!methodsCalled.containsKey(input)) {
            return 0;    
        } else {
            return methodsCalled.get(input);
        }
    }

    public static integer addCall(String input) { 
        if (!methodsCalled.containsKey(input)) {
            methodsCalled.put(input, 1);   
        } else {
            Integer i = methodsCalled.get(input) + 1;
            methodsCalled.put(input,i);
        }  

        return methodsCalled.get(input);
    }
}