public class UserTriggerHandler extends TriggerHandler {
    private Map<Id, User> oldUserMap;
    private Map<Id, User> newUserMap;
    private List<User> newUserList;

    public UserTriggerHandler() {
        this.oldUserMap = (Map<Id, User>) Trigger.oldMap;
        this.newUserMap = (Map<Id, User>) Trigger.newMap;
        this.newUserList = (List<User>) Trigger.new;
    }

    public override void beforeInsert(){
        UserHelper.beforeInsertUpdate(newUserList, oldUserMap);
    }

    public override void beforeUpdate(){
        UserHelper.beforeInsertUpdate(newUserList, oldUserMap);
    }

    
    public override void afterUpdate(){
        UserHelper.validatePartnerContactId(newUserMap);
        UserHelper.validatePartnerContactEmail(newUserMap);
        //UserHelper.deactivatedeleteRR(oldUserMap, newUserMap);
        //RRobin Mapping - future method
        UserHelper.UserFieldsPushtoWebstore(newUserList,oldUserMap);
        UserHelper.callPauseAssignment(oldUserMap, newUserMap);
    }
    //ZAK: GTMS-4935-AssetLibrary- Oct-12-2021
    public override void afterInsert(){
        UserHelper.validatePartnerContactId(newUserMap);
        UserHelper.validatePartnerContactEmail(newUserMap);
        //UserHelper.addPartnerUserToLibraryGroup(newUserList);
    }
}