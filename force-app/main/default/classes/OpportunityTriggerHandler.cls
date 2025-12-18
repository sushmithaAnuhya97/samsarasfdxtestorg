/*
* Nov-14-2022 Rajesh - GTMS-9570 - Commented timesCalled('pbConversionAfterUpdate') check
*/
public class OpportunityTriggerHandler extends TriggerHandler {

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
            Async_Request__c.SObjectType
    };
    private Map<Id, Opportunity> oldOppMap;
    private Map<Id, Opportunity> newOppMap;
    private List<Opportunity> newOppList;
    private OpportunityHelper opptyHelper;
    private OppHelperForOrderAndFinance opptyHelperForOrderAndFinance;
    private UpdateQuoteFromOpportunity opportunityQuoteHelper;
    public static Map<Id, OpportunityLineItem> opportunityLineItems = new Map<Id, OpportunityLineItem>();

    public static Trigger_Setting__mdt avalaraSetting = new List<Trigger_Setting__mdt>([SELECT Enabled__c, Loops__c FROM Trigger_Setting__mdt WHERE MasterLabel = 'Avalara' LIMIT 1])[0];

    // use to manually turn on / off trigger from a test method
    @TestVisible private static Boolean isEnabled;
    @TestVisible private static Integer maxRuns = 1;
    @TestVisible private static Map<String, Integer> methodsCalled = new Map<String, Integer>();
    Private UnitOfWork uow ;
    public static Boolean bypassForSyncMechanism = false;
    public OpportunityTriggerHandler() {
        opptyHelper = new OpportunityHelper();
        opptyHelperForOrderAndFinance = new OppHelperForOrderAndFinance();
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
            opptyHelper.createFirstOpportunityFromContact(newOppList);
            opptyHelper.beforeInsertOnly(newOppList);
            opptyHelper.beforeInsertOrUpdate(newOppList, oldOppMap,newOppMap);
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
            opptyHelper.afterInsertOperations(newOppList);
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
        }
        opptyHelper.associateRebateOppsToChannelOpps(newOppMap);
        opptyHelper.calculateAllRollUpsToAccount(newOppList, null);
        opptyHelper.updateAccountRecords();
        
		//GTMS-16221 -- Created Future method to perform logic 
		//and update Account with Finance Partner and 3PF customer
        opptyHelper.populateFinacePartneronAccount(null,newOppList);
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
		opptyHelper.validateLicenseTermOnOfandCPQ(newOppList, oldOppMap);
        // Not capped to prevent recursion; recursion limits within the method instead
        opptyHelper.beforeInsertOrUpdate(newOppList, oldOppMap,newOppMap);
        opptyHelper.beforeUpdateOnly(oldOppMap, newOppList);
        opptyHelper.checkForChangeInSmartApprovalFields(oldOppMap, newOppList);
        OpportunityProcessBuilderConversion.closingOppWithStripeTrialOrExpessFinanceApproval(newOppMap,oldOppMap);
        OpportunityProcessBuilderConversion.setPartnerReferralAmount(newOppList); // added for GTMS-23648
        OpportunityProcessBuilderConversion.processContractUpdates(newOppMap, oldOppMap);
        (new OrderValidationServiceAutomation()).runAfter(newOppList, oldOppMap);
        //OrderValidationAutomation.stageValidation(newOppList, newOppMap, oldOppMap);
        //GTMS-23446 start
        opptyHelper.masterSheetReqBefore(newOppList,oldOppMap);
        opptyHelper.expressSetAnnualDiscountLineItemOnbefore(oldOppMap,newOppMap);
        //GTMS-23446 end        
        opptyHelper.orderAdminRoundRobin(oldOppMap, newOppMap);
        opptyHelper.populateOptyTrackerField(oldOppMap, newOppMap);
        /** GTMS-15414 - START **/
        opptyHelper.emeaOpsAutomationPromoOppty(newOppList, oldOppMap);
        /** GTMS-15414 - END **/
        /** GTMS-18015 - START **/
        opptyHelper.emeaOpsAutomationRevnueOppty(newOppList, oldOppMap);
        /** GTMS-18015 - END **/
        //GTMS-10698 - Cross Sell Opportunity Identifier
        //opptyHelper.updateOpptyPurchaseType(oldOppMap, newOppMap);
        //ShippingHandlingCalculations.updateShippingAndHandlingForOpportunity(newOppList);
	OpportunityAutomationNotesCtrl.upatedAutomationNotesForWifiProduct(newOppList,oldOppMap);//GTMS-26279
        OppHelperForOrderAndFinance.updateShipFromLocationBasedOnCountry(newOppList, oldOppMap);
    }

    public override void afterUpdate() {

        if (timesCalled('afterUpdate') < maxRuns) {
            new OpportunityReturnProcesses(newOppList, oldOppMap).runAfter();
            opptyHelper.accountFieldUpdate(newOppList, oldOppMap);
            opptyHelper.createPlatformEvent();
            addCall('afterUpdate');
            opptyHelper.expressSetAnnualDiscountLineItem(oldOppMap, newOppMap);
            TrialOpptyUpdater.handleReturnUpdate(oldOppMap, newOppMap);
            opptyHelper.rebateBuyoutSubsidyToNetsuite(oldOppMap, newOppMap, newOppList);
            opptyHelper.freeTrialQuoteCreator(oldOppMap, newOppMap, newOppList);
            opptyHelper.deleteQuotaOpportunityRecords(oldOppMap, newOppMap, newOppList);
            //opportunityQuoteHelper.updateQuotes(oldOppMap, newOppMap, newOppList); // GTMS-13262 moved below
            //opptyHelper.uncheckContractRenewal(oldOppMap, newOppList); // commented this line as part of GTMS-22719
            opptyHelper.performUpdateOnFPQ(newOppList, newOppMap); // GTMS-16003 3PF Project
            opptyHelper.submitForTrialExtensionApproval(newOppList,oldOppMap);
            (new OpportunityToSELogsService()).runAfter(this.newOppMap);
            opptyHelper.updateOrders(oldOppMap, newOppList);
            ManualAccountARRCalculation.calulateActiveACVOnOpportunityClosed(newOppList, oldOppMap);//GTMS-21800
        }
        if(!FlexCnRTriggerBypass__c.getInstance().Bypass_Sync_and_Flag_Reset_Logic__c){            
            opptyHelper.flexUnsetCnRFlag(newOppList,oldOppMap,newOppMap);
            opptyHelper.flexSyncReturnOpportunities(newOppList, oldOppMap, newOppMap);
        }  
        if(bypassForSyncMechanism == false){    
        opptyHelper.calculateAllRollUpsToAccount(newOppList, oldOppMap);
        }
        opportunityQuoteHelper.updateQuotes(oldOppMap, newOppMap, newOppList);
        opptyHelper.updateAccountRecords();
		opptyHelper.updateContractDate(newOppList,oldOppMap);
        opptyHelper.sendReturnLabelEmail(oldOppMap, newOppMap);
		opptyHelper.afterUpdateAccount(oldOppMap, newOppList);
		opptyHelper.updateChildTrialOptyTrialStatus(oldOppMap, newOppList);
        
        //GTMS-27166
        opptyHelper.sendWarrantyExchangeEOLEmail(oldOppMap, newOppMap);
        //GTMS-16221 -- Created Future method to perform logic and update Account with Finance Partner and 3PF customer
        opptyHelper.populateFinacePartneronAccount(oldOppMap,newOppList);
        //if (timesCalled('pbConversionAfterUpdate') < 1) { //GTMS-9570
            addCall('pbConversionAfterUpdate');
            OpportunityProcessBuilderConversion.opptyConsolidatedProcesses(newOppMap, oldOppMap);
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
        opptyHelper.calculateAllRollUpsToAccount(oldOppMap.values(), null);
        opptyHelper.updateAccountRecords();
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-08-31
    * Not yet deployed for Production
    * GTMS-1471
    */
    public override void afterUndelete() {
        opptyHelper.calculateAllRollUpsToAccount(newOppList, null);
        opptyHelper.updateAccountRecords();
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

}