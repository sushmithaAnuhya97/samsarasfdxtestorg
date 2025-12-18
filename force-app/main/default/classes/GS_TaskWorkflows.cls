/**
* Created By : Groundswell - Flavio Contini
* @Date February 03, 2022
*
* @description : This class will be responsible for handling all apex converted workflows execution for the Task object
*
**/
public class GS_TaskWorkflows {
    
    public static String USER_ROLE_NAME;
    private GS_TaskCacheService cacheService;

    public GS_TaskWorkflows(GS_TaskCacheService cache){
        this.cacheService = cache;
    }

    public void runInsertWorkflows(Task newTask){
        //this.copyOwnerRole(newTask);
        this.runUpdateWorkflows(null, newTask);
    }

    public void runUpdateWorkflows(Task oldTask, Task newTask){
        this.updateActivityType(newTask);
        this.updateNotesAfterCall(newTask);
        //this.copyOwnerRole(newTask);
        this.copyContactStatus(newTask);
        this.copyAccountStatus(oldTask, newTask);
        this.copyOpenOpptyRev(newTask);
    }

    // On insert/update
    // WF Activity Type
    public void updateActivityType(Task t){
        if (String.isNotBlank(t.Type)){
            t.Activity_Type__c = t.Type;
        }
    }

    // On insert
    // WF Copy Owner Role at time of task creation
    /*public void copyOwnerRole(Task t){
        //if (String.isBlank(t.Owner_Role_Copy__c)){
         if (!String.valueOf(t.OwnerId).startsWith('00G')) {   //GTMS-27296
            t.Owner_Role_Copy__c = this.getUserIdRoleName(t.OwnerId);
         } 
    }*/

    // On insert/update
    // WF Update Notes after Call
    public void updateNotesAfterCall(Task t){
        if (String.isNotBlank(t.Description)){
            t.Call_Notes__c = (t.Description.length() > 255 ? t.Description.left(252)+'...' : t.Description);
        }
    }

    // On insert/update
    // WF Account status copy rule
    public void copyAccountStatus(Task oldTask, Task newTask){
        Boolean wfCriteria = (
          (oldTask == null || oldTask.Related_Contact__c != newTask.Related_Contact__c)
        || String.isBlank(newTask.Account_Status_Copy__c)
        );
        if (wfCriteria && newTask.Related_Contact__c != null){
            Contact ctt = cacheService.getRelatedContactsMap().get(newTask.Related_Contact__c);
            if (ctt != null && ctt.AccountId != null) newTask.Account_Status_Copy__c = ctt.Account.Status__c;
        }
    }

    // On insert/update
    // WF Contact status copy rule
    public void copyContactStatus(Task t){
        if (String.isBlank(t.Contact_Status_Copy__c) && t.Related_Contact__c != null){
            Contact ctt = cacheService.getRelatedContactsMap().get(t.Related_Contact__c);
            if (ctt != null) t.Contact_Status_Copy__c = ctt.Status__c;
        }
    }

    // On insert/update
    public void copyOpenOpptyRev(Task t){
        if (t.Open_Oppty_Rev_Copy__c == null && t.Related_Contact__c != null){
            Contact ctt = cacheService.getRelatedContactsMap().get(t.Related_Contact__c);
            if (ctt != null
             && ctt.AccountId != null
             && ctt.Account.Total_Expected_Revenue_Currency__c != null
             && ctt.Account.Lifetime_Purchases_Currency__c != null
            ){
                t.Open_Oppty_Rev_Copy__c = ctt.Account.Total_Expected_Revenue_Currency__c - ctt.Account.Lifetime_Purchases_Currency__c;
            }
        }
    }

    /*private String getUserIdRoleName(Id assignedToId){
        if (String.isBlank(USER_ROLE_NAME)){
            //String roleId = UserInfo.getUserRoleId();
            if (String.isBlank(assignedToId)){
                USER_ROLE_NAME = '-';
            }else{
                String roleId = [SELECT UserRoleId FROM User WHERE Id = :assignedToId].UserRoleId;
                if (String.isNotBlank(roleId))
                	USER_ROLE_NAME = [SELECT Name FROM UserRole WHERE Id = :roleId].Name;
            }
        }

        return (USER_ROLE_NAME == '-' ? '' : USER_ROLE_NAME);
    }*/
}