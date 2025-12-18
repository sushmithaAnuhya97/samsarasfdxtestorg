@IsTest
public class LightningBuddyActionControllerTest {
    @testSetup static void setup() {
        
        Schema.DescribeSObjectResult sObjDesc = Actions__c.sObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recTypes = sObjDesc.getRecordTypeInfosByDeveloperName();
        System.debug('>>>>>> recordTypes : '+recTypes);
        List<Actions__c> toInsert = new List<Actions__c>();
        Actions__c action;
        action = new Actions__c(RecordTypeId=recTypes.get('Image_Carousel').getRecordTypeId(),
                                                Name='Test Image Carousel',
                                                Object__c='Home',
                                                Page_Type__c='Home');
        toInsert.add(action);
        action = new Actions__c(RecordTypeId=recTypes.get('Popover').getRecordTypeId(),
                                                Name='Test Popover',
                                                Object__c='Contact',
                                                Page_Type__c='Home',
                                                Popover_Text__c='Test');
        toInsert.add(action);
        action = new Actions__c(RecordTypeId=recTypes.get('Rich_Text').getRecordTypeId(),
                                                Name='Test Popover',
                                                Object__c='Case',
                                                Page_Type__c='Home',
                                                Action_Text__c='Test');
        toInsert.add(action);

        action = new Actions__c(RecordTypeId=recTypes.get('Rich_Text').getRecordTypeId(),
                                                Name='Test Only Once',
                                                Object__c='Contact',
                                                Page_Type__c='Home',
                                                Action_Text__c='Test',
                                               	Recurrence__c='Only once');
        toInsert.add(action);
        action = new Actions__c(RecordTypeId=recTypes.get('Rich_Text').getRecordTypeId(),
                                                Name='Test Days after',
                                                Object__c='Campaign',
                                                Page_Type__c='Home',
                                                Action_Text__c='Days after certain date',
                                               	Recurrence__c='Days after certain date',
                                               	Recurrence_Date__c=System.today().addDays(-1),
                                               	Recurrence_Days__c=1
                                                
                                               );
        toInsert.add(action);
        action = new Actions__c(RecordTypeId=recTypes.get('Rich_Text').getRecordTypeId(),
                                                Name='Test Days after 2',
                                                Object__c='Contract',
                                                Page_Type__c='Home',
                                                Action_Text__c='Days after certain date',
                                               	Recurrence__c='Days after certain date',
                                               	Recurrence_Date__c=System.today(),
                                               	Recurrence_Days__c=0
                                                
                                               );
        toInsert.add(action);
        action = new Actions__c(RecordTypeId=recTypes.get('Rich_Text').getRecordTypeId(),
                                                Name='Test Days after 3',
                                                Object__c='Asset',
                                                Page_Type__c='Home',
                                                Action_Text__c='Days after certain date',
                                               	Recurrence__c='Days after certain date',
                                               	Recurrence_Date__c=System.today().addDays(7),
                                               	Recurrence_Days__c=1
                                                
                                               );
        toInsert.add(action);

        insert toInsert;

        action = new Actions__c(RecordTypeId=recTypes.get('Rich_Text').getRecordTypeId(),
                                                Name='Test Sub Tab Action',
                                                Object__c='Actions__c',
                                                Page_Type__c='Record Detail',
                                                Subtab_Name__c='MySubTab',
                                                Record_Id__c=toInsert[0].Id,
                                                Action_Text__c='Test');
        insert action;


        action = new Actions__c(RecordTypeId=recTypes.get('Rich_Text').getRecordTypeId(),
                                                Name='Test Record Detail Rich_Text ',
                                                Object__c='Actions__c',
                                                Page_Type__c='Record Detail',
                                                Record_Id__c=toInsert[0].Id,
                                                Action_Text__c='Test');
        insert action;
        
        action = new Actions__c(RecordTypeId=recTypes.get('Rich_Text').getRecordTypeId(),
                                                Name='Test Record Update Rich_Text ',
                                                Object__c='Actions__c',
                                                Page_Type__c='Record Update',
                                                Action_Text__c='Test');
        insert action;
        
        action = toInsert[2];
        
        Action_User_Preference__c usrPref
            = new Action_User_Preference__c(Action__c=action.Id,
                                                            User__c=UserInfo.getUserId(),
                                                            Unique_Id__c=UserInfo.getUserId()+'_'+action.Id);
        insert usrPref;
        action = toInsert[3];
        usrPref 
            = new Action_User_Preference__c(Action__c=action.Id,
                                                            User__c=UserInfo.getUserId(),
                                                            Unique_Id__c=UserInfo.getUserId()+'_'+action.Id);
        insert usrPref;
        action = toInsert[5];
        usrPref 
            = new Action_User_Preference__c(Action__c=action.Id,
                                                            User__c=UserInfo.getUserId(),
                                                            Unique_Id__c=UserInfo.getUserId()+'_'+action.Id,
                                                           	Dismissed_Date__c=System.today()
                                                           );
        insert usrPref;

    }
    public static testmethod void testGetUserInfo(){
        User usr = LightningBuddyActionController.getLoggedInUser();
        System.assertEquals(UserInfo.getProfileId(),usr.ProfileId,'ProfileId mismatch');
        System.assertEquals(UserInfo.getUserName(),usr.Username,'Username mismatch');
        System.assertEquals(UserInfo.getUserId(),usr.Id,'User Id mismatch');
    }
    
    public static testmethod void testGetPopoverMessageToDisplay(){
        String popoverText = LightningBuddyActionController.getPopoverMessageToDisplay('Contact', 'Home', null);
        //System.assertEquals('Test', popoverText, 'Popover text mismatch');
    }
    public static testmethod void testNullPopoverMessageToDisplay(){
        String popoverText = LightningBuddyActionController.getPopoverMessageToDisplay('Case', 'Home', null);
        System.assertEquals(null, popoverText, 'Popover text NULL mismatch');
    }
    
    public static testmethod void testActionWithRecordId(){
        Actions__c action = [select Id from Actions__c where Name='Test Image Carousel' limit 1];
        
        List<Actions__c> actionsToDisplay = LightningBuddyActionController.getAction('Actions__c',
                                                                                                     'Record Detail',
                                                                                                     action.Id,
                                                                                                     null);
        System.assertEquals(1, actionsToDisplay.size(), 'No actions fetched for Action record detail');
        System.assertEquals('Test', actionsToDisplay[0].Action_Text__c, 'Action text mismatch');
    }

    
    public static testmethod void testActionWithoutRecordId(){
        Actions__c action = [select Id from Actions__c where Name='Test Image Carousel' limit 1];
        
        List<Actions__c> actionsToDisplay = LightningBuddyActionController.getAction('Home',
                                                                                                     'Home',
                                                                                                     null,
                                                                                                     null);
        System.assertEquals(1, actionsToDisplay.size(), 'No actions fetched for Home:Home');
    }    
    public static testmethod void testActionWithUserPreferences(){
        Actions__c action = [select Id from Actions__c where Name='Test Image Carousel' limit 1];
        
        List<Actions__c> actionsToDisplay = LightningBuddyActionController.getAction('Case',
                                                                                                     'Home',
                                                                                                     null,
                                                                                                     null);
        //System.assertEquals(0, actionsToDisplay.size(), 'Actions fetched for Case:Home when not expected');
    }
    public static testmethod void testActionWithRecordUpdate(){
        Actions__c action = [select Id from Actions__c where Name='Test Record Update Rich_Text' limit 1];
        
        List<Actions__c> actionsToDisplay = LightningBuddyActionController.getAction('Actions__c',
                                                                                                     'Record Update',
                                                                                                     action.Id,
                                                                                                     null);
        System.assertEquals(1, actionsToDisplay.size(), 'No actions fetched for Action record detail');
        System.assertEquals('Test', actionsToDisplay[0].Action_Text__c, 'Action text mismatch');
    }
    
    public static testmethod void testNoActions(){
        List<Actions__c> actionsToDisplay = LightningBuddyActionController.getAction('Dashboard',
                                                                                                     'Home',
                                                                                                    null,
                                                                                                     null);
        System.assertEquals(null, actionsToDisplay, 'Actions fetched for Dashboard home');
    }
    
    public static testmethod void testRunOnlyOnce(){
        List<Actions__c> actionsToDisplay = LightningBuddyActionController.getAction('Contact',
                                                                                                     'Home',
                                                                                                    null,
                                                                                                     null);
        //System.assertEquals(null, actionsToDisplay, 'Actions fetched for Contact Home');
    }
    
    public static testmethod void testDaysAfterADate(){
        List<Actions__c> actionsToDisplay = LightningBuddyActionController.getAction('Campaign',
                                                                                                     'Home',
                                                                                                    null,
                                                                                                     null);
        System.assertEquals(1, actionsToDisplay.size(), 'No actions fetched for Campaign Home');
        System.assertEquals('Days after certain date', actionsToDisplay[0].Action_Text__c, 'Action text mismatch');
    }
    public static testmethod void testDaysAfterADateNoAction(){
        List<Actions__c> actionsToDisplay = LightningBuddyActionController.getAction('Contract',
                                                                                                     'Home',
                                                                                                     null,
                                                                                                     null);
       // System.assertEquals(null, actionsToDisplay, 'testDaysAfterADateNoAction = Actions fetched for Contract Home when not expected');
    }
    
    public static testmethod void testDaysAfterAFutureDate(){
        List<Actions__c> actionsToDisplay = LightningBuddyActionController.getAction('Asset',
                                                                                                     'Home',
                                                                                                     null,
                                                                                                     null);
       // System.assertEquals(null, actionsToDisplay, 'testDaysAfterADateNoAction = Actions fetched for Contract Home when not expected');
    }

    public static testmethod void testObjectSubTab(){
        Actions__c action = [select Id from Actions__c where Name='Test Sub Tab Action' limit 1];
        
        List<Actions__c> actionsToDisplay = LightningBuddyActionController.getAction('Actions__c',
                                                                                                     'Record Detail',
                                                                                                     null,
                                                                                                     'MySubTab');
        System.assertEquals(1, actionsToDisplay.size(), 'testObjectSubTab = Actions empty when action expected');
    }

    public static testmethod void testObjectSubTabWithRecordId(){
        Actions__c action = [select Id from Actions__c where Name='Test Sub Tab Action' limit 1];
        
        List<Actions__c> actionsToDisplay = LightningBuddyActionController.getAction('Actions__c',
                                                                                                     'Record Detail',
                                                                                                     action.Id,
                                                                                                     'MySubTab');
        System.assertEquals(1, actionsToDisplay.size(), 'testObjectSubTabWithRecordId = Actions returned when none expected');
    }
}