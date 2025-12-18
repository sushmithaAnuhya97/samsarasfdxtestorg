public class ContractAutoRenewalAutomation implements Database.Batchable<sObject>{
    private final String query;
    private final Boolean chainFlag;

    public ContractAutoRenewalAutomation(String query, Boolean chainFlag) {
        this.query = query;
        this.chainFlag = chainFlag;
    }
    
   public Database.QueryLocator start(Database.BatchableContext bc){
      Date cutoffDate = Date.Today().addDays(180);
      String query = query +' <=: cutoffDate' ;
      return Database.getQueryLocator(query);
   }

   public void execute(Database.BatchableContext bc, List<Contract> scope){
       List<Contract> updatedContracts = new List<Contract>();
       for(Contract contract : scope){
           if(contract.Auto_Renewal__c == false){
               if(contract.SBQQ__Opportunity__r.Configuration_Segment__c == 'Express' && contract.Account.Auto_renewal_Opt_Out__c == false && contract.Account.Quarantine_Enabled__c == false){
                   contract.Auto_Renewal__c = true;
                   updatedContracts.add(contract);
               }
               else if(contract.SBQQ__Opportunity__r.Configuration_Segment__c == 'Non Express' && 
                       (contract.Account.Approved_Payment_Type__c == 'Monthly' || contract.Account.Approved_Payment_Type__c == 'Annual') &&
                      (contract.Account.Account_Lifetime_ACV__c < 30000)){
                   contract.Auto_Renewal__c = true;
                   updatedContracts.add(contract);
               }
           }
       }
       update updatedContracts;
    }

   public void finish(Database.BatchableContext bc){
       if(chainFlag){
 			System.debug('CPU time before the job for the class <AutoRenewalOpportunityAutomation> is scheduled: ' +  Limits.getCpuTime());
        	//String query = 'SELECT EndDate, ContractNumber, (SELECT ID, Finance_Notes__c, PO_Number__c FROM SBQQ__RenewalOpportunities__r WHERE Probability < 99 AND SBQQ__Renewal__c = TRUE) FROM Contract WHERE EndDate <= NEXT_N_DAYS:7 AND EndDate >= TODAY AND Auto_Renewal__c = TRUE';                    
        	Database.executeBatch(new AutoRenewalOpportunityAutomation(System.Label.Auto_Renewal_Opportunity_Automation, true), 5);
        	System.debug('CPU time after the job for the class <AutoRenewalOpportunityAutomation> is completed: ' +  Limits.getCpuTime());
      } 
   }
}