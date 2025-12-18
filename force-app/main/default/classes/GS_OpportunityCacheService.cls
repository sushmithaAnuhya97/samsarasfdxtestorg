/**
* Created By : Groundswell - Flávio Contini
* @Date August 12, 2021
*
* @description : This class will be responsible for keeping alive all the queries executed during the trigger executing
* SFA-10
*
**/
public with sharing class GS_OpportunityCacheService {
    
    public Map<Id, Account> relatedAccountMap;
    public Map<Id, Contract> relatedContractMap;
    public Map<Id, Opportunity> loadedOpportunityMap;
    public Map<Id, Opportunity> loadedOpportunityWithOpptyLineItemsMap;
    public Map<Id, User> relatedUserMap;
    public Map<Id, Shipping_Address__c> relatedShippingAddressMap;
    public Map<String, Shipping_Countries__mdt> shippingCountriesDefaultMap;

    public List<Id> cachedAccountIds;
    public List<Id> cachedContractIds;
    public List<Id> cachedOpportunityIds;
    public List<Id> cachedOwnerIds;
    public List<Id> cachedShippingAddressIds;

    /**
     * @description : Loads the Shipping_Countries__mdt metadata object
     */
    public void loadShippingCountryMetadata(){
        if (this.shippingCountriesDefaultMap == null || this.shippingCountriesDefaultMap.size() <= 0){
            this.shippingCountriesDefaultMap = new Map<String, Shipping_Countries__mdt>();

            for (Shipping_Countries__mdt sCountry : Shipping_Countries__mdt.getAll().values()){
                this.shippingCountriesDefaultMap.put(sCountry.MasterLabel, sCountry);
            }
        }
    }

    /**
     * @description : Loads the related Contracts from the received Id List
     * @param : List<Id> ctrIdList
     */
    public void loadOppRelatedContracts(List<Id> ctrIdList){
        if (this.relatedContractMap == null || this.relatedContractMap.size() <= 0){
            this.relatedContractMap = new Map<Id, Contract>(
                (new GS_ContractSelector()).getContractsWithOppDataById(ctrIdList)
            );
        }
    }

    /**
     * @description : Loads the related Accounts from the received Id List
     * @param : List<Id> accIdList
     */
    public void loadOppRelatedAccounts(List<Id> accIdList){
        if (this.relatedAccountMap == null || this.relatedAccountMap.size() <= 0){
            this.relatedAccountMap = new Map<Id, Account>(
                (new GS_AccountSelector(false)).getAccountsWithOppAndShipAddrByIds(accIdList)
            );
        }
    }

    /**
     * @description : Loads DB version of the Opportunities in received Id List
     * @param : List<Id> opportunityIds
     */
    public void loadOpportunityWithItems(List<Id> opportunityIds) {
        if (this.loadedOpportunityMap == null){
            this.loadedOpportunityMap = new Map<Id, Opportunity>(
                (new GS_OpportunitySelector(false)).loadOpportunityWithItems(new Set<Id>(opportunityIds))
            );
        }
    }

    /**
     * @description : Loads DB version of the Opportunities with Line Items & Channel Relationshipsin received Id List
     * @param : List<Id> opportunityIds
     */
    public void loadOpportunityWithOpptyLineItems(List<Id> opportunityIds) {
        if (this.loadedOpportunityWithOpptyLineItemsMap == null){
            this.loadedOpportunityWithOpptyLineItemsMap = new Map<Id, Opportunity>(
                (new GS_OpportunitySelector(false)).loadOpportunityWithOpptyLineItems(new Set<Id>(opportunityIds))
            );
        }
    }

    

    /**
     * @description : Loads the related User from the received Id List
     * @param : List<Id> userIdList
     */
    public void loadOppRelatedUser(List<Id> userIdList){
        if (this.relatedUserMap == null || this.relatedUserMap.size() <= 0){
            this.relatedUserMap = new Map<Id, User>(
                (new GS_UserSelector(false)).getUserMapByIds(new Set<Id>(userIdList))
            );
        }
    }

    /**
     * @description : Loads the related Shipping Addresses from the Opportunity. Same as the old HelperClass dependant method.
     * @param : List<Id> shippingAddressIdList
     */
    public void loadRelatedShippingAddresses(List<Id> shippingAddressIdList) {
        if (this.relatedShippingAddressMap == null){
            this.relatedShippingAddressMap = new Map<Id, Shipping_Address__c>(
                (new GS_ShippingAddressSelector(false)).loadShippingAddressById(shippingAddressIdList)
            );
        }
    }

    /**
     * @description : Caches the related Account & Contract IDs from oppList
     * @param List<Opportunity> oppList
     */
    public void cacheRelatedIdsFromOpps(List<Opportunity> oppList){
        if (this.cachedAccountIds != null) return;

        this.cachedOpportunityIds          = new List<Id>();
        this.cachedAccountIds              = new List<Id>();
        this.cachedContractIds             = new List<Id>();
        this.cachedOwnerIds                = new List<Id>();
        this.cachedShippingAddressIds      = new List<Id>();
        for (Opportunity opp : oppList){
            if (opp.Id != null)                       this.cachedOpportunityIds.add(opp.Id);
            if (opp.Returning_Opportunity__c != null) this.cachedOpportunityIds.add(opp.Returning_Opportunity__c);
            if (opp.AccountId != null)                this.cachedAccountIds.add(opp.AccountId);
            if (opp.ContractId != null)               this.cachedContractIds.add(opp.ContractId);
            if (opp.SBQQ__AmendedContract__c != null) this.cachedContractIds.add(opp.SBQQ__AmendedContract__c);
            if (opp.SBQQ__RenewedContract__c != null) this.cachedContractIds.add(opp.SBQQ__RenewedContract__c);
            if (opp.OwnerId != null)                  this.cachedOwnerIds.add(opp.OwnerId);
            if (opp.Shipping_Address_NEW__c != null)  this.cachedShippingAddressIds.add(opp.Shipping_Address_NEW__c);
        }
    }

    
}