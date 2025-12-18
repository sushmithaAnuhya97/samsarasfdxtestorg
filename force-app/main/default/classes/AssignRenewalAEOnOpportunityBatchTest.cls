/**
 * @description       : 
 * @author            : Priyank
 * @group             : 
 * @last modified on  : 02-22-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class AssignRenewalAEOnOpportunityBatchTest {
    private static String FREE_TRIAL_OPP_NAME = 'Opp Testers 1 Inc';
    private static String REVENUE_OPPORTUNITY = 'Opp Testers 2 Inc';
    private static String RESOLUTION_OPP_NAME = 'Resolution Opp';
    @TestSetup
    static void setup() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        newAccounts.add(accountOne);
        
        /*Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                BillingState='California',
                                BillingCountry = 'United States',
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                Renewal_AE__c = Userinfo.getUserId(),
                                Industry = 'Other');
        newAccounts.add(accountTwo);*/

        insert newAccounts;

        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                    Type = 'Free Trial Opportunity',
                                                    Name = FREE_TRIAL_OPP_NAME,
                                                    StageName = 'Decision',
                                                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                    //Shipping_Contact__c = contactOne.Id, 
                                                    Selected_Payment_Type__c = 'Direct Annual',
                                                    Price_Book_Name__c = 'Standard',
                                                    OwnerId = System.Label.Renewal_Pool_User,
                                                    Shipping_Country__c = 'United States',
            Shipping_State__c = 'California',
                                                    Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 

        Opportunity opportunityTwo = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                    Type = 'Revenue Opportunity',
                                                    Name = REVENUE_OPPORTUNITY,
                                                    StageName = 'Decision',
                                                    //Shipping_Contact__c = contactTwo.Id, 
                                                    Price_Book_Name__c = 'Standard',
                                                    OwnerId = System.Label.Renewal_Pool_User,
                                                    Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityTwo);     
        
        Opportunity opportunityThree = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                    Type = 'Revenue Opportunity',
                                                    Name = 'Opp Testers 3 Inc',
                                                    StageName = 'Decision',
                                                    //Shipping_Contact__c = contactOne.Id, 
                                                    Price_Book_Name__c = 'Standard',
                                                    OwnerId = System.Label.Renewal_Pool_User,
                                                    Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityThree);  

        Opportunity resolutionOpp = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                Type = 'Free Trial Opportunity',
                                                Name = RESOLUTION_OPP_NAME,
                                                StageName = 'Closed Won',
                                                Probability = 100,
                                                //ADR_Transfer__c = log.Id,
                                                OwnerId = System.Label.Renewal_Pool_User,
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
            OwnerId = System.Label.Renewal_Pool_User,
            Shipping_Country__c = 'United States',
            Shipping_State__c = 'California'
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
            Shipping_Country__c = 'United States',
            Shipping_State__c = 'California'
        ));
        newOpportunities.add(subsidyOpp);
        insert newOpportunities;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', 
                                                  SBQQ__Account__c = accountOne.Id, 
                                                  SBQQ__Opportunity2__c = opportunityOne.Id,
                                                  SBQQ__SubscriptionTerm__c =10,
                                                  Estimated_Annual_Payment__c = 24, 
                                                  Selected_Payment_Type__c = 'Direct Annual', 
                                                  SBQQ__Primary__c = true,
                                                  SBQQ__Status__c = 'Draft');
        
        insert quote;

        SBQQ__Quote__c quote1 = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', 
                                                  SBQQ__Account__c = accountOne.Id, 
                                                  SBQQ__Opportunity2__c = opportunityTwo.Id,
                                                  SBQQ__SubscriptionTerm__c =10,
                                                  Estimated_Annual_Payment__c = 24, 
                                                  Selected_Payment_Type__c = 'Direct Annual', 
                                                  SBQQ__Primary__c = true,
                                                  SBQQ__Status__c = 'Draft');
        
        insert quote1;
        TriggerHandler.clearbypass('OpportunityTriggerHandler');
    }
    @isTest
    public static void test_assignRenewalAE(){
        try {
            Test.startTest();
            Database.executeBatch(new AssignRenewalAEOnOpportunityBatch());
            
            Test.stopTest();
            // Batch Apex job executes here


        } catch(Exception e) {
            // Catch any exceptions thrown in the batch job
        }
        Test.getEventBus().deliver();
    }
    
    @isTest
    public static void test_assignRenewalAE2(){
        try {
            Test.startTest();
            AssignRenewalAEOnOpportunityBatch assignAE = new AssignRenewalAEOnOpportunityBatch();
            //Database.executeBatch(new AssignRenewalAEOnOpportunityBatch());
            List<Opportunity> optyList = [SELECT Id, Account.Renewal_AE__c, AccountId, OwnerId FROM Opportunity LIMIT 100];
            assignAE.execute(null, optyList);
            Test.stopTest();
            // Batch Apex job executes here


        } catch(Exception e) {
            // Catch any exceptions thrown in the batch job
        }
        Test.getEventBus().deliver();
    }
}