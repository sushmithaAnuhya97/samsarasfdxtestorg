/**
 * Created by vikasmishra on 2021-07-06.
 */

@IsTest
private class PartnerRegistrationAutoConvServiceTest {
    @IsTest
    static void shouldTestAssignLeads() {
        LeadConversionRestResourceHelperMock thisHelperMock = new LeadConversionRestResourceHelperMock();
        PartnerRegistrationAutoConversionService.thisLCRHelper = thisHelperMock;

        PartnerRegistrationAutoConversionService.assignLeads(
                new List<PartnerRegistrationAutoConversionService.Payload>{
                        new PartnerRegistrationAutoConversionService.Payload()
                }
        );
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
                thisHelperMock.doProcessUserProvisioningMethodCalled,
                'LeadConversionRestResourceHelper.doProcessUserProvisioning method should be called'
        );
    }

    public class LeadConversionRestResourceHelperMock implements LeadConversionRestResourceHelper.IHelper{
        public Boolean setPayLoadStringMethodCalled = false;
        public Boolean processPayloadForConversionMethodCalled = false;
        public Boolean processDealRegistrationCalled = false;
        public Boolean updateConvertedAccountAsPartnerMethodCalled = false;
        public Boolean doProcessUserProvisioningMethodCalled = false;
        public LeadConversionRestResourceHelper.IHelper setPayLoadString(String payloadJson){
            setPayLoadStringMethodCalled = true;
            return this;
        }
        public LeadConversionRestResourceHelper.IHelper processPayloadForConversion (){
            processPayloadForConversionMethodCalled = true;
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
        public void doProcessUserProvisioning(String portalProfileName){
            doProcessUserProvisioningMethodCalled = true;
        }
    }
}