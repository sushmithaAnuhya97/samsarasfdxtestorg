/**
 * Author: Vigneshwaran D
 * Date: 8 May 2025
 * Team: Sales-Execution-Smart-Workflows-GTMS
 * Purpose: Update Deal_Health__c field on Quote -> Deal Health Score Quartile Color from CRMA
 * Jira: GTMS-27488, GTMS-27491
 * Test Class : CRMA_DHSFlowInvokerTest, CRMA_TestDataUtility, CRMA_WaveAnalyticsMock
 *
 * Description:
 * Service class for handling Wave Analytics API interactions for DHS.
 * Provides methods for executing SAQL queries, retrieving dataset IDs, and parsing responses from Wave Analytics.
 * Handles error logging and returns null or error objects on failure to maintain application flow.
 */
public inherited sharing class CRMA_DHSWaveService {
    /**
     * Wrapper class for Wave Analytics response
     */
    public class WaveResponse {
        public List<DiscountRange> discountRanges;
        public String query;
        public Integer responseTime;
        public String error;
        public String stackTrace;
        public String rawResponse;
        public WaveResponse() {
            this.discountRanges = new List<DiscountRange>();
        }
    }

    /**
     * Wrapper class for discount range data
     */
    public class DiscountRange {
        public String range;
        public String score;
        public Decimal quartile;
        public DiscountRange(String range, String score, Decimal quartile) {
            this.range = range;
            this.score = score;
            this.quartile = quartile;
        }
    }

    /**
     * Common method for making Wave API callouts
     * @param endpoint The API endpoint to call
     * @param method The HTTP method (GET, POST, etc.)
     * @param body The request body for POST requests (optional)
     * @return HttpResponse from the API call
     */
    public static HttpResponse doWaveCallout(String endpoint, String method, String body) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:CRMA_API' + endpoint);
            req.setMethod(method);
            req.setHeader(CRMA_DHSConstants.HTTP_HEADER_CONTENT_TYPE, 
                          CRMA_DHSConstants.HTTP_CONTENT_TYPE_JSON);
            if (body != null) {
                req.setBody(body);
            }
            Http http = new Http();
            return http.send(req);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in doWaveCallout: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Gets the Wave dataset ID, first checking the cache and then fetching from the API if not found.
     * @return String The dataset ID in format 'datasetId/versionId' or null if not found
     */
    public static String getWaveDatasetId() {
        String datasetId = (String) Cache.Org.get('local.CRMA.DHSDataset');
        if (datasetId == null) {
            datasetId = fetchWaveDatasetId();
            if (datasetId != null) {
                Cache.Org.put('local.CRMA.DHSDataset', datasetId);
            }
        }
        return datasetId;
    }

    /**
     * Fetches the dataset ID from Wave API (no caching), supports pagination if nextPageUrl is present
     * @return String The dataset ID in format 'datasetId/versionId' or null if not found
     */
    public static String fetchWaveDatasetId() {
        Map<String, Object> config = CRMA_ConfigUtility.getAllConfig();
        String datasetName = (String)config.get('WAVE_DATASET_NAME');
        String endpoint = CRMA_DHSConstants.WAVE_DATASET_ENDPOINT;
        while (endpoint != null) {
            try {
                HttpResponse res = doWaveCallout(endpoint, 'GET', null);
                if (res != null && CRMA_DHSConstants.HTTP_STATUS_SUCCESS.contains(res.getStatusCode()) ) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    List<Object> datasets = (List<Object>) responseMap.get(CRMA_DHSConstants.WAVE_RESPONSE_DATASETS);
                    for (Object dataset : datasets) {
                        Map<String, Object> datasetMap = (Map<String, Object>) dataset;
                        if (datasetName.equals(datasetMap.get(CRMA_DHSConstants.WAVE_RESPONSE_NAME))) {
                            String id = (String) datasetMap.get(CRMA_DHSConstants.WAVE_RESPONSE_ID);
                            String currentVersionId = (String) datasetMap.get(CRMA_DHSConstants.WAVE_RESPONSE_CURRENT_VERSION);
                            return id + CRMA_DHSConstants.WAVE_DATASET_SEPARATOR + currentVersionId;
                        }
                    }
                    // Check for nextPageUrl
                    if (responseMap.containsKey('nextPageUrl') && responseMap.get('nextPageUrl') != null) {
                        endpoint = (String) responseMap.get('nextPageUrl');
                    } else {
                        endpoint = null;
                    }
                } else {
                    return null;
                }
            } catch (Exception e) {
                return null;
            }
        }
        return null;
    }

    /**
     * Executes a SAQL query against Wave Analytics
     * @param saqlQuery The SAQL query to execute
     * @return WaveResponse containing the query results
     */
    public static WaveResponse getWaveQueryResult(String saqlQuery) {
        try {
            Map<String, Object> requestBody = new Map<String, Object>{
                CRMA_DHSConstants.HTTP_REQUEST_QUERY => saqlQuery
            };
            HttpResponse res = doWaveCallout(CRMA_DHSConstants.WAVE_QUERY_ENDPOINT, 'POST', JSON.serialize(requestBody));
            if (res == null) {
                WaveResponse response = new WaveResponse();
                response.error = 'Failed to execute Wave query';
                return response;
            }
            if (!CRMA_DHSConstants.HTTP_STATUS_SUCCESS.contains(res.getStatusCode())) {
                WaveResponse response = new WaveResponse();
                response.error = 'Error executing Wave query. Status: ' + res.getStatusCode();
                response.rawResponse = res.getBody();
                return response;
            }
            return parseWaveResponse(res.getBody());
        } catch (Exception e) {
            WaveResponse response = new WaveResponse();
            response.error = 'Error in getWaveQueryResult: ' + e.getMessage();
            response.stackTrace = e.getStackTraceString();
            return response;
        }
    }

    /**
     * Parses and formats the Wave query response
     * @param waveResponse The raw Wave query response
     * @return WaveResponse containing formatted results
     */
    public static WaveResponse parseWaveResponse(String waveResponse) {
        WaveResponse response = new WaveResponse();
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(waveResponse);
            if (!responseMap.containsKey(CRMA_DHSConstants.WAVE_RESPONSE_RESULTS)) {
                response.error = 'No results found in Wave response';
                response.rawResponse = waveResponse;
                return response;
            }
            Map<String, Object> results = (Map<String, Object>) responseMap.get(CRMA_DHSConstants.WAVE_RESPONSE_RESULTS);
            if (!results.containsKey(CRMA_DHSConstants.WAVE_RESPONSE_RECORDS)) {
                response.error = 'No records found in results';
                response.rawResponse = waveResponse;
                return response;
            }
            List<Object> records = (List<Object>) results.get(CRMA_DHSConstants.WAVE_RESPONSE_RECORDS);
            if (records.isEmpty()) {
                response.error = 'Empty records list';
                response.rawResponse = waveResponse;
                return response;
            }
            for (Object record : records) {
                Map<String, Object> recordMap = (Map<String, Object>) record;
                if (recordMap.containsKey(CRMA_DHSConstants.WAVE_RESPONSE_SCORE) && 
                    recordMap.get(CRMA_DHSConstants.WAVE_RESPONSE_SCORE) != null) {
                    DiscountRange range = new DiscountRange(
                        (String) recordMap.get(CRMA_DHSConstants.WAVE_RESPONSE_TEXTSCORE),
                        (String) recordMap.get(CRMA_DHSConstants.WAVE_RESPONSE_SCORE),
                        (Decimal) recordMap.get(CRMA_DHSConstants.WAVE_RESPONSE_QUARTILE)
                    );
                    response.discountRanges.add(range);
                }
            }
            response.query = (String) responseMap.get(CRMA_DHSConstants.WAVE_RESPONSE_QUERY);
            response.responseTime = (Integer) responseMap.get(CRMA_DHSConstants.WAVE_RESPONSE_TIME);
            return response;
        
    }
    
 
    
    public class WaveAnalyticsException extends Exception {}
}