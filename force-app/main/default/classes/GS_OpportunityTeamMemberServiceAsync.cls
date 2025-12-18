/**
 * Created by fcontini on 2021-09-21.
 */

public with sharing class GS_OpportunityTeamMemberServiceAsync {

    public void createOpportunityTeams(Map<Id, Id> opportunityIds) {
        Map<Id, Opportunity> queriedOpportunities;
        List<OpportunityTeamMember> opportunityTeams = new List<OpportunityTeamMember>();
        if(!opportunityIds.isEmpty()){
            queriedOpportunities = new Map<Id, Opportunity>(
                    (new GS_OpportunitySelector(false)).loadOpportunityWithTeamMembers(opportunityIds.keySet())
            );
        }

        for(Opportunity relatedOpp : queriedOpportunities.values()){
            List<OpportunityTeamMember> teams = relatedOpp.OpportunityTeamMembers;
            if(teams.size() > 1){
                for(OpportunityTeamMember member : teams){
                    if(member.TeamMemberRole != 'Opportunity Owner'){
                        OpportunityTeamMember newMember = new OpportunityTeamMember();
                        newMember.TeamMemberRole = member.TeamMemberRole;
                        newMember.UserId = member.UserId;
                        newMember.OpportunityId = opportunityIds.get(relatedOpp.Id);
                        opportunityTeams.add(newMember);
                    }
                }
            }
        }
        if(opportunityTeams.size()>0){
            DMLWrapper.doInsert(opportunityTeams);
        }
    }
}