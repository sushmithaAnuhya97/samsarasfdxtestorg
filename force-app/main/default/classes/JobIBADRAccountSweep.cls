/**
* @description       : https://samsaradev.atlassian.net/browse/GTMS-12819
* @author            : nishita.dhar@samsara.com
* @group             : 
* @last modified on  : 11-29-2023
* @last modified by  : 
**/
/*CRON :JobIBADRAccountSweep m = new JobIBADRAccountSweep();
String seconds = '0'; //Execute at Zero Seconds
String minutes = '0'; //Execute at every 0 minute of hour
String hours = '8'; // Execute at 8 AM
String dayOfMonth = '1'; // Execute 1st Day of every Month
String month = '*'; //Execute every Month
String dayOfWeek = '?'; 
String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek;
//String sch = '0 0 8 1 * ?';
system.schedule('JobIBADRAccountSweep Run Every 1st Day of the month at 8am', sch, m); */  
global class JobIBADRAccountSweep implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    private Boolean EOMSchedule;
    private Set<Id> accountIds;
    
    String endOfMonthQuery = System.Label.End_of_Month;
    
    global void execute(SchedulableContext sc) {
        JobIBADRAccountSweep job = new JobIBADRAccountSweep();
        ID batchprocessid = Database.executeBatch(job,1); 
    }  
    global JobIBADRAccountSweep() {
        Integer currentMonth = Date.today().month();
        System.debug('currentMonth' + currentMonth);
        
            Set<Integer> endOfMonthMonths = new Set<Integer>{1, 3, 4, 6, 7, 9, 10, 12};
                this.EOMSchedule = endOfMonthMonths.contains(currentMonth);
        System.debug('EOMSchedule' + EOMSchedule);
        
        accountIds = new Set<Id>(taskaccIds(new List<Account>()));
        System.debug('accountIds' + accountIds);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (EOMSchedule == true) {
            return Database.getQueryLocator(endOfMonthQuery);
        }
        else {
            String accountQuery = System.label.End_of_Month + ' OR AccountId In: accountIds';   
            System.debug('accountQuery: ' + accountQuery); 
            return Database.getQueryLocator(accountQuery);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> scope) {
        try {
            Map<Id, Account> uniqueAccounts = new Map<Id, Account>();
            for (Contact con : scope) {
                if (con.AccountId != null) {
                    // Check if the Account is not already in the map
                    if (!uniqueAccounts.containsKey(con.AccountId)) {
                        Account acc = new Account(Id = con.AccountId);
                        acc.OwnerId = '0051a000002W9InAAK';
                        uniqueAccounts.put(acc.Id, acc);
                        
                        System.debug('con: ' + con);
                        System.debug('acc Owner: ' + acc.OwnerId);
                    }
                }
            }

                // Update the unique Account records
                if (!uniqueAccounts.isEmpty()) {
                    update uniqueAccounts.values();
                } 
            } catch (Exception e) {
                String errorMessage = 'Error processing batch records: ' + e.getMessage();
                sendErrorEmail(errorMessage);
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
        
        public List<Id> taskaccIds(List<Account> accList) {
            Set<Id> taskAccountIds = new Set<Id>();
            String query = System.Label.IB_ADR_Task_Acc;
            
            // Check if the query string is not null or empty
            if (String.isNotBlank(query)) {
                List<Task> tasks = (List<Task>)Database.query(query);
                
                for (Task task : tasks) {
                    if (task.AccountId != null) {
                        taskAccountIds.add(task.AccountId);
                    }
                }
            }
            
            return new List<Id>(taskAccountIds);
        }
        
        global void finish(Database.BatchableContext BC) {
        }
    }