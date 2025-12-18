/*
* TestClass = ContractConsolidationBatchTest

* This Class must be processed with batch size 1, as we are hardcoding the index

* System.schedule('Scheduled Job ContractConsolidationBatch 21', '0 21 * * * ?', new ContractConsolidationBatch());

* Dec-21-2022 Rajesh :- GTMS-10332
*/
global class ContractConsolidationBatch 
implements Database.Batchable<sObject>, Database.Stateful,Schedulable {

    public Map<Id, List<Date>> ConListState = new Map<Id,List<Date>>();

    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
 
  global Database.QueryLocator start(Database.BatchableContext bc) {
        if(Test.isRunningTest()){
            return Database.getQueryLocator('SELECT Id,AccountId, EndDate, SBQQ__RenewalOpportunity__r.LastModifiedDate FROM Contract');
        }
        else{
            return Database.getQueryLocator(Label.ContractConsolidationBatchQuery);
        }
    }

    global void execute(Database.BatchableContext bc, List<Contract> records){
        try {
            if(ConListState.containsKey(records[0].AccountId) == false || (ConListState.containsKey(records[0].AccountId) && ConListState.get(records[0].AccountId).contains(records[0].EndDate) == false)){
                List<Contract> contractswithSameEndDate;
                if(Test.isRunningTest()){
                    contractswithSameEndDate = [SELECT ID, SBQQ__RenewalOpportunity__c,Contract_Renewable_ACV_USD__c FROM Contract];
                }
                else{
                    contractswithSameEndDate = [SELECT ID, SBQQ__RenewalOpportunity__c,Contract_Renewable_ACV_USD__c FROM Contract 
                                                            WHERE AccountId =: records[0].AccountId AND EndDate =: records[0].EndDate
                                                            AND (SBQQ__RenewalOpportunity__c = NULL OR SBQQ__RenewalOpportunity__r.Probability <= 10)
                                                            AND EndDate >= TODAY AND EndDate <= NEXT_N_DAYS:110 AND Is_Active__c = TRUE
                                                            ORDER BY Contract_Renewal_ACV__c DESC];
                }
                
                if(contractswithSameEndDate.size() > 1){
                    System.debug('contractswithSameEndDateSize='+ contractswithSameEndDate.size());
                    Map<Id,Opportunity> oppsToClose = new Map<Id,Opportunity>();
                    List<Contract> mapContracts = new List<Contract>();
                    Id masterContract,masterRenOpp;
    
                    for(Contract c : contractswithSameEndDate){
                        if(masterContract == null){
                        masterContract = c.Id;masterRenOpp=c.SBQQ__RenewalOpportunity__c;
                        }
    
                        if(c.SBQQ__RenewalOpportunity__c <> NULL){
                            oppsToClose.put(c.SBQQ__RenewalOpportunity__c,new Opportunity(Id=c.SBQQ__RenewalOpportunity__c, StageName ='Closed Lost', 
                                    Closed_Lost_Reason__c='Closed to create a consolidated Renewal Opportunity',
                                    Closed_Lost_Renewal_Reason__c='Renewal admin issue',
                                    Closed_Lost_Renewal_Sub_reason__c='Consolidated renewal',Consolidated_Renewal_Opportunity_Id__c=masterRenOpp));
                        }
                        
                        Contract con = new contract(Id=c.Id, SBQQ__RenewalOpportunity__c=null);
                        //if(c.Id <> masterContract)
                        con.Consolidated_Master_Contract__c = masterContract;
                        mapContracts.add(con);
                    }
    
                    update oppsToClose.values();
                    update mapContracts;
    
                    System.debug('lstOppsSzie=' + oppsToClose.size());
                    System.debug('mapContractsSize=' + mapContracts.size());
    
                    CreateRenewalContext context = new CreateRenewalContext();
                    context.masterContractId = masterContract; 
                    context.renewedContracts = [SELECT Id FROM Contract WHERE Id IN : mapContracts]; 
                    context.returnOnlyQuoteId = true; 
                    String jsonContext = JSON.serialize(context);
                    
                    // renew the two contracts
                    ContractRenewer renewer = new ContractRenewer();
                    QuoteModel[] quotes = renewer.load(null, jsonContext);
    
                    System.debug('quotes=' + quotes);
                    
                     // Query master contract to get renewal opportunity that is not closed
                    Contract masterContractRecord = [SELECT Id, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.IsClosed 
                                                   FROM Contract 
                                                   WHERE Id = :masterContract 
                                                   AND SBQQ__RenewalOpportunity__c != NULL
                                                   AND SBQQ__RenewalOpportunity__r.IsClosed = false
                                                   LIMIT 1];
                    
                    if(masterContractRecord != null) {
                        // Calculate sum of ContractRenewableACV from all contracts in contractswithSameEndDate
                        Decimal totalContractRenewableACV = 0;
                        for(Contract c : contractswithSameEndDate) {
                            if(c.Contract_Renewable_ACV_USD__c != null) {
                                totalContractRenewableACV += c.Contract_Renewable_ACV_USD__c;
                                System.debug('ContractRenewableACV-->'+c.Contract_Renewable_ACV_USD__c);
                            }
                        }
						System.debug('totalContractRenewableACV-->'+totalContractRenewableACV);
                        
                        if(totalContractRenewableACV > 0) {
                           
                            
                            
                            try {
                                Opportunity oppToUpdate = new Opportunity(
                                    Id = masterContractRecord.SBQQ__RenewalOpportunity__c,
                                    Available_TO_Renew__c = totalContractRenewableACV
                                );
                                update oppToUpdate;
                            
                            } catch (Exception ex) {
                                Logger.atError().setClassName('ContractConsolidationBatch').setRecordId(masterContractRecord.SBQQ__RenewalOpportunity__c).setExceptionOrMessage(ex);
                                Logger.setFunctionalityType('Contract Consolidation');
                                Logger.setRecordId(masterContractRecord.SBQQ__RenewalOpportunity__c);
                                Logger.insertMasterLogs();
                            } finally {
                                
                            }
                        }
                    }
    
                    if(ConListState.containsKey(records[0].AccountId)){
                        ConListState.get(records[0].AccountId).add(records[0].EndDate);
                    }
                    else {
                        ConListState.put(records[0].AccountId,new List<Date>{records[0].EndDate});
                    }
                }
            }
            
        } catch (Exception e)
        {
            thisLogger.logError('ContractConsolidationBatch. Error Message ::'+ e.getMessage());
        }
        finally{
            thisLogger.dispatch();
        }
    }

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }

    global void execute(SchedulableContext SC) {
        database.executebatch(new ContractConsolidationBatch(), Test.isRunningTest() ? 2 : 1);
     }
}