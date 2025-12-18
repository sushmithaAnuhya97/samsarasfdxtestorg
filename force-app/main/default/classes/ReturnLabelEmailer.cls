/*
* June 18th, 2020 Ron Saavedra (GTMS-931) sendReturnEmails (Update for German, Mexico, French Free Trial Return Templates)
* 9/17/2020 Ron - (GTMS-1457): (sendReturnEmails) update to handle concatenation of multiple attachments with either batch or non batch attachment addition
* 03/05/2021 Gaurav - (GTMS-3379) : Updated ccAddress list to carry CSM and IC email addresses
*/

public with sharing class ReturnLabelEmailer { 
    
    public static Map<String, Id> remorseRefundLabelLangugeTemplateIdMap = new Map<String, Id>();
    public static Map<String, Id> freeTrialReturnLabelLangugeTemplateIdMap = new Map<String, Id>();
    public static Map<String, Id> reminderLabelLanguageTemplateIdMap = new Map<String, Id>(); 
    public static Map<String, Id> warrantyExchangeLabelLangugeTemplateIdMap = new Map<String, Id>();
    
    //* 9/17/2020 Ron - (GTMS-1457): (sendReturnEmails) update to handle concatenation of multiple attachments with either batch or non batch attachment addition
    public static void sendReturnEmails(Map<Id, Opportunity> retsMap){
        
        Id orgWideEmailAddressId = System.Label.OrgWideEmailAddress;
        Set<Id> attachmentIds = new Set<Id>();
        Map<Id, Attachment> attMap = new Map<Id, Attachment>();
        
        if(!(remorseRefundLabelLangugeTemplateIdMap.size()>0)){
            remorseRefundLabelLangugeTemplateIdMap = TemplateSelectionHelper.getTemplates('Return Label - Remorse Refund');
        }

        if(!(freeTrialReturnLabelLangugeTemplateIdMap.size()>0)){
            freeTrialReturnLabelLangugeTemplateIdMap = TemplateSelectionHelper.getTemplates('Free Trial Return');
        }
        
        if(!(warrantyExchangeLabelLangugeTemplateIdMap.size()>0)){
            warrantyExchangeLabelLangugeTemplateIdMap = TemplateSelectionHelper.getTemplates('Return Label - Warranty/Exchange');
        }

        if(!(reminderLabelLanguageTemplateIdMap.size()>0)){
            reminderLabelLanguageTemplateIdMap = TemplateSelectionHelper.getTemplates('Return Label - Reminder Email');
        }
        
        
        // Make one big query of everything: Opp, Owner, Attachment, Shipping Address, and Shipping Address's contact info
        Map<Id, Opportunity> oppInfo = new Map<Id, Opportunity>([   SELECT  Id,
                                                                 Shipping_Address_NEW__c,
                                                                 Shipping_Address_NEW__r.Shipping_Email__c,
                                                                 Shipping_Address_NEW__r.Shipping_Contact__c, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.Email, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.firstname, 
                                                                 Shipping_Address_NEW__r.Shipping_Contact__r.lastname,
                                                                 OwnerId,
                                                                 Type,
                                                                 Owner.Name,
                                                                 Owner.Email,
                                                                 Account.CSM__r.Email,
                                                                 Return_Label_Attachment__c,
                                                                 Account.Which_written_language__c,
                                                                 AccountId,
                                                                 Account.SIC__c,
                                                                 Account.SIC__r.Email,
                                                                 Account.CSM__c,
                                                                 Return_Label_Sent_At__c
                                                                 FROM Opportunity 
                                                                 WHERE Id IN :retsMap.keySet()]);
        
        // We need to query attachments separately because we can't create an opp lookup to attachments
        // Enabled for multiple attachments (comma separated)
        for(Opportunity o : oppInfo.values()) {
            List<String> attachments;
            if(o.Return_Label_Attachment__c != null){
                if(o.Return_Label_Attachment__c.contains(',')){
                    attachments = o.Return_Label_Attachment__c.split(',');
                    for(String attach: attachments){
                        attachmentIds.add(Id.valueOf(attach));
                    }
                } else{
                    attachmentIds.add(o.Return_Label_Attachment__c);
                }
        	}
        }
        
        if(!attachmentIds.isEmpty()) {
            attMap = new Map<Id, Attachment>([SELECT Id, Name, Body FROM Attachment WHERE Id IN :attachmentIds]); 
        }
         
        // Now create the emails
        List<Messaging.Email> emails = new List<Messaging.Email>();
        for(Opportunity o : oppInfo.values()){
            //Check to avoid recursion -@Harsha/SS-124
            if(!HelperClass.recursionCheckForReturnOpps.contains(o.Id)){
                String csmEmail;
                // Send to CSM alias if there's no CSM
                if(o.Account.CSM__r.Email == NULL) {
                    csmEmail = 'cs-rtn@samsara.com';
                } else {
                    csmEmail = o.Account.CSM__r.Email;
                }
                // Make this a mass email thing           
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                // Moved from CC to BCC -@Harsha/SS-107
                String[] toAddresses = new String[] {};
                if(o.Shipping_Address_NEW__c != null && o.Shipping_Address_NEW__r.Shipping_Email__c != null){
                    toAddresses.add(o.Shipping_Address_NEW__r.Shipping_Email__c);
                } 
               
                /*GTMS-3379 : Gaurav Sharma : Start*/
                String[] ccAddresses = new String[] {};
                if(o.AccountId != null && o.Account.SIC__c != null && o.Account.SIC__r.Email != null){
                    ccAddresses.add(o.Account.SIC__r.Email);
                }
                
                if(o.AccountId != null && o.Account.CSM__c != null && o.Account.CSM__r.Email != null){
                    ccAddresses.add(o.Account.CSM__r.Email);
                }
                /*GTMS-3379 : Gaurav Sharma : End*/
                String[] bccAddresses = new String[] {csmEmail,'return-labels@samsara.com',o.Owner.Email};
                String language = o.Account.Which_written_language__c;
                Id returnLabelTemplateId;
                
                // Swapped the logic to send out correct emails to the customers - @Harsha/SS-126
                if((o.type == 'Warranty Exchange') || (o.type == 'Exchange')){
                    if(o.Return_Label_Sent_At__c != null && o.Return_Label_Sent_At__c == System.Today().addDays(-21)){ //return label sent 21 days ago or earlier
                        //this determines if the label that is being sent is 21 days or older
                        if((!String.isBlank(language)) && (reminderLabelLanguageTemplateIdMap.containsKey(language))){
                            returnLabelTemplateId = reminderLabelLanguageTemplateIdMap.get(language);
                        }
                        else{
                            returnLabelTemplateId = reminderLabelLanguageTemplateIdMap.get('English');
                        }
                    }
                    else {
                        if((!String.isBlank(language)) && (warrantyExchangeLabelLangugeTemplateIdMap.containsKey(language))){
                            returnLabelTemplateId = warrantyExchangeLabelLangugeTemplateIdMap.get(language);
                        }
                        else{
                            returnLabelTemplateId = warrantyExchangeLabelLangugeTemplateIdMap.get('English');
                        }
                    }
                // TODO - Remove this logic and utilize dynamic VF templates for German, Mexico, & French customers
                } else if(o.Type == 'Free Trial Return' && !String.isBlank(language) && freeTrialReturnLabelLangugeTemplateIdMap.containsKey(language) && language != 'English'){
                    returnLabelTemplateId = freeTrialReturnLabelLangugeTemplateIdMap.get(language);
                } else{
                    if((!String.isBlank(language)) && (remorseRefundLabelLangugeTemplateIdMap.containsKey(language))){
                        returnLabelTemplateId = remorseRefundLabelLangugeTemplateIdMap.get(language);
                    }
                    else{
                        returnLabelTemplateId = remorseRefundLabelLangugeTemplateIdMap.get('English');
                    }
                }
                
                mail.setToAddresses(toAddresses);
                // Moved from CC to BCC -@Harsha/SS-107
                /* GTMS-3379 : Gaurav Sharma : Uncommented to include CSM Email in cc : Start*/
                mail.setCcAddresses(ccAddresses);
                /* GTMS-3379 : Gaurav Sharma : Uncommented to include CSM Email in cc : End*/
                mail.setBccAddresses(bccAddresses);
                mail.setBccSender(true);
                mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
                
                try{
                    mail.setTemplateID(returnLabelTemplateId);
                }
                catch(System.NullPointerException e){
                    system.debug('The assignment of template Id failed with the error message '+e);
                }
                mail.setTargetObjectId(o.Shipping_Address_NEW__r.Shipping_Contact__c); 
                mail.setTreatTargetObjectAsRecipient(false);
                
                mail.setWhatId(o.Id);
                
                List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                if(attMap.size()>0){
                    for(Attachment att: attMap.values()){
                        Messaging.EmailFileAttachment emailAttach = new Messaging.EmailFileAttachment();
                        emailAttach.setBody(attMap.get(att.Id).Body);
                        emailAttach.setFileName(attMap.get(att.Id).Name);
                        emailAttach.setinline(false);
                        emailAttachments.add(emailAttach);
                    }
                    mail.setFileAttachments(emailAttachments);
                }              
                emails.add(mail);
                HelperClass.recursionCheckForReturnOpps.add(o.Id);
            }
        }
        if(Test.isRunningTest()){
            //Do Nothing
        } else{            
            Messaging.sendEmail(emails);
        }
    }
    
    //GTMS-27166
    public static void sendWarrantyExchangeEmailAlert(Map<Id, Opportunity> oldOpportunities, Map<Id, Opportunity> newOpportunities) {
        String returnEmailAdd = 'return-labels@samsara.com';
        
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        Set<Id> oppIdSet = new Set<Id>();
        
        for(Opportunity newOpp : newOpportunities.values()) {
            Opportunity oldOpp = oldOpportunities.get(newOpp.Id);
            if((newOpp.Type == 'Warranty Exchange' || newOpp.Type == 'Exchange') && 
               (newOpp.StageName == 'End of Life' || newOpp.StageName == 'End of Life with Promo') &&
               (newOpp.StageName != oldOpp.StageName)) 
            {
                oppIdSet.add(newOpp.Id);
            }
        }
        
        If(!oppIdSet.isEmpty()) {
            
            Id orgWideEmailAddressId = System.Label.OrgWideEmailAddress;
            EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Name = 'EOL Products Email' LIMIT 1];

            for(Opportunity newOpp : [Select Id, 
                                      Shipping_Address_NEW__r.Shipping_Contact__c, 
                                      Shipping_Address_NEW__r.Shipping_Email__c, 
                                      Owner.Email 
                                      FROM Opportunity 
                                      WHERE Id IN :oppIdSet
                                      AND Shipping_Address_NEW__c != null
                                      AND Shipping_Address_NEW__r.Shipping_Contact__c != null]) 
            {
                List<String> toEmailAddList = new List<String>();
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTemplateId(template.Id);
                email.setWhatId(newOpp.Id);
                email.setSaveAsActivity(false);
                email.setTargetObjectId(newOpp.Shipping_Address_NEW__r.Shipping_Contact__c); 
                email.setTreatTargetObjectAsRecipient(false);
                email.setOrgWideEmailAddressId(orgWideEmailAddressId);
                
                if(newOpp.Shipping_Address_NEW__r != null && newOpp.Shipping_Address_NEW__r.Shipping_Email__c != null) {
                    toEmailAddList.add(newOpp.Shipping_Address_NEW__r.Shipping_Email__c);
                }
                
                if(newOpp.Owner.Email != null) {
                    toEmailAddList.add(newOpp.Owner.Email);
                }
                
                if(!toEmailAddList.isEmpty()) {
                    email.setToAddresses(toEmailAddList);
                }
                email.setCcAddresses(new List<String>{returnEmailAdd});
                
                emailsToSend.add(email);
            }
            
        }
        
        if(!emailsToSend.isEmpty()) {
            try {
                Messaging.sendEmail(emailsToSend);
            } catch(Exception e) {
                System.debug('Error sending warranty exchange emails: ' + e.getMessage());
            }
        }
    }
    
     // GTMS-25173: Start - Hold Reason Email Notifications using Custom Email Templates
    // When a Return Opportunity's Hold Reason changes, this method automatically sends 
    // the appropriate notification email to the right person using predefined email templates
    public static void sendHoldReasonNotifications(Map<Id, Opportunity> newOpportunities, Map<Id, Opportunity> oppFields) {
        System.debug('sendHoldReasonNotifications ==');
       
        // Final stages where notification is not needed
        //Set<String> finalStages = new Set<String>{'Refunded-Closed', 'Partially Received'};
            
            // Filter out valid Opportunity records from map
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for (Id oppId : newOpportunities.keySet()) {
            Opportunity opp = newOpportunities.get(oppId);
            if (opp != null) {
                oppMap.put(oppId, opp);
            }
        }
        
        // Mapping Hold Reasons to corresponding Email Template IDs from Custom Labels
        Map<String, Id> holdReasonToTemplateId = new Map<String, Id>{
            'Return Kickback: Promo - RTS' => System.Label.Return_Kickback_Promo_Template_ID,
                'Free Trial - RTS'             => System.Label.Free_Trial_RTS_Template_ID,
                'Revenue - RTS'                => System.Label.Revenue_RTS_Template_ID,
                'Unplanned Return'             => System.Label.Unplanned_Return_Template_ID,
                'Partial Remorse Refund'       => System.Label.Partial_Remorse_RefundTemplate_ID
                };
                    
                    system.debug('holdReasonToTemplateId == ' +	 holdReasonToTemplateId);
        
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        // Get Org-Wide Email Address from custom label
        Id orgWideEmailAddressId = System.Label.OrgWideEmailAddress;
        
        Id renderingContactId;
     
        // Loop through all valid Opportunities to determine who should receive notifications
        for (Opportunity opp : oppMap.values()) {
            // Skip final stage Opportunities
               renderingContactId = oppFields.get(opp.Id).Shipping_Address_NEW__r.Shipping_Contact__c;
            //if (finalStages.contains(opp.StageName)) continue;
            
            Set<String> recipientEmails = new Set<String>();
            
            // Specific override for Saurav on one hold reason (for testing or ownership)
            if (opp.Hold_Reason__c == 'Return Kickback: Promo - RTS') {
                recipientEmails.add('support@samsara.com');
            } else{
                // Add Opportunity Owner's email
                if (oppFields.get(opp.Id).Owner != null && String.isNotBlank(oppFields.get(opp.Id).Owner.Email)) {
                    recipientEmails.add(oppFields.get(opp.Id).Owner.Email);
                }
                
                // Add Account Owner's email
                if (oppFields.get(opp.Id).Account != null && oppFields.get(opp.Id).Account.Owner != null && String.isNotBlank(oppFields.get(opp.Id).Account.Owner.Email)) {
                    recipientEmails.add(oppFields.get(opp.Id).Account.Owner.Email);
                }
            }
            
            // Skip if no valid recipients
            if (recipientEmails.isEmpty()) continue;
            
            // Get template ID for the Hold Reason
            Id templateId = holdReasonToTemplateId.get(opp.Hold_Reason__c);
            system.debug('templateId == ' + templateId);
            
            // Proceed if a matching template ID is found
            if (templateId != null && renderingContactId != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTemplateId(templateId);
                email.setTreatTargetobjectAsRecipient(false);
                email.setWhatId(opp.Id);
                email.setTargetObjectId(renderingContactId);
                email.setToAddresses(new List<String>(recipientEmails));
                email.setSaveAsActivity(false);
                
                // Use Org-Wide Email Address
                if (orgWideEmailAddressId != null) {
                    email.setOrgWideEmailAddressId(orgWideEmailAddressId);
                }
                
                emailsToSend.add(email);
            }
        }
        
        // Send all prepared emails in bulk
        if (!emailsToSend.isEmpty()) {
            try {
                if (!Test.isRunningTest()) {
                    System.debug('Preparing to send email...');
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend, false);
                    for (Messaging.SendEmailResult result : results) {
                        if (result.isSuccess()) {
                            System.debug('Email sent successfully.');
                        } else {
                            System.debug('Failed to send email: ' + result.getErrors()[0].getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                String errorMsg = 'Error sending Hold Reason notification emails: ' + e.getMessage();
                System.debug(errorMsg);
                
                for (Opportunity opp : oppMap.values()) {
                    LOGGER.atError()
                        .setClassName('ReturnLabelEmailer')
                        .setRecordId(opp.Id)
                        .setExceptionOrMessage(errorMsg);
                }
                
                if (Test.isRunningTest()) {
                    throw new EmailException('Error during sendHoldReasonNotifications');
                }
            }
        }
    }
    // GTMS-25173 End
}