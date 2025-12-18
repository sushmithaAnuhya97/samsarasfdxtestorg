/**********************************************************************
Name: FeatureRequestsHelper
=======================================================================
Purpose: This class will contain methods that handles Feature Request                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Oct-25        INITIAL DEVELOPMENT FOR GTMS-14262

***********************************************************************/
public class FeatureRequestsHelper {
    @auraenabled 
    public static boolean isUserSubscribed(string recordId, string action) {
        boolean isSubscribe = false;
        if (action == 'CHECK') {
            List<acideasULT__brIdeaSubscription__c> lstSubscription = [SELECT Id FROM acideasULT__brIdeaSubscription__c 
                                                                       WHERE acideasULT__brIdea__c =: recordId 
                                                                       AND acideasULT__User__c =: UserInfo.getUserId() 
                                                                      ];
            if (lstSubscription.size()>0)
                isSubscribe = true;
            else
            	isSubscribe = false;
        }
        else if (action == 'SUBSCRIBE') {
            acideasULT__brIdeaSubscription__c subsRec = new acideasULT__brIdeaSubscription__c();
            subsRec.acideasULT__brIdea__c = recordId;
            subsRec.acideasULT__User__c = UserInfo.getUserId();
            insert subsRec;
            isSubscribe = true;
        }
        else if (action == 'UNSUBSCRIBE') {
            List<acideasULT__brIdeaSubscription__c> lstSubscription = [SELECT Id FROM acideasULT__brIdeaSubscription__c 
                                                                       WHERE acideasULT__brIdea__c =: recordId 
                                                                       AND acideasULT__User__c =: UserInfo.getUserId() 
                                                                      ];
            delete lstSubscription;
            isSubscribe = false;
        }
        return isSubscribe;
    }
}