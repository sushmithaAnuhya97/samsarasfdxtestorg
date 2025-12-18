public class OpportunityTeamMemberTriggerHandler extends TriggerHandler{
    
    private Map<Id, OpportunityTeamMember> oldTeamMap;
    private Map<Id, OpportunityTeamMember> newTeamMap;
    private List<OpportunityTeamMember> newTeamList;
    private OpportunityTeamMemberHelper opptyTeamHelper;
    
   public OpportunityTeamMemberTriggerHandler() {
        opptyTeamHelper = new OpportunityTeamMemberHelper();
        this.oldTeamMap = (Map<Id, OpportunityTeamMember>) Trigger.oldMap;
        this.newTeamMap = (Map<Id, OpportunityTeamMember>) Trigger.newMap;
        this.newTeamList = (List<OpportunityTeamMember>) Trigger.new;
    }
    
    public override void beforeInsert() {
        opptyTeamHelper.stampFields(newTeamList, newTeamMap, oldTeamMap);
    }

    public override void beforeUpdate() {
        opptyTeamHelper.stampFields(newTeamList, newTeamMap, oldTeamMap);
    }

    public override void afterUpdate() {
    }

}