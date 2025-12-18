/*
* @Author : Siddharth Kumar Mishra
* @Description:- Test class for Batch_LEAPCloseOpportunities ( GTMS - 7001  -  4/19/2022  -  Move opportunities to "Closed Lost" if all conditions are met )
*/
@IsTest
public class Batch_LEAPCloseOpportunitiesTest
{
    @TestSetup 
    public static void setup()
    {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       // Insert account as current user
        System.runAs (thisUser) {
        
        //Test User
        User testUser = new User();
        testUser.lastName = 'Test User 001';
        testUser.Alias = 'test';
        testUser.Email = 'tuser@test.com';
        testUser.Username = 'tuser@test001tests.com';
        testUser.CommunityNickname = 'User16529768062775798018';
        testUser.UserRoleId = [select Id,name from UserRole where name like '%Fleet IS AE2 NA US%' limit 1].id;
        testUser.ProfileId = [select Id,name from Profile where name like '%Samsara Sales Management - New System%' limit 1].id;
        testUser.EmployeeNumber = '9000234';
		testUser.Territory__c = 'North America';
		testuser.TimeZone__c = 'America/Los_Angeles';
		testuser.TimeZoneSidKey = 'America/Los_Angeles';
		testuser.LocaleSidKey = 'en_US';
		testuser.LanguageLocaleKey = 'en_US';
		testuser.EmailEncodingKey = '	ISO-8859-1';
        testuser.Leave_Return_Date__c = null;
        Insert testUser;

        //Executing as testUser as Owner needs to be an User with role containing 'Fleet IS AE1 NA US' or 'Fleet IS AE2 NA US'
        Account testAcc = new Account();
        testAcc.name = 'Test Account 001';
        testAcc.Last_Meaningful_Engagement_Date__c = null;
        testAcc.Organization_Size__c = '1 - 99';
        testAcc.BillingCountry = 'India';
        
        
        Insert testAcc;
        
        //Test opportunity
        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'Test Opportunity 001';
        testOpp.AccountId = testAcc.Id;
        testOpp.RecordTypeId = [Select Id,name from RecordType where SobjectType = 'Opportunity' AND name = 'Standard Opportunity'].Id;
        testOpp.Type = 'Revenue Opportunity';
        testOpp.StageName = 'Trial';
        testOpp.CloseDate = Date.today().addDays(-10);
        testOpp.Shipping_Country__c = 'India';
        testOpp.Shipping_State__c = 'Maharashtra';
        testOpp.OwnerId = testUser.id;
        //testOpp.amount = 10000;         
        //testOpp.Amount_Number__c = 10000;

        Insert testOpp;

        Opportunity testOpp2 = new Opportunity();
        testOpp2.Name = 'Test Opportunity 002';
        testOpp2.AccountId = testAcc.Id;
        testOpp2.RecordTypeId = [Select Id,name from RecordType where SobjectType = 'Opportunity' AND name = 'Standard Opportunity'].Id;
        testOpp2.Type = 'Revenue Opportunity';
        testOpp2.StageName = 'Trial';
        testOpp2.CloseDate = Date.today().addDays(-10);
        testOpp2.Shipping_Country__c = 'India';
        testOpp2.Shipping_State__c = 'Maharashtra';
        testOpp2.OwnerId = testUser.id;
        Insert testOpp2;
        
        testAcc.Account_Assignment_Date__c = System.now().addDays(-100);
        update testAcc;        

        Opportunity testOpp3 = new Opportunity();
        testOpp3.Name = 'Test free trial Opportunity 001';
        testOpp3.AccountId = testAcc.Id;
        testOpp3.RecordTypeId = [Select Id,name from RecordType where SobjectType = 'Opportunity' AND name = 'Trial'].Id;
        testOpp3.Type = 'Free Trial Opportunity';
        testOpp3.StageName = 'Closed Won';
        testOpp3.CloseDate = Date.today();
        testOpp3.Shipping_Country__c = 'India';
        testOpp3.Shipping_State__c = 'Maharashtra';
        testOpp3.TrialResolutionOppty__c = testOpp2.id;
        testOpp3.Trial_Status__c ='Open';
        testOpp3.OwnerId = testUser.id;
        Insert testOpp3;
        System.debug('testOpp2.TrialResolutionOppty__c ---->'+testOpp3.TrialResolutionOppty__c);  
        }      
    }
    
    @IsTest
    static void testMethod01()
    {
        //Opportunity oldOpp = [select id,name,StageName,Owner.UserRole.name from Opportunity where name = 'Test Opportunity 001' limit 1];
        //Account acc = [Select id,name from Account where name = 'Test Account 001' Limit 1];
        test.startTest();
        //database.executebatch((new Batch_LEAPCloseOpportunities()),20);
        Batch_LEAPCloseOpportunities sch = new Batch_LEAPCloseOpportunities();
        sch.execute(null);
        test.stopTest();
        
        Opportunity newOpp1 = [select id,name,StageName from Opportunity where name = 'Test Opportunity 001' limit 1];
        Opportunity newOpp2 = [select id,name,StageName from Opportunity where name = 'Test Opportunity 002' limit 1];
        
        system.assertEquals('Closed Lost', newOpp1.StageName);
        system.assertEquals('Closed Lost', newOpp2.StageName);
    }    
}