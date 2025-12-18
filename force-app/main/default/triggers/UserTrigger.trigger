trigger UserTrigger on User (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    new UserTriggerHandler().run();
}