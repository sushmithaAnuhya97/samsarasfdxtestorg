/**********************************************************************
Name: FR_IdeaSubcriptions
Test Class: FR_IdeaSubcriptions_Test
=======================================================================
Purpose: This class contains the logic to fetch feature request subscriber emails of CE/SE profiles                                                       
=======================================================================
History  

VERSION     AUTHOR               			DATE               DETAIL                       
1.0        vijaychandra AMARANENI        2023-Aug-28        INITIAL DEVELOPMENT FOR GTMS-14263

***********************************************************************/
public class FR_IdeaSubcriptions {
	/*****************************************8
	 * @Description:this method will be called from Feature_Request_After_Update flow to send emails to subscribers
	 * @Param : frIdList - feature request record i
	 * @return : this method will return the list of subscribers emails  
	*/
    @InvocableMethod(label='Fetch Idea Subscription records' description='fetching user subscription records related to idea')
    public static List<List<String>> fetchSubscriberEmails(List<String> frIdList){
        string profileIds = System.Label.FR_Subs_CE_SE_Profile_Ids;//profile ids stored in custom label
        List<String> cs_se_profileIds = profileIds.split(';');//splitting profile ids to list
        List<string> userIdList = new List<string>();
        for(acideasULT__brIdeaSubscription__c subscription:[SELECT Id,acideasULT__User__c,acideasULT__User__r.Email FROM acideasULT__brIdeaSubscription__c WHERE acideasULT__brIdea__c IN :frIdList AND acideasULT__User__r.Profile.UserType ='Standard' AND acideasULT__User__r.ProfileId IN :cs_se_profileIds]){
            userIdList.add(subscription.acideasULT__User__r.Email);
        }
        
        return new List<List<String>>{userIdList};
    }
}