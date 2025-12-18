/**
* Created By : Groundswell - Flávio Contini
* @Date August 12, 2021
*
* @description : This class will be responsible for handling all Opportunity Operations
* SFA-10
*
**/
public inherited sharing class GS_OpportunityService {

    public GS_OpportunityService() {}

    // This Method receives OpptyRelatedAccounts Map & returns Filtered AccountMap for only Closed won OR Revenue Opportunities
    public Map<Id, Account> getAccountsForClosedOrRevenueTypeOppty( Map<Id, Account> oppAccounts){
        Map<Id, Account> oppAccountsRev = null;
        // Filter by closed revenue oppties
        oppAccountsRev = new Map<Id, Account>(oppAccounts);
        for (Id accountId : oppAccountsRev.keySet()) {
            for (Integer i = oppAccountsRev.get(accountId).Opportunities.size() - 1; i >= 0; i--) {
                Opportunity oppty = oppAccountsRev.get(accountId).Opportunities[i];
                if (oppty.StageName != 'Closed Won' || oppty.Type != 'Revenue Opportunity') {
                        oppAccountsRev.get(accountId).Opportunities.remove(i);
                    }
            }
        }
        return oppAccountsRev;
    }

    /**
    * @author - Satya Dodda
    * @date 2020-01-08
    * @additional filter conditions for DCL automation
    */
    public boolean checkDCLQualified(Opportunity newOpp, Opportunity oldOpp) {
        boolean promoCheck = false;
        boolean ftCheck = false;
        if(newOpp.Type == 'Promo Opportunity' && String.isBlank(newOpp.Shipping_Instructions__c) && String.isBlank(newOpp.Netsuite_Id__c) && 
            (newOpp.Sales_Tax__c == 0 || newOpp.Sales_Tax__c == null) && (newOpp.Balance_Due__c == 0 || newOpp.Balance_Due__c == null) && 
            (newOpp.Shipping_and_Handling__c == 0 || newOpp.Shipping_and_Handling__c == null) && (newOpp.Shipping_and_Handling_Manual__c == 0 || newOpp.Shipping_and_Handling_Manual__c == null )
            && (newOpp.Shipping_and_Handling_Amount__c == 0 || newOpp.Shipping_and_Handling_Amount__c == null) &&
            (newOpp.Owner_Role_Copy__c == 'Operations' || newOpp.Owner_Role_Copy__c == 'Management') &&
            (newOpp.Shipping_Carrier__c == 'UPS')) {
                promoCheck = true;
        }
        
        if(newOpp.Type == 'Free Trial Opportunity' && String.isBlank(newOpp.Netsuite_Transfer_Order__c) && String.isBlank(newOpp.Netsuite_Transfer_Order_ID__c)) {
            ftCheck = true;
        }
        return (ftCheck || promoCheck);
    }


    //* 3/19/20 Ron - (GTMS-142): rebateBuyoutSubsidyToNetsuite (include Ready to Ship parameters to ship off Revenue Opp to netsuite)
    public void rebateBuyoutSubsidyToNetsuite(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList) {
        if (HelperClass.firstRun) {
            for (Opportunity oppty : newOppList) {
                if (!(Test.isRunningTest()) && oppty.Type == 'Rebate' && oppty.StageName.equals('Finance Processing') &&
                    oppty.Returning_Opportunity_Closed_Won__c == true && oldOppMap.get(oppty.Id).Push_Return_to_Netsuite__c != true &&
                    oppty.Push_Return_to_Netsuite__c == true && String.isBlank(oppty.Corresponding_Netsuite_ID__c)) {
                    if (oppty.Rebate_Type__c == 'Buyout' || oppty.Rebate_Type__c == 'Partner Referral') {
                        integrator_da__.RealTimeExporter.run('rebate-buyout-referral-sync');
                    } else if (oppty.Rebate_Type__c == 'Subsidy') {
                        integrator_da__.RealTimeExporter.run('rebate-subsidy-sync');
                    } else if (oppty.Rebate_Type__c == 'Renewal Credit') {
                        integrator_da__.RealTimeExporter.run('rebate-renewal-credit-sync');
                    }
                    HelperClass.firstRun = false;
                }
            }
        }
    }



    public inherited sharing class OpportunityTriggerContext {

        public GS_OpportunityCacheService oppCache;
        public OpportunityTriggerContext(){
            this.oppCache = new GS_OpportunityCacheService();
        }

        /**
         * @description : Executes before insert services
         * @param : List<Opportunity> newOpportunityList
         * 12/17/2020 Ron, Harsha (GTMS-2395) beforeInsertOnly (Configuration Segment)
         */
        public void runBeforeInsert(List<Opportunity> newOpportunityList) {
            
            (new GS_TrialOpportunityService()).handleTrialUpdate(null, newOpportunityList);
            (new GS_OpportunityValidationService()).firstOpportunityFromContactValidation(newOpportunityList, this.oppCache);
            (new GS_OpportunityPrepopulationService()).runBeforeInsertService(newOpportunityList, this.oppCache);
            (new GS_OpportunityRunWorkflowService()).runBeforeInsertWorkflows(newOpportunityList, this.oppCache);
            (new GS_OpportunityReturnProcessService(null, newOpportunityList, this.oppCache)).runBefore();
        }


        public void runAfterInsert(List<Opportunity> newOpportunityList) {
            this.oppCache.cacheRelatedIdsFromOpps(newOpportunityList);
            // After insert operations + opptyConsolidatedProcesses
            GS_OpportunityRollupsToAccount gsOpportunityRollupsToAccountObj = new GS_OpportunityRollupsToAccount(newOpportunityList, null);
            
            (new GS_OpportunityService()).runOpportunityServiceAsyncFunctions(newOpportunityList, null, 'AFTER_INSERT_OPERATIONS');

            // Opp return process
            (new GS_OpportunityReturnProcessService(null, newOpportunityList, this.oppCache)).runAfter();

            (new GS_OpportunityPBConversionService(null, newOpportunityList, this.oppCache)).readyToShipOrClosedWon();

            // Trial Handle return creation + welcomeTrialKitProductsOnClose
            (new GS_TrialOpportunityService()).runAfterInsertFunctions(newOpportunityList);

            (new GS_OpportunityNetSuiteService()).pushInfoToNetsuite(null, newOpportunityList);
            
            (new GS_OpportunitySlackService()).postToSlack(null, newOpportunityList);

            gsOpportunityRollupsToAccountObj.calculateRollUpsToAccount();
        }

        /**
         * @description : Executes before update services
         * @param : List<Opportunity> newOpportunityList , Map<Id, Opportunity> oldOpportunityMa
         */
        public void runBeforeUpdate(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldOpportunityMap) {
            this.oppCache.cacheRelatedIdsFromOpps(newOpportunityList);
            this.oppCache.loadOppRelatedAccounts( this.oppCache.cachedAccountIds);
            this.oppCache.loadOpportunityWithItems( this.oppCache.cachedOpportunityIds);
            GS_OpportunityPBConversionService opportunityPBConversionServiceObj = new GS_OpportunityPBConversionService(oldOpportunityMap, newOpportunityList, this.oppCache);

            (new GS_OpportunityPrepopulationService()).runBeforeUpdateService(oldOpportunityMap, newOpportunityList, this.oppCache);
            
            (new GS_OpportunityRunWorkflowService()).runBeforeUpdateWorkflows(oldOpportunityMap, newOpportunityList, this.oppCache);

            (new GS_OpportunityReturnProcessService(oldOpportunityMap, newOpportunityList, this.oppCache)).runBefore();

            (new GS_TrialOpportunityService()).handleTrialUpdate(oldOpportunityMap, newOpportunityList);
            
            (new GS_TrialOpportunityService()).handleRevenueUpdate(oldOpportunityMap, newOpportunityList);
            
            opportunityPBConversionServiceObj.readyToShipOrClosedWon();

            (new GS_OpportunityNetSuiteService()).pushInfoToNetsuite(oldOpportunityMap, newOpportunityList);

            (new GS_OpportunitySlackService()).postToSlack(oldOpportunityMap, newOpportunityList);

            opportunityPBConversionServiceObj.processContractUpdates();

            opportunityPBConversionServiceObj.closingOppWithStripeTrialOrExpessFinanceApproval();
            
            (new GS_OpportunityOrderAdminRoundRobinAsync()).orderAdminRoundRobin(oldOpportunityMap, newOpportunityList);
        }


        /**
         * @description : Executes After update services
         * @param : List<Opportunity> newOpportunityList , Map<Id, Opportunity> oldOpportunityMa
         */
        public void runAfterUpdate(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldOpportunityMap) {
            this.oppCache.cacheRelatedIdsFromOpps(newOpportunityList);
            this.oppCache.loadOppRelatedAccounts( this.oppCache.cachedAccountIds);
            this.oppCache.loadOpportunityWithItems( this.oppCache.cachedOpportunityIds);
            // After update operations + opptyConsolidatedProcesses
            
            // Opp return process
            (new GS_OpportunityReturnProcessService(oldOpportunityMap, newOpportunityList, this.oppCache)).runAfter();
            
            GS_OpportunityRollupsToAccount gsOpportunityRollupsToAccountObj = new GS_OpportunityRollupsToAccount(newOpportunityList, oldOpportunityMap);

            new GS_OpportunityToUpdateAccountService().runOpportunityToUpdateAccountAfterUpdate(oldOpportunityMap, newOpportunityList, this.oppCache);

            (new GS_OpportunityPrepopulationService()).createPlatformEvent();

            new GS_OpportunityToLineItemUpdateAsync().expressSetAnnualDiscountLineItem(oldOpportunityMap, newOpportunityList, this.oppCache);

            /* Below Method executes following processes for Trial Opportunity:
            *  handleReturnUpdate
            *  welcomeTrialKitProductsOnClosing
            */
            (new GS_TrialOpportunityService()).consolidatedTrialUpdate(oldOpportunityMap, newOpportunityList);

            (new GS_OpportunityService()).rebateBuyoutSubsidyToNetsuite(oldOpportunityMap, newOpportunityList);

            new GS_FreeTrialQuoteCreatorService().createFreeTrialQuoteFromOpportunities(oldOpportunityMap, newOpportunityList);

            new GS_QuotaOpportunityService().processQuotaOpportunityDeletion(oldOpportunityMap, newOpportunityList);

            new GS_SBQQQuoteUpdationService().updateSBQQQuotesFromOpportunity(oldOpportunityMap, newOpportunityList);

            gsOpportunityRollupsToAccountObj.calculateRollUpsToAccount();


            (new GS_OpportunitySendEmailAsync()).sendReturnLabelEmail(oldOpportunityMap, newOpportunityList);


            (new GS_OpportunityService()).runOpportunityServiceAsyncFunctions(newOpportunityList, oldOpportunityMap, 'AFTER_UPDATE_OPERATIONS');
        }


        public void runBeforeDelete(Map<Id, Opportunity> oldOpportunityMap){
            // VIKAS Code will be here -
            //TrialOpptyUpdater.disconnectTrialsFromDeletes(oldOpportunityMap);
            new GS_DisconnectTrialOppService().processTrialDisconnectionsOnOpportunityDelete(oldOpportunityMap);
        }


        public void runAfterdelete(Map<Id, Opportunity> oldOpportunityMap){
            GS_OpportunityRollupsToAccount gsOpportunityRollupsToAccountObj = new GS_OpportunityRollupsToAccount(oldOpportunityMap.values(), null);
            gsOpportunityRollupsToAccountObj.calculateRollUpsToAccount();
        }


        public void runAfterUndelete(List<Opportunity> newOpportunityList){
            GS_OpportunityRollupsToAccount gsOpportunityRollupsToAccountObj = new GS_OpportunityRollupsToAccount(newOpportunityList, null);
            gsOpportunityRollupsToAccountObj.calculateRollUpsToAccount();
        }

    }



    public void runOpportunityServiceAsyncFunctions(List<Opportunity> oppList, Map<Id, Opportunity> oldOpportunityMap, String operation){
        if (!oppList.isEmpty()){
            Opportunity oldOpportunity = new Opportunity();
            GS_OpportunityServiceAsync asyncHandler = new GS_OpportunityServiceAsync();

            Map<Id, GS_OpportunityServiceAsync.ConsolidatedProcessAsyncConditions> conditionsMap =
                new Map<Id, GS_OpportunityServiceAsync.ConsolidatedProcessAsyncConditions>();
            
            Set<Id> idSetToRun = new Set<Id>();
            for (Opportunity opp : oppList){
                if(oldOpportunityMap != null && !oldOpportunityMap.isEmpty()){
                    oldOpportunity = oldOpportunityMap.get(opp.Id);
                }
                GS_OpportunityServiceAsync.ConsolidatedProcessAsyncConditions condition = asyncHandler.validateRecordForConsolidatedProcesses(oldOpportunity, opp);
                if (condition != null) conditionsMap.put(opp.Id, condition);

                idSetToRun.add(opp.Id);
            }

            DMLWrapper.doInsert(new GS_OpportunityServiceAsync().prepareAsyncRequests(
                JSON.serialize(new GS_OpportunityServiceAsync.Options(operation, conditionsMap)),
                idSetToRun
            ));
        }
    }
}