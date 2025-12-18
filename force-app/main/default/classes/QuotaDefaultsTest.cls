/**
 * Created by henryzhao on 2020-12-18.
 */

@IsTest
private class QuotaDefaultsTest {
    @IsTest
    static void testNullDefaultsFromUser() {
        /*Arrange*/
        Id managerId = TestFactory.getFakeId(User.getSObjectType());
        UserRole mockRole = new UserRole(Name = 'FakeRole');
        User usr = (User) TestFactory.createSObject(new User(
                Id = TestFactory.getFakeId(User.getSObjectType()),
                Office_Location__c = 'FakeLocation',
                ManagerId = managerId,
                Territory__c = 'FakeTerritory',
                Business_Unit__c = 'FakeBusiness',
                Role_Start_Date__c = Date.today(),
                UserRole = mockRole,
                ADR_Segment_Alignment__c = 'FakeSegment'
        ));
        Quota__c testQuota = new Quota__c(
                Id = TestFactory.getFakeId(Quota__c.getSObjectType()),
                User__c = usr.Id,
                User__r = usr
        );
        QuotaDefaults defaults = new QuotaDefaults(new List<Quota__c>{
                testQuota
        });
        defaults.quotaToUserMap.put(testQuota.Id, usr);
        /*Act*/
        defaults.onApplyDefaults(testQuota,null);

        /*Assert*/
        System.assertEquals(usr.Id, testQuota.OwnerId);
        System.assertEquals(usr.Office_Location__c, testQuota.Office_Location__c);
        System.assertEquals(usr.ManagerId, testQuota.Manager__c);
        System.assertEquals(usr.Territory__c, testQuota.Geography__c);
        System.assertEquals(usr.Business_Unit__c, testQuota.Industry__c);
        System.assertEquals(usr.Territory__c, testQuota.Territory__c);
        System.assertEquals(usr.Role_Start_Date__c, testQuota.Role_Start_Date__c);
        System.assertEquals(usr.UserRole.Name, testQuota.Role_at_Start_of_Fiscal_Period__c);
        System.assertEquals(usr.ADR_Segment_Alignment__c, testQuota.ADR_Segment_Alignment__c);
    }

    @IsTest
    static void testNonNullDefaultsFromUser() {
        /*Arrange*/
        Id managerId = TestFactory.getFakeId(User.getSObjectType());
        UserRole mockRole = new UserRole(Name = 'FakeRole');
        User usr = (User) TestFactory.createSObject(new User(
                Id = TestFactory.getFakeId(User.getSObjectType()),
                Office_Location__c = 'FakeLocation',
                ManagerId = managerId,
                Territory__c = 'FakeTerritory',
                Business_Unit__c = 'FakeBusiness',
                Role_Start_Date__c = Date.today(),
                UserRole = mockRole,
                ADR_Segment_Alignment__c = 'FakeSegment'
        ));
        Id realManagerId = TestFactory.getFakeId(User.getSObjectType());
        Quota__c testQuota = new Quota__c(
                Id = TestFactory.getFakeId(Quota__c.getSObjectType()),
                User__c = usr.Id,
                User__r = usr,
                OwnerId = TestFactory.getFakeId(User.getSObjectType()),
                Office_Location__c = 'RealLocation',
                Manager__c = realManagerId,
                Geography__c = 'RealGeography',
                Industry__c = 'RealIndustry',
                Territory__c = 'RealTerritory',
                Role_Start_Date__c = Date.today().addDays(-1),
                Role_at_Start_of_Fiscal_Period__c = 'RealRole',
                ADR_Segment_Alignment__c = 'RealSegment'
        );
        QuotaDefaults defaults = new QuotaDefaults(new List<Quota__c>{
                testQuota
        });
        defaults.quotaToUserMap.put(testQuota.Id, usr);
        /*Act*/
        defaults.onApplyDefaults(testQuota,null);

        /*Assert*/
        System.assertEquals(usr.Id, testQuota.OwnerId);
        System.assertEquals(usr.ADR_Segment_Alignment__c, testQuota.ADR_Segment_Alignment__c);
        System.assertEquals('RealLocation', testQuota.Office_Location__c);
        System.assertEquals(realManagerId, testQuota.Manager__c);
        System.assertEquals('RealGeography', testQuota.Geography__c);
        System.assertEquals('RealIndustry', testQuota.Industry__c);
        System.assertEquals('RealTerritory', testQuota.Territory__c);
        System.assertEquals(Date.today().addDays(-1), testQuota.Role_Start_Date__c);
        System.assertEquals('FakeRole', testQuota.Role_at_Start_of_Fiscal_Period__c);
    }

    @IsTest
    static void testSetAdjRoleStartDateRoundDown() {
        /*Arrange*/
        final Date startDate = Date.newInstance(2020, 1, 1);
        Quota__c testQuota = new Quota__c(
                Id = TestFactory.getFakeId(Quota__c.getSObjectType()),
                Role_at_Start_of_Fiscal_Period__c = 'AE',
                Adj_Role_Start_Date_v2__c = null,
                Role_Start_Date__c = startDate
        );
        QuotaDefaults defaults = new QuotaDefaults(new List<Quota__c>{
                testQuota
        });
        /*Act*/
        defaults.onApplyDefaults(testQuota,null);

        /*Assert*/
        System.assertEquals(1, testQuota.Adj_Role_Start_Date_v2__c.day());
        System.assertEquals(startDate.month(), testQuota.Adj_Role_Start_Date_v2__c.month());
    }

    @IsTest
    static void testSetAdjRoleStartDateRoundUp() {
        /*Arrange*/
        final Date startDate = Date.newInstance(2020, 1, 16);
        Quota__c testQuota = new Quota__c(
                Id = TestFactory.getFakeId(Quota__c.getSObjectType()),
                Role_at_Start_of_Fiscal_Period__c = 'ADR',
                Adj_Role_Start_Date_v2__c = null,
                Role_Start_Date__c = startDate,
            	Fiscal_Period_Start_Date__c = date.today(),
        		Quota_Period__c='Q4',
                Quota__c = 1000,
                Q4_Quota__c = 1000);

        QuotaDefaults defaults = new QuotaDefaults(new List<Quota__c>{
                testQuota
        });
        /*Act*/
        defaults.onApplyDefaults(testQuota,null);

        /*Assert*/
        System.assertEquals(1, testQuota.Adj_Role_Start_Date_v2__c.day());
        System.assertEquals(startDate.month() + 1, testQuota.Adj_Role_Start_Date_v2__c.month());
    }
    
    @isTest
    static void insertQuotatest() {
        String UserQuery;    
        User testUser;

        UserQuery = 'SELECT Id, Name, Role_Start_Date__c, UserRole.Name FROM User WHERE UserRole.Name LIKE \'%Manager%\' AND IsActive = true LIMIT 1';
        

        testUser = database.query(UserQuery);

        Quota__c newQuota = new Quota__c(   User__c = testUser.Id, 
                                            Role_Start_Date__c = testUser.Role_Start_Date__c,
                                            Role_at_Start_of_Fiscal_Period__c = testUser.UserRole.Name,
                                            Fiscal_Period_Start_Date__c = System.now().date(), 
                                            Fiscal_Period_End_Date__c = System.now().date()+30, 
                                            Fiscal_Period__c='Q4-3000',
                                        	Quota_Period__c='Q3',
                                         	Quota__c = 1000,
                                        	Q3_Quota__c = 1000);
        
        Test.startTest();
        insert newQuota;
        Test.stopTest();
    }
    
    @isTest
     static void testAfterUpdate() {
        // Create test data
        String UserQuery;    
        User testUser;

        UserQuery = 'SELECT Id, Name, Role_Start_Date__c, UserRole.Name FROM User WHERE UserRole.Name LIKE \'%Manager%\' AND IsActive = true LIMIT 1';
        

        testUser = database.query(UserQuery);

        Quota__c newQuota = new Quota__c(   User__c = testUser.Id, 
                                            Role_Start_Date__c = testUser.Role_Start_Date__c,
                                            Role_at_Start_of_Fiscal_Period__c = testUser.UserRole.Name,
                                            Fiscal_Period_Start_Date__c = System.now().date(), 
                                            Fiscal_Period_End_Date__c = System.now().date()+30, 
                                            Fiscal_Period__c='Q3-3000',
                                        	Quota_Period__c='Q2',
                                         	Quota__c = 1000,
                                        	Q2_Quota__c = 1000);
        
         //insert method
        insert newQuota;
        
        // Call afterUpdate method
        Test.startTest();
        List<Quota__c> quotaList = new List<Quota__c>();
        newQuota.Quota__c = 200;
        quotaList.add(newQuota);
        update quotaList;
        Test.stopTest();
        
        
    }
    @isTest
    static void Quotadefaultstest() {
        String UserQuery;    
        User testUser;

        UserQuery = 'SELECT Id, Name, Role_Start_Date__c, UserRole.Name FROM User WHERE UserRole.Name LIKE \'%Manager%\' AND IsActive = true LIMIT 1';
        

        testUser = database.query(UserQuery);

        Quota__c newQuota = new Quota__c(   User__c = testUser.Id, 
                                            Role_Start_Date__c = testUser.Role_Start_Date__c,
                                            Role_at_Start_of_Fiscal_Period__c = testUser.UserRole.Name,
                                            Fiscal_Period_Start_Date__c = System.now().date(), 
                                            Fiscal_Period_End_Date__c = System.now().date()+30, 
                                            Fiscal_Period__c='Q2-3000',
                                        	Quota_Period__c='FY',
                                         	Quota__c = 0,
                                         	Q1_Quota__c = 0,
                                         	Q2_Quota__c = 0,
                                         	Q3_Quota__c = 0,
                                        	Q4_Quota__c = 0);
        
        Test.startTest();
        insert newQuota;
        Test.stopTest();
    }
@isTest
    static void Quotadefaultstest1() {
        String UserQuery;    
        User testUser;

        UserQuery = 'SELECT Id, Name, Role_Start_Date__c, UserRole.Name FROM User WHERE UserRole.Name LIKE \'%Manager%\' AND IsActive = true LIMIT 1';
        

        testUser = database.query(UserQuery);

        Quota__c newQuota = new Quota__c(   User__c = testUser.Id, 
                                            Role_Start_Date__c = testUser.Role_Start_Date__c,
                                            Role_at_Start_of_Fiscal_Period__c = testUser.UserRole.Name,
                                            Fiscal_Period_Start_Date__c = System.now().date(), 
                                            Fiscal_Period_End_Date__c = System.now().date()+30, 
                                            Fiscal_Period__c='Q2-3000',
                                        	Quota_Period__c='Q4',
                                         	Quota__c = 400,
                                         	Q1_Quota__c = 0,
                                         	Q2_Quota__c = 0,
                                         	Q3_Quota__c = 0,
                                        	Q4_Quota__c = 400);
        
        Test.startTest();
        insert newQuota;
        Test.stopTest();
    }
    @isTest
    static void Quotadefaultstest2() {
        String UserQuery;    
        User testUser;

        UserQuery = 'SELECT Id, Name, Role_Start_Date__c, UserRole.Name FROM User WHERE UserRole.Name LIKE \'%Manager%\' AND IsActive = true LIMIT 1';
        

        testUser = database.query(UserQuery);

        Quota__c newQuota = new Quota__c(   User__c = testUser.Id, 
                                            Role_Start_Date__c = testUser.Role_Start_Date__c,
                                            Role_at_Start_of_Fiscal_Period__c = testUser.UserRole.Name,
                                            Fiscal_Period_Start_Date__c = System.now().date(), 
                                            Fiscal_Period_End_Date__c = System.now().date()+30, 
                                            Fiscal_Period__c='Q1-3000',
                                        	Quota_Period__c='Q1',
                                         	Quota__c = 400,
                                         	Q1_Quota__c = 400,
                                         	Q2_Quota__c = 0,
                                         	Q3_Quota__c = 0,
                                        	Q4_Quota__c = 0);
        
        Test.startTest();
        insert newQuota;
        Test.stopTest();
    }

    @isTest
    static void setChangedTrialQuotaOnUserTest() {
        String UserQuery;    
        User testUser;

        UserQuery = 'SELECT Id, Name, Role_Start_Date__c, UserRole.Name FROM User WHERE UserRole.Name LIKE \'%Manager%\' AND IsActive = true LIMIT 1';
        

        testUser = database.query(UserQuery);

        Quota__c newQuota = new Quota__c(   User__c = testUser.Id, 
                                            Role_Start_Date__c = testUser.Role_Start_Date__c,
                                            Role_at_Start_of_Fiscal_Period__c = testUser.UserRole.Name,
                                            Fiscal_Period_Start_Date__c = System.now().date(), 
                                            Fiscal_Period_End_Date__c = System.now().date()+30, 
                                            Fiscal_Period__c='Q1-3000',
                                        	Quota_Period__c='Q1',
                                         	ADR_Quota__c = 400,
                                         	Q1_Quota__c = 400,
                                         	Q2_Quota__c = 0,
                                         	Q3_Quota__c = 0,
                                        	Q4_Quota__c = 0,
                                        	Trial_Quota__c =100);
        
        Test.startTest();
        
        insert newQuota;
        newQuota.ADR_Quota__c = 500;
        newQuota.Fiscal_Period_End_Date__c =System.now().date()+10;
        update newQuota;
        
        Test.stopTest();
    }

	@isTest
    static void setQuotaOnUserTest() {
        String UserQuery;    
        User testUser;

        UserQuery = 'SELECT Id, Name, Role_Start_Date__c, UserRole.Name FROM User WHERE UserRole.Name LIKE \'%Manager%\' AND IsActive = true LIMIT 1';
        

        testUser = database.query(UserQuery);

        Quota__c newQuota = new Quota__c(   User__c = testUser.Id, 
                                            Role_Start_Date__c = testUser.Role_Start_Date__c,
                                            Role_at_Start_of_Fiscal_Period__c = testUser.UserRole.Name,
                                            Fiscal_Period_Start_Date__c = System.now().date(), 
                                            Fiscal_Period_End_Date__c = System.now().date()-30, 
                                            Fiscal_Period__c='Q1-3000',
                                        	Quota_Period__c='Q1',
                                         	ADR_Quota__c = 400,
                                         	Q1_Quota__c = 400,
                                         	Q2_Quota__c = 0,
                                         	Q3_Quota__c = 0,
                                        	Q4_Quota__c = 0,
                                        	Trial_Quota__c =100);
        
        Test.startTest();
        
        insert newQuota;
        
        Test.stopTest();
    }
    
}