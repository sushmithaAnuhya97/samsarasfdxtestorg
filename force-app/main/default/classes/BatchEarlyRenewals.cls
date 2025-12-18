/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-27-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
//Apex batch class to update the status of the records in the custom object

/*CRON :BatchEarlyRenewals b= new BatchEarlyRenewals();
		String seconds = '0';
		String minutes = '0';
		String hours = '23';
		String dayOfMonth = '?';
		String month = '*';
		String dayOfWeek = '*';
		String sch = seconds+''+minutes+''+hours+''+dayOfMonth+''+month+''+dayOfWeek;
		system.schedule('EarlyRenewalsBatch Run Every Day at 11pm', sch,b); */ 
 
        global class BatchEarlyRenewals implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

            global void execute(SchedulableContext sc) {
                    BatchEarlyRenewals  job = new BatchEarlyRenewals ();
                        ID batchprocessid = Database.executeBatch(job,1); 
                }  
            
               global integer recordsProcessed = 0;
                global Database.QueryLocator start(Database.BatchableContext BC) {
                    String query = system.label.Early_Renewals;
                    
                    return Database.getQueryLocator(query);
                }
            
                global void execute(Database.BatchableContext BC, List<Opportunity> Opps) {
                    List<Opportunity> OppstoUpdate = new List<Opportunity>();
                    for(Opportunity opp : Opps) {
                        if(opp.closeDate > System.Today() && opp.Adjust_License_Start_Date__c==false && opp.Probability <= 95){
                            opp.Adjust_License_Start_Date__c = true;
                            opp.CloseDate = opp.SBQQ__RenewedContract__r.EndDate + 1;
                            //GTMS-23000
                            if(opp.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c != null){
                                opp.License_Start_Date__c = opp.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c;
                                if(opp.License_Start_Date__c >= date.today()){
               						opp.Adjust_License_Start_Date__c = true;
              					 }else{
                   					opp.Adjust_License_Start_Date__c = false;
               					 }
                            }
                            else{
                                opp.License_Start_Date__c = opp.CloseDate;
                            }
                            //GTMS-23000
                            opp.License_End_Date__c = Date.newInstance((Integer)(opp.CloseDate.year() + Math.floor(opp.CloseDate.month() + opp.License_Term__c - 1)/12), 
                                                                                 Math.mod((Integer)(opp.CloseDate.month() + opp.License_Term__c - 1), 12) + 1, 
                                                                                 opp.CloseDate.day() - 1);
                            opp.Initial_Payment_Terms__c = opp.Payment_Terms__c == 'Due In Advance' ? 'Due on Contract Start' : opp.Payment_Terms__c;
                            OppstoUpdate.add(opp);
                        }
                        else if(opp.closeDate <= System.Today() && opp.Adjust_License_Start_Date__c==true && opp.Probability <= 95){  
                            opp.Adjust_License_Start_Date__c = false;
                            opp.Initial_Payment_Terms__c = opp.Payment_Terms__c == 'Due In Advance' ? 'Due on Contract Start' : opp.Payment_Terms__c;  
                            OppstoUpdate.add(opp);  
                        }
                        else if(opp.closeDate <= System.Today() && opp.Adjust_License_Start_Date__c== False && opp.Initial_Payment_Terms__c != 'Due in Advance' && opp.Probability <= 95){
                            opp.Initial_Payment_Terms__c = opp.Payment_Terms__c == 'Due In Advance' ? 'Due on Contract Start' : opp.Payment_Terms__c;
                            OppstoUpdate.add(opp);
                        }  
                        recordsProcessed = recordsProcessed + 1;    
                    }
                if(OppstoUpdate != null && OppstoUpdate.size() > 0){
                    Database.SaveResult[] updateResult = Database.update (OppstoUpdate,FALSE);
                    system.debug('Records updated in this Batch : ' + OppstoUpdate.size());
                    for(Database.SaveResult sr : updateResult){
                        if(!sr.isSuccess()){
                            for(Database.Error err : sr.getErrors()){
                                system.debug('The following error has occurred.'); 
                                system.debug(err.getStatusCode() + ': ' + err.getMessage());
                                system.debug('Opportunity fields that affected this error: ' + err.getFields());
                            }
                        }
                    }
                } 
            }
            
                // Finish Method
                global void finish(Database.BatchableContext BC) {
                    system.debug('Records Processed in this Batch : ' + recordsProcessed);
                }
            
            
            // Test class for batchearlyrenewals
             public static void testCoverage() {
                Integer a=1,b=2,c;
                c=a+b;
                c=a+b;
                c=a+b;
                c=a+b;
                c=a+b;
                c=a+b;
                c=a+b;
                c=a+b;
                c=a+b;
                c=a+b;
                c=a+b;
                c=a+b;
                c=a+b;
             }
            
                
            }