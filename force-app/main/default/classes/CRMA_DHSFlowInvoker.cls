/**
 * Author: Vigneshwaran D
 * Date: 8 May 2025
 * Team: Sales-Execution-Smart-Workflows-GTMS
 * Purpose: Update Deal_Health__c field on Quote -> Deal Health Score Quartile Color from CRMA
 * Jira: GTMS-27488, GTMS-27491
 * Test Class : CRMA_DHSFlowInvokerTest, CRMA_TestDataUtility, CRMA_WaveAnalyticsMock
 *
 * Description:
 * Invocable Apex class for processing and updating Deal Health Score for Quotes via Flow.
 * Accepts a list of Quote Ids, invokes the DHS service, and returns the quartile color for each quote.
 */
public inherited sharing class CRMA_DHSFlowInvoker {
    public class Input {
        @InvocableVariable(required=true)
        public String quoteId;
    }
    public class Output {
        @InvocableVariable
        public String quartileColor;
    }

    @InvocableMethod(label='Process and Update Deal Health' description='Runs DHS process and updates Deal_Health__c for the given Quote Id(s)')
    public static List<Output> processAndUpdateDealHealthFlow(List<Input> inputList) {
        List<Output> results = new List<Output>();
        for (Input input : inputList) {
            Output out = new Output();
            out.quartileColor = CRMA_DHSService.processAndUpdateDealHealth(input.quoteId);
            results.add(out);
        }
        return results;
    }
}