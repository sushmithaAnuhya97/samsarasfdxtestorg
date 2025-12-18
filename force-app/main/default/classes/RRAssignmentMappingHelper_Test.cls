/**********************************************************************
Name: RRAssignmentMappingHelper_Test
=======================================================================
Purpose: This class is the test class for RRAssignmentMappingHelper                                                   
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Aug-02        INITIAL DEVELOPMENT FOR GTMS-13494

***********************************************************************/ 
@IsTest (SeeAllData=false)
public class RRAssignmentMappingHelper_Test {
    private static Id  user1;
    private static Id  user2;
    private static Id  user3;
    private static Id  user4;
    private static Id  user5;
	@TestSetup
    private static void testDataSetup() {
        String manualSource = 'true';
        DateTime now;
        
        /*UserRole userR = [Select id from UserRole WHERE name='Management'];
        system.debug('userR ' + userR);
        Profile userP = [Select id from Profile WHERE name='System Administrator'];
        system.debug('userP ' + userP);
        String userName = 'USER_' + system.now().getTime();
        String userEmail = userName + '@test.com';
        system.debug('userName ' + userName);*/
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara ADRs' and IsActive = true order by createddate LIMIT 5];
        system.debug('userList ' + userList);
        /*User objUser = new User(FirstName='First', LastName='Last', Alias='Alias', UserRoleId=userR.Id, ProfileId=userP.Id, Email=userEmail,
                               EmployeeNumber='123456789', UserName=userEmail, CommunityNickname ='Nickname', EmailEncodingKey='ISO-8859-1',
                               TimeZoneSidKey='America/Los_Angeles', LocaleSidKey='en_US',LanguageLocaleKey='en_US',
                               CurrencyIsoCode='USD');
        userList.add(objUser);
        User objUser2 = new User(FirstName='First2', LastName='Last2', Alias='Alias2', UserRoleId=userR.Id, ProfileId=userP.Id, Email=userEmail,
                               EmployeeNumber='1234567892', UserName='2'+userEmail, CommunityNickname ='Nickname2', EmailEncodingKey='ISO-8859-1',
                               TimeZoneSidKey='America/Los_Angeles', LocaleSidKey='en_US',LanguageLocaleKey='en_US',
                               CurrencyIsoCode='USD');
        userList.add(objUser2);
        insert userList;*/
        List<User> userListUpd = new List<User>();
        FOR(User loc : userList) {
            loc.Enable_ADR_Leads__c = true;
            userListUpd.add(Loc);
        }
        update userListUpd;
        user1 = userList[0].Id;
        user2 = userList[1].Id;
        user3 = userList[2].Id;
        user4 = userList[3].Id;
        user5 = userList[4].Id;
        /*List<Account> newAccount = new List<Account>();
        Account acc = new Account (Name = 'Test Account Country', Organization_Size__c = '5000+', BillingCountry = 'Germany', Industry = 'Other');
        newAccount.add(acc);   
        
        Account acc1 = new Account (Name = 'Test Account Country FR', Organization_Size__c = '5000+', BillingCountry = 'France', Industry = 'Other',
                                   Is_Deal_Reg_Account__c = true);
        newAccount.add(acc1);
        
        Account acc2 = new Account (Name = 'Test Account ARR 500K', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other',
                                    Customer_ARR__c=7000000);
        newAccount.add(acc2);
        
        Account acc3 = new Account (Name = 'Test Account ARR 250K', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other', 
                                    Customer_ARR__c=200000);
        newAccount.add(acc3);
        Account acc31 = new Account (Name = 'Test Account ARR 250K2', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other', 
                                    Customer_ARR__c=200000);
        newAccount.add(acc31);
        Account acc32 = new Account (Name = 'Test Account ARR 250K3', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other', 
                                    Customer_ARR__c=200000);
        newAccount.add(acc32);
        
        Account acc4 = new Account (Name = 'Test Account ARR 100K', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other', 
                                    Customer_ARR__c=10000);
        newAccount.add(acc4);
        
        Account acc5 = new Account (Name = 'Test Account municipal ARR 100K', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other',
                                    Customer_ARR__c=10000);
        newAccount.add(acc5);
        
        Account acc6 = new Account (Name = 'Test Account Lane Four SLED', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other',
                                    Customer_ARR__c=10000, Hashtag__c='hashtag', Website='rodrigo.gov');
        newAccount.add(acc6);
        
        Account acc7 = new Account (Name = 'Test Account Lane Four Not SLED', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other',
                                    Customer_ARR__c=10000, Hashtag__c='hashtag');
        newAccount.add(acc7);
        
        Account acc8 = new Account (Name = 'Test Account Lane Four Not NULL', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other',
                                    Customer_ARR__c=10000, Hashtag__c='hashtag', Account_Lifetime_ACV__c=75);
        newAccount.add(acc8);
        
        Account acc9 = new Account (Name = 'Test Account Lane Four AND Condition', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other',
                                    Customer_ARR__c=10000, Hashtag__c='hashtag', Account_Lifetime_ACV__c=75, Renewal_AE_Queue__c='TEST_AE_QUEUE');
        newAccount.add(acc9);
        
        Account acc10 = new Account (Name = 'Test Account Lane Four SLED2', Organization_Size__c = '100 - 499', BillingCountry = 'Mexico', Industry = 'Other',
                                    Customer_ARR__c=10000, Hashtag__c='hashtag', Website='rodrigo.gov', Domain_Name__c='rodrigo.gov', Record_Type_Stamp_for_Dupes__c='Fleet');
        newAccount.add(acc10);
        
        insert newAccount; 
        */
        List<RR_Assignment_Rule__c> listRule = new List<RR_Assignment_Rule__c>();
        
        RR_Assignment_Rule__c rule6 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'Lane Four all Null', SLED__c=false,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 100, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[0].Id, Always_Use_Next_Assignment__c=false,
                                                                Billing_Country__c=null, Number_of_Vehicles__c=null, Number_of_Powered_Assets__c=null,
                                                                Number_of_Unpowered_Assets__c=null,Number_of_Students__c=null, Number_of_Citizens__c=null,
                                                                Account_Lifetime_ACV__c=null, Deal_Reg_Account__c=true);
        listRule.add(rule6);
        
        RR_Assignment_Rule__c rule7 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'Lane Four SLED', SLED__c=true, SLED_Check__c=true,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 2, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[4].Id, Always_Use_Next_Assignment__c=true,
                                                                Billing_Country__c='Mexico',Account_Hashtag__c='test', Number_of_Vehicles__c='==0', 
                                                                 Number_of_Powered_Assets__c='> 0',Number_of_Unpowered_Assets__c='>=0',
                                                                Number_of_Students__c='<=0', Number_of_Citizens__c='< 0', Organization_Size__c='1 - 99');
        listRule.add(rule7);
        
        RR_Assignment_Rule__c rule8 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'Lane Four all >=0', SLED__c=false,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 3, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[4].Id, Always_Use_Next_Assignment__c=true,
                                                                Billing_Country__c=null, Number_of_Vehicles__c='>=0', Number_of_Powered_Assets__c='>=0',
                                                                Number_of_Unpowered_Assets__c='>=0',Number_of_Students__c='>=0', Number_of_Citizens__c='>=0',
                                                                Account_Lifetime_ACV__c='>=0', Website__c='.gov', Domain_Name__c='.edu', CSM_Null_Check__c=true);
        listRule.add(rule8);
        RR_Assignment_Rule__c rule9 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'Lane Four Use AND Condition', SLED__c=false,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 4, Active__c=true, Min_Value__c=0,Use_AND_Condition__c=true,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[4].Id, Always_Use_Next_Assignment__c=true,
                                                                Billing_Country__c=null, Number_of_Vehicles__c=null, Number_of_Powered_Assets__c=null,
                                                                Number_of_Unpowered_Assets__c=null,Number_of_Students__c='>=0', Number_of_Citizens__c='>=0',
                                                                Account_Lifetime_ACV__c='>=0', Website__c='.gov', Domain_Name__c='.edu', CSM_Null_Check__c=true);
        listRule.add(rule9);
        
        RR_Assignment_Rule__c rule10 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'Lane Four SLED', SLED__c=true, SLED_Check__c=true,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 2, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[4].Id, Always_Use_Next_Assignment__c=true,
                                                                Billing_Country__c='Mexico',Account_Hashtag__c='test', Number_of_Vehicles__c='==0', 
                                                                 Number_of_Powered_Assets__c='> 0',Number_of_Unpowered_Assets__c='>=0',
                                                                Number_of_Students__c='<=0', Number_of_Citizens__c='< 0', Organization_Size__c='100 - 499');
        listRule.add(rule10);
        RR_Assignment_Rule__c rule11 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'Lane Four SLED2', SLED__c=true, SLED_Check__c=true,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 2, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[4].Id, Always_Use_Next_Assignment__c=true,
                                                                Billing_Country__c='Mexico',Account_Hashtag__c=null, Number_of_Vehicles__c='==0', 
                                                                 Number_of_Powered_Assets__c='> 0',Number_of_Unpowered_Assets__c='>=0',
                                                                Number_of_Students__c='<=0', Number_of_Citizens__c='< 0', Organization_Size__c='100 - 499',
                                                                 Record_Type_Stamp_for_Dupes__c='Fleet');
        listRule.add(rule11);
        RR_Assignment_Rule__c rule12 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'NA Fleet AE2 East - Pool User', SLED__c=false, SLED_Check__c=false,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 2, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[4].Id, Always_Use_Next_Assignment__c=true,
                                                                Billing_Country__c='Mexico',Account_Hashtag__c=null, Number_of_Vehicles__c='==0', 
                                                                 Number_of_Powered_Assets__c='> 0',Number_of_Unpowered_Assets__c='>=0',
                                                                Number_of_Students__c='<=0', Number_of_Citizens__c='< 0', Organization_Size__c='100 - 499',
                                                                 Record_Type_Stamp_for_Dupes__c='Fleet');
        listRule.add(rule12);

        insert listRule;
    
        List<RR_Assignment_Mapping__c> arrMapList = new List<RR_Assignment_Mapping__c>();
        RR_Assignment_Mapping__c map54 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[0].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='Other', Value_Total__c=10000, Pause_Assignment__c=false);
        
        arrMapList.add(map54);
        
        RR_Assignment_Mapping__c map541 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[1].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='Other', Value_Total__c=10000, Pause_Assignment__c=false);
        
        arrMapList.add(map541);
        
        RR_Assignment_Mapping__c map542 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[2].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='Other', Value_Total__c=10000, Pause_Assignment__c=false);
        
        arrMapList.add(map542);
        
        RR_Assignment_Mapping__c map543 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[3].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='Other', Value_Total__c=10000, Pause_Assignment__c=false);
        
        arrMapList.add(map543);
        
        RR_Assignment_Mapping__c map55 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[1].Id, Order__c = 2, 
                                                                     Active__c=true, Type__c='Other', Value_Total__c=10000, Pause_Assignment__c=false);
        
        arrMapList.add(map55);
        
        RR_Assignment_Mapping__c map551 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[2].Id, Order__c = 2, 
                                                                     Active__c=true, Type__c='Other', Value_Total__c=10000, Pause_Assignment__c=true);
        
        arrMapList.add(map551);
        
        RR_Assignment_Mapping__c map552 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[3].Id, Order__c = 2, 
                                                                     Active__c=true, Type__c='Other', Value_Total__c=10000, Pause_Assignment__c=true);
        
        arrMapList.add(map552);
        
        RR_Assignment_Mapping__c map553 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[4].Id, Order__c = 2, 
                                                                     Active__c=false, Type__c='Other', Value_Total__c=10000, Pause_Assignment__c=true);
        
        arrMapList.add(map553);
        
        RR_Assignment_Mapping__c map554 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[0].Id, Order__c = 2, 
                                                                     Active__c=false, Type__c='Other', Value_Total__c=10000, Pause_Assignment__c=true);
        
        arrMapList.add(map554);
        
        
		
        insert arrMapList;
    }
    
    @isTest
    static void methodCall_Test() {
        Test.startTest();
        Set<Id> setUser = new Set<Id>();
        setUser.add(user1);
        RoundRobinHandler.updateRuleNextAssignmentFuture(setUser, true);
        Test.stopTest();
    }
    
    @isTest
    static void updateRRMapping_Test() {
        Test.startTest();
        List<RR_Assignment_Mapping__c> rrMap = [SELECT Id FROM RR_Assignment_Mapping__c limit 5];
        rrMap[0].Pause_Assignment__c = true;
        update rrMap[0];
        rrMap[0].Pause_Assignment__c = false;
        update rrMap[0];
        //RoundRobinHandler.updateRuleNextAssignmentFuture(user1, true);
        Test.stopTest();
    }
    
    @isTest
    static void updateRRMapping_Test2() {
        Test.startTest();
        List<RR_Assignment_Mapping__c> rrMap = [SELECT Id FROM RR_Assignment_Mapping__c WHERE Pause_Assignment__c = false limit 10];
        List<RR_Assignment_Mapping__c> rrMapUpdate = new List<RR_Assignment_Mapping__c>();
        FOR(RR_Assignment_Mapping__c rrRec : rrMap) {
            rrRec.Pause_Assignment__c = true;
            rrMapUpdate.add(rrRec);
        }
        
        update rrMapUpdate;
        
        //RoundRobinHandler.updateRuleNextAssignmentFuture(user1, true);
        Test.stopTest();
    }
    
    @isTest
    static void updateRRMapping_Test3() {
        Test.startTest();
        List<RR_Assignment_Mapping__c> rrMap = [SELECT Id FROM RR_Assignment_Mapping__c WHERE Pause_Assignment__c = true limit 10];
        List<RR_Assignment_Mapping__c> rrMapUpdate = new List<RR_Assignment_Mapping__c>();
        FOR(RR_Assignment_Mapping__c rrRec : rrMap) {
            rrRec.Pause_Assignment__c = false;
            rrMapUpdate.add(rrRec);
        }
        
        update rrMapUpdate;
        
        //RoundRobinHandler.updateRuleNextAssignmentFuture(user1, true);
        Test.stopTest();
    }
    
    @isTest
    static void updateRRMapping_Test4() {
        Test.startTest();
        List<RR_Assignment_Mapping__c> rrMap = [SELECT Id FROM RR_Assignment_Mapping__c limit 5];
        delete rrMap;
        //RoundRobinHandler.updateRuleNextAssignmentFuture(user1, true);
        Test.stopTest();
    }
    
    @isTest
    static void updateRRMapping_Test5() {
        Test.startTest();
        List<RR_Assignment_Mapping__c> rrMap = [SELECT Id FROM RR_Assignment_Mapping__c where active__c=true limit 5];
        rrMap[0].active__c = false;
        update rrMap[0];
        
        //RoundRobinHandler.updateRuleNextAssignmentFuture(user1, true);
        Test.stopTest();
    }
    
    @isTest
    static void updateRRMapping_Test6() {
        Test.startTest();
        List<RR_Assignment_Mapping__c> rrMap = [SELECT Id FROM RR_Assignment_Mapping__c where active__c=false limit 5];
        rrMap[0].active__c = true;
        update rrMap[0];
        
        //RoundRobinHandler.updateRuleNextAssignmentFuture(user1, true);
        Test.stopTest();
    }
}