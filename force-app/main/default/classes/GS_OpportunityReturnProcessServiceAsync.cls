/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 06, 2021
*
* @description : This class will be responsible for handling Async Actions for the OpportunityReturnProcessService
* SFA-11
*
**/
public with sharing class GS_OpportunityReturnProcessServiceAsync extends BaseAsyncHandler {
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();

    public override String getRequestType(){
        return 'Opportunity Return Process Async Job';
    } 
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Opportunity.SObjectType
        //Account.SObjectType
    };
    
    /* UnitOfWork uow = new UnitOfWork(MY_SOBJECTS); */
    List<Id> recordsIds = new List<Id>();

    private UnitOfWork uow;

    @TestVisible private Map<Id, Opportunity> testOpportunityData;
    @TestVisible private Boolean shouldPublishDMLs = true;
    
    public override void execute(Async_Request__c ar){

        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);
        List<String> additionalData = (String.isBlank(opt.additionalData) ? new List<String>() : opt.additionalData.split(','));

        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in GS_OpportunityReturnProcessServiceAsync');
            switch on opt.Operation {
                when 'CREATE_SHIPMENT_MP' {	
                    for (String recordId : recordsIds)
                        this.createShipmentParameter(recordId);
                }
                when 'RETURN_PROCESS'{
                    this.createShipmentFromQueueable(recordsIds, additionalData);
                }
                when 'REMORSE_REFUND' {
                    this.callRemorseRefundFlow(recordsIds);
                }
            }

            this.publishDMLs();
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_OpportunityReturnProcessServiceAsync::', new SamsaraLoggerObjectMVP(
                ex, recordsIds
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.logTrace('Exiting in GS_OpportunityReturnProcessServiceAsync');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    // TODO: Needs to revalidate the query to make sure all fields needed are included.
    public void callRemorseRefundFlow(List<Id> recordsIds){
        List<Opportunity> opportunityList = (new GS_OpportunitySelector(false)).loadOpportunityWithItems(new Set<Id>(recordsIds));

        System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> runAfter -> passed checks, executing flow');
        Map<String, Object> param = new Map<String, Object>{
                'OppsToProcess' => opportunityList
        };
        Flow.Interview.Created_Remorse_Refund remorseRefundFlow = new Flow.Interview.Created_Remorse_Refund(param);
        remorseRefundFlow.start();
    }
    
    //GTMS-22356 Updated reference zkups to zkmulti
    public void createShipmentParameter(Id opportunityId){
        System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> run -> Beginning run zkmulti.InvocableShipmentCreate');
        /** Create Shipment **/
        if (!Test.isRunningTest()) {
            zkmulti.InvocableShipmentCreate.CreateShipmentParameter zkmultiParam
                    = new zkmulti.InvocableShipmentCreate.CreateShipmentParameter();
            zkmultiParam.customAddressId = HelperClass.getGlobalValue('UPS_Custom_Address_Source');

            zkmultiParam.recordId = opportunityId;
            zkmulti.InvocableShipmentCreate.createShipment(
                new List<zkmulti.InvocableShipmentCreate.CreateShipmentParameter>{
                        zkmultiParam
                }
            );
        }
        System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> run -> End run zkmulti.InvocableShipmentCreate');
    }

    public void createShipmentFromQueueable(List<Id> filteredOpportunitiesIds, List<String> triggeredOppsIds) {
        // Assuming filteredOpportunitiesIds are a subset of data within triggeredOppsIds
        Map<Id, Opportunity> oppMapTest = new Map<Id, Opportunity>();
        
        if (Test.isRunningTest() && testOpportunityData != null && !testOpportunityData.isEmpty()) oppMapTest = testOpportunityData;

        createPromoOpportunities(filteredOpportunitiesIds, triggeredOppsIds, oppMapTest, false);
    }
    
    @AuraEnabled
    public static void createPromoOpportunities(List<Id> filteredOpportunitiesIds, List<String> triggeredOppsIds, Map<Id, Opportunity> oppMapTest, Boolean isLWC) {
        try {
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
            if (Test.isRunningTest() && oppMapTest != null && !oppMapTest.isEmpty()) {
                oppMap = oppMapTest;
            } else {
                oppMap = new Map<Id, Opportunity>(
                    (new GS_OpportunitySelector(false)).getOppForReturnProcessById(triggeredOppsIds)
                );
            }

            List<Opportunity> promoOpportunities = new List<Opportunity>();
            List<Opportunity> triggerOpportunitiesToUpdate = new List<Opportunity>();
            String samsaraURL = 'https://samsara.my.salesforce.com/';
            for (String oppId : filteredOpportunitiesIds) {
                Opportunity opp = oppMap.get(oppId);

                promoOpportunities.add(new Opportunity(
                        AccountId = opp.AccountId,
                        Cable_Tool_Activated__c = opp.Cable_Tool_Activated__c,
                        CloseDate = System.today(),
                        Corresponding_Netsuite_ID__c = opp.Corresponding_Netsuite_ID__c,
                        CurrencyIsoCode = opp.CurrencyIsoCode,
                        Name = 'Promo Opportunity - ' + opp.Return_Number_Shipping__c,
                        Notes__c = opp.Notes__c,
                        Promo_Reason__c = isLWC ? 
                            (opp.Type == 'Unplanned Return' ? 'Unplanned Return: Exchange' :
                             opp.Type == 'Return To Sender' ? 'Return to Sender: Exchange' :
                             opp.Type == 'Free Trial Return' ? 'Free Trial: Warranty Exchange' : opp.Type) : opp.Type,
                        RMA_Return_Opportunity__c = samsaraURL + opp.Id,
                        Return_Number_Shipping__c = opp.Return_Number_Shipping__c,
                        Shipping_Address_NEW__c = opp.Shipping_Address_NEW__c,
                        StageName = 'Purchase',
                        Type = 'Promo Opportunity',
                        Zendesk_Ticket_Number__c = opp.Zendesk_Ticket_Number__c,
                        Warranty_Exchange_Reason__c  = opp.Warranty_Exchange_Reason__c //Alekya
                ));
            }
            if (!isLWC) {
                DMLWrapper.doUpsert(promoOpportunities);
            } else {
                try{
                    insert promoOpportunities;
                } catch (Exception ex){
                    LOGGER.atInfo().setCLassName('GS_OpportunityReturnProcessServiceAsync createPromoOpportunities').setExceptionOrMessage('Error while updating inserting Promo opportunities: '+ ex.getMessage());
                }
            }

            Map<Id, Id> promoOppByCurrentOpp = new Map<Id, Id>();
            for (Opportunity opp : promoOpportunities) {
                Id currentOpp = Id.valueOf(opp.RMA_Return_Opportunity__c.replace(samsaraURL, ''));
                promoOppByCurrentOpp.put(currentOpp, opp.Id);
            }

            for (String oppId : triggeredOppsIds) {
                Opportunity opp = oppMap.get(oppId);
                opp.Replacement_Opportunity__c = samsaraURL + promoOppByCurrentOpp.get(oppId);
                triggerOpportunitiesToUpdate.add(opp);
            }

            if (!isLWC) {
                DMLWrapper.doUpdate(triggerOpportunitiesToUpdate);
            } else {
                try{
                    update triggerOpportunitiesToUpdate;
                } catch (Exception ex){
                    LOGGER.atInfo().setCLassName('GS_OpportunityReturnProcessServiceAsync createPromoOpportunities').setExceptionOrMessage('Error while updating original opportunities: '+ ex.getMessage());
                }
            }
            if(isLWC){
                Logger.setFunctionalityType('Create Promo Opportunitites - Create Promo button.'); 
                Logger.insertMasterLogs();
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error in createPromoOpportunities: ' + ex.getMessage());
        }
    }

    public void publishDMLs() {
        uow = DMLWrapper.uow;
        if (!Test.isRunningTest() || this.shouldPublishDMLs) DMLWrapper.publishDML(uow);
    }
    
    public class Options {
        public String Operation {get; set;}
        public String additionalData {get; set;}
        
        public Options(String operation){
            this.Operation = operation;
        }

        public Options(String operation, String additionalData){
            this.Operation = operation;
            this.additionalData = additionalData;
        }
    }
}