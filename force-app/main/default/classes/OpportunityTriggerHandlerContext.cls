public class OpportunityTriggerHandlerContext extends TriggerHandler {
    
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Opportunity.SObjectType,
            OpportunityLineItem.SObjectType,
            Contact.SobjectType,
            Quota_Opportunity__c.SObjectType,
            ADR_Transfer_Log__c.SobjectType,
            Account.SObjectType,
            User.SObjectType,
            Contract.SObjectType,
            SBQQ__Quote__c.SObjectType,
            Async_Request__c.SObjectType,
            OpportunityTeamMember.SObjectType
            };
                
                private Map<Id, Opportunity> oldOppMap;
    private Map<Id, Opportunity> newOppMap;
    private List<Opportunity> newOppList;
    private OpportunityHelper opptyHelper;
    private OppHelperForOrderAndFinance opptyHelperForOrderAndFinance;
    private OpportunityHelperContext opptyHelperContext;
    private OpportunityHelperBeforeInsert opptyHelperBeforeInsert;
    private OpportunityHelperBeforeUpdate opptyHelperBeforeUpdate;
    private OpportunityHelperAfterInsert opptyHelperAfterInsert;
    private OpportunityHelperAfterUpdate opptyHelperAfterUpdate;
    private UpdateQuoteFromOpportunity opportunityQuoteHelper;
    public static Map<Id, OpportunityLineItem> opportunityLineItems = new Map<Id, OpportunityLineItem>();
    public static Trigger_Setting__mdt avalaraSetting = new List<Trigger_Setting__mdt>([SELECT Enabled__c, Loops__c FROM Trigger_Setting__mdt WHERE MasterLabel = 'Avalara' LIMIT 1])[0];
    // use to manually turn on / off trigger from a test method
    @TestVisible private static Boolean isEnabled;
    @TestVisible private static Integer maxRuns = 1;
    @TestVisible private static Map<String, Integer> methodsCalled = new Map<String, Integer>();
    Private UnitOfWork uow ;
    public static Boolean bypassForSyncMechanism = false;
    //To avoid return copy fields update, once owner is changed from RelatedReturnOpportunityController
    public static Boolean bypassForCopyDataMechanism = false;
    public static Integer startCPUTime;
    public static set<string> logExecution = new set<string>();
    public OpportunityTriggerHandlerContext() {
        opptyHelper = new OpportunityHelper();
        opptyHelperForOrderAndFinance = new OppHelperForOrderAndFinance();
        opptyHelperContext = new OpportunityHelperContext();
        opptyHelperBeforeInsert = new OpportunityHelperBeforeInsert();
        opptyHelperBeforeUpdate = new OpportunityHelperBeforeUpdate();
        opptyHelperAfterInsert = new OpportunityHelperAfterInsert();
        opptyHelperAfterUpdate = new OpportunityHelperAfterUpdate();
        opportunityQuoteHelper = new UpdateQuoteFromOpportunity();
        this.oldOppMap = (Map<Id, Opportunity>) Trigger.oldMap;
        this.newOppMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.newOppList = (List<Opportunity>) Trigger.new;
        //Already been initialized in Opportunity Domain Class
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }
    
    public override void beforeInsert() {
        if (timesCalled('beforeInsert') < maxRuns) {
            addCall('beforeInsert');
            // Don't need to instantiate trialopptyupdater because it doesn't have static variables
            TrialOpptyUpdater.handleTrialUpdate(oldOppMap, newOppList);
            //opptyHelper.createFirstOpportunityFromContact(newOppList);
            opptyHelperBeforeInsert.beforeInsertOnly(newOppList);
            //GTMS-29333: To update owner from revenue at the time of return creation
            OrderFinanceHelper.updateOppOwnerContra(newOppList, oldOppMap);
            opptyHelperContext.beforeInsertOrUpdate(newOppList, oldOppMap,newOppMap);
            new OpportunityReturnProcesses(newOppList, null).run();
            OpportunityProcessBuilderConversion.accountOwnerTeamEmail(newOppList);
            ShippingHandlingCalculations.updateShippingAndHandlingForOpportunity(newOppList);
            System.debug('OpportunityTriggerHandler.beforeInsert called ' + timesCalled('beforeInsert') + ' times');
            OppHelperForOrderAndFinance.updateShipFromLocationBasedOnCountry(newOppList, null);
        }
    }
    public override void afterInsert() {
        if (timesCalled('afterInsert') < maxRuns) {
            addCall('afterInsert');
            //Testing for Clari POC
            opptyHelperAfterInsert.afterInsertOperations(newOppList);
            //OpportunityHelper.createClariOpp(newOppMap.keySet());
            //End Clari Testing
            new OpportunityReturnProcesses(newOppList, oldOppMap).runAfter();
            TrialOpptyUpdater.handleReturnCreation(newOppMap);
            OpportunityProcessBuilderConversion.readyToShipOrClosedWon(newOppMap, oldOppMap);
            OpportunityProcessBuilderConversion.pushInfoToNetsuite(newOppMap, oldOppMap);
            OpportunityProcessBuilderConversion.postToSlack(newOppList, oldOppMap);
            //OpportunityProcessBuilderConversion.welcomeTrialKitProductsOnClosing(newOppList);
            OpportunityProcessBuilderConversion.opptyConsolidatedProcesses(newOppMap, oldOppMap);
            System.debug('OpportunityTriggerHandler.afterInsert called ' + timesCalled('afterInsert') + ' times');
            opptyHelperContext.afterInsertOrUpdate(oldOppMap,newOppList);
          
        }
        opptyHelperAfterInsert.associateRebateOppsToChannelOpps(newOppMap);
        opptyHelperContext.getRecords(newOppMap,oldOppMap);
        opptyHelperContext.calculateAccountRollup(newOppMap,oldOppMap);
        opptyHelperContext.updateAccountRecords();
        //GTMS-16221 -- Created Future method to perform logic
        //and update Account with Finance Partner and 3PF customer
        opptyHelperContext.populateFinacePartneronAccount(null,newOppList);
    }
    public override void beforeUpdate() {
        if (timesCalled('beforeUpdate') < maxRuns) {
            addCall('beforeUpdate');
            //opptyHelper.beforeInsertOrUpdate(newOppList, oldOppMap);
            new OpportunityReturnProcesses(newOppList, null).run();
            TrialOpptyUpdater.handleTrialUpdate(oldOppMap, newOppList);
            TrialOpptyUpdater.handleRevenueUpdate(oldOppMap, newOppMap);
            //OpportunityProcessBuilderConversion.shippingEmailsByBusinessLine(newOppList);
            OpportunityProcessBuilderConversion.readyToShipOrClosedWon(newOppMap, oldOppMap);
            OpportunityProcessBuilderConversion.pushInfoToNetsuite(newOppMap, oldOppMap);
            OpportunityProcessBuilderConversion.accountOwnerTeamEmail(newOppList);
            OpportunityProcessBuilderConversion.postToSlack(newOppList, oldOppMap);
            //Opportunity Helper to update Order management Processor field
            opptyHelperForOrderAndFinance.updateOrderManagementProcessor(newOppList, oldOppMap);
            System.debug('OpportunityTriggerHandler.beforeUpdate called ' + timesCalled('beforeUpdate') + ' times');
        }
        //3/24/25 Vijaychandra AMARANENI --START-- (GTMS-26731): Added below method to create Rebate Opportunities for all CR which are eligible for payout.
        PartnersOpportunityHelper.opptyAfterClosing(newOppList, oldOppMap);
        //3/24/25 Vijaychandra AMARANENI --END-- (GTMS-26731)
        //GTMS-16459 - Added below method to validate if there is difference in orderfrom and CPQ license terms
        opptyHelperBeforeUpdate.validateLicenseTermOnOfandCPQ(newOppList, oldOppMap);
        // Not capped to prevent recursion; recursion limits within the method instead
        opptyHelperContext.beforeInsertOrUpdate(newOppList, oldOppMap,newOppMap);
        opptyHelperBeforeUpdate.beforeUpdateOnly(oldOppMap, newOppList);
        opptyHelperBeforeUpdate.beforeUpdateCommit(newOppMap);
        opptyHelperBeforeUpdate.checkForChangeInSmartApprovalFields(oldOppMap, newOppList);
        OpportunityProcessBuilderConversion.closingOppWithStripeTrialOrExpessFinanceApproval(newOppMap,oldOppMap);
        //To log order automation failures - GTMS-28045
        OrderFinanceHelper.logOrderAutomationFailures(newOppList, oldOppMap);
        OpportunityProcessBuilderConversion.setPartnerReferralAmount(newOppList); // added for GTMS-23648
        OpportunityProcessBuilderConversion.processContractUpdates(newOppMap, oldOppMap);
        (new OrderValidationServiceAutomation()).runAfter(newOppList, oldOppMap);
        //OrderValidationAutomation.stageValidation(newOppList, newOppMap, oldOppMap);
        //GTMS-23446 start
        opptyHelperBeforeUpdate.masterSheetReqBefore(newOppList,oldOppMap);
        opptyHelperBeforeUpdate.freeTrialOpptyUScadEmeaMexicoLogic(newOppList, oldOppMap); //GTMS-27362
        opptyHelperBeforeUpdate.expressSetAnnualDiscountLineItemOnbefore(oldOppMap,newOppMap);
        //GTMS-23446 end
        opptyHelperBeforeUpdate.orderAdminRoundRobin(oldOppMap, newOppMap);
        opptyHelperBeforeUpdate.populateOptyTrackerField(oldOppMap, newOppMap);
        /** GTMS-15414 - START **/
        opptyHelperBeforeUpdate.emeaOpsAutomationPromoOppty(newOppList, oldOppMap);
        /** GTMS-15414 - END **/
        /** GTMS-18015 - START **/
        opptyHelperBeforeUpdate.emeaOpsAutomationRevnueOppty(newOppList, oldOppMap);
        /** GTMS-18015 - END **/
        //GTMS-10698 - Cross Sell Opportunity Identifier
        //opptyHelper.updateOpptyPurchaseType(oldOppMap, newOppMap);
        //ShippingHandlingCalculations.updateShippingAndHandlingForOpportunity(newOppList);
        OpportunityAutomationNotesCtrl.upatedAutomationNotesForWifiProduct(newOppList,oldOppMap);//GTMS-26279
        OppHelperForOrderAndFinance.updateShipFromLocationBasedOnCountry(newOppList, oldOppMap);
        //GTMS-29333: To update owner from revenue at the time of Returning_Opportunity__C change on return opportunity
        OrderFinanceHelper.updateOppOwnerContra(newOppList, oldOppMap);
        OpportunityRMADealsValidator.checkRMAOppHasPL1HWAndAccessories(newOppList, oldOppMap);//GTMS-26176
        //opptyHelperBeforeUpdate.EnhancedCrossSellLogic(newOppList,oldOppMap); //GTMS-28024 cross-sell logic
    }
    public override void afterUpdate() {
        logExecution.clear();
        startCPUTime = Limits.getCpuTime(); 
        if (timesCalled('afterUpdate') < maxRuns) {
            new OpportunityReturnProcesses(newOppList, oldOppMap).runAfter();
            opptyHelperAfterUpdate.accountFieldUpdate(newOppList, oldOppMap);
            opptyHelperBeforeUpdate.createPlatformEvent();
            addCall('afterUpdate');
            opptyHelperAfterUpdate.expressSetAnnualDiscountLineItem(oldOppMap, newOppMap);
            TrialOpptyUpdater.handleReturnUpdate(oldOppMap, newOppMap);
            opptyHelperAfterUpdate.rebateBuyoutSubsidyToNetsuite(oldOppMap, newOppMap, newOppList);
            opptyHelperAfterUpdate.freeTrialQuoteCreator(oldOppMap, newOppMap, newOppList);
            opptyHelperAfterUpdate.deleteQuotaOpportunityRecords(oldOppMap, newOppMap, newOppList);
            //opportunityQuoteHelper.updateQuotes(oldOppMap, newOppMap, newOppList); // GTMS-13262 moved below
            //opptyHelper.uncheckContractRenewal(oldOppMap, newOppList); // commented this line as part of GTMS-22719
            opptyHelperAfterUpdate.performUpdateOnFPQ(newOppList, newOppMap); // GTMS-16003 3PF Project
            opptyHelperAfterUpdate.submitForTrialExtensionApproval(newOppList,oldOppMap);
            (new OpportunityToSELogsService()).runAfter(this.newOppMap);
            opptyHelperAfterUpdate.updateOrders(oldOppMap, newOppList);
           ManualAccountARRCalculation.calulateActiveACVOnOpportunityClosed(newOppList, oldOppMap);//GTMS-21800
            opptyHelperContext.afterInsertOrUpdate(oldOppMap,newOppList);
            
        }
        if(!FlexCnRTriggerBypass__c.getInstance().Bypass_Sync_and_Flag_Reset_Logic__c){
            opptyHelperAfterUpdate.flexUnsetCnRFlag(newOppList,oldOppMap,newOppMap);
            opptyHelperAfterUpdate.flexSyncReturnOpportunities(newOppList, oldOppMap, newOppMap);
        }
        if(bypassForSyncMechanism == false){
            opptyHelperContext.getRecords(newOppMap,oldOppMap);
            opptyHelperContext.calculateAccountRollup(newOppMap,oldOppMap);
        }
        opportunityQuoteHelper.updateQuotes(oldOppMap, newOppMap, newOppList);
        opptyHelperContext.updateAccountRecords();
        opptyHelperAfterUpdate.updateContractDate(newOppList,oldOppMap);
        opptyHelperAfterUpdate.sendReturnLabelEmail(oldOppMap, newOppMap);
        opptyHelperAfterUpdate.afterUpdateAccount(oldOppMap, newOppList);
        opptyHelperAfterUpdate.updateChildTrialOptyTrialStatus(oldOppMap, newOppList);
        //GTMS-27166
        opptyHelperAfterUpdate.sendWarrantyExchangeEOLEmail(oldOppMap, newOppMap);
        //GTMS-16221 -- Created Future method to perform logic and update Account with Finance Partner and 3PF customer
        opptyHelperContext.populateFinacePartneronAccount(oldOppMap,newOppList);
        //if (timesCalled('pbConversionAfterUpdate') < 1) { //GTMS-9570
        addCall('pbConversionAfterUpdate');
        OpportunityProcessBuilderConversion.opptyConsolidatedProcesses(newOppMap, oldOppMap);
        if (runPromoBySetting()) {
            system.debug('insideglobalset');
            opptyHelperAfterUpdate.createOLIForPromo(oldOppMap, newOppList, false);
        }
        //}
        DiagnosticsInstrumentation.pop();
    }
    public override void beforeDelete() {
        addCall('beforeDelete');
        TrialOpptyUpdater.disconnectTrialsFromDeletes(oldOppMap);
    }
    /**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-08-31
* Not yet deployed for Production
* GTMS-1471
*/
    public override void afterdelete() {
        opptyHelperContext.getRecords(newOppMap,oldOppMap);
        opptyHelperContext.calculateAccountRollup(newOppMap,oldOppMap);
        opptyHelperContext.updateAccountRecords();
    }
    /**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-08-31
* Not yet deployed for Production
* GTMS-1471
*/
    public override void afterUndelete() {
        opptyHelperContext.getRecords(newOppMap,oldOppMap);
        opptyHelperContext.calculateAccountRollup(newOppMap,oldOppMap);
        opptyHelperContext.updateAccountRecords();
    }
    /**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-08-31
* Not yet deployed for Production
* GTMS-1471
*/
    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
        Global_Automation_Settings__c control = Global_Automation_Settings__c.getInstance();
        if( !logExecution.isEmpty() && control?.Create_Log_Records__c && startCPUTime != null && startCPUTime != Limits.getCpuTime()){  
            try { 
                SamsaraLogEntries__c log = new SamsaraLogEntries__c();  
                LOGGER logRec = new LOGGER();
                Logger.LogContext logContext = logRec.createLogContext((System.LoggingLevel.INFO));
                log.sourceApiName__c = 'OpportunityTriggerHandlerContext';
                log.SourceMetadataType__c = 'Apex';
                log.Method__c = String.join(logExecution, ',');
                log.RecordId__c = (newOppList!= null && !newOppList.isEmpty()) ? newOppList[0].id : null;
                log.Level__c = 'INFO';
                log.CPU_Time__c = Limits.getCpuTime() - startCPUTime;
                logContext.stageLog(log);
                Logger.insertMasterLogs();
            } catch(Exception e) {
                LOGGER.atError().setClassName('OpportunityTriggerHandlerContext').setExceptionOrMessage(e);
                Logger.setFunctionalityType('publishDML');
                Logger.setRecordIds(newOppMap.keySet());
                Logger.insertMasterLogs();
            }
    }
    }
    /*** Helper for enabling/disabling trigger ***/
    public static Boolean isEnabled() {
        if (isEnabled == true) {
            return true;
        }
        List<Trigger_Setting__mdt> opportunityTriggerSettings = [SELECT Enabled__c FROM Trigger_Setting__mdt WHERE MasterLabel = 'Opportunity' LIMIT 1];
        if (opportunityTriggerSettings.isEmpty()) {
            return true;
        }
        return opportunityTriggerSettings.get(0).Enabled__c;
    }
    /*** Helpers for debugging & preventing recursion ***/
    public static void resetAll() {
        methodsCalled = new Map<string, integer>();
    }
    public static integer timesCalled(String Input) {
        if (!methodsCalled.containsKey(Input)) {
            return 0;
        } else {
            return methodsCalled.get(Input);
        }
    }
    public static integer addCall(String Input) {
        if (!methodsCalled.containsKey(Input)) {
            methodsCalled.put(input, 1);
        } else {
            Integer i = methodsCalled.get(input) + 1;
            methodsCalled.put(input, i);
        }
        return methodsCalled.get(input);
    }
    
    
    public static Boolean runPromoBySetting() {     
        
        // List Custom Setting row key; change if yours differs
        Automation_Settings__c cs = Automation_Settings__c.getValues('Samsara for Samsara');
         return (cs == null || cs.Disabled__c == false);
    }
}