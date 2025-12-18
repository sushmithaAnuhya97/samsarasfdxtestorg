public with sharing class createDisclaimerController {
   @AuraEnabled
    public static string getMessage(Id recordId){
        string message='';
        Credit_Report__c creditRecord=[select id,Credit_Scorecard__c from Credit_Report__c where id=:recordId ];
      
        if(creditRecord !=null && creditRecord.Credit_Scorecard__c>= 7.0){
            message='3PF is the recommended Financing option and is easily approvable with this credit grade. TCV > $150,000.00 may still require 2 years of financials.';
        }else if(creditRecord !=null && creditRecord.Credit_Scorecard__c>=3.0 && creditRecord.Credit_Scorecard__c <=6.9){
            message='3rd Party Finance is a recommended option with this credit profile. High likelihood of 3PF approval and may require additional financial information (2 years balance sheets & income statements). Directly monthly deal WILL require higher leadership approval for blended discounts.';
        }else if(creditRecord !=null && creditRecord.Credit_Scorecard__c<=2.9){
            message='Customer’s credit profile is highly distressed and showing trends of late payments. Direct Monthly and 3PF Financing WILL require BOTH Leadership approval on blended discount, and last 2 years financial statements are required: Balance Sheets & Income statements';
        }
        return message;
    }

}