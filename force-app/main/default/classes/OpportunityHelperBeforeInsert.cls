/**********************************************************************
Name: OpportunityHelperBeforeInsert

Purpose: This class will contains method that will be called in the before insert context                                                    

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Apr-11        INITIAL DEVELOPMENT 


***********************************************************************/
public class OpportunityHelperBeforeInsert extends OpportunityHelperContext {
    // Begin trigger methods
    //* 12/17/2020 Ron, Harsha (GTMS-2395) beforeInsertOnly (Configuration Segment)
    public void beforeInsertOnly(List<Opportunity> newOppList) {
        valueforSelectedPaymentType(newOppList);
        // Load up the opp accounts static list.
        Set<Id> contractIds = new Set<Id>();
        //GTMS-8352
        Set<Id> returnIds = new Set<Id>();
        Map<Id, Id> rebateOppByOwnerId = new Map<Id, Id>();
        //GTMS-8640, 8059
        List<String> cwRoboIds = System.Label.Corpweb_SFDC_Robot.split(',');
        List<Opportunity> amendmentOppsList = new List<Opportunity>();
        String configurationSegment;
        loadOppAccounts(newOppList);
        Set<Id> mxnOpptyIdSet = new Set<Id>();
        Set<Id> originalMxnOpptyIdSet = new Set<Id>();
        Id ReturnOppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        for (Opportunity o : newOppList) {
            if (o.ContractId != NULL) {
                contractIds.add(o.ContractId);
            }
            // Renewal Code - Harsha
            if(o.SBQQ__AmendedContract__c != null){
                contractIds.add(o.SBQQ__AmendedContract__c);
                amendmentOppsList.add(o);
            }
            if(o.SBQQ__RenewedContract__c != null){
                contractIds.add(o.SBQQ__RenewedContract__c);
            }
            //GTMS-16445 Setting UUID in opportunity
            o.Opportunity_UUID__c = SSUtils.getUUID();
            //GTMS-8352
            if(o.type=='Rebate' && o.rebate_type__c=='Delinquent' && o.Returning_Opportunity__c != null){
                returnIds.add(o.Returning_Opportunity__c);
            }
            if ((o.AccountId != NULL && oppAccounts.containsKey(o.AccountId) && oppAccounts.get(o.AccountId).CurrencyIsoCode == 'MXN' && o.CurrencyIsoCode != 'MXN') || Test.isRunningTest()) {
                if (o.Type == 'Promo Opportunity' && o.RMA_Return_Opportunity__c != null) {
                    String[] parts = o.RMA_Return_Opportunity__c.split('/');
                    String rmaOppty = parts[parts.size() - 1];
                    if (rmaOppty != null && rmaOppty.startsWith('0')) {
                        mxnOpptyIdSet.add(rmaoppty);
                    }
                } else if (o.RecordTypeId == ReturnOppRecTypeId && o.Returning_Opportunity__c != null) {
                    mxnOpptyIdSet.add(o.Returning_Opportunity__c);
                }
            }
        }
        if (contractIds.size() > 0) {
            loadContracts(contractIds);
        }
         //GTMS-29420
        //This will only run if the Account Currency is MXN and Opportunity Curreny is not MXN and if it is Promo/Return oppty created from another opportunity.
        if (!mxnOpptyIdSet.isEmpty()) {
            for (Opportunity opp: [SELECT Id, CurrencyISOCode FROM Opportunity WHERE Id IN: mxnOpptyIdSet]) {
                if (opp.CurrencyISOCode == 'MXN') {
                    originalMxnOpptyIdSet.add(opp.Id);
                }
            }
        }

        /*
        //GTMS-8352
        //GTMS-29333: Shifted Rebate and Remorse Refund owner assignment logic to ReturnOwnerCopyDataUtility
        if(!returnIds.isEmpty()){
            rebateOppByOwnerId = getOwnerForDelinquentRebateOpportunity(returnIds);
        }
        //GTMS-29420
        //This will only run if the Account Currency is MXN and Opportunity Curreny is not MXN and if it is Promo/Return oppty created from another opportunity.
        if (!mxnOpptyIdSet.isEmpty()) {
            for (Opportunity opp: [SELECT Id, CurrencyISOCode FROM Opportunity WHERE Id IN: mxnOpptyIdSet]) {
                if (opp.CurrencyISOCode == 'MXN') {
                    originalMxnOpptyIdSet.add(opp.Id);
                }
            }
        }
        //GTMS-7139
        //id ReturnOppRecTypeId = [Select Id,name from RecordType where name='Return Opportunity' AND SobjectType='Opportunity'].id;
        for(Opportunity o : newOppList)
        {
            if(o.RecordTypeId == ReturnOppRecTypeId && (o.Type == 'Exchange' || o.Type == 'Warranty Exchange' || o.Type == 'Free Trial Return' || o.Type == 'Remorse Refund'))
            {
                //Populating billing payment type as 'SENDER' for the non-US countries
                if(o.Shipmate_Country__c != 'United States')
                {
                    o.Billing_Payment_Type__c = 'shipper';
                }
                //Populating the service type for various countries
                if(o.Shipmate_Country__c == 'United States')
                {
                    o.Shipmate_Service_Type__c = 'ups_ground';
                }
                else if(o.Shipmate_Country__c == 'Canada')
                {
                    o.Shipmate_Service_Type__c = 'ups_worldwide_express';
                }
                else if(o.Shipmate_Country__c == 'Mexico')
                {
                    o.Shipmate_Service_Type__c = 'ups_worldwide_saver';
                }
                else if(o.Shipmate_Country__c == 'Ireland' ||o.Shipmate_Country__c == 'United Kingdom' || o.Shipmate_Country__c == 'France' || o.Shipmate_Country__c == 'Germany' || o.Shipmate_Country__c == 'Austria' || o.Shipmate_Country__c == 'Italy' || o.Shipmate_Country__c == 'Switzerland' || o.Shipmate_Country__c == 'Spain' || o.Shipmate_Country__c == 'Netherlands')
                {
                    o.Shipmate_Service_Type__c = 'ups_standard';
                }
            }
            If(o.Type == 'Free Trial Opportunity' && o.SBQQ__AmendedContract__c != Null){
                if(contractsMap != Null && contractsMap.get(o.SBQQ__AmendedContract__c) != Null && contractsMap.get(o.SBQQ__AmendedContract__c).endDate != Null){
                    o.License_End_Date__c = contractsMap.get(o.SBQQ__AmendedContract__c).endDate;
                }
            }
            //GTMS-15659 added to set initial value for smart approval
            DateTime myDateTime = DateTime.now();
            o.Smart_Approve_Standard_Term_Indicator__c = myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year();
        }
        /*GTMS-6422: Commenting this code as business requested to place this change onhold
if(amendmentOppsList.size()>0){
loadChannelRelationshipRecords(amendmentOppsList);
}*/
        
        // GTMS-27516 Tag Reseller partners on Amendment Opportunity only for the given accounts IDs(added in metadata)
        Map<String,Reseller_Partner_Account_Config__mdt>  resellerPartnerConfigMap = Reseller_Partner_Account_Config__mdt.getAll();
        Set<Id> activeResellerAmendAccountIds = new Set<Id>();
        Set<Id> activeResellerRenewAccountIds = new Set<Id>();
        List<String> europeanGeographies = System.Label.European_Geographies.split(','); 
        
        for (Reseller_Partner_Account_Config__mdt config : resellerPartnerConfigMap.values()) {
            if (
                config.Active__c &&
                config.Account_Id__c != null &&
                (config.Account_Id__c.length() == 15 || config.Account_Id__c.length() == 18) &&
                config.Account_Id__c.startsWith('001')
            ) {
                if(config.Category__c == 'Opportunity Amendment') 
                    activeResellerAmendAccountIds.add(config.Account_Id__c);
                else if (config.Category__c == 'Opportunity Renewal')
                    activeResellerRenewAccountIds.add(config.Account_Id__c);
            }
        }
        
        for (Opportunity o : newOppList) {
            Account thisOppAccount = new Account();
            if (o.AccountId != NULL && oppAccounts.containsKey(o.AccountId)) {
                thisOppAccount = oppAccounts.get(o.AccountId);
                o.Account_Owners_18_Digit_User_ID__c = oppAccounts.get(o.AccountId).ownerId;
                //GTMS-6422: Updating the Partner fields on the Amendment opportunity based on the program type information populated on the customer account
                if(o.SBQQ__AmendedContract__c!= null){
                    if(thisOppAccount.Latest_Partner_Account_Interaction__c != null){
                        if(!cwRoboIds.contains(UserInfo.getUserId()) && thisOppAccount.Latest_Partner_Program_Interaction__c != null && thisOppAccount.Latest_Partner_Program_Interaction__c =='Resale')
                        { // GTMS-8640, 8059
                            
                            if (
                                !activeResellerAmendAccountIds.isEmpty() &&
                                activeResellerAmendAccountIds.contains(thisOppAccount.Latest_Partner_Account_Interaction__c)
                            ) {
                                o.Reseller_Partner__c = thisOppAccount.Latest_Partner_Account_Interaction__c; //GTMS-27516 Only set Reseller_Partner__c if the account is in the active set retrieved from Reseller_Partner_Account_Config__mdt 
                                o.Reseller__c = thisOppAccount.Latest_Partner_Account_Interaction__c; // GTMS-27654
                            }
                        } 
                        else if(!cwRoboIds.contains(UserInfo.getUserId()) && thisOppAccount.Latest_Partner_Program_Interaction__c!= null &&
                                (thisOppAccount.Latest_Partner_Program_Interaction__c == 'Subsidy' || thisOppAccount.Latest_Partner_Program_Interaction__c =='Premium Discount')){
                                    o.Insurance_Partner__c = thisOppAccount.Latest_Partner_Account_Interaction__c;
                                }
                        /*** PARTNER RECORD TYPE PROJECT CHANGES: Commenting this code as the requirement for this change is temporarily onhold
else if(thisOppAccount.Latest_Partner_Program_Interaction__c!= null &&
(thisOppAccount.Latest_Partner_Program_Interaction__c == 'Paid Referral'|| thisOppAccount.Latest_Partner_Program_Interaction__c == 'Unpaid Referral') ){
if(crMap!=null && crMap.containsKey(thisOppAccount.Id)){
List<Channel_Relationship__c> crList = new List<Channel_Relationship__c>();
crList = crMap.get(thisOppAccount.Id);
System.debug(crList);
for(Channel_Relationship__c cr : crList){
Date crDate = cr.CreatedDate.Date();
if((cr.Program_Type__c == 'Paid Referral' || cr.Program_Type__c == 'Unpaid Referral')
&& crDate.daysBetween(Date.today()) < 365){
system.debug('cr: '+cr);
o.Referral_Partner__c = cr.Channel_Partner__c;
}
}
}
}*/
                    }
                }
                //GTMS-27021 To populate Renewal/Amendment Opportunity Vat Number on creation
                if((o.SBQQ__AmendedContract__c != null || o.SBQQ__RenewedContract__c != null || o.SBQQ__Renewal__c == true) 
                   && thisOppAccount.VATId__c != null && thisOppAccount.Global_Geography__c != null && europeanGeographies.contains(thisOppAccount.Global_Geography__c)) {
                       o.VAT_Number__c = thisOppAccount.VATId__c;
                   }
            }
            if(contractsMap.containsKey(o.SBQQ__AmendedContract__c)){
                contract originalContract = contractsMap.get(o.SBQQ__AmendedContract__c);
                //GTMS-7487-June22
                if(!o.Is_Webstore_Upsell_Opportunity__c || (o.Account.Book_Of_Business__c == Null && o.Is_Webstore_Upsell_Opportunity__c)){
                    o.Payment_Terms__c = originalContract.SBQQ__Opportunity__r.Payment_Terms__c;
                }
                o.Shipping_Contact__c = originalContract.SBQQ__Opportunity__r.Shipping_Contact__c;
                o.Approved_Discount__c = originalContract.SBQQ__Opportunity__r.Approved_Discount__c;
                //o.Selected_Payment_Type__c = originalContract.SBQQ__Opportunity__r.Selected_Payment_Type__c;
                o.Name = 'Amendment - '+ originalContract.Account.Name.Left(Integer.valueOf(System.Label.Opportunity_Account_Name_Limit)) + ' - ' + originalContract.ContractNumber;
                //GTMS-10933
                if(thisOppAccount.Account_Size_Segment__c == 'AE1'){
                    system.debug(' SBQQ__AmendedContract ' +o.SBQQ__AmendedContract__c);
                    system.debug(' Account_Size_Segment ' +thisOppAccount.Account_Size_Segment__c);
                    o.License_End_Date__c = originalContract.EndDate;
                }
            }
            if(contractsMap.containsKey(o.SBQQ__RenewedContract__c)){
                contract originalContract = contractsMap.get(o.SBQQ__RenewedContract__c);
                //GTMS-7487-June22
                if(!o.Is_Webstore_Upsell_Opportunity__c || (o.Account.Book_Of_Business__c == Null && o.Is_Webstore_Upsell_Opportunity__c)){
                    o.Payment_Terms__c = originalContract.SBQQ__Opportunity__r.Payment_Terms__c;
                }
                o.Shipping_Contact__c = originalContract.SBQQ__Opportunity__r.Shipping_Contact__c;
                //o.Selected_Payment_Type__c = originalContract.SBQQ__Opportunity__r.Selected_Payment_Type__c;
                o.Finance_Partner__c = originalContract.SBQQ__Opportunity__r.Finance_Partner__c;
                o.Shipping_Address_NEW__c = originalContract.SBQQ__Opportunity__r.Shipping_Address_NEW__c;
                o.Original_AE__c = originalContract.SBQQ__Opportunity__r.OwnerId;
                o.Approved_Discount__c = originalContract.SBQQ__Opportunity__r.Approved_Discount__c;
                o.Name = 'Renewal - '+ originalContract.Account.Name.Left(Integer.valueOf(System.Label.Opportunity_Account_Name_Limit)) + ' - ' + originalContract.ContractNumber;
                //GTMS-12059 - Renewal Opportunity Close Date should be set to the day after the renewal contract end date
                if(o.Renewal__c || o.SBQQ__Renewal__c){
                    o.CloseDate = originalContract.EndDate.addDays(1);
                }
                
                // Update Available_TO_Renew__c field from Contract_Renewable_ACV__c GTMS 29264
                o.Available_TO_Renew__c = originalContract.Contract_Renewable_ACV_USD__c;
                
                if(!cwRoboIds.contains(UserInfo.getUserId())){
                    if(!o.Renewal__c) {
                        o.Insurance_Partner__c = originalContract.SBQQ__Opportunity__r.Insurance_Partner__c; //.GTMS 8059
                    }
                    if (
                        !activeResellerRenewAccountIds.isEmpty() && originalContract.SBQQ__Opportunity__r.Reseller_Partner__c != null &&
                        activeResellerRenewAccountIds.contains(originalContract.SBQQ__Opportunity__r.Reseller_Partner__c)
                    ) {
                        o.Reseller_Partner__c = originalContract.SBQQ__Opportunity__r.Reseller_Partner__c; //GTMS-27654 Only set Reseller_Partner__c if the account is in the active set retrieved from Reseller_Partner_Account_Config__mdt 
                        o.Reseller__c = originalContract.SBQQ__Opportunity__r.Reseller__c; // GTMS-27654
                    }
                }
            }
            //GTMD 8640, 8059
            if (!cwRoboIds.contains(UserInfo.getUserId()) && o.Type == 'Rebate' && o.Returning_Opportunity__r.Reseller_Partner__c != NULL) {
                o.Reseller_Partner__c = o.Returning_Opportunity__r.Reseller_Partner__c;
            }
            // Code to populate the Shipping Address New on opportunity create
            //Zakeer: added condition -- GTMS5381
            if ((thisOppAccount.Shipping_Addresses__r.size() > 0) && ((String.valueOf(o.Type) == 'Revenue Opportunity') || (String.valueOf(o.Type) == 'Free Trial Opportunity') || (String.valueOf(o.Type) == 'Promo Opportunity')) && !cwRoboIds.contains(UserInfo.getUserId())){
                Shipping_Address__c relatedShippingAddress = thisOppAccount.Shipping_Addresses__r;
                if(o.Shipping_Address_NEW__c == null){
                    o.Shipping_Address_NEW__c = relatedShippingAddress.id;
                }
                if(String.valueOf(relatedShippingAddress.Shipping_Country__c) != String.valueOf(o.Shipping_Country__c)){
                    o.Shipping_Country__c = relatedShippingAddress.Shipping_Country__c;
                }
                HelperClass.setShippingDefaults(o, NULL, relatedShippingAddress.Shipping_Country__c);
            }
            //Clears out serial numbers on opportunities - @Tommy
            if (o.All_Serial_Numbers__c != NULL) {
                o.All_Serial_Numbers__c = NULL;
            }
            // Code to update VAT if it is available on the Account -@Harsha
            // o.VAT_Number__c = thisOppAccount.VATId__c;
            o.Shipping_Country__c = thisOppAccount.BillingCountry;
            o.Shipping_State__c = thisOppAccount.BillingState;
            if(o.Pricebook2Id == null && !Test.isRunningTest()){
                o.Pricebook2Id = System.Label.Current_Active_Pricebook;
            }
            // GTMS-25293 Check if Account currency is 'MXN' and set Opportunity's CurrencyIsoCode
             if (thisOppAccount.CurrencyIsoCode == 'MXN' || Test.isRunningTest()) {
                if ( thisOppAccount.Owner.UserRole!=null && thisOppAccount.Owner.UserRole.Name.contains('MX') && thisOppAccount.Owner.UserRole.Name.contains('AE') &&  thisOppAccount.Owner.CurrencyIsoCode =='MXN')  {
                    o.CurrencyIsoCode = thisOppAccount.CurrencyIsoCode;
                } else if ((o.CurrencyIsoCode == 'MXN' && ((o.Type == 'Promo Opportunity' && o.RMA_Return_Opportunity__c != null) || (o.RecordTypeId == ReturnOppRecTypeId && o.Returning_Opportunity__c != null)))) {
                    //skip
                } else {
                    o.CurrencyIsoCode = 'USD';
                }
                if (!originalMxnOpptyIdSet.isEmpty() && o.CurrencyIsoCode != 'MXN') {
                    if (o.Type == 'Promo Opportunity' && o.RMA_Return_Opportunity__c != null) {
                         String[] parts = o.RMA_Return_Opportunity__c.split('/');
                         String rmaOppty = parts[parts.size() - 1];
                        if (originalMxnOpptyIdSet.contains(rmaOppty)) {
                            o.CurrencyIsoCode = 'MXN';
                        }
                    } else if (o.RecordTypeId == ReturnOppRecTypeId && o.Returning_Opportunity__c != null && originalMxnOpptyIdSet.contains(o.Returning_Opportunity__c)) {
                        o.CurrencyIsoCode = 'MXN';
                    }
                }
            }
            configurationSegment = thisOppAccount.Segment__c != null && thisOppAccount.Segment__c.contains(System.Label.Account_Express_Segment) ? 'Express' : 'Non Express';
            o.Configuration_Segment__c = configurationSegment;
            if(o.Name.contains('Renewal') && o.SBQQ__RenewedContract__c != null && o.OwnerId != System.Label.Renewal_Pool_User){
                o.OwnerId = System.Label.Renewal_Pool_User;
                o.Renewal__c = TRUE;
            }
            //GTMS-8011
            if(o.Name.toLowerCase().contains('renewal') && thisOppAccount.Renewal_AE__c != null){
                o.OwnerId = thisOppAccount.Renewal_AE__c;
            }
            //GTMS-8352
            //GTMS-29333: Shifted Rebate and Remorse Refund owner assignment logic to ReturnOwnerCopyDataUtility
            /*
            if(o.type=='Rebate' && o.rebate_type__c=='Delinquent' && rebateOppByOwnerId != null && rebateOppByOwnerId.containsKey(o.Returning_Opportunity__c)){
                o.ownerId = rebateOppByOwnerId.get(o.Returning_Opportunity__c);
                system.debug('---Owner Id set in Before Insert --'+o.ownerId);
            }
            */
        }
        
        // GTMS-28647/GTMS-28397 - Process amend opportunities AFTER all other processing to ensure our stage setting is not overridden
        processAmendOpportunities(newOppList);
    }
    
    //GTMS -10938
    public  void valueforSelectedPaymentType(List<Opportunity> newOppList) {
        Set<Id> contractIds = new Set<Id>();
        List<Opportunity> renewedOpps = new List<Opportunity>();
        for(Opportunity opp : newOppList){
            if(opp.SBQQ__Renewal__c == true && opp.SBQQ__RenewedContract__c <> null){
                contractIds.add(opp.SBQQ__RenewedContract__c);
                renewedOpps.add(opp);
            }
        }
        Map<Id,Contract> conMap = new Map<Id,Contract>([SELECT Id, SBQQ__Opportunity__r.Selected_Payment_Type__c,SBQQ__RenewalOpportunity__r.Selected_Payment_Type__c FROM Contract WHERE ID IN : contractIds]);
        Map<Id,Opportunity> amendOpps = new Map<Id,Opportunity>([SELECT Id, SBQQ__AmendedContract__c,Selected_Payment_Type__c FROM Opportunity WHERE SBQQ__AmendedContract__c IN : contractIds]);
        Map<Id, Map<id, String>> amendedOppsForContracts = new Map<Id, Map<id, String>>();
        for(Opportunity o : amendOpps.values()){
            if(o.SBQQ__AmendedContract__c <> null && !amendedOppsForContracts.containsKey(o.SBQQ__AmendedContract__c)){
                Map<id, string> amendOpPayment =  new Map<id, string>();
                amendOpPayment.put(o.id,o.Selected_Payment_Type__c);
                amendedOppsForContracts.put(o.SBQQ__AmendedContract__c, amendOpPayment);
            }
            else{
                amendedOppsForContracts.get(o.SBQQ__AmendedContract__c).put(o.id, o.Selected_Payment_Type__c);
            }
        }
        for(Opportunity opp : newOppList){
            if(opp.SBQQ__Renewal__c == true && opp.SBQQ__RenewedContract__c <> null){
                if(amendedOppsForContracts.containsKey(opp.SBQQ__RenewedContract__c)){
                    boolean isAmendOppPaymentDiffernt = false;
                    string strConOriginalOppPaymentType = '';
                    if(conMap.containsKey(opp.SBQQ__RenewedContract__c)){
                        strConOriginalOppPaymentType = (conMap.get(opp.SBQQ__RenewedContract__c)).SBQQ__Opportunity__r.Selected_Payment_Type__c;
                    }
                    for(String s : amendedOppsForContracts.get(opp.SBQQ__RenewedContract__c).values()){
                        if(strConOriginalOppPaymentType != s){
                            isAmendOppPaymentDiffernt = true;
                            break;
                        }
                    }
                    if(isAmendOppPaymentDiffernt){
                        opp.Selected_Payment_Type__c = 'Direct Annual';
                    }
                    else{
                        opp.Selected_Payment_Type__c = strConOriginalOppPaymentType;
                    }
                }
                else if(conMap.containsKey(opp.SBQQ__RenewedContract__c)){
                    opp.Selected_Payment_Type__c = (conMap.get(opp.SBQQ__RenewedContract__c)).SBQQ__Opportunity__r.Selected_Payment_Type__c;
                }
            }
        }
    }
    
    /**
     * GTMS-28647/GTMS-28397 - Process amend opportunities to set stage to 'Qualified' and optionally link contact
     * Contact selection is OPTIONAL - opportunity stage is set regardless of contact selection
     * @param newOppList List of new opportunities
     */
    @TestVisible
    public void processAmendOpportunities(List<Opportunity> newOppList) {
        if (newOppList == null || newOppList.isEmpty()) {
            return;
        }
        
        System.debug('*** GTMS-28647: processAmendOpportunities called with ' + newOppList.size() + ' opportunities');
        
        Set<Id> amendOppAccountIds = new Set<Id>();
        List<Opportunity> amendOpportunities = new List<Opportunity>();
        
        // First pass: Identify amend opportunities and collect account IDs
        for (Opportunity opp : newOppList) {
            if (isAmendOpportunity(opp)) {
                // ALWAYS set stage to Qualified for amend opportunities (contact is optional)
                opp.StageName = 'Qualified';
                if (opp.AccountId != null) {
                    amendOppAccountIds.add(opp.AccountId);
                    amendOpportunities.add(opp);
                }
            }
        }
        
        // Only proceed with contact matching if we have amend opportunities
        if (amendOppAccountIds.isEmpty()) {
            return;
        }
        
        Map<String, Map<String, String>> contractConAccMap = bulkMatchOpportunitiesWithContacts(amendOppAccountIds);
        
        // Second pass: Match contacts only for amend opportunities
        if (contractConAccMap != null && !contractConAccMap.isEmpty()) {
            for (Opportunity opp : amendOpportunities) {
                String contractNumber = extractContractNumberFromOpportunityName(opp.Name);
                if (String.isNotBlank(contractNumber)) {
                    Map<String, String> conAccMap = contractConAccMap.get(contractNumber);
                    if (conAccMap != null && opp.AccountId != null) {
                        String contactId = conAccMap.get(String.valueOf(opp.AccountId));
                        if (String.isNotBlank(contactId)) {
                            opp.Related_Contact__c = contactId;
                        }
                    }
                }
            }
        }
    }
        
    
    /**
     * GTMS-28647/GTMS-28397 - Simple, optimized contact query for amend processing
     * @param accountIds Set of account IDs to limit the contact query
     * @return Map of contract number to contact
     */
    private List<Contact> getContacts(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new List<Contact>();
        }
        
        List<Contact> contactList = new List<Contact>();
        try {
            contactList = [
                SELECT Id, AccountId, Amended_Contract_Number__c 
                FROM Contact 
                WHERE AccountId IN :accountIds
                AND Amended_Contract_Number__c != null
                LIMIT 200
            ];
        } catch (Exception e) {
            System.debug('Error querying contacts: ' + e.getMessage());
            // Return empty list instead of null on error
            contactList = new List<Contact>();
        }
        
        return contactList;
    }
    
    /**
     * GTMS-28647/GTMS-28397 - Check if opportunity is an amend opportunity
     * @param opp The opportunity to evaluate
     * @return true if this is an amend opportunity
     */
    private Boolean isAmendOpportunity(Opportunity opp) {
        if (opp == null) {
            return false;
        }
        
        return opp.SBQQ__AmendedContract__c != null 
            && opp.Returning_Opportunity__c == null 
            && opp.Type == 'Revenue Opportunity'
            && String.isNotBlank(opp.Name);
    }
    
    /**
     * GTMS-28647/GTMS-28397 - Simple bulk matching of opportunities with contacts
     * @param contractNumberToOppsMap Map of contract numbers to lists of opportunities
     * @param accountIds Set of account IDs to limit contact query scope
     */
    private Map<String, Map<String, String>> bulkMatchOpportunitiesWithContacts(Set<Id> accountIds) {
        Map<String, Map<String, String>> contractNumberToContactMap = new Map<String, Map<String, String>>();
        
        if (accountIds == null || accountIds.isEmpty()) {
            return contractNumberToContactMap;
        }
        
        List<Contact> contactList = getContacts(accountIds);
        
        if (contactList == null || contactList.isEmpty()) {
            return contractNumberToContactMap;
        }
        
        for (Contact con : contactList) {
            // Additional null checks (though query filter should handle this)
            if (String.isNotBlank(con.Amended_Contract_Number__c) && con.AccountId != null && con.Id != null) {
                String contractNumber = con.Amended_Contract_Number__c.trim();
                String accountId = String.valueOf(con.AccountId);
                String contactId = String.valueOf(con.Id);
                
                // Check if contract number already exists in map
                if (contractNumberToContactMap.containsKey(contractNumber)) {
                    // Add to existing map for this contract number
                    contractNumberToContactMap.get(contractNumber).put(accountId, contactId);
                } else {
                    // Create new map for this contract number
                    Map<String, String> accountContactMap = new Map<String, String>();
                    accountContactMap.put(accountId, contactId);
                    contractNumberToContactMap.put(contractNumber, accountContactMap);
                }
            }
        }
        
        return contractNumberToContactMap;
    }
    
    /**
     * GTMS-28647/GTMS-28397 - Extract contract number from opportunity name
     * @param opportunityName The opportunity name
     * @return The contract number or empty string if not found
     */
    private String extractContractNumberFromOpportunityName(String opportunityName) {
        if (String.isBlank(opportunityName)) {
            return '';
        }
        
        try {
            String[] parts = opportunityName.split(' - ');
            if (parts != null && parts.size() >= 3) {
                String contractNumber = parts[parts.size() - 1];
                return String.isNotBlank(contractNumber) ? contractNumber.trim() : '';
            }
        } catch (Exception e) {
            System.debug('Error extracting contract number from opportunity name: ' + opportunityName + '. Error: ' + e.getMessage());
        }
        
        return '';
    }
}