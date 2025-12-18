public without sharing class PCommunityCustomerLogoController {
    
    @AuraEnabled(cacheable=true)
    public static String getLogoUrlFromAccount(String partnerReferralEmail){
        try {
            return [SELECT Account.LogoURL__c FROM User WHERE Email = :partnerReferralEmail.replace(' ', '+') AND Account.IsPartner = true LIMIT 1].Account.LogoURL__c;
        } catch (Exception e) {
            System.debug('Exception: '+e.getMessage()+' / Stack trace: '+e.getStackTraceString());
            return '';
        }
    }
}