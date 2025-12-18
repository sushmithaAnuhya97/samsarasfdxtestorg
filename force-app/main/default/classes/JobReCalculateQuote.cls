/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-14-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
/*CRON :JobReCalculateQuote m = new JobReCalculateQuote(50);
        String seconds = '0'; //Execute at Zero Seconds
        String minutes = '0'; //Execute at every 0 minute of hour
        String hours = '8,10,12,14,16,18,23,1'; // Execute at 1 AM
        String dayOfMonth = '?'; // Execute Every Day of the Month
        String month = '*'; //Execute every Month
        String dayOfWeek = '*'; //Execute on all 7 days of the Week
        
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek;
        //String sch = '0 0 01 * * ?';
        system.schedule('JobReCalculateQuote Run Every Day at 1am', sch, m); */ 
//Modified as part of GTMS-21910
global class JobReCalculateQuote implements Database.Batchable<sObject>, Schedulable, Database.Stateful {    
    global Boolean recalculateQuote ;
    global String queryString;
    global String intialQueryString;
    global Integer batchSize;
    
    global Set<string> quoteIds = new Set<string>();
    global Set<string> qteIdRecalcFalse = new Set<string>();
    global set<string> QuotetoUpdate = new Set<string>();
    global String DataValidationWeeklyEmailAddress = System.Label.DataValidation_WeeklyReport_EmailAddress;
            
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    public List<Log__c> logListBefore = new List<Log__c>();

    global JobReCalculateQuote(Boolean recalculateQuote, String query ){
        this.recalculateQuote = recalculateQuote;
        this.intialQueryString = String.isNotBlank(query)?query:getQueryforUpdateFalse();
        List<Opportunity> oppList = Database.query(this.intialQueryString);
        Set<Id> qteIds= new Set<Id>();
        System.debug('@@@@oppty size is:  '+oppList.size());
        for(Opportunity opp : oppList) {
            if(opp.SBQQ__PrimaryQuote__c != null){
                qteIds.add(opp.SBQQ__PrimaryQuote__c);
            } 
        }
        Set<string> qteIdNeedRecalc = new Set<string>();
        if(qteIds.size()>0){
            GS_SBQQQuoteService.sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesAndQuoteLinesById(qteIds);
			for(SBQQ__Quote__c qte: GS_SBQQQuoteService.sourceQuoteData.values()){
                if(GS_SBQQQuoteService.getRenewalDataErrorCategoryType(qte)){
                    if(qte.Recalculate_Quote__c==false){
                        qteIdRecalcFalse.add(qte.id);
                    }else{
                        qteIdNeedRecalc.add(qte.id);
                    }
                    Log__c logRecord = new Log__c();
                    logRecord.Quote__c = qte.Id;
                    logRecord.Opportunity__c = qte.SBQQ__Opportunity2__c;
                    logRecord.ClassName__c = 'JobReCalculateQuote';
                    logRecord.Type__c = 'Renewal Validation Job';
                    logRecord.Message__c = 'Erros Before Job';
                    logRecord.ExceptionMessage__c = qte.Renewal_Data_Error_Category__c;
                    logRecord.StackTrace__c = null;
                    logRecord.Exception_Type__c = null;
                    logRecord.LogLevel__c = 'Info';
                    logListBefore.add(logRecord);
                }
                  
            } 
            if(logListBefore.size() > 0){ 
                try{
                    Database.insert(logListBefore, false);
                }catch(Exception e){
                    System.debug('e.getMessage()====='+e.getMessage());
                }
            }
            
        }
        this.queryString = getFinalQuery(qteIdNeedRecalc);
        
    }
    
    global JobReCalculateQuote( Integer batchSize){
        this.batchSize = batchSize;
    }
    
    global JobReCalculateQuote(Boolean recalculateQuote,Set<string> quoteIds ,String query){
        this.recalculateQuote = recalculateQuote;
        this.quoteIds = quoteIds;
        
        this.queryString = String.isNotBlank(query)?query:getFinalQuery(quoteIds);
        
    }
    
    global void execute(SchedulableContext sc) {
        
        if(Test.isRunningTest()){
            batchSize=10;
        }
        JobReCalculateQuote job = new JobReCalculateQuote(false,null);
        ID batchprocessid = Database.executeBatch(job,batchSize); 
    }  
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return  Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> quoteList) {
        system.debug('quoteList joshnaaaa'+quoteList);
        system.debug('quoteList size joshnaaaa'+quoteList.size());
        for (SBQQ__Quote__c qte : quoteList) {   
           qte.Recalculate_Quote__c = recalculateQuote;
            	if(qte.Shipping_Address_NEW__c == null){
                    qte.Shipping_Address_NEW__c = qte.SBQQ__Opportunity2__r.Shipping_Address_NEW__c !=null ?qte.SBQQ__Opportunity2__r.Shipping_Address_NEW__c : qte.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Shipping_Address_NEW__c;
                }
                if(qte.Selected_Payment_Type__c == null && qte.Process_Eligibility__c != 'Digital Renewals'){
                    qte.Selected_Payment_Type__c = qte.SBQQ__Opportunity2__r.Selected_Payment_Type__c !=null ?qte.SBQQ__Opportunity2__r.Selected_Payment_Type__c : qte.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c;
                }
            QuotetoUpdate.add(qte.Id);
        }
        if(recalculateQuote == false ){
            TriggerHandler.bypass('GS_OpportunityTriggerHandler');
            TriggerHandler.bypass('OpportunityTriggerHandler');
            TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
            TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
            TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
            TriggerHandler.bypass('AccountTriggerHandler');
            SBQQ.TriggerControl.disable();
        }
        if(recalculateQuote == true){
            GS_SBQQQuoteService.reCalculateJobTaxCalc = true;
            SBQQ.TriggerControl.enable();
            TriggerHandler.clearAllBypasses();
        }
        try{
           update quoteList;
        } catch (Exception e)
        {
            System.debug('e.getMessage()====='+e.getMessage());
            thisLogger.logError('JobReCalculateQuote. Error Message ::'+ e.getMessage());
            
        } finally{
            SBQQ.TriggerControl.enable();
            TriggerHandler.clearAllBypasses();
            thisLogger.dispatch();
        }       
    }
    
    global void finish(Database.BatchableContext BC) { 
        
        if(recalculateQuote == false){
            if(qteIdRecalcFalse.size()>0){
                QuotetoUpdate.addall(qteIdRecalcFalse);
            }
            JobReCalculateQuote recalculate = new JobReCalculateQuote(true,QuotetoUpdate,null);
            ID batchprocessid = Database.executeBatch(recalculate,1); 
            
        }else if(recalculateQuote == true || Test.isRunningTest()){
         ID jobID = System.enqueueJob(new AsyncJobReCalculateQuote(QuotetoUpdate),Integer.Valueof(System.Label.RenewalJobRecalcTimeDelay)); 
        }
        Datetime dt = DateTime.now();
		String dayOfWeek = dt.format('EEEE');
		System.debug('~~~~~~~~~ ::'+dayOfWeek);
        if((dayOfWeek == 'Monday' && recalculateQuote == true) || Test.isRunningTest()){
        String emailBody='';
            
            String startDate = string.valueof(Date.today().addDays(-7)); //Dec 2
            String endDate = string.valueof(Date.today().addDays(-1)); //Dec 8
            String jobDays = string.valueof(Date.today().addDays(88));
            List<Opportunity> weeklyRecords = getQueryforWeeklyReport((Date.today().addDays(-7)),(Date.today().addDays(88)));
            List<AggregateResult> logErrors = [SELECT count(id) TotalRecords, Message__c, DAY_ONLY(CreatedDate) FROM log__c
                                      WHERE ClassName__c ='JobReCalculateQuote' and Type__c = 'Renewal Validation Job' and
                                      CreatedDate <= YESTERDAY and CreatedDate >= LAST_N_DAYS:8 group by DAY_ONLY(CreatedDate),Message__c order by DAY_ONLY(CreatedDate) asc,Message__c desc];
            Integer index=0;
            Integer issuesIdentified = 0;
            Integer issuesneedManualFix = 0;
            Integer issuesJobFixed = 0;
            Integer beforeJobValue =0;
           	Integer afterJobValue=0;
            
            for(AggregateResult lE:logErrors){
                
                if(String.valueOf(lE.get('Message__c')) =='Erros Before Job'){
                     beforeJobValue=Integer.valueOf(lE.get('TotalRecords'));
                    if(index == 0){
                        issuesIdentified = Integer.valueOf(lE.get('TotalRecords'));
                    }if(index > 0){
                        issuesIdentified += (beforeJobValue-afterJobValue);
                    }
                    afterJobValue=0;
                }else{
                    if(index == logErrors.size()-1){
                        issuesneedManualFix=Integer.valueOf(lE.get('TotalRecords'));
                    }
                     afterJobValue=Integer.valueOf(lE.get('TotalRecords'));
                     issuesJobFixed += (beforeJobValue-afterJobValue);
                     beforeJobValue=0;
                     //afterJobValue=0;
                }
                
                index++;
            }
            String text0 = 'Weekly Report Date Range : '+startDate +' '+ '<==>'  +' '+ endDate;
            String text1 = 'Total number of Records Processed : '+weeklyRecords.size();
            String text2 = 'Issues Identified : '+issuesIdentified;
            String text3 = 'Issues Resolved by Job : '+issuesJobFixed;
            String text4 = 'Issues Need Manual Fix : '+issuesneedManualFix;
            	emailBody= text0+'\r\n'+text1+'\r\n'+text2+'\r\n'+text3+'\r\n'+text4+'\r\n';
                 List<String> toEmail=new List<String>();
                for(String e:DataValidationWeeklyEmailAddress.split(',')){
                    if(String.isNotBlank(e)){
                        toEmail.add(e.trim());
                    }
                }
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toEmail);
                email.setSubject('Weekly Renewal Validation Job Report');
                email.setPlainTextBody(emailBody);
                if(!test.isRunningTest())
        		{			
                Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});   
                }
            }
        
    }
    
    
       
    public String getQueryforUpdateFalse(){
        String query = System.label.Job_Recalculate_Quote_Query;
        return query;
        
    }

    public String getFinalQuery(Set<string> qteIds) {
        this.quoteIds = qteIds;
        String query = 'Select Id, Process_Eligibility__c, Recalculate_Quote__c,Shipping_Address_NEW__c,Selected_Payment_Type__c,SBQQ__Opportunity2__r.Shipping_Address_NEW__c, SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Shipping_Address_NEW__c, ';
        query += 'SBQQ__Opportunity2__r.Selected_Payment_Type__c, SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c from SBQQ__Quote__c where Id IN: quoteIds';
        return query;
    }
    
    public List<Opportunity> getQueryforWeeklyReport(Date startDate,Date jobDays){
        String query = 'Select Id, SBQQ__PrimaryQuote__c From Opportunity WHERE SBQQ__PrimaryQuote__c !=null AND Probability <95 and SBQQ__RenewedContract__c !=null AND Probability!=0 AND IsClosed =false AND Type=\'Revenue Opportunity\' and (Renewal__c =true OR SBQQ__Renewal__c =true) and (Owner.Name like \'%Renewal Pool%\' OR Owner.Name like \'%Elan%\' OR Owner.Name like \'%Robert%\' OR Owner.Name like \'%Renewal Bot%\') AND SBQQ__RenewedContract__r.EndDate<=:jobDays AND SBQQ__RenewedContract__r.EndDate >= :startDate and SBQQ__RenewedContract__r.Deactivated__c=false and SBQQ__RenewedContract__c NOT In (Select Contract__c from Contract_Consolidation_Request__c) and SBQQ__PrimaryQuote__c not in (select SBQQ__Quote__c from SBQQ__QuoteLine__c where SBQQ__ProductCode__c like \'%LIC-VS2-ENT%\' and SBQQ__Quote__r.SBQQ__Opportunity2__r.PriceBook2Id!=\'01s1a000002BkEkAAK\')';
        
        //String query = System.label.Job_Weekly_Query;
        List<Opportunity> oppLst = Database.query(query);
        return oppLst;
        
    } 
   
}