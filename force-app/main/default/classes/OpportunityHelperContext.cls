public virtual class OpportunityHelperContext {
    
    public static Set<Id> newOppIdSet = new Set<Id>();     //GTMS-26285 :Store all the CurrentId
    public static Map<Id, Account> oppAccounts = null;
    public static Map<Id, Account> oppAccountsRev = null;
    public static Map<Id, Opportunity> oppFields = null;
    private static Set<Id> oppAccountIds = null;
    public static Map<Id, Contract> contractsMap = new Map<Id, Contract>();
    private static Boolean isRecursion = false;
    public static Map<Id, User> mapUsers = null;
    public static Map<Id, Account> accountUpdateMap = new Map<Id, Account>();
    public set<Id> accountIdSet = new set<Id>(); //GTMS-6450
    private static Map<Id, Opportunity> trialOppFields = new Map<Id, Opportunity>();
    public static Id opportunityRevRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standard_Opportunity').getRecordTypeId();
    
    public static Map<String, Id> trailLangugeTemplateIdMap = new Map<String, Id>();
    public Set<Id> closedLostOppIdSet;
    public static boolean expressSetDiscountRun = false;
    private static final Set<String> CLOSED_STAGES = new Set<String>{'Closed Won','Refunded - Closed'}; 
    private static final Set<String> OPPORTUNITY_TYPES = new Set<String>{'Revenue Opportunity', 'Remorse Refund', 'Rebate','Revenue Opportunity - Bill Only','Warranty Exchange'};
    private static Map<Id, Opportunity> allOppMap = new Map<Id, Opportunity>();
    private static Set<Id> OppAccIds = new Set<Id>();
    //public static List<Order_Event__e> orderSyncEvents = new List<Order_Event__e>();
    //public static List<Rebate_Event__e> rebateSyncEvents = new List<Rebate_Event__e>();
    public Set<Id> duplicateOpportunityEvents = new Set<Id>();
    //public static List<Opportunity_Event__e> opportunityEvents = new List<Opportunity_Event__e>();
    public List<Opportunity> clickPathOppList;
    public Map<Id, Id> primaryQuoteToOppIdMap;
    public final static String GAINSIGHT_IGNORE_STATUS = Label.Success;
    public static Map<String, Set<Id>> methodToOppIdsMap = new Map<String, Set<Id>>(); //GTMS-28265 used to store the method name and the opportunity ids that are processed by the method
        Global_Automation_Settings__c gas = Global_Automation_Settings__c.getInstance(UserInfo.getUserId());
     /**
     * Retrieve records from salesforce 
     */
    public void getRecords(Map<Id, Opportunity> newOppMap, Map<Id, Opportunity> oldOppMap) {

        List<Opportunity> oppList = newOppMap == null ? oldOppMap.values() : newOppMap.values();
        for (Opportunity opp : oppList) {
            Opportunity newOpp = newOppMap != null ? newOppMap.get(opp.Id) : null; 
            Opportunity oldOpp = oldOppMap != null ? oldOppMap.get(opp.Id) : null;          

             if (isOpportunityChange(newOpp, oldOpp)) {
                if (opp.AccountId != null) {
                    OppAccIds.add(opp.AccountId);
                }
                if (oldOpp?.AccountId != null && oldOpp.AccountId != opp.AccountId) {
                    OppAccIds.add(oldOpp.AccountId);
                }
            }
        }
         if (allOppMap.isEmpty() && !OppAccIds.isEmpty()) {
            allOppMap = new Map<Id, Opportunity>([
                SELECT Id, Name, AccountId, Type, StageName, ACV_Bookings_SOT__c,Owner.Name,
                       ExpectedRevenue, IsClosed, Probability, CreatedDate, CloseDate, Active_Opportunity__c,
                       Monthly_Deal_or_Monthly_Return__c, License_End_Date__c, Total_License_Due__c, 
                       Returning_Opportunity__c, Returning_Opportunity__r.License_End_Date__c
                FROM Opportunity
                WHERE Type IN :OPPORTUNITY_TYPES AND AccountId IN :OppAccIds ORDER BY AccountId]);
        }
    }
    private Boolean isOpportunityChange(Opportunity opp, Opportunity oldOpp) {
        // OpenOpportunity
        if (((opp!= null && !opp.IsClosed) || (oldOpp != null && !oldOpp.IsClosed)) &&
        ((opp!= null && opp.Type == 'Revenue Opportunity') || (oldOpp != null && oldOpp.Type == 'Revenue Opportunity')) &&
         (oldOpp == null || opp == null|| 
                opp.Probability != OldOpp.Probability|| 
                opp.IsClosed != OldOpp.IsClosed ||
                opp.Type != OldOpp.Type ||
                opp.amount != OldOpp.amount ||
                opp.AccountId != oldOpp.AccountId)) {
            return true;
        }
        
        if (((opp!=null && CLOSED_STAGES.contains(opp.StageName)) || 
                (oldOpp != null && CLOSED_STAGES.contains(oldOpp.StageName))) && 
               ((opp!=null && String.isNotBlank(opp.Type) && OPPORTUNITY_TYPES.contains(opp.Type)) || 
                (oldOpp != null && String.isNotBlank(oldOpp.Type) && OPPORTUNITY_TYPES.contains(oldOpp.Type))) &&
               (oldOpp == null || opp == null||
                opp.StageName != oldOpp.StageName ||
                opp.Type != oldOpp.Type || 
                opp.ACV_Bookings_SOT__c != oldOpp.ACV_Bookings_SOT__c)) {
            return true;
        }
        
        if (((opp!=null && String.isNotBlank(opp.Type) && OPPORTUNITY_TYPES.contains(opp.Type)) || 
                (oldOpp != null && String.isNotBlank(oldOpp.Type) && OPPORTUNITY_TYPES.contains(oldOpp.Type))) &&
                (oldOpp == null || opp == null||
                 opp.StageName != OldOpp.StageName || 
                 opp.License_End_Date__c != oldOpp.License_End_Date__c ||
                 opp.CloseDate != OldOpp.CloseDate ||
                 opp.type != OldOpp.type ||
                 opp.Active_Opportunity__c != OldOpp.Active_Opportunity__c ||
                 opp.Monthly_Deal_or_Monthly_Return__c != OldOpp.Monthly_Deal_or_Monthly_Return__c
                 ||opp.AccountId != oldOpp.AccountId)) {
            return true;
        }
        return false;
    }
    
    
    // COMMENTS FOR OPTIMIZING THE CURRENT CODE
    // 1. We can fsolidate similar conditions, for example if probability <= 95
    // * 03/04/2021 Ron (GTMS-2878) Annual Payments no longer trigger payment processing fee
    public void beforeInsertOrUpdate(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap,Map<Id, Opportunity> newOppMap) {
        loadOppAccounts(newOppList);
        loadOppFields(newOppList);
        Set<Id> contractIds = new Set<Id>();
        //Map<Id, Contract> contractsMap = new Map<Id, Contract>();
        Opportunity oldOpportunity = new Opportunity();
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
        Set<Id> shippingAddressIds = new Set<Id>();
        String shippingAndHandlingTaxLocations = System.Label.Shipping_and_Handling_Tax;
        Boolean changeAddressQueryFlag = false;
        String configurationSegment;
        Set<Id> ownerIds = new Set<Id>();
        Map<Id, Opportunity> opptyWithOwnerRoleMap = new Map<Id, Opportunity>();
        Map<String, Object> flowParams = new Map<String, Object>();
        Set<String> opptyStagesForOwnerRole = new Set<String>{'Incubate', 'Qualified', 'Trial', 'Proposal', 'Decision', 'Purchase' , 'Closing' , 'Return Created', 'Return Initiated','Return Label Sent','Products Processing','Finance Processing'};
            //GTMS-8640, 8059
            List<String> cwRoboIds = System.Label.Corpweb_SFDC_Robot.split(',');
        //GTMS-9601
        List<String> profileIdsForHwAG4ValdiationRule = System.Label.HWAG4ProductLineProfiles.split(',');
        String HWAG4ValidationErrorMsg = System.Label.HWAG4ProductLineValidationErrorMsg;
        List<String> returnOppTypes = System.Label.Return_Opportunity_Types.split(','); //GTMS-10297
        //Groundswell - Nilesh Jain : Workflow Changes
        //GTMS-10997
        Map<String, String> mapCanadaState = getCanadaShipFrom();
        Set<Id> oppIds = new Set<Id>();
        // Query any related contract end dates
        setOpportunityTypeForFreeTrials(newOppList);
        for (Opportunity o : newOppList) {
            
            if(oldOppMap != null && o.StageName != oldOppMap.get(o.Id).StageName && o.StageName == 'Closing') {
                oppIds.add(o.Id);
            }
            //GTMS-23000
            if (o.SBQQ__RenewedContract__c != null){
                contractIds.add(o.SBQQ__RenewedContract__c);
                opportunity oppty;
                if (oppFields != null && oppFields.Containskey(o.id)) {
                    oppty =  oppFields.get(o.id);
                }
                if(oppty != null && oppty.Account !=null && oppty.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c == null && o.Probability <= 95 && o.stageName != 'Closed Lost' && o.CloseDate != null && o.Type == 'Revenue Opportunity' && 
                    (oppty.Account?.Segment__c == 'AE1' || oppty.Account.Segment__c == 'Small Business' || (oppty.Account.Segment__c == 'Management' && (oppty.Account.Account_Size_Segment__c != 'AE2/AE3' && oppty.Account.Account_Size_Segment__c != 'ENT'))
					|| (oppty.Account.Segment__c == 'AE2' && oppty.Account.Customer_ARR_Netsuite__c <= 20000)) && oppty.Account.Segment__c != 'AE3' && oppty.Account.Segment__c != 'Enterprise'
					){
                        o.License_Start_Date__c = o.CloseDate;
                	 }
            }
            //added condition for GTMS-10997
            if(o.Shipping_State__c != null && mapCanadaState.containsKey(o.Shipping_State__c) && o.Shipping_Country__c == 'Canada' &&
               o.Type == 'Promo Opportunity' && o.StageName == 'Orders Processing') {
                   //o.Ship_From_Location__c = mapCanadaState.get(o.Shipping_State__c); GTMS-28141 -- ABU --> 06262025
                   o.Shipping_Carrier__c = 'UPS';
                   //o.Shipping_Method__c = 'Ground'; GTMS-28141 -- ABU --> 06262025
               }
            //update for GTMS-22807
            if (o.StageName == 'Incubate' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Incubate')) {
                o.Went_To_Incubate_Date__c = Datetime.Now();
                o.Went_To_Incubate__c = TRUE;
            } else if (o.StageName == 'Qualified' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Qualified')) {
                o.Went_To_Qualified_Date__c = Datetime.Now();
                o.Went_To_Qualified__c = TRUE;
            } else if (o.StageName == 'Trial' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Trial')) {
                o.Went_To_Trial_Date__c = Datetime.Now();
                o.Went_To_Trial__c = TRUE;
            } else if (o.StageName == 'Proposal' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Proposal')) {
                o.Went_To_Proposal_Date__c = Datetime.Now();
                o.Went_To_Proposal__c = TRUE;
            } else if (o.StageName == 'Decision' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Decision')) {
                o.Went_To_Decision_Date__c = Datetime.Now();
                o.Went_To_Decision__c = TRUE;
            } else if (o.StageName == 'Purchase' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Purchase')) {
                o.Went_To_Purchase_Date__c = Datetime.Now();
                o.Went_To_Purchase__c = TRUE;
            } else if (o.StageName == 'Closing' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Closing')) {
                o.Went_To_Closing_Date__c = Datetime.Now();
                o.Went_To_Closing__c = TRUE;
            } else if (o.StageName == 'Orders Processing' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Orders Processing')) {
                o.Went_to_Orders_Processing_Date__c = Datetime.Now();
                o.Went_to_Orders_Processing__c = TRUE;
                if (!(o.Type == 'Revenue Opportunity' && o.SBQQ__Renewal__c == true) && o.CloseDate != Date.today()){
                    o.CloseDate = Date.today();
                }
            } else if (o.StageName == 'Ready To Ship' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Ready To Ship')) {
                o.Went_To_Ready_To_Ship_Date__c = Datetime.Now();
                o.Went_To_Ready_To_Ship__c = TRUE;
            } else if (o.StageName == 'Closed Won' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Closed Won')) {
                o.Went_To_Closed_Won_Date__c = Datetime.Now();
                o.Went_To_Closed_Won__c = TRUE;
            }
            //GTMS-21691
            if((oldOppMap != null && HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.Probability)) &&oppFields.Containskey(o.id) &&oppFields.get(o.Id).opportunityLineItems != null && !(o.SE_Key_Account__c)){
                o.SE_Key_Account_Override__c = KeyAccountEligible(oppFields.get(o.Id).opportunityLineItems);
            }
            // added for GTMS-16051
            if (o.Insurance_Partner__c != null &&  (((oldOppMap == null || (oldOppMap != null && oldOppMap.get(o.Id) == null)) && o.LOI_Status__c =='Sent')
                                                    || (oldOppMap != null && (oldOppMap.get(o.Id) != null && oldOppMap.get(o.Id).LOI_Status__c != o.LOI_Status__c) && o.LOI_Status__c =='Sent')))
            {
                o.SCL_Status_Sent_Date__c = system.now();
            }
            // added for GTMS-20208
            if (o.VAT_Number__c != null && o.VAT_Number__c.contains(' ')) {
                o.VAT_Number__c =  o.VAT_Number__c.replaceAll('\\s+', '');
            }
            //GTMS-9601
            if(Trigger.isBefore && Trigger.isUpdate && oldOppMap != null &&
               oppFields.containsKey(o.Id) && oppFields.get(o.Id).opportunityLineItems != null){
                   Boolean isError = validateOppForHWProducts(oppFields.get(o.Id).opportunityLineItems, o,
                                                              oldOppMap, profileIdsForHwAG4ValdiationRule, returnOppTypes );
                   if(isError){
                       o.addError(HWAG4ValidationErrorMsg);
                   }
               }
            //GTMS-13685             (o.Renewal__c || o.SBQQ__Renewal__c) &&
            if (Trigger.isBefore && Trigger.isUpdate &&
                !System.Label.SkipCotermContractValidationProfileIDs.contains(UserInfo.getProfileId()) &&
                o.Probability>=75 &&
                oppFields.containsKey(o.Id) &&
                oppFields.get(o.Id).SBQQ__PrimaryQuote__c!=null &&
                oppFields.get(o.Id).SBQQ__PrimaryQuote__r.Co_Term_Contract__c!=null &&
                oppFields.get(o.Id).SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate!=null &&
                o.CloseDate.daysBetween(oppFields.get(o.Id).SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate)<=30){
                    o.addError('Co-term Contract on primary Quote will expire in 30 days when the opportunity will close. Please change/remove co-term Contract on primary quote or change close date on opportunity.');
                }
            /*
//GTMS-7702
if ((o.Shipping_and_Handling_Amount__c == 99999 || o.Total_Weight_oz__c > 2500) && (o.StageName == 'Purchase' && o.Probability == 90))
{
system.debug('RODRIGO send email');
o.Shipping_Carrier__c = 'FEDEX FREIGHT';
o.Shipping_Method__c = 'ECONOMY';
}  */
            //GTMS-7702
            if (o.Shipping_Address_NEW__c != null) {
                shippingAddressIds.add(o.Shipping_Address_NEW__c);
                if (!HelperClass.opportunityShippingAddresses.isEmpty() && !HelperClass.opportunityShippingAddresses.containsKey(o.Shipping_Address_NEW__c)) {
                    changeAddressQueryFlag = true;
                }
            }
            //GTMS-6450
            if(o.AccountId <> null)
                accountIdSet.add(o.AccountId);
            //GTMS-13490 --Start : to add referral rebate value based referral partner account.
            if(trigger.isBefore){
                if(trigger.isInsert){
                    o.Referral_Rebate__c = o.Referral_partner__c != null ? oppAccounts.get(o.Referral_Partner__c) != null ?  oppAccounts.get(o.Referral_Partner__c).Referral_Rebate__c : null : null;
                }else if(trigger.isUpdate){
                    o.Referral_Rebate__c = oldOppMap.get(o.Id).Referral_partner__c !=  o.Referral_Partner__c ? oppAccounts.get(o.Referral_Partner__c) != null ?  oppAccounts.get(o.Referral_Partner__c).Referral_Rebate__c : null : oppAccounts.get(o.Referral_Partner__c) != null ? oppAccounts.get(o.Referral_Partner__c).Referral_Rebate__c : o.Referral_Rebate__c;
                }
            }
            //GTMS-13490 -- End
            //GTMS-25658
            Id opptyReturnRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Return_Opportunity').getRecordTypeId();
            
            if (o.RecordTypeId == opptyReturnRecordTypeId) {
                if (o.Shipping_Country__c == 'United States') {
                    o.Shipmate_Service_Type__c = 'ups_ground';
                } else if (o.Shipping_Country__c == 'Canada') {
                    o.Shipmate_Service_Type__c = 'ups_worldwide_express';
                } else if (o.Shipping_Country__c == 'Mexico') {
                    o.Shipmate_Service_Type__c = 'ups_worldwide_saver';
                } else if (o.Shipping_Country__c != null && System.label.EMEA_Countries.Contains(o.Shipping_Country__c)) {
                    o.Shipmate_Service_Type__c = 'ups_standard';
                } 
            }
            
            //Added for GTMS-28039
            if(o.SBQQ__RenewedContract__c != null && o.Probability < 95 && o.stageName != 'Closed Lost' && o.CloseDate != null && o.CloseDate >= Date.valueOf(System.Label.Checkout_Link_For_Renewal_Go_Live_Date) && o.SBQQ__PrimaryQuote__c != null){
    			Account relatedAccount = (oppAccounts != null && oppAccounts.containsKey(o.AccountId)) ? oppAccounts.get(o.AccountId) : null;
    			Opportunity oppWithFields = (oppFields != null && oppFields.containsKey(o.Id)) ? oppFields.get(o.Id) : null;
                if(relatedAccount != null && oppWithFields != null){
                    setRenewalCheckoutAgreementLink(o, relatedAccount, oppWithFields);
                }
    			
			}
        }
        //End
        if(oppIds.size() > 0) {
            for(Opportunity opp : [SELECT Id, AccountId, Amount, Type, StageName, Returning_Opportunity__r.Owner_Role_Copy__c, Configuration_Segment__c, TrialResolutionOppty__c,
                                   Pricebook2.Name, Pricebook2Id, CurrencyISOCode, Owner.UserRole.Name, Owner.Manager.Name,Owner.Manager.Manager.Manager.Name, Owner.Manager.Manager.Manager.UserRole.Name, Ship_From_Location__c,
                                   SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.Co_Term_Contract__c,SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate
                                   FROM Opportunity
                                   WHERE TrialResolutionOppty__c IN :oppIds
                                  ]) {
                                      trialOppFields.put(opp.TrialResolutionOppty__c, opp);
                                  }
        }
        //GTMS-23000
        if(contractIds.size()>0 && (contractsMap == null || contractsMap.size() <= 0)){
            loadContracts(contractIds);
        }
        if ((shippingAddressIds.size() > 0) && (HelperClass.opportunityShippingAddresses.isEmpty() || changeAddressQueryFlag)) {
            HelperClass.opportunityShippingAddresses = HelperClass.getShippingData(shippingAddressIds);
        }
        Org_Setting__mdt otLaunchSetting = Org_Setting__mdt.getInstance('OTLaunchDate');
        for (Opportunity vOpportunity : newOppList) {
            if(trialOppFields.containsKey(vOpportunity.Id) && vOpportunity.CreatedDate >= Date.valueOf(otLaunchSetting.Value__c)) {
                vOpportunity.addError('This revenue opportunity is associated with a Free Trial. Please complete the free trial decision flow before moving this to closing.');
            }
            if(vOpportunity.Id != null){
                opportunityIds.add(vOpportunity.Id);
            }
            //GTMS-29333: We need Returning_Opportunity__c data to populate on Return Opportunity for Copy Fields
            //            In update scenario
            if(vOpportunity.Returning_Opportunity__c != null){
                opportunityIds.add(vOpportunity.Returning_Opportunity__c);
            }
            if (oldOppMap != null) {
                oldOpportunity = oldOppMap.get(vOpportunity.Id);
            }
            if(vOpportunity.OwnerId != null){
                ownerIds.add(vOpportunity.OwnerId);
                //WF Rule - Copy Owner Role
                if((opptyStagesForOwnerRole.contains(vOpportunity.StageName) || (vOpportunity.Owner_Role_Copy__c == null)) && (vOpportunity.Rebate_Type__c != 'Partner Referral' || vOpportunity.Rebate_Type__c != 'Co-Term Credit')
                  ){
                      opptyWithOwnerRoleMap.put(vOpportunity.OwnerId,vOpportunity);
                  }
            }
        }
        Map<Id, Opportunity> opportunitiesDataByIds = queryOpportunities(opportunityIds);
        if(oldOppMap != null) {
            RebateLogicHandler.updateQuoteFieldsDealComp(newOppMap, opportunitiesDataByIds);//GTMS-27273
        }
        //GTMS-15132
        Map<String,Id> gvLabelUserId = new Map<String,Id>();
        Map<String,Global_Variable__mdt>  globalVariables = Global_Variable__mdt.getall();
        if(globalVariables != null){
            for(Global_Variable__mdt gv:globalVariables.values()){
                if(gv.DeveloperName.startsWith('Rebate_')){
                    gvLabelUserId.put(gv.Label, gv.Value__c);
                    ownerIds.add(gv.Value__c);
                }
            }
        }
        if(ownerIds != null && ownerIds.size() > 0){
            ownerIds.add(Label.Clickpath_Opportunity_Won_User_Id); //Flavio:GTMS:6105-Mar2022
            getOpptyOwner(ownerIds);
            system.debug('$$$$$$$ownerIds=====> ' + ownerIds);
        }    
        ShippingHandlingCalculations.getShippingConfigurations(); // GTMS-28236 Rodrigo
        B360LogicHandler.isB360Opportunity(newOppList, mapUsers, oppFields, oldOppMap); //GTMS-27916
        for (Opportunity o : newOppList) {
            //DCA Code Start
            if(o.IsClosed==false){
                o.DCA_Enabled__c=getDCAEnabled(o);
            }
            //DCA Code End
            if (oldOppMap != null) {
                oldOpportunity = oldOppMap.get(o.Id);
            }
            /*Merge conflict Issue */
            if(oppAccounts != Null && oppAccounts.containsKey(o.AccountId)) {
                if(o.Type == 'Revenue Opportunity' && o.RecordTypeId == opportunityRevRecordTypeId && oppAccounts.get(o.AccountId).Segment__c != 'AE1') {
                    //GTMS-17232
                    if(oppAccounts.get(o.Finance_Partner__c) != null && ((trigger.isInsert && o.Finance_Partner__c != Null)
                                                                         || (trigger.isUpdate && trigger.isBefore && oldOpportunity != Null && oldOpportunity.Finance_Partner__c != o.Finance_Partner__c))) {
                                                                             o.Payment_Terms__c = oppAccounts.get(o.Finance_Partner__c).Payment_Terms__c;
                                                                             o.Internal_Finance_Payment_Type__c = oppAccounts.get(o.Finance_Partner__c).Approved_Payment_Type__c;
                                                                         }
                    else if(oppAccounts.get(o.Reseller__c) != null && ((trigger.isInsert && o.Reseller__c != Null) || (trigger.isUpdate && trigger.isBefore && oldOpportunity != Null && oldOpportunity.Reseller__c != o.Reseller__c))) {
                        o.Payment_Terms__c = oppAccounts.get(o.Reseller__c).Payment_Terms__c != null ? oppAccounts.get(o.Reseller__c).Payment_Terms__c : 'Net 30';//Net 30 added as part of GTMS-26451 If payment terms on reseller are blank need to populate default value as Net 30;
                        o.Internal_Finance_Payment_Type__c = oppAccounts.get(o.Reseller__c).Approved_Payment_Type__c;
                    }
                    else if(oppAccounts.get(o.Insurance_Partner__c) != null && ((trigger.isInsert && o.Insurance_Partner__c != Null)  || (trigger.isUpdate && trigger.isBefore && oldOpportunity != Null && oldOpportunity.Insurance_Partner__c != o.Insurance_Partner__c))) {
                        o.Payment_Terms__c = oppAccounts.get(o.Insurance_Partner__c).Payment_Terms__c;
                        o.Internal_Finance_Payment_Type__c = oppAccounts.get(o.Insurance_Partner__c).Approved_Payment_Type__c;
                    }
                    else if(trigger.isInsert && oppAccounts.get(o.Insurance_Partner__c) == null && oppAccounts.get(o.Reseller__c) == null && oppAccounts.get(o.Finance_Partner__c) == null && ( o.Payment_Terms__c == null || o.Internal_Finance_Payment_Type__c == null)) {
                        if(oppAccounts.get(o.AccountId) != null) {
                            if(String.isNotBlank(oppAccounts.get(o.AccountId).Payment_Terms__c)) {
                                o.Payment_Terms__c = oppAccounts.get(o.AccountId).Payment_Terms__c;
                            }
                            if(String.isNotBlank(oppAccounts.get(o.AccountId).Approved_Payment_Type__c)) {
                                o.Internal_Finance_Payment_Type__c = oppAccounts.get(o.AccountId).Approved_Payment_Type__c;
                            }
                        }
                    }
                    if(trigger.isInsert && String.isNotBlank(o.Payment_Terms__c)) {
                        o.Initial_Payment_Terms__c = o.Payment_Terms__c;
                    }
                    //GTMS-17232
                }
                //GTMS-24282
                if(o.Type == 'Revenue Opportunity' && o.RecordTypeId == opportunityRevRecordTypeId && o.SBQQ__AmendedContract__c != null && Trigger.isInsert && String.isNotBlank(o.Payment_Terms__c) && oppAccounts.get(o.AccountId).Segment__c == 'AE1'){
                    o.Initial_Payment_Terms__c = o.Payment_Terms__c;
                }
            }
            //GTMS-12823
            if(Trigger.isUpdate && opportunitiesDataByIds <> NULL && opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__c <> NULL){
                if((o.SBQQ__AmendedContract__c == NULL && opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__r.sbqq__mastercontract__c <> NULL) ||
                   (o.SBQQ__AmendedContract__c <> NULL && opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__r.sbqq__mastercontract__c == NULL) ||
                   (o.SBQQ__AmendedContract__c <> NULL && opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__r.sbqq__mastercontract__c <> NULL && o.SBQQ__AmendedContract__c <> opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__r.sbqq__mastercontract__c)){
                       o.SBQQ__AmendedContract__c = opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__r.sbqq__mastercontract__c;
                   }
            }
            //Satya: GTMS-6110 Apr 29 2022
            if(o.Type == 'Revenue Opportunity' && oldOpportunity.StageName != o.StageName && o.SBQQ__Contracted__c && o.StageName == 'Closed Won' && o.SBQQ__AmendedContract__c != null && !opportunitiesDataByIds.get(o.Id).SBQQ__AmendedContract__r.SBQQ__RenewalQuoted__c && !isRecursion) {
                flowParams.put('contractId', o.SBQQ__AmendedContract__c);
                Flow.Interview.Send_Email_on_Closed_Amendment_Opp email = new Flow.Interview.Send_Email_on_Closed_Amendment_Opp(flowParams);
                email.start();
                isRecursion = true;
            }
            // GTMS-22650    
            Boolean isAutoRenewal = false;
            if(contractsMap != Null && contractsMap.containsKey(o.SBQQ__RenewedContract__c)){
                isAutoRenewal = contractsMap.get(o.SBQQ__RenewedContract__c).Auto_Renewal__c;
            }
            //Flavio:GTMS:6105-Mar2022
            if(o.Type == 'Revenue Opportunity'
               && (o.Sub_Type__c == 'Clickpath' || isAutoRenewal)
               && o.Renewal__c
               && !(oppAccounts.containsKey(o.AccountId) && oppAccounts.get(o.AccountId).Customer_require_PO_for_invoicing__c == 'Yes' && (o.PO_Number__c == '-' || o.PO_Number__c == '' || o.PO_Number__c == null))
               && (oldOpportunity != null && oldOpportunity.Id != null)
               && (o.Express_Agreement_Accepted_Date__c != null && oldOpportunity.Express_Agreement_Accepted_Date__c != o.Express_Agreement_Accepted_Date__c)
               && (o.SBQQ__RenewedContract__c != NULL || o.SBQQ__AmendedContract__c != NULL)){
                   o.StageName = 'Orders Processing';
                   if (o.CloseDate > System.today()){
                       o.Adjust_License_Start_Date__c = true;
                       o.License_Start_Date__c = o.CloseDate;
                   }
                   //GTMS-23000
                   updateOpptyFromContractUsingWASD(o, contractsMap);
                   if (o.OwnerId == Id.valueOf(Label.Renewal_Pool_User) && mapUsers.containsKey(Label.Clickpath_Opportunity_Won_User_Id) && mapUsers.get(Label.Clickpath_Opportunity_Won_User_Id).IsActive){
                       o.OwnerId = Id.valueOf(Label.Clickpath_Opportunity_Won_User_Id);
                   }
               }
            //Zakeer: GTMS-4675-Dec-16
            if(o.Adjust_License_Start_Date__c && o.StageName == 'Closed Won'){
                o.CloseDate = o.License_Start_Date__c;
            }
            //workflow
            if (o.Probability > 0 && o.Qualified_Date__c == null && o.Type == 'Revenue Opportunity') {
                o.Qualified_Date__c = System.now();
            }
            Account thisOppAccount = new Account();
            if (o.AccountId != NULL && oppAccounts.containsKey(o.AccountId)) {
                thisOppAccount = oppAccounts.get(o.AccountId);
            }
            //GTMS-14333
            If(thisOppAccount != null && thisOppAccount.Segment__c != Null && !Trigger.IsUpdate && !thisOppAccount.Segment__c.contains('AE1')) {
                o.Selected_Payment_Type__c = thisOppAccount.Approved_Payment_Type__c;
                o.Internal_Finance_Payment_Type__c = thisOppAccount.Approved_Payment_Type__c;
            }
            if (o.isClosed == FALSE) {
                if(HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.OwnerId)){
                    configurationSegment = thisOppAccount.Segment__c != null && thisOppAccount.Segment__c.contains(System.Label.Account_Express_Segment) ? 'Express' : 'Non Express';
                    o.Configuration_Segment__c = configurationSegment;
                }
                // Logic to update FP & Upsell for Buyouts & Subsidy
                if((o.Amount != NULL && o.License_Term__c != NULL && o.License_Term__c != 0  && o.Rebate_Type__c != NULL && o.Type != NULL) && System.Label.Rebate.contains(o.Type) && (oldOppMap == null || oldOpportunity.Amount != o.Amount || o.License_Term__c != oldOpportunity.License_Term__c)
                   && (System.Label.Buyout.contains(o.Rebate_Type__c) || System.Label.Subsidy.contains(o.Rebate_Type__c) || System.Label.Partner_Referral.contains(o.Rebate_Type__c) || System.Label.Delinquent.contains(o.Rebate_Type__c) || System.Label.Non_Commissionable_SKU.contains(o.Rebate_Type__c))){
                       if(o.Owner_Role_Copy__c != NULL && o.Owner_Role_Copy__c.contains(System.Label.Renewal)){
                           o.Renewal_ACV__c = o.Amount / (o.License_Term__c /12);
                       }
                       else{
                           o.FP_and_Upsell_ACV__c = o.Amount / (o.License_Term__c /12);
                       }
                   }
                if (HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.VAT_Validation_Status__c) &&
                    o.VAT_Validation_Status__c == 'Verified' &&
                    thisOppAccount.VAT_Validation_Status__c != 'Verified' &&
                    o.VAT_Number__c != null) {
                        thisOppAccount.VATId__c = o.VAT_Number__c;
                        thisOppAccount.VAT_Validation_Status__c = o.VAT_Validation_Status__c;
                        DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{
                            Account.VATId__c, Account.VAT_Validation_Status__c
                                });
                    }
                // Need to make sure variables are set properly for the commissionable dollars field to work, at least until we run a mass update on historical closed won opps so we can change that formula field)
                // For new internal financing, just uncomment the line below and delete the if(o.internal_finance__c = 'approved') part.
                o.Internal_Finance__c = 'Approved';
                if (o.Selected_Payment_Type__c == 'Direct Monthly') {
                    o.Direct_Monthly__c = TRUE;
                    o.Direct_Annual__c = FALSE;
                    o.Direct_Quarterly__c = FALSE;
                } else if (o.Selected_Payment_Type__c == 'Direct Quarterly') {
                    //GTMS-13035 - DirectQuarterly
                    o.Direct_Quarterly__c = TRUE;
                    o.Direct_Monthly__c = FALSE;
                    o.Direct_Annual__c = FALSE;
                } else if (o.Selected_Payment_Type__c == 'Direct Annual') {
                    o.Direct_Monthly__c = FALSE;
                    o.Direct_Quarterly__c = FALSE;
                    o.Direct_Annual__c = TRUE;
                } else {
                    o.Direct_Monthly__c = FALSE;
                    o.Direct_Annual__c = FALSE;
                    o.Direct_Quarterly__c = FALSE;
                }
                if (o.Probability < 98) {
                    o.ACV_Commissionable_Dollars_Copy__c = o.ACV_Commissionable_Dollars__c;
                }
            }
            // Stamp ACV Bookings Copy
            if (o.ACV_Bookings_Copy__c != o.ACV_Bookings_SOT__c && o.CloseDate >= Date.valueOf(SYSTEM.Label.Annualize_ACV_Date)) {
                o.ACV_Bookings_Copy__c = o.ACV_Bookings_SOT__c;
            }
            // Stamp finance approved amount, if necessary
            if (o.Probability >= 95 && o.Finance_Approved_Amount_Stamp__c == NULL) {
                o.Finance_Approved_Amount_Stamp__c = o.Amount;
            }
            if (o.Small_Fleet_Opportunity__c == TRUE && o.Express_Annual_Discount__c > 0 && o.StageName !='Closed Won') {
                o.Express_Annual_Discount__c = 0;
            }
            if (o.Small_Fleet_Opportunity__c == TRUE && o.Express_Upfront_Discount__c > 0 && o.StageName !='Closed Won') {
                o.Express_Upfront_Discount__c = 0;
            }
            //Satya-GTMS-5905
            if (o.Price_Book_Name__c <> null && o.StageName !='Closed Won') {
                if (o.Configuration_Segment__c == 'Express' && !o.Small_Fleet_Opportunity__c ) {
                    o.Express_Upfront_Discount__c = 15;
                    o.Express_Annual_Discount__c = 10;
                }
                if(o.Configuration_Segment__c == 'Express' && (thisOppAccount.Number_of_Vehicles__c != NULL && thisOppAccount.Number_of_Vehicles__c < 11) && (o.AG2_License_Count__c + o.AG4_License_Count__c) < 31 ||
                   (o.Configuration_Segment__c == 'Express' && (o.CM1_License_Count__c + o.CM2_License_Count__c) == 0 && o.VG_License_Count__c == 0 && (o.AG2_License_Count__c + o.AG4_License_Count__c) < 31)) {
                       o.Express_Upfront_Discount__c = 0;
                       o.Express_Annual_Discount__c = 0;
                   }
            }
            if (o.Type == 'Revenue Opportunity' && o.IsWon == TRUE && o.Amount > 0) {
                if (thisOppAccount.First_Purchase_Value__c == NULL) {
                    thisOppAccount.First_Purchase_Value__c = o.Amount;
                    DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{
                        Account.First_Purchase_Value__c
                            });
                }
            }
            Opportunity vOpportunity = new Opportunity();
            if(o.Id != null){
                vOpportunity = opportunitiesDataByIds.get(o.Id);
            }else if(o.Returning_Opportunity__c != null){
                vOpportunity = opportunitiesDataByIds.get(o.Returning_Opportunity__c);
            }else if(o.Id == null){
                vOpportunity = o;
            }    
            
            //added by KrishnaRao GTMS-25417
            Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
           If((o.Type != 'Remorse Refund'
                && (o.Type != 'Rebate' || o.Rebate_Type__c != 'Delinquent') //GTMS-29333: Shifted Rebate Delinquent and Remorse Refund copy field logic to ReturnOwnerCopyDataUtility
                && vOpportunity != null && o.Id == null
                && vOpportunity.Rebate_Type__c != 'Partner Referral'
                && vOpportunity.Rebate_Type__c != 'Renewal Credit')
               || vOpportunity.Overwrite_Validation_Rule__c) 
            {
                        o.Owner_Manager_Name_Copy__c = (Id) managerFormula(o, vOpportunity, 'Manager Name');
                        o.Owner_Manager_Role_Copy__c = (String) managerFormula(o, vOpportunity, 'Manager Role');
                        o.Owner_Director_Name_Copy__c = (Id) managerFormula(o, vOpportunity, 'Director Name');
                        o.Owner_Manager_Email_Copy__c = (String) managerFormula(o, vOpportunity, 'Manager Email');

                        /*  Added this as part of GTMS-28160. We are adding this temoprarily. We have initialted the discussion on the 
                            owner copy fields logic with the BA team. Once we have the proper requirement finalised, we will refactor 
                            this whole piece which is populating any owner realted copy fields - HG - 12th Aug, 2025 - START 
                        */
                        o.Owner_AVP_Team__c = (String) managerFormula( o, vOpportunity, 'DirectorsManagersSalesUserType' );
                    }
            
            //GTMS-29333: Updating copy fields on Rebate and Remorse Refund Return Opportunity
            Opportunity revOpp = opportunitiesDataByIds.containsKey(o.Returning_Opportunity__c) ? opportunitiesDataByIds.get(o.Returning_Opportunity__c) : null;
            //Checking bypassForCopyDataMechanism as false, so return copy fields are not updated again once owner is changed from RelatedReturnOpportunityController
            If(!OpportunityTriggerHandlerContext.bypassForCopyDataMechanism && revOpp != null) {
                OrderFinanceHelper.updateOppCopyDataContra(o, oldOpportunity, revOpp, mapUsers, Trigger.isInsert);
            }
            
            if (vOpportunity != null && o.Id != null) {
                if (vOpportunity.Type == 'Rebate') {
                    if(vOpportunity.Rebate_Type__c != null && System.Label.Rebate_Close_Date.contains(vOpportunity.Rebate_Type__c) && vOpportunity.StageName == 'Refunded - Closed'){
                        o.CloseDate = vOpportunity.Returning_Opportunity__r.CloseDate;
                    }
                    //GTMD-8640, 8059
                    if (!cwRoboIds.contains(UserInfo.getUserId()) && vOpportunity.Returning_Opportunity__r.Referral_Partner__c != null) {
                        o.Referral_Partner__c = o.Referral_Partner__c != null ? o.Referral_Partner__c : vOpportunity.Returning_Opportunity__r.Referral_Partner__c;
                        //GTMS-13490==START
                        o.Referral_Rebate__c = vOpportunity.Returning_Opportunity__r.Referral_Partner__r.Referral_Rebate__c;
                        //GTMS-13490==END
                    }
                    //GTMS-8640, 8059
                    if (!cwRoboIds.contains(UserInfo.getUserId()) && vOpportunity.Returning_Opportunity__r.Insurance_Partner__c != null) {
                        o.Insurance_Partner__c = vOpportunity.Returning_Opportunity__r.Insurance_Partner__c;
                    }
                }
                //GTMS-15132
                if (((o.Type == 'Rebate' && o.Rebate_Type__c == 'Delinquent' ) || o.Type == 'Remorse Refund')
                    && o.StageName == 'Refunded - Closed'
                    && (o.Returning_Opportunity__r == null || vOpportunity.Returning_Opportunity__r.Owner.Name != 'Samsara Small Fleets')
                    && o.Delinquent_Return_Past_180_Days__c){
                        if(vOpportunity.Returning_Opportunity__c != null && vOpportunity.Returning_Opportunity__r.Owner.UserRole.Name.Contains('Renewal')){
                            o.OwnerId = gvLabelUserId.get('Renewal');
                        }
                        else if(vOpportunity.Returning_Opportunity__c != null && vOpportunity.Returning_Opportunity__r.Owner.UserRole.Name.Contains('EMEA')){
                            o.OwnerId = gvLabelUserId.get('EMEA');
                        }
                        else if(vOpportunity.Returning_Opportunity__c != null && vOpportunity.Returning_Opportunity__r.Owner.UserRole.Name.Contains('ENT')){
                            o.OwnerId = gvLabelUserId.get('ENT');
                        }
                        else if(vOpportunity.Returning_Opportunity__c != null && vOpportunity.Returning_Opportunity__r.Owner.UserRole.Name.Contains('Fleet IS')){
                            o.OwnerId = gvLabelUserId.get('Fleet IS');
                        }
                        else{
                            o.OwnerId = gvLabelUserId.get('Default');
                        }
                    }
                //Zakeer: added IF condition -- GTMS5381
                /* Replaces Node 'Shipping Country is Canada or Mexico' */
                if (o.Shipping_Address_NEW__c != null && o.Type != 'Free Trial Opportunity'){
                    string ShippingCountry = HelperClass.opportunityShippingAddresses.get(o.Shipping_Address_NEW__c).Shipping_Country__c;
                    if ((o.Shipping_Address_NEW__c != oldOppMap.get(o.Id).Shipping_Address_NEW__c || o.Shipping_Country__c != ShippingCountry || o.IsClone()) && !cwRoboIds.contains(UserInfo.getUserId())) {
                        if(o.Shipping_Country__c != ShippingCountry){
                            o.Shipping_Country__c = ShippingCountry;
                        }
                        HelperClass.setShippingDefaults(o, NULL, shippingCountry);
                    }
                }
                if (vOpportunity.Shipping_Address_NEW__r.Shipping_Country__c == 'Canada'
                    && vOpportunity.Probability <= 95
                    && (vOpportunity.Shipping_Country__c != 'Canada')) {
                        o.Shipping_Country__c = 'Canada';
                        o.Shipping_Method__c = 'Ground';
                    }
                if(HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.Product_Count__c)
                   && o.Product_Count__c > oldOpportunity.Product_Count__c
                   && oldOpportunity.StageName == 'Incubate'){
                       o.StageName = 'Qualified';
                   }
                /* Sonal: Changed on 9th April, 2020 Replaces Node 'Express Amount Agreed To' */
                if (o.Express_Agreement_Accepted_Date__c != null) {
                    o.Contract_Amount_Agreed_To__c = vOpportunity.Amount;
                }
                /* Replaces Node 'Express Discount is Added to Blended Discount' */
                //TODO - Ensure that we stamp the Discount Approval Needed
                // Anil Bogadi - GTMS-4994
                if (((vOpportunity.Selected_Payment_Type__c <> null && (vOpportunity.Selected_Payment_Type__c == 'Direct Annual' || vOpportunity.Selected_Payment_Type__c == 'Upfront Payments'))
                     || (vOpportunity.SBQQ__PrimaryQuote__c <> null && vOpportunity.SBQQ__PrimaryQuote__r.ApprovalStatus__c == 'Approved'))
                    && vOpportunity.Pricebook2.Name <> null && vOpportunity.Configuration_Segment__c == 'Express' && vOpportunity.CPQ_Opportunity__c == true ) {
                        if(vOpportunity.Blended_Discount__c !=  oldOpportunity.Blended_Discount__c){
                            o.Approved_Discount__c = vOpportunity.Blended_Discount__c + 0.1;
                        }
                        o.Discount_Approval_Status__c = 'Approved';
                    }
                /* Replaces Node 'New Billing Process Approval' */
                if ((vOpportunity.Price_Book_Name__c != null
                     && vOpportunity.Configuration_Segment__c == 'Express')
                    && vOpportunity.Payment_Token__c != null && vOpportunity.Probability >= 98 && !vOpportunity.IsClosed && !vOpportunity.Account.New_Billing_Process_Approved__c) {
                        thisOppAccount.New_Billing_Process_Approved__c = true;
                        DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{Account.New_Billing_Process_Approved__c});
                    }
                /* Replaces Node 'Stamp Manager On Stage Change' */
                
                if ((o.Type != 'Remorse Refund'
                     && (o.Type != 'Rebate' || o.Rebate_Type__c != 'Delinquent') //GTMS-29333: Shifted Rebate Delinquent and Remorse Refund copy field logic to ReturnOwnerCopyDataUtility
                     && vOpportunity.Rebate_Type__c != 'Partner Referral'
                     && vOpportunity.Rebate_Type__c != 'Renewal Credit'
                     && (HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.Probability) 
                         || vOpportunity.ownerId != o.ownerId)) 
                    || vOpportunity.Overwrite_Validation_Rule__c) 
                {
                    
                        o.Owner_Manager_Name_Copy__c = (Id) managerFormula(o, vOpportunity, 'Manager Name');
                        o.Owner_Manager_Role_Copy__c = (String) managerFormula(o, vOpportunity, 'Manager Role');
                    o.Owner_Director_Name_Copy__c = (Id) managerFormula(o, vOpportunity, 'Director Name');
                    //GTMS-26431 Copy Owner Director Email 
                    o.Owner_Director_Email_Copy__c = (String) managerFormula(o, vOpportunity, 'Director Email');
                    //o.Owner_Director_Role_Copy__c = (String) managerFormula(o, vOpportunity, 'Director Role');
                    //Zakeer-GTMS:5758-Mar3-2022
                    o.Owner_AVP_Name_Copy__c = (String) managerFormula(o, vOpportunity, 'DirectorsManagersName');
                    o.Owner_AVP_Role_Copy__c = (String) managerFormula(o, vOpportunity, 'DirectorsManagersRole');
                    //GTMS-17681 -- Start -- Added below logic to set Owner AVP team on oppty
                    o.Owner_AVP_Team__c = (String) managerFormula(o, vOpportunity, 'DirectorsManagersSalesUserType');
                    }
                /* Groundswell : Tanuj - WFlow Rule - Copy Owner Manager Email When Closing
* This rule copies the name of the owner's manager when opportunity is moved into closing
*/
                if((o.StageName == 'Closing'
                    || o.StageName == 'Refunded - Closed'
                    || o.StageName == 'Orders Processing')
                   && o.Owner_Manager_Email_Copy__c == null
                   && o.Type != 'Remorse Refund' //GTMS-29333: Shifted Rebate Delinquent and Remorse Refund copy field logic to ReturnOwnerCopyDataUtility
                   && (o.Type != 'Rebate' || o.Rebate_Type__c != 'Delinquent'))
                {
                       o.Owner_Manager_Email_Copy__c = (String) managerFormula(o, vOpportunity, 'Manager Email');
                   }
                /* Replaces Node 'Stamp Geo On Stage Change' */
                if ((vOpportunity.Rebate_Type__c != 'Partner Referral'
                     && vOpportunity.Rebate_Type__c != 'Renewal Credit'
                     && vOpportunity.Probability <= 95
                     && (HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.Probability)
                         || vOpportunity.Owner_Geo_Copy__c != vOpportunity.Owner.Territory__c))
                    || vOpportunity.Overwrite_Validation_Rule__c) {
                        o.Owner_Geo_Copy__c = extractOwnerGeographyCopy(vOpportunity);
                    }
                if(oldOppMap.get(o.Id).Payment_Terms__c != o.Payment_Terms__c && o.Payment_Terms__c != NULL && o.Payment_Terms__c != o.Initial_Payment_Terms__c) {
                    o.Initial_Payment_Terms__c = o.Payment_Terms__c;
                }
                //Commented as part of GTMS-28446  (Will sync this field from primary quote)
                /*if (o.SBQQ__PrimaryQuote__c == null &&
                    o.Shipping_and_Handling__c != null && o.Shipping_and_Handling__c > 0 && o.Shipping_and_Handling__c != 99999.99
                    && o.Sales_Tax_Rate_NEW__c != null && o.Sales_Tax_Rate_NEW__c > 0 && o.Sales_Tax_Rate_NEW__c < 100
                    && ((o.Shipping_Country__c != null && !(shippingAndHandlingTaxLocations.contains(o.Shipping_Country__c))))) {
                        o.S_H_Tax__c = o.Shipping_and_Handling__c * (o.Sales_Tax_Rate_NEW__c / 100);
                    } else {
                        o.S_H_Tax__c = 0;
                    }*/
            }
            if(Trigger.isInsert || (HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.Owner_Role_Copy__c )) || o.Probability >= 90) {
                String ownerSegment;
                if(o.Id != null && o.Returning_Opportunity__c != null){
                    ownerSegment = opportunitiesDataByIds.get(o.Id).Returning_Opportunity__r.Owner_Segment__c;
                }else if(o.Returning_Opportunity__c != null){
                    ownerSegment = opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Segment__c;
                    /*o.Owner_Manager_Name_Copy__c = opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Manager_Name_Copy__c;
o.Owner_Manager_Role_Copy__c = opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Manager_Role_Copy__c;
o.Owner_Director_Role_Copy__c = opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Director_Role_Copy__c;
o.Owner_Director_Name_Copy__c = opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Director_Name_Copy__c;
o.Owner_Manager_Email_Copy__c =  opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Manager_Email_Copy__c;*/
                    
                }
                if(o.Owner_Segment__c != 'Other' && !String.isBlank(o.Owner_Segment__c)) {
                    o.Bookings_Owner_Segment__c  = o.Owner_Segment__c;
                }
                else if(o.Returning_Opportunity__c != Null && ownerSegment != 'Other' && !String.isBlank(ownerSegment)) {
                    o.Bookings_Owner_Segment__c  = ownerSegment;
                }
                else {
                    if(oppAccounts.get(o.AccountId) != Null) o.Bookings_Owner_Segment__c  = oppAccounts.get(o.AccountId).Segment__c;
                }
                if((!o.IsClosed || o.Finance_Segment_Stamp__c == null) && o.Bookings_Owner_Segment__c != NULL){
                    /* Update Finance Segment Stamp Field */
                    IF(o.CloseDate <= date.newInstance(2021, 08, 06)){
                        o.Finance_Segment_Stamp__c = o.Finance_Segment_Stamp__c;
                    }else if(o.Bookings_Owner_Segment__c.contains('Small Business') || o.Bookings_Owner_Segment__c.contains('AE1')){
                        o.Finance_Segment_Stamp__c = 'SMB';
                    }else if(o.Bookings_Owner_Segment__c.contains('Enterprise')){
                        o.Finance_Segment_Stamp__c = 'Enterprise';
                    }else{
                        o.Finance_Segment_Stamp__c = 'Mid Market';
                    }
                }
            }
            //Need to assign oldOpportunity again as the value is only assigned if the opportunity is not closed.
            if (oldOppMap != null) {
                oldOpportunity = oldOppMap.get(o.Id);
                // Update the cross sell identifier and purchase type fields
                updateCrossSellIdentifier(o, oldOpportunity, thisOppAccount, opportunitiesDataByIds.get(o.Id)?.OpportunityLineItems);
                o.Shipping_and_Handling_Value__c = ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(null,o, opportunitiesDataByIds.get(o.Id)?.OpportunityLineItems);
                //o.Shipping_and_Handling_Value__c = ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(o, opportunitiesDataByIds.get(o.Id)?.OpportunityLineItems);
                if (oppAccounts.containsKey(o.AccountId) && oppAccounts.get(o.AccountId).CurrencyIsoCode == 'MXN' && o.RecordTypeId == recordTypeId && o.Returning_Opportunity__c != null && o.CurrencyIsoCode != 'MXN'&& (o.RecordTypeId != oldOpportunity.RecordTypeId  || o.Returning_Opportunity__c != oldOpportunity.Returning_Opportunity__c)) {
                    o.CurrencyIsoCode = opportunitiesDataByIds != null && opportunitiesDataByIds.containsKey(o.Returning_Opportunity__c) && opportunitiesDataByIds.get(o.Returning_Opportunity__c).CurrencyIsoCode == 'MXN' ? 'MXN' : o.CurrencyIsoCode;
                }
            }
            if(null != mapUsers && mapUsers.get(o.OwnerId) != null)
                OpportunityWorkflowConversion.beforeInsertUpdateMethod(o, oldOpportunity, vOpportunity, thisOppAccount, mapUsers.get(o.OwnerId));
            if(oldOpportunity.Id !=null){
                OpportunityWorkflowConversion.beforeUpdateMethod(o, oldOpportunity, mapUsers.get(o.OwnerId));
                // Code for new Renewal Process
                OpportunityProcessBuilderConversion.stampDataForAmendments(o, oppAccounts.get(o.AccountId), oldOpportunity);
                //GTMS-23000
                //OpportunityHelper.updateOpptyFromContractUsingWASD(o,contractsMap);
                updateOpptyFromContractUsingWASD(o,contractsMap);
            }
            //End
            //GTMS-25660
            if ((o.Type == 'Exchange' || o.Type == 'Warranty Exchange') && o.Shipping_Country__c == 'United States' && o.Shipmate_Preference__c == 'ShippingPreference-000029' && o.Shipmate_Preference_Override__c) {
                o.Shipmate_Service_Type__c  = 'ups_next_day_air';
            }
            if (o.Type == 'Warranty Exchange') {
                o.Comments__c = 'Product replaced under warranty, value for Customs purpose only';
            } else {
                o.Comments__c = null;
            }
        }
        updateAccountRecords();
    }

    public static Map<Id, Opportunity> queryOpportunities(Set<Id>
                                                          opportunityIds) 
    {
        Map<Id, Opportunity> opportunitiesDataByIds = new Map<Id, Opportunity>([
            SELECT Id, Name, CurrencyIsoCode,Pricebook2Id, Pricebook2.Name, Shipping_Address_NEW__c, Shipping_Address_NEW__r.Shipping_Country__c,
            Shipping_Country__c, Shipping_Method__c, Type, Returning_Opportunity__r.Reseller_Partner__c, Bookings_Owner_Segment__c,Returning_Opportunity__r.Referral_Partner__r.Referral_Rebate__c,//GTMS-13490
            Returning_Opportunity__r.Referral_Partner__c,Returning_Opportunity__r.Insurance_Partner__c,Insurance_Partner__c, StageName, Rebate_Type__c, Delinquent_Return_Past_180_Days__c,
            OwnerId, RecordType.Name, Stripe_Subscription_Id__c, Finance_Notes__c, Express_Agreement_Accepted_Date__c, Owner_Segment__c,
            Balance_Due__c, Rebate_Type_Formula__c, Returning_Opportunity__r.Buyout_Opportunity__c, Returning_Opportunity__r.Owner_Segment__c,Returning_Opportunity__r.Owner_Director_Role_Copy__c,
            Returning_Opportunity__r.Subsidy_Opportunity__c, Returning_Opportunity__c, Returning_Opportunity__r.License_Term__c, Returning_Opportunity__r.License_End_Date__c,
            Returning_Opportunity__r.Partner_Referral_Opportunity__c, Returning_Opportunity__r.CloseDate, Price_Book_Name__c, Payment_Token__c,
            First_Purchase__c, Probability, IsClosed, Account.New_Billing_Process_Approved__c, Resend_Return_Email__c, Configuration_Segment__c,
            Account.Overwrite_Validation_Rule__c, License_Term__c, CloseDate, IsWon, CPQ_Opportunity__c,SBQQ__AmendedContract__r.SBQQ__RenewalQuoted__c,
            License_Term_Approval_Status__c, License_End_Date__c, ContractId, Approved_Discount__c, License_Start_Date__c,
            Contract.EndDate, Contract.Original_Approved_Discount__c, Account.Latest_Active_Contract__c, Renewal__c, RecordTypeId,
            Segment_Sales_Role__c, Account.Latest_Active_Contract__r.Original_Approved_Discount__c,
            Account.Latest_Active_Contract__r.EndDate, netsuite_conn__Bill_To_Tier__c, netsuite_conn__Celigo_Contract__c,
            Selected_Payment_Type__c, Discount_Approval_Status__c, Blended_Discount__c, Trial_Primary_Contact__c,
            Trial_Primary_Contact__r.Trial_Deactivation_Email__c, ADR_Transfer__c,
            ADR_Transfer__r.ADR_Manager_Name_Copy_at_Qualification__c, ADR_Transfer__r.ADR_Transfer_Qualified_Date__c,
            ADR_Transfer__r.ADR_Transfer_By__r.ManagerId, ADR_Transfer__r.ADR_Role_Copy_at_Qualification__c,
            ADR_Transfer__r.ADR_Transfer_By__r.UserRole.Name, ADR_Transfer__r.ADR_Transfer_Status__c, Amount, Account.CSM__c,
            Account.CSM__r.FirstName, Account.CSM__r.LastName, Shipping_Instructions__c, Account_Approved_Payment_Type__c,Account.Payment_Terms__c,
            Account.Approved_Payment_Type__c, Owner_Manager_Name_Copy__c, Returning_Opportunity__r.Owner_Manager_Name_Copy__c,
            Owner.ManagerId, Owner.UserRole.Name, Owner_Role_Copy__c, Returning_Opportunity__r.Owner_Role_Copy__c, Owner_Director_Name_Copy__c,Owner_Director_Email_Copy__c,
            Owner.Manager.ManagerId, Returning_Opportunity__r.Owner_Director_Name_Copy__c,Returning_Opportunity__r.Owner_Director_Email_Copy__c, Owner_Manager_Role_Copy__c, Owner.Manager.Email, Returning_Opportunity__r.Owner_Manager_Email_Copy__c,
            Owner.Manager.UserRole.Name, Returning_Opportunity__r.Owner_AVP_Name_Copy__c, Owner_AVP_Name_Copy__c, Returning_Opportunity__r.Owner_AVP_Role_Copy__c, Owner_AVP_Role_Copy__c, Returning_Opportunity__r.Owner_Manager_Role_Copy__c, Overwrite_Validation_Rule__c,
            Contract_Amount_Agreed_To__c, Shipping_Address_NEW__r.Shipping_Contact__c, Owner.Manager.Manager.Level__c, Owner.Manager.Level__c,
            of_Serialized_Products__c, Shipping_Contact__c, Oppty_Owners_CSM__c,Returning_Opportunity__r.Owner.Name,
            Owner_Geo_Copy__c, Owner.Territory__c, Owner_Director_Role_Copy__c, Owner_Manager_Email_Copy__c,
            Returning_Opportunity__r.Id, Returning_Opportunity__r.Name, Returning_Opportunity__r.Owner.Territory__c, Owner.Level__c,
            Returning_Opportunity__r.Owner.Level__c, Returning_Opportunity__r.Owner_Director_Name_Copy__r.Id, Owner_Director_Name_Copy__r.Manager.Name, Owner_Director_Name_Copy__r.Manager.UserRole.Name,
            Account.Number_of_Vehicles__c, Owner.Manager.Manager.Manager.Name, Owner.Manager.Manager.Manager.UserRole.Name, Owner.Manager.Manager.Id, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.ApprovalStatus__c,
            netsuite_conn__From_Contract__r.Original_Approved_Discount__c, netsuite_conn__From_Contract__c,ACV_Bookings_SOT__c,SBQQ__PrimaryQuote__r.sbqq__mastercontract__c,
            SBQQ__PrimaryQuote__r.SBQQ__SalesRep__c,SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.ManagerId, SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.UserRole.Name,SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.Email,
            Returning_Opportunity__r.Owner.UserRole.Name,Owner.Manager.Sales_User_Type__c, Owner.Manager.Manager.Sales_User_Type__c, Owner.Manager.Manager.Manager.Sales_User_Type__c,
            Owner.Manager.Name, Owner.Manager.Manager.Name, Owner.Manager.Manager.UserRole.Name,Returning_Opportunity__r.Owner_AVP_Team__c, Returning_Opportunity__r.CurrencyIsoCode,
            (SELECT Id, Product_Type_Copy__c, Product_Code_Copy__c, Product2.Baseline_Cost__c, Ship_To__c, License_Term_Copy__c, Discount, Express_Upfront_Discount__c, Express_Annual_Discount__c, 
             Selected_Sales_Price__c, Express_Selected_Discount__c, UnitPrice,ProductCode, Quantity, Product2Id,Product2.ProductCode
             FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);
        system.debug('opportunitiesDataByIds ::::>'+opportunitiesDataByIds);
        return opportunitiesDataByIds;
    }
    
    //GTMS-9601
    public static Boolean doesLineItemContainsEOL(List<OpportunityLineItem> oppLineItems, Opportunity opp){
        system.debug('---In doesLineItemContainsEOL---'+oppLineItems.size());
        for(OpportunityLineItem oli : oppLineItems){
            if((oli.Product2.Product_Status__c == 'EOL' && !oli.Product2.CPQ_Enabled_Product__c) || (oli.ProductCode.contains('ACC-EI') && oppAccounts.get(opp.AccountId) != NULL)){
                system.debug('---In true---');
                return true;
            }
        }
        return false;
    }
    //GTMS-9601
    
    //DCA Logic Start
    public static String getDCAEnabled(Opportunity o){
        String dcaString='Non DCA';
        //List<String> roleList = system.Label.DCA_Phase_Two_Launch?.split(',');   
        if(o!=null && mapUsers!=null && mapUsers.containsKey(o.OwnerId) ){
            User oppOwner=mapUsers.get(o.OwnerId);
            if(  String.isNotBlank(System.Label.DCA_Enabled_Users) && 
               (System.Label.DCA_Enabled_Users.contains(o.OwnerId)|| getDcaEnabledForOpportunity(System.Label.DCA_Enabled_Users,oppOwner)
                /*(oppOwner.ManagerId!=null && System.Label.DCA_Enabled_Users.contains(oppOwner.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null && System.Label.DCA_Enabled_Users.contains(oppOwner.Manager.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && System.Label.DCA_Enabled_Users.contains(oppOwner.Manager.Manager.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.ManagerId!=null && System.Label.DCA_Enabled_Users.contains(oppOwner.Manager.Manager.Manager.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.Manager.ManagerId!=null && System.Label.DCA_Enabled_Users.contains(oppOwner.Manager.Manager.Manager.Manager.ManagerId))
*/
               )    
              )
            {
                dcaString='DCA';
            }else if(  String.isNotBlank(System.Label.DCA_Phase_Two_Launch_Users) && 
                     (System.Label.DCA_Phase_Two_Launch_Users.contains(o.OwnerId)|| getDcaEnabledForOpportunity(System.Label.DCA_Phase_Two_Launch_Users,oppOwner) )){
                         dcaString='DCA Phase Two';
                     }else if (oppOwner.UserRole.Name != null && String.isBlank(oppOwner.ContactId) && !oppOwner.UserRole.Name.contains('AE1') && !oppOwner.UserRole.Name.contains('Small Fleets') &&
                               oppOwner.Profile.Name != 'System Administrator' && oppOwner.Profile.Name != 'System Administrator API' &&
                               oppOwner.Profile.Name != 'Systems Automation' && oppOwner.Profile.Name != 'Samsara API Only'){
                                   dcaString='DCA Phase Three';
                               }
        }
        return dcaString;
    }
    public Static Boolean getDcaEnabledForOpportunity(String users ,User oppOwner){
        return ((oppOwner.ManagerId!=null && users.contains(oppOwner.ManagerId)) ||
                (oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null && users.contains(oppOwner.Manager.ManagerId)) ||
                (oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && users.contains(oppOwner.Manager.Manager.ManagerId)) ||
                (oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.ManagerId!=null && users.contains(oppOwner.Manager.Manager.Manager.ManagerId)) ||
                (oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.Manager.ManagerId!=null && users.contains(oppOwner.Manager.Manager.Manager.Manager.ManagerId)));
    }    
    //DCA Logic End
    
    //GTMS-23000
    public static void updateOpptyFromContractUsingWASD(Opportunity opp,Map<Id, Contract> contractsMapNew) {
        if(System.Label.WASD_Logic_Check.equalsIgnoreCase('true') && contractsMapNew != null && contractsMapNew.size()>0 && contractsMapNew.containsKey(opp.SBQQ__RenewedContract__c)
           && contractsMapNew.get(opp.SBQQ__RenewedContract__c).Weighted_Average_Start_Date__c != null){
               opp.License_Start_Date__c = contractsMapNew.get(opp.SBQQ__RenewedContract__c).Weighted_Average_Start_Date__c;
               if(opp.IsClosed==false){
                   if(opp.License_Start_Date__c >= date.today()){
                       opp.Adjust_License_Start_Date__c = true;
                   }else{
                       opp.Adjust_License_Start_Date__c = false;
                   }
               }
           } 
    }
    
    @testvisible
    private static String extractOwnerGeographyCopy(Opportunity newOpp) {
        List<String> opportunityTypes = new List<String>{
            'Revenue Opportunity', 'Free Trial Opportunity', 'Promo Opportunity', 'Rebate', 'Remorse Refund'
                };
                    if (opportunityTypes.contains(newOpp.Type)) {
                        return newOpp.Owner.Territory__c;
                    } else {
                        return newOpp.Returning_Opportunity__r.Owner.Territory__c;
                    }
    }
    
    @TestVisible
    //This method is used to update the Opportunity purchase type and cross sell identifier fields
    public static void updateCrossSellIdentifier(Opportunity newOpp, Opportunity oldOpp, Account acc, List<OpportunityLineItem> itemList){
        System.debug('updateCrossSellIdentifier');
        if (oldOpp == null || acc == null || itemList == null || itemList.size() <= 0) return;
        Boolean purchaseTypeHasChangedOrBlank = ((oldOpp.Purchase_Type__c != newOpp.Purchase_Type__c) || String.isBlank(newOpp.Purchase_Type__c));
        if (    newOpp.Type == 'Revenue Opportunity'
            &&((newOpp.StageName == 'Closed Won' && ((oldOpp.StageName != newOpp.StageName) || purchaseTypeHasChangedOrBlank))
               || (newOpp.SBQQ__PrimaryQuote__c != null && ((oldOpp.SBQQ__PrimaryQuote__c != newOpp.SBQQ__PrimaryQuote__c) || purchaseTypeHasChangedOrBlank)))
           ){
               //Account.First_Purchase_Date__c = CloseDate || ISBLANK(Account.First_Purchase_Date__c)
               if (acc.First_Purchase_Date__c == newOpp.CloseDate || acc.First_Purchase_Date__c == null){
                   newOpp.Purchase_Type__c = 'First Purchase';
               }else{
                   Boolean isCrossSell = false;
                   List<Product_Code_by_Type__mdt> prodByTypeMdt = Product_Code_by_Type__mdt.getAll().values();
                   for (OpportunityLineItem item : itemList){
                       if (String.isBlank(item.ProductCode)) continue;
                       if ((isCrossSell = checkForCrossSellOnOppItems(acc, item, prodByTypeMdt)) == true) break;
                   }
                   if (isCrossSell) newOpp.Purchase_Type__c = 'Cross-Sell';
                   else             newOpp.Purchase_Type__c = 'Add-On';
               }
           }else if (newOpp.StageName != 'Closed Won' && newOpp.SBQQ__PrimaryQuote__c == null && newOpp.Purchase_Type__c != null){
               newOpp.Purchase_Type__c = '';
           }
    }
    
    public void updateAccountRecords() {
        if (accountUpdateMap.values().size() > 0) {
            List<Account> accounts = new List<Account>();
            accounts.addAll(accountUpdateMap.values());
            accountUpdateMap.clear();
            DMLWrapper.doUpdate(accounts);
        }
    }
    @TestVisible
    private static Boolean checkForCrossSellOnOppItems(Account acc, OpportunityLineItem item, List<Product_Code_by_Type__mdt> prodByTypeMdt){
        Boolean isCrossSell = false;
        for (Product_Code_by_Type__mdt mdt : prodByTypeMdt){
            Decimal purchasedInAccount = (
                mdt.Product_Type__c == 'AG' ? acc.Total_Purchased_AG_Count__c :
                mdt.Product_Type__c == 'CM' ? acc.Total_Purchased_CM_Count__c :
                mdt.Product_Type__c == 'VG' ? acc.Total_Purchased_VG_Count__c :
                mdt.Product_Type__c == 'EM' ? acc.Total_Purchased_EM_Count__c :
                null
            );
            System.debug('purchasedInAccount'+purchasedInAccount);
            if ((item.ProductCode.startsWith(mdt.Product_Code_Prefix__c) && purchasedInAccount == 0 )|| acc.Cross_Sell__c){
                isCrossSell = true;
                break;
            }
        }
        return isCrossSell;
    }
    
    //GTMS-13689 //GTMS -19921 adding new changes related to this Jira
    @testvisible
    private Object managerFormula(String managerType, Opportunity newOpportunity, Opportunity oppty) {
        return managerFormula(newOpportunity, oppty, managerType);
    }
    @testvisible private static Object managerFormula(Opportunity newOpportunity, Opportunity oppty, String managerType) {
        Object returnObject = null; 
        User opportunityOwner = mapUsers.containsKey(newOpportunity.ownerId) ? mapUsers.get(newOpportunity.ownerId) : null;//GTMS - 19921
        if (oppty.Type == 'Revenue Opportunity' || oppty.Type == 'Free Trial Opportunity'
            || oppty.Type == 'Promo Opportunity' || ((oppty.Type == 'Rebate' || oppty.Type == 'Remorse Refund')
                                                     && opportunityOwner != null && opportunityOwner.Level__c != null && oppty.Returning_Opportunity__c != null && oppty.Returning_Opportunity__r.Owner.Level__c != null
                                                     && opportunityOwner.Level__c.equals('AE 1') && oppty.Returning_Opportunity__r.Owner.Level__c.equals('AE 1'))) {
                                                         switch on managerType {
                                                             when 'Manager Name' {
                                                                 if(oppty.Owner_Role_Copy__c <> null && (oppty.Owner_Role_Copy__c.contains('Regional') || oppty.Owner_Role_Copy__c.contains('Rover')) && oppty.SBQQ__PrimaryQuote__c <> null && oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__c <> null){
                                                                     returnObject = oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.ManagerId;
                                                                 }else{
                                                                     returnObject = opportunityOwner.ManagerId;
                                                                 }
                                                             }
                                                             when 'Manager Role' {
                                                                 if(oppty.Owner_Role_Copy__c <> null && (oppty.Owner_Role_Copy__c.contains('Regional') || oppty.Owner_Role_Copy__c.contains('Rover')) &&oppty.SBQQ__PrimaryQuote__c <> null && oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__c <> null){
                                                                     returnObject = oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.UserRole.Name;
                                                                 }else{
                                                                     returnObject = opportunityOwner.Manager.UserRole.Name;
                                                                 }
                                                             }
                                                             when 'Director Name' {
                                                                 if(opportunityOwner.Manager.Manager.Level__c != null && opportunityOwner.Manager.Manager.Level__c.contains('ISD')){
                                                                     returnObject = opportunityOwner.Manager.ManagerId;
                                                                 }
                                                                 else if(opportunityOwner.Manager.Level__c != null && opportunityOwner.Manager.Level__c.contains('ISD')){
                                                                     returnObject = opportunityOwner.ManagerId;
                                                                 }
                                                                 else{
                                                                     returnObject = opportunityOwner.Manager.ManagerId;
                                                                 }
                                                             }
                                                             //GTMS-26431 Copy Owner Director Email
                                                             when 'Director Email' {
                                                                 if(opportunityOwner.Manager.Manager.Level__c != null && opportunityOwner.Manager.Manager.Level__c.contains('ISD')){
                                                                     returnObject = opportunityOwner.Manager.Email;
                                                                 }
                                                                 else if(opportunityOwner.Manager.Level__c != null && opportunityOwner.Manager.Level__c.contains('ISD')){
                                                                     returnObject = opportunityOwner.Email;
                                                                 }
                                                                 else{
                                                                     returnObject = opportunityOwner.Manager.Email;
                                                                 }
                                                             }
                                                             when 'Manager Email' {
                                                                 if(oppty.Owner_Role_Copy__c <> null && (oppty.Owner_Role_Copy__c.contains('Regional') || oppty.Owner_Role_Copy__c.contains('Rover')) && oppty.SBQQ__PrimaryQuote__c <> null && oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__c <> null){
                                                                     returnObject = oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.Email;
                                                                 }else{
                                                                     returnObject = opportunityOwner.Manager.Email;
                                                                 }
                                                             }
                                                             when 'DirectorsManagersName' {
                                                                 if(opportunityOwner.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != NULL){
                                                                     //returnObject = opportunityOwner.Manager.Manager.Manager.Name;
                                                                     returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Name : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Name :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.Name :''));
                                                                         }
                                                             }
                                                             when 'DirectorsManagersRole' {
                                                                 if(opportunityOwner.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != NULL){
                                                                     //returnObject = opportunityOwner.Manager.Manager.Manager.UserRole.Name;
                                                                     returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.UserRole.Name : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.UserRole.Name :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.UserRole.Name :''));
                                                                         }
                                                             }
                                                             //GTMS-17681 -- Start -- Added logic to set Sales_User_Type__c of User's Manager and their manager by checking if Sales_User_Type__c not blank and set it to Owner_AVP_Team__c  on Oppty
                                                             when 'DirectorsManagersSalesUserType' {
                                                                 if(opportunityOwner.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != NULL){
                                                                     returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Sales_User_Type__c : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Sales_User_Type__c :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c :''));
                                                                         }
                                                             }
                                                             //GTMS-17681 -- End
                                                         }
                                                     }else if((newOpportunity.Type == 'Rebate'
                                                               || newOpportunity.Type == 'Remorse Refund')
                                                              && managerType == 'Manager Email'){
                                                                  switch on managerType {
                                                                      when 'Manager Email' {
                                                                          returnObject = oppty.Returning_Opportunity__r.Owner_Manager_Email_Copy__c;
                                                                      }
                                                                  }
                                                              } else {
                                                                  switch on managerType {
                                                                      when 'Manager Name' {
                                                                          returnObject = oppty.Returning_Opportunity__r.Owner_Manager_Name_Copy__c;
                                                                      }
                                                                      when 'Manager Role' {
                                                                          returnObject = oppty.Returning_Opportunity__r.Owner_Manager_Role_Copy__c;
                                                                      }
                                                                      when 'Director Name' {
                                                                          returnObject = oppty.Returning_Opportunity__r.Owner_Director_Name_Copy__c;
                                                                      }
                                                                      //GTMS-26431 Copy Owner Director Email
                                                                      when 'Director Email' {
                                                                          returnObject = oppty.Returning_Opportunity__r.Owner_Director_Email_Copy__c;
                                                                      }
                                                                      when 'DirectorsManagersName' {
                                                                          if(oppty.Returning_Opportunity__r.Owner_AVP_Name_Copy__c != NULL){
                                                                              returnObject = oppty.Returning_Opportunity__r.Owner_AVP_Name_Copy__c;
                                                                          } else if(opportunityOwner.Manager.Manager.Manager != NULL){
                                                                              //returnObject = opportunityOwner.Manager.Manager.Manager.Name;
                                                                              returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Name : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Name :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.Name :''));
                                                                                  }
                                                                      }
                                                                      when 'DirectorsManagersRole' {
                                                                          if(oppty.Returning_Opportunity__r.Owner_AVP_Role_Copy__c != NULL){
                                                                              returnObject = oppty.Returning_Opportunity__r.Owner_AVP_Role_Copy__c;
                                                                          } else if(opportunityOwner.Manager.Manager.Manager.UserRole != NULL) {
                                                                              //returnObject = opportunityOwner.Manager.Manager.Manager.UserRole.Name;
                                                                              returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.UserRole.Name : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.UserRole.Name :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.UserRole.Name :''));
                                                                                  }
                                                                      }
                                                                      //GTMS-17681 -- Start -- Added logic to set Sales_User_Type__c of User's Manager and their manager by checking if Sales_User_Type__c not blank and set it to Owner_AVP_Team__c  on Oppty
                                                                      when 'DirectorsManagersSalesUserType' {
                                                                          if(oppty.Returning_Opportunity__r.Owner_AVP_Team__c != NULL){
                                                                              returnObject = oppty.Returning_Opportunity__r.Owner_AVP_Team__c;
                                                                          } else if(opportunityOwner.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != NULL){
                                                                              returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Sales_User_Type__c : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Sales_User_Type__c :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c :''));
                                                                                  }
                                                                      }
                                                                  }
                                                              }
        return returnObject;
    }
    
    public void getOpptyOwner(Set<Id> userIds){
        if(mapUsers == null || !(mapUsers.keySet().containsAll(userIds))){
            mapUsers = new Map<Id, User>([SELECT Email, UserRole.Name, profileId, profile.name, contactId, Manager.Email, Manager.Manager.Email, Manager.Name, Manager.UserRole.Name, Level__c, Business_Unit__c, Segment__c, IsActive,
                                          ManagerId,Manager.ManagerId,Manager.Manager.ManagerId,Manager.Manager.Manager.ManagerId,Manager.Manager.Manager.Manager.ManagerId,Manager.Manager.Name,Manager.Manager.Manager.Name,Manager.Manager.Manager.Manager.Name, Manager.Manager.Manager.UserRole.Name,Manager.Sales_User_Type__c,Manager.Manager.Manager.Sales_User_Type__c,
                                          Manager.Manager.Sales_User_Type__c,Manager.Manager.UserRole.Name,Manager.Manager.Level__c,Manager.Level__c FROM User where Id IN : userIds]);
        }
    }
    
    public void loadContracts(Set<Id> contractIds){
        // No cache is being made so it will refresh at every recursion and avoid null pointers.
        contractsMap = new Map<Id, Contract>([SELECT Id, StartDate, EndDate, ContractNumber, Auto_Renewal__c, Original_Reseller_ID__c,SBQQ__Opportunity__r.Insurance_Partner__c,
                                              SBQQ__Opportunity__r.Referral_Partner__c, SBQQ__Opportunity__r.Reseller_Partner__c,Contract_Renewable_ACV_USD__c,
                                              SBQQ__Opportunity__r.Shipping_Contact__c, SBQQ__Opportunity__r.Payment_Terms__c, SBQQ__Opportunity__r.Selected_Payment_Type__c,
                                              SBQQ__Opportunity__r.Approved_Discount__c, SBQQ__Opportunity__r.Reseller__c, SBQQ__Opportunity__r.Finance_Partner__c,
                                              SBQQ__Opportunity__r.Shipping_Address_NEW__c, SBQQ__Opportunity__r.OwnerId, SBQQ__Opportunity__c, Account.Name, Weighted_Average_Start_Date__c
                                              FROM Contract WHERE Id IN :contractIds]);
    }
    
    //GTMS-9601
    public static Boolean validateOppForHWProducts(List<OpportunityLineItem> oppLineItems, Opportunity opp, Map<Id, Opportunity> oldOppMap, List<String> profileIdsForHwAG4ValdiationRule, List<String> returnOppTypes){
        if(opp.probability < 90 &&
           oldOppMap!=null && opp.stageName != oldOppMap.get(opp.Id).stageName &&
           doesLineItemContainsEOL(oppLineItems, opp) &&
           !profileIdsForHwAG4ValdiationRule.contains(UserInfo.getProfileId())  &&
           !returnOppTypes.contains(opp.Type)
          ){
              return true;
          }
        return false;
    }
    
    //GTMS-21691: Start
    private static Boolean KeyAccountEligible(List<OpportunityLineItem> oppLineItems){
        for(OpportunityLineItem oli : oppLineItems){
            if(oli.Product2.Key_Account_Eligible__c == true){
                return true;
            }
        }
        return false;
    } 
    
    private void setOpportunityTypeForFreeTrials(List<Opportunity> oppList){
        if(oppList==null){
            return;
        }
        Map<Id,Opportunity> amendContracts = new Map<Id, Opportunity>();
        for(Opportunity o:oppList){
            if(o.SBQQ__AmendedContract__c!=null){
                amendContracts.put(o.SBQQ__AmendedContract__c,o);
            }
        }
        if(amendContracts.isEmpty()){
            return;
        }
        //Better to create utility method to get the recordtype id.
        Id contractRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Free_Trial').getRecordTypeId();
        Id opportunityTrialRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Trial').getRecordTypeId();
        if(String.isBlank(contractRecordTypeId)|| String.isBlank(opportunityTrialRecordTypeId)){
            return;
        }
        for(Contract con : [Select id,Opportunity_Type__c from Contract where RecordTypeId = :contractRecordTypeId and id IN :amendContracts.keySet()]){
            Opportunity freeTrialOpportunity = amendContracts.get(con.id);
            if(freeTrialOpportunity!=null){
                freeTrialOpportunity.RecordTypeId = opportunityTrialRecordTypeId;
                freeTrialOpportunity.Type = con.Opportunity_Type__c;
            }
        }
    }
    
    //added this condition for GTMS-10997
    public Map<String, String> getCanadaShipFrom() {
        Map<String, String> mapCanadaState = new Map<String, String>();
        String ShippingStateMapping = Shipping_Countries__mdt.getInstance('Canada')?.Shipping_State_Mapping__c;
        if(ShippingStateMapping != null) {
            List<String> strArr = ShippingStateMapping.split('\\*');
            List<String> dclla = strArr[0].split('\\@');
            if(dclla != null) {
                for(String s : dclla[0].split('\\;')) {
                    mapCanadaState.put(s, dclla[1]);
                }
            }
            List<String> dclky = strArr[1].split('\\@');
            if(dclky != null) {
                for(String s : dclky[0].split('\\;')) {
                    mapCanadaState.put(s, dclky[1]);
                }
            }
        }
        return mapCanadaState;
    }
    
    public void loadOppFields(Map<Id, Opportunity> oppMap) {
        if (oppFields == null || Test.isRunningTest()) {
            oppFields = new Map<Id, Opportunity>([
                SELECT Id, Owner.Email,Account.Owner.Email,OwnerId,Shipping_Address_NEW__r.Shipping_Contact__c,Shipping_Contact__c,Shipping_Contact__r.Id,Segment_Sales_Role__c,AccountId,SBQQ__AmendedContract__r.Contract_C_R_In_Progress__c,Upgraded_Opportunity_ID__c, Sub_Type__c, Account.Account_C_R_In_Progress__c, Account.Owner_Role__c, Amount, Type, StageName, Returning_Opportunity__r.Owner_Role_Copy__c, Configuration_Segment__c,Returning_Opportunity__c,Returning_Opportunity__r.Renewal__c,Owner.Profile.Name,Renewal__c,Finance_Partner__c,Finance_Partner__r.Is_Finance_Partner_Active__c,
                Pricebook2.Name, Pricebook2Id, CurrencyISOCode,Customer_require_PO_for_invoicing__c,Account.Customer_require_PO_for_invoicing__c, Owner.UserRole.Name, Owner.Manager.Name,Owner.Manager.Manager.Manager.Name, Owner.Manager.Manager.Manager.UserRole.Name, Ship_From_Location__c,
                SBQQ__PrimaryQuote__c,SBQQ__PrimaryQuote__r.DCA_Validation__c, SBQQ__PrimaryQuote__r.Co_Term_Contract__c,SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate, SBQQ__PrimaryQuote__r.SBQQ__BillingCountry__c,/*GTMS-28039*/SBQQ__PrimaryQuote__r.SBQQ__Status__c, SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c, SBQQ__RenewedContract__r.Contract_Renewable_ACV_USD__c, account.Customer_ARR_Netsuite__c,
                Account.Segment__c,Account.Account_Size_Segment__c,/* GTMS- 29094*/Sites_ACV_Bookings__c,Unique_Shipping_Addresses__c,/* GTMS- 29094*/ Reseller__c, First_Purchase__c, SBQQ__AmendedContract__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, Processing_Type__c, Custom_Schedule__c, Stub_Payment__c, Selected_Payment_Type__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c, SBQQ__RenewedContract__r.Auto_Renewal__c,



Small_Fleet_Opportunity__c, Probability, IsClosed, SBQQ__PrimaryQuote__r.Billing_Ann_Date__c, Account.B360_Payment_Type__c, Account.Payment_Terms__c, Account.B360_ContractEndDate__c, SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Billing_360_Manual_Override__c,
                //OppoFlow Optimization
                Bypass_Validation_Rule_DateTime__c, Owner_Role_Copy__c,Went_to_Purchase__c, Replacement_Opportunity__c,
                Shipping_Contact_Email__c,Hold_Reason__c, Product_Version__c,License_Term__c, Owner_Manager_Email_Copy__c,
                //End OppFlow,
                (
                    SELECT Id, Description, Discount, ListPrice,
                    Name, OpportunityId, Product2Id,
                    PriceBookEntryId, ProductCode,
                    TotalPrice, UnitPrice, Quantity, Product_Cost__c,
                    Other_Discount__c, Selected_Sales_Price__c, Express_Upfront_Discount__c, Express_Selected_Discount__c,
                    Express_Annual_Discount__c, Ship_To_Country__c, Ship_From_Location__c
                    , Product2.Product_Status__c, Product2.CPQ_Enabled_Product__c,Product2.Product_Type__c, //GTMS-9061
                    Product2.Key_Account_Eligible__c, //GTMS-21691
                    Product2.Family, ACV_Total_Price_Bookings__c, Related_Shipping_Address_Name__c // GTMS-29094
                    FROM OpportunityLineItems
                ), (
                    SELECT Channel_Partner__c, Channel_Partner__r.Partner_Status__c, Channel_Partner__r.RecordType.Name,
                    Channel_Partner__r.Business_Unit__c
                    FROM Channel_Relationships__r
                    LIMIT 1
                ), (
                    SELECT Id FROM Orders
                ),
                (SELECT Id,Primary_Quote__c,dsfs__Opportunity__c,Customer_require_PO_for_invoicing__c,PO_Number__c from  R00N80000002fD9vEAE where Envelope_Type__c != 'Rebate Document' AND dsfs__Envelope_Status__c = 'Completed' order by lastModifiedDate desc),
                (SELECT Id, Type, Trial_Status__c FROM Opportunities__r),
                (SELECT Id, Name, Flex_Is_Rebook__c FROM ReplacementContracts__r LIMIT 1),
                (SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c, SBQQ__Opportunity2__r.SBQQ__AmendedContract__c, SBQQ__StartDate__c, OwnerId FROM SBQQ__Quotes2__r),
                //                (SELECT Id, Name, CloseDate, StageName, OwnerId, Upgraded_Opportunity_ID__c,SBQQ__AmendedContract__c, Upgraded_Opportunity__r.StageName, Sub_Type__c, AccountId, (SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c, SBQQ__StartDate__c, OwnerId, SBQQ__Opportunity2__r.SBQQ__AmendedContract__c, SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.Flex_Is_Rebook__c FROM SBQQ__Quotes2__r) FROM Opportunities4__r)
                (SELECT Id, Revenue_Opportunity__c, Revenue_Opportunity__r.CloseDate, Revenue_Opportunity__r.StageName, Revenue_Opportunity__r.OwnerId, Revenue_Opportunity__r.Sub_Type__c , Revenue_Opportunity__r.AccountId,
                 Cancelation_Opportunity__c,Cancelation_Opportunity__r.CloseDate, Cancelation_Opportunity__r.StageName, Cancelation_Opportunity__r.OwnerId , Cancelation_Opportunity__r.SBQQ__AmendedContract__c, Cancelation_Opportunity__r.Sub_Type__c , Cancelation_Opportunity__r.AccountId,Cancelation_Opportunity__r.Upgraded_Opportunity_ID__c, 
                 (Select Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c, SBQQ__StartDate__c, OwnerId, SBQQ__Opportunity2__r.SBQQ__AmendedContract__c, SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.Flex_Is_Rebook__c From RelatedQuotes__r) From Related_Opportunities__r) 
                FROM Opportunity
                WHERE Id
                IN :oppMap.keyset()
            ]);
        }
    }
    
    public void loadOppFields(List<Opportunity> lstOpp) {
        Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>();
        for (Opportunity opp : lstOpp) {
            mapOpp.put(opp.Id, opp);
        }
        if (!mapOpp.isEmpty()) {
            loadOppFields(mapOpp);
        }
    }
    
    public static void loadOppAccountIds(List<Opportunity> oppList) {
        if (oppAccountIds == null) {
            oppAccountIds = new Set<Id>();
            for (Opportunity o : oppList) {
                oppAccountIds.add(o.AccountId);
                //GTMS-13490===START
                if(o.Referral_Partner__c != null){oppAccountIds.add(o.Referral_Partner__c);}
                //GTMS-13490===END
                //GTMS-17232
                if(o.Finance_Partner__c != null){oppAccountIds.add(o.Finance_Partner__c);}
                if(o.Reseller__c != null){oppAccountIds.add(o.Reseller__c);}
                if(o.Insurance_Partner__c != null) {
                    oppAccountIds.add(o.Insurance_Partner__c);
                }
                //GTMS-17232 === END
            }
        }
    }
    
    public static void loadOppAccounts(List<Opportunity> oppList) {
        if (oppAccounts == null) {
            loadOppAccountIds(oppList);
            oppAccounts = new Map<Id, Account>([
                SELECT Id, Name, Account_C_R_In_Progress__c, Free_Trial_Kit_Sent_Date__c, Segment__c, Number_of_Vehicles__c,CurrencyIsoCode,Payment_Terms__c,Owner.UserRole.Name,Owner.CurrencyIsoCode,
                Welcome_Kit_Sent_Date__c, Segment_Text_stamped__c, Latest_Active_Contract__r.EndDate, Approved_Payment_Type__c,
                Billing_Email__c, BillingStreet,BillingCity, BillingPostalCode, Latest_Active_Contract__c, Book_of_Business__c,
                BillingCountry, Internally_Financed__c, Churn_Update_CC_Link__c, Which_written_language__c, IS_Named_Account__c,
                VAT_Validation_Status__c, BillingState, First_Purchase_Value__c, VATId__c, Status__c, First_Purchase_Date__c, Global_Geography__c,
                Partner_Status__c, RecordType.Name, Business_Unit__c, Critically_Escalated_Hardware_Returns__c, SLED_Account__c, Owner_Role__c,
                Netsuite_Id__c, Push_to_Netsuite__c ,Ownerid,Latest_Partner_Account_Interaction__c,Latest_Partner_Program_Interaction__c,
                Latest_Partner_Account_Interaction__r.OwnerId,Latest_Partner_Account_Interaction__r.Partner_Discount__c,Renewal_AE__c,Account_Size_Segment__c,
                Total_Purchased_AG_Count__c, Total_Purchased_CM_Count__c, Total_Purchased_VG_Count__c, Total_Purchased_EM_Count__c, Referral_Rebate__c,//GTMS-13490
                Cross_Sell__c,// P&P 2.0 for Enhanced Cross-Sell logic(PRO SKUS) 032724
                Customer_require_PO_for_invoicing__c, Account_Lifetime_ACV__c,Current_Monthly_Payments__c,Total_Open_Opp_Expected_Revenue__c,Highest_Probability_Open_Opportunity__c,Open_Opportunity__c, // GTMS-28914
                Billing_First_Name__c, Billing_Last_Name__c, Billing_Phone__c,/*GTMS-28039*/
                //OppFlow Optimization
                 CS_Tier__c,Timezone__c,SIC__c,LIC_CM1_PRO__c,LIC_CM2_PRO__c,
                //End OppFlow
                (
                    SELECT Id, Pricebook2.Name, Pricebook2Id,
                    CloseDate, StageName, Sub_Type__c, Type
                    FROM Opportunities
                    ORDER BY CloseDate DESC
                ), (
                    SELECT id, Name, Shipping_Country__c
                    FROM Shipping_Addresses__r
                    ORDER BY LastModifiedDate desc
                    LIMIT 1
                )
                FROM Account
                WHERE Id
                IN :oppAccountIds
            ]);
        }
        // Filter by closed revenue oppties
        oppAccountsRev = new Map<Id, Account>(oppAccounts);
        for (Id accountId : oppAccountsRev.keySet()) {
            for (Integer i = oppAccountsRev.get(accountId).Opportunities.size() - 1; i >= 0; i--) {
                Opportunity oppty = oppAccountsRev.get(accountId).Opportunities[i];
                if (oppty.StageName != 'Closed Won' ||
                    oppty.Type != 'Revenue Opportunity') {
                        oppAccountsRev.get(accountId).Opportunities.remove(i);
                    }
            }
        }
    }
    
    public void populateFinacePartneronAccount(Map<Id,Opportunity> mapOldOpp, List<opportunity> newOppList){
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
    
      /**
     * @description Sets the Renewal Checkout Agreement Link based on comprehensive validation checks
     * Validates payment type, billing information, shipping requirements, and business rules
     * @param opportunity The opportunity record to update
     * @param relatedAccount The related account record
     * @param oppWithFields The opportunity record with related fields (including primary quote)
     * @author GTMS-28039
     */
    public void setRenewalCheckoutAgreementLink(Opportunity opportunity, Account relatedAccount, Opportunity oppWithFields) {

        SBQQ__Quote__c primaryQuote = (oppWithFields?.SBQQ__PrimaryQuote__r != null) ? 
                oppWithFields.SBQQ__PrimaryQuote__r : null;
        
        if (primaryQuote == null) {
            return;
        }

        // Initialize validation flags
        Boolean isEligibleForCheckoutLink = false;
        
        try {        

            // Define validation sets for contains checks (best practice: use Sets for O(1) lookup)
            Set<String> restrictedPaymentTypes = new Set<String>{'Direct Semi-Annual', 'Direct Quarterly'};
            Set<String> validNorthAmericaCountries = new Set<String>{'United States', 'Canada', 'Mexico'};
            Set<String> validEuropeanCountries = new Set<String>{
                'United Kingdom', 'France', 'Belgium', 'Germany', 'Netherlands', 
                'Ireland', 'Austria', 'Italy', 'Luxembourg', 'Switzerland'
            };
            Set<String> validEuropeanCurrencies = new Set<String>{'GBP', 'EUR'};
            Set<String> exemptShippingMethods = new Set<String>{
                'Ground', 'Next Day Air', 'MX Standard', 'MX Express', 'UK Standard', 'UK Express'
            };

            // Validation 1: Payment Type Checks (with null safety)
            Boolean paymentChecks = String.isNotBlank(opportunity.Selected_Payment_Type__c) && 
                !(String.isNotBlank(opportunity.Owner_Segment__c) && 
                  opportunity.Owner_Segment__c == 'AE1' && 
                  restrictedPaymentTypes.contains(opportunity.Selected_Payment_Type__c));

            // Validation 2: Basic Business Rules (with comprehensive null checks)
            Boolean basicChecks = relatedAccount != null && 
                primaryQuote != null &&
                opportunity.Reseller__c == null && // Reseller must be blank
                opportunity.Amount != null &&
                opportunity.Amount > 0 && // Opportunity ACV must be greater than 0
                String.isNotBlank(primaryQuote.SBQQ__Status__c) &&
                primaryQuote.SBQQ__Status__c == 'Approved' && // Quote must be approved
                String.isNotBlank(opportunity.Opportunity_UUID__c); // UUID required for link generation
            

            // Validation 3: Billing Information Completeness (with null safety for all fields)
            Boolean billingChecks = relatedAccount != null &&
                String.isNotBlank(opportunity.CurrencyIsoCode) &&
                String.isNotBlank(relatedAccount.CurrencyIsoCode) &&
                opportunity.CurrencyIsoCode == relatedAccount.CurrencyIsoCode && // Currency alignment
                String.isNotBlank(relatedAccount.Billing_First_Name__c) &&
                String.isNotBlank(relatedAccount.Billing_Last_Name__c) &&
                String.isNotBlank(relatedAccount.Billing_Email__c) &&
                String.isNotBlank(relatedAccount.Billing_Phone__c) &&
                String.isNotBlank(relatedAccount.BillingStreet) &&
                String.isNotBlank(relatedAccount.BillingCity) &&
                String.isNotBlank(relatedAccount.BillingPostalCode);

            Boolean validBillingLocation = false;
            if (relatedAccount != null && String.isNotBlank(relatedAccount.BillingCountry)) {
                if (String.isNotBlank(relatedAccount.BillingState) && 
                    validNorthAmericaCountries.contains(relatedAccount.BillingCountry)) {
                    validBillingLocation = true;
                }
                else if (String.isBlank(relatedAccount.BillingState) && 
                         String.isNotBlank(relatedAccount.CurrencyIsoCode) &&
                         validEuropeanCurrencies.contains(relatedAccount.CurrencyIsoCode) && 
                         validEuropeanCountries.contains(relatedAccount.BillingCountry)) {
                    validBillingLocation = true;
                }
            }
            Boolean shippingChecks1 = false;
            Boolean shippingChecks2 = false;
            //Added for GTMS - 29254
            // Apply shipping checks only if HW count > 0, otherwise bypass these checks
            if (opportunity.of_HW_Products__c == null || opportunity.of_HW_Products__c <= 0) {
                // No hardware products, bypass shipping checks
                shippingChecks1 = true;
                shippingChecks2 = true;
            } else {
                // Hardware products present, apply shipping validation checks
            if (opportunity.Multi_Line_Shipping__c == true && 
                opportunity.Shipping_and_Handling_Manual__c != null) {
                shippingChecks1 = true;
            }
            else if (opportunity.Multi_Line_Shipping__c == false) {
                shippingChecks1 = true; 
            }
            
            if (String.isNotBlank(opportunity.Shipping_Method__c) && 
                exemptShippingMethods.contains(opportunity.Shipping_Method__c)) {
                shippingChecks2 = true; 
            }else if((String.isBlank(opportunity.Shipping_Method__c)) || (String.isNotBlank(opportunity.Shipping_Method__c) && 
                !exemptShippingMethods.contains(opportunity.Shipping_Method__c))) {
                shippingChecks2 = (opportunity.Shipping_and_Handling_Manual__c != null);
            }
            }   
            //GTMS - 29254 End
            
            Boolean shippingChecks = shippingChecks1 && shippingChecks2;
            isEligibleForCheckoutLink = paymentChecks && basicChecks && billingChecks && validBillingLocation && shippingChecks;

        } catch (Exception ex) {
        }

        if (isEligibleForCheckoutLink && String.isNotBlank(opportunity.Opportunity_UUID__c)) {
            opportunity.Renewal_Checkout_Agreement_Link__c = 
                'https://www.samsara.com/checkout/opportunity?id=' + opportunity.Opportunity_UUID__c;
        } else {
            opportunity.Renewal_Checkout_Agreement_Link__c = null;
        }
    }
     /**
     * Calculates account rollup values based on opportunities
     */
    public void calculateAccountRollup(Map<Id, Opportunity> newOppMap, Map<Id, Opportunity> oldOppMap) {
        if (OppAccIds.isEmpty()) {
            return;
        } 
        Map<Id, Account> accRollupMap = new Map<Id, Account>();

        for (Opportunity opp : allOppMap.values()){
            Opportunity oldOpp = oldOppMap != null ? oldOppMap.get(opp.Id) : null;
            opp = (newOppMap != null && newOppMap.containsKey(opp.id)) ? newOppMap?.get(opp.id) : opp; 
            Account acc = accRollupMap.containsKey(opp.AccountId) ? 
                         accRollupMap.get(opp.AccountId) : 
                         new Account(Id = opp.AccountId,Account_Lifetime_ACV__c = 0,Current_Monthly_Payments__c=0,Total_Open_Opp_Expected_Revenue__c=0,Highest_Probability_Open_Opportunity__c=0);

            if (OppAccIds.contains(opp.AccountId)) {
                 processOppRollup(acc, opp);
                 accRollupMap.put(acc.Id, acc);
            } 

           
        } 
        for (Account calculatedAcc : accRollupMap.values()) {
            Account existingAcc = oppAccounts?.get(calculatedAcc.Id);
            Account accToUpdate = accountUpdateMap.containsKey(calculatedAcc.Id) ? 
                                 accountUpdateMap.get(calculatedAcc.Id) : 
                                 new Account(Id = calculatedAcc.Id);
            
            if (existingAcc == null || (
                calculatedAcc.Account_Lifetime_ACV__c != existingAcc.Account_Lifetime_ACV__c ||
                calculatedAcc.Current_Monthly_Payments__c != existingAcc.Current_Monthly_Payments__c ||
                calculatedAcc.Total_Open_Opp_Expected_Revenue__c != existingAcc.Total_Open_Opp_Expected_Revenue__c ||
                calculatedAcc.Highest_Probability_Open_Opportunity__c != existingAcc.Highest_Probability_Open_Opportunity__c ||
                calculatedAcc.Open_Opportunity__c != existingAcc.Open_Opportunity__c ||
                calculatedAcc.Total_Open_Opp_Expected_Revenue__c != existingAcc.Total_Open_Opp_Expected_Revenue__c)) {
                    OpportunityTriggerHandlerContext.logExecution.add('calculateAccountRollup');
                    accToUpdate.Account_Lifetime_ACV__c = calculatedAcc.Account_Lifetime_ACV__c;
                    accToUpdate.Current_Monthly_Payments__c = calculatedAcc.Current_Monthly_Payments__c;
                    accToUpdate.Total_Open_Opp_Expected_Revenue__c = calculatedAcc.Total_Open_Opp_Expected_Revenue__c;
                    accToUpdate.Highest_Probability_Open_Opportunity__c = calculatedAcc.Highest_Probability_Open_Opportunity__c;
                    accToUpdate.Open_Opportunity__c = calculatedAcc.Open_Opportunity__c;
                    accountUpdateMap.put(accToUpdate.Id, accToUpdate);
            }
        }  
    }
    
    /**
     * Calculates rollup values for open opportunities
     */
    private void processOppRollup(Account acc, Opportunity opp) {
        if (!opp.IsClosed && opp.Type == 'Revenue Opportunity') {
            if (opp.ExpectedRevenue != null) {
                acc.Total_Open_Opp_Expected_Revenue__c += opp.ExpectedRevenue;
            }
            acc.Open_Opportunity__c = true;
            if (!opp.Name.contains('Renewal') && opp?.Owner?.Name != 'Samsara Small Fleets') {
                acc.Highest_Probability_Open_Opportunity__c = Math.max(acc.Highest_Probability_Open_Opportunity__c, opp.Probability);
            }
        } else if (opp.ACV_Bookings_SOT__c != null && 
                   ((opp.Type == 'Revenue Opportunity' && opp.StageName == 'Closed Won') ||
                    ((opp.Type == 'Remorse Refund' || opp.Type == 'Rebate') && opp.StageName == 'Refunded - Closed'))) {
            acc.Account_Lifetime_ACV__c += opp.ACV_Bookings_SOT__c;
        }
        
        if (opp.Total_License_Due__c != null && opp.Type != null &&
            OPPORTUNITY_TYPES.contains(opp.Type) &&
            opp.Active_Opportunity__c == true &&
            opp.Monthly_Deal_or_Monthly_Return__c == true) {
            Date licenseEndDate = (opp.Returning_Opportunity__c != null && opp.Returning_Opportunity__r.License_End_Date__c != null) ? 
                                 opp.Returning_Opportunity__r.License_End_Date__c : opp.License_End_Date__c;
            
            if (licenseEndDate != null && opp.CloseDate != null) {
                Integer numberOfMonths = opp.CloseDate.monthsBetween(licenseEndDate);
                numberOfMonths = numberOfMonths != 0 ? numberOfMonths : 1;
                acc.Current_Monthly_Payments__c += (opp.Total_License_Due__c / numberOfMonths);
            }
        }
    }

    /*Following methods replaces the flow logic of creating a promo opportunity. Part of Optimizations for opportunity processes*/
    public void afterInsertOrUpdate(Map<Id,Opportunity> oldOpps, List<Opportunity> newList){
        if(!gas.Opportunity_Flow__c){
            for(Opportunity opp : newList){
                if( (oldOpps == null || opp.Original_AE__c != oldopps.get(opp.Id)?.Original_AE__c) && opp.Original_AE__c != null){
                    OpportunityTeamMember oppTeam = new OpportunityTeamMember(
                        OpportunityId  = opp.Id,
                        TeamMemberRole = 'Original Account Executive',
                        UserId         = opp.Original_AE__c
                    );
                    DMLWrapper.doInsert(oppTeam);
                }
            }
        }  
    }
  
  @testvisible public void updateTrialStartDateOnRevenueOppty( set<Id> relatedRevenueOptyIds )
    {
        try
        {
            date latestTrialStartDate;

            // Update the Revenue Opportunity's Trial Start Date Field with the first created Trial Opportunity's Trial Start Date New Field
            // NOTE: Only the first created Trial Opportunity's Trial Start Date new is considered
            for ( Opportunity revenueOppty : [ SELECT Id, Trial_Start_Date__c, 
                                                (
                                                    SELECT Id, Trial_Start_Date_new__c FROM Opportunities__r 
                                                    WHERE Trial_Start_Date_new__c != null
                                                    ORDER BY createddate
                                                    LIMIT 1
                                                ) 
                                            FROM Opportunity WHERE Id in :relatedRevenueOptyIds ])
            {
                // If the Revenue Opportunity's Trial Start Date matches with the first created Free Trial Opportunity's Trial Start Date New Field, skip
                if( revenueOppty.Opportunities__r.isEmpty() ) { continue; }
                
                latestTrialStartDate = revenueOppty.Opportunities__r[0].Trial_Start_Date_new__c;

                if ( latestTrialStartDate != revenueOppty.Trial_Start_Date__c ) 
                {
                    revenueOppty.Trial_Start_Date__c = latestTrialStartDate;
                    DMLWrapper.doUpdate(revenueOppty, new List<SobjectField>{ Opportunity.Trial_Start_Date__c });
                }
            }
        }

        catch ( Exception e )
        {
            Logger.atError()
                .setExceptionOrMessage(e)
                .setMethod('updateTrialStartDateOnRevenueOppty');
            Logger.insertMasterLogs();
        }
    }
}