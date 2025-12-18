/**********************************************************************
Name: AccountMonthlyExpiration_Batch
Test Class: AccountMonthlyExpBatch_Test
-----------------------------------------------------------------------
Purpose: This class contains the logic to send emails to account owner and owner's manager based on certains conditions and a field update on a daily basis                                                       
-----------------------------------------------------------------------
History  
GTMS-14503	Vijaychandra AMARANENI	08/11/23	Intial Development for Monthly expiration emails for Direct Monthly accounts
GTMS-16798	Vijaychandra AMARANENI	11/16/23	Updated Monthly expiration email logic by added more condtions in SOQL
***********************************************************************/ 

public class AccountMonthlyExpiration_Batch implements Database.Batchable<sObject>, Schedulable{
    
    static final string MONTHLY_PAYMENT = 'Direct Monthly';
    static final string ANNUAL_PAYMENT = 'Direct Annual';
    static final string IF_DMF_TYPE = 'Direct Monthly Financing';
    static final String IF_APPROVED_STATUS = 'Approved';

    public Database.querylocator start(Database.BatchableContext bc){

        Date date90 = Date.today().addDays(-90);
        Date date60 = Date.today().addDays(-60);
        //11/16/23 Vijaychandra --START-- (GTMS-16798) :modified SOQL from Account to Internal Finance Request object and added conditions based on requirment
		/*'SELECT Id,Name,Owner.Email, Owner.Manager.Email,Approved_Payment_Type__c,IF_Response_Date__c,Current_Monthly_Payments__c,IF_Submitter_Email__c'
                        +' FROM Account'
                        +' WHERE'
                        +' (Approved_Payment_Type__c =: MONTHLY_PAYMENT AND IF_Response_Date__c =: date90'
                        +' AND (Current_Monthly_Payments__c = NULL OR Current_Monthly_Payments__c = 0))'
                        +' OR IF_Response_Date__c =:date60';
		*/
        string query = 'SELECT Id, IF_Response_Date__c,Request_Type__c, Account__c,Account__r.OwnerId,Account__r.Name,Account__r.Owner.Email,Account__r.Owner.Manager.Email,'
            			+' Account__r.Approved_Payment_Type__c,Account__r.Current_Monthly_Payments__c,Account__r.IF_Response_Date__c, Submitter__r.Email'
            			+' FROM Internal_Finance_Approval_Request__c'
            			+' WHERE'
            			+' ((IF_Response_Date__c =: date90 AND Account__r.IF_Response_Date__c =:date90)'
                        +' OR (IF_Response_Date__c =:date60 AND Account__r.IF_Response_Date__c =:date60 AND Request_Type__c =:IF_DMF_TYPE))'
            			+' AND (Account__r.Current_Monthly_Payments__c = NULL OR Account__r.Current_Monthly_Payments__c = 0)'
            			+' AND Account__r.Approved_Payment_Type__c =: MONTHLY_PAYMENT AND Account__c != NULL AND Payment_Type_Approval_Status__c =:IF_APPROVED_STATUS';
        //11/16/23 --END-- (GTMS-16798)
        return Database.getQueryLocator(query);

    }
	//11/16/23 Vijaychandra (GTMS-16278) Replaced parameter data type Account with Internal Finance Approval Request object
    public void execute(Database.BatchableContext bc, List<Internal_Finance_Approval_Request__c> scope){
        //calling method to send email or update payment type 
		processRecords(scope);
    }

    public void finish(Database.BatchableContext bc){

    }
	/*****************************************8
	 * @Description:this method will be executed when we schedule the class
	*/
    public void execute(System.schedulableContext sc){
        Database.executeBatch(new AccountMonthlyExpiration_Batch(),80);
    }
	/*****************************************8
	 * @Description:this method will draft the emails that need to be sent to account owner and owner's Manager
	 * @Param : acc - account record
	 * @Param : templateId - classic email templateId
	 * @return : this method will record draft email message  
	*/
    //11/16/23 Vijaychandra (GTMS-16278) Replaced parameter data type Account with Internal Finance Approval Request object
    //And replaced all account references with Internal Finance Approval Request
    private Messaging.SingleEmailMessage draftEmail(Internal_Finance_Approval_Request__c ifar,string templateId){
        
        List<string> ccEmailsList = new List<String>();
        if(ifar.Account__r.Owner.Manager != null){ccEmailsList.add(ifar.Account__r.Owner.Manager.Email);}
        if(ifar.Submitter__c != null && !(string.isEmpty(ifar.Submitter__r.Email))){ccEmailsList.add(ifar.Submitter__r.Email);}
		
        Messaging.singleEmailMessage msg = Messaging.renderStoredEmailTemplate(templateId,ifar.Account__r.OwnerId, ifar.Account__c);
        //msg.setToAddresses(new List<String>{/*acc.Owner.Email,*/'vijaychandra.amaraneni@samsara.com'});
        if(!ccEmailsList.isEmpty()){msg.setCcAddresses(ccEmailsList);}
        msg.setTemplateId(templateId);
        msg.setTargetObjectId(ifar.Account__r.OwnerId);
        //msg.setWhatId(acc.Id);
        msg.setSaveAsActivity(false);
        return msg;
    }
    /*****************************************8
	 * @Description:this method will send emails and update the payment type based on criteria
	 * @Param : scope - list of account records from execute mentod
	*/
    //11/16/23 Vijaychandra (GTMS-16278) Replaced parameter data type Account with Internal Finance Approval Request object
    //And replaced all account references with Internal Finance Approval Request
    public void processRecords(List<Internal_Finance_Approval_Request__c> scope){
        
        Date date90 = Date.today().addDays(-90);
        Date date60 = Date.today().addDays(-60);
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        Set<Account> date90Set = new Set<Account>();
       
        string templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName ='Monthly_Expiration_Email_Template'].Id;
		
        for(Internal_Finance_Approval_Request__c IFAR:scope){
            if((IFAR.Account__r.Current_Monthly_Payments__c == NULL ||IFAR.Account__r.Current_Monthly_Payments__c == 0) && IFAR.Account__r.Approved_Payment_Type__c == MONTHLY_PAYMENT){
                if(IFAR.IF_Response_Date__c == date60 && IFAR.Account__r.IF_Response_Date__c == date60 && IFAR.Request_Type__c == IF_DMF_TYPE){
                    emailList.add(draftEmail(IFAR,templateId));
                }if(IFAR.IF_Response_Date__c == date90 && IFAR.Account__r.IF_Response_Date__c == date90){
                    date90Set.add(mapAccountFields(ifar.Account__c));
                }
            }
        }
		
        if(!date90Set.isEmpty()){update new List<Account>(date90Set);}
            /*Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.AllowSave = true;
         	Database.update(date90List, dml);*/
           
        if(!emailList.isEmpty()){Messaging.sendEmail(emailList,false);}
    }
	
    private Account mapAccountFields(string accId){
        Account tempAcc = new Account();
        tempAcc.Id = accId;
        tempAcc.Approved_Payment_Type__c = ANNUAL_PAYMENT;
		
        return tempAcc;
    }
}