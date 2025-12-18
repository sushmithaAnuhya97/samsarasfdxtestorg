/*
 * 04/15/20 Harsha - (GTMS-471): updateOpenChildOpportunityApprovedPayment (Renamed and commented out the method since its not relevant anymore)
 * 07/05/20 Harsha - (GTMS-858) updateOpenChildOpportunities (Commented out the method)
 * 08/12/20 Harsha - (GTMS-1464) beforeUpdate(Added beforeUpdate method call), afterUpdate(Added platformEvent call)
 */
public class AccountTriggerHandler extends TriggerHandler{
    private Map<Id, Account> oldAccountMap;
    private Map<Id, Account> newAccountMap;
    private List<Account> newAccountList;
    private List<Account> oldDeleteAccountList;
    public static Boolean alreadyRan = false;
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
            CS_Record__c.SObjectType,
            Contact.SObjectType,
            Account.SobjectType,
            AccountTeamMember.SobjectType
    };
    Private UnitOfWork uow ;
    public AccountTriggerHandler() {
        this.oldAccountMap = (Map<Id, Account>) Trigger.oldMap;
        this.newAccountMap = (Map<Id, Account>) Trigger.newMap;
        this.newAccountList = (List<Account>) Trigger.new;
        this.oldDeleteAccountList = (List<Account>) Trigger.old;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }

    public override void beforeInsert() {
        AccountHelper.beforeInsertUpdateOperations(oldAccountMap, newAccountList);
        //Groundswell : Nilesh Jain  - Changes done as a part of GTMS-2875 to merge account billing logic into beforeInsertUpdateOperations  method
        //AccountHelper.accountIndustryCheck(oldAccountMap, newAccountList);
    }
    
    public override void afterInsert() {
        AccountHelper.afterInsertOperations(oldAccountMap, newAccountList);
    }

    public override void beforeUpdate() {
        AccountHelper.beforeInsertUpdateOperations(oldAccountMap, newAccountList);
        //This method is merged into beforeInsertUpdateOperations Method.
        //AccountHelper.beforeUpdateOperations(oldAccountMap, newAccountList);
        //Groundswell : Nilesh Jain  - Changes done as a part of GTMS-2875 to merge account billing logic into beforeInsertUpdateOperations method
        //AccountHelper.accountIndustryCheck(oldAccountMap, newAccountList);
        //AccountHelper.populateBillingDetails(oldAccountMap, newAccountList);
    }


    public override void afterUpdate() {
        if(!alreadyRan){
            //AccountHelper.stampLawfulBasisOnAccountUpdate(newAccountList);
            AccountHelper.stampLawfulBasisAndCheckIfAccountNeedsCsmOrSeOnUpdate(oldAccountMap, newAccountList);
            //AccountHelper.updateOpenChildOpportunities(oldAccountMap, newAccountMap);
            //AccountHelper.updateContactOwner(newAccountList, oldAccountMap);
            alreadyRan = true;
        }
        AccountHelper.stampAccountInfoOnCsRecord(oldAccountMap, newAccountList);
        AccountHelper.createPlatformEvent();
    }

    public override void beforeDelete() {
        AccountHelper.beforeDeleteOperations(oldDeleteAccountList);
    }

    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
}