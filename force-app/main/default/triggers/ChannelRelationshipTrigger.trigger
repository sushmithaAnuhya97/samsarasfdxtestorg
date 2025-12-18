trigger ChannelRelationshipTrigger on Channel_Relationship__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    new ChannelRelationshipTriggerHandler().run();
}