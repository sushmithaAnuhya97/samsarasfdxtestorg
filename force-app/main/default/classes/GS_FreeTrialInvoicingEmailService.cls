/**
 * Created by vikasmishra on 2021-09-15.
 */

public with sharing class GS_FreeTrialInvoicingEmailService implements IService{
    static final String TEMPLATE_TYPE_STRING = 'Free Trail';
    static Map<String, Id> mapOfTemplateIdAndLanguage = getMapOfTemplateIdAndLanguage();
    static final OrgWideEmailAddress ORG_WIDE_DEFAULT_EMAIL_ADDRESS = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'trials@samsara.com' ];


    public  Messaging.SingleEmailMessage getEmailMessage(Quote thisQuote, Opportunity thisOpp, Blob body) {

        String emailTemplateId = mapOfTemplateIdAndLanguage.get(thisOpp.Account.Which_written_language__c);
       if(String.isBlank(emailTemplateId)){
           emailTemplateId = mapOfTemplateIdAndLanguage.get('English');
       }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        if(body != null){

            attach.setContentType('application/pdf');
            attach.setFileName('SamsaraTrialInvoice.pdf');
            attach.setInline(false);
            attach.body = body;
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach });
        }



        mail.setUseSignature(false);
        mail.setTemplateId(emailTemplateId);
        mail.setTargetObjectId(thisOpp.Trial_Primary_Contact__c);
        mail.setWhatId(thisOpp.Id);

        //in case the contact doesn't have email associated, we send email to billing email
        if (thisOpp.Trial_Primary_Contact__r.Email <> null) {
            List<String> customerEmail = new String[1];
            customerEmail[0] = thisOpp.Trial_Primary_Contact__r.Email;
            mail.setToAddresses(customerEmail);
        }

        mail.setOrgWideEmailAddressId(ORG_WIDE_DEFAULT_EMAIL_ADDRESS.Id);

        if (thisOpp.Account.Owner.Email <> null){
            mail.setCcAddresses(new String[] {thisOpp.Account.Owner.Email,'vikas@gscloudsolutions.com'});
        }


        mail.saveAsActivity = false;
        // Send the email
       return mail;
    }

    private static Map<String, Id> getMapOfTemplateIdAndLanguage() {
        Map<String, Id> languageTemplateIdMap = new Map<String, Id>();
        for(Email_Template__mdt template : new GS_EmailTemplateMetaDataSelector(true).checkFatalError().getEmailTemplatesMdtByType(TEMPLATE_TYPE_STRING)){
            languageTemplateIdMap.put(template.Language__c, template.Template_Id__c);
        }
        return languageTemplateIdMap;
    }

    public interface IService{
        Messaging.SingleEmailMessage getEmailMessage(Quote thisQuote, Opportunity thisOpp, Blob body);
    }


}