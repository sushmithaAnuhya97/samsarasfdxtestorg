@IsTest
public with sharing class GS_OpportunityServiceTest {
    

    private static String FREE_TRIAL_OPP_NAME = 'Opp Testers 1 Inc';
    private static String REVENUE_OPPORTUNITY = 'Opp Testers 2 Inc';
    private static String RESOLUTION_OPP_NAME = 'Resolution Opp';


    @TestSetup
    static void setup(){
        GS_GlobalAutomationSettingsTest.createAutomationTestSetting();

        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
         
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        newAccounts.add(accountOne);
        
        Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                BillingState='California',
                                BillingCountry = 'United States',
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                Industry = 'Other');
        newAccounts.add(accountTwo);

        insert newAccounts;
        
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        newContacts.add(contactOne);
        
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'test@test.com'));
        newContacts.add(contactTwo);

        insert newContacts;
        
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
        shippingAddressList.add(sa);
        Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = accountOne.Id);
        shippingAddressList.add(sa2);

        insert shippingAddressList;

        ADR_Transfer_Log__c log = new ADR_Transfer_Log__c();
        insert log;

        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                    Type = 'Free Trial Opportunity',
                                                    Name = FREE_TRIAL_OPP_NAME,
                                                    StageName = 'Proposal',
                                                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                    //Shipping_Contact__c = contactOne.Id, 
                                                    Selected_Payment_Type__c = 'Direct Annual',
                                                    Price_Book_Name__c = 'Standard',
                                                    Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 

        Opportunity opportunityTwo = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id, 
                                                    Type = 'Revenue Opportunity',
                                                    Name = REVENUE_OPPORTUNITY,
                                                    StageName = 'Proposal',
                                                    //Shipping_Contact__c = contactTwo.Id, 
                                                    Price_Book_Name__c = 'Standard',
                                                    Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityTwo);     
        
        Opportunity opportunityThree = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                    Type = 'Revenue Opportunity',
                                                    Name = 'Opp Testers 3 Inc',
                                                    StageName = 'Proposal',
                                                    //Shipping_Contact__c = contactOne.Id, 
                                                    Price_Book_Name__c = 'Standard',
                                                    Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityThree);  

        Opportunity resolutionOpp = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                Type = 'Free Trial Opportunity',
                                                Name = RESOLUTION_OPP_NAME,
                                                StageName = 'Closed Won',
                                                Probability = 100,
                                                ADR_Transfer__c = log.Id,
                                                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                Send_Invoice__c = false));
        newOpportunities.add(resolutionOpp);

        Opportunity buyoutOpp = (Opportunity) TestFactory.createSObject(new Opportunity(
            Type = 'Rebate',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
            Name = 'Buyout',
            AccountId = accountOne.Id,
            Configuration_Segment__c = 'Non Express',
            StageName = 'Closed Date',
            CloseDate = System.today(),
            Probability = 100,
            Rebate_Type__c = 'Buyout',
            Amount = -1,
            Shipping_Country__c = 'United States'
        ));
        newOpportunities.add(buyoutOpp);

        Opportunity subsidyOpp = (Opportunity) TestFactory.createSObject(new Opportunity(
            Type = 'Rebate',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
            Name = 'Subsidy',
            AccountId = accountOne.Id,
            Configuration_Segment__c = 'Non Express',
            StageName = 'Closed Date',
            CloseDate = System.today(),
            Probability = 100,
            Rebate_Type__c = 'Subsidy',
            Amount = -1,
            Shipping_Country__c = 'United States'
        ));
        newOpportunities.add(subsidyOpp);
        insert newOpportunities;
    }

    private static void initializeUoW(){
        DMLWrapper.intializeUnitOfWork(new List<Schema.SObjectType>{
            Async_Request__c.getSObjectType(),
            Opportunity.getSObjectType()
        });
    }

    private static void publishDML(){
        DMLWrapper.publishDML();
    }

    private static Set<Id> getListIds(List<SObject> sobjectList){
        Set<Id> returnList = new Set<Id>();
        for (SObject obj : sobjectList){
            returnList.add(obj.Id);
        }

        return returnList;
    }

    @isTest
    public static void test_sync_createAsyncRecords(){
        Opportunity opp = (new GS_OpportunitySelector(false)).loadOpportunityWithItems(
            getListIds([SELECT Id FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1])
        )[0];

        Opportunity oldOpp = opp.clone(true, true);
        oldOpp.License_Term__c = 101010101;

        Test.startTest();
        Integer amountOfAsyncRecordsBefore = [SELECT COUNT() FROM Async_Request__c];
        initializeUoW();
        System.debug('On before running the service');
        (new GS_OpportunityService()).runOpportunityServiceAsyncFunctions(new List<Opportunity>{opp}, new Map<Id, Opportunity>(new List<Opportunity>{oldOpp}), 'AFTER_INSERT_OPERATIONS');
        System.debug('On after running the service');
        publishDML();
        //Test.stopTest();

        String expectedConditionsInJson = JSON.serialize(
            new GS_OpportunityServiceAsync.Options(
                'AFTER_INSERT_OPERATIONS',
                new Map<Id,GS_OpportunityServiceAsync.ConsolidatedProcessAsyncConditions>{
                    opp.Id => new GS_OpportunityServiceAsync.ConsolidatedProcessAsyncConditions(false,true,false,false)
                }
            )
        );

        List<Async_Request__c> asyncRequestRecords = [
            SELECT Id, Params__c, Options__c
            FROM Async_Request__c
            ORDER BY CreatedDate DESC
        ];
        System.assertEquals(amountOfAsyncRecordsBefore + 1, asyncRequestRecords.size());
        System.assertEquals(String.valueOf(opp.Id).substring(0, 15)+';', asyncRequestRecords[0].Params__c);
        System.assertEquals(expectedConditionsInJson, asyncRequestRecords[0].Options__c);
    }

    @isTest
    public static void test_async_afterInsertOperations_ClariOppTeams(){
        Integer clariOppAmountOnSetup = [SELECT COUNT() FROM Clari_Opp__c];

        String oppId = String.valueOf(new List<Id>(getListIds([SELECT Id FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1]))[0]);

        Test.startTest();
        (new GS_OpportunityServiceAsync()).execute(new Async_Request__c(
                Params__c = oppId+';',
                Options__c = JSON.serialize(new GS_OpportunityServiceAsync.Options('AFTER_INSERT_OPERATIONS'))
        ));
        //Test.stopTest(); // This method would fire several queueables from setup that should not be fired at this moment

        // 0 have been created on setup, since those are new Async records, 1 have been created on the manually calling Async service
        System.assertEquals(clariOppAmountOnSetup + 1, [SELECT COUNT() FROM Clari_Opp__c]);
        // 4 have been created on setup. None were created on the method. One belongs to this OppId
        System.assertEquals(1, [SELECT COUNT() FROM OpportunityTeamMember WHERE OpportunityId = :oppId]);
    }

    @isTest
    public static void test_async_afterInsertOperations_OppTeams(){
        Opportunity opp = [SELECT Type, Name, StageName, RecordTypeId, Shipping_Contact__c, Selected_Payment_Type__c, Price_Book_Name__c, Send_Invoice__c, Amount, CloseDate FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        opp.TrialResolutionOppty__c = [SELECT Id FROM Opportunity WHERE Name = :REVENUE_OPPORTUNITY LIMIT 1][0].Id;
        update opp;

        User otherUser;
        System.runAs(new User(Id = UserInfo.getUserId())){
            String orgId = UserInfo.getOrganizationId();

            User managerUser = new User(
                LastName = 'User',
                FirstName = 'Manager',
                email = '9812h98udw98y298rhunique2@test' + orgId + '.org',
                Username = '9812h98udw98y298rhunique2@test' + orgId + '.org',
                EmailEncodingKey = 'ISO-8859-1',
                Alias = '9812e2',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                ProfileId = UserInfo.getProfileId(),
                EmployeeNumber='1234');
            insert managerUser;

            otherUser = new User(
                LastName = 'User',
                FirstName = 'Manager',
                email = '9812h98udw98y298rhunique@test' + orgId + '.org',
                Username = '9812h98udw98y298rhunique@test' + orgId + '.org',
                EmailEncodingKey = 'ISO-8859-1',
                Alias = '9812h98',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                ManagerId = managerUser.Id,
                ProfileId = UserInfo.getProfileId(),
                EmployeeNumber='123'
            );
            insert otherUser;

            update new User (Id = UserInfo.getUserId(), ManagerId = managerUser.Id);
        }

        List<OpportunityTeamMember> teamList = new List<OpportunityTeamMember>{
            new OpportunityTeamMember(
                UserId = UserInfo.getUserId(),
                OpportunityId = opp.TrialResolutionOppty__c,
                OpportunityAccessLevel = 'All',
                TeamMemberRole = 'Opportunity Owner'
            ),
            new OpportunityTeamMember(
                UserId = otherUser.Id,
                OpportunityId = opp.TrialResolutionOppty__c,
                OpportunityAccessLevel = 'All',
                TeamMemberRole = 'Account Executive'
            )
        };
        insert teamList;


        Test.startTest(); 
        (new GS_OpportunityServiceAsync()).execute(new Async_Request__c(
            Params__c = opp.Id+';',
            Options__c = JSON.serialize(
                new GS_OpportunityServiceAsync.Options(
                    'AFTER_INSERT_OPERATIONS'
                )
            )
        ));
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM OpportunityTeamMember WHERE OpportunityId = :opp.Id]);
    }

    @isTest
    public static void test_async_afterInsertOperations_RebateBuyoutType(){
        Opportunity opp = [SELECT Type, Name, StageName, RecordTypeId, Shipping_Contact__c, Selected_Payment_Type__c, Price_Book_Name__c, Send_Invoice__c, Amount, CloseDate FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        opp.Returning_Opportunity__c = [SELECT Id FROM Opportunity WHERE Name = 'Buyout' LIMIT 1][0].Id;
        update opp;

        Test.startTest();
        GS_OpportunityServiceAsync asyncHandler = new GS_OpportunityServiceAsync();
        asyncHandler.RebateTypeFormulaTestOverride = 'Buyout';
        asyncHandler.execute(new Async_Request__c(
                Params__c = opp.Id+';',
                Options__c = JSON.serialize(
                    new GS_OpportunityServiceAsync.Options(
                        'AFTER_UPDATE_OPERATIONS',
                        new Map<Id, GS_OpportunityServiceAsync.ConsolidatedProcessAsyncConditions>{
                            opp.Id => new GS_OpportunityServiceAsync.ConsolidatedProcessAsyncConditions(false, false, false, true)
                        }
                    )
                )
            )
        );
        Test.stopTest();

        System.assertEquals(opp.Id, [SELECT Buyout_Opportunity__c FROM Opportunity WHERE Id = :opp.Returning_Opportunity__c][0].Buyout_Opportunity__c);
    }

    @isTest
    public static void test_async_afterInsertOperations_RebateSubsidyType(){
        Opportunity opp = [SELECT Type, Name, StageName, RecordTypeId, Shipping_Contact__c, Selected_Payment_Type__c, Price_Book_Name__c, Send_Invoice__c, Amount, CloseDate FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        opp.Returning_Opportunity__c = [SELECT Id FROM Opportunity WHERE Name = 'Subsidy' LIMIT 1][0].Id;
        update opp;

        Test.startTest();
        GS_OpportunityServiceAsync asyncHandler = new GS_OpportunityServiceAsync();
        asyncHandler.RebateTypeFormulaTestOverride = 'Subsidy';
        asyncHandler.execute(new Async_Request__c(
                Params__c = opp.Id+';',
                Options__c = JSON.serialize(
                    new GS_OpportunityServiceAsync.Options(
                        'AFTER_UPDATE_OPERATIONS',
                        new Map<Id, GS_OpportunityServiceAsync.ConsolidatedProcessAsyncConditions>{
                            opp.Id => new GS_OpportunityServiceAsync.ConsolidatedProcessAsyncConditions(false, false, true, false)
                        }
                    )
                )
            )
        );
        Test.stopTest();

        System.assertEquals(opp.Id, [SELECT Subsidy_Opportunity__c FROM Opportunity WHERE Id = :opp.Returning_Opportunity__c][0].Subsidy_Opportunity__c);
    }

    @isTest
    public static void test_async_afterInsertOperations_RebatePartner_ReferralType(){
        Opportunity opp = [SELECT Type, Name, StageName, RecordTypeId, Shipping_Contact__c, Selected_Payment_Type__c, Price_Book_Name__c, Send_Invoice__c, Amount, CloseDate FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        opp.Returning_Opportunity__c = [SELECT Id FROM Opportunity WHERE Name = 'Buyout' LIMIT 1][0].Id; // Mock opp
        update opp;

        Test.startTest();
        GS_OpportunityServiceAsync asyncHandler = new GS_OpportunityServiceAsync();
        asyncHandler.RebateTypeFormulaTestOverride = 'Partner Referral';
        asyncHandler.execute(new Async_Request__c(
                Params__c = opp.Id+';',
                Options__c = JSON.serialize(
                    new GS_OpportunityServiceAsync.Options(
                        'AFTER_UPDATE_OPERATIONS'
                    )
                )
            )
        );
        Test.stopTest();

        System.assertEquals(opp.Id, [SELECT Partner_Referral_Opportunity__c FROM Opportunity WHERE Id = :opp.Returning_Opportunity__c][0].Partner_Referral_Opportunity__c);
    }
}