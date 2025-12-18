/*
    ******************************************************************************
    Apex Class Name    : JobContractHWM
    Created Date       : Dec 12, 2023
    @description       : This is class is used to inser OpportunitySplitRecords
    @author            : Navees
    Modification Log:
    -----------------------------------------------------------------------------
    Version |  Date       |   Author       |    Modification
    -----------------------------------------------------------------------------
    1.0     |  12-12-2023 | Navees        |      Initial Version
    
    *****************************************************************************
    */
/*CRON :JobContractHWM m = new JobContractHWM(null,null);
        String seconds = '0'; //Execute at Zero Seconds
        String minutes = '0'; //Execute at every 0 minute of hour
        String hours = '6,18'; // Execute at 1 AM
        String dayOfMonth = '?'; // Execute Every Day of the Month
        String month = '*'; //Execute every Month
        String dayOfWeek = '*'; //Execute on all 7 days of the Week
        
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek;
        //String sch = '0 0 01 * * ?';
        system.schedule('JobContractHWM Run Every Day at 6am6pm', sch, m); */  
        global class JobContractHWM implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
            global Map<String,String> mapFailedRecords=new Map<String,String>();
            global String query = '';
           // global final Boolean chainNextJob;
            global Map<String,String> failedContracts = new Map<String,String>();
            global String OppSplitEmailAddress = System.Label.RattleSnake_OpportunitySplitJobEmailAddresses;
            global JobContractHWM (String query, String contractId) {
                //get Query from the batch job or from the custom label
                if(String.isNotBlank(query)){
                    String escapedStrQuery = query;
                    this.query = escapedStrQuery;
                }
                else{  
                    //add Deactivated__c=false
                    this.query = System.Label.RattleSnake_JobContractHWM;
                }
                // check if the contractId is not blank
                if(String.isNotBlank(contractId)){
                    String condition = ' Select Id From Contract where ID = \''+String.escapeSingleQuotes(contractId)+'\'';
                    this.query  =  condition;
                }
                this.query+=' Order By CreatedDate ASC';
                system.debug('this.query with condition====:'+this.query);
            }            
            global void execute(SchedulableContext sc) {
                JobContractHWM job = new JobContractHWM(null,null);
                ID batchprocessid = Database.executeBatch(job,1); 
            }  
            global Database.QueryLocator start(Database.BatchableContext BC) {
                //Convert into Label
                //EndDate>=2023-01-01 AND
                ////add logic for Exclude
                //add logic for lastmodified date for oppty to reduce batch size
                //String query1='Select Id From Contract where  RecordTypeName__c!=\'Free Trial\' AND Account.Segment__c IN (\'Enterprise\',\'AE3\') AND Account.CurrencyIsoCode IN (\'USD\',\'CAD\',\'MXN\')  AND SBQQ__Opportunity__c!=null AND Account.Exclude_HWM__c=false order by ID';
                return Database.getQueryLocator(this.query);
            }
        
            global void execute(Database.BatchableContext BC, List<Contract> contractList) {
                try{
                    if(contractList!=null && contractList.size()>0){
                        List<Contract>  listContracts=[Select Id,SBQQ__Opportunity__c,Consumed_Renewal_ACV__c,SBQQ__RenewalOpportunity__c,Contract_Renewable_ACV__c ,HWM_Value__c,HWM_Threshold__c,Rolling_off_HWM__c,
														SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__Opportunity__r.SBQQ__RenewedContract__r.HWM_Value__c,Consolidated_Master_Contract__c,
														SBQQ__Opportunity__r.SBQQ__RenewedContract__r.Consolidated_Master_Contract__c 
                                                        From Contract 
                                                        Where Id =:contractList];
                        if(listContracts.size()==1){
                            Contract c=listContracts[0];
                            Decimal contractHWM=0,contractConsumedRenewalACV=0,contractRollingOffHWM=0;
                            Decimal contractOppHWM_H=0;
                            //,contractOppHWM=0,contractOppHWM_R=0;
                            /*if(c.Contract_Renewable_ACV__c!=null){
                                contractHWM+=c.Contract_Renewable_ACV__c;
                            }*/
                            // add CurrencyIsoCode =’USD’ or “CAD’ or ‘MXN’
                            //check if same renewal opportunity is used for more than one contracts
                            Set<Id> contractIDs=new Set<Id>();
                            Set<Id> oppIDs=new Set<Id>();
                            Set<Id> subOppIDs=new Set<Id>();
                            /*if(c.SBQQ__RenewalOpportunity__c!=null){
                                List<Contract>  listContractWithSameRenewal=[Select Id,SBQQ__Opportunity__c,SBQQ__RenewalOpportunity__c ,Contract_Renewable_ACV__c
                                                                From Contract 
                                                                Where SBQQ__RenewalOpportunity__c=:c.SBQQ__RenewalOpportunity__c AND SBQQ__Opportunity__c!=null];
                                for(Contract conWithSameR:listContractWithSameRenewal){
                                    contractIDs.add(conWithSameR.Id);
                                    oppIDs.add(conWithSameR.SBQQ__Opportunity__c);
                                }
                            }*/
            
                            //for 8001P000000XzuHQAS use case
                            // AND SBQQ__TerminatedDate__c =null
                            for(SBQQ__Subscription__c s:[Select Prior_OppId_Legacy__c,Prior_OppId__c From SBQQ__Subscription__c where SBQQ__Contract__c =:c.Id and ((SBQQ__TerminatedDate__c !=null AND SBQQ__Quantity__c<0) OR (SBQQ__TerminatedDate__c=null)  )]){
                                if(String.isNotBlank(s.Prior_OppId_Legacy__c)){
                                    oppIDs.add(s.Prior_OppId_Legacy__c);
                                    subOppIDs.add(s.Prior_OppId_Legacy__c);
                                }
                                if(String.isNotBlank(s.Prior_OppId__c)){
                                    oppIDs.add(s.Prior_OppId__c);
                                    subOppIDs.add(s.Prior_OppId__c);
                                }                    
                            }
                            if(c.SBQQ__Opportunity__c!=null){
                                Set<Id> consolidatedMasterContract=new Set<Id>();
								consolidatedMasterContract.add(c.SBQQ__Opportunity__r.SBQQ__RenewedContract__r.Consolidated_Master_Contract__c);
								consolidatedMasterContract.add(c.SBQQ__Opportunity__r.SBQQ__RenewedContract__c);
								List<Contract>  listContractWithSameRenewal=[Select Id,HWM_Value__c From Contract Where ((Consolidated_Master_Contract__c!=null AND Consolidated_Master_Contract__c=:consolidatedMasterContract) OR
                                                                            (SBQQ__RenewalOpportunity__c=:c.SBQQ__Opportunity__c OR Id=:c.SBQQ__Opportunity__r.SBQQ__RenewedContract__c)) AND HWM_Value__c!=null AND HWM_Value__c!=0];
                                for(Contract conWithSameR:listContractWithSameRenewal){
                                    contractRollingOffHWM+=conWithSameR.HWM_Value__c;
                                } 
                            }
                            if(String.isNotBlank(c.SBQQ__Opportunity__c)){
                                oppIDs.add(c.SBQQ__Opportunity__c);
                                subOppIDs.add(c.SBQQ__Opportunity__c);
                                if(c.SBQQ__Opportunity__r.SBQQ__RenewedContract__c!=null){
                                    Map<Id,Opportunity> allRenewals=new Map<Id,Opportunity>([Select Id From Opportunity where SBQQ__RenewedContract__c=:c.SBQQ__Opportunity__r.SBQQ__RenewedContract__c AND IsClosed=true and IsWon=true]);
                                    List<Contract> allRenewedContracts=[Select Id From Contract where SBQQ__Opportunity__c=:allRenewals.keySet()];
                                    Map<Id,Opportunity>  allAmendmentOpps=new Map<Id,Opportunity>([Select Id From Opportunity where SBQQ__AmendedContract__c=:allRenewedContracts AND IsClosed=true and IsWon=true]);
                                    if(allRenewals.size()>0){
                                        oppIDs.addAll(allRenewals.keySet());
                                    }
                                    if(allAmendmentOpps.size()>0){
                                        oppIDs.addAll(allAmendmentOpps.keySet());
                                    } 
                                }
                            }                                          
                           // Set<Id> consumedOppIDs=new Set<Id>();        
                        for(Opportunity o:[Select Id,Split_Renewal_ACV__c From Opportunity where (Id=:oppIDs OR (Returning_Opportunity__c=:oppIDs AND Type='Rebate' AND Rebate_Type__c='Delinquent')) AND Split_Renewal_ACV__c!=null AND IsClosed=true AND IsWon=true]){
                            contractConsumedRenewalACV+=o.Split_Renewal_ACV__c;
                          //  consumedOppIDs.add(o.Id);
                        }
                       /* if(consumedOppIDs.size()>0){
                            for(Opportunity o:[Select Id,Split_Renewal_ACV__c From Opportunity where Returning_Opportunity__c=:consumedOppIDs AND Type='Rebate' AND Rebate_Type__c='Delinquent' AND Split_Renewal_ACV__c!=null AND IsClosed=true AND IsWon=true]){
                                contractConsumedRenewalACV+=o.Split_Renewal_ACV__c;
                                }
                        }*/
                        contractIDs.add(c.Id);

            
                            //will there be a subsidy opportunity on renewal opportunity?
                            // OR Contract_ID_Link__c=:contractIDs

                            Map<Id,Decimal> mapOppAmount=new Map<Id,Decimal>();
                            Set<Id> removeOppIDs=new Set<Id>();
                        List<Opportunity> listOpportunities=[Select Id,StageName,ACV_Bookings_SOT__c, Type, Rebate_Type__c ,Sub_Type__c,
                                                                Subsidy_Opportunity__c, Subsidy_Opportunity__r.ACV_Bookings_SOT__c,License_Term__c,
                                                                Renewable_ACV__c,CloseDate,Returning_Opportunity__c,Returning_Opportunity__r.License_Term__c,
                                                                Returning_Opportunity__r.ACV_Bookings_SOT__c,Returning_Opportunity__r.Renewable_ACV__c,
                                                                of_LIC_Products__c,Returning_Opportunity__r.of_LIC_Products__c,Amount,Returning_Opportunity__r.Amount
                                                                From Opportunity 
                                                                Where (Id=:subOppIDs OR SBQQ__AmendedContract__c =:contractIDs OR Returning_Opportunity__c=:subOppIDs)  AND IsClosed=true AND IsWon=true AND 
                                                                License_Term__c!=null AND of_LIC_Products__c!=0];
                            for(Opportunity o:listOpportunities){
                                //System.debug('o.Id===='+o.Id);
                                //add logic for tru-up using subtype
                                /* if(o.Rebate_Type__c=='Subsidy'){
                                contractHWM+=o.ACV_Bookings_SOT__c;
                                }
                                else if(o.Sub_Type__c=='True-Up'){
                                contractHWM+=o.ACV_Bookings_SOT__c;
                                }*/
                                /* if(o.Subsidy_Opportunity__c!=null && o.Subsidy_Opportunity__r.ACV_Bookings_SOT__c!=null){
                                contractHWM+=o.Subsidy_Opportunity__r.ACV_Bookings_SOT__c;
                                contractOppHWM+=o.Subsidy_Opportunity__r.ACV_Bookings_SOT__c;
                                }*/
                                //subOppIDs.contains(o.Id) && 
                                if(((o.Type=='Revenue Opportunity' || o.Type=='Remorse Refund'))  || (o.Type=='Rebate' && o.Rebate_Type__c=='Delinquent')){
                                    /*if(o.License_Term__c>0 && o.License_Term__c<12){
                                        contractOppHWM+=((o.ACV_Bookings_SOT__c/o.License_Term__c)*12);
                                    }
                                    else{
                                        contractOppHWM+=o.ACV_Bookings_SOT__c;
                                    }
                                    if(o.Renewable_ACV__c!=null){
                                        contractOppHWM_R+=o.Renewable_ACV__c;
                                    }*/
                                    if(o.Type=='Rebate' && o.Rebate_Type__c=='Delinquent' && o.Returning_Opportunity__c!=null){
                                        if( o.Returning_Opportunity__c!=null && (o.of_LIC_Products__c+o.Returning_Opportunity__r.of_LIC_Products__c)<=0){
                                            removeOppIDs.add(o.Returning_Opportunity__c);
                                        }                                        
                                        else if(o.CloseDate<Date.newInstance(2023,04,30)){                                                       
                                            if(o.License_Term__c>0 && o.License_Term__c<12 && o.Returning_Opportunity__r.Renewable_ACV__c!=null){
                                                // contractOppHWM_H+=0-o.Returning_Opportunity__r.Renewable_ACV__c;
                                                mapOppAmount.put(o.id,0-o.Returning_Opportunity__r.Renewable_ACV__c);
                                            }
                                            else if( o.Renewable_ACV__c!=null){
                                                //contractOppHWM_H+=o.Renewable_ACV__c;
                                                mapOppAmount.put(o.id,o.Renewable_ACV__c);
                                            }
                                        }
                                        else if(o.CloseDate>=Date.newInstance(2023,04,30)){
                                            if(o.License_Term__c>0 && o.License_Term__c<12 && o.Returning_Opportunity__r.ACV_Bookings_SOT__c!=null){
                                                //contractOppHWM_H+=0-((o.Returning_Opportunity__r.ACV_Bookings_SOT__c/o.Returning_Opportunity__r.License_Term__c)*12);
                                                if(o.closeDate < Date.valueOf(SYSTEM.Label.Annualize_ACV_Date))
                                                {
                                                    mapOppAmount.put(o.id,0-((o.Returning_Opportunity__r.ACV_Bookings_SOT__c/o.Returning_Opportunity__r.License_Term__c)*12));
                                                }else{
                                                    mapOppAmount.put(o.id,0-(o.Returning_Opportunity__r.ACV_Bookings_SOT__c));
                                                }
                                            }
                                            else if(o.ACV_Bookings_SOT__c!=null){
                                                //contractOppHWM_H+=o.ACV_Bookings_SOT__c;
                                                mapOppAmount.put(o.id,o.ACV_Bookings_SOT__c);
                                            }
                                        }                                        
                                    }
                                    else{
                                        if(o.Type=='Remorse Refund' && o.Returning_Opportunity__c!=null && (o.of_LIC_Products__c+o.Returning_Opportunity__r.of_LIC_Products__c)<=0){
                                            removeOppIDs.add(o.Returning_Opportunity__c);
                                        }
                                        else if(o.CloseDate<Date.newInstance(2023,04,30) && o.Renewable_ACV__c!=null){
                                            //System.debug('o.Id E1===='+o.Id);
                                            //contractOppHWM_H+=o.Renewable_ACV__c;
                                            mapOppAmount.put(o.id,o.Renewable_ACV__c);
                                        }
                                        else if(o.CloseDate>=Date.newInstance(2023,04,30)){
                                            if(o.License_Term__c>0 && o.License_Term__c<12 && o.ACV_Bookings_SOT__c!=null){
                                                //contractOppHWM_H+=((o.ACV_Bookings_SOT__c/o.License_Term__c)*12);
                                                if(o.closeDate < Date.valueOf(SYSTEM.Label.Annualize_ACV_Date))
                                                {
                                                   mapOppAmount.put(o.id,((o.ACV_Bookings_SOT__c/o.License_Term__c)*12));
                                                }else{
                                                   mapOppAmount.put(o.id,o.ACV_Bookings_SOT__c);
                                                }
                                            }
                                            else if(o.ACV_Bookings_SOT__c!=null){
                                                //contractOppHWM_H+=o.ACV_Bookings_SOT__c;
                                                mapOppAmount.put(o.id,o.ACV_Bookings_SOT__c);
                                            }
                                        
                                        }
                                    }

                                }
            
                            }
                            Decimal contractOppHWM_H_New=0;
                            for(Id key:mapOppAmount.keySet()){
                                if(!removeOppIDs.contains(key)){
                                    contractOppHWM_H_New+=mapOppAmount.get(key);
                                }
                                
                            }
                            System.debug('removeOppIDs===='+removeOppIDs);
                            System.debug('contractOppHWM_H_New===='+contractOppHWM_H_New);
                            contractOppHWM_H=contractOppHWM_H_New;  
                            if(contractOppHWM_H!=null){
                                contractOppHWM_H=contractOppHWM_H.setScale(2);
                            }
                            if(contractOppHWM_H<0){
                                contractOppHWM_H=0;
                            }
                            if(contractConsumedRenewalACV!=null){
                                contractConsumedRenewalACV=contractConsumedRenewalACV.setScale(2);
                            }
                            if(contractRollingOffHWM!=null){
                                contractRollingOffHWM=contractRollingOffHWM.setScale(2);
                            }                                                        
                            if(c.HWM_Threshold__c==null || c.HWM_Value__c!=contractOppHWM_H || c.Consumed_Renewal_ACV__c!=contractConsumedRenewalACV || contractRollingOffHWM!=c.Rolling_off_HWM__c){
                                c.HWM_Value__c=contractOppHWM_H;
                                c.Consumed_Renewal_ACV__c=contractConsumedRenewalACV;
                               // if(c.SBQQ__Opportunity__r.SBQQ__RenewedContract__c!=null && c.SBQQ__Opportunity__r.SBQQ__RenewedContract__r.HWM_Value__c!=c.Rolling_off_HWM__c){
                                    c.Rolling_off_HWM__c=contractRollingOffHWM;
                              //  }
                                if(c.HWM_Threshold__c==null ){
                                    c.HWM_Threshold__c=Integer.valueOf(System.Label.RattleSnake_HWM_Threshold);//convert into label
                                }
                                TriggerHandler.bypass('ContractTriggerHandler');
                                update c;                
                            }
                        }
            
                    }
                }
                catch(Exception ex){
                    failedContracts.put(contractList[0].id,ex.getMessage()+'\r\nStack Trace:'+ex.getStackTraceString());
                }
            }  
        
            global void finish(Database.BatchableContext BC) { 
                String emailBody='';
                if(mapFailedRecords.size()>0 ){
                    emailBody='Failed Records:\r\n';
                    for(String key:failedContracts.keySet()){
                        emailBody+=key+':'+mapFailedRecords.get(key)+'\r\n';
                    }          
                }
        
                List<String> toEmail=new List<String>();
                for(String e:OppSplitEmailAddress.split(',')){
                    if(String.isNotBlank(e)){
                        toEmail.add(e.trim());
                    }
                }
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toEmail);
                email.setSubject('JobContractHWM Processing');
                email.setPlainTextBody(emailBody);
                if(!test.isRunningTest())
        		{			
                Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});   
                }
                if( Boolean.valueOf(System.Label.Rattlesnake_Execute_NextJob)){
                    JobPopulateOpprtunitySplitData job = new JobPopulateOpprtunitySplitData(null,null);
                    ID batchprocessid = Database.executeBatch(job,1);    
                }   
              
            }  
        }