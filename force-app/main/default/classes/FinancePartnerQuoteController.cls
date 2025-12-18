public without sharing class FinancePartnerQuoteController {
    public class wrapper{
        @AuraEnabled public String LegalName;
        @AuraEnabled public Decimal Tcv;
        @AuraEnabled public Decimal Term;
        @AuraEnabled public Date ExpCloseDate;
        @AuraEnabled public String Address;
        @AuraEnabled public String Duns;
        @AuraEnabled public String opportunityOwner;
    }  
    @AuraEnabled 
    public static wrapper getQuoteDetail(String QuoteID){
        Finance_Partner_Quote__c FPQ;
        account acc;
        FPQ=[Select Id,Opportunity__c,Opportunity__r.AccountId,Opportunity__r.Latest_Close_Date__c,Opportunity__r.owner.Name,Opportunity__r.License_Term__c,Opportunity__r.Balance_Due__c,Opportunity__r.Concatenated_Shipping_Address__c from Finance_Partner_Quote__c where Id=:QuoteID];
       acc=[Select Id,Name,(Select Id,DUNS_Number__c from Credit_Reports__R order by createddate desc limit 1) from account where Id=:FPQ.Opportunity__r.AccountId];
        wrapper wrp = new wrapper();
        system.debug('opppppp-'+FPQ.Opportunity__r.Balance_Due__c);
        wrp.LegalName=acc.Name;
        wrp.Tcv=FPQ.Opportunity__r.Balance_Due__c;
        wrp.ExpCloseDate=FPQ.Opportunity__r.Latest_Close_Date__c;
        wrp.Address=FPQ.Opportunity__r.Concatenated_Shipping_Address__c;
        wrp.Term=FPQ.Opportunity__r.License_Term__c;
        wrp.opportunityOwner = FPQ.Opportunity__r.Owner.Name;
        if(acc != null && acc.Credit_Reports__R != null && acc.Credit_Reports__R.size() > 0)
            wrp.Duns = acc.Credit_Reports__R[0].DUNS_Number__c;
        return wrp;


    }
    @AuraEnabled 
    public static String approvalSubmit(String QuoteID){
        try{
            if(QuoteID != null){
                Finance_Partner_Quote__c obj = new Finance_Partner_Quote__c(Id=QuoteID,Financing_Decision_Date__c=system.now(),Financing_Decision__c = 'Approved');
                update obj;
                List<Finance_Partner_Quote__c> listFPQ = [Select id,Opportunity__c,Finance_Partner__c,Partner_Contact__c from Finance_Partner_Quote__c where Id=:QuoteID];
                Opportunity opp = new Opportunity(Id=listFPQ[0].Opportunity__c,Finance_Partner__c=listFPQ[0].Finance_Partner__c,Finance_Partner_Contact__C =listFPQ[0].Partner_Contact__c);
                //Update opp;
                return 'SUCCESS';
            }
        }catch(Exception ex){
            return ex.getmessage();
        }
        return 'SUCCESS';
    }
    @AuraEnabled 
    public static String sendPOUploadEmail(String QuoteID){
    
        if(QuoteID != null){
            List<Finance_Partner_Quote__c> listFPQ = [Select id,Opportunity__c,Opportunity__r.Owner.email,Opportunity__r.Owner.managerid,Opportunity__r.Owner.manager.email,Finance_Partner__c,Partner_Contact__c from Finance_Partner_Quote__c where Id=:QuoteID];
            if(listFPQ != null && listFPQ.size() > 0){
            String toemail = listFPQ[0].Opportunity__r.Owner.email;
            String ccemail;
            if(listFPQ[0].Opportunity__r.Owner.managerId != null)
               ccemail = listFPQ[0].Opportunity__r.Owner.manager.email;
                sendEmail.sendEmailMethod('FPQ PO Upload Notification',toemail ,ccemail ,listFPQ[0].Opportunity__c);
            }    
        
        }
        return '';
    
    }
}