public with sharing class QuoteExtController {
    private Id quoteId;
    public Boolean isRenewal {get; set;} 

    public QuoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();

        SBQQ__Quote__c QuoteData = [SELECT Id,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.SBQQ__Renewal__c, SBQQ__Opportunity2__r.SBQQ__RenewedContract__c 
                                    FROM SBQQ__Quote__c 
                                    WHERE Id = :quoteId 
                                    LIMIT 1];

        isRenewal = ((QuoteData.SBQQ__Opportunity2__r?.SBQQ__Renewal__c??false) ||  (QuoteData?.SBQQ__Opportunity2__r?.SBQQ__RenewedContract__c != null));
    }

    
    public PageReference onSubmit() {
        
        try {
            if (quoteId != null) {
                SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
            }
        } 
        // Approval Enablement Package 4.0 - Catch any errors (Validation, Apex) during approval process
        catch(Exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
        
        // Approval Enablement Package 4.0 - If no error then return user to the quote page
        PageReference pr = new PageReference('/' + quoteId);
        pr.setRedirect(true);
        return pr;
    }
    
    public PageReference onRecall() {
        try {
            if (quoteId != null) {
                SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
            }
        }
        // Approval Enablement Package 4.0 - Catch any errors (Validation, Apex) during approval process
        catch(Exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
        // Approval Enablement Package 4.0 - If not error, return to quote page
        PageReference pr = new PageReference('/' + quoteId);
        pr.setRedirect(true);
        return pr;
    }
    // Approval Enablement Package 4.0 - Show a Cancel button on the page if an error occurs
    public PageReference onCancel() {
        return new PageReference('/' + quoteId);
    }
    
    
}