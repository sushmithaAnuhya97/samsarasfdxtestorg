/**
* Created By : Groundswell - Suman Kundu
* @Date September 10, 2021
*
* @description : This class will be responsible for handling all Quote Service Operations
* June-21-2022  Chinmaya Dash GTMS-7343 Added UpdateCPQQuote method
* Oct-4-2022  Nishita GTMS-8280 Fix the null pointer exception
* Jan-19-2023  Rajesh GTMS-11159 Fix the null pointer exception
* Feb-14-2023 Rajesh GTMS-11536: Reverted the LicenseTerm calculations
* Feb-17-2023 Rajesh GTMS-11327 Added AutoRenewal condition to populate Start/End dates
* Feb-23-2023 Rajesh GTMS-10935 If Contracted Adjusted RenewalOpp EndDate is not null then Assign to Quote End
* Mar-14-2023 Siddharth GTMS-11706 Populate 'VG Basic Purchased' and 'VG ENT Purchased' on quote insertion according to values on same field on the associated Customer 360 record on the related account*
* May-23-2023 Rajesh GTMS-13193 Populating License Term & EndDate upon checking some renewal conditions
* June-27-2023 Rajesh GTMS-13785 Added Null check
* June-28-2023 Rajesh GTMS-13687 Populating Co_Term Contract
* October-12-2023 Joshna GTMS-15935 CPQ Start Date Logic
* Oct-19-2023 Vijaychandra (GTMS-16286) Added 3 field change condtions in hasAnyDisclaimerFieldChanged method.
* Oct-23-2023 Vijaychandra (GTMS-16283) Added new conditions for OV out of scope criteria.
* Oct-26-2023 Vijaychadnra (GTMS-16289) Added docusign void logic if few fields changed on quote.
* Oct-12-2023 Rajesh GTMS-16392 Vertex Project: Quote not refreshed for new tax -Priority 1 issue
* Jan-15-2024 Vijaychandra (GTMS-17941): Added new condition in hasAnyVoidFieldChange method.
* Mar-04-2024 Vijaychandra (GTMS-19085): Added OVA phase 2 Pilot rollout check in setDocusignDisclaimerCondition method
* Jan-15-2024 Rodrigo GTMS-16223/GTMS-16226 3PF Project
* Apr-04-2024 Rodrigo GTMS-20064
* May-20-2024 Vijaychandra (GTMS-20818): Added Mexico and First Purchase check in to OVA entry criteria in setDocusignDisclaimer method
* Dec-05-2024 Venkatesh Vallepu (GTMS-24149): Added Method to validate the free trial for Tier and legacy product condition
* Jan-10-2025 Abu GTMS-25074: Added logic to check P_P_Pilot_Customer__c to True when Contracts P_P_Renewals__c is True when cloned.
* Mar-07-2025 Anas GTMS-25783: To bypass Return_opp_Quotes_are_Locked_for_sel Quote validation rule
* Mar-10-2025 Shivam GTMS-26512: Added S&H Calculations in before insert and update
* Mar-26-2025 Ravindra GTMS-26842: Renewal quote Payment terms assignment based on the account payment terms
* Apr-25-2025 Rushikesh GTMS-26249: To bypass Flex_Prevent_Quote_Modification validation rule 
*/
public without sharing class GS_SBQQQuoteService {
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    public static Id currentUserId = UserInfo.getUserId();
    public static Id currentUserRoleId = UserInfo.getUserRoleId();
    public static boolean skipValidations = Test.isRunningTest();
    public Static Map<Id, SBQQ__Quote__c> sourceQuoteData;
    Static Set<Id> relatedQuoteIds = new Set<Id>();
    Static Map<Id, Shipping_Address__c> shippingData;
    Static Set<Id> relatedShippingAddressIDs = new Set<Id>();
    Static Map<Id, Contract> contractData;
    public static Boolean TaxCalculationScheduled=false;
    public static Boolean reCalculateJobTaxCalc=false;
    Static Set<Id> relatedContractIDs = new Set<Id>();
    Final Static String PURCHASE_STAGE = 'Purchase';
    public static Boolean OppStartDateUpdatedFromContract=false; //GTMS-23000
    public static Boolean bypassValidation = false;
    public static Boolean isTaxCalculationCompleted = false;
    public static Boolean bypassQuoteToOptySync = false;
    public GS_SBQQQuoteService() {}
    // Method to set the Shipping Fields
    public static void setShipToDetails(SBQQ__Quote__c quote, Shipping_Address__c relatedShippingAddress){
        if(relatedShippingAddress != null){
            quote.Shipping_Country__c = relatedShippingAddress.Shipping_Country__c;
            quote.Shipping_State__c = relatedShippingAddress.Shipping_State__c;
            quote.SBQQ__ShippingName__c = relatedShippingAddress.Name;
            quote.SBQQ__ShippingStreet__c = relatedShippingAddress.Shipping_Address_Line_1__c;
            quote.SBQQ__ShippingCity__c  = relatedShippingAddress.Shipping_City__c;
            quote.SBQQ__ShippingState__c  = relatedShippingAddress.Shipping_State__c;
            quote.SBQQ__ShippingPostalCode__c = relatedShippingAddress.Shipping_Zip_Code__c;
            quote.SBQQ__ShippingCountry__c  = relatedShippingAddress.Shipping_Country__c;
        }
        else if(relatedShippingAddress == null){
            quote.Shipping_Country__c = null;
            quote.Shipping_State__c = null;
            quote.SBQQ__ShippingName__c = null;
            quote.SBQQ__ShippingStreet__c = null;
            quote.SBQQ__ShippingCity__c  = null;
            quote.SBQQ__ShippingState__c  = null;
            quote.SBQQ__ShippingPostalCode__c = null;
            quote.SBQQ__ShippingCountry__c  = null;
        }
    }
    private static void cloneMappings(SBQQ__Quote__c quote){
        quote.ApprovalStatus__c = null;
        quote.SBQQ__Status__c = 'Draft';
        quote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
        quote.Selected_Payment_Type__c = null;
        if(sourceQuoteData != null && sourceQuoteData.containsKey(quote.SBQQ__Source__c)){
            SBQQ__Quote__c sourceRecord = sourceQuoteData.get(quote.SBQQ__Source__c);
            //quote.Approved_Discount__c = sourceRecord.Approved_Discount__c;
            quote.Approved_Discount__c = null;
            quote.ApprovedProductsCount__c = sourceRecord.ApprovedProductsCount__c;
        }
        if(quote.ClonedQuoteAppendName__c == FALSE) {
            quote.ClonedQuoteAppendName__c = True;
            String quoteName = String.isBlank(quote.Quote_Name__c) ? '' : quote.Quote_Name__c;
            quote.Approved_Discount__c = null;
            quote.Quote_Name__c = quoteName + ' Cloned Copy';
        }
    }
    // SBQQ__WatermarkShown__c can be deprecated from code
    // Should me modified to reduce the execution time/ Move the whole logic to PriceRules -Harsha
    public static void updateQuoteFields(Map<Id, SBQQ__Quote__c> oldQuoteMap, Map<Id, SBQQ__Quote__c> newQuoteMap, List<SBQQ__Quote__c> quoteList, Map<Id, Opportunity> opportunityData) {
        SBAA_Enablement_IDs__c sbaaIds = SBAA_Enablement_IDs__c.getInstance();
        //Set<Id> qtIds = new Set<Id>();
        Map<Id, SBQQ__Quote__c > quoteMap = new Map<Id,SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote: quoteList) {
            if(quote.Associated_Opportunity_Type__c=='Free Trial Opportunity'){
                if(Trigger.isInsert){
                    quote.ApprovalStatus__c='Approved';
                }
                //Start: 10/29/2024- GTMS-24192 Commented the below code and move the change to Price Rule(Stamp Approval Status to Draft on Quote When AT11 and Training SKUS are Added.)
                                        /* if(sourceQuoteData != null && sourceQuoteData.containsKey(quote.Id)){
                        SBQQ__Quote__c FTQuote = sourceQuoteData.get(quote.Id);
                        List<SBQQ__QuoteLine__c> qliList = sourceQuoteData.get(quote.Id).SBQQ__LineItems__r;
                        for(SBQQ__QuoteLine__c qL: qliList){
                        if(Label.FT_Exception_ProdCode.contains(qL.SBQQ__Product__r.ProductCode)){
                        quoteMap.put(quote.id,quote);
                        }
                        }
                        }if(quoteMap.size()==0){
                        quote.ApprovalStatus__c = 'Approved';
                        }*/
                //End: 10/29/2024- GTMS-24192
            }
        }
        if(quoteMap.size()>0 && trigger.isUpdate){
            for(SBQQ__Quote__c Qte:quoteMap.values()){
                if(sourceQuoteData.containsKey(Qte.Id) && sourceQuoteData.get(Qte.Id).AAE_Approvals__r.size() == 0 || (sourceQuoteData.get(Qte.Id).AAE_Approvals__r.size() > 0 && sourceQuoteData.get(Qte.Id).ApprovalStatus__c == 'Recalled')){
                    Qte.ApprovalStatus__c = null;
                }
            }
        }
        for (SBQQ__Quote__c quote: quoteList) {
            if (Trigger.isInsert || oldQuoteMap.get(quote.Id).ApprovalStatus__c != quote.ApprovalStatus__c
                || (quote.ApprovalStatus__c=='Pending' && quote.SBQQ__Status__c=='Draft')
                || (quote.ApprovalStatus__c=='Recalled' && oldQuoteMap.get(quote.Id).SBQQ__Status__c =='Draft' && quote.Approved_Discount__c!=null) // added for GTMS-15659
               ) {
                   if (quote.ApprovalStatus__c == 'Approved') {
                       quote.RecordTypeId = sbaaIds.Approved_Quote_RT__c;
                       quote.SBQQ__Status__c = 'Approved';
                       quote.SBQQ__WatermarkShown__c = false;
                       quote.Approved_Discount__c = quote.Blended_Discount__c + Decimal.valueOf(System.Label.Approved_Discount_Increment);
                       quote.ApprovedProductsCount__c = quote.NumOfProductsNeedingApproval__c;
                   } else if (quote.ApprovalStatus__c == 'Pending') {
                       quote.RecordTypeId = sbaaIds.In_Progress_Quote_RT__c;
                       quote.SBQQ__Status__c  = 'In Review';
                       quote.SBQQ__WatermarkShown__c  = true;
                   } else if(quote.ApprovalStatus__c == 'Rejected') {
                       quote.RecordTypeId = sbaaIds.Draft_Quote_RT__c;
                       quote.SBQQ__Status__c = 'Denied';
                       quote.SBQQ__WatermarkShown__c = true;
                       if (quote.SBQQ__MasterContract__c != null) {
                           quote.RejectedAddOn__c = true;
                       }
                   } else {
                       if (quote.RecordTypeId == sbaaIds.Draft_Quote_RT__c || quote.RecordTypeId == sbaaIds.Approved_Quote_RT__c || quote.RecordTypeId == sbaaIds.In_Progress_Quote_RT__c) {
                           quote.RecordTypeId = sbaaIds.Draft_Quote_RT__c;
                           quote.SBQQ__WatermarkShown__c  = true;
                       }
                       quote.SBQQ__Status__c = opportunityData.containsKey(quote.SBQQ__Opportunity2__c) && opportunityData.get(quote.SBQQ__Opportunity2__c)?.Small_Fleet_Opportunity__c ? quote.SBQQ__Status__c : 'Draft';
                       // added for GTMS-15659 to update the Approved Discount field value when quote is recalled, from Approved Status
                       if ( (quote.ApprovalStatus__c == 'Recalled' && oldQuoteMap.get(quote.Id).ApprovalStatus__c=='Approved')
                           || (quote.ApprovalStatus__c=='Recalled' && oldQuoteMap.get(quote.Id).SBQQ__Status__c =='Draft' && quote.Approved_Discount__c!=null)
                          )
                           quote.Approved_Discount__c = null;
                   }
               }
            checkRecalculationBypass(quote, (oldQuoteMap != null ? oldQuoteMap.get(quote.Id) : null));
  
            /* if(!Trigger.isInsert){
            if (oldQuoteMap.get(quote.Id).SBQQ__LastCalculatedOn__c == null &&
            oldQuoteMap.get(quote.Id).SBQQ__LastCalculatedOn__c  != quote.SBQQ__LastCalculatedOn__c
            ) {
            qtIds.add(quote.Id);
            }
            } */
        }
            /* if (!qtIds.isempty()/* && !Test.isRunningTest()/) {
            DMLWrapper.doInsert(new GS_SBQQQuoteServiceAsync().prepareAsyncRequests(
            JSON.serialize(new GS_SBQQQuoteServiceAsync.Options('recalculateQuote')),
            qtIds
            ));
            } */
    }
  
    private static void checkRecalculationBypass(SBQQ__Quote__c quote, SBQQ__Quote__c oldQuote){
        if (oldQuote == null) return;
        Boolean hasStartDateChanged = (
            oldQuote.SBQQ__StartDate__c != quote.SBQQ__StartDate__c
            &&  quote.SBQQ__StartDate__c < quote.SBQQ__EndDate__c
        );
        Boolean isCurrentlyRecalculating = (
            oldQuote.SBQQ__LastCalculatedOn__c != quote.SBQQ__LastCalculatedOn__c  // If LastCalculatedOn has been changed, this quote has been recalculated
            &&  quote.SBQQ__LastSavedOn__c == quote.SBQQ__LastCalculatedOn__c          // If LastSavedOn is equals LastCalculatedOn, this quote is currently calculated
            &&  oldQuote.SBQQ__LastCalculatedOn__c != oldQuote.SBQQ__LastSavedOn__c    // Checking if a non-calculating field was updated, meaning this both fields would have the same value on old quote.
        );
        Boolean isRevenueStandardAmmendmentOpportunity = (
            quote.Associated_Opportunity_Probability__c < 95
            &&  quote.Associated_Opportunity_Type__c == 'Revenue Opportunity'
            &&  quote.Opportunity_Record_Type__c == 'Standard Opportunity'
            &&  quote.SBQQ__EndDate__c != null
            &&  quote.SBQQ__StartDate__c >= System.today()
        );
        Boolean isQuoteApproved = (
            quote.ApprovalStatus__c == 'Approved'
        );
        // This Ship_From_Location__c
        // field update should be true for a change in the Quote's Start Date (either manually or from the Opportunity), specifically for Ammendment Opportunities
        // Then return to false right after.
        quote.ApprovedRecalculationBypass__c = ((hasStartDateChanged || isCurrentlyRecalculating) && isRevenueStandardAmmendmentOpportunity && isQuoteApproved);
    }
    //* 2/09/21 Groundswell - Tanuj - [Non Express] Checks if there is an approved discount on a quote (i.e on a cloned draft quote) and
    // the selected payment type is changed from upfront or annual to monthly.
    public static void clearOutApprovedQuote(SBQQ__Quote__c updatedQuote,  SBQQ__Quote__c oldQuote){
        if(updatedQuote.Configuration_Segment__c != null && updatedQuote.Configuration_Segment__c.equalsIgnoreCase(Label.Configuration_Segment_NonExpress) && isChanged(updatedQuote,oldQuote,Schema.SBQQ__Quote__c.Selected_Payment_Type__c) &&
           (String.isBlank(oldQuote.Selected_Payment_Type__c) || oldQuote.Selected_Payment_Type__c.equalsIgnoreCase(Label.Upfront_Payment_Type) || oldQuote.Selected_Payment_Type__c.equalsIgnoreCase(Label.Direct_Annual_Payment_Type)) &&
           updatedQuote.Selected_Payment_Type__c !=null && updatedQuote.Selected_Payment_Type__c.equalsIgnoreCase(Label.Direct_Monthly_Payment_Type) && updatedQuote.Approved_Discount__c != null) {  //GTMS-8280
               if(updatedQuote.SBQQ__Source__c != null && sourceQuoteData != null && sourceQuoteData.containsKey(updatedQuote.SBQQ__Source__c)
                  && sourceQuoteData.get(updatedQuote.SBQQ__Source__c).SBQQ__Source__r.Selected_Payment_Type__c != null && !sourceQuoteData.get(updatedQuote.SBQQ__Source__c).SBQQ__Source__r.Selected_Payment_Type__c.equalsIgnoreCase(Label.Direct_Monthly_Payment_Type)){
                      updatedQuote.Approved_Discount__c = null;
                  } else if(updatedQuote.SBQQ__Source__c == null || (sourceQuoteData != null && sourceQuoteData.containsKey(updatedQuote.SBQQ__Source__c)
                                                                     && sourceQuoteData.get(updatedQuote.SBQQ__Source__c).SBQQ__Source__r.Selected_Payment_Type__c == null)){
                                                                         updatedQuote.Approved_Discount__c = null;
                                                                     }
           }
    }
    //* 2/09/21 Groundswell - Tanuj
    // Helper method for comparing whether a certain field changed between an old Quote and new Quote
    private static Boolean isChanged(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote, Schema.SObjectField field) {
        if (oldQuote == null) {
            return true;
        } else if (newQuote.get(field) != oldQuote.get(field)) {
            return true;
        } else {
            return false;
        }
    }
    private static void setTaxData(SBQQ__Quote__c quote){
        if(quote.Taxpayer_Code__c == NULL && quote.Shipping_Country__c == 'Mexico'){
            quote.Taxpayer_Code__c = System.Label.MX_Taxpayer_Code;
        }
    }
    
    
    /**
    * Created By : Joshna Konudula
    * @Date July 27, 2024
    * @description : method handles the logic to populate the picklist Field : Renewal_Data_Error_Category__c
    * Jira: GTMS-22224
    **/
        
    public static Boolean getRenewalDataErrorCategoryType(SBQQ__Quote__c updatedQuote){
        String oldErrorCategoryType = updatedQuote.Renewal_Data_Error_Category__c;
        try{
            if((sourceQuoteData!= null && !sourceQuoteData.isEmpty() &&  sourceQuoteData.containsKey(updatedQuote.Id) && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__c != null && updatedQuote.SBQQ__Primary__c == true
                && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c != null && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Deactivated__c == false) || Test.isRunningTest()){
                    Opportunity QteOpty = sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r;
                    Decimal opptyACV, contractACV, acvDiff;
                    Boolean ACVdidnotMatch = false;
                    
                    if(updatedQuote.SBQQ__Primary__c == true && QteOpty.ACV_Bookings_SOT__c != null
                       && QteOpty.SBQQ__RenewedContract__r.Contract_Renewable_ACV__c != null && updatedQuote.SBQQ__RenewalUpliftRate__c != null){
                           opptyACV = QteOpty.ACV_Bookings_SOT__c.setscale(2);
                           contractACV = ((QteOpty.SBQQ__RenewedContract__r.Contract_Renewable_ACV__c)*(1+(updatedQuote.SBQQ__RenewalUpliftRate__c/100))).setscale(2);
                           acvDiff = opptyACV-contractACV;
                           if(acvDiff  != 0 && (acvDiff <-1 || acvDiff > 1) && acvDiff != -10.2){
                               List<SBQQ__QuoteLine__c> qLineList = sourceQuoteData.get(updatedQuote.Id).SBQQ__LineItems__r;
                               for(SBQQ__QuoteLine__c qL: qLineList){
                                   if((qL.Renewal_Data_Error_Type__c != 'ValidationSuccessful')){
                                       ACVdidnotMatch = true;
                                   }
                               }
                           }}
                    if(QteOpty.SBQQ__RenewedContract__r.Auto_Renewal__c == true && QteOpty.SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c == null){
                        updatedQuote.Renewal_Data_Error_Category__c ='UpliftIsNull';
                    }else if((updatedQuote.SBQQ__RenewalUpliftRate__c!=null?updatedQuote.SBQQ__RenewalUpliftRate__c.setScale(2):(updatedQuote.SBQQ__RenewalUpliftRate__c)) != (QteOpty.SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c != null?QteOpty.SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c.setscale(2):(QteOpty.SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c))){
                        updatedQuote.Renewal_Data_Error_Category__c = 'UpliftNotMatch';
                    }
                    //Commenting below code under ticket GTMS-26363
                    /*else if(updatedQuote.SBQQ__Uncalculated__c  == true){
                        updatedQuote.Renewal_Data_Error_Category__c = 'CalculationIssue';
                    }*/else if(updatedQuote.SBQQ__Primary__c == true && (updatedQuote.Shipping_Address_NEW__c == null || QteOpty.Shipping_Address_NEW__c == null)){
                        updatedQuote.Renewal_Data_Error_Category__c = 'ShippingAddressDidNotMatch';
                    }else if(updatedQuote.Tax_Calculation_Status__c != 'Updated'){
                        updatedQuote.Renewal_Data_Error_Category__c = 'TaxIssue';
                    }else if(updatedQuote.SBQQ__Primary__c == true && (updatedQuote.Selected_Payment_Type__c == null || QteOpty.Selected_Payment_Type__c == null /*&& updatedQuote.Process_Eligibility__c != 'Digital Renewals'*/)){
                        updatedQuote.Renewal_Data_Error_Category__c = 'PaymentTypeDidNotMatch';
                    }else if(updatedQuote.SBQQ__Primary__c == true && (String.valueof(updatedQuote.License_Term__c) != String.valueof(QteOpty.License_Term__c))){
                        updatedQuote.Renewal_Data_Error_Category__c = 'LicenseTermDidNotMatch';
                    }else if (updatedQuote.SBQQ__NetAmount__c == null || QteOpty.Amount == null || (updatedQuote.SBQQ__NetAmount__c != QteOpty.Amount && 
                                                                                                    ((updatedQuote.SBQQ__NetAmount__c - QteOpty.Amount) < -1 || (updatedQuote.SBQQ__NetAmount__c - QteOpty.Amount) > 1))) { updatedQuote.Renewal_Data_Error_Category__c = 'AmountDidNotMatch';
                                                                                                    }else if(ACVdidnotMatch) { updatedQuote.Renewal_Data_Error_Category__c = 'ACVDidNotMatch'; }
                                                                                                    //Adding code as part of GTMS-26363
                                                                                                    else if(updatedQuote.Process_Eligibility__c == 'Digital Renewals' && updatedQuote.SBQQ__Primary__c == true && QteOpty.SBQQ__RenewedContract__r.Webstore_Renewal_Quote_Step__c !=null && QteOpty.SBQQ__RenewedContract__r.Webstore_Renewal_Quote_Step__c < 7){
                                                                                                        updatedQuote.Renewal_Data_Error_Category__c = 'DigitalRenewalJobFailed';}
                                                                                                    else{ updatedQuote.Renewal_Data_Error_Category__c = 'CleanData'; }
                }
        }catch(exception e){
            /*Api_Logger__c aplog = new Api_Logger__c();
            apLog.Opportunity_Name__c = 'Updating Renewal_Data_Error_Type__c field with picklist value for renewal Data cleanup';
            apLog.DML__c= true;
            apLog.Exception_Message__c = e.getMessage();
            aplogList.add(aplog);*/
                    }
                    /*if(!aplogList.isEmpty()) {
            insert apLogList;
            }*/
        if(oldErrorCategoryType!=null && updatedQuote.Renewal_Data_Error_Category__c=='CleanData' && (oldErrorCategoryType!=updatedQuote.Renewal_Data_Error_Category__c)){
            return true;
        }
        else if(updatedQuote.Renewal_Data_Error_Category__c =='CleanData' || updatedQuote.Renewal_Data_Error_Category__c =='NegativeBelendedDiscount' 
           || updatedQuote.Renewal_Data_Error_Category__c =='NegativeBlendedDiscount'){
               return false;
           }else{
               return true;
           }
    }
    // added for GTMS-15659 to calculate if the difference between 2 value is within 3%
    /* commented and move to another class
    private static Boolean isWithinThreePercent(Decimal newValue, Decimal oldValue) {
    if (newValue==0 || newValue==null || oldValue==null || oldValue==0)
    return false;
    Decimal difference = Math.abs(newValue - oldValue);
    Decimal percentage = difference / oldValue * 100;
    Decimal percentageFinal= (percentage >= 0) ? percentage : percentage * -1;
    return percentageFinal <= 3;
    }  commented and move to another class*/
    public inherited sharing class TriggerContext{
        List<SBQQ__Quote__c> newList;
        List<SBQQ__Quote__c> oldList;
        Map<Id, SBQQ__Quote__c> newMap;
        Map<Id, SBQQ__Quote__c> oldMap;
        public TriggerContext(List<SBQQ__Quote__c> newList, List<SBQQ__Quote__c> oldList, Map<Id, SBQQ__Quote__c> newMap, Map<Id, SBQQ__Quote__c> oldMap){
            this.newList = newList;
            this.oldList = oldList;
            this.newMap = newMap;
            this.oldMap = oldMap;
        }
        public void handleBeforeInsertOperations(){
            thisLogger.logDebug('handleBeforeInsertOperations Quote List ::', newList);
            Set<Id> relatedOpportunityIDs = new Set<Id>();
            Map<Id, Opportunity> opportunityData;
            List<String> cwRoboIds = System.Label.Corpweb_SFDC_Robot.split(',');
            Set<Id> accountIds = new Set<Id>();//GTMS - 11706
            Boolean eligibleForPaymentTermDefault = String.isBlank(System.label.Default_PaymentTerms_Quote_Date)? true : date.valueOf(System.label.Default_PaymentTerms_Quote_Date) <= System.today();
            for (SBQQ__Quote__c newQuote : newList) {
                if( newQuote.SBQQ__Account__c != null && (newQuote.DCA_Validation__c == 'DCA' || Test.isRunningTest())){
                    newQuote.Bill_to_Account__c = newQuote.SBQQ__Account__c;//GTMS-16585
                }
                // GTMS-16190 start
                if (newQuote.Is_Promo__c == true) {
                    // Automatically set these fields when Is_Promo__c is true
                    newQuote.Can_Discount_a_la_Carte_Hardware__c = true;
                    newQuote.Selected_Payment_Type__c = 'Upfront Payments';
                }
                // Check if the quote is approved and the discount is 100% or greater
                if (newQuote.ApprovalStatus__c == 'Approved' && newQuote.Blended_Discount__c >= 100) {
                    // Set Shipping_and_Handling_Manual__c to 0 when the discount is 100% or more and the quote is approved
                    newQuote.Shipping_and_Handling_Manual__c = 0;
                }
                // Added as part of user story GTMS-19837
                if(((newQuote.Finance_Partner_Account__c != null || newQuote.Reseller_Account__c != null) && string.isEmpty(newQuote.Customer_Preferred_Payment_Method__c) )
                   && (newQuote.DCA_Validation__c == 'DCA' || Test.isRunningTest())){
                       newQuote.Customer_Preferred_Payment_Method__c = 'Check/Wire';
                   }
                if(((newQuote.Finance_Partner_Account__c == null && newQuote.Reseller_Account__c == null) && string.isEmpty(newQuote.Customer_Preferred_Payment_Method__c) )
                   && (newQuote.DCA_Validation__c == 'DCA' || Test.isRunningTest())){
                       newQuote.Customer_Preferred_Payment_Method__c = 'Credit Card/ACH Debit';
                   }
                relatedOpportunityIDs.add(newQuote.SBQQ__Opportunity2__c);
                if (newQuote.Shipping_Address_NEW__c != null) {
                    relatedShippingAddressIDs.add(newQuote.Shipping_Address_NEW__c);
                }
                if(newQuote.SBQQ__Source__c != null){
                    relatedQuoteIds.add(newQuote.SBQQ__Source__c);
                }
                if(!accountIds.contains(newQuote.SBQQ__Account__c))//GTMS-11706
                {
                    accountIds.add(newQuote.SBQQ__Account__c);
                }
                newQuote.Has_Been_Submitted_for_Approval__c = false; // GTMS-13640
                DateTime myDateTime = DateTime.now();
                newQuote.Smart_Approve_Fields_Indicator__c = myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year(); // GTMS-15659
                newQuote.Skip_Approval_Process__c  = myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year(); // GTMS-20064
  
            }
            //GTMS-11706
            if(!accountIds.isEmpty())
            {
                List<Customer_360__c> cutomer360List = [SELECT Id,VG_Basic_Purchased__c,VG_ENT_Purchased__c,Account__c FROM Customer_360__c WHERE Account__c IN:accountIds];
                if(!cutomer360List.isEmpty())
                {
                    for(SBQQ__Quote__c newQuote : newList)
                    {
                        for(Customer_360__c c: cutomer360List)
                        {
                            if(newQuote.SBQQ__Account__c == c.Account__c)
                            {
                                newQuote.VG_Basic_Purchased__c = c.VG_Basic_Purchased__c;
                                newQuote.VG_ENT_Purchased__c = c.VG_ENT_Purchased__c;
                            }
                        }
                    }
                }
            }
            if ((relatedShippingAddressIDs.size() > 0) && (shippingData == null)) {
                List<Id> addressIds = new List<Id>();
                addressIds.addAll(relatedShippingAddressIDs);
                shippingData = new Map<Id, Shipping_Address__c>(
                    new GS_ShippingAddressSelector(true).checkFatalError().loadShippingAddressById(addressIds)
                );
            }
            if(relatedQuoteIds.size()>0){
                sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesById(relatedQuoteIds);
            }
            if (relatedOpportunityIDs.size() > 0) {
                opportunityData = new GS_OpportunitySelector(true).checkFatalError().getOpptyWithQuotesById(relatedOpportunityIDs);
                for(SBQQ__Quote__c newQuote : newList) {
                    Opportunity relatedOpportunity = opportunityData.get(newQuote.SBQQ__Opportunity2__c);
                    if(newQuote.isClone()){
                        cloneMappings(newQuote);
                    }
                    if (relatedOpportunity != null) {
                        
                        
                        /*Start  as part of these user story GTMS-21120 By viswa J*/
                        
                        if(String.isNotBlank(relatedOpportunity.SBQQ__RenewedContract__r.Selected_Payment_Type__c) && (system.Label.SystemsAutomationRobotUserId.contains(currentUserId) || Test.isRunningTest())){
                            
                            newQuote.Selected_Payment_Type__c = relatedOpportunity.SBQQ__RenewedContract__r.Selected_Payment_Type__c;
                            
                            newQuote.Process_Eligibility__c = 'Digital Renewals';
                            
                        }else{
                            
                            newQuote.Selected_Payment_Type__c = relatedOpportunity.Selected_Payment_Type__c;
                            
                        }
                        
                        /*End  as part of these user story GTMS-21120 By viswa J*/
  
                        /*GTMS-21781 Start*/
                          if((relatedOpportunity.Owner.ProfileId == System.Label.SamsaraSalesRenewalsNewSystem || relatedOpportunity.Owner.ProfileId == System.Label.SamsaraSalesRenewalsSpecialist) && relatedOpportunity.SBQQ__RenewedContract__c != null && relatedOpportunity.Owner.isActive == true){
                             newQuote.OwnerId = relatedOpportunity.OwnerId;    
                             newQuote.SBQQ__SalesRep__c = relatedOpportunity.OwnerId; //Added for GTMS-27773
                        }  
                         /*GTMS-21781 End*/
                        
                        //Edit by: Govindaraju Boddu (21st, July 2023)
                        newQuote.First_Purchase_Date__c = relatedOpportunity.Account.First_Purchase_Date__c;
                        //Edit PnP2.0 Team GTMS-21393 (23 may 2024) ::: to update the Oppty_Owner_PnP_Pilot__c on Quote from (Owner.P_P_Pilot__c) Oppty, User for PnP CPQ configs
                        newQuote.Oppty_Owner_PnP_Pilot__c = relatedOpportunity.Owner.P_P_Pilot__c;
                        // GTMS-19064 - Update Draft Quote Payment term default value
                        if(relatedOpportunity.Type == 'Revenue Opportunity' && relatedOpportunity.Account.Segment__c != 'AE1'){
                            if((relatedOpportunity.Renewal__c == true || relatedOpportunity.SBQQ__AmendedContract__c != NULL)) { newQuote.SBQQ__PaymentTerms__c = relatedOpportunity.Account.Payment_Terms__c;}
                            if(relatedOpportunity.Insurance_Partner__c != Null) {newQuote.SBQQ__PaymentTerms__c = relatedOpportunity.Insurance_Partner__r.Payment_Terms__c;}
                            if(relatedOpportunity.Finance_Partner__c != Null) { newQuote.SBQQ__PaymentTerms__c = relatedOpportunity.Finance_Partner__r.Payment_Terms__c; }
                            if(relatedOpportunity.Reseller_Partner__c != Null) { newQuote.SBQQ__PaymentTerms__c = relatedOpportunity.Reseller_Partner__r.Payment_Terms__c;}
                        }
  
                        // GTMS-26842 Start
                        if(relatedOpportunity.Type == 'Revenue Opportunity' && relatedOpportunity.SBQQ__RenewedContract__c != null
                           && relatedOpportunity.Account.Payment_Terms__c != null){
                                newQuote.SBQQ__PaymentTerms__c = relatedOpportunity.Account.Payment_Terms__c;
                        }
                        // GTMS-26842 End
  
                        /*if(newQuote.SBQQ__Type__c == 'Amendment')
                        {  */           
                        newQuote.CM_Tier__c = relatedOpportunity.Account.CM_Tier__c;
                        newQuote.VG_Tier__c = relatedOpportunity.Account.VG_Tier__c;
                        /*newQuote.CM_Platform_Tier__c = relatedOpportunity.Account.CM_Platform_Tier__c;
                        newQuote.VG_Platform_Tier__c = relatedOpportunity.Account.VG_Platform_Tier__c;
                        newQuote.Platform_Premium__c = relatedOpportunity.Account.Platform_Premium__c;*/
                        newQuote.Platform_Type__c = relatedOpportunity.Account.Platform_Type__c;
                        newQuote.P_P_Pilot_Customer__c = relatedOpportunity.Account.P_P_Pilot_Customer__c;
                        newQuote.P_P_Customer_Type__c = relatedOpportunity.Account.P_P_Customer_Type__c;//GTMS-27500
                        // GTMS:25074 by Abu Jan 10 2025 Start:
                        if(relatedOpportunity.SBQQ__RenewedContract__c != NULL && relatedOpportunity.SBQQ__RenewedContract__r.P_P_Renewals__c){
                            
                            newQuote.P_P_Pilot_Customer__c = true;
                            newQuote.P_P_Customer_Type__c = 'FY26 P&P'; //GTMS-28592 : Add renewals will happen to FY26 P&P
                            
                        }		
                        // GTMS:25074 by Abu Jan 10 2025 End:
                        //Mohamed - Bridge SKU fields updation on the Quote
                        newQuote.LIC_CM1_PRO__c = relatedOpportunity.Account.LIC_CM1_PRO__c;
                        newQuote.LIC_CM2_PRO__c = relatedOpportunity.Account.LIC_CM2_PRO__c;
                        newQuote.LIC_PLTFM_PRO__c = relatedOpportunity.Account.LIC_PLTFM_PRO__c;
                        newQuote.LIC_VG_PRO__c = relatedOpportunity.Account.LIC_VG_PRO__c;
                        
                        //Mohamed - Bridge SKU fields updation on the Quote, This is part of PnP2.0 changes
                        //}
                        //Edit end: Govindaraju Boddu (21st, July 2023)
                        newQuote.Configuration_Segment__c = relatedOpportunity.Configuration_Segment__c;
                        if (newQuote.Shipping_Address_NEW__c == null) {
                            newQuote.Shipping_Address_NEW__c = relatedOpportunity.Shipping_Address_NEW__c;
                            newQuote.Shipping_Country__c = relatedOpportunity.Shipping_Address_NEW__r.Shipping_Country__c;
                            newQuote.Shipping_State__c = relatedOpportunity.Shipping_Address_NEW__r.Shipping_State__c;
                            newQuote.SBQQ__ShippingName__c = relatedOpportunity.Shipping_Address_NEW__r.Name;
                            newQuote.SBQQ__ShippingStreet__c = relatedOpportunity.Shipping_Address_NEW__r.Shipping_Address_Line_1__c;
                            newQuote.SBQQ__ShippingCity__c  = relatedOpportunity.Shipping_Address_NEW__r.Shipping_City__c;
                            newQuote.SBQQ__ShippingState__c  = relatedOpportunity.Shipping_Address_NEW__r.Shipping_State__c;
                            newQuote.SBQQ__ShippingPostalCode__c = relatedOpportunity.Shipping_Address_NEW__r.Shipping_Zip_Code__c;
                            newQuote.SBQQ__ShippingCountry__c  = relatedOpportunity.Shipping_Address_NEW__r.Shipping_Country__c;
                            newQuote.Shipping_Carrier__c   = 'UPS';
                            newQuote.Shipping_Method__c    = 'Ground';
                            newQuote.Ship_From_Location__c = 'DCL';
                           //GTMS-28141 -- ABU -- 06262025 --> Start
                            if(relatedOpportunity.Shipping_Country__c == 'Canada'){
                                newQuote.Shipping_Carrier__c = 'UPS';
                              newQuote.Shipping_Method__c = 'Ground';
                              newQuote.Ship_From_Location__c = 'ON-Logistics'; 
                            }
                            //GTMS-28141 -- ABU -- 06262025 --> End
                            //GTMS-18016 - Added If for mexico location start
                             if(relatedOpportunity.Shipping_Country__c == 'Mexico') {
                                newQuote.Ship_From_Location__c = 'Estafeta';
                                newQuote.Shipping_Method__c = 'MX Standard';
                                newQuote.Shipping_Carrier__c = 'Estafeta';
                            }
                            //GTMS-18016 - Added If for mexico location end
                        }else{
                            newQuote.Shipping_Address_NEW__c = newQuote.Shipping_Address_NEW__c;
                            Shipping_Address__c relatedShippingAddress = shippingData.get(newQuote.Shipping_Address_NEW__c);
                            setShipToDetails(newQuote, relatedShippingAddress);
                        }
                        // This logic is to add start date (Opportunity close date +15) when quote is created
                        if(relatedOpportunity.CloseDate != null && relatedOpportunity.SBQQ__AmendedContract__c != NULL && relatedOpportunity.Type != 'Free Trial Opportunity' ){
                            newQuote.SBQQ__StartDate__c = relatedOpportunity.CloseDate + 15;
                        }
                        if(relatedOpportunity.Type == 'Free Trial Opportunity' || relatedOpportunity.Type == 'Free Trial Return'){
                            newQuote.License_Term__c = '1';
                            newQuote.License_Term_Defaulted__c = false;
                            newQuote.SBQQ__SubscriptionTerm__c = 1;
                            if(relatedOpportunity.Trial_Period__c != null) {
                                Decimal trialPeriod = Math.ceil(relatedOpportunity.Trial_Period__c/30);
                                newQuote.License_Term__c = String.valueOf(trialPeriod);
                                newQuote.SBQQ__SubscriptionTerm__c = trialPeriod;
                            }
                        }
                        newQuote.Shipping_Account_Type__c = relatedOpportunity.Shipping_Account_Type__c;
                        newQuote.SBQQ__PrimaryContact__c = newQuote.SBQQ__PrimaryContact__c != null ? newQuote.SBQQ__PrimaryContact__c : relatedOpportunity.Related_Contact__c;
                        // newQuote.Selected_Payment_Type__c = relatedOpportunity.Selected_Payment_Type__c;
                        if(newQuote.SBQQ__RenewalTerm__c != NULL){
                            Boolean renewedContract = relatedOpportunity.SBQQ__RenewedContract__c != null;
                            //newQuote.SBQQ__Primary__c = (relatedOpportunity.SBQQ__RenewedContract__r.Auto_Renewal__c || newQuote.OwnerId == '0051P000003KrI8')? TRUE : FALSE;
                            //newQuote.SBQQ__MasterContract__c = renewedContract ? relatedOpportunity.SBQQ__RenewedContract__c : newQuote.SBQQ__MasterContract__c;
                            newQuote.SBQQ__MasterContract__c = newQuote.SBQQ__MasterContract__c == null && relatedOpportunity.ContractId != null ? relatedOpportunity.ContractId : newQuote.SBQQ__MasterContract__c;
                            if(renewedContract && relatedOpportunity.SBQQ__RenewedContract__r.Auto_Renewal__c){
                                newQuote.ApprovalStatus__c = 'Approved';
                                newQuote.SBQQ__Status__c = 'Approved';
                                newQuote.SBQQ__Primary__c = True;
                            }
                        }
                        //GTMS-6422: Populate partner field on quote if the partner information is populated on teh opportunity
                        if(relatedOpportunity.SBQQ__AmendedContract__c != NULL &&
                           (relatedOpportunity.Reseller__c!=null || relatedOpportunity.Reseller_Partner__c !=null || relatedOpportunity.Referral_Partner__c!=null || relatedOpportunity.Insurance_Partner__c !=null )){
                               newQuote.SBQQ__Partner__c = relatedOpportunity.Account.Latest_Partner_Account_Interaction__c;
                               newQuote.channel_partner_discount__c = relatedOpportunity.Account.Latest_Partner_Account_Interaction__r.Partner_Discount__c;
                           }
                        if(relatedOpportunity.SBQQ__AmendedContract__c != NULL && !FeatureManagement.checkPermission('NetSuite_Service_User_Permission') && !cwRoboIds.contains(newQuote.OwnerId)){
                            newQuote.SBQQ__Primary__c = FALSE;
                        }
                        //GTMS-11327 & 12059 : Populate the start date of the quote with the close date of the opportunity to accommodate +1 day to renewed contract end date
                        if(relatedOpportunity.SBQQ__RenewedContract__c <> null && newQuote.SBQQ__StartDate__c == null){newQuote.SBQQ__StartDate__c = relatedOpportunity.CloseDate; }
                        //newQuote.SBQQ__MasterContract__c = relatedOpportunity.ContractId;
                        System.debug('MasterContract : '+newQuote.SBQQ__MasterContract__c +newQuote.SBQQ__StartDate__c);
                        newQuote.Opportunity_Sub_Type__c = relatedOpportunity.Sub_Type__c;
  
                        if (newQuote.SBQQ__Type__c == 'Renewal'){
  
                          if(relatedOpportunity.Account?.Owner?.Region__c != NULL && relatedOpportunity.Account?.Owner?.Region__c != 'None'){
                              if(relatedOpportunity.Account?.Owner?.Region__c == 'EMEA'){ newQuote.Geo_Availablity__c = 'EMEA';  }
                              else if(relatedOpportunity.Account?.Owner?.Region__c == 'North America'){ newQuote.Geo_Availablity__c = 'USA';  }
                          }
                          else{ newQuote.Geo_Availablity__c = 'ALL';}
  
                        } else {
  
                          if(relatedOpportunity.Owner.Region__c != NULL && relatedOpportunity.Owner.Region__c != 'None'){
                              if(relatedOpportunity.Owner.Region__c == 'EMEA'){ newQuote.Geo_Availablity__c = 'EMEA';  }
                              else if(relatedOpportunity.Owner.Region__c == 'North America'){ newQuote.Geo_Availablity__c = 'USA';  }
                          }
                          else{ newQuote.Geo_Availablity__c = 'ALL';}
  
                        }
  
                        //Zakeer-GTMS-4531-Dec6:Updated SegmentAvailaibility
                        if(relatedOpportunity.Segment_Sales_Role__c  != NULL){
                            if(relatedOpportunity.Segment_Sales_Role__c == 'Industrial'){ newQuote.Segment_Availability__c  = 'Fleet; Industrial; Connected Worker';  }
                            else if(relatedOpportunity.Segment_Sales_Role__c == 'Connected Worker'){newQuote.Segment_Availability__c  = 'Fleet; Industrial; Connected Worker';  }
                            else if(relatedOpportunity.Segment_Sales_Role__c.contains('AE1')){
                                newQuote.Segment_Availability__c = 'Fleet';
                                newQuote.Sales_Segment__c = 'AE1';
                            }
                            else if(relatedOpportunity.Segment_Sales_Role__c.contains('AE2')){
                                newQuote.Sales_Segment__c = 'AE2';
                                newQuote.Segment_Availability__c = Label.Segment_Default;
                            }
                            else if(relatedOpportunity.Segment_Sales_Role__c.contains('AE3') || relatedOpportunity.Segment_Sales_Role__c.contains('ENT')){
                                newQuote.Sales_Segment__c = 'AE3';
                                newQuote.Segment_Availability__c = Label.Segment_Default;
                            }
                            else{
                                newQuote.Segment_Availability__c = Label.Segment_Default;
                                newQuote.Sales_Segment__c = 'ALL';
                            }
                        }
                        List<String> botIds = system.Label.Bot_Users.split(',');
                        if (!botIds.contains(currentUserId)) {
                            HelperClass.setShippingDefaults(Null, newQuote, newQuote.SBQQ__ShippingCountry__c);
                        }
                        /*if (relatedOpportunity.ContractId != null) {
                            newQuote.SBQQ__EndDate__c = relatedOpportunity.Contract.EndDate;
                            }*/
                        if (newQuote.SBQQ__EndDate__c != null) {
                            newQuote.License_Term__c = String.valueOf(newQuote.CalculatedSubscriptionTerm__c);
                        }
                        if(eligibleForPaymentTermDefault && (relatedOpportunity.SBQQ__RenewedContract__c == null || !relatedOpportunity.SBQQ__Renewal__c)  
                        && relatedOpportunity.SBQQ__AmendedContract__c != null 
                        && relatedOpportunity.Type == 'Revenue Opportunity'
                        && !relatedOpportunity.Account.Segment__c.contains('AE1')
                        && newQuote.Finance_Partner_Account__c == null
                        && newQuote.Reseller_Account__c == null
                        && !relatedOpportunity.Payment_Type_Opportunity_only_Exception__c 
                        && new list<String>{'Incubate', 'Qualified', 'Trial', 'Proposal', 'Decision', 'Purchase'}.contains(relatedOpportunity.StageName)){
                            defaultPaymentTermsToUpFront(newQuote, (String.isBlank(newQuote.License_Term__c) ? (integer)(relatedOpportunity?.License_Term__c ?? 0) : integer.valueOf(newQuote.License_Term__c)), relatedOpportunity?.Account?.Approved_Payment_Type__c ?? '');
                        }
                        if (relatedOpportunity.Reseller_Partner__c != null) {
                            newQuote.SBQQ__Partner__c = relatedOpportunity.Reseller_Partner__c;
                        }
                        //Satya: commenting as part of 6725
                        /*if(relatedOpportunity.Owner_Role_Copy__c != null && relatedOpportunity.Owner_Role_Copy__c.contains(System.Label.ExpressSegment)
                                || (newQuote.SBQQ__SalesRep__c != null && System.Label.ExpressSegmentOwnerID.contains(newQuote.SBQQ__SalesRep__c))
                                ){
                                newQuote.Configuration_Segment__c = 'Express';
                                }
                                else{
                                newQuote.Configuration_Segment__c = 'Non Express';
                                }*/
                        //[Non Express] Set Start Date on quote based on master contract
                        //coTermedStartDate(newQuote, relatedOpportunity);
                        //GTMS 4092 copying the fields from NB opportunity
                        //Added null check below : GTMS-11159
                        if(relatedOpportunity.Owner_Role_Copy__c <> null && relatedOpportunity.Owner_Role_Copy__c.contains('Renewal') && relatedOpportunity.Renewal__c &&
                           relatedOpportunity.SBQQ__RenewedContract__c != null && relatedOpportunity.SBQQ__RenewedContract__r.SBQQ__Opportunity__c != null) {
                               //Satya:GTMS-5474-Mar3-2022
                               Double originalBlendedDisc = relatedOpportunity.SBQQ__RenewedContract__r.Original_Blended_Discount_Manual__c;
                               newQuote.Original_Blended_Discount__c = originalBlendedDisc == null ?
                                   relatedOpportunity.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Blended_Discount__c : originalBlendedDisc;
                               newQuote.Original_License_Term__c = relatedOpportunity.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.License_Term__c;
                               newQuote.Original_Selected_Payment_Type__c = relatedOpportunity.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c;
                               newQuote.Original_Blended_Discount__c = relatedOpportunity.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Blended_Discount__c;
                               newQuote.Original_License_Term__c = relatedOpportunity.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.License_Term__c;
                               newQuote.Original_Selected_Payment_Type__c = relatedOpportunity.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c;
                           }
                        // ABU:GTMS-15650 09/18/2023
                        List<String> programTypelst = new List<String>();
                        List<String> crProgramType = System.Label.Channel_Relationship_ProgramTypes.split(',');
                        System.debug('relatedOpportunity.Channel_Relationships__r:'+relatedOpportunity.Channel_Relationships__r);
                        for(Channel_Relationship__c str: relatedOpportunity.Channel_Relationships__r){
                            programTypelst.add(str.Program_Type__c);
                        }
                        System.debug('programTypelst:'+programTypelst);
                        System.debug('relatedOpportunity.Insurance_Partner__c:'+relatedOpportunity.Insurance_Partner__c);
                        System.debug('crProgramType:'+crProgramType);
                        If((relatedOpportunity.Insurance_Partner__c != null || relatedOpportunity.Insurance_Partner__c !='') && (programTypelst.contains(crProgramType[0])||programTypelst.contains(crProgramType[1])||programTypelst.contains(crProgramType[2]))){
                            newQuote.Oppty_Insurance_Partner_Check__c = true;
                        }
                        //ABU:End
                    }
                    setTaxData(newQuote);
                }
            }
            FinancePartnerQuoteTriggerHelper.updateQuoteFinancePartner(newList,opportunityData);   // GTMS-16223
  
            //Re-writing the for loop of new list again as below code requires Finance Partner data to be evaluated.
            date defaultPaymentTermsCutOffDate = String.isBlank(System.label.Default_PaymentTerms_AddOn_Quote_Date)? date.valueOf('2025-01-01') : date.valueOf(System.label.Default_PaymentTerms_AddOn_Quote_Date);
            for(SBQQ__Quote__c newQuote : newList) {
  
                if(!opportunityData.containsKey(newQuote.SBQQ__Opportunity2__c)){continue;}
  
                Opportunity relatedOpportunity = opportunityData.get(newQuote.SBQQ__Opportunity2__c);
  
                //For Add On Opportunities, default its Quote to Account's Approved Payment Type
                if((relatedOpportunity.SBQQ__RenewedContract__c == null || !relatedOpportunity.SBQQ__Renewal__c)
            && relatedOpportunity.SBQQ__AmendedContract__c != null
            && relatedOpportunity.Type == 'Revenue Opportunity'
            && !relatedOpportunity.Account.Segment__c.contains('AE1')
            && newQuote.Finance_Partner_Account__c == null
                        && newQuote.Reseller_Account__c == null
            && !relatedOpportunity.Payment_Type_Opportunity_only_Exception__c
            && System.today() >= defaultPaymentTermsCutOffDate){
  
                        newQuote.Selected_Payment_Type__c = relatedOpportunity.Account.Approved_Payment_Type__c;
                }
            }
  
            updateQuoteFields(oldMap, newMap, newList, opportunityData);
            ShippingHandlingCalculations.updateShippingAndHandlingForQuote(newList, opportunityData);
            new GS_SBQQQuoteWorkflowService(oldMap, newMap, newList).performWorkflowActions();
        }
  
        public void handleAfterInsertOperations(){
            thisLogger.logDebug('handleAfterInsertOperations Quote List ::', newList);
            //new GS_QuoteEventService().createQuoteSavePE(newList);
            new GS_SBQQQuoteLineService().createQuoteLines(newMap.keySet());
        }
        public void handleBeforeUpdateOperations(){
            thisLogger.logDebug('handleBeforeUpdateOperations New Quote List ::', newList);
            thisLogger.logDebug('handleBeforeUpdateOperations Old Quote Map ::', oldMap.values());
            Map<Id,Decimal> mapQuoteIdAndTotalSubsidyAmount = new Map<Id,Decimal>();
            Map<Id, SObject> unprocessedRecords = GS_TriggerRecursionManager.getNonRecursiveRecords(
                'SBQQ__Quote__c', 'before_update', newMap
            );
            for(SBQQ__Quote__c newQuote : newList){
                // GTMS-25783 - To bypass Return_opp_Quotes_are_Locked_for_sel Quote validation rule
                // GTMS-26249 - To bypass Flex_Prevent_Quote_Modification validation
                if (!FlexCnRTriggerBypass__c.getInstance().Bypass_Sync_and_Flag_Reset_Logic__c && (System.isFuture() || System.isScheduled() || System.isBatch() || System.isQueueable() || newQuote.SBQQ__LastCalculatedOn__c < newQuote.SBQQ__LastSavedOn__c || (newQuote.Snapshot_Quote__c == true && OpportunityTriggerHandler.bypassForSyncMechanism == true))) {
                    newQuote.Flex_Bypass_Validation_Rule_Date_Time__c = Datetime.now();
                }
            }
            if (unprocessedRecords.size() == 0) {
                thisLogger.logDebug('handleBeforeUpdateOperations All Quotes are already executed, so exiting the trigger.');
                return;
            }
            
            String shippingAndHandlingTaxLocations = System.Label.Shipping_and_Handling_Tax;
            set<id> billToAcctIds = new set<id>();
            set<Id> billToContacts = new Set<Id>();
            Map<Id, Account> billToAcctMap = new Map<Id, Account>();
            Map<Id,Contact> mapOfContacts=new Map<Id,Contact>();
            sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesAndQuoteLinesById(newMap.KeySet());

            Automation_Settings__c stageValidationSetting = Automation_Settings__c.getValues('Stage Validation');

            boolean globalStageValidationDisabled= stageValidationSetting?.Disabled__c ?? false;
            Map<String, Oppty_Stage_Validation_Exempt__c> ruleExemptRoleMap = Oppty_Stage_Validation_Exempt__c.getAll();
            list<Oppty_Stage_Validation_Exempt__c> ruleExemptRoles = new list<Oppty_Stage_Validation_Exempt__c>();

            if( !ruleExemptRoleMap.isEmpty() ) { ruleExemptRoles = ruleExemptRoleMap.values(); }

            if( !Utility.hasPermission('Validation_Rule_Exemption') 
                && !Utility.hasPermission('Validation_Exemption_Opportunity')
                && !Utility.areValidationsSkippedAtCustomSettings( currentUserId )
                && !skipValidations )
            {
                for(SBQQ__Quote__c newQuote : newList)
                {
                    performStageValidation( newQuote, oldMap.get( newQuote.Id ), sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r, globalStageValidationDisabled, ruleExemptRoles );
                }
            }

            RebateLogicHandler.checkFirstInvoiceAmounts(oldMap, newList);//GTMS-26606
            RebateLogicHandler.calculateBuyoutAmount(oldMap, newList);//GTMS-26318
  
            B360LogicHandler.handleBADValidation(sourceQuoteData, oldMap, newList); //GTMS-28089
            B360LogicHandler.setB360APIStatusOnApprovedQuote(sourceQuoteData, oldMap, newList);//GTMS-28870
  
            String currentUserProfileId = userInfo.getProfileId();
            Boolean eligibleForPaymentTermDefault = String.isBlank(System.label.Default_PaymentTerms_Quote_Date)? true : date.valueOf(System.label.Default_PaymentTerms_Quote_Date) <= System.today();
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
            List<String> at11ProductsList = System.Label.AT11_products.split(','); 
  
            for(SBQQ__Quote__c newQuote : newList){
                if (sourceQuoteData.containsKey(newQuote.Id)) {
                    Opportunity relatedOpportunity = sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r;
                    if(relatedOpportunity != null){
                      opportunityMap.put(relatedOpportunity.Id, relatedOpportunity);
                    }
  
                     Boolean isActiveQuoteOwner = sourceQuoteData.get(newQuote.Id).owner.isActive; 
                     if (relatedOpportunity != null && relatedOpportunity.SBQQ__RenewedContract__c != null) {
  
                        //GTMS-26842 Start
                        if(newQuote.SBQQ__Status__c != 'Approved' && (newQuote.SBQQ__PaymentTerms__c!= sourceQuoteData.get(newQuote.Id).SBQQ__Account__r.Payment_Terms__c)){
                            newQuote.SBQQ__PaymentTerms__c = sourceQuoteData.get(newQuote.Id).SBQQ__Account__r.Payment_Terms__c;
                        }
                        //GTMS-26842 End
                     }
  
                    Id newQuoteOwnerProfileId = sourceQuoteData.get(newQuote.Id).Owner.ProfileId;
  
                    if ((newQuoteOwnerProfileId == System.Label.SamsaraSalesRenewalsNewSystem || newQuoteOwnerProfileId == System.Label.SamsaraSalesRenewalsSpecialist)  && newQuote.SBQQ__Type__c == 'Quote') {
                        newQuote.SBQQ__Type__c = 'Renewal';
                    }
                    date updatePaymentTermsCutOffDate = String.isBlank(System.label.Update_PaymentTerms_AddOn_Quote_Date)? date.valueOf('2025-01-01') : date.valueOf(System.label.Update_PaymentTerms_AddOn_Quote_Date);
  
                    if((relatedOpportunity.SBQQ__RenewedContract__c == null || !relatedOpportunity.SBQQ__Renewal__c) 
                        && relatedOpportunity.SBQQ__AmendedContract__c != null 
                        && newQuote.createddate >= updatePaymentTermsCutOffDate 
                        && newQuote.Of_LIC_Products__c != oldMap.get(newQuote.Id).Of_LIC_Products__c 
                        && newQuote.Of_LIC_Products__c != null
                        && relatedOpportunity.Type == 'Revenue Opportunity'
                        && !relatedOpportunity.Account.Segment__c.contains('AE1')
                        && !relatedOpportunity.isClosed
                        && newQuote.Finance_Partner_Account__c == null
                        && newQuote.Reseller_Account__c == null
                        && !relatedOpportunity.Payment_Type_Opportunity_only_Exception__c){
  
                            newQuote.Selected_Payment_Type__c = newQuote.Of_LIC_Products__c > 0 ?
                                                                    relatedOpportunity.Account.Approved_Payment_Type__c : 'Upfront Payments';
                    }
                    
                 /*GTMS- 27600 START Commented For Future PurposeAdd commentMore actions
          Formula for ACV Booking on QUOTE  - 
          IF( AND( NOT(ISBLANK(Quote_ACV_Copy__c)), Quote_ACV_Copy__c &lt;&gt; 0 ), Quote_ACV_Copy__c, Add commentMore actions
                    IF( SBQQ__Opportunity2__r.CloseDate &lt; DATEVALUE($Label.Annualize_ACV_Date),
                    IF( SBQQ__SubscriptionTerm__c &lt; 12, IF(ACV_Bookings_Rollup__c &gt; 0, ACV_Bookings_Rollup__c, SBQQ__NetAmount__c),
                    (IF(ACV_Bookings_Rollup__c &gt; 0, ACV_Bookings_Rollup__c, SBQQ__NetAmount__c) / SBQQ__SubscriptionTerm__c) * 12 ),
                    (IF(ACV_Bookings_Rollup__c &gt; 0, ACV_Bookings_Rollup__c, SBQQ__NetAmount__c) / SBQQ__SubscriptionTerm__c) * 12 ) )
  
                    // New Logic: Calculate Annualized ACV
                    if(relatedOpportunity != null && relatedOpportunity.CloseDate >= Date.valueOf(System.Label.X27600_Quote_ACV_New_Logic_Date)){
                        Decimal totalACV = 0;
                        Date annualizeACVDate = Date.valueOf(System.Label.Annualize_ACV_Date);
                        Decimal selectedAmountForOldLogic = (newQuote.ACV_Bookings_Rollup__c != null && newQuote.ACV_Bookings_Rollup__c > 0) 
                            ? newQuote.ACV_Bookings_Rollup__c 
                            : (newQuote.SBQQ__NetAmount__c != null ? newQuote.SBQQ__NetAmount__c : 0);
                        Decimal selectedAmountForNewLogic = (newQuote.ACV_Bookings_Rollup__c != null && newQuote.ACV_Bookings_Rollup__c <> 0) 
                            ? newQuote.ACV_Bookings_Rollup__c 
                            : (newQuote.SBQQ__NetAmount__c != null ? newQuote.SBQQ__NetAmount__c : 0);
                                // Non-revenue condition
                                Boolean isNonRevenueEdgeCase = relatedOpportunity.Type != 'Revenue Opportunity' &&                           
                                sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Returning_Opportunity__r != null &&
                                sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Returning_Opportunity__r.CloseDate != null &&
                                sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Returning_Opportunity__r.CloseDate < annualizeACVDate &&
                                sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Returning_Opportunity__r.SBQQ__PrimaryQuote__c != null &&
                                sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Returning_Opportunity__r.SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c != null &&
                                sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Returning_Opportunity__r.SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c < 12 &&
                                newQuote.SBQQ__SubscriptionTerm__c != null &&
                                newQuote.SBQQ__SubscriptionTerm__c < 12;
                        
                        if (isNonRevenueEdgeCase) {
                            totalACV = selectedAmountForOldLogic; 
                        } else if (newQuote.SBQQ__SubscriptionTerm__c != null && newQuote.SBQQ__SubscriptionTerm__c > 0 && selectedAmountForNewLogic != 0) {
                            totalACV = (selectedAmountForNewLogic / newQuote.SBQQ__SubscriptionTerm__c) * 12; 
                        } else {
                            totalACV = 0; 
                        }
                        
                        newQuote.Quote_ACV_Copy__c  = totalACV.setScale(2);
                    }
                    /*GTMS- 27600 END*/
                
                /*GTMS-24865* START*/
                    if(sourceQuoteData.get(newQuote.Id).Finance_Partner_Account__c != null && sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c != null){
                Boolean isActiveFinancePartner = sourceQuoteData.get(newQuote.Id).Finance_Partner_Account__c != null ? sourceQuoteData.get(newQuote.Id).Finance_Partner_Account__r.Is_Finance_Partner_Active__c : false;
                        if(newQuote.Finance_Partner_Account__c != null && !isActiveFinancePartner){
                    newQuote.Finance_Partner_Account__c = null;
                }
                    }
                /*GTMS-24865 END*/
                }
                
                if (newQuote.Is_Webstore_Upsell_Quote__c==true && newQuote.Finance_Partner_Account__c != null){// added for GTMS-19857
                    newQuote.Finance_Partner_Account__c = null;
                }
                //GTMS-27248: Logic to update Quote payment terms when finance partner account is updated for Revenue Opportunities
               if(sourceQuoteData != null && sourceQuoteData.containsKey(newQuote.Id) && sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Type == 'Revenue Opportunity' 
                   && sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c == null && newQuote.Finance_Partner_Account__c != null
                   && newQuote.Finance_Partner_Account__c != oldMap.get(newQuote.Id).Finance_Partner_Account__c
                  ) { billToAcctIds.add(newQuote.Finance_Partner_Account__c);}
                
                if(newQuote.Finance_Partner_Account__c == null && sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Type=='Revenue Opportunity'){
                    //GTMS-25155
                    if(newQuote.Reseller_Account__c != sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Reseller__c){
                        newQuote.SBQQ__PaymentTerms__c = sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Reseller__c == null ? sourceQuoteData.get(newQuote.Id).SBQQ__Account__r.Payment_Terms__c : sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Payment_Terms__c;
                    }
                    //GTMS-25155
                    newQuote.Reseller_Account__c = sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Reseller__c;
                }
                if(Test.isRunningTest() || newQuote.DCA_Validation__c == 'DCA'){
                    
                    if(newQuote.Bill_to_Account__c!=null){
                        billToAcctIds.add(newQuote.Bill_to_Account__c);
                    }
                    if(newQuote.Finance_Partner_Account__c!=null){
                        billToAcctIds.add(newQuote.Finance_Partner_Account__c);
                    }
                    if(newQuote.Reseller_Account__c!=null){
                        billToAcctIds.add(newQuote.Reseller_Account__c);
                    }
                    if(newQuote.Bill_to_Contact__c != null){
                        billToContacts.add(newQuote.Bill_to_Contact__c) ;
                    }
                }
                
                if (newQuote.Is_Promo__c == true && newQuote.Is_Promo__c != oldMap.get(newQuote.Id).Is_Promo__c) {
                    // Automatically set these fields when Is_Promo__c is true
                    newQuote.Can_Discount_a_la_Carte_Hardware__c = true;
                    newQuote.Selected_Payment_Type__c = 'Upfront Payments';
                }
                // Check if the quote is approved and the discount is 100% or greater
                if (newQuote.ApprovalStatus__c == 'Approved' && newQuote.ApprovalStatus__c != oldMap.get(newQuote.Id).ApprovalStatus__c && newQuote.Blended_Discount__c >= 100) {
                    // Set Shipping_and_Handling_Manual__c to 0 when the discount is 100% or more and the quote is approved
                    newQuote.Shipping_and_Handling_Manual__c = 0;
                }  
            }
            if(billToAcctIds.size()>0){
                billToAcctMap=new Map<Id,Account>([Select id,name,Billing_Email__c,Billing_Contact__c, BillingCity,BillingCountry,	BillingState,BillingStreet,BillingPostalCode,Payment_Terms__c From Account Where id= :billToAcctIds]);
            }
            if(billToContacts.size()>0){
                mapOfContacts = new Map<Id,Contact>([Select Id,AccountId From contact where Id =:billToContacts]);
            }
            for(SBQQ__Quote__c newQuote : newList){
                Id newShippingAddressId = newMap.get(newQuote.Id).Shipping_Address_NEW__c;
                Id oldShippingAddressId = oldMap.get(newQuote.Id).Shipping_Address_NEW__c;
                // GTMS-16585
                if(Test.isRunningTest() || newQuote.DCA_Validation__c == 'DCA'){
                    if(newQuote.Finance_Partner_Account__c != null ){
                        newQuote.Bill_to_Account__c = newQuote.Finance_Partner_Account__c;
                    } else if (newQuote.Reseller_Account__c != null ){
                        newQuote.Bill_to_Account__c = newQuote.Reseller_Account__c;
                    } else if (newQuote.SBQQ__Account__c != null ){
                        newQuote.Bill_to_Account__c = newQuote.SBQQ__Account__c;
                    }
                }
                //GTMS-27248: Update Quote payment terms with finance partner account/Account payment terms for Revenue Opportunities      
                if(sourceQuoteData != null && sourceQuoteData.containsKey(newQuote.Id) && sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.Type == 'Revenue Opportunity'            
                   && sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c == null && newQuote.Finance_Partner_Account__c != oldMap.get(newQuote.Id).Finance_Partner_Account__c
                  ) { if(newQuote.Finance_Partner_Account__c != null && billToAcctMap != null && billToAcctMap.containsKey(newQuote.Finance_Partner_Account__c)){
                          newQuote.SBQQ__PaymentTerms__c = billToAcctMap.get(newQuote.Finance_Partner_Account__c).Payment_Terms__c;
                      } else if(newQuote.Finance_Partner_Account__c == null && sourceQuoteData.get(newQuote.Id).SBQQ__Account__r != null) {
                          newQuote.SBQQ__PaymentTerms__c = sourceQuoteData.get(newQuote.Id).SBQQ__Account__r.Payment_Terms__c;
                      }
                  }
                if ( String.isNotBlank(newQuote.Billing_Emails__c) ){ newQuote.Consolidated_Billing_Email__c = newQuote.Billing_Emails__c;
                }else{
                    if(newQuote.Bill_to_Account__c!=null && billToAcctMap != null && billToAcctMap.containsKey(newQuote.Bill_to_Account__c) ) {
                        newQuote.Consolidated_Billing_Email__c = billToAcctMap.get(newQuote.Bill_to_Account__c).Billing_Email__c;
                    }
                }
                if(newQuote.Bill_to_Account__c!=null && billToAcctMap != null && billToAcctMap.containsKey(newQuote.Bill_to_Account__c) && (Test.isRunningTest() || newQuote.DCA_Validation__c == 'DCA')){
                    if(newQuote.SBQQ__BillingCity__c != billToAcctMap.get(newQuote.Bill_to_Account__c).BillingCity){
                        newQuote.SBQQ__BillingCity__c = billToAcctMap.get(newQuote.Bill_to_Account__c).BillingCity;
                    }
                    if(newQuote.SBQQ__BillingCountry__c != billToAcctMap.get(newQuote.Bill_to_Account__c).BillingCountry){
                        newQuote.SBQQ__BillingCountry__c = billToAcctMap.get(newQuote.Bill_to_Account__c).BillingCountry;
                    }
                    if(newQuote.SBQQ__BillingState__c != billToAcctMap.get(newQuote.Bill_to_Account__c).BillingState){
                        newQuote.SBQQ__BillingState__c = billToAcctMap.get(newQuote.Bill_to_Account__c).BillingState;
                    }
                    if(newQuote.SBQQ__BillingPostalCode__c != billToAcctMap.get(newQuote.Bill_to_Account__c).BillingPostalCode){
                        newQuote.SBQQ__BillingPostalCode__c = billToAcctMap.get(newQuote.Bill_to_Account__c).BillingPostalCode;
                    }
                    if(newQuote.SBQQ__BillingStreet__c != billToAcctMap.get(newQuote.Bill_to_Account__c).BillingStreet){
                        newQuote.SBQQ__BillingStreet__c = billToAcctMap.get(newQuote.Bill_to_Account__c).BillingStreet;
                    }
                    if(newQuote.Bill_to_Contact__c == null){
                        newQuote.Bill_to_Contact__c =  billToAcctMap.get(newQuote.Bill_to_Account__c).Billing_Contact__c;
                    }
                }
                
                if(newQuote.Bill_to_Account__c!=null  && newQuote.Bill_to_Contact__c != null && mapOfContacts.containsKey(newQuote.Bill_to_Contact__c) && (Test.isRunningTest() || newQuote.DCA_Validation__c == 'DCA')){
                    //contact c = (mapOfContacts != null && mapOfContacts.containsKey(newQuote.Bill_to_Contact__c )) ? mapOfContacts.get(newQuote.Bill_to_Contact__c):null;
                    Contact con = mapOfContacts.get(newQuote.Bill_to_Contact__c);
                    if( con != null && con.AccountId != newQuote.Bill_to_Account__c ){
                        newQuote.Bill_to_Contact__c = null;
                    }
                }
                if(oldShippingAddressId != newShippingAddressId){
                    if (newShippingAddressId != null) {
                        relatedShippingAddressIDs.add(newShippingAddressId);
                    }
                    if (oldShippingAddressId != null) {
                        relatedShippingAddressIDs.add(oldShippingAddressId);
                    }
                }
                // Added as part of user story GTMS-19837
                if(((newQuote.Finance_Partner_Account__c != null && newQuote.Finance_Partner_Account__c !=  oldMap.get(newQuote.Id).Finance_Partner_Account__c )
                    || (newQuote.Reseller_Account__c != null && newQuote.Reseller_Account__c !=  oldMap.get(newQuote.Id).Reseller_Account__c ))
                   && (newQuote.DCA_Validation__c == 'DCA' || Test.isRunningTest())){
                       newQuote.Customer_Preferred_Payment_Method__c = 'Check/Wire';
                   }
                if(((newQuote.Finance_Partner_Account__c == null && newQuote.Reseller_Account__c == null) && string.isEmpty(newQuote.Customer_Preferred_Payment_Method__c) )
                   && (newQuote.DCA_Validation__c == 'DCA' || Test.isRunningTest())){
                       newQuote.Customer_Preferred_Payment_Method__c = 'Credit Card/ACH Debit';
                   }
                relatedContractIDs.add(newQuote.SBQQ__MasterContract__c);
                if (newQuote.Co_Term_Contract__c != null) relatedContractIDs.add(newQuote.Co_Term_Contract__c);
            }
            mapQuoteIdAndTotalSubsidyAmount = calculateTotalQuotelineSubsidy(newMap.keySet())  ;
            sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesAndQuoteLinesById(newMap.KeySet());
            
            if((relatedContractIDs.size()>0) && (contractData == null)){
                contractData = new GS_ContractSelector().getContractData(relatedContractIDs);
            }
            // Logic to stamp shipping state and country from the shipping address.
            if((relatedShippingAddressIDs.size()>0) && (shippingData == null)){
                List<Id> addressIds = new List<Id>();
                addressIds.addAll(relatedShippingAddressIDs);
                shippingData = new Map<Id, Shipping_Address__c>(
                    new GS_ShippingAddressSelector(true).checkFatalError().loadShippingAddressById(addressIds)
                );
            }
            ShippingHandlingCalculations.getShippingConfigurations(); // GTMS-28236 Rodrigo
            for(SBQQ__Quote__c updatedQuote : newList){
                /*if(sourceQuoteData != null && sourceQuoteData.containsKey(updatedQuote.Id) && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r != null){
                        Opportunity relatedOpportunity = sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r;
                        if (relatedOpportunity != null) {
                        coTermedStartDate(updatedQuote, relatedOpportunity);
                        }
                        }*/
                //GTMS-23000
                if(sourceQuoteData != null && sourceQuoteData.containsKey(updatedQuote.Id) && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__c != null &&
                   sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c != null &&
                   sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c != null &&
                   updatedQuote.SBQQ__StartDate__c <> sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c ){
                       updatedQuote.SBQQ__StartDate__c = sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c ;
                   }
                if(sourceQuoteData != null && sourceQuoteData.containsKey(updatedQuote.Id)
                   && String.isNotBlank(sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Owner_Role_Copy__c)
                   && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Owner_Role_Copy__c.contains('AE1')){
                       updatedQuote.SBQQ__PaymentTerms__c = sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Payment_Terms__c;
                   }
                if(mapQuoteIdAndTotalSubsidyAmount.containsKey(updatedQuote.Id)){
                    updatedQuote.Total_Quote_Line_Item_Subsidy_amount__c   =  mapQuoteIdAndTotalSubsidyAmount.get(updatedQuote.id);
                }
                if(shippingData != null){
                    Shipping_Address__c relatedShippingAddress = shippingData.get(updatedQuote.Shipping_Address_NEW__c);
                    GS_SBQQQuoteService.setShipToDetails(updatedQuote, relatedShippingAddress);
                }
                /*if(contractData != null){
                    Contract relatedContract = contractData.get(updatedQuote.SBQQ__MasterContract__c);
                    if(relatedContract != null){
                    updatedQuote.SBQQ__EndDate__c = relatedContract.EndDate;
                    }
                    }*/
                                    /* if(updatedQuote.SBQQ__EndDate__c != null){
                    //Zakeer: Commented- GTMS5626
                    //updatedQuote.License_Term__c = String.valueOf(updatedQuote.CalculatedSubscriptionTerm__c);
                    } */
                                    //Zakeer- GTMS5626-RenewalLicenseEndDate-GTMS6298
                                    //GTMS-11327
                                    /*GTMS-10935
                    !updatedQuote.Change_License_End_Date__c && updatedQuote.SBQQ__Type__c == 'Renewal'
                    && updatedQuote.SBQQ__MasterContract__c == NULL && sourceQuoteData <> null && sourceQuoteData.get(updatedQuote.Id) <> null
                    && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__c <> null && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c <> null
                    && !sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Auto_Renewal__c
                    */
                //GTMS-13687
                //removed from if GTMS-15704: && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Auto_Renewal__c
                if( sourceQuoteData <> null && sourceQuoteData.get(updatedQuote.Id) <> null
                   && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__c <> null
                   && sourceQuoteData.get(updatedQuote.Id).SBQQ__Account__c <> null
                   && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c <> null
                   && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate <> null
                   && updatedQuote.Co_Term_Contract__c == NULL && sourceQuoteData.get(updatedQuote.Id).SBQQ__Account__r.Latest_Active_Contract__c <> NULL
                   && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Adjusted_RenewalOpp_EndDate__c <> null
                   && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Skip_Silent_Auto_Renewal__c == false
                   && sourceQuoteData.get(updatedQuote.Id).SBQQ__Account__r.Skip_Silent_Auto_Renewal__c == false
                   && sourceQuoteData.get(updatedQuote.Id).SBQQ__Account__r.Latest_Active_Contract__r.EndDate >=
                   sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate.addMonths(12)){
                       //updatedQuote.SBQQ__EndDate__c = Date.valueOf(updatedQuote.SBQQ__StartDate__c-1).addMonths(Integer.valueOf(updatedQuote.License_Term__c));
                       //updatedQuote.SBQQ__EndDate__c = sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Adjusted_RenewalOpp_EndDate__c;
                       updatedQuote.Co_Term_Contract__c = sourceQuoteData.get(updatedQuote.Id).SBQQ__Account__r.Latest_Active_Contract__c;
                   }
                   if(updatedQuote.SBQQ__EndDate__c != null && (updatedQuote.SBQQ__MasterContract__c <> null || updatedQuote.Co_Term_Contract__c <> null || (sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__c != Null && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__AmendedContract__c <> null)
                                                                || (sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__c != NULL && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Processing_Type__c != NULL &&
                                                                    sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Processing_Type__c == 'Fixed End Date'))){
                    updatedQuote.License_Term__c = String.valueOf(updatedQuote.CalculatedSubscriptionTerm__c);
                }
                if(eligibleForPaymentTermDefault && (sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c == null || !sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__Renewal__c) 
                && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__AmendedContract__c != null 
                && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Type == 'Revenue Opportunity'
                && !sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Account.Segment__c.contains('AE1')
                && updatedQuote.Finance_Partner_Account__c == null
                && updatedQuote.Reseller_Account__c == null
                && !sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Payment_Type_Opportunity_only_Exception__c && new list<String>{'Incubate', 'Qualified', 'Trial', 'Proposal', 'Decision', 'Purchase'}.contains(sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.StageName)){
                            defaultPaymentTermsToUpFront(updatedQuote, (integer) (String.isBlank(updatedQuote?.License_Term__c) ? 0 : integer.valueOf(updatedQuote?.License_Term__c)),
                            sourceQuoteData.get(updatedQuote.Id).SBQQ__Account__r?.Approved_Payment_Type__c ?? '');
                 }
                if((sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__Renewal__c || sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Renewal__c
                    || sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c != Null)
                   && (oldMap.get(updatedQuote.Id).SBQQ__StartDate__c <> updatedQuote.SBQQ__StartDate__c || (updatedQuote.License_Term__c <> NULL
                                                                                                             && oldMap.get(updatedQuote.Id).License_Term__c  <> updatedQuote.License_Term__c) || (updatedQuote.Custom_License_Term__c  <> NULL
                                                                                                                                                                                                  && oldMap.get(updatedQuote.Id).Custom_License_Term__c <> updatedQuote.Custom_License_Term__c))){
                                                                                                                                                                                                      if(((updatedQuote.SBQQ__StartDate__c != NULL && updatedQuote.License_Term__c <> NULL) && oldMap.get(updatedQuote.Id).License_Term__c  <> updatedQuote.License_Term__c)
                                                                                                                                                                                                         || ((updatedQuote.SBQQ__StartDate__c != NULL && updatedQuote.License_Term__c <> NULL) && oldMap.get(updatedQuote.Id).SBQQ__StartDate__c <> updatedQuote.SBQQ__StartDate__c)) {
                                                                                                                                                                                                             updatedQuote.SBQQ__EndDate__c = Date.valueOf(updatedQuote.SBQQ__StartDate__c - 1).addMonths(Integer.valueOf(updatedQuote.License_Term__c));
                                                                                                                                                                                                         }
                                                                                                                                                                                                      else if(updatedQuote.SBQQ__StartDate__c != Null && updatedQuote.Custom_License_Term__c  <> NULL && oldMap.get(updatedQuote.Id).Custom_License_Term__c   <> updatedQuote.Custom_License_Term__c ){
                                                                                                                                                                                                          updatedQuote.SBQQ__EndDate__c = Date.valueOf(updatedQuote.SBQQ__StartDate__c - 1).addMonths(Integer.valueOf(updatedQuote.Custom_License_Term__c ));
                                                                                                                                                                                                      }
                                                                                                                                                                                                  }
                
                /*if(oldMap.get(updatedQuote.Id).Selected_Payment_Type__c != updatedQuote.Selected_Payment_Type__c){  
                updatedQuote.Recalculate_Quote__c = true;   
                }*/
                
                if((updatedQuote.Shipping_Address_NEW__c != null && oldMap.get(updatedQuote.Id).Shipping_Address_NEW__c != updatedQuote.Shipping_Address_NEW__c &&
                    ShippingData != null && (ShippingData.containsKey(updatedQuote.Shipping_Address_NEW__c)))) {
                        String oldShippingAddressId = oldMap.get(updatedQuote.Id).Shipping_Address_NEW__c;
                        String oldShippingCountry;
                        if(oldShippingAddressId != null) {
                            //relatedShippingAddressIDs.add(oldShippingAddressId);
                            //getShippingData(relatedShippingAddressIDs);
                            oldShippingCountry = shippingData != null && shippingData.containsKey(oldShippingAddressId) ?
                                shippingData.get(oldShippingAddressId).Shipping_Country__c : '';
                        }
                        String shippingCountry = ShippingData != null && ShippingData.containsKey(updatedQuote.Shipping_Address_NEW__c) ?
                            ShippingData.get(updatedQuote.Shipping_Address_NEW__c).Shipping_Country__c : '';
                        List<String> botIds = system.Label.Corpweb_SFDC_Robot.split(',');
                        if(oldShippingCountry != shippingCountry && !botIds.contains( currentUserId )) {
                            HelperClass.setShippingDefaults(Null, updatedQuote, shippingCountry);
                        }
                    } /*GTMS-2040 Teja*/
                /* GTMS-10697 - new IS PROMO? Field logic for new workflow*/
                if (updatedQuote.Is_Promo__c && !(oldMap.get(updatedQuote.Id).Is_Promo__c)){
                    updatedQuote.Can_Discount_a_la_Carte_Hardware__c = true;
                    updatedQuote.Selected_Payment_Type__c = 'Upfront Payments';
                }
                //ONLY get shipping defaults if the shipping country in the address has changed
                if(updatedQuote.Shipping_and_Handling__c != null && updatedQuote.Shipping_and_Handling__c > 0  && updatedQuote.Shipping_and_Handling__c != 99999.99
                   && updatedQuote.Sales_Tax_Rate__c != null && updatedQuote.Sales_Tax_Rate__c > 0 && updatedQuote.Sales_Tax_Rate__c < 100
                   && ((updatedQuote.Shipping_Country__c != null && !(shippingAndHandlingTaxLocations.contains(updatedQuote.Shipping_Country__c))))){
                       updatedQuote.S_H_Tax__c = updatedQuote.Shipping_and_Handling__c*(updatedQuote.Sales_Tax_Rate__c/100);
                   } else{
                       updatedQuote.S_H_Tax__c = 0;
                   }
                //GTMS - 10234 starts here
                if ((updatedQuote.Total_Weight_oz__c > 2500) && ((updatedQuote.Shipping_Country__c == 'United States') ||(updatedQuote.Shipping_Country__c == 'Canada'))
                    &&((updatedQuote.Override__c == false) && (updatedQuote.Override_Freight_Shipping__c == false)))
                {
                    updatedQuote.Shipping_Carrier__c = 'FEDEX FREIGHT';
                    updatedQuote.Shipping_Method__c = 'ECONOMY';
                }
                //GTMS - 10234 ends here
                // GTMS-15659 starts here
                /* commented and move to another class
                    DateTime myDateTime = DateTime.now();
                    if (updatedQuote.ApprovalStatus__c == 'Recalled' && updatedQuote.Quote_ACV__c != oldMap.get(updatedQuote.Id).Quote_ACV__c) {
                    if(!isWithinThreePercent(updatedQuote.Quote_ACV__c,oldMap.get(updatedQuote.Id).Quote_ACV__c))
                    updatedQuote.Smart_Approve_Fields_Indicator__c = (updatedQuote.Smart_Approve_Fields_Indicator__c != null) ? updatedQuote.Smart_Approve_Fields_Indicator__c + 5 : myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year();
                    }
                    if (updatedQuote.ApprovalStatus__c == 'Recalled' && updatedQuote.Buyout_Amount__c != oldMap.get(updatedQuote.Id).Buyout_Amount__c) {
                    if(!isWithinThreePercent(updatedQuote.Buyout_Amount__c,oldMap.get(updatedQuote.Id).Buyout_Amount__c))
                    updatedQuote.Smart_Approve_Fields_Indicator__c = (updatedQuote.Smart_Approve_Fields_Indicator__c != null) ? updatedQuote.Smart_Approve_Fields_Indicator__c + 5 : myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year();
                    }
                    if (updatedQuote.ApprovalStatus__c == 'Recalled' && updatedQuote.Subsidy_Amount__c != oldMap.get(updatedQuote.Id).Subsidy_Amount__c) {
                    if(!isWithinThreePercent(updatedQuote.Subsidy_Amount__c,oldMap.get(updatedQuote.Id).Subsidy_Amount__c))
                    updatedQuote.Smart_Approve_Fields_Indicator__c = (updatedQuote.Smart_Approve_Fields_Indicator__c != null) ? updatedQuote.Smart_Approve_Fields_Indicator__c + 5 : myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year();
                    }
                    commented and move to another class*/
                // GTMS-15659 ends here
                // GTMS-11854
                // Logic to populate the Quote End Date
                //GTMS-25399 Start
                if(sourceQuoteData != null && sourceQuoteData.containsKey(updatedQuote.Id) && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__c != null){
                    if(sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__AmendedContract__c != null
                       && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Type == 'Revenue Opportunity'){
                           if(updatedQuote.SBQQ__StartDate__c != sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Closedate +15 && currentUserId == System.Label.SkipAddressUpdate) {
                               updatedQuote.SBQQ__StartDate__c = sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Closedate +15;
                           }
                       }
                }
                //GTMS-25399 End
                Date QuoteEndDate = null;
                if(sourceQuoteData != NULL && sourceQuoteData.containsKey(updatedQuote.Id)){
                    if((sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__c != Null && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.SBQQ__AmendedContract__c != null) || updatedQuote.SBQQ__MasterContract__c != null) {
                        QuoteEndDate = updatedQuote.Contract_End_Date__c;
                    } else if(updatedQuote.Co_Term_Contract__c != null) {
                        QuoteEndDate =sourceQuoteData.get(updatedQuote.Id).Co_Term_Contract__r.EndDate;
                    }
                }
                if (QuoteEndDate != NULL && updatedQuote.SBQQ__EndDate__c != QuoteEndDate){
                    updatedQuote.SBQQ__EndDate__c = QuoteEndDate;
                }
                // Method to clear the Approved Discount on Quote
                clearOutApprovedQuote(updatedQuote, oldMap.get(updatedQuote.Id));
                setTaxData(updatedQuote);
                Automation_Settings__c stampUpfrontAndAnnualPaymentsToggle = Automation_Settings__c.getInstance('GTMS-25799');
              Boolean stampUpfrontAndAnnualPaymentsDisabled =  stampUpfrontAndAnnualPaymentsToggle != null && stampUpfrontAndAnnualPaymentsToggle.Disabled__c == true;
                if(!stampUpfrontAndAnnualPaymentsDisabled) stampUpfrontAndAnnualPayments(updatedQuote,sourceQuoteData.get(updatedQuote.Id).SBQQ__LineItems__r);
                //GTMS-16392
                if(updatedQuote.Associated_Opportunity_Probability__c < 99 && updatedQuote.Free_Trial__c == NULL){
                    updatedQuote.VertexCPQ__Tax_Status__c = null;
                    if(updatedQuote.Shipping_Address_NEW__c == null){
                        updatedQuote.Tax_Calculation_Status__c = 'Validation';
                        updatedQuote.VertexCPQ__Tax_Status__c = Label.Vertex_Missing_Shipping_Address_error;
                        //updatedQuote.VertexCPQ__Tax_Amount__c = null;
                    }
                    else{
                         Map<Id, Decimal> qlHWQuoteMap = new Map<Id, Decimal>();
                         Decimal shippingNewValue = 0;
                        if(sourceQuoteData <> null && sourceQuoteData.get(updatedQuote.Id) <> null){
                            boolean isQLTotalNull = false;
                            for (SBQQ__QuoteLine__c ql : sourceQuoteData.get(updatedQuote.Id).SBQQ__LineItems__r) {
                                // This validation is for NULL only, not 0.
                                if (ql.SBQQ__NetTotal__c == null) {
                                    updatedQuote.Tax_Calculation_Status__c = 'Validation';
                                    updatedQuote.VertexCPQ__Tax_Status__c = Label.Vertex_Null_Line_Net_Total_error;
                                    isQLTotalNull = true;
                                    break;
                                }
                                
                                  if ((System.isFuture() || System.isQueueable() || Test.isRunningTest()) && at11ProductsList.contains(ql.SBQQ__ProductCode__c)) {
                                    Decimal countHW = 0;
                                    countHW = (ql.SBQQ__Quantity__c / 10) * 9;
                                    if (!qlHWQuoteMap.containsKey(ql.SBQQ__Quote__c)) {
                                        qlHWQuoteMap.put(ql.SBQQ__Quote__c, countHW);
                                    } else {
                                        qlHWQuoteMap.put(ql.SBQQ__Quote__c, qlHWQuoteMap.get(ql.SBQQ__Quote__c) + countHW);
                                    }
                                }
                            }
                            if (System.isFuture() || System.isQueueable()) {
                                // GTMS-28236 Rodrigo - changed method call
                                updatedQuote.Shipping_and_Handling_Value__c = ShippingHandlingCalculations.calculateShippingFieldForQuote(sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r, sourceQuoteData.get(updatedQuote.Id).SBQQ__LineItems__r, updatedQuote, sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Segment__c, null != qlHWQuoteMap && !qlHWQuoteMap.isEmpty() && qlHWQuoteMap.containsKey(updatedQuote.Id) ? qlHWQuoteMap.get(updatedQuote.Id) : 0);
                                //updatedQuote.Shipping_and_Handling_Value__c = ShippingHandlingCalculations.calculateShippingFieldForQuote(updatedQuote, sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r.Segment__c, null != qlHWQuoteMap && !qlHWQuoteMap.isEmpty() && qlHWQuoteMap.containsKey(updatedQuote.Id) ? qlHWQuoteMap.get(updatedQuote.Id) : 0);
                            }
                            if(isQLTotalNull == false && updatedQuote.VertexCPQ__Tax_Status__c == Label.Vertex_Null_Line_Net_Total_error){
                                updatedQuote.VertexCPQ__Tax_Status__c = NULL;
                                updatedQuote.Tax_Calculation_Status__c = NULL;
                            }
                        }
                    }
                    //GTMS-23000
                    if((string.isBlank(updatedQuote.VertexCPQ__Tax_Status__c) &&  (!System.isBatch() || reCalculateJobTaxCalc) && !System.isFuture() && !System.isQueueable() && updatedQuote.Tax_Calculation_Status__c <> 'Aborted') || OppStartDateUpdatedFromContract){
                        updatedQuote.Tax_Calculation_Status__c = 'Refresh';
                    }
                    //Added this method to identify and update Renewal_Data_Error_Category__c picklist field and also this method is used by jobRecalculateQuote Batch class if it is true
                    if(System.Label.quoteValidationCheck.equalsIgnoreCase('true')){
                        Boolean needRecalculationOfQuote = getRenewalDataErrorCategoryType(updatedQuote);
                    }
                }
              //  this.manageDealHealthData(updatedQuote, oldMap.get(updatedQuote.Id)); //When the Quote is Recalled, reset the Deal Health Data on Quote
            }
            //FinancePartnerQuoteTriggerHelper.updateQuoteFinancePartner(newList); // GTMS-16223
            updateQuoteFields(oldMap, newMap, newList, opportunityMap);            
  
            // validateSelectecPaymentTypeMatrix(oldMap, newMap, newList); // GTMS-20064
            //GTMS-16392
            //(new GS_SBQQQuoteVertexTaxService()).run(newMap, oldMap, sourceQuoteData);
            /* if(newMap.size() <= 100 && !System.isBatch() && !System.isFuture() && !System.isQueueable()){
            PopulateTaxes.populateVertexTaxes(newMap.keySet());
            }*/
            validateFreeTrialQuoteLines(newList);
            //ShippingHandlingCalculations.updateShippingAndHandlingForQuote(newList, opportunityMap);
            new GS_SBQQQuoteWorkflowService(oldMap, newMap, newList).performWorkflowActions();
            //GTMS-7343
            //UpdateCPQQuote(oldMap,newMap);
            setDocusignDisclaimer(newMap,oldMap);
            populateQuoteTrackerField(newMap,oldMap);
        }
        
        private void defaultPaymentTermsToUpFront(SBQQ__Quote__c quote, Integer licenseTerm, String approvedPaymentType){
            if((quote.Selected_Payment_Type__c != 'Upfront Payments') && ((licenseTerm <= 12 && approvedPaymentType == 'Direct Annual') ||
                (licenseTerm <= 6 && approvedPaymentType == 'Direct Semi-Annual') || (licenseTerm <= 3 && approvedPaymentType == 'Direct Quarterly')))
            {
                quote.Selected_Payment_Type__c = 'Upfront Payments';
            }
        }
        public void stampUpfrontAndAnnualPayments(SBQQ__Quote__c updatedQuote, List<SBQQ__QuoteLine__c> quoteLines){
            Decimal upfrontPayment = 0;
            Decimal annualPayment = 0;   
            for(SBQQ__QuoteLine__c quoteLine : quoteLines){
                if(quoteLine.Total_Annual_Price__c != null && quoteLine.Conga_Line_Item_Type__c == true){
                    annualPayment += quoteLine.Total_Annual_Price__c;
                }
                if(updatedQuote.Configuration_Segment__c != null && updatedQuote.Configuration_Segment__c == 'Non Express' && quoteLine.SBQQ__NetTotal__c != null &&  quoteLine.Product_Type__c != null && quoteLine.Product_Type__c != 'License' && quoteLine.Product_Type__c != 'Deal Component'){
                    upfrontPayment += quoteLine.SBQQ__NetTotal__c;
                }
            }
            if(updatedQuote.Estimated_Annual_Payment__c != annualPayment) updatedQuote.Estimated_Annual_Payment__c = annualPayment;
            if(updatedQuote.Estimated_Upfront_Amount__c != upfrontPayment) updatedQuote.Estimated_Upfront_Amount__c = upfrontPayment;
        }
        
       /* public void manageDealHealthData(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote){
            
            if(newQuote.ApprovalStatus__c == 'Recalled' && oldQuote.ApprovalStatus__c != 'Recalled' && newQuote.Deal_Health__c != null){
                newQuote.Deal_Health__c = null;
                newQuote.recommended_Discount__c = null;
            }
        } */
        
        private void populateQuoteTrackerField(Map<Id, SBQQ__Quote__c> newMap, Map<Id, SBQQ__Quote__c> oldMap){
            
            for(SBQQ__Quote__c quote :newMap.values()){
                
                //If no Express Agreement Accepted Date, skip
                if(quote.Express_Agreement_Accepted_Date__c == null) continue;
                
                for(Schema.FieldSetMember fm : Schema.SObjectType.SBQQ__Quote__c.fieldSets.getMap()?.get('Quote_Field_Track')?.getFields()){
                    
                    if(oldMap.get(quote.Id).get(fm.getFieldPath()) == quote.get(fm.getFieldPath())) continue;
                    
                    if(String.isNotBlank(quote.Quote_Tracking__c)){
                        
                        if(quote.Quote_Tracking__c.split(';').contains('Warning: '+fm.getlabel()))
                            continue;
                    }
                    
                    quote.Quote_Tracking__c = String.isBlank(quote.Quote_Tracking__c)?'Warning: '+fm.getlabel():quote.Quote_Tracking__c+(';Warning: '+fm.getlabel());
                }
            }
        }
        //Venkatesh Vallepu --start--GTMS-24149--
        // Method to validate the free trial for Tier and legacy product condition
        public void validateFreeTrialQuoteLines(List<SBQQ__Quote__c> newList) {
            Set<Id> accountIdsToCheck = new Set<Id>();
            Map<Id, SBQQ__Quote__c> FTQuoteMap = new Map<Id, SBQQ__Quote__c>();
            for (SBQQ__Quote__c newquote : newList) {
                if (newquote.SBQQ__Account__c != null && newquote.Associated_Opportunity_Type__c == 'Free Trial Opportunity') {
                    accountIdsToCheck.add(newquote.SBQQ__Account__c);
                    FTQuoteMap.put(newquote.Id, newquote);
                    System.debug('Adding Account ID to check: ' + newquote.SBQQ__Account__c);
                }
            }
            Map<Id, Boolean> accountHasCoreLicense = new Map<Id, Boolean>();
            if (!accountIdsToCheck.isEmpty()) {
                List<SBQQ__QuoteLine__c> existingQuoteLines = [SELECT SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.SBQQ__Opportunity2__r.Trial_End_Date__c
                                                               FROM SBQQ__QuoteLine__c
                                                               WHERE License_Type__c = 'Core'
                                                               AND SBQQ__Quote__r.Associated_Opportunity_Type__c = 'Free Trial Opportunity'
                                                               AND SBQQ__Quote__r.Associated_Opportunity_Probability__c = 100
                                                               AND SBQQ__Quote__r.SBQQ__Opportunity2__r.Trial_End_Date__c > TODAY
                                                               AND SBQQ__Quote__r.SBQQ__Account__c IN :accountIdsToCheck];
                System.debug('existingQuoteLines: ' + existingQuoteLines);
                if (!existingQuoteLines.isEmpty()) {
                    for (SBQQ__QuoteLine__c quoteLine : existingQuoteLines) {
                        if (quoteLine.SBQQ__Quote__r.SBQQ__Account__c != null) { accountHasCoreLicense.put(quoteLine.SBQQ__Quote__r.SBQQ__Account__c, true);
                            System.debug('accountHasCoreLicense: ' + accountHasCoreLicense);
                        }
                    }
                }
                
                String errorMessage = System.Label.FTLicenseTypeErrorMessage;
                List<SBQQ__QuoteLine__c> newQuoteLines = [SELECT SBQQ__Quote__c, License_Type__c FROM SBQQ__QuoteLine__c 
                                                          WHERE SBQQ__Quote__c IN :FTQuoteMap.keySet()
                                                          AND License_Type__c = 'Tier'];
                System.debug('newQuoteLines: ' + newQuoteLines);
                if (!newQuoteLines.isEmpty()) {
                    for (SBQQ__QuoteLine__c quoteLine : newQuoteLines) {
                        SBQQ__Quote__c quote = FTQuoteMap.get(quoteLine.SBQQ__Quote__c);
                        if (quote != null && quote.SBQQ__Account__c != null && quote.Associated_Opportunity_Type__c == 'Free Trial Opportunity' && quote.Associated_Opportunity_Probability__c <= 95) {
                            if (accountHasCoreLicense.containsKey(quote.SBQQ__Account__c)) { quote.addError(errorMessage);
                                System.debug('errorMessage: ' + errorMessage);
                            }
                        }
                    }
                }
            }
        }
        //Venkatesh Vallepu --end--GTMS-24149-
        public void handleAfterUpdateOperations(){
              thisLogger.logDebug('handleAfterUpdateOperations New Quote List ::', newList);
              thisLogger.logDebug('handleAfterUpdateOperations Old Quote Map ::', oldMap.values());
              system.debug('RODRIGO handleAfterUpdateOperations createFPQQuoteMarkedPrimary ');
              FinancePartnerQuoteTriggerHelper.createFPQQuoteMarkedPrimary(newMap, oldMap); // GTMS-16226
              //new GS_QuoteEventService().createQuoteSavePE(newList);
              Set<Id> relatedOpportunityIds = new Set<Id>();
              Map<Id, Opportunity> opportunityData;
              List<Opportunity> updatedOpportunities = new List<Opportunity>();
              Set<Id> addressFilteredQuotes = new Set<Id>();
              Map<Id, SBQQ__QuoteLine__c> relatedQuoteLines;
              Set<Id> processQuoteEventIds = new Set<Id>();
              List<Shipping_Calculation_Event__e> events = new List<Shipping_Calculation_Event__e>();
              Set<Id> qidset = new Set<Id>();
              //GTMS--9848 added boolean for check.
              List<SobjectField> dirtyFields = new List<SObjectField>();
              Boolean isAddressUpdateInitiated = false;
              Boolean isQLShipAddressUpdated = false;
              Map<string,Account> accToUpdate = new Map<string,Account>();
              Set<Id> quotesIdsToRecalculate=new Set<Id>();
              // GTMS-27380 -- Abu 06/25/2025 --> Start
              Set<Id> contractCoTermRenewalSet = new Set<Id>();
              // GTMS-27380 -- Abu 06/25/2025 --> End
              Set<Id> billingProrationQuoteIdSet = new Set<Id>();
              sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesAndQuoteLinesById(newMap.keySet());
              OrderFinanceSetting__mdt billing360Enabled = OrderFinanceSetting__mdt.getInstance('B360_R1_Toggle');
              for (Id quoteId : newMap.keySet()) {
                  SBQQ__Quote__c editedQuote = newMap.get(quoteId);
                  SBQQ__Quote__c oldQuoteData = oldMap.get(quoteId);
                bypassQuoteToOptySync = editedQuote.BypassQuoteToOptySynDate__c != oldQuoteData.BypassQuoteToOptySynDate__c 
                                        ? true : bypassQuoteToOptySync;
                  //Logic to retrigger CPQ calculation when Remorse Refund is processed via Mulesoft
                  if(editedQuote.Mulesoft_Status__c != oldQuoteData.Mulesoft_Status__c && editedQuote.Mulesoft_Status__c == 'Completed'){
                      processQuoteEventIds.add(editedQuote.Id);
                  }
                  relatedOpportunityIds.add(editedQuote.SBQQ__Opportunity2__c);
                  //GTMS-16392
                  if ((oldQuoteData.Shipping_Address_NEW__c != editedQuote.Shipping_Address_NEW__c) ||
                      (oldQuoteData.Ship_From_Location__c  != editedQuote.Ship_From_Location__c)){
                          addressFilteredQuotes.add(editedQuote.Id);
                      }
                  if(editedQuote.SBQQ__Uncalculated__c==false && editedQuote.Tax_Calculation_Status__c!='Updated'){
                      quotesIdsToRecalculate.add(quoteId);
                  }
                  //GTMS-27380 -- Abu 06/25/2025 --> Start
                  if(billing360Enabled.Value__c.equalsIgnoreCase('True') && newMap.get(quoteId).SBQQ__Type__c == 'Renewal' &&  newMap.get(quoteId).Co_Term_Contract__c != NULL && oldMap.get(quoteId).Co_Term_Contract__c != newMap.get(quoteId).Co_Term_Contract__c){
                      contractCoTermRenewalSet.add(newMap.get(quoteId).Co_Term_Contract__c);
                  }
                  //GTMS-27380 -- Abu 06/25/2025 --> End
                  //GTMS-28870
                  if (editedQuote.API_Status__c == 'Start' && System.isFuture() && isTaxCalculationCompleted) {
                      billingProrationQuoteIdSet.add(editedQuote.Id);
                  }              
              }
              //GTMS-27380 -- Abu 06/25/2025 --> End
              //GTMS-28870
              if (!billingProrationQuoteIdSet.isEmpty()) {                
                  //sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesAndQuoteLinesById(billingProrationQuoteIdSet);
                  BillingProrationAmountController.handleStartDateChange(sourceQuoteData, billingProrationQuoteIdSet);
              }
              //Added by Navees !System.isQueueable()
              if(newMap.size() <= 100 && !System.isBatch() && !System.isFuture() && quotesIdsToRecalculate.size()>0 && TaxCalculationScheduled==false){
                  // PopulateTaxes.populateVertexTaxes(newMap.keySet());
                  System.debug('handleAfterUpdateOperations Navees Execute Future======');
                  PopulateTaxes.populateVertexTaxes(quotesIdsToRecalculate);
                  TaxCalculationScheduled=true;
                  GS_SBQQQuoteServiceAsync.asyncContext = 'CopyQuoteFieldsToOppty';
              }
              if (newMap.keyset().size() > 0) {
                  List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();              
                  for (SBQQ__Quote__c quote : sourceQuoteData.values()) {
                    if (quote.SBQQ__LineItems__r != null) {
                        quoteLineList.addAll(quote.SBQQ__LineItems__r);
                    }
                  }
                  //Map<Id, SBQQ__QuoteLine__c> quoteLineList = new GS_SBQQQuoteLineSelector(true).checkFatalError().getQuoteLinessByQuoteId(newMap.keyset());
                  dirtyFields = new List<SObjectField>();
                  // Code to stamp the changed Ship TO on line items.
                  List<SBQQ__QuoteLine__c> updatedQuoteLines = new List<SBQQ__QuoteLine__c>();
                  if (quoteLineList != null) {
                      for (SBQQ__QuoteLine__c quoteLine : quoteLineList) {
                          Boolean changeFlag = false;
                          if (quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.Type == 'Revenue Opportunity') {
                              //GTMS-27380 -- Abu 06/25/2025 --> Start
                              if(!contractCoTermRenewalSet.isEmpty() && contractCoTermRenewalSet.contains(quoteLine.SBQQ__Quote__r.Co_Term_Contract__c) 
                                 && quoteLine.Product_Type__c == 'License' && quoteLine.SBQQ__Quote__r.Co_Term_Contract__r.Billing_Contract_Line_Id__c != null){                     
                                  changeFlag = true;
                                  quoteLine.Billing_Contract_Line_Id__c = quoteLine.SBQQ__Quote__r.Co_Term_Contract__r.Billing_Contract_Line_Id__c;
                              } else if(contractCoTermRenewalSet.isEmpty() && newMap.get(quoteLine.SBQQ__Quote__c).Co_Term_Contract__c == NULL 
                                        && newMap.get(quoteLine.SBQQ__Quote__c).SBQQ__Type__c == 'Renewal' && quoteLine.Billing_Contract_Line_Id__c != NULL){
                                  changeFlag = true;
                                  quoteLine.Billing_Contract_Line_Id__c = '';
                              }
                          }
                          //GTMS-27380 -- Abu 06/25/2025 --> End
                          if(addressFilteredQuotes.size() > 0 && isQLShipAddressUpdated == false){
                              SBQQ__Quote__c newQuoteData = newMap.get(quoteLine.SBQQ__Quote__c);
                              if (newQuoteData.MultipleShippingLocations__c != 'Yes'
                                  && quoteLine.Ship_To__c != newQuoteData.Shipping_Address_NEW__c
                                  && newQuoteData.Override__c == False){
                                      //GMS-7353 override check for ship-to in QuoteLines
                                      quoteLine.Ship_To__c = newQuoteData.Shipping_Address_NEW__c;
                                      changeFlag = true;
                                      dirtyFields.add(SBQQ__QuoteLine__c.Ship_To__c);
                                  }
                              if(quoteLine.Ship_From_Location__c  != newQuoteData.Ship_From_Location__c && String.isBlank(quoteLine.Original_FT_Oppty_Line_Item_SF_Id__c)){
                                  quoteLine.Ship_From_Location__c = newQuoteData.Ship_From_Location__c ;
                                  changeFlag = true;
                                  dirtyFields.add(SBQQ__QuoteLine__c.Ship_From_Location__c);
                                  //GTMS--9848 added boolean for check.
                                  //isAddressUpdateInitiated = true; //GTMS-16392
                              }
                          }
                          if(changeFlag == true) {
                              updatedQuoteLines.add(quoteLine);
                              //isQLShipAddressUpdated = true;
                              //SBQQ.TriggerControl.disable();
                              //DMLWrapper.doUpdate(quoteLine, dirtyFields);
                              //SBQQ.TriggerControl.enable();
                          }
                      }
                  }

                  if(!updatedQuoteLines.isEmpty()) {
                      SBQQ.TriggerControl.disable();
                        /*  replaced direct DML with FFLIB DML
                            ( prepare the records and commmit to DB at the end ) 
                            - HG - GTMS-32141 - 30th Oct, 2025 - START 
                        */
                        DMLWrapper.doUpdate( updatedQuoteLines );
                        // END
                      SBQQ.TriggerControl.enable();
                  }
              }
            Map<Id, SObject> unprocessedRecords = GS_TriggerRecursionManager.getNonRecursiveRecords(
                'SBQQ__Quote__c', 'after_update', newMap
            );
            if (unprocessedRecords.size() == 0) {
                thisLogger.logDebug('handleBeforeUpdateOperations All Quotes are already executed, so exiting the trigger.');
                return;
            }
            /*
            if(!qidset.isEmpty()){
            PopulateTaxes.populateVertexTaxes(qidset);
            }
            */
            //Logic to retrigger CPQ calculation when Remorse Refund is processed via Mulesoft
            if(processQuoteEventIds.size() > 0){
                GS_QuoteEventService.publishQuoteEvent(processQuoteEventIds);
            }
            List<Quote_To_Opportunity_Mapping__mdt> quoteToOpptyFieldMapping = new GS_QuoteToOpportunityMappingSelector(true).checkFatalError().getFieldMapping();
            opportunityData = new GS_OpportunitySelector(true).checkFatalError().getQuoteToOppotyFieldMappingData(relatedOpportunityIds, quoteToOpptyFieldMapping);
            Map<String, Quote_To_Opportunity_Mapping__mdt> fieldMappings = new Map<String, Quote_To_Opportunity_Mapping__mdt>();
            for (Quote_To_Opportunity_Mapping__mdt mapping : quoteToOpptyFieldMapping) {
                fieldMappings.put(mapping.Quote_Field__c, mapping);
            }
            //Map<String, Schema.SobjectField> opptyFieldSchema = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap();
            Set<Id> primaryQuoteIdsForFields = new Set<Id>();
            Map<String, String> quoteEligibleActions = new Map<String, String>();

            for (Id quoteId : newMap.keySet()) {
                SBQQ__Quote__c updatedQuote = newMap.get(quoteId);
                SBQQ__Quote__c oldQuoteData = oldMap.get(quoteId);
                Boolean changeFlag = false;
                if (updatedQuote.SBQQ__Primary__c == true) {
                    Opportunity relatedOpportunity = opportunityData.get(updatedQuote.SBQQ__Opportunity2__c);
                    if(relatedOpportunity!=null)
                    {
                        Boolean isChanged = false;
                        for(String quoteField : fieldMappings.keySet()) {
                            Quote_To_Opportunity_Mapping__mdt mappingMetadata = fieldMappings.get(quoteField);
                            String oppField = mappingMetadata.Opportunity_Field__c;
                            Boolean noBypass = mappingMetadata.Bypass__c? false: true;
                            Boolean hasChanged = relatedOpportunity.get(oppField) != updatedQuote.get(quoteField)? true: false;
                            Boolean nullCheck = mappingMetadata.Null_Check__c == true && hasChanged? updatedQuote.get(quoteField) != null: hasChanged;
                            Boolean typeCheck = mappingMetadata.Type__c != null && isChanged? mappingMetadata.Type__c == updatedQuote.Configuration_Segment__c||relatedOpportunity.Is_Webstore_Upsell_Opportunity__c : nullCheck;
                            Boolean ownerCheck = mappingMetadata.Owner_Segment__c != null && hasChanged? mappingMetadata.Owner_Segment__c.contains(relatedOpportunity.Account.Segment__c) : nullCheck;
                            if(hasChanged && nullCheck && typeCheck && noBypass && ownerCheck) {
                                isChanged = true;
                            }
                        }
                        /*GTMS-3734 : End*/
                        if ((oldQuoteData.Blended_Discount__c != updatedQuote.Blended_Discount__c) ||
                            (oldQuoteData.Approved_Discount__c  != updatedQuote.Approved_Discount__c) ||
                            (oldQuoteData.SBQQ__Primary__c != updatedQuote.SBQQ__Primary__c)
                           ) {
                               quoteEligibleActions.put(quoteId, 'DA');
                               isChanged = true;
                           }
                        // ProductApprovalNeeded__c is set by Price Rules
                        if ((oldQuoteData.ProductApprovalNeeded__c  != updatedQuote.ProductApprovalNeeded__c) ||
                            (oldQuoteData.SBQQ__Primary__c != updatedQuote.SBQQ__Primary__c)
                           ) {
                               String existingActions = (quoteEligibleActions.containsKey(quoteId) ? quoteEligibleActions.get(quoteId)+',' : '');
                               quoteEligibleActions.put(quoteId, existingActions + 'PA');
                               isChanged = true;
                           }
                        if ((oldQuoteData.Approved_Discount__c != updatedQuote.Approved_Discount__c) ||
                            (relatedOpportunity.Approved_Discount__c != updatedQuote.Approved_Discount__c) ||
                            (oldQuoteData.SBQQ__Primary__c != updatedQuote.SBQQ__Primary__c)
                           ) {
                               String existingActions = (quoteEligibleActions.containsKey(quoteId) ? quoteEligibleActions.get(quoteId)+',' : '');
                               quoteEligibleActions.put(quoteId, existingActions + 'AD');
                               isChanged = true;
                           }


                        /*  Added as part of GTMS-29825, we copied these conditions from GS_SBQQQuoteServiceAsync 
                            to keep the triggering and syncing logic same. 
                            The quote to opp sync was not working when License Term/ Custom License Term was getting 
                            updated on quote. In the quote to opp mapping metadata, License_Term__c field is marked 
                            as bypass and Custom_License_Term__c field is not at all present. So we are adding these 
                            explicit checks in order for the sync process to happen - HG - Sep 11th, 2025 - OPEN
                        */
                        if(
                            (   
                                updatedQuote.License_Term__c != null
                                &&  
                                (
                                    relatedOpportunity.License_Term_CPQ__c  != Decimal.valueOf( updatedQuote.License_Term__c )
                                    || relatedOpportunity.License_Term__c   != Decimal.valueOf( updatedQuote.License_Term__c )
                                )
                            ) ||
                            (
                                updatedQuote.Custom_License_Term__c != null
                                &&
                                (
                                    relatedOpportunity.License_Term_CPQ__c != updatedQuote.Custom_License_Term__c
                                    || relatedOpportunity.License_Term__c != updatedQuote.Custom_License_Term__c
                                )
                            ) ||
                            (
                                (   updatedQuote.Upsell_Amount__c != oldQuoteData.Upsell_Amount__c 
                                    && updatedQuote.Upsell_Amount__c != null
                                ) || 
                                (    updatedQuote.SBQQ__RenewalTerm__c != oldQuoteData.SBQQ__RenewalTerm__c 
                                    && updatedQuote.SBQQ__RenewalTerm__c != null
                                ) ||  
                                (   updatedQuote.Renewal_Amount__c != oldQuoteData.Renewal_Amount__c 
                                    && updatedQuote.Renewal_Amount__c != null
                                )
                            )
                        ) {
                            isChanged = true;
                        }
                        // CLOSE
                        
                        if (isChanged) {
                            primaryQuoteIdsForFields.add(quoteId);
                        }
                    }
                }
                if ((oldQuoteData.Shipping_Address_NEW__c != updatedQuote.Shipping_Address_NEW__c) ||
                    (oldQuoteData.Ship_From_Location__c  != updatedQuote.Ship_From_Location__c)
                   ) {
                       addressFilteredQuotes.add(updatedQuote.Id);
                   }
            }
            System.debug('****primaryQuoteIdsForFields> '+primaryQuoteIdsForFields+' :: '+GS_SBQQQuoteServiceAsync.asyncContext);
            if (primaryQuoteIdsForFields.size() > 0 &&
                GS_SBQQQuoteServiceAsync.asyncContext != 'CopyQuoteFieldsToOppty' &&    // To avoid recursion
                GS_SBQQQuoteServiceAsync.asyncContext != 'QuoteSavePE'  && // In Quote Save it already copies required change to Oppty, so need for this
                !bypassQuoteToOptySync // To avoid recursion
               ) {
                   System.debug('*** Coming Inside.');
                   DMLWrapper.doInsert(new GS_SBQQQuoteServiceAsync().prepareAsyncRequests(
                       JSON.serialize(new GS_SBQQQuoteServiceAsync.Options('CopyQuoteFieldsToOppty', quoteEligibleActions)),
                       primaryQuoteIdsForFields
                   ));
               }
                /*if (newMap.keyset().size() > 0 && addressFilteredQuotes.size() > 0) {
                System.debug('*** Coming Inside UpdatedQuoteLines');
                DMLWrapper.doInsert(new GS_SBQQQuoteServiceAsync().prepareAsyncRequests(
                JSON.serialize(new GS_SBQQQuoteServiceAsync.Options('updatedQuoteLines')),
                addressFilteredQuotes
                ));
                }*/
                            /*if (newMap.keyset().size() > 0 && addressFilteredQuotes.size() > 0) {
                Map<Id, SBQQ__QuoteLine__c> quoteLineList = new GS_SBQQQuoteLineSelector(true).checkFatalError().getQuoteLinessByQuoteId(newMap.keyset());
                dirtyFields = new List<SObjectField>();
                // Code to stamp the changed Ship TO on line items.
                List<SBQQ__QuoteLine__c> updatedQuoteLines = new List<SBQQ__QuoteLine__c>();
                if (quoteLineList != null) {
                for (SBQQ__QuoteLine__c quoteLine : quoteLineList.values()) {
                SBQQ__Quote__c newQuoteData = newMap.get(quoteLine.SBQQ__Quote__c);
                Boolean changeFlag = false;
                if (newQuoteData.MultipleShippingLocations__c != 'Yes'
                && quoteLine.Ship_To__c != newQuoteData.Shipping_Address_NEW__c
                && newQuoteData.Override__c == False){
                //GMS-7353 override check for ship-to in QuoteLines
                quoteLine.Ship_To__c = newQuoteData.Shipping_Address_NEW__c;
                changeFlag = true;
                dirtyFields.add(SBQQ__QuoteLine__c.Ship_To__c);
                }
                if(quoteLine.Ship_From_Location__c  != newQuoteData.Ship_From_Location__c &&
                String.isBlank(quoteLine.Original_FT_Oppty_Line_Item_SF_Id__c)){
                quoteLine.Ship_From_Location__c = newQuoteData.Ship_From_Location__c ;
                changeFlag = true;
                dirtyFields.add(SBQQ__QuoteLine__c.Ship_From_Location__c);
                //GTMS--9848 added boolean for check.
                //isAddressUpdateInitiated = true; //GTMS-16392
                }
                if(changeFlag == true) {
                //updatedQuoteLines.add(quoteLine);
                DMLWrapper.doUpdate(quoteLine, dirtyFields);
                }
                }
                }
                }*/
                            /* //GTMS-16392
                //added below condition for GTMS-9848
                system.debug('isAddressUpdateInitiated---'+isAddressUpdateInitiated);
                if(!isAddressUpdateInitiated) {
                updateShipToAddressOnQuoteLineItem(oldMap, newMap);
                }*/ 
                B360LogicHandler.handleBillingProrationResponse(oldMap, newList); //GTMS-27138
        }
            /* GTMS-16392
            //added below condition for GTMS-9848
            public void updateShipToAddressOnQuoteLineItem(Map<Id,SBQQ__Quote__c> oldQuoteMap, Map<Id,SBQQ__Quote__c> newQuoteMap) {
            Set<Id> relatedQuoteId = new Set<Id>();
            List<SBQQ__QuoteLine__c> updateQLI = new List<SBQQ__QuoteLine__c>();
            for(Id objQ : newQuoteMap.keyset()) {
            system.debug('newQuoteMap.get(objQ).Shipping_Address_NEW__c---'+newQuoteMap.get(objQ).Shipping_Address_NEW__c);
            system.debug('oldQuoteMap.get(objQ).Shipping_Address_NEW__c---'+oldQuoteMap.get(objQ).Shipping_Address_NEW__c);
            if(newQuoteMap.get(objQ).Shipping_Address_NEW__c != oldQuoteMap.get(objQ).Shipping_Address_NEW__c) {
            relatedQuoteId.add(objQ);
            }
            }
            if(!relatedQuoteId.isEmpty()) {
            List<SBQQ__QuoteLine__c> qLI = [
            SELECT Id, SBQQ__Quote__c, Ship_To__c, Ship_From_Location__c, Total_Subsidy__c, Total_Subsidy_Calc__c,
            SBQQ__ProductCode__c,Subsidy_Method__c,Subsidy_Amount__c, One_Time__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :relatedQuoteId
            ];
            if(!qLI.isEmpty()) {
            for(SBQQ__QuoteLine__c objQLI: qLI) {
            SBQQ__Quote__c newQuoteRec = newQuoteMap.get(objQLI.SBQQ__Quote__c);
            system.debug('objQLI.Ship_To__c---'+objQLI.Ship_To__c);
            system.debug('newQuoteRec.Shipping_Address_NEW__c---'+newQuoteRec.Shipping_Address_NEW__c);
            if(objQLI.Ship_To__c != newQuoteRec.Shipping_Address_NEW__c) {
            objQLI.Ship_To__c = newQuoteRec.Shipping_Address_NEW__c;
            updateQLI.add(objQLI);
            }
            }
            system.debug('updateQLI----'+updateQLI);
            if(!updateQLI.isEmpty()) {
            TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
            update updateQLI;
            }
            }
            }
            }
            /* GTMS-16392
            ////GTMS-7343
            /*public void updateCPQQuote(Map<Id, SBQQ__Quote__c> oldMap, Map<Id, SBQQ__Quote__c> newMap){
            for (SBQQ__Quote__c record : newMap.values()){
            //Quote - On Update/After Save flow
            if(record.Co_Term_Contract__c != NULL && oldmap.get(record.Id).Co_Term_Contract__c != record.Co_Term_Contract__c){
            record.Change_License_End_Date__c = true;
            //record.SBQQ__EndDate__c = record.Co_Term_Contract__r.EndDate;
            record.SBQQ__EndDate__c = contractData.get(record.Co_Term_Contract__c).EndDate;
            }
            }
            }*/
        // GTMS-8632 - Disclaimer logic - Flavio
        private void setDocusignDisclaimer(Map<Id, SBQQ__Quote__c> newMap, Map<Id, SBQQ__Quote__c> oldMap){
            Map<Id, List<SBQQ__Quote__c>> oppIdToQuoteMap = new Map<Id, List<SBQQ__Quote__c>>();
            Set<Id> oppIdSet = new Set<Id>();//added for (GTMS-16289)
            List<dsfs__DocuSign_Status__c> docSignUpdtList = new List<dsfs__DocuSign_Status__c>();//added for (GTMS-16289)
            Map<Id,String> docSignVoidReason = new Map<Id,String>();//added for GTMS-19973
            for (Id quoteId : newMap.keySet()){
                SBQQ__Quote__c newQuote = newMap.get(quoteId);
                SBQQ__Quote__c oldQuote = oldMap.get(quoteId);
                Opportunity opp = sourceQuoteData.get(quoteId).SBQQ__Opportunity2__r;
                Boolean notMxCountry = newQuote != null ? newQuote.SBQQ__BillingCountry__c != 'Mexico' : false;
                Boolean notMXRole = opp != null ? opp.Owner_Role_Copy__c != null ? !(opp.Owner_Role_Copy__c.contains('MX')) : true : false;                          
                Boolean notMxnFpOpp = opp != null ? (!opp.First_Purchase__c) ? true : (notMxCountry && notMXRole) : false; 
                List<SBQQ__QuoteLine__c> qliList = sourceQuoteData.get(quoteId).SBQQ__LineItems__r;//GTMS-16283
                if (opp <> NULL && !newQuote.Is_Promo__c && notMxnFpOpp && this.hasAnyDisclaimerFieldChanged(newQuote, oldQuote) &&  this.setDocusignDisclaimerCondition(opp,qliList) && opp.StageName == PURCHASE_STAGE){ //GTMS-13785
                    if (oppIdToQuoteMap.containsKey(opp.Id)){ oppIdToQuoteMap.get(opp.Id).add(newQuote);
                    }else{
                        oppIdToQuoteMap.put(opp.Id, new List<SBQQ__Quote__c>{newQuote});
                    }
                }
                //10/26/23 Vijaychandra --START-- (GTMS-16289) :  adding logic to list oppIds to void the completed docusign if a specific field value changes
                //12/1/23 Vijaychandra : Added stagename check in below if condition after the discussion with agamani on 12/1/23
                if(opp <> NULL && !newQuote.Is_Promo__c && notMxnFpOpp && this.hasAnyVoidFieldChanged(newQuote, oldQuote) &&  this.setDocusignDisclaimerCondition(opp,qliList) && opp.StageName == PURCHASE_STAGE){
                    string reason = mapVoidReason(newQuote,oldQuote);//added for GTMS-19973
                    docSignVoidReason.put(opp.Id,reason);//added for GTMS-19973
                    oppIdSet.add(opp.Id);
                }
                //--END- (GTMS-16289)
            }
            System.debug('QUOTE DOCUSIGN DISCLAIMER: Records to query: '+JSON.serializePretty(oppIdToQuoteMap));
            if (!oppIdToQuoteMap.isEmpty() || !oppIdSet.isEmpty()){
                for (dsfs__DocuSign_Status__c status : [
                    SELECT Id, dsfs__Opportunity__c,dsfs__Envelope_Status__c,Docusign_Voided_Reason__c
                    FROM dsfs__DocuSign_Status__c
                    WHERE (dsfs__Opportunity__c IN :oppIdToQuoteMap.keySet() OR dsfs__Opportunity__c IN :oppIdSet)
                    AND dsfs__Opportunity__c != NULL AND  dsfs__Envelope_Status__c = 'Completed'
                    AND Envelope_Type__c != 'Rebate Document'
                ]){
                    if(oppIdToQuoteMap.get(status.dsfs__Opportunity__c)!= null){
                        for (SBQQ__Quote__c newQuote : oppIdToQuoteMap.get(status.dsfs__Opportunity__c)){
                            System.debug('QUOTE DOCUSIGN DISCLAIMER: Setting true for '+newQuote.Id);
                            newQuote.Show_Docusign_Disclaimer__c = true;
                        }
                    }
                    //10/26/23 Vijaychandra --START-- (GTMS-16289) :  adding logic to list oppIds to void the completed docusign if a specific field value changes
                    if(oppIdSet.contains(status.dsfs__Opportunity__c)){
                        //4/2/24 Vijaychandra --START-- (GTMS-19973): added docusign void reason logic
                        dsfs__DocuSign_Status__c docRec = new dsfs__DocuSign_Status__c();
                        docRec.Id = status.id;
                        docRec.dsfs__Envelope_Status__c='Voided';
                        string oldreason = status.Docusign_Voided_Reason__c;
                        string reason = docSignVoidReason.get(status.dsfs__Opportunity__c);
                        docRec.Docusign_Voided_Reason__c = reason != null ? oldReason != null ? oldReason+reason : reason : oldReason;
                        //4/2/24 --END-- (GTMS-19973)
                        docSignUpdtList.add(docRec);
                    }
                }
                if(!docSignUpdtList.isEmpty()){update docSignUpdtList;}//updating docusign status record
                //--END-- (GTMS-16289)
            }
        }
        private Boolean hasAnyDisclaimerFieldChanged(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote){
            return (newQuote.Sales_Tax__c != oldQuote.Sales_Tax__c
                    || newQuote.Shipping_Address_NEW__c != oldQuote.Shipping_Address_NEW__c
                    || hasAnyVoidFieldChanged(newQuote, oldQuote));//GTMS-(16289)
            //|| newQuote.Tax_Calculation_Status__c == 'Refresh'Commented for GTMS-17662
            //|| newQuote.SBQQ__Status__c != 'Approved'); commented for GTMS-17855
        }
        //10/26/23 Vijaychandra --START-- (GTMS-16289): Created for code reusability, removed below conditions from hasAnyDisclaimerFieldChanged and added in below method
        /***********
        * Description : to check for field value changes to void the realted docusign
        * @Param: newQuote (Quote trigger.new variable)
        * @Param: oldQuote (Quote trigger.old variable)
        *************/
        private Boolean hasAnyVoidFieldChanged(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote){
            Opportunity opp = sourceQuoteData.get(newQuote.Id).SBQQ__Opportunity2__r;
            return((newQuote.Of_LIC_Products__c != oldQuote.Of_LIC_Products__c
                    || newQuote.of_HW_Products__c != oldQuote.of_HW_Products__c)
                   //10/19/23 Vijaychandra --START-- (GTMS-16286) Added more field changes in to the condition
                   //4/2/24 Vijaychandra --START-- (GTMS-19973) commented below 2 lines.
                   /*|| newQuote.Total_License_Due__c != oldQuote.Total_License_Due__c
                    || newQuote.Total_Hardware_Due__c != oldQuote.Total_Hardware_Due__c)*/
                   //4/2/24 --END-- (GTMS-19973)
                   && !opp.Is_Webstore_Upsell_Opportunity__c && !opp.Small_Fleet_Opportunity__c);//GTMS-17941
            //|| newQuote.Selected_Payment_Type__c != oldQuote.Selected_Payment_Type__c);Commented for GTMS-17662
            //--END-- (GTMS-16286)
        }
        //--END-- (GTMS-16289)
        //4/2/24 Vijaychandra --START-- (GTMS-19973): created to add docusign void reason logc
        /***********
        * Description : to add docusign void reason logc
        * @Param: newQuote (Quote trigger.new variable)
        * @Param: oldQuote (Quote trigger.old variable)
        *************/
        public string mapVoidReason(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote){
            string reason;
            string newLICCount = newQuote.Of_LIC_Products__c != null ? string.valueOf(newQuote.Of_LIC_Products__c):'null value';
            string oldLICCount = oldQuote.Of_LIC_Products__c != null ? string.valueOf(oldQuote.Of_LIC_Products__c):'null value';
            string newHWCount = newQuote.of_HW_Products__c != null ? string.valueOf(newQuote.of_HW_Products__c):'null value';
            string oldHWCount = oldQuote.of_HW_Products__c != null ? string.valueOf(oldQuote.of_HW_Products__c):'null value';
            string licCountReason = 'License Product count was updated by '+UserInfo.getName()+' New Count: '+newLICCount+' Old Count: '+oldLICCount+'; ';
            string hwCountReason = 'Hardware Product count was updated by '+UserInfo.getName()+' New Count: '+newHWCount+' Old Count: '+oldHWCount+'; ';
            reason = (newQuote.Of_LIC_Products__c != oldQuote.Of_LIC_Products__c) ? licCountReason : null;
            reason = (newQuote.Of_HW_Products__c != oldQuote.Of_HW_Products__c) ? reason != null ? reason+hwCountReason : hwCountReason : null;
            return reason;
        }
        //4/2/24 --END-- (GTMS-19973)
        private Boolean setDocusignDisclaimerCondition(Opportunity opp, List<SBQQ__QuoteLine__c> quoteLines){
            OrderValidationServiceAutomation ovaCheck = new OrderValidationServiceAutomation();
            //03/04/24 Vijaychandra (GTMS-19085): Added ova pilot rollout check
            return !((ovaCheck.outOfScopeCheck(opp) || ovaCheck.settingsOwnerExceptionCriteria(opp))|| insSubsidyQliCheck(quoteLines));
            //03/04/24 Vijaychandra (GTMS-19085) ENDING : Added ova pilot rollout check
            //Adding OVA Pilot check for voiding docusign
            //10/23/23 Vijaychandra (GTMS-16283): commented in OV phase 2 for code reuse.
            /*
            * (opp.Custom_Schedule__c == true
            || opp.Type != 'Revenue Opportunity'
            || (opp.Owner_Role_Copy__c != null && opp.Owner_Role_Copy__c.contains('SLED'))
            || (opp.Owner_Manager_Role_Copy__c != null && opp.Owner_Manager_Role_Copy__c.contains('SLED'))
            || !((opp.Finance_Segment__c == 'Enterprise' && opp.Is_Webstore_Upsell_Opportunity__c == TRUE)|| opp.Finance_Segment__c == 'Mid Market')
            || opp.Payment_Type__c == 'Reseller'
            || opp.Payment_Type__c == 'Finance Partner'
            || opp.SBQQ__Renewal__c == false
            || String.valueOf(opp.Name).Contains('INVENTORYSPLIT')
            || opp.Selected_Payment_Type__c == 'Direct Quarterly'
            || opp.Buyout_Opportunity__c != null
            || opp.Subsidy_Opportunity__c != null
            || ((opp.CurrencyIsoCode == 'GBP'||opp.CurrencyIsoCode == 'EUR') && opp.VAT_Validation_Status__c != 'Confirmed')
            */
        }
        //10/23/23 Vijaychandra --START-- (GTMS-16283): Created for Order Validation out of scope entry criteria check.
        /***********
        * Description : to iterate over quotelines to check for INS-Subsidy products
        * @Param: qteLines (list of all quote lines related to quote.)
        *************/
        private Boolean insSubsidyQliCheck(List<SBQQ__QuoteLine__c> qteLines){
            Boolean isSubsidy = False;
            for(SBQQ__QuoteLine__c qli:qteLines){
                if(qli.SBQQ__Product__r.ProductCode == SYSTEM.LABEL.Insurance_Subsidy_Product_Code){ isSubsidy = true; break;
                }
            }
            return isSubsidy;
        }
        //--END-- (GTMS-16283)
        /*public void beforeDeleteOperations(){
        thisLogger.logDebug('beforeDeleteOperations Old Quote List ::', oldList);
        }*/
    }
    public static Map<Id,Decimal> calculateTotalQuotelineSubsidy(Set<Id> subsidyFilteredQuotes){
        Map<Id,Decimal> mapQuoteIdAndTotalSubsidyAmount = new Map<Id,Decimal>();
        for(SBQQ__QuoteLine__c quoteline : [Select Id,Total_Subsidy__c,SBQQ__Quote__c,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where SBQQ__Quote__c IN : subsidyFilteredQuotes AND SBQQ__ProductCode__c ='INS-SUBSIDY']){
            if(mapQuoteIdAndTotalSubsidyAmount.containsKey(quoteline.SBQQ__Quote__c)){
                decimal tempNetSubsidy = mapQuoteIdAndTotalSubsidyAmount.get(quoteline.SBQQ__Quote__c) + quoteline.Total_Subsidy__c;
                mapQuoteIdAndTotalSubsidyAmount.put(quoteline.SBQQ__Quote__c,tempNetSubsidy);
            }else{
                mapQuoteIdAndTotalSubsidyAmount.put(quoteline.SBQQ__Quote__c,quoteline.Total_Subsidy__c);
            }
        }
        return  mapQuoteIdAndTotalSubsidyAmount;
    }
    // added for GTMS-15663
    public class previewDiscountApprovalResponse {
        @InvocableVariable public boolean needsApproval;
        @InvocableVariable public boolean AVPPlus;
    }
    // added for GTMS-15663
    @InvocableMethod(label='Preview Approval For Discount')
    public static List<previewDiscountApprovalResponse> previewApprovalForDiscount(List<Id> quoteIds){
        List<previewDiscountApprovalResponse> previewList = new List<previewDiscountApprovalResponse>();
        previewDiscountApprovalResponse previewRec = new previewDiscountApprovalResponse();
        previewRec.needsApproval = false;
        List<SBAA__Approval__c> approvals = SBAA.ApprovalAPI.preview(quoteIds[0], SBAA__Approval__c.Quote__c);
        // added for GTMS-19799 starts here
        Set<Id> ruleIdSet = new Set<Id>();
        FOR(SBAA__Approval__c approval : approvals) {
            ruleIdSet.add(approval.sbaa__Rule__c );
        }
        if(ruleIdSet.size()>0) {
            List<sbaa__ApprovalRule__c> approvalRules = [SELECT Id, Submit_for_Approval_Screen__c from sbaa__ApprovalRule__c WHERE Id IN: ruleIdSet];
            FOR (sbaa__ApprovalRule__c approvalRule : approvalRules) {
                if (approvalRule.Submit_for_Approval_Screen__c != null && approvalRule.Submit_for_Approval_Screen__c.containsIgnoreCase('Discount Approval')) {
                    previewRec.needsApproval = true;
                }
                if (approvalRule.Submit_for_Approval_Screen__c != null && approvalRule.Submit_for_Approval_Screen__c.containsIgnoreCase('AVP Plus Approval')) {
                    previewRec.AVPPlus = true;
                }
            }
        }
        // GTMS-19799 ends here
        //if (approvals.size()>0)
        //    previewRec.needsApproval = true;
        previewList.add(previewRec);
        return previewList;
    }

    public static void performStageValidation( SBQQ__Quote__c quote, 
                                                SBQQ__Quote__c oldQuote, 
                                                Opportunity sourceOpportunityRec, 
                                                boolean globalStageValidationDisabled, 
                                                list<Oppty_Stage_Validation_Exempt__c> ruleExemptRoles )
    {
        if( sourceOpportunityRec.Owner_Role_Copy__c == null && globalStageValidationDisabled ) { return; }

        if( sourceOpportunityRec.Owner_Role_Copy__c != null && hasValidationDisbaledForRole( sourceOpportunityRec.Owner_Role_Copy__c, globalStageValidationDisabled, ruleExemptRoles) ) { return; }

        if( quote.SBQQ__Primary__c
            && !oldQuote.SBQQ__Primary__c
            && sourceOpportunityRec.StageName == 'Incubate'
            && !sourceOpportunityRec.Is_Webstore_Upsell_Opportunity__c
            && ( !sourceOpportunityRec.SBQQ__Renewal__c && sourceOpportunityRec.SBQQ__RenewedContract__c == null )
            && (
                ( sourceOpportunityRec.CloseDate == null || sourceOpportunityRec.Related_Contact__c == null )
                ||  ( sourceOpportunityRec.SBQQ__AmendedContract__c == null
                    && ( sourceOpportunityRec.Need__c == null || sourceOpportunityRec.Budget_Confirmed__c == null )
                )
            )
        )
        {
            quote.addError( System.label.Revenue_Opportunity_Incubate_Validation_Quote );
        }
    }

    public static boolean hasValidationDisbaledForRole( string roleToCheck,
                                                        boolean globalStageValidationDisabled, 
                                                        list<Oppty_Stage_Validation_Exempt__c> ruleExemptRoles )
    {
        for(Oppty_Stage_Validation_Exempt__c ruleExemptRole : ruleExemptRoles)
        {

            if( !roleToCheck.contains( ruleExemptRole.Name ) ) { continue; }

            // XOR Logic: If globally disabled & at role level this is inverted (OR) If globally enabled and role leve not inverted - apply logic
            //  if not, perform the validation
            return ( globalStageValidationDisabled != ruleExemptRole.Invert_Stage_Validation__c );
        }

        return globalStageValidationDisabled;
    }

    // GTMS-20064 starts here
    /* public static void validateSelectecPaymentTypeMatrix(Map<Id, SBQQ__Quote__c> oldQuoteMap, Map<Id, SBQQ__Quote__c> newQuoteMap, List<SBQQ__Quote__c> quoteList)
    {
    Map<Id, SBQQ__Quote__c> cpqPaymentTypeChanged = new Map<Id, SBQQ__Quote__c>();
    FOR( SBQQ__Quote__c cpqReq : quoteList) {
    SBQQ__Quote__c oldCPQ = oldQuoteMap.get(cpqReq.id);
    if(cpqReq.Discount_Approval_Process__c!=null && cpqReq.ApprovalStatus__c == 'Recalled' && oldCPQ != null && cpqReq.Selected_Payment_Type__c != oldCPQ.Selected_Payment_Type__c) {
    cpqPaymentTypeChanged.put(cpqReq.Id, cpqReq);
    }
    }
    if (cpqPaymentTypeChanged.size()>0) {
    // get metadata details
    List<Selected_Payment_Type_Matrix__mdt> mcs = Selected_Payment_Type_Matrix__mdt.getAll().values();
    Map<String, String> mcsMap = new Map<String, String>();
    FOR(Selected_Payment_Type_Matrix__mdt mcsRec : mcs) {
    mcsMap.put(mcsRec.MasterLabel, mcsRec.No_ReApproval_Selected_Payment_Type__c);
    }
    // verify selected payment type against metadata
    FOR( SBQQ__Quote__c cpqReq : quoteList) {
    SBQQ__Quote__c oldCPQ = oldQuoteMap.get(cpqReq.id);
    string noApproval = mcsMap.get(oldCPQ.Selected_Payment_Type__c);
    DateTime myDateTime = DateTime.now();
    //system.debug('RODRIGO noApproval ' + noApproval);/
    //system.debug('RODRIGO cpqReq.Selected_Payment_Type__c ' + cpqReq.Selected_Payment_Type__c);
    //system.debug('RODRIGO noApproval ' + noApproval.containsIgnoreCase(cpqReq.Selected_Payment_Type__c));
    if(noApproval != null && noApproval.containsIgnoreCase(cpqReq.Selected_Payment_Type__c)) {
    //cpqReq.Smart_Approve_Fields_Indicator__c = myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year(); // GTMS-15659
    cpqReq.Skip_Approval_Process__c  = (cpqReq.Smart_Approve_Fields_Indicator__c != null) ? cpqReq.Smart_Approve_Fields_Indicator__c + 5 : myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year() ; // GTMS-20064
    }
    else {
    //cpqReq.Skip_Approval_Process__c=0;
    cpqReq.Smart_Approve_Fields_Indicator__c = (cpqReq.Smart_Approve_Fields_Indicator__c != null) ? cpqReq.Smart_Approve_Fields_Indicator__c + 5 : myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year() ; // GTMS-15659
    }
    //system.debug('RODRIGO cpqReq.Skip_Approval_Process__c ' + cpqReq.Skip_Approval_Process__c);
    } 
    }
    }*/
    // GTMS-20064 ends here
    //
  }