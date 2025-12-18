public class ContentVersionTriggerHandler extends TriggerHandler {
    private Map<Id, ContentVersion > oldPartnerRegistrationMap;
    private Map<Id, ContentVersion > newPartnerRegistrationMap;
    private List<ContentVersion > newPartnerRegistrationList;
    private List<ContentVersion > oldDeletePartnerRegistrationList;
    public static Boolean alreadyUpdateRan = false;
    public static Boolean alreadyInsertRan = false;
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{ContentVersion.SobjectType};
    Private UnitOfWork uow;

    public ContentVersionTriggerHandler() {
        this.oldPartnerRegistrationMap = (Map<Id, ContentVersion>) Trigger.oldMap;
        this.newPartnerRegistrationMap = (Map<Id, ContentVersion>) Trigger.newMap;
        this.newPartnerRegistrationList = (List<ContentVersion>) Trigger.new;
        this.oldDeletePartnerRegistrationList = (List<ContentVersion>) Trigger.old;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }
    
    public override void afterInsert() {
        ContentVersionHelper.syncContentVersion(newPartnerRegistrationList, newPartnerRegistrationMap);
        //ContentVersionEmailSender.sendContentVersionEmail(newPartnerRegistrationList, newPartnerRegistrationMap);
    }
}