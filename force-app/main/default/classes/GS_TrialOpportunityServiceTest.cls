@isTest
public with sharing class GS_TrialOpportunityServiceTest {

    private static String FREE_TRIAL_OPP_NAME = 'Opp Testers 1 Inc';
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

        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                    Type = 'Free Trial Opportunity',
                                                    Name = FREE_TRIAL_OPP_NAME,
                                                    StageName = 'Proposal',
                                                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                    Shipping_Contact__c = contactOne.Id, 
                                                    Selected_Payment_Type__c = 'Direct Annual',
                                                    Price_Book_Name__c = 'Standard',
                                                    Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 

        Opportunity opportunityTwo = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id, 
                                                    Type = 'Revenue Opportunity',
                                                    Name = 'Opp Testers 2 Inc',
                                                    StageName = 'Proposal',
                                                    Shipping_Contact__c = contactTwo.Id, 
                                                    Price_Book_Name__c = 'Standard',
                                                    Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityTwo);     
        
        Opportunity opportunityThree = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                    Type = 'Free Trial Opportunity',
                                                    Name = 'Opp Testers 3 Inc',
                                                    StageName = 'Proposal',
                                                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                    Shipping_Contact__c = contactOne.Id, 
                                                    Price_Book_Name__c = 'Standard',
                                                    Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityThree);  

        Opportunity resolutionOpp = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                Type = 'Free Trial Opportunity',
                                                Name = RESOLUTION_OPP_NAME,
                                                StageName = 'Closed Won',
                                                Probability = 100,
                                                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                Send_Invoice__c = false));
        newOpportunities.add(resolutionOpp);
        insert newOpportunities;
    }

    @isTest
    public static void TrialTest_noTrialResolutionOppNotWon(){
        Opportunity toUpdateOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        //toUpdateOpp.StageName Not Closed Won

        // Testing Trial statuses
        Test.startTest();
        update toUpdateOpp;
        Test.stopTest();

        toUpdateOpp = [SELECT Id, Trial_Status__c FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        System.assertEquals('Not Shipped', toUpdateOpp.Trial_Status__c);
    }

    @isTest
    public static void TrialTest_noTrialResolutionOppClosedWon(){
        Opportunity toUpdateOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        
        // Testing Trial statuses
        Test.startTest();
        toUpdateOpp.StageName = 'Closed Won';
        update toUpdateOpp;
        Test.stopTest();

        toUpdateOpp = [SELECT Id, Trial_Status__c FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        System.assertEquals('Open', toUpdateOpp.Trial_Status__c);
    }

    @isTest
    public static void TrialTest_withTrialResolutionOppNotWon(){
        Opportunity toUpdateOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        Opportunity resolutionOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = :RESOLUTION_OPP_NAME LIMIT 1];
        
        // Testing Trial statuses
        Test.startTest();
        toUpdateOpp.TrialResolutionOppty__c = resolutionOpp.Id;
        update toUpdateOpp;
        Test.stopTest();

        toUpdateOpp = [SELECT Id, Trial_Status__c FROM Opportunity WHERE Name = 'Opp Testers 1 Inc' LIMIT 1];
        System.assertEquals('Not Shipped', toUpdateOpp.Trial_Status__c);
    }

    // Async tests


    @isTest
    public static void TrialTest_handleReturnCreationAsync(){
        Opportunity toUpdateOpp = (new GS_OpportunitySelector(false)).getOppForTrialServiceById(
            new List<Id>{[SELECT Id FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1][0].Id}
        )[0];

        toUpdateOpp.Returning_Opportunity__c = [SELECT Id FROM Opportunity WHERE Name = :RESOLUTION_OPP_NAME LIMIT 1][0].Id;
        toUpdateOpp.Type = 'Free Trial Return';
        update toUpdateOpp;

        // Testing Trial statuses
        Test.startTest();
        (new GS_TrialOpportunityServiceAsync()).execute(new Async_Request__c(
            Params__c = toUpdateOpp.Id+';',
            Options__c = JSON.serialize((new GS_TrialOpportunityServiceAsync.Options('AFTER_INSERT')))
        ));
        Test.stopTest();

        Opportunity returnOpp = [SELECT Id, FT_Return__c FROM Opportunity WHERE Name = :RESOLUTION_OPP_NAME LIMIT 1];
        System.assertEquals(toUpdateOpp.Id, returnOpp.FT_Return__c);
    }

    @isTest
    public static void TrialTest_welcomeTrialKitOnClosingAsync(){
        List<Account> accList = new List<Account>{
            new Account(
                Name = 'Test Account 1 - Transportation',
                Industry = 'Transportation & Warehousing',
                Organization_Size__c = '100 - 499',
                BillingCountry = 'United States',
                BillingState = 'California'
            ),
            new Account(
                Name = 'Test Account 2 - Transportation',
                Industry = 'Food & Beverage',
                Organization_Size__c = '100 - 499',
                BillingCountry = 'United States',
                BillingState = 'California'
            ),
            new Account(
                Name = 'Test Account 3 - Any',
                Organization_Size__c = '100 - 499',
                BillingCountry = 'United States',
                BillingState = 'Florida'
            ),
            new Account(
                Name = 'Test Account 4 - Any',
                Organization_Size__c = '100 - 499',
                BillingCountry = 'Portugal'
            )
        };
        insert accList;

        // Generate the four opps
        List<Opportunity> testOpps = new List<Opportunity>{
            // Ready data for opp1 - Transportation & Warehousing
            new Opportunity(
                Type = 'Free Trial Opportunity',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                Name = 'New opp for testing 0',
                AccountId = accList[0].Id,
                Configuration_Segment__c = 'Non Express',
                StageName = 'Proposal',
                CloseDate = System.today(),
                Probability = 100,
                Shipping_Country__c = 'United States'
            ),

            // Ready data for opp2 - Food & Beverage
            new Opportunity(
                Type = 'Free Trial Opportunity',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                Name = 'New opp for testing 1',
                AccountId = accList[1].Id,
                Configuration_Segment__c = 'Non Express',
                StageName = 'Proposal',
                CloseDate = System.today(),
                Probability = 100,
                Shipping_Country__c = 'United States'
            ),

            // Ready data for opp3 - Standard
            new Opportunity(
                Type = 'Free Trial Opportunity',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                Name = 'New opp for testing 2',
                AccountId = accList[2].Id,
                Configuration_Segment__c = 'Non Express',
                StageName = 'Closed Won',
                CloseDate = System.today(),
                Probability = 100,
                Shipping_Country__c = 'United States'
            ),

            // Ready data for opp4 - FREE-TRIAL-KIT-EU
            new Opportunity(
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                Name = 'New opp for testing 3',
                AccountId = accList[3].Id,
                Configuration_Segment__c = 'Non Express',
                StageName = 'Proposal',
                CloseDate = System.today(),
                Probability = 100
            ),

            // Ready data for opp5 - Welcome kit
            new Opportunity(
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                Name = 'New opp for testing 4',
                AccountId = accList[3].Id,
                Renewal__c = false,
                Type = 'Revenue Opportunity',
                Configuration_Segment__c = 'Non Express',
                StageName = 'Proposal',
                CloseDate = System.today(),
                Amount = 35000,
                Probability = 100,
                Shipping_Country__c = 'United States'
            )
        };

        insert testOpps;

        // Testing Trial statuses
        Test.startTest();
        (new GS_TrialOpportunityServiceAsync()).execute(new Async_Request__c(
            Params__c = testOpps[0].Id+';'+testOpps[1].Id+';'+testOpps[2].Id+';'+testOpps[3].Id+';'+testOpps[4].Id+';',
            Options__c = JSON.serialize((new GS_TrialOpportunityServiceAsync.Options('AFTER_INSERT')))
        ));
        Test.stopTest();

        

        //Opportunity returnOpp = [SELECT Id, FT_Return__c FROM Opportunity WHERE Name = :RESOLUTION_OPP_NAME LIMIT 1];
        //System.assertEquals(toUpdateOpp.Id, returnOpp.FT_Return__c);
    }
    
    @isTest
    public static void TrialTest_handleRevenueUpdateAsync(){
        Test.startTest();
        Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
        Opportunity toUpdateOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        toUpdateOpp.TrialResolutionOppty__c = revenueOpp.Id;
        toUpdateOpp.StageName = 'Closed Won';
        update toUpdateOpp;
        
        revenueOpp.StageName = 'Closed Won';
        
        update revenueOpp;
        (new GS_TrialOpportunityServiceAsync()).execute(new Async_Request__c(
            Params__c = revenueOpp.Id+';',
            Options__c = JSON.serialize((new GS_TrialOpportunityServiceAsync.Options('BEFORE_UPDATE_OPERATIONS',
                    new Map<Id, Boolean>{
                    revenueOpp.Id => false
                })))
        )); 
        toUpdateOpp = [SELECT Id, Trial_Status__c FROM Opportunity WHERE id = :toUpdateOpp.Id];
        system.assertEquals('Purchased', toUpdateOpp.Trial_Status__c);
        
        Test.stopTest();
    }
   
    @isTest
    public static void TrialTest_consolidatedTrialUpdateAsync(){
        Test.startTest();
        
      Opportunity toUpdateOpp = (new GS_OpportunitySelector(false)).getOppForTrialServiceById(
            new List<Id>{[SELECT Id FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1][0].Id}
        )[0];
            
        toUpdateOpp.Returning_Opportunity__c = [SELECT Id FROM Opportunity WHERE Name = :RESOLUTION_OPP_NAME LIMIT 1][0].Id;
        toUpdateOpp.Type = 'Free Trial Return';
        
         update toUpdateOpp;
        
        Opportunity freeTrialOppty = [SELECT Id , Trial_Status__c FROM Opportunity WHERE Id =: toUpdateOpp.Returning_Opportunity__c];
		freeTrialOppty.TrialResolutionOppty__c = toUpdateOpp.Id;
        freeTrialOppty.FT_Return__c = toUpdateOpp.Id;
        
        update freeTrialOppty;
        
        toUpdateOpp.StageName = 'Closed Won';
        
        update toUpdateOpp;
        
        (new GS_TrialOpportunityServiceAsync()).execute(new Async_Request__c(
            Params__c = toUpdateOpp.Id+';',
            Options__c = JSON.serialize((new GS_TrialOpportunityServiceAsync.Options('AFTER_UPDATE_OPERATIONS',
                    new Map<Id, Boolean>{
                    toUpdateOpp.Id => true
                })))
        )); 
        
        freeTrialOppty = [SELECT Id, Trial_Status__c FROM Opportunity WHERE id = :freeTrialOppty.Id];
        system.debug('freeTrialOppty Id : '+freeTrialOppty.id);
        system.assertEquals('Returned', freeTrialOppty.Trial_Status__c);
        
        Test.stopTest();
    }
    
    

  //  @isTest
  /*  public static void TrialTest_withTrialResolutionOppClosedWonRes100(){
        Opportunity toUpdateOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        Opportunity resolutionOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = :RESOLUTION_OPP_NAME LIMIT 1];
        
        // Testing Trial statuses
        Test.startTest();
        toUpdateOpp.TrialResolutionOppty__c = resolutionOpp.Id;
        toUpdateOpp.StageName = 'Closed Won';
        update toUpdateOpp;
        Test.stopTest();

        toUpdateOpp = [SELECT Id, Trial_Status__c FROM Opportunity WHERE Name = 'Opp Testers 1 Inc' LIMIT 1];
      //  System.assertEquals('Returned', toUpdateOpp.Trial_Status__c);
    }*/

   // @isTest
  /*  public static void TrialTest_withTrialResolutionOppClosedWonRes90(){
        Opportunity toUpdateOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        Opportunity resolutionOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = :RESOLUTION_OPP_NAME LIMIT 1];
        resolutionOpp.Probability = 90;
        update resolutionOpp;
        
        // Testing Trial statuses
        Test.startTest();
        toUpdateOpp.TrialResolutionOppty__c = resolutionOpp.Id;
        toUpdateOpp.StageName = 'Closed Won';
        update toUpdateOpp;
        Test.stopTest();

        toUpdateOpp = [SELECT Id, Trial_Status__c FROM Opportunity WHERE Name = 'Opp Testers 1 Inc' LIMIT 1];
      //  System.assertEquals('Return In Progress', toUpdateOpp.Trial_Status__c);
    }*/

    @isTest
    public static void TrialTest_withTrialResolutionOppRevenueClosedWon(){
        Opportunity toUpdateOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = :FREE_TRIAL_OPP_NAME LIMIT 1];
        Opportunity resolutionOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = :RESOLUTION_OPP_NAME LIMIT 1];
        resolutionOpp.Type = 'Revenue Opportunity - Bill Only';
        resolutionOpp.StageName = 'Closed Won';
        update resolutionOpp;

        // Testing Trial statuses
        Test.startTest();
        toUpdateOpp.TrialResolutionOppty__c = resolutionOpp.Id;
        toUpdateOpp.StageName = 'Closed Won';
        update toUpdateOpp;
        Test.stopTest();

        toUpdateOpp = [SELECT Id, Trial_Status__c FROM Opportunity WHERE Name = 'Opp Testers 1 Inc' LIMIT 1];
        System.assertEquals('Purchased', toUpdateOpp.Trial_Status__c);
    }
}