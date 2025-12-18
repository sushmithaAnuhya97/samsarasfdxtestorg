/**********************************************************************
Name: PartnerRegistrationHandler
Purpose: This class will contains method that will handle the trigger context for partner registration                                                   

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Aug-21        INITIAL DEVELOPMENT - GTMS-28939

***********************************************************************/
public class PartnerRegistrationHandler extends TriggerHandler {
	private Map<Id, Partner_Registration__c> oldPartnerRegistrationMap;
    private Map<Id, Partner_Registration__c> newPartnerRegistrationMap;
    private List<Partner_Registration__c> newPartnerRegistrationList;
    private List<Partner_Registration__c> oldDeletePartnerRegistrationList;
    public static Boolean alreadyUpdateRan = false;
    public static Boolean alreadyInsertRan = false;
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{Partner_Registration__c.SobjectType};
    Private UnitOfWork uow;
    
    public PartnerRegistrationHandler() {
        this.oldPartnerRegistrationMap = (Map<Id, Partner_Registration__c>) Trigger.oldMap;
        this.newPartnerRegistrationMap = (Map<Id, Partner_Registration__c>) Trigger.newMap;
        this.newPartnerRegistrationList = (List<Partner_Registration__c>) Trigger.new;
        this.oldDeletePartnerRegistrationList = (List<Partner_Registration__c>) Trigger.old;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }
    
    public override void beforeInsert() {
        if (!alreadyInsertRan) {
            alreadyInsertRan = true;
        }
    }
    
    public override void beforeUpdate() {
        if (!alreadyUpdateRan) {
            PartnerRegistrationHelper.handleBeforeUpdate(newPartnerRegistrationList, oldPartnerRegistrationMap);
            PartnerRegistrationHelper.updateSLADueDate(newPartnerRegistrationList, oldPartnerRegistrationMap);
            alreadyUpdateRan = true;
        }
    }
}