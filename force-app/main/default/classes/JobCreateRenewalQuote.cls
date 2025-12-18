/*
******************************************************************************
Apex Class Name    : JobCreateRenewalQuote
Created Date       : may 21, 2024
@description       : This is class is used to inser create Renewal Quote
@author            : Visweswara Rao
Modification Log:
-----------------------------------------------------------------------------
Version |  Date       |   Author       |    Modification
-----------------------------------------------------------------------------
1.0     |  05-21-2025 | Visweswara Rao        |      Initial Version
1.1     |  08-26-2024 | Arun Asadi            |      (GTMS-22780): Updating renewal opportunities to 'Proposal' stage 
*****************************************************************************
*/
/*CRON :JobCreateRenewalQuote m = new JobCreateRenewalQuote();
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
global class JobCreateRenewalQuote implements Database.Batchable<sObject> ,Schedulable,  Database.Stateful {
    global Boolean executeFinishBatch = false;
    global Set<string> contractIds;
    global Set<string> accIds = new Set<string>();
    global Integer batchStep;
    global Integer previousStep;
    global string query = 'Select Id,SBQQ__RenewalQuoted__c,Webstore_Renewal_Quote_Step__c,SBQQ__Opportunity__c,SBQQ__Opportunity__r.Selected_Payment_Type__c,SBQQ__RenewalUpliftRate__c,SBQQ__RenewalTerm__c,Selected_Payment_Type__c,AccountId,Account.SBQQ__RenewalPricingMethod__c,ContractTerm,EndDate,Account.Latest_Active_Contract__r.EndDate,Adjusted_RenewalOpp_EndDate__c,SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.Probability from Contract Where ';
    global Date endDateCheck = Date.valueOf(System.label.RenewalQuoteCreationDate);
    global string whereClause = System.label.Digital_Renewals_Threshold +' AND (CreatedDate >= 2021-07-01T00:00:00Z OR Renewal_Data_Clean__c = True) AND SBQQ__Opportunity__c != NULL AND RecordTypeName__c != \'Free Trial\' AND '+
        ' SBQQ__Opportunity__r.Type = \'Revenue Opportunity\' AND Health_Status__c != \'Unaddressable\' AND EndDate != NULL AND SBQQ__RenewalOpportunity__r.isClosed = false AND SBQQ__RenewalOpportunity__r.Probability <= 90 AND '+
        ' EndDate >: endDateCheck AND EndDate <= NEXT_N_DAYS:90   AND SBQQ__RenewalOpportunity__r.Finance_Partner__c=null AND SBQQ__RenewalOpportunity__r.Payment_Type__c <> \'Reseller\' AND ID NOT IN (Select Contract__c from Contract_Consolidation_Request__c) AND Contract_Id_Same_as_Renewal_Opp_Contract__c	= true' ;
    
    global  JobCreateRenewalQuote(){
        
    }
    
    global Map<Integer,RenewalQuoteCreationSteps__mdt> getRenewalSteps{
        get{
            if(getRenewalSteps == null){
                getRenewalSteps = new Map<Integer,RenewalQuoteCreationSteps__mdt>();
                List<RenewalQuoteCreationSteps__mdt> renewalSteps = RenewalQuoteCreationSteps__mdt.getAll()?.values();
                if(renewalSteps != null){
                    for(RenewalQuoteCreationSteps__mdt step:renewalSteps){
                        getRenewalSteps.put(Integer.valueOf(step.Order__c),step);
                    } 
                }
                
                if(Test.isRunningTest()){
                    getRenewalSteps.put(1,new RenewalQuoteCreationSteps__mdt(Payment_Type__c = 'Upfront Payments',Uplift_Percent__c =0,Order__c = 1,Operation_Type__c = 'Create Quote',Batch_Size__c = 10,Partially__c = false) );
                    getRenewalSteps.put(2,new RenewalQuoteCreationSteps__mdt(Payment_Type__c = 'Direct Annual',Uplift_Percent__c =0,Order__c = 2,Operation_Type__c = 'Create Quote',Batch_Size__c = 10,Partially__c = false) );
                    getRenewalSteps.put(3,new RenewalQuoteCreationSteps__mdt(Payment_Type__c = 'Upfront Payments',Uplift_Percent__c =0,Order__c = 3,Operation_Type__c = 'Recalculate Quote',Batch_Size__c = 10,Partially__c =false));
                    getRenewalSteps.put(4,new RenewalQuoteCreationSteps__mdt(Payment_Type__c = 'Direct Annual',Uplift_Percent__c =0,Order__c = 4,Operation_Type__c = 'Recalculate Quote',Batch_Size__c = 10,Partially__c = false));
                    getRenewalSteps.put(5,new RenewalQuoteCreationSteps__mdt(Payment_Type__c = 'Upfront Payments',Uplift_Percent__c =0,Order__c = 5,Operation_Type__c = 'Primary Quote',Batch_Size__c = 1,Partially__c = false));
                }
            } 
            return getRenewalSteps;
        }
        set{
            getRenewalSteps = value; 
        }
    }
    
    /*
@description constructor
*/
    global JobCreateRenewalQuote (Integer batchStep, Set<String> contractIds) {  
        this.contractIds = contractIds;
        if(batchStep  == 1){
            if(contractIds == null){
                query  = query+whereClause +' AND Webstore_Renewal_Quote_Step__c = null ';
            }else{
                query  = query+' Id IN :contractIds';
            } 
        }else if(batchStep > 1){
            this.contractIds = contractIds;
            previousStep = batchStep-1;
            query  = query+'  Webstore_Renewal_Quote_Step__c =:previousStep AND Id IN :contractIds ';
        }
        
        this.batchStep = batchStep;
    }
  /*  global JobCreateRenewalQuote (Integer batchStep,Set<String> contractIds,String async) {  
        
        this.batchStep = batchStep;
    }*/
    
    global void execute(SchedulableContext sc) {
        
        JobCreateRenewalQuote job = new JobCreateRenewalQuote(1,null);
        ID batchprocessid = Database.executeBatch(job,Integer.ValueOf(getRenewalSteps.get(1)?.Batch_Size__c)); 
    }
    /*
* @description start which is used to get the opportunity records whose segment is Enterprise and AE3 
* @return Database.QueryLocator
*/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        return Database.getQueryLocator(this.query);
    }
    /*
* @description execute which is used to delete the existing opportunity split Overlay records and insert the opportunity team and opportunitysplit records
* @param Database.BatchableContext
* @param oppList conatins the list of opportunity records fetched from start method
* @return null
*/
    global void execute(Database.BatchableContext BC, List<Contract> cont) {
       cont = validataingContract(cont);
        if(cont?.size() == 0){
         return ;   
        }
        executeFinishBatch = true;
        if(batchStep != null && getRenewalSteps != null && getRenewalSteps.containsKey(batchStep) && getRenewalSteps.get(batchStep)?.Operation_Type__c == 'Create Quote' ){
            createQuote(cont,getRenewalSteps.get(batchStep));
        }
        if(batchStep != null && getRenewalSteps != null &&  getRenewalSteps.containsKey(batchStep) && getRenewalSteps.get(batchStep)?.Operation_Type__c == 'Primary Quote'){
            Map<string,contract> mapOfcontract = new Map<String,contract>();
            for(contract con:cont){
                mapOfcontract.put(con.Id,con);
            }
            updatePrimaryQuote(mapOfcontract,getRenewalSteps.get(batchStep));
        }
        if(batchStep != null && getRenewalSteps != null &&  getRenewalSteps.containsKey(batchStep) && getRenewalSteps.get(batchStep)?.Operation_Type__c == 'Recalculate Quote'){
            reCalculatingQuote(cont,getRenewalSteps.get(batchStep));
        }
        
        
    }  
    
    public List<contract> validataingContract(List<contract> conList){
        List<contract> contarctList = new List<contract>();
        for(contract con: conList){
            if(con.Id  == con.SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c){
               contarctList.add(con); 
            }
            
            if(contractIds == null ){
                contractIds = new Set<string>();
            }
            
             contractIds.add(con.Id);
        }
        
        return contarctList;
    } 
    
    /*
* @description finish which is used to send status mail after execution of batch
* @param Database.BatchableContext
* @return null
*/
    global void finish(Database.BatchableContext BC) {
        
        if(executeFinishBatch == true && batchStep != null && getRenewalSteps != null &&  getRenewalSteps.containsKey(batchStep+1)){
            ID jobID = System.enqueueJob(new AsyncCreateRenewalQuote(batchStep,contractIds),Integer.Valueof(System.Label.RenewalQuoteCreationTimeDelay)); 
        }
    }
    
    
    public  Void createQuote(List<contract> conts,RenewalQuoteCreationSteps__mdt metadata){
        
        List<Account> accLists = new List<Account>();
        Map<Id, Opportunity> opportunitiesToUpdateMap = new Map<Id, Opportunity>();

        for(contract con:conts){
            con.Selected_Payment_Type__c = metadata?.Payment_Type__c; 
            //Decimal uplift =  metadata?.Uplift_Percent__c/12;
            Decimal uplift =  metadata?.Uplift_Percent__c;
            if(con.Adjusted_RenewalOpp_EndDate__c != null){
                Integer monthsDiff = (con.Account.Latest_Active_Contract__r.EndDate != null && con.EndDate?.monthsBetween(con.Account.Latest_Active_Contract__r.EndDate) != 0 )? con.EndDate?.monthsBetween(con.Account.Latest_Active_Contract__r.EndDate) : 1;
                if (con.Account.Latest_Active_Contract__r.EndDate?.day() > con.EndDate?.day()){
                    monthsDiff++;
                }
                if(monthsDiff == null || monthsDiff < 12){
                    con.SBQQ__RenewalTerm__c = Integer.valueOf(System.Label.Renewal_Term_For_Digital_Renewal);
                }else{
                    con.SBQQ__RenewalTerm__c = monthsDiff; 
                }
                
                
            }else{
                con.SBQQ__RenewalTerm__c = Integer.valueOf(System.Label.Renewal_Term_For_Digital_Renewal);
            }
            //con.SBQQ__RenewalUpliftRate__c = (con.ContractTerm != null)? (con.ContractTerm*uplift).setscale(3):(uplift*1).setscale(3);//metadata?.Uplift_Percent__c*noOfTerms; 
            con.SBQQ__RenewalUpliftRate__c = uplift;
            con.SBQQ__RenewalQuoted__c = false; 
            con.Webstore_Renewal_Quote_Step__c = metadata.Order__c;
            
            if( (string.isBlank(con.Account.SBQQ__RenewalPricingMethod__c) || con.Account.SBQQ__RenewalPricingMethod__c != 'Uplift') && ! accIds.contains(con.AccountId)){
                accLists.add(new Account(Id = con.AccountId,SBQQ__RenewalPricingMethod__c='Uplift' ));
                accIds.add(con.AccountId);
            }

            //GTMS-22780
            if(con.SBQQ__RenewalOpportunity__c != null && con.SBQQ__RenewalOpportunity__r.Probability < 50 ){
                Opportunity opp = new opportunity(Id = con.SBQQ__RenewalOpportunity__c, StageName = 'Proposal');
                opportunitiesToUpdateMap.put(con.SBQQ__RenewalOpportunity__c, opp);
            }
        }


        byPassTriggers();
        
        if(!accLists.isEmpty() && accLists.Size()>0){
            Database.SaveResult[] sR =  DataBase.update(accLists,metadata?.Partially__c);
        }

        //update opportunities -> GTMS-22780
        if(!(opportunitiesToUpdateMap.values()).isEmpty()){
            Database.SaveResult[] oppR =  DataBase.update(opportunitiesToUpdateMap.values(),metadata?.Partially__c);
        }
        
        // update conts;
        Database.SaveResult[] cR =  DataBase.update(conts,metadata?.Partially__c);
        
        for(contract con:conts){
            con.SBQQ__RenewalQuoted__c = true;  
        }
        clearByPassTrigger();
        // update conts;
        Database.SaveResult[] cRS =  DataBase.update(conts,metadata?.Partially__c);
    }
    
    
    
    public void updatePrimaryQuote( Map<string,contract> contractMap,RenewalQuoteCreationSteps__mdt metadata ){
        
        Map<String,List<SBQQ__Quote__c>> contractQuote = new Map<String,List<SBQQ__Quote__c>>();
        
        List<SBQQ__Quote__c> primaryQuoteUpdate = new List<SBQQ__Quote__c>();
        
        List<Contract> conlist = new List<contract>();
        
        Map<String,Decimal> upliftValues = new Map<string,Decimal>();
        
        Boolean quoteSelectedPaymentMatch = false;
        
        SBQQ__Quote__c quoteuplift;
        
        for(SBQQ__Quote__c quote:[Select Id,Co_Term_Contract__c,Selected_Payment_Type__c,SBQQ__Primary__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c,SBQQ__RenewalUpliftRate__c,
                                  SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Id,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.License_Term__c from SBQQ__Quote__c where 
                                  SBQQ__Opportunity2__r.SBQQ__RenewedContract__c IN : contractMap.KeySet() AND
                                  Process_Eligibility__c = 'Digital Renewals' Order By SBQQ__Opportunity2__c ]){
                                      
                                      /*Added These Line For Merge Conflict*/
                                      if(String.isNotBlank(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c) &&
                                         quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c == 'Upfront Payments' && quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.License_Term__c == 12 
                                         && quote.Selected_Payment_Type__c == 'Direct Annual' ){
                                             
                                             primaryQuoteUpdate = new List<SBQQ__Quote__c>();
                                             quote.SBQQ__Primary__c = true;
                                             primaryQuoteUpdate.add(quote);
                                             quoteSelectedPaymentMatch = true;
                                             break; 
                                             
                                         }
                                      
                                      if (String.isNotBlank(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c) &&
                                          quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c == quote.Selected_Payment_Type__c){
                                              quote.SBQQ__Primary__c = true;
                                              primaryQuoteUpdate.add(quote);
                                              quoteSelectedPaymentMatch = true;
                                              continue ;
                                          }                     
                                      
                                      if( quote.Selected_Payment_Type__c == 'Upfront Payments'){
                                          quote.SBQQ__Primary__c = true;
                                          quoteuplift = quote;
                                      }
                                      
                                      
                                      
                                  }
        
        
        if(quoteSelectedPaymentMatch == false && primaryQuoteUpdate.Size() == 0 && quoteuplift != null){
            
            primaryQuoteUpdate.add(quoteuplift);
            
            
        }
        for(SBQQ__Quote__c uplift:primaryQuoteUpdate){
            upliftValues.put(uplift.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Id,uplift.SBQQ__RenewalUpliftRate__c);  
        }
        for(String conId:contractMap.keySet()){
            contract con = contractMap.get(conId);
            con.SBQQ__RenewalUpliftRate__c  = upliftValues.get(conId);
            con.Webstore_Renewal_Quote_Step__c =  metadata?.Order__c;
            conlist.add(con); 
        }
        
        if (!conlist.isEmpty() && conlist.Size()>0){
            byPassTriggers();
            Database.SaveResult[] sR =  DataBase.update(conlist,metadata?.Partially__c); 
        }
        
        if(!primaryQuoteUpdate.isEmpty() && primaryQuoteUpdate.Size()>0){
            clearByPassTrigger();
            Database.SaveResult[] sR =  DataBase.update(primaryQuoteUpdate,metadata?.Partially__c);
            //update primaryQuoteUpdate;
        }
        
        
        
    }
    
    public void reCalculatingQuote(List<Contract> conts,RenewalQuoteCreationSteps__mdt metadata){
        Set<String> conIds =  new Set<string>();
        for(Contract con:conts){
            con.Selected_Payment_Type__c = null;
            con.Webstore_Renewal_Quote_Step__c = metadata?.Order__c;
            conIds.add(con.Id);
        }
        byPassTriggers();
        
        Database.SaveResult[] cR =  DataBase.update(conts,metadata?.Partially__c);
        String selectedPaymentType =  metadata?.Payment_Type__c;
        List<SBQQ__Quote__c> quoteList = [Select Id From SBQQ__Quote__c where SBQQ__Opportunity2__r.SBQQ__RenewedContract__c IN : conIds AND
                                          Selected_Payment_Type__c =: selectedPaymentType  AND     Process_Eligibility__c = 'Digital Renewals' 
                                            Order By SBQQ__Opportunity2__c];
        if(quoteList != null && quoteList.Size()>0){
            
            for(SBQQ__Quote__c quote:quoteList){
                quote.Recalculate_Quote__c  = true;
            }
            clearByPassTrigger();
            // update quoteList;
            Database.SaveResult[] sR =  DataBase.update(quoteList,metadata?.Partially__c);
        }                                  
    }
    
    public void byPassTriggers(){
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        SBQQ.TriggerControl.disable();
    }
    
    public void clearByPassTrigger(){
        TriggerHandler.clearBypass('GS_OpportunityTriggerHandler');
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.clearBypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.clearBypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.clearBypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearBypass('GS_AccountTriggerHandler');
        TriggerHandler.clearBypass('ContractTriggerHandler');
        TriggerHandler.clearBypass('GS_ContactTriggerHandler');
        TriggerHandler.clearBypass('ContactTriggerHandler');
        SBQQ.TriggerControl.enable();
    }
    
}