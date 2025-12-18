public class FeedItemTriggerHandler extends TriggerHandler {
    private Map<Id, FeedItem> oldFeedItemMap;
	private Map<Id, FeedItem> newFeedItemMap;
	private List<FeedItem> newFeedItemList;
	// use to manually turn on / off trigger from a test method
    @TestVisible private static Integer maxRuns = 1;
    @TestVisible private static Map<String, Integer> methodsCalled = new Map<String, Integer>();
    
    public FeedItemTriggerHandler() {
		this.oldFeedItemMap = (Map<Id, FeedItem>) Trigger.oldMap;
		this.newFeedItemMap = (Map<Id, FeedItem>) Trigger.newMap;
		this.newFeedItemList = (List<FeedItem>) Trigger.new;
		
	}
    
    public override void beforeInsert() {
        if (timesCalled('beforeInsert') < maxRuns) {
            FeedItemTriggerHandlerHelper.beforeUpdateInsert(oldFeedItemMap, newFeedItemList);
            addCall('beforeInsert');
        }
	}
    
    public static integer timesCalled(String Input) {

        if (!methodsCalled.containsKey(Input)) {
            return 0;
        } else {
            return methodsCalled.get(Input);
        }

    }
    
    public static integer addCall(String Input) {

        if (!methodsCalled.containsKey(Input)) {
            methodsCalled.put(input, 1);
        } else {
            Integer i = methodsCalled.get(input) + 1;
            methodsCalled.put(input, i);
        }

        return methodsCalled.get(input);
    }
}