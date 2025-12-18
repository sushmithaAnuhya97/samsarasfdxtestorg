/**
 * @description       : https://samsaradev.atlassian.net/browse/GTMS-10150
 * @author            : navees.ahmed@samsara.com
 * @group             : 
 * @last modified on  : 12-15-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * last modified by   : 25th April 2024 as part of GTMS-19113
**/
/*CRON :JobContractAutomation m = new JobContractAutomation();
        String seconds = '0'; //Execute at Zero Seconds
        String minutes = '0'; //Execute at every 0 minute of hour
        String hours = '21'; // Execute at 1 AM
        String dayOfMonth = '?'; // Execute Every Day of the Month
        String month = '*'; //Execute every Month
        String dayOfWeek = '*'; //Execute on all 7 days of the Week
        
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek;
        //String sch = '0 0 01 * * ?';
        system.schedule('JobContractAutomation Run Every Day at 9pm', sch, m); */  
global class JobContractAutomation implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

        public static String WHERECLAUSE_RENEWALFORECAST=' SBQQ__RenewalForecast__c=FALSE ';
    //Removed Opt out, Billing Stripe Id, Finance Partner, Reseller from the query as per GTMS-19113  
    //public static String WHERECLAUSE_RENEWALTERM_AUTORENEWAL=' (Account.Auto_renewal_Opt_Out__c=FALSE AND Account.Quarantine_Enabled__c=FALSE AND SBQQ__RenewalOpportunity__r.ACV_Bookings_SOT__c<15000 AND Account.Billing_Stripe_Customer_Id__c!=NULL AND Account.Customer_ARR__c< 25000 AND SBQQ__RenewalOpportunity__r.Finance_Partner__c=NULL AND SBQQ__RenewalOpportunity__r.Payment_Type__c!=\'Reseller\' AND Account.Account_Size_Segment__c!=\'ENT\' AND Account.Netsuite_Delinquent_Status__c NOT IN (\'Deactivated\',\'Written-off\') AND (Auto_Renewal__c = false OR SBQQ__RenewalTerm__c!=12)) ';
    // GTMS-19113 removed Auto_renewal_Opt_Out__c, Billing_Stripe_Customer_Id__c, Finance_Partner__c and Payment_Type__c!='Reseller' fields
    public static String WHERECLAUSE_RENEWALTERM_AUTORENEWAL=' ('+System.label.Digital_Renewals_Threshold+' AND Auto_Renewal__c = false and SBQQ__RenewalQuoted__c = false) ';
        public static String WHERECLAUSE_RENEWALQUOTED=' (SBQQ__RenewalQuoted__c = false AND EndDate>=TODAY AND EndDate<=NEXT_N_DAYS:90  ) ';
        public static String WHERECLAUSE_DEFAULT=' (CreatedDate >= 2021-07-01T00:00:00Z OR Renewal_Data_Clean__c = True) AND SBQQ__Opportunity__c != NULL AND RecordTypeName__c != \'Free Trial\' AND SBQQ__Opportunity__r.Type = \'Revenue Opportunity\' AND Health_Status__c != \'Unaddressable\' AND EndDate!=NULL and EndDate >= TODAY and (SBQQ__RenewalOpportunity__c = null or (SBQQ__RenewalOpportunity__r.isClosed = false AND SBQQ__RenewalOpportunity__r.Probability <= 90))'+System.label.Contract_Automation_Enhanced_Clause;
        
    global void execute(SchedulableContext sc) {
        JobContractAutomation job = new JobContractAutomation();
            ID batchprocessid = Database.executeBatch(job,1); 
    }  
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //String query1='Select Id, AccountId, Account.Latest_Active_Contract__c, Account.Latest_Active_Contract__r.Enddate, Account.Latest_Active_Contract__r.deactivated__c, SBQQ__RenewalForecast__c, SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c, SBQQ__RenewalQuoted__c, EndDate, Auto_Renewal__c, SBQQ__RenewalTerm__c, Adjusted_RenewalOpp_EndDate__c From Contract Where '+WHERECLAUSE_DEFAULT+' AND ('+WHERECLAUSE_RENEWALFORECAST+' OR '+WHERECLAUSE_RENEWALTERM_AUTORENEWAL+' OR '+WHERECLAUSE_RENEWALQUOTED+' ) ';
        String query1='Select Id,SBQQ__RenewalForecast__c,SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,SBQQ__RenewalQuoted__c,EndDate,Auto_Renewal__c,SBQQ__RenewalTerm__c,Adjusted_RenewalOpp_EndDate__c From Contract Where '+WHERECLAUSE_DEFAULT+' AND ('+WHERECLAUSE_RENEWALFORECAST+' OR '+WHERECLAUSE_RENEWALTERM_AUTORENEWAL+' OR '+WHERECLAUSE_RENEWALQUOTED+' ) ';
        return Database.getQueryLocator(query1);
    }
    
    global void execute(Database.BatchableContext BC, List<Contract> contractList) {
        if(contractList!=null && contractList.size()>0){
            String renewalTermQuery=' Select Id,SBQQ__RenewalForecast__c,SBQQ__RenewalQuoted__c, SBQQ__RenewalTerm__c From Contract Where Id = :contractList AND '+WHERECLAUSE_RENEWALTERM_AUTORENEWAL;
            List<Contract> listContracts= Database.query(renewalTermQuery);
            Map<Id,Contract> mapContracts=new Map<Id,Contract>(listContracts);
            Date nintyDaysFromNow=System.Today().addDays(90);
            for(Contract c:contractList){
                if(c.SBQQ__RenewalForecast__c==false){
                    c.SBQQ__RenewalForecast__c=true;
                }
                if(mapContracts.containsKey(c.Id)){
                    c.Auto_Renewal__c=true;
                    if(c.Adjusted_RenewalOpp_EndDate__c == null){
                    	c.SBQQ__RenewalTerm__c=36;
                    }
                }
                System.debug('Enddate-->'+c.EndDate+'  nintyDaysFromNow-->'+nintyDaysFromNow);
                if(c.EndDate<=nintyDaysFromNow && c.EndDate>=System.Today() && c.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c==null){
                    c.SBQQ__RenewalQuoted__c=true;
                    /*if(c.Auto_Renewal__c == false && c.account.Latest_Active_Contract__c != null 
                       && c.account.Latest_Active_Contract__r.enddate > system.today() &&
                      c.account.Latest_Active_Contract__r.deactivated__c == false &&
                      c.Id!=c.account.Latest_Active_Contract__c && system.today() >= Date.valueOf(SYSTEM.Label.Annualize_ACV_Date)){
                    	c.Adjusted_RenewalOpp_EndDate__c=c.account.Latest_Active_Contract__r.enddate;
                    }*/
                }
            }
            update contractList;
        }

    }  

    global void finish(Database.BatchableContext BC) { 
    }  
}