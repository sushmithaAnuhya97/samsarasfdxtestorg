/**********************************************************************
Name: FR_Related_Opps_Update_Batch
Test Class: FR_Related_Opps_Update_Batch_TEST
-----------------------------------------------------------------------
Purpose: This class contains the logic to update Feature related opportunities data on every quarter end
-----------------------------------------------------------------------
History  
TICKET		AUTHOR			DATE		DETAIL
GTMS-25823 	Vijaychandra	01/18/25	To update the Feature request related opportunities data on every quarter end.
***********************************************************************/ 
/*
string cronExp = '0 0 1 2 1,4,7,10 ?';
System.schedule('FR Related Opps Update Batch',cronExp,new FR_Related_Opps_Update_Batch());
*/
public class FR_Related_Opps_Update_Batch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public List<ErrorWrapper> errorList = new List<ErrorWrapper>();
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        string query = 'SELECT Id FROM acideasULT__brIdea__c';
        
        return Database.getQueryLocator(query);
        
    }
    
    public void execute(Database.BatchableContext bc, List<acideasULT__brIdea__c> ideaList){
        Map<Id,Opportunity_Idea_Assignment__c> relatedOppMap = new Map<Id,Opportunity_Idea_Assignment__c>([SELECT Id,AC_Idea__c,Opportunity_Stage_Text__c,ACV__c,Opportunity__r.StageName,Opportunity__r.ACV_Bookings_SOT__c FROM Opportunity_Idea_Assignment__c WHERE AC_Idea__c IN :ideaList]);
        List<Opportunity_Idea_Assignment__c> oppIAUpdateList = new List<Opportunity_Idea_Assignment__c>();
        Opportunity_Idea_Assignment__c oppIARec;
        for(Opportunity_Idea_Assignment__c oppIA:relatedOppMap.values()){
            oppIARec = new Opportunity_Idea_Assignment__c();
            oppIARec.Id = oppIA.Id;
            oppIARec.Opportunity_Stage_Text__c = oppIA.Opportunity__r.StageName;
            oppIARec.ACV__c = oppIA.Opportunity__r.ACV_Bookings_SOT__c;
            
            oppIAUpdateList.add(oppIARec); 
        }
        if(!oppIAUpdateList.isEmpty()){
            ErrorWrapper errRec;
            for(Database.SaveResult sr: Database.update(oppIAUpdateList,false)){
                if(!sr.isSuccess() || Test.isRunningTest()){
                    Opportunity_Idea_Assignment__c relatedOppRec = relatedOppMap.get(sr.getId()) != null ? relatedOppMap.get(sr.getId()) : new Opportunity_Idea_Assignment__c();
                    Database.Error err = sr.getErrors().size()>0 ? sr.getErrors().get(0) : null;
                    string errorMessage = err != null ? String.valueOf(err.getMessage()).replace('\n','--'): null;
                   	errRec = new ErrorWrapper(sr.getId(),relatedOppRec.AC_Idea__c,errorMessage);
                   	errorList.add(errRec);
                }
            }
            
        }
    }
    
    public void finish(Database.BatchableContext bc){
        if(!errorList.isEmpty()){sendEmailMethod(bc.getJobId());}
        
        Last_FR_Total_ACV_Batch_Run_Date__c custSettings = Last_FR_Total_ACV_Batch_Run_Date__c.getOrgDefaults();
        custSettings.Last_Run_Date__c = String.valueOf(Date.Today());
        update custSettings;
    }
    
    /*************************************************
     * Description: to send emails to user who initiates OVA through submitting to closing
     * jobId : Batch Job Id
	*/
    public void sendEmailMethod(string jobId){
        AsyncApexJob a = [SELECT Id, CreatedBy.Profile.Name,CreatedBy.Email FROM AsyncApexJob WHERE Id =:jobId];
        
        List<String> emailList = new List<String>();
        emailList.add(a.CreatedBy.Email);
        
        string csvString = string.join(new List<string>{'Rleated Opportunity Id','Feature Request Id','Error Message'},',')+'\n';
        List<String> dataList = new List<String>();
        for(ErrorWrapper ew:errorList){
            dataList.add(ew.relatedOppId+','+ew.frId+','+ew.errorMsg);
        }
        csvString += string.join(dataList,'\n');
        system.debug(csvString);
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Qaurterly Total ACV Calculation Failed Records.csv');
        attachment.setBody(Blob.valueOf(csvString));
        attachment.setContentType('tex/csv');
        attachment.setInline(true);
        
        Messaging.singleEmailMessage msg = new Messaging.singleEmailMessage();
        msg.setSubject('Qaurterly Total ACV Calculation Failed Records');
        msg.setHtmlBody('Hi, Sum of the Feature request and its Related Opportunities Total ACV Calculation got failed. Please find the attachment for Failure details');
        msg.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});
        msg.setToAddresses(emailList);
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{msg},false);   
    }
    
    
    public class ErrorWrapper{
        public string relatedOppId{get;set;}
        public string frId{get;set;}
        public string errorMsg{get;set;}
        
        public ErrorWrapper(string relatedOppId, string frId, string errorMsg){
            this.relatedOppId = relatedOppId;
            this.frId = frId;
            this.errorMsg = errorMsg;
        }
    }
    
    @InvocableMethod(label='Execute FR ACV Total Batch')
    public static void executeFR_ACV_Batch(){
        Database.executebatch(new FR_Related_Opps_Update_Batch(),50);
    }
    
    public void execute(SchedulableContext sc){
        Database.executebatch(new FR_Related_Opps_Update_Batch(),50);
    }
}