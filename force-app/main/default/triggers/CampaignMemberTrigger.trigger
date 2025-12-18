trigger CampaignMemberTrigger on CampaignMember (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    new CampaignMemberTriggerHandler().run();
}