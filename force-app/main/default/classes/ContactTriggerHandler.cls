public class ContactTriggerHandler extends TriggerHandler {
  private Map<Id, Contact> oldContactMap;
  private Map<Id, Contact> newContactMap;
  private List<Contact> newContactList;
  static Boolean triggerSettingFlag = false;
  static Trigger_Setting__mdt thisTrigger;
  public static Boolean alreadyRanUpdate = false;
  public static Boolean alreadyRanInsert = false;
  public String dncExceptions = System.Label.DNC_Exceptions;
  public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
      Account.SObjectType,
      Contact.SObjectType,
      CampaignMember.SobjectType,
      ADR_Transfer_Log__c.SObjectType
  };
  Private UnitOfWork uow ;
  public ContactTriggerHandler() {
    this.oldContactMap = (Map<Id, Contact>) Trigger.oldMap;
    this.newContactMap = (Map<Id, Contact>) Trigger.newMap;
    this.newContactList = (List<Contact>) Trigger.new;
    DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    //As the trigger is being called in recursion, in order to avoid running the query again and again added the static variables. - Harsha
    //Need to debug the recursive behaviour though when i get a chance.
    if (triggerSettingFlag == false) {
      thisTrigger = new List<Trigger_Setting__mdt>([
          SELECT   BeforeInsert__c,
              AfterInsert__c,
              BeforeUpdate__c, 
              AfterUpdate__c 
          FROM Trigger_Setting__mdt 
          WHERE MasterLabel = 'Contact' LIMIT 1])[0];
      triggerSettingFlag = true;
    }
  }

  public override void beforeInsert() {
    DiagnosticsInstrumentation.push('contactBeforeInsert');
    if(thisTrigger.BeforeInsert__c) {
      if (!dncExceptions.contains(UserInfo.getUserId())) {
        ContactHelper.checkForOptOutDupes(newContactList, oldContactMap);
      }
      ContactHelper.beforeInsertUpdate(oldContactMap, newContactList);
            ContactHelper.concatenatePreferenceField(oldContactMap, newContactList);
          ContactHelper.populateAdrAssignment(newContactList);

      // consolidated contact
      ContactHelper.ensureOwnerMatchesAccount(newContactList); // Process Builder - Mass Action: Account Owner equals Contact Owner (Invocable)

      // WorkflowProcesses
      //ContactHelper.workflowConversionProcess(newContactList, oldContactMap);
    }
    DiagnosticsInstrumentation.pop();
  }

  public override void afterInsert() {
    DiagnosticsInstrumentation.push('contactAfterInsert');
    Boolean async = (System.isFuture() || System.isScheduled() || System.isQueueable() || System.isBatch()) ? true : false;

    if (thisTrigger.AfterInsert__c) {
      ContactHelper.stampLawfulBasisOnContactCreate(newContactMap); //DEPRECATE
            //GTMS-3485
      //ContactHelper.customerReferrals(newContactList, oldContactMap);
      ContactHelper.newInboundOrChannel(newContactMap, oldContactMap);
      //ReferralLeadLogic.referralLeadLogicCheck(oldContactMap, newContactMap, async);
      ContactHelper.calculateAllRollUpsToAccount(newContactList, null);
      ContactHelper.updateAccounts();
            ContactHelper.sendSurveyMail(newContactList);//GTMS-8518
      ContactHelper.validateContactEmailPartnerUser(newContactList); // added for GTMS-13853
      if (!async) {
        CampaigntoAdd.CampaignMemberCheckFuture(newContactMap, ContactHelper.manualSource, ContactHelper.yoyoContactMap, System.now());
        ContactHelper.updateAccountDemoDateFuture(newContactList);
      } else {
        CampaigntoAdd.CampaignMemberCheck(newContactMap, ContactHelper.manualSource, ContactHelper.yoyoContactMap, System.now());
      }

      // consolidated contact
      ContactHelper.resetFlags(newContactList, Trigger.isUpdate);
      //ContactHelper.workflowConversionProcess( newContactList, oldContactMap);
      ContactHelper.updateContacts();
    }
    DiagnosticsInstrumentation.pop();
  }

  public override void beforeUpdate() {
    DiagnosticsInstrumentation.push('contactBeforeUpdate');
    if(thisTrigger.BeforeUpdate__c) {
      if(!dncExceptions.contains(UserInfo.getUserId())){
        ContactHelper.checkForOptOutDupes(newContactList, oldContactMap);
      }
      ContactHelper.beforeInsertUpdate(oldContactMap, newContactList);
            ContactHelper.concatenatePreferenceField(oldContactMap, newContactList);
            ContactHelper.sendSurveyMail(newContactList);//GTMS-8518
            ContactHelper.populateFuncLevel(newContactList,OldContactMap);//GTMS-13696
        	ContactHelper.updateOptoutFields(newContactList,OldContactMap);//GTMS-29989

      // consolidated contact
      ContactHelper.ensureOwnerMatchesAccount(newContactList, oldContactMap); // Process Builder - Mass Action: Account Owner equals Contact Owner (Invocable)

    }
    DiagnosticsInstrumentation.pop();
  }

  public override void afterUpdate() {
        system.debug('After update entering');
    DiagnosticsInstrumentation.push('contactAfterUpdate');
    Boolean async = (System.isFuture() || System.isScheduled() || System.isQueueable() || System.isBatch()) ? true : false;

    if (thisTrigger.AfterUpdate__c) {

      if (!alreadyRanUpdate) {
        ContactHelper.setAccountStatusFromContact(oldContactMap, newContactMap);
        ContactHelper.setAccountStatusFromContactInbound(oldContactMap,newContactMap);// Added as part of GTMS-25352
        //ContactHelper.hotTransfer(oldContactMap, newContactMap, newContactList); //GTMS-5742:Commenting out, as this logic has moved to flow
        ContactHelper.manuallyUnloadContact(oldContactMap, newContactMap, newContactList);
                //GTMS-3485
        //ContactHelper.customerReferrals(newContactList, oldContactMap);
        ContactHelper.newInboundOrChannel(newContactMap, oldContactMap);
        //ReferralLeadLogic.referralLeadLogicCheck(oldContactMap, newContactMap, async);

        if (!async) {
          CampaigntoAdd.CampaignMemberCheckFuture(newContactMap, ContactHelper.manualSource, ContactHelper.yoyoContactMap, System.now());
          ContactHelper.updateCampaignFieldsFuture(oldContactMap, newContactMap);
        }
        else{
          CampaigntoAdd.CampaignMemberCheck(newContactMap, ContactHelper.manualSource, ContactHelper.yoyoContactMap, System.now());
          ContactHelper.updateCampaignFields(oldContactMap, newContactMap);
        }
        // consolidated contact
        ContactHelper.updateAccountDemoDate(newContactList, oldContactMap);
        ContactHelper.demoDateChanges(newContactList, oldContactMap);
        ContactHelper.updateAccountBillingInfo(newContactList, oldContactMap);

        //NOW HERE
        alreadyRanUpdate = true;
      }

      ContactHelper.resetFlags(newContactList, Trigger.isUpdate);

    }

    // WorkflowProcesses
    ContactHelper.workflowConversionProcess(newContactList, oldContactMap);
    ContactHelper.updateContacts();

    //Taking rollup calculation out of recursion check
    //GTMS-2128
    ContactHelper.calculateAllRollUpsToAccount(newContactList, oldContactMap);
    ContactHelper.updateAccounts();

    DiagnosticsInstrumentation.pop();
  }

  /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-08
  * Not yet deployed for Production
  * GTMS-1471
    */
    public override void afterdelete() {
        ContactHelper.calculateAllRollUpsToAccount(oldContactMap.values(), null);
        ContactHelper.updateAccounts();
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-08
  * Not yet deployed for Production
  * GTMS-1471
    */
    public override void afterUndelete (){
    ContactHelper.calculateAllRollUpsToAccount(newContactList, null);
    ContactHelper.updateAccounts();
  }

  /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
  * Not yet deployed for Production
  * GTMS-1471
    */
  public override void publishDMLs() {
    uow = DMLWrapper.uow;
    DMLWrapper.publishDML(uow);
  }
}