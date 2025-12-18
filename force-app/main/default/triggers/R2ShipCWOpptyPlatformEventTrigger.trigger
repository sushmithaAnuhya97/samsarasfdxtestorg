trigger R2ShipCWOpptyPlatformEventTrigger on R2Ship_CW_Opportunity__e (after insert){
    new R2ShipCWOpptyPlatformEventTriggerHandler().run();
}