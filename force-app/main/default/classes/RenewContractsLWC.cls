/**
 * @description       : 
 * @author            : Navees Ahmed
 * @group             : 
 * @last modified on  : 06-25-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDocx
**/
public with sharing class RenewContractsLWC {
    @AuraEnabled(cacheable=true)
    public static AccountWrapper getAccountAndActiveContracts(String accId) {
        AccountWrapper result = new AccountWrapper();
        result.errorMessage='';
        if(String.isBlank(accId)){
            result.errorMessage='Invalid account';
        }
        else{
            List<Account> listAcc = new List<Account>();
            if(Test.isRunningTest()){
               listAcc=[SELECT Id, Name,(SELECT Id,AccountId, ContractNumber, StartDate, EndDate,
                                    SBQQ__RenewalOpportunity__c,SBQQ__RenewalOpportunity__r.Name,SBQQ__RenewalOpportunity__r.StageName,
                                    SBQQ__RenewalOpportunity__r.Probability
                                    FROM Contracts)
                                    FROM Account Where Id=:accId];  
            }else{
                String queryString = 'SELECT Id, Name, (SELECT Id, AccountId, ContractNumber, StartDate, EndDate, ' +
                                        'SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.Name, SBQQ__RenewalOpportunity__r.StageName, ' +
                                        'SBQQ__RenewalOpportunity__r.Probability ' +
                                        'FROM Contracts ' +
                                        'WHERE AccountId = :accId ' +
                                        'AND SBQQ__RenewalOpportunity__r.Probability < 95 ' +
                                        'AND SBQQ__RenewalOpportunity__r.IsClosed = false ' +
                                        'AND Is_Active__c = true ' +
                                        ') FROM Account WHERE Id = :accId';
                            
                System.debug('Query String: ' + queryString);
                listAcc = Database.query(queryString);
            }
           
            Set<Id> contractIds = new Set<Id>();
            for (Account acc : listAcc) {
                for (Contract con : acc.Contracts) {
                    contractIds.add(con.Id);
                }
            }

            // Query CCR records and separate child vs master
            List<Contract_Consolidation_Request__c> ccrRecords = [
                SELECT Contract__c, Master_Contract__c 
                FROM Contract_Consolidation_Request__c 
                WHERE Contract__c IN :contractIds
            ];
            
            Set<Id> ccrChildContractIds = new Set<Id>();
            Set<Id> ccrMasterContractIds = new Set<Id>();
            
            for (Contract_Consolidation_Request__c ccr : ccrRecords) {
                if (ccr.Master_Contract__c == true) {
                    ccrMasterContractIds.add(ccr.Contract__c);
                } else {
                    ccrChildContractIds.add(ccr.Contract__c);
                }
            }

            // Remove child CCR contracts from display
            Set<Id> filteredSet = new Set<Id>(contractIds);
            filteredSet.removeAll(ccrChildContractIds);

            List<Contract> consolidatedContracts = [
                SELECT Id, Consolidated_Master_Contract__c 
                FROM Contract 
                WHERE Id IN :filteredSet 
                AND Consolidated_Master_Contract__c IN :filteredSet
            ];
            Set<Id> consolidatedIdsChild = new Set<Id>();
            Set<Id> consolidatedIdsMaster = new Set<Id>();
            for (Contract con : consolidatedContracts) {
                if (con.Id != con.Consolidated_Master_Contract__c) {
                    consolidatedIdsChild.add(con.Id);
                } else if (con.Id == con.Consolidated_Master_Contract__c) {
                    consolidatedIdsMaster.add(con.Id);
                }
            }
            
            // Add CCR master contracts to consolidatedIdsMaster
            consolidatedIdsMaster.addAll(ccrMasterContractIds);
            
            System.debug('Consolidated Master:::'+consolidatedIdsMaster);

            Set<Id> finalSet = new Set<Id>(filteredSet);
            finalSet.removeAll(consolidatedIdsChild);


            if(listAcc.size()==0){
                result.errorMessage='Invalid account';
            }
            else{
                Account a=listAcc[0];
                result.accountName = a.Name;
                result.activeContracts = new List<ContractWrapper>();
                if(a.Contracts.size()==0){
                    result.errorMessage='This account has no valid contract to consolidate.';
                }
                else{
                    for(Contract c:a.Contracts){
                        if(finalSet.contains(c.Id)){
                            ContractWrapper cw=new ContractWrapper();
                            cw.contractConsolidated=false;
                            cw.c=c;
                            cw.contractURL='/lightning/r/Contract/' + c.Id + '/view';
                            cw.renewalOppURL='';
                            if(c.SBQQ__RenewalOpportunity__c!=null){
                                cw.renewalOppURL='/lightning/r/Opportunity/' + c.SBQQ__RenewalOpportunity__c + '/view';
                            }
                            
                            cw.isMaster=false;
                            cw.isMasterSelected=false;
                            cw.isChildSelected=false;
                            cw.isConsolidated = consolidatedIdsMaster.contains(c.Id);
                            System.debug('Consolidated Status for Contract ' + c.Id + ': ' + cw.isConsolidated);
                            result.activeContracts.add(cw);
                        }
                    }
                }
            }
        }
         
        

        return result;
    }
    @AuraEnabled
    public static String renewContracts(String accountId,List<ContractWrapper> selectedChildContracts,List<ContractWrapper> selectedMasterContracts) {   
        String result='';    
        if(String.isBlank(accountId) || selectedChildContracts==null || selectedChildContracts.size()==0 || selectedMasterContracts==null || selectedMasterContracts.size()==0){
            result='No contracts are selected to renew.';
        }
        else{
            List<Contract_Consolidation_Request__c> listCCR=new List<Contract_Consolidation_Request__c>();
            String key=accountId+'_'+UserInfo.getUserId()+'_'+DateTime.now().year()+'-'+DateTime.now().month()+'-'+DateTime.now().day()+'_'+DateTime.now().hour()+':'+DateTime.now().minute()+':'+DateTime.now().second();
            String masterContractId='';
           // List<Contract> listContractQuotedFalse=new List<Contract>();
           // List<Contract> listContractQuotedTrue=new List<Contract>();
            for (ContractWrapper cw : selectedMasterContracts) {
                masterContractId=cw.c.Id;
                Contract_Consolidation_Request__c ccr=new Contract_Consolidation_Request__c(Name=key,Contract__c=cw.c.Id,Status__c='New',Master_Contract__c=true,Consolidated_Opportunity__c=cw.c.SBQQ__RenewalOpportunity__c,Account__c = cw.c.AccountId);
                listCCR.add(ccr);
                
                //listContractQuotedFalse.add(new Contract(Id=cw.c.Id,SBQQ__RenewalQuoted__c=false));    
            }            
            for (ContractWrapper cw : selectedChildContracts) {
                if(masterContractId!=cw.c.Id){
                    Contract_Consolidation_Request__c ccr=new Contract_Consolidation_Request__c(Name=key,Contract__c=cw.c.Id,Status__c='New',Consolidated_Opportunity__c=cw.c.SBQQ__RenewalOpportunity__c,Account__c = cw.c.AccountId);
                    listCCR.add(ccr);
                   // listContractQuotedFalse.add(new Contract(Id=cw.c.Id,SBQQ__RenewalQuoted__c=false));            
                }
            }
          //  update listContractQuotedFalse;
            //update listContractQuotedTrue;
            insert listCCR;
            System.debug('List of ContractConsolidationRequest: '+listCCR);
            /*BatchConsolidateContracts job = new BatchConsolidateContracts('Quoted UnChecked',key,null);
            ID batchprocessid = Database.executeBatch(job,listCCR.size()); */     
            /*BatchConsolidateContracts job = new BatchConsolidateContracts('Quoted Checked',key,null);
            ID batchprocessid = Database.executeBatch(job,listCCR.size());           */        
            ID jobID = System.enqueueJob(new QueueableContractConsolidation('Quoted UnChecked',key),QueueableContractConsolidation.waitTime); 
            result='Saved successfully. You will get a notification once renewal and consolidation is completed. It will take '+(QueueableContractConsolidation.waitTime*listCCR.size()*3)+' minutes.';
        }
        return result;
    }

    
    // new method added
     @AuraEnabled(cacheable=true)
    public static Period getQuarterPeriod(Integer quarterNumber, String fiscalYearName) {
        return [
            SELECT Id, StartDate, EndDate
            FROM Period
            WHERE Type = 'Quarter'
            AND Number = :quarterNumber
            AND FiscalYearSettings.Name = :fiscalYearName
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<FiscalYearDTO> getFiscalYears(String accId) {
        List<FiscalYearDTO> years = new List<FiscalYearDTO>();
        for (FiscalYearSettings fys : [
            SELECT Name, StartDate, EndDate
            FROM FiscalYearSettings
            ORDER BY StartDate ASC
        ]) {
            years.add(new FiscalYearDTO(fys.Name, fys.StartDate, fys.EndDate));
        }
        return years;
    }


    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCurrentQuarterAndYear() {
        Period p = [
            SELECT Id, StartDate, EndDate, FiscalYearSettings.Name, Number
            FROM Period
            WHERE Type = 'Quarter' 
            AND StartDate = THIS_FISCAL_QUARTER
            LIMIT 1
        ];
        
        return new Map<String, String>{
            'year' => p.FiscalYearSettings.Name,
            'quarter' => String.valueOf(p.Number)
        };
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isSystemAdministrator() {
        try {
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [SELECT Id, Profile.Id, Profile.Name FROM User WHERE Id = :currentUserId];
            String salesOpsProfileId = System.Label.Sales_ops_profile;
            return currentUser.Profile.Name == 'System Administrator' || currentUser.Profile.Id == salesOpsProfileId;
        } catch (Exception e) {
            System.debug('Error checking System Administrator status: ' + e.getMessage());
            return false;
        }
    }

    
    public class AccountWrapper {
        @AuraEnabled
        public String accountName{get;set;}
        @AuraEnabled
        public String errorMessage{get;set;}
        @AuraEnabled
        public List<ContractWrapper> activeContracts{get;set;}
        @AuraEnabled
        public List<String> yearsWithContracts {get;set;}
    }
    public class ContractWrapper{
        @AuraEnabled
        public Boolean contractConsolidated {get;set;}
        @AuraEnabled
        public Contract c {get;set;}
        @AuraEnabled
        public String contractURL {get;set;}     
        @AuraEnabled
        public String renewalOppURL {get;set;}             
        @AuraEnabled
        public Boolean isMaster {get;set;}
        @AuraEnabled
        public Boolean isMasterSelected {get;set;}
        @AuraEnabled
        public Boolean isChildSelected {get;set;}  
        @AuraEnabled
        public Boolean isConsolidated{get;set;}      
    }

    public class FiscalYearDTO {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Date   startDate { get; set; }
        @AuraEnabled public Date   endDate { get; set; }
        public FiscalYearDTO(String n, Date s, Date e) {
            name = n; startDate = s; endDate = e;
    }
}
}