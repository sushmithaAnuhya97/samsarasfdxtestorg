/**
 * Author: Vigneshwaran D
 * Date: 8 May 2025
 * Team: Sales-Execution-Smart-Workflows-GTMS
 * Purpose: Update Deal_Health__c field on Quote -> Deal Health Score Quartile Color from CRMA
 * Jira: GTMS-27488, GTMS-27491
 * Test Class : CRMA_DHSFlowInvokerTest, CRMA_TestDataUtility, CRMA_WaveAnalyticsMock
 *
 * Description:
 * Service class for handling Discount Health Score (DHS) calculations and analysis.
 * Provides methods for analyzing quotes, generating Wave Analytics queries, and updating Deal_Health__c.
 * Handles error logging and returns default values on error to maintain application flow.
 */
public inherited sharing class CRMA_DHSService {
    /**
     * Inner class representing the analysis results for a quote
     * Contains all relevant fields needed for DHS calculation
     */
    public class QuoteAnalysis {
        public String quoteId { get; set; }
        public String quoteName { get; set; }
        public String accountName { get; set; }
        public String dealHealthValue { get; set; }
        public Decimal totalAmount { get; set; }
        public String productImportance { get; set; }
        public String licenseTerm { get; set; }
        public String renewalFlag { get; set; }
        public String industryBucket { get; set; }
        public String region { get; set; }
        public String revenueBand { get; set; }
        public String oneTimeDiscount { get; set; }
        public String paymentType { get; set; }
        public Decimal blendedDiscountSum { get; set; }
    }
    
    /**
     * Analyzes a quote and returns the DHS analysis results
     * @param quoteId The ID of the quote to analyze
     * @return QuoteAnalysis containing analysis results, null on error
     */
    public static QuoteAnalysis getQuoteAnalysis(String quoteId) {
            // Get quote data with optimized field selection
            SBQQ__Quote__c quote = getQuoteData(quoteId);
            if (quote == null) {
                System.debug(LoggingLevel.ERROR, 'Quote not found: ' + quoteId);
                return null;
            }
            
            // Get quote line items with optimized field selection
            List<SBQQ__QuoteLine__c> lineItems = getQuoteLineItems(quoteId);
            
            // Calculate product totals
            Map<String, Decimal> productTotals = calculateProductTotals(lineItems);
            
            // Create analysis record
            QuoteAnalysis analysis = new QuoteAnalysis();
            analysis.quoteId = quote.Id;
            analysis.quoteName = quote.Name;
            analysis.accountName = quote.SBQQ__Account__r.Name;
        	analysis.dealHealthValue = quote.Deal_Health__c;
            analysis.totalAmount = productTotals.get(CRMA_DHSConstants.TOTAL_ANNUAL_NET);
            analysis.productImportance = determineProductImportance(productTotals);
            analysis.licenseTerm = determineLicenseTerm(quote.License_Term__c);
            analysis.renewalFlag = determineRenewalFlag(quote.First_Purchase__c, quote.Renewal__c);
            analysis.industryBucket = determineIndustryBucket(quote.SBQQ__Account__r.Industry);
            analysis.region = determineRegion(quote.SBQQ__Account__r.Global_Geography__c);
            analysis.revenueBand = determineRevenueBand(quote.First_Purchase__c, quote.Quote_ACV_USD__c, quote.SBQQ__Account__r.Total_parent_child_ARR__c);
            analysis.oneTimeDiscount = determineOneTimeDiscount(quote.Subsidy_Amount__c, quote.Buyout_Amount__c);
            analysis.paymentType = determinePaymentType(quote.Selected_Payment_Type__c);
            analysis.blendedDiscountSum = quote.Blended_Discount__c;
            
            return analysis;
    }

    /**
     * Gets quote data with optimized field selection
     * @param quoteId The ID of the quote
     * @return SBQQ__Quote__c object or null if not found
     */
    private static SBQQ__Quote__c getQuoteData(String quoteId) {
            List<SBQQ__Quote__c> quotes = [
                SELECT Id, Name, 
                       SBQQ__Account__r.Name, 
                       SBQQ__Account__r.Industry, 
                       SBQQ__Account__r.Global_Geography__c,
                       SBQQ__Account__r.Total_parent_child_ARR__c,
                       License_Term__c, 
                       First_Purchase__c, 
                       Renewal__c,
                	   Deal_Health__c,
                       Subsidy_Amount__c, 
                       Buyout_Amount__c, 
                       Selected_Payment_Type__c,
                       Blended_Discount__c, 
                       Quote_ACV_USD__c
                FROM SBQQ__Quote__c 
                WHERE Id = :quoteId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            return quotes.isEmpty() ? null : quotes[0];
    }

    /**
     * Gets quote line items with optimized field selection
     * @param quoteId The ID of the quote
     * @return List of SBQQ__QuoteLine__c objects
     */
    private static List<SBQQ__QuoteLine__c> getQuoteLineItems(String quoteId) {
            return [
                SELECT Annual_Net_Total__c,
                       SBQQ__Product__r.ProductCode,
                SBQQ__Product__r.Product_Tag__c,
                       SBQQ__Product__r.License_Tier__c
                FROM SBQQ__QuoteLine__c 
                WHERE SBQQ__Quote__c = :quoteId
                WITH SECURITY_ENFORCED
            ];
        
    }

    /**
     * Calculates product totals from line items
     * @param lineItems List of quote line items
     * @return Map containing calculated totals
     */
    private static Map<String, Decimal> calculateProductTotals(List<SBQQ__QuoteLine__c> lineItems) {
        Map<String, Decimal> totals = new Map<String, Decimal>{
            CRMA_DHSConstants.TOTAL_CM1 => 0,
            CRMA_DHSConstants.TOTAL_CM2 => 0,
            CRMA_DHSConstants.TOTAL_VG => 0,
            CRMA_DHSConstants.TOTAL_LEGACY => 0,
            CRMA_DHSConstants.TOTAL_HIGH => 0,
            CRMA_DHSConstants.TOTAL_LOW => 0,
            CRMA_DHSConstants.TOTAL_ANNUAL_NET => 0
        };
        for (SBQQ__QuoteLine__c item : lineItems) {
            Decimal lineTotal = item.Annual_Net_Total__c != null ? item.Annual_Net_Total__c : 0;
            totals.put(CRMA_DHSConstants.TOTAL_ANNUAL_NET, 
                      totals.get(CRMA_DHSConstants.TOTAL_ANNUAL_NET) + lineTotal);
            String productCode = item.SBQQ__Product__r.Product_Tag__c;
            if (productCode != null) {
                if (productCode.equalsIgnoreCase(CRMA_DHSConstants.PRODUCT_TAG_VG)) {
                    totals.put(CRMA_DHSConstants.TOTAL_VG, 
                             totals.get(CRMA_DHSConstants.TOTAL_VG) + lineTotal);
                } else if (productCode.equalsIgnoreCase(CRMA_DHSConstants.PRODUCT_TAG_CM1)) {
                    totals.put(CRMA_DHSConstants.TOTAL_CM1, 
                             totals.get(CRMA_DHSConstants.TOTAL_CM1) + lineTotal);
                } else if (productCode.equalsIgnoreCase(CRMA_DHSConstants.PRODUCT_TAG_CM2)) {
                    totals.put(CRMA_DHSConstants.TOTAL_CM2, 
                             totals.get(CRMA_DHSConstants.TOTAL_CM2) + lineTotal);
                }
            }
            String licenseTier = item.SBQQ__Product__r.License_Tier__c;
            if (licenseTier == CRMA_DHSConstants.LICENSE_TIER_LEGACY) {
                totals.put(CRMA_DHSConstants.TOTAL_LEGACY, 
                         totals.get(CRMA_DHSConstants.TOTAL_LEGACY) + lineTotal);
            } else if (licenseTier == CRMA_DHSConstants.LICENSE_TIER_HIGH) {
                totals.put(CRMA_DHSConstants.TOTAL_HIGH, 
                         totals.get(CRMA_DHSConstants.TOTAL_HIGH) + lineTotal);
            } else if (licenseTier == CRMA_DHSConstants.LICENSE_TIER_LOW) {
                totals.put(CRMA_DHSConstants.TOTAL_LOW, 
                         totals.get(CRMA_DHSConstants.TOTAL_LOW) + lineTotal);
            }
        }
        return totals;
    }

    /**
     * Determines product importance based on calculated totals
     * @param totals Map containing product totals
     * @return String representing product importance
     */
    public static String determineProductImportance(Map<String, Decimal> totals) {
        system.debug('*** totals ****');
        system.debug(totals);
        Map<String, Object> config = CRMA_ConfigUtility.getAllConfig();
        String productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_MIXED;
        Decimal annualNetTotal = totals.get(CRMA_DHSConstants.TOTAL_ANNUAL_NET);
        if (annualNetTotal > 0) {
            Decimal cm1Ratio = totals.containsKey(CRMA_DHSConstants.TOTAL_CM1) && totals.get(CRMA_DHSConstants.TOTAL_CM1) != null ? totals.get(CRMA_DHSConstants.TOTAL_CM1)/annualNetTotal : 0;
            Decimal cm2Ratio = totals.containsKey(CRMA_DHSConstants.TOTAL_CM2) && totals.get(CRMA_DHSConstants.TOTAL_CM2) != null ? totals.get(CRMA_DHSConstants.TOTAL_CM2)/annualNetTotal : 0;
            Decimal vgRatio = totals.containsKey(CRMA_DHSConstants.TOTAL_VG) && totals.get(CRMA_DHSConstants.TOTAL_VG) != null ? totals.get(CRMA_DHSConstants.TOTAL_VG)/annualNetTotal : 0;
            Decimal highRatio = totals.containsKey(CRMA_DHSConstants.TOTAL_HIGH) && totals.get(CRMA_DHSConstants.TOTAL_HIGH) != null ? totals.get(CRMA_DHSConstants.TOTAL_HIGH)/annualNetTotal : 0;
            Decimal lowRatio = totals.containsKey(CRMA_DHSConstants.TOTAL_LOW) && totals.get(CRMA_DHSConstants.TOTAL_LOW) != null ? totals.get(CRMA_DHSConstants.TOTAL_LOW)/annualNetTotal : 0;
            Decimal legacyTotal = totals.containsKey(CRMA_DHSConstants.TOTAL_LEGACY) && totals.get(CRMA_DHSConstants.TOTAL_LEGACY) != null ? totals.get(CRMA_DHSConstants.TOTAL_LEGACY) : 0;
            Decimal dominanceThreshold = (Decimal)config.get('PRODUCT_DOMINANCE_THRESHOLD');
            if (cm1Ratio >= dominanceThreshold) {
                if (legacyTotal > 0) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM1_LEGACY;
                } else if (highRatio >= dominanceThreshold) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM1_HIGH;
                } else if (lowRatio >= dominanceThreshold) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM1_LOW;
                } else {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM1_MIXED;
                }
            } else if (cm2Ratio >= dominanceThreshold) {
                if (legacyTotal > 0) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM2_LEGACY;
                } else if (highRatio >= dominanceThreshold) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM2_HIGH;
                } else if (lowRatio >= dominanceThreshold) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM2_LOW;
                } else {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_CM2_MIXED;
                }
            } else if (vgRatio >= dominanceThreshold) {
                if (legacyTotal > 0) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_VG_LEGACY;
                } else if (highRatio >= dominanceThreshold) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_VG_HIGH;
                } else if (lowRatio >= dominanceThreshold) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_VG_LOW;
                } else {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_VG_MIXED;
                }
            } else {
                if (legacyTotal > 0) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_MIXED_LEGACY;
                } else if (highRatio >= dominanceThreshold) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_MIXED_HIGH;
                } else if (lowRatio >= dominanceThreshold) {
                    productImportance = CRMA_DHSConstants.PRODUCT_IMPORTANCE_MIXED_LOW;
                }
            }
        }
        return productImportance;
    }

    /**
     * Determines license term based on term months
     * @param licenseTerm License term in months
     * @return String representing license term bucket
     */
    public static String determineLicenseTerm(String licenseTerm) {
        Map<String, Object> config = CRMA_ConfigUtility.getAllConfig();
        if (licenseTerm == null) {
            return (String)config.get('LICENSE_TERM_UNKNOWN');
        }
        Decimal termMonths = Decimal.valueOf(licenseTerm);
        Decimal threshold = (Decimal)config.get('LICENSE_TERM_THRESHOLD');
        return (termMonths <= threshold) ? 
            (String)config.get('LICENSE_TERM_LEQ_3_YEARS') : (String)config.get('LICENSE_TERM_GT_3_YEARS');
    }

    /**
     * Determines renewal flag based on first purchase and renewal flags
     * @param firstPurchase First purchase flag
     * @param renewal Renewal flag
     * @return String representing renewal flag
     */
    public static String determineRenewalFlag(Boolean firstPurchase, Boolean renewal) {
        return firstPurchase ? CRMA_DHSConstants.RENEWAL_FLAG_FIRST_PURCHASE : 
            renewal ? CRMA_DHSConstants.RENEWAL_FLAG_RENEWALS : CRMA_DHSConstants.RENEWAL_FLAG_EXPANSION;
    }

    /**
     * Determines industry bucket based on account industry
     * @param industry Account industry
     * @return String representing industry bucket
     */
    public static String determineIndustryBucket(String industry) {
        Map<String, Object> config = CRMA_ConfigUtility.getAllConfig();
        String industryDefault = (String) config.get('INDUSTRY_DEFAULT');
        if (industry == null || !config.containsKey(industry)) {
            return industryDefault;
        }
        return (String) config.get(industry);
    }

    /**
     * Determines region based on account geography
     * @param geography Account geography
     * @return String representing region
     */
    public static String determineRegion(String geography) {
        Map<String, Object> config = CRMA_ConfigUtility.getAllConfig();
        String regionDefault = (String) config.get('REGION_DEFAULT');
        if (geography == null || !config.containsKey(geography)) {
            return regionDefault;
        }
        return (String) config.get(geography);
    }

    /**
     * Determines revenue band based on first purchase and revenue
     * @param firstPurchase First purchase flag
     * @param quoteACV Quote ACV
     * @param totalParentChildARR Total parent child ARR
     * @return String representing revenue band
     */
    public static String determineRevenueBand(Boolean firstPurchase, Decimal quoteACV, Decimal totalParentChildARR) {
        Map<String, Object> config = CRMA_ConfigUtility.getAllConfig();
        Decimal band1 = (Decimal) config.get('REVENUE_BAND_1_THRESHOLD');
        Decimal band3 = (Decimal) config.get('REVENUE_BAND_3_THRESHOLD');
        if (firstPurchase) {
            if (quoteACV < band1) {
                return CRMA_DHSConstants.REVENUE_BAND_1;
            } else if (quoteACV > band3) {
                return CRMA_DHSConstants.REVENUE_BAND_3;
            }
            return CRMA_DHSConstants.REVENUE_BAND_2;
        }
       	 if (totalParentChildARR == null || totalParentChildARR < band1) {
            return CRMA_DHSConstants.REVENUE_BAND_1;
        } else if (totalParentChildARR > band3) {
            return CRMA_DHSConstants.REVENUE_BAND_3;
        }
        return CRMA_DHSConstants.REVENUE_BAND_2;
    }

    /**
     * Determines one time discount based on subsidy and buyout amounts
     * @param subsidyAmount Subsidy amount
     * @param buyoutAmount Buyout amount
     * @return String representing one time discount
     */
    private static String determineOneTimeDiscount(Decimal subsidyAmount, Decimal buyoutAmount) {
        return (subsidyAmount > 0 || buyoutAmount > 0) ? 
            CRMA_DHSConstants.OTD_INCLUDE : CRMA_DHSConstants.OTD_EXCLUDE;
    }

    /**
     * Determines payment type
     * @param selectedPaymentType Selected payment type
     * @return String representing payment type
     */
    private static String determinePaymentType(String selectedPaymentType) {
        return String.isBlank(selectedPaymentType) ? 
            CRMA_DHSConstants.PAYMENT_TYPE_NOT_SELECTED : selectedPaymentType;
    }

    /**
     * Generates and executes a Wave Analytics query based on quote analysis
     * @param analysis The QuoteAnalysis object containing all required parameters
     * @return WaveResponse containing the Wave query results
     */
    public static CRMA_DHSWaveService.WaveResponse getWaveQueryResult(QuoteAnalysis analysis) {
            // Get dataset ID dynamically
            String datasetId = CRMA_DHSWaveService.getWaveDatasetId();
            if (datasetId == null) {
                CRMA_DHSWaveService.WaveResponse response = new CRMA_DHSWaveService.WaveResponse();
                response.error = 'Failed to get dataset ID';
                createLogger(analysis.quoteId,'Failed to get dataset ID',String.valueOf(analysis),String.valueOf(response), true);
                return response;
            }

            // Get query template from metadata config map
            String queryTemplate = (String)CRMA_ConfigUtility.getAllConfig().get('Query');
            if (String.isBlank(queryTemplate)) {
                CRMA_DHSWaveService.WaveResponse response = new CRMA_DHSWaveService.WaveResponse();
                response.error = 'Query template not found in metadata';
                createLogger(analysis.quoteId,'Query template not found in metadata',String.valueOf(analysis),String.valueOf(response), true);
                return response;
            }

            // Replace placeholders in the template
            String saqlQuery = queryTemplate
                .replace('{DATASET_ID}', datasetId)
                .replace('{LICENSE_TERM}', analysis.licenseTerm)
                .replace('{PRODUCT_IMPORTANCE}', analysis.productImportance)
                .replace('{RENEWAL_FLAG}', analysis.renewalFlag)
                .replace('{INDUSTRY}', analysis.industryBucket)
                .replace('{REGION}', analysis.region)
                .replace('{REVENUE_BAND}', analysis.revenueBand)
                .replace('{OTD}', analysis.oneTimeDiscount)
                .replace('{PAYMENT_TYPE}', analysis.paymentType)
                .replace('{BLENDED_DISCOUNT}', String.valueOf(analysis.blendedDiscountSum));

            return CRMA_DHSWaveService.getWaveQueryResult(saqlQuery);
    }


    /**
     * Analyzes which quartile a blended discount falls into based on Wave query results
     * @param blendedDiscount The blended discount value to analyze
     * @param waveResponse The Wave query response containing quartile ranges
     * @return Map containing the analysis results with keys: range, score, quartile
     */
    public static Map<String, Object> analyzeBlendedDiscountQuartile(String quoteId,Decimal blendedDiscount, 
                                                                   CRMA_DHSWaveService.WaveResponse waveResponse) {
        Map<String, Object> result = new Map<String, Object>{
            CRMA_DHSConstants.ANALYSIS_BLENDED_DISCOUNT => blendedDiscount,
            CRMA_DHSConstants.ANALYSIS_RANGE => null,
            CRMA_DHSConstants.ANALYSIS_SCORE => null,
            CRMA_DHSConstants.ANALYSIS_QUARTILE => null,
            CRMA_DHSConstants.ANALYSIS_ERROR => null
        };
        
        // If blendedDiscount is negative, treat as zero for range comparison
        Decimal discountForRange = blendedDiscount < 0 ? 0 : blendedDiscount;
        
        if (waveResponse == null || waveResponse.error != null) {
            result.put(CRMA_DHSConstants.ANALYSIS_ERROR,'Invalid Wave response: ' + (waveResponse?.error ?? 'null response'));
            createLogger(quoteId,'Invalid Wave response',String.valueOf(blendedDiscount),String.valueOf(waveResponse), true);
                return result;
            }
            
            if (waveResponse.discountRanges == null || waveResponse.discountRanges.isEmpty()) {
                result.put(CRMA_DHSConstants.ANALYSIS_ERROR, 'No discount ranges found in Wave response');
            createLogger(quoteId,'No discount ranges found in Wave response',String.valueOf(blendedDiscount),String.valueOf(waveResponse),true);
                return result;
            }
            
            for (CRMA_DHSWaveService.DiscountRange range : waveResponse.discountRanges) {
                if (range.range == null || !range.range.contains('-')) {
                    continue;
                }
                
                String[] rangeParts = range.range.split('-');
                if (rangeParts.size() != 2) {
                    continue;
                }
                
                String minStr = rangeParts[0].trim().removeEnd('%').trim();
                String maxStr = rangeParts[1].trim().removeEnd('%').trim();
                
            // Sanitize minStr and maxStr to remove non-numeric characters except dot and minus
            minStr = minStr.replaceAll('[^0-9.-]', '');
            maxStr = maxStr.replaceAll('[^0-9.-]', '');
                Decimal minValue = 0;
                Decimal maxValue = 100;
                
                if (minStr != '') {
                    minValue = Decimal.valueOf(minStr);
                }
                if (maxStr != '') {
                    maxValue = Decimal.valueOf(maxStr);
                }
                
                // Check if blended discount falls within this range
            if (discountForRange >= minValue && discountForRange <= maxValue) {
                result.put(CRMA_DHSConstants.ANALYSIS_RANGE, range.range);
                result.put(CRMA_DHSConstants.ANALYSIS_SCORE, range.score);
                result.put(CRMA_DHSConstants.ANALYSIS_QUARTILE, range.quartile);
                createLogger(quoteId,'Success : Blended discount falls within this range',String.valueOf(discountForRange),String.valueOf(range), true);

                    return result;
                }
            }
            
            // If no range was found, check if it's above the highest range
            CRMA_DHSWaveService.DiscountRange lastRange = waveResponse.discountRanges[waveResponse.discountRanges.size() - 1];
            if (lastRange.range != null && lastRange.range.contains('+')) {
            String minStr = lastRange.range;
            // If there is a dash, split and take the first part
            if (minStr.contains('-')) {
                minStr = minStr.split('-')[0];
            }
            minStr = minStr.trim().removeEnd('%').trim();
            // Sanitize minStr for lastRange as well
            minStr = minStr.replaceAll('[^0-9.-]', '');
            Decimal minValue = Decimal.valueOf(minStr);
            
            if (discountForRange > minValue) {
                result.put(CRMA_DHSConstants.ANALYSIS_RANGE, lastRange.range);
                result.put(CRMA_DHSConstants.ANALYSIS_SCORE, lastRange.score);
                result.put(CRMA_DHSConstants.ANALYSIS_QUARTILE, lastRange.quartile);
                createLogger(quoteId,'No range was found, check if its above the highest range',String.valueOf(discountForRange),String.valueOf(lastRange), true);
                return result;
            }
        }
        result.put(CRMA_DHSConstants.ANALYSIS_ERROR,'No matching range found for blended discount: ' + blendedDiscount);
        createLogger(quoteId,'No matching range found for blended discount',String.valueOf(blendedDiscount),String.valueOf(waveResponse),true);
        return result;
    }

    /**
     * Updates the Deal_Health__c field on a given SBQQ__Quote__c record while bypassing CPQ triggers.
     * @param quoteId The ID of the quote to update
     * @param dealHealthValue The new value for Deal_Health__c
     * @return Boolean indicating success or failure
     */
    public static void updateDealHealthBypassingCPQTriggers(String quoteId, String dealHealthValue) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Id = quoteId;
        quote.Deal_Health__c = dealHealthValue;
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        SBQQ.TriggerControl.disable();
        update quote;
        SBQQ.TriggerControl.enable();
    }
    
    

    /**
     * Runs DHS analysis, gets Wave query result, analyzes quartile, and updates Deal_Health__c for the given quote.
     * @param quoteId The ID of the quote to process
     * @return The quartile color (score) that was set, or null if error
     */
    public static String processAndUpdateDealHealth(String quoteId) {
        try {
            
            
            // Get config once
            Map<String, Object> config = CRMA_ConfigUtility.getAllConfig();
            // Check for DHS_ApprovalToggle config and Active__c , config json value will be DHSApproval_Active
            Object activeToggle = config.get('DHSApproval_Active');

            if(!FeatureManagement.checkPermission('DHS_Approval')){
                createLogger(quoteId,'Current user dont have custom permission for DHS Approval',null,null, true);
                updateDealHealthBypassingCPQTriggers(quoteId,'');
                return 'Current user dont have custom permission for DHS Approval';
            }
            
            if (activeToggle == null || activeToggle == false ||  String.valueOf(activeToggle).toLowerCase() != 'true') {
                    String errorMessage = 'DHS Approval Feature Inactive - CRMA Config Metadata or User dont have access for this feature';
                    createLogger(quoteId,errorMessage,null,null,true);
                	updateDealHealthBypassingCPQTriggers(quoteId,'');
                    return 'DHS Approval Inactive - CRMA Config Metadata';
                }
             
            //Get QuoteDetails
            QuoteAnalysis analysis = getQuoteAnalysis(quoteId);
            
            
            // 1. Analyze the quote
            if (analysis == null) {
                createLogger(quoteId,'DHS analysis failed for quote',null,null,true);
                updateDealHealthBypassingCPQTriggers(quoteId,'');
                return null;
            }
            
            // 2. Payment type check
            if(!CRMA_DHSConstants.SELECTED_PAYMENT_TYPE.contains(analysis.paymentType)){
                createLogger(quoteId,'Payment type '+analysis.paymentType+' not applicable.',String.valueOf(analysis),null,true);
                updateDealHealthBypassingCPQTriggers(quoteId,'');
                return null;
            }
            
            // 3. Get Wave query result
            CRMA_DHSWaveService.WaveResponse waveResponse = getWaveQueryResult(analysis);
            if (waveResponse == null || waveResponse.error != null) {
                createLogger(quoteId,'Wave query response for quote has issues.',String.valueOf(analysis),String.valueOf(waveResponse),true);
                updateDealHealthBypassingCPQTriggers(quoteId,'');
                return null;
            }
            // 4. Analyze quartile
            Map<String, Object> quartileResult = analyzeBlendedDiscountQuartile(quoteId,analysis.blendedDiscountSum, waveResponse);
            String quartileColor = (String) quartileResult.get(CRMA_DHSConstants.ANALYSIS_SCORE);
            if (String.isBlank(quartileColor)) {
                createLogger(quoteId,'Quartile color not found for quote',String.valueOf(analysis),String.valueOf(waveResponse),true);
                updateDealHealthBypassingCPQTriggers(quoteId,'');
                return null;
            }
            // Only use the color part (e.g., 'Green' from '1.Green')
            if (quartileColor != null && quartileColor.contains('.')) {
                quartileColor = quartileColor.split('\\.')[1];
            }
            
            // 5. Update Deal_Health__c
      		updateDealHealthBypassingCPQTriggers(quoteId, quartileColor);
            
            return quartileColor;
        } catch (Exception e) {
            createLogger(quoteId,'Error in processAndUpdateDealHealth: ' + e.getMessage() + '\n' + e.getStackTraceString(),null,null,false);
            updateDealHealthBypassingCPQTriggers(quoteId,'');

            return null;
        }
    }
    
    public static void createLogger(String quoteId,String errorMessage,String Request, String Response,boolean isSuccess)
    {
        	
            if(Request != null){
                errorMessage = errorMessage != null ? errorMessage + '; Request : '+Request : 'Request : '+Request;
            }
        
        	if(Response != null){
                errorMessage = errorMessage != null ? errorMessage + '; Response : '+Response : 'Response : '+Response;
            }
        
            if(isSuccess){
    			LOGGER.atInfo().setCLassName('CRMA_DHSService').setRecordId(quoteId).setExceptionOrMessage(errorMessage);                         
            }
        	else{
                LOGGER.atError().setCLassName('CRMA_DHSService').setRecordId(quoteId).setExceptionOrMessage(errorMessage);
            }
        
        	Logger.setFunctionalityType('DHS_Updation'); 
            Logger.setRecordId(quoteId);
            Logger.insertMasterLogs();  

    }
}