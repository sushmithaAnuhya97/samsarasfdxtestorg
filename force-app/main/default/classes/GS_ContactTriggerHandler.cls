/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 12, 2021
*
* @description : This class will be responsible for handling all Contact Service Operations
* SFA-14
*
**/
public class GS_ContactTriggerHandler extends TriggerHandler {
    private Map<Id, Contact> oldContactMap;
    private Map<Id, Contact> newContactMap;
    private List<Contact> newContactList;
    private List<Contact> oldContactList;
    static Boolean triggerSettingFlag = false;
    static Trigger_Setting__mdt thisTrigger;
    public static Boolean alreadyRanUpdate = false;
    public static Boolean alreadyRanInsert = false;
    public String dncExceptions = System.Label.DNC_Exceptions;
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Account.SObjectType,
            Contact.SObjectType,
            CampaignMember.SobjectType,
            ADR_Transfer_Log__c.SObjectType,
            Async_Request__c.SobjectType
            };
                Private UnitOfWork uow ;
    Private GS_ContactService contactService;
    Private GS_ContactCheckOptOutDupeService contactDupeService;
    public GS_ContactTriggerHandler() {
        this.oldContactMap = (Map<Id, Contact>) Trigger.oldMap;
        this.newContactMap = (Map<Id, Contact>) Trigger.newMap;
        this.newContactList = (List<Contact>) Trigger.new;
        this.oldContactList = (List<Contact>) Trigger.old;
        contactService = new GS_ContactService();
        
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        //As the trigger is being called in recursion, in order to avoid running the query again and again added the static variables. - Harsha
        //Need to debug the recursive behaviour though when i get a chance.
        if (triggerSettingFlag == false) {
            thisTrigger = new List<Trigger_Setting__mdt>([
                SELECT  BeforeInsert__c,
                AfterInsert__c,
                BeforeUpdate__c, 
                AfterUpdate__c 
                FROM Trigger_Setting__mdt 
                WHERE MasterLabel = 'Contact' LIMIT 1])[0];
            triggerSettingFlag = true;
        }
    }
    
    public override void beforeInsert() {
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Contact Trigger Before Insert');
            DiagnosticsInstrumentation.push('contactBeforeInsert');
            if(thisTrigger.BeforeInsert__c) {
                if (!dncExceptions.contains(UserInfo.getUserId())) {
                    contactDupeService = new GS_ContactCheckOptOutDupeService();
                    contactDupeService.checkForOptOutDupes(newContactList, oldContactMap);
                }
                contactService.handleBeforeOperations(newContactList, oldContactMap, Trigger.isUpdate);
            }
            DiagnosticsInstrumentation.pop();
        }catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Contact Trigger Before Insert::', new SamsaraLoggerObjectMVP(
                ex, newContactList
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
    
    public override void afterInsert() {
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Contact Trigger After Insert');
            DiagnosticsInstrumentation.push('contactAfterInsert');
            Boolean async = (System.isFuture() || System.isScheduled() || System.isQueueable() || System.isBatch()) ? true : false;
            
            if (thisTrigger.AfterInsert__c) {
                contactService.handleAfterOperations(newContactList, newContactMap, oldContactMap ,Trigger.IsUpdate, async);
            }
            DiagnosticsInstrumentation.pop();
        }catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Contact Trigger Before Insert::', new SamsaraLoggerObjectMVP(
                ex, newContactList
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
    
    public override void beforeUpdate() {
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Contact Trigger Before Update');
            DiagnosticsInstrumentation.push('contactBeforeUpdate');
            if(thisTrigger.BeforeUpdate__c) {
                if(!dncExceptions.contains(UserInfo.getUserId())){
                    contactDupeService = new GS_ContactCheckOptOutDupeService();
                    contactDupeService.checkForOptOutDupes(newContactList, oldContactMap);
                }
                contactService.handleBeforeOperations(newContactList, oldContactMap, Trigger.isUpdate);
            }
            DiagnosticsInstrumentation.pop();
        }
        catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Contact Trigger Before Update::', new SamsaraLoggerObjectMVP(
                ex, newContactList
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
    
    public override void afterUpdate() {
        try {
            thisSamsaraLoggerService.logger.logTrace('Entering in Contact After Trigger Update');
            DiagnosticsInstrumentation.push('contactAfterUpdate');
            Boolean async = (System.isFuture() || System.isScheduled() || System.isQueueable() || System.isBatch()) ? true : false;
            if (thisTrigger.AfterUpdate__c) {
                if (!alreadyRanUpdate) {
                    contactService.handleAfterOperations(newContactList, newContactMap, oldContactMap, Trigger.IsUpdate, async);
                    //  Moving to FLOW
                    //  ContactHelper.hotTransfer(oldContactMap, newContactMap, newContactList);
                    
                    //NOW HERE
                    alreadyRanUpdate = true;
                }
                
                if(async){
                    new GS_Contact_ResetFlagService().resetFlags(newContactList, GS_ContactService.yoyoContactMap, Trigger.isUpdate, async);  
                }else{
                    new GS_Contact_ResetFlagService().resetFlagsFuture(newContactList, GS_ContactService.yoyoContactMap, Trigger.isUpdate, async);  
                }
            }
            
            // WorkflowProcesses
            new GS_ContactCampaignToAddService().workflowConversionProcess(newContactList, oldContactMap);
            
            //Taking rollup calculation out of recursion check
            //GTMS-2128 
            GS_ContactRollupsToAccount gsContactRollupAccountObj = new GS_ContactRollupsToAccount(this.newContactList, this.oldContactMap);
            gsContactRollupAccountObj.calculateRollUpsToAccount(); 
            
            DiagnosticsInstrumentation.pop();
        }
        catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Contact Trigger After Update::', new SamsaraLoggerObjectMVP(
                ex, newContactList
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
    
    /**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-09-08
* Not yet deployed for Production
* GTMS-1471 
*/
    public override void afterdelete() {
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Contact After Delete Trigger ');
            contactService.handleAfterDeleteOperations(oldContactMap.values(), null);
        }
        catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Contact Trigger After Delete::', new SamsaraLoggerObjectMVP(
                ex, oldContactMap.keySet()
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
    
    /**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-09-08
* Not yet deployed for Production
* GTMS-1471
*/
    public override void afterUndelete (){
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in Contact After UnDelete Trigger ');
            contactService.handleAfterUndeleteOperations(newContactList, null);
        }
        catch (Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in Contact Trigger After UnDelete::', new SamsaraLoggerObjectMVP(
                ex, newContactList
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
    
    /**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-09-09
* Not yet deployed for Production
* GTMS-1471
*/
    public override void publishDMLs() {
        thisSamsaraLoggerService.logger.logTrace('Exiting Contact Trigger Context');
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
}