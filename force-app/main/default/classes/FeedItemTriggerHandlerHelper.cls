public class FeedItemTriggerHandlerHelper {
    private static Map<String, Schema.SObjectType> gd = new Map<String, Schema.SObjectType>();
    public static void beforeUpdateInsert(Map<Id, FeedItem> oldFeedItemMap, List<FeedItem> newFeedItemList) {
        //Get schema information
        gd =  Schema.getGlobalDescribe(); 
        
        for (FeedItem feeditem : newFeedItemList)
        {
            //system.debug('feeditem ' + feeditem);
            Id fiParentId = feeditem.ParentId; 
			//System.debug('object is '+ fiParentId.getsobjecttype());
			string objType = findObjectNameFromRecordIdPrefix(fiParentId);
            system.debug('objType ' + objType);
            if(feeditem.Visibility!='InternalUsers' && objType=='acideasULT__brIdea__c')
                feeditem.addError('Please use Samsara Only Option to tag internal user within Samsara');
        }
    }
	
    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        try{
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
             
            //Loop through all the sObject types returned by Schema
            for(Schema.SObjectType stype : gd.values()){

                //if (!sObj.contains('__')) to exclude managed package objects

                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                //System.debug('Prefix is ' + prefix);
                 
                //Check if the prefix matches with requested prefix
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    //System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
        return objectName;
    }
    
    public class SlackUserIds {
        @InvocableVariable public string slackUserId;
        
    }
    
    @InvocableMethod(label='Get Chatter Mentions Slack Id')
    public static List<List<String>> getChatterMentionSlackId(List<Id> feedItemIds) {
        List<List<String>> resultList = new List<List<String>>();
        List<String> slackUserIds = new List<String>();
        List<String> userIds = new List<String>();
        //List<String> feedItemIds = new List<String>();
        String communityId = Network.getNetworkId();
        feedItemIds.add(feedItemIds[0]);
        // Re-fetch the feed items passed into the trigger
        ConnectApi.BatchResult[] results = ConnectApi.ChatterFeeds.getFeedElementBatch(communityId, feedItemIds);
       
        for (ConnectApi.BatchResult result : results) {
            if (result.isSuccess()) {
                Object theResult = result.getResult();
                if (theResult instanceof ConnectApi.FeedItem) {
                    ConnectApi.FeedItem item = (ConnectApi.FeedItem) theResult;
                    
                    for (ConnectApi.MessageSegment segment : item.body.messageSegments) {
                        if (segment instanceof ConnectApi.MentionSegment) {
                            ConnectApi.MentionSegment theMention = (ConnectApi.MentionSegment) segment;
                            String mentionedId = theMention.record.id;
                            userIds.add(mentionedId);
                            
                            // Do what you need to do with mentionedId...
                            System.debug('Mentioned ID: ' + mentionedId);
                        }
                    }
                }
            }
        }
        List<User> userList = [SELECT Id, Slack_User_Id__c from User where Id IN: userIds];
        FOR(User usr : userList) {
            string slackIdstr = usr.Slack_User_Id__c;
            system.debug('slackIdstr ' + slackIdstr);
            if(slackIdstr != null) {
                integer pos = slackIdstr.indexOf('@');
                slackUserIds.add(slackIdstr.substring(pos+1));
            }                
                
        }
        if(slackUserIds.size()>0) resultList.add(slackUserIds);
        	
        return resultList;
    }
}