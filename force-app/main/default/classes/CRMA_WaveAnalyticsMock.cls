/**
 * Author: Vigneshwaran D
 * Date: 8 May 2025
 * Team: Sales-Execution-Smart-Workflows-GTMS
 * Purpose: Update Deal_Health__c field on Quote -> Deal Health Score Quartile Color from CRMA
 * Jira: GTMS-27488, GTMS-27491
 *
 * Description:
 * HTTP callout mock class for simulating Wave Analytics API responses in DHS-related test methods.
 * Supports custom mock responses for both /wave/datasets and /wave/query endpoints, as well as error and edge-case testing.
 */
@isTest
public class CRMA_WaveAnalyticsMock implements HttpCalloutMock {
    private Map<String, Object> mockResponse;
    
    public CRMA_WaveAnalyticsMock() {
        this.mockResponse = null;
    }
    public CRMA_WaveAnalyticsMock(Map<String, Object> mockResponse) {
        this.mockResponse = mockResponse;
    }
    
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        String url = req.getEndpoint();
        
        // If a custom mockResponse is provided, use it for error/edge-case testing
        if (mockResponse != null) {
            // If the test provides a 'body', use it directly
            if (mockResponse.containsKey('body')) {
                Object body = mockResponse.get('body');
                res.setBody(body != null ? String.valueOf(body) : '');
                res.setStatusCode((Integer)mockResponse.get('statusCode') != null ? (Integer)mockResponse.get('statusCode') : 200);
                return res;
            }
            // If the test provides a 'datasets' key and this is a datasets call
            if (url != null && url.contains('/wave/datasets') && mockResponse.containsKey('datasets')) {
                res.setBody(JSON.serialize(new Map<String, Object>{'datasets' => mockResponse.get('datasets')}));
                res.setStatusCode(200);
                return res;
            }
            // If the test provides a 'results' key and this is a query call
            if (url != null && url.contains('/wave/query') && mockResponse.containsKey('results')) {
                res.setBody(JSON.serialize(new Map<String, Object>{'results' => mockResponse.get('results')}));
                res.setStatusCode(200);
                return res;
            }
            // Fallback: serialize the whole map
            res.setBody(JSON.serialize(mockResponse));
            res.setStatusCode(200);
            return res;
        }
        
        // Default logic for standard test scenarios
        res.setStatusCode(200);
        if (url != null && url.contains('/wave/datasets')) {
            res.setBody('{"datasets": [{"id": "0FbXXXXXXXXXXXXXXX", "name": "Deal_Health_Score_Inputs_CSV_Source", "currentVersionId": "0FcXXXXXXXXXXXXXXX"}]}');
        } else if (url != null && url.contains('/wave/query')) {
            res.setBody('{"results": {"records": [{"Score": "1.Green", "textscore": "0-10%", "Quartile": 10}, {"Score": "2.Yellow", "textscore": "10-20%", "Quartile": 20}, {"Score": "3.Orange", "textscore": "20-30%", "Quartile": 30}, {"Score": "4.Red", "textscore": "30%+", "Quartile": 40}]}}');
        } else {
            res.setBody('{}');
        }
        return res;
    }
}