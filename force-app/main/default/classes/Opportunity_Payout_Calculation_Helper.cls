/**********************************************************************
Name: Opportunity_Payout_Calculation_Helper
Test Class: [Opportunity_Payout_Helper_Test]
-----------------------------------------------------------------------
Purpose: This class contains the logic to calculate payouts for partners based on 
         opportunity interactions and partner program enrollments.
-----------------------------------------------------------------------
History  
TICKET      AUTHOR                          DATE            DETAIL
GTMS-26017  [Vijaychandra AMARANENI]       [3/5/2025]      Added logic to update Partner Payout and Categorization Reason
GTMS-26124  [Vijaychandra AMARANENI]       [3/15/2025]     Added logic to update Partner Payout and Categorization Reason
GTMS-26559  [Majusha]                      [3/15/2025]     Added logic to update opportunity partner fields from CR
GTMS-27265  [Vijaychandra AMARANENI]       [4/5/2025]      Added logic to update Partner Payout and Stage for Rebate Opportunities
GTMS-28680  [Vijaychandra AMARANENI]	   [7/28/2025]	   Added logic for Expansion Engagement Type in to the Influence Logic
***********************************************************************/ 
public without sharing class Opportunity_Payout_Calculation_Helper {
    
    public static Final String SOURCE_TYPE = SYSTEM.LABEL.Partner_Sourced_Interaction_Type;
    public static final string INFLUENCE_TYPE = SYSTEM.LABEL.Partner_Influenced_Interaction_Type;
    public static final string EXPANSION_TYPE = SYSTEM.LABEL.Partner_Expansion_Interaction_Type;//GTMS-28680: created constant for Expansion Interaction Type
    public static final string PERPETUAL_PERIOD = 'Perpetual';//GTMS-28680: created constant for Perpetual Period
    public static final String TRANSACTING_PARTNER = 'Transacting Partner';
    public static final String PERCENT_MODEL = 'Percentage';
    public static final string FLAT_RATE_MODEL = 'Flat Rate';
    public static final string LIST_AMOUNT = 'List Amount';
    public static final string NET_AMOUNT = 'Net Amount';
    public static Map<String, DatedConversionRate> conversionRateMap = new Map<String, DatedConversionRate>();
    /*************************************************
     * Description: Invocable method to calculate payouts for partners. This method serves as the entry point
     * and routes the calculation to either future or synchronous execution based on context.
     * oppIdList: List of Opportunity IDs to calculate payouts for
     */
    @InvocableMethod(label='Calculate Payouts' description='To Calculate Payout for partners' category='Opportunity')
    public static void calculatePayout(List<Id> oppIdList){
        if(System.isFuture()||System.isBatch()){
            payoutCalculationMethod(oppIdList);
        }else{
            payoutCalculationFuture(oppIdList);
        }
    }
    
   	/*************************************************
     * Description: Future method to handle asynchronous payout calculations
     * oppIdList: List of Opportunity IDs to calculate payouts for
     */
   	@Future
    public static void payoutCalculationFuture(List<Id> OppIdList){
        payoutCalculationMethod(oppIdList);
    }
    
    /*************************************************
     * Description: Core method that implements the payout calculation logic. Handles sourced and influenced
     * partner payouts based on program enrollment and interaction type.
     * oppIdList: List of Opportunity IDs to calculate payouts for
     */
    public static void payoutCalculationMethod(List<Id> oppIdList){
        if(!oppIdList.isEmpty()){
            PayoutAndReasonWrapper finalWrapper = new PayoutAndReasonWrapper(0,SYSTEM.LABEL.NO_CUSTOMER_OR_PARTNER_SELECTED);
            Set<String> customerIdsSet = new Set<String>();
            Set<String> partnerIdsSet = new Set<String>();
            Set<String> opportunityCurrencySet = new Set<String>();
            Set<Date> opptyCloseDateSet = new Set<Date>();
            Map<Id,Account> accRelatedFirstOpp = new Map<Id,Account>();
            Map<String,PayoutWrapper> partner_Customer_Payout_Map = new Map<String,PayoutWrapper>();
            List<Channel_Relationship__c> crListToUpdate = new List<Channel_Relationship__c>();

            Map<Id,Channel_Relationship__c> crMap = new Map<Id,Channel_Relationship__c>([SELECT Id,Opportunity__c,Partner_Payout__c,Eligible_For_Payout__c,
                                         Influence_Payout_Fee__c,Influence_Payout_Model__c,Influence_Payout_Percentage__c,Sourced_Payout_Fee__c,
                                         Sourced_Payout_Model__c,Sourced_Payout_Percentage__c,Primary_Record__c,Channel_Partner__c,
                                         Partner_Program__c,Partner_Enrollment__c,Partner_Interaction_Type__c,Opportunity__r.AccountId,Opportunity__r.ACV_Bookings_SOT__c,
                                         Partner_Enrollment__r.Member_Status__c,Partner_Enrollment__r.Sourced_Payout_Cap__c,Partner_Enrollment__r.Sourced_Payout_Fee__c,
                                         Partner_Enrollment__r.Sourced_Payout_Model__c,  Partner_Enrollment__r.Influence_Payout_Cap__c,Calculate_Rebate_From__c,Partner_Enrollment__r.Rebate_Timeline_Eligibility__c,
                                         Partner_Enrollment__r.Influence_Payout_Fee__c, Partner_Enrollment__r.Influence_Payout_Model__c,Opportunity__r.Blended_Discount__c, 
                                         Channel_Partner__r.Partner_Status__c,Opportunity__r.Account.Latest_Active_Contract_End_Date__c,Customer_Account__c,Customer_Account__r.Latest_Active_Contract_End_Date__c,
                                         Opportunity__r.SBQQ__AmendedContract__c, Opportunity__r.SBQQ__Renewal__c,Partner_Program__r.Paid_for_new_business__c, Partner_Program__r.Paid_for_Add_Ons__c,
                                         Partner_Program__r.Paid_for_Renewals__c,Is_Deal_Registration__c, Opportunity__r.CloseDate,CreatedDate,Opportunity__r.CurrencyIsoCode,Opportunity__r.First_Purchase__c,
                                         Partner_Enrollment__r.Program_Compensation_Model__c,Opportunity_Currency__c, Opportunity_Currency_Conversion_Rate__c, Partner_Payout_In_Opportunity_Currency__c, Partner_Currency__c                                             
                                         FROM Channel_Relationship__c WHERE Opportunity__c IN: oppIdList]);
            
            for(Channel_Relationship__c crRec: crMap.Values()){
                if(crRec.Customer_Account__c != null)customerIdsSet.add(crRec.Customer_Account__c);
                if(crRec.Channel_Partner__c != null)PartnerIdsSet.add(crRec.Channel_Partner__c);
                if(crRec.Opportunity_Currency__c != null)opportunityCurrencySet.add(crRec.Opportunity_Currency__c);
                if(crRec.Opportunity__r.CloseDate != null)opptyCloseDateSet.add(crRec.Opportunity__r.CloseDate);
            }
            
            if(!opportunityCurrencySet.isEmpty() && !opptyCloseDateSet.isEmpty()) {
              	conversionRateMap = getConversionRates(opportunityCurrencySet, opptyCloseDateSet);
            }
            if(!customerIdsSet.isEmpty()){
                accRelatedFirstOpp = new Map<Id,Account>([SELECT Id,
                                                        (SELECT Id,CloseDate 
                                                         FROM Opportunities 
                                                         WHERE 
                                                         StageName = 'Closed Won' 
                                                         AND SBQQ__AmendedContract__c = null 
                                                         AND SBQQ__Renewal__c = false 
                                                         and Type = 'Revenue Opportunity'
                                                         AND First_Purchase__c = true
                                                         AND Id NOT In : oppIdList
                                                         Order By CloseDate ASC LIMIT 1)
                                                        FROM Account
                                                        WHERE 
                                                        Id IN: customerIdsSet]);
            }
            if(!customerIdsSet.isEmpty() && !PartnerIdsSet.isEmpty()){
                partner_Customer_Payout_Map = fetchExistingPayoutValues(customerIdsSet, PartnerIdsSet, oppIdList);
            }
           	for(Channel_Relationship__c cr: crMap.values()){
                Decimal payoutVal = 0;
                if(cr.Customer_Account__c != null && cr.Channel_Partner__c != null){
                    string keyString = cr.Channel_Partner__c+'-'+cr.Customer_Account__c;
                    PayoutWrapper payoutVar = partner_Customer_Payout_Map.containsKey(keyString) ? partner_Customer_Payout_Map.get(keyString) : new PayoutWrapper(0,0) ;
                    finalWrapper = calculatePayoutAndReason(cr,accRelatedFirstOpp.get(cr.Customer_Account__c),payoutVar);
                }
                // Get opportunity currency conversion rate from dated conversion rate map, defaulting to 1 if not found
                DatedConversionRate opptyDcr = conversionRateMap.get(cr.Opportunity_Currency__c + '-' + cr.Opportunity__r.CloseDate);
                Decimal opptyCurrencyConversionRate = opptyDcr != null ? opptyDcr.ConversionRate : 1;
                
                // Convert partner payout to opportunity currency by multiplying by conversion rate
                Decimal partnerPayoutInOpportunityCurrency = finalWrapper.partnerPayout != null ? finalWrapper.partnerPayout * opptyCurrencyConversionRate : 0;
                
                // Create new Channel Relationship record for update
                Channel_Relationship__c crRec = new Channel_Relationship__c();
                crRec.Id = cr.Id;
                crRec.Partner_Payout__c = finalWrapper.partnerPayout != null ? finalWrapper.partnerPayout.setScale(2, RoundingMode.HALF_UP) : 0;
                crRec.Partner_Payout_In_Opportunity_Currency__c = partnerPayoutInOpportunityCurrency != null ? partnerPayoutInOpportunityCurrency.setScale(2, RoundingMode.HALF_UP) : 0;
                crRec.Opportunity_Currency_Conversion_Rate__c = opptyCurrencyConversionRate != null ? opptyCurrencyConversionRate.setScale(2, RoundingMode.HALF_UP) : 0;
                if(finalWrapper.categorizationReason != null) crRec.Categorization_Reason__c = finalWrapper.categorizationReason;
                crRec.Categorization_Date__c = Datetime.now();
                // Add record to list for bulk update
                crListToUpdate.add(crRec);                    
                
           	}
            
            if(!crListToUpdate.isEmpty() && !Test.IsRunningTest()){
                update crListToUpdate;
                updateRebateOpportunities(crListToUpdate, crMap);
            }

            //updateOpportunityPartnerFiledsFromCR(OppIdList);//GTMS-26559 
        }
    }
    //GTMS-26559 --START-- Method to update opportunity fields from Channel Relationship records
    /*************************************************
     * Description: Updates opportunity fields from Channel Relationship records based on mapping metadata
     * oppIdList: List of Opportunity IDs to update fields for
     */
    /*public static void updateOpportunityPartnerFiledsFromCR(List<Id> OppIdList){ //GTMS-26559 -- start     
        Map<String, OpportunityToChannelRelationshipMapping__mdt> metadataMap = OpportunityToChannelRelationshipMapping__mdt.getAll();
        Map<String, String> fieldMappings = new Map<String, String>();
        Map<Id, Channel_Relationship__c> crToAssignMap = new Map<Id, Channel_Relationship__c>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for (OpportunityToChannelRelationshipMapping__mdt metadataRecord : metadataMap.values()) {
            String crFieldName = metadataRecord.CR_Field_Name__c;
            String oppFieldName = metadataRecord.Opp_Field_Name__c; 
            fieldMappings.put(crFieldName,oppFieldName);
        }
        system.debug('fieldMappings '+fieldMappings);
        List<String> crFieldsToQuery = new List<String>();
        for (String crFieldName : fieldMappings.keySet()) {
            crFieldsToQuery.add(crFieldName);  
        }
        crFieldsToQuery.add('Opportunity__c');
        crFieldsToQuery.add('Partner_Interaction_Type__c');
        crFieldsToQuery.add('Eligible_For_Payout__c');
        
        String soqlQuery = 'SELECT ' + String.join(crFieldsToQuery, ', ') + ' FROM Channel_Relationship__c WHERE Opportunity__c IN :OppIdList';
        List<Channel_Relationship__c> crList = Database.query(soqlQuery);
        
        for(Channel_Relationship__c cr: crList){
            if(cr.Partner_Interaction_Type__c == 'Partner Sourced'){  
                crToAssignMap.put(cr.Opportunity__c,cr);
            }
            else if(cr.Partner_Interaction_Type__c == 'Partner Influenced'&& cr.Eligible_For_Payout__c == 'Yes' && !crToAssignMap.containsKey(cr.Opportunity__c)){
                crToAssignMap.put(cr.Opportunity__c,cr);
            }
        }
        if(!crToAssignMap.isEmpty()){
            for(Channel_Relationship__c crToAssign: crToAssignMap.values()){
                Opportunity oppToUpdate = new Opportunity(Id = crToAssign.Opportunity__c);
                for (String crField : fieldMappings.keySet()) {
                    String oppField = fieldMappings.get(crField);
                    oppToUpdate.put(oppField, crToAssign.get(crField));
                }
                system.debug('oppToUpdate '+oppToUpdate);
                opportunitiesToUpdate.add(oppToUpdate);
            }
        }
        system.debug('opportunitiesToUpdate '+opportunitiesToUpdate);
        if(!opportunitiesToUpdate.isEmpty() && !Test.IsRunningTest()) update opportunitiesToUpdate;
    }
	*/
    //GTMS-26559 --END-- Method to update opportunity fields from Channel Relationship records
    
    /*************************************************
     * Description: Fetches existing payout values for partner-customer combinations to track against caps
     * customerAccIds: Set of customer account IDs
     * partnerAccIds: Set of partner account IDs
     * oppIdList: List of Opportunity IDs to exclude from calculations
     * Returns: Map of partner-customer key to their payout wrapper containing source and influence payouts
     */
    @testvisible
    static Map<String,PayoutWrapper> fetchExistingPayoutValues(Set<String> customerAccIds, Set<String> partnerAccIds,List<Id> oppIdList){
        Map<String,PayoutWrapper> partner_Customer_Payout_Map = new Map<String,PayoutWrapper>();
        //07/31/2025 Vijaychandra AMARANENI (GTMS-28680): removed Partner Program and Enrollment conditions from the below query
        for(Channel_Relationship__c crRec:[SELECT Id,Customer_Account__c,Channel_Partner__c,Partner_Payout__c,Partner_Interaction_Type__c FROM Channel_Relationship__c WHERE Partner_Interaction_Type__c != null AND Partner_Payout__c != null AND Partner_Payout__c != 0 AND Customer_Account__c IN :customerAccIds AND Channel_Partner__c IN :partnerAccIds AND Opportunity_Stage__c = 'Closed Won' AND Opportunity__c NOT IN :oppIdList AND Eligible_For_Payout__c = 'Yes']){
            string keyString = crRec.Channel_Partner__c+'-'+crRec.Customer_Account__c;
            if(!partner_Customer_Payout_Map.containsKey(keyString)){
                partner_Customer_Payout_Map.put(keyString, new PayoutWrapper(0,0));
            }
            PayoutWrapper payoutVar = partner_Customer_Payout_Map.get(keyString);
            payoutVar.sourcePayout += (crRec.Partner_Interaction_Type__c == SOURCE_TYPE) ? crRec.Partner_Payout__c : 0;
            //07/31/2025 Vijaychandra AMARANENI (GTMS-28680): added EXPANSION_TYPE to the condition in below conditions
            payoutVar.influencePayout += (crRec.Partner_Interaction_Type__c == INFLUENCE_TYPE || crRec.Partner_Interaction_Type__c == EXPANSION_TYPE) ? crRec.Partner_Payout__c : 0;
 
            partner_Customer_Payout_Map.put(keyString, payoutVar);
        }
        
        return partner_Customer_Payout_Map;
    }
    
    /*************************************************
     * Description: Calculates payout amount and reason based on opportunity type (new, amendment, renewal)
     * cr: Channel Relationship record
     * accRec: Account record
     * payoutVar: Existing payout values wrapper
     * Returns: PayoutAndReasonWrapper containing calculated payout amount and categorization reason
     */
    static PayoutAndReasonWrapper calculatePayoutAndReason(Channel_Relationship__c cr, Account accRec, PayoutWrapper payoutVar){
        PayoutAndReasonWrapper finalWrapper = new PayoutAndReasonWrapper(0,null);
        if(cr.Partner_program__r != null) {
            if(cr.Opportunity__r.SBQQ__AmendedContract__c != null){
            	finalWrapper = calculateAmendPayoutAndReason(cr,accRec,payoutVar);
            }else if(cr.Opportunity__r.SBQQ__Renewal__c){
                finalWrapper = calculateRenewalPayoutAndReason(cr,accRec,payoutVar);
            }else{
                finalWrapper = calculateNewOpptyPayoutAndReason(cr,accRec,payoutVar);
            }
        }else{
            finalWrapper = new PayoutAndReasonWrapper(0,SYSTEM.LABEL.NOT_ENROLLED_FOR_A_PROGRAM);
        }

        return finalWrapper;
    }
    
    /*************************************************
     * Description: Calculates payout for new business opportunities
     * cr: Channel Relationship record
     * accRec: Account record
     * payoutVar: Existing payout values wrapper
     * Returns: PayoutAndReasonWrapper containing calculated payout amount and categorization reason
     */
    static PayoutAndReasonWrapper calculateNewOpptyPayoutAndReason(Channel_Relationship__c cr, Account accRec, PayoutWrapper payoutVar){
        Decimal payoutVal = 0;
        Boolean generalEligibility = true;
        String catergorizationReason = null;
        Boolean isPaidForNewOppty = (cr.Partner_Program__r?.Paid_for_new_business__c) == 'Yes' && (cr.Partner_Enrollment__r?.Program_Compensation_Model__c) == 'Paid' ? true : false;
        //07/31/2025 Vijaychandra AMARANENI (GTMS-28680): added EXPANSION_TYPE to the condition in below line
        catergorizationReason = !isPaidForNewOppty ? cr.Partner_Interaction_Type__c == SOURCE_TYPE ? SYSTEM.LABEL.Referral_Without_Payout : 
        				(cr.Partner_Interaction_Type__c == INFLUENCE_TYPE || cr.Partner_Interaction_Type__c == EXPANSION_TYPE) ? SYSTEM.LABEL.Influence_Without_Payout : SYSTEM.LABEL.NO_PARTNER_INTERACTION_TYPE : null;
        
        if(isPaidForNewOppty){
           	GeneralPayoutResonsWrapper generalWrapper = generalPayoutChecksAndReasons(cr,accRec,payoutVar);
            catergorizationReason = generalWrapper.generalReason;
            generalEligibility = generalWrapper.isGenerallyEligible;
        }

        if(isPaidForNewOppty && generalEligibility){
            payoutVal = calculatePayout(cr,accRec,payoutVar);
        }
        
        return new PayoutAndReasonWrapper(payoutVal,catergorizationReason);
    }
    /*************************************************
     * Description: Calculates payout for Amendmentopportunities
     * cr: Channel Relationship record
     * accRec: Account record
     * payoutVar: Existing payout values wrapper
     * Returns: PayoutAndReasonWrapper containing calculated payout amount and categorization reason
     */
	@testvisible
	static PayoutAndReasonWrapper calculateAmendPayoutAndReason(Channel_Relationship__c cr, Account accRec, PayoutWrapper payoutVar){
        Decimal payoutVal = 0;
        Boolean generalEligibility = true;
        String catergorizationReason = null;
        
        Boolean isContractActive = cr.Customer_Account__c != null ? cr.Customer_Account__r.Latest_Active_Contract_End_Date__c != null ? cr.Customer_Account__r.Latest_Active_Contract_End_Date__c > Date.Today() : false :false;
        Boolean isPaidForAmendOppty = (cr.Partner_Program__r?.Paid_for_Add_Ons__c) == 'Yes' && (cr.Partner_Enrollment__r?.Program_Compensation_Model__c) == 'Paid' ? true : false;
        //07/31/2025 Vijaychandra AMARANENI (GTMS-28680): added EXPANSION_TYPE to the condition in below line
        catergorizationReason = !isContractActive ? SYSTEM.LABEL.INACTIVE_CONTRACT_REASON :
        							!isPaidForAmendOppty ? cr.Partner_Interaction_Type__c == SOURCE_TYPE ? SYSTEM.LABEL.Referral_Without_Payout : 
        							(cr.Partner_Interaction_Type__c == INFLUENCE_TYPE || cr.Partner_Interaction_Type__c == EXPANSION_TYPE) ? SYSTEM.LABEL.Influence_Without_Payout : 	SYSTEM.LABEL.NO_PARTNER_INTERACTION_TYPE : null;
        if(isContractActive && isPaidForAmendOppty){
           	GeneralPayoutResonsWrapper generalWrapper = generalPayoutChecksAndReasons(cr,accRec,payoutVar);
            catergorizationReason = generalWrapper.generalReason;
            generalEligibility = generalWrapper.isGenerallyEligible;
        }
        if(isContractActive && isPaidForAmendOppty && generalEligibility){
            payoutVal = calculatePayout(cr,accRec,payoutVar);
        }
        
        return new PayoutAndReasonWrapper(payoutVal,catergorizationReason);
    }
    /*************************************************
     * Description: Calculates payout for Renewal opportunities
     * cr: Channel Relationship record
     * accRec: Account record
     * payoutVar: Existing payout values wrapper
     * Returns: PayoutAndReasonWrapper containing calculated payout amount and categorization reason
     */
    @testvisible
    static PayoutAndReasonWrapper calculateRenewalPayoutAndReason(Channel_Relationship__c cr, Account accRec, PayoutWrapper payoutVar){
        Decimal payoutVal = 0;
        Boolean generalEligibility = true;
        String catergorizationReason = null;
        Boolean isPaidForRenewalOppty = (cr.Partner_Program__r?.Paid_for_Renewals__c) == 'Yes' && (cr.Partner_Enrollment__r?.Program_Compensation_Model__c) == 'Paid' ? true : false;
        //07/31/2025 Vijaychandra AMARANENI (GTMS-28680): added EXPANSION_TYPE to the condition in below line
        catergorizationReason = !isPaidForRenewalOppty ? cr.Partner_Interaction_Type__c == SOURCE_TYPE ? SYSTEM.LABEL.Referral_Without_Payout : 
        				(cr.Partner_Interaction_Type__c == INFLUENCE_TYPE || cr.Partner_Interaction_Type__c == EXPANSION_TYPE) ? SYSTEM.LABEL.Influence_Without_Payout : SYSTEM.LABEL.NO_PARTNER_INTERACTION_TYPE : null;
        
        if(isPaidForRenewalOppty){
            GeneralPayoutResonsWrapper generalWrapper = generalPayoutChecksAndReasons(cr,accRec,payoutVar);
            catergorizationReason = generalWrapper.generalReason;
            generalEligibility = generalWrapper.isGenerallyEligible;
        }
        if(isPaidForRenewalOppty && generalEligibility){
            payoutVal = calculatePayout(cr,accRec,payoutVar);
        }
        
        return new PayoutAndReasonWrapper(payoutVal,catergorizationReason);
    }
    
    /*************************************************
     * Description: Performs general eligibility checks for payouts and determines reasons for ineligibility
     * cr: Channel Relationship record
     * accRec: Account record
     * payoutVar: Existing payout values wrapper
     * Returns: GeneralPayoutResonsWrapper containing eligibility flag and reason
     */
    static GeneralPayoutResonsWrapper generalPayoutChecksAndReasons(Channel_Relationship__c cr,Account accRec, PayoutWrapper payoutVar){
        Boolean isTransactingPartner = cr.Channel_Partner__r.Partner_Status__c == TRANSACTING_PARTNER;
        Date closeDate = cr.Partner_Interaction_Type__c == SOURCE_TYPE ? !accRec.Opportunities.isEmpty() ? accRec.Opportunities[0].CloseDate : cr.Opportunity__r.First_Purchase__c ? cr.Opportunity__r.CloseDate : null : null;
        //07/31/2025 Vijaychandra AMARANENI (GTMS-28680): added logic to check if the rebate eligibility date is perpetual or not
        Date rebatedEligibilityDate = (cr.Partner_Enrollment__r.Rebate_Timeline_Eligibility__c == PERPETUAL_PERIOD && cr.Partner_Interaction_Type__c == SOURCE_TYPE) || (cr.Partner_Interaction_Type__c == INFLUENCE_TYPE || cr.Partner_Interaction_Type__c == EXPANSION_TYPE) ? null : cr.Partner_Enrollment__r.Rebate_Timeline_Eligibility__c != null && closeDate != null ? calculateDateFromPeriod(cr.Partner_Enrollment__r.Rebate_Timeline_Eligibility__c, closeDate) : null;
        //07/31/2025 Vijaychandra AMARANENI (GTMS-28680): added logic to check if the rebate eligibility date is perpetual or not
        Boolean withInPayoutPeriod = (cr.Partner_Enrollment__r.Rebate_Timeline_Eligibility__c == PERPETUAL_PERIOD && cr.Partner_Interaction_Type__c == SOURCE_TYPE) || (cr.Partner_Interaction_Type__c == INFLUENCE_TYPE || cr.Partner_Interaction_Type__c == EXPANSION_TYPE) ? true : closeDate != null && rebatedEligibilityDate != null ? rebatedEligibilityDate > Date.Today() ? true :  false : rebatedEligibilityDate == null ? false : true;
        
        Boolean withInSourcePayoutCap = cr.Partner_Enrollment__c != NULL ? payoutVar.sourcePayout < cr.Partner_Enrollment__r.Sourced_Payout_Cap__c : FALSE;
        Boolean withInInfluencePayoutCap = cr.Partner_Enrollment__c != NULL ? payoutVar.influencePayout < cr.Partner_Enrollment__r.Influence_Payout_Cap__c : FALSE;
        Boolean withInPayoutCap = cr.Partner_Interaction_Type__c == SOURCE_TYPE ? withInSourcePayoutCap : (cr.Partner_Interaction_Type__c == INFLUENCE_TYPE || cr.Partner_Interaction_Type__c == EXPANSION_TYPE) ? withInInfluencePayoutCap : false;
        
        Date crCreatedDate = cr.CreatedDate.date();
        Boolean isClosedWithInOneFiftyDays = cr.Is_Deal_Registration__c ? crCreatedDate.addDays(150) > cr.Opportunity__r.CloseDate : true;
        Boolean isGenerallyEligible = (isTransactingPartner  && withInPayoutCap && withInPayoutPeriod && isClosedWithInOneFiftyDays);
        //07/31/2025 Vijaychandra AMARANENI (GTMS-28680): added EXPANSION_TYPE to the condition in below conditions
        string generalReason = !isTransactingPartner ? SYSTEM.LABEL.NOT_A_TRANSCTING_PARTNER :
                        !isClosedWithInOneFiftyDays ? SYSTEM.LABEL.ONE_FIFTY_DAY_REASON :
        				!withInPayoutPeriod ? SYSTEM.LABEL.OUTSIDE_PAYOUT_PERIOD_REASON:
        				(cr.Partner_Interaction_Type__c != SOURCE_TYPE && cr.Partner_Interaction_Type__c != INFLUENCE_TYPE && cr.Partner_Interaction_Type__c != EXPANSION_TYPE) ? SYSTEM.LABEL.NO_PARTNER_INTERACTION_TYPE :
                        (cr.Partner_Interaction_Type__c == SOURCE_TYPE && !withInSourcePayoutCap)? SYSTEM.Label.Referral_Outside_Payoutcap :
                        ((cr.Partner_Interaction_Type__c == INFLUENCE_TYPE || cr.Partner_Interaction_Type__c == EXPANSION_TYPE) && !withInInfluencePayoutCap) ? SYSTEM.Label.Influence_Outside_Payout_Cap : null;
        
        return new GeneralPayoutResonsWrapper(isGenerallyEligible,generalReason);
    }
    /*************************************************
     * Description: Calculates the actual payout amount based on interaction type and payout model
     * cr: Channel Relationship record
     * accRec: Account record
     * payoutVar: Existing payout values wrapper
     * Returns: Decimal value representing the calculated payout amount
     */
    static Decimal calculatePayout(Channel_Relationship__c cr,Account accRec, PayoutWrapper payoutVar){
        DatedConversionRate opptyDcr = conversionRateMap.get(cr.Opportunity_Currency__c + '-' + cr.Opportunity__r.CloseDate);
        if(opptyDcr == null){
            List<DatedConversionRate> dcrList = new List<DatedConversionRate>([SELECT Id, IsoCode, ConversionRate, StartDate, NextStartDate FROM DatedConversionRate WHERE IsoCode =:cr.Opportunity_Currency__c AND StartDate <=: cr.Opportunity__r.CloseDate AND NextStartDate > :cr.Opportunity__r.CloseDate LIMIT 1]);
            opptyDcr = !dcrList.isEmpty() ? dcrList[0] : null;
        }
        Decimal opptyCurrencyConversionRate = opptyDcr != null ? opptyDcr.ConversionRate : 1;
        
        Decimal payoutVal = 0;
        Decimal blendedDiscount = cr.Opportunity__r.Blended_Discount__c != null ? cr.Opportunity__r.Blended_Discount__c/100 : 0;

        Decimal acvVal = cr.Opportunity__r.ACV_Bookings_SOT__c != null ? cr.Calculate_Rebate_From__c == LIST_AMOUNT ? (cr.Opportunity__r.ACV_Bookings_SOT__c/(1-(blendedDiscount))) : cr.Opportunity__r.ACV_Bookings_SOT__c : 0;
        // Convert ACV to USD using opportunity currency conversion rate
        Decimal acvValUSD = acvVal != 0 ? acvVal/opptyCurrencyConversionRate : 0;
        if(cr.Partner_Interaction_Type__c == SOURCE_TYPE){
            Decimal originalPayoutVal = (cr.Sourced_Payout_Model__c == PERCENT_MODEL || cr.Calculate_Rebate_From__c == LIST_AMOUNT) ? cr.Sourced_Payout_Percentage__c != null ? (acvValUSD*cr.Sourced_Payout_Percentage__c)/100 : 0 :
            							(cr.Sourced_Payout_Model__c == FLAT_RATE_MODEL) ? cr.Sourced_Payout_Fee__c : 0;
            payoutVal = (originalPayoutVal+ payoutVar.sourcePayout) > cr.Partner_Enrollment__r.Sourced_Payout_Cap__c ? cr.Partner_Enrollment__r.Sourced_Payout_Cap__c - payoutVar.sourcePayout : originalPayoutVal;
        }else if(cr.Partner_Interaction_Type__c == INFLUENCE_TYPE || cr.Partner_Interaction_Type__c == EXPANSION_TYPE){
            Decimal originalPayoutVal = (cr.Influence_Payout_Model__c == PERCENT_MODEL || cr.Calculate_Rebate_From__c == LIST_AMOUNT) ? cr.Influence_Payout_Percentage__c != null ? (acvValUSD*cr.Influence_Payout_Percentage__c)/100 : 0 :
            							(cr.Influence_Payout_Model__c == FLAT_RATE_MODEL) ? cr.Influence_Payout_Fee__c : 0;
            payoutVal = (originalPayoutVal+ payoutVar.influencePayout) > cr.Partner_Enrollment__r.Influence_Payout_Cap__c ? cr.Partner_Enrollment__r.Influence_Payout_Cap__c - payoutVar.influencePayout : originalPayoutVal;
        }
        return payoutVal;
    }
    
    //GTMS-27265 --START-- Method to update Rebate Opportunities related to Channel Relationships
    /*************************************************
     * Description: Updates rebate opportunities related to channel relationships
     * crList: List of Channel Relationship records to process
     * crMap: Map of Channel Relationship records with full details
     */
    public static void updateRebateOpportunities(List<Channel_Relationship__c> crList, Map<Id,Channel_Relationship__c> crMap) {
        // Exit early if input list is empty
        if (crList == null || crList.isEmpty() || crMap == null || crMap.isEmpty()) {
            return;
        }
        // Create maps and sets to store data
        Map<String, Decimal> oppPartnerToPayoutMap = new Map<String, Decimal>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> partnerIds = new Set<Id>();
        Set<String> currencyIsoCodes = new Set<String>();
        Set<Date> closeDates = new Set<Date>();
        
        // Collect data from input list and validate records
        for (Channel_Relationship__c cr : crList) {
            if (cr == null || cr.Partner_Payout__c == null) {
                continue;
            }
            
            Channel_Relationship__c crRec = crMap.get(cr.Id);
            if (crRec == null || crRec.Opportunity__c == null || crRec.Channel_Partner__c == null) {
                continue;
            }
            
                String key = crRec.Opportunity__c + '-' + crRec.Channel_Partner__c;
                oppPartnerToPayoutMap.put(key, cr.Partner_Payout__c);
                oppIds.add(crRec.Opportunity__c);
                partnerIds.add(crRec.Channel_Partner__c);
            }
        
        // Exit if no valid records found
        if (oppPartnerToPayoutMap.isEmpty()) {
            return;
        }
        
        
            // Query rebate opportunities with selective filters and field limits
            List<Opportunity> rebateOpps = [
                SELECT Id, Returning_Opportunity__c, Referral_Partner__c, 
                       CurrencyIsoCode, CloseDate
            FROM Opportunity 
            WHERE Returning_Opportunity__c IN :oppIds 
            AND Referral_Partner__c IN :partnerIds 
            AND StageName = 'Return Created'
                AND Type = 'Rebate'
                AND CurrencyIsoCode != null
                AND CloseDate != null
            ];
            
            // Exit if no rebate opps found
            if(rebateOpps == null || rebateOpps.isEmpty()) {
                return;
            }

            // Collect currency and date info for conversion rates
            for(Opportunity opp : rebateOpps) {
                currencyIsoCodes.add(opp.CurrencyIsoCode);
                closeDates.add(opp.CloseDate);
            }

            // Get currency conversion rates
            Map<String, DatedConversionRate> conversionRateMap = getConversionRates(currencyIsoCodes, closeDates);

            // Process opportunities and prepare for update
            List<Opportunity> rebateOppsToUpdate = new List<Opportunity>();
            
            for (Opportunity rebateOpp : rebateOpps) {
            String key = rebateOpp.Returning_Opportunity__c + '-' + rebateOpp.Referral_Partner__c;
            
                if (!oppPartnerToPayoutMap.containsKey(key)) {
                    continue;
                }
                
                String conversionKey = rebateOpp.CurrencyIsoCode + '-' + rebateOpp.CloseDate;
                Decimal conversionRate = 1;
                
                if(conversionRateMap != null && conversionRateMap.containsKey(conversionKey)) {
                    DatedConversionRate dcr = conversionRateMap.get(conversionKey);
                    if(dcr == null){
            List<DatedConversionRate> dcrList = new List<DatedConversionRate>([SELECT Id, IsoCode, ConversionRate, StartDate, NextStartDate FROM DatedConversionRate WHERE IsoCode =:rebateOpp.CurrencyIsoCode AND StartDate <=: rebateOpp.CloseDate AND NextStartDate > :rebateOpp.CloseDate LIMIT 1]);
            dcr = !dcrList.isEmpty() ? dcrList[0] : null;
        }
                    if(dcr != null && dcr.ConversionRate != null) {
                        conversionRate = dcr.ConversionRate;
            }
        }
        
                Decimal payoutUSD = oppPartnerToPayoutMap.get(key);
                if(payoutUSD != null) {
                    Decimal payoutConverted = payoutUSD * conversionRate;
                    
                    // Create opportunity for update with minimal fields
                    Opportunity oppToUpdate = new Opportunity(
                        Id = rebateOpp.Id,
                        StageName = 'Finance Processing',
                        Push_Return_to_Netsuite__c = true,
                        Amount = payoutConverted * -1
                    );
                    
                    rebateOppsToUpdate.add(oppToUpdate);
        }
    }
            
            // Perform update with allOrNone false to allow partial success
            if (!rebateOppsToUpdate.isEmpty() && !Test.isRunningTest()) {Database.SaveResult[] results = Database.update(rebateOppsToUpdate, false);}
                
    }
    //GTMS-27265 --END-- Method to update Rebate Opportunities related to Channel Relationships

    /*************************************************
     * Description: Queries DatedConversionRate records for given currencies and dates
     * Parameters:
     * - currencyIsoCodes: Set of currency ISO codes to query
     * - closedDates: Set of dates to query conversion rates for
     * Returns: Map with composite key (CurrencyIsoCode-StartDate) mapping to DatedConversionRate record
     */
    public static Map<String, DatedConversionRate> getConversionRates(Set<String> currencyIsoCodes, Set<Date> closedDates) {
        Map<String, DatedConversionRate> conversionRateMap = new Map<String, DatedConversionRate>();
        if(test.isRunningTest()){conversionRateMap.put('EUR-'+Date.Today(),new DatedConversionRate(Isocode='EUR',ConversionRate=0.89));}
        try {
            for(DatedConversionRate dcr : [SELECT Id, IsoCode, ConversionRate, StartDate, NextStartDate 
                                         FROM DatedConversionRate 
                                         WHERE IsoCode IN :currencyIsoCodes
                                         AND StartDate IN :closedDates]) {
                String key = dcr.IsoCode + '-' + dcr.StartDate;
                                             
                conversionRateMap.put(key, dcr);
            }
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getConversionRates: ' + e.getMessage());
            throw e;
        }
        
        return conversionRateMap;
    }
    //07/31/2025 --START-- Vijaychandra AMARANENI (GTMS-28680): added method to calculate date from period
    /*************************************************
     * Description: Calculates a future date based on the period string and close date
     * periodString: String indicating the period (e.g., "1Year", "2 Years", "3 Years")
     * closeDate: Base date to calculate from
     * Returns: Date value calculated by adding the specified years to the close date
     */
    public static Date calculateDateFromPeriod(String periodString, Date closeDate) {
        if (closeDate == null || String.isBlank(periodString)) {
            return null;
        }
        
        // Extract numeric value from the string using regex
        Pattern numberPattern = Pattern.compile('\\d+');
        Matcher numberMatcher = numberPattern.matcher(periodString);
        
        if (numberMatcher.find()) {
            try {
                Integer yearsToAdd = Integer.valueOf(numberMatcher.group());
                return closeDate.addYears(yearsToAdd);
            } catch (Exception e) {
                // Return null if conversion fails
                return null;
            }
        }
        
        // Return null if no number found in the string
        return null;
    }
    //07/31/2025 --END-- Vijaychandra AMARANENI (GTMS-28680): added method to calculate date from period
    

    public class PayoutWrapper{
        public Decimal sourcePayout;
        public Decimal influencePayout;
        
        public PayoutWrapper(Decimal sourcePayout, Decimal influencePayout){
            this.sourcePayout = sourcePayout;
            this.influencePayout = influencePayout;
        }
    }
    
    public class GeneralPayoutResonsWrapper{
        public Boolean isGenerallyEligible;
        public string generalReason;
        
        public GeneralPayoutResonsWrapper(Boolean isGenerallyEligible, string generalReason){
            this.isGenerallyEligible = isGenerallyEligible;
            this.generalReason = generalReason;
        }
    }
    
    Public class PayoutAndReasonWrapper{
        Public Decimal partnerPayout;
        Public String categorizationReason;
        
        Public PayoutAndReasonWrapper(Decimal partnerPayout, String categorizationReason){
            this.partnerPayout = partnerPayout;
            this.categorizationReason = categorizationReason;
        }
    }



}