@isTest(seeAllData=false)
private class TrackAccountFieldsToPublishEventsTest {
    
    @testSetup
    private static void makeData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        DateTime now = DateTime.now();
		String tD = now.year() + '' + now.month()+ '' + now.day()+''+now.hour()+ '' +now.minute() + '' + now.second()+''+now.millisecond();
		String newUserName= 'systemAdmin'+tD+'@samsara.com';
		User u = new User(Alias = 'SysAdmin', Email='sysadmin@samsara.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id, EmployeeNumber = 'EMPLOYEE_NUMBER',TimeZoneSidKey='America/Los_Angeles', UserName=newUserName);
        INSERT u;

        List<Account> accountList = new List<Account>();
        for(Integer i=0;i<3;i++){
            accountList.add((Account) TestFactory.createSObject(new Account(Name='MercuryTestAccount'+i, BigCommerce_Id__c='123456789'+i, Website='samsara.com', CSM_First_30d_Stage__c = 'Pending Intro',OwnerId = u.Id)));
        }
        if(accountList.size() > 0) {
            insert accountList;
        }
    }
    
    @isTest
    private static void testTrackAccountFields(){
        List<User> users = [Select Id from User where UserName like '%systemAdmin%'];
        
        Set<Id> userIds = new Set<Id>();
        for(User u:users){
            userIds.add(u.Id);
        }
        List<Account> accList = TrackAccountFieldsToPublishPlatEvents.trackAccountFields(userIds,User.sObjectType);
    	//System.AssertEquals(3,accList.size());
    }
    
    @isTest
    private static void testTrackingNullCheckForTrackingFields(){
        Account acct = [Select Id from Account where Name like 'MercuryTestAccount%' Limit 1];
        Boolean result = TrackAccountFieldsToPublishPlatEvents.verifyNullCheck(acct,new List<Sync_Object_Field_WebStore__mdt>());
        //Assert.isTrue(result);
    }
}