/**********************************************************************
Name: OrderValidationServiceAutomationAsync
Test Class: OrderValidationAsyncTest
----------------------------------------------------------------------
Purpose: This class contains the logic to perform Order Validation between opp, Quote and docusign for Revneue opprotunities
----------------------------------------------------------------------
History  

Ticket           AUTHOR              DATE               DETAIL                       
Sai Ganesh Repaka               
GTMS-13378  Vijaychandra            9/13/23             Created executeOrderValidation method to call from batch class to resolve queueable issue
GTMS-15223  Vijaychandra            9/13/23         Added Selected Payment Type field condition in Order Validation to kickback if criteria doesnt matches
GTMS-15783  Vijaychandra            10/10/23        Updated HW Products and LIC Product data check logic with variable assignments. Previously null is comparing with 0 value
GTMS-16035  Vijaychandra            10/17/23        Added aditional condtion in if statement.
GTMS-16028  Vijaychandra            10/18/23        Added logic to map VAT VAlidation status value with Account.FirstPurchase.VAT Validation status if crietia satisfied
GTMS-16291  Vijaychandra            10/27/23        Added logic for fetching docs related to opp and KB logic if docusing and attahcment doesnt exist.
GTMS-16298  Vijaychandra            10/30/23        Added VAT Status condition for CVS Review logic
GTMS-16312  Vijaychandra            10/30/23        Extended DIA logic to EMEA, Replaced payment tyems with Custom Labels and Added Net terms logic.
GTMS-16314   Vijaychandra      11/03/23     Added CurrencyIsoCode kickback logic.
GTMS-16317  Rodrigo.                11/08/23.       Extended logic Today's Date > Latest Closed Date (CPQ), to also check for Status to be able to assign different kickback resolution
GTMS-16316  Vijaychandra      11/09/23    Added logic to VAT validation for EMEA deals
GTMS-17284  Vijaychandra      12/05/23    Added Payment_Terms__c validation logice between Qte/Opp/OF as per change request
GTMS-17786  Vijaychandra      01/05/23    Added additional condition in Licnese Term validation if check
GTMS-16121  Vijaychandra      12/06/23    Added Shipping_And_Handling kickback validation logic check between Qte/Opp/OF.
GTMS-17861  Vijaychandra      01/15/23    Added CVS review logic for NA deals if Docusign License terms is 1 or 2 months greater than Opportunity.
GTMS-16637  Vijaychandra      12/05/23    Added new validations as per DCA project requirement and Modified below logic by saperating OVA and DCA validations
GTMS-19053  Vijaychandra      02/28/24    Updated DCA entry criteria and Add new mannual review logic as per business request
GTMS-19277  Vijaychandra      03/05/24    Updated Bill To Email check with Consolidated Email field on quote. Removed Account's Billing Email field.
GTMS-19686  Vijaychandra      22/03/24    Updated logic of checking of oppty Payment Terms with First purchase oppty payment terms to Account payment Terms. Added Credit Analyst kickback notes for Payment Terms Missmatch
GTMS-19691  Vijaychandra      03/22/24    Adding reasons for all OM review functionlities in OVA logic.
GTMS-19362  Mahesh          03/26/24    Added logic to be confirming New Billing Process Approved is enabled for opportunities with payment terms = Due in Advance
GTMS-20016  Vijaychandra      04/04/24    Added OVA Logging functionality.
GTMS-19973  Vijaychadnra      04/02/24    Added new Kickbacks reasons and resolutions for Total Hardware Due and Total License Due differences
GTMS-20016  Vijaychandra      04/04/24    Added OVA Logging functionality.
GTMS-20040  Vijaychandra      04/04/24    Updated logic to Persist the OM Review reasons and Kickbacks
GTMS-20187  Vijaychandra      04/10/24    Commented Camera only kickback logic as per the business request.
GTMS-20151  Vijaychandra      04/09/24    Updated logic to remove Mexico customer from Paymen Method kickback
GTMS-20152  Vijaychandra      04/09/24    Updated logic to replace empty payment method kickback with cvs Review.
GTMS-20187  Vijaychandra      04/10/24    Commented Camera only kickback logic as per the business request.
GTMS-20294  Vijaychandra      04/12/24    Added $1 buffer logic while comparing Lic Due and HW Due
GTMS-20209  Vijaychandra      04/13/24    Replaced opp.Sales_Tax_Rate_new__c field with opp.sBQQ__PrimaryQuote__r.Sales_Tax_Rate__c field in emeaVATCheck method
GTMS-20711  Vijaychandra      04/29/24    remove Comma value from LIC Product count and HW product count values from docusign record.
GTMS-27988  rodrigo           05/26/25.   updated the logic
***********************************************************************/ 
public without sharing class OrderValidationServiceAutomationAsync extends BaseAsyncHandler {
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    
    @TestVisible private Boolean shouldPublishDML = true;
    private final static String CUSTOM_NOTIFICATION_TYPE_DEV_NAME = 'Order_Validation_Complete_Notification';
    
    private final static Decimal CREDIT_CARD_PROCESSING_FEE_MULTIPLIER = 0.03;
    Async_Apex_Logging_Switch__mdt asyncLogSwitch = Async_Apex_Logging_Switch__mdt.getInstance('OVA_Log_Switch');//GTMS-20016 switch for OVA Async logger
    public Map<Id,Id> opptyLoggerMap = new Map<Id,Id>();//GTMS-20016 Async Apex LoggerIds;
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Account.SObjectType,
            Opportunity.SObjectType
            };
                
                List<Id> recordsIds;
    
    public override String getRequestType(){
        return 'Order Validation Async Job';
    }
    public void setOpptyLoggerMap(Map<Id,Id> opptyLogMap){
        this.opptyLoggerMap = opptyLogMap;
    }
    
    //Added for GTMS-13378 ---start
    /*****************************************
* @Description:this method will call the performValidationMethod to process OrderValidation logic
* @Param : recordidList - opportunity Id list
* @Param : operation - value = finance validation  
*************************/
    public void executeOrderValidation(List<string> recordidList,string operation){
        
        recordsIds = recordIdList;
        //this.opptyLoggerMap = opptyLoggerMap;
        
        if(recordsIds.isEmpty()) return;
        
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        
        try{
            switch on operation {
                when 'Finance Validation' {
                    performValidation();
                }
            }
        }catch(Exception ex){
            thisLogger.logError(
                'Error in OrderValidationServiceAutomationAsync during Finance Validation Operation::',
                new SamsaraLoggerObjectMVP(
                    ex,
                    recordsIds
                )
            );
            throw ex;
        }finally{
            thisLogger.dispatch();
        }
    }
    //Added for GTMS-13378 --end
    
    public override void execute(Async_Request__c ar){
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);
        
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        
        try{
            switch on opt.Operation {
                when 'Finance Validation' {
                    performValidation();
                }
            }
        }catch(Exception ex){
            thisLogger.logError(
                'Error in OrderValidationServiceAutomationAsync during '+ opt.Operation +' Operation::',
                new SamsaraLoggerObjectMVP(
                    ex,
                    recordsIds
                )
            );
            throw ex;
        }finally{
            thisLogger.dispatch();
        }
    }
    
    public void performValidation() {
        System.debug('entering to method');
        Map<Id, Account> accountMap = new Map<ID, Account>();
        Map<string,Integer> docsCountMap = new Map<string,Integer>();//GTMS-16291
        List<Async_Apex_Logger__c> asyncLoggerList = new List<Async_Apex_Logger__c>();
        OrderFinanceSetting__mdt billing360Enabled = OrderFinanceSetting__mdt.getInstance('B360_R1_Toggle');
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>([
            SELECT Id, Name, OwnerId, Owner.Name, Owner.Region__c, Amount, Notes__c, Finance_Segment_Stamp__c, Segment_Sales_Role__c,
            StageName, Payment_Terms__c, Initial_Payment_Terms__c, CloseDate,PO_Number__c,Overwrite_Validation_Rule__c,
            Finance_Kickback_Reason__c, Finance_Kickback_Resolution__c,Shipping_and_Handling__c,Bypass_Validation_rule__c,
            License_Term__c, License_Term_CPQ__c, Amount_Received__c,Payment_Method__c,of_LIC_Products__c,of_Accessories__c,
            Buyout_Amount__c, Buyout_Opportunity__c, Subsidy_Amount__c,Payment_Token__c,Temp_FFM_Tax__c,Sum_of_Rebates__c,SBQQ__PrimaryQuote__r.Subsidy_Amount__c,SBQQ__PrimaryQuote__r.Number_of_months_of_Free_service__c,SBQQ__PrimaryQuote__r.Future_Free_Months_Amount__c,
            Subsidy_Opportunity__c, Sales_Tax__c, Sales_Tax_Amount__c, Credit_Analyst_Kickback_Note__c,
            Shipping_and_Handling_Manual__c, CurrencyIsoCode, CM_Unit_Count__c, VG_unit_count__c, of_HW_Products__c,
            VAT_Validation_Status__c, CVS_Review__c, Finance_Segment__c,Shipping_Zip_Code__c,
            Is_Webstore_Upsell_Opportunity__c, Custom_Schedule__c, Camera_Only_Deal__c,/*GTMS-20040*/OM_Review_Reason_Code__c,/*GTMS-20040*/
            Selected_Payment_Type__c, Payment_Type__c, First_Invoice_Total__c, Payment_Processing_Fee__c, First_Purchase__c,Billing_360_Transaction__c,Deal_Components__c,
            Hardware_Sales_Tax__c, License_Sales_Tax__c, Sbqq__PrimaryQuote__c, Total_Hardware_Due__c, Total_License_Due__c,/*GTMS-19053*/DCA_Enabled__c,CreatedDate,Account.Customer_require_PO_for_invoicing__c,/*GTMS-19053*/
            SBQQ__PrimaryQuote__r.Name,SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c,SBQQ__PrimaryQuote__r.License_Term__c,/*GTMS-19277*/SBQQ__PrimaryQuote__r.Consolidated_Billing_Email__c,SBQQ__PrimaryQuote__r.CreatedDate,/*GTMS-19277*/SBQQ__PrimaryQuote__r.S_H_Tax__c,
            SBQQ__PrimaryQuote__r.CalculatedSubscriptionTerm__c, License_Sales_Tax_CPQ__c,Hardware_Sales_Tax_CPQ__c,/*GTMS-17786*/SBQQ__PrimaryQuote__r.of_Accessories__c,/*GTMS-17786*/
            SBQQ__PrimaryQuote__r.SBQQ__Status__c, SBQQ__PrimaryQuote__r.Close_Date__c,/*(GTMS-16314)*/SBQQ__PrimaryQuote__r.CurrencyIsoCode,/*(GTMS-16314)*/ /*GTMS-16121*/SBQQ__PrimaryQuote__r.Shipping_And_Handling__c,/*GTMS-16121*/
            SBQQ__PrimaryQuote__r.Latest_Close_Date__c, SBQQ__PrimaryQuote__r.SBQQ__Primary__c,/*GTMS-17284*/SBQQ__PrimaryQuote__r.Payment_Terms__c,/*GTMS-17284*/Sales_Tax_Rate_NEW__c,
            SBQQ__PrimaryQuote__r.of_HW_Products__c, SBQQ__PrimaryQuote__r.Checkout_Link__c, SBQQ__PrimaryQuote__r.Of_LIC_Products__c, SBQQ__PrimaryQuote__r.Sales_Tax__c, SBQQ__PrimaryQuote__r.AccountName__c,SBQQ__PrimaryQuote__r.Selected_Payment_Type__c,
            /*GTMS-16637*/Owner_Manager_Name_Copy__c, Owner_Director_Name_Copy__c, SBQQ__PrimaryQuote__r.Bill_To_Account__r.Name, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingStreet, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCity,SBQQ__PrimaryQuote__r.Prorated_Amount__c,SBQQ__PrimaryQuote__r.First_Annual_Payment__c,SBQQ__PrimaryQuote__r.First_Semi_Annual_Payment__c,SBQQ__PrimaryQuote__r.First_Quarter_Payment__c,
            SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingState, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCountry, SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingPostalCode,SBQQ__PrimaryQuote__r.Bill_To_Account__r.Billing_Email__c,SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Email, 
            SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Name, SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Title,SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Phone, SBQQ__PrimaryQuote__r.Bill_To_Account__r.Phone,SBQQ__PrimaryQuote__r.DCA_Validation__c, SBQQ__PrimaryQuote__r.Customer_Preferred_Payment_Method__c,/*GTMS-16637*/
            /*GTMS-16035*/Account.Billing_Stripe_Customer_Id__c,Owner_Segment__c,/*GTMS-16035*//*GTMS-16028*/SBQQ__RenewedContract__c,Type,Account.VAT_Validation_Status__c, Account.First_Purchase_Opportunity__r.Shipping_Country__c,
            Shipping_Country__c, VAT_Number__c,Account.First_Purchase_Opportunity__c, Account.First_Purchase_Opportunity__r.VAT_Number__c,Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c,/*GTMS-16028*/
            /*GTMS-16312*/Account.First_Purchase_Opportunity__r.Payment_Terms__c, Account.First_Purchase_Opportunity__r.Initial_Payment_Terms__c,/*GTMS-16312*//*GTMS-20209*/SBQQ__PrimaryQuote__r.Sales_Tax_Rate__c,/*GTMS-20209*/
            /*GTMS-19686*/Account.Payment_Terms__c,/*GTMS-19686*//*GTMS-19973*/SBQQ__PrimaryQuote__r.Total_Hardware_Due__c, SBQQ__PrimaryQuote__r.Total_License_Due__c, SBQQ__PrimaryQuote__r.Total_License_Price__c,SBQQ__PrimaryQuote__r.Estimated_Upfront_Amount__c,/*GTMS-19973*/
            (SELECT ID, First_invoice_line_amount__c from OpportunityLineItems),
            (SELECT Id, Name, dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c, dsfs__DocuSign_Status__c.dsfs__Opportunity__c, dsfs__DocuSign_Status__c.License_Term__c,
             dsfs__DocuSign_Status__c.Account_Name__c, dsfs__DocuSign_Status__c.of_HW_Products__c,/*GTMS-16121*/dsfs__Docusign_Status__c.Shipping_And_Handling__c,/*GTMS-16121*/
             dsfs__DocuSign_Status__c.of_LIC_Products__c, dsfs__DocuSign_Status__c.Payment_Terms__c, dsfs__Company__r.name,dsfs__Docusign_Status__c.Opp_Currency__c,//(GTMS-16314)
             /*GTMS-16637*/dsfs__DocuSign_Status__c.Bill_To_Contact_Name__c, dsfs__DocuSign_Status__c.Bill_To_Contact_Phone__c, dsfs__DocuSign_Status__c.Bill_To_Contact_Title__c, dsfs__DocuSign_Status__c.Billing_City__c,dsfs__DocuSign_Status__c.Number_of_Months_of_Free_Service__c,dsfs__DocuSign_Status__c.Temp_FFM_Tax__c,dsfs__DocuSign_Status__c.Future_Free_Months_Amount__c,
             dsfs__DocuSign_Status__c.Billing_Company_Name__c, dsfs__DocuSign_Status__c.Billing_Country__c, dsfs__DocuSign_Status__c.Billing_Email__c,dsfs__DocuSign_Status__c.Customer_Preferred_Payment_Method__c,
             dsfs__DocuSign_Status__c.Billing_Postal_Code__c,dsfs__DocuSign_Status__c.Billing_State__c, dsfs__DocuSign_Status__c.Billing_Street__c,dsfs__DocuSign_Status__c.Bill_To_Contact_Email__c,/*GTMS-16637*/
             dsfs__DocuSign_Status__c.Sales_Tax_Amount__c,dsfs__DocuSign_Status__c.Selected_Payment_Type__c,/*GTMS-19973*/dsfs__DocuSign_Status__c.Total_Hardware_Due__c, dsfs__DocuSign_Status__c.Total_License_Due__c/*GTMS-19973*/
             ,/*GTMS-27988*/ dsfs__DocuSign_Status__c.Total_License_Cost__c/*GTMS-27988*/, dsfs__DocuSign_Status__c.Next_Recurring_Bill_Date__c,dsfs__DocuSign_Status__c.First_Annual_Payment__c, dsfs__DocuSign_Status__c.First_Month_Payment__c, dsfs__DocuSign_Status__c.First_Quarter_Payment__c, dsfs__DocuSign_Status__c.First_Semi_Annual_Payment__c
             FROM R00N80000002fD9vEAE__r WHERE dsfs__DocuSign_Status__c.dsfs__Opportunity__c != null 
            AND dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c = 'Completed' 
             AND dsfs__DocuSign_Status__c.Envelope_Type__c != 'Rebate Document'),
            AccountId, Account.Name, Account.Further_information_required__c, Account.CurrencyIsoCode, Account.BillingCountry, Account.New_Billing_Process_Approved__c,
            SBQQ__RenewedContract__r.Name, SBQQ__RenewedContract__r.AccountId,Opportunity_Tracking__c,/*GTMS-26451*/Sub_Type__c,Reseller__r.Payment_Terms__c, 
    		Reseller__r.Partner_Agreement_Accepted__c,Reseller__r.Customer_require_PO_for_invoicing__c,SBQQ__PrimaryQuote__r.Reseller_Account__r.Partner_Agreement_Accepted__c/*GTMS-26451*/, SBQQ__PrimaryQuote__r.Next_Recurring_Bill_Date__c, Reseller__c
            FROM Opportunity
            WHERE Id IN :recordsIds
        ]);
        
        Integer signedDocumentCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN (SELECT Id
                                     FROM dsfs__DocuSign_Status__c
                                     WHERE dsfs__Envelope_Status__c = 'Completed'
                                     AND Envelope_Type__c != 'Rebate Document'
                                     AND dsfs__Opportunity__c IN :recordsIds)
        ];
        //10/27/23 Vijaychandra --START-- (GTMS-16291):Adding logic to fetch documents attaced to Opportunity
        for(AggregateResult result:[SELECT Count(Id)recSum,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :recordsIds Group BY LinkedEntityId]){
            docsCountMap.put(String.valueOf(result.get('LinkedEntityId')),Integer.valueOf(result.get('recSum')));
        }
        //--END-- (GTMS-16291)
        
        //integer signedDocumentCount = [SELECT COUNT() FROM Attachment WHERE ParentID IN (SELECT id FROM dsfs__DocuSign_Status__c WHERE dsfs__Opportunity__c IN:newOppMap.keySet())];
        
        
        List<Opportunity> oppsToNotify = new List<Opportunity>();
        
        for(Id oppId : recordsIds) {
            Boolean cvsReview = false;
            string omReasonCode;//GTMS-20040
          Set<SObjectField> updatedOpportunityFields = new Set<SObjectField>();
            List<String> kickbackReasons = new List<String>();
          List<String> kickbackResolution = new List<String>();
            Opportunity opp = newOppMap.get(oppId);
            //12/8/23 Vijaychandra --START-- (GTMS-16637): moved below 2 if conditions form OVA check method to here for Global validation for both OVA and DCA
            if(opp.R00N80000002fD9vEAE__r.isEmpty() && docsCountMap.get(opp.Id)!= NULL/*(GTMS-16291)*/){
                cvsReview = true;
                omReasonCode = 'Deal was routed to OM review because There is no completed Docusign record linked to this opportunity';//GTMS-20040
                //03/22/24 Vijaychandra (GTMS-19691): Adding reason for the CVS Review.
                //opp.Credit_Analyst_Kickback_Note__c = 'Deal was routed to OM review because There is no completed Docusign record linked to this opportunity';
                //updatedOpportunityFields.add(Opportunity.Credit_Analyst_Kickback_Note__c);
            }
            //10/27/23 Vijaychandra --START-- (GTMS-16291):Adding logic to fetch documents attaced to Opportunity
            if(opp.R00N80000002fD9vEAE__r.isEmpty() && docsCountMap.get(opp.Id) == NULL && !cvsReview){
                
                kickbackReasons.add('Order Form/ PO not attached to SFDC');
                kickbackResolution.add('Attach Signed Order Form/ PO to SFDC');
                
            }
            //--END-- (GTMS-16291)
            //--END-- (GTMS-16637)
            
            //12/7/23 Vijaychandra --START-- (GTMS-16637): Added below logic for OVA and DCA merging and validation checks
            //02/28/24 Vijaychandra --START-- (GTMS-19053): updated DCA logic field from (opp.SBQQ__PrimaryQuote__r.DCA_Validation__c == 'DCA')
            //3/12/24 Vijaychandra (GTMS-19474): Replaced (opp.DCA_Enabled__c == 'DCA' && dateCheck) with (opp.SBQQ__PrimaryQuote__r.DCA_Validation__c == 'DCA')
            //Datetime dateVAl = opp.SBQQ__PrimaryQuote__r.CreatedDate;
            //Boolean dateCheck = dateVAl != null ? dateVal.date() >= Date.valueOf(SYSTEM.Label.DCA_Cutoff_Date) : false;
            if(!cvsReview && ((opp.SBQQ__PrimaryQuote__r.DCA_Validation__c == 'DCA')||Test.isRunningTest()) && !opp.R00N80000002fD9vEAE__r.isEmpty()){
                ValidationWrapper dcaWrap = dcaValidationCheck(opp,signedDocumentCount,docsCountMap, billing360Enabled.Value__c);
                cvsReview = dcaWrap.cvsReview;
                omReasonCode = dcaWrap.omReasonCode;//GTMS-20040
                if(!dcaWrap.oppFields.isEmpty()){updatedOpportunityFields.addAll(dcaWrap.oppFields);}
                if(!dcaWrap.kbWrap.reason.isEmpty()){
                    kickbackReasons.addAll(dcaWrap.kbWrap.reason);
                    kickbackResolution.addAll(dcaWrap.kbWrap.resolution);
                }
                opp = dcaWrap.opp;
            }
            if(!cvsReview && !(new OrderValidationServiceAutomation().settingsOwnerExceptionCriteria(opp))){
                ValidationWrapper ovaWrap = ovaValidationCheck(opp,signedDocumentCount,docsCountMap,kickbackReasons, billing360Enabled.Value__c);
                cvsReview = ovaWrap.cvsReview;
                omReasonCode = ovaWrap.omReasonCode;//GTMS-20040
                if(!ovaWrap.oppFields.isEmpty()){updatedOpportunityFields.addAll(ovaWrap.oppFields);}
                if(!ovaWrap.kbWrap.reason.isEmpty()){
                    kickbackReasons.addAll(ovaWrap.kbWrap.reason);
                    kickbackResolution.addAll(ovaWrap.kbWrap.resolution);
                }
                opp = ovaWrap.opp;
            }
            //--END-- (GTMS-16637)
           
            //12/8/23 Vijaychandra --START-- (GTMS-16637): moved below logic from OVA check to here to make it as common logic for OVA and DCA
            //3/12/24 Vijaychandra (GTMS-19474): Replaced (opp.DCA_Enabled__c == 'DCA' && dateCheck) with (opp.SBQQ__PrimaryQuote__r.DCA_Validation__c == 'DCA')
            if(cvsReview && (((opp.SBQQ__PrimaryQuote__r.DCA_Validation__c == 'DCA')||Test.isRunningTest()) || (!(new OrderValidationServiceAutomation().settingsOwnerExceptionCriteria(opp))))){
                opp.CVS_Review__c = cvsReview;
                opp.StageName = 'Closing';
                opp.OM_Review_Reason_Code__c = omReasonCode != null ? opp.OM_Review_Reason_Code__c != null ? opp.OM_Review_Reason_Code__c+';'+omReasonCode : omReasonCode : opp.OM_Review_Reason_Code__c;//GTMS-20040
                opp.Finance_Kickback_Reason__c = null;
                opp.Finance_Kickback_Resolution__c = null;
                updatedOpportunityFields.add(Opportunity.StageName);
                updatedOpportunityFields.add(Opportunity.CVS_Review__c);
                updatedOpportunityFields.add(Opportunity.OM_Review_Reason_Code__c);//GTMS-20040
                updatedOpportunityFields.add(Opportunity.Finance_Kickback_Reason__c);
                updatedOpportunityFields.add(Opportunity.Finance_Kickback_Resolution__c);

                kickbackReasons.clear();
                kickbackResolution.clear();
                
                oppsToNotify.add(opp);
            //3/12/24 Vijaychandra (GTMS-19474): Replaced (opp.DCA_Enabled__c == 'DCA' && dateCheck) with (opp.SBQQ__PrimaryQuote__r.DCA_Validation__c == 'DCA')
          }else if(!kickbackReasons.isEmpty()&&!kickBackResolution.isEmpty() && (((opp.SBQQ__PrimaryQuote__r.DCA_Validation__c == 'DCA')||Test.isRunningTest()) || (!(new OrderValidationServiceAutomation().settingsOwnerExceptionCriteria(opp))))){
                
        opp.StageName = 'Purchase';
                opp.Finance_Kickback_Reason__c = String.join(kickbackReasons, ';');//GTMS-20040
                opp.Finance_Kickback_Resolution__c = String.join(kickbackResolution, ';');//GTMS-20040
                
                updatedOpportunityFields.add(Opportunity.StageName);
                updatedOpportunityFields.add(Opportunity.Finance_Kickback_Reason__c);//GTMS-20040
                updatedOpportunityFields.add(Opportunity.Finance_Kickback_Resolution__c);//GTMS-20040
            }

            Async_Apex_Logger__c asyncLogger = new Async_Apex_Logger__c();
            Id asyncId = (opptyLoggerMap != null) ? opptyLoggerMap.get(opp.Id) : null;
            if(asyncId != null){
                asyncLogger.Id = asyncId;
                asyncLogger = new AsyncApexLoggerService().updateAsyncLogger(asyncLogger,opp,kickbackReasons,kickbackResolution,omReasonCode);
                asyncLoggerList.add(asyncLogger);
            }
            if(!updatedOpportunityFields.isEmpty()){
                DMLWrapper.doUpdate(opp, new List<SObjectField>(updatedOpportunityFields));
                oppsToNotify.add(opp);
            }
            //--END-- (GTMS-16637)
        }
        
        DMLWrapper.publishDML();
        if(!asyncLoggerList.isEmpty()){update asyncLoggerList;}
        System.debug('ORDER VALIDATION SERVICE: Opps to notify: '+oppsToNotify.size());
        
        if (!oppsToNotify.isEmpty()) fireNotifications(oppsToNotify);
    }
    
    
    public void fireNotifications(List<Opportunity> oppsToNotify){
        CustomNotificationType notificationType = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = :CUSTOM_NOTIFICATION_TYPE_DEV_NAME
        ];
        
        for (Opportunity opp : oppsToNotify){
            // Create a new custom notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            
            // Set the contents for the notification
            notification.setTitle(Label.Order_Validation_Notification_Title);
            notification.setBody(
                String.format(
                    Label.Order_Validation_Notification_Body,
                    new List<String>{ opp.Name }
                )
            );
            
            // Set the notification type and target
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(opp.Id);
            
            notification.send(new Set<String>{opp.OwnerId, UserInfo.getUserId()});
        }
    }
    
    public static Decimal nullCheck(Decimal value, Decimal valueIfNull){
        return (value != null ? value : valueIfNull);
    }
    
    public static Decimal nullCheck(Decimal value){
        return nullCheck(value, 0);
    }
    
    public static Decimal sumValues(List<Decimal> values){
        Decimal amount = 0;
        String debugBreakdown = 'Invoice breakdown: (';
        for (Integer idx = 0; idx < values.size(); idx++){
            amount += values[idx];
            debugBreakdown += (idx > 0 ? ' + ' : '')+('{'+idx+'}');
        }
        
        System.debug(LoggingLevel.FINER, String.format(debugBreakdown+')', values));
        return amount;
    }
    //12/07/23 Vijaychandra --START-- (GTMS-16637): Created this method to move OVA check while saperating OVA check from DCA check
    /***********
     * Description : This method contains the logic for Order Validation
     * @Param: opp (Opportunity record)
     * @Param: signedDocumentCount (count of attachment records of completed docusign record)
     * @Param: docsCountMap (this variable is a map of oppid and document record count.)
  *************/
    public static ValidationWrapper ovaValidationCheck(Opportunity opp , Integer signedDocumentCount, Map<string,Integer> docsCountMap,List<String> kickbackReasons, String B360Enabled){
        Boolean cvsReview = false;
        Set<SObjectField> updatedOpportunityFields = new Set<SObjectField>();
        List<String> reasonList = new List<String>();
        List<String> resolutionList = new List<String>();
     
        string omReasonCode;//GTMS-20040

        //10/18/23 Vijaychandra --START-- (GTMS-16028): Added logic to map VAT VAlidation status value with Account.FirstPurchase.VAT Validation status if crietia satisfied
        //11/16/23 Vijaychandra: Below code block moved from 395 to here after demo
        if((opp.CurrencyIsoCode == 'EUR'||opp.CurrencyIsoCode == 'GBP')&&!opp.First_Purchase__c && opp.SBQQ__RenewedContract__c == NULL && opp.Account.First_Purchase_Opportunity__c != null &&(opp.Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c == 'Verified' || opp.Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c == 'Confirmed')  
           && opp.Shipping_Country__c == opp.Account.First_Purchase_Opportunity__r.Shipping_Country__c && opp.VAT_Number__c == opp.Account.First_Purchase_Opportunity__r.VAT_Number__c && opp.Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c != opp.VAT_Validation_Status__c){
               //Assigning VAT Validation status with Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c
               opp.VAT_Validation_Status__c = opp.Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c;
               opp.Bypass_Validation_rule__c = true;
               updatedOpportunityFields.add(Opportunity.VAT_Validation_Status__c);
               updatedOpportunityFields.add(Opportunity.Bypass_Validation_rule__c);
           }
        //--END--(GTMS-16028) 
        // Manual review check
        // 11/10/23 Vijaychandra : As per dicusssion with agamani below logic is removed from if condition
        //(opp.Payment_Terms__c != 'Due in advance' && opp.Initial_Payment_Terms__c != 'Due in advance' && opp.Amount_Received__c == null && opp.Payment_Token__c == null)
        ////11/16/23 Vijaychandra --START-- (GTMS-16028): Added one more condition to if statement
        if(((!opp.R00N80000002fD9vEAE__r.isEmpty() && opp.Account.name != opp.R00N80000002fD9vEAE__r[0].Account_Name__c)
           || /*(GTMS-19362)*/ (opp.First_Purchase__c == false && opp.Payment_Terms__c == 'Due in advance' && opp.Initial_Payment_Terms__c == 'Due in advance' && opp.Account.New_Billing_Process_Approved__c == false)
           || /*(GTMS-16298)*/((opp.CurrencyIsoCode == 'EUR'|| opp.CurrencyIsoCode == 'GBP') && opp.VAT_Validation_Status__c != 'Confirmed')/*(GTMS-16298)*/
           ||/*(GTMS-16028)*/((opp.CurrencyIsoCode == 'EUR'||opp.CurrencyIsoCode == 'GBP')&&!opp.First_Purchase__c && opp.SBQQ__RenewedContract__c == NULL && opp.Account.First_Purchase_Opportunity__c != null && (opp.Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c == 'Verified' || opp.Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c == 'Confirmed')  
           && opp.Shipping_Country__c == opp.Account.First_Purchase_Opportunity__r.Shipping_Country__c && opp.VAT_Number__c == opp.Account.First_Purchase_Opportunity__r.VAT_Number__c && (opp.Account.First_Purchase_Opportunity__r.VAT_Validation_Status__c != opp.VAT_Validation_Status__c)))/*GTMS-16028*/){
                                  
               cvsReview = true;
               //03/22/24 Vijaychandra --START-- (GTMS-19691): Adding reason for the CVS Review.
               boolean accNameCheck = (!opp.R00N80000002fD9vEAE__r.isEmpty() && opp.Account.name != opp.R00N80000002fD9vEAE__r[0].Account_Name__c);
               boolean vatStatusCheck = ((opp.CurrencyIsoCode == 'EUR'|| opp.CurrencyIsoCode == 'GBP') && opp.VAT_Validation_Status__c != 'Confirmed');
               /*(GTMS-19362)*/boolean nbpCheck = (opp.First_Purchase__c == false && opp.Payment_Terms__c == 'Due in advance' && opp.Initial_Payment_Terms__c == 'Due in advance' && opp.Account.New_Billing_Process_Approved__c == false);
               string kbNote = accNameCheck ? 'Deal was routed to OM review because Opportunity Account name and Docusign Account Name are different' 
                           : vatStatusCheck ? 'Deal was routed to OM review because VAT validation status was not yet confirmed for EMEA Opportunity'
                                : nbpCheck ? 'Deal was routed to OM review because Accounts New Billing Process was not approved for the first purchase opportunity'
                                :'Deal was routed to OM review because VAT Validation Status of the current opportunity and VAT Validation Status of First Purchase Opportunity is different';
               omReasonCode = kbNote;//GTMS-20040
               //opp.Credit_Analyst_Kickback_Note__c = kbNote;
               //updatedOpportunityFields.add(Opportunity.Credit_Analyst_Kickback_Note__c);
               //03/22/24 --END-- (GTMS-19691)
               //List<SObjectField> oppFields = new List<SObjectField>{Opportunity.CVS_Review__c};
               //if(!updatedOpportunityFields.isEmpty()){oppFields.addAll(updatedOpportunityFields);}    
               //DMLWrapper.doUpdate(opp,oppFields);
               //oppsToNotify.add(opp);
               
               //if(!Test.isRunningTest()){ break;}
         }
         //GTMS-25962 Non-DCA Opportunity PO number validation check
         if(!cvsReview && (opp.Account.Customer_require_PO_for_invoicing__c == 'Yes' && (opp.PO_Number__c == null || opp.PO_Number__c == '' || opp.PO_Number__c == '-'))){
            cvsReview = true;
            omReasonCode = 'Deal was routed to OM review because it is missing the PO Number';
        }
         //GTMS-26451 Start
        if(!cvsReview){
            Boolean isValidOppReseller = opp.Reseller__c != null && opp.Reseller__r.Partner_Agreement_Accepted__c != null;
            
            Boolean isValidQuoteReseller = opp.SBQQ__PrimaryQuote__r != null &&
                opp.SBQQ__PrimaryQuote__r.Reseller_Account__c != null && 
                opp.SBQQ__PrimaryQuote__r.Reseller_Account__r.Partner_Agreement_Accepted__c != null;
            
            if(opp.Reseller__c != null && opp.Reseller__r.Partner_Agreement_Accepted__c == null) {
                cvsReview = true;
                omReasonCode = 'Deal was routed to OM review because Reseller account missing Authorization Date';
            } else if(opp.SBQQ__PrimaryQuote__r != null && opp.SBQQ__PrimaryQuote__r.Reseller_Account__c != null && opp.SBQQ__PrimaryQuote__r.Reseller_Account__r.Partner_Agreement_Accepted__c == null) {
                cvsReview = true;
                omReasonCode = 'Deal was routed to OM review because Reseller account missing Authorization Date';
            }
            
            Boolean hasResellerMismatch = (isValidOppReseller && !isValidQuoteReseller) || (!isValidOppReseller && isValidQuoteReseller) || (isValidOppReseller && isValidQuoteReseller && opp.Reseller__c != opp.SBQQ__PrimaryQuote__r.Reseller_Account__c); 
            if(hasResellerMismatch) {
                cvsReview = true;
                omReasonCode = 'Deal was routed to OM review because Reseller Account on oppty does not match CPQ level';
            }         
            
            if (!cvsReview && opp.Sub_Type__c == 'Upfitter') {
                if (!isValidOppReseller || !isValidQuoteReseller) {
                    cvsReview = true;
                    omReasonCode = 'Deal was routed to OM review because Reseller Account is missing on Upfitter Deal';
                } else {
                    if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.UPFRONT_PAYMENT_TYPE) {
                        if ((opp.of_HW_Products__c != null && opp.of_HW_Products__c > 0) || (opp.of_Accessories__c != null && opp.of_Accessories__c > 0)) {
                            if (opp.of_LIC_Products__c != null && opp.of_LIC_Products__c > 0) {
                                cvsReview = true;
                                omReasonCode = 'Deal was routed to OM review because products do not align with Upfitter Deal';
                            }
                        }
                    } else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.DIRECT_MONTHLY_PAYMENT_TYPE || opp.Selected_Payment_Type__c == SYSTEM.LABEL.DIRECT_ANNUAL_PAYMENT_TYPE) {
                        cvsReview = true;
                        omReasonCode = 'Deal was routed to OM review because Payment type do not align with the Upfitter Deal';
                    }
                }
            }
            
            if(isValidOppReseller && !cvsReview) {
                String expectedPaymentTerms = String.isNotBlank(opp.Reseller__r.Payment_Terms__c) ? opp.Reseller__r.Payment_Terms__c : 'Net 30';
                if((opp.Payment_Terms__c != null && opp.Payment_Terms__c != expectedPaymentTerms) ||
                   (opp.SBQQ__PrimaryQuote__r != null && opp.SBQQ__PrimaryQuote__r.Payment_Terms__c != null && opp.SBQQ__PrimaryQuote__r.Payment_Terms__c != expectedPaymentTerms)) {
					 reasonList.add('Account payment terms do not match opp level');
                     resolutionList.add('Need to confirm if customer is going through Samsara directly or is this a partner/reseller deal');
                 }
            }
        }
        //GTMS-26451 End
        if(!cvsReview){
            
            Boolean validated = true;
            for(dsfs__DocuSign_Status__c docusign : opp.dsfs__R00N80000002fD9vEAE__r) {
                 //Added by vijaychandra AMARANENI for GTMS-15783
                //GTMS-15783 == START
                Decimal oppHwProds = (opp.of_HW_Products__c != null && opp.of_HW_Products__c != 0) ? opp.of_HW_Products__c : 0;
                Decimal oppLicProds = (opp.of_LIC_Products__c != null && opp.of_LIC_Products__c != 0) ? opp.of_LIC_Products__c : 0;
                Decimal qteHwProds = (opp.SBQQ__PrimaryQuote__r.of_HW_Products__c != null && opp.SBQQ__PrimaryQuote__r.of_HW_Products__c != 0) ? opp.SBQQ__PrimaryQuote__r.of_HW_Products__c : 0;
                Decimal qteLicProds = (opp.SBQQ__PrimaryQuote__r.of_LIC_Products__c != null && opp.SBQQ__PrimaryQuote__r.of_LIC_Products__c != 0) ? opp.SBQQ__PrimaryQuote__r.of_LIC_Products__c : 0;
                Decimal dsHwProds = (docusign.of_HW_Products__c != null && docusign.of_HW_Products__c != '') ? (Decimal.valueOf(String.valueOf(docusign.of_HW_Products__c).remove(',')) != 0) ? Decimal.valueOf(String.valueOf(docusign.of_HW_Products__c).remove(',')) :0 : 0;
                Decimal dsLicProds = (docusign.of_LIC_Products__c != null && docusign.of_LIC_Products__c != '') ? (Decimal.valueOf(String.valueOf(docusign.of_LIC_Products__c).remove(',')) != 0) ? Decimal.valueOf(String.valueOf(docusign.of_LIC_Products__c).remove(',')) :0 : 0;
                //GTMS-15783 == END
                //5/1/24 Vijaychandra --START-- (GTMS-17786): Adding below line to add aditional check in License Term validation
                Decimal qteAcsProds = (opp.SBQQ__PrimaryQuote__r.of_Accessories__c != null && opp.SBQQ__PrimaryQuote__r.of_Accessories__c != 0) ? opp.SBQQ__PrimaryQuote__r.of_Accessories__c : 0;
                //--END-- (GTMS-17786)
                if((signedDocumentCount == null || signedDocumentCount == 0) && docusign.dsfs__Envelope_Status__c == 'Completed'){
                    
                    reasonList.add('Order Form/ PO not attached to SFDC');
                    resolutionList.add('Attach Signed Order Form/ PO to SFDC');
                    
                }
                //10/19/23 Vijaychandra (GTMS-16031): Removed North America condition(&& opp.owner.Region__c == 'North America') form IF
                //11/16/23 added quote license terms varaible
                //1/5/24 Added of_Accessories__c, of_HW_Products__c, of_LIC_Productst__c check in below license term if condition
                Integer qteLT = opp.SBQQ__PrimaryQuote__c != null ? opp.SBQQ__PrimaryQuote__r.License_Term__c != null ? Integer.valueOf(opp.SBQQ__PrimaryQuote__r.License_Term__c) : null : null;
                if (((opp.SBQQ__PrimaryQuote__c != null && opp.License_Term__c != null && docusign.License_term__c != Null) && (opp.License_Term__c == qteLT) &&
                     (opp.License_Term__c == docusign.License_term__c)) || (qteLicProds == 0 && (qteHwProds > 0 || qteAcsProds > 0))
                   ){
                       System.debug('license terms matched');
                   }else{
                       if(((docusign.License_term__c >= opp.License_Term__c) && ((opp.License_Term__c >= docusign.License_term__c - 2) || (opp.License_Term__c >= docusign.License_term__c - 1)) && opp.CurrencyIsoCode != 'EUR' && opp.CurrencyIsoCode != 'GBP')){
                           cvsReview = true;
                           omReasonCode = 'Deal was routed to OM review because License Term in Docusign record is greater than License Term in the Opportunity';//GTMS-20040
                           //03/22/24 Vijaychandra (GTMS-19691): Adding reason for the CVS Review.
                           //opp.Credit_Analyst_Kickback_Note__c = 'Deal was routed to OM review because License Term in Docusign record is greater than License Term in the Opportunity';
                      //updatedOpportunityFields.add(Opportunity.Credit_Analyst_Kickback_Note__c);
                       }else{
                       System.debug('in license term else loop');
                       reasonList.add('Increase in License Term due to Change in Close Date');
                       resolutionList.add('Need new order form or move to closing on original close date');
                       }                       
                   }
                //10/27/23 Vijaychandra --START-- (GTMS-16314): Added currencyisocode condition for Order Validation kickback
                if(opp.CurrencyIsoCode != docusign.Opp_Currency__c || opp.CurrencyIsoCode != opp.SBQQ__PrimaryQuote__r.CurrencyIsoCode){
                    
                    reasonList.add('Currency Mismatch across Opportunity, CPQ, and Docusign');
                    resolutionList.add('Align currency on Opportunity, CPQ and Docusign');
                    
                }
                //--END-- (GTMS-16314)
                if (B360Enabled.equalsIgnoreCase('True') && opp.SBQQ__PrimaryQuote__r.Next_Recurring_Bill_Date__c != docusign.Next_Recurring_Bill_Date__c) {                    
                    cvsReview = true;                    
                    omReasonCode = 'Deal was routed to OM review because there is a mismatch on the Next Recurring Bill Date on CPQ Quote and DocuSign';//GTMS-27099                    
                }
                //4/3/24 vijaychandra --START-- (GTMS-19973): Added new kickback validations
                Decimal oppHWDue = (opp.Total_Hardware_Due__c != null && opp.Total_Hardware_Due__c != 0) ? opp.Total_Hardware_Due__c : 0;
                Decimal oppLICDue = (opp.Total_License_Due__c != null && opp.Total_License_Due__c != 0) ? opp.Total_License_Due__c : 0;
                Decimal dsHWDue = (docusign.Total_Hardware_Due__c != null && docusign.Total_Hardware_Due__c != 0) ? docusign.Total_Hardware_Due__c : 0;
                Decimal dsLICDue = (docusign.Total_License_Due__c != null && docusign.Total_License_Due__c != 0) ? docusign.Total_License_Due__c : 0;
                Decimal qteHWDue = (opp.SBQQ__PrimaryQuote__r.Estimated_Upfront_Amount__c != null && opp.SBQQ__PrimaryQuote__r.Estimated_Upfront_Amount__c != 0) ? opp.SBQQ__PrimaryQuote__r.Estimated_Upfront_Amount__c : 0;
                Decimal qteLICDue = (opp.SBQQ__PrimaryQuote__r.Total_License_Price__c != null && opp.SBQQ__PrimaryQuote__r.Total_License_Price__c != 0) ? opp.SBQQ__PrimaryQuote__r.Total_License_Price__c : 0;
                Boolean totalDueCheck = ((Math.abs(oppHWDue - dsHWDue) > 1 || Math.abs(dsHWDue - qteHWDue) > 1 || Math.abs(qteHWDue - oppHWDue) > 1
                   ||Math.abs(oppLICDue - dsLICDue) > 1 || Math.abs(dsLICDue - qteLICDue) > 1 || Math.abs(qteLICDue - oppLICDue) > 1));
                if(totalDueCheck){
                       reasonList.add('The system has detected a change in the Total Hardware Due or Total License Due on the opportunity compared to the DocuSign. This may be due to a change in the tax calculation, shipping address, shipping and handling charge, or product pricing.');
                       resolutionList.add('If the change to the Total Hardware Due or Total License Due is intentional, have the Customer sign a new Order Form for the updated values. If this was an unintentional change, revert the opportunity to the original values and resubmit to Closing.');
                   }
        //4/3/24 --END-- (GTMS-19973)
                //Vijaychandra GTMS-15223 Added Selected Payment Type field in to the order validation.--start
                
                if((opp.Selected_Payment_Type__c != null && docusign.Selected_Payment_Type__c != null && opp.SBQQ__PrimaryQuote__r.Selected_Payment_Type__c != null) &&  
                   ((opp.Selected_Payment_Type__c != docusign.Selected_Payment_Type__c)||(opp.Selected_Payment_Type__c != opp.SBQQ__PrimaryQuote__r.Selected_Payment_Type__c))){
                       
                       reasonList.add('Mismatch Payment Type on Order Form/SFDC');
                       resolutionList.add('Align Payment Type on Order Form/SFDC');
                       
                       opp.Credit_Analyst_Kickback_Note__c = 'There is a potential mismatch between the selected payment type in SFDC and Order Form. These need to match 1:1 for auditing purposes. A correction is needed to proceed.';
                       updatedOpportunityFields.add(Opportunity.Credit_Analyst_Kickback_Note__c);
                       
                   }
                //GTMS-15223 Added Selected Payment Type field in to the order validation.--End 
                
                //11/09/23 Vijaychandra --START-- (GTMS-16316) : Adding VAT Logic for EMEA deals
                if((Opp.CurrencyIsoCode == 'GBP' || Opp.CurrencyIsoCode == 'EUR') && opp.Shipping_Country__c != null && opp.Amount <> 0){
                    if(emeaVatCheck(opp)){
                        reasonList.add('VAT Discrepancy');
                        resolutionList.add('Ensure VAT number and rate correct');
                    }
                }
                //--END-- (GTMS-16316)
                
                //12/6/23 Vijaychandra --START-- (GTMS-16121): Added Shipping And Handling Validation check between Qte/Opp/OF
                if(opp.Shipping_And_Handling__c != opp.SBQQ__PrimaryQuote__r.Shipping_And_Handling__c || opp.SBQQ__PrimaryQuote__r.Shipping_And_Handling__c != docusign.Shipping_And_Handling__c || docusign.Shipping_And_Handling__c != opp.Shipping_And_Handling__c){
                    reasonList.add('S&H not matching Docusign');
                    resolutionList.add('Please align SFDC S&H to Docusign. Email Order Ops');
                    opp.Credit_Analyst_Kickback_Note__c = 'If S&H value has changed as a result of an update in shipping method, please generate a new order form.';
                    updatedOpportunityFields.add(Opportunity.Credit_Analyst_Kickback_Note__c);
                }
                //--END-- (GTMS-16121)
                
                //12/5/23 Vijaychandra --START-- (GTMS-17284): Added Payment_Terms Validation check between Qte/Opp/OF
                if(((opp.CurrencyIsoCode == 'EUR' || opp.CurrencyIsoCode == 'GBP')&&(Opp.Payment_Terms__c != opp.SBQQ__PrimaryQuote__r.Payment_Terms__c || opp.SBQQ__PrimaryQuote__r.Payment_Terms__c != docusign.Payment_Terms__c || docusign.Payment_Terms__c != opp.Payment_Terms__c))){
                    cvsReview = true;
                    omReasonCode = 'Deal was routed to OM review because there is a Mismatch between Opportunity, Docusign and Primary Quote Payment Term values';//GTMS-20040
                    //03/22/24 Vijaychandra (GTMS-19691): Adding reason for the CVS Review.
                    //opp.Credit_Analyst_Kickback_Note__c = 'Deal was routed to OM review because there is a Mismatch between Opportunity, Docusign and Primary Quote Payment Term values';
                  //updatedOpportunityFields.add(Opportunity.Credit_Analyst_Kickback_Note__c);
                    if(!Test.isRunningTest()){ break;}
                }
                //--END-- (GTMS-17284)
                
                // added for GTMS-27988  - starts here
                if(opp.SBQQ__PrimaryQuote__r.Total_License_Price__c != docusign.Total_License_Cost__c ) {
                    cvsReview = true;
                    omReasonCode = 'Deal was routed to OM review because there is a mismatch on Total License Cost on Primary Quote and DocuSign';
                    if(!Test.isRunningTest()){ break;}
                }
                // added for GTMS-27988  - ends here
                //GTMS-29409 Start OVA-EXPANSION: Future Free Months Validation Checks
                if (opp.Subsidy_Amount__c != 0 && (opp.Deal_Components__c != null && opp.Deal_Components__c == 'Future Free Months')) {
                    
                    Boolean quoteHas = (opp.SBQQ__PrimaryQuote__r?.Number_of_months_of_Free_service__c != null && opp.SBQQ__PrimaryQuote__r?.Number_of_months_of_Free_service__c != 0);
                    Boolean docusignHas = (docusign.Number_of_Months_of_Free_Service__c != null && docusign.Number_of_Months_of_Free_Service__c != 0);
                    if ((quoteHas || docusignHas) && opp.SBQQ__PrimaryQuote__r?.Number_of_months_of_Free_service__c != docusign.Number_of_Months_of_Free_Service__c) {
                        reasonList.add('The system has detected a change in the Number of Free Months in CPQ compared to the DocuSign');
                        resolutionList.add('If the change to the Number of Free Months is intentional, the Customer must sign a new Order Form with the updated values. If this was an unintentional change, revert CPQ to the original values and resubmit to Closing');
                    }
                    
                    Boolean quoteHasAmt = (opp.SBQQ__PrimaryQuote__r?.Future_Free_Months_Amount__c != null && opp.SBQQ__PrimaryQuote__r?.Future_Free_Months_Amount__c != 0);
                    Boolean docusignHasAmt = (docusign.Future_Free_Months_Amount__c != null && docusign.Future_Free_Months_Amount__c != 0);
                    Boolean oppHasAmt = (opp.Subsidy_Amount__c != null && opp.Subsidy_Amount__c != 0);
                    Decimal oppSubsidyAbs = oppHasAmt ? Math.abs(opp.Subsidy_Amount__c) : 0;
                    if ((quoteHasAmt || docusignHasAmt || oppHasAmt) && (opp.SBQQ__PrimaryQuote__r?.Future_Free_Months_Amount__c != docusign.Future_Free_Months_Amount__c || opp.SBQQ__PrimaryQuote__r?.Future_Free_Months_Amount__c != oppSubsidyAbs || docusign.Future_Free_Months_Amount__c != oppSubsidyAbs)) {
                        reasonList.add('The system has detected a change in the Free Service Amount in CPQ compared to the DocuSign');
                        resolutionList.add('If the change to the Free Service Amount is intentional, the Customer must sign a new Order Form with the updated amounts. If this was an unintentional change, revert CPQ to the original values and resubmit to Closing');
                    }
                    
                    Boolean oppHasTax = (opp.Temp_FFM_Tax__c != null && opp.Temp_FFM_Tax__c != 0);
                    Boolean docusignHasTax = (docusign.Temp_FFM_Tax__c != null && docusign.Temp_FFM_Tax__c != 0);
                    Decimal oppTaxAbs = oppHasTax ? Math.abs(opp.Temp_FFM_Tax__c) : 0;
                    Decimal docusignTaxAbs = docusignHasTax ? Math.abs(docusign.Temp_FFM_Tax__c) : 0;
                    if ((oppHasTax || docusignHasTax) && oppTaxAbs != docusignTaxAbs) {
                        reasonList.add('The system has detected a change in the Free Service Tax Amount in CPQ compared to the DocuSign');
                        resolutionList.add('If the change to the Free Service Amount tax is due to a change in the Free Service Amount, the Customer must sign a new Order Form with the updated amounts. If this change is unintentional, please check with the Tax team');
                    }
                    
                    Boolean quoteHasSubsidy = (opp.SBQQ__PrimaryQuote__r?.Subsidy_Amount__c != null && opp.SBQQ__PrimaryQuote__r?.Subsidy_Amount__c != 0);
                    Boolean rebateHasAmt = (opp.Sum_of_Rebates__c != null && opp.Sum_of_Rebates__c != 0);
                    Decimal quoteSubsidyAbs = quoteHasSubsidy ? Math.abs(opp.SBQQ__PrimaryQuote__r?.Subsidy_Amount__c) : 0;
                    Decimal rebateAbs = rebateHasAmt ? Math.abs(opp.Sum_of_Rebates__c) : 0;
                    if ((quoteHasSubsidy || rebateHasAmt) && Math.abs(quoteSubsidyAbs - rebateAbs) > 1) {
                        cvsReview = true;
                        omReasonCode = 'Deal was routed to OM review because the Sum of Subsidy in CPQ does not match the Sum of Rebates on the Opportunity';
                    }
                }
                //GTMS-29409 ends
                //TC-0010 
                //Confirm payment terms
                
                string pTerms = opp.Payment_Terms__c != null ? opp.Payment_Terms__c : '';//10/30/23 Vijaychandra (GTMS-16312)
                string ipTerms = opp.Initial_Payment_Terms__c != null ? opp.Initial_Payment_Terms__c : '';//10/30/23 Vijaychandra (GTMS-16312)
                if(pTerms.contains('Net') && ipTerms.contains('Net') && opp.Subsidy_Amount__c != 0 && (opp.Deal_Components__c != null && opp.Deal_Components__c == 'Future Free Months')){
                    Decimal firstInvoiceAmount = frstInvAmntCalcMthd1(opp);
                    firstInvoiceAmount = firstInvoiceAmount.setScale(2, RoundingMode.HALF_UP);
                    if(firstInvoiceAmount != 0) {
                        opp.First_Invoice_Total__c = firstInvoiceAmount;
                        updatedOpportunityFields.add(Opportunity.First_Invoice_Total__c);
                    }
                  Set<String> supportedPaymentTypes = new Set<String>{SYSTEM.LABEL.Direct_Annual_Payment_Type, SYSTEM.LABEL.Direct_Monthly_Payment_Type,SYSTEM.LABEL.Direct_Quarterly_Payment_Type, SYSTEM.LABEL.Direct_Semi_Annual_Payment_Type};
                    if(!cvsReview && opp.First_Invoice_Total__c != null && supportedPaymentTypes.contains(opp.Selected_Payment_Type__c)) {
                        Decimal docusignPaymentAmount = null;
                        String paymentTypeMismatch = '';
                        
                        if(opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Annual_Payment_Type) {
                            docusignPaymentAmount = docusign.First_Annual_Payment__c;
                            paymentTypeMismatch = 'First Annual Payment';
                        } else if(opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Monthly_Payment_Type) {
                            docusignPaymentAmount = docusign.First_Month_Payment__c;
                            paymentTypeMismatch = 'First Monthly Payment';
                        } else if(opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Quarterly_Payment_Type) {
                            docusignPaymentAmount = docusign.First_Quarter_Payment__c;
                            paymentTypeMismatch = 'First Quarterly Payment';
                        } else if(opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Semi_Annual_Payment_Type) {
                            docusignPaymentAmount = docusign.First_Semi_Annual_Payment__c;
                            paymentTypeMismatch = 'First Semi Annual Payment';
                        }
                        if(Math.abs(Math.abs(nullCheck(opp.First_Invoice_Total__c)) - Math.abs(nullCheck(docusignPaymentAmount))) > 1) {
                            cvsReview = true;
                            omReasonCode = 'Deal was routed to OM review because First Invoice Total on Opportunity is not equal to ' + paymentTypeMismatch + ' on DocuSign';
                            if(!Test.isRunningTest()){ break;}
                        }
                    }
                }
                
                if (opp.Payment_Terms__c == 'Due in advance' && opp.Initial_Payment_Terms__c == 'Due in advance') {
                    if (opp.Amount_Received__c == null) {
                        
                        reasonList.add('Missing 1st payment');
                        resolutionList.add('Customer must complete checkout link');
                        
                    }else if(opp.License_Term__c != null){
                        Decimal firstInvoiceAmount = frstInvAmntCalcMthd(opp);
                        
                        firstInvoiceAmount = firstInvoiceAmount.setScale(2, RoundingMode.HALF_UP);
                        if(firstInvoiceAmount != 0) opp.First_Invoice_Total__c = firstInvoiceAmount;
                        updatedOpportunityFields.add(Opportunity.First_Invoice_Total__c);
                        
                        if((Math.abs(nullCheck(opp.Amount_Received__c) - nullCheck(opp.First_Invoice_Total__c)) > 1)){
                            
                            cvsReview = true;
                            omReasonCode = 'Deal was routed to OM review becauseAmount Received is not equals to First Invoice Total of the Opportunity.';//GTMS-20040
                            //03/22/24 Vijaychandra (GTMS-19691): Adding reason for the CVS Review.
                            //opp.Credit_Analyst_Kickback_Note__c = 'Deal was routed to OM review becauseAmount Received is not equals to First Invoice Total of the Opportunity.';
                      //updatedOpportunityFields.add(Opportunity.Credit_Analyst_Kickback_Note__c);
                            //DMLWrapper.doUpdate(opp, new List<SObjectField>{Opportunity.CVS_Review__c,Opportunity.First_Invoice_Total__c,Opportunity.StageName});
                            if(!Test.isRunningTest()){ break;}
                        }
                    }
                    //11/01/23 Vijaychandra --START-- (GTMS-16312) : Added Net terms logic for different owner segments
                   //22/03/24 Vijaychandra (GTMS-19686): Replaced opp.Account.First_Purchase_Opportunity__r.Payment_Terms__c with opp.Account.Payment_Terms__c in below if condtion.
                }else if(pTerms.contains('Net') && ipTerms.contains('Net') && opp.SBQQ__PrimaryQuote__r.Customer_Preferred_Payment_Method__c == 'Credit Card/ACH Debit' && opp.SBQQ__PrimaryQuote__r.Checkout_Link__c ==null){
                      	 Boolean isValidOppReseller = opp.Reseller__c != null && opp.Reseller__r.Partner_Agreement_Accepted__c != null;
                    if(((opp.Selected_Payment_Type__c == SYSTEM.LABEL.DIRECT_ANNUAL_PAYMENT_TYPE || opp.Selected_Payment_Type__c == SYSTEM.LABEL.DIRECT_MONTHLY_PAYMENT_TYPE || opp.Selected_Payment_Type__c == SYSTEM.LABEL.UPFRONT_PAYMENT_TYPE || opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Semi_Annual_Payment_Type || opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Quarterly_Payment_Type)
                       && (opp.Owner_Segment__c == SYSTEM.LABEL.AE2_OWNER_SEGMENT || opp.Owner_Segment__c == SYSTEM.LABEL.AE3_OWNER_SEGMENT)
                       && !opp.First_Purchase__c && opp.SBQQ__RenewedContract__c == NULL
                       && (opp.Payment_Terms__c != opp.Account.Payment_Terms__c || opp.Initial_Payment_Terms__c != opp.Account.Payment_Terms__c)
                       && opp.CurrencyIsoCode != 'EUR' && opp.CurrencyIsoCode != 'GBP' && !isValidOppReseller)){
                           
                           cvsReview = true;
                           omReasonCode = 'Deal was routed to OM review because Initial Payment Terms, Payment Terms do not match Account Payment Terms';//GTMS-20040
                           //22/03/24 Vijaychandra (GTMS-19686): Added credit Analyst kckback note mapping as per the request by business.
                   //03/22/24 Vijaychandra (GTMS-19691): Adding reason for the CVS Review.
                           //opp.Credit_Analyst_Kickback_Note__c = 'Deal was routed to OM review because Initial Payment Terms, Payment Terms do not match Account Payment Terms';
                            //updatedOpportunityFields.add(Opportunity.Credit_Analyst_Kickback_Note__c);
                           if(!Test.isRunningTest()){ break;}
                        //4/9/24 Vijaychandra --START-- (GTMS-20151)&(GTMS-20152): removed below functinoality for Mexico customers and replaced KB reasons and resolutiosn with CVS Review.   
                       }else if(((opp.Selected_Payment_Type__c == SYSTEM.LABEL.DIRECT_ANNUAL_PAYMENT_TYPE || opp.Selected_Payment_Type__c == SYSTEM.LABEL.UPFRONT_PAYMENT_TYPE || opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Monthly_Payment_Type || opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Semi_Annual_Payment_Type || opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Quarterly_Payment_Type)
                                && opp.First_Purchase__c && opp.Owner_Segment__c == SYSTEM.LABEL.AE2_OWNER_SEGMENT && opp.Account.Billing_Stripe_Customer_Id__c == NULL
                                && opp.CurrencyIsoCode != 'EUR' && opp.CurrencyIsoCode != 'GBP')){
                               cvsReview = true;
                                omReasonCode = (opp.CurrencyIsoCode == 'MXN') ? System.label.OVA_OM_Review_Code_For_1st_Purchase_Net_Terms_Mexico_Deals
                                                     : System.label.OVA_OM_Review_Code_for_1st_Purchase_Net_Terms_Non_Mexico_Deals;
                               //reasonList.add('No Payment Method on File');
                               //resolutionList.add('Have Customer Complete Capture Link');
                       }
                }
                //11/01/23 --END-- (GTMS-16312)
                
                //TC-001
                if (opp.Buyout_Amount__c != 0 || opp.Buyout_Opportunity__c != null /*Commented as part of GTMS-29409 || opp.Subsidy_Amount__c != 0 || opp.Subsidy_Opportunity__c != Null*/) {
                    reasonList.add('Incorrect Buyout Amount in SFDC');
                    resolutionList.add('Remove Buyout Amount from SFDC');
                }
                
                //TC-002
                if (opp.Sales_Tax__c == 99999.99) {
                    reasonList.add('Tax listed as $99K in error');
                    resolutionList.add('Email Sales Ops');
                }
                
                //TC-003
                if (opp.Shipping_and_Handling__c == 99999.99) {
                    reasonList.add('S&H listed as $99k in error');
                    resolutionList.add('Email Order Ops');
                }
                
                //TC-004
                if (opp.CurrencyIsoCode != opp.Account.CurrencyIsoCode) {
                    reasonList.add('Mismatch currency on Order Form/ SFDC');
                    resolutionList.add('Align currency on Order Form/SFDC');
                }
                
                else if((oppHwProds == qteHwProds) && (qteHwProds == dsHwProds) && (oppLicProds == qteLicProds) && (qteLicProds == dsLicProds)){System.debug('products count matched');} 
                else{
                    reasonList.add('Difference in products on order form/sfdc');
                    resolutionList.add('Align Products in SFDC with Order Form');
                }
                //TC-007
                System.debug('opp.Sales_Tax__c'+opp.Sales_Tax__c);
                if ((opp.Sales_Tax_Amount__c> docusign.Sales_Tax_Amount__c) || (opp.Sales_Tax_Amount__c != docusign.Sales_Tax_Amount__c) ||
                    (opp.Sales_Tax_Amount__c != opp.SBQQ__PrimaryQuote__r.Sales_Tax__c)) {
                        System.debug('value ' + docusign.Sales_Tax_Amount__c);
                        //String resolutionValue = 'Please have customer confirm updated Tax Amount';
                        //5/9/24 Vijaychandra --START-- (GTMS-20597): replaced Please have customer confirm updated Tax Amount with Need customer authorization to process balance due
                        reasonList.add('Tax Discrepancy');
                        resolutionList.add('Need customer authorization to process balance due');
                    }
                //TC-008
                if (opp.SBQQ__PrimaryQuote__r.SBQQ__Status__c != 'Approved') {
                    reasonList.add('Primary Quote Not Approved');
                    resolutionList.add(' Approve Primary Quote');
                }
                
                if(Date.today() > opp.SBQQ__PrimaryQuote__r.Latest_Close_Date__c){
                    reasonList.add('Close Date has exceeded Latest Close date');
                    resolutionList.add('Please update close date to today');
                }else if(opp.CurrencyIsoCode == 'GBP' || opp.CurrencyIsoCode == 'Eur'){
                    kickBackWrapper kbWrap = closeDateChkMthd(opp);
                    if(kbWrap != null){
                        reasonList.addAll(kbWrap.reason);
                        resolutionList.addAll(kbWrap.resolution);
                    }
                }
                
                validated = (reasonList.isEmpty()&&resolutionList.isEmpty() && !cvsReview && kickbackReasons.isempty());                
                
                    if (validated || Test.isRunningTest()) {

                    //10/18/23 Vijachandra (GTMS-16034): Added CurrencyIsoCode condtion in below If statement for EMEA deals
                    //10/23/23 Vijaychandra (GTMS-16034): Removed CurrencyIsoCode condition in below statemane for EMEA deals after getting clarification from business(||opp.CurrencyIsoCode == 'GBP'||opp.CurrencyIsoCode == 'EUR')
                    if (opp.Payment_Method__c == 'Credit Card' && opp.Account.BillingCountry == 'United States') {
                        opp.Payment_Processing_Fee__c = true;
                        updatedOpportunityFields.add(Opportunity.Payment_Processing_Fee__c);
                    }
                    if (opp.Payment_Token__c == null && opp.Payment_Terms__c == 'Due in advance') {
                        opp.Payment_Terms__c = 'Net 5';
                        opp.Initial_Payment_Terms__c = 'Net 5';
                        updatedOpportunityFields.add(Opportunity.Payment_Terms__c);
                        updatedOpportunityFields.add(Opportunity.Initial_Payment_Terms__c);
                    } 
                    if (opp.First_Purchase__c == true &&
                        //10/17/23Vijaychandra --START-- (GTMS-16035) : Added below conditon for OVA Phase2
                        ((Opp.Payment_Terms__c == 'Due In Advance') ||(Opp.Payment_Terms__c != 'Due In Advance' && (opp.Amount_Received__c == null || opp.Amount_Received__c == 0) && Opp.Owner_Segment__c == SYSTEM.LABEL.AE2_OWNER_SEGMENT && Opp.Account.Billing_Stripe_Customer_Id__c != null))) {
                            //10/17/23 --END-- (GTMS-16035)
                            DMLWrapper.doUpdate(
                                new Account(
                                    Id = opp.AccountId,
                                    New_Billing_Process_Approved__c = true
                                ),
                                new List<SObjectField>{
                                    Account.New_Billing_Process_Approved__c
                                        }
                            );
                        }
                    //opp.PO_Number__c = opp.SBQQ__PrimaryQuote__r.Name;
                    opp.StageName = 'Orders Processing';
                    opp.Finance_Kickback_Reason__c = null;
                    opp.Finance_Kickback_Resolution__c = null;
                    opp.Bypass_Validation_rule__c = true;
                    opp.Bypass_Validation_Rule_DateTime__c = System.now();
                    if(Opp.CurrencyIsoCode != 'EUR' && Opp.CurrencyIsoCode != 'GBP'){opp.CloseDate = Date.today();}
                    //opp.CloseDate = (Opp.CurrencyIsoCode != 'EUR' && Opp.CurrencyIsoCode != 'GBP') ? Date.today() : Opp.CloseDate;
                    //added for GTMS-13116 
                    if(String.isEmpty(opp.Opportunity_Tracking__c)) {
                        opp.Opportunity_Tracking__c = 'Order Processing set By OrderValidationAutomation';
                    }
                    else {
                        opp.Opportunity_Tracking__c = opp.Opportunity_Tracking__c + ';Order Processing set By OrderValidationAutomation';
                    }
                    updatedOpportunityFields.add(Opportunity.Opportunity_Tracking__c);
                    //updatedOpportunityFields.add(Opportunity.PO_Number__c);
                    updatedOpportunityFields.add(Opportunity.StageName);
                    updatedOpportunityFields.add(Opportunity.Bypass_Validation_rule__c);
                    updatedOpportunityFields.add(Opportunity.CloseDate);
                    updatedOpportunityFields.add(Opportunity.Finance_Kickback_Reason__c);
                    updatedOpportunityFields.add(Opportunity.Finance_Kickback_Resolution__c);
                }
            }
        } 
        return new ValidationWrapper(cvsReview, updatedOpportunityFields, new KickbackWrapper(reasonList,resolutionList),opp,omReasonCode);
    }
    //--END-- (GTMS-16637)
    //11/11/23 Vijaychandra --START--  Moved below code block from performValidation method to below method
    /***************
    * Description: This method contains logic to calculate first Invoice Amount Total value
    * @Param: opp (Opportunity Record)
    * *************/
    public static Decimal frstInvAmntCalcMthd(Opportunity opp){
        Decimal firstInvoiceAmount;
        
        Boolean isCreditCard                   = (opp.Payment_Method__c == 'Credit Card');
        
        Decimal licenseTermCPQ                 = nullCheck(opp.License_Term_CPQ__c,1);
        Decimal totalLicenseDue                = nullCheck(opp.Total_License_Due__c);
        Decimal licenseSalesTax                = nullCheck(opp.License_Sales_Tax_CPQ__c);
        Decimal totalHardwareDue               = nullCheck(opp.Total_Hardware_Due__c);
        Decimal hardwareSalesTax               = nullCheck(opp.Hardware_Sales_Tax_CPQ__c);
        Decimal shippingAndHandling            = nullCheck(opp.Shipping_and_Handling__c);
        Decimal salesTaxAmount                 = nullCheck(opp.Sales_Tax_Amount__c);
        
        Decimal licenseDueDivByTerm            = (totalLicenseDue / licenseTermCPQ);
        Decimal licenseSalesTaxDivByTerm       = (licenseSalesTax / licenseTermCPQ);
        Decimal licenseDueDivByTermAnnual      = (licenseDueDivByTerm * 12);
        Decimal licenseDueDivByTermQuarterly      = (licenseDueDivByTerm * 3);
        Decimal licenseDueDivByTermSemiAnnual      = (licenseDueDivByTerm * 6);
        Decimal licenseSalesTaxDivByTermQuarterly = (licenseSalesTaxDivByTerm * 3);
        Decimal licenseSalesTaxDivByTermSemiAnnual = (licenseSalesTaxDivByTerm * 6);
        Decimal licenseSalesTaxDivByTermAnnual = (licenseSalesTaxDivByTerm * 12);
        Decimal totalHardwareDuePlusTaxes      = (totalHardwareDue + hardwareSalesTax);
        Decimal salesTaxMinusLicenseTax        = (salesTaxAmount - licenseSalesTax);
        
        System.debug(LoggingLevel.FINER, String.format(
            'licenseDueDivByTerm: {0}\nlicenseSalesTaxDivByTerm: {1}\nlicenseDueDivByTermAnnual: {2}\nlicenseSalesTaxDivByTermAnnual: {3}\ntotalHardwareDue: {4}\ntotalHardwareDuePlusTaxes: {5}\nshippingAndHandling: {6}\nsalesTaxMinusLicenseTax: {7}',
            new List<Decimal>{ licenseDueDivByTerm, licenseSalesTaxDivByTerm, licenseDueDivByTermAnnual, licenseSalesTaxDivByTermAnnual, totalHardwareDue, totalHardwareDuePlusTaxes, shippingAndHandling, salesTaxMinusLicenseTax}
        ));
        
        Set<String> otherCurrencies = new Set<String>{
            'CAD', 'MXN','EUR','GBP'
                };
                    //10/30/23 Vijaychandra (GTMS-16312) : add EUR and GBP in below IF condtion to extend logic for EMEA
                    if (opp.CurrencyISOCode == 'USD'){
                        if (opp.Selected_Payment_Type__c == SYSTEM.Label.Direct_Annual_Payment_Type){
                            Decimal processingFee = 0;
                            if (isCreditCard) processingFee = ((licenseDueDivByTermAnnual + totalHardwareDue) * CREDIT_CARD_PROCESSING_FEE_MULTIPLIER);
                            
                            System.debug(LoggingLevel.FINER, 'processingFee: '+processingFee);
                            
                            // OK
                            /*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- Start*/
                            if(opp.Billing_360_Transaction__c && opp.SBQQ__PrimaryQuote__c!= NULL && opp.SBQQ__PrimaryQuote__r.First_Annual_Payment__c!= NULL){
                                if (isCreditCard) processingFee = ((opp.SBQQ__PrimaryQuote__r.Prorated_Amount__c + totalHardwareDue) * CREDIT_CARD_PROCESSING_FEE_MULTIPLIER);
                                firstInvoiceAmount = opp.SBQQ__PrimaryQuote__r.First_Annual_Payment__c+processingFee;
                            }else{/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                            firstInvoiceAmount = sumValues(
                                new List<Decimal>{
                                    licenseDueDivByTermAnnual,
                                        totalHardwareDue,
                                        processingFee,
                                        licenseSalesTaxDivByTermAnnual,
                                        salesTaxMinusLicenseTax,
                                        shippingAndHandling
                                        }
                            );
                                }/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                        }else if (opp.Selected_Payment_Type__c == SYSTEM.Label.Direct_Monthly_Payment_Type){
                            Decimal processingFee = 0;
                            if (isCreditCard) processingFee = ((licenseDueDivByTerm + totalHardwareDue) * CREDIT_CARD_PROCESSING_FEE_MULTIPLIER);
                            System.debug(LoggingLevel.FINER, 'processingFee: '+processingFee);
                            
                            // OK
                            firstInvoiceAmount = sumValues(
                                new List<Decimal>{
                                    licenseDueDivByTerm,
                                        totalHardwareDue,
                                        processingFee,
                                        licenseSalesTaxDivByTerm,
                                        salesTaxMinusLicenseTax,
                                        shippingAndHandling
                                        }
                            );
                        }else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Upfront_Payment_Type){
                            Decimal processingFee = 0;
                            if (isCreditCard) processingFee = ((totalLicenseDue + totalHardwareDue) * CREDIT_CARD_PROCESSING_FEE_MULTIPLIER);
                            System.debug(LoggingLevel.FINER, 'processingFee: '+processingFee); 
                            
                            // OK
                            firstInvoiceAmount = sumValues(
                                new List<Decimal>{
                                    totalLicenseDue,
                                        totalHardwareDue,
                                        processingFee,
                                        licenseSalesTax,
                                        salesTaxMinusLicenseTax,
                                        shippingAndHandling
                                        }
                            );
                        }else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Quarterly_Payment_Type){
                          Decimal processingFee = 0;
                          if (isCreditCard) processingFee = ((licenseDueDivByTermQuarterly + totalHardwareDue) * CREDIT_CARD_PROCESSING_FEE_MULTIPLIER);
                            System.debug(LoggingLevel.FINER, 'processingFee: '+processingFee);
                            // OK
                            /*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- Start*/
                            if(opp.Billing_360_Transaction__c && opp.SBQQ__PrimaryQuote__c!= NULL && opp.SBQQ__PrimaryQuote__r.First_Quarter_Payment__c!= NULL){
                                if (isCreditCard) processingFee = ((opp.SBQQ__PrimaryQuote__r.Prorated_Amount__c + totalHardwareDue) * CREDIT_CARD_PROCESSING_FEE_MULTIPLIER);
                                firstInvoiceAmount = opp.SBQQ__PrimaryQuote__r.First_Quarter_Payment__c+processingFee;
                            }else{/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                            firstInvoiceAmount = sumValues(
                                new List<Decimal>{
                                    licenseDueDivByTermQuarterly,
                                        totalHardwareDue,
                                        processingFee,
                                        licenseSalesTaxDivByTermQuarterly,
                                        salesTaxMinusLicenseTax,
                                        shippingAndHandling
                                        }
                            );
                            }/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                        }else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Semi_Annual_Payment_Type){
                            Decimal processingFee = 0;
                            if (isCreditCard) processingFee = ((licenseDueDivByTermSemiAnnual + totalHardwareDue) * CREDIT_CARD_PROCESSING_FEE_MULTIPLIER);
                            
                            System.debug(LoggingLevel.FINER, 'processingFee: '+processingFee);
                            
                            // OK
                            /*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- Start*/
                            if(opp.Billing_360_Transaction__c && opp.SBQQ__PrimaryQuote__c!= NULL && opp.SBQQ__PrimaryQuote__r.First_Semi_Annual_Payment__c!= NULL){
                                if (isCreditCard) processingFee = ((opp.SBQQ__PrimaryQuote__r.Prorated_Amount__c + totalHardwareDue) * CREDIT_CARD_PROCESSING_FEE_MULTIPLIER);
                                firstInvoiceAmount = opp.SBQQ__PrimaryQuote__r.First_Semi_Annual_Payment__c+processingFee;
                            }else{/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                            firstInvoiceAmount = sumValues(
                                new List<Decimal>{
                                    licenseDueDivByTermSemiAnnual,
                                        totalHardwareDue,
                                        processingFee,
                                        licenseSalesTaxDivByTermSemiAnnual,
                                        salesTaxMinusLicenseTax,
                                        shippingAndHandling
                                        }
                            );
                            }/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                        }
                    }else if (otherCurrencies.contains(opp.CurrencyISOCode)){
                        Decimal salesTaxMinusLicenseTaxAndHW = (salesTaxMinusLicenseTax - hardwareSalesTax);
                        System.debug(LoggingLevel.FINER, 'salesTaxMinusLicenseTaxAndHW: '+salesTaxMinusLicenseTaxAndHW);
                        
                        if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.DIRECT_MONTHLY_PAYMENT_TYPE){
                            // OK
                            firstInvoiceAmount = sumValues(
                                new List<Decimal>{
                                    licenseDueDivByTerm,
                                        licenseSalesTaxDivByTerm,
                                        totalHardwareDuePlusTaxes,
                                        salesTaxMinusLicenseTaxAndHW,
                                        shippingAndHandling
                                        }
                            );
                        }else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.DIRECT_ANNUAL_PAYMENT_TYPE){
                            // OK
                            /*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- Start*/
                            if(opp.Billing_360_Transaction__c && opp.SBQQ__PrimaryQuote__c!= NULL && opp.SBQQ__PrimaryQuote__r.First_Annual_Payment__c!= NULL){
                                firstInvoiceAmount = opp.SBQQ__PrimaryQuote__r.First_Annual_Payment__c;
                            }else{/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                            firstInvoiceAmount = sumValues(
                                new List<Decimal>{
                                    licenseDueDivByTermAnnual,
                                        licenseSalesTaxDivByTermAnnual,
                                        totalHardwareDuePlusTaxes,
                                        salesTaxMinusLicenseTaxAndHW,
                                        shippingAndHandling
                                        }
                            );
                            }/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                        }else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.UPFRONT_PAYMENT_TYPE){
                            firstInvoiceAmount = sumValues(
                                new List<Decimal>{
                                    totalLicenseDue,
                                        licenseSalesTax,
                                        totalHardwareDuePlusTaxes,
                                        salesTaxMinusLicenseTaxAndHW,
                                        shippingAndHandling
                                        }
                            );
                        }else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Quarterly_Payment_Type){
                            /*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- Start*/
                            if(opp.Billing_360_Transaction__c && opp.SBQQ__PrimaryQuote__c!= NULL && opp.SBQQ__PrimaryQuote__r.First_Quarter_Payment__c!= NULL){
                                firstInvoiceAmount = opp.SBQQ__PrimaryQuote__r.First_Quarter_Payment__c;
                            }else{/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                            firstInvoiceAmount = sumValues(
                                new List<Decimal>{
                                    licenseDueDivByTermQuarterly,
                                        licenseSalesTaxDivByTermQuarterly,
                                        totalHardwareDuePlusTaxes,
                                        salesTaxMinusLicenseTaxAndHW,
                                        shippingAndHandling
                                        }
                            );
                            }/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                        }else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Semi_Annual_Payment_Type){
                            // OK
                            /*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- Start*/
                            if(opp.Billing_360_Transaction__c && opp.SBQQ__PrimaryQuote__c!= NULL && opp.SBQQ__PrimaryQuote__r.First_Semi_Annual_Payment__c!= NULL){
                                firstInvoiceAmount = opp.SBQQ__PrimaryQuote__r.First_Semi_Annual_Payment__c;
                            }else{/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                            firstInvoiceAmount = sumValues(
                                new List<Decimal>{
                                    licenseDueDivByTermSemiAnnual,
                                        licenseSalesTaxDivByTermSemiAnnual,
                                        totalHardwareDuePlusTaxes,
                                        salesTaxMinusLicenseTaxAndHW,
                                        shippingAndHandling
                                        }
                            );
                            }/*Billing360 New CR for First Invoice Payment field from OVA -- Abu -- 9/8/2025 -- End*/
                        }
                    }
        
        System.debug(LoggingLevel.FINER, 'FIRST INVOICE TOTAL AMOUNT: '+firstInvoiceAmount);
        return firstInvoiceAmount;
    }
    //11/11/23 Vijaychandra --END--
    // GTMS-31221-OVA-EXPANSION: New calculation method for Free Months rebates
    public static Decimal frstInvAmntCalcMthd1(Opportunity opp) {
        Decimal firstInvoiceAmount;
        Decimal licenseTermCPQ = nullCheck(opp.License_Term_CPQ__c, 1);
        Decimal totalLicenseDue = nullCheck(opp.Total_License_Due__c);
        Decimal licenseSalesTax = nullCheck(opp.License_Sales_Tax_CPQ__c);
        Decimal totalHardwareDue = nullCheck(opp.Total_Hardware_Due__c);
        Decimal hardwareSalesTax = nullCheck(opp.Hardware_Sales_Tax_CPQ__c);
        Decimal shippingAndHandling = nullCheck(opp.Shipping_and_Handling__c);
    
        Decimal licenseDueDivByTerm = (totalLicenseDue / licenseTermCPQ);
        Decimal licenseSalesTaxDivByTerm = (licenseSalesTax / licenseTermCPQ);
        Decimal licenseDueDivByTermAnnual = (licenseDueDivByTerm * 12);
        Decimal licenseDueDivByTermQuarterly = (licenseDueDivByTerm * 3);
        Decimal licenseDueDivByTermSemiAnnual = (licenseDueDivByTerm * 6);
        Decimal licenseSalesTaxDivByTermQuarterly = (licenseSalesTaxDivByTerm * 3);
        Decimal licenseSalesTaxDivByTermSemiAnnual = (licenseSalesTaxDivByTerm * 6);
        Decimal licenseSalesTaxDivByTermAnnual = (licenseSalesTaxDivByTerm * 12);
        Decimal totalHardwareDuePlusTaxes = (totalHardwareDue + hardwareSalesTax);
        
        Decimal futureFreeMonthsAmount = Math.abs(nullCheck(opp.SBQQ__PrimaryQuote__r?.Future_Free_Months_Amount__c));
        Decimal tempFFMTax = Math.abs(nullCheck(opp.Temp_FFM_Tax__c));
        Decimal freeServiceAndTaxTotal = (futureFreeMonthsAmount + tempFFMTax);
        
        List<String> otherCurrencies = new List<String>{'CAD', 'MXN','EUR','GBP'};
            
            if (opp.CurrencyISOCode == 'USD') {
                if (opp.Selected_Payment_Type__c == SYSTEM.Label.Direct_Annual_Payment_Type) {
                    firstInvoiceAmount = licenseDueDivByTermAnnual + licenseSalesTaxDivByTermAnnual + totalHardwareDuePlusTaxes + shippingAndHandling - freeServiceAndTaxTotal;
                } else if (opp.Selected_Payment_Type__c == SYSTEM.Label.Direct_Monthly_Payment_Type) {
                    firstInvoiceAmount = licenseDueDivByTerm + licenseSalesTaxDivByTerm + totalHardwareDuePlusTaxes + shippingAndHandling - freeServiceAndTaxTotal;
                } else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Upfront_Payment_Type) {
                    firstInvoiceAmount = totalLicenseDue + licenseSalesTax + totalHardwareDuePlusTaxes + shippingAndHandling - freeServiceAndTaxTotal;
                } else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Quarterly_Payment_Type) {
                    firstInvoiceAmount = licenseDueDivByTermQuarterly + licenseSalesTaxDivByTermQuarterly + totalHardwareDuePlusTaxes + shippingAndHandling - freeServiceAndTaxTotal;
                } else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Semi_Annual_Payment_Type) {
                    firstInvoiceAmount = licenseDueDivByTermSemiAnnual + licenseSalesTaxDivByTermSemiAnnual + totalHardwareDuePlusTaxes + shippingAndHandling - freeServiceAndTaxTotal;
                }
            } else if (otherCurrencies.contains(opp.CurrencyISOCode)) {
                Decimal shippingAndHandlingWithTax = shippingAndHandling + nullCheck(opp.SBQQ__PrimaryQuote__r?.S_H_Tax__c);
                    if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Monthly_Payment_Type) {
                        firstInvoiceAmount = licenseDueDivByTerm + licenseSalesTaxDivByTerm + totalHardwareDuePlusTaxes + shippingAndHandlingWithTax - freeServiceAndTaxTotal;
                    } else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Annual_Payment_Type) {
                        firstInvoiceAmount = licenseDueDivByTermAnnual + licenseSalesTaxDivByTermAnnual + totalHardwareDuePlusTaxes + shippingAndHandlingWithTax - freeServiceAndTaxTotal;
                    } else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Upfront_Payment_Type) {
                        firstInvoiceAmount = totalLicenseDue + licenseSalesTax + totalHardwareDuePlusTaxes + shippingAndHandlingWithTax - freeServiceAndTaxTotal;
                    } else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Quarterly_Payment_Type) {
                        firstInvoiceAmount = licenseDueDivByTermQuarterly + licenseSalesTaxDivByTermQuarterly + totalHardwareDuePlusTaxes + shippingAndHandlingWithTax - freeServiceAndTaxTotal;
                    } else if (opp.Selected_Payment_Type__c == SYSTEM.LABEL.Direct_Semi_Annual_Payment_Type) {
                        firstInvoiceAmount = licenseDueDivByTermSemiAnnual + licenseSalesTaxDivByTermSemiAnnual + totalHardwareDuePlusTaxes + shippingAndHandlingWithTax - freeServiceAndTaxTotal;
                    }
            }       
        System.debug(LoggingLevel.FINER, 'FIRST INVOICE TOTAL AMOUNT (NEW METHOD): '+firstInvoiceAmount);
        return firstInvoiceAmount;
    }
    //11/09/23 Vijaychandra --START-- (GTMS-16316) : Adding VAT Logic for EMEA deals
    /*****
    * Discription: to add VAT logic for EMEA deals
    * @Param: opp (Opportunity Record)
    * @Return: return boolean value which indicates if VAT criteria is satsfied or not
    *****/ 
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
    //--END-- (GTMS-16316) : Adding VAT Logic for EMEA deals
    
    //11/11/23 Vijaychandra --START-- (GTMS-16317) : Adding Close date check for EMEA deals
    /***************
    * Description:This method contains the Close Date critera check for EMEA deals
    * @Param: opp (Opportunity Record)
    * @Return: KickBackWrapper(contains kickbackReason and Resolution values for closedate criteria)
    * *************/
    public static KickBackWrapper closeDateChkMthd(Opportunity opp){
        List<String> reason = new List<String>();
        List<String> resolution = new List<String>();
        KickBackWrapper kbWrap;
        Datetime sysTime = System.Now();
        Date todayDate = date.today();
        Date nxtBsnsDte = calcNextBusinessDate();//calling method to return next business day //date.today().addDays(1);
        if((opp.CloseDate == todayDate || opp.CloseDate < todayDate || (opp.CloseDate > todayDate && opp.CloseDate != nxtBsnsDte)) && ((todayDate == sysTime.dateGMT() && sysTime.hourGMT()>=14)||(date.today().addDays(1) == sysTime.dateGMT() && sysTime.hourGMT()<14))){
            reason.add('Order received after shipping cutoff');
            resolution.add('Order was received after shipping cutoff (2PM GMT). Update close date to next business day and recalculate CPQ quote');
        }else if((opp.closeDate < todayDate || opp.CloseDate > todayDate) && (todayDate == sysTime.dateGMT() && sysTime.hourGMT() < 14) ){
            reason.add('Close Date is not equal to current date');
            resolution.add('Please update close date to today and recalculate CPQ');
        }
        if(!reason.isEmpty() && !resolution.isEmpty()){kbWrap = new KickBackWrapper(reason,resolution);}
        
        return kbWrap;
    }
    //--END-- (GTMS-16317) : Adding Close date check for EMEA deals
    //11/17/23 Vijaychandra --START-- (GTMS-16317) : Adding Close date check for EMEA deals.Added this method after demo ask
    public static Date calcNextBusinessDate(){
        Set<String> plusOneDaySet = new Set<String>{'Mon','Tue','Wed','Thu','Sun'};
            string weekDay = Datetime.now().format('E');
        Date nextDate = (plusOneDaySet.contains(weekDay)) ? date.today().addDays(1) : (weekDay == 'Fri') ? date.today().addDays(3) : date.today().addDays(2);
        return nextDate;
    }
    //--END-- (GTMS-16317)
    
    //12/6/23 Vijaychandra --START-- (GTMS-16637) : Added new validation for DCA project
    /***************************************************************
    * @Description: this method contains the validation checks logic
    * @Param: opp - Opportunity record which triggerd the OVA validation.
    * @Param: signedDocumentCount - count of document records related to completed docusign status record.
    * @Param: docsCountMap - Map of Opportunity Id and document record count
    */
    public static ValidationWrapper dcaValidationCheck(Opportunity opp , Integer signedDocumentCount, Map<string,Integer> docsCountMap, String B360Enabled){
        
        List<String> reasonList = new List<String>();
        List<String> resolutionList = new List<String>();
        Set<SObjectField> oppFields = new Set<SObjectField>();
        Boolean cvsReview = false;

        string omReasonCode;//GTMS-20040
        
        //Set<SObjectField> updatedOpportunityFields = new Set<SObjectField>();
        
        
        for(dsfs__DocuSign_Status__c docusign : opp.dsfs__R00N80000002fD9vEAE__r) {
            
            Boolean billingAddressCheck = (opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingStreet != docusign.Billing_Street__c || opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCity != docusign.Billing_City__c || opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingState != docusign.Billing_State__c
                                           || opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCountry != docusign.Billing_Country__c || opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingPostalCode != docusign.Billing_Postal_Code__c);
            //3/11/24 Vijaychadnra (GTMS-16641): Removed (||  opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Email != docusign.Bill_To_Contact_Email__c) from below conDetailsCheck if block as per the comment update on the ticket by BSA
            Boolean conDetailsCheck = (opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Name != docusign.Bill_To_Contact_Name__c || opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Title != docusign.Bill_To_Contact_Title__c || opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Phone != docusign.Bill_To_Contact_Phone__c);
            //3/7/24 Vijaychandra --START-- (GTMS-19277): changed the logic to check emails
            //Boolean emailCheck = opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.Billing_Email__c != null ? opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.Billing_Email__c != docusign.Billing_Email__c :opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Email != docusign.Billing_Email__c ;
            Boolean emailCheck = opp.SBQQ__PrimaryQuote__r.Consolidated_Billing_Email__c != docusign.Billing_Email__c;
            //3/7/24 Vijaychandra --END-- (GTMS-19277): changed the logic to check email
            if((billingAddressCheck || conDetailsCheck || emailCheck)){
                cvsReview = true;
                omReasonCode = addCreditAnalystNote(opp,docusign);//GTMS-20040
                //opp.Credit_Analyst_Kickback_Note__c = omReasonCode;
                //oppFields.add(Opportunity.Credit_Analyst_Kickback_Note__c);
                if(!Test.isRunningTest()){break;}
            }
            //2/29/24 Vijaychandra --START-- (GTMS-19053): Added below if condition as per business request.
           if(opp.Reseller__c != null && opp.Reseller__r.Partner_Agreement_Accepted__c == null) {
                cvsReview = true;
                omReasonCode = 'Deal was routed to OM review because Reseller account missing Authorization Date';
                if(!Test.isRunningTest()){break;}
            } else if((opp.Reseller__c != null && opp.Reseller__r.Partner_Agreement_Accepted__c != null && opp.Reseller__r.Customer_require_PO_for_invoicing__c == 'Yes' && (opp.PO_Number__c == null || opp.PO_Number__c == '' || Opp.PO_Number__c == '-')) ||
                (opp.Account.Customer_require_PO_for_invoicing__c == 'Yes' && (opp.PO_Number__c == null || opp.PO_Number__c == '' || Opp.PO_Number__c == '-'))){
                cvsReview = true;
                omReasonCode = 'Deal was routed to OM review because it is missing the PO Number';//GTMS-20040
                //opp.Credit_Analyst_Kickback_Note__c = 'Deal was routed to OM review because it is missing the PO Number';
                //oppFields.add(Opportunity.Credit_Analyst_Kickback_Note__c);
                if(!Test.isRunningTest()){break;}
            }
            //2/29/24 --END-- (GTMS-19053)
            if(opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.Name != docusign.Billing_Company_Name__c){
                reasonList.add('Billing Company Name does not match between the DocuSign and the CPQ quote');
                resolutionList.add('Please send a new DocuSign to the customer with a Billing Company Name that matches the CPQ quote');
            }
            
            if(!opp.First_Purchase__c && opp.Account.New_Billing_Process_Approved__c && opp.SBQQ__PrimaryQuote__r.Customer_Preferred_Payment_Method__c != docusign.Customer_Preferred_Payment_Method__c){
                reasonList.add('The customer is enrolled in automated billing (New Billing Process)');
                resolutionList.add('Please select Credit Card or ACH as the Payment Method, and have a new DocuSign signed reflecting the updated Payment Method');
            }
            
            if(opp.Selected_Payment_Type__c != opp.SBQQ__PrimaryQuote__r.Selected_Payment_Type__c || opp.SBQQ__PrimaryQuote__r.Selected_Payment_Type__c != docusign.Selected_Payment_Type__c || docusign.Selected_Payment_Type__c != opp.Selected_Payment_Type__c){
                reasonList.add('The billing frequency on the DocuSign do not match the payments on the CPQ quote');
                resolutionList.add('Please send a new DocuSign to the customer with billing frequency that match the CPQ quote');
            }
            
            if(opp.Payment_Terms__c != opp.SBQQ__PrimaryQuote__r.Payment_Terms__c || opp.SBQQ__PrimaryQuote__r.Payment_Terms__c != docusign.Payment_Terms__c || docusign.Payment_Terms__c != opp.Payment_Terms__c){
                reasonList.add('The payment terms on the DocuSign do not match the payments on the CPQ quote');
                resolutionList.add('Please send a new DocuSign to the customer with Payment Terms that match the CPQ quote');
            }
            
            if (B360Enabled.equalsIgnoreCase('True') && opp.SBQQ__PrimaryQuote__r.Next_Recurring_Bill_Date__c != docusign.Next_Recurring_Bill_Date__c) {                
                cvsReview = true;                
                omReasonCode = 'Deal was routed to OM review because there is a mismatch on the Next Recurring Bill Date on CPQ Quote and DocuSign';//GTMS-27099
            }
            
        }
        
        return new ValidationWrapper(cvsReview,oppFields, new KickBackWrapper(reasonList,resolutionList),opp,omReasonCode);
    }
    //--END-- (GTMS-16637)
    /***************************************************************
    * @Description: this method has the logic to create Credit Analyst note for different fields
    * @Param: opp - Opportunity record which triggerd the OVA validation.
    * @Param: docusign - completed docusign of the opportunity.
    */
    @Testvisible
    public static string addCreditAnalystNote(Opportunity opp, dsfs__DocuSign_Status__c docusign){
        List<string> fieldLabels = new List<String>();
        string creditAnalystNote;
        // Added as per GTMS-28783 - Swami Gurrala - OPEN
        String cleanedQuoteBillingStreet = cleanBillingAddress(opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingStreet);
        String cleanedDocuSignBillingStreet = cleanBillingAddress(docusign.Billing_Street__c);
        // CLOSE 
        if(cleanedQuoteBillingStreet != cleanedDocuSignBillingStreet){fieldLabels.add('Billing Street'); }
        if(opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCity != docusign.Billing_City__c){fieldLabels.add('Billing City');}
        if(opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingState != docusign.Billing_State__c){fieldLabels.add('Billing State');}
        if(opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingCountry != docusign.Billing_Country__c){fieldLabels.add('Billing Country');}
        if(opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.BillingPostalCode != docusign.Billing_Postal_Code__c){fieldLabels.add('Billing Postal Code');}
        if(opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Name != docusign.Bill_To_Contact_Name__c){fieldLabels.add('Bill To Contact Name');}
        if(opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Title != docusign.Bill_To_Contact_Title__c){fieldLabels.add('Bill To Contact Title');}
        if(opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Phone != docusign.Bill_To_Contact_Phone__c){fieldLabels.add('Bill To Contact Phone');}
        //3/11/24 Vijaychadnra (GTMS-16641): Commented below if block as per the comment update on the ticket by BSA
        //if(opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Email != docusign.Bill_To_Contact_Email__c){fieldLabels.add('Bill To Contact Email');}
        //3/7/24 Vijaychandra --START-- (GTMS-19277): changed the logic to check emails
        //Boolean emailCheck = opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.Billing_Email__c != null ? opp.SBQQ__PrimaryQuote__r.Bill_To_Account__r.Billing_Email__c != docusign.Billing_Email__c :opp.SBQQ__PrimaryQuote__r.Bill_To_Contact__r.Email != docusign.Billing_Email__c ;
        Boolean emailCheck = opp.SBQQ__PrimaryQuote__r.Consolidated_Billing_Email__c != docusign.Billing_Email__c;
        //3/7/24 Vijaychandra --END-- (GTMS-19277): changed the logic to check email
        if(emailCheck){fieldLabels.add('Billing Email');}
        if(!fieldLabels.isEmpty()){
            creditAnalystNote = String.join(fieldLabels,';')+' Mismatch on the Order Form';
        }
        
        return creditAnalystNote;
    }
   	// @author Swami Gurrala - GTMS-28783
    private static String cleanBillingAddress(String address) {
        if (String.isBlank(address)) {
            return '';
        }
        String cleaned = address.replaceAll('\n', ' ')  // Replace line breaks with spaces
            .replaceAll('\r', ' ')   // Replace carriage returns with spaces
            .replaceAll('\\s+', ' ') // Replace multiple spaces with single space
            .trim();                  // Remove leading/trailing whitespace
        return cleaned;
    }  
    public class Options {
        public String Operation {get; set;}
        
        public Options(String operation){
            this.Operation = operation;
        }
    }
    
    public class KickBackWrapper{
        public List<string> reason{get;set;}
        public List<string> resolution{get;set;}
        
        public KickBackWrapper(List<string> reason, List<string> resolution){
            this.reason = reason;
            this.resolution = resolution;
        }
    }
    
    public class ValidationWrapper{
        public Boolean cvsReview{get;set;}
        public Set<SObjectField> oppFields{get;set;}
        public KickBackWrapper kbWrap{get;set;}
        public Opportunity opp{get;set;}
        public string omReasonCode{get;set;}//GTMS-20040
        
        public ValidationWrapper(Boolean cvsReview, Set<SObjectField> oppFields, KickBackWrapper kbWrap, Opportunity opp,string omReasonCode){
            this.cvsReview = cvsReview;
            this.oppFields = oppFields;
            this.kbWrap = kbWrap;
            this.opp = opp;
            this.omReasonCode = omReasonCode;//GTMS-20040
        }
    }
    
}