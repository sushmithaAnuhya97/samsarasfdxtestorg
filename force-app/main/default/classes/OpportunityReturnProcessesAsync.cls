/**
 * Created by vikasmishra on 2020-11-09.
 */

public without sharing class OpportunityReturnProcessesAsync extends BaseAsyncHandler {
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger(); 

    @TestVisible List<Id> recordsIds = new List<Id>();
    private Options option;
    public static String asyncContext;

    private List<Opportunity> filteredOpportunityList;
    private List<Opportunity> triggeredOpportunityList;

    public override String getRequestType(){
        return 'Opportunity Return Process Queueable';
    }

    public override void execute(Async_Request__c ar) {
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        option = (Options) JSON.deserialize(ar.Options__c, Options.class);

        Boolean hasError = false;
        try{
            switch on option.Operation {
                when 'CreateShipment' {
                    this.prepareOpportunityRecords(option);
                    this.createShipmentFromQueueable(this.filteredOpportunityList, this.triggeredOpportunityList);
                }
            }
        }catch(Exception ex){
            hasError = true;
            thisLogger.logError(
                'Error in OpportunityReturnProcessQueueable::',
                new SamsaraLoggerObjectMVP(
                    ex, recordsIds
                )
            );
            throw ex;
        }finally{
            if (hasError) thisLogger.dispatch();
        }
    }

    private void prepareOpportunityRecords(Options opt){
        // Required because of trimmed IDs on Params__c field.
        Set<Id> recordIdsSet = new Set<Id>();
        for (String recordId : this.recordsIds)
            recordIdsSet.add(Id.valueOf(recordId));
        
        Set<Id> filteredIdsSet = new Set<Id>();
        for (String recordId : opt.FilteredIds)
            filteredIdsSet.add(Id.valueOf(recordId));

        Set<Id> oppIds = new Set<Id>();
        oppIds.addAll(filteredIdsSet);
        oppIds.addAll(recordIdsSet);

        this.filteredOpportunityList = new List<Opportunity>();
        this.triggeredOpportunityList = new List<Opportunity>();

        Map<Id, Opportunity> queriedOppMap = new Map<Id, Opportunity>(
            (new GS_OpportunitySelector(false)).getOppForReturnProcessById(new List<Id>(oppIds))
        );

        for (Id oppId : queriedOppMap.keySet()){
            if (opt.FilteredIds.contains(oppId)){
                this.filteredOpportunityList.add(queriedOppMap.get(oppId));
            }

            if (recordIdsSet.contains(oppId)){
                this.triggeredOpportunityList.add(queriedOppMap.get(oppId));
            }
        }
    }

    public void createShipmentFromQueueable(List<Opportunity> filteredOpportunities, List<Opportunity> triggeredOpps) {
        List<Opportunity> promoOpportunities = new List<Opportunity>();
        List<Opportunity> triggerOpportunitiesToUpdate = new List<Opportunity>();
        String samsaraURL = 'https://samsara.my.salesforce.com/';
        for (Opportunity opp : filteredOpportunities) {
            system.debug('Opp.Id ---->'+opp.Id);
            Opportunity promoOpportunity = new Opportunity(
                    AccountId = opp.AccountId,
                    Cable_Tool_Activated__c = opp.Cable_Tool_Activated__c,
                    CloseDate = System.today(),
                    Corresponding_Netsuite_ID__c = opp.Corresponding_Netsuite_ID__c,
                    CurrencyIsoCode = opp.CurrencyIsoCode,
                    Name = 'Promo Opportunity - ' + opp.Return_Number_Shipping__c,
                    Notes__c = opp.Notes__c,
                    Promo_Reason__c = opp.Type,
                    RMA_Return_Opportunity__c = samsaraURL + opp.Id,
                    Return_Number_Shipping__c = opp.Return_Number_Shipping__c,
                    Shipping_Address_NEW__c = opp.Shipping_Address_NEW__c,
                    StageName = 'Purchase',
                    Type = 'Promo Opportunity',
                    Zendesk_Ticket_Number__c = opp.Zendesk_Ticket_Number__c,
                	Warranty_Exchange_Reason__c  = opp.Warranty_Exchange_Reason__c //Alekya
            );
            system.debug('Opp.Id ---->'+promoOpportunity.RMA_Return_Opportunity__c);
            promoOpportunities.add(promoOpportunity);
            //DMLWrapper.doInsert(promoOpportunity);
        }
        upsert promoOpportunities;


        Map<Id, Id> promoOppByCurrentOpp = new Map<Id, Id>();
        for (Opportunity opp : promoOpportunities) {
            system.debug('opp.RMA_Return_Opportunity__c ---->'+opp.RMA_Return_Opportunity__c);
            system.debug('opp.RMA_Return_Opportunity__c.replace ---->'+opp.RMA_Return_Opportunity__c.replace(samsaraURL, ''));
            Id currentOpp = Id.valueOf(opp.RMA_Return_Opportunity__c.replace(samsaraURL, ''));
            promoOppByCurrentOpp.put(currentOpp, opp.Id);
        }

        for (Opportunity opp : [SELECT id,Replacement_Opportunity__c FROM Opportunity WHERE Id IN:triggeredOpps]) {
            opp.Replacement_Opportunity__c = samsaraURL + promoOppByCurrentOpp.get(opp.Id);
            triggerOpportunitiesToUpdate.add(opp);
        }
        update triggerOpportunitiesToUpdate;
    }

    public class Options {
        public String Operation {get; set;}
        public List<String> FilteredIds; // Eligible actions comma separated
        
        public Options(String operation){
            this.Operation = operation;
        }

        public Options(String operation, List<String> filteredIds){
            this.Operation = operation;
            this.FilteredIds = filteredIds;
        }
    }
}