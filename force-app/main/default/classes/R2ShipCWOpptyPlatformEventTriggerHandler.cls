public class R2ShipCWOpptyPlatformEventTriggerHandler extends TriggerHandler{
	private List<R2Ship_CW_Opportunity__e> newR2ShipCWPlatformEventList; 
	static Boolean triggerSettingFlag = false;
	static Trigger_Setting__mdt thisTrigger;

	public R2ShipCWOpptyPlatformEventTriggerHandler() {
		this.newR2ShipCWPlatformEventList = (List<R2Ship_CW_Opportunity__e>) Trigger.new;
    }
    
    public override void afterInsert(){
        System.debug(LoggingLevel.INFO, 'Hitting PE TriggerHandler');
        R2ShipCWPlatformEventHelper.r2ShipCWPlatormEventDispatch(newR2ShipCWPlatformEventList);
    }
}