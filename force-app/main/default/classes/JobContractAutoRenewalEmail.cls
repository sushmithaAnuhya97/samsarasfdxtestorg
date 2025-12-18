/**
 * @description       : https://samsaradev.atlassian.net/browse/GTMS-10567
 * GTMS-13089
 * @author            : navees.ahmed@samsara.com
 * @group             : 
 * @last modified on  : 06-07-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
/*CRON :JobContractAutoRenewalEmail m = new JobContractAutoRenewalEmail();
        String seconds = '0'; //Execute at Zero Seconds
        String minutes = '0'; //Execute at every 0 minute of hour
        String hours = '21'; // Execute at 1 AM
        String dayOfMonth = '?'; // Execute Every Day of the Month
        String month = '*'; //Execute every Month
        String dayOfWeek = '*'; //Execute on all 7 days of the Week
        
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek;
        //String sch = '0 0 01 * * ?';
        system.schedule('JobContractAutoRenewalEmail Run Every Day at 9pm', sch, m); */  
        global class JobContractAutoRenewalEmail implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

            global void execute(SchedulableContext sc) {
                JobContractAutoRenewalEmail job = new JobContractAutoRenewalEmail();
                    ID batchprocessid = Database.executeBatch(job,1); 
            }  
            global Database.QueryLocator start(Database.BatchableContext BC) {
                Date emailDate=Date.today().addDays(Integer.valueOf(Label.Contract_Email_Sending_Days));            
               String query = 'select Id from Contract where Auto_Renewal__c=true AND SBQQ__RenewalOpportunity__c !=null AND SBQQ__RenewalOpportunity__r.IsClosed = false and Opt_Out_of_Auto_Renewal_Emails__c = false  AND EndDate=:emailDate ';
               
                
                return Database.getQueryLocator(query);
            }
            
            global void execute(Database.BatchableContext BC, List<Contract> contractList) {
                if(contractList!=null && contractList.size()>0){
                    Map<String, Object> inputs = new Map<String, Object>();
                    Map<Id,Opportunity> mapRenewalOpportunities=new Map<Id,Opportunity>([Select Id,(Select Id,Product2Id,Product2.Name,Quantity From OpportunityLineItems) From Opportunity Where SBQQ__RenewedContract__c=:contractList]);
                    for(Contract con : [SELECT Id, name, EndDate, SBQQ__RenewalTerm__c,Contract.Account.Name,Contract.Account.CS_POC_Email_Address__c,SBQQ__RenewalQuoted__c,Account.Billing_Contact__c,Account.Billing_Contact__r.Email,Account.Which_written_language__c,SBQQ__RenewalOpportunity__c,
                                        Contract.Account.CS_POC_First_Name__c,Contract.Account.Approved_Payment_Type__c,SBQQ__RenewalOpportunity__r.Selected_Payment_Type__c,SBQQ__RenewalOpportunity__r.ACV_Bookings_SOT__c,
                                        SBQQ__RenewalOpportunity__r.License_Term__c
                                        FROM Contract where ID  IN : contractList]){
                        VariablesForContractFlow fm = new VariablesForContractFlow();
                        if(con.Account.Billing_Contact__c!=null && String.isNotBlank(con.Account.Billing_Contact__r.Email)){
                            fm.BillingContact = con.Account.Billing_Contact__r.Email;
                        }
                        fm.AccountName = con.Account.Name;
                        fm.LicenseInfo='';
                        if(mapRenewalOpportunities.containsKey(con.SBQQ__RenewalOpportunity__c)){
                            Opportunity renewalOpp=mapRenewalOpportunities.get(con.SBQQ__RenewalOpportunity__c);
                            Map<String,Integer> mapProductQuantity=new Map<String,Integer>();
                            for(OpportunityLineItem oli:renewalOpp.OpportunityLineItems){
                                if(!mapProductQuantity.containsKey(oli.Product2.Name)){
                                    mapProductQuantity.put(oli.Product2.Name,0);
                                }
                                mapProductQuantity.put(oli.Product2.Name,mapProductQuantity.get(oli.Product2.Name)+Integer.valueOf(oli.Quantity));
                            }
                            List<String> renewalInfo=new List<String>();
                            for(String key: mapProductQuantity.keySet()){
                                renewalInfo.add(mapProductQuantity.get(key)+' '+key.replace('License for','').trim());
                            }
                            fm.LicenseInfo='\n\t'+String.join(renewalInfo,'\n\t');
                        }
                        if(con.Account.CS_POC_Email_Address__c !=null){
                            fm.AccountPOCEmail = con.Account.CS_POC_Email_Address__c;
                        }
                        fm.AccountPOCFirstName = con.Account.CS_POC_First_Name__c;
                        fm.WrittenLanguage = con.Account.Which_written_language__c;
                        //fm.subList = con.SBQQ__Subscriptions__r;
                           fm.AccountFrequency = con.SBQQ__RenewalOpportunity__r.Selected_Payment_Type__c;
                        fm.ContractEndDate =String.valueOf(con.EndDate) ;
                        fm.EmailDeadline=String.valueOf(con.EndDate.addDays(-(Integer.valueOf(Label.Contract_Email_Sending_Days)-7))) ;
                        fm.UpdatedPayment=''+con.SBQQ__RenewalOpportunity__r.ACV_Bookings_SOT__c;
                        fm.RenewalTerm=''+con.SBQQ__RenewalOpportunity__r.License_Term__c;//con.SBQQ__RenewalTerm__c;
                        if(fm.AccountFrequency=='Direct Monthly'){
                            fm.UpdatedPayment=''+con.SBQQ__RenewalOpportunity__r.ACV_Bookings_SOT__c/12;
                        }
                       fm.AccountFrequency=fm.AccountFrequency.replace('Direct','').trim();
                        /*else if(fm.AccountFrequency=='Direct Annual'){
                            
                        }    */                
                        if(String.isNotBlank(fm.BillingContact) || String.isNotBlank(fm.AccountPOCEmail)){
                            inputs.put('ApexDef',fm);
                        }
                        system.debug('inputs'+inputs);
                        system.debug('fm'+fm);
                        if(inputs.size() >0){
                            Flow.Interview.Contract_renewal_flow flow1 = new Flow.Interview.Contract_renewal_flow(inputs);
                            flow1.start();
                        }
                    }
                }
        
            }  
        
            global void finish(Database.BatchableContext BC) { 
            }  
        }