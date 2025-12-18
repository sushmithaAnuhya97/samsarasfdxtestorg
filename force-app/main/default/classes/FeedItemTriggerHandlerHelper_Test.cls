@isTest(SeeAllData=true)
public class FeedItemTriggerHandlerHelper_Test {
	@isTest
    static void CreateTestAllUsers(){
        /*acideasULT__brZone__c zone = [SELECT Id from acideasULT__brZone__c WHERE Name = 'Samsara Default FR Zone'];
        acideasULT__brIdea__c fr = new acideasULT__brIdea__c();
        fr.Name = 'Samsara Default FR Zone';
        fr.acideasULT__brZone__c = zone.Id;
        insert fr;*/
        acideasULT__brIdea__c fr = [SELECT Id FROM acideasULT__brIdea__c where RecordType.Name = 'Internal Feature Request' limit 1];
        FeedItem fi = new FeedItem();
        fi.Body='@Shravan Govindaraja test';
        fi.Status = 'Published';
        //fi.Visibility = 'AllUsers';
        fi.Type = 'TextPost';
        fi.NetworkScope='AllNetworks';
        fi.ParentId = fr.Id;
        insert fi;
        FeedItemTriggerHandlerHelper.getChatterMentionSlackId(New List<Id>{fi.Id});
    }
    @isTest
    static void CreateTestInternalUsers(){
        /*acideasULT__brZone__c zone = [SELECT Id from acideasULT__brZone__c WHERE Name = 'Samsara Default FR Zone'];
        acideasULT__brIdea__c fr = new acideasULT__brIdea__c();
        fr.Name = 'Samsara Default FR Zone';
        fr.acideasULT__brZone__c = zone.Id;
        insert fr;*/
        acideasULT__brIdea__c fr = [SELECT Id FROM acideasULT__brIdea__c where RecordType.Name = 'Internal Feature Request' limit 1];
        FeedItem fi = new FeedItem();
        fi.Body='@Shravan Govindaraja test';
        fi.Status = 'Published';
        fi.Visibility = 'InternalUsers';
        fi.Type = 'TextPost';
        fi.NetworkScope='AllNetworks';
        fi.ParentId = fr.Id;
        insert fi;
        FeedItemTriggerHandlerHelper.getChatterMentionSlackId(New List<Id>{fi.Id});
        FeedItemTriggerHandlerHelper SlackUserIds;
    }
    /*10:36:17:395 USER_DEBUG [4]|DEBUG|feeditem FeedItem:{Id=null, ParentId=aDJS00000008h1DOAQ, Type=TextPost, 
        CreatedById=null, CreatedDate=null, IsDeleted=false, LastModifiedDate=null, SystemModstamp=null, CommentCount=null, 
        LikeCount=null, Title=null, Body=@Shravan Govindaraja test, LinkUrl=null, IsRichText=false, RelatedRecordId=null, InsertedById=null, 
        NetworkScope=AllNetworks, Visibility=AllUsers, BestCommentId=null, HasContent=false, 
        HasLink=false, HasFeedEntity=false, HasVerifiedComment=false, IsClosed=false, Status=Published}*/
}