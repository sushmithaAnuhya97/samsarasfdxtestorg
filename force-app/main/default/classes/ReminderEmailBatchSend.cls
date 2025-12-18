/* 
 * Class Created: 05/05/20 Kai-Rey Lee (GTMS-743/GTMS-803)
 * Test Class: RemidnerEmailBatchSend.cls
 * 9/17/20 Teja - (GTMS-1489) Added 'ENT', Exclude From Return Drip Campaign field as a criteria in the query, removed frequency of email when Return_Label_Sent_At__c is (-15, -30) to -25
 */  

global class ReminderEmailBatchSend implements Database.Batchable<sObject> 
{  
    List<Id> opptyIds = new List<Id>();
    public static Map<String, Id> reminderLabelLanguageTemplateIdMap = new Map<String, Id>(); 
    public static Map<String, Id> secondReminderLabelLanguageTemplateIdMap = new Map<String, Id>();
    String EmailType; 

    public ReminderEmailBatchSend(List<Id> filteredOpportunities){
        this.opptyIds = filteredOpportunities;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        String accRole = '%ENT%';
        String query = 'SELECT Id, Shipping_Address_NEW__c, Shipping_Address_NEW__r.Shipping_Contact__c,'
            + 'Shipping_Address_NEW__r.Shipping_Contact__r.Email, Shipping_Address_NEW__r.Shipping_Contact__r.firstname,' 
            + 'Shipping_Address_NEW__r.Shipping_Contact__r.lastname, OwnerId, Type, Owner.Name, Owner.Email, Account.CSM__r.Email,'
            + 'Return_Label_Attachment__c, Account.Which_written_language__c, Account.Exclude_From_Return_Drip_Campaign__c,' 
            + 'Return_Label_Sent_At__c FROM Opportunity WHERE Account.Exclude_From_Return_Drip_Campaign__c = false and (NOT Account.Owner_Role__c Like :accRole) and Id IN : opptyIds';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) 
    {     
        if(!(reminderLabelLanguageTemplateIdMap.size()>0)){
            reminderLabelLanguageTemplateIdMap = TemplateSelectionHelper.getTemplates('Return Label - Reminder Email');
            secondReminderLabelLanguageTemplateIdMap = TemplateSelectionHelper.getTemplates('Return Label - Second Reminder Email'); 
        }

        OrgWideEmailAddress samsaraFromEmail = [Select id from OrgWideEmailAddress where Address = 'returns@samsara.com' LIMIT 1];
        Set<Id> attachmentIds = new Set<Id>();
        Map<Id, Attachment> attMap;
        for(Opportunity o : scope) {
            attachmentIds.add(o.Return_Label_Attachment__c);
        }
        
        if(!attachmentIds.isEmpty()) {
            attMap = new Map<Id, Attachment>([SELECT Id, Name, Body FROM Attachment WHERE Id IN :attachmentIds]); 
        }

         List<Messaging.Email> emails = new List<Messaging.Email>();
         for(Opportunity o : scope){
                 String csmEmail;
                 if(o.Account.CSM__r.Email == NULL) {
                     csmEmail = 'cs-rtn@samsara.com';
                 } else {
                     csmEmail = o.Account.CSM__r.Email;
                 }      
                 Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                 String[] toAddresses = new String[] {o.Shipping_Address_NEW__r.Shipping_Contact__r.Email};
                     
                 String[] bccAddresses = new String[] {csmEmail,'return-labels@samsara.com',o.Owner.Email};
                     
                 String language = o.Account.Which_written_language__c;
                 Id returnLabelTemplateId;
                 
                 if((o.type == 'Warranty Exchange') || (o.type == 'Exchange')){
                     if(o.Return_Label_Sent_At__c != null){ 
                         if(o.Return_Label_Sent_At__c == System.Today().addDays(-25)){
                            returnLabelTemplateId = reminderLabelLanguageTemplateIdMap.get('English');
                             
                         } else if(o.Return_Label_Sent_At__c == System.Today().addDays(-40)){                        
                            returnLabelTemplateId = secondReminderLabelLanguageTemplateIdMap.get('English');
                         }
                     }
                 }
                 
                 mail.setToAddresses(toAddresses);
                 mail.setBccAddresses(bccAddresses);
                 mail.setBccSender(true);
                 mail.setOrgWideEmailAddressId(samsaraFromEmail.Id);
                 
                 try{
                     mail.setTemplateID(returnLabelTemplateId);
                 }
                 catch(System.NullPointerException e){
                     system.debug('The assignment of template Id failed with the error message '+e);
                 }
                 mail.setTargetObjectId(o.Shipping_Address_NEW__r.Shipping_Contact__c); 
                 mail.setWhatId(o.Id);
                 
                 Messaging.EmailFileAttachment emailAttach = new Messaging.EmailFileAttachment();
                 if(attMap.size()>0){
                     emailAttach.setBody(attMap.get(o.Return_Label_Attachment__c).Body);
                     emailAttach.setFileName(attMap.get(o.Return_Label_Attachment__c).Name);
                     emailAttach.setinline(false);
                     mail.setFileAttachments(new Messaging.EmailFileAttachment[] { emailAttach } );
                 }
                 
                 emails.add(mail);
         }
         if(Test.isRunningTest()){
             
         }else{
             Messaging.sendEmail(emails);
         }
     }
    
    global void finish(Database.BatchableContext BC){}
}