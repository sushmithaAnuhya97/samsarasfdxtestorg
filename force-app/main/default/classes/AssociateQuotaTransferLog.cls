/* 
 * Class Created: 04/01/19 - @author: Harsha
 * 9/13/2022 Siddharth Kumar Mishra GTMS-9363:introduced error handling and logging
 */  

 /* Class to associate quota's and ADR Transfer Logs so that reporting can be done on quota object */
public without sharing class AssociateQuotaTransferLog { 

    // Field to get the date after which the ADR Transfer Process changed.
    Static Date changeDate;
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();

    //Method that contains the logic to Map the data
    public void mapQuotaAndTransferLogs(){
        
        Map<Id, Quota__c> mapOfValidQuotasForTransferLogs = new Map<Id, Quota__c>(); //Holds the map of valid quotas
        List<Quota_Transfer_Log__c> finalQuotaTransferLogs = new List<Quota_Transfer_Log__c>(); //Stores the new and updated Quota Transfer Logs
        List<Quota_Transfer_Log__c> quotaLogsToDelete = new List<Quota_Transfer_Log__c>(); //Stores the unmatched quota logs and deletes them.
        List<Date> sortedStartDatesForQuote = new List<Date>(); //Stores the list of Start Dates of the quotes
        List<Date> sortedEndDatesForQuote = new List<Date>(); // Stores the list of End Dates of the quotes
        Date validStartDate; // Stores the earliest start date
        Date validEndDate; // Stores the fartest end date

        if((changeDate == null) && (Schema.sObjectType.Date__mdt.fields.Date__c.isAccessible())){
            Date__mdt dateRecord = [SELECT Date__c FROM Date__mdt WHERE MasterLabel = 'ADR Change Date'];
            changeDate = dateRecord.Date__c;
            system.debug('Change Date '+changeDate);
        }

        // Get the valid Quota's for the given time period.
        for(Quota__c quota : [Select Id, User__c, User__r.Name, Role_at_Start_of_Fiscal_Period__c, Quota_Period_Start_Date__c, Quota_Period_End_Date__c 
                                    FROM Quota__c 
                                    WHERE Valid_Quota__c = true 
                                    AND Quota_Period_Start_Date__c != null 
                                    AND Quota_Period_End_Date__c != null
                                    AND ADR_Quota__c != null])
        {

            mapOfValidQuotasForTransferLogs.put(quota.User__c,quota);
            sortedStartDatesForQuote.add(quota.Quota_Period_Start_Date__c);
            sortedEndDatesForQuote.add(quota.Quota_Period_End_Date__c);
        }
        if(sortedStartDatesForQuote.isEmpty() || sortedEndDatesForQuote.isEmpty())
        {
            //stop processingm further if the quota query does not return any rows
            return;
        }
        system.debug('Details of valid Quota ' +mapOfValidQuotasForTransferLogs);
        
        try
        {  
            //sortedStartDatesForQuote.sort();
            //sortedEndDatesForQuote.sort();
            //GTMS-9363        
            sortedStartDatesForQuote.sort();
            validStartDate = sortedStartDatesForQuote.get(0);
            sortedEndDatesForQuote.sort();
            validEndDate = sortedEndDatesForQuote.get(sortedEndDatesForQuote.size() - 1);
            //validStartDate = sortedStartDatesForQuote.get(0); //GTMS-9363         
            //validEndDate = sortedEndDatesForQuote.get(sortedEndDatesForQuote.size() - 1);
        }
        catch(Exception e)
        {
            //GTMS-9363            
            thisLogger.logError('AssociateQuotaTransferLog. Error Message ::'+ e.getMessage() +' | StackTrace:: '+ e.getStackTraceString());
        }
        finally
        {
            //GTMS-9363
            thisLogger.dispatch();
        }        

        system.debug('Start Date ----> '+validStartDate);
        system.debug('End Date ----> '+validEndDate);

        /*ADR_Transfer_Log__c adrTransferLog : [SELECT Id, ADR_Transfer_By__c, ADR_Transfer__c, ADR_Accepted_Date__c, ADR_Transfer_Qualified__c,
                                                    ADR_Transfer_Qualified_Date__c, ADR_Role_Copy_at_Qualification__c
                                                    FROM ADR_Transfer_Log__c
                                                    WHERE ADR_Accepted_Date__c != null
                                                    AND ADR_Transfer_Qualified_Date__c != null
                                                    AND (ADR_Transfer_Qualified_Date__c >=: validStartDate AND ADR_Transfer_Qualified_Date__c <=: validEndDate)
                                                    AND (ADR_Accepted_Date__c >=: validStartDate AND ADR_Accepted_Date__c <=: validEndDate)
                                                    AND (ADR_Transfer__c = true OR ADR_Transfer_Qualified__c = true)*/
        // Logic for Mapping
        for(ADR_Transfer_Log__c adrTransferLog : [SELECT Id, ADR_Transfer_By__c, ADR_Transfer_By__r.Name, ADR_Transfer__c, ADR_Accepted_Date__c, ADR_Transfer_Qualified__c,
                                                    ADR_Transfer_Qualified_Date__c, ADR_Role_Copy_at_Qualification__c,
                                                    (SELECT Id, Related_Quota_for_the_ADR_Log__c, Role_of_the_ADR__c, ADR_Transfer_Log__r.ADR_Transfer_By__c, 
                                                     Related_Quota_for_the_ADR_Log__r.User__c FROM Quota_Transfer_Logs__r)
                                                    FROM ADR_Transfer_Log__c
                                                    WHERE ADR_Role_Copy_at_Qualification__c != null 
                                                    AND (ADR_Transfer_Qualified_Date__c >=: validStartDate AND ADR_Transfer_Qualified_Date__c <=: validEndDate)]){
                
            system.debug('Transfer Log ' +adrTransferLog);
            
            if(mapOfValidQuotasForTransferLogs.containsKey(adrTransferLog.ADR_Transfer_By__c))
            {
                system.debug('True');
                Quota__c relatedQuotaForTheLogOwner = mapOfValidQuotasForTransferLogs.get(adrTransferLog.ADR_Transfer_By__c);
                
                String roleFromAdrLog = adrTransferLog.ADR_Role_Copy_at_Qualification__c;
                String roleFromQuota = relatedQuotaForTheLogOwner.Role_at_Start_of_Fiscal_Period__c;
                Boolean roleMatch = roleFromAdrLog.equalsIgnoreCase(roleFromQuota);

                Date quotaStartDate = relatedQuotaForTheLogOwner.Quota_Period_Start_Date__c;
                Date quotaEndDate = relatedQuotaForTheLogOwner.Quota_Period_End_Date__c;

                Date qualifiedDate;
                Boolean dateCheck;
                
                system.debug('Role Match '+roleMatch);

                if((adrTransferLog.ADR_Transfer_Qualified_Date__c >= changeDate)){
                    system.debug('Date is greater than change date');
                    Boolean transferQualified = adrTransferLog.ADR_Transfer_Qualified__c;
                    qualifiedDate = adrTransferLog.ADR_Transfer_Qualified_Date__c;
                    dateCheck = ((qualifiedDate >= quotaStartDate) && (qualifiedDate <= quotaEndDate) ? true : false );
                    Quota_Transfer_Log__c quotaTransferLog = new Quota_Transfer_Log__c();
                    
                    if(dateCheck){
                        if((adrTransferLog.Quota_Transfer_Logs__r.size() == 0) && (roleMatch) && (transferQualified)){
                            //quotaTransferLog.ADR_Transfer_Log__c = adrTransferLog.Id;
                            //quotaTransferLog.Related_Quota_for_the_ADR_Log__c = relatedQuotaForTheLogOwner.Id;
                            mapQuotaTransferLogData(quotaTransferLog, relatedQuotaForTheLogOwner, adrTransferLog);
                            finalQuotaTransferLogs.add(quotaTransferLog);
                        }
                        else if(adrTransferLog.Quota_Transfer_Logs__r.size() > 0){
                            quotaTransferLog = adrTransferLog.Quota_Transfer_Logs__r;
                            //quotaTransferLog.ADR_Transfer_Log__c = adrTransferLog.Id;
                            //quotaTransferLog.Related_Quota_for_the_ADR_Log__c = relatedQuotaForTheLogOwner.Id;
                            system.debug(' in else if ');
                            if((roleMatch) && (transferQualified)){
                            mapQuotaTransferLogData(quotaTransferLog, relatedQuotaForTheLogOwner, adrTransferLog);
                            finalQuotaTransferLogs.add(quotaTransferLog);
                            }
                            else{
                                quotaLogsToDelete.add(quotaTransferLog);
                                system.debug(' Delete ');
                            }
                        }
                    }
                }
            }
            else if(adrTransferLog.Quota_Transfer_Logs__r.size() > 0){
                Quota_Transfer_Log__c invalidQuotaTransferLog = adrTransferLog.Quota_Transfer_Logs__r;
                try{
                	if(invalidQuotaTransferLog.ADR_Transfer_Log__r.ADR_Transfer_By__c != invalidQuotaTransferLog.Related_Quota_for_the_ADR_Log__r.User__c){
                		quotaLogsToDelete.add(invalidQuotaTransferLog);
                	}
                }
                catch(System.NullPointerException e){
                    system.debug('The check failed with exception '+e.getMessage());
                }
            }                                               
        }
        system.debug('List of New Quota Transfer Logs ' +finalQuotaTransferLogs);
        system.debug('List of Quota Transfer Logs that needs to deleted' +quotaLogsToDelete);
        if(finalQuotaTransferLogs.size() > 0){
            try{
                upsert finalQuotaTransferLogs;
            }
            catch(DmlException e){
                system.debug('Upsert failed with exception '+e.getMessage());
            }
        }

        if(quotaLogsToDelete.size() > 0){
            try{
                delete quotaLogsToDelete;
            }
            catch(DmlException e){
                system.debug('Delete failed with exception '+e.getMessage());
            }
        }
    }

    //Method to map QTL with Quota and the respective ADR Transfer Log
    public void mapQuotaTransferLogData(Quota_Transfer_Log__c mapQuotaTransferLog, Quota__c mapRelatedQuota, ADR_Transfer_Log__c mapRelatedTransferLog){
        mapQuotaTransferLog.ADR_Transfer_Log__c = mapRelatedTransferLog.Id;
        mapQuotaTransferLog.Related_Quota_for_the_ADR_Log__c = mapRelatedQuota.Id;
    }
}