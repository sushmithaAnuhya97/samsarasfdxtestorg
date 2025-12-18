/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 10, 2021
*
* @description : This class will be responsible for handling Async Actions on CS Record
* SFA-11
*
**/

public without sharing class GS_CS_RecordServiceAsync extends BaseAsyncHandler {
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    
    public override String getRequestType(){
        return 'CS Record Async Job';
    } 
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        CS_Record__c.SObjectType};
            
            UnitOfWork uow = new UnitOfWork(MY_SOBJECTS);
    
    List<Id> recordsIds = new List<Id>();
    
    public override void execute(Async_Request__c ar)
    {
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);

        // Do something with CS Records
        try{
            switch on opt.Operation {
                when 'Insert' {
                    insertCsRecords();
                }
                when 'Update' {

                }
                when 'Upsert' {
                    upsertRecords();
                }
                when 'Delete' {
                    deleteCsRecords();
                }
            }
        }catch(Exception ex){
            thisLogger.logError(
                    'Error in GS_CS_RecordServiceAsync during '+ opt.Operation +'Operation::',
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
    
    
    public void insertCsRecords(){
        List<sObject> records = new List<sObject>();
        List<Account> newAccountList = new List<Account>();
        for(Id accountId : recordsIds){
            CS_Record__c CSRecord = new CS_Record__c();
            CSRecord.Account__c = accountId;
            records.add(CSRecord);
        }
        if(!records.isEmpty()){
            thisLogger.logDebug('Creating CS Record - New Account Id ::', records);
            uow.registerNew(records);
            uow.commitWork();
        }
    }
    
    public void upsertRecords(){
        List<CS_Record__c> updatedRecords = new List<CS_Record__c>();
        updatedRecords = stampAccountInfoOnCsRecord();
        if(!updatedRecords.isEmpty()){
            thisLogger.logDebug('Stamp Account Info on CS Record  ::', updatedRecords);
            uow.registerUpsert(updatedRecords);
            uow.commitWork();
        }
    }
    
    public List<CS_Record__c> stampAccountInfoOnCsRecord(){
        List<CS_Record__c> updatedRecords = new List<CS_Record__c>();
        List<Account> accounts = new List<Account>();
        accounts = new GS_AccountSelector(true).checkFatalError().getAccountsWithCSMRecordsByAccIds(recordsIds);
        for(Account account : accounts){
            CS_Record__c relatedRecord = account.CS_Records__r.size() > 0 ? account.CS_Records__r.get(0) : null; 
            CS_Record__c updatedRecord = null;
            Boolean isChanged = false;
            if(relatedRecord != null){
                updatedRecord = new CS_Record__c(id = relatedRecord.Id);
                if(relatedRecord.Key_Stakeholder_for_CSM__c != account.Key_Stakeholder_for_CSM__c){
                    updatedRecord.Key_Stakeholder_for_CSM__c = account.Key_Stakeholder_for_CSM__c;
                    isChanged = true;
                }
                if(relatedRecord.Key_Value_Points__c != account.Key_Value_Points__c){
                    updatedRecord.Key_Value_Points__c = account.Key_Value_Points__c;
                    isChanged = true;
                }
                if(relatedRecord.Upsell_Opportunity_Products__c != account.Upsell_Opportunity_Products__c){
                    updatedRecord.Upsell_Opportunity_Products__c = account.Upsell_Opportunity_Products__c;
                    isChanged = true;
                }
                if(relatedRecord.AE_to_CSM_handoff_notes__c != account.AE_to_CSM_handoff_notes__c){
                    updatedRecord.AE_to_CSM_handoff_notes__c = account.AE_to_CSM_handoff_notes__c;
                    isChanged = true;
                }
                if(relatedRecord.Preparedness_Rating__c != account.Preparedness_Rating__c){
                    updatedRecord.Preparedness_Rating__c = account.Preparedness_Rating__c;
                    isChanged = true;
                }
                if(relatedRecord.Self_install_or_Vendor__c != account.Self_install_or_Vendor__c){
                    updatedRecord.Self_install_or_Vendor__c = account.Self_install_or_Vendor__c;
                    isChanged = true;
                }
                if(relatedRecord.Did_they_Trial__c != account.Did_they_Trial__c){
                    updatedRecord.Did_they_Trial__c = account.Did_they_Trial__c;
                    isChanged = true;
                }
                if(relatedRecord.Feature_commits_CSM__c != account.Feature_commits_CSM__c){
                    updatedRecord.Feature_commits_CSM__c = account.Feature_commits_CSM__c;
                    isChanged = true;
                }
                if(relatedRecord.Pain_Points_Objections_during_the_trial__c != account.Pain_Points_Objections_during_the_trial__c){
                    updatedRecord.Pain_Points_Objections_during_the_trial__c = account.Pain_Points_Objections_during_the_trial__c;
                    isChanged = true;
                }
                if(relatedRecord.CS_POC_Email_Address__c != account.CS_POC_Email_Address__c){
                    updatedRecord.CS_POC_Email_Address__c = account.CS_POC_Email_Address__c;
                    isChanged = true;
                }
                if(relatedRecord.CS_POC_First_Name__c != account.CS_POC_First_Name__c){
                    updatedRecord.CS_POC_First_Name__c = account.CS_POC_First_Name__c;
                    isChanged = true;
                }  
                if(relatedRecord.First_Purchase_Date__c != account.First_Purchase_Date__c ){
                    updatedRecord.First_Purchase_Date__c = account.First_Purchase_Date__c;
                    isChanged = true;
                } 
                if(relatedRecord.SIC__c != account.SIC__r.Name){
                    updatedRecord.SIC__c = account.SIC__r.Name;
                    isChanged = true;
                } 
                if(relatedRecord.Pre_Sale_IC__c != account.Pre_Sale_IC__r.Name){
                    updatedRecord.Pre_Sale_IC__c = account.Pre_Sale_IC__r.Name;
                    isChanged = true;
                } 
            }
            else if(relatedRecord == null){
                updatedRecord = new CS_Record__c();
                updatedRecord.Account__c = account.Id;
                //(GTMS-3070) Create Cs Record in the Update Transaction - Anil Bogadi
                updatedRecord.Key_Stakeholder_for_CSM__c = account.Key_Stakeholder_for_CSM__c;
                updatedRecord.Key_Value_Points__c = account.Key_Value_Points__c;
                updatedRecord.Upsell_Opportunity_Products__c = account.Upsell_Opportunity_Products__c;
                updatedRecord.AE_to_CSM_handoff_notes__c = account.AE_to_CSM_handoff_notes__c;
                updatedRecord.Preparedness_Rating__c = account.Preparedness_Rating__c;
                updatedRecord.Self_install_or_Vendor__c = account.Self_install_or_Vendor__c;
                updatedRecord.Did_they_Trial__c = account.Did_they_Trial__c;
                updatedRecord.Feature_commits_CSM__c = account.Feature_commits_CSM__c;
                updatedRecord.Pain_Points_Objections_during_the_trial__c = account.Pain_Points_Objections_during_the_trial__c;
                updatedRecord.CS_POC_Email_Address__c = account.CS_POC_Email_Address__c;
                updatedRecord.CS_POC_First_Name__c = account.CS_POC_First_Name__c;
                updatedRecord.First_Purchase_Date__c = account.First_Purchase_Date__c;
                updatedRecord.SIC__c = account.SIC__c;
                updatedRecord.Pre_Sale_IC__c = account.Pre_Sale_IC__c;
                isChanged = true;
            }
            if(isChanged == true){
                updatedRecords.add(updatedRecord);
            }
        }
        return updatedRecords;
    }
    
    public void deleteCsRecords(){
        List<CS_Record__c> csRecords = new List<CS_Record__c>();
        csRecords = new GS_CS_RecordSelector(true).checkFatalError().getCSRecordsByIds(recordsIds);
        if(!csRecords.isEmpty()) {
            thisLogger.logDebug('Deleting CS Record  ::', csRecords);
            //delete csRecords;
            uow.registerDeleted(csRecords);
            uow.commitWork();
        }
    }
    
    
    public class Options {
        public String Operation {get; set;}
        
        public Options(String operation){
            this.Operation = operation;
        }
    }
}