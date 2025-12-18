@IsTest(SeeAllData=true)
public class FeatureRequestsHelper_Test {
    /*@testSetup
    private static void testDataSetup() {
        acideasULT__brZone__c ideaZone = new acideasULT__brZone__c ();
        ideaZone.name = 'Test Data';
        ideaZone.acideasULT__CommunityName__c = 'Test Community';
        insert ideaZone;
        
        List<acideasULT__brIdea__c> ideaList = new List<acideasULT__brIdea__c>();
        acideasULT__brIdea__c idea1 = new acideasULT__brIdea__c ();
        idea1.Name = 'Idea 1';
        idea1.acideasULT__brZone__c = ideaZone.id;
        ideaList.add(idea1);
        
        insert ideaList;
	}
    */
    @isTest 
    static void notSubscribedTest() {
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara CSM' and IsActive = true order by createddate LIMIT 5];
        
        System.runAs(userList[0]) {
            List<acideasULT__brIdea__c> ideaList = new List<acideasULT__brIdea__c>();
            ideaList = [SELECT Id FROM acideasULT__brIdea__c limit 1];
            //ideaList = [SELECT Id FROM acideasULT__brIdea__c WHERE Name = 'Idea 1'];
            FeatureRequestsHelper.isUserSubscribed(ideaList[0].Id, 'CHECK');
        }
    }
    
    @isTest 
    static void subscribedTest() {
        List<acideasULT__brIdea__c> ideaList = new List<acideasULT__brIdea__c>();
        ideaList = [SELECT Id FROM acideasULT__brIdea__c limit 1];
        //ideaList = [SELECT Id FROM acideasULT__brIdea__c WHERE Name = 'Idea 1'];
        FeatureRequestsHelper.isUserSubscribed(ideaList[0].Id, 'CHECK');
    }
    
    @isTest 
    static void SubscribedActionTest() {
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara CSM' and IsActive = true order by createddate LIMIT 5];
        
        System.runAs(userList[0]) {
            List<acideasULT__brIdea__c> ideaList = new List<acideasULT__brIdea__c>();
            ideaList = [SELECT Id FROM acideasULT__brIdea__c limit 1];
            //ideaList = [SELECT Id FROM acideasULT__brIdea__c WHERE Name = 'Idea 1'];
            FeatureRequestsHelper.isUserSubscribed(ideaList[0].Id, 'SUBSCRIBE');
        }
    }
    
    @isTest 
    static void UnubscribedActionTest() {
        List<acideasULT__brIdea__c> ideaList = new List<acideasULT__brIdea__c>();
        ideaList = [SELECT Id FROM acideasULT__brIdea__c limit 1];
        //ideaList = [SELECT Id FROM acideasULT__brIdea__c WHERE Name = 'Idea 1'];
        FeatureRequestsHelper.isUserSubscribed(ideaList[0].Id, 'UNSUBSCRIBE');
    }
}