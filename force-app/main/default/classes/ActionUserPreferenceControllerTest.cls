@IsTest
public class ActionUserPreferenceControllerTest {
    @testSetup static void setup() {
        Schema.DescribeSObjectResult sObjDesc = Actions__c.sObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recTypes = sObjDesc.getRecordTypeInfosByDeveloperName();
        System.debug('>>>>>> recordTypes : '+recTypes);
        Actions__c action = new Actions__c(RecordTypeId=recTypes.get('Image_Carousel').getRecordTypeId(),
                                           Name='Test Image Carousel',
                                           Object__c='Home',
                                           Page_Type__c='Home');
        insert action;
    }
    public static testmethod void testDismissActionForever(){
    	Actions__c action = [select Id,Name from Actions__c limit 1];
        ActionUserPreferenceController.dismissActionForever(action.Id);
        List<Action_User_Preference__c> userPref = [select Action__c,User__c,Unique_Id__c
                                                    from Action_User_Preference__c
                                                   where Action__c = :action.Id];
        
        System.assertEquals(1,userPref.size(),'Action user preferences not saved.');
        System.assertEquals(UserInfo.getUserId(),userPref[0].User__c,'User Id mismatch.');
        System.assertEquals(action.Id,userPref[0].Action__c,'Action Id mismatch.');
    }
}