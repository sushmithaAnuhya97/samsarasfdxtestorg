public with sharing class GS_OpportunityPrepopulationService {
    
    private GS_OpportunityCacheService cache;
    private static List<Opportunity_Event__e> opportunityEvents = new List<Opportunity_Event__e>();
    private static List<Order_Event__e> orderSyncEvents = new List<Order_Event__e>();    
    private Set<Id> duplicateOpportunityEvents = new Set<Id>();

    /**
     * @description : Executes before-insert related field prepopulation (beforeInsertOnly)
     * @param List<Opportunity> newOpportunityList
     * 12/17/2020 Ron, Harsha (GTMS-2395) beforeInsertOnly (Configuration Segment)
     */
    public void runBeforeInsertService(List<Opportunity> newOpportunityList, GS_OpportunityCacheService cache) {
        this.cache = cache;
        cache.cacheRelatedIdsFromOpps(newOpportunityList);
        cache.loadOppRelatedAccounts(cache.cachedAccountIds);
        cache.loadOppRelatedContracts(cache.cachedContractIds);
        cache.loadOppRelatedUser(cache.cachedOwnerIds);

        cache.cachedAccountIds = null;
        cache.cachedContractIds = null;

        for (Opportunity opp : newOpportunityList) {
                        
            Account relatedAccount = (cache.relatedAccountMap.containsKey(opp.AccountId) ? cache.relatedAccountMap.get(opp.AccountId) : new Account());

            // Before Insert Only prepopulation
            this.populateFieldsFromRelatedContracts(opp);
            this.populateFieldsFromReturningOpportunity(opp);
            this.populateFieldsFromAccount(opp, relatedAccount);
            this.populateInsertOpportunityValues(opp);

            // Before context prepopulation
            this.runCommonBeforeServiceMethods(new Opportunity(), opp, relatedAccount, false);
        }
    }

    /**
     * @description : Executes before-update related field prepopulation (beforeInsertOnly)
     * @param Map<Id,Opportunity> oldOpportunityMap
     * @param List<Opportunity>   newOpportunityList
     * @param GS_OpportunityCacheService cache
     * 12/17/2020 Ron, Harsha (GTMS-2395) beforeInsertOnly (Configuration Segment)
     */
    public void runBeforeUpdateService(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> newOpportunityList, GS_OpportunityCacheService cache){

        this.cache = cache;
        cache.loadOppRelatedUser(cache.cachedOwnerIds);
        Opportunity oldOpportunity = new Opportunity();

        if ((cache.cachedShippingAddressIds != null) && (cache.relatedShippingAddressMap == null || cache.relatedShippingAddressMap.isEmpty())) {
            cache.loadRelatedShippingAddresses(cache.cachedShippingAddressIds);
            cache.cachedShippingAddressIds = null;
        }

        for (Opportunity opp : newOpportunityList) {
            Account relatedAccount = (cache.relatedAccountMap.containsKey(opp.AccountId) ? cache.relatedAccountMap.get(opp.AccountId) : new Account());
            oldOpportunity = oldOpportunityMap.get(opp.Id);
            
             this.populateUpdateData(oldOpportunity, opp);
             // Before context prepopulation
             this.runCommonBeforeServiceMethods(oldOpportunity, opp, relatedAccount, true);

             syncOpportunity(newOpportunityList, oldOpportunityMap);
        }

        new GS_OpportunityToUpdateAccountService().runOpportunityToUpdateAccountBeforeUpdate(oldOpportunityMap, newOpportunityList, cache);
    }


    private void syncOpportunity(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldMap) {
        for (Opportunity oppty : newOpportunityList) {
            Opportunity oldOppty = oldMap.get(oppty.Id);

            if ((oppty.Type == 'Revenue Opportunity' || oppty.Type == 'Promo Opportunity')
                && oppty.StageName.equals('Ready to Ship')
                && ((oldOppty.StageName != oppty.StageName) || (oppty.Push_to_Mulesoft__c && (oldOppty.Push_to_Mulesoft__c != oppty.Push_to_Mulesoft__c)))
                && String.isBlank(oppty.Netsuite_Id__c)
                && oppty.Sync_in_Progress__c != true) {
                    oppty.Sync_in_Progress__c = true;
                    orderSyncEvents.add(new Order_Event__e(Id__c = oppty.Id, Type__c = oppty.Type));
            }
            
           if ((oppty.Type == 'Work Order' || oppty.Type == 'Free Trial Opportunity')
                && oppty.StageName.equals('Ready to Ship')
                && ((oldOppty.StageName != oppty.StageName) || (oppty.Push_to_Mulesoft__c && (oldOppty.Push_to_Mulesoft__c != oppty.Push_to_Mulesoft__c)))
                && String.isBlank(oppty.Netsuite_Id__c)
                && oppty.Sync_in_Progress__c != true) {
                    oppty.Sync_in_Progress__c = true;
                    orderSyncEvents.add(new Order_Event__e(Id__c = oppty.Id, Type__c = oppty.Type));
            }  
        }
    }

    private void runCommonBeforeServiceMethods(Opportunity oldOpp, Opportunity newOpp, Account relatedAccount, Boolean checkForChanges){
        // Before context prepopulation
        this.populateFinancialFields(newOpp);
        this.populateBookingsOwnerSegment(oldOpp, newOpp, relatedAccount, checkForChanges);
        this.populateAccountOwnerTeamEmail(newOpp);
    }

    /**
     * @description : Update opportunity fields related to its original amended contract
     * @param Opportunity opp
     */
    @TestVisible
    private void populateFieldsFromRelatedContracts(Opportunity opp){
        if (this.cache.relatedContractMap.containsKey(opp.SBQQ__AmendedContract__c)){
            Contract originalContract    = this.cache.relatedContractMap.get(opp.SBQQ__AmendedContract__c);
            opp.Payment_Terms__c         = originalContract.SBQQ__Opportunity__r.Payment_Terms__c;
            opp.Shipping_Contact__c      = originalContract.SBQQ__Opportunity__r.Shipping_Contact__c;
            opp.Approved_Discount__c     = originalContract.SBQQ__Opportunity__r.Approved_Discount__c;
            opp.Selected_Payment_Type__c = originalContract.SBQQ__Opportunity__r.Selected_Payment_Type__c;
            opp.Name = 'Amendment - '+ originalContract.Account.Name.Left(Integer.valueOf(System.Label.Opportunity_Account_Name_Limit)) + ' - ' + originalContract.ContractNumber;
        }

        if (this.cache.relatedContractMap.containsKey(opp.SBQQ__RenewedContract__c)){
            Contract originalContract    = this.cache.relatedContractMap.get(opp.SBQQ__RenewedContract__c);
            opp.Payment_Terms__c         = originalContract.SBQQ__Opportunity__r.Payment_Terms__c;
            opp.Shipping_Contact__c      = originalContract.SBQQ__Opportunity__r.Shipping_Contact__c;
            opp.Reseller__c              = originalContract.SBQQ__Opportunity__r.Reseller__c;
            opp.Selected_Payment_Type__c = originalContract.SBQQ__Opportunity__r.Selected_Payment_Type__c;
            opp.Finance_Partner__c       = originalContract.SBQQ__Opportunity__r.Finance_Partner__c;
            opp.Shipping_Address_NEW__c  = originalContract.SBQQ__Opportunity__r.Shipping_Address_NEW__c;
            opp.Original_AE__c           = originalContract.SBQQ__Opportunity__r.OwnerId;   
            opp.Approved_Discount__c     = originalContract.SBQQ__Opportunity__r.Approved_Discount__c;
            opp.Name = 'Renewal - '+ originalContract.Account.Name.Left(Integer.valueOf(System.Label.Opportunity_Account_Name_Limit)) + ' - ' + originalContract.ContractNumber;
        }
    }

    /**
     * @description : Update opportunity fields related to the Reseller Partner
     * @param Opportunity opp
     */
    @TestVisible
    private void populateFieldsFromReturningOpportunity(Opportunity opp){
        if (opp.Type == 'Rebate' && opp.Returning_Opportunity__r != null && opp.Returning_Opportunity__r.Reseller_Partner__c != NULL) {
            opp.Reseller_Partner__c = opp.Returning_Opportunity__r.Reseller_Partner__c;
        }
    }

    /**
     * @description : Updates opportunity fields related to the Account.
     * @param Opportunity opp
     */
    @TestVisible
    private void populateFieldsFromAccount(Opportunity opp, Account oppAccount){
        // Code to populate the Shipping Address New on opportunity create
        List<String> cwRoboIds = System.Label.Corpweb_SFDC_Robot.split(',');

        if ((oppAccount.Shipping_Addresses__r != null)
        && (oppAccount.Shipping_Addresses__r.size() > 0)
        && ((opp.Type == 'Revenue Opportunity') || (opp.Type == 'Free Trial Opportunity'))
        && (!cwRoboIds.contains(UserInfo.getUserId()))
        && (opp.Shipping_Address_NEW__c == null)
        ){
            Shipping_Address__c relatedShippingAddress = oppAccount.Shipping_Addresses__r;
            opp.Shipping_Address_NEW__c = relatedShippingAddress.id;
            this.setShippingDefaults(opp, relatedShippingAddress.Shipping_Country__c, false);
        }

        opp.Shipping_Country__c = oppAccount.BillingCountry;
        opp.Shipping_State__c = oppAccount.BillingState;

        opp.Configuration_Segment__c = (
            oppAccount.Segment__c != null
        && oppAccount.Segment__c.contains(System.Label.Account_Express_Segment)
        ?  'Express' : 'Non Express'
        );
    }

    /**
     * Initialize other opportunity fields from before Insert context
     * @param Opportunity opp
     */
    @TestVisible
    private void populateInsertOpportunityValues(Opportunity opp){
        //Clears out serial numbers on opportunities - @Tommy
        opp.All_Serial_Numbers__c = null;
        
        if(opp.Pricebook2Id == null && !Test.isRunningTest()){
            opp.Pricebook2Id = System.Label.Current_Active_Pricebook;
        }

        if(opp.Name.contains('Renewal')
        && opp.SBQQ__RenewedContract__c != null
        && opp.OwnerId != System.Label.Renewal_Pool_User
        ){
            opp.OwnerId = System.Label.Renewal_Pool_User;
            opp.Renewal__c = true;
        }
    }

    /**
     * @description : Sets the default shipping values for the opportunity based on the shipping country
     * @param : Opportunity opp
     * @param : String shippingCountry
     */
    @TestVisible
    private void setShippingDefaults(Opportunity opp, String shippingCountry, Boolean checkShippingCountry){
        this.cache.loadShippingCountryMetadata();
        
        if (shippingCountry != NULL && (this.cache.shippingCountriesDefaultMap.containsKey(shippingCountry))){
            opp.Shipping_Carrier__c   = this.cache.shippingCountriesDefaultMap.get(shippingCountry).Shipping_Carrier__c;
            opp.Ship_From_Location__c = this.cache.shippingCountriesDefaultMap.get(shippingCountry).Ship_From_Location__c;

            if(!checkShippingCountry || (ShippingCountry != 'United States' && checkShippingCountry)){
                opp.Shipping_Method__c = this.cache.shippingCountriesDefaultMap.get(shippingCountry).Shipping_Method__c;
            }
        }
    }

    /**
     * @description : Called at beforeInsertOrUpdate previous method implementation.
     */
    @TestVisible
    private void populateFinancialFields(Opportunity newOpp) {

        if (newOpp.isClosed){
            // Need to make sure variables are set properly for the commissionable dollars field to work, at least until we run a mass update on historical closed won opps so we can change that formula field)
            // For new internal financing, just uncomment the line below and delete the if(o.internal_finance__c = 'approved') part.
            
            newOpp.Internal_Finance__c = 'Approved';
            if (newOpp.Selected_Payment_Type__c == 'Direct Monthly') {
                newOpp.Direct_Monthly__c = TRUE;
                newOpp.Direct_Annual__c = FALSE;
            } else if (newOpp.Selected_Payment_Type__c == 'Direct Annual') {
                newOpp.Direct_Monthly__c = FALSE;
                newOpp.Direct_Annual__c = TRUE;
            } else {
                newOpp.Direct_Monthly__c = FALSE;
                newOpp.Direct_Annual__c = FALSE;
            }
            if (newOpp.Probability < 98) {
                newOpp.ACV_Commissionable_Dollars_Copy__c = newOpp.ACV_Commissionable_Dollars__c;
            }
        }

        //workflow
        if (newOpp.Probability > 0 && newOpp.Qualified_Date__c == null && newOpp.Type == 'Revenue Opportunity') {
            newOpp.Qualified_Date__c = System.now();
        }
        // Stamp ACV Bookings Copy
        if (newOpp.ACV_Bookings_Copy__c != newOpp.ACV_Bookings_SOT__c) {
            newOpp.ACV_Bookings_Copy__c = newOpp.ACV_Bookings_SOT__c;
        }
        // Stamp finance approved amount, if necessary
        if (newOpp.Probability >= 95 && newOpp.Finance_Approved_Amount_Stamp__c == NULL) {
            newOpp.Finance_Approved_Amount_Stamp__c = newOpp.Amount;
        }
        if (newOpp.Small_Fleet_Opportunity__c == TRUE){
            if (newOpp.Express_Annual_Discount__c > 0) {
                newOpp.Express_Annual_Discount__c = 0;
            }
            if (newOpp.Express_Upfront_Discount__c > 0) {
                newOpp.Express_Upfront_Discount__c = 0;
            }
        }
        if (newOpp.Price_Book_Name__c <> null) {
            if (newOpp.Configuration_Segment__c == 'Express' && newOpp.Small_Fleet_Opportunity__c == false) {
                newOpp.Express_Upfront_Discount__c = 15;
                newOpp.Express_Annual_Discount__c = 10;
            }
        }
    }

    /**
     * @description : Update only values assignment that depends on old value / new value difference.
     */
    @TestVisible
    private void populateOnFieldChange(Opportunity oldOpp, Opportunity newOpp, Account thisOppAccount){

        if (newOpp.StageName == 'Closing' && newOpp.Direct_Monthly_Annual_through_Checkout__c == true && !newOpp.Direct_Annual__c && newOpp.Configuration_Segment__c != 'Express' &&
                (newOpp.Payment_Token__c != null && newOpp.Payment_Token__c.startsWith(System.Label.Credit_Card_Token_Prefix)) &&
                (HelperClass.isChanged(newOpp, oldOpp, Schema.Opportunity.StageName) || HelperClass.isChanged(newOpp, oldOpp, Schema.Opportunity.Payment_Token__c))) {                
            newOpp.Payment_Processing_Fee__c = true;
        }

        if(HelperClass.isChanged(newOpp, oldOpp, Schema.Opportunity.OwnerId)){
            newOpp.Configuration_Segment__c = (thisOppAccount.Segment__c != null && thisOppAccount.Segment__c.contains(System.Label.Account_Express_Segment) ? 'Express' : 'Non Express');  
        }
    }

    /**
     * @description : Update Bookings Owner Segment field
     */
    @TestVisible
    private void populateBookingsOwnerSegment(Opportunity oldOpp, Opportunity newOpp, Account thisOppAccount, Boolean checkForChanges){
        if (!checkForChanges || HelperClass.isChanged(newOpp, oldOpp, Schema.Opportunity.Owner_Role_Copy__c)){
            if(newOpp.Owner_Segment__c != 'Other' && !String.isBlank(newOpp.Owner_Segment__c)) {
                newOpp.Bookings_Owner_Segment__c  = newOpp.Owner_Segment__c;
            }
            else if(newOpp.Returning_Opportunity__c != Null && newOpp.Returning_Opportunity__r.Owner_Segment__c != 'Other' && !String.isBlank(newOpp.Returning_Opportunity__r.Owner_Segment__c)) {
                newOpp.Bookings_Owner_Segment__c  = newOpp.Returning_Opportunity__r.Owner_Segment__c;
            }
            else {
                newOpp.Bookings_Owner_Segment__c  = thisOppAccount.Segment__c;
            }
        }
    }

    /**
     * @description : Before update part only from beforeInsertOrUpdate method
     * 
     */
    @TestVisible
    public void populateUpdateData(Opportunity oldOpp, Opportunity newOpp){

        String shippingAndHandlingTaxLocations = System.Label.Shipping_and_Handling_Tax;

        Opportunity vOpportunity;
        if(newOpp.Id != null){
            vOpportunity = this.cache.loadedOpportunityMap.get(newOpp.Id);
        }else if(newOpp.Returning_Opportunity__c != null){
            vOpportunity = this.cache.loadedOpportunityMap.get(newOpp.Returning_Opportunity__c);
        }
        
        if (vOpportunity != null && newOpp.Id != null) {
            if (vOpportunity.Type == 'Rebate') {
                if(vOpportunity.Rebate_Type__c != null && System.Label.Rebate_Close_Date.contains(vOpportunity.Rebate_Type__c) && vOpportunity.StageName == 'Refunded - Closed'){
                    newOpp.CloseDate = vOpportunity.Returning_Opportunity__r.CloseDate;
                }
                if (vOpportunity.Returning_Opportunity__r.Referral_Partner__c != null) {
                    newOpp.Referral_Partner__c = vOpportunity.Returning_Opportunity__r.Referral_Partner__c;
                }
                if (vOpportunity.Returning_Opportunity__r.Insurance_Partner__c != null) {
                    newOpp.Insurance_Partner__c = vOpportunity.Returning_Opportunity__r.Insurance_Partner__c;
                }
                if (vOpportunity.StageName == 'Refunded - Closed' && vOpportunity.Rebate_Type__c == 'Delinquent' && vOpportunity.Delinquent_Return_Past_180_Days__c) {
                    newOpp.OwnerId = Global_Variable__mdt.getInstance('Owner_Delinquent_Return_Past_180_Days').Value__c;
                }
            }
            
            /* Replaces Node 'Shipping Country is Canada or Mexico' */
            List<String> cwRoboIds = System.Label.Corpweb_SFDC_Robot.split(',');
            if (newOpp.Shipping_Address_NEW__c != NULL && (newOpp.Shipping_Address_NEW__c != oldOpp.Shipping_Address_NEW__c) && !cwRoboIds.contains(UserInfo.getUserId())) {
                
                string ShippingCountry = this.cache.relatedShippingAddressMap.get(newOpp.Shipping_Address_NEW__c).Shipping_Country__c;
                    HelperClass.setShippingDefaults(newOpp, NULL, shippingCountry);
            }
            if (vOpportunity.Shipping_Address_NEW__r.Shipping_Country__c == 'Canada'
                && vOpportunity.Probability <= 95
                && (vOpportunity.Shipping_Country__c != 'Canada')) {                    
                    newOpp.Shipping_Country__c = 'Canada';
                    if(newOpp.Type == 'Promo Opportunity'){
                        newOpp.Shipping_Method__c = 'Worldwide Expedited';
                    }
                } else if (vOpportunity.Shipping_Address_NEW__r.Shipping_Country__c == 'Mexico'
                            && vOpportunity.Probability <= 95
                            && (vOpportunity.Shipping_Country__c != 'Mexico')) {
                                newOpp.Shipping_Country__c = 'Mexico';
                                //newOpp.Shipping_Method__c = 'Worldwide Expedited';
                            }
            
            if(HelperClass.isChanged(newOpp, oldOpp, Schema.Opportunity.Product_Count__c)
                && newOpp.Product_Count__c > oldOpp.Product_Count__c
                && oldOpp.StageName == 'Incubate'){
                    newOpp.StageName = 'Qualified';
                }
            
            /* Sonal: Changed on 9th April, 2020 Replaces Node 'Express Amount Agreed To' */
            if (newOpp.Express_Agreement_Accepted_Date__c != null) {
                newOpp.Contract_Amount_Agreed_To__c = vOpportunity.Amount;
            }
            
            /* Replaces Node 'Express Discount is Added to Blended Discount' */
            //TODO - Ensure that we stamp the Discount Approval Needed
            if (((vOpportunity.Selected_Payment_Type__c <> null && (vOpportunity.Selected_Payment_Type__c == 'Direct Annual' || vOpportunity.Selected_Payment_Type__c == 'Upfront Payments'))
                    || (vOpportunity.SBQQ__PrimaryQuote__c <> null && vOpportunity.SBQQ__PrimaryQuote__r.ApprovalStatus__c == 'Approved'))
                && vOpportunity.Pricebook2.Name <> null
                && vOpportunity.Configuration_Segment__c == 'Express') {
                    newOpp.Approved_Discount__c = vOpportunity.Blended_Discount__c + 0.1;
                    newOpp.Discount_Approval_Status__c = 'Approved';
                }
            
            /* Replaces Node 'New Billing Process Approval' */
            //if ((vOpportunity.Price_Book_Name__c != null
            //     && vOpportunity.Configuration_Segment__c == 'Express')
            //    && vOpportunity.Payment_Token__c != null
            //    && vOpportunity.Probability >= 98
            //    && !vOpportunity.IsClosed
            //    && !vOpportunity.Account.New_Billing_Process_Approved__c) {
            //        thisOppAccount.New_Billing_Process_Approved__c = true;
            //        DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{Account.New_Billing_Process_Approved__c});
            //    }
            
            /* Replaces Node 'Mexico Shipping' */
            if (vOpportunity.Type == 'Free Trial Opportunity' && newOpp.Shipping_Country__c == 'Mexico'
                && vOpportunity.Shipping_Instructions__c == null) {
                    newOpp.Shipping_Instructions__c = 'Please add Sample Label';
                }
            

            if (vOpportunity.Overwrite_Validation_Rule__c
            ||  (vOpportunity.Rebate_Type__c != 'Partner Referral'
            &&  vOpportunity.Rebate_Type__c != 'Renewal Credit'
            &&  vOpportunity.Probability <= 95)
            ){
                
                /* Replaces Node 'Stamp Manager On Stage Change' */
                String managerFormulaResult = null;
                if (vOpportunity.Overwrite_Validation_Rule__c
                || (HelperClass.isChanged(newOpp, oldOpp, Schema.Opportunity.Probability)
                    // Assign and check at the same time to avoid recalling the managerFormula twice
                    || (managerFormulaResult = (String) managerFormula(newOpp, vOpportunity, 'Manager Name')) != vOpportunity.Owner_Manager_Email_Copy__c)
                ){
                    newOpp.Owner_Manager_Name_Copy__c = (managerFormulaResult != null ? (Id) managerFormula(newOpp, vOpportunity, 'Manager Name') : null);
                    newOpp.Owner_Manager_Role_Copy__c = (String) managerFormula(newOpp, vOpportunity, 'Manager Role');
                }
                
                /* Replaces Node 'Stamp Director On Stage Change' */
                managerFormulaResult = null;
                if (vOpportunity.Overwrite_Validation_Rule__c
                || (HelperClass.isChanged(newOpp, oldOpp, Schema.Opportunity.Probability)
                    // Assign and check at the same time to avoid recalling the managerFormula twice
                    || (managerFormulaResult = (String) managerFormula(newOpp, vOpportunity, 'Director Name')) != vOpportunity.Owner_Director_Role_Copy__c)
                ){
                    newOpp.Owner_Director_Name_Copy__c = (managerFormulaResult != null ? (Id) managerFormula(newOpp, vOpportunity, 'Director Name') : null);
                }
                
                /* Replaces Node 'Stamp Geo On Stage Change' */
                if (vOpportunity.Overwrite_Validation_Rule__c
                || (HelperClass.isChanged(newOpp, oldOpp, Schema.Opportunity.Probability) || vOpportunity.Owner_Geo_Copy__c != vOpportunity.Owner.Territory__c)
                ){
                    newOpp.Owner_Geo_Copy__c = extractOwnerGeographyCopy(vOpportunity);
                }
            }
                
                /* Groundswell : Tanuj - WFlow Rule - Copy Owner Manager Email When Closing
                * This rule copies the name of the owner's manager when opportunity is moved into closing
                */
            if((newOpp.StageName == 'Closing'
            || newOpp.StageName == 'Refunded - Closed'
            || newOpp.StageName == 'Orders Processing')
            && newOpp.Owner_Manager_Email_Copy__c == null){
                newOpp.Owner_Manager_Email_Copy__c = (String) managerFormula(newOpp, vOpportunity, 'Manager Email');
            }
            /*
            * End of WFlow Rule - Copy Owner Manager Email When Closing
            */
            
            
            if (newOpp.Shipping_Address_NEW__c == NULL) {
                newOpp.Shipping_Carrier__c = 'UPS';
                //newOpp.Shipping_Method__c    = '3 Day Select';
                newOpp.Ship_From_Location__c = 'DCL';
            }
            
            if(oldOpp.Payment_Terms__c != newOpp.Payment_Terms__c && newOpp.Payment_Terms__c != NULL && newOpp.Payment_Terms__c != newOpp.Initial_Payment_Terms__c) {
                newOpp.Initial_Payment_Terms__c = newOpp.Payment_Terms__c;
            }
            if (newOpp.SBQQ__PrimaryQuote__c == null
            &&  newOpp.Shipping_and_Handling__c != null && newOpp.Shipping_and_Handling__c > 0 && newOpp.Shipping_and_Handling__c != 99999.99
            &&  newOpp.Sales_Tax_Rate_NEW__c != null && newOpp.Sales_Tax_Rate_NEW__c > 0 && newOpp.Sales_Tax_Rate_NEW__c < 100
            && ((newOpp.Shipping_Country__c != null && !(shippingAndHandlingTaxLocations.contains(newOpp.Shipping_Country__c))))) {
                newOpp.S_H_Tax__c = newOpp.Shipping_and_Handling__c * (newOpp.Sales_Tax_Rate_NEW__c / 100);
            } else {
                newOpp.S_H_Tax__c = 0;
            }

           /*
            Below Logic Copied over from beforeUpdateOnly Method
            *
            */
           
            newOpp.License_Term__c = newOpp.License_Term_CPQ__c != null ? newOpp.License_Term_CPQ__c : newOpp.License_Term__c ;
            
            stampStageChangeAnalysisFields(newOpp , oldOpp);

            if ((newOpp.Type == 'Warranty Exchange' || newOpp.Type == 'Exchange' || newOpp.Type == 'Remorse Refund') && newOpp.StageName == 'Return Initiated' && oldOpp.StageName != 'Return Initiated') {
                newOpp.Return_Label_Sent_At__c = Date.Today();
            }
            if(!duplicateOpportunityEvents.contains(newOpp.Id) && newOpp.SBQQ__RenewedContract__c != NULL && newOpp.StageName != oldOpp.StageName && newOpp.StageName == 'Ready to Ship'){
                 opportunityEvents.add(new Opportunity_Event__e(Id__c = newOpp.Id)); 
                duplicateOpportunityEvents.add(newOpp.Id);
            }
            if(newOpp.Amount != NULL && newOpp.SBQQ__RenewedContract__c != NULL && newOpp.Renewal_ACV__c == NULL && newOpp.License_Term_CPQ__c != null && newOpp.License_Term_CPQ__c != 0){
                newOpp.Renewal_ACV__c = newOpp.Amount / (newOpp.License_Term_CPQ__c / 12);
            }
        }
    }


    private void stampStageChangeAnalysisFields(Opportunity newOpportunity, Opportunity oldOpp){
        // Stamp stage change analysis fields
        if (newOpportunity.StageName == 'Incubate' && oldOpp.StageName != 'Incubate') {
            newOpportunity.Went_To_Incubate_Date__c = Datetime.Now();
            newOpportunity.Went_To_Incubate__c = TRUE;
        } else if (newOpportunity.StageName == 'Qualified' && oldOpp.StageName != 'Qualified') {
            newOpportunity.Went_To_Qualified_Date__c = Datetime.Now();
            newOpportunity.Went_To_Qualified__c = TRUE;
        } else if (newOpportunity.StageName == 'Trial' && oldOpp.StageName != 'Trial') {
            newOpportunity.Went_To_Trial_Date__c = Datetime.Now();
            newOpportunity.Went_To_Trial__c = TRUE;
        } else if (newOpportunity.StageName == 'Proposal' && oldOpp.StageName != 'Proposal') {
            newOpportunity.Went_To_Proposal_Date__c = Datetime.Now();
            newOpportunity.Went_To_Proposal__c = TRUE;
        } else if (newOpportunity.StageName == 'Decision' && oldOpp.StageName != 'Decision') {
            newOpportunity.Went_To_Decision_Date__c = Datetime.Now();
            newOpportunity.Went_To_Decision__c = TRUE;
        } else if (newOpportunity.StageName == 'Purchase' && oldOpp.StageName != 'Purchase') {
            newOpportunity.Went_To_Purchase_Date__c = Datetime.Now();
            newOpportunity.Went_To_Purchase__c = TRUE;
        } else if (newOpportunity.StageName == 'Closing' && oldOpp.StageName != 'Closing') {
            newOpportunity.Went_To_Closing_Date__c = Datetime.Now();
            newOpportunity.Went_To_Closing__c = TRUE;
        } else if (newOpportunity.StageName == 'Orders Processing' && oldOpp.StageName != 'Orders Processing') {
            newOpportunity.Went_to_Orders_Processing_Date__c = Datetime.Now();
            newOpportunity.Went_to_Orders_Processing__c = TRUE;
        } else if (newOpportunity.StageName == 'Ready To Ship' && oldOpp.StageName != 'Ready To Ship') {
            newOpportunity.Went_To_Ready_To_Ship_Date__c = Datetime.Now();
            newOpportunity.Went_To_Ready_To_Ship__c = TRUE;
        } else if (newOpportunity.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
            newOpportunity.Went_To_Closed_Won_Date__c = Datetime.Now();
            newOpportunity.Went_To_Closed_Won__c = TRUE;
            newOpportunity.SBQQ__Contracted__c = True;
        } else if ((newOpportunity.StageName == 'Refunded - Closed' && oldOpp.StageName != 'Refunded - Closed') && newOpportunity.SBQQ__AmendedContract__c != NULL ) {
            newOpportunity.SBQQ__Contracted__c = True;
        } else if (newOpportunity.StageName == 'Closed Lost' && oldOpp.StageName != 'Closed Lost') {
            newOpportunity.Went_To_Closed_Lost_Date__c = Datetime.Now();
            newOpportunity.Went_To_Closed_Lost__c = TRUE;
            newOpportunity.CloseDate = Date.Today();
        }
    }


    private static Object managerFormula(Opportunity newOpportunity, Opportunity oppty, String managerType) {
        Object returnObject = null;
        if (oppty.Type == 'Revenue Opportunity' || oppty.Type == 'Free Trial Opportunity'
                || oppty.Type == 'Promo Opportunity' || ((oppty.Type == 'Rebate' || oppty.Type == 'Remorse Refund')
                && oppty.Owner.Level__c != null && oppty.Returning_Opportunity__r.Owner.Level__c != null
                && oppty.Owner.Level__c.equals('AE 1') && oppty.Returning_Opportunity__r.Owner.Level__c.equals('AE 1'))) {
            switch on managerType {
                when 'Manager Name' {
                    returnObject = oppty.Owner.ManagerId;
                }
                when 'Manager Role' {
                    returnObject = oppty.Owner.Manager.UserRole.Name;
                }
                when 'Director Name' {
                    if(oppty.Owner.Manager.Manager.Level__c != null && oppty.Owner.Manager.Manager.Level__c.contains('ISD')){
                        returnObject = oppty.Owner.Manager.ManagerId;
                    }
                    else if(oppty.Owner.Manager.Level__c != null && oppty.Owner.Manager.Level__c.contains('ISD')){
                        returnObject = oppty.Owner.ManagerId;
                    }
                    else{
                        returnObject = oppty.Owner.Manager.ManagerId;                        
                    }               
                }
                when 'Manager Email' {
                    returnObject = oppty.Owner.Manager.Email;
                    }
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
            }
        }

        return returnObject;
    }

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

    private void populateAccountOwnerTeamEmail(Opportunity newOpp){
        if (newOpp.StageName == 'Orders Processing'){
            User u = cache.relatedUserMap.get(newOpp.OwnerId);
            if (u != null) newOpp.Team_Email_Alias__c = u.Team_Email_Alias__c;
        }
    }

    public void createPlatformEvent() {
        if(opportunityEvents.size() > 0){
            List<Database.SaveResult> results = EventBus.publish(opportunityEvents); 
        }
        if (orderSyncEvents.size() > 0) {
            system.debug('Before firing Order event');
            List<Database.SaveResult> results = EventBus.publish(orderSyncEvents);
            system.debug('Order event results: ' + results);
        }   
    }
}