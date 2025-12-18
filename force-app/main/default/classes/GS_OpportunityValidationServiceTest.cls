@isTest
public with sharing class GS_OpportunityValidationServiceTest {

    @TestSetup
    static void setup(){
        GS_GlobalAutomationSettingsTest.createAutomationTestSetting();

        Account acc = new Account(
            Name = 'Test Account 1 - Transportation',
            Industry = 'Transportation & Warehousing',
            Organization_Size__c = '100 - 499',
            BillingCountry = 'United States',
            BillingState = 'California'
        );
        insert acc;
    }
    
    @isTest
    public static void Validation_NoAccountError(){

        Opportunity opp = new Opportunity(
            Type = 'Revenue Opportunity',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
            Name = 'Run the createFirstOpportunityFromContact test',
            //AccountId = acc.Id,
            Configuration_Segment__c = 'Express',
            StageName = 'Ready to Ship',
            CloseDate = System.today(),
            Probability = 100,
            Shipping_Country__c = 'United States'
        );

        Test.startTest();
        (new GS_OpportunityValidationService()).firstOpportunityFromContactValidation(new List<Opportunity>{opp}, new GS_OpportunityCacheService());
        System.assert(opp.hasErrors(), 'No addError fired as expected for new Opportunities without Account');
        System.assert(opp.getErrors()[0].getMessage().contains('Please associate an Account'), 'The addError found has a different message than expected for Opportunity without Account');
        Test.stopTest();
    }
    
    @isTest
    public static void Validation_CanCreateException(){

        Opportunity opp = new Opportunity(
            Type = 'Revenue Opportunity',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
            Name = 'Run the createFirstOpportunityFromContact test',
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            Configuration_Segment__c = 'Express',
            StageName = 'Ready to Ship',
            CloseDate = System.today(),
            Probability = 100,
            Shipping_Country__c = 'United States'
        );

        Test.startTest();
        Boolean expectedExceptionFired = false;
        try{
            (new GS_OpportunityValidationService()).firstOpportunityFromContactValidation(new List<Opportunity>{opp}, new GS_OpportunityCacheService());
        }catch(CalloutException k){
            expectedExceptionFired = true;
            System.assert(k.getMessage().contains('This is the first opportunity for this Account'), 'Error message for first Opportunity for Account has not worked (CalloutException)');
        }
        System.assert(expectedExceptionFired, 'No addError fired as expected for creating first Opportunity for this Account');
        Test.stopTest();
    }
    
    @isTest
    public static void Validation_CanCreateSuccess(){

        Opportunity opp = new Opportunity(
            Type = 'Revenue Opportunity',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
            Name = 'Run the createFirstOpportunityFromContact test',
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            Configuration_Segment__c = 'Express',
            StageName = 'Ready to Ship',
            CloseDate = System.today(),
            Probability = 100,
            Can_Create__c = true,
            Shipping_Country__c = 'United States'
        );

        Test.startTest();
        (new GS_OpportunityValidationService()).firstOpportunityFromContactValidation(new List<Opportunity>{opp}, new GS_OpportunityCacheService());

        // If no exception gets thrown here, that's what was expected.
        System.assert(!opp.hasErrors(), 'Error message for Opportunity that should be creatable. Error in GS_OpportunityValidationService');
        Test.stopTest();
    }
}