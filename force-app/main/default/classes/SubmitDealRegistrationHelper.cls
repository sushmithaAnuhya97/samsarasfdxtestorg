public class SubmitDealRegistrationHelper {

    public static void afterInsertOperations(Map<Id, SubmitDealRegistrationEvent__e> oldEventMap, List<SubmitDealRegistrationEvent__e> newEventList){
        Map<Id, Lead> recordsToUpdate = new Map<Id, Lead>();
        Set<Id> leadRecordIdSet = new Set<Id>();
        Set<Id> leadOwnerIdSet = new Set<Id>();

        for (SubmitDealRegistrationEvent__e event : newEventList) {
            if(!String.isBlank(event.Lead_Record_Id_t__c)) {
                leadRecordIdSet.add(event.Lead_Record_Id_t__c);
            }
        }
        
        //Query the lead records
        List<Lead> leadRecords = Database.query('Select Id, Status, OwnerId from Lead where Id in :leadRecordIdSet');
        if(!leadRecords.isEmpty()) {
            for(Lead record : leadRecords) {
                leadOwnerIdSet.add(record.OwnerId);
            }    
        }
        
        //Get related PSM UserId
        Map<Id, User> psmUserMap = new Map<Id, User>([Select Id, Account.OwnerId from User where Id in :leadOwnerIdSet]);
        
        //change lead record ownership to PSM
        for(Lead record : leadRecords) {
            if(psmUserMap.containsKey(record.OwnerId)) {
                User leadOwner = psmUserMap.get(record.OwnerId);
                if(leadOwner.Account != null && leadOwner.Account.OwnerId != null) {
                    record.OwnerId = leadOwner.Account.OwnerId;
                    record.Status = 'Pending Review';
                    recordsToUpdate.put(record.Id, record);
                }
            }
        }

       	List<Lead> dealsToSendEmail = new List<Lead>();
        if(recordsToUpdate.size() > 0){
            Database.SaveResult[] updateResult = Database.update(recordsToUpdate.values(), false);
            for (Database.SaveResult result : updateResult){
                if (result.isSuccess()) {
                    dealsToSendEmail.add(recordsToUpdate.get(result.getId()));
                }
            }
        }
        
        //Notify CAM users about the new deal reg submission
        //5/6/24 Vijaychandra --START-- (GTMS-20584): Commneted below code to stop sending emails to lead owners for Partners System Alignment project
        /*
        if(!dealsToSendEmail.isEmpty()) {
            SubmitDealRegistrationHelper.sendNewDealRegEmailToCAM(dealsToSendEmail);
        }
		*/
        //--END-- (GTMS-20584)
        //5/6/24 Vijaychandra --START-- (GTMS-20584): Added below code to send leads to notre dam when lead are submitted to CAMs for Partners System Alignment project
        if(!leadRecordIdSet.isEmpty() && !System.isBatch() && !System.isFuture()){
            callNotreDamFuture(leadRecordIdSet);
        }
        //--END-- (GTMS-20584)
        
    }
    //5/6/24 Vijaychandra --START-- (GTMS-20584): Added below code to send leads to notre dam when lead are submitted to CAMs for Partners System Alignment project
    /*
     * @Description: Future callout method to perform webservice callout to NotreDam system to send lead Ids
     * @param: leadIdSet - set of lead Ids
	*/
    @future(callout=true)
    public static void callNotreDamFuture(Set<Id> leadIdSet){
        for(Id leadId:leadIdSet){
            SubmitLeadForApprovalControllerService.IService thisCtrlService = new SubmitLeadForApprovalControllerService();
        	thisCtrlService.submitLeadForApprovalByPSM(leadId);
        }
        
    }
    //5/6/24 Vijaychandra --START-- (GTMS-20584): Commneted below code to stop sending emails to lead owners for Partners System Alignment project
    /*
    public static void sendNewDealRegEmailToCAM(List<Lead> leadRecords) {
        if(leadRecords != null) {
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            EmailTemplate template = [Select Id from EmailTemplate where DeveloperName = 'Channel_CAM_NewLead_Alert'];
            OrgWideEmailAddress fromEmail = [Select Id from OrgWideEmailAddress where DisplayName = 'no-reply'];
            
            for(Lead record : leadRecords) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
                List<String> toAddresses = new List<String>{record.OwnerId};
                mail.setToAddresses(toAddresses);
                mail.setTargetObjectId(record.Id);
                mail.setTreatTargetObjectAsRecipient(false);
                mail.setTemplateId(template.Id);
                mail.setOrgWideEmailAddressId(fromEmail.Id);
                
                emailsToSend.add(mail);
            }
            
            if(!emailsToSend.isEmpty()) {
                // Send the emails created.
                Messaging.sendEmail(emailsToSend);
            }
        }
        
        
    }
	*/
     //--END-- (GTMS-20584)
}