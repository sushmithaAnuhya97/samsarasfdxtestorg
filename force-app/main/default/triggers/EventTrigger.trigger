trigger EventTrigger on Event (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    new EventTriggerHandler().run();
}