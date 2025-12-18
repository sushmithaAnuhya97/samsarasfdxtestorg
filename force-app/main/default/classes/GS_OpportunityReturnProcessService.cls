public with sharing class GS_OpportunityReturnProcessService {

    private final static Id ALLOWED_RECORD_TYPE = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
    
    //Alekya
    public Map<Id, Opportunity> oldOppMap;
    private List<Opportunity> newOppList;
    private GS_OpportunityCacheService cache;

    public GS_OpportunityReturnProcessService(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList, GS_OpportunityCacheService cache){
        this.oldOppMap  = oldOppMap;
        this.newOppList = newOppList;
        this.cache      = cache;
    }

    // Main method
    public void runBefore(){
        Map<Id, String> returnShippingLabelOrigin = this.getReturnShippingLabelOrigin();
        Set<Id> filteredOpportunities = new Set<Id>();
        Set<Id> createShipmentsIdList = new Set<Id>();

        for (Opportunity opp : newOppList) {
            this.updateReturnOppStageToRefundedClosedNode(opp);

            if (!this.canEnterReturnProcesses(opp)) {
                continue;
            }

            if (opp.StageName == 'Return Initiated') {

                if(opp.Shipmate_Preference__c == null){
                    switch on returnShippingLabelOrigin.get(opp.Id) {
                        when 'UK Shipping Label' {
                            /* Replaces node 'UK Shipping Label?' */
                            opp.Shipmate_Preference__c = 'ShippingPreference-000001';
                        }
                        when 'HQ Shipping Label' {
                            /* Replaces node 'HQ Shipping Label?' */
                            opp.Shipmate_Preference__c = 'ShippingPreference-000010';
                        }
                        when 'VCK Shipping Label' {
                            /* Replaces node 'VCK Shipping Label?' */
                            opp.Shipmate_Preference__c = 'ShippingPreference-000000';
                        }
                        // Changes as part of GTMS-759
                        when 'Samsara HQ'{
                            opp.Shipmate_Preference__c = 'ShippingPreference-000007'; 
                        }
                    }
                }
                
                if (this.exchangeOrReturnInitiatedAndStageHasChanged(opp)) {
                    
                    /** Set Free Trial Status to 'Return In Process' **/
                    if (opp.Type == 'Free Trial Opportunity') {
                        opp.Trial_Status__c = 'Return In Process';
                    }

                    /* Replaces node 'Exchange - Return Initiated?' */
                    createShipmentsIdList.add(opp.Id);
                    if (opp.Type == 'Exchange' || opp.Type == 'Warranty Exchange') {
                        filteredOpportunities.add(opp.Id);
                    }
                }
            }
            if(oldOppMap == null){
                this.isOwnerInactiveNode(opp);
                this.isOwnerActiveNode(opp);
            }
        }

        if (createShipmentsIdList.size() > 0){
            DMLWrapper.doInsert(new GS_OpportunityReturnProcessServiceAsync().prepareAsyncRequests(
                JSON.serialize(new GS_OpportunityReturnProcessServiceAsync.Options('CREATE_SHIPMENT_MP')),
                createShipmentsIdList
            ));
        }

        if (filteredOpportunities.size() > 0){
            List<String> idList = new List<String>();
            for (Opportunity opp : newOppList){
                if (opp.Id != null) idList.add(opp.Id);
            }

            DMLWrapper.doInsert(new GS_OpportunityReturnProcessServiceAsync().prepareAsyncRequests(
                JSON.serialize(new GS_OpportunityReturnProcessServiceAsync.Options('RETURN_PROCESS', String.join(idList, ','))),
                filteredOpportunities
            ));
        }
    }

    public void runAfter() {
        System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> runAfter -> entered');
        
        Set<Id> oppsRemorseRefund = new Set<Id>();
        for (Opportunity opp : this.newOppList) {
            if (!this.canEnterReturnProcesses(opp)) {
                continue;
            }
            Opportunity oldOpp;
            if (this.oldOppMap != null) {
                oldOpp = this.oldOppMap.get(opp.Id);
            }

            System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> runAfter -> opp -> ' + opp);
            System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> runAfter -> oldOpp -> ' + oldOpp);

            if (this.canCreateRemorseRefundOnInsert(opp) || this.canCreateRemorseRefundOnUpdate(opp)) {
                oppsRemorseRefund.add(opp.Id);
            }

            if (oppsRemorseRefund.size() > 0) {
                System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> runAfter -> passed checks, executing flow');
                DMLWrapper.doInsert(new GS_OpportunityReturnProcessServiceAsync().prepareAsyncRequests(
                    JSON.serialize(new GS_OpportunityReturnProcessServiceAsync.Options('REMORSE_REFUND')),
                    oppsRemorseRefund
                ));
            }
        }
    }

    private void updateReturnOppStageToRefundedClosedNode(Opportunity opp) {
        System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> entered');
        System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> opp.Type -> ' + opp.Type);
        System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> opp.Amount -> ' + opp.Amount);
        System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> opp.RecordType.DeveloperName -> ' + opp.RecordType.DeveloperName);
        System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> opp.StageName -> ' + opp.StageName);


        /** Replaces node Update Return Opp Stage to Refunded Closed **/
        if ((opp.Type == 'Free Trial Return'
            || opp.Type == 'Exchange'
            || opp.Type == 'Warranty Exchange'
        )
        && opp.Amount == 0
        && opp.StageName == 'Finance Processing'
        ){
            System.debug(LoggingLevel.DEBUG, '##### OpportunityReturnProcesses -> updateReturnOppStageToRefundedClosedNode -> setting stage to refunded closed');
            opp.StageName = 'Refunded - Closed';
        }
    }

    private Boolean canEnterReturnProcesses(Opportunity opp) {
        List<String> ACCEPTABLE_STAGES = new List<String>{
                'Return Created', 'Return Initiated', 'Return Cancelled'
        };

        Boolean canEnter = (
            ALLOWED_RECORD_TYPE == opp.RecordTypeId
        &&  ACCEPTABLE_STAGES.contains(opp.StageName)
        &&  opp.Returning_Opportunity__c != null
        );

        System.debug(LoggingLevel.INFO, '##### OpportunityReturnProcesses -> canEnter -> !conditions.contains(false) -> ' + canEnter);

        return canEnter;
    }

    private Boolean canCreateRemorseRefund(Opportunity opp){
        return (opp.StageName.equals('Return Created') && opp.Created_Remorse_Refund__c);
    }
    private Boolean canCreateRemorseRefundOnInsert(Opportunity opp) {
        return (this.canCreateRemorseRefund(opp) && this.oldOppMap == null);
    }

    private Boolean canCreateRemorseRefundOnUpdate(Opportunity opp) {
        return (this.canCreateRemorseRefund(opp)
            && opp.Type == 'Remorse Refund'
            && opp.StageName == 'Return Created'
            && opp.Return_Opportunity_Approval_Status__c == NULL
        );
    }

    private void isOwnerInactiveNode(Opportunity opp) {

        /* Replaces node 'Is Owner Inactive?' */
        if ((!this.cache.loadedOpportunityMap.get(opp.Returning_Opportunity__c).Owner.IsActive)
        &&  (opp.StageName == 'Return Created' || opp.StageName == 'Return Initiated')
        &&  opp.Owner_Manager_Email_Copy__c != null
        &&  opp.Type != 'Free Trial Return'
        &&  opp.Owner_Manager_Role_Copy__c != null
        ){
            /** Update Owner as Manager **/
            opp.OwnerId = opp.Owner_Manager_Name_Copy__c;
        }
    }

    private void isOwnerActiveNode(Opportunity opp) {
        Opportunity returningOpp = this.cache.loadedOpportunityMap.get(opp.Returning_Opportunity__c);

        /* Replaces node 'Is Owner Active?' */
        if (returningOpp.Owner.IsActive
        &&  (opp.StageName == 'Return Created' || opp.StageName == 'Return Initiated')
        &&  opp.Type != 'Free Trial Return'
        &&  opp.Rebate_Type__c != 'Partner Referral'
        ){
            /** Update Owner of Return Oppty **/
            opp.OwnerId = returningOpp.OwnerId;
        }
    }

    /**
     * Logic for Opportunity.Exchange_or_Return_Initiated__c formula field
     *
     */
    private Boolean exchangeOrReturnInitiatedAndStageHasChanged(Opportunity opp) {
        List<String> opportunityTypes = new List<String>{
                'Exchange', 'Warranty Exchange', 'Free Trial Return', 'Remorse Refund'
        };
        
        return (opportunityTypes.contains(opp.Type)
             && opp.RecordTypeId == ALLOWED_RECORD_TYPE
             && HelperClass.isChanged(opp, (this.oldOppMap != null ? this.oldOppMap.get(opp.Id) : null), Schema.Opportunity.StageName));
    }

    /**
     * Logic for Opportunity.Return_Shipping_Label_Origin__c formula field
     */
    private Map<Id, String> getReturnShippingLabelOrigin() {
        Map<Id, String> shippingCountriesByOppIds = new Map<Id, String>();

        if (this.cache.cachedShippingAddressIds != null && (this.cache.relatedShippingAddressMap == null || this.cache.relatedShippingAddressMap.isEmpty())){
            this.cache.loadRelatedShippingAddresses(this.cache.cachedShippingAddressIds);
            this.cache.cachedShippingAddressIds = null;
        }

        if (this.cache.relatedShippingAddressMap != null && this.cache.relatedShippingAddressMap.size() > 0) {
            for (Opportunity opp : this.newOppList) {
                Shipping_Address__c address = this.cache.relatedShippingAddressMap.get(opp.Shipping_Address_NEW__c);
                if (address != null) {
                    shippingCountriesByOppIds.put(opp.Id, address.Shipping_Country__c);
                }
            }
        }

        Map<Id, String> returnShippingLabelOriginByOppIds = new Map<Id, String>();
        List<String> shippingCountries = new List<String>{
                'United States', 'Canada', 'Mexico', 'Puerto Rico'
        };

        // Changes as part of GTMS-759
        for (Opportunity opp : this.newOppList) {
            
            String returnShippingLabelOrigin;

            Account thisOppAccount = new Account();
            if(opp.AccountId != NULL && this.cache.relatedAccountMap.containsKey(opp.AccountId)) {
                thisOppAccount = this.cache.relatedAccountMap.get(opp.AccountId);
            }
                        
            if (opp.Type == 'Warranty Exchange' && shippingCountries.contains(shippingCountriesByOppIds.get(opp.Id)) && thisOppAccount != null) {
                if(thisOppAccount.Critically_Escalated_Hardware_Returns__c){
                   returnShippingLabelOrigin = 'Samsara HQ';
                }
            }
            else if (!shippingCountries.contains(shippingCountriesByOppIds.get(opp.Id))) {
                returnShippingLabelOrigin = 'VCK Shipping Label';
            }
            /*
            else if (opp.Type == 'Remorse Refund' && !shippingCountries.contains(shippingCountriesByOppIds.get(opp.Id))) {
                returnShippingLabelOrigin = 'UK Shipping Label';
            }
            */
            else if (opp.Type == 'Remorse Refund' || shippingCountries.contains(shippingCountriesByOppIds.get(opp.Id))) {
                returnShippingLabelOrigin = 'HQ Shipping Label';
            }
            else {
                returnShippingLabelOrigin = 'DCL Shipping Label';
            }
            returnShippingLabelOriginByOppIds.put(opp.Id, returnShippingLabelOrigin);
        }
        return returnShippingLabelOriginByOppIds;
    }
}