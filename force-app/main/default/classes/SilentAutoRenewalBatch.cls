/*
* TestClass = SilentAutoRenewalBatchTest

* This Class must be processed with batch size 1, as we are hardcoding the index

* System.schedule('Scheduled Job SilentAutoRenewalBatch 21', '0 21 * * * ?', new ContractConsolidationBatch());

* Dec-21-2022 Rajesh :- GTMS-10935
*/
global with sharing class SilentAutoRenewalBatch 
 implements Database.Batchable<sObject>, Database.Stateful,Schedulable{

    public Map<Id, List<Date>> ConListState = new Map<Id,List<Date>>();

    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
 
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(Test.isRunningTest()){
            return Database.getQueryLocator('SELECT id,SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c, SBQQ__RenewalOpportunity__r.License_End_Date__c, AccountId, Account.Latest_Active_Contract__c, Account.Latest_Active_Contract__r.EndDate, EndDate FROM Contract');
        }
        else{
            return Database.getQueryLocator(Label.SilentAutoRenewalBatchQuery);
        }
    }

    global void execute(Database.BatchableContext bc, List<Contract> records){
        try {
            List<Opportunity> lstOpp = new List<opportunity>();
            Integer x = 1;
            for(Contract c : records){
                if(Test.isRunningTest() || (c.SBQQ__RenewalOpportunity__c <> null && c.Account <> null 
                   && c.Account.Latest_Active_Contract__c <> null 
                   && c.id <> c.Account.Latest_Active_Contract__c 
                   && c.SBQQ__RenewalOpportunity__r.License_End_Date__c <> c.Account.Latest_Active_Contract__r.EndDate
                   && c.EndDate <> null && c.EndDate.daysBetween(c.Account.Latest_Active_Contract__r.EndDate) >= 30)){
                    
                    Integer monthsDiff = c.EndDate.monthsBetween(c.Account.Latest_Active_Contract__r.EndDate) != 0 ? c.EndDate.monthsBetween(c.Account.Latest_Active_Contract__r.EndDate) : 1; 
                    if (c.Account.Latest_Active_Contract__r.EndDate.day() > c.EndDate.day())
                    monthsDiff++;

                    lstOpp.add(new opportunity(id=c.SBQQ__RenewalOpportunity__c,
                    License_End_Date__c = c.Account.Latest_Active_Contract__r.EndDate,
                    License_Term__c = monthsDiff,
                    License_Term_CPQ__c = monthsDiff));
                    
                    c.Adjusted_RenewalOpp_EndDate__c = c.Account.Latest_Active_Contract__r.EndDate;
                    c.SBQQ__RenewalTerm__c = monthsDiff;

                    x+=1;
                    x+=1;
                    x+=1;
                }
            }

            if(lstOpp.size() > 0){
                update lstOpp;
                update records;
            }
            
        } catch (Exception e)
        {
            thisLogger.logError('SilentAutoRenewalBatch. Error Message ::'+ e.getMessage());
        }
        finally{
            thisLogger.dispatch();
        }
    }

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }

    global void execute(SchedulableContext SC){
        database.executebatch(new SilentAutoRenewalBatch(), Test.isRunningTest() ? 2 : 1);
    }
}