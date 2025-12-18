/**********************************************************************
Name: FR_IdeaSubcriptions_Test
Realated Class: FR_IdeaSubcriptions
=======================================================================
Purpose: This class contains the test case methods for FR_IdeaSubcriptions class                                                       
=======================================================================
History  

VERSION     AUTHOR               			DATE               DETAIL                       
1.0        vijaychandra AMARANENI        2023-SEP-01        INITIAL DEVELOPMENT FOR GTMS-14503

***********************************************************************/ 

@IsTest(SeeAllData=true)
public class FR_IdeaSubcriptions_Test {
	/*****************************************8
	 * @Description:This method will create test data of users and required objects.
	 * 				This method will test the logic in fetchSubscriberEmails method of FR_IdeaSubcriptions apex class
	*/
    @IsTest
    static void emailFetchTest(){
        
        string profileIds = System.Label.FR_Subs_CE_SE_Profile_Ids;//profile ids stored in custom label
        List<String> cs_se_profileIds = profileIds.split(';');//splitting profile ids to list
        
        string ProfileId = [SELECT Id FROM Profile WHERE Id=:cs_se_profileIds[0] ].Id;
        
        User testUser = new User();
        
        testUser.ProfileId = ProfileId;
        testUser.LastName = 'testUser';
        testUser.Email = 'testUser@samsara.com';
        testUser.Username = 'testUser@samsara.com';
        testUser.Alias = 'user1';
        testUser.CompanyName = 'Samsara';
        testUser.TimeZoneSidKey='America/New_York';
        testUser.EmailEncodingKey='UTF-8';
        testUser.LanguageLocaleKey='en_US';
        testUser.LocaleSidKey='en_US';
        testUser.EmployeeNumber = '3456';
        
        /*insert testUser;
        
        acideasULT__brZone__c frZone = new acideasULT__brZone__c(Name='Test Zone',acideasULT__CommunityName__c='Test Community');
        
        insert frZone;
        
        acideasULT__brIdea__c fr = new acideasULT__brIdea__c(Name='Test FR',acideasULT__brZone__c=frZone.Id);
        
        insert fr;*/
        
        acideasULT__brIdea__c fr = [SELECT Id FROM acideasULT__brIdea__c limit 1];
        
        acideasULT__brIdeaSubscription__c subscription = new acideasULT__brIdeaSubscription__c(acideasULT__brIdea__c=fr.id,acideasULT__User__c = testUser.id);
        
        insert subscription;
        
        List<List<String>> emailsList = FR_IdeaSubcriptions.fetchSubscriberEmails(new List<String>{fr.Id});
        
        //Assert.isTrue(emailsList[0][0]=='testUser@samsara.com','Fetching of Subscriptoin user failed');

    }
}