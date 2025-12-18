@IsTest
public without sharing class OpportunityToSELogsServiceTest {
    
@TestSetup    
 
    public static void setupTestUsers() {
        // Query UserRole and Profile in separate SOQL calls
        Id userRoleId = [SELECT Id FROM UserRole WHERE Name LIKE '%Fleet IS AE2 NA US%' LIMIT 1].Id;
        Id profileId = [SELECT Id FROM Profile WHERE Name LIKE '%System Administrator%' LIMIT 1].Id;

        // Create test users
        User testUsers = new User(
                LastName = 'McGrath',
                Alias = 'test1',
                Email = 'tuser@test1.com',
                Username = 'tuser' + DateTime.now().millisecond() + '@test.com', // Unique username
                CommunityNickname = 'User16529768062775798018',
                UserRoleId = userRoleId,
                ProfileId = profileId, 
                Territory__c = 'North America', // Ensure this field exists
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'ISO-8859-1',
            EmployeeNumber = 'NA'
        );
     insert testUsers;
    }
    
       
    public static Opportunity opp;

    public static void buildBasicOpp(){
            User testUser = [SELECT Id FROM User WHERE Email = 'tuser@test1.com' LIMIT 1];
        System.runAs(testUser) {
        opp = new Opportunity(
            Id = TestFactory.getFakeId(Opportunity.getSObjectType()),
            CurrencyIsoCode = 'USD',
            Probability = 50,
            Owner_Role_Copy__c = 'Enterprise',
            Amount = 1000000,
            License_Term__c = 11
        );
        
        opp.TrialResolutionOppty__c = TestFactory.getFakeId(Opportunity.getSObjectType());
        opp.TrialResolutionOppty__r = new Opportunity(
            Id = opp.TrialResolutionOppty__c,
            CloseDate = System.today().addDays(30)
        );
        }
    }
    public static void buildEnterpriseTrialOpp(){
            User testUser = [SELECT Id FROM User WHERE Email = 'tuser@test1.com' LIMIT 1];
        System.runAs(testUser) {
        buildBasicOpp();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Trial').getRecordTypeId();
        opp.StageName = 'Closed Won';

        Formula.recalculateFormulas(new List<Opportunity>{opp});
        }
    }

    public static void buildEnterpriseStandardOpp(){
            User testUser = [SELECT Id FROM User WHERE Email = 'tuser@test1.com' LIMIT 1];
        System.runAs(testUser) {
        buildBasicOpp();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standard_Opportunity').getRecordTypeId();
        opp.StageName = 'Trial';

        Formula.recalculateFormulas(new List<Opportunity>{opp});
        }
    }

    public static void buildNonEnterpriseStandardOpp(){
         User testUser = [SELECT Id FROM User WHERE Email = 'tuser@test1.com' LIMIT 1];
        System.runAs(testUser) {
        buildBasicOpp();
        opp.Owner_Role_Copy__c = 'SLED';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standard_Opportunity').getRecordTypeId();
        opp.StageName = 'Trial';
        
        Formula.recalculateFormulas(new List<Opportunity>{opp});
        }
    }

    @IsTest
    public static void testSyncService(){
         User testUser = [SELECT Id FROM User WHERE Email = 'tuser@test1.com' LIMIT 1];
        System.runAs(testUser) {
        DMLWrapper.intializeUnitOfWork(new List<Schema.SObjectType>{
            Async_Request__c.SObjectType
        });

        buildEnterpriseTrialOpp();
        Opportunity enterpriseTrialOpp = opp;
        buildNonEnterpriseStandardOpp();
        Opportunity nonEnterpriseOpp = opp;

        new OpportunityToSELogsService().runAfter(new Map<Id, Opportunity>{
            enterpriseTrialOpp.Id => enterpriseTrialOpp,
            nonEnterpriseOpp.Id => nonEnterpriseOpp
        });
        //Test.stopTest();
    }
    }

    @IsTest
    public static void testAsyncService_SELogsCreation(){
         User testUser = [SELECT Id FROM User WHERE Email = 'tuser@test1.com' LIMIT 1];
        System.runAs(testUser) {
        buildEnterpriseTrialOpp();
        Opportunity enterpriseTrialOpp = opp;
        buildEnterpriseStandardOpp();
        Opportunity enterpriseStandardOpp = opp;
        buildNonEnterpriseStandardOpp();
        Opportunity trialOpp = opp; 

        OpportunityToSELogsServiceAsync.PERFORM_DMLS = false;
        OpportunityToSELogsServiceAsync service = new OpportunityToSELogsServiceAsync();
        service.queriedOppMap = new Map<Id, Opportunity>{
            enterpriseTrialOpp.Id => enterpriseTrialOpp,
            enterpriseStandardOpp.Id => enterpriseStandardOpp,
            trialOpp.Id => trialOpp
        };

        service.execute(new Async_Request__c(
            Params__c = enterpriseTrialOpp.Id+';'+enterpriseStandardOpp.Id+';'+trialOpp.Id+';',
            Options__c = JSON.serialize(new OpportunityToSELogsServiceAsync.Options('Insert'))
        ));
    }
    }
}