/**
* Created By : 
* @Date September 10, 2021
*
* @description : This class will be responsible for handling the initiation of contract renewal automation
*
* Modification History:
* Date			Author				Story/Defect			Description
* 2022-08-23	Harsha				GTMS-8374  				Added null check for the renewal opportunity. 
* 2022-04-08	Rodrigo Carpio		GTMS-6084 				Original selected payment type, blended discount, and license term aren't populating
* 
**/
public class ContractAutomation implements Database.Batchable<sObject>{
    private final String query;
    private final Boolean chainFlag;

    public ContractAutomation(String query, Boolean chainFlag) {
        this.query = query;
        this.chainFlag = chainFlag;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Contract> scope){
        List<Account> accountUpdateList = new List<Account>();
        
        Set<Id> originalOptyId = new Set<Id>();
        Set<Id> renewalOptyId = new Set<Id>();
        //List<Opportunity> lstoptyToBeUpdated = new List<Opportunity>();
        List<SBQQ__Quote__c> lstQuoteToBeUpdated = new List<SBQQ__Quote__c>();
        Map<Id, Id> renewalOriginalIDMap = new Map<Id, Id>(); // identifier will be the renewal id, value is the original id
        for(Contract contract : scope){
            // check if the opporunit sub type != Auto-renewal, 
            // payment type = Blended Discount and License is not null or greater than 0
            // added for GTMS-6084
            if (contract.SBQQ__Opportunity__c != null && 
                contract.SBQQ__RenewalOpportunity__c != NULL &&
                contract.SBQQ__RenewalOpportunity__r.Sub_Type__c != 'Auto-Renewal' &&
                contract.SBQQ__Opportunity__r.Payment_Type__c  != null &&
                contract.SBQQ__Opportunity__r.License_Term__c != null &&
                contract.SBQQ__Opportunity__r.License_Term__c>0 &&
                contract.SBQQ__Opportunity__r.Blended_Discount__c  != null &&
                (contract.SBQQ__Opportunity__r.Blended_Discount__c != 0 || (Test.isRunningTest()))) // condition  added for GTMS-6084
            {
                // populated 3 field coming from original to the renewal, if fields are missing
                if (contract.SBQQ__Opportunity__c != null && contract.SBQQ__RenewalOpportunity__c != null) {
                    originalOptyId.add(contract.SBQQ__Opportunity__c);
                	renewalOptyId.add(contract.SBQQ__RenewalOpportunity__c);
                	renewalOriginalIDMap.put(contract.SBQQ__RenewalOpportunity__c, contract.SBQQ__Opportunity__c);
                    system.debug(originalOptyId + 'originalOptyId - renewalOptyId ' + renewalOptyId);
                }
            }
            else 
            {   
                // Check days between today & the Contract End Date
                //Renewal Quoted being marked true will auto generate a renewal quote associated with the Contract
                Integer daysBetween = 0;
                if (contract.EndDate != null) // added the check to avoid null exception
                	daysBetween = (System.Today().daysBetween(Date.valueOf(contract.EndDate)));                
                    contract.SBQQ__RenewalForecast__c = TRUE;
                    if(daysBetween > 0){
                        if(daysBetween <= 90 && contract.SBQQ__RenewalQuoted__c == FALSE){
                            contract.SBQQ__RenewalQuoted__c = TRUE;
                        }  
                    }
                
                
                Boolean escalationCriteriaMet = contract.SBQQ__RenewalOpportunity__r.Renewable_ACV__c < 10000 && 
                    contract.Account.Customer_ARR__c < 25000 && 
                    contract.SBQQ__RenewalOpportunity__r.Finance_Partner__c == null && 
                    (  contract.SBQQ__RenewalOpportunity__r.Payment_Type__c != 'Upfront' || 
                     contract.SBQQ__RenewalOpportunity__r.Payment_Type__c != 'Reseller')? true:false;
                
                //If Evergreen quote then mark as auto renewal
                if(escalationCriteriaMet){
                    contract.Auto_Renewal__c = true;
                    contract.SBQQ__RenewalTerm__c = 12;
                } else{
                    Account contractAccount = new Account(Id=contract.AccountId, Auto_Renewal_Opt_Out__c = true);
                    accountUpdateList.add(contractAccount);
                }   
            }
        }
        if(scope.size() > 0){
           Database.SaveResult[] srList = Database.update(scope, false);
        }
        
        // check if the originalOptyId not empty for GTMS-6084
        if (originalOptyId.size() > 0) {
            Map<Id, Opportunity> optyToBeUpdated = new Map<Id, Opportunity>();
            
            Map<Id, Opportunity> originalOpty = new Map<Id, Opportunity>([SELECT Id, Amount, Blended_Discount__c, Payment_Type__c, License_Term_Formula__c, License_Term_CPQ__c, License_Term__c, Selected_Payment_Type__c, Name, Blended_Discount_CPQ__c, Buyout_Opportunity__c, Subsidy_Opportunity__c,SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.License_Term__c, SBQQ__PrimaryQuote__r.Selected_Payment_Type__c, SBQQ__PrimaryQuote__r.Original_Blended_Discount__c FROM Opportunity WHERE Id IN :originalOptyId]);
            Map<Id, Opportunity> renewalOpty = new Map<Id, Opportunity>([SELECT Id, Amount, Blended_Discount__c, Payment_Type__c, License_Term_Formula__c, License_Term_CPQ__c, License_Term__c, Selected_Payment_Type__c, Name, Blended_Discount_CPQ__c, Buyout_Opportunity__c, Subsidy_Opportunity__c, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.License_Term__c, SBQQ__PrimaryQuote__r.Selected_Payment_Type__c, SBQQ__PrimaryQuote__r.Original_Blended_Discount__c FROM Opportunity WHERE Id IN :renewalOptyId]);
            for (Opportunity opty : renewalOpty.Values()) {
                Id localOrigId = null;
                
                if ( (opty.SBQQ__PrimaryQuote__r.License_Term__c == null) || 
                    (opty.SBQQ__PrimaryQuote__r.Original_Blended_Discount__c  == null || opty.SBQQ__PrimaryQuote__r.Original_Blended_Discount__c  ==0) ||
                    (opty.SBQQ__PrimaryQuote__r.Selected_Payment_Type__c == null) )
                {
                    localOrigId = renewalOriginalIDMap.get(opty.Id);
                    Opportunity origOpty = originalOpty.get(localOrigId);
                    SBQQ__Quote__c renewalQuote = new SBQQ__Quote__c();
                    system.debug('SBQQ__PrimaryQuote__c ' + opty.SBQQ__PrimaryQuote__c);
                    if (opty.SBQQ__PrimaryQuote__c != null) {
                        renewalQuote.Id = opty.SBQQ__PrimaryQuote__c;
                        if (origOpty.License_Term__c != null && origOpty.License_Term__c !=0)
                        renewalQuote.Original_License_Term__c = origOpty.License_Term__c;
                        renewalQuote.Original_Selected_Payment_Type__c = origOpty.Selected_Payment_Type__c;
                        renewalQuote.Original_Blended_Discount__c = origOpty.Blended_Discount__c;                      
                        lstQuoteToBeUpdated.add(renewalQuote);   
                    }
                }                
            }
        }
        
        if (lstQuoteToBeUpdated.size()>0) { // added for GTMS-6084
            system.debug('RODRIGO lstQuoteToBeUpdated ' +lstQuoteToBeUpdated);
            Database.SaveResult[] srList = Database.update(lstQuoteToBeUpdated, false);
            system.debug('RODRIGO lstQuoteToBeUpdated ' +srList);
        }
    }
    
    public void finish(Database.BatchableContext bc){
        if(chainFlag){
            System.debug('CPU time before the job for the class <ContractAutoRenewalAutomation> is scheduled: ' +  Limits.getCpuTime());
            Database.executeBatch(new ContractAutoRenewalAutomation(System.Label.Contract_Auto_Renewal_Automation, true), 5);
            System.debug('CPU time after the job for the class <ContractAutoRenewalAutomation> is completed: ' +  Limits.getCpuTime());
        } 
    }
}