public with sharing class GS_OpportunityPBConversionService {
    
  @TestVisible private Map<Id, Opportunity> oldOppMap;
  @TestVisible private List<Opportunity> newOppList;
  @TestVisible private GS_OpportunityCacheService cache;

    public GS_OpportunityPBConversionService(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList, GS_OpportunityCacheService cache){
        this.oldOppMap  = oldOppMap;
        this.newOppList = newOppList;
        this.cache      = cache;
    }

    public void readyToShipOrClosedWon(){
        Map<Id,Opportunity> virtualBellOpptyMap = new Map<Id, Opportunity>();

        // Check if trigger.newMap is eligible to push to NS
        for(Opportunity opp : this.newOppList){
            //TODO - include backup to allow for Send Virtual Bell checkbox to trigger the logic a secondary time if necessary
            if(opp.StageName == 'Orders Processing' || opp.StageName == 'Closed Won') {
                if(opp.Send_Virtual_Bell__c){
                    virtualBellOpptyMap.put(opp.Id, opp);
                }
            }
        }
        if(virtualBellOpptyMap.size() > 0){
            (new GS_OpportunityEventPublisherService()).createR2ShipCWPlatformEvent(virtualBellOpptyMap);
        }
    }

    public void processContractUpdates(){
        // Commented below Query as the Account Map is not being used anywhere
        //Map<Id, Account> accountMap = linkContracts(newOpptyMap, oldOpptyMap);
        updateContractBasedFields();
    }

    public void updateContractBasedFields(){

        Set<Id> contractIds = new Set<Id>();
        for(Opportunity opp : this.newOppList) {
            contractIds.add(opp.ContractId);
            if (this.oldOppMap.get(opp.Id).netsuite_conn__From_Contract__c != opp.netsuite_conn__From_Contract__c && opp.netsuite_conn__From_Contract__c != null) {
               contractIds.add(opp.netsuite_conn__From_Contract__c);
            }
            if (this.oldOppMap.get(opp.Id).netsuite_conn__From_Contract__c != opp.netsuite_conn__From_Contract__c && opp.netsuite_conn__From_Contract__c == null) {
                opp.Original_Approved_Discount__c = Null;
            }
        }
        if (!contractIds.isEmpty()) {
        Map<Id, Contract> contractsMap = new Map<Id, Contract>((new GS_ContractSelector()).getContractsWithOppDataById(new List<Id>(contractIds)));

            for (Opportunity oppty : this.newOppList) {
                if (contractsMap.containsKey(oppty.netsuite_conn__From_Contract__c)) {
                    Contract fromContract = contractsMap.get(oppty.netsuite_conn__From_Contract__c);
                    oppty.Original_Approved_Discount__c = fromContract.Original_Approved_Discount__c;
                }
                Opportunity oldOpp = this.oldOppMap.get(oppty.Id);
                oppty.Contract = contractsMap.get(oppty.ContractId);

                if (oppty.ContractId != null) {
                    /*
                    PlaceHolder for Future Changes if needed
                    *
                    */
                } else {
                    // will not have contract
                    if((oppty.netsuite_conn__Bill_To_Tier__c == null && HelperClass.isChanged(oppty, oldOpp, Schema.Opportunity.netsuite_conn__Bill_To_Tier__c)) 
                        || (oppty.License_Term_Approval_Status__c == 'Approved' && HelperClass.isChanged(oppty, oldOpp, Schema.Opportunity.License_Term_Approval_Status__c))){

                        /* Replaces Node 'Contract Unlinked' */
                        oppty.Approved_Discount__c = 10;
                    }

                    
                    if (HelperClass.isChanged(oppty, oldOpp, Schema.Opportunity.StageName) && oppty.Type == 'Revenue Opportunity' && (oppty.StageName == 'Ready to Ship' || oppty.StageName == 'Closed Won')) {
                        
                        if(!oppty.Adjust_License_Start_Date__c && (oppty.License_Start_Date__c == null || oppty.License_End_Date__c == null || oppty.License_Start_Date__c != oppty.CloseDate)) {
                            oppty.CloseDate = Date.today();
                            oppty.License_Start_Date__c = oppty.CloseDate;
                            oppty.License_End_Date__c = Date.newInstance((Integer)(oppty.CloseDate.year() + Math.floor(oppty.CloseDate.month() + oppty.License_Term__c - 1)/12), 
                                                                        Math.mod((Integer)(oppty.CloseDate.month() + oppty.License_Term__c - 1), 12) + 1, 
                                                                        oppty.CloseDate.day() - 1);
                        }
                        
                        if(oppty.Adjust_License_Start_Date__c && oppty.License_Start_Date__c != null && oppty.License_End_Date__c == null) {
                            oppty.License_End_Date__c = Date.newInstance((Integer)(oppty.License_Start_Date__c.year() + Math.floor(oppty.License_Start_Date__c.month() + oppty.License_Term__c - 1)/12), 
                                                                        Math.mod((Integer)(oppty.License_Start_Date__c.month() + oppty.License_Term__c - 1), 12) + 1, 
                                                                        oppty.License_Start_Date__c.day() - 1);
                        }
                    }
                    
                    // Anil Bogadi Auto-Populate License End Date for Promos - GTMS-3963
                    
                    if( HelperClass.isChanged(oppty, oldOpp, Schema.Opportunity.StageName) && oppty.StageName == 'Closed Won' && oppty.Promo_Reason__c == 'Beta Program' && oppty.Type == 'Promo Opportunity') {
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
    }

    public void closingOppWithStripeTrialOrExpessFinanceApproval() {
        for (Opportunity oppty : this.newOppList) {
            if(oppty.StageName == 'Closing' && ((oppty.Type == 'Free Trial Opportunity' || oppty.Type == 'Promo Opportunity' || oppty.Stripe_Subscription_Id__c != null) 
                || (oppty.Type == 'Revenue Opportunity' && oppty.Finance_Notes__c != null 
                && ((oppty.Express_Agreement_Accepted_Date__c <> null && oppty.Price_Book_Name__c != null && oppty.Configuration_Segment__c == 'Express') || (oppty.Amount >0 && oppty.Balance_Due__c < 10))))){
                /* Replaces Node 'Closing Opp with Stripe/Trial OR Express/Finance Approval' */
                oppty.Overwrite_Validation_Rule__c = true;
                oppty.Probability = 98;
                oppty.StageName = 'Orders Processing';
            }
        }
    }

    /*
     * // Commented below Query as the Account Map is not being used anywhere
     * public static Map<Id, Account> linkContracts( Map<Id, Opportunity> newOpptyMap, Map<Id, Opportunity> oldOpptyMap ){

        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Latest_Active_Contract__c, 
                   Latest_Active_Contract__r.EndDate, Segment__c 
            FROM Account
            WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :newOpptyMap.keySet())
        ]);
        return accountMap;
	
    }*/
}