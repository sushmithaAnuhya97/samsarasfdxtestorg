/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 24, 2021
*
* @description : This class will be responsible to Add Campaign to contact Asynchronously
* SFA-14
*
**/
public class GS_ContactCampaignToAddAsync extends BaseAsyncHandler{
    public override String getRequestType(){
        return 'ContactCampaignToAdd';
    } 
    
    SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Contact.SObjectType};
            
            UnitOfWork uow = new UnitOfWork(MY_SOBJECTS);
    
    List<Id> recordsIds = new List<Id>(); 
    Map<Id, Contact> newContactMap;
    public Map<Id, Contact> contactToUpdateById = new Map<Id, Contact>();
    public override void execute(Async_Request__c ar)
    {
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        
        newContactMap = new Map<Id, Contact>(
            (new GS_ContactSelector(true)).checkFatalError().getContactDetailsByIds(new Set<Id>(recordsIds)));
        
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in GS_ContactCampaignToAddAsync');
            for(Contact contactObj : newContactMap.values()){
                if (!contactToUpdateById.containsKey(contactObj.Id)) {
                    contactToUpdateById.put(contactObj.Id, contactObj.clone(true));
                }
                ContactWorkFlowConversion.processCampaignToAdd(contactToUpdateById.get(contactObj.Id));
            }
            
            if(!contactToUpdateById.isEmpty()){
                uow.registerDirty(contactToUpdateById.values());
                uow.commitWork(); 
            }
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError(
                'Error in GS_ContactCampaignToAddAsync::',
                new SamsaraLoggerObjectMVP(
                        ex, recordsIds
                )
        );
            throw ex;
        }finally{
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
}