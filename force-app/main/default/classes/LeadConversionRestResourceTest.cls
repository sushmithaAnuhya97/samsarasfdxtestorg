/**
 * Created by vikasmishra on 2021-07-06.
 * Modified by Azra Khan on 2025-10-09
 */
@IsTest
private class LeadConversionRestResourceTest {
    @IsTest
    static void shouldProcessDoPost() {
        RestRequest req = new RestRequest();
        
        String validPayload = '[{"leadId":"00Q000000000001","status":"success","accountId":"001000000000001","contactId":"003000000000001","errorMessage":""}]';
        req.requestBody = Blob.valueOf(validPayload);
        
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/lead-processing'; //Request URL
        req.httpMethod = 'POST';

        RestContext.request = req;
        RestContext.response= res;
        LeadConversionRestResourceHelperMock thisHelperMock = new LeadConversionRestResourceHelperMock();
        LeadConversionRestResource.thisRestResourceHelper = thisHelperMock;

        Test.startTest();
        LeadConversionRestResource.doPost();
        Test.stopTest();
        
        System.assert(
                thisHelperMock.setPayLoadStringMethodCalled,
                'LeadConversionRestResourceHelper.setPayLoadString method should be called'
        );
        System.assert(
                thisHelperMock.processPayloadForConversionMethodCalled,
                'LeadConversionRestResourceHelper.processPayloadForConversion method should be called'
        );
        System.assert(
                thisHelperMock.updateConvertedAccountAsPartnerMethodCalled,
                'LeadConversionRestResourceHelper.updateConvertedAccountAsPartner method should be called'
        );
        System.assert(
                thisHelperMock.create_PA_PR_CreationMethodCalled,
                'LeadConversionRestResourceHelper.create_PA_PR_Creation method should be called'
        );
    }

    @IsTest
    static void shouldHandleInvalidPayload() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('invalid json');
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/lead-processing';
        req.httpMethod = 'POST';

        RestContext.request = req;
        RestContext.response= res;
        LeadConversionRestResourceHelperMock thisHelperMock = new LeadConversionRestResourceHelperMock();
        LeadConversionRestResource.thisRestResourceHelper = thisHelperMock;

        Test.startTest();
        LeadConversionRestResource.doPost();
        Test.stopTest();
        
        System.assert(
                !thisHelperMock.setPayLoadStringMethodCalled,
                'LeadConversionRestResourceHelper.setPayLoadString method should NOT be called with invalid payload'
        );
    }

    public class LeadConversionRestResourceHelperMock implements LeadConversionRestResourceHelper.IHelper{
        public Boolean setPayLoadStringMethodCalled = false;
        public Boolean processPayloadForConversionMethodCalled = false;
        public Boolean processDealRegistrationCalled = false;
        public Boolean updateConvertedAccountAsPartnerMethodCalled = false;
        public Boolean doProcessUserProvisioningMethodCalled = false;
        public Boolean create_PA_PR_CreationMethodCalled = false;
        public Boolean processLeadConversionErrorCalled = false;
        
        public LeadConversionRestResourceHelper.IHelper setPayLoadString(String payloadJson){
            setPayLoadStringMethodCalled = true;
            return this;
        }
        public LeadConversionRestResourceHelper.IHelper processPayloadForConversion (){
            processPayloadForConversionMethodCalled = true;
            return this;
        }
        public LeadConversionRestResourceHelper.IHelper processLeadConversionError (){
            processLeadConversionErrorCalled = true;
            return this;
        }
        public LeadConversionRestResourceHelper.IHelper processDealRegistration (){
            processDealRegistrationCalled = true;
            return this;
        }
        public LeadConversionRestResourceHelper.IHelper updateConvertedAccountAsPartner(){
            updateConvertedAccountAsPartnerMethodCalled = true;
            return this;
        }
        public LeadConversionRestResourceHelper.IHelper create_PA_PR_Creation(){
            create_PA_PR_CreationMethodCalled = true;
            return this;
        }
        public void doProcessUserProvisioning(String portalProfileName){
            doProcessUserProvisioningMethodCalled = true;
        }
    }
}