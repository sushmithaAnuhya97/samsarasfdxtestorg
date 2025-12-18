/**********************************************************************
Name: DiscountApprovalSLAAutomation
=======================================================================
Purpose: This class will logic to process discount approval SLA breach process                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Nov-17        INITIAL DEVELOPMENT FOR GTMS-15662

***********************************************************************/ 
global class DiscountApprovalSLAAutomation implements Database.Batchable<sObject>, Schedulable {
    
    public static List<Holiday> holidays = new List<Holiday>();
    global DiscountApprovalSLAAutomation() {
        holidays=[Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h limit 50];
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = null;
        // SELECT Id, sbaa__Status__c, Quote__c, Quote__r.OwnerId, Quote__r.Owner_Country__c, Quote__r.Owner_Role__c, LastModifiedDate FROM sbaa__Approval__c WHERE sbaa__Status__c = 'Requested' and sbaa__Rule__r.name = 'Mid Market Revenue Oppty Discount - AE3 Deal Desk'
        //if (Test.isRunningTest())
        //	query = 'SELECT Id, sbaa__Status__c, Quote__c, Quote__r.OwnerId, Quote__r.Owner_Country__c, Quote__r.Owner_Role__c from sbaa__Approval__c Limit 1';
        DateTime todaysDate = System.today();
        //system.debug('todaysDate ' + todaysDate);
        SamsaraHolidayWeekendCheck check = new SamsaraHolidayWeekendCheck('United States');
		DateTime startDateTime = check.determineStartDateTime(todaysDate); // System.today()-1;
        //system.debug('startDateTime ' + startDateTime);
        Datetime startDate = Datetime.newInstance(startDateTime.yearGmt(), startDateTime.monthGmt(), startDateTime.dayGmt(), startDateTime.hourGmt(), startDateTime.minuteGmt(), 00);
        Datetime endDate = (Test.isRunningTest()) ? Datetime.newInstance(todaysDate.yearGmt(), todaysDate.monthGmt(), todaysDate.dayGmt(), 00, 00, 00) 
            : Datetime.newInstance(todaysDate.yearGmt(), todaysDate.monthGmt(), todaysDate.dayGmt(), 00, 00, 00);
        String validStartDateString = string.valueOfGmt(startDate);
        String validEndDateString = string.valueOfGmt(endDate);
        validStartDateString = validStartDateString.replace(' ', 'T') + '.000+0000';
        validEndDateString = validEndDateString.replace(' ', 'T')+ '.000+0000';
        
        if (Test.isRunningTest())
        	query = 'SELECT Id,sbaa__Status__c, Quote__c, Quote__r.OwnerId, Quote__r.Owner_Country__c, Quote__r.Owner_Role__c, Last_Modified_At__c from sbaa__Approval__c Limit 1';
        else {
            query = System.Label.DiscountApprovalSLAAutomation;
            query =  query + ' '+ 'AND Last_Modified_At__c >= ' + validStartDateString;
        }
        //system.debug('query ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<sbaa__Approval__c> records){
        // variable to hold country and user ids
        Map<id, string> countryNames = new map<id, string>();
        Set<Id> userList = new Set<Id>();
        FOR(sbaa__Approval__c rec : records) {
            countryNames.put(rec.Quote__r.OwnerId, rec.Quote__r.Owner_Country__c);
            userList.add(rec.Quote__r.OwnerId);
        }
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, TimeZoneSidKey from User where Id IN: userList]);
        SamsaraHolidayWeekendCheck bhCheck = new SamsaraHolidayWeekendCheck('United States');
        
        // loop thru all approval records
        FOR(sbaa__Approval__c rec : records) {
            User locUser = userMap.get(rec.Quote__r.OwnerId);
            Boolean toSend = bhCheck.isEmailAlertToBeSent(rec.Quote__r.Owner_Country__c, locUser.TimeZoneSidKey, rec.Last_Modified_At__c);
            
            if(toSend) {
                // send the email notification
                Map<String,Object> approvalMap = new Map<String, Object >();
                
                approvalMap.put('ApprovalId', rec.Id); 
                approvalMap.put('OwnerRole', rec.Quote__r.Owner_Role__c);
                
                Flow.Interview.Discount_Approval_Deal_Desk_Reminder flowInstance = new Flow.Interview.Discount_Approval_Deal_Desk_Reminder(approvalMap);
                flowInstance.start();
            }
        }
    }
    /*public static void methodTest() {
        String query = null;
        DateTime todaysDate = System.today();
        //system.debug('todaysDate ' + todaysDate);
        
        SamsaraHolidayWeekendCheck check = new SamsaraHolidayWeekendCheck('United States');
		DateTime startDateTime = check.determineStartDateTime(todaysDate); // System.today()-1;
        system.debug('startDateTime ' + startDateTime);
        Datetime startDate = Datetime.newInstance(startDateTime.yearGmt(), startDateTime.monthGmt(), startDateTime.dayGmt(), 13, 00, 00);
        Datetime endDate = (Test.isRunningTest()) ? Datetime.newInstance(todaysDate.yearGmt(), todaysDate.monthGmt(), todaysDate.dayGmt(), 13+5, 00, 00) 
            : Datetime.newInstance(todaysDate.yearGmt(), todaysDate.monthGmt(), todaysDate.dayGmt(), 13, 00, 00);
        String validStartDateString = string.valueOfGmt(startDate);
        String validEndDateString = string.valueOfGmt(endDate);
        validStartDateString = validStartDateString.replace(' ', 'T') + '.000+0000';
        validEndDateString = validEndDateString.replace(' ', 'T')+ '.000+0000';
        
        if (Test.isRunningTest())
        	query = 'SELECT Id from sbaa__Approval__c Limit 1';
        else {
            query = System.Label.DiscountApprovalSLAAutomation;
            query =  query + ' '+ 'AND Last_Modified_At__c >= ' + validStartDateString;
        }
        system.debug('query ' + query);
    }*/
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }

    global void execute(SchedulableContext SC){
        Date currDate = date.today(); 
        
        if (!SamsaraHolidayWeekendCheck.isSamasaraHolidayOrWeekend(currDate))
        	database.executebatch(new DiscountApprovalSLAAutomation(), Test.isRunningTest() ? 100 : 50);
    }

}