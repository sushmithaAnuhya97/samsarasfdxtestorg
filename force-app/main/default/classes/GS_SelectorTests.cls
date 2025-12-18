@isTest
public with sharing class GS_SelectorTests {
    
    @isTest
    public static void callAccountSelectorMethods(){
        GS_AccountSelector selector = new GS_AccountSelector(false);
        selector.checkFatalError().getAccountsByIds(new List<Id>());
        selector.checkFatalError().getAccountsWithCSMRecordsByAccIds(new List<Id>());
        selector.checkFatalError().getAccountsWithOppAndShipAddrByIds(new List<Id>());
        selector.checkFatalError().getAccountsWithOpptyAndContactRecordsByAccIds(new List<Id>());
        selector.checkFatalError().getAccountsWithDemoDateByIds(new Set<Id>());
        
        GS_OpportunitySelector oppselector = new GS_OpportunitySelector(false);
        
        oppselector.checkFatalError().getOppForResolutionById(new List<Id>());
        oppselector.checkFatalError().getOppForReturnProcessById(new List<Id>());
        oppselector.checkFatalError().getOppForTrialServiceById(new List<Id>());
        oppselector.checkFatalError().getOppForPostToSlackServiceById(new List<Id>());
        oppselector.checkFatalError().loadOpportunityWithItems(new set<Id>());
        oppselector.checkFatalError().loadOpportunityWithOpptyLineItems(new set<Id>());
        oppselector.checkFatalError().loadOpportunityWithTeamMembers(new set<Id>());
        oppselector.checkFatalError().getOpptyWithQuotesById(new set<Id>());
        oppselector.checkFatalError().getOpportunityFromIds(new set<Id>());
        oppselector.checkFatalError().getOpportunityMapFromIds(new set<Id>());
        oppselector.checkFatalError().getTrialOpportunitiesFromTrialResolutionIds(new set<Id>());
        
    }
}