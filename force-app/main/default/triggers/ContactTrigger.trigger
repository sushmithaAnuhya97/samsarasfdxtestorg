trigger ContactTrigger on Contact (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    if(HelperClass.contactTriggerPlug == null){
      HelperClass.contactTriggerPlug = new List<Trigger_Setting__mdt>([SELECT Enabled__c FROM Trigger_Setting__mdt WHERE MasterLabel = 'Contact' LIMIT 1])[0];
    }
    if(HelperClass.contactTriggerPlug.Enabled__c) {
      new GS_TriggerHandlerRunnerConfig().createHandler('Contact').run();
    }
}