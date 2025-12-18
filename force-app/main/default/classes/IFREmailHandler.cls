global  class IFREmailHandler implements Messaging.InboundEmailHandler {
    global class FromFlow{
        @invocablevariable(required=true)
        global id ifrId;
        @invocablevariable(required=true)
        global String salesDirectorId;
    }
    //send email to sales director for approval when IFR is created
    @InvocableMethod(label='notificationEmailToSalesDirector' description='To send email notification to sales director for approval/rejection of ifr')
    global static void notificationEmailToSalesDirector(List<fromFlow> valFromFlow){
        System.debug('send email to sales director for approval');
        sendEmailToSD(valFromFlow.get(0).ifrId,valFromFlow.get(0).salesDirectorId);
    }
    // construction email subject,body and sender and recipient
    public static void sendEmailToSD(Id ifr,String salesDirectorId) {
        try {
            Internal_Finance_Approval_Request__c ifrObj=[SELECT Id,Opportunity__r.Name,Quote__r.Name,Approver__c,Account__c,Account__r.Name,Request_Type__c,Quote__c,Opportunity__c,Opportunity__r.ACV_Bookings_USD__c,Opportunity__r.CloseDate,
                                                         Approved_Payment_Type_at_Submission__c,Name,CreatedBy.Name,Requested_Payment_Types__c,Payment_Type_Opportunity_only_Exception__c,Notes_from_Requester__c FROM 
                                                         Internal_Finance_Approval_Request__c where id=:ifr];
            String OppExcep='No';
            if(ifrObj.Payment_Type_Opportunity_only_Exception__c==False)
            {
                OppExcep='No';
            }
            else
            {
                OppExcep='Yes'; 
            }
            User userObj=[Select id,email,Name from user where id=:salesDirectorId];
            ifrObj.Approver__c=salesDirectorId;
            update ifrObj;
            String notesFromRecOrginal=ifrObj.Notes_from_Requester__c;
            String notesFromRecReplaced=notesFromRecOrginal.replace('For a quicker resolution and to avoid further iterations with Deal Desk please respond to all relevant questions in the Text Field below.','');
            String body='Hi '+userObj.Name+','+'\n'+'\n'+ifrObj.CreatedBy.Name+' has submitted a Payment Type Request for '+ifrObj.Account__r.Name+' and is requesting '+ifrObj.Requested_Payment_Types__c+' billing.'+' Please review the business justification below.To approve or reject this request, reply to this email with the word APPROVE, APPROVED, YES, REJECT, REJECTED, or NO in the first line of the email message.'+'\n'+'\n'+'Opportunity: '+ifrObj.Opportunity__r.Name+' '+Url.getOrgDomainUrl().toExternalForm()+'/'+ifrObj.Opportunity__c+'\n'+'\n'+'Quote: '+ifrObj.Quote__r.Name+' '+Url.getOrgDomainUrl().toExternalForm()+'/'+ifrObj.Quote__c+'\n'+'\n'+'Opportunity ACV:'+ifrObj.Opportunity__r.ACV_Bookings_USD__c+'\n'+'\n'+'Opportunity Close Date:'+ifrObj.Opportunity__r.CloseDate+'\n'+'\n'+'Business Justification: '+notesFromRecReplaced+'\n'+'\n'+'One-Time Payment Type Exception:'+OppExcep+'\n'+'\n'+'Thank you.';
            String subject='Approval Requested: Payment Type Request for '+ifrObj.Account__r.Name+' - '+ifrObj.Name;
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {userObj.email });
            email.setSubject(subject);
            email.setPlainTextBody(body);
            String emailFrom=system.label.IFR_From_Email_address_for_Sales_Director_Approval;
            if (emailFrom != null && String.isNotBlank(emailFrom)) {
                email.setReplyTo(emailFrom);
            }
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('results'+results);
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
            
        }
    }
    //Once sales director approves the email ,if the first line is yes/approve/approved
    // and no second line by default requested payment is approved payment type,if the first line is yes/approve/approved
    // and in second line if any payment type is specified we will take the approved payment as mentioned in the second line.
    // in case of rejection, if the first line no/rejected then status will be rejected if there is any second line mentioned in the mail we will take that and keep in finance comments.
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        try {
            Boolean approvalStatus=false;
            String approvedPaymentType=null;
            String financeComments=null;
            Integer check=0;
            String emailBody = '';
            String idRecord='';
            idRecord=extractRecordIdFromSubject(email.subject);
            String approvedStatus='';
            String reason='';
            if(idRecord!=null && idRecord!=''){
                // Get the plain text body if available
                if (email.plainTextBody != null) {
                    emailBody = email.plainTextBody;
                    Integer newlineIndex = emailBody.indexOf('\n');
                    if (newlineIndex != -1) {
                        List<String> parts = emailBody.split('\n');
                        if(parts.size()>0){
                            approvedStatus = parts[0];
                            if(parts.size()>=2){
                                reason=parts[1];
                            }
                        }
                    }
                    
                } 
                
                if(approvedStatus!=null && approvedStatus!=''){
                    if(approvedStatus.toLowerCase().contains('approve')||approvedStatus.toLowerCase().contains('yes'))
                    {
                        approvalStatus=true;
                        check=1;
                        if(reason!=null && reason!=''){
                            if(reason.toLowerCase().contains('semi')){
                                approvedPaymentType='Direct Semi-Annual';
                            }
                            if(reason.toLowerCase().contains('annual') && !reason.toLowerCase().contains('semi')){
                                approvedPaymentType='Direct Annual';
                            }
                            else if(reason.toLowerCase().contains('quarterly')){
                                
                                approvedPaymentType='Direct Quarterly';
                            }
                            else if(reason.toLowerCase().contains('monthly')){
                                
                                approvedPaymentType='Direct Monthly';
                            }
                            else if(reason.toLowerCase().contains('upfront')){
                                
                                approvedPaymentType='Upfront Payments';
                            }
                        }
                    }
                    else if(approvedStatus.toLowerCase().contains('reject')||approvedStatus.toLowerCase().contains('no')){
                        approvalStatus=false;
                        if(reason!=null && reason!=''){
                            financeComments=reason;
                            
                        }
                        check=1;
                    }
                    
                }
            }
            System.debug('check'+check+'idRecord'+idRecord);
            if( check==1&&idRecord!=''&&idRecord!=null){
                idRecord='IF-'+idRecord;
                Internal_Finance_Approval_Request__c ifrObj=[SELECT Id,Quote__c, Account__c,Approver__c,Finance_Comments__c,
                                                             Opportunity__c,Opportunity__r.SBQQ__PrimaryQuote__c,
                                                             Opportunity__r.SBQQ__PrimaryQuote__r.Monthly_License_with_Tax__c,Approved_Payment_Type__c,Requested_Payment_Types__c,
                                                             Payment_Type_Approval_Status__c,Name FROM Internal_Finance_Approval_Request__c where Name=:idRecord]; 
                if(ifrObj!=null){
                    if(approvalStatus) {                                      
                        ifrObj.Payment_Type_Approval_Status__c='Approved';
                        if(approvedPaymentType!=null){
                            ifrObj.Approved_Payment_Type__c= approvedPaymentType;
                        }
                        else{
                            
                            if(!(ifrObj.Requested_Payment_Types__c.contains('and')))
                            {
                                ifrObj.Approved_Payment_Type__c= ifrObj.Requested_Payment_Types__c;  
                            }
                        }
                    }
                    else{
                        ifrObj.Payment_Type_Approval_Status__c='Rejected';  
                        
                        ifrObj.Finance_Comments__c=financeComments;
                        
                    }
                    String approverId=ifrObj.Approver__c;
                    ifrObj.Approver__c=approverId;
                    update ifrObj;
                    Decimal creditLimitCalculation;
                    if(approvalStatus &&ifrObj.Opportunity__r.SBQQ__PrimaryQuote__c!=null && ifrObj.Opportunity__r.SBQQ__PrimaryQuote__r.Monthly_License_with_Tax__c!=null){
                        Decimal monthlyLicenseValue=ifrObj.Opportunity__r.SBQQ__PrimaryQuote__r.Monthly_License_with_Tax__c;
                        creditLimitCalculation=monthlyLicenseValue+(monthlyLicenseValue*0.20);
                        Account acc=[select id,Credit_Limit__c from account where Id=:ifrObj.Account__c];
                        acc.Credit_Limit__c=creditLimitCalculation;
                        System.debug('acc credit Limit Calculation'+creditLimitCalculation);
                        update acc;
                    }
                }
            }
            result.success = true;
        } catch (Exception e) {
            System.debug('Error processing inbound email: ' + e.getMessage());
            result.success = false;
        }
        
        return result;
    }
    
    private static String extractRecordIdFromSubject(String subject) {
        if (subject == null || subject == '') {
            return '';
        }
        // Find the last occurrence of '-'
        Integer lastHyphenIndex = subject.lastIndexOf('-');
        // If no hyphen found, return empty string
        if (lastHyphenIndex == -1) {
            return '';
        } 
        // Return the substring from after the last hyphen to the end
        return subject.substring(lastHyphenIndex + 1).trim();   
        
    }
    
}