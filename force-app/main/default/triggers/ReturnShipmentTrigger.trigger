//Aug-22-2022  Chinmaya Dash GTMS-6069 Optimized.
trigger ReturnShipmentTrigger on zkups__UPSShipment__c (before insert,after insert) 
{
    ReturnShipmentTriggerHandler handler = new ReturnShipmentTriggerHandler();
   
     if(Trigger.isAfter && Trigger.isInsert)
    {
        handler.onAfterInsert(Trigger.new);
    }    
}