/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 06, 2021
*
* @description : This class will be responsible for handling Async Actions on Contact
* SFA-11
*
**/

public with sharing class GS_ContactServiceAsync extends BaseAsyncHandler{
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger(); 
    public override String getRequestType(){
        return 'Contact Service Async Job';
    } 
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Contact.SObjectType,
            Account.SObjectType};
                
                UnitOfWork uow = new UnitOfWork(MY_SOBJECTS);
    
    List<Id> recordsIds = new List<Id>();
    
    public override void execute(Async_Request__c ar)
    {
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);
        
        // Do something with Contact Records
        
        try{
            thisLogger.logTrace('Entering in GS_ContactServiceAsync');
            switch on opt.Operation {
                when 'Insert' {
                }
                when 'Update' {
                    updateRecords();
                }
                when 'Upsert' {
                }
                when 'Delete' {
                }
                when 'StampLawfulBasis' {
                    stampLawfulBasisOnContact();
                }
            }
        }catch(Exception ex){
            thisLogger.logError(
                    'Error in GS_ContactServiceAsync::',
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
    
    
    public void updateRecords(){
        
        
    }
    
    public void stampLawfulBasisOnContact(){
        
        List<Contact> contactList = stampfulBasisOnContact();
        
        if(!contactList.isEmpty()){
            thisLogger.logDebug('Stamp Lawful Basis On Contact :: ', contactList);
            uow.registerDirty(contactList);
            uow.commitWork();
        }
    }
    
    public List<Contact> stampfulBasisOnContact(){
        List<Contact> contactList = new List<Contact>();       
        for (Contact thisContact : new GS_ContactSelector(true).checkFatalError().getContactsToStampLawfulBasisOnContactByAccountIds(recordsIds)){
            thisContact.Associated_Lawful_Basis__c = 'Contract';
            contactList.add(thisContact);
        }
        return contactList;
    }
    
    
    public class Options {
        public String Operation {get; set;}
        
        public Options(String operation){
            this.Operation = operation;
        }
    }
}