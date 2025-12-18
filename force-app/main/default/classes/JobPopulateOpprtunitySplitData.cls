/*
    ******************************************************************************
    Apex Class Name    : JobPopulateOpprtunitySplitData
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

/*CRON :JobPopulateOpprtunitySplitData m = new JobPopulateOpprtunitySplitData(null,null,false);
        String seconds = '0'; //Execute at Zero Seconds
        String minutes = '0'; //Execute at every 0 minute of hour
        String hours = '21'; // Execute at 1 AM
        String dayOfMonth = '?'; // Execute Every Day of the Month
        String month = '*'; //Execute every Month
        String dayOfWeek = '*'; //Execute on all 7 days of the Week
        
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek;
        //String sch = '0 0 01 * * ?';
        system.schedule('JobPopulateOpprtunitySplitData Run Every Day at 9pm', sch, m); */  
        global class JobPopulateOpprtunitySplitData implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
            global Map<String,String> mapFailedRecords=new Map<String,String>();
            global String query = '';
            global final String opportunityId;
            //global final Boolean chainNextJob;
            global String OppSplitEmailAddress = System.Label.RattleSnake_OpportunitySplitJobEmailAddresses;
          //  global string getmonthcondition = (Date.Today().toStartofWeek().month() != Date.Today().month())?' (CloseDate = LAST_N_MONTHS:2 OR CloseDate = THIS_MONTH )':' (CloseDate = LAST_N_MONTHS:1 OR CloseDate = THIS_MONTH )';

            global JobPopulateOpprtunitySplitData (String query, String opportunityId) { 
                String selectStatement='Select Id,IsClosed,IsWon,Went_to_closed_won_date__c,Went_to_closed_lost_date__c,CreatedDate,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c, Split_New_ACV__c,Split_Renewal_ACV__c, SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.Health_Status__c, SBQQ__RenewedContract__r.HWM_Threshold__c, SBQQ__RenewedContract__r.Rolling_off_HWM__c,of_LIC_Products__c,Returning_Opportunity__c,Returning_Opportunity__r.of_LIC_Products__c,Returning_Opportunity__r.ACV_Bookings_SOT__c,Returning_Opportunity__r.Split_Renewal_ACV__c,AccountId, SBQQ__RenewedContract__r.EndDate, SBQQ__RenewedContract__r.SBQQ__Opportunity__c From Opportunity ';
                //get Query from the batch job or from the custom label
                if(String.isNotBlank(query)){
                    String escapedStrQuery = query;
                    this.query = escapedStrQuery;
                }
                else{  
                    // this.query = selectStatement+' Where Overwrite_Split_Values__c = false AND Account.Exclude_HWM__c=false AND (((Type=\'Remorse Refund\' OR (Type=\'Rebate\'  AND Rebate_Type__c =\'Delinquent\')) AND IsWon=true) OR Type=\'Revenue Opportunity\') AND ACV_Bookings_SOT__c !=0 AND Account.CurrencyIsoCode IN (\'USD\',\'CAD\',\'MXN\') AND Account.Segment__c IN (\'Enterprise\',\'AE3\') AND (( CloseDate>=2024-02-04 AND CloseDate<=Next_N_DAYS:365 AND ISClosed = false) OR (ISClosed = true AND '+ getmonthcondition +' ) )';
                    this.query = selectStatement+' Where  Account.Exclude_HWM__c=false AND (((Type=\'Remorse Refund\' OR (Type=\'Rebate\'  AND Rebate_Type__c =\'Delinquent\')) AND IsWon=true) OR Type=\'Revenue Opportunity\') AND Account.CurrencyIsoCode IN (\'USD\',\'CAD\',\'MXN\') AND Account.Segment__c IN (\'Enterprise\',\'AE3\') AND (NOT Account.Owner_Role__c  LIKE \'%COR%\') AND CloseDate>=2024-02-04 AND CloseDate<=Next_N_DAYS:365 ';
                	//this.query = selectStatement+' Where id in (\'006ct000001q80vAAA\',\'006ct000001qEr7AAE\',\'006ct000001qCFpAAM\')';
                    this.query += ' AND Id NOT IN (SELECT Revenue_Opportunity__c FROM Related_Opportunity__c)';

                system.debug('inn JobPopulateOpprtunitySplitData'+this.query);
                }
                // check if the opportunityId is not blank
                if(String.isNotBlank(opportunityId)){
                    this.opportunityId=opportunityId;
                    String condition = selectStatement+' Where ID = \''+String.escapeSingleQuotes(opportunityId)+'\'';
                    condition += ' AND Id NOT IN (SELECT Revenue_Opportunity__c FROM Related_Opportunity__c)';

                    this.query  =  condition;
                }
                this.query+=' Order by Went_to_closed_won_date__c ASC NULLS LAST, CreatedDate ASC';
                  system.debug('this.query with condition====:'+this.query);
            }            
            global void execute(SchedulableContext sc) {
                JobPopulateOpprtunitySplitData job = new JobPopulateOpprtunitySplitData(null,null);
                ID batchprocessid = Database.executeBatch(job,1); 
            }  
            global Database.QueryLocator start(Database.BatchableContext BC) {
                //Convert into Label
                //create split on closed lost when the reason is not equal to Admin?
                //Select Id From Opportunity Where ((IsClosed=true And IsWon=true and CloseDate>=Yesterday) OR IsClosed=false) AND (Type IN ('Remorse Refund','Revenue Opportunity' ) OR (Type='Rebate'  AND Rebate_Type__c ='Delinquent' )) AND CloseDate>=2024-02-04 AND ACV_Bookings_SOT__c !=0 AND CurrencyIsoCode IN ('USD','CAD','MXN') 


                //backfill data Select Id,StartDate,SBQQ__Opportunity__r.CloseDate,SBQQ__Opportunity__r.License_Start_Date__c From Contract Where StartDate>=2024-02-04
                //fix CloseDate>=2024-02-04 AND CloseDate<=Next_N_DAYS:1000 
                //String query1='Select Id From Contract where  RecordTypeName__c!=\'Free Trial\' AND Account.Segment__c IN (\'Enterprise\',\'AE3\') AND Account.CurrencyIsoCode IN (\'USD\',\'CAD\',\'MXN\')  AND SBQQ__Opportunity__c!=null ';
                /*return Database.getQueryLocator([Select Id,CloseDate,SBQQ__AmendedContract__c,License_Term__c, SBQQ__RenewedContract__c, Type,Rebate_Type__c,StageName,ACV_Bookings_SOT__c,
                Split_New_ACV__c,Split_Renewal_ACV__c,
                SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c,SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate ,SBQQ__AmendedContract__r.HWM_Value__c, 
                SBQQ__AmendedContract__r.HWM_Threshold__c, SBQQ__AmendedContract__r.Rolling_off_HWM__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__c, 
                SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.HWM_Value__c, SBQQ__RenewedContract__r.HWM_Threshold__c, 
                SBQQ__RenewedContract__r.Rolling_off_HWM__c  
                From Opportunity
                Where  Account.Exclude_HWM__c=false AND (((Type='Remorse Refund' OR (Type='Rebate'  AND Rebate_Type__c ='Delinquent')) AND IsWon=true) OR Type='Revenue Opportunity') AND 
                ACV_Bookings_SOT__c !=0 AND CurrencyIsoCode IN ('USD','CAD','MXN') AND Account.Segment__c IN ('Enterprise','AE3') AND CloseDate>=2023-02-04 AND CloseDate<=Next_N_DAYS:1000 ]);*/
                return Database.getQueryLocator(this.query);                
            }
        
            global void execute(Database.BatchableContext BC, List<Opportunity> oppList) {
                try{
                    if(oppList!=null && oppList.size()>0){
                        if(
                            oppList.size()==1 && 
                            ( 
                                String.isNotBlank(opportunityId) ||
                                oppList[0].IsClosed==false || 
                                (
                                    (oppList[0].IsClosed==true && oppList[0].Type!='Revenue Opportunity' && oppList[0].CloseDate>=Date.today().addDays(-1)) || 
                                    (oppList[0].IsClosed==true && oppList[0].IsWon==true && oppList[0].Type=='Revenue Opportunity' && oppList[0].Went_to_closed_won_date__c!=null && oppList[0].Went_to_closed_won_date__c>=Date.today().addDays(-1)) ||
                                    (oppList[0].IsClosed==true && oppList[0].IsWon==false  && oppList[0].Type=='Revenue Opportunity' && oppList[0].Went_to_closed_lost_date__c!=null && oppList[0].Went_to_closed_lost_date__c>=Date.today().addDays(-1))
                                )
                            )
                        ){
                            //added for Expansion
                            List<Related_Opportunity__c> relatedOpportunities = new List<Related_Opportunity__c>();
                            System.debug('0======');
                            Opportunity opp=oppList[0];
                            Opportunity oppOldCopy=opp.clone();
                            //find the HWM including consolidated contract
                            
                            system.debug('opp.Type:==='+opp.Type);
                            system.debug('opp.StageName:==='+opp.StageName);
                            system.debug('opp.SBQQ__AmendedContract__c:==='+opp.SBQQ__AmendedContract__c);
                            system.debug('opp.SBQQ__RenewedContract__c:==='+opp.SBQQ__RenewedContract__c);
                                system.debug('opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__c:==='+opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__c);
                                system.debug('opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c:==='+opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c);
                                //if(opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__c!=null &&  opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c==null){
                                    //New Opp
                                    if(opp.SBQQ__AmendedContract__c==null && opp.SBQQ__RenewedContract__c==null){
                                        opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                                        opp.Split_Renewal_ACV__c=0;
                                        //set commission fields
                                        System.debug('1======');
                                    }
                                    //Renewal oppty
                                   // else 
                                    ///Find Consumed ACV Start   
                                    Set<Id> oppIDs=new Set<Id>();
                                    Decimal contractConsumedRenewalACV=0,contractConsumedACV=0,totalACVBookingsSOT=0;
                                    Decimal currentHWM=0;
                                    if(opp.SBQQ__RenewedContract__c!=null){
                                        oppIDs.add(opp.Id);
                                        Map<Id,Opportunity> allRenewals=new Map<Id,Opportunity>([Select Id From Opportunity where SBQQ__RenewedContract__c=:opp.SBQQ__RenewedContract__c AND IsClosed=true and IsWon=true]);
                                        List<Contract> allRenewedContracts=[Select Id From Contract where SBQQ__Opportunity__c=:allRenewals.keySet()];
                                        Map<Id,Opportunity>  allAmendmentOpps=new Map<Id,Opportunity>([Select Id From Opportunity where SBQQ__AmendedContract__c=:allRenewedContracts  AND IsClosed=true and IsWon=true]);
                                        if(allRenewals.size()>0){
                                            oppIDs.addAll(allRenewals.keySet());
                                        }
                                        if(allAmendmentOpps.size()>0){
                                            oppIDs.addAll(allAmendmentOpps.keySet());
                                        }   
                                        for(Opportunity o:[Select Id,Went_to_closed_won_date__c,CreatedDate,IsClosed,IsWon,Split_Renewal_ACV__c,Split_New_ACV__c,ACV_Bookings_SOT__c  From Opportunity where Id=:oppIDs Order by Went_to_closed_won_date__c ASC, CreatedDate ASC ]){
                                            if(o.Id!=opp.Id && o.Split_Renewal_ACV__c!=null && o.Went_to_closed_won_date__c<=opp.Went_to_closed_won_date__c){
                                                contractConsumedRenewalACV+=o.Split_Renewal_ACV__c;
                                                system.debug('here 1'+contractConsumedRenewalACV);
                                            }
                                            if(o.Id!=opp.Id && o.Split_New_ACV__c!=null && o.Went_to_closed_won_date__c<=opp.Went_to_closed_won_date__c){
                                                contractConsumedACV+=o.Split_New_ACV__c;
                                                system.debug('here 2'+contractConsumedACV);
                                            }  
                                            if(o.Id==opp.Id || o.Went_to_closed_won_date__c<=opp.Went_to_closed_won_date__c){
                                                totalACVBookingsSOT+=o.ACV_Bookings_SOT__c;
                                                system.debug('here 3'+totalACVBookingsSOT);
                                            }                                          
                                            
                                        }  
                                        
                                        Set<Id> consolidatedMasterContract=new Set<Id>();
                                        //consolidatedMasterContract.add(c.SBQQ__Opportunity__r.SBQQ__RenewedContract__r.Consolidated_Master_Contract__c);
                                        consolidatedMasterContract.add(opp.SBQQ__RenewedContract__c);                                        
                                        for(Contract c: [Select Id,HWM_Value__c, Health_Status__c From Contract Where ((Consolidated_Master_Contract__c!=null AND Consolidated_Master_Contract__c=:consolidatedMasterContract) OR (SBQQ__RenewalOpportunity__c=:opp.Id OR Id=:opp.SBQQ__RenewedContract__c )) AND HWM_Value__c!=null AND HWM_Value__c!=0]){
                                            System.debug('c.Id======'+c.Id);
                                            currentHWM+=c.HWM_Value__c;
                                        }                                                                         
                                    }                                            
                                    ///Find Consumed ACV End                                   
                                    if(opp.Type=='Revenue Opportunity' && opp.StageName!='Closed Lost' && opp.SBQQ__AmendedContract__c==null && opp.SBQQ__RenewedContract__c!=null){

                                        System.debug('1.1======');
                                        System.debug('currentHWM======'+currentHWM);
                                        System.debug('contractConsumedRenewalACV======'+contractConsumedRenewalACV);
                                        System.debug('contractConsumedACV======'+contractConsumedACV);
                                        System.debug('totalACVBookingsSOT======'+totalACVBookingsSOT);
                                        System.debug('opp.SBQQ__RenewedContract__r.HWM_Threshold__c======'+opp.SBQQ__RenewedContract__r.HWM_Threshold__c);
                                        if(currentHWM!=null && currentHWM!=0 && opp.SBQQ__RenewedContract__r.HWM_Threshold__c!=null && opp.SBQQ__RenewedContract__r.HWM_Threshold__c!=0){
                                            System.debug('1.2======');
                                            Decimal renewalCap=currentHWM*opp.SBQQ__RenewedContract__r.HWM_Threshold__c/100;
                                            System.debug('renewalCap======'+renewalCap);
                                            System.debug('opp.ACV_Bookings_SOT__c****'+opp.ACV_Bookings_SOT__c);
                                            System.debug('currentHWM****'+currentHWM);
                                            opp.Split_New_ACV__c=totalACVBookingsSOT-contractConsumedACV-currentHWM;
                                            System.debug('opp.Split_New_ACV__c============='+opp.Split_New_ACV__c);
                                            System.debug('totalACVBookingsSOT-contractConsumedACV-currentHWM==='+(totalACVBookingsSOT-contractConsumedACV-currentHWM));
                                            ///////////////////Code For Accounts for Life project start///////////////////////////
                                            if(opp.IsClosed==true && opp.StageName == 'Closed Won'){
                                                Date sixMonthsBeforeRenewal = opp.SBQQ__RenewedContract__r.EndDate.addMonths(-6);
                                                System.debug('sixMonthsBeforeRenewal===='+sixMonthsBeforeRenewal);

                                                List<Opportunity> expansionOpps = [
                                                    SELECT Id,AccountId, ACV_Bookings_SOT__c, CloseDate,SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, SBQQ__AmendedContract__r.StartDate,
                                                    SBQQ__AmendedContract__r.SBQQ__Opportunity__c,SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c,
                                                        (Select Remaining_Split_Renewal_Expansion__c From Related_Opportunities1__r order by CreatedDate DESC limit 1)
                                                    FROM Opportunity
                                                    WHERE AccountId = :opp.AccountId AND IsClosed = true AND IsWon = true AND Type ='Revenue Opportunity' 
                                                    AND (
                                                            (SBQQ__RenewedContract__c = null AND SBQQ__AmendedContract__c != null AND 
                                                            SBQQ__AmendedContract__r.SBQQ__Opportunity__c!=null  AND  
                                                            SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c=null)
                                                        OR
                                                            (SBQQ__RenewedContract__c = null AND SBQQ__AmendedContract__c = null)
                                                    )
                                                    AND Id !=:opp.SBQQ__RenewedContract__r.SBQQ__Opportunity__c
                                                    AND Went_to_closed_won_date__c <= :opp.Went_to_closed_won_date__c
                                                    AND CloseDate >= :sixMonthsBeforeRenewal AND CloseDate <= :opp.SBQQ__RenewedContract__r.EndDate AND Id != :opp.Id AND ACV_Bookings_SOT__c > 0
                                                    AND Id NOT IN (SELECT Renewal_of_Expansion_Opportunity__c 
                                                                    FROM Related_Opportunity__c 
                                                                    WHERE Renewal_of_Expansion_Opportunity__r.AccountId = :opp.AccountId 
                                                                    AND Remaining_Split_Renewal_Expansion__c <= 0)
                                                    ORDER BY Went_to_closed_won_date__c ASC 
                                                ];
                                                
                                                System.debug('expansionOpps===='+expansionOpps);
                                                System.debug('currentHWM===='+currentHWM);
                                                Decimal hwmThreshold = (opp.SBQQ__RenewedContract__r.HWM_Threshold__c/100) * currentHWM;
                                                //Decimal contractConsumedRenewalACV = 500; 
                                                Decimal splitRenewalACV = 0;

                                                System.debug('hwmThreshold===='+hwmThreshold);
                                                if (contractConsumedRenewalACV >= hwmThreshold) {
                                                    splitRenewalACV = 0;
                                                } else {
                                                    Decimal remainingThreshold = hwmThreshold - contractConsumedRenewalACV;
                                                    System.debug('remainingThreshold===='+remainingThreshold);
                                                    Decimal oppACV = opp.ACV_Bookings_SOT__c;
                                                    if (oppACV <= remainingThreshold) {
                                                        splitRenewalACV += oppACV;
                                                        remainingThreshold -= oppACV;
                                                    } else {
                                                        splitRenewalACV += remainingThreshold;
                                                        remainingThreshold = 0;
                                                    }

                                                    

                                                    for (Opportunity expOpp : expansionOpps) {
                                                        //if(expOpp.SBQQ__AmendedContract__c != null && expOpp.SBQQ__AmendedContract__r.StartDate != null && expOpp.SBQQ__AmendedContract__r.StartDate.addmonths(12) > expOpp.CloseDate) continue;
                                                        //&& expOpp.SBQQ__AmendedContract__r.StartDate != null && expOpp.SBQQ__AmendedContract__r.StartDate.addmonths(12) > expOpp.CloseDate
                                                        //if(expOpp.SBQQ__AmendedContract__c != null  && expOpp.SBQQ__AmendedContract__r.SBQQ__Opportunity__c!=null  &&  expOpp.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c!=null ) continue;
                                                        if (remainingThreshold <= 0) break;  
                                                        
                                                        Decimal acvFromExpansion = expOpp.ACV_Bookings_SOT__c;
                                                        system.debug('acvFromExpansion000=='+acvFromExpansion);
                                                       
                                                        if(expOpp.Related_Opportunities1__r.size()==1){
                                                            system.debug('expOpp.Related_Opportunities1__r '+expOpp.Related_Opportunities1__r);
                                                            acvFromExpansion=expOpp.Related_Opportunities1__r[0].Remaining_Split_Renewal_Expansion__c;
                                                            system.debug('acvFromExpansion2222=== '+expOpp.Related_Opportunities1__r[0].Remaining_Split_Renewal_Expansion__c);
                                                        }
                                                        system.debug('acvFromExpansion333=='+acvFromExpansion);
                                                        system.debug('remainingThreshold'+remainingThreshold);

                                                        Decimal amountToUse = Math.min(acvFromExpansion, remainingThreshold);
                                                        splitRenewalACV += amountToUse;
                                                        remainingThreshold -= amountToUse;

                                                        Related_Opportunity__c relatedOpportunity = new Related_Opportunity__c(
                                                            Revenue_Opportunity__c = opp.Id,
                                                            Renewal_of_Expansion_Opportunity__c = expOpp.Id,
                                                            Split_Renewal_Expansion__c = amountToUse,
                                                            Remaining_Split_Renewal_Expansion__c = acvFromExpansion - amountToUse
                                                        );
                                                        relatedOpportunities.add(relatedOpportunity);  
                                                    }

                                                    if (!relatedOpportunities.isEmpty()) {
                                                        System.debug('relatedOpportunities===='+relatedOpportunities);
                                                        
                                                    }
                                                    System.debug('Remaining Threshold after calculation====== ' + remainingThreshold);
                                                }
                                                opp.Split_Renewal_ACV__c = Math.min(splitRenewalACV, hwmThreshold);  
                                                System.debug('opp.Split_Renewal_ACV__c===='+opp.Split_Renewal_ACV__c);
                                            }                                       
                                            ///////////////////Code For Accounts for Life project end///////////////////////////
                                            else{
                                            if(contractConsumedRenewalACV>=renewalCap){
                                                System.debug('2======');
                                                opp.Split_Renewal_ACV__c=0;
                                            }
                                            else if((contractConsumedRenewalACV+opp.ACV_Bookings_SOT__c)<=renewalCap){
                                                System.debug('3======');
                                                opp.Split_Renewal_ACV__c=opp.ACV_Bookings_SOT__c;
                                            }
                                            else if((contractConsumedRenewalACV+opp.ACV_Bookings_SOT__c)>renewalCap){
                                                System.debug('4======');
                                                opp.Split_Renewal_ACV__c=renewalCap-contractConsumedRenewalACV;
                                            }
                                            else{
                                                System.debug('5======');
                                            }
                                            /*if(opp.ACV_Bookings_SOT__c<currentHWM){
                                                opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c-currentHWM;
                                                opp.Split_Renewal_ACV__c=opp.ACV_Bookings_SOT__c;
                                                System.debug('2======');
                                            }            
                                            else if(opp.ACV_Bookings_SOT__c==currentHWM){
                                                opp.Split_New_ACV__c=0;
                                                opp.Split_Renewal_ACV__c=opp.ACV_Bookings_SOT__c;
                                                System.debug('3======');
                                            }
                                            else if(opp.ACV_Bookings_SOT__c>currentHWM && opp.ACV_Bookings_SOT__c<=renewalCap){
                                                opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c-currentHWM;
                                                opp.Split_Renewal_ACV__c=opp.ACV_Bookings_SOT__c;
                                                System.debug('4======');
                                            }
                                            else if(opp.ACV_Bookings_SOT__c>renewalCap){
                                                opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c-currentHWM;
                                                opp.Split_Renewal_ACV__c=renewalCap;
                                                System.debug('5======');
                                            }
                                            else{
                                                System.debug('6======');
                                            }   */         
                                        }
                                        }else{
                                            opp.Split_New_ACV__c=0;
                                            opp.Split_Renewal_ACV__c=0;     
                                            System.debug('6.1======');       
                                        }     
                                    }
                                    else if(opp.Type=='Revenue Opportunity' && opp.StageName=='Closed Lost' && opp.SBQQ__AmendedContract__c==null && opp.SBQQ__RenewedContract__c!=null){
                                        System.debug('currentHWM======'+currentHWM);
                                        System.debug('contractConsumedRenewalACV======'+contractConsumedRenewalACV);
                                        System.debug('totalACVBookingsSOT======'+totalACVBookingsSOT);      
                                        if(totalACVBookingsSOT>=currentHWM){
                                            opp.Split_New_ACV__c=0;
                                        }
                                        if(totalACVBookingsSOT<currentHWM){
                                            opp.Split_New_ACV__c=(totalACVBookingsSOT-currentHWM);
                                        }                                  
                                       // opp.Split_New_ACV__c=-(opp.SBQQ__RenewedContract__r.HWM_Value__c!=null?opp.SBQQ__RenewedContract__r.HWM_Value__c:0);
                                        opp.Split_Renewal_ACV__c=0;        
                                        System.debug('7======');
                                    }
                                    else if(opp.Type=='Revenue Opportunity' && opp.StageName=='Closed Lost' && opp.SBQQ__AmendedContract__c!=null && opp.SBQQ__RenewedContract__c==null){
                                        opp.Split_New_ACV__c=0;
                                        opp.Split_Renewal_ACV__c=0;        
                                        System.debug('7.1======');
                                    }    
                                    //Amendment oppty
                                    
                                    else if(opp.Type=='Revenue Opportunity' && opp.StageName!='Closed Lost' && opp.SBQQ__AmendedContract__c!=null && opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__c!=null  &&  opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.SBQQ__RenewedContract__c!=null){
                                        if(opp.CloseDate<=(opp.SBQQ__AmendedContract__r.StartDate.addMonths(12))){
                                            Decimal amendedContractCap=opp.SBQQ__AmendedContract__r.Rolling_off_HWM__c*opp.SBQQ__AmendedContract__r.HWM_Threshold__c/100;
                                            opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                                            System.debug('amendedContractCap==='+amendedContractCap);
                                            System.debug('opp.ACV_Bookings_SOT__c==='+opp.ACV_Bookings_SOT__c);
                                            System.debug('opp.Split_New_ACV__c==='+opp.Split_New_ACV__c);
                                            System.debug('opp.SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c===='+opp.SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c);
                                            Decimal amendedContractCapConsumed=amendedContractCap;
                                            if(opp.SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c!=null){
                                                amendedContractCapConsumed=amendedContractCap-opp.SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c;
                                            }
                                            if(opp.Split_New_ACV__c!=null && opp.IsClosed && opp.SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c!=null){
                                                amendedContractCap=amendedContractCap-(opp.SBQQ__AmendedContract__r.Consumed_Renewal_ACV__c-opp.Split_New_ACV__c);
                                            }                                            
                                            if(opp.ACV_Bookings_SOT__c<=amendedContractCapConsumed && opp.SBQQ__AmendedContract__r.StartDate!=null && opp.SBQQ__AmendedContract__r.StartDate>=Date.newInstance(2024,02,04)){
                                                opp.Split_Renewal_ACV__c=opp.ACV_Bookings_SOT__c;
                                                System.debug('9======');
                                            }
                                            else if(opp.ACV_Bookings_SOT__c>amendedContractCapConsumed && opp.SBQQ__AmendedContract__r.StartDate!=null && opp.SBQQ__AmendedContract__r.StartDate>=Date.newInstance(2024,02,04)){
                                                //need to test if this can be negative or not? if yes then convert into positive
                                                opp.Split_Renewal_ACV__c=amendedContractCapConsumed;
                                                System.debug('10======');
                                            }
                                            else{
                                                opp.Split_Renewal_ACV__c=0;
                                                System.debug('11======');                    
                                            }
                                        }
                                        else if(opp.CloseDate>(opp.SBQQ__AmendedContract__r.StartDate.addMonths(12))){
                                        opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                                        opp.Split_Renewal_ACV__c=0;
                                        System.debug('12======');
                                        } 
                                    }
                            else if(opp.Type=='Revenue Opportunity' && opp.StageName!='Closed Lost' && opp.SBQQ__AmendedContract__c!=null && opp.SBQQ__RenewedContract__c==null){
                                            opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                                            opp.Split_Renewal_ACV__c=0;
                                            System.debug('8======');
                                    }                            
                            //}    
                            else if(opp.Type=='Remorse Refund' && opp.StageName!='Closed Lost' && opp.StageName!='Return Cancelled' && opp.SBQQ__AmendedContract__c!=null && opp.SBQQ__RenewedContract__c==null && opp.Returning_Opportunity__c!=null){                               
                                if((opp.of_LIC_Products__c+opp.Returning_Opportunity__r.of_LIC_Products__c)<=0){
                                opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                                opp.Split_Renewal_ACV__c=0-(opp.Returning_Opportunity__r.Split_Renewal_ACV__c==null?0:opp.Returning_Opportunity__r.Split_Renewal_ACV__c) ; 
                                    System.debug('13.1======');  
                                }
                                else if((opp.of_LIC_Products__c+opp.Returning_Opportunity__r.of_LIC_Products__c)>0 ){
                                    if( (opp.Returning_Opportunity__r.Split_Renewal_ACV__c==null || opp.Returning_Opportunity__r.Split_Renewal_ACV__c==0)){
                                    opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                                    opp.Split_Renewal_ACV__c=0 ;  
                                System.debug('13.1.1======');      
                                    }
                                    else{
                                        Decimal renewalAcv=Math.min(0, ((opp.Returning_Opportunity__r.ACV_Bookings_SOT__c + opp.ACV_Bookings_SOT__c) - opp.Returning_Opportunity__r.Split_Renewal_ACV__c));
                                        opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                                        opp.Split_Renewal_ACV__c=renewalAcv ; 
                                        System.debug('13.1.2======');  
                                    }
                                } 
                                if(opp.SBQQ__AmendedContract__r.StartDate!=null && opp.SBQQ__AmendedContract__r.StartDate<Date.newInstance(2024,02,04)){
                                    opp.Split_Renewal_ACV__c=0;
                                    System.debug('13.1.3======'); 
                                 }                                     
                            }   
                            else if(opp.Type=='Remorse Refund' && (opp.StageName=='Closed Lost' || opp.StageName=='Return Cancelled')  && opp.SBQQ__AmendedContract__c!=null && opp.SBQQ__RenewedContract__c==null){
                                opp.Split_New_ACV__c=0;
                                opp.Split_Renewal_ACV__c=0;  
                                System.debug('13.3======');      
                            }     
                            else if(opp.Type=='Rebate'  && opp.StageName!='Closed Lost' && opp.StageName!='Return Cancelled' && opp.Rebate_Type__c =='Delinquent' && opp.License_Term__c!=null && opp.Returning_Opportunity__c!=null){
                                if((opp.of_LIC_Products__c+opp.Returning_Opportunity__r.of_LIC_Products__c)<=0){
                                opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                                opp.Split_Renewal_ACV__c=0-(opp.Returning_Opportunity__r.Split_Renewal_ACV__c==null?0:opp.Returning_Opportunity__r.Split_Renewal_ACV__c) ; 
                                    System.debug('14.1======');  
                                }
                                else if((opp.of_LIC_Products__c+opp.Returning_Opportunity__r.of_LIC_Products__c)>0 ){
                                    if( (opp.Returning_Opportunity__r.Split_Renewal_ACV__c==null || opp.Returning_Opportunity__r.Split_Renewal_ACV__c==0)){
                                        opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                                        opp.Split_Renewal_ACV__c=0 ; 
                                        System.debug('14.1.1======');  
                                    } 
                                    else{
                                        Decimal renewalAcv=Math.min(0, ((opp.Returning_Opportunity__r.ACV_Bookings_SOT__c + opp.ACV_Bookings_SOT__c) - opp.Returning_Opportunity__r.Split_Renewal_ACV__c));
                                        opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                                        opp.Split_Renewal_ACV__c=renewalAcv ; 
                                        System.debug('14.1.2======');  
                                    }
                                }                                 
                                //opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                              //  opp.Split_Renewal_ACV__c=opp.ACV_Bookings_SOT__c;        
                                System.debug('14======');
                            }    
                            else if(opp.Type=='Rebate'  && (opp.StageName=='Closed Lost' || opp.StageName=='Return Cancelled') && opp.Rebate_Type__c =='Delinquent' && opp.License_Term__c!=null){
                                opp.Split_New_ACV__c=0;
                                opp.Split_Renewal_ACV__c=0;        
                                System.debug('15======');
                            }      
                            
                            if(opp.Type=='Revenue Opportunity' && opp.SBQQ__RenewedContract__c != null && opp.SBQQ__RenewedContract__r.Health_Status__c == 'Unhealthy' && opp.Split_New_ACV__c < 0) {
                            	opp.Split_New_ACV__c = 0;
                            }
                            System.debug('opp.Split_New_ACV__c111====='+opp.Split_New_ACV__c);
                            if(oppOldCopy.Split_New_ACV__c!=opp.Split_New_ACV__c || oppOldCopy.Split_Renewal_ACV__c!=opp.Split_Renewal_ACV__c){
                                System.debug('11111=====');
                                TriggerHandler.bypass('GS_OpportunityTriggerHandler');
                                TriggerHandler.bypass('OpportunityTriggerHandler');
                                
                                opp.Split_New_ACV__c = (opp.Split_New_ACV__c == null)? 0:opp.Split_New_ACV__c;
                                opp.Split_Renewal_ACV__c = (opp.Split_Renewal_ACV__c == null)?0:opp.Split_Renewal_ACV__c;
                                
                                update opp;
                            }
                            else if(opp.StageName=='Closed Won' && (opp.Split_New_ACV__c==null || opp.Split_New_ACV__c==0) && opp.Split_New_ACV__c!=opp.ACV_Bookings_SOT__c){
                                System.debug('222=====');
                                TriggerHandler.bypass('GS_OpportunityTriggerHandler');
                                TriggerHandler.bypass('OpportunityTriggerHandler');
                              //  opp.Split_New_ACV__c=opp.ACV_Bookings_SOT__c;
                                
                                opp.Split_New_ACV__c = (opp.Split_New_ACV__c == null)?0:opp.Split_New_ACV__c;
                                opp.Split_Renewal_ACV__c = (opp.Split_Renewal_ACV__c == null)?0:opp.Split_Renewal_ACV__c;
                                
                                update opp;
                            } else if(opp.Split_New_ACV__c == null  && opp.Split_Renewal_ACV__c == null){
                                System.debug('3333=====');
                                TriggerHandler.bypass('GS_OpportunityTriggerHandler');
                                TriggerHandler.bypass('OpportunityTriggerHandler');
                                opp.Split_New_ACV__c = 0;
                                opp.Split_Renewal_ACV__c =0;
                              update opp;
                            }                            

                            System.debug('opp.Split_New_ACV__c====='+opp.Split_New_ACV__c);
                            System.debug('opp.Split_Renewal_ACV__c====='+opp.Split_Renewal_ACV__c);
                            //added for account expansion
                            if(relatedOpportunities.size() > 0 ){
                                insert relatedOpportunities; 
                            }
                        }
                    }

                }
                catch(Exception ex){
                    mapFailedRecords.put(oppList[0].id,ex.getMessage()+'\r\nStack Trace:'+ex.getStackTraceString());
                }
            }  
        
            global void finish(Database.BatchableContext BC) { 
                String emailBody='';
                if(mapFailedRecords.size()>0 ){
                    emailBody='Failed Records:\r\n';
                    for(String key:mapFailedRecords.keySet()){
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
                email.setSubject('JobPopulateOpprtunitySplitData Processing');
                email.setPlainTextBody(emailBody);
                if(!test.isRunningTest())
        		{		
            		Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});      
                }
                if( Boolean.valueOf(System.Label.Rattlesnake_Execute_NextJob)){
                    JobCreateOpportunitySplit job = new JobCreateOpportunitySplit(null,this.opportunityId);
                    ID batchprocessid = Database.executeBatch(job,1);   
                }    
               
            } 

        }