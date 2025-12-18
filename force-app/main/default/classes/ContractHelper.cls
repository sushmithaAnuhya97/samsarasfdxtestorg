/**
* Created by vikasmishra on 2020-10-20.
* 2022-05-27    Flavio Contini    GTMS-6785    Adding the Subscription rollup logic to update Downsell_Timeframe__c field
* June-14-2022  Sweta  GTMS-7342 Changing the status of newly created quotes to Activated
* 2022-06-21    Flavio Contini    GTMS-7526    Adding uncheckAutoRenewal, shouldUncheckAutoRenewal and syncSubscriptionsToRenewalOpps as ports from existing flows into the trigger.
* 2023-Jan-24   Rajesh GTMS-10932. Refactored the code to fix the Latest Active Contract not populated issue
* 2023-June-12   Rajesh GTMS-13686. Added Active Check for latest Active contract
* 2024-Mar-19   Joshna Added logic for Mercury Project
* 2024-Sep-20   Arun Added GTMS-22958 Renewal Opportunity did not Contract successfully because the Original Opportunity had an inactive 3PF Account
* 2024-DEC-26   Abu Added GTMS-25074 P_P_Renewals
*/
public without sharing class ContractHelper {
    private Map<String, Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new Map<String, Rollup_Switch__mdt> ();
    private Set<String> targetRollupAccountSet = new Set<String> ();
    private List<Contract> targetContracts = new List<Contract>();
    private Map<Id, List<SBQQ__Subscription__c>> contractIdToSubscriptionMap = new Map<Id, List<SBQQ__Subscription__c>>();
    // GTMS:25074 by Abu DEC 26 2024 Start:
    public List<Contract> ppRenewalContract = new List<Contract>();
    // GTMS:25074 by Abu DEC 26 2024 End:
    public static final String DOWNSELL_SUBSCRIPTION_TYPE = 'Downsell';
    //GTMS-25074 by Abu on Jan 9th -- Start
    public Set<Id> renewalOpportunityIds = new Set<Id>();
    public List<Contract> conPPrenewList = new List<Contract>();
    //GTMS-25074 by Abu on Jan 9th -- End
    public static Boolean UPDATE_FROM_SUBSCRIPTION_INSERT_FLOW = false;
    
    // GTMS-28592: Class-level variables for fiscal quarter dates (initialized once per batch execution)
    private static Date nextQuarterStartDate;
    private static Date nextQuarterEndDate;
    private static String currentQuarterKey;
    private static Boolean fiscalQuarterDatesInitialized = false;
    public void afterUpdate(List<Contract> newContractList,Map<Id, Contract> oldContractMap,Map<Id, Contract> newContractMap){
        if(newContractList!=null && newContractList.size()>0){
            Set<Id> contractIDs=new Set<Id>();
            List <Id> ContractIDsToEdit = new List<Id>();
            Set <Id> renOpptyIdwithWeightedAvgCon = new Set<Id>();//GTMS-23000
            Set<Id> contractsWithRenewableACVChange = new Set<Id>(); // For Available_TO_Renew__c update
            Date createdDateFilter= Date.newinstance(2023, 1, 1);
            for(Contract c:newContractList){
                contractIDs.add(c.Id);
                SBQQSubscriptionHelper.skippMethod.add('updateRelatedContract'+c.Id);
                if(c.EndDate != oldContractMap.get(c.id).EndDate && c.RecordTypeName__c == 'Free Trial') {
                    ContractIDsToEdit.add(c.id);
                }
                // GTMS:25074 by Abu DEC 26 2024 Start:
                if(c.P_P_Renewals__c == True && c.P_P_Renewals__c != oldContractMap.get(c.id).P_P_Renewals__c){
                    ppRenewalContract.add(c);
                }
                // GTMS:25074 by Abu DEC 26 2024 End:
                //GTMS-23000
                if(c.Weighted_Average_Start_Date__c != oldContractMap.get(c.id).Weighted_Average_Start_Date__c){
                    //renOpptyIdwithWeightedAvgCon.add(c.SBQQ__RenewalOpportunity__c);
                    renOpptyIdwithWeightedAvgCon.add(c.id);
                }
                // Check if Contract_Renewable_ACV__c has changed
                if(c.Contract_Renewable_ACV_USD__c != oldContractMap.get(c.id).Contract_Renewable_ACV_USD__c && c.SBQQ__RenewalOpportunity__c != null){
                    contractsWithRenewableACVChange.add(c.Id);
                }
            }
            if(contractIDs.size()>0){
                List<SBQQ__Subscription__c> listSubTobUpdated=new List<SBQQ__Subscription__c>();
                List<SBQQ__Subscription__c> listSubscription=[Select Id,SBQQ__SubscriptionStartDate__c,SBQQ__SubscriptionEndDate__c,SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_Start_Date__c,SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_End_Date__c
                                                              From SBQQ__Subscription__c Where SBQQ__Contract__c=:contractIDs AND SBQQ__QuoteLine__c!=null AND SBQQ__QuoteLine__r.SBQQ__Quote__c!=null AND SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__c!=null AND CreatedDate>=:createdDateFilter];
                for(SBQQ__Subscription__c s:listSubscription){
                    if(
                        (s.SBQQ__SubscriptionStartDate__c!=null && s.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_Start_Date__c!=s.SBQQ__SubscriptionStartDate__c) ||
                        (s.SBQQ__SubscriptionEndDate__c!=null && s.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_End_Date__c!=s.SBQQ__SubscriptionEndDate__c)
                    ){
                        listSubTobUpdated.add(s);
                    }
                }
                if(listSubTobUpdated.size()>0){
                    update listSubTobUpdated;
                }
            }
            If(!ContractIDsToEdit.isEmpty()) UpdateAmendmentOpportunities(ContractIDsToEdit);
            //GTMS-23000
            If(!renOpptyIdwithWeightedAvgCon.isEmpty() && !System.isBatch() && !System.isFuture() && !System.isQueueable() ){
                UpdateRenewalOpptyCloseDate(renOpptyIdwithWeightedAvgCon);
            }
            // GTMS:25074 by Abu DEC 26 2024 Start:
            if(ppRenewalContract.size()>0 && !ppRenewalContract.isEmpty()){
                System.debug('I am in If: ');
                System.debug('ppRenewalContract: '+ppRenewalContract);
                ID jobID = System.enqueueJob(new ContractRenewalQueueable('New',ppRenewalContract,NULL,NULL,NULL,NULL,NULL));
            }
            // GTMS:25074 by Abu DEC 26 2024 End:
            
            // Update Available_TO_Renew__c on renewal opportunities when Contract_Renewable_ACV__c changes
            if(!contractsWithRenewableACVChange.isEmpty() && !System.isBatch() && !System.isFuture() && !System.isQueueable()){
                updateRenewalOpportunityAvailableToRenew(contractsWithRenewableACVChange);
            }
        }
    }
    //GTMS-23000 to Update Renewal Opportunity Close Date when Weighted_Average_Start_Date__c is populated or update on the contract
    @future
    public static void UpdateRenewalOpptyCloseDate(Set<Id> renOpptyIdwithWeightedAvgCon){
        system.debug('coming into our UpdateRenewalOpptyCloseDate joshna');
        Map<Id, Opportunity> renOpptiesToUpdate = new Map<Id,Opportunity>();
        Set<Id> opptyIds = new Set<Id>();
        if(renOpptyIdwithWeightedAvgCon.size() >0){
            for(Contract Con : [Select Id, SBQQ__RenewalOpportunity__c From Contract Where Id=:renOpptyIdwithWeightedAvgCon]){
                opptyIds.add(Con.SBQQ__RenewalOpportunity__c);
            }
            //for(Opportunity Opp : [select Id, License_Start_Date__c,Adjust_License_Start_Date__c,CloseDate,SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c, SBQQ__RenewedContract__r.EndDate from Opportunity where ID IN:renOpptyIdwithWeightedAvgCon]) {
            for(Opportunity Opp : [select Id, License_Start_Date__c,Adjust_License_Start_Date__c,CloseDate, SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c,
                                   SBQQ__RenewedContract__r.EndDate from Opportunity where ((SBQQ__RenewedContract__c!= null and SBQQ__RenewedContract__c=:renOpptyIdwithWeightedAvgCon)
                                                                                            or Id =:opptyIds) and IsClosed = false]) {
                                                                                                if(Opp.SBQQ__RenewedContract__c != null && Opp.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c == null){
                                                                                                    Opp.License_Start_Date__c = Opp.SBQQ__RenewedContract__r.EndDate+1;
                                                                                                    Opp.CloseDate = Opp.SBQQ__RenewedContract__r.EndDate+1;
                                                                                                    if(Opp.License_Start_Date__c >= date.today()){
                                                                                                        Opp.Adjust_License_Start_Date__c = true;
                                                                                                    }else{
                                                                                                        Opp.Adjust_License_Start_Date__c = false;
                                                                                                    }
                                                                                                }
                                                                                                if(!renOpptiesToUpdate.containsKey(Opp.id)){
                                                                                                    renOpptiesToUpdate.put(Opp.id , Opp);
                                                                                                }
                                                                                            }
        }
        if(renOpptiesToUpdate.size()>0){
            GS_SBQQQuoteService.OppStartDateUpdatedFromContract = true;
            update renOpptiesToUpdate.values();
        }
        /*if(!renOpptiesToUpdate.isEmpty()){
Database.SaveResult[] saveResults = Database.update(renOpptiesToUpdate, false);
for (Database.SaveResult saveResult : saveResults) {
if (!saveResult.isSuccess()) {
for (Database.Error error : saveResult.getErrors()) {
System.debug('Error updating Opportunity: ' + error.getMessage());
}
}
}
}*/
    }
    //GTMS-23000 End
    
    /**
     * Future method to update Available_TO_Renew__c field on renewal opportunities when Contract_Renewable_ACV__c changes
     * Only updates contracts that are NOT master contracts (either DR or normal consolidation)
     * Skips contracts with closed renewal opportunities
     * @param contractsWithRenewableACVChange Set of contract IDs where Contract_Renewable_ACV__c has changed
     */
    
    public static void updateRenewalOpportunityAvailableToRenew(Set<Id> contractsWithRenewableACVChange) {
        if(contractsWithRenewableACVChange == null || contractsWithRenewableACVChange.isEmpty()) {
            return;
        }
        
        
        // Single optimized query to get all contract information we need
        // Including both the contracts and their master contract relationships in one query
        Map<Id, Contract> allContractsMap = new Map<Id, Contract>([
            SELECT Id, Contract_Renewable_ACV_USD__c, SBQQ__RenewalOpportunity__c, 
                   SBQQ__RenewalOpportunity__r.Id, SBQQ__RenewalOpportunity__r.Available_TO_Renew__c,
                   SBQQ__RenewalOpportunity__r.IsClosed, Consolidated_Master_Contract__c
            FROM Contract 
            WHERE Id IN :contractsWithRenewableACVChange 
            OR Consolidated_Master_Contract__c IN :contractsWithRenewableACVChange
        ]);
        
        // Identify master contracts by finding contracts that have children pointing to them
        Set<Id> masterContractIds = new Set<Id>();
        for(Contract contract : allContractsMap.values()) {
            if(contract.Consolidated_Master_Contract__c != null && 
               contractsWithRenewableACVChange.contains(Id.valueOf(contract.Consolidated_Master_Contract__c))) {
                masterContractIds.add(Id.valueOf(contract.Consolidated_Master_Contract__c));
            }
        }
        
        // Process non-master contracts that have open renewal opportunities
        List<Opportunity> renewalOppsToUpdate = new List<Opportunity>();
        for(Id contractId : contractsWithRenewableACVChange) {
            Contract contract = allContractsMap.get(contractId);
            if(contract == null) continue;
            
            // Skip master contracts
            if(masterContractIds.contains(contract.Id)) {
                continue;
            }
            
            // Only process contracts with open renewal opportunities
            if(contract.SBQQ__RenewalOpportunity__c != null && 
               contract.SBQQ__RenewalOpportunity__r.IsClosed == false) {
                                
                // Update the Available_TO_Renew__c field with the contract's renewable ACV value
                Opportunity renewalOpp = new Opportunity(
                    Id = contract.SBQQ__RenewalOpportunity__c,
                    Available_TO_Renew__c = contract.Contract_Renewable_ACV_USD__c
                );
                renewalOppsToUpdate.add(renewalOpp);
            }
        }
        
        // Update the opportunities if any were found
        if(!renewalOppsToUpdate.isEmpty()) {
            try {

                update renewalOppsToUpdate;

            } catch(Exception e) {
            }

        } 
    }
    
    public void calculateAllRollUpsToAccount(List<Contract> contractList, Map<Id, Contract> OldContractMap) {
        //GTMS-10932
        /*mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Account', 'Contract');
loadContractTargetRollupAccountSet(contractList, OldContractMap);
loadTargetContracts();
calculateAllRollUpsToAccount();*/
        Map<Id,Contract> accountsToUpdate = new Map<Id,Contract>();
        Set<Id> accontIdSet = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        for(Contract c : contractList){
            if(c.AccountId <> null){
                accontIdSet.add(c.AccountId);
            }
            if(OldContractMap <> NULL && c.AccountId <> OldContractMap.get(c.id).accountId){
                accontIdSet.add(OldContractMap.get(c.id).accountId);
            }
            if(OldContractMap <> NULL && (c.EndDate != OldContractMap.get(c.id).EndDate || c.CurrencyIsoCode  != OldContractMap.get(c.id).CurrencyIsoCode)) {
                contractIds.add(c.Id);
            }
        }
        Map<Id,Account> mapAccountToBeUpdated=new Map<Id,Account>();
        if(trigger.Isupdate && trigger.IsAfter){
            List<Account> accountsListtoUpdate = TrackAccountFieldsToPublishPlatEvents.trackAccountFields(contractIds,Contract.sObjectType);
            mapAccountToBeUpdated = new Map<Id,Account>(accountsListtoUpdate);
            DMLWrapper.intializeUnitOfWork(new List<Schema.SObjectType>{Account.SObjectType});
        }
        Set<Id> latestContract=new Set<Id>();
        List<Account> listAccount = [Select Id,Latest_Active_Contract__c,SBQQ__RenewalPricingMethod__c,
                                     Netsuite_Delinquent_Status__c,
                                     (SELECT Id, Is_Active__c, EndDate,SBQQ__RenewalUpliftRate__c,
                                      SBQQ__Opportunity__c,SBQQ__Opportunity__r.ACV_Bookings_SOT__c
                                      FROM Contracts
                                      WHERE Is_Active__c = TRUE ORDER BY AccountId, EndDate DESC)
                                     FROM Account Where Id IN :accontIdSet ];
        for(Account a:listAccount){
            String latestActiveContractId,pricingMethod;
            for(Contract c:a.Contracts){
                if(
                    latestContract.contains(a.Id)==false &&
                    c.EndDate>Date.today() &&
                    a.Netsuite_Delinquent_Status__c!='Written-off' &&
                    a.Netsuite_Delinquent_Status__c != 'Deactivated' &&
                    c.SBQQ__Opportunity__c!=null &&
                    c.SBQQ__Opportunity__r.ACV_Bookings_SOT__c > 0){
                        latestContract.add(a.Id);
                        latestActiveContractId=c.Id;
                    }
                if(c.SBQQ__RenewalUpliftRate__c!=null && c.SBQQ__RenewalUpliftRate__c!=0){
                    pricingMethod='Uplift';
                }
            }
            if(a.Latest_Active_Contract__c!=latestActiveContractId || a.SBQQ__RenewalPricingMethod__c!=pricingMethod){
                a.Latest_Active_Contract__c=latestActiveContractId;
                a.SBQQ__RenewalPricingMethod__c=pricingMethod;
                if(mapAccountToBeUpdated.containskey(a.Id)){a.Push_to_Webstore__c=true;}
                mapAccountToBeUpdated.put(a.Id,a);
            }
        }
        if(mapAccountToBeUpdated.size()>0){
            DMLWrapper.doUpdate(mapAccountToBeUpdated.values());
        }
        //////////////
        //GTMS-13686
        /* List<Contract> targetContracts = [SELECT Id, AccountId, Is_Active__c, EndDate,SBQQ__RenewalUpliftRate__c,
Account.SBQQ__RenewalPricingMethod__c,Account.Latest_Active_Contract__c
FROM Contract
WHERE Is_Active__c = TRUE AND Account.Netsuite_Delinquent_Status__c <> 'Written-off'
AND Account.Netsuite_Delinquent_Status__c <> 'Deactivated'
AND SBQQ__Opportunity__r.ACV_Bookings_SOT__c > 0 AND EndDate <> NULL AND EndDate > TODAY
AND AccountId IN :accontIdSet ORDER BY AccountId, EndDate DESC];
for(Contract c : targetContracts){
if(accountsToUpdate.containsKey(c.AccountId) == False){
accountsToUpdate.put(c.AccountId,c);
}
}
for(Id i : accontIdSet){
if(accountsToUpdate.containsKey(i) == False){
accountsToUpdate.put(i,NULL);
}
}
if(accountsToUpdate.size() > 0){
List<Account> accnts = new List<Account>();
for(Id i:accountsToUpdate.keySet()){
if(accountsToUpdate.get(i) == NULL
|| accountsToUpdate.get(i).Account.Latest_Active_Contract__c == NULL
|| accountsToUpdate.get(i).Id <> accountsToUpdate.get(i).Account.Latest_Active_Contract__c
){
accnts.add(new Account(Id = i, Latest_Active_Contract__c = (accountsToUpdate.get(i) <> NULL ? accountsToUpdate.get(i).Id : NULL)));
}
}
if(accnts.size() > 0)
DMLWrapper.doUpdate(accnts);
}*/
    }
    // endDatePushtoWebstore
    public void endDatePushtoWebstore(List<Contract> contractList, Map<Id, Contract> OldContractMap) {
        if(contractList==null || contractList.size()==0 || OldContractMap.isEmpty() || OldContractMap==null){
            return;
        }
        Set<Id> contractIds = new Set<Id>();
        for(Contract c:contractList){
            if(c.EndDate != OldContractMap.get(c.id).EndDate || c.CurrencyIsoCode  != OldContractMap.get(c.id).CurrencyIsoCode) {
                contractIds.add(c.Id);
            }
        }
        if(contractIds.isEmpty()){
            return;
        }
        //Retrieve Metadata toggle
        //Toggle_Platform_Event__mdt accountEventToggle = Toggle_Platform_Event__mdt.getInstance('Account_Sync_Webstore_Event');
        Toggle_Platform_Event__mdt cs360EventToggle = Toggle_Platform_Event__mdt.getInstance('Customer_360_Event');
        /*Sync_Object_Field_WebStore__mdt [] accountNullCheckFields = [Select Id,Object_Api_Name__c,Field_Api_Name__c,Null_Check_Needed__c from Sync_Object_Field_WebStore__mdt Where Object_Api_Name__c = 'Account' and Null_Check_Needed__c = true];
List<Account> accList = [select id,Name,Current_Owner_Email__c, Which_Written_Language__c,BigCommerce_Id__c,
CurrencyIsoCode,Segment__c ,Segment_Text_Stamped__c,SAM_Number_Undecorated__c,SAM_Number_Decorated__c,Push_to_Webstore__c,
Billing_Email__c,Billing_First_Name__c ,Billing_Last_Name__c ,BillingCountry, BillingCountryCode,BillingState,BillingStateCode,
Latest_Active_Contract__c from Account where Latest_Active_contract__c in: contractIds];
if(!accList.isEmpty()){
List<Account> AccountstoUpdate = New List<Account>();
for(Account acc : accList){
Boolean nullFlagCheck = verifyNullCheck(acc,accountNullCheckFields);
if ((nullFlagCheck || Acc.BigCommerce_Id__c != null) && acc.Push_to_Webstore__c == false && accountEventToggle.toggle__c){
Account Accnt = new Account(Id = acc.Id, Push_to_Webstore__c = true);
AccountstoUpdate.add(Accnt);
}
}
If(AccountstoUpdate.size() > 0){
update AccountstoUpdate;
}
}*/
        //update cs360toUpdate
        List<Customer_360__c> cs360toUpdate = New List<Customer_360__c>();
        for(Customer_360__c cs360 : [select Id,Account__c,BigCommerce_Id__c,Push_to_Webstore__c from Customer_360__c where Account__c != null and Latest_Active_Contract_Historical__c in: contractIds]){
            if(cs360.Account__c != null && cs360.BigCommerce_Id__c != null && cs360.Push_to_Webstore__c == false && cs360EventToggle.toggle__c){
                Customer_360__c css360 = new Customer_360__c(Id = cs360.Id, Push_to_Webstore__c = true);
                cs360toUpdate.add(css360);
            }
        }
        If(cs360toUpdate.size() > 0){
            update cs360toUpdate;
        }
    }
    /*public static Boolean verifyNullCheck(Account Acc,Sync_Object_Field_WebStore__mdt [] AccountNullCheckFields){
//To check the nulls in Acc mandate fields
for(Sync_Object_Field_WebStore__mdt EachMdtField: AccountNullCheckFields){
if(Acc.get(EachMdtField.Field_Api_Name__c)==null){
return false;
}
}
return true;
}*/
    /*private void calculateAllRollUpsToAccount() {
Map<string, Map<String, List<Contract>>> mapOfRollupFiledVsRecordList = new Map<string, Map<String, List<Contract>>> ();
Map<String, List<Contract>> mapOfAccountIdVsContractList = new Map<String, List<Contract>>();
for (String accountId : targetRollupAccountSet) {
if (!mapOfAccountIdVsContractList.ContainsKey(accountId)) mapOfAccountIdVsContractList.put(accountId, new List<Contract>());
}
for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
if (!mapOfRollupFiledVsRecordList.containsKey(rollUpField))
mapOfRollupFiledVsRecordList.put(rollUpField, mapOfAccountIdVsContractList);
}
for (integer i = 0; i < targetContracts.size(); i++) {
for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
Callable callInstance = (Callable) Type.forName('ContractHelper').newInstance();
if ((Boolean) callInstance.call(rollUpField, new map<String, Object>{
'newRecord' => targetContracts[i]
})) {
if (!mapOfRollupFiledVsRecordList.ContainsKey(rollUpField)) mapOfRollupFiledVsRecordList.put(rollUpField, new Map<String, List<Contract>>());
if (!mapOfRollupFiledVsRecordList.get(rollUpField).containsKey(targetContracts[i].AccountId))
mapOfRollupFiledVsRecordList.get(rollUpField).put(targetContracts[i].AccountId, new List<Contract>());
mapOfRollupFiledVsRecordList.get(rollUpField).get(targetContracts[i].AccountId).add(targetContracts[i]);
}
}
}
Map<String, Schema.SObjectField> accountFieldsMap = Account.SObjectType.getDescribe().fields.getMap();
for (String rollupField : mapOfRollupFiledVsRecordList.keySet()) {
if (!mapOfRollupFiledVsRecordList.containsKey(rollupField)) {
continue;
}
Schema.SobjectField theDirtyField = accountFieldsMap.get(rollupField);
for (String accountId : mapOfRollupFiledVsRecordList.get(rollupField).keySet()) {
Account thisAccount = new Account(Id = accountId);
if (mapOfRollupFiledVsRecordList.get(rollupField).get(accountId).isEmpty()) {
System.debug('rollupField1====='+rollupField);
thisAccount.put(rollupField, null);
DMLWrapper.doUpdate(thisAccount, new List<SobjectField>{
theDirtyField
});
continue;
}
if (rollupField == 'SBQQ__RenewalPricingMethod__c') {
String renewalPricingMethod = getRenewalPricingMethod(mapOfRollupFiledVsRecordList.get(rollupField).get(accountId));
if(renewalPricingMethod!='NOUPDATE'){
thisAccount.put(rollupField, renewalPricingMethod);
DMLWrapper.doUpdate(thisAccount, new List<SobjectField>{
theDirtyField
});
}
continue;
}
//Todo handling the count first last and average using Callable
Callable callInstance = (Callable) Type.forName('ContractHelper').newInstance();
if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'LAST' && rollupField != 'SBQQ__RenewalPricingMethod__c') {
Contract lastContract = new Contract();
object result = callInstance.call('LAST', new map<String, Object>{
'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(accountId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
});
if (result == null) continue;
lastContract = (Contract) result;
if (lastContract == null) continue;
if(lastContract.Account.Latest_Active_Contract__c!=lastContract.Id){
thisAccount.put(rollupField, lastContract.Id);
DMLWrapper.doUpdate(thisAccount, new List<SobjectField>{
theDirtyField
});
}
}
}
}
}
public String getRenewalPricingMethod(List<Contract> cList) {
String renewalPricingMethod='';
String exisitngRenewalPricingMethod='';
for (Contract c : cList) {
exisitngRenewalPricingMethod=c.Account.SBQQ__RenewalPricingMethod__c;
if(c.Is_Active__c == true && c.SBQQ__RenewalUpliftRate__c!=null && c.SBQQ__RenewalUpliftRate__c!=0){
renewalPricingMethod='Uplift';
break;
}
}
if(renewalPricingMethod==exisitngRenewalPricingMethod){
renewalPricingMethod='NOUPDATE';
}
return renewalPricingMethod;
}*/
    public void activateContractAfterInsert(List<Contract> contractList){
        List<Contract> contractListToUpdate = new List<Contract>(); //GTMS-7342
        for (Contract ctt : contractList)
            contractListToUpdate.add(new Contract(Id = ctt.Id, Status = 'Activated')); //GTMS-7342
        //GTMS-7342
        if (contractListToUpdate.size() > 0)
            DMLWrapper.doUpdate(contractListToUpdate);
    }
    // Future method to update the amendment opportunities for free trial contract with new end date
    @future
    public static void UpdateAmendmentOpportunities(List<Id> ContractIds){
        List<Opportunity> amendmentOpps = [Select id,CloseDate,SBQQ__AmendedContract__r.EndDate from Opportunity where SBQQ__AmendedContract__c IN :ContractIds AND Type = 'Free Trial Opportunity'];
        List<Opportunity> OpportunitiesToUpdate = new List<Opportunity>();
        for(Opportunity Opp :amendmentOpps) {
            Opportunity oppty = new Opportunity();
            oppty.id = Opp.id;
            oppty.Trial_End_date_from_contract__c = Opp.SBQQ__AmendedContract__r.EndDate;
            OpportunitiesToUpdate.add(oppty);
        }
        if(!OpportunitiesToUpdate.isEmpty())
            update OpportunitiesToUpdate;
    }
    /*public void loadContractTargetRollupAccountSet(List<Contract> contractList, Map<Id, Contract> OldContractMap) {
if (OldContractMap == null) {
Callable callInstance = (Callable) Type.forName('ContractHelper').newInstance();
for (integer i = 0; i < contractList.size(); i++) {
for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
Object result = callInstance.call(rollUpField, new map<String, Object>{
'newRecord' => contractList[i]
});
if (result == null) continue;
if ((Boolean) result) {
if (contractList[i].AccountId != null)
targetRollupAccountSet.add(contractList[i].AccountId);
break;
}
}
}
} else {
for (integer i = 0; i < contractList.size(); i++) {
for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
if (accountReparenting(contractList[i], OldContractMap.get(contractList[i].id))) {
if (OldContractMap.get(contractList[i].id).AccountId != null)
targetRollupAccountSet.add(OldContractMap.get(contractList[i].id).AccountId);
if (contractList[i].AccountId != null)
targetRollupAccountSet.add(contractList[i].AccountId);
} else {
Callable callInstance = (Callable) Type.forName('ContractHelper').newInstance();
object result = callInstance.call(rollUpField + 'PreCheck', new map<String, Object>{
'newRecord' => contractList[i], 'oldRecord' => OldContractMap.get(contractList[i].id)
});
if (result == null) continue;
if ((Boolean) result) {
if (contractList[i].AccountId != null)
targetRollupAccountSet.add(contractList[i].AccountId);
break;
}
}
}
}
}
}
public Object call(String action, Map<String, Object> args) {
switch on action {
when 'Latest_Active_Contract__c' {
return this.rollup_Latest_Active_ContractCondition((Contract) args.get('newRecord'));
}
when 'Latest_Active_Contract__cPreCheck' {
return this.latest_Active_ContractPreCheck((Contract) args.get('newRecord'), (Contract) args.get('oldRecord'));
}
when 'SBQQ__RenewalPricingMethod__c' {
return this.renewalPricingMethod_ContractCondition((Contract) args.get('newRecord'));
}
when 'SBQQ__RenewalPricingMethod__cPreCheck' {
return true;
}
when 'LAST' {
return this.last((List<Sobject>) args.get('recordList'), (String) args.get('field'));
}
when else {
return null;
}
}
}
public void loadTargetContracts() {
targetContracts = [
SELECT Id, AccountId, Is_Active__c, EndDate,SBQQ__RenewalUpliftRate__c,Account.SBQQ__RenewalPricingMethod__c,Account.Latest_Active_Contract__c
FROM Contract
WHERE AccountId IN :targetRollupAccountSet
];
}
private Boolean accountReparenting(Contract thisRecord, Contract oldrecord) {
return (thisRecord.AccountId != oldrecord.AccountId);
}
private Boolean latest_Active_ContractPreCheck(Contract thisContract, Contract oldContract) {
return (thisContract.Is_Active__c != oldContract.Is_Active__c || thisContract.EndDate != oldContract.EndDate) && (rollup_Latest_Active_ContractCondition(thisContract) || rollup_Latest_Active_ContractCondition(oldContract));
}
private Boolean rollup_Latest_Active_ContractCondition(Contract thisContract) {
return thisContract.Is_Active__c == true;
}
private Boolean renewalPricingMethod_ContractCondition(Contract thisContract) {
return thisContract.Is_Active__c == true && thisContract.SBQQ__RenewalUpliftRate__c!=null && thisContract.SBQQ__RenewalUpliftRate__c!=0 && ( String.isBlank(thisContract.Account.SBQQ__RenewalPricingMethod__c) ||  thisContract.Account.SBQQ__RenewalPricingMethod__c!='Uplift');
}
private Sobject last(List<Sobject>recordList, String field) {
return RollupService.last(recordList, field);
}*/
    /**
* GTMS-6785 - Be able to track "Reverse Churns"
* Flavio Contini
*/
    public void runSubscriptionRollup(Map<Id, Contract> newContractMap){
        // Fetch all Subscriptions
        getSubscriptionsByContract(newContractMap.keySet());
        for (Id contractId : newContractMap.keySet()){
            Contract ctt = newContractMap.get(contractId);
            // Set contract rollup starting values
            resetRollupValues(ctt);
            // Aux variables
            Boolean contractDownsellSet = false;
            Decimal newRenewalACV = 0;
            List<SBQQ__Subscription__c> subscriptionList = this.contractIdToSubscriptionMap.get(contractId);
            ctt.Deactivated__c=subscriptionList==null?true:false;
            if (subscriptionList == null) return;
            Decimal total_Subscriptions_Quantity=0;
            for (SBQQ__Subscription__c subscription : subscriptionList){
                // If just one is true, break.
                total_Subscriptions_Quantity+=subscription.SBQQ__Quantity__c==null?0:subscription.SBQQ__Quantity__c;
                if (!contractDownsellSet && (contractDownsellSet = this.checkForContractDownsell(subscription))){
                    ctt.ContractDownsell__c = this.checkForContractDownsell(subscription);
                    contractDownsellSet = true;
                }
                newRenewalACV += this.getRenewalACVValue(subscription);
            }
            ctt.Deactivated__c=total_Subscriptions_Quantity<=0?true:false;
            if(ctt.Netsuite_Delinquent_Status__c != NULL && ctt.Netsuite_Delinquent_Status__c == 'Written-off'){
                ctt.Deactivated__c = true;
            }
            Decimal annualACV = this.getAnnualACVValue(ctt, newRenewalACV);
            if (ctt.Contract_Renewal_ACV__c != annualACV) this.uncheckAutoRenewal(ctt);
            ctt.Contract_Renewal_ACV__c = annualACV;
        }
    }
    private Boolean checkForContractDownsell(SBQQ__Subscription__c subscription){
        return (subscription.Renewal_LineItem_Type__c == DOWNSELL_SUBSCRIPTION_TYPE && subscription.SBQQ__Quantity__c < 0);
    }
    private Decimal getRenewalACVValue(SBQQ__Subscription__c subscription){
        return (subscription.SBQQ__NetPrice__c==null?0:subscription.SBQQ__NetPrice__c) * (subscription.SBQQ__RenewalQuantity__c==null?0:subscription.SBQQ__RenewalQuantity__c);
    }
    private Decimal getAnnualACVValue(Contract ctt, Decimal acvSum){
        Decimal annualACV = acvSum;
        if (ctt.ContractTerm > 12)
            annualACV = ((acvSum / ctt.ContractTerm) * 12);
        return annualACV;
    }
    private void getSubscriptionsByContract(Set<Id> contractIds){
        if (this.contractIdToSubscriptionMap == null || this.contractIdToSubscriptionMap.size() <= 0){
            for (SBQQ__Subscription__c subscription : [
                SELECT Id, SBQQ__Quantity__c,Renewal_LineItem_Type__c,
                SBQQ__NetPrice__c, SBQQ__RenewalQuantity__c,
                SBQQ__Contract__c
                FROM SBQQ__Subscription__c
                WHERE SBQQ__SubscriptionType__c!='One-time' AND SBQQ__Contract__c IN :contractIds
            ]){
                List<SBQQ__Subscription__c> subscriptionList = this.contractIdToSubscriptionMap.get(subscription.SBQQ__Contract__c);
                if (subscriptionList == null){
                    subscriptionList = new List<SBQQ__Subscription__c>();
                    this.contractIdToSubscriptionMap.put(subscription.SBQQ__Contract__c, subscriptionList);
                }
                subscriptionList.add(subscription);
            }
        }
    }
    private void resetRollupValues(Contract ctt){
        ctt.ContractDownsell__c = false;
    }
    /**
* Unchecks the Auto-Renewal field if Contract's ACV > 10k
* Flávio Contini
*/
    private void uncheckAutoRenewal(Contract ctt){
        if (ctt.Contract_Renewal_ACV__c >= 10000
            && ctt.SBQQ__RenewalForecast__c
            && !ctt.SBQQ__RenewalQuoted__c
            && ctt.Auto_Renewal__c
           ){
               ctt.Auto_Renewal__c = false;
           }
    }
    //https://samsaradev.atlassian.net/browse/GTMS-10458
    public void beforeInsert(List<Contract> newContractList){
        if(newContractList!=null && newContractList.size()>0){
            Set<Id> oppIds=new Set<Id>();
            for(Contract c:newContractList){
                if(c.SBQQ__Opportunity__c!=null){
                    oppIds.add(c.SBQQ__Opportunity__c);
                }
            }
            //GTMS-14430 --s> Abu Saleh Khan (Added date logic to default Grace Period to ContractEndDate+2 days)
            if(oppIds.size()>0){
                Map<Id,Opportunity> mapOpps=new Map<Id,Opportunity>([Select Id,CloseDate,License_Start_Date__c,License_End_Date__c,Trial_Start_Date_New__c,
                                                                     Trial_End_Date__c, Type, Finance_Partner__c, StageName, Finance_Partner__r.Is_Finance_Partner_Active__c From Opportunity Where Id=:oppIds]);
                for(Contract c:newContractList){
                    if(c.SBQQ__Opportunity__c!=null && mapOpps.containsKey(c.SBQQ__Opportunity__c)){
                        Opportunity o=mapOpps.get(c.SBQQ__Opportunity__c);
                        c.StartDate=o.License_Start_Date__c!=null?o.License_Start_Date__c:o.CloseDate;
                        c.EndDate=o.License_End_Date__c!=null?o.License_End_Date__c:c.EndDate;
                        c.GP_End_Date__c = c.EndDate+2;
                        //GTMS-14430 --s> Abu Saleh Khan (Added date logic to default Grace Period to ContractEndDate+2 days)
                        // added for GTMS-13244
                        if(o.Type == 'Free Trial Opportunity') {
                            c.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Free_Trial').getRecordTypeId();
                            c.StartDate=o.Trial_Start_Date_New__c!=null?o.Trial_Start_Date_New__c:o.CloseDate;
                            c.EndDate=o.Trial_End_Date__c!=null?o.Trial_End_Date__c:c.EndDate;
                        }
                        if(o.StageName =='Closed Won' && o.Finance_Partner__r.Is_Finance_Partner_Active__c){ // added GTMS-16222
                            c.Finance_Partner_Account__c = o.Finance_Partner__c;
                        }
                        
                    }
                }
            }
        }
    }
    //GTMS-14430 Abu Saleh Khan --> added an extra Parameter to beforeInsertUpdate method.
    //https://samsaradev.atlassian.net/browse/GTMS-10566
    public void beforeInsertUpdate(List<Contract> newContractList,Map<Id, Contract> oldContractMap,Map<Id,Contract> newContractMap){
        if(newContractList!=null && newContractList.size()>0){
            Set<Id> finacePartnerAccountIds = new Set<Id>();
            //GTMS-25074 -- 01/09/2025 -- Abu Saleh Khan ---> Start
            Set<Id> conPPrenewal = new Set<Id>();
            Set<Id> opptyIds=new Set<Id>();
          //GTMS-25074 -- 01/09/2025 -- Abu Saleh Khan ---> End
            if(Label.Execute_Code_Check == 'True' || Test.isRunningTest()){
                for(Contract c:newContractList){
                    if(c.Auto_Renewal__c==true && c.SBQQ__Opportunity__c!=null){
                        opptyIds.add(c.SBQQ__Opportunity__c);
                    }
                    //GTMS-25074 -- 01/09/2025 -- Abu Saleh Khan ---> Start
                    if(c.P_P_Renewals__c){
                        conPPrenewal.add(c.Id);
                    }
                    if(c.P_P_Renewals__c == True && c.SBQQ__RenewalOpportunity__c != NULL){
                        renewalOpportunityIds.add(c.SBQQ__RenewalOpportunity__c);
                        conPPrenewList.add(c);
                    }
                    //GTMS-25074 -- 01/09/2025 -- Abu Saleh Khan ---> End
                    if(oldContractMap!=null && c.Auto_Renewal__c!=oldContractMap.get(c.Id).Auto_Renewal__c && c.Auto_Renewal__c==false){
                        c.SBQQ__RenewalUpliftRate__c=null;
                    }
                    //if(c.Auto_Renewal__c==true && c.SBQQ__RenewalUpliftRate__c==null && (oldContractMap==null || oldContractMap.get(c.Id).Auto_Renewal__c==false || oldContractMap.get(c.Id).ContractTerm!=c.ContractTerm)){
                    /*if(c.Is_Active__c && c.Auto_Renewal__c==true && c.SBQQ__RenewalUpliftRate__c==null && c.ContractTerm!=null ){
                        Decimal baseUplift = Decimal.ValueOf(Label.Contract_BaseUplift_Decimal_Value);
                        c.SBQQ__RenewalUpliftRate__c=((baseUplift/12)*c.ContractTerm).setscale(3);
                    }*/
                    //GTMS-14430 Abu Saleh Khan --> Start
                    if(oldContractMap!=null && newContractMap!= null){
                        if(newContractMap.get(c.Id).ApprovalStatus__c!=oldContractMap.get(c.Id).ApprovalStatus__c && newContractMap.get(c.Id).ApprovalStatus__c == 'Approved'){
                            c.GP_End_Date__c = newContractMap.get(c.Id).EndDate+30;
                        }else if(newContractMap.get(c.Id).ApprovalStatus__c!=oldContractMap.get(c.Id).ApprovalStatus__c && newContractMap.get(c.Id).ApprovalStatus__c == 'Rejected'){
                            c.GP_End_Date__c = newContractMap.get(c.Id).EndDate+2;
                        }
                        if (c.Finance_Partner_Account__c != null) {
                            finacePartnerAccountIds.add(c.Finance_Partner_Account__c);
                        }
                    }
                    //GTMS-14430 Abu Saleh Khan--> End
                }
                //GTMS-25074 -- 01/09/2025 -- Abu Saleh Khan ---> Start
                if(conPPrenewal.size()>0 && !conPPrenewal.isEmpty() && renewalOpportunityIds != NULL && !renewalOpportunityIds.isEmpty()){
                    
                    Map<ID,List<SBQQ__Quote__c>> opportunityQuotesMap = new Map<Id,List<SBQQ__Quote__c>>();
                    for(Opportunity opp: [SELECT Id, (SELECT ID,SBQQ__Opportunity2__c FROM SBQQ__Quotes2__r LIMIT 1) FROM Opportunity WHERE Id IN :renewalOpportunityIds]){
                        System.debug('opp: '+opp.Id);
                        System.debug('Quote: '+opp.SBQQ__Quotes2__r);
                        if(opp.SBQQ__Quotes2__r.size()>0){
                            for(SBQQ__Quote__c qte: opp.SBQQ__Quotes2__r){
                                if(!opportunityQuotesMap.containsKey(opp.Id)){
                                    opportunityQuotesMap.put(opp.Id,new List<SBQQ__Quote__c>{qte});
                                }else{
                                    opportunityQuotesMap.get(opp.Id).add(qte);
                                }
                            }
                        }else{
                            opportunityQuotesMap.put(opp.Id,new List<SBQQ__Quote__c>());
                        }
                        System.debug('opportunityQuotesMap: '+opportunityQuotesMap);
                    }
                    for(Contract cc: conPPrenewList){
                        if(cc.P_P_Renewals__c && cc.SBQQ__RenewalOpportunity__c != NULL){
                            if(opportunityQuotesMap.get(cc.SBQQ__RenewalOpportunity__c).size() == 0 && opportunityQuotesMap.get(cc.SBQQ__RenewalOpportunity__c).isEmpty()){
                                cc.addError(System.Label.PnP_Renewal_ContractError);
                            }
                        }else{
                            cc.addError(System.Label.PnP_Renewal_ContractError);
                        }
                    }
                }
                //GTMS-25074 -- 01/09/2025 -- Abu Saleh Khan ---> End
                if (!finacePartnerAccountIds.isEmpty()) {
                    Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Is_Finance_Partner_Active__c FROM Account WHERE Id IN: finacePartnerAccountIds AND Is_Finance_Partner_Active__c = false]);
                    for (Contract c : newContractList) {
                        if (c.Finance_Partner_Account__c != null && accountMap.containsKey(c.Finance_Partner_Account__c)) {
                            c.Finance_Partner_Account__c = null;
                        }
                    }
                }
                if(opptyIds.size()>0){
                    Map<Id,Opportunity> mapOpptys=new Map<Id,Opportunity>([Select Id,Selected_Payment_Type__c From Opportunity Where Id=:opptyIds]);
                    for(Contract c:newContractList){
                        if(c.Auto_Renewal__c==true && (oldContractMap==null || c.SBQQ__RenewalUpliftRate__c==null || oldContractMap.get(c.Id).Auto_Renewal__c==false) && c.Is_Active__c){

                            if(c.SBQQ__Opportunity__c!=null && mapOpptys.containsKey(c.SBQQ__Opportunity__c)){

                                Opportunity o=mapOpptys.get(c.SBQQ__Opportunity__c);
                                List<RenewalQuoteCreationSteps__mdt> renewalSteps = RenewalQuoteCreationSteps__mdt.getAll()?.values();
                                if(renewalSteps != null){
                                    for(RenewalQuoteCreationSteps__mdt step:renewalSteps){
                                        if((Integer.valueOf(step.Order__c) == 1 || Integer.valueOf(step.Order__c) == 2 || Integer.valueOf(step.Order__c) == 3) && o.Selected_Payment_Type__c != null && o.Selected_Payment_Type__c == step.Payment_Type__c){

                                            c.SBQQ__RenewalUpliftRate__c = step.Uplift_Percent__c;
                                            break;
                                        }
                                    } 
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    /* List<Contract> targetContracts = [SELECT Id, AccountId, Is_Active__c, EndDate,SBQQ__RenewalUpliftRate__c,
Account.SBQQ__RenewalPricingMethod__c,Account.Latest_Active_Contract__c
FROM Contract
WHERE Is_Active__c = TRUE AND Account.Netsuite_Delinquent_Status__c <> 'Written-off'
AND Account.Netsuite_Delinquent_Status__c <> 'Deactivated'
AND SBQQ__Opportunity__r.ACV_Bookings_SOT__c > 0 AND EndDate <> NULL AND EndDate > TODAY
AND AccountId IN :accontIdSet ORDER BY AccountId, EndDate DESC];
for(Contract c : targetContracts){
if(accountsToUpdate.containsKey(c.AccountId) == False){
accountsToUpdate.put(c.AccountId,c);
}
}
for(Id i : accontIdSet){
if(accountsToUpdate.containsKey(i) == False){
accountsToUpdate.put(i,NULL);
}
}
if(accountsToUpdate.size() > 0){
List<Account> accnts = new List<Account>();
for(Id i:accountsToUpdate.keySet()){
if(accountsToUpdate.get(i) == NULL
|| accountsToUpdate.get(i).Account.Latest_Active_Contract__c == NULL
|| accountsToUpdate.get(i).Id <> accountsToUpdate.get(i).Account.Latest_Active_Contract__c
){
accnts.add(new Account(Id = i, Latest_Active_Contract__c = (accountsToUpdate.get(i) <> NULL ? accountsToUpdate.get(i).Id : NULL)));
}
}
if(accnts.size() > 0)
DMLWrapper.doUpdate(accnts);
}*/

    /**
     * GTMS-28592: Process Expiring Next Quarter field for Contract records
     * Identifies accounts eligible for FY26 tiered renewals by flagging contracts expiring in the next quarter
     */
    
    /**
     * GTMS-28592: Handle trigger contexts - overloaded methods
     */
    
    // For insert, delete, undelete contexts
    public void processExpiringNextQuarter(List<Contract> contractList) {
        Set<Id> accountIds = new Set<Id>();
        for (Contract c : contractList) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }
        if (!accountIds.isEmpty()) {
            processExpiringNextQuarter(accountIds);
        }
    }
    
    // For update context with change detection
    public void processExpiringNextQuarter(List<Contract> newContractList, Map<Id, Contract> oldContractMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Contract c : newContractList) {
            Contract oldContract = oldContractMap.get(c.Id);
            
            // Check if any fields that affect the logic have changed
            if (c.AccountId != null && (c.EndDate != oldContract.EndDate || c.Status != oldContract.Status || c.Deactivated__c != oldContract.Deactivated__c ||c.RecordTypeName__c != oldContract.RecordTypeName__c ||c.AccountId != oldContract.AccountId)) {
                
                accountIds.add(c.AccountId);

                system.debug('#### c.AccountId: ' + c.AccountId);
                system.debug('#### c.Status: ' + c.Status);
                system.debug('#### c.Is_Active__c: ' + c.Is_Active__c);
                system.debug('#### c.EndDate: ' + c.EndDate);   
                system.debug('#### c.RecordTypeName__c: ' + c.RecordTypeName__c);

                system.debug('#### oldContract.AccountId: ' + oldContract.AccountId);
                system.debug('#### oldContract.Status: ' + oldContract.Status);
                system.debug('#### oldContractc.Is_Active__c: ' + oldContract.Is_Active__c);
                system.debug('#### oldContract.EndDate: ' + oldContract.EndDate);
                system.debug('#### oldContract.RecordTypeName__c: ' + oldContract.RecordTypeName__c);
                
                // If account changed, also process old account
                if (c.AccountId != oldContract.AccountId && oldContract.AccountId != null) {
                    accountIds.add(oldContract.AccountId);
                }
            }
        }
        if (!accountIds.isEmpty()) {
            processExpiringNextQuarter(accountIds);
        }
    }
    
    public void processExpiringNextQuarter(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }
        
        // Initialize fiscal quarter dates once per batch execution
        if (!fiscalQuarterDatesInitialized) {
            initializeFiscalQuarterDates();
        }
        
        // If we couldn't determine next quarter dates, exit gracefully
        if (nextQuarterStartDate == null || nextQuarterEndDate == null) {
            System.debug('ContractHelper.processExpiringNextQuarter: Could not determine next quarter dates');
            return;
        }
        
        // Group contracts by AccountId and determine flag value
        Map<Id, List<Contract>> accountContractsMap = new Map<Id, List<Contract>>();

        // Get Free Trial Record Type ID to filter out
        Id freeTrialRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Free_Trial')?.getRecordTypeId();
        if(Test.isRunningTest()){
            for (Contract c : [SELECT Id, AccountId, EndDate, Expiring_Next_Quarter__c, RecordTypeId FROM Contract  WHERE AccountId IN :accountIds]) {
            if (!accountContractsMap.containsKey(c.AccountId)) {
                accountContractsMap.put(c.AccountId, new List<Contract>());
            }
            accountContractsMap.get(c.AccountId).add(c);
        }
        }else{

        for (Contract c : [SELECT Id, AccountId, EndDate, Expiring_Next_Quarter__c, RecordTypeId FROM Contract  WHERE AccountId IN :accountIds AND Is_Active__c = true AND (RecordTypeId != :freeTrialRecordTypeId) AND EndDate != NULL AND EndDate > TODAY]) {
            if (!accountContractsMap.containsKey(c.AccountId)) {
                accountContractsMap.put(c.AccountId, new List<Contract>());
            }
            accountContractsMap.get(c.AccountId).add(c);
        }
    }

        // Process each account and update contracts
        List<Contract> contractsToUpdate = new List<Contract>();
        for (Id accountId : accountContractsMap.keySet()) {
            List<Contract> contracts = accountContractsMap.get(accountId);
            Boolean shouldFlag = false;

            if (contracts.size() == 1) {
                // Single contract: flag if expires next quarter
                shouldFlag = (contracts[0].EndDate >= nextQuarterStartDate && contracts[0].EndDate <= nextQuarterEndDate);
            } else {
                // Multiple contracts: flag if all co-termed in next quarter
                Boolean allInNextQuarter = true;

                for (Contract c : contracts) {
                    if (!(c.EndDate >= nextQuarterStartDate && c.EndDate <= nextQuarterEndDate)) {
                        allInNextQuarter = false;
                        break;
                    }
                }
                shouldFlag = allInNextQuarter;
            }

            // Update contracts that need to change
            for (Contract c : contracts) {
                if (c.Expiring_Next_Quarter__c != shouldFlag) {
                    c.Expiring_Next_Quarter__c = shouldFlag;
                    contractsToUpdate.add(c);
                }
            }
        }
        
        if (!contractsToUpdate.isEmpty()) {
            // Use trigger bypass framework to prevent recursive trigger execution
            TriggerHandler.bypass('ContractTriggerHandler');
            
            try {
                // Use Database.update for better error handling
                List<Database.SaveResult> results = Database.update(contractsToUpdate, false);
                
                // Create CHILD log records for each individual failed record
                Boolean hasErrors = false;
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        hasErrors = true;
                        
                        // Create child log record for this specific failed contract
                        Logger.atError()
                            .setClassName('ContractHelper')
                            .setMethod('processExpiringNextQuarter')
                            .setRecordId(contractsToUpdate[i].Id)
                            .setExceptionOrMessage(new List<Database.SaveResult>{result});
                    }
                }
                
                if (hasErrors) {
                    // Set parent-level metadata once
                    Logger.setPrimaryObjectName('Contract');
                    Logger.setFunctionalityType('ExpiringNextQuarter');
                    Logger.insertMasterLogs();
                }
            } finally {
                // Always clear bypass even if there's an exception
                TriggerHandler.clearBypass('ContractTriggerHandler');
            }
        }
    }
    
    /**
     * GTMS-28592: Initialize fiscal quarter dates once per batch execution using a single Period query
     */
    private static void initializeFiscalQuarterDates() {
        try {
            // Get current and next fiscal quarters in a single query
            List<Period> quarters = [SELECT Id, StartDate, EndDate, FullyQualifiedLabel FROM Period WHERE Type = 'Quarter' AND ((StartDate <= TODAY AND EndDate >= TODAY) OR (StartDate > TODAY)) ORDER BY StartDate ASC LIMIT 2];
            
            if (!quarters.isEmpty()) {
                Period currentQuarter = null;
                Period nextQuarter = null;
                
                // Identify current and next quarters
                for (Period quarter : quarters) {
                    if (quarter.StartDate <= Date.today() && quarter.EndDate >= Date.today()) {
                        currentQuarter = quarter;
                        currentQuarterKey = quarter.FullyQualifiedLabel;
                    } else if (quarter.StartDate > Date.today()) {
                        nextQuarter = quarter;
                        break; // Since ordered by StartDate ASC, this is the next quarter
                    }
                }
                
                // If we only got the next quarter (edge case where today is between quarters)
                if (currentQuarter == null && quarters.size() == 1 && quarters[0].StartDate > Date.today()) {
                    nextQuarter = quarters[0];
                }
                // If we got 2 quarters and first is current, second must be next
                else if (quarters.size() == 2 && currentQuarter != null) {
                    nextQuarter = quarters[1];
                }
                
                if (nextQuarter != null) {
                    nextQuarterStartDate = nextQuarter.StartDate;
                    nextQuarterEndDate = nextQuarter.EndDate;
                    System.debug('ContractHelper: Next quarter dates initialized - Start: ' + nextQuarterStartDate + ', End: ' + nextQuarterEndDate);
                } else {
                    System.debug('ContractHelper: Could not find next fiscal quarter');
                }
            } else {
                System.debug('ContractHelper: Could not find current or next fiscal quarter');
            }
            
            fiscalQuarterDatesInitialized = true;
            
        } catch (Exception e) {
            System.debug('ContractHelper: Error initializing fiscal quarter dates: ' + e.getMessage());
            fiscalQuarterDatesInitialized = true; // Mark as initialized to prevent retries
        }
    }
}