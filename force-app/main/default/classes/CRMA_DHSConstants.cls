/**
 * Author: Vigneshwaran D
 * Date: 8 May 2025
 * Team: Sales-Execution-Smart-Workflows-GTMS
 * Purpose: Update Deal_Health__c field on Quote -> Deal Health Score Quartile Color from CRMA
 * Jira: GTMS-27488, GTMS-27491
 * Test Class : CRMA_DHSFlowInvokerTest, CRMA_TestDataUtility, CRMA_WaveAnalyticsMock
 *
 * Description:
 * Constants class for Discount Health Score (DHS) calculations and CRMA integration.
 * Contains technical, field, and integration constants. All business-configurable values are stored in metadata and accessed via CRMA_ConfigUtility.
 * Used for typo-safety, field references, and integration endpoints.
 *
 * Section breakdown:
 *   1. Wave Analytics Field Name Constants: Used in SAQL queries and for mapping fields.
 *   2. Wave Analytics Response Field Constants: Used to parse and extract data from API responses.
 *   3. HTTP and Cache Constants: Used for API callouts and caching logic.
 *   4. Wave Analytics API Endpoint Constants: Used to construct API endpoint URLs.
 *   5. License Tier Constants: Direct license tier values for product analysis.
 *   6. One Time Discount Constants: Direct OTD mapping values.
 *   7. Payment Type Constants: Direct payment type values.
 *   8. Product Code Constants: Direct product code values for categorization.
 *   9. Product Importance Constants: Direct product importance mapping values.
 *   10. Renewal Flag Constants: Direct renewal flag values.
 *   11. Revenue Band Constants: Direct revenue band values.
 * ---------------------------------------------------------------------------
 */
public inherited sharing class CRMA_DHSConstants {

    // -------------------------------------------------------------------------
    // 1. Wave Analytics Field Name Constants
    //    These constants are used to reference fields in Wave Analytics (CRMA)
    //    queries and responses. They ensure field names are typo-safe and
    //    consistent across the codebase.
    // -------------------------------------------------------------------------
    public static final String WAVE_FIELD_LICENSE_TERM_BUCKETS   = 'License_Term_Buckets';
    public static final String WAVE_FIELD_PRODUCT_IMPORTANCE     = 'Product_Importance_Tagging';
    public static final String WAVE_FIELD_RENEWAL_FLAG           = 'Renewal_Flag_CoE';
    public static final String WAVE_FIELD_INDUSTRY               = 'Industry_Tagging_CoE';
    public static final String WAVE_FIELD_REGION                 = 'Region_Tagging_CoE';
    public static final String WAVE_FIELD_REVENUE_BAND           = 'Revenue_Band';
    public static final String WAVE_FIELD_OTD_MAPPING            = 'One_Time_Discount_Mapping';
    public static final String WAVE_FIELD_PAYMENT_TYPE           = 'Selected_Payment_Type';
    public static final String WAVE_FIELD_BLENDED_DISCOUNT       = 'Blended_Discount_Sum';

    // -------------------------------------------------------------------------
    // 2. Wave Analytics Response Field Constants
    //    These constants are used to parse and extract data from Wave Analytics
    //    API responses, ensuring typo-safety and consistency.
    // -------------------------------------------------------------------------
    public static final String WAVE_RESPONSE_DATASETS            = 'datasets';
    public static final String WAVE_RESPONSE_ID                  = 'id';
    public static final String WAVE_RESPONSE_NAME                = 'name';
    public static final String WAVE_RESPONSE_CURRENT_VERSION     = 'currentVersionId';
    public static final String WAVE_RESPONSE_RESULTS             = 'results';
    public static final String WAVE_RESPONSE_RECORDS             = 'records';
    public static final String WAVE_RESPONSE_SCORE               = 'Score';
    public static final String WAVE_RESPONSE_TEXTSCORE           = 'textscore';
    public static final String WAVE_RESPONSE_QUARTILE            = 'Quartile';
    public static final String WAVE_RESPONSE_QUERY               = 'query';
    public static final String WAVE_RESPONSE_TIME                = 'responseTime';

    // -------------------------------------------------------------------------
    // 3. HTTP and Cache Constants
    //    These constants are used for making HTTP callouts to the Wave Analytics
    //    API and for caching dataset IDs and other values.
    // -------------------------------------------------------------------------
    public static final String HTTP_HEADER_AUTHORIZATION         = 'Authorization';
    public static final String HTTP_HEADER_CONTENT_TYPE          = 'Content-Type';
    public static final String HTTP_CONTENT_TYPE_JSON            = 'application/json';
    public static final String HTTP_AUTH_BEARER                  = 'Bearer ';
    public static final Set<Integer> HTTP_STATUS_SUCCESS         = new Set<Integer>{200,201};
    public static final String HTTP_REQUEST_QUERY                = 'query';

    public static final String CACHE_DHS_INPUT_DATASET_ID        = 'DHS_INPUT_DATASET_ID';
    public static final Integer CACHE_TTL_24_HOURS               = 86400; // 24 hours in seconds
    public static final String CACHE_PARTITION_NAME              = 'local.DHSCache';

    // -------------------------------------------------------------------------
    // 4. Wave Analytics API Endpoint Constants
    //    These constants are used to construct endpoint URLs for Wave Analytics
    //    API calls, ensuring versioning and path consistency.
    // -------------------------------------------------------------------------
    public static final String WAVE_QUERY_BLANK                  = '';
    public static final String WAVE_QUERY_BLANK_MARKER           = 'a';
    public static final String WAVE_API_VERSION                  = 'v62.0';
    public static final String WAVE_QUERY_ENDPOINT               = '/services/data/' + WAVE_API_VERSION + '/wave/query';
    public static final String WAVE_DATASET_ENDPOINT             = '/services/data/' + WAVE_API_VERSION + '/wave/datasets';
    public static final String WAVE_DATASET_SEPARATOR            = '/';
    
    // Analysis Result Fields
    public static final String ANALYSIS_BLENDED_DISCOUNT = 'blendedDiscount';
    public static final String ANALYSIS_RANGE = 'range';
    public static final String ANALYSIS_SCORE = 'score';
    public static final String ANALYSIS_QUARTILE = 'quartile';
    public static final String ANALYSIS_ERROR = 'error';

    // Business key constants for product totals and related fields
    public static final String TOTAL_HIGH = 'highTotal';
    public static final String TOTAL_CM1 = 'cm1Total';
    public static final String TOTAL_CM2 = 'cm2Total';
    public static final String TOTAL_VG = 'vgTotal';
    public static final String TOTAL_LEGACY = 'legacyTotal';
    public static final String TOTAL_LOW = 'lowTotal';
    public static final String TOTAL_ANNUAL_NET = 'annualNetTotal';

    // -------------------------------------------------------------------------
    // 5. License Tier Constants
    //    These constants define the license tier values used for product analysis
    // -------------------------------------------------------------------------
    public static final String LICENSE_TIER_LEGACY = 'Legacy';
    public static final String LICENSE_TIER_HIGH = 'High';
    public static final String LICENSE_TIER_LOW = 'Low';

    // -------------------------------------------------------------------------
    // 6. One Time Discount Constants
    //    These constants define the one time discount mapping values
    // -------------------------------------------------------------------------
    public static final String OTD_INCLUDE = 'Include';
    public static final String OTD_EXCLUDE = 'Exclude';

    // -------------------------------------------------------------------------
    // 7. Payment Type Constants
    //    These constants define the payment type values
    // -------------------------------------------------------------------------
    public static final String PAYMENT_TYPE_NOT_SELECTED = 'Not Selected';
    public static final Set<String> SELECTED_PAYMENT_TYPE = new Set<String>{'Direct Annual','Direct Monthly','Direct Quarterly','Direct Semi-Annual','Upfront Payments'};


    // -------------------------------------------------------------------------
    // 8. Product Code Constants
    //    These constants define the product code values for categorization
    // -------------------------------------------------------------------------
    public static final String PRODUCT_TAG_VG = 'VG';
    public static final String PRODUCT_TAG_CM1 = 'CM1';
    public static final String PRODUCT_TAG_CM2 = 'CM2';

    // -------------------------------------------------------------------------
    // 9. Product Importance Constants
    //    These constants define the product importance mapping values
    // -------------------------------------------------------------------------
    public static final String PRODUCT_IMPORTANCE_MIXED = 'Mixed - Mixed';
    public static final String PRODUCT_IMPORTANCE_CM1_LEGACY = 'CM1 dominant - Legacy';
    public static final String PRODUCT_IMPORTANCE_CM1_HIGH = 'CM1 dominant - High';
    public static final String PRODUCT_IMPORTANCE_CM1_LOW = 'CM1 dominant - Low';
    public static final String PRODUCT_IMPORTANCE_CM1_MIXED = 'CM1 dominant - Mixed';
    public static final String PRODUCT_IMPORTANCE_CM2_LEGACY = 'CM2 dominant - Legacy';
    public static final String PRODUCT_IMPORTANCE_CM2_HIGH = 'CM2 dominant - High';
    public static final String PRODUCT_IMPORTANCE_CM2_LOW = 'CM2 dominant - Low';
    public static final String PRODUCT_IMPORTANCE_CM2_MIXED = 'CM2 dominant - Mixed';
    public static final String PRODUCT_IMPORTANCE_VG_LEGACY = 'VG dominant - Legacy';
    public static final String PRODUCT_IMPORTANCE_VG_HIGH = 'VG dominant - High';
    public static final String PRODUCT_IMPORTANCE_VG_LOW = 'VG dominant - Low';
    public static final String PRODUCT_IMPORTANCE_VG_MIXED = 'VG dominant - Mixed';
    public static final String PRODUCT_IMPORTANCE_MIXED_LEGACY = 'Mixed - Legacy';
    public static final String PRODUCT_IMPORTANCE_MIXED_HIGH = 'Mixed - High';
    public static final String PRODUCT_IMPORTANCE_MIXED_LOW = 'Mixed - Low';

    // -------------------------------------------------------------------------
    // 10. Renewal Flag Constants
    //    These constants define the renewal flag values
    // -------------------------------------------------------------------------
    public static final String RENEWAL_FLAG_FIRST_PURCHASE = 'First Purchase';
    public static final String RENEWAL_FLAG_RENEWALS = 'Renewals';
    public static final String RENEWAL_FLAG_EXPANSION = 'Expansion';

    // -------------------------------------------------------------------------
    // 11. Revenue Band Constants
    //    These constants define the revenue band values
    // -------------------------------------------------------------------------
    public static final String REVENUE_BAND_1 = 'Revenue Band 1';
    public static final String REVENUE_BAND_2 = 'Revenue Band 2';
    public static final String REVENUE_BAND_3 = 'Revenue Band 3';
}