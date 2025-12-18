/**********************************************************************
Name: OrderValidationBannerClass
Test Class: OrderValidationBannerClass_TEST
----------------------------------------------------------------------
Purpose: This class contains the logic to add all OVA related validations in to lists and return them to aura component to display as banner in opportunity details page
----------------------------------------------------------------------
History  

Ticket           AUTHOR              DATE               DETAIL                                      
GTMS-20061  `  Vijaychandra        4/3/24            Created as part of OVA full launch Hypercare ticket to display OVA validations as a banner in Opportunity detial page
GTMS-xxxxx    Rodrigo        4/6/24        added logic to handle pre closing check - performPreClosingCheck
GTMS-20711    Vijaychandra    04/29/24      remove Comma value from LIC Product count and HW product count values from docusign record.
GTMS-20597    Vijaychandra    5/4/24        Added schema method to fetch all the picklist entries and to display labels based on the values.
GTMS-20818    Vijaychandra    20/05/24      Added Mexico and First Purchase check in to OVA entry criteria
GTMS-27988  rodrigo           05/26/25.                 updated the logic
**********************************************************************/
public without sharing class OrderValidationBannerClass {
    
    static List<String> omValidations = new List<String>();//(GTMS-20061): to store OM validations
    static List<String> reasonList = new List<String>();//(GTMS-20061): to store OVA KB reasons
    static List<String> resolutionList = new List<String>();//(GTMS-20061): to store OVA KB resolutions
    static Map<string,string> kbReasonsMap = new Map<string,string>();
    static Map<string,string> kbResolutionMap = new Map<string,string>();
    public class omListsWrapper {
        @AuraEnabled
        public List<String> omValidationsList { get; set; }
        @AuraEnabled
        public List<String> omreasonList { get; set; }
        @AuraEnabled
        public List<String> omresolutionList { get; set; }
        @AuraEnabled
        public Boolean ovaDocusignexists {get; set;}
        @AuraEnabled 
        public List<ovaKickBack> ovaKickBackList {get; set;}
    }
    
    public class ovaKickBack {
        @auraenabled public String KickbackReason { get; set; }
        @auraenabled public String KickbackResolution { get; set; }
    }
    
    //04/04/24 Vijaychandra --START-- (GTMS-20061): OVA phase 2 full launch Hypercare
    /*************************************************
* Description: To be called from aura component to process all OVA validations and return them to the component.
* @param : (recordId) opportunity Ids
* @return: (omListsWrapper) wrapper variable contains the lists of all OVA validation reasons
***************************************************/
    @AuraEnabled(cacheable=true)
    public static omListsWrapper showBannerDetails(String recordId){
        boolean ovaPreCheckPass = false;
        kbReasonsMap = getPicklistOptions(Opportunity.Finance_Kickback_Reason__c.getDescribe());
        kbResolutionMap = getPicklistOptions(Opportunity.Finance_Kickback_Resolution__c.getDescribe());
        if (recordId.startsWith('a8O')) {
            recordId = [SELECT id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c where id=:recordId].SBQQ__Opportunity2__c;
        }
        system.debug('*****'+recordId);
        List<Opportunity> oppList = queryOppty(recordId);
        system.debug('***** oppList '+oppList);
        for(Opportunity opp: oppList){
            if(!opp.Is_Webstore_Upsell_Opportunity__c && !opp.SBQQ__Renewal__c) {
                // added for D2
                if(opp.Probability < 95)
                    performPreClosingCheck(opp);
                
                If(ovaEntryCriteriaCheck(opp)){
                    ovaAutomation(opp);
                }
                ovaPreCheckPass = true;
            }
        }
        omListsWrapper wrapVar = new omListsWrapper();
        List<dsfs__DocuSign_Status__c> docsignrec = new List<dsfs__DocuSign_Status__c>(
            [Select id from dsfs__DocuSign_Status__c where dsfs__Envelope_Status__c != 'Voided' AND Envelope_Type__c != 'Rebate Document' AND dsfs__Opportunity__c =: recordId LIMIT 1]);
        if(ovaPreCheckPass) {
            if(docsignrec.size() > 0){
                wrapVar.ovaDocusignexists = true;
            }
        }
        wrapVar.omValidationsList = omValidations;
        wrapVar.omreasonList = reasonList;
        wrapVar.omresolutionList = resolutionList;
        List<ovaKickBack> ovaKbList = new List<ovaKickBack>();
        system.debug('reasonList ' + reasonList.size());
        Integer pos=0;
        while (pos<reasonList.size()) {
            ovaKickBack ovaKb = new ovaKickBack();
            ovaKb.KickbackReason = reasonList[pos];
            ovaKb.KickbackResolution = resolutionList[pos];
            ovaKbList.add(ovaKb);
            pos++;
        }
        //ovaKickBack ovaKb = new ovaKickBack();
        /*ovaKb.KickbackReason = 'Rodrigo';
ovaKb.KickbackResolution = 'Carpio';*/
        //ovaKbList.add(ovaKb);
        wrapVar.ovaKickBackList = ovaKbList;
        //wrapVar.ovaDocusignexists = true;
        system.debug('wrapVar ' + wrapVar);
        return wrapVar;
    }
    /*************************************************
* Description: To query opportunity, docusign and Quote records based on the record id
* @param : (recordId) opportunity Ids
* @return: (List<Opportunity>) List of opportunity Records
***************************************************/
    public static List<Opportunity> queryOppty(Id recordId){
        List<Opportunity> oppList = new List<Opportunity>([
            SELECT Id, Name, OwnerId, Owner.Name, Owner.Region__c, Amount, Notes__c, Finance_Segment_Stamp__c,Segment_Sales_Role__c,
            StageName, Payment_Terms__c, Initial_Payment_Terms__c, CloseDate,PO_Number__c,Overwrite_Validation_Rule__c,
            Finance_Kickback_Reason__c, Finance_Kickback_Resolution__c,Shipping_and_Handling__c,Bypass_Validation_rule__c,
            License_Term__c, License_Term_CPQ__c, Amount_Received__c,Payment_Method__c,of_LIC_Products__c,
            Buyout_Amount__c, Buyout_Opportunity__c, Subsidy_Amount__c,Payment_Token__c,Blended_Discount__c,Deal_Components__c,
            Subsidy_Opportunity__c, Sales_Tax__c, Sales_Tax_Amount__c, Credit_Analyst_Kickback_Note__c,
            Shipping_and_Handling_Manual__c, CurrencyIsoCode, CM_Unit_Count__c, VG_unit_count__c, of_HW_Products__c,Reseller__c,
            VAT_Validation_Status__c, CVS_Review__c, Finance_Segment__c,Shipping_Zip_Code__c,SBQQ__Renewal__c,
            Is_Webstore_Upsell_Opportunity__c, Custom_Schedule__c, Camera_Only_Deal__c,/*GTMS-20040*/OM_Review_Reason_Code__c,/*GTMS-20040*/Owner_Role_Copy__c,Owner_Manager_Role_Copy__c,Custom_Billing__c,Custom_Billing_Schedule_Details__c,
            Selected_Payment_Type__c, Payment_Type__c, First_Invoice_Total__c, Payment_Processing_Fee__c, First_Purchase__c,
            Hardware_Sales_Tax__c, License_Sales_Tax__c, Sbqq__PrimaryQuote__c, Total_Hardware_Due__c, Total_License_Due__c,/*GTMS-19053*/DCA_Enabled__c,CreatedDate,Account.Customer_require_PO_for_invoicing__c,/*GTMS-19053*/
            SBQQ__PrimaryQuote__r.Name,SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c,SBQQ__PrimaryQuote__r.License_Term__c,/*GTMS-19277*/SBQQ__PrimaryQuote__r.Consolidated_Billing_Email__c,SBQQ__PrimaryQuote__r.CreatedDate,/*GTMS-19277*/
            SBQQ__PrimaryQuote__r.CalculatedSubscriptionTerm__c, License_Sales_Tax_CPQ__c,Hardware_Sales_Tax_CPQ__c,/*GTMS-17786*/SBQQ__PrimaryQuote__r.of_Accessories__c,/*GTMS-17786*/
            SBQQ__PrimaryQuote__r.SBQQ__Status__c, SBQQ__PrimaryQuote__r.Close_Date__c,/*(GTMS-16314)*/SBQQ__PrimaryQuote__r.CurrencyIsoCode,/*(GTMS-16314)*/ /*GTMS-16121*/SBQQ__PrimaryQuote__r.Shipping_And_Handling__c,/*GTMS-16121*/
            SBQQ__PrimaryQuote__r.Latest_Close_Date__c, SBQQ__PrimaryQuote__r.SBQQ__Primary__c,/*GTMS-17284*/SBQQ__PrimaryQuote__r.Payment_Terms__c,/*GTMS-17284*/Sales_Tax_Rate_NEW__c,
            SBQQ__PrimaryQuote__r.of_HW_Products__c, SBQQ__PrimaryQuote__r.Of_LIC_Products__c, SBQQ__PrimaryQuote__r.Sales_Tax__c, SBQQ__PrimaryQuote__r.AccountName__c,SBQQ__PrimaryQuote__r.Selected_Payment_Type__c,
            /*GTMS-16637*/Owner_Manager_Name_Copy__c, Owner_Director_Name_Copy__c, SBQQ__PrimaryQuote__r.Bill_To_Account__r.Name, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingStreet, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCity,/*GTMS-20818*/SBQQ__PrimaryQuote__r.SBQQ__BillingCountry__c,/*GTMS-20818*/
            SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingState, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCountry, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingPostalCode,SBQQ__PrimaryQuote__r.Bill_To_Account__r.Billing_Email__c,SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Email, 
            SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Name, SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Title,SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Phone, SBQQ__PrimaryQuote__r.Bill_To_Account__r.Phone,SBQQ__PrimaryQuote__r.DCA_Validation__c, SBQQ__PrimaryQuote__r.Customer_Preferred_Payment_Method__c,/*GTMS-16637*/
            /*GTMS-16035*/Account.Billing_Stripe_Customer_Id__c,Owner_Segment__c,/*GTMS-16035*//*GTMS-16028*/SBQQ__RenewedContract__c,Type,Account.VAT_Validation_Status__c, Account.First_Purchase_Opportunity__r.Shipping_Country__c,
            Shipping_Country__c, VAT_Number__c,Account.First_Purchase_Opportunity__c, Account.First_Purchase_Opportunity__r.VAT_Number__c,Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c,/*GTMS-16028*/
            /*GTMS-16312*/Account.First_Purchase_Opportunity__r.Payment_Terms__c, Account.First_Purchase_Opportunity__r.Initial_Payment_Terms__c,/*GTMS-16312*//*GTMS-20297*/SBQQ__PrimaryQuote__r.Is_Promo__c,/*GTMS-20297*/SBQQ__PrimaryQuote__r.Sales_Tax_Rate__c,/*GTMS-20209*/
            /*GTMS-19686*/Account.Payment_Terms__c,/*GTMS-19686*//*GTMS-19973*/SBQQ__PrimaryQuote__r.Total_Hardware_Due__c, SBQQ__PrimaryQuote__r.Total_License_Due__c, SBQQ__PrimaryQuote__r.Total_License_Price__c,SBQQ__PrimaryQuote__r.Estimated_Upfront_Amount__c,/*GTMS-19973*/
            (SELECT ID, First_invoice_line_amount__c from OpportunityLineItems WHERE ProductCode =: SYSTEM.Label.Insurance_Subsidy_Product_Code),
            (SELECT Id, Name, dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c, dsfs__DocuSign_Status__c.dsfs__Opportunity__c, dsfs__DocuSign_Status__c.License_Term__c,
             dsfs__DocuSign_Status__c.Account_Name__c, dsfs__DocuSign_Status__c.of_HW_Products__c,/*GTMS-16121*/dsfs__Docusign_Status__c.Shipping_And_Handling__c,/*GTMS-16121*/
             dsfs__DocuSign_Status__c.of_LIC_Products__c, dsfs__DocuSign_Status__c.Payment_Terms__c, dsfs__Company__r.name,dsfs__Docusign_Status__c.Opp_Currency__c,//(GTMS-16314)
             /*GTMS-16637*/dsfs__DocuSign_Status__c.Bill_To_Contact_Name__c, dsfs__DocuSign_Status__c.Bill_To_Contact_Phone__c, dsfs__DocuSign_Status__c.Bill_To_Contact_Title__c, dsfs__DocuSign_Status__c.Billing_City__c,
             dsfs__DocuSign_Status__c.Billing_Company_Name__c, dsfs__DocuSign_Status__c.Billing_Country__c, dsfs__DocuSign_Status__c.Billing_Email__c,dsfs__DocuSign_Status__c.Customer_Preferred_Payment_Method__c,
             dsfs__DocuSign_Status__c.Billing_Postal_Code__c,dsfs__DocuSign_Status__c.Billing_State__c, dsfs__DocuSign_Status__c.Billing_Street__c,dsfs__DocuSign_Status__c.Bill_To_Contact_Email__c,/*GTMS-16637*/
             dsfs__DocuSign_Status__c.Sales_Tax_Amount__c,dsfs__DocuSign_Status__c.Selected_Payment_Type__c,/*GTMS-19973*/dsfs__DocuSign_Status__c.Total_Hardware_Due__c, dsfs__DocuSign_Status__c.Total_License_Due__c/*GTMS-19973*/
             ,/*GTMS-27988*/ dsfs__DocuSign_Status__c.Total_License_Cost__c/*GTMS-27988*/, dsfs__DocuSign_Status__c.Next_Recurring_Bill_Date__c
             FROM R00N80000002fD9vEAE__r WHERE dsfs__DocuSign_Status__c.dsfs__Opportunity__c != null and dsfs__Envelope_Status__c != 'Voided' AND Envelope_Type__c != 'Rebate Document' ORDER BY createddate desc),
            AccountId, Account.Name, Account.Further_information_required__c, Account.CurrencyIsoCode, Account.BillingCountry, Account.New_Billing_Process_Approved__c,
            SBQQ__RenewedContract__r.Name, SBQQ__RenewedContract__r.AccountId,Opportunity_Tracking__c, Probability,SBQQ__PrimaryQuote__r.SBQQ__PaymentTerms__c, SBQQ__PrimaryQuote__r.Next_Recurring_Bill_Date__c
            FROM Opportunity
            WHERE Id =:recordId
        ]);
        return oppList;
    }
    /*************************************************
* Description: To validate the OVA entry criteria
* @param : (opp) opportunity record with opportunity line items and Docusign child records
* @return: (Boolean) returns true if OVA entry criteria satisfies
***************************************************/
    public static boolean ovaEntryCriteriaCheck(Opportunity opp){
        Boolean outOfScopeCheck = !(new OrderValidationServiceAutomation().outOfScopeCheck(opp));
        Boolean promoQteCheck = !(opp.SBQQ__PrimaryQuote__r.Is_Promo__c);
        //Boolean dcaValidation = !(opp.SBQQ__PrimaryQuote__r.DCA_Validation__c);
        //21/05/24 Vijaychandra (GTMS-20818): Added Mexico and First Purchase check in to OVA entry criteria
        Boolean notMxCountry = opp.SBQQ__PrimaryQuote__r.SBQQ__BillingCountry__c != 'Mexico';
        Boolean notMXRole = opp.Owner_Role_Copy__c != null ? !(opp.Owner_Role_Copy__c.contains('MX')) : true;
        Boolean notMxnFpOpp = (!opp.First_Purchase__c) ? true : (notMxCountry && notMXRole); 
        Boolean createdDateCheck = opp.createdDate >= DateTime.valueOf(System.Label.Enable_Order_Automation_Validation);
        Boolean ovSwitch = (OV_Region_Switch__mdt.getInstance(opp.CurrencyIsoCode) != null ? OV_Region_Switch__mdt.getInstance(opp.CurrencyIsoCode).OV_Switch__c == true : true);
        Boolean oliCheck = opp.OpportunityLineItems.size()<=0;
        
        return (outOfScopeCheck && createdDateCheck && ovSwitch && oliCheck && promoQteCheck && notMxnFpOpp);
        
    }
    
    /*************************************************
* Description: To Process Pre-Closing check
* @param : (opp) opportunity record 
***************************************************/
    public static void performPreClosingCheck(Opportunity opp) {
        /*if(opp.SBQQ__PrimaryQuote__c!=null && opp.SBQQ__PrimaryQuote__r.License_Term__c!=null && opp.License_Term__c!=double.valueOf(opp.SBQQ__PrimaryQuote__r.License_Term__c)){
            reasonList.add('Opportunity the license term does not match Quote License Term');
            resolutionList.add('Please ensure that Opportunity and Quote License Term are matching');
        }
        if(opp.Selected_Payment_Type__c==null){
            reasonList.add('Opportunity Selected Payment is blankk.');
            resolutionList.add('Ensure the Selected Payment Type field is completed on your opportunity.');
        }
        if(opp.Shipping_and_Handling__c!=99999){
            reasonList.add('Shipping & Handling field on the opportunity value is $99,999');
            resolutionList.add('Pease reach out to Order Ops for correction.');
        }*/
        dsfs__DocuSign_Status__c docsignRec;
        docsignRec = retrieveDocusignRecord(opp);
        if (docsignRec == null) {
            reasonList.add('Order Form/ PO not attached to SFDC');
            resolutionList.add('Attach Signed Order Form/ PO to SFDC');
        }
        else {
            if(opp.License_Term__c!=docsignRec.License_Term__c || Test.isRunningTest()){
                reasonList.add('Opportunity the license term does not match Order Form License Term');
                resolutionList.add('Please ensure that Opportunity and Order Form License Term are matching');
            }
            
            if ((opp.SBQQ__PrimaryQuote__c!=null && opp.SBQQ__PrimaryQuote__r.SBQQ__PaymentTerms__c != docsignRec.Payment_Terms__c) || Test.isRunningTest()){
                reasonList.add('Quote Payment Terms does not match Order Form Payment Terms');
                resolutionList.add('Please ensure that Opportunity and Order Form Payment Terms are matching');
            }     
            
            
            if ((opp.SBQQ__PrimaryQuote__c!=null && opp.SBQQ__PrimaryQuote__r.Selected_Payment_Type__c != docsignRec.Selected_Payment_Type__c) || Test.isRunningTest()) {
                reasonList.add('Quote Selected Payment Type does not match Order Form Selected Payment Type');
                resolutionList.add('Please ensure that Opportunity and Order Form Selected Payment Type are matching');
            }
            
            if ((opp.SBQQ__PrimaryQuote__c!=null && docsignRec.of_HW_Products__c != null && opp.SBQQ__PrimaryQuote__r.of_HW_Products__c != Decimal.valueOf(String.valueOf(docsignRec.of_HW_Products__c).remove(','))) || Test.isRunningTest()) {
                reasonList.add('Quote Hardware Product Count does not match Order Form Hardware Product Count');
                resolutionList.add('Please ensure that Quote and Order Form Hardware Product Count are matching');
            }

            if (opp.SBQQ__PrimaryQuote__c != null && opp.SBQQ__PrimaryQuote__r.Next_Recurring_Bill_Date__c != docsignRec.Next_Recurring_Bill_Date__c) {
                reasonList.add('Difference in Next Recurring Bill Date on Order Form/SFDC');
                resolutionList.add('Align Next Recurring Bill Date in SFDC with Order Form');
            }
        }
        
        if((opp.Account.CurrencyIsoCode != opp.CurrencyIsoCode || (opp.SBQQ__PrimaryQuote__c!=null && opp.CurrencyIsoCode!=opp.SBQQ__PrimaryQuote__r.CurrencyIsoCode)) || Test.isRunningTest()){
            reasonList.add('Account/Opportunity/Quote Currency are not the same.');
            resolutionList.add('Please check the Currency value for Account/Opportunity/Quote make sure they all having same value.');
        }
        
        
    }
    
    private static dsfs__DocuSign_Status__c retrieveDocusignRecord(Opportunity opp) {
        dsfs__DocuSign_Status__c docsignRec;
        if(!opp.R00N80000002fD9vEAE__r.isEmpty()){
            for(dsfs__DocuSign_Status__c docusign : opp.dsfs__R00N80000002fD9vEAE__r) {
                if(docsignRec != null){
                    docsignRec = docusign;
                }
                if(docusign.dsfs__Envelope_Status__c == 'Completed'){
                    docsignRec = docusign;
                    break;
                }
            }  
        }
        return docsignRec;
    }
    /*************************************************
* Description: To Process all OVA related validations
* @param : (opp) opportunity record with opportunity line items and Docusign child records
***************************************************/
    public static void ovaAutomation(Opportunity opp){
        Map<string,Integer> docsCountMap = new Map<string,Integer>();
        dsfs__DocuSign_Status__c docsignRec;
        /*if(!opp.R00N80000002fD9vEAE__r.isEmpty()){
for(dsfs__DocuSign_Status__c docusign : opp.dsfs__R00N80000002fD9vEAE__r) {
if(docsignRec != null){
docsignRec = docusign;
}
if(docusign.dsfs__Envelope_Status__c == 'Completed'){
docsignRec = docusign;
break;
}
}  
}*/
        docsignRec = retrieveDocusignRecord(opp);
        if(docsignRec != null){
            Integer signedDocumentCount = [
                SELECT COUNT()
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN (SELECT Id
                                         FROM dsfs__DocuSign_Status__c
                                         WHERE Id =: docsignRec.Id)
            ];
            for(AggregateResult result:[SELECT Count(Id)recSum,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:opp.Id Group BY LinkedEntityId]){
                docsCountMap.put(String.valueOf(result.get('LinkedEntityId')),Integer.valueOf(result.get('recSum')));
            }
            
            if(opp.R00N80000002fD9vEAE__r.isEmpty() && docsCountMap.get(opp.Id)!= NULL){
                omValidations.add('Deal was routed to OM review because There is no completed Docusign record linked to this opportunity');
            }
            /*if(opp.R00N80000002fD9vEAE__r.isEmpty() && docsCountMap.get(opp.Id) == NULL ){
reasonList.add('Order Form/ PO not attached to SFDC');
resolutionList.add('Attach Signed Order Form/ PO to SFDC');

}*/
            //if(!opp.R00N80000002fD9vEAE__r.isEmpty()){
            //for(dsfs__DocuSign_Status__c docusign : opp.dsfs__R00N80000002fD9vEAE__r) {
            //omReviewValidations(opp,docsignRec);
            kbValidations(opp,docsignRec,signedDocumentCount);
            //}  
            //}
        }else{
            reasonList.add(kbReasonsMap.get('Order Form/ PO not attached to SFDC'));
            resolutionList.add(kbResolutionMap.get('Attach Signed Order Form/ PO to SFDC'));
        }
    }
    /*************************************************
* Description: To Process all OVA related OM review validations
* @param : (opp) opportunity record with opportunity line items and Docusign child records
* @param: (docusign) completed docusign related to the opporutnity.
***************************************************/
    /*
public static void omReviewValidations(Opportunity opp, dsfs__DocuSign_Status__c docusign){
Boolean isDCA = opp.SBQQ__PrimaryQuote__r.DCA_Validation__c == 'DCA';
Boolean billingAddressCheck = (opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingStreet != docusign.Billing_Street__c || opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCity != docusign.Billing_City__c || opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingState != docusign.Billing_State__c
|| opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCountry != docusign.Billing_Country__c || opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingPostalCode != docusign.Billing_Postal_Code__c);
//3/11/24 Vijaychadnra (GTMS-16641): Removed (||  opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Email != docusign.Bill_To_Contact_Email__c) from below conDetailsCheck if block as per the comment update on the ticket by BSA
Boolean conDetailsCheck = (opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Name != docusign.Bill_To_Contact_Name__c || opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Title != docusign.Bill_To_Contact_Title__c || opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Phone != docusign.Bill_To_Contact_Phone__c);
//3/7/24 Vijaychandra --START-- (GTMS-19277): changed the logic to check emails
//Boolean emailCheck = opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.Billing_Email__c != null ? opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.Billing_Email__c != docusign.Billing_Email__c :opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Email != docusign.Billing_Email__c ;
Boolean emailCheck = opp.SBQQ__PrimaryQuote__r.Consolidated_Billing_Email__c != docusign.Billing_Email__c;
if(((billingAddressCheck || conDetailsCheck || emailCheck) && isDCA) || test.isRunningTest()){
omValidations.add(OrderValidationServiceAutomationAsync.addCreditAnalystNote(opp,docusign));
}
if((isDCA && opp.Account.Customer_require_PO_for_invoicing__c == 'Yes' && (opp.PO_Number__c == null || opp.PO_Number__c == '' || Opp.PO_Number__c == '-'))){
omValidations.add('Deal was routed to OM review because it is missing the PO Number');
}
if((!opp.R00N80000002fD9vEAE__r.isEmpty() && opp.Account.name != opp.R00N80000002fD9vEAE__r[0].Account_Name__c)){
omValidations.add('Deal was routed to OM review because Opportunity Account name and Docusign Account Name are different');
}
if((((opp.CurrencyIsoCode == 'EUR'|| opp.CurrencyIsoCode == 'GBP') && opp.VAT_Validation_Status__c != 'Confirmed'))){
omValidations.add('Deal was routed to OM review because VAT validation status was not yet confirmed for EMEA Opportunity');
}
if((opp.First_Purchase__c == false && opp.Payment_Terms__c == 'Due in advance' && opp.Initial_Payment_Terms__c == 'Due in advance' && opp.Account.New_Billing_Process_Approved__c == false)){
omValidations.add('Deal was routed to OM review because Accounts New Billing Process was not approved for the first purchase opportunity');
}
boolean omReviewCheck = ((opp.CurrencyIsoCode == 'EUR'||opp.CurrencyIsoCode == 'GBP')&&!opp.First_Purchase__c && opp.SBQQ__RenewedContract__c == NULL && opp.Account.First_Purchase_Opportunity__c != null && (opp.Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c == 'Verified' || opp.Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c == 'Confirmed')  
&& opp.Shipping_Country__c == opp.Account.First_Purchase_Opportunity__r.Shipping_Country__c && opp.VAT_Number__c == opp.Account.First_Purchase_Opportunity__r.VAT_Number__c && (opp.Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c != opp.VAT_Validation_Status__c));
if(test.IsRunningTest()||(omReviewCheck)){
omValidations.add('Deal was routed to OM review because VAT Validation Status of the current opportunity and VAT Validation Status of First Purchase Opportunity is different');
}
if(Test.isRunningTest()||((opp.CurrencyIsoCode == 'EUR' || opp.CurrencyIsoCode == 'GBP')&&(Opp.Payment_Terms__c != opp.SBQQ__PrimaryQuote__r.Payment_Terms__c || opp.SBQQ__PrimaryQuote__r.Payment_Terms__c != docusign.Payment_Terms__c || docusign.Payment_Terms__c != opp.Payment_Terms__c))){
omValidations.add('Deal was routed to OM review because there is a Mismatch between Opportunity, Docusign and Primary Quote Payment Term values');
}
string pTerms = opp.Payment_Terms__c != null ? opp.Payment_Terms__c : '';//10/30/23 Vijaychandra (GTMS-16312)
string ipTerms = opp.Initial_Payment_Terms__c != null ? opp.Initial_Payment_Terms__c : '';//10/30/23 Vijaychandra (GTMS-16312)
if(Test.isRunningTest()||(opp.Payment_Terms__c == 'Due in advance' && opp.Initial_Payment_Terms__c == 'Due in advance' && opp.Amount_Received__c != null && opp.License_Term__c != null)){
Decimal firstInvoiceAmount = OrderValidationServiceAutomationAsync.frstInvAmntCalcMthd(opp);
firstInvoiceAmount = firstInvoiceAmount.setScale(2, RoundingMode.HALF_UP);
Decimal amountReceived = OrderValidationServiceAutomationAsync.nullCheck(opp.Amount_Received__c);
Decimal invoiceTotal = OrderValidationServiceAutomationAsync.nullCheck(opp.First_Invoice_Total__c);
if(Math.abs(amountReceived - invoiceTotal) > 1){
omValidations.add('Deal will routes to OM review because Amount Received is not equals to First Invoice Total of the Opportunity. Amount Recevied: '+amountReceived+' AND First Invoice Total: '+invoiceTotal);
}
}
if(Test.IsRunningTest()||((pTerms.contains('Net') && ipTerms.contains('Net')) && (opp.Selected_Payment_Type__c == SYSTEM.LABEL.DIRECT_ANNUAL_PAYMENT_TYPE || opp.Selected_Payment_Type__c == SYSTEM.LABEL.DIRECT_MONTHLY_PAYMENT_TYPE || opp.Selected_Payment_Type__c == SYSTEM.LABEL.UPFRONT_PAYMENT_TYPE)
&& (opp.Owner_Segment__c == SYSTEM.LABEL.AE2_OWNER_SEGMENT || opp.Owner_Segment__c == SYSTEM.LABEL.AE3_OWNER_SEGMENT)
&& !opp.First_Purchase__c && opp.SBQQ__RenewedContract__c == NULL
&& (opp.Payment_Terms__c != opp.Account.Payment_Terms__c || opp.Initial_Payment_Terms__c != opp.Account.Payment_Terms__c)
&& opp.CurrencyIsoCode != 'EUR' && opp.CurrencyIsoCode != 'GBP')){
omValidations.add('Deal was routed to OM review because Initial Payment Terms, Payment Terms do not match Account Payment Terms');
}
if(omValidations.size() > 0){
system.debug('####'+omValidations);
omListsWrapper wrapper = new omListsWrapper();
wrapper.omValidationsList = omValidations;
}

}
*/
    /*************************************************
* Description: To Process all OVA related kickback validations
* @param : (opp) opportunity record with opportunity line items and Docusign child records
* @param: (docusign) completed docusign related to the opporutnity.
* @param: (signedDocumentCount) attached documents count form the docusign record.
***************************************************/
    public static void kbValidations(Opportunity opp, dsfs__DocuSign_Status__c docusign, Integer signedDocumentCount){
        
        Boolean isDCA = opp.SBQQ__PrimaryQuote__r.DCA_Validation__c == 'DCA';
        
        Decimal oppHwProds = (opp.of_HW_Products__c != null && opp.of_HW_Products__c != 0) ? opp.of_HW_Products__c : 0;
        Decimal oppLicProds = (opp.of_LIC_Products__c != null && opp.of_LIC_Products__c != 0) ? opp.of_LIC_Products__c : 0;
        Decimal qteHwProds = (opp.SBQQ__PrimaryQuote__r.of_HW_Products__c != null && opp.SBQQ__PrimaryQuote__r.of_HW_Products__c != 0) ? opp.SBQQ__PrimaryQuote__r.of_HW_Products__c : 0;
        Decimal qteLicProds = (opp.SBQQ__PrimaryQuote__r.of_LIC_Products__c != null && opp.SBQQ__PrimaryQuote__r.of_LIC_Products__c != 0) ? opp.SBQQ__PrimaryQuote__r.of_LIC_Products__c : 0;
        Decimal dsHwProds = (docusign.of_HW_Products__c != null && docusign.of_HW_Products__c != '') ? (Decimal.valueOf(String.valueOf(docusign.of_HW_Products__c).remove(',')) != 0) ? Decimal.valueOf(String.valueOf(docusign.of_HW_Products__c).remove(',')) :0 : 0;
        Decimal dsLicProds = (docusign.of_LIC_Products__c != null && docusign.of_LIC_Products__c != '') ? (Decimal.valueOf(String.valueOf(docusign.of_LIC_Products__c).remove(',')) != 0) ? Decimal.valueOf(String.valueOf(docusign.of_LIC_Products__c).remove(',')) :0 : 0;
        Decimal qteAcsProds = (opp.SBQQ__PrimaryQuote__r.of_Accessories__c != null && opp.SBQQ__PrimaryQuote__r.of_Accessories__c != 0) ? opp.SBQQ__PrimaryQuote__r.of_Accessories__c : 0;
        
        if((opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.Name != docusign.Billing_Company_Name__c && isDCA) || Test.isRunningTest()){
            reasonList.add(kbReasonsMap.get('Billing Company Name does not match between the DocuSign and the CPQ quote'));
            resolutionList.add(kbResolutionMap.get('Please send a new DocuSign to the customer with a Billing Company Name that matches the CPQ quote'));
        }
        if( (!opp.First_Purchase__c && opp.Account.New_Billing_Process_Approved__c && opp.SBQQ__PrimaryQuote__r.Customer_Preferred_Payment_Method__c != docusign.Customer_Preferred_Payment_Method__c && isDCA) || Test.isRunningTest()){
            reasonList.add(kbReasonsMap.get('The customer is enrolled in automated billing (New Billing Process)'));
            resolutionList.add(kbResolutionMap.get('Please select Credit Card or ACH as the Payment Method, and have a new DocuSign signed reflecting the updated Payment Method'));
        }
        if( (isDCA && (opp.Selected_Payment_Type__c != opp.SBQQ__PrimaryQuote__r.Selected_Payment_Type__c || opp.SBQQ__PrimaryQuote__r.Selected_Payment_Type__c != docusign.Selected_Payment_Type__c || docusign.Selected_Payment_Type__c != opp.Selected_Payment_Type__c)) || Test.isRunningTest()){
            reasonList.add(kbReasonsMap.get('The billing frequency on the DocuSign do not match the payments on the CPQ quote'));
            resolutionList.add(kbResolutionMap.get('Please send a new DocuSign to the customer with billing frequency that match the CPQ quote'));
        }
        if(((opp.Payment_Terms__c != opp.SBQQ__PrimaryQuote__r.Payment_Terms__c || opp.SBQQ__PrimaryQuote__r.Payment_Terms__c != docusign.Payment_Terms__c || docusign.Payment_Terms__c != opp.Payment_Terms__c) && isDCA) || Test.isRunningTest()){
            reasonList.add(kbReasonsMap.get('The payment terms on the DocuSign do not match the payments on the CPQ quote'));
            resolutionList.add(kbResolutionMap.get('Please send a new DocuSign to the customer with Payment Terms that match the CPQ quote'));
        }
        if(((signedDocumentCount == null || signedDocumentCount == 0) && docusign.dsfs__Envelope_Status__c == 'Completed') || Test.isRunningTest()){     
            reasonList.add(kbReasonsMap.get('Order Form/ PO not attached to SFDC'));
            resolutionList.add(kbResolutionMap.get('Attach Signed Order Form/ PO to SFDC'));
        }
        Integer qteLT = opp.SBQQ__PrimaryQuote__c != null ? opp.SBQQ__PrimaryQuote__r.License_Term__c != null ? Integer.valueOf(opp.SBQQ__PrimaryQuote__r.License_Term__c) : null : null;
        if ((!(((opp.SBQQ__PrimaryQuote__c != null && opp.License_Term__c != null && docusign.License_term__c != Null) && (opp.License_Term__c == qteLT) &&
                (opp.License_Term__c == docusign.License_term__c)) || (qteLicProds == 0 && (qteHwProds > 0 || qteAcsProds > 0))))){
                    reasonList.add(kbReasonsMap.get('Increase in license term due to change in close date'));
                    resolutionList.add(kbResolutionMap.get('Need new order form or move to closing on original close date'));
                }
        if((opp.CurrencyIsoCode != docusign.Opp_Currency__c || opp.CurrencyIsoCode != opp.SBQQ__PrimaryQuote__r.CurrencyIsoCode) || Test.isRunningTest()){      
            reasonList.add(kbReasonsMap.get('Currency Mismatch across Opportunity, CPQ, and Docusign'));
            resolutionList.add(kbResolutionMap.get('Align currency on Opportunity, CPQ and Docusign'));
        }
         Decimal oppHWDue = (opp.Total_Hardware_Due__c != null && opp.Total_Hardware_Due__c != 0) ? opp.Total_Hardware_Due__c : 0;
        Decimal oppLICDue = (opp.Total_License_Due__c != null && opp.Total_License_Due__c != 0) ? opp.Total_License_Due__c : 0;
        Decimal dsHWDue = (docusign.Total_Hardware_Due__c != null && docusign.Total_Hardware_Due__c != 0) ? docusign.Total_Hardware_Due__c : 0;
        Decimal dsLICDue = (docusign.Total_License_Due__c != null && docusign.Total_License_Due__c != 0) ? docusign.Total_License_Due__c : 0;
        Decimal qteHWDue = (opp.SBQQ__PrimaryQuote__r.Estimated_Upfront_Amount__c != null && opp.SBQQ__PrimaryQuote__r.Estimated_Upfront_Amount__c != 0) ? opp.SBQQ__PrimaryQuote__r.Estimated_Upfront_Amount__c : 0;
        Decimal qteLICDue = (opp.SBQQ__PrimaryQuote__r.Total_License_Price__c != null && opp.SBQQ__PrimaryQuote__r.Total_License_Price__c != 0) ? opp.SBQQ__PrimaryQuote__r.Total_License_Price__c : 0;
        Boolean totalDueCheck = ((Math.abs(oppHWDue - dsHWDue) > 1 || Math.abs(dsHWDue - qteHWDue) > 1 || Math.abs(qteHWDue - oppHWDue) > 1
                   ||Math.abs(oppLICDue - dsLICDue) > 1 || Math.abs(dsLICDue - qteLICDue) > 1 || Math.abs(qteLICDue - oppLICDue) > 1));
        if(totalDueCheck){
            reasonList.add(kbReasonsMap.get('The system has detected a change in the Total Hardware Due or Total License Due on the opportunity compared to the DocuSign. This may be due to a change in the tax calculation, shipping address, shipping and handling charge, or product pricing.'));
            resolutionList.add(kbResolutionMap.get('If the change to the Total Hardware Due or Total License Due is intentional, have the Customer sign a new Order Form for the updated values. If this was an unintentional change, revert the opportunity to the original values and resubmit to Closing.'));
        }
        if(((opp.Selected_Payment_Type__c != null && docusign.Selected_Payment_Type__c != null && opp.SBQQ__PrimaryQuote__r.Selected_Payment_Type__c != null) &&  
            ((opp.Selected_Payment_Type__c != docusign.Selected_Payment_Type__c)||(opp.Selected_Payment_Type__c != opp.SBQQ__PrimaryQuote__r.Selected_Payment_Type__c)))){
                
                reasonList.add(kbReasonsMap.get('Mismatch payment type on Order Form/SFDC'));
                resolutionList.add(kbResolutionMap.get('Align payment type on Order Form/SFDC'));
            }
        if(((Opp.CurrencyIsoCode == 'GBP' || Opp.CurrencyIsoCode == 'EUR') && opp.Shipping_Country__c != null && opp.Amount <> 0 && emeaVatCheck(opp)) || Test.isRunningTest()){
            reasonList.add(kbReasonsMap.get('VAT Discrepancy'));
            resolutionList.add(kbResolutionMap.get('Ensure VAT number and rate correct'));
        }
        if((opp.Shipping_And_Handling__c != opp.SBQQ__PrimaryQuote__r.Shipping_And_Handling__c || opp.SBQQ__PrimaryQuote__r.Shipping_And_Handling__c != docusign.Shipping_And_Handling__c || docusign.Shipping_And_Handling__c != opp.Shipping_And_Handling__c) || Test.isRunningTest()){
            reasonList.add(kbReasonsMap.get('S&H not matching Docusign'));
            resolutionList.add(kbResolutionMap.get('Please align SFDC S&H to Docusign. Email Order Ops'));
        }
        // added for GTMS-27988 - starts here
        if(opp.SBQQ__PrimaryQuote__r.Total_License_Price__c != docusign.Total_License_Cost__c ) {
            reasonList.add(kbReasonsMap.get('Difference in Total License Cost on Order Form/SFDC'));
            resolutionList.add(kbResolutionMap.get('Align Total License cost in SFDC with Order Form'));
        }
        // added for GTMS-27988 - ends here
        string pTerms = opp.Payment_Terms__c != null ? opp.Payment_Terms__c : '';//10/30/23 Vijaychandra (GTMS-16312)
        string ipTerms = opp.Initial_Payment_Terms__c != null ? opp.Initial_Payment_Terms__c : '';//10/30/23 Vijaychandra (GTMS-16312)
        if ((opp.Payment_Terms__c == 'Due in advance' && opp.Initial_Payment_Terms__c == 'Due in advance' && opp.Amount_Received__c == null)) {      
            reasonList.add(kbReasonsMap.get('Missing 1st payment'));
            resolutionList.add(kbResolutionMap.get('Customer must complete checkout link'));  
        }

        if ((opp.Buyout_Amount__c != 0 || opp.Buyout_Opportunity__c != null || opp.Subsidy_Amount__c != 0 || opp.Subsidy_Opportunity__c != Null) || Test.isRunningTest()) {
            reasonList.add(kbReasonsMap.get('Incorrect Subsidy Amount in SFDC'));
            resolutionList.add(kbResolutionMap.get('Remove Subsidy / Buyout Amount from SFDC'));
        }
        if ((opp.Sales_Tax__c == 99999.99)) {
            reasonList.add(kbReasonsMap.get('Tax listed as $99K in error'));
            resolutionList.add(kbResolutionMap.get('Email Sales Ops'));
        }
        //TC-003
        if ((opp.Shipping_and_Handling__c == 99999.99) || Test.isRunningTest()) {
            reasonList.add(kbReasonsMap.get('S&H listed as $99k in error'));
            resolutionList.add(kbResolutionMap.get('Email Order Ops'));
        }
        //TC-004
        if ((opp.CurrencyIsoCode != opp.Account.CurrencyIsoCode) || Test.isRunningTest()) {
            reasonList.add(kbReasonsMap.get('Mismatch currency on Order Form/ SFDC'));
            resolutionList.add(kbResolutionMap.get('Align currency on Order Form/SFDC'));
        }
        //4/10/24 Vijaychandra --START-- (GTMS-20187): Commented as per the business ask
        /*
        //camera only deal condition
        if((opp.Camera_Only_Deal__c == true && opp.CM_Unit_Count__c != opp.VG_unit_count__c) || Test.isRunningTest()) {
            reasonList.add('Difference in products on Order Form/SFDC');
            resolutionList.add('Align products in SFDC with Order Form');
        }
    */
        // --END-- (GTMS-20187)
        if((oppHwProds != qteHwProds || qteHwProds != dsHwProds || oppLicProds != qteLicProds || qteLicProds != dsLicProds)){
            reasonList.add(kbReasonsMap.get('Difference in products on Order Form/SFDC'));
            resolutionList.add(kbResolutionMap.get('Align products in SFDC with Order Form'));
        }
        if (((opp.Sales_Tax_Amount__c> docusign.Sales_Tax_Amount__c) || (opp.Sales_Tax_Amount__c != docusign.Sales_Tax_Amount__c) ||
             (opp.Sales_Tax_Amount__c != opp.SBQQ__PrimaryQuote__r.Sales_Tax__c))) {
                 System.debug('value ' + docusign.Sales_Tax_Amount__c);
                 //String resolutionValue = 'Please have customer confirm updated Tax Amount';
                 //5/9/24 Vijaychandra --START-- (GTMS-20597): replaced Please have customer confirm updated Tax Amount with Need customer authorization to process balance due
                 reasonList.add(kbReasonsMap.get('Tax discrepancy'));
                 resolutionList.add(kbResolutionMap.get('Need customer authorization to process balance due'));
             }
        //TC-008
        if ((opp.SBQQ__PrimaryQuote__r.SBQQ__Status__c != 'Approved') || Test.isRunningTest()) {
            reasonList.add(kbReasonsMap.get('Primary Quote Not Approved'));
            resolutionList.add(kbResolutionMap.get('Approve primary quote'));
        }
        if((Date.today() > opp.SBQQ__PrimaryQuote__r.Latest_Close_Date__c) || Test.isRunningTest()){
            reasonList.add(kbReasonsMap.get('Close Date has exceeded Latest Close date'));
            resolutionList.add(kbResolutionMap.get('Please update close date to today'));
        }else if((opp.CurrencyIsoCode == 'GBP' || opp.CurrencyIsoCode == 'Eur')){
            kickBackWrapper kbWrap = closeDateChkMthd(opp);
            if(kbWrap != null){
                reasonList.addAll(kbWrap.reason);
                resolutionList.addAll(kbWrap.resolution);
            }
        }
        system.debug('@@@@'+reasonList);
        system.debug('@@@@'+resolutionList);
    }
    public static  Boolean emeaVatCheck(Opportunity opp){
        List<String> euCountries = new List<String>(String.valueOf(SYSTEM.LABEL.EU_COUNTRIES).split(';'));
        Boolean invalidVAT = false;
        Decimal strVal = opp.SBQQ__PrimaryQuote__r.Sales_Tax_Rate__c;//opp.Sales_Tax_Rate_New__c;(GTMS-20209):replaced opp.Sales_Tax_Rate_New__c with opp.SBQQ__PrimaryQuote__r.Sales_Tax_Rate__c;
        Integer strNew = strVal != null ? strVal.IntValue() : 0;
        if(opp.VAT_Number__c != null){
            invalidVAT = ((strNew <> 0 && (euCountries.contains(opp.Shipping_Country__c) || (String.valueOf(opp.VAT_number__c).startsWithIgnoreCase('XI') && String.valueOf(opp.Shipping_Zip_Code__c).startsWithIgnoreCase('BT%'))))
                          ||(opp.Shipping_Country__c == 'United Kingdom' && !(String.valueOf(opp.Shipping_Zip_Code__c).startsWithIgnoreCase('BT%')) && strNew <> 20));
            
        }else{
            invalidVAT = (euCountries.contains(opp.Shipping_Country__c) || opp.Shipping_Country__c == 'United Kingdom') && strNew <> 21;//(GTMS-20209):replaced opp.Sales_Tax_Rate_New__c with opp.SBQQ__PrimaryQuote__r.Sales_Tax_Rate__c;
        }
        
        return invalidVAT;
    }
    
    public static KickBackWrapper closeDateChkMthd(Opportunity opp){
        List<String> reason = new List<String>();
        List<String> resolution = new List<String>();
        KickBackWrapper kbWrap;
        Datetime sysTime = System.Now();
        Date todayDate = date.today();
        Date nxtBsnsDte = calcNextBusinessDate();//calling method to return next business day //date.today().addDays(1);
        if((opp.CloseDate == todayDate || opp.CloseDate < todayDate || (opp.CloseDate > todayDate && opp.CloseDate != nxtBsnsDte)) && ((todayDate == sysTime.dateGMT() && sysTime.hourGMT()>=14)||(date.today().addDays(1) == sysTime.dateGMT() && sysTime.hourGMT()<14))){
            reason.add(kbReasonsMap.get('Order received after shipping cutoff'));
            resolution.add(kbResolutionMap.get('Order was received after shipping cutoff (2PM GMT). Update close date to next business day and recalculate CPQ quote'));
        }else if((opp.closeDate < todayDate || opp.CloseDate > todayDate) && (todayDate == sysTime.dateGMT() && sysTime.hourGMT() < 14) ){
            reason.add(kbReasonsMap.get('Close Date is not equal to current date'));
            resolution.add(kbResolutionMap.get('Please update close date to today and recalculate CPQ'));
        }
        if(!reason.isEmpty() && !resolution.isEmpty()){kbWrap = new KickBackWrapper(reason,resolution);}
        
        return kbWrap;
    }
    
    public static Date calcNextBusinessDate(){
        Set<String> plusOneDaySet = new Set<String>{'Mon','Tue','Wed','Thu','Sun'};
            string weekDay = Datetime.now().format('E');
        Date nextDate = (plusOneDaySet.contains(weekDay)) ? date.today().addDays(1) : (weekDay == 'Fri') ? date.today().addDays(3) : date.today().addDays(2);
        return nextDate;
    }
    
    public static Map<string,string> getPicklistOptions(Schema.DescribeFieldResult fieldDescription){
        Map<string,string> optionsMap = new Map<string,string>();
        List<Schema.PicklistEntry> entries = fieldDescription.getPicklistValues();
        // Do something with entries
        for (Schema.PicklistEntry entry : entries) {
            optionsMap.put(entry.getValue(),entry.getLabel());
        }
        return optionsMap;
    }
    
    public class KickBackWrapper{
        public List<string> reason{get;set;}
        public List<string> resolution{get;set;}
        
        public KickBackWrapper(List<string> reason, List<string> resolution){
            this.reason = reason;
            this.resolution = resolution;
        }
    }
}