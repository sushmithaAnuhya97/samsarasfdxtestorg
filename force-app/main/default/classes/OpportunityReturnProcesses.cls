/*
* Created by Henry on 4/6/2020.
* 04/19/21 Lavanya - (GTMS-3519) changes to run(). Updated IF condition to check if shipmate preference field is null
* 11/13/20 Ron - (GTMS-2116) update run() to queueable execution of CreateShipment (Promo Oppty) + linking back to the return oppty
* 6/01/20 Harsha - (GTMS-759) Changes to run(), getReturnShippingLabelOrigin() (HQ Shipping for escalated accounts)
* 5/22/20 Harsha - (GTMS-921) Changes to run method (users should be able the change the owner at any stage)
* Aug-9-2022 Chinmaya  - (GTMS-5838) Commented out the flow callout (Created_Remorse_Refund)
* Aug-9-2022 Sweta - GTMS-6593  Added ReturnCrated also for ShipmatePreference logic. Fixed two null pointer exceptions issues, so that it populates the shipmate correctly
* Sep-2-2022 Siddharth Kumar Mishra - GTMS-7139 Added logic to diffrentiate between countries requiring automated label creation
* Dec-8-2022-GTMS-9846:Zakeer - added criteria before createShipmentApi-line#139 not to process 'Return Created' opptys.
* Apr-26-2023-GTMS-12196: Alekhya- Added Automation for Shipmate Preference on Returns for North America(United States,Canada) based on country and State logic in run()
* Apr-3-2022-GTMS-12124:Siddharth - Added ShipmatePreference-0513 'Estafeta' to the preference mappings
* Apr-26-2023-GTMS-12196: Alekhya- Added Automation for Shipmate Preference on Returns for North America(United States,Canada) based on country and State logic in run() line no: 128-163
*/

public with sharing class OpportunityReturnProcesses {
    public class OpportunityReturnProcessesException extends Exception {
    }
    /** Workflow Rules
* Return Cancelled by Rep?
* **/
    
    /** Flows
* Created_Remorse_Refund
* **/
    private List<Opportunity> newOpps;
    private Map<Id, Opportunity> oldOppMap;
    private final static Id ALLOWED_RECORD_TYPE = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
    
    public OpportunityReturnProcesses(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> OpportunityReturnProcesses -> initted');
        this.oldOppMap = oldOppMap;
        this.newOpps = newOpps;
    }
    
    public static Boolean canEnterReturnProcesses(Opportunity opp) {
        List<String> ACCEPTABLE_STAGES = new List<String>{
            'Return Created','Return Initiated', 'Return Cancelled'
                };
                    // Added Condition to bypass the refund process for the Opportunity which doesn't have hardware.GTMS-21917
                    List<Boolean> conditions = new List<Boolean>{
                        ALLOWED_RECORD_TYPE == opp.RecordTypeId,
                            ACCEPTABLE_STAGES.contains(opp.StageName),
                            opp.Returning_Opportunity__c != null
                            };
                                //  System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> canEnter -> !conditions.contains(false) -> ' + !conditions.contains(false));
                                return !conditions.contains(false);
    }
    
    public void runAfter() {
        System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> runAfter -> entered');
        
        List<Opportunity> oppsRemorseRefund = new List<Opportunity>();
        for (Opportunity opp : this.newOpps) {
            system.debug('canEnterReturnProcesses(opp) >>' + canEnterReturnProcesses(opp));
            if (!canEnterReturnProcesses(opp)) {
                continue;
            }
            final Opportunity oldOpp = null;
            if (this.oldOppMap != null) {
                oldOpp = this.oldOppMap.get(opp.Id);
            }
            
            System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> runAfter -> opp -> ' + opp);
            System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> runAfter -> oldOpp -> ' + oldOpp);
            
            if ((canCreateRemorseRefund(opp) && oldOpp == Null) || (canCreateRemorseRefund(opp) && opp.Type == 'Remorse Refund' && opp.StageName == 'Return Created' && opp.Return_Opportunity_Approval_Status__c == NULL)) {
                oppsRemorseRefund.add(opp);
            }
            
            if (oppsRemorseRefund.size() > 0) {
                System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> runAfter -> passed checks, executing flow');
                Map<String, Object> param = new Map<String, Object>{
                    'OppsToProcess' => oppsRemorseRefund
                        };
                            //commented Flow call out   @Chinmaya Dash GTMS-5838
                            //Flow.Interview.Created_Remorse_Refund remorseRefundFlow = new Flow.Interview.Created_Remorse_Refund(param);
                            //remorseRefundFlow.start();
                            }
        }
    }
    // added for gtms-12196
    public static Map<string, string> getCountryShipmatePreference() {
        Map<string, string> shipmatePref = new Map<string, string>();
        Map<string, Warehouse_Mapping__mdt> warehouseMdt = Warehouse_Mapping__mdt.getAll();
        for(String rec : warehouseMdt.keySet()){
            shipmatePref.put(warehouseMdt.get(rec).Country__c+warehouseMdt.get(rec).MasterLabel,warehouseMdt.get(rec).Shipmate_Preference__c);
        }
        return shipmatePref;   
    }
    // this should fire in before insert and before update
    // Replaces: Consolidated Returns Process
    // Decision was made to keep the delayed Email send as a Process Builder
    //* 11/13/20 Ron - (GTMS-2116) update run() to queueable execution of CreateShipment (Promo Oppty) + linking back to the return oppty
    public void run() {
        String ReturnOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        Map<Id, Opportunity> returningOpportunities = getReturningOpportunities(this.newOpps);
        List<String> filteredOpportunities = new List<String>();
        Map<Id, Opportunity> oldOppMap = (Map<Id, Opportunity>) Trigger.oldMap;
        Map<Id,Shipping_Address__c> IdVsShippingAddress = new  Map<Id,Shipping_Address__c>();
        //system.debug('run--> started');
        //gtms-12196
        Map<string, string> countryShipmatePref = getCountryShipmatePreference();
        Set<Id> shippingIds = new Set<Id>();
        // Define a mapping of returnShippingLabelOrigin values to Shipmate_Preference__c values
        Map<String, String> shippingLabelToPreference = new Map<String, String>{
        'UK Shipping Label'  => 'ShippingPreference-000001',
        'HQ Shipping Label'  => 'ShippingPreference-000010',
        'VCK Shipping Label' => 'ShippingPreference-000027',
        'Samsara HQ'         => 'ShippingPreference-000007',
        'Estafeta'          => 'ShippingPreference-000030'
        };
        for (Opportunity opp : this.newOpps){
            if (ReturnOppRecordTypeId == opp.RecordTypeId && opp.Shipping_Address_NEW__c != null && opp.StageName != 'Refunded - Closed' && opp.Type != 'Return to Sender' && opp.Type != 'Virtual Return') {
                shippingIds.add(opp.Shipping_Address_NEW__c);  
            } 
        }
        if(!shippingIds.isEmpty()){
            IdVsShippingAddress = getShippingAddress(shippingIds);
        }
        Map<Id, String> returnShippingLabelOrigin = getReturnShippingLabelOrigin(this.newOpps, ReturnOppRecordTypeId, IdVsShippingAddress);
        /* GTMS-28076 -- Abu -- 8/26/2025 -- Start*/
        List<String> emeaShippingCountryList = System.Label.EMEA_Countries.split(',');
        /* GTMS-28076 -- Abu -- 8/26/2025 -- End*/
        for (Opportunity opp : this.newOpps) {
            if(ReturnOppRecordTypeId != opp.RecordTypeId || opp.StageName == 'Refunded - Closed' || opp.Type == 'Return to Sender' || opp.Type == 'Virtual Return'){
                continue;
            }
            updateReturnOppStageToRefundedClosedNode(opp);
            //GTMS-13721. when shipping address is changed update the opportunity shipping state and shipmate preference
            if(oldOppMap != null && oldOppMap.containsKey(opp.id) && !IdVsShippingAddress.isEmpty() && IdVsShippingAddress.containsKey(opp.Shipping_Address_NEW__c) && oldOppMap.get(opp.id).Shipping_Address_NEW__c != opp.Shipping_Address_NEW__c ){
                opp.Shipping_State__c = IdVsShippingAddress.get(opp.Shipping_Address_NEW__c).Shipping_State__c;
                opp.Shipping_Country__c = IdVsShippingAddress.get(opp.Shipping_Address_NEW__c).Shipping_Country__c;
            } 
            if(!returnShippingLabelOrigin.isEmpty() && returnShippingLabelOrigin.containsKey(opp.Id) && (opp.Shipmate_Preference__c == null || ( oldOppMap != null && oldOppMap.containsKey(opp.id) && oldOppMap.get(opp.id).Shipping_Address_NEW__c != opp.Shipping_Address_NEW__c))){
                opp.Shipmate_Preference__c = shippingLabelToPreference.get(returnShippingLabelOrigin.get(opp.Id));
            }
            
            //GTMS-18016 - Added If for mexico location added mexico
            if (opp.Shipping_Country__c == 'United States' || opp.Shipping_Country__c == 'Canada' || String.isBlank(opp.Shipping_Country__c ) ) {
                if( (oldOppMap != null && oldOppMap.containsKey(opp.id) && oldOppMap.get(opp.id).Shipping_Address_NEW__c != opp.Shipping_Address_NEW__c)){
                    string shipmatePref;
                if(String.isBlank(opp.Shipping_State__c)){
                    shipmatePref = countryShipmatePref.get('Default'+'Default');
                }else{
                    shipmatePref = countryShipmatePref.get(opp.Shipping_Country__c+opp.Shipping_State__c);
                }
                //if (oldOppMap.get(opp.Id).Shipmate_Preference__c == 'ShipmatePreference-0238' || 
                //     oldOppMap.get(opp.Id).Shipmate_Preference__c == 'ShipmatePreference-0515')
                
                //system.debug(opp.Id);
                //system.debug( 'old map value'+oldOppMap.get(opp.Id).Shipmate_Preference__c );
                // system.debug( 'old map value Shipmate Value'+shipmatePref);
                if (shipmatePref != null && oldOppMap == null){
                    //system.debug('In first if'+shipmatePref);
                    opp.Shipmate_Preference__c = shipmatePref;
                }
                else if (shipmatePref != null && !oldOppMap.get(opp.Id).shipmate_Preference_override__c){
                    
                    //system.debug('In else'+shipmatePref);
                    opp.Shipmate_Preference__c = shipmatePref;
                }
                }
                
                //else if(!oldOppMap.get(opp.Id).shipmate_Preference_override__c)
                //opp.Shipmate_Preference__c = 'ShipmatePreference-0238';
            }   //GTMS-12196  
            /* GTMS-28076 -- Abu -- 8/26/2025 -- Start*/
            if(!String.isBlank(opp.Shipping_Country__c ) && emeaShippingCountryList.contains(opp.Shipping_Country__c) && !opp.shipmate_Preference_override__c){
                opp.Shipmate_Preference__c = 'ShippingPreference-000027';
            }
            /* GTMS-28076 -- Abu -- 8/26/2025 -- Endt*/
            //GTMS-6593. setting default shipmate preference
            if(opp.Shipmate_Preference__c == null) //populating the default shipmate preference, if its not populated above
                opp.Shipmate_Preference__c = 'ShippingPreference-000010';
            
            if (!canEnterReturnProcesses(opp)) {
                
                continue;
            }
            
            //system.debug('before stage check:' + opp.StageName + 'returnShippingLabelOrigin.get(opp.Id)=' + returnShippingLabelOrigin.get(opp.Id));
            //GTMS-6593. Added ReturnCreated here as per Biz request
            if (opp.StageName == 'Return Initiated' || opp.StageName == 'Return Created') {
                
                
                /* //gtms-12196


if(((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Hawaii')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Alaska')) ||((opp.Shipping_Country__c == 'United States')&& (opp.Shipping_State__c =='California'))
|| ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Washington')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Oregon')) ||((opp.Shipping_Country__c == 'United States') && (opp.Shipping_State__c == 'Idaho')) 
||((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Nevada')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Utah')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Arizona')) 
||((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Montana')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Wyoming')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Colorado'))
||((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'New Mexico')) || ((opp.Shipping_Country__c == 'Canada') &&(opp.Shipping_State__c == 'British Columbia')) ||((opp.Shipping_Country__c == 'Canada') &&(opp.Shipping_State__c == 'Alberta'))
|| ((opp.Shipping_Country__c == 'Canada') &&(opp.Shipping_State__c == 'Saskatchewan')) ||((opp.Shipping_Country__c == 'Canada') && (opp.Shipping_State__c == 'Manitoba')) ||((opp.Shipping_Country__c == 'Canada') && (opp.Shipping_State__c =='Yukon'))
|| ((opp.Shipping_Country__c == 'Canada') &&(opp.Shipping_State__c == 'Northwest Territories')) || ((opp.Shipping_Country__c == 'Canada') &&(opp.Shipping_State__c == 'Nunavut'))) {

if(oldOppMap.get(opp.Id).Shipmate_Preference__c != 'ShipmatePreference-0238'){
opp.Shipmate_Preference__c = 'ShipmatePreference-0238';
}
}
else if(((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'District of Columbia')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Maine')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c =='Vermont'))
|| ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'New Hampshire')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Massachusetts')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Rhode Island')) 
|| ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Connecticut')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'New Jersey')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Delaware' ))
|| ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Maryland')) ||  ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'New York')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Pennsylvania'))
||  ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Ohio')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'West Virginia')) ||((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Virginia'))
|| ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Michigan')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Indiana')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c =='Kentucky'))
|| ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Tennessee')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Wisconsin')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Illinois'))
|| ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Minnesota')) ||((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c =='Iowa')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Missouri')) ||
((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Arkansas')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Mississippi')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Alabama')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c =='South Carolina'))
|| ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'North Carolina')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Georgia')) ||((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Florida'))
|| ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Louisiana')) ||((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c =='Texas')) ||((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Oklahoma')) ||
((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Kansas')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'Nebraska')) || ((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c == 'South Dakota')) ||((opp.Shipping_Country__c == 'United States') &&(opp.Shipping_State__c =='North Dakota'))
|| ((opp.Shipping_Country__c == 'Canada') &&(opp.Shipping_State__c == 'Ontario')) ||((opp.Shipping_Country__c == 'Canada') && (opp.Shipping_State__c == 'Quebec')) ||((opp.Shipping_Country__c == 'Canada') &&(opp.Shipping_State__c == 'Newfoundland and Labrador'))
|| ((opp.Shipping_Country__c == 'Canada') &&(opp.Shipping_State__c == 'Prince Edward Island')) ||((opp.Shipping_Country__c == 'Canada') &&(opp.Shipping_State__c =='Nova Scotia')) || ((opp.Shipping_Country__c == 'Canada') &&(opp.Shipping_State__c == 'New Brunswick')) 
) {
if(oldOppMap.get(opp.Id).Shipmate_Preference__c != 'ShipmatePreference-0515'){
opp.Shipmate_Preference__c = 'ShipmatePreference-0515';
}
}
else{
if(oldOppMap.get(opp.Id).Shipmate_Preference__c != 'ShipmatePreference-0238'){
opp.Shipmate_Preference__c = 'ShipmatePreference-0238';
}
} // gtms-12196 */
                
                //GTMS-12196
                
                //GTMS-6593. Added null pointer check in below condition
                if (exchangeOrReturnInitiated(opp)
                    && HelperClass.isChanged(opp, oldoppmap<>null ? oldOppMap.get(opp.Id) : null, Schema.Opportunity.StageName)) 
                {
                    /* Replaces node 'Exchange - Return Initiated?' */
                    
                    //System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> run -> Beginning run zkmulti.InvocableShipmentCreate');
                    /** Create Shipment **/
                    if (!Test.isRunningTest()) 
                    {
                        //GTMS-7139
                        if((opp.of_HW_Products__c != 0 || opp.of_Accessories__c != 0) && opp.StageName != 'Return Created' &&opp.Shipmate_Country__c!= null && System.label.Automated_Return_Label_Generation_Countries.contains(opp.Shipmate_Country__c))
                        {
                            
                            zkmulti.InvocableShipmentCreate.CreateShipmentParameter zkmultiParam = new zkmulti.InvocableShipmentCreate.CreateShipmentParameter();
                            zkmultiParam.customAddressId = HelperClass.getGlobalValue('UPS_Custom_Address_Source');
                            zkmultiParam.recordId = opp.Id;
                            zkmulti.InvocableShipmentCreate.createShipment(new List<zkmulti.InvocableShipmentCreate.CreateShipmentParameter>{ zkmultiParam });
                        }
                    }
                    //System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> run -> End run zkmulti.InvocableShipmentCreate');
                    // Sonal: Apr 20, 2020. Flow is no more required. Logic is now in filteredOpportunities method
                    //                    /** Updated Stage - Shipping Label Sent **/
                    //                    Map<String, Object> param = new Map<String, Object>{
                    //                            'OpportunityId' => opp.Id
                    //                    };
                    //                    Flow.Interview.Check_If_UPS_Shipment_Created checkShipmentCreated
                    //                            = new Flow.Interview.Check_If_UPS_Shipment_Created(param);
                    //                    checkShipmentCreated.start();
                    //                    
                    if (opp.Type == 'Exchange' || opp.Type == 'Warranty Exchange') 
                    {
                        filteredOpportunities.add(opp.Id);
                    }
                    
                    
                    /** Set Free Trial Status to 'Return In Process' **/
                    if (opp.Type == 'Free Trial Opportunity') 
                    {
                        opp.Trial_Status__c = 'Return In Process';
                    }
                }
            }
            
            if(oldOppMap == null){
                isOwnerInactiveNode(opp, returningOpportunities);
                isOwnerActiveNode(opp, returningOpportunities);
            }
        }
        
        //GTMS-6593. Added null pointer check for oldOppMap in below condition
        if (filteredOpportunities != null && !filteredOpportunities.isEmpty() && oldOppMap != null) {
            //System.enqueueJob(new OpportunityReturnProcessesQueueable(filteredOpportunities, newOpps)); 
            
            DMLWrapper.doInsert(
                new OpportunityReturnProcessesAsync().prepareAsyncRequests(
                    JSON.serialize(new OpportunityReturnProcessesAsync.Options('CreateShipment', filteredOpportunities)),
                    oldOppMap.keySet()
                )
            );
        }
        
    }
    
    private static Boolean canCreateRemorseRefund(Opportunity opp) {
        return (opp.StageName.equals('Return Created') && opp.Created_Remorse_Refund__c);
    }
    
    
    @TestVisible
    private void createShipment(List<Opportunity> filteredOpportunities) {
        /*
List<Opportunity> promoOpportunities = new List<Opportunity>();
String samsaraURL = 'https://samsara.my.salesforce.com/';
for (Opportunity opp : filteredOpportunities) {
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
Zendesk_Ticket_Number__c = opp.Zendesk_Ticket_Number__c
);
promoOpportunities.add(promoOpportunity);
//DMLWrapper.doInsert(promoOpportunity);
}
//upsert promoOpportunities;


Map<Id, Id> promoOppByCurrentOpp = new Map<Id, Id>();
for (Opportunity opp : promoOpportunities) {
Id currentOpp = Id.valueOf(opp.RMA_Return_Opportunity__c.replace(samsaraURL, ''));
promoOppByCurrentOpp.put(currentOpp, opp.Id);
}

for (Opportunity opp : this.newOpps) {
opp.Replacement_Opportunity__c = samsaraURL + promoOppByCurrentOpp.get(opp.Id);
}
*/
    }
    
    /* 
public static void createShipmentFromQueueable(List<Opportunity> filteredOpportunities, List<Opportunity>triggeredOpps) {
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
Zendesk_Ticket_Number__c = opp.Zendesk_Ticket_Number__c
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
*/
    
    private void isOwnerInactiveNode(Opportunity opp, Map<Id, Opportunity> returningOpportunities) {
        
        /* Replaces node 'Is Owner Inactive?' */
        List<Boolean> ownerInactiveConditions = new List<Boolean>{
            returningOpportunities.get(opp.Returning_Opportunity__c).Owner.IsActive == false,
                opp.StageName == 'Return Created',
                opp.StageName == 'Return Initiated',
                opp.Owner_Manager_Email_Copy__c != null,
                opp.Type != 'Free Trial Return',
                opp.Owner_Manager_Role_Copy__c != null,
                opp.Type != 'Rebate', //GTMS-29333: Shifted Rebate Delinquent and Remorse Refund owner field logic to ReturnOwnerCopyDataUtility
                opp.Rebate_Type__c != 'Delinquent',
                opp.Type != 'Remorse Refund'
                };
                    
                    if (ownerInactiveConditions[0] 
                        && ownerInactiveConditions[3] 
                        && (ownerInactiveConditions[1] || ownerInactiveConditions[2]) 
                        && ownerInactiveConditions[4] 
                        && ownerInactiveConditions[5]
                        && (ownerInactiveConditions[6] || ownerInactiveConditions[7])
                        && ownerInactiveConditions[8]) 
                {
                                                                                         /** Update Owner as Manager **/
                                                                                         opp.OwnerId = opp.Owner_Manager_Name_Copy__c;
                                                                                     }
    }
    
    private void isOwnerActiveNode(Opportunity opp, Map<Id, Opportunity> returningOpportunities) {
        /* Replaces node 'Is Owner Active?' */
        List<Boolean> ownerActiveConditions = new List<Boolean>{
            returningOpportunities.get(opp.Returning_Opportunity__c).Owner.IsActive == true,
                opp.StageName == 'Return Created',
                opp.StageName == 'Return Initiated',
                opp.Type != 'Free Trial Return',
                opp.Rebate_Type__c != 'Partner Referral',
                opp.type != 'Rebate', //GTMS-29333: Shifted Rebate Delinquent and Remorse Refund owner field logic to ReturnOwnerCopyDataUtility
                opp.Rebate_Type__c != 'Delinquent',
                opp.Type != 'Type'
                };
                    if (ownerActiveConditions[0] 
                        && (ownerActiveConditions[1] || ownerActiveConditions[2])
                        && ownerActiveConditions[3] 
                        && ownerActiveConditions[4]
                        && (ownerActiveConditions[5] || ownerActiveConditions[6])
                        && ownerActiveConditions[7]) 
                {
                            /** Update Owner of Return Oppty **/
                            opp.OwnerId = returningOpportunities.get(opp.Returning_Opportunity__c).OwnerId;
                        }
    }
    
    private Map<Id, Opportunity> getReturningOpportunities(List<Opportunity> newOpps) {
        List<Id> returningOppIds = new List<Id>();
        Map<Id, Opportunity> returningOpportunities = new Map<Id, Opportunity>();
        for (Opportunity opp : newOpps) {
            if(opp.Returning_Opportunity__c != null){
                returningOppIds.add(opp.Returning_Opportunity__c);
            }
        }
        if(!returningOppIds.isEmpty()){
            returningOpportunities = new Map<Id, Opportunity>([
                SELECT
                Owner_Director_Name_Copy__c,
                Owner.Level__c,
                Owner.IsActive,
                Return_Label_Attachment__c,
                Is_Owner_Active__c,
                OwnerId
                FROM Opportunity
                WHERE Id = :returningOppIds
            ]);
        }
        return returningOpportunities;
    }
    
    @InvocableMethod(Label='Created Remorse Refund Logic')
    public static void createdRemorseRefund(List<List<Opportunity>> opps) {
        boolean doPublish = false;
        if (DMLWrapper.uow == null) {
            DMLWrapper.intializeUnitOfWork(new List<Schema.SObjectType>{
                Opportunity.SObjectType
                    });
            doPublish = true;
        }
        system.debug('In Invocalblle Harsha');
        createRemorseRefundProcess(opps);
        if (doPublish) DMLWrapper.publishDML();
        
    }
    
    private static void createRemorseRefundProcess(List<List<Opportunity>> opps) {
        if (opps.size() == 0) {
            System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> createdRemorseRefund -> received input of size 0!');
            throw new OpportunityReturnProcessesException('received input of size 0!');
        }
        final Set<Id> idsToQuery = new Map<Id, Opportunity>(opps[0]).keySet();
        List<Opportunity> refreshedOpps = [
            SELECT Id,
            Return_Reason__c,
            Return_Subreason__c,
            Opportunity_Age_at_Return_C__c,
            OwnerId,Probability
            FROM Opportunity
            WHERE Id = :idsToQuery
        ];
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        
        List<SobjectField> dirtyFields = new List<SobjectField>();
        for (Opportunity opp : refreshedOpps) {
            if (String.isBlank(opp.Return_Reason__c)) {
                opp.Return_Reason__c = 'Rep Did Not Respond';
                dirtyFields.add(Opportunity.Return_Reason__c);
            }
            if (String.isBlank(opp.Return_Subreason__c)) {
                opp.Return_Subreason__c = 'Rep Did Not Respond';
                dirtyFields.add(Opportunity.Return_Subreason__c);
            }
            if (opp.Opportunity_Age_at_Return_C__c <= 30  && opp.Probability < 25) {
                opp.StageName = 'Return Initiated';
                dirtyFields.add(Opportunity.StageName);
            }
            System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> createdRemorseRefund -> Set Reasons for ' + opp.Id);
            System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> createdRemorseRefund -> opp.Return_Reason__c -> ' + opp.Return_Reason__c);
            System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> createdRemorseRefund -> opp.Opportunity_Age_at_Return_C__c -> ' + opp.Opportunity_Age_at_Return_C__c);
            System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> createdRemorseRefund -> opp.Return_Subreason__c -> ' + opp.Return_Subreason__c);
            DMLWrapper.doUpdate(Opp, dirtyFields);
            Approval.ProcessSubmitRequest apprv = new Approval.ProcessSubmitRequest();
            apprv.setSubmitterId(opp.OwnerId);
            apprv.setObjectId(opp.Id);
            //            setting this to null so we go through default approval process as per process builder
            apprv.setProcessDefinitionNameOrId(null);
            approvalRequests.add(apprv);
        }
        
        //update refreshedOpps;
        System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> createdRemorseRefund -> done update.');
        try {
            Approval.process(approvalRequests);
        } catch (DmlException excptn) {
            System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> createdRemorseRefund -> ' + excptn.getDmlType(0));
            if (excptn.getDmlType(0) != StatusCode.NO_APPLICABLE_PROCESS) {
                System.debug('OpportunityReturnProcesses.cls');
                System.debug('*****APEX EXCEPTION***** ' + excptn.getMessage());
                throw excptn;
            }
        }
    }
    
    /**
* Logic for Opportunity.Exchange_or_Return_Initiated__c formula field
*
*/
    public static Boolean exchangeOrReturnInitiated(Opportunity opp) {
        Boolean exchangeOrReturnInitiated = false;
        List<String> opportunityTypes = new List<String>{
            'Exchange', 'Warranty Exchange', 'Free Trial Return', 'Remorse Refund'
                };
                    if (opportunityTypes.contains(opp.Type)
                        && opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId()) {
                            exchangeOrReturnInitiated = true;
                        }
        return exchangeOrReturnInitiated;
    }
    
    /**
* Logic for Opportunity.Return_Shipping_Label_Origin__c formula field
*
*/
    public static Map<Id, String> getReturnShippingLabelOrigin(List<Opportunity> opps, String returnRecordTypeId, Map<Id, Shipping_Address__c> shippingAddressesByIds) {
        //List<Id> shippingAddresses = new List<Id>();
        Map<Id, String> shippingCountriesByOppIds = new Map<Id, String>();
        Map<Id, String> returnShippingLabelOriginByOppIds = new Map<Id, String>();
        /*GTMS-13721 Commenting the lines
         * for (Opportunity opp : opps) {
            //GTMS-6593. Added null check
            if(opp.Shipping_Address_NEW__c <> null && opp.recordTypeId == returnRecordTypeId ){  
                shippingAddresses.add(opp.Shipping_Address_NEW__c);
            }
        }
        if (shippingAddresses.size() > 0) {
            // system.debug('The shipping adress is' +shippingAddresses);
            Map<Id, Shipping_Address__c> shippingAddressesByIds = new Map<Id, Shipping_Address__c>([
                SELECT Id, Shipping_Country__c
                FROM Shipping_Address__c
                WHERE Id = :shippingAddresses
            ]);
            
            for (Opportunity opp : opps) {
                if (shippingAddressesByIds.get(opp.Shipping_Address_NEW__c) != null) {
                    shippingCountriesByOppIds.put(opp.Id, shippingAddressesByIds.get(opp.Shipping_Address_NEW__c).Shipping_Country__c);
                }
            }
        }*/
        if (!shippingAddressesByIds.isEmpty()) {
            for (Opportunity opp : opps) {
                if (shippingAddressesByIds.containsKey(opp.Shipping_Address_NEW__c)) {
                    shippingCountriesByOppIds.put(opp.Id, shippingAddressesByIds.get(opp.Shipping_Address_NEW__c).Shipping_Country__c);
                }
            }
        }
        List<String> shippingCountries = new List<String>{'United States', 'Canada', 'Mexico', 'Puerto Rico'};
        //GTMS-12124
        List<String> opptyStages = new List<String>{'Remorse Refund','Free Trial Return','Exchange','Warranty Exchange'};
        if (OpportunityHelperContext.oppAccounts == null) OpportunityHelperContext.loadOppAccounts(opps);
        
        // Changes as part of GTMS-759
        for (Opportunity opp : opps) {
            if(opp.recordTypeId != returnRecordTypeId){
                continue;
            }
            if(!shippingCountriesByOppIds.isEmpty()){
                String returnShippingLabelOrigin;
                Account thisOppAccount = new Account();
                if(opp.AccountId != NULL && OpportunityHelperContext.oppAccounts.containsKey(opp.AccountId)) {
                    thisOppAccount = OpportunityHelperContext.oppAccounts.get(opp.AccountId);
                }
                //system.debug('opp.Type=' + opp.Type + ', shippingCountries.contains(shippingCountriesByOppIds.get(opp.Id))=' + shippingCountries.contains(shippingCountriesByOppIds.get(opp.Id)) + ', thisOppAccount=' + thisOppAccount);            
                //system.debug('shippingCountries.size()=' + shippingCountries.size() + ', shippingCountries.contains='+ shippingCountries.contains(shippingCountriesByOppIds.get(opp.Id)));
                //GTMS-12124
                if( shippingCountriesByOppIds.containsKey(opp.Id) && shippingCountriesByOppIds.get(opp.Id)=='Mexico' && opptyStages.contains(opp.Type)) {
                    returnShippingLabelOrigin = 'Estafeta';
                }
                else if (shippingCountriesByOppIds.containsKey(opp.Id) && opp.Type == 'Warranty Exchange' && shippingCountries.contains(shippingCountriesByOppIds.get(opp.Id)) && thisOppAccount != null) {
                    if(thisOppAccount.Critically_Escalated_Hardware_Returns__c){
                        returnShippingLabelOrigin = 'Samsara HQ';
                    }
                } 
                else if (shippingCountriesByOppIds.containsKey(opp.Id) && !shippingCountries.contains(shippingCountriesByOppIds.get(opp.Id))) {
                    returnShippingLabelOrigin = 'VCK Shipping Label';
                }
                /*
else if (opp.Type == 'Remorse Refund' && !shippingCountries.contains(shippingCountriesByOppIds.get(opp.Id))) {
returnShippingLabelOrigin = 'UK Shipping Label';
}
*/
                else if (opp.Type == 'Remorse Refund' || (shippingCountriesByOppIds.containsKey(opp.Id) && shippingCountries.contains(shippingCountriesByOppIds.get(opp.Id)))) {
                    returnShippingLabelOrigin = 'HQ Shipping Label';
                }
                else {
                    returnShippingLabelOrigin = 'DCL Shipping Label';
                }
                returnShippingLabelOriginByOppIds.put(opp.Id, returnShippingLabelOrigin);
            }
        }
        return returnShippingLabelOriginByOppIds;
    }
    
    private void updateReturnOppStageToRefundedClosedNode(Opportunity opp) {
        /*System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> entered');
System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> opp.Type -> ' + opp.Type);
System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> opp.Amount -> ' + opp.Amount);
System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> opp.RecordType.DeveloperName -> ' + opp.RecordType.DeveloperName);
System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> opp.StageName -> ' + opp.StageName);*/
        
        
        /** Replaces node Update Return Opp Stage to Refunded Closed 
Digital only Trial Returns should not receive a Return Label - GTMS-21917
**/
        if ((opp.Type == 'Free Trial Return'
             || opp.Type == 'Exchange'
             || opp.Type == 'Warranty Exchange')
            && opp.Amount == 0
            && (opp.StageName == 'Finance Processing' || 
                (opp.StageName == 'Return Initiated' && opp.of_LIC_Products__c != 0 &&
                 opp.of_HW_Products__c == 0 && opp.of_Accessories__c == 0
                 && opp.Type == 'Free Trial Return'))
           ) {
               // System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> setting stage to refunded closed');
               opp.StageName = 'Refunded - Closed';
           }
    }
    public static Map<Id,Shipping_Address__c> getShippingAddress(Set<Id> ShippingAdressId){
        Map<Id,Shipping_Address__c> shippingAddressesById = new Map<Id, Shipping_Address__c>();
        if(ShippingAdressId != null && !ShippingAdressId.isEmpty()) {
            shippingAddressesById = new Map<Id, Shipping_Address__c>([
                SELECT Id, Shipping_State__c, Shipping_Country__c
                FROM Shipping_Address__c
                WHERE Id = :ShippingAdressId
            ]);   
        }
        return shippingAddressesById;
    }
}