/**
* Created By : Groundswell - Arun Mudaliar
* @Date June 27, 2023
*
* @description : This class will be responsible for handling Async Actions on Contract
*
**/

public with sharing class GS_ContractServiceAsync extends BaseAsyncHandler{
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger(); 
    public override String getRequestType(){
        return 'Contract Service Async Job';
    } 
    
    List<Id> recordsIds = new List<Id>();
    Options opt = new Options();
    
    public override void execute(Async_Request__c ar)
    {
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        opt = (Options) JSON.deserialize(ar.Options__c, Options.class);
        
        // Do something with Contract Records
        
        try{
            thisLogger.logTrace('Entering in GS_ContractServiceAsync');
            switch on opt.Operation {
                when 'FreeTrialDecision' {
                    handleFreeTrialDecision();
                }
            }
        }catch(Exception ex){
            thisLogger.logError(
                    'Error in GS_ContractServiceAsync::',
                    new SamsaraLoggerObjectMVP(
                            ex, recordsIds
                    )
            );
            throw ex;
        }finally{
            thisLogger.dispatch();
        }

        thisLogger.dispatch();
    }
    
    public void handleFreeTrialDecision(){
        FreeTrialDecisionsHandler.handleDecision(this.opt.infoFTDetails);
    }
    
    
    public class Options {
        public String Operation {get; set;}
        public List<FreeTrialDecisionsHandler.FreeTrialFlowInfo> infoFTDetails { get; set;}
        
        public Options() {} 
        
        public Options(String operation){
            this.Operation = operation;
        }
        
        public Options(String operation, List<FreeTrialDecisionsHandler.FreeTrialFlowInfo> infoFTDetails){
            this(operation);
            this.infoFTDetails = infoFTDetails;
        }
    }
}