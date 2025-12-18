public with sharing class DealMapControllerExtension {

    public Integer minInt;
    public Integer maxInt;

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public DealMapControllerExtension(ApexPages.StandardController stdController) {
        this.minInt = 0;
        this.maxInt = 999999999;
    }

    public String minString{get;set;}
    public String maxString{get;set;}
    public String userId{get;set;}

    // Submit min and max values from deals map page
    public void doSubmit() {
        try {
            this.minInt = integer.valueof(minString);
        }
        catch (exception e) {
            this.minInt = 0;
        }

        try {
            this.maxInt = integer.valueof(maxString);
        }
        catch (exception e) {
            this.maxInt = 999999999;
        }
    }

    // Show map by default
    public void defaultShow() {
        System.debug('show');
        System.debug(userId);
        User user = [SELECT Id, map_default__c FROM User WHERE Id = :userId LIMIT 1];
        System.debug(user.map_default__c);
        user.map_default__c = True;
        update user;
    }

    // Hide map by default
    public void defaultHide() {
        System.debug('hide');
        System.debug(userId);
        User user = [SELECT Id, map_default__c FROM User WHERE Id = :userId LIMIT 1];
        System.debug(user.map_default__c);
        user.map_default__c = False;
        update user;
    }


    public Integer getMinInt() {
        return minInt;
    }


    public Integer getMaxInt() {
        return maxInt;
    }
}