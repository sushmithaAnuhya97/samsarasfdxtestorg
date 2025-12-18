trigger OpportunityTeamMemberTrigger on OpportunityTeamMember (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
        new OpportunityTeamMemberTriggerHandler().run();
}