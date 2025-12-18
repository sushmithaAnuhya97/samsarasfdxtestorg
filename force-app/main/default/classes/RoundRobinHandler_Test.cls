/**********************************************************************
Name: RoundRobinHandler_Test
=======================================================================
Purpose: This will handle the coverage for RoundRobinHandler                                                       
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT FOR GTMS-10121

***********************************************************************/ 
@isTest  (SeeAllData=false)
public class RoundRobinHandler_Test {
     
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
        List<Account> newAccount = new List<Account>();
        Account acc = new Account (Name = 'Test Account Country', Organization_Size__c = '5000+', BillingCountry = 'Germany', Industry = 'Other');
        newAccount.add(acc);   

        //Added below account as part of GTMS-18362
        Account acc_Texas = new Account (Name = 'Timezone Test Account US - Texas', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState = 'Texas', Industry = 'Other');
        newAccount.add(acc_Texas);   
        
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
        
        Account acc6 = new Account (Name = 'Test Account Lane Four SLED', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other',Public_Sector__c = true,
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
        
        Account acc10 = new Account (Name = 'Test Account Lane Four SLED2', Organization_Size__c = '100 - 499', BillingCountry = 'Mexico', Industry = 'Other',Public_Sector__c = true,
                                    Customer_ARR__c=10000, Hashtag__c='hashtag', Website='rodrigo.gov', Domain_Name__c='rodrigo.gov', Record_Type_Stamp_for_Dupes__c='Fleet');
        newAccount.add(acc10);
        
        Account acc11 = new Account (Name = 'Test Account Lane Four SLED21', Organization_Size__c = '100 - 499', BillingCountry = 'Mexico', Industry = 'Other', Public_Sector__c = true,
                                    Customer_ARR__c=10000, Hashtag__c='hashtag', Website='rodrigo.gov', Domain_Name__c='rodrigo.gov', Record_Type_Stamp_for_Dupes__c='Fleet');
        newAccount.add(acc11);

        insert newAccount; 
        
        List<RR_Assignment_Rule__c> listRule = new List<RR_Assignment_Rule__c>();
        RR_Assignment_Rule__c rule0 = new RR_Assignment_Rule__c (Category__c = 'Automating Pipeline', Rule_Description__c = 'Test Country FR', Region__c='FR',
                                                               Type__c = 'Country', Object__c='Account', Order__c = 1, Active__c=true,
                                                               Next_Assignment__c=userList[4].Id, Always_Use_Next_Assignment__c=true);
        listRule.add(rule0);
        RR_Assignment_Rule__c rule1 = new RR_Assignment_Rule__c (Category__c = 'Automating Pipeline', Rule_Description__c = 'Test Country', Region__c='DE',
                                                               Type__c = 'Country', Object__c='Account', Order__c = 2, Active__c=true,
                                                               Next_Assignment__c=userList[0].Id, Always_Use_Next_Assignment__c=true);
        listRule.add(rule1);
        RR_Assignment_Rule__c rule2 = new RR_Assignment_Rule__c (Category__c = 'Automating Pipeline', Rule_Description__c = 'Test 500K',Max_Value__c=0,
                                                               Type__c = 'ARR', Object__c='Account', Order__c = 3, Active__c=true, Min_Value__c=500000,
                                                                Next_Assignment__c=userList[3].Id, Always_Use_Next_Assignment__c=true);
        listRule.add(rule2);
        
        RR_Assignment_Rule__c rule3 = new RR_Assignment_Rule__c (Category__c = 'Automating Pipeline', Rule_Description__c = 'Test 250K',
                                                               Type__c = 'ARR', Object__c='Account', Order__c = 4, Active__c=true, Min_Value__c=150000,
                                                                Max_Value__c = 500000, Next_Assignment__c=userList[3].Id, Always_Use_Next_Assignment__c=true);
        listRule.add(rule3);
        
        RR_Assignment_Rule__c rule4 = new RR_Assignment_Rule__c (Category__c = 'Automating Pipeline', Rule_Description__c = 'Test 150K',
                                                               Type__c = 'ARR', Object__c='Account', Order__c = 4, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[3].Id, Always_Use_Next_Assignment__c=true);
        listRule.add(rule4);
        
        RR_Assignment_Rule__c rule5 = new RR_Assignment_Rule__c (Category__c = 'Automating Pipeline', Rule_Description__c = 'Test 150K SLED', SLED__c=true,
                                                               Type__c = 'ARR', Object__c='Account', Order__c = 4, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[4].Id, Always_Use_Next_Assignment__c=true);
        listRule.add(rule5);
        
        RR_Assignment_Rule__c rule6 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'Lane Four all Null', SLED__c=false,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 100, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[4].Id, Always_Use_Next_Assignment__c=true,
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
        RR_Assignment_Rule__c rule12 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'NA Fleet AE2 East - Pool User', SLED__c=false, 
                                                                  SLED_Check__c=true,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 2, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[4].Id, Always_Use_Next_Assignment__c=true,
                                                                Billing_Country__c='Mexico',Account_Hashtag__c=null, Number_of_Vehicles__c='==0', 
                                                                 Number_of_Powered_Assets__c='> 0',Number_of_Unpowered_Assets__c='>=0',
                                                                Number_of_Students__c='<=0', Number_of_Citizens__c='< 0', Organization_Size__c='100 - 499',
                                                                 Record_Type_Stamp_for_Dupes__c='Fleet');
        listRule.add(rule12);
        RR_Assignment_Rule__c rule13 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'NA Fleet AE2 East - Pool User 2', SLED__c=false, 
                                                                  SLED_Check__c=true,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 2, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=userList[4].Id, Always_Use_Next_Assignment__c=true,
                                                                Billing_Country__c='Mexico',Account_Hashtag__c=null, Number_of_Vehicles__c='', 
                                                                 Number_of_Powered_Assets__c='',Number_of_Unpowered_Assets__c='',
                                                                Number_of_Students__c='', Number_of_Citizens__c='', Organization_Size__c='100 - 499',
                                                                 Record_Type_Stamp_for_Dupes__c='Fleet');
        listRule.add(rule13);
        insert listRule;
    
        List<RR_Assignment_Mapping__c> arrMapList = new List<RR_Assignment_Mapping__c>();
        RR_Assignment_Mapping__c map0 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[3].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=10000, Max_Value__c=2000000);
        
        arrMapList.add(map0);
        RR_Assignment_Mapping__c map01 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[4].Id, Order__c = 2, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=10000, Max_Value__c=2000000);
        
        arrMapList.add(map01);
        RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[1].Id, User__c=userList[0].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=200000, Max_Value__c=200000);
        
        arrMapList.add(map1);
        
		RR_Assignment_Mapping__c map2 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[2].Id, User__c=userList[0].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=200000, Max_Value__c=200000);
        
        arrMapList.add(map2);
		
        RR_Assignment_Mapping__c map21 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[2].Id, User__c=userList[1].Id, Order__c = 2, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=150000, Max_Value__c=200000);
        
        arrMapList.add(map21);

        RR_Assignment_Mapping__c map22 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[2].Id, User__c=userList[2].Id, Order__c = 3, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=100000, Max_Value__c=200000);
        
        arrMapList.add(map22);
        RR_Assignment_Mapping__c map23 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[2].Id, User__c=userList[3].Id, Order__c = 3, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=0, Max_Value__c=200000);
        
        arrMapList.add(map23);
		
		RR_Assignment_Mapping__c map3 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[3].Id, User__c=userList[2].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=0, Max_Value__c=200000);
        
        arrMapList.add(map3);
        RR_Assignment_Mapping__c map31 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[3].Id, User__c=userList[3].Id, Order__c = 2, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=150000, Max_Value__c=2000000);
        
        arrMapList.add(map31);
        RR_Assignment_Mapping__c map32 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[3].Id, User__c=userList[4].Id, Order__c = 3, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=100000, Max_Value__c=2000000);
        
        arrMapList.add(map32);
        RR_Assignment_Mapping__c map33 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[3].Id, User__c=userList[1].Id, Order__c = 4, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=100000, Max_Value__c=2000000);
        
        arrMapList.add(map33);
        
        RR_Assignment_Mapping__c map34 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[3].Id, User__c=userList[1].Id, Order__c = 4, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=0, Max_Value__c=2000000);
        
        
        arrMapList.add(map34);
        RR_Assignment_Mapping__c map35 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[3].Id, User__c=userList[1].Id, Order__c = 4, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=120000, Max_Value__c=2000000);
        
        arrMapList.add(map35);
        
        RR_Assignment_Mapping__c map4 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[4].Id, User__c=userList[3].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=0);
        
        arrMapList.add(map4);
        
        RR_Assignment_Mapping__c map5 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[5].Id, User__c=userList[4].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=10000, Max_Value__c=2000000);
        
        arrMapList.add(map5);
        
        RR_Assignment_Mapping__c map51 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[5].Id, User__c=userList[3].Id, Order__c = 2, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=20000, Max_Value__c=2000000);
        
        arrMapList.add(map51);
        RR_Assignment_Mapping__c map52 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[5].Id, User__c=userList[2].Id, Order__c = 3, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=20000, Max_Value__c=2000000);
        
        arrMapList.add(map52);
        RR_Assignment_Mapping__c map53 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[5].Id, User__c=userList[1].Id, Order__c = 4, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=10000, Max_Value__c=2000000);
        
        arrMapList.add(map53);
        
        RR_Assignment_Mapping__c map54 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[6].Id, User__c=userList[1].Id, Order__c = 4, 
                                                                     Active__c=true, Type__c='Other', Value_Total__c=10000, Max_Value__c=2000000);
        
        arrMapList.add(map54);
        
        RR_Assignment_Mapping__c map55 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[6].Id, User__c=userList[1].Id, Order__c = 4, 
                                                                     Active__c=true, Type__c='Other', Value_Total__c=10000, Max_Value__c=2000000);
        
        arrMapList.add(map55);
        insert arrMapList;
    }
    
    @isTest
    static void testAssignNextAssignment_LaneFourSLED21() {
        Test.startTest(); 
        RR_Assignment_Rule__c countryRule = [SELECT Id, Always_Use_Next_Assignment__c FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Test Country FR'];
        countryRule.Always_Use_Next_Assignment__c = false;
        update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
                                                                     Active__c=true, Type__c='Other', Value_Total__c=0);
        insert map1;
        Account oldAccount = [Select Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, 
                              Name, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, Onboarding_Complete__c, Owner_Role__c, timezone__c    
                              from account where name = 'Test Account Lane Four SLED21'];
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        rr.getAssignedUser(oldAccount.Id);
        //RoundRobinHandler.resetRuleMappingTotalValue('ARR');
        Test.stopTest();
    }

    //Added below test method as part of GTMS-18362
    @isTest
    static void testAssignNextAssignment_Timezone() {
        Test.startTest(); 

        user assginee = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara ADRs' and IsActive = true order by createddate LIMIT 1];

        RR_Assignment_Rule__c timezoneRule = new RR_Assignment_Rule__c(
                                                Category__c = 'Lane Four',
                                                Type__c = 'Other',
                                                Field_To_Assign_User__c = 'CSM__c',
                                                Timezone__c = 'CST',
                                                Active__c = true,
                                                Rule_Description__c = 'Rule Timezone CST',
                                                Object__c = 'Account',
                                                Next_Assignment__c = assginee.Id,
                                                Order__c = 1);


        insert timezoneRule;

        RR_Assignment_Mapping__c timezoneMap = new RR_Assignment_Mapping__c(
                                                    Assignment_Rule__c = timezoneRule.Id,
                                                    Type__c = 'Other',
                                                    Field_To_Assign__c = 'User',
                                                    User__c = assginee.Id,
                                                    Active__c = true,
                                                    Order__c = 1);

        insert timezoneMap;
        
        timezoneRule.Next_Assignment_Mapping__c = timezoneMap.Id;

        update timezoneRule;

        Account oldAccount = [Select Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, 
                              Name, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, Onboarding_Complete__c, Owner_Role__c, timezone__c    
                              from account where name = 'Timezone Test Account US - Texas'];
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        rr.getAssignedUser(oldAccount.Id);

        Assert.areEqual(rrInfo.ruleId, (String)timezoneRule.Id);
        Assert.areEqual(rrInfo.userId, (String)assginee.Id);

        Test.stopTest();
    }

    //Added below test method as part of GTMS-18362
    @isTest
    static void testAssignNextAssignment_OwnerRole() {

        Test.startTest();

        string roleName = [SELECT Id, name from UserRole where id = :UserInfo.getUserRoleId()].name ?? 'RoleTest';

        string ownerRuleCriteria = '('+roleName.replace(' ','_') +' || US) || (Fleet && !ADR)';

        user assginee = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara ADRs' and IsActive = true order by createddate LIMIT 1];

        RR_Assignment_Rule__c ownerRoleRule = new RR_Assignment_Rule__c(
                                                Category__c = 'Lane Four',
                                                Type__c = 'Other',
                                                Field_To_Assign_User__c = 'CSM__c',
                                                Owner_Role__c = ownerRuleCriteria,
                                                Active__c = true,
                                                Rule_Description__c = 'Rule Owner Role',
                                                Object__c = 'Account',
                                                Next_Assignment__c = assginee.Id,
                                                Order__c = 1);


        insert ownerRoleRule;

        RR_Assignment_Mapping__c ownerRoleMap = new RR_Assignment_Mapping__c(
                                                    Assignment_Rule__c = ownerRoleRule.Id,
                                                    Type__c = 'Other',
                                                    Field_To_Assign__c = 'User',
                                                    User__c = assginee.Id,
                                                    Active__c = true,
                                                    Order__c = 1);

        insert ownerRoleMap;
        
        ownerRoleRule.Next_Assignment_Mapping__c = ownerRoleMap.Id;

        update ownerRoleRule;

        Account oldAccount = [Select Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, 
                              Name, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, Onboarding_Complete__c, Owner_Role__c, timezone__c    
                              from account where name = 'Timezone Test Account US - Texas'];
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        rr.getAssignedUser(oldAccount.Id);

        Assert.areEqual(rrInfo.ruleId, (String)ownerRoleRule.Id);
        Assert.areEqual(rrInfo.userId, (String)assginee.Id);

        Test.stopTest();
    }
    
    @isTest
    static void testAssignNextAssignment_LaneFourNULL() {
        Test.startTest(); 
        RR_Assignment_Rule__c countryRule = [SELECT Id, Order__c, Region__c, Type__c, Min_Value__c, Max_Value__c, Name,
        Always_Use_Next_Assignment__c, Next_Assignment__c, SLED__c, Next_Assignment_Mapping__c,Partner_Team_Alignment__c,
        Is_Owner_Pool_User__c, Global_Geography__c, Assign_CSM__c, Record_Type_Stamp_for_Dupes__c, Use_AND_Condition__c,
        Organization_Size__c, Most_Recent_Source__c, Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c,
                                         Deal_Reg_Account__c, Business_Unit__c, Partner_Persona__c, Which_written_language__c, CS_Tier__c,
                                                       Industry__c, Partner_Program_Segment__c, Billing_Country__c, Billing_State__c,
                                                       Account_Hashtag__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c,
                                                       Inside_Sales_Assignment__c, Number_of_Citizens__c, Number_of_Students__c,Account_Lifetime_ACV__c, 
                                                      Website__c, Domain_Name__c, CSM_Null_Check__c, SLED_Check__c, Onboarding_Complete__c, SIC_Null_Check__c, 
                                                      Owner_Role__c, Timezone__c,Owner_Manager__c,Customer_ARR__c 
                                             FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Lane Four all Null'];
        //countryRule.Always_Use_Next_Assignment__c = false;
        //update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=0);
        insert map1;
        Account oldAccount = [Select Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c,Owner_Manager__c,Customer_ARR__c, 
                              Name, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c,Onboarding_Complete__c, Owner_Role__c, timezone__c  
                              from account where name = 'Test Account Country FR'];
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account');
        Id userid = rr.performLaneFourRuleCheck(oldAccount, countryRule);
        rr.updateRuleDetail();  
        Test.stopTest();
    }
    
    @isTest
    static void testAssignNextAssignment_LaneFourANDCondition() {
        Test.startTest(); 
        RR_Assignment_Rule__c countryRule = [SELECT Id, Order__c, Region__c, Type__c, Min_Value__c, Max_Value__c, Name,
        Always_Use_Next_Assignment__c, Next_Assignment__c, SLED__c, Next_Assignment_Mapping__c,Partner_Team_Alignment__c,
        Is_Owner_Pool_User__c, Global_Geography__c, Assign_CSM__c, Record_Type_Stamp_for_Dupes__c, Use_AND_Condition__c,
        Organization_Size__c, Most_Recent_Source__c, Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c,
                                         Deal_Reg_Account__c, Business_Unit__c, Partner_Persona__c, Which_written_language__c, CS_Tier__c,
                                                       Industry__c, Partner_Program_Segment__c, Billing_Country__c, Billing_State__c,
                                                       Account_Hashtag__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c,
                                                       Inside_Sales_Assignment__c, Number_of_Citizens__c, Number_of_Students__c,Account_Lifetime_ACV__c, 
                                                      Website__c, Domain_Name__c, CSM_Null_Check__c, SLED_Check__c, Onboarding_Complete__c, SIC_Null_Check__c, 
                                                      Owner_Role__c, Timezone__c,Owner_Manager__c,Customer_ARR__c 
                                             FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Lane Four Use AND Condition'];
        //countryRule.Always_Use_Next_Assignment__c = false;
        //update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=0);
        insert map1;
        Account oldAccount = [Select Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c,Owner_Manager__c,Customer_ARR__c, 
                              Name, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, Onboarding_Complete__c, Owner_Role__c, timezone__c   
                              from account where name = 'Test Account Lane Four AND Condition'];
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account');
        Id userid = rr.performLaneFourRuleCheck(oldAccount, countryRule);
        rr.updateRuleDetail();  
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        Test.stopTest();
    }
    
    
    @isTest
    static void testAssignNextAssignment_LaneFourSLED() {
        Test.startTest(); 
        RR_Assignment_Rule__c countryRule = [SELECT Id, Always_Use_Next_Assignment__c FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Test Country FR'];
        countryRule.Always_Use_Next_Assignment__c = false;
        update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=0);
        insert map1;
        Account oldAccount = [Select Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, 
                              Name, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, Onboarding_Complete__c, Owner_Role__c, timezone__c   
                              from account where name = 'Test Account Lane Four SLED'];
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        rr.getAssignedUser(oldAccount.Id);
        RoundRobinHandler.resetRuleMappingTotalValue('ARR');
        Test.stopTest();
    }
    
    
    
    
    @isTest
    static void testAssignNextAssignment_LaneFourNOTNULL() {
        Test.startTest(); 
        RR_Assignment_Rule__c countryRule = [SELECT Id, Always_Use_Next_Assignment__c FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Test Country FR'];
        countryRule.Always_Use_Next_Assignment__c = false;
        update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=0);
        insert map1;
        Account oldAccount = [Select Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, 
                              Name, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, Onboarding_Complete__c, Owner_Role__c, timezone__c   
                              from account where name = 'Test Account Lane Four Not NULL'];
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        RoundRobinHandler.resetRuleMappingTotalValue('ARR');
        //rr.getAssignedUser(oldAccount.Id);
        Test.stopTest();
    }

@isTest
    static void testAssignNextAssignment_LaneFourSLED2() {
        Test.startTest(); 
        RR_Assignment_Rule__c countryRule = [SELECT Id, Always_Use_Next_Assignment__c FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Test Country FR'];
        countryRule.Always_Use_Next_Assignment__c = false;
        update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=0);
        insert map1;
        Account oldAccount = [Select Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, 
                              Name, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, Onboarding_Complete__c, Owner_Role__c, timezone__c   
                              from account where name = 'Test Account Lane Four SLED2'];
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        rr.getAssignedUser(oldAccount.Id);
        //RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        Test.stopTest();
    }
    
    
    
    
    /*@isTest
    static void testAssignNextAssignment_CountryFR() {
        Test.startTest(); 
        RR_Assignment_Rule__c countryRule = [SELECT Id, Always_Use_Next_Assignment__c FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Test Country FR'];
        List<RR_Assignment_Mapping__c> mappingId = [SELECT Id, User__c, Queue_Name__c FROM RR_Assignment_Mapping__c WHERE Assignment_Rule__c =: countryRule.Id];
        countryRule.Always_Use_Next_Assignment__c = false;
        countryRule.Next_Assignment__c = mappingId[0].User__c;
        countryRule.Queue_Name__c = mappingId[0].Queue_Name__c;
        countryRule.Next_Assignment_Mapping__c = mappingId[0].Id;
        update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=0);
        insert map1;
        Account oldAccount = [Select id, billingcountrycode, csm__c, Customer_ARR__c, SLED_Account__c, Renewal_AE__c, Name  
                              from account where name = 'Test Account Country FR'];
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        
        Test.stopTest();
    }
    
    @isTest
    static void testAssignNextAssignment_Country() {
        Test.startTest(); 
        RR_Assignment_Rule__c countryRule = [SELECT Id, Always_Use_Next_Assignment__c FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Test Country'];
        List<RR_Assignment_Mapping__c> mappingId = [SELECT Id, User__c, Queue_Name__c FROM RR_Assignment_Mapping__c WHERE Assignment_Rule__c =: countryRule.Id];
        countryRule.Always_Use_Next_Assignment__c = false;
        countryRule.Next_Assignment__c = mappingId[0].User__c;
        countryRule.Queue_Name__c = mappingId[0].Queue_Name__c;
        countryRule.Next_Assignment_Mapping__c = mappingId[0].Id;
        update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=0);
        insert map1;
        Account oldAccount = [Select id, billingcountrycode, csm__c, Customer_ARR__c, SLED_Account__c, Renewal_AE__c, Name  
                              from account where name = 'Test Account Country'];
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        rr.getAssignedUserByAttributes(oldAccount.Id, oldAccount.SLED_Account__c, oldAccount.billingcountrycode, oldAccount.Customer_ARR__c, oldAccount.Customer_ARR__c, oldAccount.Name);
        Test.stopTest();
    }
    */
    
     @isTest
    static void testAlwaysAssignNextAssignment_Country() {
        Test.startTest(); 
        Account oldAccount = [Select id, billingcountrycode, csm__c, Customer_ARR__c, SLED_Account__c, Renewal_AE__c, Name  
                              from account where name = 'Test Account Country'];
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        
        Test.stopTest();
    }
    
    @isTest
    static void testAssignNextAssignment_ARR500K() {
        Test.startTest(); 
        
        RR_Assignment_Rule__c countryRule = [SELECT Id, Always_Use_Next_Assignment__c, Next_Assignment__c, Min_Value__c, Max_Value__c FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Test 500K'];
        List<RR_Assignment_Mapping__c> mappingId = [SELECT Id, User__c, Queue_Name__c, Assignment_Rule__c FROM RR_Assignment_Mapping__c WHERE Assignment_Rule__c =: countryRule.Id];
        countryRule.Always_Use_Next_Assignment__c = false;
        countryRule.Next_Assignment__c = mappingId[0].User__c;
        countryRule.Queue_Name__c = mappingId[0].Queue_Name__c;
        countryRule.Next_Assignment_Mapping__c = mappingId[0].Id;
        countryRule.Max_Value__c=null;
        update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        //RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
        //                                                             Active__c=true, Type__c='ARR', Value_Total__c=0);
        //insert map1;
        
        Account oldAccount = [Select Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, 
                              Name, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c,Customer_ARR__c, Owner_Role__c, timezone__c   
                              from account where name = 'Test Account ARR 500K'];
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        //rr.performARRBaseRuleCheck(oldAccount, countryRule);
        rr.assignNextAssignmentUserUsingOrder(mappingId[0].Assignment_Rule__c, mappingId[0].User__c, null, false, mappingId[0].Id);
        rr.getAssignedUserByAttributes(oldAccount.Id, oldAccount.SLED_Account__c, oldAccount.billingcountrycode, oldAccount.Customer_ARR__c, oldAccount.Customer_ARR__c, oldAccount.Name);
        Test.stopTest();
    } 
   
    @isTest
    static void testAssignNextAssignment_ARR250K() {
        Test.startTest(); 
        
        RR_Assignment_Rule__c countryRule = [SELECT Id, Always_Use_Next_Assignment__c FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Test 250K'];
        List<RR_Assignment_Mapping__c> mappingId = [SELECT Id, User__c, Queue_Name__c FROM RR_Assignment_Mapping__c WHERE Assignment_Rule__c =: countryRule.Id];
        countryRule.Always_Use_Next_Assignment__c = false;
        countryRule.Next_Assignment__c = mappingId[0].User__c;
        countryRule.Queue_Name__c = mappingId[0].Queue_Name__c;
        countryRule.Next_Assignment_Mapping__c = mappingId[0].Id;
        update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        //RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
        //                                                             Active__c=true, Type__c='ARR', Value_Total__c=0);
        //insert map1;
        Account oldAccount = [Select id, billingcountrycode, csm__c, Customer_ARR__c, SLED_Account__c, Renewal_AE__c, Name  
                              from account where name = 'Test Account ARR 250K'];
        
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        rr.getAssignedUserByAttributes(oldAccount.Id, oldAccount.SLED_Account__c, oldAccount.billingcountrycode, oldAccount.Customer_ARR__c, oldAccount.Customer_ARR__c, oldAccount.Name);
        Test.stopTest();
    }
    
    @isTest
    static void testAssignNextAssignment_ARR150K() {
        Test.startTest(); 
        
        RR_Assignment_Rule__c countryRule = [SELECT Id, Always_Use_Next_Assignment__c FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Test 150K'];
        List<RR_Assignment_Mapping__c> mappingId = [SELECT Id, User__c, Queue_Name__c FROM RR_Assignment_Mapping__c WHERE Assignment_Rule__c =: countryRule.Id];
        countryRule.Always_Use_Next_Assignment__c = false;
        countryRule.Next_Assignment__c = mappingId[0].User__c;
        countryRule.Queue_Name__c = mappingId[0].Queue_Name__c;
        countryRule.Next_Assignment_Mapping__c = mappingId[0].Id;
        update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=0);
        insert map1;
        Account oldAccount = [Select id, billingcountrycode, csm__c, Customer_ARR__c, SLED_Account__c, Renewal_AE__c, Name  
                              from account where name = 'Test Account ARR 100K'];
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        rr.getAssignedUserByAttributes(oldAccount.Id, oldAccount.SLED_Account__c, oldAccount.billingcountrycode, oldAccount.Customer_ARR__c, oldAccount.Customer_ARR__c, oldAccount.Name);
        Test.stopTest();
    }
    
    @isTest
    static void testAssignNextAssignment_ARR150KSLED() {
        Test.startTest(); 
        
        RR_Assignment_Rule__c countryRule = [SELECT Id, Always_Use_Next_Assignment__c FROM RR_Assignment_Rule__c WHERE Rule_Description__c = 'Test 150K SLED'];
        List<RR_Assignment_Mapping__c> mappingId = [SELECT Id, User__c, Queue_Name__c FROM RR_Assignment_Mapping__c WHERE Assignment_Rule__c =: countryRule.Id];
        countryRule.Always_Use_Next_Assignment__c = false;
        countryRule.Next_Assignment__c = mappingId[0].User__c;
        countryRule.Queue_Name__c = mappingId[0].Queue_Name__c;
        countryRule.Next_Assignment_Mapping__c = mappingId[0].Id;
        update countryRule;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        //RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=countryRule.Id, User__c=userList[0].Id, Order__c=2, 
        //                                                             Active__c=true, Type__c='ARR', Value_Total__c=0);
        //insert map1;
        Account oldAccount = [Select id, billingcountrycode, csm__c, Customer_ARR__c, SLED_Account__c, Renewal_AE__c, Name  
                              from account where name = 'Test Account municipal ARR 100K'];
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        rr.getAssignedUserByAttributes(oldAccount.Id, oldAccount.SLED_Account__c, oldAccount.billingcountrycode, oldAccount.Customer_ARR__c, oldAccount.Customer_ARR__c, oldAccount.Name);
        Test.stopTest();
    }

    
    @isTest
    static void testAlwaysAssignNextAssignment_ARR500K() {
        Test.startTest(); 
        
        Account oldAccount = [Select Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState, BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, Name, Customer_ARR__c, 
                       Owner_Role__c, timezone__c    
                              from account where name = 'Test Account ARR 500K'];
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        
        Test.stopTest();
    }
    
    @isTest
    static void testAlwaysAssignNextAssignment_ARR250K() {
        Test.startTest(); 
        
        Account oldAccount = [Select id, billingcountrycode, csm__c, Customer_ARR__c, SLED_Account__c, Renewal_AE__c, Name  
                              from account where name = 'Test Account ARR 250K'];
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        
        Test.stopTest();
    }
    
    @isTest
    static void testAlwaysAssignNextAssignment_ARR150K() {
        Test.startTest(); 
        
        Account oldAccount = [Select id, billingcountrycode, csm__c, Customer_ARR__c, SLED_Account__c, Renewal_AE__c, Name  
                              from account where name = 'Test Account ARR 100K'];
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        
        Test.stopTest();
    }
    
    @isTest
    static void testAlwaysAssignNextAssignment_ARR150KSLED() {
        Test.startTest(); 
        
        Account oldAccount = [Select id, billingcountrycode, csm__c, Customer_ARR__c, SLED_Account__c, Renewal_AE__c, Name  
                              from account where name = 'Test Account municipal ARR 100K'];
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(oldAccount);
        rr.updateRuleDetail();  
        
        Test.stopTest();
    }
   
    @isTest
    static void testAlwaysAssignNextAssignment_ARRRecords() {
        Test.startTest(); 
        
        List<Account> oldAccount = [Select Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, 
                              Name, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c,Customer_ARR__c, Owner_Role__c, timezone__c  
                              from account where name Like 'Test Account ARR%'];
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account');
        For(Account obj: oldAccount) {
            RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
            rrInfo = rr.getAssignedUser(obj);
        }
        
        rr.updateRuleDetail();  
        
        List<RoundRobinHandler.RoundRobinFlowInput> rrInputList = new List<RoundRobinHandler.RoundRobinFlowInput>();
        RoundRobinHandler.RoundRobinFlowInput rrInput = new RoundRobinHandler.RoundRobinFlowInput();
        rrInput.accountId = oldAccount[0].Id;
        rrInputList.add(rrInput);
		RoundRobinHandler.checkIfCustomRoutingIsToBeUsed(rrInputList);
        
        Test.stopTest();
    }
	
    @isTest
    static void updateQueueUserAssignment_Test() {
        Test.startTest();
        Map<Id,RR_Assignment_Rule__c> countryRuleMap = new Map<Id,RR_Assignment_Rule__c>([SELECT Id, Always_Use_Next_Assignment__c FROM RR_Assignment_Rule__c 
                                                                                 WHERE Rule_Description__c = 'Test 150K SLED']);
        
        //RoundRobinHandler rr0 = new RoundRobinHandler(countryRuleMap.keySet());
        
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        RoundRobinHandler.updateQueueUserAssignment('TEST_AE_QUEUE', userList[0].Id);
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline','Account', false);
        RoundRobinHandler rr2 = new RoundRobinHandler(countryRuleMap.keySet());
        Test.stopTest();
    }
    
    @isTest
    static void methodCall_Test() {
        Test.startTest();
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara Sales - NA US AE2' and IsActive = true LIMIT 1];
        Set<Id> setUser = new Set<Id>();
        setUser.add(userList[0].Id);
        RoundRobinHandler.updateRuleNextAssignmentFuture(setUser, true);
        RoundRobinHandler rr = new RoundRobinHandler();
        RoundRobinHandler rr2 = new RoundRobinHandler('Automating Pipeline','Account', 'OwnerId');
        rr2.validateFieldValue('>=99', 100.0);
        rr2.validateFieldValue('<=101', 100.0);
        rr2.validateFieldValue('> 50', 100.0);
        rr2.validateFieldValue('< 101', 100.0);
        rr2.validateAccountAttribute('>=99 AND <=101', 100.00);
        Test.stopTest();
    }

    @isTest
    static void validateARRConditionTest(){
        String ruleDetail1='<=10000';
        String ruleDetail2='>=10000';
        String ruleDetail3='==10000';
        String ruleDetail4='<10000';
        String ruleDetail5='>10000';
        Decimal accntFieldValue=11000;
        Decimal accntFieldValue1=9000;
        Decimal accntFieldValue2=15000;
        Test.startTest();
        RoundRobinHandler rr=new RoundRobinHandler();
        rr.validateARRCondition(ruleDetail1, accntFieldValue);
        rr.validateARRCondition(ruleDetail2, accntFieldValue);
        rr.validateARRCondition(ruleDetail3, accntFieldValue);
        rr.validateARRCondition(ruleDetail4, accntFieldValue1);
        rr.validateARRCondition(ruleDetail5, accntFieldValue1);
        Test.stopTest();
    }
}