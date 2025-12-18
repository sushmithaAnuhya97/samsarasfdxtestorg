public without sharing class ContractUpdateServiceAsync extends BaseAsyncHandler{
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger();

    @TestVisible private Boolean shouldPublishDML = true;
    
    public override String getRequestType(){
        return 'Contract Update Async Job';
    }

    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Contract.SObjectType
    };
            
    UnitOfWork uow = new UnitOfWork(MY_SOBJECTS);
    
    @TestVisible List<Id> recordsIds = new List<Id>();
    @TestVisible List<Opportunity> queriedOpportunityList;
    
    public override void execute(Async_Request__c ar)
    {
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);

        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);

        try{
            switch on opt.Operation {
                when 'Update Dates' {
                    updateContractDates();
                }
            }

            if (shouldPublishDML) DMLWrapper.publishDML();
        }catch(Exception ex){
            System.debug('Exception: '+ex.getMessage()+' / '+ex.getStackTraceString());
            thisLogger.logError(
                'Error in ContractUpdateServiceAsync during '+ opt.Operation +'Operation::',
                new SamsaraLoggerObjectMVP(
                    ex,
                    recordsIds
                )
            );
            throw ex;
        }finally{
            thisLogger.dispatch();
        }
    }
    
    private void updateContractDates(){
        if (!recordsIds.isEmpty()){
            fetchContractData();

            List<Contract> toUpdateList = new List<Contract>();
            for (Opportunity opp : queriedOpportunityList){
                // Amended Contract should be updated to run the triggers and update it's subscriptions
                if (opp.SBQQ__AmendedContract__c != null){
                    toUpdateList.add(new Contract(Id = opp.SBQQ__AmendedContract__c));

                }else if (!opp.SBQQ__Contracts__r.isEmpty()){
                    for (Contract ctt : opp.SBQQ__Contracts__r){
                        if (ctt.StartDate != opp.License_Start_Date__c
                        ||  ctt.EndDate   != opp.License_End_Date__c){
    
                            ctt.StartDate = opp.License_Start_Date__c;
                            ctt.EndDate   = opp.License_End_Date__c;
                            toUpdateList.add(ctt);
                        }
                    }
                }
            }

            if (!toUpdateList.isEmpty()) DMLWrapper.doUpdate(toUpdateList);
        }
    }

    @TestVisible
    private void fetchContractData(){
        if (queriedOpportunityList == null || queriedOpportunityList.isEmpty()){
            queriedOpportunityList = [
                SELECT License_Start_Date__c, License_End_Date__c, SBQQ__AmendedContract__c,
                       (SELECT Id, StartDate, EndDate FROM SBQQ__Contracts__r)
                  FROM Opportunity
                 WHERE Id IN :recordsIds
            ];
        }
    }

    public class Options {
        public String Operation {get; set;}
        
        public Options(String operation){
            this.Operation = operation;
        }
    }
}