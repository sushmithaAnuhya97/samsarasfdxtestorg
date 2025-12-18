/**
* Created By : Satya Dodda
* @Date Mar 24, 2022
* Test Class: SyncSubsToRenewalOppTest 
* @description : This class will be responsible for handling Async Actions on Contract
* 
*
**/

public without sharing class UpdateContractServiceAsync extends BaseAsyncHandler {
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    static Decimal RETRY_THRESHOLD = 3;
    public override String getRequestType(){
        return 'Update Contract Service Async';
    } 
    
    List<Id> recordsIds = new List<Id>();
    
    public override void execute(Async_Request__c ar)
    {
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);
        try{
            switch on opt.Operation {
                when 'uncheckContract' {
                    uncheckContract();
                }
                when 'checkContract' {
                    checkContract(ar);
                }
            }
        }catch(Exception ex){
            thisLogger.logError('Error in UpdateContractServiceAsync during '+ opt.Operation +'Operation::', new SamsaraLoggerObjectMVP(ex,recordsIds));
            throw ex;
        }finally{
            thisLogger.dispatch();
        }
        
    }
    public void checkContract(Async_Request__c ar) {
        List<sObject> records = new List<sObject>();
        List<Contract> lstContracts = [SELECT Id, SBQQ__RenewalQuoted__c from Contract where Id in:recordsIds FOR UPDATE ];
        for (Contract rec : lstContracts) {
            rec.SBQQ__RenewalQuoted__c = true;
            records.add(rec);
        }
        if(!records.isEmpty()){
            Savepoint sp = Database.setSavepoint();
            try {
                Database.update(records, true);
            }
            catch(Exception ex){
                system.debug('ex.Message checkContract=====> ' + ex.getMessage());
            }
            
        }
        
    }
    public void uncheckContract() {
        List<sObject> records = new List<sObject>();
        for(Id record : recordsIds){
            records.add(new Contract(Id = record, SBQQ__RenewalQuoted__c = false));
        }
        if(!records.isEmpty()){
            Database.update(records);
        }
        insert new UpdateContractServiceAsync().prepareAsyncRequests(
            JSON.serialize(new UpdateContractServiceAsync.Options('checkContract')), 
            new Set<Id>(recordsIds));    }
    
    public class Options {
        public String Operation {get; set;}
        
        public Options(String operation){
            this.Operation = operation;
        }
    }
}