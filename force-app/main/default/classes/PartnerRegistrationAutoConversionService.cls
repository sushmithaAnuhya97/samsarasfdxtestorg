/**
 * Created by vikasmishra on 2021-06-24.
 */

public without sharing class PartnerRegistrationAutoConversionService {

    static final String ADMIN_LOGIN_PORTAL_PROFILE_NAME = 'Samsara Partner Community Login License User';
    static final String LEAD_STATUS_TO_UPDATE = 'Verification Pending';
    @TestVisible
    static LeadConversionRestResourceHelper.IHelper thisLCRHelper = new LeadConversionRestResourceHelper();
    @InvocableMethod (Label='AutoConvert Partners' Description='Method to provision user')
    public static void assignLeads(List<Payload> payloads){
        LeadConversionRestResourceHelper.LEAD_STATUS_TO_UPDATE = LEAD_STATUS_TO_UPDATE;
        thisLCRHelper.setPayLoadString(JSON.serialize(payloads))
                .processPayloadForConversion().updateConvertedAccountAsPartner().doProcessUserProvisioning(ADMIN_LOGIN_PORTAL_PROFILE_NAME);

    }

    public class Payload {
        @InvocableVariable(Label='Lead Id' Description='Lead Id for user provisioning' Required=true)
        public String leadId;
        @InvocableVariable(Label='Account Id' Description='Existing Account Id for user provisioning' Required=true)
        public String accountId;
        @InvocableVariable(Label='Contact Id' Description='Contact Id for user provisioning')
        public String contactId;
        public String status = 'success';

    }



}