/*
* Title: OpportunityProcessBuilderConversion
* Description: Class to house all the converted Opportunity Process Builders
*               This is being created as a standalone class so that regression testing
*               can be done in isolation and unit tests can be written to cover expected
*               process builder functionality
* Author: Anders Windell
* Created: July 12, 2019
* 08/09/21 Lavanya (GTMS-4426) Updated the IF condition in stampDataForAmendments to check if the contractId on the oppty is not null
* 07/08/21 Anil Bogadi (GTMS-3963) Auto-Populate License End Date for Promos
* 06/29/21 Lavanya (GTMS-4104) closingOppWithStripeTrialOrExpessFinanceApproval (updated IF condition to check if amount is greater than 0)
* 04/22/21 Sai (GTMS-3994)  createR2ShipCWPlatformEvent() (Included 'Parent Opportunity' in the VB)
* 06/15/2021 Agamani (GTMS-3556) Updated Balance due<10 on line 920
* 06/01/21 Dipen (GTMS-3840) Updated the IF condition in "opptyConsolidatedProcesses" where the code updates the ADR transfer log
* 05/06/21 Teja (GTMS-2309) copied 'Original Approved Discount' from Contract to Opportunity on updateContractBasedFields method
* 04/22/21 Sai (GTMS-3424) readyToShipOrClosedWon() & createR2ShipCWPlatformEvent() (Changed Virtual bell notification for 'Ready to ship' to 'Orders processing')
* 04/17/21 Gaurav (GTMS-3467) Added criteria for Oppty subType != 'Paid Pilot' in the linkContracts() method 
*12/03/20 Ron (GTMS-1869) beforeInsertOrUpdate (match CloseDate on Rebate to Rev)
* 11/10/20 Harsha - (GTMS-2133/2117) welcomeTrialKitProductsOnClosing (Removed the Renewal Kit Logic)
* 7/22/20 Tommy - (GTMS-1350): hotfix for error in sendEmail()
* Sep-26-2022 Raghavendran Ragothaman - GTMS-9687 - Added null check on Shipping_Address_New__c.Shipping_Contact__c or Opportunity.Shipping_Contact__c before sending email
* Nov-14-2022 Rajesh - GTMS-9570 - Added RejectedReason logic for ADR
* Feb-14-2024 Rodrigo GTMS-18563  Payment_Token__c check in a condition 
*/
public without sharing class OpportunityProcessBuilderConversion {

    private static String PAY_TERM_DUE_IN_ADV = 'Due in advance';

    /*@TestVisible
    private static Welcome_Trial_Kit_Product__mdt welcomeTrialKitProducts {
        get {
            if(welcomeTrialKitProducts == null){
                welcomeTrialKitProducts = [
                    SELECT  Food_Beverage__c, Standard__c, Standard_Welcome_Kit__c, Transport_Warehousing__c, 
                            UK_Trial_Kits__c
                    FROM Welcome_Trial_Kit_Product__mdt
                    WHERE Label = 'Default Product List'
                    LIMIT 1
                ];
                return welcomeTrialKitProducts;
            }else{
                return welcomeTrialKitProducts;
            }
        }
        set;
    }*/
    
    public static void processContractUpdates(Map<Id, Opportunity> newOpptyMap, Map<Id, Opportunity> oldOpptyMap){
        Map<Id, Account> accountMap = linkContracts(newOpptyMap, oldOpptyMap);
        updateContractBasedFields(newOpptyMap, oldOpptyMap, accountMap);
        updateContractsOnLicenseDatesChanges(newOpptyMap, oldOpptyMap);
    }

    public static void updateContractBasedFields(Map<Id, Opportunity> newOpptyMap, Map<Id, Opportunity> oldOpptyMap, Map<Id, Account> accountMap){

        Set<Id> contractIds = new Set<Id>();
        for(Opportunity opp : newOpptyMap.values()) {
            contractIds.add(opp.ContractId);
             //ABU: GTMS-15753 09/19/2023
            contractIds.add(opp.SBQQ__RenewedContract__c);
            //ABU: End
            if (oldOpptyMap.get(opp.Id).netsuite_conn__From_Contract__c != opp.netsuite_conn__From_Contract__c && opp.netsuite_conn__From_Contract__c != null) {
               contractIds.add(opp.netsuite_conn__From_Contract__c);
            }
            if (oldOpptyMap.get(opp.Id).netsuite_conn__From_Contract__c != opp.netsuite_conn__From_Contract__c && opp.netsuite_conn__From_Contract__c == null) {
                opp.Original_Approved_Discount__c = Null;
            }
        }
        Map<Id, Opportunity> OpportunityMap = getOpportunitydetails(newOpptyMap);
        System.debug('contractIds'+contractIds);
        System.debug('contractIds.isEmpty()'+contractIds.isEmpty());
        Map<Id, Contract> contractsMap = new Map<Id, Contract>();
        Automation_Settings__c disableConstantLicenseEndDateToggle = Automation_Settings__c.getInstance('Fixed_End_Date_Disable');
        Boolean disableConstantLicenseEndDate =  disableConstantLicenseEndDateToggle != null && disableConstantLicenseEndDateToggle.Disabled__c == true;
        if (!contractIds.isEmpty()) {
             //ABU: GTMS-15753 09/19/2023
                contractsMap = new Map<Id, Contract>([SELECT Id, EndDate,GP_End_Date__c,SBQQ__RenewalOpportunity__c, Original_Approved_Discount__c,Weighted_Average_Start_Date__c 
            FROM Contract
            WHERE Id IN :contractIds]);
        }
             //ABU: End
        for (Opportunity oppty : newOpptyMap.values()) {
            Opportunity oldOpp = oldOpptyMap.get(oppty.Id);
            if (contractsMap.containsKey(oppty.netsuite_conn__From_Contract__c)) {
                Contract fromContract = contractsMap.get(oppty.netsuite_conn__From_Contract__c);
                oppty.Original_Approved_Discount__c = fromContract.Original_Approved_Discount__c;
            }
            if (oppty.ContractId == null) {
                if((oppty.netsuite_conn__Bill_To_Tier__c == null && isChanged(oppty, oldOpp, Schema.Opportunity.netsuite_conn__Bill_To_Tier__c)) 
                    || (oppty.License_Term_Approval_Status__c == 'Approved' && isChanged(oppty, oldOpp, Schema.Opportunity.License_Term_Approval_Status__c))){
                    // Replaces Node 'Contract Unlinked' //
                    oppty.Approved_Discount__c = 10;
                }
                        }
            
                System.debug('oldOpp.CloseDate'+oldOpp.CloseDate);
                System.debug('oppty.CloseDate'+oppty.CloseDate);
                System.debug('oldOpp.StageName'+oldOpp.StageName);
                System.debug('oppty.StageName'+oppty.StageName);
                String currentUserId = UserInfo.getUserId();
                if(oppty.Type == 'Revenue Opportunity' && (isChanged(oppty, oldOpp, Schema.Opportunity.StageName) || oldOpp.CloseDate != oppty.CloseDate || FeatureManagement.checkPermission('NetSuite_Service_User_Permission')) && (oppty.StageName == 'Ready to Ship' || oppty.StageName == 'Closed Won')) {
                if(oppty.SBQQ__AmendedContract__c != NULL || (oppty.SBQQ__PrimaryQuote__c != NULL && OpportunityMap.get(oppty.id).SBQQ__PrimaryQuote__r.SBQQ__MasterContract__c != NULL) || (oppty.SBQQ__PrimaryQuote__c != NULL && OpportunityMap.get(oppty.id).SBQQ__PrimaryQuote__r.Co_Term_Contract__c != NULL)){
                     System.debug('in amendments');
                  oppty.License_Start_Date__c = oppty.CloseDate;
                  //GTMS-23000
                    if(oppty.Went_to_Ready_to_Ship_Date__c!=null && oppty.SBQQ__RenewedContract__c != Null && contractsMap.get(oppty.SBQQ__RenewedContract__c).GP_End_Date__c != Null 
                       && (contractsMap.get(oppty.SBQQ__RenewedContract__c).GP_End_Date__c>=Date.newInstance((Integer)(oppty.Went_to_Ready_to_Ship_Date__c.year()),
                                                                                                             (Integer)(oppty.Went_to_Ready_to_Ship_Date__c.month()),
                                                                                                             oppty.Went_to_Ready_to_Ship_Date__c.day())))
                    {
                        oppty.License_Start_Date__c = Date.newInstance((Integer)(contractsMap.get(oppty.SBQQ__RenewedContract__c).EndDate.year()),
                                                                       (Integer)(oppty.Renewed_Contract_EndDate__c.month()),
                                                                       oppty.Renewed_Contract_EndDate__c.day()+1);
                        System.debug('oppty.License_Start_Date__c:'+oppty.License_Start_Date__c);
                        
                    }
                  OpportunityHelperContext.updateOpptyFromContractUsingWASD(oppty,contractsMap);
                    
                    if(!(oppty.SBQQ__PrimaryQuote__c != NULL && OpportunityMap.get(oppty.id).SBQQ__PrimaryQuote__r.Co_Term_Contract__c != NULL)){
                      if(oppty.SBQQ__PrimaryQuote__c != NULL && OpportunityMap.get(oppty.id).SBQQ__PrimaryQuote__r.Contract_End_Date__c != NULL && oppty.License_End_Date__c != OpportunityMap.get(oppty.id).SBQQ__PrimaryQuote__r.Contract_End_Date__c){ //quote is null then get amended contract end date
                        oppty.License_End_Date__c = OpportunityMap.get(oppty.id).SBQQ__PrimaryQuote__r.Contract_End_Date__c;
                                }
                                //if quote is null and amended contract is not null then get amended contract end date
                                else if(oppty.SBQQ__PrimaryQuote__c == NULL && oppty.SBQQ__AmendedContract__c != Null && opportunityMap.get(oppty.id).SBQQ__AmendedContract__r.EndDate != Null){
                        oppty.License_End_Date__c = OpportunityMap.get(oppty.id).SBQQ__AmendedContract__r.EndDate;
                      }  
                    }else{
                        if(OpportunityMap.get(oppty.id).SBQQ__PrimaryQuote__c != NULL && OpportunityMap.get(oppty.id).SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate != NULL){
                           oppty.License_End_Date__c = OpportunityMap.get(oppty.id).SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate; 
                        }
                    }
                    
                }
                    //ABU: GTMS-15753 09/19/2023
                    /*else if(oppty.SBQQ__RenewedContract__c != Null && contractsMap.get(oppty.SBQQ__RenewedContract__c).GP_End_Date__c != Null 
                         && (contractsMap.get(oppty.SBQQ__RenewedContract__c).GP_End_Date__c>=oppty.CloseDate 
                         && isChanged(oppty, oldOpp, Schema.Opportunity.StageName))){
                             oppty.License_Start_Date__c = Date.newInstance((Integer)(contractsMap.get(oppty.SBQQ__RenewedContract__c).EndDate.year()),
                                                                           (Integer)(oppty.Renewed_Contract_EndDate__c.month()),
                                                                           oppty.Renewed_Contract_EndDate__c.day()+1);
                            System.debug('oppty.License_Start_Date__c:'+oppty.License_Start_Date__c);
                            oppty.License_End_Date__c = Date.newInstance((Integer)(oppty.License_Start_Date__c.year()+Math.floor((Integer)oppty.License_Term__c/12)),
                                                                         (Integer)(oppty.License_Start_Date__c.month()),
                                                                         (Integer)oppty.License_Start_Date__c.day()-1);
                                          
                }*/
                   //ABU: GTMS-15753 09/19/2023--> End 
                    else{
                    System.debug('in non amendments');
                    System.debug('oppty.License_Start_Date__c'+oppty.License_Start_Date__c);
                    System.debug('oppty.License_End_Date__c'+ oppty.License_End_Date__c);
                    System.debug('oppty.CloseDate'+ oppty.CloseDate);
                  if(!oppty.Adjust_License_Start_Date__c) {
                        if (isChanged(oppty, oldOpp, Schema.Opportunity.StageName)){
                            oppty.CloseDate = Date.today();
                        } 
                        //GTMS-23000
                       if(oppty.SBQQ__RenewedContract__c != Null && contractsMap.get(oppty.SBQQ__RenewedContract__c).Weighted_Average_Start_Date__c != Null && oppty.License_Term__c != Null){
                            oppty.License_End_Date__c = Date.newInstance((Integer)(oppty.License_Start_Date__c.year() + Math.floor(oppty.License_Start_Date__c.month() + oppty.License_Term__c - 1)/12), 
                                                                     Math.mod((Integer)(oppty.License_Start_Date__c.month() + oppty.License_Term__c - 1), 12) + 1, 
                                                                     oppty.License_Start_Date__c.day() - 1);

                        }
                      //ABU: GTMS-15753 09/19/2023(121-135,140)
                        else if(oppty.Went_to_Ready_to_Ship_Date__c!=null && oppty.SBQQ__RenewedContract__c != Null && contractsMap.get(oppty.SBQQ__RenewedContract__c).GP_End_Date__c != Null 
                         && (contractsMap.get(oppty.SBQQ__RenewedContract__c).GP_End_Date__c>=Date.newInstance((Integer)(oppty.Went_to_Ready_to_Ship_Date__c.year()),
                                                                                                  (Integer)(oppty.Went_to_Ready_to_Ship_Date__c.month()),
                                                                                                   oppty.Went_to_Ready_to_Ship_Date__c.day())))
                         {
                             oppty.License_Start_Date__c = Date.newInstance((Integer)(contractsMap.get(oppty.SBQQ__RenewedContract__c).EndDate.year()),
                                                                           (Integer)(oppty.Renewed_Contract_EndDate__c.month()),
                                                                           oppty.Renewed_Contract_EndDate__c.day()+1);
                            System.debug('oppty.License_Start_Date__c:'+oppty.License_Start_Date__c);
                            //GTMS-23000
                            OpportunityHelperContext.updateOpptyFromContractUsingWASD(oppty,contractsMap);
                    
                            oppty.License_End_Date__c = Date.newInstance((Integer)(oppty.License_Start_Date__c.year()+Math.floor((Integer)oppty.License_Term__c/12)),
                                                                         (Integer)(oppty.License_Start_Date__c.month()),
                                                                         (Integer)oppty.License_Start_Date__c.day()-1);
                                          
                       }else{
                        oppty.License_Start_Date__c = oppty.CloseDate;
                        //GTMS-23000
                        OpportunityHelperContext.updateOpptyFromContractUsingWASD(oppty,contractsMap);
                           if (disableConstantLicenseEndDate || oppty.License_End_Date__c == null || (oppty.Processing_Type__c != 'Fixed End Date' && !disableConstantLicenseEndDate)) {
                                oppty.License_End_Date__c = Date.newInstance((Integer)(oppty.CloseDate.year() + Math.floor(oppty.CloseDate.month() + oppty.License_Term__c - 1)/12), 
                                                                     Math.mod((Integer)(oppty.CloseDate.month() + oppty.License_Term__c - 1), 12) + 1, 
                                                                     oppty.CloseDate.day() - 1);
                           }
                       }
                       //ABU: GTMS-15753 09/19/2023--> End 
                    }
                    
                    else if(oppty.Adjust_License_Start_Date__c) { 
                        if(oppty.License_Start_Date__c == null) oppty.License_Start_Date__c = oppty.CloseDate;
                        //GTMS-23000
                        OpportunityHelperContext.updateOpptyFromContractUsingWASD(oppty,contractsMap);
                        if (disableConstantLicenseEndDate || oppty.License_End_Date__c == null || (oppty.Processing_Type__c != 'Fixed End Date' && !disableConstantLicenseEndDate)) {
                            oppty.License_End_Date__c = Date.newInstance((Integer)(oppty.License_Start_Date__c.year() + Math.floor(oppty.License_Start_Date__c.month() + oppty.License_Term__c - 1)/12), 
                                                                     Math.mod((Integer)(oppty.License_Start_Date__c.month() + oppty.License_Term__c - 1), 12) + 1, 
                                                                     oppty.License_Start_Date__c.day() - 1);   
                        }  
                    }
              }
            }
            
            if( isChanged(oppty, oldOpp, Schema.Opportunity.StageName) && oppty.StageName == 'Closed Won' && oppty.Promo_Reason__c == 'Beta Program' && oppty.Type == 'Promo Opportunity') {
                if(!(oppty.SBQQ__AmendedContract__c != NULL || (oppty.SBQQ__PrimaryQuote__c != NULL &&  opportunityMap.get(oppty.id).SBQQ__PrimaryQuote__r.SBQQ__MasterContract__c != NULL))){
                    oppty.License_End_Date__c = Date.newInstance((Integer)(oppty.CloseDate.year() + Math.floor(oppty.CloseDate.month() + oppty.License_Term__c - 1)/12), 
                                                                     Math.mod((Integer)(oppty.CloseDate.month() + oppty.License_Term__c - 1), 12) + 1, 
                                                                     oppty.CloseDate.day());
                }
                        
            }

            // moved from opportunity helper - beforeUpdateOnly
            if(oppty.Type == 'Revenue Opportunity' 
                && oppty.License_Term__c != oldOpp.License_Term__c 
                && oppty.License_Term__c < oldOpp.License_Term__c) {

                oppty.Approved_Discount__c = null;
            }
        }
        }

    /**
     * Checks for License Start Date and End Date changes 
     */
    public static void updateContractsOnLicenseDatesChanges(Map<Id, Opportunity> newOpptyMap, Map<Id, Opportunity> oldOpptyMap){
        Set<Id> idsToProcess = new Set<Id>();
        for (Id oppId : newOpptyMap.keySet()){
            Opportunity opp = newOpptyMap.get(oppId);
            Opportunity oldOpp = oldOpptyMap.get(oppId);
            
            if (opp.License_Start_Date__c != oldOpp.License_Start_Date__c
            ||  opp.License_End_Date__c != oldOpp.License_End_Date__c){
                idsToProcess.add(oppId);
            }
        }

        if (!idsToProcess.isEmpty()){
            DMLWrapper.doInsert(
                new ContractUpdateServiceAsync().prepareAsyncRequests(
                    JSON.serialize(new ContractUpdateServiceAsync.Options('Update Dates')), 
                    idsToProcess
                )
            );
        }
    }
    
    //adding logic to stamp License_Start_Date__c on amendment opportunities as part of renewals
    //GTMS-4426: Lavanya : Updated the IF condition to check if the contractId on the oppty is not null
    public static void stampDataForAmendments(Opportunity oppty, Account account, Opportunity oldOpportunity) {
        if((oppty.ContractId != null || oppty.SBQQ__AmendedContract__c  != null || oppty.SBQQ__RenewedContract__c != null) && account != null) {
                if(oppty.Configuration_Segment__c != 'Express'
                    && account.Latest_Active_Contract__c != null 
                    && account.Latest_Active_Contract__r.EndDate >= Date.today()
                    && oppty.Type == 'Revenue Opportunity'  
                    && oppty.Segment_Sales_Role__c != 'AE1'
                    && oppty.Probability<99) {
                    if(!oppty.Adjust_License_Start_Date__c) {
                        oppty.License_Start_Date__c = oppty.CloseDate;
                    }
                    //GTMS-23000
                    //OpportunityHelper.updateOpptyFromContractUsingWASD(oppty);
                }
            }
        }  
   public static Map<Id, Account> linkContracts( Map<Id, Opportunity> newOpptyMap, Map<Id, Opportunity> oldOpptyMap ){

        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Latest_Active_Contract__c, 
                   Latest_Active_Contract__r.EndDate, Segment__c 
            FROM Account
            WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :newOpptyMap.keySet())
        ]);
       
        return accountMap;
    }

    public static Map<Id, Opportunity> getOpportunitydetails(Map<Id, Opportunity> newOpptyMap){
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
            SELECT Id, SBQQ__PrimaryQuote__r.SBQQ__MasterContract__c, 
                   SBQQ__AmendedContract__r.EndDate, Segment__c,SBQQ__PrimaryQuote__r.Contract_End_Date__c, SBQQ__PrimaryQuote__r.Co_Term_Contract__c, SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate
            FROM Opportunity
            WHERE Id IN :newOpptyMap.keySet()
        ]);
       
        return opportunityMap;
    }
    

    public static void readyToShipOrClosedWon(Map<Id, Opportunity> newOpptyMap, Map<Id, Opportunity> oldOpptyMap){
        Map<Id,Opportunity> virtualBellOpptyMap = new Map<Id, Opportunity>();

        // Check if trigger.newMap is eligible to push to NS
        for(Opportunity opp : newOpptyMap.values()){
            //TODO - include backup to allow for Send Virtual Bell checkbox to trigger the logic a secondary time if necessary
            if(opp.StageName == 'Ready to Ship' || opp.StageName == 'Closed Won') {
                if(opp.Send_Virtual_Bell__c){
                    virtualBellOpptyMap.put(opp.Id, opp);
                }
            }
        }
        if(virtualBellOpptyMap.size() > 0){
            convertACVtoUSD(virtualBellOpptyMap, oldOpptyMap);
            createR2ShipCWPlatformEvent(virtualBellOpptyMap);
             }
    }

    public static void convertACVtoUSD(Map<Id, Opportunity> Opps, Map<Id, Opportunity> oldOpptyMap){
        system.debug('oldOpptyMap'+oldOpptyMap);
        system.debug('oldOpptyMap'+oldOpptyMap == null);
        String getACV;
        String getACVinUSD;
        string ACVMultiCurrency;
        List<DatedConversionRate>  listDateConvRate =new List<DatedConversionRate>();

        Set<String> setOppIso = new Set<String>();
        date closedate = date.today();
        for(Opportunity o : Opps.values()) {
      if(o.CurrencyIsoCode != null){
        setOppIso.add(o.CurrencyIsoCode);
             }  
        }
        if(setOppIso.size() > 0 ){
            listDateConvRate = [ SELECT isocode ,startdate, NextStartDate, ConversionRate  
                              FROM DatedConversionRate 
                              WHERE isocode IN :setOppIso and startdate <= :closedate and NextStartDate > :closedate LIMIT 50000];
              }
        Map<String, List<DatedConversionRate> > MapRates = new Map< String, List<DatedConversionRate> >();
        if(listDateConvRate.size() > 0){
      For(DatedConversionRate d:listDateConvRate) {
        if( MapRates.containsKey(d.isocode)) {
          List<DatedConversionRate> lstDateConv = MapRates.get(d.isocode);
          lstDateConv.add(d);
        }
        else {
          List<DatedConversionRate> lstDateConv = new List<DatedConversionRate>();
          lstDateConv.add(d);
          MapRates.put(d.isocode,lstDateConv);
        }
            }
        }
            for(Opportunity opp : Opps.values()){
            if(opp.ACV_Bookings_SOT__c != null && opp.ACV_Bookings_SOT__c != 0){
            Decimal ACVAmount = (opp.ACV_Bookings_SOT__c);
            getACV = getFormat(ACVAmount);
            Decimal ACVAmountinUSD;
            if( opp.CurrencyIsoCode == 'USD') {
                 ACVMultiCurrency = String.ValueOf(opp.CurrencyIsoCode)+' '+getACV;  
            }else if(opp.CurrencyIsoCode!= null && MapRates.containsKey(opp.CurrencyIsoCode) && opp.CurrencyIsoCode != 'USD'){
                List<DatedConversionRate> listDc = MapRates.get(opp.CurrencyIsoCode);
                for( DatedConversionRate dcr : listDc){
                          if(dcr.startdate < = closedate && dcr.NextStartDate > closedate){
                        ACVAmountinUSD = (((opp.ACV_Bookings_SOT__c)/(dcr.ConversionRate)).setscale(2));
                    }else{
                        ACVAmountinUSD = (((opp.ACV_Bookings_SOT__c)/(opp.Currency_Exchange_Rate__c)).setscale(2));
                    }   
                }
                getACVinUSD = getFormat(ACVAmountinUSD); 
                ACVMultiCurrency = String.ValueOf(opp.CurrencyIsoCode)+' '+ getACV+'(USD'+' '+getACVinUSD+')';
            }else{
                opp.ACV_Amount_Multi_Currency__c = String.ValueOf(opp.CurrencyIsoCode)+' '+(opp.ACV_Bookings_SOT__c);
            }
        if(oldOpptyMap != null && (oldOpptyMap.get(opp.Id).ACV_Amount_Multi_Currency__c == null || oldOpptyMap.get(opp.Id).ACV_Amount_Multi_Currency__c != ACVMultiCurrency)){
                opp.ACV_Amount_Multi_Currency__c = ACVMultiCurrency;
            }
        }
    }
    }
    public static String getFormat(Decimal ACVAmount){
        String StrACV = String.valueOf(ACVAmount);
        String z = '.';
        if(StrACV.contains(',')) z = ',';
        StrACV = StrACV.substring(0, StrACV.indexOf(z));
        string afterDec = (String.valueOf(ACVAmount)).substringAfterLast(z);
        if(ACVAmount - Decimal.valueOf(StrACV) == 0){
            return String.valueOf(ACVAmount.format()) + z + '00';
        }
        else if(afterDec.right(1) == '0'){
            return String.valueOf(ACVAmount.format()) +'0';
        }
        else {
            return String.valueOf((ACVAmount).format());
        }
    }

    //Replaces: Push Rev, Promo, Rebate, FT to Netsuite
    //* 12/03/2020 Ron (GTMS-1869) beforeInsertOrUpdate (match CloseDate on Rebate to Rev)
    public static void pushInfoToNetsuite(Map<Id, Opportunity> newOpptyMap, Map<Id, Opportunity> oldOpptyMap){
        Map<Id,Opportunity> changedOpptyMap = new Map<Id, Opportunity>();
        Set<Opportunity> oppsToUpdate = new Set<Opportunity>();

        // Check if trigger.newMap is eligible to push to NS
        for(Opportunity opp : newOpptyMap.values()){

            if( oldOpptyMap != null && (oldOpptyMap.get(opp.Id) == null || opp.StageName != oldOpptyMap.get(opp.Id).StageName) && 
                (opp.StageName == 'Ready to Ship' || opp.StageName == 'Closed Won') ) {
                changedOpptyMap.put(opp.Id,opp);
            }
        }
        if(changedOpptyMap.size() > 0){
            Map<Id, Opportunity> allRelatedOpptys = new Map<Id, Opportunity>([
                SELECT Id, Buyout_Opportunity__r.Push_Return_to_Netsuite__c, 
                        Subsidy_Opportunity__r.Push_Return_to_Netsuite__c, 
                        Partner_Referral_Opportunity__r.Push_Return_to_Netsuite__c,
                        Retry_TO_to_NS__c, netsuite_conn__Push_To_NetSuite__c
                FROM Opportunity
                WHERE Id IN :changedOpptyMap.keyset()]);

            for(Opportunity opp : changedOpptyMap.values()){
                // Nodes in this code path are going to update fields on related Opportunities
                // which indicate they need to push a return to Netsuite
                Opportunity oppToUpdate = new Opportunity();
                if(opp.Type == 'Revenue Opportunity' && opp.StageName == 'Closed Won'){
                    /* Replaces Node 'Revenue Opportunity with Buyout Going to Closed Won' */
                    if(opp.Buyout_Opportunity__c != null){
                        //allRelatedOpptys.get(opp.Id).Buyout_Opportunity__r.Push_Return_to_Netsuite__c = true;
                        //oppsToUpdate.add(allRelatedOpptys.get(opp.Id).Buyout_Opportunity__r);
                        oppToUpdate.Id = opp.Buyout_Opportunity__c;
                        oppToUpdate.Push_Return_to_Netsuite__c = true;
                        oppToUpdate.CloseDate = opp.CloseDate;
                    }
                    /* Replaces Node 'Revenue Opportunity with Subsidy Going to Closed Won' */
                    else if(opp.Subsidy_Opportunity__c != null){
                        //allRelatedOpptys.get(opp.Id).Subsidy_Opportunity__r.Push_Return_to_Netsuite__c = true;
                        //oppsToUpdate.put(oppty.Returning_Opportunity__c, oppty.Returning_Opportunity__r);
                        oppToUpdate.Id = opp.Subsidy_Opportunity__c;
                        oppToUpdate.Push_Return_to_Netsuite__c = true;
                        oppToUpdate.CloseDate = opp.CloseDate;
                    }
                    /* Replaces Node 'Revenue Opportunity with Referral Going to Closed Won' */ 
                    else if (opp.Partner_Referral_Opportunity__c != null) {
                        //allRelatedOpptys.get(opp.Id).Partner_Referral_Opportunity__r.Push_Return_to_Netsuite__c = true;
                        //oppsToUpdate.add(allRelatedOpptys.get(opp.Id).Partner_Referral_Opportunity__r);
                        oppToUpdate.Id = opp.Partner_Referral_Opportunity__c;
                        oppToUpdate.Push_Return_to_Netsuite__c = true;
                        oppToUpdate.CloseDate = opp.CloseDate;
                    }
                    if (oppToUpdate.Id != null) DMLWrapper.doUpdate(oppToUpdate, new List<SobjectField>{
                            Opportunity.Push_Return_to_Netsuite__c, 
                            Opportunity.CloseDate
                    });
                }
                // Nodes in this code path are going to update the triggered opportunity
                // and depending on the type of opportunity, will check the appropriate flag
                else if(opp.StageName == 'Ready to Ship'){
                    if(oldOpptyMap != null){
                        if(oldOpptyMap.get(opp.Id).StageName == opp.StageName){
                            continue;
                        }
                        /* Replaces Node 'Trial Opportunity Push NS' */
                        if(opp.Type == 'Free Trial Opportunity'|| opp.Type == 'Work Order'){
                            opp.Retry_TO_to_NS__c = true;  // updated to NOT include opp in beforeTrigger context to update list
                        }
                        /* Replaces Nodes 'Rev Opportunity Push to NS' and 'Promo Opportunity Push to NS' */
                        else if(opp.Type == 'Revenue Opportunity' || opp.Type == 'Promo Opportunity'){
                            opp.netsuite_conn__Push_To_NetSuite__c = true; // updated to NOT include opp in beforeTrigger context to update list
                        }
                    }
                }
            }
        }
    }

    public static void createR2ShipCWPlatformEvent(Map<Id, Opportunity> platformOpps){
        List<R2Ship_CW_Opportunity__e> r2ShipCWs = new List<R2Ship_CW_Opportunity__e>();
        List<Database.SaveResult> results = new List<Database.SaveResult>();

        for(Opportunity o: platformOpps.values()){

            if((o.Type == 'Revenue Opportunity' || o.Type == 'Parent Opportunity') && o.StageName == 'Ready to Ship'){
                R2Ship_CW_Opportunity__e r2ShipCW = new R2Ship_CW_Opportunity__e(   Is_Closed_Won__c = false,
                                                                                    Revenue_Opportunity__c = true, // THis will hold true for 'Parent/Revenue' types
                                                                                    AccountId__c = o.AccountId,
                                                                                    OpportunityId__c = o.Id,
                                                                                    Send_Virtual_Bell__c = o.Send_Virtual_Bell__c);
    
                r2ShipCWs.add(r2ShipCW);
            }
        }
        if(r2ShipCWs.size() > 0){
            results = EventBus.publish(r2ShipCWs);
        }

        if(results.size() > 0){
            for(Database.SaveResult sr : results){
                if(sr.isSuccess()){
                    System.debug(LoggingLevel.INFO, 'Successful Event Publish');
                }
                else{
                    for(Database.Error err: sr.getErrors()){
                        System.debug(LoggingLevel.INFO, 'Error Returned: '+err.getStatusCode()+' - '+err.getMessage());
                    }
                }
            }
        }
    }

    // Replaces: Account Owner Team Email
    public static void accountOwnerTeamEmail(List<Opportunity> newOpptyList){
        List<Id> ownerIdsToQuery = new List<Id>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(Opportunity oppty : newOpptyList){
            if(oppty.StageName == 'Orders Processing'){
                ownerIdsToQuery.add(oppty.OwnerId);
                oppsToUpdate.add(oppty);
            }
        }

        if(!ownerIdsToQuery.isEmpty()){
            Map<Id, User> queriedOwners = new Map<Id, User>([SELECT Id, Team_Email_Alias__c FROM User WHERE Id IN :ownerIdsToQuery]);
            
            for(Opportunity opp : oppsToUpdate){
                opp.Team_Email_Alias__c = queriedOwners.get(opp.OwnerId).Team_Email_Alias__c;
            }
        }
    }

    // Replaces: Post Closed Won to Slack
    public static void postToSlack(List<Opportunity> newOpptyList, Map<Id, Opportunity> oldOpptyMap){
        List<Opportunity> applicableOpptys = new List<Opportunity>();
        Set<Id> applicableOpptyIds = new Set<Id>();
        Set<Id> applicableCSBellIds = new Set<Id>();
        for(Opportunity opp : newOpptyList){
            if(oldOpptyMap != null){
                if(oldOpptyMap.get(opp.Id).StageName == opp.StageName){
                    continue;
                }
            }
            System.debug('ACV bookings: ' + opp.ACV_Bookings__c + ' Express Flag: ' + opp.Express_Flag__c);
            if( opp.StageName == 'Ready to Ship' && (String.isBlank(opp.Automation_Notes__c) || (String.isNotBlank(opp.Automation_Notes__c) && !opp.Automation_Notes__c.contains('Re-Push Automation'))) &&
                opp.Type == 'Revenue Opportunity' && 
                (   (opp.ACV_Bookings__c > 833 && opp.Express_Flag__c == 1) || 
                    (opp.ACV_Bookings__c > 6250 && opp.Express_Flag__c == 0) || 
                    (opp.ACV_Bookings__c > 250 && opp.Express_Flag__c == 0) || 
                    (opp.ACV_Bookings__c > 1250 && opp.Configuration_Segment__c == 'Non Express') || 
                    opp.Industrial_Oppty__c)
                ){
                    applicableOpptys.add(opp);
                    applicableOpptyIds.add(opp.Id);
            }
            
            if (
                opp.StageName == 'Ready to Ship' && 
                opp.Type == 'Revenue Opportunity' &&
                opp.SBQQ__Renewal__c &&
                opp.Renewal__c &&
                opp.ACV_Bookings__c >= 50000
            ){
                applicableCSBellIds.add(opp.Id);
            }
        }

        if(!applicableOpptys.isEmpty()){
            List<Opportunity> queriedOpptys = [
                SELECT Id, Name, Amount_Number_Formula__c, Account.Name, Owner.FirstName, Owner.LastName, ACV_Bookings__c
                FROM Opportunity
                WHERE Id IN :applicableOpptyIds
            ];

            for(Opportunity opp : queriedOpptys){
                // Ideally we could post the entire opp list
                // but the Slack apex method is not equipped to handle multiple Opps
                SlackPublisher.Oppty oppty = new SlackPublisher.Oppty();
                oppty.opptyName = opp.Name;
                oppty.opptyOwnerFN = opp.Owner.FirstName;
                oppty.opptyOwnerLN = opp.Owner.LastName;
                oppty.opptyAmount = opp.Amount_Number_Formula__c;
                oppty.accountName = opp.Account.Name;
                oppty.opptyId = opp.Id;
                oppty.opportunityACVBookings = opp.ACV_Bookings__c;
                SlackPublisher.postToSlack(new List<SlackPublisher.Oppty>{ oppty });
            }
        }

        if (!applicableCSBellIds.isEmpty()){
            Slack_Notification__mdt mdt = [SELECT ID, Enable_SlackPublisher__c FROM Slack_Notification__mdt WHERE MasterLabel = 'Notifications' LIMIT 1];
            if (mdt.Enable_SlackPublisher__c) DMLWrapper.doInsert(new SlackPublisherAsync().prepareAsyncRequests(
                JSON.serialize(new SlackPublisherAsync.Options('CS_BELL')),
                applicableCSBellIds
            ));
        }
    }

    // Replaces: Oppty: Consolidated Processes
    public static void opptyConsolidatedProcesses(Map<Id, Opportunity> newOpptyMap, Map<Id, Opportunity> oldOpptyMap){
        Opportunity oldOpp = new Opportunity();
        Map<Id, OpportunityLineItem> lineItemsToUpdate = new Map<Id, OpportunityLineItem>();
        Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
        List<ADR_Transfer_Log__c> adrTransferLogsToUpdate = new List<ADR_Transfer_Log__c>();

        // query orgWideEmailAddresses for from argument in sendEmail methods
        OrgWideEmailAddress noReplyEmail = Utility.getOrgWideEmailAddressBasedOnAddress('no-reply@samsara.com');// [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'no-reply@samsara.com' LIMIT 1]; 
        OrgWideEmailAddress financeEmail = Utility.getOrgWideEmailAddressBasedOnAddress('finance@samsara.com');// [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'finance@samsara.com' LIMIT 1]; 
        OrgWideEmailAddress noreply =  Utility.getOrgWideEmailAddressBasedOnAddress('no-reply@samsara.com');// [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'no-reply@samsara.com' LIMIT 1];
       
        List<Opportunity> queriedOpportunities = OpportunityHelperContext.queryOpportunities(newOpptyMap.keySet()).values();

        for(Opportunity oppty : queriedOpportunities){
            if(oldOpptyMap == null){
                oldOpp = null;
            }else{
                oldOpp = oldOpptyMap.get(oppty.Id);
            }
            if(oppty.Shipping_Address_NEW__c != null && isChanged(oppty, oldOpp, Schema.Opportunity.Shipping_Address_NEW__c)){
                System.debug(LoggingLevel.INFO, 'Shipping Address Change');
                /* Replaces Node 'Product Added or Opp's Shipping Address Changes' */
                for(OpportunityLineItem oli : oppty.OpportunityLineItems){

                    /* OpportunityLineItem triggerHandlerOli;
                    if(OpportunityTriggerHandler.opportunityLineItems != null && OpportunityTriggerHandler.opportunityLineItems.get(oli.Id) != null){
                        triggerHandlerOli = OpportunityTriggerHandler.opportunityLineItems.get(oli.Id);
                    } else{
                        triggerHandlerOli = new OpportunityLineItem(Id = oli.Id, Ship_To__c = null);
                    } */

                    oli.Ship_To__c = oppty.Shipping_Address_NEW__c;
                    DMLWrapper.doUpdate(oli, new List<SObjectField>{OpportunityLineItem.Ship_To__c});
                    //OpportunityTriggerHandler.opportunityLineItems.put(oli.Id, triggerHandlerOli);
                    //lineItemsToUpdate.put(oli.Id, oli);
                    //System.debug('OpportunityProcessBuilderConversion - Running Node: Product Added or Opp\'s Shipping Address Changes');
                }
            }


            if(oppty.StageName == 'Closing'){
                if(oppty.RecordType.Name == 'Industrial Opportunity'){
                    /* Replaces Node 'HM Opp Closing' */
                     // GTMS-9687 - Null check to avoid Email exception 
                    if(oppty.Shipping_Address_NEW__r.Shipping_Contact__c != null || oppty.Shipping_Contact__c != null){ 
                        sendEmail(oppty, Id.valueOf('00X1a000000dkU0'), new List<String>{System.Label.Industrial_Opp_Closing_Email}, noReplyEmail); 
                    }
                }               
            }
            //Commented on as part of GTMS-5727: Moved the below code changes from OpportunityProcessBuilderConversion - 11/08      
            /*if(oppty.Rebate_Type_Formula__c != null){
                Opportunity returningOpp = new Opportunity();
                switch on oppty.Rebate_Type_Formula__c {
                    when 'Buyout' {
                        returningOpp.Id = oppty.Returning_Opportunity__c;
                        returningOpp.Buyout_Opportunity__c = oppty.Id;
                        DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
                                Opportunity.Buyout_Opportunity__c
                        });
                        //System.debug('OpportunityProcessBuilderConversion - Running Node: Buyout opp created');
                    }
                    when 'Subsidy' {
                        returningOpp.Id = oppty.Returning_Opportunity__c;
                        returningOpp.Subsidy_Opportunity__c = oppty.Id;
                        DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
                                Opportunity.Subsidy_Opportunity__c
                        });
                        //System.debug('OpportunityProcessBuilderConversion - Running Node: Subsidy opp created');
                    }
                    when 'Partner Referral' {
                        returningOpp.Id = oppty.Returning_Opportunity__c;
                        returningOpp.Partner_Referral_Opportunity__c = oppty.Id;
                        DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
                                Opportunity.Partner_Referral_Opportunity__c
                        });
                        //System.debug('OpportunityProcessBuilderConversion - Running Node: Partner Referral opp created');
                    }
                }
            }*/

            if(oppty.Resend_Return_Email__c){
                /* Replaces Node 'Resend Return Email Checked' */
                oppty.Resend_Return_Email__c = false;
                DMLWrapper.doUpdate(oppty, new List<SObjectField>{Opportunity.Resend_Return_Email__c});
                //oppsToUpdate.put(oppty.Id, oppty);
                //System.debug('OpportunityProcessBuilderConversion - Running Node: Resend Return Email Checked');
            }

            // TODO: License_Term__c
            if(isChanged(oppty, oldOpp, Schema.Opportunity.License_Term__c)){
                /* Replaces Node 'License Term Changes' */
                for(OpportunityLineItem oli : oppty.OpportunityLineItems){

                    oli.License_Term_Copy__c = oppty.License_Term__c;
                    DMLWrapper.doUpdate(oli, new List<SObjectField>{OpportunityLineItem.License_Term_Copy__c});

                }
            }

            if(oppty.Trial_Primary_Contact__c != null && !oppty.Trial_Primary_Contact__r.Trial_Deactivation_Email__c){
                /* Replaces Node 'Trial Contact Deactivation Email' */
                oppty.Trial_Primary_Contact__r.Trial_Deactivation_Email__c = true;
                contactsToUpdate.put(oppty.Trial_Primary_Contact__c, oppty.Trial_Primary_Contact__r);
            }

            if((oppty.OpportunityLineItems.size() > 0 || oppty.Probability >= 10) && oppty.ADR_Transfer__c != null){
                /* Replaces Node 'ADR Transfer Qualified' */
                System.debug(LoggingLevel.INFO, 'ADR Transfer Logic Called');
                if(oppty.ADR_Transfer__r.ADR_Transfer_Qualified_Date__c == null){
                    if(oppty.ACV_Bookings_SOT__c < 2000 && oppty.SBQQ__AmendedContract__c <> null){ //GTMS-9570
                        oppty.ADR_Transfer__r.ADR_Transfer_Status__c = 'Accepted - No Credit';
                    }   
                    else {
                        System.debug(LoggingLevel.INFO, 'ADR Transfer Logic Executing');
                        oppty.ADR_Transfer__r.AE_Qualified_Transfer_To__c = oppty.OwnerId;
                        oppty.ADR_Transfer__r.ADR_Manager_Name_Copy_at_Qualification__c = oppty.ADR_Transfer__r.ADR_Transfer_By__r.ManagerId;
                        oppty.ADR_Transfer__r.ADR_Role_Copy_at_Qualification__c = oppty.ADR_Transfer__r.ADR_Transfer_By__r.UserRole.Name;
                        oppty.ADR_Transfer__r.ADR_Transfer_Qualified_Date__c = System.today();
                        oppty.ADR_Transfer__r.ADR_Transfer_Status__c = 'Accepted and Qualified';
                    }
                    adrTransferLogsToUpdate.add(oppty.ADR_Transfer__r);
                    //System.debug('OpportunityProcessBuilderConversion - Running Node: ADR Transfer Qualified');
                }
            }

            if(oppty.IsWon && oldOpptyMap != null && oldOpp.StageName == 'Closed Won' && (isChanged(oppty, oldOpp, Schema.Opportunity.Amount) || isChanged(oppty, oldOpp, Schema.Opportunity.CloseDate))){
                /* Replaces Node 'Closed Won Amount Change' */
                 // GTMS-9687 - Null check to avoid Email exception 
                if(oppty.Shipping_Address_NEW__r.Shipping_Contact__c != null  || oppty.Shipping_Contact__c != null){    
                    sendEmail(oppty, Id.valueOf('00X1P0000015xqz'), new List<String> {System.Label.SFDC_Pool_Email}, financeEmail); 
                }
            }
            List<String> closedWonErrorEmailList = System.Label.Closed_Opp_Error_Emails.split(',');
            if(oldOpptyMap != null && oldOpp.StageName == 'Closed Won' && (isChanged(oppty, oldOpp, Schema.Opportunity.Amount) || isChanged(oppty, oldOpp, Schema.Opportunity.StageName))){
                 // GTMS-9687 - Null check to avoid Email exception 
                if(oppty.Shipping_Address_NEW__r.Shipping_Contact__c != null  || oppty.Shipping_Contact__c != null){    
                    sendEmail(oppty, Id.valueOf(system.label.Closed_Won_Opp_Stage_Change_Email_Template ), closedWonErrorEmailList, noreply);   
                }
            }
        }

        if(!contactsToUpdate.keySet().isEmpty()){
            DMLWrapper.doUpdate(contactsToUpdate.values());
        }

        if(!adrTransferLogsToUpdate.isEmpty()) {
            DMLWrapper.doUpdate(adrTransferLogsToUpdate);
        }
    }

    /* Helper Classes */

    // Sends an email to the appropriate email addresses 
    public static void sendEmail(Opportunity opp, Id emailTemplateId, List<String> toEmailAddresses, OrgWideEmailAddress fromEmail){
        // In the future, use a custom object or metadata type to store a dictionary of Process Builder Node Reference : Email Template Id
        // For now, the email template ID's will be hard coded
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        email.setTemplateId(emailTemplateId);
        //GTMS-9687 - If ShippingAddress.ShippingContact is null then populate opp.Shipping_Contact__c  
        email.setTargetObjectId(opp.Shipping_Address_NEW__r.Shipping_Contact__c != null ? opp.Shipping_Address_NEW__r.Shipping_Contact__c : opp.shipping_Contact__c);
        email.setTreatTargetObjectAsRecipient(false);
        email.setToAddresses(toEmailAddresses);
        email.setWhatId(opp.Id);
        email.saveAsActivity = false;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if (fromEmail != null && fromEmail.Address != null) {
            email.setOrgWideEmailAddressId(fromEmail.Id);
        }
        if(!test.isRunningTest()){
        List<Messaging.SendEmailResult> resultSend = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    	}
    }

    // Executes the Insert Product Flow with the provided parameters
    @TestVisible
    private static void executeFlow(String currencyCode, Integer discountAmount, Id oppId, Id pbId, Id productId, Integer quantity, Double salesPrice, String shipFrom, Integer shippedQuantity){
        Map<String, Object> params = new Map<String, Object>();
        params.put('inputCurrencyCode', currencyCode);
        params.put('inputDiscountAmount', discountAmount);
        params.put('inputOpportunityId', oppId);
        params.put('inputPricebook2Id', pbId);
        params.put('inputProduct2Id', productId);
        params.put('inputQuantity', quantity);
        params.put('inputSalesPrice', salesPrice);
        params.put('inputShipFromLocation', shipFrom);
        params.put('inputShippedQuantity', shippedQuantity);

        Flow.Interview.Insert_Product insertProductFlow = new Flow.Interview.Insert_Product(params);
        insertProductFlow.start();

        String oppLineItemID = (String) insertProductFlow.getVariableValue('OpportunityLineItemId');
    }
    

    // Executes the "Check if UPS Shipment Created" flow
    // Could possibly create a more generic execute flow method that accepts a Flow name and map of params
    // but would have to figure out how to appropriate call the Flow, maybe using schema methods would be possible
    @TestVisible
    private static void executeFlow(Id oppId){
        Map<String, Object> params = new Map<String, Object>();
        params.put('OpportunityId', oppId);

        Flow.Interview.Check_If_UPS_Shipment_Created checkShipmentCreated = new Flow.Interview.Check_If_UPS_Shipment_Created(params);
        checkShipmentCreated.start();
    }
    

    // Helper method for comparing whether a certain field changed between an old opportunity and new opportunity
    private static Boolean isChanged(Opportunity newOpp, Opportunity oldOpp, Schema.SObjectField field){
        if(field == Schema.Opportunity.Shipping_Address_NEW__c ){
            System.debug(LoggingLevel.INFO, 'Hitting change of Shipping Address field');
        }

        if(oldOpp == null){
            return true;
        }else if(newOpp.get(field) != oldOpp.get(field)){
            return true;
        }else{
            return false;
        }
    }

    // Currently being handled by process builder Oppty: Consolidated Processes
    // Helper method for the node 'Stamp Director On Stage Change' and 'Stamp Manager on Stage Change', since this is a long formula and is used more than once
    @TestVisible
    private static Object managerFormula(Opportunity oppty, String managerType){
        Object returnObject = null;
        if(oppty.Type == 'Revenue Opportunity' || oppty.Type == 'Free Trial Opportunity' || oppty.Type == 'Promo Opportunity' || ((oppty.Type == 'Rebate' || oppty.Type == 'Remorse Refund') && oppty.Owner.UserRole.Name.Contains('SMB') && oppty.Returning_Opportunity__r.Owner_Role_Copy__c.Contains('SMB'))){
            switch on managerType {
                when 'Manager Name' {
                    returnObject = oppty.Owner.ManagerId;
                }
                when 'Manager Role' {
                    returnObject = oppty.Owner.Manager.UserRole.Name;
                }
                when 'Director Name' {
                    returnObject = oppty.Owner.Manager.ManagerId;
                }
            }
        }else{
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
            }
        }

        return returnObject;
    }
    

    public static void closingOppWithStripeTrialOrExpessFinanceApproval(Map<Id, Opportunity> newOpptyMap,Map<Id, Opportunity> oldOpptyMap) {
        
        Map<Id, Opportunity> oppMapforTax = new Map<Id, Opportunity>();
        if (OpportunityHelperContext.oppAccounts == null) OpportunityHelperContext.loadOppAccounts(newOpptyMap.values());
        for (Opportunity oppty : newOpptyMap.values()) {
            if(oldOpptyMap.get(oppty.id).StageName != oppty.StageName && oppty.StageName == 'Closing' && oppty.Amount != 0 && oppty.SBQQ__PrimaryQuote__c != null && oppty.Is_Webstore_Upsell_Opportunity__c == true){
                oppMapforTax.put(oppty.id,oppty);
            }
            Boolean isOrderValidation =   (new OrderValidationServiceAutomation()).checkingmaincriteria1(oppty,oldOpptyMap.get(oppty.id));
            
       
            Account acc  = OpportunityHelperContext.oppAccounts.containsKey(oppty.AccountId) ? OpportunityHelperContext.oppAccounts.get(oppty.AccountId) : null;
            
            If(oldOpptyMap.get(oppty.id).StageName != oppty.StageName && oppty.StageName == 'Closing') {
                
                if(!isOrderValidation  &&  !(oppty.Type != 'Free Trial Opportunity' && oppty.Type != 'Promo Opportunity' && acc != null 
                                             && acc.Customer_require_PO_for_invoicing__c == 'Yes' && (oppty.PO_Number__c == '-' || oppty.PO_Number__c == '' || oppty.PO_Number__c == null))
                   && ((oppty.Type == 'Free Trial Opportunity' || oppty.Type == 'Promo Opportunity' || oppty.Stripe_Subscription_Id__c != null) 
                       || (oppty.Type == 'Revenue Opportunity' && (oppty.Finance_Notes__c != null || oppty.Payment_Token__c != null )
                           && ((oppty.Express_Agreement_Accepted_Date__c <> null && oppty.Price_Book_Name__c != null && oppty.Configuration_Segment__c == 'Express')
                               || (oppty.Amount >0 && oppty.Balance_Due__c < 10)))))
                {
                    /* Replaces Node 'Closing Opp with Stripe/Trial OR Express/Finance Approval' */
                    
                    oppty.Overwrite_Validation_Rule__c = true;
                    oppty.Probability = 98;
                    oppty.StageName = 'Orders Processing';
                    oppty.Went_to_Orders_Processing_Date__c = Datetime.Now();
                    oppty.Went_to_Orders_Processing__c = TRUE;
                    
                    LOGGER.atInfo().setCLassName('OpportunityProcessBuilderConversion').setMethod('closingOppWithStripeTrialOrExpessFinanceApproval').setRecordId(oppty.Id).setExceptionOrMessage(getLoggerMessage('Order automation success in closingOppWithStripeTrialOrExpessFinanceApproval method : Record Data -> ' + JSON.serialize(oppty)));
                
                } else {
                    
                    LOGGER.atInfo().setCLassName('OpportunityProcessBuilderConversion').setMethod('closingOppWithStripeTrialOrExpessFinanceApproval').setRecordId(oppty.Id).setExceptionOrMessage(getLoggerMessage('Order automation failed because orders processing conditions are not satisfied : Record Data -> ' + JSON.serialize(oppty)));
                }
                
                if(isOrderValidation) {
                    LOGGER.atInfo().setCLassName('OpportunityProcessBuilderConversion').setMethod('checkingmaincriteria1').setRecordId(oppty.Id).setExceptionOrMessage(getLoggerMessage('Order automation failed because order validation conditions are not satisfied : Record Data -> ' + JSON.serialize(oppty)));
                }
                
            }
        }
            
        //Query to get the tax rate from the Quote based on query from Opportunity

        if(oppMapforTax.size() > 0){
           for(Opportunity opp : [SELECT Id,Sales_Tax_Amount__c, SBQQ__PrimaryQuote__c,SBQQ__PrimaryQuote__r.Sales_Tax__c FROM Opportunity WHERE Id IN :oppMapforTax.keySet() AND SBQQ__PrimaryQuote__r.Sales_Tax__c != Null]){
            if(opp.Sales_Tax_Amount__c != opp.SBQQ__PrimaryQuote__r.Sales_Tax__c){
                newOpptyMap.get(opp.id).Sales_Tax_Amount__c = opp.SBQQ__PrimaryQuote__r.Sales_Tax__c;
              }
           } 
        }
        Logger.setFunctionalityType('Order Automation Logging');
        Logger.insertMasterLogs();
    }
    

    /*
     * added for GTMS-23648 this will old logic Partner_Referral_Amount__c formula
    */
    public static void setPartnerReferralAmount(List<Opportunity> newOpptyList) {
        list<CurrencyType> currencyTpyeList = [SELECT ISOCode, ConversionRate FROM CurrencyType WHERE IsActive=TRUE];
        Map<String , Decimal> isoWithRateMap = new Map<String, Decimal>();
        for(CurrencyType c : currencyTpyeList) {
            isoWithRateMap.put(c.IsoCode , c.ConversionRate) ;
        }
        for (Opportunity oppty : newOpptyList) {
            // check if closeddate 2024-10-01 and Probability < 95
            // check if closeddate 2025-02-01 and Probability < 95 and ACV_Bookings_SOT__c > 250000
            // account id is in Partner_Referral_Exclude_Account 
            Decimal acvInUSD = (oppty.CurrencyIsoCode != 'USD') ? oppty.ACV_Bookings_SOT__c / isoWithRateMap.get(oppty.CurrencyIsoCode) : oppty.ACV_Bookings_SOT__c;
            String excludedAccount = System.Label.Partner_Referral_Exclude_Account;
            if ( (string.isNotBlank(oppty.Referral_Partner__c) && excludedAccount.contains(oppty.Referral_Partner__c)) || 
                ((oppty.Probability < 95 && oppty.CloseDate < Date.newinstance(2024, 10, 01)) ||
                (oppty.Probability < 95 && oppty.CloseDate < Date.newinstance(2025, 02, 01) && acvInUSD > 200000)
                && oppty.CreatedDate < datetime.newInstance(2024, 09, 04))) 
            {
                if(string.isNotBlank(oppty.Referral_Partner__c) && oppty.Referral_Rebate__c != null &&
                   oppty.Uncapped_Partner_Referral_Payout_Amount__c == true && 
                   ((-(oppty.ACV_Bookings_SOT__c/(1-(oppty.Blended_Discount__c/100)) * (oppty.Referral_Rebate__c/100)) < -50000)
                  )){
                      oppty.Partner_Referral_Amount_Field__c = -(oppty.ACV_Bookings_SOT__c/(1-(oppty.Blended_Discount__c/100)) * (oppty.Referral_Rebate__c/100));
                  }
                else if (string.isNotBlank(oppty.Referral_Partner__c) && oppty.Referral_Rebate__c != null &&
                         oppty.Uncapped_Partner_Referral_Payout_Amount__c == false && 
                         ((-(oppty.ACV_Bookings_SOT__c/(1-(oppty.Blended_Discount__c/100)) * (oppty.Referral_Rebate__c/100)) < -50000)
                        )) {
                            oppty.Partner_Referral_Amount_Field__c = -50000;
                        }
                else if (string.isNotBlank(oppty.Referral_Partner__c) && oppty.Referral_Rebate__c != null &&
                         
                         ((-(oppty.ACV_Bookings_SOT__c/(1-(oppty.Blended_Discount__c/100))) * (oppty.Referral_Rebate__c/100)) >= -50000)
                        ) {
                            oppty.Partner_Referral_Amount_Field__c = -(oppty.ACV_Bookings_SOT__c/(1-(oppty.Blended_Discount__c/100))) * (oppty.Referral_Rebate__c/100);
                        }
                else {
                    oppty.Partner_Referral_Amount_Field__c = 0;
                }
                
            }
            else {
                if(string.isNotBlank(oppty.Referral_Partner__c) && oppty.Referral_Rebate__c != null &&
                   oppty.Uncapped_Partner_Referral_Payout_Amount__c == true && 
                   (-(oppty.ACV_Bookings_SOT__c * (oppty.Referral_Rebate__c/100)) < -50000)
                  ) {
                      oppty.Partner_Referral_Amount_Field__c = -(oppty.ACV_Bookings_SOT__c * (oppty.Referral_Rebate__c/100));
                  }
                else if (string.isNotBlank(oppty.Referral_Partner__c) && oppty.Referral_Rebate__c != null &&
                         oppty.Uncapped_Partner_Referral_Payout_Amount__c == false && 
                         (-(oppty.ACV_Bookings_SOT__c * (oppty.Referral_Rebate__c/100)) < -50000)
                        ) {
                            oppty.Partner_Referral_Amount_Field__c = -50000;
                        }
                else if (string.isNotBlank(oppty.Referral_Partner__c) && oppty.Referral_Rebate__c != null &&
                         
                         (-(oppty.ACV_Bookings_SOT__c * (oppty.Referral_Rebate__c/100)) >= -50000)
                        ) {
                            oppty.Partner_Referral_Amount_Field__c = -(oppty.ACV_Bookings_SOT__c * (oppty.Referral_Rebate__c/100));
                        }
                else {
                    oppty.Partner_Referral_Amount_Field__c = 0;
                }
            }
        }
    }
    //Frame your Logger message 
    public Static String getLoggerMessage(String message) {
        return message.length() > 130072 ? message.substring(0, 130072) : message;
    }
}