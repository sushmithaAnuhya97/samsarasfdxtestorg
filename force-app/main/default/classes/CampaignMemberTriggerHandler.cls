/*
 * August 16th, 2022 Saiteja Kolishetti (GTMS-6439) Added Static variables(methodsCalled,maxRuns) && 
 * methods(timesCalled, addCall, resetAll) to turn off trigger when called from Task(GS_TaskService)
*/

public class CampaignMemberTriggerHandler extends TriggerHandler{
  private Map<Id, CampaignMember> oldCampaignMemberMap;
  private Map<Id, CampaignMember> newCampaignMemberMap;
  private List<CampaignMember> newCampaignMemberList;
  Slack_Enabled_Campaign_Type__mdt slackCampaignTypes = [SELECT Enabled__c, Campaign_Type_List__c, afterInsert_Slack__c FROM Slack_Enabled_Campaign_Type__mdt LIMIT 1][0];
  public static Boolean updateAlreadyRan = false;
  public static Boolean insertAlreadyRan = false;
  public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
      Contact.SObjectType,
      Account.SObjectType
  };
  private UnitOfWork uow ;
    
    // use to manually turn on / off trigger from a test method
    @TestVisible private static Integer maxRuns = 1;
    @TestVisible private static Map<String, Integer> methodsCalled = new Map<String, Integer>();
    
  public CampaignMemberTriggerHandler() {
    this.oldCampaignMemberMap = (Map<Id, CampaignMember>) Trigger.oldMap;
    this.newCampaignMemberMap = (Map<Id, CampaignMember>) Trigger.newMap;
    this.newCampaignMemberList = (List<CampaignMember>) Trigger.new;
    DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
  }

  public override void beforeInsert() {
        if (timesCalled('beforeInsert') < maxRuns) {
            CampaignMemberHelper.beforeUpdateInsert(oldCampaignMemberMap, newCampaignMemberList);
            /*if (slackCampaignTypes.Enabled__c && !slackCampaignTypes.afterInsert_Slack__c) {
                system.debug(LoggingLevel.INFO, 'IS FUTURE:'+System.isFuture());
                CampaignMemberHelper.postInboundSlackMessage(newCampaignMemberList);
            }*/
            CampaignMemberHelper.workflowConversionProcess(newCampaignMemberList, oldCampaignMemberMap);
          CampaignMemberHelper.handleCampaignMemberInsert(newCampaignMemberList);  
          CampaignMemberHelper.setLeadScopeCopy(newCampaignMemberList); //added as part of GTMS-24448
        }
  }

  public override void beforeUpdate() {
        if (timesCalled('beforeUpdate') < maxRuns) {
            CampaignMemberHelper.beforeUpdateInsert(oldCampaignMemberMap, newCampaignMemberList);
            CampaignMemberHelper.workflowConversionProcess(newCampaignMemberList, oldCampaignMemberMap);
            CampaignMemberHelper.setLeadScoreIfCampaignMemberStatusIsResponded(oldCampaignMemberMap, newCampaignMemberList); // added as part of GTMS-25400
            addCall('beforeUpdate');
        }  
  }

    public override void afterUpdate() {
        if (timesCalled('afterUpdate') < maxRuns) {
            CampaignMemberHelper.calculateAllRollUpsToContact(newCampaignMemberList, oldCampaignMemberMap);
            CampaignMemberHelper.webSiteVisitorLead(newCampaignMemberMap.keySet());
            addCall('afterUpdate');
        }
  }

  public override void afterInsert() {
        if (timesCalled('afterInsert') < maxRuns) {
            CampaignMemberHelper.calculateAllRollUpsToContact(newCampaignMemberList, null);
            CampaignMemberHelper.webSiteVisitorLead(newCampaignMemberMap.keySet());
            /*if (slackCampaignTypes.Enabled__c && slackCampaignTypes.afterInsert_Slack__c) {
                CampaignMemberHelper.postInboundSlackMessage(newCampaignMemberList);
            }*/
        }
  }

  public override void afterDelete() {
    CampaignMemberHelper.calculateAllRollUpsToContact(oldCampaignMemberMap.values(), null);

  }
  //GTMS-27353 Start 
  public override void beforeDelete() {
    CampaignMemberHelper.restrictedProfileDeleteAccess(oldCampaignMemberMap.values());

  }
  //GTMS-27353 End 
	
  public override void afterUndelete() {
    CampaignMemberHelper.calculateAllRollUpsToContact(newCampaignMemberList, null);

  }

  public override void publishDMLs() {
    uow = DMLWrapper.uow;
    DMLWrapper.publishDML(uow);
  }
    
    /*** Helpers for debugging & preventing recursion ***/

    public static void resetAll() {
        methodsCalled = new Map<string, integer>();
    }


    public static integer timesCalled(String Input) {

        if (!methodsCalled.containsKey(Input)) {
            return 0;
        } else {
            return methodsCalled.get(Input);
        }

    }

    public static integer addCall(String Input) {

        if (!methodsCalled.containsKey(Input)) {
            methodsCalled.put(input, 1);
        } else {
            Integer i = methodsCalled.get(input) + 1;
            methodsCalled.put(input, i);
        }

        return methodsCalled.get(input);
    }
}