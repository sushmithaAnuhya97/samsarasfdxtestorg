/* 
 * Class Created: 07/03/19 - @author: Harsha
 * 07/11/20 Harsha - (GTMS-1307) quoteLineAfterUpdateOperations (Method deprecated)
 * 01/14/21 Harsha - (GTMS-2674) quoteLineBeforeUpdateOperations (Added a null check) 
 * 04/14/22 Flavio - (GTMS-6104) Gainsight Audit fields update. Included Subscriptions query and Gainsight Audit logic to Insert & Update methods.
 * 06/08/22 Rodrigo - (GTMS-7328) quoteLineBeforeUpdateOperations (Added logic that will calculate and update total subsidy)
 * 06/16/22 Alekya - (GTMS-7481) Add-Onchanges are stamped with the ticket number 
 * 08/04/22 Rodrigo - (GTMS-7949) modified condition in stampShipToAddress
 * 09/27/22 Rajesh  - (GTMS-9717) Added else check for Amendment Type
 * 10/31/22 Rajesh  - (GTMS-10103) Added Discount > 0 check before processing and removed the approval flag
 * 11/16/22 Rajesh  - (GTMS-10180) Added a threshold value for GainSight comparision of QuotePrice & SubscriptionPrice
 * March-6-2023 Rajesh GTMS-11201 Added method SetACV to populate ACV values
 * May-11-2023 Rajesh GTMS-12705 Populating SBQQ__AdditionalDiscountAmount__c
 * June-21-2023 Rajesh GTMS-13039 Added method setIsACV
 * Sep-2023 Zakeer GTMS-13035 - Direct Quarterly
 * Oct-2023 Rodrigo GTMS-15701 Implement margin of error for Customer 360 discount auto-approvals
 * Oct-2023 Rodrigo GTMS-15657 Conditional approvals based on the discount level of the add-on vs. first purchase
 * May-2024 Joshna GTMS-21125 Add a maximum discount to Digital Renewals Opportunities/Quotes
 * Apr-2025 Rushikesh GTMS-26503 Prevent adding, deleting and modifying products from Carryover and Upgrade Groups.
*/  
public class SBQQQuoteLineHelper {
    
    static Set<Id> shippingIds = new Set<Id>();
    static Map<Id, Shipping_Address__c> shippingData;
    
    static Set<Id> relatedQuoteIds = new Set<Id>(); 
    static Map<Id, SBQQ__Quote__c > quoteData;
  static Map<Id, Contract > amendedContractData; //GTMS-15657
    static Map<string, SBQQ__QuoteLine__c> amendedQuoteLineData = new Map<string, SBQQ__QuoteLine__c>(); //GTMS-15657
    Set<Id> listOfOpptyAmendedQuote = new Set<Id>(); // added for GTMS-15657
    // This boolean is not the user override
    public static Boolean GainsightProcessingOverride = false;
    List<SBQQ__QuoteLine__c> quoteLinesWithRenewalSubscription = new List<SBQQ__QuoteLine__c>();
    Set<Id> subscriptionIdSet = new Set<Id>();
    Map<Id, SBQQ__Subscription__c> subscriptionMap;
    Map<string, string> productCodeMap = new Map<string, string>(); // added for GTMS-7481;
    Map<Id, Customer_360__c> customer360Map = new Map<Id, Customer_360__c>(); // added for GTMS-7481;
    // Operation's on quoteline inserts. 
    public void quoteLineBeforeInsertOperations(Map<Id, SBQQ__QuoteLine__c> oldQuoteLineMap, List<SBQQ__QuoteLine__c> newQuoteLineList){
        Set<Id> relatedQuoteIDs = new Set<Id>();
        Set<Id> ftOpportunityLineIds = new Set<Id>();
        // list added for GTMS-7481
		Set<Id> listOfUpsellAccountId = new Set<Id>();
        //Set<Id> clonedFromQuoteLineIDs = new Set<Id>();
       // Map<Id,SBQQ__QuoteLine__c> mapClonedFromQuoteLines;      
       //GTMS-27378 GTMS-27380
        Map<Id, String> contractReplacementBillingLineIdMap = new Map<Id, String>();
        Map<Id, String>  amendmentBillingLineIdMap = new Map<Id, String>();
        //Map<Id, String> cotermRenewalBillingLineIdMap = new Map<Id, String>();
        Set<Id> contractReplacementSet = new Set<Id>();
        //Set <Id> contractCoTermRenewalSet = new Set<Id>(); 
        Set<Id> accountAmendmentSet     = new Set<Id>(); 

        for(SBQQ__QuoteLine__c quoteLine : newQuoteLineList){
            relatedQuoteIDs.add(quoteLine.SBQQ__Quote__c);
            
            if(quoteLine.Ship_To__c != null){
                shippingIds.add(quoteLine.Ship_To__c);
            }   
            
            if(String.isNotBlank(quoteline.Original_FT_Oppty_Line_Item_SF_Id__c)) {
                ftOpportunityLineIds.add(quoteline.Original_FT_Oppty_Line_Item_SF_Id__c);
            }
            
            //https://samsaradev.atlassian.net/browse/GTMS-10129           
            /* if(!quoteLine.SBQQ__Incomplete__c && quoteLine.isClone() && quoteLine.getCloneSourceId()!=null && (!UserInfo.getUserEmail().startsWith('corpweb-sfdc-robot@samsara.com') && !FeatureManagement.checkPermission('Validation_Rule_Exemption') && !UserInfo.getProfileId().startsWith('00e1a000000UoNc') && !UserInfo.getProfileId().startsWith('00e1P000000FBBD')) || Test.isRunningTest()){                            
                clonedFromQuoteLineIDs.add(quoteLine.getCloneSourceId());
            }  */ 
           if (quoteLine.LineItem_type__c == 'Upsell' && quoteLine.Account__c != null){// added for GTMS-7481
                listOfUpsellAccountId.add(quoteLine.Account__c);
            } 
            // ends here for GTMS-7481
        }
        
         // check if upsell list has value - // added for GTMS-7481
        if (!listOfUpsellAccountId.isEmpty()) {
            populateProductCodeMapAndGetC360Records(listOfUpsellAccountId);
        } // ends here for GTMS-7481 
        
        /*if(clonedFromQuoteLineIDs.size()>0){
            mapClonedFromQuoteLines=new Map<Id,SBQQ__QuoteLine__c>([Select Id From SBQQ__QuoteLine__c Where Id=:clonedFromQuoteLineIDs AND Is_Renewed_Line__c=true]);
        } */      
        
        if(ftOpportunityLineIds.size() > 0){
          stampShippingLocations(ftOpportunityLineIds, newQuoteLineList);
        }
        
        if(relatedQuoteIDs.size() > 0){
            getQuoteData(relatedQuoteIDs);
        }
        
        for(SBQQ__Quote__c relatedQuote : quoteData.values()){
            if(relatedQuote.Shipping_Address_NEW__c != null){
                shippingIds.add(relatedQuote.Shipping_Address_NEW__c);
            }

           //Logic to populate Billing Contract Line Id on Quote lines on Insert
            if(relatedQuote.SBQQ__Opportunity2__c != null && relatedQuote.SBQQ__Account__c != null && relatedQuote.SBQQ__Opportunity2__r.Type == 'Revenue Opportunity' && OrderFinanceSetting__mdt.getInstance('B360_R1_Toggle').Value__c.equalsIgnoreCase('True')){
                if (relatedQuote.SBQQ__Opportunity2__r.Sub_Type__c == 'Contract Replacement') { // GTMS-27380 (Added Renewal to the condition)
                    contractReplacementSet.add(relatedQuote.SBQQ__Opportunity2__c);    
                } else if (relatedQuote.SBQQ__Type__c == 'Amendment' && relatedQuote.SBQQ__MasterContract__r.Billing_Contract_Line_Id__c == null && relatedQuote.SBQQ__Account__r.B360_ContractEndDate__c != null && relatedQuote.SBQQ__Account__r.B360_Payment_Type__c != null) {   
                    accountAmendmentSet.add(relatedQuote.SBQQ__Account__c);   
                } 
            }          
        }
        //GTMS-27380 START - Populate the subscription billing id map
        if(!contractReplacementSet.isEmpty() || !accountAmendmentSet.isEmpty()) {
            B360LogicHandler.getSubscription(contractReplacementSet, accountAmendmentSet, contractReplacementBillingLineIdMap, amendmentBillingLineIdMap);           
        }
        //GTMS-27380 END - Populate the subscription billing id map

        //Get the shipping Data
        if((shippingIds.size() > 0) && (shippingData == null)){
            getShippingAddress(shippingIds);
        }
        for(SBQQ__QuoteLine__c newQuoteLine : newQuoteLineList){
            SBQQ__Quote__c associatedQuote = quoteData.get(newQuoteLine.SBQQ__Quote__c);
            if((associatedQuote != null)){
                if(newQuoteLine.Ship_To__c == null){
                   newQuoteLine.Ship_To__c = associatedQuote.Shipping_Address_NEW__c;
                }
                if(String.isBlank(newQuoteLine.Original_FT_Oppty_Line_Item_SF_Id__c)) {
                newQuoteLine.Ship_From_Location__c = associatedQuote.Ship_From_Location__c;
                }
                newQuoteLine.Created_From_Quote__c = true;
                newQuoteLine.Account__c = associatedQuote.SBQQ__Account__c;
                String licenseTerm = associatedQuote.License_Term__c == null ? '0' : associatedQuote.License_Term__c;
                Decimal netPrice = newQuoteLine.SBQQ__NetPrice__c == null ? 0 : newQuoteLine.SBQQ__NetPrice__c;

                /*newQuoteLine.ACV_Total_Price_Stamp__c = calculateACV(Integer.valueof(licenseTerm), newQuoteLine.SBQQ__TotalDiscountRate__c, 
                                                                   newQuoteLine.SBQQ__Quantity__c, netPrice);*/
                // populates concatenated ship to field
                stampShipToAddress(newQuoteLine);
                newQuoteLine.Product_Code_Copy__c = newQuoteLine.SBQQ__ProductCode__c;
            }
            if((newQuoteLine.Product_Type__c=='Hardware' || newQuoteLine.Product_Type__c=='Cable' || newQuoteLine.Product_Type__c=='Accessory') && newQuoteLine.SBQQ__ListPrice__c==0 )
            {// added for GTMS-28048
                newQuoteLine.Approval_Required__c= false;
            }
             
            // starts here for GTMS-7481
             /* else if((associatedQuote.SBQQ__Type__c == 'Amendment') || (associatedQuote.First_Purchase__c ==false && ((associatedQuote.Opportunity_Owner_Segment__c =='AE1' || associatedQuote.Opportunity_Owner_Segment__c =='AE2'
                                                               || associatedQuote.Opportunity_Owner_Segment__c =='AE3' || associatedQuote.Opportunity_Owner_Segment__c =='ENT'
                                                               || associatedQuote.Opportunity_Owner_Segment__c =='Enterprise')||(String.isNotBlank(associatedQuote.Opportunity_Owner_Role_Copy__c) && associatedQuote.Opportunity_Owner_Role_Copy__c.contains('ENT'))))
                )*/
             else if((associatedQuote.SBQQ__Type__c == 'Amendment') || (associatedQuote.First_Purchase__c ==false && ((String.isNotBlank(associatedQuote.Opportunity_Owner_Role_Copy__c)&&(associatedQuote.Opportunity_Owner_Role_Copy__c.contains('AE1')||associatedQuote.Opportunity_Owner_Role_Copy__c.contains('AE2')||
                                                                                                                          associatedQuote.Opportunity_Owner_Role_Copy__c.contains('AE3')))||(associatedQuote.Opportunity_Owner_Segment__c =='ENT'
                                                               || associatedQuote.Opportunity_Owner_Segment__c =='Enterprise')||(String.isNotBlank(associatedQuote.Opportunity_Owner_Role_Copy__c) && associatedQuote.Opportunity_Owner_Role_Copy__c.contains('ENT'))))
                )
            {
                    if (newQuoteLine.LineItem_type__c == 'Upsell'){
                      updateAprrovalRequired(newQuoteLine, newQuoteLine.SBQQ__ProductCode__c,associatedQuote.Opportunity_Owner_Role_Copy__c);
                      // Update MUP comparison flag for GTMS-29089 (same logic as C360 discount)
                      updateMUPComparisonFlag(newQuoteLine, newQuoteLine.SBQQ__ProductCode__c);
                      if(newQuoteLine.SBQQ__TotalDiscountRate__c > 0){
                      // added for GTMS-15657 starts here
                    Double rebateAmount = (associatedQuote.Subsidy_Amount__c != null) ? associatedQuote.Subsidy_Amount__c : 0;
                    double buyoutAmount = (associatedQuote.Buyout_Amount__c != null) ? associatedQuote.Buyout_Amount__c : 0;
                    rebateAmount = rebateAmount + buyoutAmount;
                    if (rebateAmount > 0)
                        newQuoteLine.Approval_Required__c = true;
                    // added for GTMS-15657 ends here
                      }
                }
                /*else if (updatedQuoteLine.LineItem_type__c == 'Amended Line' && updatedQuoteLine.Opportunity_Amended_Contract__c!=null) { // added for GTMS-15657 starts here
                  //if (updatedQuoteLine.Opportunity_Amended_Contract__c!=null) {
                    Contract localContact = new Contract();
                    localContact = amendedContractData.get(updatedQuoteLine.Opportunity_Amended_Contract__c);
                    if(localContact.SBQQ__Quote__r.Selected_Payment_Type__c != updatedQuoteLine.Quote_Selected_Payment_Type__c)
                        updatedQuoteLine.Approval_Required__c = true;
                    else
                        updatedQuoteLine.Approval_Required__c = false;
                    
                    if(!updatedQuoteLine.Approval_Required__c) {
                        SBQQ__QuoteLine__c localQuoteLine = amendedQuoteLineData.get(localContact.SBQQ__Quote__c+updatedQuoteLine.SBQQ__ProductCode__c+updatedQuoteLine.Ship_To__c);
                        if(localQuoteLine!= null && localQuoteLine.SBQQ__Discount__c<updatedQuoteLine.SBQQ__Discount__c)
                            updatedQuoteLine.Approval_Required__c = true;
                    }
                    //}
                }*/ // commented for GTMS-19958
                else if(string.isBlank(newQuoteLine.LineItem_type__c) &&  newQuoteLine.List_Unit_Price__c > 0 ){ //GTMS-10103
                     if(newQuoteLine.SBQQ__Discount__c > 0){ 
                        newQuoteLine.Approval_Required__c = true;
                     }
                     else{
                         newQuoteLine.Approval_Required__c = false;
                     }
                }
            }
            else{
                newQuoteLine.Approval_Required__c= true;
            }
            
            // ends here for GTMS-7481

            //GTMS-28254 START
            // Amendment - Contracts(Legacy)
            if (associatedQuote != null && associatedQuote.SBQQ__Account__c != NULL && associatedQuote.SBQQ__Type__c == 'Amendment' && newQuoteLine.Product_Type__c == 'License' && null != amendmentBillingLineIdMap &&
             !amendmentBillingLineIdMap.isEmpty() && amendmentBillingLineIdMap.containsKey(associatedQuote.SBQQ__Account__c)) {
                newQuoteLine.Billing_Contract_Line_Id__c = amendmentBillingLineIdMap.get(associatedQuote.SBQQ__Account__c);
            }
            // Amendment - Contracts(Addon)
            else if (associatedQuote != null && associatedQuote.SBQQ__MasterContract__c != NULL && associatedQuote.SBQQ__Type__c == 'Amendment' && newQuoteLine.Product_Type__c == 'License' && associatedQuote.SBQQ__MasterContract__r.Billing_Contract_Line_Id__c != null) {
                newQuoteLine.Billing_Contract_Line_Id__c =associatedQuote.SBQQ__MasterContract__r.Billing_Contract_Line_Id__c;
            }
            // C&R Upgrade - Contracts
            else if (associatedQuote != null && associatedQuote.SBQQ__Opportunity2__c != null && associatedQuote.SBQQ__Opportunity2__r.Sub_Type__c == 'Contract Replacement' && newQuoteLine.Product_Type__c == 'License' && 
             null != contractReplacementBillingLineIdMap && !contractReplacementBillingLineIdMap.isEmpty() && contractReplacementBillingLineIdMap.containsKey(associatedQuote.SBQQ__Opportunity2__c)) {
                newQuoteLine.Billing_Contract_Line_Id__c = contractReplacementBillingLineIdMap.get(associatedQuote.SBQQ__Opportunity2__c);
            }
            // Renewals
            else if (associatedQuote != null && associatedQuote.Co_Term_Contract__c != NULL && associatedQuote.SBQQ__Type__c == 'Renewal' && newQuoteLine.SBQQ__EffectiveQuantity__c > 0  && newQuoteLine.Product_Type__c == 'License' && associatedQuote.Co_Term_Contract__r.Billing_Contract_Line_Id__c != null) {
                newQuoteLine.Billing_Contract_Line_Id__c = associatedQuote.Co_Term_Contract__r.Billing_Contract_Line_Id__c;
            }
            //GTMS-28254 END

            setTaxData(newQuoteLine, associatedQuote);
			this.markQuoteLineForRenewalValidation(associatedQuote, newQuoteLine);
            //https://samsaradev.atlassian.net/browse/GTMS-10129
            /*if(!newQuoteLine.SBQQ__Incomplete__c && newQuoteLine.isClone() && newQuoteLine.getCloneSourceId()!=null && mapClonedFromQuoteLines!=null && mapClonedFromQuoteLines.containsKey(newQuoteLine.getCloneSourceId())){ 
                newQuoteLine.addError('You cant clone this line because it is a renewal line.');               
            }*/
        }

        this.validateClickPathSubscriptions();
        Logger.insertMasterLogs();
    }
    
    // Method to perform opertaions before updating the line items
    public void quoteLineBeforeUpdateOperations(Map<Id, SBQQ__QuoteLine__c> oldQuoteLineMap, Map<Id, SBQQ__QuoteLine__c> newQuoteLineMap, List<SBQQ__QuoteLine__c> updatedQuoteLineList){
        Map<Id, String> subscriptionBillingIdMap = new Map<Id, String>(); // GTMS-27380
        Map<Id, Id> contractToQuoteMap = new Map<Id, Id>(); // GTMS-27380

        // list added for GTMS-7481
        Set<Id> listOfUpsellAccountId = new Set<Id>();
        Set<Id> listOfOpptyAmendedContract = new Set<Id>(); // added for GTMS-15657
        
        Apex_Validation_Setting__mdt setting = Apex_Validation_Setting__mdt.getInstance('FTQuoteLineRestriction');
        Id currentUserProfileId = UserInfo.getProfileId();
        String profileName = null;
        FlexConstants__c flexConstant = FlexConstants__c.getInstance('FlexConstants'); //GTMS-26503
        //Retrieve profile name
        List<Profile> profiles = [SELECT Name FROM Profile WHERE Id =: currentUserProfileId];
        if(profiles != null && !profiles.isEmpty()) {
            profileName = profiles[0].Name;
        }
        
        for(SBQQ__QuoteLine__c quoteLine : updatedQuoteLineList){
            SBQQ__QuoteLine__c oldQuoteLineValue = oldQuoteLineMap.get(quoteLine.Id);
            if (flexConstant != null && !FlexCnRTriggerBypass__c.getInstance().Bypass_Sync_and_Flag_Reset_Logic__c &&
                !FeatureManagement.checkPermission(flexConstant.Flex_Access_QuoteLine__c) && 
                !System.isBatch() && 
                !System.isQueueable() && 
                !System.isScheduled() && 
                !System.isFuture()) {  
                // Check Carryover Products group added for GTMS-26503
                if (String.isNotBlank(quoteLine.Flex_Group_Name__c) && 
                    quoteLine.Flex_Group_Name__c == flexConstant.Carryover_Products__c && 
                    ( quoteLine.SBQQ__NetPrice__c != oldQuoteLineValue.SBQQ__NetPrice__c ||
                     quoteLine.SBQQ__ListPrice__c != oldQuoteLineValue.SBQQ__ListPrice__c ||
                     quoteLine.SBQQ__SpecialPrice__c != oldQuoteLineValue.SBQQ__SpecialPrice__c ||
                     quoteLine.SBQQ__CustomerPrice__c != oldQuoteLineValue.SBQQ__CustomerPrice__c ||
                     quoteLine.SBQQ__UnitCost__c != oldQuoteLineValue.SBQQ__UnitCost__c ||
                     quoteLine.SBQQ__RegularPrice__c != oldQuoteLineValue.SBQQ__RegularPrice__c||
                     quoteLine.SBQQ__ProductCode__c != oldQuoteLineValue.SBQQ__ProductCode__c||
                     quoteLine.SBQQ__Quantity__c != oldQuoteLineValue.SBQQ__Quantity__c)) 
                     { 
                        quoteLine.addError(flexConstant.Error_Message__c);
                }
                // Check Upgraded Products group added for GTMS-26503
                if (String.isNotBlank(quoteLine.Flex_Group_Name__c) && 
                    quoteLine.Flex_Group_Name__c == flexConstant.Upgraded_Products__c &&
                    (quoteLine.SBQQ__Quantity__c != oldQuoteLineValue.SBQQ__Quantity__c ||
                     quoteLine.SBQQ__ProductCode__c != oldQuoteLineValue.SBQQ__ProductCode__c)) 
                     {
                        quoteLine.addError(flexConstant.Error_Message__c);
                }    
            }

            if(flexConstant != null && !FlexCnRTriggerBypass__c.getInstance().Bypass_Sync_and_Flag_Reset_Logic__c &&
               !FeatureManagement.checkPermission(flexConstant.Flex_Access_QuoteLine__c) &&
               String.isNotBlank(quoteLine.Flex_Group_Name__c) &&
               (quoteLine.Flex_Group_Name__c == flexConstant.Upgraded_Products__c ||
                quoteLine.Flex_Group_Name__c == flexConstant.Carryover_Products__c))
                {
               if(quoteLine.Flex_Group_Name__c != oldQuoteLineValue.Flex_Group_Name__c) {       
                       System.debug('Error Message: ' + flexConstant.Error_Message__c);
                       quoteLine.addError(flexConstant.Error_Message__c);
               }
               }
            shippingIds.add(quoteLine.Ship_To__c);
            relatedQuoteIds.add(quoteLine.SBQQ__Quote__c);
            if (quoteLine.LineItem_type__c == 'Upsell' && quoteLine.Account__c != null){// added for GTMS-7481
                listOfUpsellAccountId.add(quoteLine.Account__c);
            } 
            // ends here for GTMS-7481

            if (quoteLine.Opportunity_Amended_Contract__c != null && quoteLine.LineItem_type__c == 'Amended Line'){ // added for GTMS-15657
                listOfOpptyAmendedContract.add(quoteLine.Opportunity_Amended_Contract__c);
            } // added for GTMS-15657
            
            SBQQ__QuoteLine__c oldQuoteLine = oldQuoteLineMap.get(quoteLine.Id);  
            if(setting != null && String.isNotBlank(profileName) && !setting.Excluded_Profiles__c.contains(profileName)) {
                if(String.isNotBlank(quoteLine.Original_FT_Oppty_Line_Item_SF_Id__c) && (quoteLine.SBQQ__Quantity__c != oldQuoteLine.SBQQ__Quantity__c 
                   || quoteLine.SBQQ__Product__c != oldQuoteLine.SBQQ__Product__c)) {
                   quoteLine.addError(setting.Error_Message__c);   
                }  
            }
            
            /*GTMS-27220*STARTS*/
            if(quoteLine.SBQQ__StartDate__c != null && Boolean.valueOf(System.Label.Nullify_SubscriptionEndDate)){
                quoteLine.SBQQ__StartDate__c = null;
            } 
            if(quoteLine.SBQQ__EndDate__c != null && Boolean.valueOf(System.Label.Nullify_SubscriptionEndDate)){
             	quoteLine.SBQQ__EndDate__c = null;
            }
            /*GTMS-27220*ENDS*/
        }
        
        if(listOfOpptyAmendedContract.size()>0) { // added for GTMS-15657
            getAmendedContractData(listOfOpptyAmendedContract);
            getAmendedQuoteLineData(listOfOpptyAmendedQuote);
        } // added for GTMS-15657
        
        if((relatedQuoteIds.size() > 0)/*  && (quoteData == null) */){
            getQuoteData(relatedQuoteIds);
        }
        
        
        
         // check if upsell list has value - // added for GTMS-7481
        if (!listOfUpsellAccountId.isEmpty()) {
            populateProductCodeMapAndGetC360Records(listOfUpsellAccountId);
        } // ends here for GTMS-7481
        
        //Get the shipping Data
        if(((shippingIds.size() > 0) && (shippingData == null)) || (shippingIds.size() != shippingData.size())){
            getShippingAddress(shippingIds);
        }
        
        for(SBQQ__QuoteLine__c updatedQuoteLine : updatedQuoteLineList){
            SBQQ__QuoteLine__c oldQuoteLineData = oldQuoteLineMap.get(updatedQuoteLine.Id);
            SBQQ__Quote__c relatedQuoteData = quoteData.get(updatedQuoteLine.SBQQ__Quote__c);    
            if(Label.Execute_Code_Check == 'True' || Test.isRunningTest()){
                //relatedQuoteData.SBQQ__SubscriptionTerm__c
                //SBQQ__ListTotal__c
                //updatedQuoteLine.SBQQ__CustomerPrice__c >  updatedQuoteLine.SBQQ__ListPrice__c
                Decimal term = relatedQuoteData.CalculatedSubscriptionTerm__c==null ? relatedQuoteData.SBQQ__SubscriptionTerm__c : relatedQuoteData.CalculatedSubscriptionTerm__c;
                if(term == null){
                    term = 1;
                }
                Decimal listPrice = ((updatedQuoteLine.SBQQ__ListPrice__c==null?0:updatedQuoteLine.SBQQ__ListPrice__c)/12) * term;
                if(updatedQuoteLine.Is_Renewed_Line__c && relatedQuoteData.SBQQ__Type__c =='Renewal' && relatedQuoteData.SBQQ__Opportunity2__c!=null && 
                relatedQuoteData.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c!=null 
                && (relatedQuoteData.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Auto_Renewal__c == True 
                || relatedQuoteData.SBQQ__Opportunity2__r.Sub_Type__c == 'Auto-Renewal' || relatedQuoteData.SBQQ__Opportunity2__r.Sub_Type__c == 'Clickpath' 
                || relatedQuoteData.Process_Eligibility__c=='Digital Renewals')
                && relatedQuoteData.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c >= 0 
                && updatedQuoteLine.SBQQ__CustomerPrice__c >  listPrice ){
                    updatedQuoteLine.SBQQ__Discount__c = null;
                    updatedQuoteLine.SBQQ__AdditionalDiscountAmount__c = null;
                    updatedQuoteLine.SBQQ__CustomerPrice__c =  listPrice;
                    updatedQuoteLine.SBQQ__NetPrice__c=  listPrice;
                }
            }

            //GTMS-27380 START
            if(relatedQuoteData!= NULL && relatedQuoteData.SBQQ__Type__c == 'Renewal' && relatedQuoteData.Co_Term_Contract__c == NULL && updatedQuoteLine.Billing_Contract_Line_Id__c != NULL){
               updatedQuoteLine.Billing_Contract_Line_Id__c = ''; 
            }
            // GTMS-27380 END
            
            //Start of GTMS-12705
            if(updatedQuoteLine.Is_Renewed_Line__c && relatedQuoteData.SBQQ__Type__c =='Renewal' 
               && relatedQuoteData.SBQQ__Opportunity2__c!=null  
               && relatedQuoteData.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c!=null
               ){
                    if((oldQuoteLineData.SBQQ__AdditionalDiscountAmount__c == NULL || oldQuoteLineData.SBQQ__AdditionalDiscountAmount__c == 0)
                    && updatedQuoteLine.SBQQ__AdditionalDiscountAmount__c > 0){
                        updatedQuoteLine.AdditionalDiscAmntPM__c = updatedQuoteLine.SBQQ__AdditionalDiscountAmount__c / updatedQuoteLine.SBQQ__EffectiveSubscriptionTerm__c;
                    }
                    if(updatedQuoteLine.SBQQ__Discount__c==null && updatedQuoteLine.AdditionalDiscAmntPM__c > 0 && updatedQuoteLine.SBQQ__RenewedSubscription__c <> null && !updatedQuoteLine.Webstore_Discount_Check__c){
                        if(relatedQuoteData.License_Term__c <> NULL){
                            updatedQuoteLine.SBQQ__AdditionalDiscountAmount__c = updatedQuoteLine.AdditionalDiscAmntPM__c * decimal.valueOf(relatedQuoteData.License_Term__c);
                        }
                        else if(relatedQuoteData.Custom_License_Term__c <> NULL){
                            updatedQuoteLine.SBQQ__AdditionalDiscountAmount__c = updatedQuoteLine.AdditionalDiscAmntPM__c * relatedQuoteData.Custom_License_Term__c;
                        }
                    }
            }   
            //End of GTMS-12705

            //if(oldQuoteLineData.Ship_To__c != updatedQuoteLine.Ship_To__c){
               // populates concatenated ship to field
               stampShipToAddress(updatedQuoteLine);
            //}
            if(relatedQuoteData.SBQQ__Account__c != null){
                updatedQuoteLine.Account__c = relatedQuoteData.SBQQ__Account__c;                 
            }
            String licenseTerm = relatedQuoteData.License_Term__c == null ? '0' : relatedQuoteData.License_Term__c;
            Decimal netPrice = updatedQuoteLine.SBQQ__NetPrice__c == null ? 0 : updatedQuoteLine.SBQQ__NetPrice__c;
            /*updatedQuoteLine.ACV_Total_Price_Stamp__c = calculateACV(Integer.valueof(licenseTerm), updatedQuoteLine.SBQQ__TotalDiscountRate__c, 
                                                                    updatedQuoteLine.SBQQ__Quantity__c, netPrice);*/
            
            if((updatedQuoteLine.Product_Type__c=='Hardware' || updatedQuoteLine.Product_Type__c=='Cable' || updatedQuoteLine.Product_Type__c=='Accessory') && updatedQuoteLine.SBQQ__ListPrice__c==0 )
            {// added for GTMS-28048
             updatedQuoteLine.Approval_Required__c= false;
            }
            
            // starts here for GTMS-7481
              /* else if ((relatedQuoteData.SBQQ__Type__c == 'Amendment') || (relatedQuoteData.First_Purchase__c ==false && ((relatedQuoteData.Opportunity_Owner_Segment__c =='AE1' || relatedQuoteData.Opportunity_Owner_Segment__c =='AE2'
                                                               || relatedQuoteData.Opportunity_Owner_Segment__c =='AE3' || relatedQuoteData.Opportunity_Owner_Segment__c =='ENT'
                                                               || relatedQuoteData.Opportunity_Owner_Segment__c =='Enterprise')||(String.isNotBlank(relatedQuoteData.Opportunity_Owner_Role_Copy__c)&&relatedQuoteData.Opportunity_Owner_Role_Copy__c.contains('ENT'))))
                )*/ else if ((relatedQuoteData.SBQQ__Type__c == 'Amendment') || (relatedQuoteData.First_Purchase__c ==false && ( (String.isNotBlank(relatedQuoteData.Opportunity_Owner_Role_Copy__c)&&(relatedQuoteData.Opportunity_Owner_Role_Copy__c.contains('AE1')||relatedQuoteData.Opportunity_Owner_Role_Copy__c.contains('AE2')||
                                                                                                                                                                                              relatedQuoteData.Opportunity_Owner_Role_Copy__c.contains('AE3')))||(relatedQuoteData.Opportunity_Owner_Segment__c =='ENT'
                                                               || relatedQuoteData.Opportunity_Owner_Segment__c =='Enterprise')||(String.isNotBlank(relatedQuoteData.Opportunity_Owner_Role_Copy__c)&&relatedQuoteData.Opportunity_Owner_Role_Copy__c.contains('ENT'))
                ))){
               if (updatedQuoteLine.LineItem_type__c == 'Upsell')
                   { //GTMS-10103
                    updateAprrovalRequired(updatedQuoteLine, updatedQuoteLine.SBQQ__ProductCode__c,relatedQuoteData.Opportunity_Owner_Role_Copy__c);
                    // Update MUP comparison flag for GTMS-29089 (same logic as C360 discount)
                    updateMUPComparisonFlag(updatedQuoteLine, updatedQuoteLine.SBQQ__ProductCode__c);
                   if (updatedQuoteLine.SBQQ__TotalDiscountRate__c > 0){
                   // added for GTMS-15657 starts here
                    Double rebateAmount = (relatedQuoteData.Subsidy_Amount__c != null) ? relatedQuoteData.Subsidy_Amount__c : 0;
                    double buyoutAmount = (relatedQuoteData.Buyout_Amount__c != null) ? relatedQuoteData.Buyout_Amount__c : 0;
                    rebateAmount = rebateAmount + buyoutAmount;
                    if (rebateAmount > 0)
                        updatedQuoteLine.Approval_Required__c = true;
                    // added for GTMS-15657 ends here
                   }
                }
                /*else if (updatedQuoteLine.LineItem_type__c == 'Amended Line' && updatedQuoteLine.Opportunity_Amended_Contract__c!=null) { // added for GTMS-15657 starts here
                  //if (updatedQuoteLine.Opportunity_Amended_Contract__c!=null) {
                    Contract localContact = new Contract();
                    localContact = amendedContractData.get(updatedQuoteLine.Opportunity_Amended_Contract__c);
                    if(localContact.SBQQ__Quote__r.Selected_Payment_Type__c != updatedQuoteLine.Quote_Selected_Payment_Type__c)
                        updatedQuoteLine.Approval_Required__c = true;
                    else
                        updatedQuoteLine.Approval_Required__c = false;
                    
                    if(!updatedQuoteLine.Approval_Required__c) {
                        SBQQ__QuoteLine__c localQuoteLine = amendedQuoteLineData.get(localContact.SBQQ__Quote__c+updatedQuoteLine.SBQQ__ProductCode__c+updatedQuoteLine.Ship_To__c);
                        if(localQuoteLine!= null && localQuoteLine.SBQQ__Discount__c<updatedQuoteLine.SBQQ__Discount__c)
                            updatedQuoteLine.Approval_Required__c = true;
                    }
                    //}
                }*/ // commented for GTMS-19958
                else if(string.isBlank(updatedQuoteLine.LineItem_type__c) &&  updatedQuoteLine.List_Unit_Price__c > 0 ){ //GTMS-10103
                     if(updatedQuoteLine.SBQQ__Discount__c > 0){ 
                        updatedQuoteLine.Approval_Required__c = true;
                     }
                     else{
                         updatedQuoteLine.Approval_Required__c = false;
                     }
                }
            }
            else{
                updatedQuoteLine.Approval_Required__c= true;
            }
             
            // ends here for GTMS-7481
            
            setTaxData(updatedQuoteLine, relatedQuoteData);  

            this.markQuoteLineForRenewalValidation(relatedQuoteData, updatedQuoteLine);
            
            // added section of code for GTMS-7328 - starts here
            if (updatedQuoteLine.SBQQ__ProductCode__c =='INS-SUBSIDY')
            {
                if (updatedQuoteLine.Subsidy_Method__c=='Fixed $') {
                    if (updatedQuoteLine.One_Time__c==true){ // added for GTMS-9561
                        updatedQuoteLine.Total_Subsidy__c = updatedQuoteLine.Total_Subsidy_Calc__c;
                    }
                    else {
                        if (relatedQuoteData.Selected_Payment_Type__c != null) {
                            if (relatedQuoteData.License_Term__c != null)
                                updatedQuoteLine.Total_Subsidy__c = updatedQuoteLine.Total_Subsidy_Calc__c * double.valueOf(relatedQuoteData.License_Term__c);
                            /*if (relatedQuoteData.Selected_Payment_Type__c == 'Direct Monthly')
                                updatedQuoteLine.Total_Subsidy__c = updatedQuoteLine.Total_Subsidy_Calc__c;
                            if (relatedQuoteData.Selected_Payment_Type__c == 'Direct Annual')
                                updatedQuoteLine.Total_Subsidy__c = updatedQuoteLine.Total_Subsidy_Calc__c * 12;
                            if (relatedQuoteData.Selected_Payment_Type__c == 'Upfront Payments' && relatedQuoteData.License_Term__c != null) {
                                if (Test.isRunningTest() || relatedQuoteData.License_Term__c == '12')
                                    updatedQuoteLine.Total_Subsidy__c = updatedQuoteLine.Total_Subsidy_Calc__c * 12;
                                if (Test.isRunningTest() || relatedQuoteData.License_Term__c == '36')
                                    updatedQuoteLine.Total_Subsidy__c = updatedQuoteLine.Total_Subsidy_Calc__c * 36;
                                if (Test.isRunningTest() || relatedQuoteData.License_Term__c == '60')
                                    updatedQuoteLine.Total_Subsidy__c = updatedQuoteLine.Total_Subsidy_Calc__c * 60;
                            }*/
                        }
                    }
                }
                if (updatedQuoteLine.Subsidy_Method__c=='Percentage') {
                    if (relatedQuoteData.Selected_Payment_Type__c != null) {
                        if (relatedQuoteData.Selected_Payment_Type__c == 'Direct Monthly')
                            updatedQuoteLine.Total_Subsidy__c = (updatedQuoteLine.Subsidy_Amount__c/100) * (-1) * relatedQuoteData.Monthly_License_with_Tax__c;
                        if (relatedQuoteData.Selected_Payment_Type__c == 'Direct Quarterly')
                            updatedQuoteLine.Total_Subsidy__c = (updatedQuoteLine.Subsidy_Amount__c/100) * (-1) * relatedQuoteData.Quarterly_License_with_Tax__c;
                        if (relatedQuoteData.Selected_Payment_Type__c == 'Direct Semi-Annual')
                            updatedQuoteLine.Total_Subsidy__c = (updatedQuoteLine.Subsidy_Amount__c/100) * (-1) * relatedQuoteData.Semi_Annual_License_with_Tax__c;
                        if (relatedQuoteData.Selected_Payment_Type__c == 'Direct Annual')
                            updatedQuoteLine.Total_Subsidy__c = (updatedQuoteLine.Subsidy_Amount__c/100) * (-1) * relatedQuoteData.Annual_License_with_Tax__c;
                        if (relatedQuoteData.Selected_Payment_Type__c == 'Upfront Payments') {
                            updatedQuoteLine.Total_Subsidy__c = (updatedQuoteLine.Subsidy_Amount__c/100) * (-1) * relatedQuoteData.Total_License_Due__c;
                        }
                    }
                } 
                
            }
            // added section of code for GTMS-7328 - ends here
        }

        this.validateClickPathSubscriptions();
        Logger.insertMasterLogs();
    }
/**
* Created By : Joshna Konudula
* @Date June 27, 2024
* @description : method handles the logic to populate the picklist Field : Renewal_Data_Error_Type__c
* Jira: GTMS-22224
**/
    
public void populateStatusPLForRenewalsValidation(List<SBQQ__QuoteLine__c> updatedQuoteLineList) {
    //List<Api_Logger__c> aplogList = new List<Api_Logger__c>();
    set<Id> subIds = new set<Id>();
    Map<Id, SBQQ__Subscription__c> subscriptionMap = new  Map<Id, SBQQ__Subscription__c>();
    for(SBQQ__QuoteLine__c eQL : updatedQuoteLineList){
        if(eQL.SBQQ__RenewedSubscription__c != null){
        subIds.add(eQL.SBQQ__RenewedSubscription__c);
            }
    }
    if(subIds.size()>0){
        subscriptionMap = new Map<Id, SBQQ__Subscription__c>(getSubscriptions(subIds));
    }
    try{
    for(SBQQ__QuoteLine__c qL:updatedQuoteLineList){
        SBQQ__Quote__c qD = quoteData.get(qL.SBQQ__Quote__c);
        if(!subscriptionMap.containsKey(qL.SBQQ__RenewedSubscription__c)){
            continue;
        }
        SBQQ__Subscription__c SubofQL = subscriptionMap.get(qL.SBQQ__RenewedSubscription__c);
                
        if(qD != null && qL.SBQQ__CustomerPrice__c!= null && qL.SBQQ__ListPrice__c != null && qL.SBQQ__ProrateMultiplier__c!= null && qL.SBQQ__RenewedSubscription__c != null && qD.SBQQ__Opportunity2__c != null && qD.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c != null 
           && (SubofQL.SBQQ__RenewalPrice__c != null || SubofQL.SBQQ__CustomerPrice__c != null) && 
             qD.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c != null && qD.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Deactivated__c == false){
               if(qL.SBQQ__Uplift__c == null){qL.SBQQ__Uplift__c = 1;}
                
                Decimal calProrateMultiplier=1;
                if(qL.SBQQ__EffectiveSubscriptionTerm__c != null && qL.SBQQ__DefaultSubscriptionTerm__c != null){
                    calProrateMultiplier = (qL.SBQQ__EffectiveSubscriptionTerm__c/qL.SBQQ__DefaultSubscriptionTerm__c).setScale(2);
                }
               Decimal RenewalWithupliftValue = (1+((qL.SBQQ__Uplift__c)/100))*(SubofQL.SBQQ__RenewalPrice__c!=null?SubofQL.SBQQ__RenewalPrice__c:(SubofQL.SBQQ__CustomerPrice__c!=null?SubofQL.SBQQ__CustomerPrice__c:0));
               Decimal diff1 = (qL.SBQQ__CustomerPrice__c - ( RenewalWithupliftValue*qL.SBQQ__ProrateMultiplier__c));
               Decimal diff2 = (qL.SBQQ__CustomerPrice__c - ( qL.SBQQ__ListPrice__c*qL.SBQQ__ProrateMultiplier__c));
               Decimal diff4 = (qL.SBQQ__CustomerPrice__c - ( RenewalWithupliftValue*calProrateMultiplier));
               Decimal diff5 = (qL.SBQQ__CustomerPrice__c - ( qL.SBQQ__ListPrice__c*calProrateMultiplier));
               if(((qD.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Auto_Renewal__c == true || qD.Process_Eligibility__c=='Digital Renewals') && qD.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c == null)){
                   qL.Renewal_Data_Error_Type__c ='UpliftIsNull';
               }else if((qD.SBQQ__RenewalUpliftRate__c!=null?qD.SBQQ__RenewalUpliftRate__c.setScale(2):(qD.SBQQ__RenewalUpliftRate__c)) != (qD.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c != null?qD.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c.setscale(2):(qD.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c))){
                   qL.Renewal_Data_Error_Type__c = 'UpliftNotMatch';
               } else if (qL.Ship_To__c == null) {
                   qL.Renewal_Data_Error_Type__c = 'Ship To On QuoteLine Is Null';
               } else if (qD.Shipping_Address_NEW__c == null) {
                   qL.Renewal_Data_Error_Type__c = 'Shipping Address On Quote Is Null'; 
               } else if (ql.SBQQ__Quantity__c <=0) {
                   qL.Renewal_Data_Error_Type__c = 'QuantityIsZeroOrNegative';
               } else if (ql.SBQQ__NetTotal__c < 0 || ql.SBQQ__NetTotal__c == null) {
                   qL.Renewal_Data_Error_Type__c = 'Amount is Null';
               } else if((qL.SBQQ__Discount__c!=null && qL.SBQQ__Discount__c == 40) || (qL.SBQQ__TotalDiscountRate__c != null && qL.SBQQ__TotalDiscountRate__c >=40)){
                    if ((qL.SBQQ__CustomerPrice__c == qL.SBQQ__ProratedListPrice__c*0.6) || (diff1 > -1 && diff1 < 1)){
                        qL.Renewal_Data_Error_Type__c = 'ValidationSuccessful';
                    }else{
                        qL.Renewal_Data_Error_Type__c = 'CustomerPriceDidntMatch';
                    }
                } else if(qL.SBQQ__ListPrice__c >= RenewalWithupliftValue){
                    if ((qL.SBQQ__CustomerPrice__c == RenewalWithupliftValue*qL.SBQQ__ProrateMultiplier__c) || (qL.SBQQ__CustomerPrice__c == RenewalWithupliftValue*calProrateMultiplier) || (diff1 > -1 && diff1 < 1) || (diff4 > -1 && diff4 < 1)){
                        qL.Renewal_Data_Error_Type__c = 'ValidationSuccessful';
                    }else{
                        qL.Renewal_Data_Error_Type__c = 'CustomerPriceDidntMatch';
                    }
                }else if(qL.SBQQ__ListPrice__c < RenewalWithupliftValue){
                    if ((qL.SBQQ__CustomerPrice__c == qL.SBQQ__ListPrice__c*qL.SBQQ__ProrateMultiplier__c)  || (qL.SBQQ__CustomerPrice__c == qL.SBQQ__ListPrice__c*calProrateMultiplier)|| (diff2 > -1 && diff2 < 1) || (diff5 > -1 && diff5 < 1)){
                        qL.Renewal_Data_Error_Type__c = 'ValidationSuccessful';
                    }else{
                        qL.Renewal_Data_Error_Type__c = 'CustomerPriceDidntMatch';
                    }
                }else{
                   qL.Renewal_Data_Error_Type__c = 'ValidationSuccessful';
                }
           } }
    
    if (Test.isRunningTest()) {
        //throw new DMLException('Test Coverage'); 
    }
    } catch(exception e){
        system.debug('Exception in populateStatusPLForRenewalsValidation'+e.getMessage());
    }
}
    
     /**
* Created By : Alekya Koleti
* @Date June 27, 2022
*
* @description : method handles the logic to update the Approval Required Field
*
* Modification History:
* Date          Author              Story/Defect            Description
* 2022-06-27    Alekya Koleti       GTMS-7481               this handles the logic to update Approval Required field 
* 2023-09-27.   Rodrigo Carpio.     GTMS-15701.             added condition to check 0.5% margin of error
**/
  private void updateAprrovalRequired(SBQQ__QuoteLine__c updatedQuoteLine, String productCode,String OpptyOwnerRoleCopy) {
        String c360MupAPI = productCodeMap.get(productCode+'-MUP');
		String  c360DiscountAPI=productCodeMap.get(productCode);
        Decimal quoteLineDiscount = updatedQuoteLine.SBQQ__TotalDiscountRate__c;
         Decimal c360Discount = 0;
        Decimal c360Mup = 0;
        Customer_360__c c360object = customer360Map.get(updatedQuoteLine.Account__c);
        if (c360object != null) {
            if (Test.isRunningTest() || String.isNotBlank(c360MupAPI)){
                try {
                    Map<String, Object> populatedFields = c360object.getPopulatedFieldsAsMap();
                    if (populatedFields != null && populatedFields.containsKey(c360MupAPI)) {
                        Object rawValue = populatedFields.get(c360MupAPI);
                        c360Mup = rawValue == null ? null : (Decimal)rawValue;
						updatedQuoteLine.C360_MUP__c = c360Mup;
                    } else {
                       updatedQuoteLine.C360_MUP__c = null;
                    }
					if (populatedFields != null && populatedFields.containsKey(c360DiscountAPI)) {
                        Object rawValue = populatedFields.get(c360DiscountAPI);
                        c360Discount = rawValue == null ? null : (Decimal)rawValue;
						updatedQuoteLine.C360_Discount__c = c360Discount;
                    } else {
					c360Discount=null;
                       updatedQuoteLine.C360_Discount__c = null;
                    }
                } catch (Exception ex) {
                    Logger.atError()
                        .setClassName('SBQQQuoteLineHelper')
                        .setMethod('updateAprrovalRequired')
                        .setLineNumber(610)
                        .setExceptionOrMessage(ex)
                        .setExceptionOrMessage('Failed reading C360 discount field ' + c360DiscountAPI +
                            ' for productCode ' + productCode +
                            ' on Account ' + String.valueOf(updatedQuoteLine.Account__c));
                    
                }
                
            }
        }
        if(String.isNotBlank(OpptyOwnerRoleCopy) && (OpptyOwnerRoleCopy.contains('ENT')||
             OpptyOwnerRoleCopy.contains('AE1')||OpptyOwnerRoleCopy.contains('AE2')||OpptyOwnerRoleCopy.contains('AE3')))
        {
          updateApprovalRequiredMUP(updatedQuoteLine,productCode);  
        }
        else{
            if(quoteLineDiscount>0){
                
				
        // check for the value of the c360DiscountAPI
        // added logic to 0.5 margin of error to c360Discount value and the OR condition as per GTMS-15701
        if ((c360object != null && c360Discount != null && quoteLineDiscount > (c360Discount + 0.5)) || c360object == null || c360Discount == null )        {
           updatedQuoteLine.Approval_Required__c = true;
        } else {
            updatedQuoteLine.Approval_Required__c = false;
        }
        }
        }
    }
    
    // Method to perform opertaions after updating the line items
    //public void quoteLineAfterUpdateOperations(Map<Id, SBQQ__QuoteLine__c> oldQuoteLineMap, Map<Id, SBQQ__QuoteLine__c> newQuoteLineMap, List<SBQQ__QuoteLine__c> updatedQuoteLineList){
        // this will have the logic to update the ship to address of bundle and it related products
        //performBundleShipToAddressUpdate(oldQuoteLineMap, newQuoteLineMap, updatedQuoteLineList);
    //}


    /**
     * Audit ClickPath field price and quantity validation. It compares the QuoteLine's quantity and price to it's subscription counterparts.
     */
    private void validateClickPathSubscriptions(){
        if (this.quoteLinesWithRenewalSubscription == null || this.quoteLinesWithRenewalSubscription.isEmpty()) return;
        getQuoteLineRenewalSubscriptions();

        for (SBQQ__QuoteLine__c quoteLine : quoteLinesWithRenewalSubscription){
            String status = '';

            if (quoteLine.SBQQ__RenewedSubscription__c == null){
                if (this.isWithinSeconds(300, quoteData.get(quoteLine.SBQQ__Quote__c), quoteLine)){
                    status = Label.Clickpath_Missing_renewed_subscription;
                }else{
                    status = Label.Success;
                }
            }else{
                // Currently, it is not expected to have more than one subscription for a quote line
                SBQQ__Subscription__c subscription = subscriptionMap.get(quoteLine.SBQQ__RenewedSubscription__c);

                String customerPriceStatus = this.matchesCustomerPrice(quoteLine, subscription);
                if (String.isNotBlank(customerPriceStatus)) status += (String.isBlank(status) ? '' : ' ')+customerPriceStatus+';';
    
                String quantityStatus = this.matchesQuantity(quoteLine, subscription);
                if (String.isNotBlank(quantityStatus)) status += (String.isBlank(status) ? '' : ' ')+quantityStatus+';';
    
                if (String.isBlank(customerPriceStatus) && String.isBlank(quantityStatus))
                    status = Label.Success;
            }
            
            quoteLine.Gainsight_Audit_Status__c = status;
        }
    }

    public void webStoreRenewalsMaximumDiscount(List<SBQQ__QuoteLine__c> newQuoteLineList){
        set<Id> relatedQteIds = new Set<Id>();
        Map<Id, SBQQ__QuoteLine__c> qLMap = new Map<Id, SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c quoteLine : newQuoteLineList){
            if(quoteData == null || quoteData.size() == 0 || !quoteData.containsKey(quoteLine.SBQQ__Quote__c)){
              relatedQteIds.add(quoteLine.SBQQ__Quote__c);
            }
            if(quoteLine.SBQQ__TotalDiscountRate__c != null && quoteLine.SBQQ__TotalDiscountRate__c > 40){
                qLMap.put(quoteLine.Id, quoteLine);
            }
        }
        if(relatedQteIds.size() > 0 && qLMap.size()>0){
        	getQuoteData(relatedQteIds);
        }
        if(qLMap.size()>0){
            for (SBQQ__QuoteLine__c quoteLine : newQuoteLineList){
                if(quoteData != null && quoteData.containsKey(quoteLine.SBQQ__Quote__c) && qLMap.containsKey(quoteLine.Id)){
                    SBQQ__Quote__c relateddQuote = quoteData.get(quoteLine.SBQQ__Quote__c);
                    if ((!quoteLine.SBQQ__Incomplete__c && relateddQuote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c!=null && quoteLine.SBQQ__ListPrice__c != 0 
                       && quoteLine.SBQQ__ListPrice__c != null && relateddQuote.SBQQ__Opportunity2__r.IsClosed == false && quoteLine.Webstore_Discount_Check__c == false && 
                       (relateddQuote.Process_Eligibility__c == 'Digital Renewals' || relateddQuote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Auto_Renewal__c == true
                       || relateddQuote.SBQQ__Opportunity2__r.Sub_Type__c == 'Auto-Renewal' || relateddQuote.SBQQ__Opportunity2__r.Sub_Type__c == 'Clickpath'))){
                            system.debug('Max 40% discount loop Entered webStoreRenewalsMaximumDiscount joshna');
                            quoteLine.Webstore_Discount_Check__c=true;
                            quoteLine.SBQQ__Discount__c =40;
                            quoteLine.SBQQ__AdditionalDiscountAmount__c=null;
                            quoteLine.SBQQ__OptionDiscount__c=null;
                            quoteLine.SBQQ__OptionDiscountAmount__c=null;
                            quoteLine.SBQQ__PartnerDiscount__c=null;
                            quoteLine.SBQQ__TermDiscount__c=null;
                            quoteLine.SBQQ__DistributorDiscount__c=null;
                    }
                }
            }
        }
    }
    private Boolean isWithinSeconds(Integer numberOfSeconds, SObject olderRecord, SObject newRecord){
        Long olderRecordTs = ((Datetime) olderRecord.get('CreatedDate')).getTime();
        Long newRecordTs = (
            (newRecord.Id != null ? ((Datetime) newRecord.get('CreatedDate')) : System.now()).getTime()
        );
        
        return Integer.valueOf(Math.abs((newRecordTs - olderRecordTs)) / 1000) <= numberOfSeconds;
    }

    /**
     * Checks if SBQQ__CustomerPrice__c from QL matches Subscription's SBQQ__RenewalPrice__c
     * Returns String to display them to the user on Opp.
     */
    private String matchesCustomerPrice(SBQQ__QuoteLine__c ql, SBQQ__Subscription__c sub){
        Decimal quotePrice        = this.calculatePrice(ql.SBQQ__CustomerPrice__c, ql.SBQQ__ProrateMultiplier__c, 2);
        Decimal subscriptionPrice = this.calculatePrice(sub.SBQQ__CustomerPrice__c, sub.SBQQ__ProrateMultiplier__c, 2);
        if (Math.Abs(quotePrice - subscriptionPrice) < Decimal.ValueOf(Label.GainSightThreshold)){ //GTMS-10180
            return '';
        }else{
            return Label.Clickpath_Customer_price_does_not_match;
        }
    }

    /**
     * Calculates the price for License Term discrepancy (36 months comparing a subscription record for 12 months) using the Prorate Multiplier.
     */
    private Decimal calculatePrice(Decimal price, Decimal prorateMultiplier, Integer scale){
        return (price != null && prorateMultiplier != null && prorateMultiplier != 0 ? (price / prorateMultiplier).setScale(scale) : 0);
    }

    /**
     * Checks if the quantity matches between quote and subscription. If revised subscription is filled, sum all of it's children before comparing.
     * Returns String to display them to the user on Opp.
     */
    private String matchesQuantity(SBQQ__QuoteLine__c ql, SBQQ__Subscription__c sub){
        Decimal quantity = 0;
        if (sub.SBQQ__RevisedSubscription__c != null){
            SBQQ__Subscription__c revisedSub = subscriptionMap.get(sub.SBQQ__RevisedSubscription__c);
            quantity += revisedSub.SBQQ__Quantity__c;
            for (SBQQ__Subscription__c childSub : revisedSub.SBQQ__Revisions__r)
                quantity += childSub.SBQQ__Quantity__c;
        }else{
            quantity = sub.SBQQ__Quantity__c;
        }

        return (ql.SBQQ__Quantity__c == quantity ? '' : Label.Clickpath_Quantity_does_not_match);
    }

    /**
     * @param : SBQQ__Quote__c
     */
    private Boolean isClickPath(SBQQ__Quote__c quote){
        return (quote.SBQQ__Opportunity2__r.Sub_type__c == 'Clickpath' || quote.SBQQ__Opportunity2__r.Sub_Type__c == 'Auto-Renewal' || GainsightProcessingOverride);
    }

    /**
     * @param : SBQQ__Quote__c
     */
    private Boolean isRenewalOpportunity(SBQQ__Quote__c quote){
        return quote.SBQQ__Opportunity2__r.Renewal__c;
    }

    /**
     * @param : SBQQ__Quote__c
     * @param : SBQQ__QuoteLine__c
     */
    private void markQuoteLineForRenewalValidation(SBQQ__Quote__c quote, SBQQ__QuoteLine__c line){
        if (this.isClickPath(quote) && this.isRenewalOpportunity(quote)){
            this.quoteLinesWithRenewalSubscription.add(line);
            if (line.SBQQ__RenewedSubscription__c != null) this.subscriptionIdSet.add(line.SBQQ__RenewedSubscription__c);
        }
    }

    /**
     * Retrieves existing Subscriptions for the QuoteLines in context.
     */
    public void getQuoteLineRenewalSubscriptions(){
        // Query all subscriptions directly tied to quoteLines through the SBQQ__RenewedSubscription__c field.
        subscriptionMap = new Map<Id, SBQQ__Subscription__c>(
            getSubscriptions(subscriptionIdSet)
        );

        // To match the Quantities, all the Revised subscriptions are required, so a second "layer" needs to be queried as well.
        Set<Id> layer2Subscriptions = new Set<Id>();
        for (SBQQ__Subscription__c sub : subscriptionMap.values()){
            if (sub.SBQQ__RevisedSubscription__c != null) layer2Subscriptions.add(sub.SBQQ__RevisedSubscription__c);
        }

        if (!layer2Subscriptions.isEmpty())
            subscriptionMap.putAll(getSubscriptions(layer2Subscriptions));
    }

    public List<SBQQ__Subscription__c> getSubscriptions(Set<Id> idsToQuery){
        return [
            SELECT Id, SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__CustomerPrice__c, SBQQ__QuoteLine__c, SBQQ__RevisedSubscription__c, SBQQ__ProrateMultiplier__c, SBQQ__RenewalPrice__c,
                (SELECT SBQQ__Quantity__c FROM SBQQ__Revisions__r)
                FROM SBQQ__Subscription__c
                WHERE Id IN :idsToQuery
        ];
    }

    //HelperMethods
    //Method to fetch the shipping address
    public void getShippingAddress(Set<Id> relatedShippingAddress){
        shippingData = new Map<Id, Shipping_Address__c>([SELECT Id, Shipping_Contact__r.FirstName, Shipping_Contact__r.LastName, Shipping_Address_Line_1__c,
                                                        Shipping_Address_Line_2__c, Shipping_City__c, Shipping_Country__c, Shipping_Zip_Code__c, Shipping_State__c
                                                        FROM Shipping_Address__c WHERE Id IN : relatedShippingAddress]);
    }
    
    //Method to fetch the amended contract Data
    public void getAmendedContractData(Set<Id> contractIds){ // added for GTMS-15657
        amendedContractData = new Map<Id, Contract>([select Id, SBQQ__Quote__c, SBQQ__Quote__r.Selected_Payment_Type__c 
                                                     from Contract where id in:contractIds]);
        FOR(Contract locContract : amendedContractData.values()) {
            listOfOpptyAmendedQuote.add(locContract.SBQQ__Quote__c);
    }
        
    } // added for GTMS-15657
    
    //Method to fetch the amended quote line Data
    public void getAmendedQuoteLineData(Set<Id> quoteIds){ // added for GTMS-15657
        List<SBQQ__QuoteLine__c> listQuoteLinesData = [select Id, SBQQ__Quote__c, SBQQ__Discount__c, Product_Code_Copy__c, SBQQ__ProductCode__c, Ship_To__c 
                                                       from SBQQ__QuoteLine__c where SBQQ__Quote__c in:quoteIds];
        FOR(SBQQ__QuoteLine__c  locRec: listQuoteLinesData) {
            amendedQuoteLineData.put(locRec.SBQQ__Quote__c+locRec.SBQQ__ProductCode__c+locRec.Ship_To__c,locRec);
            
        }
    } // added for GTMS-15657
    
    //Method to fetch the Quote Data
    public void getQuoteData(Set<Id> quoteIds){
        quoteData = new Map<Id, SBQQ__Quote__c>([SELECT Id, Shipping_Address_NEW__c, SBQQ__Account__c, Ship_From_Location__c, License_Term__c, Shipping_Country__c,Custom_License_Term__c, 
                                                 SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Renewal__c, SBQQ__Opportunity2__r.Sub_type__c, CreatedDate,SBQQ__Type__c,
                                                 Selected_Payment_Type__c, Total_License_Price__c, Annual_License_with_Tax__c, Monthly_License_with_Tax__c, 
                                                 Total_License_Due__c, First_Purchase__c, Opportunity_Owner_Segment__c,SBQQ__SubscriptionTerm__c,CalculatedSubscriptionTerm__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Deactivated__c,
                                                 SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Auto_Renewal__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c,
                                                 Buyout_Amount__c, Subsidy_Amount__c,SBQQ__Opportunity2__r.probability, SBQQ__Opportunity2__r.IsClosed, Process_Eligibility__c,SBQQ__RenewalUpliftRate__c,Opportunity_Owner_Role_Copy__c,
                                                 SBQQ__MasterContract__c, SBQQ__Opportunity2__r.Type, Co_Term_Contract__c,
                                                 SBQQ__MasterContract__r.Billing_Contract_Line_Id__c, SBQQ__Account__r.B360_ContractEndDate__c, SBQQ__Account__r.B360_Payment_Type__c, Co_Term_Contract__r.Billing_Contract_Line_Id__c 
                                                 FROM SBQQ__Quote__c WHERE Id IN : quoteIds]);
    
    }

    // Method to calculate ACV
    public Decimal calculateACV(Integer licenseTerm, Decimal discount, Decimal quantity, Decimal unitPrice){
        Decimal acvPrice;
        if(licenseTerm < 12 || licenseTerm == NULL) {
          acvPrice = unitPrice * quantity * (100 - discount) / 100;
        } else {
          acvPrice = unitPrice * quantity * (100 - discount) / 100 / licenseTerm * 12;
        }
        return acvPrice;
    }
    
    //Method to stamp the field Ship_To_Address_Concatenated__c on the line item.
    public void stampShipToAddress(SBQQ__QuoteLine__c quoteline){
        if(quoteline.Ship_To__c != null){
             if(shippingData.containsKey(quoteline.Ship_To__c)  && quoteline.SBQQ__RequiredBy__c==null){ // changed for GTMS-7949
                Shipping_Address__c relatedShippingAddress = shippingData.get(quoteline.Ship_To__c);
                if((relatedShippingAddress.Shipping_State__c == null) && (relatedShippingAddress.Shipping_Address_Line_2__c != null)){
                     quoteline.Ship_To_Address_Concatenated__c = relatedShippingAddress.Shipping_Contact__r.FirstName +' '+relatedShippingAddress.Shipping_Contact__r.LastName+'\n'
                     +relatedShippingAddress.Shipping_Address_Line_1__c+'\n'
                     +relatedShippingAddress.Shipping_Address_Line_2__c+'\n'
                     +relatedShippingAddress.Shipping_City__c+', '+relatedShippingAddress.Shipping_Zip_Code__c+'\n' 
                     +relatedShippingAddress.Shipping_Country__c;        
                }
                else if((relatedShippingAddress.Shipping_Address_Line_2__c == null) && (relatedShippingAddress.Shipping_State__c != null)){
                    quoteline.Ship_To_Address_Concatenated__c = relatedShippingAddress.Shipping_Contact__r.FirstName +' '+relatedShippingAddress.Shipping_Contact__r.LastName+'\n'
                    +relatedShippingAddress.Shipping_Address_Line_1__c+'\n'
                    +relatedShippingAddress.Shipping_City__c+', '+relatedShippingAddress.Shipping_State__c+', '+relatedShippingAddress.Shipping_Zip_Code__c+'\n' 
                    +relatedShippingAddress.Shipping_Country__c;  
                }
                else if((relatedShippingAddress.Shipping_Address_Line_2__c == null) && (relatedShippingAddress.Shipping_State__c == null)){
                    quoteline.Ship_To_Address_Concatenated__c = relatedShippingAddress.Shipping_Contact__r.FirstName +' '+relatedShippingAddress.Shipping_Contact__r.LastName+'\n'
                    +relatedShippingAddress.Shipping_Address_Line_1__c+'\n'
                    +relatedShippingAddress.Shipping_City__c+', '+relatedShippingAddress.Shipping_Zip_Code__c+'\n' 
                    +relatedShippingAddress.Shipping_Country__c;  
                }
                 else{
                     quoteline.Ship_To_Address_Concatenated__c = relatedShippingAddress.Shipping_Contact__r.FirstName +' '+relatedShippingAddress.Shipping_Contact__r.LastName+'\n'
                     +relatedShippingAddress.Shipping_Address_Line_1__c+'\n'
                     +relatedShippingAddress.Shipping_Address_Line_2__c+'\n'
                     +relatedShippingAddress.Shipping_City__c+', '+relatedShippingAddress.Shipping_State__c+', '+relatedShippingAddress.Shipping_Zip_Code__c+'\n' 
                     +relatedShippingAddress.Shipping_Country__c; 
                }
            }        
        }
        else{
            quoteline.Ship_To_Address_Concatenated__c = '';
        }
    }
    
    private void setTaxData(SBQQ__QuoteLine__c quoteLine, SBQQ__Quote__c quote){
        if(quoteLine.Taxpayer_Code__c == NULL && (quoteLine.Ship_To_Country__c == 'Mexico' || quote.Shipping_Country__c == 'Mexico')){
            quoteLine.Taxpayer_Code__c = System.Label.MX_Taxpayer_Code;
        }
    }
    
    //https://samsaradev.atlassian.net/browse/GTMS-10007
    public void beforeDeleteOperations(List<SBQQ__QuoteLine__c> oldDeleteQuoteLineList) {
        if(oldDeleteQuoteLineList!=null && oldDeleteQuoteLineList.size()>0){
            Boolean hasPermission = (!UserInfo.getUserEmail().startsWith('corpweb-sfdc-robot@samsara.com') && !FeatureManagement.checkPermission('Validation_Rule_Exemption') && !UserInfo.getProfileId().startsWith('00e1a000000UoNc') && !UserInfo.getProfileId().startsWith('00e1P000000FBBD')) || Test.isRunningTest();  
                for(SBQQ__QuoteLine__c qle:oldDeleteQuoteLineList){
                if(hasPermission && String.isNotBlank(qle.Original_FT_Oppty_Line_Item_SF_Id__c)) {  
                    qle.addError('You cant delete quote line, because it is a created from a free trial opportunity. Please refresh page to view it again.');  
                    }
                if(hasPermission && qle.Is_Renewed_Line__c){  
                    qle.addError('You cant delete quote line #'+Integer.valueOf(qle.SBQQ__Number__c)+'. Because it is a renewal line. Please refresh page to view it again.');  
                }
                     //GTMS-26503
                FlexConstants__c flexConstant = FlexConstants__c.getInstance('FlexConstants');
                if(flexConstant != null && !FlexCnRTriggerBypass__c.getInstance().Bypass_Sync_and_Flag_Reset_Logic__c &&
                   !FeatureManagement.checkPermission(flexConstant.Flex_Access_QuoteLine__c)&& 
                    String.isNotBlank(qle.Flex_Group_Name__c) && 
                    (qle.Flex_Group_Name__c == FlexConstants__c.getInstance('FlexConstants').Carryover_Products__c || 
                     qle.Flex_Group_Name__c == FlexConstants__c.getInstance('FlexConstants').Upgraded_Products__c)){
                     
                        qle.addError(FlexConstants__c.getInstance('FlexConstants').Error_Message__c);
                }
                }
               
            }
        }
 
    /**
    * @description : method handles the logic to prevent the addition of products to Carryover Products or Upgraded Products groups.
    * Jira: GTMS-26503
    **/
    public void preventProductAdditionToProtectedGroups(List<SBQQ__QuoteLine__c> quoteLines) {
        if(quoteLines != null && quoteLines.size() > 0) {
                FlexConstants__c flexConstant = FlexConstants__c.getInstance('FlexConstants');
                // To avoid existing test class failures
                if (flexConstant == null) {
                    return;
                }
                for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                    if (quoteLine.SBQQ__PriorQuantity__c == null &&
                        !FeatureManagement.checkPermission(flexConstant.Flex_Access_QuoteLine__c) &&
                        String.isNotBlank(quoteLine.Flex_Group_Name__c)) {
                        if (quoteLine.Flex_Group_Name__c == flexConstant.Carryover_Products__c || 
                            quoteLine.Flex_Group_Name__c == flexConstant.Upgraded_Products__c) {
                            quoteLine.addError(flexConstant.Error_Message__c);
                    }
                }
            }
        }
        Logger.insertMasterLogs();
    }
    
    //GTMS-11201
    /* public void setACV(List<SBQQ__QuoteLine__c> quoteLines){
        List<SBQQ__QuoteLine__c> QLs = new List<SBQQ__QuoteLine__c>();
        Boolean isChanged = false;
       
        for(SBQQ__QuoteLine__c ql : quoteLines){
            if(ql.New_ACV__c == NULL || ql.Renewal_ACV2__c == NULL ||
               ql.New_ACV__c <> ql.New_ACV_Formula__c ||
               ql.Renewal_ACV2__c <> ql.Renewal_ACV_Formula__c){
               
                   QLs.add(new SBQQ__QuoteLine__c(Id=ql.id, 
                                            New_ACV__c = ql.New_ACV_Formula__c,
                                            Renewal_ACV2__c = ql.Renewal_ACV_Formula__c));
                                           
                   isChanged = true;
               }
        }
        
        if(isChanged)
            update QLs;
    } */
   /*
    No DML operation (update) inside the method
    Fields are updated directly on quoteLines, ensuring the changes are committed during beforeInsert and beforeUpdate.
    Ensures better governor limits usage by avoiding unnecessary database operations.
    */

     public void setACV(List<SBQQ__QuoteLine__c> quoteLines){
        for(SBQQ__QuoteLine__c ql : quoteLines){
            System.debug('ql.New_ACV_Formula__c'+ql.New_ACV_Formula__c);
            System.debug('ql.Renewal_ACV_Formula__c'+ql.Renewal_ACV_Formula__c);
            if(ql.New_ACV__c == NULL || ql.Renewal_ACV2__c == NULL ||
               ql.New_ACV__c <> ql.New_ACV_Formula__c ||
               ql.Renewal_ACV2__c <> ql.Renewal_ACV_Formula__c){

                System.debug('ql.New_ACV_Formula__c'+ql.New_ACV_Formula__c);
                System.debug('ql.Renewal_ACV2__c'+ql.Renewal_ACV_Formula__c);
                
                ql.New_ACV__c = ql.New_ACV_Formula__c;
                ql.Renewal_ACV2__c = ql.Renewal_ACV_Formula__c;
            }
        }
    }

    //GTMS-13039
       public void setIsACV(List<SBQQ__QuoteLine__c> quoteLines){
        Set<Id> productIdSet = new Set<Id>();
        for (SBQQ__QuoteLine__c ql : quoteLines){
            if (ql.SBQQ__Product__c != null && ql.IsACV__c == False){
                productIdSet.add(ql.SBQQ__Product__c);
            } 
        }
        if (productIdSet.isEmpty()) return;
        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, IsACV__c FROM Product2 WHERE Id IN :productIdSet AND IsACV__c = TRUE]);
        for (SBQQ__QuoteLine__c ql : quoteLines){
            if(productMap.get(ql.SBQQ__Product__c) <> NULL){
                ql.IsACV__c = productMap.get(ql.SBQQ__Product__c).IsACV__c;
            }
        }
    }

    public void stampShippingLocations(Set<Id> ftOpportunityLineIds, List<SBQQ__QuoteLine__c> quotelines){
      Map<Id, OpportunityLineItem> opportunityLineById = new Map<Id, OpportunityLineItem>([SELECT Id, Ship_From_Location__c, Ship_To__c FROM OpportunityLineItem WHERE Id IN:ftOpportunityLineIds]);
        for(SBQQ__QuoteLine__c quoteline : quotelines) {
            if(String.isNotBlank(quoteline.Original_FT_Oppty_Line_Item_SF_Id__c)) {
                OpportunityLineItem ftOpportunityLine = opportunityLineById.get(quoteline.Original_FT_Oppty_Line_Item_SF_Id__c);
                if(ftOpportunityLine != null) {
                    String shipFromLocation = 'Free Trial';
                    if(ftOpportunityLine.Ship_From_Location__c == 'Estafeta'){
                        shipFromLocation = 'MX Free Trial';
                    }else if(ftOpportunityLine.Ship_From_Location__c == 'VCK' || ftOpportunityLine.Ship_From_Location__c == 'DHL'){
                        shipFromLocation = 'Free Trial EU';
                    }
                    quoteline.Ship_From_Location__c = shipFromLocation;
                    quoteline.Ship_To__c = ftOpportunityLine.Ship_To__c;
                }
            }
        }
    }
    
    public void populateProductCodeMapAndGetC360Records(Set<Id> accountIds){

        // put product code into map
        // Build a separate set of field API names used ONLY for the query
        Set<String> c360FieldSet = new Set<String>();
        for (Opportunity_Product_Code__mdt metarec : Opportunity_Product_Code__mdt.getAll().values()) {
            if(metarec.Is_Active__c){
                productCodeMap.put(metarec.Name__c, metarec.Value__c);
                // Include in query only when active AND not checked
                if(metarec.Is_Checked__c == false && String.isNotBlank(metarec.Value__c)){
                    c360FieldSet.add(metarec.Value__c.trim());
                }
            }
        }
        // Build SELECT field list from productCodeMap values and custom labels, plus core identifiers
        List<String> selectFields = new List<String>();
        selectFields.add('Id');
        selectFields.add('Account__c');

        // c360FieldSet is populated above from metadata where Is_Active__c == true AND Is_Checked__c == false

        // Labels were used for developer verification only; rely on active metadata values

        selectFields.addAll(new List<String>(c360FieldSet));

        String c360Record = ' SELECT ' + String.join(selectFields, ', ')
            + ' FROM Customer_360__c WHERE Account__c IN:accountIds AND Account__c != null AND SOT__c = True';
        try {
            for (Customer_360__c c36rec:Database.query(c360Record)) {
                customer360Map.put(c36rec.account__c, c36rec);
            }
        } catch (Exception e) {
            Logger.atError()
                .setClassName('SBQQQuoteLineHelper')
                .setMethod('populateProductCodeMapAndGetC360Records')
                .setLineNumber(1083)
                .setExceptionOrMessage(e);
            System.debug('Error executing dynamic SOQL for Customer_360__c. SOQL=' + c360Record + ' Error=' + e.getMessage());
        }
    }
     //for GTMS-28256
     public  void updateApprovalRequiredMUP(SBQQ__QuoteLine__c updatedQuoteLine, String productCode)
    {
       String c360DiscountAPI = productCodeMap != null ?productCodeMap.get(productCode+'-MUP'):null; 
       try {
        Customer_360__c c360object = customer360Map != null ? customer360Map.get(updatedQuoteLine.Account__c) : null;
           if (c360object != null && c360DiscountAPI != null && String.isNotBlank(c360DiscountAPI)) 
       {
           Object fieldValue = c360object.get(c360DiscountAPI);
           //check whether monthly unit price is lesser than mup of c360 adding a buffer of 0.5%
           if((fieldValue != null && updatedQuoteLine.Monthly_Unit_Price__c < (Decimal)fieldValue * 0.995) ||fieldValue==null)
           {
               updatedQuoteLine.Approval_Required__c = true;  
           }
           else
           {
              updatedQuoteLine.Approval_Required__c = false;   
           }
       }
       else
       {
        updatedQuoteLine.Approval_Required__c = true;   
       }
    }
       catch(Exception e)
       {
          System.debug('Field ' + c360DiscountAPI + ' not accessible on Customer_360__c: ' + e.getMessage());

           }
       }

    //for GTMS-29089 - MUP Mismatch Detection
    public void updateMUPComparisonFlag(SBQQ__QuoteLine__c updatedQuoteLine, String productCode)
    {
        if (updatedQuoteLine == null || String.isBlank(productCode) || updatedQuoteLine.Account__c == null) {
            return;
        }
        
        String c360MUPField = productCodeMap != null ? productCodeMap.get(productCode + '-MUP') : null;
        
        try {
            Customer_360__c c360object = customer360Map != null ? customer360Map.get(updatedQuoteLine.Account__c) : null;
            
            if (c360object != null && c360MUPField != null && String.isNotBlank(c360MUPField)) {
                Object c360MUPValue = c360object.get(c360MUPField);
                
                if (c360MUPValue != null && (Decimal)c360MUPValue != 0) {
                    // Check if Monthly_Unit_Price__c does not match C360 MUP
                    if (updatedQuoteLine.Monthly_Unit_Price__c != (Decimal)c360MUPValue) {
                        updatedQuoteLine.MUP_Mismatch_Flag__c = true;
                    } else {
                        updatedQuoteLine.MUP_Mismatch_Flag__c = false;
                    }
                } else {
                    updatedQuoteLine.MUP_Mismatch_Flag__c = false;
                }
            } else {
                updatedQuoteLine.MUP_Mismatch_Flag__c = false;
            }
        } catch(Exception e) {
            updatedQuoteLine.MUP_Mismatch_Flag__c = false;
        }
    }

}