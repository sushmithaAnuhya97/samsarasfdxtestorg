/**********************************************************************
Name: SLABreachAutomation
=======================================================================
Purpose: This class will logic to process discount approval SLA breach process                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Jun-30        INITIAL DEVELOPMENT FOR GTMS-13635

***********************************************************************/ 
global class SLABreachAutomation implements Database.Batchable<sObject>, Schedulable, Database.allowsCallouts{
    List<Holiday> holidays = new List<Holiday>();
    private static List<Api_Logger__c> aplogList = new List<Api_Logger__c>();
    global SLABreachAutomation() {
        holidays=[Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h limit 50];
    }
    
    public class SLABreachAutomationFlow {
        @InvocableVariable public String quoteId;
    }
	
    @InvocableMethod(label='SLABreachAutomation Submit Quote') 
    public static void submitQuote(List<SLABreachAutomationFlow> infoDetails) {
        if (!Test.isRunningTest())
        SBAA.ApprovalAPI.submit(infoDetails[0].quoteId, SBAA__Approval__c.Quote__c);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        DateTime todaysDate = System.today();
        //system.debug('todaysDate ' + todaysDate);
		DateTime startDateTime = determineStartDateTime(todaysDate); // System.today()-1;
        //system.debug('startDateTime ' + startDateTime);
        Datetime startDate = Datetime.newInstance(startDateTime.yearGmt(), startDateTime.monthGmt(), startDateTime.dayGmt(), 13, 00, 00);
        Datetime endDate = (Test.isRunningTest()) ? Datetime.newInstance(todaysDate.yearGmt(), todaysDate.monthGmt(), todaysDate.dayGmt(), 13+5, 00, 00) 
            : Datetime.newInstance(todaysDate.yearGmt(), todaysDate.monthGmt(), todaysDate.dayGmt(), 13, 00, 00);
        String validStartDateString = string.valueOfGmt(startDate);
        String validEndDateString = string.valueOfGmt(endDate);
        validStartDateString = validStartDateString.replace(' ', 'T') + '.000+0000';
        validEndDateString = validEndDateString.replace(' ', 'T')+ '.000+0000';
        String query = System.Label.SLABreachAutomationQuery;
        if (Test.isRunningTest())
        	query = 'SELECT Id from sbaa__Approval__c Limit 1';
        else {
            query = System.Label.SLABreachAutomationQuery;
            query =  query + ' '+ 'AND Last_Modified_At__c >= ' + validStartDateString + ' AND Last_Modified_At__c <= '+ validEndDateString;
        }
        system.debug('query ' + query);
        createLog('database query ', query,  new HTTPResponse());
        //if (aplogList.size()>0)
        //    insert aplogList;
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<sbaa__Approval__c> records){
        List<sbaa__Approval__c> approvalForUpdate = new List<sbaa__Approval__c>();
        aplogList = new List<Api_Logger__c>();
        FOR(sbaa__Approval__c approvalRec : records) {
            //system.debug('RODRIGO Approval id ' + approvalRec.Id);
            //approvalRec.sbaa__Status__c = 'Approved';
            //approvalForUpdate.add(approvalRec);
            sendAPIRequest(approvalRec.Id);
        }
        if (aplogList.size()>0)
            insert aplogList;
        //system.debug('approvalForUpdate'+ approvalForUpdate);
            
        //if (approvalForUpdate.size()>0)
        //    update approvalForUpdate;
    }
    //@future (callout=true)
    private static void sendAPIRequest(string approvalId) {
        String sessionId = UserInfo.getOrganizationId()+''+UserInfo.getSessionId().SubString(15);
        String bearer = 'Bearer ' + sessionId;
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm(); 
        String restAPIURL = sfdcURL + '/services/apexrest/sbaa/ServiceRouter';
        req.setEndpoint(restAPIURL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', bearer);
        String body = '{"model":"{\\"approvalId\\":\\"'+approvalId+'\\",\\"comments\\":\\"Approved thru SLA Breach batch job\\"}","saver":"SBAA.ApprovalRestApiProvider.Approve"}';
        //system.debug('body ' + body);
        req.setBody(body);
        HTTPResponse res = new HTTPResponse();
        try { 
            if (!Test.isRunningTest()) {
                res = http.send(req);
                //createLog(approvalId, res.getStatus(), res);
            }
        }
        catch(Exception e) {
            System.debug('sendAPIRequest exception occurred: ' + e.getMessage());
            createLog(approvalId, e.getMessage(), res);
        }
        
    }
    
    @testvisible
    private static void createLog(string approvalId, string errorMessage, HTTPResponse res){
        try {
            Api_Logger__c aplog = new Api_Logger__c();
                apLog.Opportunity_Name__c =  'SLABreachAutomation';
                apLog.Quote_Number__c =system.UserInfo.getName();
                apLog.DML__c= true;
                apLog.Request__c= approvalId;
                apLog.Exception_Message__c = errorMessage;
                apLog.Response__c=res.getStatusCode() + ' - ' + res.getStatus();
                aplogList.add(aplog);
        }
        catch(Exception e) {
            System.debug('createLog exception occurred: ' + e.getMessage());
            
        }
    }
    
    public DateTime determineStartDateTime(DateTime inStartDateTime) {
        //if (holidays.size()==0)
        //	holidays=[Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h limit 50];
        //system.debug('inStartDateTime ' + inStartDateTime);
        DateTime dateTimeValue = inStartDateTime;
        Boolean isNotHolidayOrWeekend = true;
        Integer dayCounter = 1;
        while (isNotHolidayOrWeekend) {
            String dayOfWeek = null;
            DateTime tempDateTimeValue;
            tempDateTimeValue = inStartDateTime - dayCounter;
            dayOfWeek = tempDateTimeValue.format('E'); // dayOfWeek is Sun, Mon, Tue, etc.
        	
            //system.debug('-------------------------------- ' + dayCounter);
            //system.debug('dateTimeValue.date() ' + tempDateTimeValue.dateGMT());
            Boolean isHolidayValue = isHoliday(tempDateTimeValue);
            //system.debug('isHolidayValue ' + isHolidayValue);
            if (!dayOfWeek.equalsIgnoreCase('Sat') && !dayOfWeek.equalsIgnoreCase('Sun') && !isHolidayValue) {
                isNotHolidayOrWeekend = false;
                dateTimeValue = tempDateTimeValue;
                break;
            }
            //system.debug('tempDateTimeValue ' + tempDateTimeValue);
            dayCounter=dayCounter+1;
            //system.debug('dayCounter ' + dayCounter);
            //system.debug('isNotHolidayOrWeekend ' + isNotHolidayOrWeekend);
        }
        //system.debug('dateTimeValue before exit ' + dateTimeValue);
        // check if current date is monday
        /*String dayOfWeek = dateTimeValue.format('E'); // dayOfWeek is Sun, Mon, Tue, etc.
        system.debug('dayOfWeek ' + dayOfWeek);
        if (dayOfWeek.equalsIgnoreCase('Mon'))
            dateTimeValue = dateTimeValue-3;
        else 
            dateTimeValue = dateTimeValue-3;
        
        system.debug('dateTimeValue ' + dateTimeValue);*/
        return dateTimeValue;
    }
    
    private boolean isHoliday(DateTime inDateToBeChecked) {
        
        // check if current day is holiday or not
        Boolean isDateHoliday = false;
        FOR(Holiday dateHoliday : holidays) {
            //system.debug('inDateToBeChecked. ' + inDateToBeChecked.dateGMT());
            //system.debug('dateHoliday.ActivityDate. ' + dateHoliday.ActivityDate);
            IF (dateHoliday.ActivityDate == inDateToBeChecked.dateGMT())
                isDateHoliday = true;
        }
        
        return isDateHoliday;
    }
    
	global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }

    global void execute(SchedulableContext SC){
        // get holiday information
        //if (holidays.size()==0)
        //	holidays=[Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h];

        Date currDate = date.today(); 
        if (!isHoliday(currDate))
        	database.executebatch(new SLABreachAutomation(), Test.isRunningTest() ? 100 : 50);
    }
}