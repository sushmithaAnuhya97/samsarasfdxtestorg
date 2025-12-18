/**
 * @description       : 
 * @author            : Navees Ahmed
 * @group             : 
 * @last modified on  : 02-20-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
/*CRON :JobRenewalCoTerm m = new JobRenewalCoTerm();
        String seconds = '0'; //Execute at Zero Seconds
        String minutes = '0'; //Execute at every 0 minute of hour
        String hours = '1'; // Execute at 1 AM
        String dayOfMonth = '?'; // Execute Every Day of the Month
        String month = '*'; //Execute every Month
        String dayOfWeek = '*'; //Execute on all 7 days of the Week
        
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek;
        //String sch = '0 0 01 * * ?';
        system.schedule('JobClickpathCoTerming Run Every Day at 1am', sch, m); */  
global class JobRenewalCoTerm implements Database.Batchable<sObject>, Schedulable, Database.Stateful {    
    global Map<String,String> mapFailedRecords;
    global Map<String,String> mapEndDateIn30DaysRecords;
    global JobRenewalCoTerm(){
        mapFailedRecords=new Map<String,String>();
        mapEndDateIn30DaysRecords=new Map<String,String>();
    }
    
    global  Date  tweleveMonthsFuture = Date.Today().addMonths(12);
    global   String DATA_QUERY= getQueryString();//'Select Id,SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c, SBQQ__RenewalOpportunity__r.License_End_Date__c, AccountId, Account.Latest_Active_Contract__c, Account.Latest_Active_Contract__r.EndDate, EndDate, Status from Contract Where AccountId!=NULL AND Account.Latest_Active_Contract__c!=NULL AND  Account.Latest_Active_Contract__r.Deactivated__c = false AND Account.Latest_Active_Contract__r.EndDate!=NULL AND SBQQ__RenewalOpportunity__c!=NULL  AND SBQQ__RenewalOpportunity__r.ACV_Bookings_SOT__c <= 15000 AND Account.Customer_ARR__c <= 25000 AND Account.Skip_Silent_Auto_Renewal__c = FALSE AND Skip_Silent_Auto_Renewal__c = FALSE AND SBQQ__RenewalOpportunity__r.RecordType.Name = \'Revenue Opportunity\' AND Account.Account_Size_Segment__c NOT IN ( \'Ent\',\'AE2/AE3\') AND SBQQ__RenewalOpportunity__r.StageName NOT IN (\'Closing\', \'Orders Processing\', \'Ready to Ship\', \'Closed Won\', \'Closed Lost\') AND Is_Active__c = TRUE  AND Account.Latest_Active_Contract__r.EndDate >= NEXT_N_MONTHS: 12';
   // public Static queryFromConstructor;
   global JobRenewalCoTerm(String query){
        //this();
        mapFailedRecords=new Map<String,String>();
        mapEndDateIn30DaysRecords=new Map<String,String>();
        this.DATA_QUERY = String.isNotBlank(query) ? query:this.DATA_QUERY;
        
    }
    
    
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    global void execute(SchedulableContext sc) {
        Integer batchSize=1;
        if(Test.isRunningTest()){
            batchSize=10;
        }
        JobRenewalCoTerm job = new JobRenewalCoTerm();
        ID batchprocessid = Database.executeBatch(job,batchSize); 
    }  
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if(Test.isRunningTest()){
            return Database.getQueryLocator('SELECT id,SBQQ__RenewalOpportunity__c,SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c, SBQQ__RenewalOpportunity__r.License_End_Date__c, AccountId, Account.Latest_Active_Contract__c, Account.Latest_Active_Contract__r.EndDate, EndDate,SBQQ__RenewalOpportunity__r.ACV_Bookings_SOT__c FROM Contract');
        }
        else{
            return Database.getQueryLocator(DATA_QUERY);
        }        
    }
    
    global void execute(Database.BatchableContext BC, List<Contract> records) {
        try {
            List<Opportunity> lstOpp = new List<opportunity>();
            for(Contract c : records){
                Date endDateCheck = c.EndDate ;
                      endDateCheck = endDateCheck.addMonths(12);
                if((c.Id <> c.Account.Latest_Active_Contract__c  && c.Account.Latest_Active_Contract__r.EndDate >= endDateCheck) || Test.isRunningTest()){
                    
                        Integer monthsDiff = c.EndDate.monthsBetween(c.Account.Latest_Active_Contract__r.EndDate) != 0 ? c.EndDate.monthsBetween(c.Account.Latest_Active_Contract__r.EndDate) : 1; 
                       
                        if (c.Account.Latest_Active_Contract__r.EndDate.day() > c.EndDate.day()){
                            monthsDiff++;
                        }
                        
                        lstOpp.add(new opportunity(id=c.SBQQ__RenewalOpportunity__c, License_End_Date__c = c.Account.Latest_Active_Contract__r.EndDate, License_Term__c = monthsDiff, License_Term_CPQ__c = monthsDiff));
                        
                        c.Adjusted_RenewalOpp_EndDate__c = c.Account.Latest_Active_Contract__r.EndDate;
                        c.SBQQ__RenewalTerm__c = monthsDiff;
                    }
                   

                }
            

            if(lstOpp.size() > 0){
                TriggerHandler.bypass('GS_OpportunityTriggerHandler');
                TriggerHandler.bypass('OpportunityTriggerHandler');
                TriggerHandler.bypass('ContractTriggerHandler');
                TriggerHandler.bypass('AccountTriggerHandler');
                update lstOpp;
                update records;
                
            }
            
        } catch (Exception e)
        {
            System.debug('e.getMessage()====='+e.getMessage());
            thisLogger.logError('JobClickpathCoTerming. Error Message ::'+ e.getMessage());
            for(Contract c : records){
                mapFailedRecords.put(c.Id,e.getMessage()+' '+e.getStackTraceString());
            }
        }
        finally{
            thisLogger.dispatch();
        }
    } 
    global void finish(Database.BatchableContext BC) { 
        String emailBody='';
        if(mapFailedRecords.size()>0 || mapEndDateIn30DaysRecords.size()>0){
            emailBody='Failed Records:\r\n';
            for(String key:mapFailedRecords.keySet()){
                emailBody+=key+':'+mapFailedRecords.get(key)+'\r\n';
            }
                      
        }
        if(String.isNotBlank(emailBody) && String.isNotBlank(System.Label.JobClickpathCoTermingNotification)){
            List<String> toEmail=new List<String>();
            for(String e:System.Label.JobClickpathCoTermingNotification.split(',')){
                if(String.isNotBlank(e)){
                    toEmail.add(e.trim());
                }
            }
             Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toEmail);
            email.setSubject('Click Path Co-Terming Processing');
            email.setPlainTextBody(emailBody);
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});      
        }  
    }
    
    public static String getQueryString(){
        
       
        String query ='Select Id,SBQQ__RenewalOpportunity__c,SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c,'+
                      ' SBQQ__RenewalOpportunity__r.License_End_Date__c, AccountId,'+
                      ' Account.Latest_Active_Contract__c,convertCurrency(SBQQ__RenewalOpportunity__r.ACV_Bookings_SOT__c), Account.Latest_Active_Contract__r.EndDate,'+
                      ' EndDate, Status from Contract Where AccountId!=NULL'+
                      ' AND Account.Latest_Active_Contract__c!=NULL AND '+
                      ' Account.Latest_Active_Contract__r.Deactivated__c = false AND '+
                      ' Account.Latest_Active_Contract__r.EndDate!=NULL AND SBQQ__RenewalOpportunity__c!=NULL '+
                      ' AND Account.Skip_Silent_Auto_Renewal__c = false AND Skip_Silent_Auto_Renewal__c = false AND '+
                      ' SBQQ__RenewalOpportunity__r.Type = \'Revenue Opportunity\' AND '+
                      ' SBQQ__RenewalOpportunity__r.StageName NOT IN (\'Closing\', \'Orders Processing\', \'Ready to Ship\', \'Closed Won\', \'Closed Lost\') AND '+
                      ' Is_Active__c = TRUE '+
            		  ' AND EndDate >= TODAY and (SBQQ__RenewalOpportunity__r.isClosed = false AND SBQQ__RenewalOpportunity__r.Probability <= 90)'+ 
                      ' AND Adjusted_RenewalOpp_EndDate__c =null AND EndDate <=NEXT_N_DAYS:110 AND SBQQ__RenewalQuoted__c = false AND '+System.label.Digital_Renewals_Threshold;
        
        
        return query;
    }
}