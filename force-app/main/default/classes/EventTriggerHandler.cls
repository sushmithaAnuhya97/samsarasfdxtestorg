public class EventTriggerHandler extends TriggerHandler{
    private Map<Id, Event> oldEventMap;
    private Map<Id, Event> newEventMap;
    private List<Event> newEventList;

    public EventTriggerHandler() {
        this.oldEventMap = (Map<Id, Event>) Trigger.oldMap;
        this.newEventMap = (Map<Id, Event>) Trigger.newMap;
        this.newEventList = (List<Event>) Trigger.new; 
    }
    public override void beforeInsert(){
        EventHelper.beforeInsertUpdate(newEventList, oldEventMap);
    }

    public override void beforeUpdate(){
        EventHelper.beforeInsertUpdate(newEventList, oldEventMap);
    }

    public override void afterInsert() {
       EventHelper.postEventcreationContactUpdate(newEventList);
    }
}