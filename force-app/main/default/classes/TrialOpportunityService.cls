/**
 * Created by henryzhao on 2020-01-20.
 */

public class TrialOpportunityService {
    public static final String EMAIL_TEMPLATE_KEY = 'Trial Acceptance';
    public static final String DEFAULT_LANGUAGE = 'English';

    public static void emailOnTrialAgreementAcceptance(
            OpportunityStateManager store,
            UnitOfWork uow,
            Map<Id, Opportunity> oldOpps,
            Map<Id, Opportunity> newOpps) {
        List<Opportunity> emailEligibleOpps = new List<Opportunity>();

        for (Opportunity opp : newOpps.values()) {
            if (opp.Trial_Agreement_Accepted__c == True
                    && opp.Trial_Agreement_Accepted__c != oldOpps.get(opp.Id).Trial_Agreement_Accepted__c) {
                //Add oppty, owner & selected contact to list if Trial Agreement was changed and set to True
                emailEligibleOpps.add(opp);
            }
        }

        Map<String, Id> languageToTemplateId = new Map<String, Id>();
//        no email to send, end the method
        if (emailEligibleOpps.isEmpty()) {
            return;
        } else {
            languageToTemplateId = store.getlanguageToTemplateId(EMAIL_TEMPLATE_KEY);
        }

        store.addToUserMap(emailEligibleOpps);
        store.addToContactMap(emailEligibleOpps);
        store.addToAccountMap(emailEligibleOpps);

        for (Opportunity opp : emailEligibleOpps) {
            Id templateId;
            final String LANG = store.accountInformationMap.get(opp.AccountId).Which_written_language__c;

            if (String.isBlank(LANG) || languageToTemplateId.get(LANG) == null) {
                templateId = languageToTemplateId.get(DEFAULT_LANGUAGE);
            } else {
                templateId = languageToTemplateId.get(LANG);
            }
            final User OPP_OWNER = store.userInformationMap.get(opp.OwnerId);
            final Contact TRIAL_CONTACT = store.contactInformationMap.get(opp.Trial_Primary_Contact__c);
            // TODO: hzhz - this only ever looks at trial primary contact, but what about shipping contact?

            if (OPP_OWNER != null && TRIAL_CONTACT != null) {
                uow.registerEmail(generateTrialEmail(
                        OPP_OWNER,
                        TRIAL_CONTACT,
                        store.getsamsaraSalesEmail(),
                        templateId,
                        opp
                ));
            } else {
                uow.registerEmail(generateErrorEmail(opp, store.getsamsaraSalesEmail()));
            }
        }
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-01-28
    *
    * @description Generates a standard trial welcome email
    */
    private static Messaging.Email generateTrialEmail(
            User oppOwner,
            Contact trialContact,
            OrgWideEmailAddress salesEmail,
            Id templateId,
            Opportunity opp
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> toAddress = new List<String>{
                trialContact.Email
        };
        List<String> ccAddress = new List<String>{
                oppOwner.Email
        };
        mail.setToAddresses(toAddress);
        mail.setCcAddresses(ccAddress);
        mail.setBccSender(false);
        mail.setOrgWideEmailAddressId(salesEmail.Id);
        mail.setReplyTo(oppOwner.Email);
        mail.setTargetObjectId(trialContact.Id);
        mail.setTemplateId(templateId);
        mail.setUseSignature(false);
        mail.setWhatId(opp.Id);

        return mail;
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-01-28
    *
    * @description Generates a standard Samsara error email
    */
    private static Messaging.Email generateErrorEmail(Opportunity opp, OrgWideEmailAddress salesEmail) {
// Either Owner or Contact are not defined - generate error email to Admin, no email will be sent to contact OR owner
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // TODO: hzhz - this should be custom metadata
        String[] toAddresses = new String[]{
                'rushil@samsara.com'
        };
        mail.setToAddresses(toAddresses);
        mail.setBccSender(false);
        mail.setOrgWideEmailAddressId(salesEmail.Id);
        // TODO: hzhz - this should be custom metadata
        mail.setReplyTo('rushil@samsara.com');
// Email content
        mail.setSubject('Error in sending Free Trial Agreement');
        mail.setHtmlBody('There was an error in sending the free trial agreemnet email for https://samsara.my.salesforce.com/' + opp.id);

        return mail;
    }


}