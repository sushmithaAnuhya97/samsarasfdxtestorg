/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 03-01-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QuoteCustomCongaComposer {
    public String displayErrorMessage{get; set;}
    public String returnURL{get; set;}
    public String quoteId{get; set;}
    public Boolean quoteDocument {get;set;}
    public Boolean validation{get;set;}
    public Boolean proratedAPIFailed{get;set;}
    public String fp0Str{get; set;}
    public list<string> taxCalculationStatusList = (System.label.Generate_Quote_Tax_Calculation_Status_Error??'').split(';');
    
    public PageReference validateQuote() {
        quoteDocument = true;
        List<string> warningMessageList = new List<string>();
        displayErrorMessage='Please populate below fields to generate document.';
        PageReference nextPage;
        validation=true;
        proratedAPIFailed = false;
        quoteId = ApexPages.currentPage().getParameters().get('Id');
        fp0Str = ApexPages.currentPage().getParameters().get('FP0');
        List<Schema.FieldSetMember>  fieldSetMember = SobjectType.SBQQ__Quote__c.FieldSets.DCA.getFields();
        String query = 'Select Id, DCA_Validation__c, Estimated_Annual_Payment__c';
        
        for(Schema.FieldSetMember fld:fieldSetMember){
            query += ','+fld.getFieldPath();
        }
        
        query += ',SBQQ__Opportunity2__r.Small_Fleet_Opportunity__c,SBQQ__Opportunity2__r.Is_Webstore_Upsell_Opportunity__c, Override__c';
        query += ',SBQQ__Opportunity2__r.Renewal__c,SBQQ__Opportunity2__r.SBQQ__Renewal__c,SBQQ__Opportunity2__r.Account.Segment__c, SBQQ__ExpirationDate__c,Custom_OF_Generated__c';
        query += ',SBQQ__Opportunity2__r.Type,SBQQ__Opportunity2__r.License_Term__c,Custom_License_Term__c,License_Term__c,Shipping_Address_NEW__c';
        query += ',CalculatedSubscriptionTerm__c,SBQQ__Opportunity2__r.Selected_Payment_Type__c,SBQQ__Opportunity2__r.Shipping_and_Handling__c';
        query += ',SBQQ__Opportunity2__r.Quote_Subsidy_Amount__c, Subsidy_Amount__c, SBQQ__Opportunity2__r.Quote_Buyout_Amount__c, Buyout_Amount__c';
        query += ',SBQQ__Opportunity2__r.Subsidy_Amount__c,Proposed_Picklist_Options__c, SBQQ__Opportunity2__r.Buyout_Amount__c,SBQQ__Account__r.VATId__c,SBQQ__Account__r.Razon_Social_Legal_Company_Name__c,SBQQ__Account__r.Tipo_de_RFC__c,SBQQ__Account__r.Regimen_Fiscal_Receptor__c,SBQQ__Account__r.Delinquency_Status__c';
        query += ',API_Status__c, API_Error_msg__c, Selected_Payment_Type__c, Billing_Ann_Date__c, SBQQ__StartDate__c,Close_Date__c'; // GTMS-27620
        query += ',SBQQ__Opportunity2__r.Billing_360_Transaction__c,SBQQ__Opportunity2__r.isClosed, SBQQ__Opportunity2__r.First_Purchase__c, SBQQ__Opportunity2__r.Sub_Type__c, SBQQ__Opportunity2__r.Purchase_Type__c'; // GTMS-27620
        query += ',SBQQ__Account__r.Billing_Anniversary_Date__c'; // GTMS-27620
        query += ',SBQQ__Opportunity2__r.Processing_Type__c, Next_Recurring_Bill_Date__c, Prorated_Amount__c';
        query += ',SBQQ__Opportunity2__r.CloseDate,SBQQ__Uncalculated__c,Tax_Calculation_Status__c FROM SBQQ__Quote__c Where Id =:quoteId';
        SBQQ__Quote__c quoteRec;
        List<SBQQ__Quote__c> quoteRecList = DataBase.query(query);  
        if(quoteRecList.size()==1){
            quoteRec=quoteRecList[0];
        }
        if(quoteRec==null){
            validation = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,displayErrorMessage));
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Invalid quote.'));
        }

        else if(quoteRec != null){
            if(quoteRec.DCA_Validation__c == 'DCA'){
                List<string> dcaErrors = new List<string>();
                for(Schema.FieldSetMember fld:fieldSetMember){
                    if(fld.getFieldPath() != 'SBQQ__BillingState__c' && (quoteRec.get(fld.getFieldPath())==null || String.isBlank(String.valueOf(quoteRec.get(fld.getFieldPath()) )))){
                        validation = false;
                        dcaErrors.add(fld.getLabel());
                        //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,fld.getLabel()));
                    } 
                    else if(fld.getFieldPath() == 'SBQQ__BillingState__c' && (quoteRec.get(fld.getFieldPath())==null || String.isBlank(String.valueOf(quoteRec.get(fld.getFieldPath()) ))) && quoteRec.SBQQ__BillingCountry__c == 'United States'){
                        validation = false;
                        dcaErrors.add(fld.getLabel());
                        // ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,fld.getLabel()));
                    }   
                }
                
                if(! dcaErrors.isEmpty() && dcaErrors.Size()>0){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,displayErrorMessage));
                    for(string msg:dcaErrors) {  
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,msg));
                    }
                }
            }
            
            if(quoteRec.SBQQ__Uncalculated__c || !taxCalculationStatusList.contains(quoteRec.Tax_Calculation_Status__c)){
                validation = false;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,System.Label.Generate_Quote_Document_Uncalculated_Error));
            }
                 if(fp0Str == '2' && quoteRec.Proposed_Picklist_Options__c == null) {
                   validation = false;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,System.Label.Proposed_Picklist_Cannot_be_Null));
        }
            
            if(quoteRec?.SBQQ__Account__r?.Delinquency_Status__c == 'Orders Blocked' && quoteRec?.SBQQ__Opportunity2__r?.Type == 'Revenue Opportunity'){
                validation = false;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,System.Label.AccountDelinquencyStatusError));
            }

            // GTMS-27620
            //OrderFinanceSetting__mdt billing360Enabled = OrderFinanceSetting__mdt.getInstance('B360_R1_Toggle');
            Map<String, OrderFinanceSetting__mdt> mapOrderFinanceSettings = OrderFinanceSetting__mdt.getAll();
            if(mapOrderFinanceSettings.get('B360_R1_Toggle').Value__c.equalsIgnoreCase('true') && quoteRec.SBQQ__Opportunity2__c !=NULL && quoteRec.SBQQ__Opportunity2__r.Type == 'Revenue Opportunity' 
               &&  quoteRec.SBQQ__Opportunity2__r.isClosed == false && !FeatureManagement.checkPermission('Bypass_B360_Validations')) {
                if (quoteRec.Billing_Ann_Date__c != null ) {
                    String validationError = B360LogicHandler.returnValidationMessage(quoteRec, quoteRec.SBQQ__Opportunity2__r, quoteRec.SBQQ__Account__r, mapOrderFinanceSettings);
                    if(String.isNotBlank(validationError)){
                        validation = false;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, quoteRec.API_Error_msg__c != null ? quoteRec.API_Error_msg__c : validationError));
                    } 
              }
                   if(quoteRec.Next_Recurring_Bill_Date__c != null){
                      if(quoteRec.API_Status__c == 'Pending'){
                        validation = false;
                        if(quoteRec.Next_Recurring_Bill_Date__c != null && quoteRec.Next_Recurring_Bill_Date__c < Date.today()) {
                           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,mapOrderFinanceSettings.get('Err_Next_Recurring_Bill_Date').Value__c)); 
                        }else{
                           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, mapOrderFinanceSettings.get('Err_Pending_Prorate_API_Callout').Value__c)); 
                        }
                        
                    }else if (!String.isBlank(quoteRec.API_Error_msg__c)){
                        proratedAPIFailed = true;
                    }  else if (quoteRec.API_Status__c == null && quoteRec.Prorated_Amount__c == null && BillingProrationAmountController.eligibleForBillingProrationAPICallout(new List<String>{String.valueOf(quoteRec.Id)})) {
                        validation = false;
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,mapOrderFinanceSettings.get('eligibileForProrationAPIError').Value__c)); 
                    }
                   }
            }
            // GTMS-27620 - End

      //GTMS-25907 start
            if(quoteRec.SBQQ__BillingCountry__c == 'Mexico' && quoteRec.SBQQ__Account__r != null) {
                List<String> missingFields = new List<String>();
                if(String.isBlank(quoteRec.SBQQ__Account__r.Razon_Social_Legal_Company_Name__c)) { 
                    missingFields.add('Razon Social');}
                if(String.isBlank(quoteRec.SBQQ__Account__r.Tipo_de_RFC__c)) { 
                    missingFields.add('Tipo de RFC'); }
                if(String.isBlank(quoteRec.SBQQ__Account__r.Regimen_Fiscal_Receptor__c)) { 
                    missingFields.add('Regimen Fiscal Receptor'); }
                if(String.isBlank(quoteRec.SBQQ__Account__r.VATId__c)) { 
                    missingFields.add('Tax ID'); }
                if(!missingFields.isEmpty()) { validation = false;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, system.Label.MXNAccFieldsCheck + String.join(missingFields, ', ')));
                } 
            }
             //GTMS-25907 end
            if(validation && !proratedAPIFailed) 
            warningMessageList.addAll(getGenericWarningMessage(quoteRec));

            if(System.Label.GenerateQuoteValidationEnabled == 'Yes' && isGenerateQuoteDocumentPreCheckPermissionExist() && quoteIsEligbleForValidation(quoteRec) && validation && !proratedAPIFailed){
                warningMessageList.addAll(getSpecificWarningMessage(quoteRec));
            }
            if(!quoteRec.Custom_OF_Generated__c && fp0Str == '2' && validation && quoteDocument && !proratedAPIFailed ){
                quoteRec.Custom_OF_Generated__c = true;
                update quoteRec;
             }  
        }

        if(!warningMessageList.isEmpty()) throwQuoteWarnings(warningMessageList);
        
        returnURL='/'+quoteId ;             
        if(validation && quoteDocument && !proratedAPIFailed){
            nextPage = new PageReference('/apex/APXTConga4__Conga_Composer');
            for(String key:ApexPages.currentPage().getParameters().keySet()){
                nextPage.getParameters().put(key,ApexPages.currentPage().getParameters().get(key));
            }
            nextPage.setRedirect(true);
        }
        
        return nextPage;
    }

    public void throwQuoteWarnings (List<string> errorMessage){

        for(string msg:errorMessage){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,msg));
            quoteDocument = false;
        }
    }

    public Boolean quoteIsEligbleForValidation(SBQQ__Quote__c quoteRec){
        Boolean valid = false;
        Set<string> segments = new Set<string>{'AE2','AE3','Enterprise','Management'};
            if(segments.contains(quoteRec.SBQQ__Opportunity2__r.Account.Segment__c)
               && quoteRec.SBQQ__Opportunity2__r.Type == 'Revenue Opportunity' && quoteRec.SBQQ__Opportunity2__r.Renewal__c == false
               && quoteRec.SBQQ__Opportunity2__r.SBQQ__Renewal__c == false && quoteRec.SBQQ__Opportunity2__r.Is_Webstore_Upsell_Opportunity__c == false && quoteRec.SBQQ__Opportunity2__r.Small_Fleet_Opportunity__c == false){
                   valid = true;
               }
        return valid;
        
    }
    public PageReference navigateQuoteDocumnet(){
        PageReference  nextPage = new PageReference('/apex/APXTConga4__Conga_Composer');
        for(String key:ApexPages.currentPage().getParameters().keySet()){
            nextPage.getParameters().put(key,ApexPages.currentPage().getParameters().get(key));
        }
        nextPage.setRedirect(true);
        
        
        return nextPage;
    }
    
    public Boolean isGenerateQuoteDocumentPreCheckPermissionExist(){
        
        return (FeatureManagement.checkPermission('GenerateQuoteDocumentPreCheckPermission') || Test.isRunningTest());
    }
    
    public List<string> getSpecificWarningMessage(SBQQ__Quote__c quote){
        List<string> errorMessages = new List<string>();
        try{
            if(string.isBlank(quote.SBQQ__Opportunity2__r.Selected_Payment_Type__c)){
              errorMessages.add(System.Label.OppPreCheck_Selected_Payment_Type);
            }
            if(quote.SBQQ__Opportunity2__r.Shipping_and_Handling__c == 99999.99){
              errorMessages.add(System.Label.OppPreCheck_Shipping_and_Handling);
            }

        }catch(Exception e){
            errorMessages.add('Below exception occured while validating data.');
            errorMessages.add(e.getMessage());
        }
        
        return errorMessages;
    } 
  @TestVisible
    private List<string> getGenericWarningMessage(SBQQ__Quote__c quote){
        
        List<string> errorMessages = new List<string>();
        try{
      Decimal calculatedAnnualPayment = null;
            Integer linesWithoutShipTo = 0;
          List<SBQQ__QuoteLine__c> quoteLines = [SELECT SBQQ__Quote__c, Total_Annual_Price__c, Ship_To__c, Conga_Line_Item_Type__c FROM SBQQ__QuoteLine__c 
            WHERE SBQQ__Quote__c =:quote.Id];
            for(SBQQ__QuoteLine__c quoteLine : quoteLines) {
              if(quoteLine.Conga_Line_Item_Type__c == true) {
                  if(calculatedAnnualPayment == null) {
                      calculatedAnnualPayment = 0;
                  }
                  calculatedAnnualPayment = calculatedAnnualPayment + quoteLine.Total_Annual_Price__c;
              }              
                if(String.isBlank(quoteLine.Ship_To__c)) {
                    linesWithoutShipTo++;
                }
            }

            if(quote.SBQQ__ExpirationDate__c < Date.Today()){
                errorMessages.add(System.Label.OppPreCheck_ExpirationDate);
            }

            if( quote?.SBQQ__Opportunity2__r?.License_Term__c == null || String.isBlank(quote.License_Term__c)){
                errorMessages.add(System.Label.OppPreCheck_License_Term);
            }else{
                if(integer.valueOf(quote.License_Term__c) != quote.SBQQ__Opportunity2__r.License_Term__c) 
                    errorMessages.add(System.Label.OppPreCheck_License_Term);
            }
            
            if(quote.SBQQ__Opportunity2__r.CloseDate != Date.Today() && quote?.SBQQ__Opportunity2__r?.Type == 'Revenue Opportunity'){
                errorMessages.add(System.Label.OppPreCheck_CloseDate);
            }
            //Buyout amount on opportunity will be -ve, add a -ve before comparing.
            //Buyout amount on quote can be null, consider it as 0 before comparing.
            if(-quote.SBQQ__Opportunity2__r.Buyout_Amount__c != (quote.Buyout_Amount__c??0)){
                errorMessages.add(System.Label.Oppty_Quote_Buyout_Amount_Mismatch);
            }
            //Subsidy amount on opportunity will be -ve, add a -ve before comparing.
            //Subsidy amount on quote can be null, consider it as 0 before comparing.
            if(-quote.SBQQ__Opportunity2__r.Subsidy_Amount__c != (quote.Subsidy_Amount__c??0)){
                errorMessages.add(System.Label.Oppty_Quote_Subsidy_Amount_Mismatch);
            }
            if(calculatedAnnualPayment != null && quote.Estimated_Annual_Payment__c != null && quote.Estimated_Annual_Payment__c.setScale(2) != calculatedAnnualPayment.setScale(2)){
                errorMessages.add(System.Label.estAmtMisMatchWarningMsg);
            }
            if(quote.Shipping_Address_NEW__c != null && linesWithoutShipTo > 0) {
                errorMessages.add(quote.Override__c ? System.Label.Quote_Line_Has_No_Ship_To_Multiline : System.Label.Quote_Line_Has_No_Ship_To_No_Multiline);
            }
        }catch(Exception e){
            errorMessages.add('Exception occured while validating data in generic errors: '+e.getMessage());
        }
        
        return errorMessages;
    }
}