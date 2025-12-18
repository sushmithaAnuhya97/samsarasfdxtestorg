/**********************************************************************
Name: OrderValidationAutomation_Batch
Test Class: OrderValidationAutomation_Batch_TEST
-----------------------------------------------------------------------
Purpose: This class contains the logic to call Opportunity Order validation logic.
-----------------------------------------------------------------------
History  
TICKET		AUTHOR			DATE		DETAIL
GTMS-13378 	Vijaychandra	9/15/23		To overcome Quote calculation Queueable error
OVA Phase2	Vijaychandra	11/24/23	To add logic for Error Loging Emails as per Shobhit inputs
GTMS-19973	Vijaychandra	4/2/24		Added error logger functionality.
GTMS-20016	Vijaychandra	4/4/24		To log OVA Process Logs
***********************************************************************/ 
public class OrderValidationAutomation_Batch implements Database.Batchable<sObject>,Database.stateful{
    
    public Set<Id> oppIds;
    
    public List<ErrorWrapper> errorList = new List<ErrorWrapper>();
    public List<Opportunity> failedOppList = new List<Opportunity>();
    public Map<Id,String> errorMap = new Map<Id,String>();
    List<Id> loggerIdList = new List<Id>();//GTMS-20061 to log OVA process
    Async_Apex_Logging_Switch__mdt asyncLogSwitch = Async_Apex_Logging_Switch__mdt.getInstance('OVA_Log_Switch');
    public OrderValidationAutomation_Batch(Set<Id> oppIds){
        this.oppIds = oppIds;
    }
	
    public Database.querylocator start(Database.BatchableContext bc){
		string query = 'SELECT Id,Name,OwnerId,stageName, Probability, SBQQ__PrimaryQuote__c, Payment_Terms__c, Initial_Payment_Terms__c,'
            			+' Owner_Segment__c, Custom_Schedule__c, Type, Owner_Role_Copy__c, Owner_Manager_Role_Copy__c, Finance_Segment__c,' 
            			+' Is_Webstore_Upsell_Opportunity__c, Payment_Type__c, SBQQ__Renewal__c, Selected_Payment_Type__c, Buyout_Opportunity__c,' 
            			+' Subsidy_Opportunity__c, Blended_Discount__c, Owner_Manager_Name_Copy__c, Owner_Director_Name_Copy__c, CurrencyIsoCode, DCA_Enabled__c, Owner_AVP_Name_Copy__c,'
            			+' OM_Review_Reason_Code__c, Opportunity_Tracking__c,Buyout_Amount__c,Subsidy_Amount__c'
            			+' FROM Opportunity WHERE Id IN :oppIds';
        return Database.getQueryLocator(query);

    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope){
        Map<Id,Id> opptyLoggerMap = new Map<Id,Id>();
        List<Id> oppIdList = new List<Id>();
        List<Async_Apex_Logger__c> aaLoggerList = new List<Async_Apex_Logger__c>();//List to created Async Apex logs
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>(scope);
        if(!asyncLogSwitch.Stop_OVA_Log_Creation__c){
            opptyLoggerMap = new AsyncApexLoggerService().createAsyncApexLogger(bc.getJobId(),'OrderValidationAutomation_Batch', 'Batch Apex', scope);
            if(!opptyLoggerMap.isEmpty()){loggerIdList.addAll(opptyLoggerMap.values());}
        }
        if(!oppMap.keySet().isEmpty()){
            Try{
                OrderValidationServiceAutomationAsync ovaAsync= new OrderValidationServiceAutomationAsync();
                ovaAsync.opptyLoggerMap = opptyLoggerMap;
            	ovaAsync.executeOrderValidation(new List<Id>(oppMap.keySet()),'Finance Validation');
            }catch(Exception ex){
                errorList.add(new ErrorWrapper(scope[0].Id,scope[0].Name,ex.getMessage()));
                failedOppList.add(scope[0]);
                errorMap.put(scope[0].Id,ex.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc){
        if(!failedOppList.isEmpty()){setCvsReviewMethod(failedOppList);}
        if(!errorList.isEmpty()){sendEmailMethod(bc.getJobId());}
        if(!errorMap.isEmpty() && !asyncLogSwitch.Stop_OVA_Log_Creation__c){new AsyncApexLoggerService().updateOVAFailuresInAsyncLogger(loggerIdList, errorMap);}
    }
    
    //11/24/23 Vijaychandra --START-- (OVA PAHSE 2 Error Emails Logic) To send error emails to users about OVA process failure records.
    /*************************************************
     * Description: to set Order Management review field to true for OVA Process failed records.
     * failedIdList : failed opportunity Ids
	*/
    public void setCvsReviewMethod(List<Opportunity> failedOppList){
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity opp:failedOppList){
            oppList.add(new Opportunity(Id=opp.Id,CVS_Review__c = true,OM_Review_Reason_Code__C = (Opp.OM_Review_Reason_Code__C != null) ? Opp.OM_Review_Reason_Code__C+';'+'Deal was routed to OM review because Order Validation Automation process was failed.': 'Deal was routed to OM review because Order Validation Automation process was failed.'));
        }
        try{
            update oppList;
            new OrderValidationServiceAutomationAsync().fireNotifications(failedOppList);
        }catch(System.Dmlexception ex){
            errorList.add(new ErrorWrapper(ex.getDmlId(0),ex.getDmlId(0),ex.getDmlMessage(0)+' --WHILE UPDATING CVS REVIEW AFTER OVA PROCESS FAILURE'));
        }
        
    }
    
    /*************************************************
     * Description: to send emails to user who initiates OVA through submitting to closing
     * jobId : Batch Job Id
	*/
    public void sendEmailMethod(string jobId){
        AsyncApexJob a = [SELECT Id, CreatedBy.Profile.Name,CreatedBy.Email FROM AsyncApexJob WHERE Id =:jobId];
        
        List<String> emailList = new List<String>();
        emailList.add(a.CreatedBy.Email);
        emailList.addAll(String.valueOf(SYSTEM.LABEL.OVA_Error_Log_Emails).split(';'));
        
        string csvString = string.join(new List<string>{'Opportunity Id','OpportunityName','Cause of Error','Error Message'},',')+'\n';
        List<String> dataList = new List<String>();
        for(ErrorWrapper ew:errorList){
            dataList.add(ew.oppId+','+ew.oppName+','+ew.errorMsg);
        }
        csvString += string.join(dataList,'\n');
        system.debug(csvString);
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('OVA Process Failed Records.csv');
        attachment.setBody(Blob.valueOf(csvString));
        attachment.setContentType('tex/csv');
        attachment.setInline(true);
        
        Messaging.singleEmailMessage msg = new Messaging.singleEmailMessage();
        msg.setSubject('OVA Process Failure');
        msg.setHtmlBody(System.Label.OVA_Failure_Email_Body);
        msg.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});
        msg.setToAddresses(emailList);
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{msg},false);   
    }
    
    //11/24/23 --END-- (OVA PAHSE 2 Error Emails Logic)
    
    public class ErrorWrapper{
        public string oppId{get;set;}
        public string oppName{get;set;}
        public string errorMsg{get;set;}
        
        public ErrorWrapper(string oppId, string oppName, string errorMsg){
            this.oppId = oppId;
            this.oppName = oppName;
            this.errorMsg = errorMsg;
        }
    }
    
}