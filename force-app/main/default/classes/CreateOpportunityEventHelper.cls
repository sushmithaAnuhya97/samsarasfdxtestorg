/*
* 22-Aug-2022 GTMS-8185 Created updateAccounts method for updating Updating account from flow : Create_Opp_for_Converted_Deal_Reg_Lead @Aparna Raypitam.
* 8/25/2022 Siddharth Kumar Mishra (GTMS-8185) - Added code to re-update Account in case of row lock error
* 11/30/2022 Ankit Goswami (GTMS-10340) - Add Number_of_Vehicles__c field into string  and future method.
*/
public class CreateOpportunityEventHelper {
    
    public static void afterInsertOperations(Map<Id, CreateOpportunityEvent__e > oldEventMap, List<CreateOpportunityEvent__e > newEventList){
        SamsaraLoggerService thisLoggerService = new SamsaraLoggerService();
        for (CreateOpportunityEvent__e event : newEventList) {

            if(!String.isBlank(event.Converted_Lead_Id_t__c)) {
                try{
                    Decimal retryCounter = event.Retry_Counter_n__c != null ? Integer.valueOf(event.Retry_Counter_n__c)+1 : 0;
                    Map<String,Object> leadMap = new Map<String, Object >();
                    
                    Lead leadRecord = new Lead();
                    leadRecord.Id = event.Converted_Lead_Id_t__c;
                    leadMap.put('leadRecord', leadRecord); 
                    leadMap.put('RetryCounter', retryCounter);
                    
                    
                    
                        thisLoggerService.logger.logTrace('Create Opportunity Platform Event get fired '+ retryCounter +' times.', event);
                        Flow.Interview.Create_Opp_for_Converted_Deal_Reg_Lead flowInstance = new Flow.Interview.Create_Opp_for_Converted_Deal_Reg_Lead(leadMap);
                    	//Flow.Interview.Create_Partner_Registration_on_Lead_Conversion flowInstance = new Flow.Interview.Create_Partner_Registration_on_Lead_Conversion(leadMap);
                        flowInstance.start();


                }
                catch(Exception ex){
                    thisLoggerService.logger.logError(
                            'Create Opportunity Platform Event get fired'+ event.Retry_Counter_n__c + 1,
                            new SamsaraLoggerObjectMVP(ex, event)
                    );
                }


            }
        }
        thisLoggerService.logger.dispatch();
    }
    
//GTMS-8185 Created updateAccounts method for updating Updating account from flow : Create_Opp_for_Converted_Deal_Reg_Lead @Aparna Raypitam.
//GTMS-10340 Add Number_of_Vehicles__c field into string  @Ankit Goswami.

    @InvocableMethod(label='UpdateAccfromFlow' description='Update account from flow' category='Account')
    public static void updateAccounts(List<Account> accList){

        List<String> accStringList = new List<String>();

        for( account acc : accList ){
            
            String accString = acc.Id + '+' + acc.Initiate_Round_Robin__c + '+' + acc.Latest_Partner_Account_Interaction__c  + '+' + acc.Latest_Partner_Program_Interaction__c + '+' +acc.Number_of_Vehicles__c;
            accStringList.add(accString);
        }
        updateAccountsAsync(accStringList);

    }
//GTMS-10340 Add Number_of_Vehicles__c field into string  @Ankit Goswami.
    //@future(callout=true)
    public static void updateAccountsAsync(List<String> accStringList){

        List<Account> accToUpdateList = new List<Account>();
        List<Database.SaveResult> updateResults = new  List<Database.SaveResult>();
        List<Account> accUpdateAgain = new List<Account>();

        for(string accString : accStringList ){
            List<String> accFieldList = accString.split('\\+');
            Account accToUpdate = new Account();
            accToUpdate.Id = accFieldList[0];
            accToUpdate.Initiate_Round_Robin__c = accFieldList[1] == 'true' ? true : false;
           if(accFieldList[2] != null && accFieldList[2] != 'null') accToUpdate.Latest_Partner_Account_Interaction__c = accFieldList[2];

           if(accFieldList[3] != null && accFieldList[3] != 'null') accToUpdate.Latest_Partner_Program_Interaction__c = accFieldList[3];

           if(accFieldList[4] != null && accFieldList[4] != 'null') accToUpdate.Number_of_Vehicles__c = integer.valueOf(accFieldList[4]);

            accToUpdateList.add(accToUpdate);


        }

        // if(accToUpdateList.size() >0){
        //     UPDATE accToUpdateList;
        // }


        if(accToUpdateList.size() >0)
        {
            //added this condition for GTMS-12099
            //TriggerHandler.bypass('GS_AccountTriggerHandler');
            updateResults = Database.update(accToUpdateList,false);
        }
        for(Integer i=0;i<updateResults.size();i++)
        {
             if(!updateResults[i].isSuccess())
             {
                 for(Database.Error err : updateResults[i].getErrors())
                 {
                       //System.DmlException: Insert failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                     if(err.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                     {
                        accUpdateAgain.add(accToUpdateList[i]);
                     }
                 }
                 
             }
        }
        if(!accUpdateAgain.isEmpty())
        {
            //added this condition for GTMS-12099
            //TriggerHandler.bypass('GS_AccountTriggerHandler');
            Database.update(accUpdateAgain,false);
        }
    }


}