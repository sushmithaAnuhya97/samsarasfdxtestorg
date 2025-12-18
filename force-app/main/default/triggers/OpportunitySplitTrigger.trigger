trigger OpportunitySplitTrigger on OpportunitySplit (before insert, before update, after insert, after update, before delete, after delete, after undelete) {

new GS_TriggerHandlerRunnerConfig().createHandler('OpportunitySplit').run();

}