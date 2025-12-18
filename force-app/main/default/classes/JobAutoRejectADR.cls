/**
* @description       : https://samsaradev.atlassian.net/browse/GTMS-14200
* @author            : nishita.dhar@samsara.com
* @group             : 
* @last modified on  : 31-08-2023
* @last modified by  : 
**/

global class JobAutoRejectADR implements Database.Batchable<sObject>, Schedulable, Database.Stateful{
    
    map<string,list<Integer>> holidayMap{get{
        if(holidayMap != null) return holidayMap;

        holidayMap = new map<string,list<Integer>>();

        for(holiday__mdt hDay : holiday__mdt.getAll().values()){

            if(!holidayMap.containsKey(hDay.Role_Code__c))
                holidayMap.put(hDay.Role_Code__c, new list<Integer>());

            holidayMap.get(hDay.Role_Code__c).add((Integer)hDay.Holiday_Code__c);
        }

        return holidayMap;
    }set;}

    @testVisible Date currentDate{get{
        if(currentDate == null) currentDate = System.today();
        return currentDate;
    }set;}

    Integer todayDateCode;
    
    global void execute(SchedulableContext sc) {
        
        // Get the current day of the week
        String dayOfWeek = DateTime.now().format('EEEE');
        
        // Check if it's a weekday (Monday to Friday)
        if (dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday') {
            JobAutoRejectADR job = new JobAutoRejectADR();
            ID batchProcessId = Database.executeBatch(job, 1);
        }
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext context) {
        todayDateCode = getDateInCode(currentDate);
        return Database.getQueryLocator(System.label.ADR_Logs_SLA);
    }
    
    global void execute(Database.BatchableContext context, List<SObject> scope) {
        List<ADR_Transfer_Log__c> ADRLogstoUpdate = new List<ADR_Transfer_Log__c>();
        List<Account> accountsToUpdate = new List<Account>();
        
        for (SObject obj : scope) {

            ADR_Transfer_Log__c adrlog = (ADR_Transfer_Log__c)obj;

            Integer demoDateCode = getDateInCode(adrlog.ADR_Demo_Date__c.date());

            if(adrlog.ADR_Demo_Date__c > currentDate) continue; //If the ADR log's demo date is in the future, skip this record.

            if(isTodayHoliday(adrlog, demoDateCode)) continue; //If its a holiday, skip this record.

            Integer workingDays = calculateWorkingDays(adrlog);

            if (workingDays == 2 && adrlog.Email_Sent_SLA_Reminder__c == false) {
                adrlog.Email_Sent_SLA_Reminder__c = true;
                adrlog.AE_Manager__c = adrlog.AE_Demo_Transfer_To__r.Manager_ID__c;
                ADRLogstoUpdate.add(adrlog);
            }
            if (workingDays >= 3 && adrlog.Email_Sent_SLA_Reminder__c == true) {
                adrlog.ADR_Transfer_Status__c = 'Auto Reject - SLA';
                adrlog.Rejection_Reason__c = 'Auto Reject: SLA Non-Adherence';
                adrlog.Rejection_Time__c = system.today();
                adrlog.Rejected_By_New__c = '0051P000003IOLsQAO';
                adrlog.Email_Sent_SLA_Reminder__c = false;
                //Alpha Logic
                if (adrlog.Account__c != null) {
                    Account acc = new Account(Id = adrlog.Account__c);
                    if(adrlog.Account__r.Books_Of_Business__c == null){
                        acc.OwnerId = adrlog.ADR_Transfer_By__c;
                        //System.debug('Account Owner - ' + adrlog.Account__r.OwnerId);
                    }
                    else if(adrlog.Account__r.Books_Of_Business__c != null && adrlog.Account__r.Account_Status_Updated__c=='Non Existing Customer'){
                        acc.Prospecting_Status__c = 'ADR Prospecting';
                    }
                    accountsToUpdate.add(acc);
                }
                ADRLogstoUpdate.add(adrlog);
            }
        }

        try{

            Database.SaveResult[] saveResults = Database.update(ADRLogstoUpdate, false);
            saveResults.addAll(Database.update(accountsToUpdate, false));
            
            // Check for errors in ADRLogstoUpdate updates
            for (Database.SaveResult result : saveResults) {
                if (!result.isSuccess()) {
                    System.debug('ADRLogstoUpdate/Account update error: ' + result.getErrors()[0].getMessage());
                    sendErrorEmail(result.getErrors()[0].getMessage());
                }
            }
        }
        catch (Exception ex) {
            System.debug('An exception occurred: ' + ex.getMessage());
            sendErrorEmail(ex.getMessage());
        }
    }
    
    public void sendErrorEmail(String errorMessage) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{'nishita.dhar@samsara.com'});
        email.setSubject('Error in Batch Processing');
        email.setPlainTextBody('An error occurred during batch processing:\n' + errorMessage);
        
        Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        
        for (Messaging.SendEmailResult sendResult : sendResults) {
            if (!sendResult.isSuccess()) {
                System.debug('Email sending failed: ' + sendResult.getErrors()[0].getMessage());
            }
        }
    }
    
    global Integer calculateWorkingDays(ADR_Transfer_Log__c adrlog) {
        
        list<date> holidays = getHolidays(adrlog);

        Datetime DemoDate = adrlog.ADR_Demo_Date__c.adddays(1); //Existing functionality - Not sure why this was added
        //System.debug('DemoDate after adding 1 day more -->' + DemoDate);
        Integer workingDays = 0;
        
        Date currentDate = System.today();
        
        // Calculate the number of days between DemoDate and currentDate
        Integer days = DemoDate.date().daysBetween(currentDate);
        
        for (Integer i = 0; i <= days; i++) {
            if(workingDays == 3) break;
            Datetime dt = DemoDate.addDays(i);
            // Check if the day is not a weekend and not a holiday
            if (dt.format('EEEE') != 'Saturday' && dt.format('EEEE') != 'Sunday' && !holidays.contains(dt.date())) {
                workingDays++;
            }
        }
        System.debug('workingDays-->' + workingDays);
        return workingDays;
    }

    private list<date> getHolidays(ADR_Transfer_Log__c adrlog){
        list<Integer> holidaysForRole = new list<Integer>();

        for(String roleCode :holidayMap.keySet()){

            if(!adrlog.Owner.UserRole.Name.contains(roleCode)) continue;
            
            holidaysForRole.addAll(holidayMap.get(roleCode));
            break;
        }

        if(holidaysForRole.isEmpty()) return new list<Date>();

        list<date> applicableHolidays = new list<date>();

        Integer demoDateCode = getDateInCode(adrlog.ADR_Demo_Date__c.date());

        for(Integer hCode :holidaysForRole){

            if(adrlog.ADR_Demo_Date__c.year() == System.today().year() && demoDateCode < hCode && hCode < todayDateCode)
                applicableHolidays.add(getDateValueOfCode(hCode,adrlog.ADR_Demo_Date__c.year()));
            if(adrlog.ADR_Demo_Date__c.year() < System.today().year() && demoDateCode < hCode)
                applicableHolidays.add(getDateValueOfCode(hCode,adrlog.ADR_Demo_Date__c.year()));
            if(adrlog.ADR_Demo_Date__c.year() < System.today().year() && hCode < todayDateCode)
                applicableHolidays.add(getDateValueOfCode(hCode,System.today().year()));
        }

        return applicableHolidays;
    }

    private Integer getDateInCode(Date inputDate){
        return Integer.valueOf(String.valueOf(inputDate.month())
        +(inputDate.day() > 9 ? String.valueOf(inputDate.day()) : '0'+String.valueOf(inputDate.day())));
    }

    private date getDateValueOfCode(Integer code, Integer year){
        string codeString = code > 999 ? String.valueOf(code) : '0'+String.valueOf(code);
        return date.newInstance(year, Integer.valueOf(codeString.substring(0,2)),Integer.valueOf(codeString.substring(2,4)));
    }

    private boolean isTodayHoliday(ADR_Transfer_Log__c adrlog, Integer demoDateCode){

        for(String roleCode :holidayMap.keySet()){

            if(!adrlog.owner.userRole.Name.contains(roleCode)) continue;
                
            if(!holidayMap.get(roleCode).contains(demoDateCode)) break;

            return true;
        }

        return false;
    }
    
    global void finish(Database.BatchableContext context) {
    }
}