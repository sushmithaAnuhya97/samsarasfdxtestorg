/**********************************************************************
Name: OpportunityHelperBeforeUpdate
Purpose: This class will contains method that will be called in the before update context                                                    

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Apr-30        INITIAL DEVELOPMENT 

***********************************************************************/

public class OpportunityHelperBeforeUpdate extends OpportunityHelperContext {
    public static Org_Setting__mdt orderTransformationSetting = Org_Setting__mdt.getInstance('OrderTransformationPhase2');
    public static List<Opportunity_Event__e> opportunityEvents = new List<Opportunity_Event__e>();
    public static  List<Order_Event__e> orderSyncEvents = new List<Order_Event__e>();
    public static  List<Rebate_Event__e> rebateSyncEvents = new List<Rebate_Event__e>();
    public static List<Opportunity> promoOpportunities = new List<Opportunity>();
    public static Map<Id,Opportunity> mapOppToPromo = new Map<Id,Opportunity>();
    public static Boolean syncOppoPromoFlag = false;

    private static final String OPP_STAGE_RET_LABEL_SENT    =   'Return Label Sent';
    private static final String OPP_STAGE_RET_FIN_PROCESS   =   'Finance Processing';
    private static final String OPP_TYPE_REMORSE_REFUND     =   'Remorse Refund';
    private static final String OPP_SUB_TYPE_UPGRADE        =   'Upgrade';

    public static Id opportunityRevRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standard_Opportunity').getRecordTypeId();
    Global_Automation_Settings__c gas = Global_Automation_Settings__c.getInstance(UserInfo.getUserId());

    public void beforeUpdateOnly(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList) {
        //beforeInsertOrUpdate(newOppList, oldOppMap);
        syncOpportunity(newOppList, oldOppMap);
        //GTMS-25560 - Feb-10-2025 -- Start
        List<Opportunity> remorseOppo = new List<Opportunity>();
        Set<String> naCurrencySet = new Set<String>{'USD','CAD','MXN'};
            Set<String> emeaCurrencySet = new Set<String>{'CHF','EUR','GBP'};  
                //GTMS-25560 - Feb-10-2025 -- End
                Map<Id, Id> opportunityIds  = new Map<Id, Id>();
        Set<Id> setOfUserIds = new Set<Id>();
        //GTMS-6450
        Map<ID,Account> accountMapBookBiz = new Map<Id,Account>([SELECT Id,Book_of_Business__c FROM ACCOUNT WHERE ID IN : accountIdSet AND  Book_of_Business__c = null]);
        //GTMS-16225: START
        Set<Id> primaryQuoteIds = new Set<Id>();
        for (Opportunity oppt : newOppList) {
            if(oppt.SBQQ__PrimaryQuote__c !=null){
                primaryQuoteIds.add(oppt.SBQQ__PrimaryQuote__c);
            }
            if(oppt.StageName != oldOppMap.get(oppt.Id).StageName && oppt.StageName != null && (oppt.StageName == 'Orders Processing' || oppt.StageName == 'Ready to Ship' ||  oppt.StageName == 'Closed Won')){
                setOfUserIds.add(Userinfo.getUserId());
            }
            //GTMS-29391: START
            if(oppt.SBQQ__RenewedContract__c!=null){    
                Boolean acvChanged = oppt.ACV_Bookings_USD__c!=null && (oppt.ACV_Bookings_USD__c != oldOppMap.get(oppt.id).ACV_Bookings_USD__c);
                Boolean availableToRenewChanged = oppt.Available_to_Renew__c!=null && oppt.Available_to_Renew__c != oldOppMap.get(oppt.id).Available_to_Renew__c;
                Boolean isClosedLost = oppt.StageName == 'Closed Lost' && oppt.IsClosed != oldOppMap.get(oppt.id).IsClosed;
                
                if(availableToRenewChanged) {
                    Decimal oldValue = oldOppMap.get(oppt.id).Available_to_Renew__c;
                    Decimal newValue = oppt.Available_to_Renew__c;
                    String logMessage = 'Available to Renew ACV changed from ' + oldValue + ' to ' + newValue + 
                                      ' | Changed by User: ' + UserInfo.getName() + ' (' + UserInfo.getUserId() + ')' +
                                      ' | Opportunity: ' + oppt.Name + ' (' + oppt.Id + ')';
                    LOGGER.atInfo()
                          .setCLassName('OpportunityHelperBeforeUpdate')
                          .setMethod('beforeUpdateOnly')
                          .setRecordId(oppt.Id)
                          .setExceptionOrMessage(getLoggerMessage(logMessage));
                }
                
                if(acvChanged || availableToRenewChanged || isClosedLost){
                    setRenewalSubType(oppt);
                }
            }
            //GTMS-29391: END
        }
        Map<ID,SBQQ__Quote__c> finanaceMapQuote = new Map<Id,SBQQ__Quote__c>([SELECT Id, Finance_Partner_Account__c,DCA_Validation__c from SBQQ__Quote__c where Id =: primaryQuoteIds]);
        //GTMS-16225: END
        if(!setOfUserIds.isEmpty()){ 
            getOpptyOwner(new Set<Id>{Userinfo.getUserId()}); 
        }
        // GTMS-29094 START : Inline rollups from line items (Sites_ACV_Bookings__c, Unique_Shipping_Addresses__c)
        Set<String> sitesFamilies = new Set<String>{ 'Connected Worker', 'Connected Sites' }; // GTMS-29094 END
        for (Opportunity o : newOppList) {
            if (System.isFuture() || System.isScheduled() || System.isBatch() || System.isQueueable()) {
                o.Bypass_Validation_Rule_DateTime__c = Datetime.now(); //GTMS-25783: Bypass VR Return_Opportunities_are_locked_for_Sel
            }
            // GTMS 25726: Restrict amended opp linked to In progress C&R from closing
            if(o.AccountId != null && o.SBQQ__AmendedContract__c != null && oppFields.containskey(o.Id))
            {
                // GTMS 25726: FeatureManagement.checkPermission returns true if the user has the specified   custom permission.
                
                if (!System.FeatureManagement.checkPermission('Validation_Exemption_Opportunity')&& 
                    o.of_LIC_Products__c!= 0 && 
                    oppFields.get(o.Id).Account.Account_C_R_In_Progress__c && 
                    oppFields.get(o.Id).SBQQ__AmendedContract__r.Contract_C_R_In_Progress__c && 
                    (o.Sub_Type__c!= 'Contract Cancellation' && o.Sub_Type__c!= 'Contract Replacement') && 
                    o.StageName == 'Closing')
                {
                    o.addError('You cannot submit this Opportunity to “Closing” because the amending contract is undergoing a C&R process, and this opportunity contains LIC which may alter this contract');
                }  
            }
            if( o.StageName != oldOppMap.get(o.Id).StageName && o.StageName != null  
            && mapUsers.containskey(Userinfo.getUserId()) 
            && !System.isBatch() && !System.isQueueable() 
            && Label.SkipValidationForStages.contains(mapUsers.get(Userinfo.getUserId()).Profile.Name) 
            && (o.StageName == 'Orders Processing' || o.StageName == 'Ready to Ship' ||  o.StageName == 'Closed Won')
            && o.Bypass_Validation_Rule_DateTime__c == oldOppMap.get(o.Id).Bypass_Validation_Rule_DateTime__c)
            {
                o.addError('Action not allowed: As an Account Executive, you cannot save this record when the stage is either Orders Processing, Ready to Ship, Closed Won, or Closed Lost.Please ensure you have the appropriate access.');
            }
            string quoteDcaValidation = (finanaceMapQuote != null) ? finanaceMapQuote.get(o.SBQQ__PrimaryQuote__c)?.DCA_Validation__c:null;
            if( o.SBQQ__PrimaryQuote__c != null && o.SBQQ__PrimaryQuote__c != oldOppMap.get(o.Id).SBQQ__PrimaryQuote__c && quoteDcaValidation == 'DCA'  && o.isClosed == false){
                Opportunity oppo = (oppFields != null )? oppFields.get(o.Id):null;
                List<dsfs__DocuSign_Status__c> docuSignStatus = oppo?.R00N80000002fD9vEAE;
                if(docuSignStatus != null){
                    for(dsfs__DocuSign_Status__c docu:docuSignStatus){
                        if(docu.Primary_Quote__c == o.SBQQ__PrimaryQuote__c && String.isNotBlank(docu.Customer_require_PO_for_invoicing__c) ){
                            o.Customer_require_PO_for_invoicing__c =  docu.Customer_require_PO_for_invoicing__c;
                            o.PO_Number__c = docu.PO_Number__c;
                            break ;
                        }
                    }
                }
            }
            Opportunity oldOpp = new Opportunity();
            //GTMS-21122 Setting UUID in opportunity
            if(String.isBlank(o.Opportunity_UUID__c)){
                o.Opportunity_UUID__c = SSUtils.getUUID();
            }
            //GTMS-5451: Setting the "Is_Webstore_Upsell_Opportunity__c" to true if that field is being modified
            if(o.Is_Webstore_Upsell_Opportunity__c != oldOppMap.get(o.Id).Is_Webstore_Upsell_Opportunity__c){
                o.Is_Webstore_Upsell_Opportunity__c = true;
            }
            if(o.Is_Webstore_Upsell_Opportunity__c){
                o.Finance_Partner__c=null; // added for GTMS-19857
                if(oppAccounts != null && oppAccounts.get(o.AccountId) != null) {
                    if(String.isNotBlank(oppAccounts.get(o.AccountId).Payment_Terms__c)) {
                        o.Payment_Terms__c = oppAccounts.get(o.AccountId).Payment_Terms__c;
                    }
                    if(String.isNotBlank(oppAccounts.get(o.AccountId).Approved_Payment_Type__c)) {
                        o.Internal_Finance_Payment_Type__c = oppAccounts.get(o.AccountId).Approved_Payment_Type__c;
                    }
                }
            }
            if(!gas.Opportunity_Flow__c && o.StageName == 'End of Life with Promo' && o.Replacement_Opportunity__c == null && (o.Type == 'Exchange' || o.Type == 'Warranty Exchange')){
                    Opportunity promoOpp = new Opportunity(
                        AccountId                    = o.AccountId,
                        Amount                       = o.Amount,
                        Cable_Tool_Activated__c      = o.Cable_Tool_Activated__c,
                        CloseDate                    = System.today(),
                        Corresponding_Netsuite_ID__c = o.Corresponding_Netsuite_ID__c,
                        CurrencyIsoCode              = o.CurrencyIsoCode,
                        Currency_Converted_Tracker__c= o.Currency_Converted_Tracker__c,
                        Finance_Partner__c           = o.Finance_Partner__c,
                        Name                         = o.Name + ' - Promo',
                        Notes__c                     = o.Notes__c,
                        OwnerId                      = o.OwnerId,
                        Promo_Reason__c              = o.Type,
                        RMA_Return_Opportunity__c    = URL.getOrgDomainUrl().toExternalForm() + '/'+o.Id,
                        RecordTypeId                 = opportunityRevRecordTypeId,
                        Shipping_Address_Line_1__c   = o.Shipping_Address_Line_1__c,
                        Shipping_Address_Line_2__c   = o.Shipping_Address_Line_2__c,
                        Shipping_Address_NEW__c      = o.Shipping_Address_NEW__c,
                        Shipping_City__c             = o.Shipping_City__c,
                        Shipping_Contact__c          = o.Shipping_Contact__c,
                        Shipping_Country__c          = o.Shipping_Country__c,
                        Shipping_State__c            = o.Shipping_State__c,
                        Shipping_Zip_Code__c         = o.Shipping_Zip_Code__c,
                        StageName                    = 'Purchase',
                        Type                         = 'Promo Opportunity',
                        Unique_Shipping_Addresses__c = o.Unique_Shipping_Addresses__c,
                        Warranty_Exchange_Reason__c  = o.Warranty_Exchange_Reason__c,
                        Zendesk_Ticket_Number__c     = o.Zendesk_Ticket_Number__c
                    );
                    promoOpportunities.add(promoOpp);
            }
            //GTMS-16225: START
            if(!finanaceMapQuote.isEmpty()){
                if((o.Probability == 98 && oldOppMap.get(o.Id).Probability == 95) && finanaceMapQuote.containsKey(o.SBQQ__PrimaryQuote__c) && (o.Finance_Partner__c != finanaceMapQuote.get(o.SBQQ__PrimaryQuote__c).Finance_Partner_Account__c)){
                    o.addError('Opportunity Finance Partner and Quote Finance Partner does not match.');
                }     
            }
            
            //GTMS-16225: END
            if(o.License_Term__c != oldOppMap.get(o.Id).License_Term__c && o.CPQ_Opportunity__c == true){
                o.License_Term__c = o.License_Term_CPQ__c != null ? o.License_Term_CPQ__c : o.License_Term__c;
            }
            if (oldOppMap.size() > 0) {
                oldOpp = oldOppMap.get(o.Id);
            }
            // Stamp stage change analysis fields
            OpportunityTriggerHandler.addCall('OpportunityHelper.stageChangeAnalysis');
            System.debug('OpportunityHelper.stageChangeAnalysis: ' + OpportunityTriggerHandler.timesCalled('OpportunityHelper.stageChangeAnalysis'));
            //rattlesnake project requirement
            if(oppAccounts != null && oppAccounts.containsKey(o.AccountId) && ((oppAccounts.get(o.AccountId).Segment__c == 'Enterprise' || oppAccounts.get(o.AccountId).Segment__c == 'AE3') && oppAccounts.get(o.AccountId).Owner_Role__c != null && 
                                                                               !oppAccounts.get(o.AccountId).Owner_Role__c.contains('COR')) && (oppAccounts.get(o.AccountId).CurrencyIsoCode=='USD' || oppAccounts.get(o.AccountId).CurrencyIsoCode=='CAD' || oppAccounts.get(o.AccountId).CurrencyIsoCode=='MXN') &&
               (String.isNotBlank(o.Type) && (o.Type=='Revenue Opportunity' || o.Type=='Remorse Refund' || (o.Type=='Rebate'  && o.Rebate_Type__c =='Delinquent')))
              ){
                  //Run Rattlesnake Logic
              }
            else if(
                (o.isClosed == false ||(o.IsClosed == true && oldOpp.isClosed == false))
            ){
                if(o.SBQQ__RenewedContract__c!=null || o.Renewal__c || (oppFields!=null && oppFields.containsKey(o.Id) && oppFields.get(o.Id).Returning_Opportunity__c!=null && oppFields.get(o.Id).Returning_Opportunity__r.Renewal__c)){
                    o.Split_New_ACV__c = 0;
                    o.Split_Renewal_ACV__c = o.ACV_Bookings_SOT__c;
                }
                else{
                    o.Split_New_ACV__c = o.ACV_Bookings_SOT__c;
                    o.Split_Renewal_ACV__c = 0;
                }
            }
            //update for GTMS-22807, commented the populuation of went to fields
            // as this needs to be called in insert and update both scenarios.
            /*if (o.StageName == 'Incubate' && oldOpp.StageName != 'Incubate') {
o.Went_To_Incubate_Date__c = Datetime.Now();
o.Went_To_Incubate__c = TRUE;
} else if (o.StageName == 'Qualified' && oldOpp.StageName != 'Qualified') {
o.Went_To_Qualified_Date__c = Datetime.Now();
o.Went_To_Qualified__c = TRUE;
} else if (o.StageName == 'Trial' && oldOpp.StageName != 'Trial') {
o.Went_To_Trial_Date__c = Datetime.Now();
o.Went_To_Trial__c = TRUE;
} else if (o.StageName == 'Proposal' && oldOpp.StageName != 'Proposal') {
o.Went_To_Proposal_Date__c = Datetime.Now();
o.Went_To_Proposal__c = TRUE;
} else if (o.StageName == 'Decision' && oldOpp.StageName != 'Decision') {
o.Went_To_Decision_Date__c = Datetime.Now();
o.Went_To_Decision__c = TRUE;
} else if (o.StageName == 'Purchase' && oldOpp.StageName != 'Purchase') {
o.Went_To_Purchase_Date__c = Datetime.Now();
o.Went_To_Purchase__c = TRUE;
} else if (o.StageName == 'Closing' && oldOpp.StageName != 'Closing') {
o.Went_To_Closing_Date__c = Datetime.Now();
o.Went_To_Closing__c = TRUE;
} else if (o.StageName == 'Orders Processing' && oldOpp.StageName != 'Orders Processing') {
o.Went_to_Orders_Processing_Date__c = Datetime.Now();
o.Went_to_Orders_Processing__c = TRUE;
if (!(o.Type == 'Revenue Opportunity' && o.SBQQ__Renewal__c == true) && o.CloseDate != Date.today()){
o.CloseDate = Date.today();
}
} else if (o.StageName == 'Ready To Ship' && oldOpp.StageName != 'Ready To Ship') {
o.Went_To_Ready_To_Ship_Date__c = Datetime.Now();
o.Went_To_Ready_To_Ship__c = TRUE;
} else*/ if (o.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
    //o.Went_To_Closed_Won_Date__c = Datetime.Now();
    //o.Went_To_Closed_Won__c = TRUE;
    if(((Boolean.valueOf(orderTransformationSetting.Value__c) == false && o.Type != 'Free Trial Opportunity') || (Boolean.valueOf(orderTransformationSetting.Value__c) == true && o.Type != 'Free Trial Opportunity') && o.Type != 'Revenue Opportunity') ||
       (Boolean.valueOf(orderTransformationSetting.Value__c) == true && oppFields.containsKey(o.Id) && oppFields.get(o.Id).Orders.isEmpty() && ( o.Type == 'Free Trial Opportunity' || o.Type == 'Revenue Opportunity'))) {
           o.SBQQ__Contracted__c = True;
       }
} else if ((o.StageName == 'Refunded - Closed' && oldOpp.StageName != 'Refunded - Closed') && o.SBQQ__AmendedContract__c != NULL ) {
    if(Boolean.valueOf(orderTransformationSetting.Value__c) == false || (Boolean.valueOf(orderTransformationSetting.Value__c) == true
                                                                         && o.Type != 'Free Trial Return' && o.Type != 'Warranty' && o.Type != 'Rebate')) {
                                                                             o.SBQQ__Contracted__c = True;
                                                                         }
} else if (o.StageName == 'Closed Lost' && oldOpp.StageName != 'Closed Lost') {
    o.Went_To_Closed_Lost_Date__c = Datetime.Now();
    o.Went_To_Closed_Lost__c = TRUE;
    o.CloseDate = Date.Today();
    if (closedLostOppIdSet == null) closedLostOppIdSet = new Set<Id>();
    if (o.SBQQ__RenewedContract__c == null) closedLostOppIdSet.add(o.Id);
}
            if ((o.Type == 'Warranty Exchange' || o.Type == 'Exchange' || o.Type == 'Remorse Refund') && o.StageName == 'Return Initiated' && oldOpp.StageName != 'Return Initiated') {
                o.Return_Label_Sent_At__c = Date.Today();
            }
            if(!duplicateOpportunityEvents.contains(o.Id) && o.SBQQ__RenewedContract__c != NULL && o.StageName != oldOpp.StageName && o.StageName == 'Ready to Ship'){
                opportunityEvents.add(new Opportunity_Event__e(Id__c = o.Id));
                duplicateOpportunityEvents.add(o.Id);
            }
            if(o.Amount != NULL && o.SBQQ__RenewedContract__c != NULL && o.Renewal_ACV__c == NULL && o.License_Term_CPQ__c != NULL && o.License_Term_CPQ__c != 0 ){
                o.Renewal_ACV__c = o.Amount / (o.License_Term_CPQ__c / 12);
            }
            /* GTMS-11183
if(oldOpp != null){
system.debug('*******calculateEquipmentACV********');
EquipmentACVCalculationService eqpAcvCalcService = new EquipmentACVCalculationService();
eqpAcvCalcService.calculateEquipmentACV(oldOpp, o);
}*/
            // Map to store delinquent and respective returning oppty IDS based on below criteria
            if(o.Type == 'Rebate' && o.Rebate_Type__c == 'Delinquent' && o.StageName != oldOpp.StageName && o.StageName == 'Refunded - Closed' && o.Returning_Opportunity__c != null){
                opportunityIds.put(o.Returning_Opportunity__c, o.id);
            }
            //GTMS-6450  //GTMS-17289
            /*if(o.Initial_Payment_Terms__c <> 'Due in advance' && o.Selected_Payment_Type__c == 'Upfront Payments'
&& o.Express_Agreement_Accepted_Date__c <> null && accountMapBookBiz.containsKey(o.AccountId)) //oldOppMap.get(o.Id).Account.Book_of_Business__c == null
{
o.Initial_Payment_Terms__c = 'Due in advance';
o.Payment_Terms__c = 'Due in advance';
}
else */
            /*
* If the opportunity is AE1, it’s not a Webstore Opp and Amount Received is greater than 0, then stamp the Payment_Terms__c to “Due in advance”.
*/
            if(((o.Configuration_Segment__c == 'Express' && o.Amount_Received__c > 0 && o.Express_Agreement_Accepted_Date__c <> null)
                || (o.Amount_Received__c > 0 && o.Configuration_Segment__c == 'Non Express'))
               && (o.Is_Webstore_Upsell_Opportunity__c == false && o.Small_Fleet_Opportunity__c == false) && o.Segment_Sales_Role__c == 'AE1'
               && accountMapBookBiz.containsKey(o.AccountId)) //oldOppMap.get(o.Id).Account.Book_of_Business__c == null
            {
                o.Payment_Terms__c = 'Due in advance';
            }
            if(o.StageName == 'Return Initiated' && o.Type == 'Remorse Refund' && o.of_HW_Products__c == 0
               && o.of_Accessories__c == 0 && o.of_LIC_Products__c < 0)
            {
                o.StageName = 'Finance Processing';
            }
            /* GTMS-8426 - Flavio - Wrong value fix for Ship from location in LIC only opportunities */
            if ((o.Ship_From_Location__c != oldOppMap.get(o.Id).Ship_From_Location__c
                 ||   o.of_LIC_Products__c != oldOppMap.get(o.Id).of_LIC_Products__c
                 ||   o.of_HW_Products__c != oldOppMap.get(o.Id).of_HW_Products__c)
                &&  o.Probability > 0 && o.Probability < 100
                &&  o.of_LIC_Products__c > 0 && o.of_HW_Products__c <= 0 && o.Total_Weight_oz__c <= 0){
                    // GTMS-28141 -- ABU --> 06262025 --> Start
                    if (HelperClass.shippingCountryDefaults == null || HelperClass.shippingCountryDefaults.isEmpty()){
                        HelperClass.queryShippingCountryDefaults();
                    }
                    // GTMS-28141 -- ABU --> 06262025 --> End
                    if (o.Type == 'Revenue Opportunity' || o.Type == 'Free Trial Opportunity' || o.Type == 'Promo Opportunity'){
                        //GTMS-28317 -- ABU -- 7142025 --Start
                        List<String> emeaShippingCountryList = System.Label.EMEA_Countries.split(',');
                        //GTMS-28317 -- ABU -- 7142025 --End
                        if (HelperClass.shippingCountryDefaults.containsKey(o.Shipping_Country__c) && o.Shipping_Country__c != 'Canada' && !emeaShippingCountryList.contains(o.Shipping_Country__c)) //GTMS-28141 -- ABU --> 06262025 
                        {
                            o.Ship_From_Location__c = HelperClass.shippingCountryDefaults.get(o.Shipping_Country__c).Ship_From_Location__c;
                            o.Shipping_Method__c = HelperClass.shippingCountryDefaults.get(o.Shipping_Country__c).Shipping_Method__c;
                            o.Shipping_Carrier__c = HelperClass.shippingCountryDefaults.get(o.Shipping_Country__c).Shipping_Carrier__c;
                        }
                    }else if ((o.Type == 'Exchange' || o.Type == 'Remorse Refund' || o.Type == 'Free Trial Return' || o.Type == 'Unplanned Return') && o.Shipping_Country__c != 'Canada') //GTMS-28141 -- ABU --> 06262025
                    {
                        
                        o.Ship_From_Location__c = Label.Ship_From_Location_for_Virtual_Returns;
                        //o.Shipping_Method__c = HelperClass.shippingCountryDefaults.get(o.Shipping_Country__c).Shipping_Method__c;
                        // o.Shipping_Carrier__c = HelperClass.shippingCountryDefaults.get(o.Shipping_Country__c).Shipping_Carrier__c;
                        
                    }
                }
            /* GTMS-10539 - Flavio - Rolling up product costs for Shipmate on Remorse Refunds */
            if (o.Type == 'Remorse Refund'
                && (o.Shipping_Country__c == 'Canada' || o.Shipping_Country__c == 'Mexico' || o.Shipping_Country__c == 'United Kingdom')){
                    o.Shipmate_Declared_Value__c = rollupOpportunityProductCosts(o);
                }
            //GTMS-25560 - Feb-10-2025 -- Start              
            if(o.Type == 'Remorse Refund' && o.Returning_Opportunity__c != NULL){
                List<String> prodCodeLst =  System.Label.MEM_PLTFMPRO.split(',');
                if(oppFields.containsKey(o.id) && oppFields.get(o.id).OpportunityLineItems.size()>0){
                    for(OpportunityLineItem oLI: oppFields.get(o.id).OpportunityLineItems){
                        if(prodCodeLst.contains(oLI.ProductCode)){                
                            if(naCurrencySet.contains(o.CurrencyISOCode) && String.isNotBlank(o.Owner_Role_Copy__c)){
                                if(oppFields.get(o.id).Account.Owner_Role__c.contains('AE1 ')|| oppFields.get(o.id).Account.Owner_Role__c.contains('AE2 ')){
                                    o.OwnerId = System.Label.MEM_AE1AE2;
                                }else If(oppFields.get(o.id).Account.Owner_Role__c.contains('AE3 ')|| oppFields.get(o.id).Account.Owner_Role__c.contains('ENT ')){
                                    o.OwnerId = System.Label.MEM_ENTAE3;
                                }
                            }else If(emeaCurrencySet.contains(o.CurrencyISOCode)){
                                o.OwnerId = System.Label.MEM_EMEA;
                            }
                            break;
                        } 
                    } 
                }            
            }
            //GTMS-25560 - Feb-10-2025 -- End
            //GTMS-20484
            if (o.StageName != oldOppMap.get(o.Id).StageName && o.StageName == 'Return Label Sent' && o.Type == 'Remorse Refund' && 
                o.Sub_Type__c  == 'Upgrade') {
                    o.StageName = 'Finance Processing';                
                }
            //GTMS-7220
            if(o.CurrencyIsoCode == 'USD' && o.Payment_Method__c == 'Credit Card' && o.Finance_Segment__c <> 'SMB' && !(oppAccounts.get(o.AccountId) != NULL && oppAccounts.get(o.AccountId).Book_of_Business__c != NULL && ((oppAccounts.get(o.AccountId).Book_of_Business__c).contains('ENT')) && !(oppAccounts.get(o.AccountId).IS_Named_Account__c)))
                o.Payment_Processing_Fee__c = true;
            this.addToClickpathOpportunityList(o);
            setOwnerSubRegion(o, oppAccounts.get(o.AccountId));
            setOwnerBusinessUnit(o, oppAccounts.get(o.AccountId));
            // GTMS-29094 Start: Compute rollups based on current line items
            if (oppFields != null && oppFields.containsKey(o.Id) && oppFields.get(o.Id).OpportunityLineItems != null) {
                List<OpportunityLineItem> oliList = oppFields.get(o.Id).OpportunityLineItems;
                Decimal sitesAcvSum = 0;
                Boolean hasAcvSitesLines = false;
                Set<String> distinctShipTo = new Set<String>();
                for (OpportunityLineItem oli : oliList) {
                    if (oli != null && oli.Product2 != null && sitesFamilies.contains(oli.Product2.Family)) {
                        hasAcvSitesLines = true;
                        if (oli.ACV_Total_Price_Bookings__c != null) sitesAcvSum += oli.ACV_Total_Price_Bookings__c;
                    }
                    String relatedShipName = oli.Related_Shipping_Address_Name__c;
                    if (!String.isBlank(relatedShipName)) distinctShipTo.add(relatedShipName.trim());
                }
                o.Sites_ACV_Bookings__c = hasAcvSitesLines ? sitesAcvSum : null;
                o.Unique_Shipping_Addresses__c = Decimal.valueOf(distinctShipTo.size()); // GTMS-29094 END
            }
        }
        if(!opportunityIds.isEmpty())
            updateRenewedLinesforRebate(opportunityIds);
        this.setClickpathAuditStatus(oldOppMap);
        this.validateClosedLostOpps(newOppList);
        this.setSyncInProgress(oldOppMap,newOppList);


        /*  This method is used to throw a validation error when the status of return opportunity 
            will be updated to Finance Processing/Return Label Sent and there are no Related 
            Opportunity recods with subtype as 'Upgrade Opportunity' - 
            GTMS-27442 - Hitesh Garg - 29th Aug, 2025
        */
        this.validateSwapOpportunity( newOppList, oldOppMap );
    }
    
    public void syncOpportunity(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldMap) {
        List<Opportunity> opptiesToUpdate = new List<Opportunity>();
        for (Opportunity oppty : newOpportunityList) {
            Opportunity oldOppty = oldMap.get(oppty.Id);
            if (((Boolean.valueOf(orderTransformationSetting.Value__c) == false && (oppty.Type == 'Revenue Opportunity' || oppty.Type == 'Promo Opportunity'))
                 || (Boolean.valueOf(orderTransformationSetting.Value__c) == true && oppty.Type == 'Promo Opportunity'))
                && oppty.StageName.equals('Ready to Ship')
                && ((oldOppty.StageName != oppty.StageName) || (oppty.Push_to_Mulesoft__c && (oldOppty.Push_to_Mulesoft__c != oppty.Push_to_Mulesoft__c)))
                && String.isBlank(oppty.Netsuite_Id__c)
                && oppty.Sync_in_Progress__c != true) {
                    oppty.Sync_in_Progress__c = true;
                    orderSyncEvents.add(new Order_Event__e(Id__c = oppty.Id, Type__c = oppty.Type));
                }
            // || oppty.Type == 'Free Trial Opportunity' remove for GTMS-13390
            if ((oppty.Type == 'Work Order' ) && oppty.StageName.equals('Ready to Ship') && ((oldOppty.StageName != oppty.StageName) || (oppty.Push_to_Mulesoft__c && (oldOppty.Push_to_Mulesoft__c != oppty.Push_to_Mulesoft__c)))
                && String.isBlank(oppty.Netsuite_Id__c) && oppty.Sync_in_Progress__c != true) {
                    oppty.Sync_in_Progress__c = true;
                    orderSyncEvents.add(new Order_Event__e(Id__c = oppty.Id, Type__c = oppty.Type));
                }
            //3/24/25 Vijaychandra AMARANENI  (GTMS-28240): Added or condition to handle the case where the oppty is closed won and the stage is moved to finance processing and the push to netsuite is true and the rebate type is partner referral
            // temp removed  oppty.StageName.equals('Finance Processing') && oppty.Returning_Opportunity_Closed_Won__c == true
            if (oppty.Type == 'Rebate' && (oppty.Rebate_Type__c == 'Buyout' || oppty.Rebate_Type__c == 'Partner Referral' || oppty.Rebate_Type__c == 'Subsidy')
                && oppty.Returning_Opportunity_Closed_Won__c == true && 
                ((oldOppty.Push_Return_to_Netsuite__c != true && oppty.Push_Return_to_Netsuite__c == true 
                  && oppty.StageName.equals('Finance Processing')) || (oppty.Push_Return_to_Netsuite__c == true 
                                                                       && oppty.StageName.equals('Finance Processing') && oldOppty.StageName != 'Finance Processing' && oppty.Rebate_Type__c == 'Partner Referral')))
            {
                oppty.Sync_in_Progress__c = true;
                rebateSyncEvents.add(new Rebate_Event__e(Id__c = oppty.Id, Type__c = oppty.Type, Sub_Type__c = oppty.Rebate_Type__c));
            }
        }
    }
    
    private Decimal rollupOpportunityProductCosts(Opportunity opp){
        Decimal cost = 0;
        if(oppFields!=null && oppFields.containsKey(opp.Id)) {
            if (oppFields.get(opp.Id).OpportunityLineItems.isEmpty()) return cost;
            for (OpportunityLineItem item : oppFields.get(opp.Id).OpportunityLineItems)
                cost += (item.Product_Cost__c != null ? item.Product_Cost__c : 0);
        }
        return cost;
    }
    
    private void addToClickpathOpportunityList(Opportunity opp){
        if (this.isClickpathOpp(opp) && this.isRenewal(opp)){
            if (this.clickPathOppList == null){
                this.clickPathOppList = new List<Opportunity>();
                this.primaryQuoteToOppIdMap = new Map<Id, Id>();
            }
            if (opp.SBQQ__PrimaryQuote__c != null){
                this.clickPathOppList.add(opp);
                this.primaryQuoteToOppIdMap.put(opp.SBQQ__PrimaryQuote__c, opp.Id);
            }
        }
    }
    
    public static void setOwnerSubRegion(Opportunity opp, Account acc){
        // +'' to avoid null pointers
        String ownRole = (opp != null && opp.Owner_Role_Copy__c != null ? opp.Owner_Role_Copy__c : '');
        String accRole = (acc != null && acc.Owner_Role__c != null ? acc.Owner_Role__c : '');
        String subRegion;
        if      (ownRole.contains(' US ')   || ownRole.endsWithIgnoreCase(' US')  ) subRegion = 'US';
        else if (ownRole.contains(' CA ')   || ownRole.endsWithIgnoreCase(' CA')  ) subRegion = 'CA';
        else if (ownRole.contains(' MX ')   || ownRole.endsWithIgnoreCase(' MX')  ) subRegion = 'MX';
        else if (ownRole.contains(' UK ')   || ownRole.endsWithIgnoreCase(' UK')  ) subRegion = 'UK';
        else if (ownRole.contains(' FR ')   || ownRole.endsWithIgnoreCase(' FR')  ) subRegion = 'FR';
        else if (ownRole.contains(' DE ')   || ownRole.endsWithIgnoreCase(' DE')  ) subRegion = 'DE';
        else if (ownRole.contains(' NL ')   || ownRole.endsWithIgnoreCase(' NL')  ) subRegion = 'NL';
        else if (ownRole.contains(' EMEA ') || ownRole.endsWithIgnoreCase(' EMEA')) subRegion = 'EMEA';
        else if (ownRole.contains(' NA ')   || ownRole.endsWithIgnoreCase(' NA')  ) subRegion = 'NA';
        else if (accRole.contains(' US ')   || accRole.endsWithIgnoreCase(' US')  ) subRegion = 'US';
        else if (accRole.contains(' CA ')   || accRole.endsWithIgnoreCase(' CA')  ) subRegion = 'CA';
        else if (accRole.contains(' MX ')   || accRole.endsWithIgnoreCase(' MX')  ) subRegion = 'MX';
        else if (accRole.contains(' UK ')   || accRole.endsWithIgnoreCase(' UK')  ) subRegion = 'UK';
        else if (accRole.contains(' FR ')   || accRole.endsWithIgnoreCase(' FR')  ) subRegion = 'FR';
        else if (accRole.contains(' DE ')   || accRole.endsWithIgnoreCase(' DE')  ) subRegion = 'DE';
        else if (accRole.contains(' NL ')   || accRole.endsWithIgnoreCase(' NL')  ) subRegion = 'NL';
        else if (accRole.contains(' EMEA ') || accRole.endsWithIgnoreCase(' EMEA')) subRegion = 'EMEA';
        else if (accRole.contains(' NA ')   || accRole.endsWithIgnoreCase(' NA')  ) subRegion = 'NA';
        else subRegion = 'US';
        opp.Owner_Sub_Region__c = subRegion;
    }
    
    public static void setOwnerBusinessUnit(Opportunity opp, Account acc){
        // +'' to avoid null pointers
        String ownerRole = (opp != null && opp.Owner_Role_Copy__c != null ? opp.Owner_Role_Copy__c : '');
        String businessUnit;
        if (ownerRole.contains(' SLED ') || ownerRole.endsWithIgnoreCase(' SLED')) businessUnit = 'Public Sector';
        else businessUnit = 'Private Sector';
        opp.Owner_Business_Unit__c = businessUnit;
    }
    
    private void setClickpathAuditStatus(Map<Id, Opportunity> oldOppMap){
        if (this.clickPathOppList == null || this.clickPathOppList.isEmpty()) return;
        List<SBQQ__QuoteLine__c> quoteLineList = [
            SELECT Name, SBQQ__Quote__c, Gainsight_Audit_Status__c,SBQQ__Quote__r.Process_Eligibility__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :primaryQuoteToOppIdMap.keySet()
            AND Gainsight_Audit_Status__c != :GAINSIGHT_IGNORE_STATUS
        ];
        Map<Id, String> opportunityIdToStatus = new Map<Id, String>();
        Map<Id, String> primaryQuoteEligibilityMap = new Map<Id, String>();
        // Join quote lines by Opportunity/Quote
        for (SBQQ__QuoteLine__c ql : quoteLineList){
            Id opportunityId = primaryQuoteToOppIdMap.get(ql.SBQQ__Quote__c);
            String oppStatus = opportunityIdToStatus.get(opportunityId);
            if (String.isBlank(oppStatus)) oppStatus = '';
            else oppStatus += '\n';
            oppStatus += String.format(Label.Clickpath_QuoteLine_has_the_following_issues, new List<String>{ql.Name})+' '+(String.isBlank(ql.Gainsight_Audit_Status__c) ? Label.Clickpath_Pending_Update : ql.Gainsight_Audit_Status__c);
            opportunityIdToStatus.put(opportunityId, oppStatus);
            if (!primaryQuoteEligibilityMap.containsKey(ql.SBQQ__Quote__c)) {
                primaryQuoteEligibilityMap.put(ql.SBQQ__Quote__c, ql.SBQQ__Quote__r.Process_Eligibility__c);
            }
        }
        String customerPrice = Label.Clickpath_Customer_price_does_not_match;
        String missingSubs = Label.Clickpath_Missing_renewed_subscription;
        String pendingUpdate = Label.Clickpath_Pending_Update;
        String quantityMismatch = Label.Clickpath_Quantity_does_not_match;
        Set<Id> contractIdSet = new Set<Id>();
        for (Opportunity opp : this.clickPathOppList){
            String processEligibility = primaryQuoteEligibilityMap.get(opp.SBQQ__PrimaryQuote__c);
            String status;
            // Assigning status and testing it
            if (String.isNotBlank(status = opportunityIdToStatus.get(opp.Id))){
                opp.Gainsight_Audit_Status__c = (status.length() > 254 ? status.left(255) : status);
                if(String.isNotBlank(opp.Gainsight_Audit_Status__c) && opp.Gainsight_Audit_Status__c.contains(customerPrice) && !opp.Gainsight_Audit_Status__c.contains(missingSubs) 
                   && !opp.Gainsight_Audit_Status__c.contains(pendingUpdate) && !opp.Gainsight_Audit_Status__c.contains(quantityMismatch) 
                   && processEligibility == 'Digital Renewals'){
                       opp.Gainsight_Audit_Status__c =  Label.Success;
                   }
            }else{
                opp.Gainsight_Audit_Status__c =  Label.Success;
            }
            if (opp.SBQQ__RenewedContract__c != null) contractIdSet.add(opp.SBQQ__RenewedContract__c);
        }
        if (contractIdSet.size() > 0 && (contractsMap == null || contractsMap.size() <= 0)){
            loadContracts(contractIdSet);
        }
        for (Opportunity opp : this.clickPathOppList){
            if(contractsMap.get(opp.SBQQ__RenewedContract__c) != null){
                this.processFutureDatedAutoRenewal(opp, (oldOppMap != null ? oldOppMap.get(opp.Id) : null), contractsMap.get(opp.SBQQ__RenewedContract__c));
                //GTMS-23000
                updateOpptyFromContractUsingWASD(opp,contractsMap);
            }
        }
    }
    
    public void validateClosedLostOpps(List<Opportunity> oppList){
        Boolean isAEProfile = Label.Samsara_AEs_Profiles_List.contains(String.valueOf(UserInfo.getProfileId()));
        if (closedLostOppIdSet != null && !closedLostOppIdSet.isEmpty() && (isAEProfile || Test.isRunningTest())){
            Set<Id> oppsWithInsight = new Set<Id>();
            for (Closed_Deal_Insights__c insight : [
                SELECT Opportunity__c
                FROM Closed_Deal_Insights__c
                WHERE Opportunity__c IN :closedLostOppIdSet
            ]){
                oppsWithInsight.add(insight.Opportunity__c);
            }
            for (Opportunity opp : oppList){
                if (opp.Type != 'Free Trial Opportunity' && closedLostOppIdSet.contains(opp.Id) && !oppsWithInsight.contains(opp.Id) && !Test.isRunningTest()){
                    opp.addError(Label.Closed_Lost_Flow_Validation_Error_Message);
                }
            }
        }
    }
    
    private void setSyncInProgress(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){
        if(oldOppMap.isEmpty() || newOppList.isEmpty()){
            return;
        }
        for(Opportunity newOpportunityData: newOppList){
            Opportunity oldOpportunityData = oldOppMap.get(newOpportunityData.Id);
            if(oldOpportunityData==null){
                continue;
            }
            if ( newOpportunityData.SBQQ__PrimaryQuote__c!=null && ((newOpportunityData.StageName == 'Ready To Ship' && oldOpportunityData.StageName != newOpportunityData.StageName && newOpportunityData.Type == 'Free Trial Opportunity') ||
                                                                    (newOpportunityData.StageName == 'Return Initiated' && oldOpportunityData.StageName != newOpportunityData.StageName && newOpportunityData.Type == 'Free Trial Return')) )
            {
                newOpportunityData.Sync_in_Progress__c  = true;
            }
        }
    }
    
    private Boolean isClickpathOpp(Opportunity opp){
        return (opp.Sub_type__c == 'Clickpath' || opp.Sub_Type__c == 'Auto-Renewal');
    }
    
    private Boolean isRenewal(Opportunity opp){
        return opp.Renewal__c;
    }
    
    // GTMS-6099 process future-dated auto-renewals
    @TestVisible
    private void processFutureDatedAutoRenewal(Opportunity opp, Opportunity oldOpp, Contract ctt){
        Integer daysUntilClosing = (System.today().daysBetween(ctt.EndDate));
        Boolean isAutoRenewal = (opp.Sub_Type__c == 'Auto-Renewal');
        Boolean isWithinTimeframe = (daysUntilClosing >= 0 && daysUntilClosing <= 30);
        // Changed from something else to success or override has been checked.
        Boolean gainsightChangedToSuccess = (
            (
                (oldOpp == null || oldOpp.Gainsight_Audit_Status__c != opp.Gainsight_Audit_Status__c)
                &&   opp.Gainsight_Audit_Status__c == Label.Success
            )
            ||
            (
                (oldOpp == null || oldOpp.Gainsight_Audit_Override__c != opp.Gainsight_Audit_Override__c)
                &&   opp.Gainsight_Audit_Override__c
            )
        );
        if (isAutoRenewal && gainsightChangedToSuccess && isWithinTimeframe){
            opp.StageName = 'Purchase';
            // If closeDate != today
            if (daysUntilClosing > 0){
                opp.Adjust_License_Start_Date__c = true;
                opp.License_Start_Date__c = opp.CloseDate;
                if (opp.OwnerId == Id.valueOf(Label.Renewal_Pool_User)
                    && mapUsers.containsKey(Label.Clickpath_Opportunity_Won_User_Id)
                    && mapUsers.get(Label.Clickpath_Opportunity_Won_User_Id).IsActive){
                        opp.OwnerId = Id.valueOf(Label.Clickpath_Opportunity_Won_User_Id);
                    }
            }
        }
    }
    
    /** GTMS-15659 starts here **/
    public void checkForChangeInSmartApprovalFields(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList) {
        for (Opportunity o : newOppList) {
            Opportunity oldOpty = oldOppMap.get(o.Id);
            if (o.SLA_Termination_right__c != oldOpty.SLA_Termination_right__c ||
                o.Samsara_insolvency__c != oldOpty.Samsara_insolvency__c  ||
                o.Permanent_Downsize__c  != oldOpty.Permanent_Downsize__c  ||
                o.Partial_use_seasonal__c  != oldOpty.Partial_use_seasonal__c  ||
                o.MSA_negotiated_under_good_faith_after_or__c  != oldOpty.MSA_negotiated_under_good_faith_after_or__c  ||
                o.Price_stability_for_renewal__c  != oldOpty.Price_stability_for_renewal__c  ||
                o.Termination_for_convenience__c  != oldOpty.Termination_for_convenience__c  ||
                o.Termination_for_lack_of_appropriation_of__c  != oldOpty.Termination_for_lack_of_appropriation_of__c  ||
                o.Temporary_Suspension__c  != oldOpty.Temporary_Suspension__c  ||
                o.Extended_returns_beyond_30_days__c  != oldOpty.Extended_returns_beyond_30_days__c  ||
                o.Price_lock_language_for_add_on_orders__c  != oldOpty.Price_lock_language_for_add_on_orders__c  ||
                o.Non_Standard_terms_description__c  != oldOpty.Non_Standard_terms_description__c
               ) {
                   DateTime myDateTime = DateTime.now();
                   o.Smart_Approve_Standard_Term_Indicator__c = (o.Smart_Approve_Standard_Term_Indicator__c!=null)?o.Smart_Approve_Standard_Term_Indicator__c+5:myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + + myDateTime.year();
               }
        }
    }
    /** GTMS-15659 ends here **/
    
    //GTMS-23446 Start
    public void masterSheetReqBefore(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        Map<String, FieldNamesByApiNamesSetting__mdt> fieldSettings = FieldNamesByApiNamesSetting__mdt.getAll();
        Map<String, String> fieldApiNames = new Map<String, String>();
        Map<String, FieldNamesByApiNamesSetting__mdt> fieldApiNamesByMeta = new Map<String, FieldNamesByApiNamesSetting__mdt>();
        List<String> emeaShippingCountryList = System.Label.EMEA_SHIPPING_COUNTRIES.split(','); // EMEA automation notes logic
        
        List<String> listOfValues = new List<String>();
        for (String key : fieldSettings.keySet()) {
            FieldNamesByApiNamesSetting__mdt setting = fieldSettings.get(key);
            fieldApiNames.put(setting.Field_API_Name__c, setting.Field_Label__c);
            fieldApiNamesByMeta.put(setting.Field_API_Name__c + '-' + setting.Opportunity_type__c, setting);
            if (setting.Values__c != null) {
                listOfValues.addAll(setting.Values__c.split(','));
            }
        }
        for (Opportunity opp : newOppList) {
            List<String> notNullFieldsForPromo = new List<String>();
            List<String> notNullFieldsForRevenue = new List<String>();
            Opportunity oldOpp = oldOppMap.get(opp.Id);
            for (String fP : fieldApiNames.keySet()) {
                if ((opp.Shipping_Country__c == 'United States' || opp.Shipping_Country__c == 'Canada' || emeaShippingCountryList.contains(opp.Shipping_Country__c)) && (opp.of_LIC_Products__c == 0 || (opp.of_LIC_Products__c != 0 && (opp.of_HW_Products__c != 0 || opp.of_Accessories__c != 0))) && // EMEA automation notes logic
                    ((oldOpp.StageName != 'Orders Processing' && opp.StageName == 'Orders Processing') ||
                     (opp.StageName == 'Closing' && String.isBlank(opp.Finance_Kickback_Reason__c) && oldOpp.StageName != 'Closing' && opp.Bypass_Validation_rule__c))) {
                         //opp.Automation_Notes__c = '';
                         Boolean isPromoOpportunity = opp.Type == 'Promo Opportunity';
                         Boolean isRevenueOpportunity = opp.Type == 'Revenue Opportunity';
                         if (opp.get(fP) != null && fieldApiNamesByMeta.containsKey(fP + '-' + opp.Type)) {
                             if (isPromoOpportunity) {
                                 if ((fP == 'Free_Trial_Purchase__c' && opp.Free_Trial_Purchase__c != null) ||
                                     (fP == 'Shipping_Country__c' && !listOfValues.contains(opp.Shipping_Country__c)) ||
                                     (fP != 'Free_Trial_Purchase__c' && fP != 'Shipping_Country__c' && fP != 'Shipping_Method__c' && fP != 'Shipping_Carrier__c' && fP != 'Total_Weight_oz__c')) {
                                         notNullFieldsForPromo.add(fieldApiNames.get(fP));
                                     }
                             } else if (isRevenueOpportunity) {
                                 if ((fP == 'Free_Trial_Purchase__c' && opp.Free_Trial_Purchase__c != null && opp.Free_Trial_Purchase__c != 'No Purchase') ||
                                     (fP == 'Shipping_Country__c' && !listOfValues.contains(opp.Shipping_Country__c)) ||
                                     (fP == 'Amount' && opp.Amount > 500000) ||
                                     (fP != 'Segment_Sales_Role__c' && fP != 'Free_Trial_Purchase__c' && fP != 'Shipping_Country__c' && fP != 'Shipping_Method__c' && fP != 'Shipping_Carrier__c' && fP != 'Total_Weight_oz__c' && fP != 'Amount')) {
                                         notNullFieldsForRevenue.add(fieldApiNames.get(fP));
                                     }
                             }
                         }
                     }
            }
            
            if (!notNullFieldsForPromo.isEmpty()) {
                String fieldNames = String.join(notNullFieldsForPromo, ', ');
                String automationNotes = 'Not meeting the criteria: field names: ' + fieldNames;
                
                String automationNotesValue = String.isNotBlank(opp.Automation_Notes__c) ? (opp.Automation_Notes__c + '; ' + automationNotes) : automationNotes;
                if (automationNotesValue.length() > 255) {
                    automationNotesValue = automationNotesValue.substring(0, 255);
                }
                opp.Automation_Notes__c = automationNotesValue;

            }
            if (!notNullFieldsForRevenue.isEmpty()) {
                String fieldNames = String.join(notNullFieldsForRevenue, ', ');
                String automationNotes = 'Not meeting the criteria: field names: ' + fieldNames;
                
                String automationNotesValue = String.isNotBlank(opp.Automation_Notes__c) ? (opp.Automation_Notes__c + '; ' + automationNotes) : automationNotes;
                if (automationNotesValue.length() > 255) {
                    automationNotesValue = automationNotesValue.substring(0, 255);
                }
                opp.Automation_Notes__c = automationNotesValue;
            }
        }
    }
    
    // Method to handle logic for setting the annual discount line item before updates
    public void expressSetAnnualDiscountLineItemOnbefore(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        if (OpportunityHelperContext.expressSetDiscountRun) {
            return;
        }
        // EMEA automation notes logic
        List<Opportunity> updateOpty = new List<Opportunity>();
        loadOppFields(newOppMap);
        List<String> lstDCLProdCodes = new List<String>();
        
        Map<String, String> prodCodesToDispatchMap = new Map<String, String>();
        List<String> emeaShippingCountryList = System.Label.EMEA_SHIPPING_COUNTRIES.split(',');
        
        // EMEA automation notes logic
        List<OpportunityLineItem> opptyLToUpdate = new List<OpportunityLineItem>();
        List<String> byPassShipFromLocation = System.Label.GTMS_ShipFromLocationProducts.split(',');
        for (Opportunity newOpp : newOppMap.values()) {
            String labelError = '';
            Opportunity oldOpp = oldOppMap.get(newOpp.Id);
            String prodCodesToDispatch = '';
            Decimal productCount = newOpp.of_HW_Products__c + newOpp.of_Accessories__c;
            Decimal expressSelectedDiscount = newOpp.Express_Selected_Discount__c != null ? newOpp.Express_Selected_Discount__c : 0;
            Integer QtyLimitPerProduct = getQtyLimitPerProduct(newOpp.Type);
            // EMEA automation notes logic
            if ((newOpp.Shipping_Country__c == 'Mexico' || newOpp.Shipping_Country__c == 'United States' || newOpp.Shipping_Country__c == 'Canada' 
                 || emeaShippingCountryList.contains(newOpp.Shipping_Country__c)) 
                && newOpp.type != 'Free Trial Opportunity'
                && (newOpp.of_LIC_Products__c == 0 || (newOpp.of_LIC_Products__c != 0 
                                                       && (newOpp.of_HW_Products__c != 0 || newOpp.of_Accessories__c != 0))) 
                && oldOpp.StageName != 'Orders Processing' && newOpp.StageName == 'Orders Processing') {
                lstDCLProdCodes = OrderAutomationService.getProductCodesByCountryAndType(newOpp.Shipping_Country__c, newOpp.type);
            
                Boolean productFlag = true;
                for (OpportunityLineItem oli : oppFields.get(newOpp.Id).OpportunityLineItems) {
                    if (lstDCLProdCodes.contains(oli.ProductCode) && oli.Quantity >= 1) {
                        prodCodesToDispatch = prodCodesToDispatch + ',' + oli.ProductCode;
                    } else {
                        labelError = System.Label.Invalid_Product_SKU_Note;
                    }
                }
                String automationNotes = String.isNotBlank(newOpp.Automation_Notes__c) ? (newOpp.Automation_Notes__c + ' ' + labelError) : labelError;
                if (automationNotes.length() > 255) {
                    automationNotes = automationNotes.substring(0, 255);
                }
                newOpp.Automation_Notes__c = automationNotes;
            }
        }
    }
    
    // * 8/20/20 Tommy - (GTMS-1362) orderAdminRoundRobin (changed criteria for UK Users so that all EMEA orders are assigned to Nora Csillag)
    public void orderAdminRoundRobin(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        Map<Id, Opportunity> roundRobinThese = new Map<Id, Opportunity>();
        Map<Id, User> updateUsers = new Map<Id, User>();
        List<User> usersUK = new List<User>();
        List<User> usersUS = new List<User>();
        List<Shipping_Countries__mdt> lstShipCtry = Shipping_Countries__mdt.getAll()?.values();
        List<String> lstShipCountries = new List<String>();
        Map<String, Shipping_Countries__mdt> shipFromMap = new Map<String, Shipping_Countries__mdt>();
        String userNamesString = System.Label.Order_Admin_Removal_Users;
        List<String> adminUsersRemovalList = userNamesString.split(',');
        if(lstShipCtry != null && lstShipCtry.Size() > 0 ){
            for (Shipping_Countries__mdt country : lstShipCtry) {
                lstShipCountries.add(country.Country__c);
                shipFromMap.put(country.Country__c, country);
            }
        }
        // Query round robin-able users, if necessary
        for (Opportunity o : newOppMap.values()) {
            if (o.Type == 'Revenue Opportunity' || o.Type == 'Promo Opportunity' || o.Type == 'Free Trial Opportunity') {
                if (o.Order_Admin__c == NULL && (o.StageName == System.Label.Orders_Processing || o.Probability == 98) && (((oldOppMap.get(o.Id).StageName != newOppMap.get(o.Id).StageName)) || ((oldOppMap.get(o.Id).Probability != newOppMap.get(o.Id).Probability)))) {
                    roundRobinThese.put(o.Id, o);
                }
            }
        }
        // If we don't need to assign any users, don't do anything else.
        if (roundRobinThese.size() > 0) {
            // Query eligible users (up to the number that we need)
            List<User> eligibleUsers = [SELECT Id, Order_Admin_Oppty_Date__c, Entity__c FROM User WHERE Order_Admin_Available__c = TRUE AND isActive = TRUE AND Name NOT IN :adminUsersRemovalList ORDER BY Order_Admin_Oppty_Date__c ASC];
            if (eligibleUsers.size() == 0) {
                eligibleUsers = [SELECT Id, Entity__c, Order_Admin_Oppty_Date__c FROM User WHERE Order_Admin_Fallback_User__c = TRUE AND isActive = TRUE AND Name NOT IN :adminUsersRemovalList ORDER BY Order_Admin_Oppty_Date__c ASC];
            }
            for (User user : eligibleUsers) {
                if (user.Entity__c == 'Samsara UK') {
                    usersUK.add(user);
                } else {
                    usersUS.add(user);
                }
            }
            //Two variables to track the total number of users in each region
            Integer countUS = 0;
            Integer countUK = 0;
            for (Opportunity opp : roundRobinThese.values()) {
                //assigning users based on Shipping Country
                string shipFromLocation = shipFromMap.get(opp.Shipping_Country__c).Ship_From_Location__c;
                //GTMS-28317 -- ABU -- 7142025 -- Replaced VCK with DHL
                if (opp.Shipping_Country__c != null && (shipFromLocation == 'DHL' || shipFromLocation == 'Samsara UK') && !usersUK.isEmpty()) {
                    opp.Order_Admin__c = usersUK[countUK].Id;
                    updateUsers.put(usersUK[countUK].Id, new User(Id = usersUK[countUK].Id, Order_Admin_Oppty_Date__c = System.now()));
                    countUK++;
                    countUK = (countUK >= usersUK.size()) ? 0 : countUK;
                } else if (!usersUS.isEmpty()) {
                    opp.Order_Admin__c = usersUS[countUS].Id;
                    updateUsers.put(usersUS[countUS].Id, new User(Id = usersUS[countUS].Id, Order_Admin_Oppty_Date__c = System.now()));
                    countUS++;
                    countUS = (countUS >= usersUS.size()) ? 0 : countUS;
                }
            }
            if (updateUsers.size() > 0) {
                try {
                    //update updateUsers.values();
                    DMLWrapper.doUpdate(updateUsers.values());
                } catch (Exception e) {
                    System.debug('There was an error: ' + e);
                }
            }
        }
    }
    
    public void populateOptyTrackerField(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap){
        for(Opportunity opp :newOppMap.values()){
            //When Express Agreement Accepted Date is nullified in the current transaction, remove the warnings
            if(opp.Express_Agreement_Accepted_Date__c == null && oldOppMap.get(opp.Id).Express_Agreement_Accepted_Date__c != opp.Express_Agreement_Accepted_Date__c) removeWarningFromOptyTrackerField(opp);
            //If empty or changed in this transaction, skip
            if(opp.Express_Agreement_Accepted_Date__c == null || oldOppMap.get(opp.Id).Express_Agreement_Accepted_Date__c != opp.Express_Agreement_Accepted_Date__c) continue;
            for(Schema.FieldSetMember fm : Schema.SObjectType.Opportunity.fieldSets.getMap().get('Opportunity_Field_Track').getFields()){
                if(oldOppMap.get(opp.Id).get(fm.getFieldPath()) == opp.get(fm.getFieldPath())) continue;
                if(opp.get(fm.getFieldPath()) != 'Closed Lost' && fm.getFieldPath() == 'StageName') continue;
                if(String.isNotBlank(opp.Opportunity_Tracking__c)){
                    if(opp.Opportunity_Tracking__c.split(';').contains('Warning: '+fm.getlabel())) continue;
                }
                opp.Opportunity_Tracking__c = String.isBlank(opp.Opportunity_Tracking__c)?'Warning: '+fm.getlabel():opp.Opportunity_Tracking__c+(';Warning: '+fm.getlabel());
            }
        }
    }
    //28317 -- Start
    public static List<Opportunity> readytoShipOppoList = new List<Opportunity>();
    public static void updateStageReadyToShip(Opportunity o){
        o.StageName = 'Ready to Ship';
        o.Probability = 99;
        o.Went_To_Ready_To_Ship_Date__c = Datetime.Now();
        o.Went_To_Ready_To_Ship__c = true;
        o.Automation_Notes__c = System.Label.EMEA_Automation_Notes;
        if(!readytoShipOppoList.contains(o) && o.type == 'Promo Opportunity'){
            syncOppoPromoFlag = true;
            readytoShipOppoList.add(o);
        }       
    }
    //28317 -- End
    /** GTMS-15414- START **/
    public void emeaOpsAutomationPromoOppty(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        loadOppAccounts(newOppList);
        loadOppFields(newOppList);
        Map<String, String> prodCodesToDispatchMap = new Map<String, String>();
        List<String> lstDCLProdCodes = new List<String>();
        Set<String> noProdCodes = new Set<String>();
        //lstDCLProdCodes = System.Label.DCL_Product_SKU_List.split(',');
        // DCL_Product_SKU_List Custom Label Changed to VCK_EMEA_Promo_SKU as rqusted GTMS-21311 ticket
        //-- Add condition for GTMS-15414 - START
        List<String> emeaShippingCountryList = System.Label.EMEA_SHIPPING_COUNTRIES.split(',');
        List<String> oderOpsAdminProfiles = System.Label.Order_Automation_Profile_Promo_Oppty.split(',');
        for (Opportunity o : newOppList) {
            
            String prodCodesToDispatch = '';
            if (o.StageName == 'Orders Processing' && emeaShippingCountryList.contains(o.Shipping_Country__c) && o.Type == 'Promo Opportunity') {
                Boolean validatedShipFromLoc = OrderAutomationService.satisfyShipFromLocation(o);
                if(oderOpsAdminProfiles.contains(UserInfo.getProfileId()) 
                   && validatedShipFromLoc
                   && (o.CurrencyIsoCode == 'GBP' || o.CurrencyIsoCode == 'EUR' || o.CurrencyIsoCode == 'CHF') 
                   && String.isBlank(o.Shipping_Instructions__c) 
                   && String.isBlank(o.Internal_RFO_Notes__c) 
                   && String.isBlank(o.Hold_Reason__c)
                   && o.Sales_Tax__c == 0 
                   && o.Balance_Due__c == 0 
                   && (o.Shipping_and_Handling__c == 0 || o.Shipping_and_Handling__c == null)
                   && o.Price_Book_Name__c == 'Samsara FY22'
                   && !o.Multi_Line_Shipping__c )
            {
                lstDCLProdCodes = OrderAutomationService.getProductCodesByCountryAndType(o.Shipping_Country__c, o.type);
                if (oppFields.containsKey(o.Id) && oppFields.get(o.Id).OpportunityLineItems != null) {
                    for (OpportunityLineItem oli : oppFields.get(o.Id).OpportunityLineItems) {
                        system.debug('****'+oli.ProductCode);
                        system.debug('****'+oli.Product2Id);
                        if (lstDCLProdCodes.contains(oli.ProductCode)) {
                            if(prodCodesToDispatch != ''){
                                prodCodesToDispatch = prodCodesToDispatch + ',' + oli.ProductCode;
                            }
                            else{
                                prodCodesToDispatch = oli.ProductCode;
                            }
                        }else{
                            noProdCodes.add(oli.ProductCode);
                        }
                    }
                }
                }
                
            }
            /**GTMS-13565 - START - Checking License Type Products**/
            if(o.StageName == 'Orders Processing' && oldOppMap != null && oldOppMap.get(o.Id) != null && o.StageName != oldOppMap.get(o.Id).StageName
               && oppFields != NULL && oppFields.get(o.Id) != NULL && !oppFields.get(o.Id).OpportunityLineItems.isEmpty() /*&& oppFields.get(o.Id).OpportunityLineItems != NULL*/)
            {
                string returnDecision = checkLicenceProducts(oppFields.get(o.Id).OpportunityLineItems);
                if(returnDecision == 'Ready to Ship'){
                    //o = updateStageReadyToShip(o);
                    Set<Id> setId = new Set<id>();
                    Map<String,Set<Id>> paramMap = New Map<String,Set<Id>>();
                    setId.add(o.Id);
                    if(setId.size() >0 && !Test.isRunningTest()){
                        paramMap.put('RecordCole',setId);
                        Flow.Interview.Opportunity_Stage_Update_to_Ready_to_Ship flow1 = new Flow.Interview.Opportunity_Stage_Update_to_Ready_to_Ship(paramMap);
                        flow1.start();
                    }
                } else {
                    o.StageName = returnDecision;
                }
                if (prodCodesToDispatch != '' && noProdCodes.isEmpty()) {
                    updateStageReadyToShip(o); // GTMS-28317
                }   	    
            }
            /**GTMS-13565 - END - Checking License Type Products**/
        }
        //GTMS-28317 -- 8/6/25 -- Mayank Gupta -- Start
        if(syncOppoPromoFlag && readytoShipOppoList.size()>0){
            syncOpportunity(readytoShipOppoList,oldOppMap);
            syncOppoPromoFlag = false;
            readytoShipOppoList.clear();
        }
        
    }
    /** GTMS-15414- END **/
    
    /** GTMS-18015 Started **/
    public void emeaOpsAutomationRevnueOppty(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        loadOppAccounts(newOppList);
        loadOppFields(newOppList);
        Map<String, String> prodCodesToDispatchMap = new Map<String, String>();
        Set<String> lstDCLProdCodes = new Set<String>();
        
        Set<String> emeaShippingCountryList = new Set<String>(System.Label.EMEA_SHIPPING_COUNTRIES.split(','));
        for (Opportunity opp : newOppList) {
            String VRAutomationNotes = '';
            String prodCodesToDispatch = '';
            lstDCLProdCodes.addAll(OrderAutomationService.getProductCodesByCountryAndType(opp.Shipping_Country__c, opp.type));
            //GTMS-28317 -- ABU -- 7142025 -- Replaced VCK with DHL in Ship_From_Location__c field
            if (opp.Shipping_Country__c != null 
                && emeaShippingCountryList.contains(opp.Shipping_Country__c) 
                && opp.Type == 'Revenue Opportunity' 
                && opp.StageName == 'Orders Processing' 
                && oldOppMap.get(opp.Id).StageName != opp.StageName ) {
                    
                    Boolean validatedShipFromLoc = OrderAutomationService.satisfyShipFromLocation(opp);
                    
                    if(validatedShipFromLoc
                        && ((opp.CurrencyIsoCode == 'GBP' || opp.CurrencyIsoCode == 'EUR' || opp.CurrencyIsoCode == 'CHF') 
                            && opp.Amount < Decimal.valueOf(System.Label.US_Canada_EMEA_Amount_Threshold))
                        && ((opp.Segment_Sales_Role__c == 'AE2' || opp.Segment_Sales_Role__c == 'AE3' || opp.Segment_Sales_Role__c == 'Enterprise' || Test.isRunningTest())
                            && (opp.name.contains('Webstore') ? (opp.Free_Trial_Purchase__c == NULL) : (opp.Free_Trial_Purchase__c == 'No Purchase'))) 
                        && String.isBlank(opp.Shipping_Instructions__c) 
                        && String.isBlank(opp.Order_Ops_Notes__c) 
                        && String.isBlank(opp.Internal_RFO_Notes__c) 
                        && String.isBlank(opp.Hold_Reason__c) 
                        && opp.Shipping_and_Handling__c < 99999 
                        && opp.Price_Book_Name__c == 'Samsara FY22'
                        && opp.Sub_Type__c != 'Virtual Return')
                {
                Boolean productFlag = true;
                if (oppFields.containsKey(opp.Id) && oppFields.get(opp.Id).OpportunityLineItems != null) {
                    for ( OpportunityLineItem oli : oppFields.get(opp.Id).OpportunityLineItems) {
                        if (lstDCLProdCodes.contains(oli.ProductCode)) {
                            prodCodesToDispatch = prodCodesToDispatch + ',' + oli.ProductCode;
                        }
                        else{
                            productFlag = false;
                        }
                    }
                    if (prodCodesToDispatch != '' && productFlag == true  ) {
                        updateStageReadyToShip(opp); //GTMS-28317
                        } 
                    }
                } 
                }
            
            
            if(oldOppMap.get(opp.Id).StageName != opp.StageName && opp.StageName == 'Orders Processing' 
               && opp.Type == 'Revenue Opportunity' && opp.sub_Type__c == 'Virtual Return') 
            {
                VRAutomationNotes = 'Failed due to VR';
            }
            
            if (!String.isEmpty(VRAutomationNotes)) {
                String automationNotesValue = String.isNotBlank(opp.Automation_Notes__c) ? (opp.Automation_Notes__c + '; ' + VRAutomationNotes) : VRAutomationNotes;
                if (automationNotesValue.length() > 255) {
                    automationNotesValue = automationNotesValue.substring(0, 255);
                }
                opp.Automation_Notes__c = automationNotesValue;
            }
        }
        
    }
    /** GTMS-18015 Ended **/
    
    //GTMS-16459 -- Added validation to check if License Term of Quote and Orderform are not matching,
    // and stage is moved to 98% by AE profiles on FinancePartner Opportunities, display an error message and block the update
    public void validateLicenseTermOnOfandCPQ(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        Set<Id> oppIDs = new Set<Id>();
        List<dsfs__DocuSign_Status__c> listOFCPtoValidate = new List<dsfs__DocuSign_Status__c>();
        Map<Id,dsfs__DocuSign_Status__c > mapOFQuoteLicenseTerms = new Map<Id,dsfs__DocuSign_Status__c >();
        for(Opportunity opp:newOppList){
            if(opp.Finance_Partner__c != null && Label.Samsara_AEs_Profiles_List.contains(String.valueOf(UserInfo.getProfileId())) && opp.StageName == 'Orders Processing' && opp.SBQQ__PrimaryQuote__c != null){
                oppIDs.add(opp.Id);
            }
        }
        if(oppIDs.size() > 0){
            listOFCPtoValidate = [Select Id,License_Term__c ,dsfs__Opportunity__c ,
                                  dsfs__Opportunity__r.SBQQ__PrimaryQuote__c,dsfs__Opportunity__r.SBQQ__PrimaryQuote__r.License_Term__c
                                  from dsfs__DocuSign_Status__c where dsfs__Opportunity__c in : oppIDs and
                                  License_Term__c != null and
                                  dsfs__Opportunity__r.SBQQ__PrimaryQuote__r.License_Term__c != ''];
        }
        if(listOFCPtoValidate.size () > 0){
            for(dsfs__DocuSign_Status__c docsts:listOFCPtoValidate){
                mapOFQuoteLicenseTerms.put(docsts.dsfs__Opportunity__c,docsts);
            }
        } 
        /*test comment*/
     
        if(mapOFQuoteLicenseTerms != null){
            for(Opportunity opptoValidate:newOppList){
                if(mapOFQuoteLicenseTerms.containsKey(opptoValidate.Id) && mapOFQuoteLicenseTerms.get(opptoValidate.Id).dsfs__Opportunity__r.SBQQ__PrimaryQuote__r.License_Term__c != String.valueOf(mapOFQuoteLicenseTerms.get(opptoValidate.Id).License_Term__c)){
                    opptoValidate.addError('There is a difference in license term on Order Form/SFDC');
                }
            }
        }
    }
    
    @testvisible
    private void removeWarningFromOptyTrackerField(Opportunity opp){
        if(String.isBlank(opp.Opportunity_Tracking__c)) return;
        list<String> pickList = new list<String>();
        for(String pickVal :opp.Opportunity_Tracking__c.split(';')){
            if(pickVal.startsWith('Warning: ')) continue;
            pickList.add(pickVal);
        }
        opp.Opportunity_Tracking__c = String.join(pickList,';');
    }
    
    /**GTMS-13565 - START**/
    public static String checkLicenceProducts(List<OpportunityLineItem> oppLineItems){
        boolean allLicenseTypeProds = true;
        boolean partOfLicenseProdList = false;
        List<String> licenseProdCodes = System.Label.LICENSE_PRODUCT_CODE.split(',');
        for(OpportunityLineItem opli : oppLineItems){
            if(opli.Product2.Product_Type__c != 'License') {
                allLicenseTypeProds = false;break;
            }
            if(opli.Product2.Product_Type__c == 'License' && licenseProdCodes.contains(opli.ProductCode))
            {
                partOfLicenseProdList = true;
            }
        }
        if(allLicenseTypeProds && !(partOfLicenseProdList)){
            return 'Ready to Ship';
        } else {
            return 'Orders Processing';
        }
    }
    
    // Bulkified future method that will update delinquent oppty lines  'Renewed line' to True based returning oppty lines renewed line
    @future
    public static void UpdateRenewedLinesforRebate(Map<Id, Id> opportunityIds) {
        Set<Id> eligibleDelinquentOpptys = new Set<Id>();
        Map<Id, Set<String>> returningOpptyOLIMap = new Map<Id,Set<String>>(); // Map for returning oppty => eligbile product codes (renewedline = true)
        List<OpportunityLineItem> delinquentOLIsToUpdate = new List<OpportunityLineItem>();
        //Get all oppty lines from returning oppty where Renewed_Line__c = True
        for(OpportunityLineItem Oli : [SELECT Id,ProductCode, Renewed_Line__c,OpportunityId FROM OpportunityLineItem where Renewed_Line__c = true and OpportunityId IN : opportunityIds.keySet()]){
            eligibleDelinquentOpptys.add(opportunityIds.get(Oli.OpportunityId));
            //If the returning oppty is already in the map, add the respective string of product codes with new product codes
            if(returningOpptyOLIMap.ContainsKey(Oli.OpportunityId)){
                Set<String> productCodes = returningOpptyOLIMap.get(Oli.OpportunityId);
                productCodes.add(Oli.ProductCode);
                returningOpptyOLIMap.put(Oli.OpportunityId, productCodes);
            }else{ // if the map doesn't have returning oppty id -> initiate with new set of product codes
                returningOpptyOLIMap.put(Oli.OpportunityId, new Set<String>{Oli.Productcode});
            }
        }
        // Get the related delinquent Oppty lines based on the eligible delinquent opptys from above logic
        List<OpportunityLineItem> deliquentOLIs = [Select Id, Renewed_Line__c, Opportunity.Returning_Opportunity__c,productCode from OpportunityLineItem where OpportunityId IN : eligibleDelinquentOpptys];
        for(OpportunityLineItem delinquentOli : deliquentOLIs){
            // if the product code matches in returning oli map then we need to update delinquent OLI to renewedline = true
            if(returningOpptyOLIMap.containsKey(delinquentOli.Opportunity.Returning_Opportunity__c)){
                Set<String> productCodes = returningOpptyOLIMap.get(delinquentOli.Opportunity.Returning_Opportunity__c);
                if(productCodes.contains(delinquentOli.productCode)){
                    OpportunityLineItem Oli = new OpportunityLineItem(Id = delinquentOli.Id, Renewed_Line__c = true);
                    delinquentOLIsToUpdate.add(Oli);
                }
            }
        }
        // Final list of delinquent oppty OLIs for update
        if(!delinquentOLIsToUpdate.isEmpty()) update delinquentOLIsToUpdate;
    }
    
    public void createPlatformEvent() {
        if(opportunityEvents.size() > 0){
            List<Database.SaveResult> results = EventBus.publish(opportunityEvents);
        }
        if (orderSyncEvents.size() > 0) {
            List<Database.SaveResult> results = EventBus.publish(orderSyncEvents);
        }
        if (rebateSyncEvents.size() > 0) {
            List<Database.SaveResult> results = EventBus.publish(rebateSyncEvents);
        }
    } 
    
    public Integer getQtyLimitPerProduct(String oppType){
        if(oppType == 'Free Trial Opportunity' || oppType == 'Promo Opportunity')
            return 10;
        else if(oppType == 'Revenue Opportunity')
            return 20;
        return null;
    }
    
    //GTMS-28044, GTMS-27103 - Free Trial Order Automation
    public void freeTrialOpptyUScadEmeaMexicoLogic(List<Opportunity> newOppList, Map<Id, Opportunity> olpOppMap) {
        // Initialize maps and sets
        Set<String> emeaCountries = new Set<String>(System.Label.EMEA_SHIPPING_COUNTRIES.split(','));
        Set<String> validCurrencies = new Set<String>{ 'GBP', 'EUR', 'CHF','MXN' };
        
        // Query for Opportunity Line Items
        Map<Id, List<OpportunityLineItem>> oppLineItemsMap = new Map<Id, List<OpportunityLineItem>>();
        loadOppFields(newOppList);
        for (Opportunity opp : newOppList) {
            Set<String> prodCodes = new Set<String> ();
            String errorMsg = '';
            //United States Free Trial automation has been moved to OpportunityHelperAfterUpdate.expressSetAnnualDiscountLineItem() 
            //Because we need to check warehouse availability using api callout
            if (opp.Type == 'Free Trial Opportunity' 
                && opp.StageName == 'Orders Processing' && opp.StageName != olpOppMap.get(opp.Id).stageName
                && (emeaCountries.contains(opp.Shipping_Country__c) || opp.Shipping_Country__c == 'Mexico')) {
                    
                    Boolean validatedShipFromLoc = OrderAutomationService.satisfyShipFromLocation(opp);
                    if (validCurrencies.contains(opp.CurrencyIsoCode) 
                        && opp.Shipping_Address_NEW__c != null
                        && (opp.Segment_Sales_Role__c == 'AE2' || opp.Segment_Sales_Role__c == 'AE3' || opp.Segment_Sales_Role__c == 'Enterprise' || opp.Segment_Sales_Role__c == 'ENT' || Test.isRunningTest())
                        && String.isBlank(opp.Order_Ops_Notes__c)
                        && String.isBlank(opp.Shipping_Instructions__c) 
                        && String.isBlank(opp.Internal_RFO_Notes__c)
                        && opp.Hold_Reason__c == null 
                        && validatedShipFromLoc)
            {
                prodCodes.addAll(OrderAutomationService.getProductCodesByCountryAndType(opp.Shipping_Country__c, opp.Type));
                
                if (oppFields.containsKey(opp.Id) && oppFields.get(opp.Id) != null && oppFields.get(opp.Id).OpportunityLineItems != null) 
                {
                    for (OpportunityLineItem oli : oppFields.get(opp.Id).OpportunityLineItems) {
                        if (!prodCodes.contains(oli.ProductCode)) {
                            errorMsg = System.Label.Invalid_Product_SKU_Note;
                            break;
                        }
                    }
                }
                
                if (String.isEmpty(errorMsg)) 
                {
                    opp.StageName = 'Ready to Ship';
                    opp.Probability = 99;
                    opp.Went_To_Ready_To_Ship__c = true;
                    opp.Went_To_Ready_To_Ship_Date__c = DateTime.now();
                    If(emeaCountries.contains(opp.Shipping_Country__c)) {
                        opp.Automation_Notes__c = System.Label.EMEA_Automation_Notes;
                    }
                    If(opp.Shipping_Country__c == 'Mexico') {
                        opp.Automation_Notes__c = System.Label.Mexico_Automation_Notes;
                    }
                    
                } else {
                    
                    String automationNotes = String.isNotBlank(opp.Automation_Notes__c) ? (opp.Automation_Notes__c + '; ' + errorMsg) : errorMsg;
                    if (automationNotes.length() > 255) {
                        automationNotes = automationNotes.substring(0, 255);
                    }
                    opp.Automation_Notes__c = automationNotes;
                }
            }
                    
                }
        }
        
    }  
    
    //Frame your Logger message 
    public String getLoggerMessage(String message) {
        return message.length() > 130072 ? message.substring(0, 130072) : message;
    }
        
    
    /**

    * @description  This method is used to throw a validation error when the status of return opportunity 
                    will be updated to Finance Processing/Return Label Sent and there are no Related 
                    Opportunity recods with subtype as 'Upgrade Opportunity' - GTMS-27442
    * @author hitesh.garg | 08-29-2025 
    * @param newOppList 
    * @param oldOppMap 
    **/

    private void validateSwapOpportunity( List< Opportunity > newOppList, Map< Id, Opportunity > oldOppMap ) {

        Map< Id, Opportunity > returnWithSwapOppIdToOppRecMap = new Map< Id, Opportunity >();

        for( Opportunity oppRec : newOppList ) {

            if (    oppRec.Type == OPP_TYPE_REMORSE_REFUND
                    &&  (   oppRec.StageName == OPP_STAGE_RET_FIN_PROCESS
                            || oppRec.StageName == OPP_STAGE_RET_LABEL_SENT
                        )
                    && oldOppMap.get( oppRec.Id ).StageName != oppRec.StageName
                    && oppRec.Swap__c == true 
                    && oppRec.Sub_Type__c == OPP_SUB_TYPE_UPGRADE ) {
                returnWithSwapOppIdToOppRecMap.put( oppRec.Id,  oppRec );
            }
        }

        if ( returnWithSwapOppIdToOppRecMap.isEmpty() ) {
            return;
        }
        
        new ReturnOpportunityService().validateSwapOpportunity( returnWithSwapOppIdToOppRecMap );
    }
    
    /**
     * GTMS-29391: Sets the Renewal_Type__c picklist field on Opportunity based on business logic
     * This method determines renewal type based on ACV vs Available to Renew comparison
     * and stage changes to Closed Lost
     */
    public void setRenewalSubType(Opportunity opp) {
            // 1. Full Churn: When a master renewal opportunity is fully Closed Lost
            if (opp.StageName == 'Closed Lost' && opp.IsClosed && opp.Consolidated_Renewal_Opportunity_Id__c==null) {
                opp.RenewalSubType__c = System.Label.Renewal_Sub_Type_Full_Churn;
            }
        	// 2. Consolidated / Merged ACV : When consolidated child renewal opportunity is Closed Lost
            else if(opp.StageName == 'Closed Lost' && opp.IsClosed && opp.Consolidated_Renewal_Opportunity_Id__c!=null){
                opp.RenewalSubType__c = System.Label.Renewal_Sub_Type_Consolidated;
            }
            // 2. Downsize: When Renewal Oppty ACV < Available to Renew
            else if (
                opp.ACV_Bookings_USD__c != null && 
                opp.Available_to_Renew__c != null &&
                opp.ACV_Bookings_USD__c < opp.Available_to_Renew__c
            ) {
                opp.RenewalSubType__c =  System.Label.Renewal_Sub_Type_Downsize;
            }
            // 3. Flat: No change in Renewal Oppty ACV; i.e. ACV == Available to Renew
            else if (
                opp.ACV_Bookings_USD__c != null && 
                opp.Available_to_Renew__c != null &&
                opp.ACV_Bookings_USD__c == opp.Available_to_Renew__c
            ) {
                opp.RenewalSubType__c = System.Label.Renewal_Sub_Type_Flat;
            }
            // 4. Upsize: When Renewal Oppty ACV > Available to Renew
            else if (
                opp.ACV_Bookings_USD__c != null && 
                opp.Available_to_Renew__c != null &&
                opp.ACV_Bookings_USD__c > opp.Available_to_Renew__c
            ) {
                opp.RenewalSubType__c = System.Label.Renewal_Sub_Type_Upsize;
            }
    }
    
    public void beforeUpdateCommit(Map<Id,Opportunity> oldOppMap){
        if(promoOpportunities != null && !promoOpportunities.isEmpty()){
            insert promoOpportunities;
            for(Opportunity opp : promoOpportunities){
                String oppId = opp.RMA_Return_Opportunity__c.substringAfterLast('/');
                Opportunity oldOpp = oldOppMap.get((Id)oppId);
                oldOpp.Replacement_Opportunity__c = URL.getOrgDomainUrl().toExternalForm() + '/' + opp.Id;
            }
            promoOpportunities.clear();
        }
    }
}