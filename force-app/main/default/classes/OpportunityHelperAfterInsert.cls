/**********************************************************************
Name: OpportunityHelperAfterInsert

Purpose: This class will contains method that will be called in the after insert context                                                    

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Apr-11        INITIAL DEVELOPMENT 

***********************************************************************/

public class OpportunityHelperAfterInsert extends OpportunityHelperContext {
    public void afterInsertOperations(List<Opportunity> newOppList){
        Opportunity oldOpportunity = new Opportunity();
        List <Clari_Opp__c> clariOppsToCreate = new List <Clari_Opp__c>();
        Map<Id, Id> opportunityIds = new Map<Id, Id>();
        loadOppAccounts(newOppList);
        for (Opportunity opp : newOppList){
            if(opp.type != 'Free Trial Opportunity' && opp.Type != 'Free Trial Return') {
                Clari_Opp__c clariOpp = new Clari_Opp__c();
                clariOpp.Opportunity__c = opp.Id;
                clariOppsToCreate.add(clariOpp);
            }
            if((opp.type == 'Free Trial Opportunity') && (opp.TrialResolutionOppty__c != null)){
                opportunityIds.put(opp.TrialResolutionOppty__c, opp.Id);
            }
            else if((opp.type == 'Rebate' || opp.type == 'Remorse Refund') && (opp.Returning_Opportunity__c != null)){
                opportunityIds.put(opp.Returning_Opportunity__c, opp.Id);
            }
            // Groundswell : Tanuj - WFlow Rule - Update Account for NS Sync
            // Start
            Account thisOppAccount = new Account();
            if (opp.AccountId != NULL && oppAccounts.containsKey(opp.AccountId)) {
                thisOppAccount = oppAccounts.get(opp.AccountId);
                OpportunityWorkflowConversion.afterInsertUpdateMethod(opp, null, thisOppAccount);
            }
            // End
        }
        //Zakeer: added !System.isBatch() -- Oct26-2021-->ContractAutomation
        if(!opportunityIds.isEmpty() && !System.isBatch()){
            createOpportunityTeams(opportunityIds);
        }
        insert clariOppsToCreate;
    }
    
    //GTMS-5727: Moved the below code changes from OpportunityProcessBuilderConversion
    public void associateRebateOppsToChannelOpps(Map<Id, Opportunity> opsMap) {
        for (Opportunity o : opsMap.values()) {
            Opportunity returningOpp = new Opportunity();
            if(o.Rebate_Type_Formula__c != null){
                switch on o.Rebate_Type_Formula__c {
                    when 'Buyout' {
                        returningOpp.Id = o.Returning_Opportunity__c;
                        returningOpp.Buyout_Opportunity__c = o.Id;
                        DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
                            Opportunity.Buyout_Opportunity__c
                                });
                    }
                    when 'Subsidy' {
                        returningOpp.Id = o.Returning_Opportunity__c;
                        returningOpp.Subsidy_Opportunity__c = o.Id;
                        DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
                            Opportunity.Subsidy_Opportunity__c
                                });
                    }
                    when 'Partner Referral' {
                        returningOpp.Id = o.Returning_Opportunity__c;
                        returningOpp.Partner_Referral_Opportunity__c = o.Id;
                        DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
                            Opportunity.Partner_Referral_Opportunity__c
                                });
                    }
                }
            }
        }
    }
    
    //GTMS-16221 -- Created method to check for closed won opps and pass to Future method
    /*public void populateFinacePartneronAccount(Map<Id,Opportunity> mapOldOpp, List<opportunity> newOppList){
        Set<Id> closedWonOpportunityAccIdSet = new Set<Id>();
        Set<Id> closedWonOpportunityIdSet = new Set<Id>();
        for(Opportunity opp : newOppList){
            if(mapOldOpp == null && opp.StageName == 'Closed Won' &&  opp.Finance_Partner__c != null && opp.Type == 'Revenue Opportunity'){
                closedWonOpportunityAccIdSet.add(opp.AccountId);
                closedWonOpportunityIdSet.add(opp.Id);
            }
            else if(mapOldOpp !=null && opp.StageName == 'Closed Won' && mapOldOpp.get(opp.Id).StageName != 'Closed Won' &&  opp.Finance_Partner__c != null && opp.Type == 'Revenue Opportunity'){
                system.debug('***populateFinacePartneronAccountCheckPASSED');
                closedWonOpportunityAccIdSet.add(opp.AccountId);
                closedWonOpportunityIdSet.add(opp.Id);
            }
        }
        if(!closedWonOpportunityAccIdSet.isEmpty()){
            String JsonoppAccIds = JSON.serialize(closedWonOpportunityAccIdSet);
            String JsonoppIds = JSON.serialize(closedWonOpportunityIdSet);
            //GTMS-16221 -- Invoking below future method to process the required logic as update is on Account object
            if(!System.isFuture() && !System.isScheduled() && !System.isQueueable() && !System.isBatch()){
                populateFinacePartneronAccountFuture(JsonoppAccIds,JsonoppIds);
            }
        }
    }
    
    @Future
    public static void populateFinacePartneronAccountFuture(String jsonOppAccIds, String jsonOppIds){
        Set<Id> oppAccIds = (Set<Id>)JSON.deserialize(jsonOppAccIds,Set<Id>.class);
        Set<Id> oppIds = (Set<Id>)JSON.deserialize(jsonOppIds,Set<Id>.class);
        Map<Id, Opportunity> oldestOpportunityMap = new Map<Id, Opportunity>();
        List<Account> listAccountstoUpdate = new List<Account>();
        List<Finance_Partner_Quote__c> listFPQstoUpdate = new List<Finance_Partner_Quote__c>();
        List<Opportunity> listOpportunities = new List<Opportunity>([SELECT Id, Name, AccountId, CloseDate,Finance_Partner__c FROM Opportunity WHERE AccountId In:oppAccIds and StageName = 'Closed Won' and Finance_Partner__c != '' and Type = 'Revenue Opportunity' ORDER BY CloseDate ASC]);
        List<Finance_Partner_Quote__c> listfpqValues = new List<Finance_Partner_Quote__c>([Select Id,Name,Opportunity__c,Finance_Partner__c,Opportunity__r.AccountId,Opportunity__r.Type,Opportunity__r.StageName,Opportunity__r.contractId,Opportunity__r.Finance_Partner__c,Opportunity__r.contract.EndDate from Finance_Partner_Quote__c where Opportunity__c In:oppIds]);
        system.debug('***populateFinacePartneronAccountFuture'+listOpportunities);
        for (Opportunity opp : listOpportunities) {
            if (!oldestOpportunityMap.containsKey(opp.AccountId)) {
                // If account is not already in the map, add the opportunity
                oldestOpportunityMap.put(opp.AccountId, opp);
            } else {
                // Check if the current opportunity's close date is earlier than the one in the map
                Opportunity existingOldestOpportunity = oldestOpportunityMap.get(opp.AccountId);
                if (opp.CloseDate < existingOldestOpportunity.CloseDate) {
                    // Update the map if the current opportunity is older
                    oldestOpportunityMap.put(opp.AccountId, opp);
                }
            }
            system.debug('***populateFinacePartneronAccountFutureMAP'+oldestOpportunityMap);
        }
        //To set Finance Partner and 3PF customer Fields on Account
        for (Opportunity opp : oldestOpportunityMap.values()) {
            Account acc = new Account();
            acc.Id = opp.AccountId;
            acc.Finance_Partner__c = opp.Finance_Partner__c;
            acc.X3PF_Customer__c = true;
            listAccountstoUpdate.add(acc);
        }
        //Update accounts with Finance Partner
        if(listAccountstoUpdate.size() > 0){
            update listAccountstoUpdate;
        }
        //To set Contract EndDate on FPQ records
        if(listfpqValues.size() > 0){
            for(Finance_Partner_Quote__c fpquote:listfpqValues){
                Finance_Partner_Quote__c fpq = new Finance_Partner_Quote__c();
                fpq.Id = fpquote.Id;
                fpq.Contract_End_Date__c = fpquote.Opportunity__r.contract.EndDate;
                listFPQstoUpdate.add(fpq);
            }
        }
        //Update Contract EndDate on FPQ records
        if(listFPQstoUpdate.size() >0){
            update listFPQstoUpdate;
        }
    }
    */
    @future
    public static void createOpportunityTeams(Map<Id, Id> opportunityIds) {
        Map<Id, Opportunity> queriedOpportunities;
        List<OpportunityTeamMember> opportunityTeams = new List<OpportunityTeamMember>();
        if(!opportunityIds.isEmpty()){
            queriedOpportunities = new Map<Id, Opportunity>([SELECT Id, (SELECT Id, OpportunityAccessLevel, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMembers)
                                                             FROM Opportunity WHERE ID IN : opportunityIds.keyset()]);
        }
        for(Opportunity relatedOpp : queriedOpportunities.values()){
            List<OpportunityTeamMember> teams = relatedOpp.OpportunityTeamMembers;
            if(teams.size() > 1){
                for(OpportunityTeamMember member : teams){
                    if(member.TeamMemberRole != 'Opportunity Owner'){
                        OpportunityTeamMember newMember = new OpportunityTeamMember();
                        newMember.TeamMemberRole = member.TeamMemberRole;
                        newMember.UserId = member.UserId;
                        newMember.OpportunityId = opportunityIds.get(relatedOpp.Id);
                        opportunityTeams.add(newMember);
                    }
                }
            }
        }
        if(opportunityTeams.size()>0){
            insert opportunityTeams;
        }
    }
}