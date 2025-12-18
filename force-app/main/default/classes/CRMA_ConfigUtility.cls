/**
 * Author: Vigneshwaran D
 * Date: 8 May 2025
 * Team: Sales-Execution-Smart-Workflows-GTMS
 * Purpose: Update Deal_Health__c field on Quote -> Deal Health Score Quartile Color from CRMA
 * Jira: GTMS-27488, GTMS-27491
 * Test Class : CRMA_DHSFlowInvokerTest, CRMA_TestDataUtility, CRMA_WaveAnalyticsMock
 *
 * Description:
 * Utility class for loading and accessing JSON-based configuration from CRMA_Configurations__mdt custom metadata.
 * - Loads all config records once per transaction and caches them in-memory for efficient access.
 * - Provides a method to retrieve a config map by its config type key.
 * - Returns null if the config type is not found.
 *
 * Usage:
 *   Map<String, Object> thresholds = CRMA_ConfigUtility.getConfig('DHS_Thresholds');
 *   Decimal dominanceThreshold = (Decimal) thresholds.get('PRODUCT_DOMINANCE_THRESHOLD');
 */
public inherited sharing class CRMA_ConfigUtility {
    // In-memory cache for all config key-value pairs
    private static Map<String, Object> allConfig;

    /**
     * Loads all config records from CRMA_Configurations__mdt with DHS_ prefix into a single flat map (if not already loaded).
     * This ensures only one SOQL query and one JSON parse per transaction.
     */
    private static void loadAllConfigs() {
        if (allConfig == null) {
            allConfig = new Map<String, Object>();
            for (CRMA_Configurations__mdt rec : [
                SELECT Config_Type__c, Config_JSON__c FROM CRMA_Configurations__mdt
                WHERE Config_Type__c LIKE 'DHS_%'
            ]) {
                if (String.isNotBlank(rec.Config_JSON__c)) {
                    Map<String, Object> section = (Map<String, Object>) JSON.deserializeUntyped(rec.Config_JSON__c);
                    for (String key : section.keySet()) {
                        allConfig.put(key, section.get(key));
                    }
                }
            }
        }
    }

    /**
     * Retrieves the flat config map containing all DHS_ config key-value pairs.
     * @return Map<String, Object> of all config values
     */
    public static Map<String, Object> getAllConfig() {
        loadAllConfigs();
        return allConfig;
    }
}