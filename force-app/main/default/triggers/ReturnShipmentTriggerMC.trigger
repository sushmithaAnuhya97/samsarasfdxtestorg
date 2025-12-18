//Jul-20-2024: Multi carrier UPS package upgrade - GTMS22356
trigger ReturnShipmentTriggerMC on zkmulti__MCShipment__c (before insert,after insert) 
{
    ReturnShipmentTriggerHandlerMC handler = new ReturnShipmentTriggerHandlerMC();
   
     if(Trigger.isAfter && Trigger.isInsert)
    {
        handler.onAfterInsert(Trigger.new);
    }    
}