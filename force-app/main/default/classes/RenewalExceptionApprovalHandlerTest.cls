@isTest
public with sharing class RenewalExceptionApprovalHandlerTest {
    @testSetup
    private static void setupData(){
        Account account = new Account(
            Name = 'Testing Account',
            Organization_Size__c = '1 - 99',
            Industry = 'Manufacturing',
            BillingState = 'Alabama',
            ShippingState = 'Alabama',
            BillingCountry = 'United States',
            ShippingCountry = 'United States'
        );        
        insert account;
        
        Opportunity opp = new Opportunity(
            name = 'Testing Opp',
            StageName = 'Incubate',
            closeDate = Date.today(),
            AccountId = account.Id,
            ForecastCategoryName = 'Omitted'
        ); 
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        SBQQ.TriggerControl.disable();
        insert opp;
    }
    @isTest
    private static void insertRenewalExceptionWithSplit(){
        Opportunity opp = [SELECT ID FROM Opportunity LIMIT 1];
        OpportunitySplitType type = [Select id from opportunitysplittype WHERE DeveloperName = 'Overlay'];

        OpportunityTeamMember member = new OpportunityTeamMember();
        member.UserId = UserInfo.getUserId();
        member.OpportunityId = opp.Id;
        insert member;

        OpportunitySplit split = new OpportunitySplit();
        split.OpportunityId = opp.Id;
        split.SplitTypeId = type.Id;
        split.SplitPercentage = 30;
        split.SplitOwnerId = UserInfo.getUserId();
        insert split;

        Renewal_Exception_Approval__c approval = new Renewal_Exception_Approval__c();
        approval.Opportunity__c = opp.Id;
        approval.Account_Executive__c = UserInfo.getUserId();
        approval.Exception_Type__c = 'Renewal';
        approval.Exception_Request_Primary_Reason__c = 'Customer went bankrupt or out of business';
        insert approval;

        approval.Status__c = 'Approved';
        RenewalExceptionApprovalTriggerHandler.isProcessing = false;
        update approval;

        System.debug('in test class'+[Select Id,SplitOwnerId,OpportunityId from OpportunitySplit WHERE SplitType.DeveloperName='Overlay']);
    }

}