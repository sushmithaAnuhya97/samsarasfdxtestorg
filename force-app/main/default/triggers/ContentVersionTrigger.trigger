trigger ContentVersionTrigger on ContentVersion (after insert, after update) {
    new ContentVersionTriggerHandler().run();
}