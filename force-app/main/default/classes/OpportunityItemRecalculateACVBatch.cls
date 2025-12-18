/**
 * Created By: Flavio Contini 2023-05-31
 * This class was created as a temporary solution for GTMS-11998. The issue to be fixed by this batch is the incorrect Opportunity Product rollup ACV calculation.
 * 
 * The root cause of the issue lies in API updates from Opportunity Product first, then Opportunity record in the same transaction, where the Opportunity update involves changes to the License_Term__c field.
 * This is a small description on how the issue happens:
 * 
 * 1- Opportunity gets created in Incubate with 36 months of License Term. (most likely a Renewal).
 * 2- API call to update Products & Opportunity
 *     2.1 - This API updates first the Products, where the ACV is recalculated based on 36 months of License Term.
 *     2.2 - Still in the same transaction, the API then updates the Opportunity's License Term to 34 (or anything > 12 that is different than the previous value).
 * Finally, since there is no third update to the Opportunity Product records again, the ACV value calculated of 36 months persists in the Opportunity.
 * 
 * This batch will no longer be necessary if the API call manages to change the License Term on the Opportunity first, then update the products. Or if we find a performatic way to do this third update without extra async or system performance overhead.
 */
public without sharing class OpportunityItemRecalculateACVBatch implements Database.Batchable<String>, System.Schedulable {

    public static final String SOURCE_REPORT_DEVELOPER_NAME = Label.Batch_OpportunityWithWrongACVReportDeveloperName;
    public static final Integer REPORT_OPPORTUNITY_ID_COLUMN_INDEX = 0;
    public static final Integer DEFAULT_BATCH_SIZE = 10;

    // Some logics built in Opportunity trigger are preventing this batch from properly executing.
    public static final Boolean BYPASS_OPPORTUNITY_TRIGGERS = true;

    @TestVisible private static List<String> TEST_RECORDS_OVERRIDE;

    public void execute(SchedulableContext ctx){
        Database.executeBatch(new OpportunityItemRecalculateACVBatch(), DEFAULT_BATCH_SIZE);
    }
    
    public System.Iterable<String> start(Database.BatchableContext ctx){
        // Get the report ID
        String reportId;
        List <Report> reportList = [SELECT Id FROM Report WHERE DeveloperName = :SOURCE_REPORT_DEVELOPER_NAME LIMIT 1];
        if (!reportList.isEmpty()) reportId = String.valueOf(reportList[0].Id);

        if (reportId == null) throw new ReportNotFoundException('Report source for Batch not found. Report name expected: '+SOURCE_REPORT_DEVELOPER_NAME);
        
        Set<String> opportunityIdsToUpdate = new Set<String>();

        // Run a report synchronously
        Reports.reportResults results = runReport(reportId);

        // Get the fact map from the report results
        Reports.ReportFactWithDetails factDetails =
            (Reports.ReportFactWithDetails)results.getFactMap().get('T!T');

        Boolean testOverride = (Test.isRunningTest() && TEST_RECORDS_OVERRIDE != null);
        for (Reports.ReportDetailRow row : factDetails.getRows()){
            // Get the first column as data 
            opportunityIdsToUpdate.add(String.valueOf(row.getDataCells()[REPORT_OPPORTUNITY_ID_COLUMN_INDEX].getValue()));
            if (testOverride) break;
        }

        return (testOverride ? TEST_RECORDS_OVERRIDE : new List<String>(opportunityIdsToUpdate));
    }

    private Reports.ReportResults runReport(String reportId){
        // Reports always see all org's data, resulting in CPU time limit too quickly
        if (Test.isRunningTest()){
            Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
            Reports.ReportMetadata reportMd = describe.getReportMetadata();
            reportMd.getStandardDateFilter().setDurationValue('TODAY');
            reportMd.getStandardDateFilter().setEndDate(String.valueOf(System.today()));
            if (TEST_RECORDS_OVERRIDE != null && TEST_RECORDS_OVERRIDE.size() == 1) reportMd.getReportFilters().add(new Reports.ReportFilter('OPPORTUNITY_ID', 'equals', String.valueOf(TEST_RECORDS_OVERRIDE[0])));

            return Reports.ReportManager.runReport(reportId, reportMd, true);
        }else return Reports.ReportManager.runReport(reportId, true);
    }

    // Perform an empty update so ACV is recalculated
    public void execute(Database.BatchableContext ctx, List<String> opportunityIdList){
        if (BYPASS_OPPORTUNITY_TRIGGERS) TriggerHandler.bypass(OpportunityTriggerHandler.class.getName());           
        
        
        List<OpportunityLineItem> toUpdateList = new List<OpportunityLineItem>();
        for (OpportunityLineItem item : [SELECT Id, ACV_Total_Price_Bookings__c, ACV_Total_Price_Stamp__c FROM OpportunityLineItem WHERE OpportunityId = :opportunityIdList ORDER BY OpportunityId]){
            if (item.ACV_Total_Price_Bookings__c?.setScale(2) != item.ACV_Total_Price_Stamp__c?.setScale(2)) toUpdateList.add(item);
        }
        Database.update(toUpdateList, false);
        
        TriggerHandler.clearBypass(OpportunityTriggerHandler.class.getName());
    }

    public void finish(Database.BatchableContext ctx){}

    public class ReportNotFoundException extends Exception{}
}