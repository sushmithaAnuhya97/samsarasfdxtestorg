trigger CaseTrigger on Case (before insert,after insert, after update) {
    new CaseTriggerHandler().run();
}