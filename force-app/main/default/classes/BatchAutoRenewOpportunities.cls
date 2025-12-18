/*
* Test Class   :   BatchAutoRenewOpportunitiesTest
* Coverage     :   100%
* Description  :   This batch apex auto renews opptys
* Related Jira :   GTMS-938
* *************************************************************************************************************
* 8/12/20 Satya - (GTMS-938): Created
* 11/17/20 Satya- (GTMS-2048): Updated code to update partial updates
* 05/16/22 Flavio - (GTMS-6099): Removed Line Item logic, updated field mapping and changed query to support up to 30 days.
*/
global class BatchAutoRenewOpportunities implements Database.Batchable<sObject>, Schedulable{
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();

    global Database.Querylocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(System.Label.Opportunity_Auto_Renew_Query);
    } 
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        try{
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
            List<Id> lstOriginalOppIds = new List<Id>();
            List<Id> primaryQuoteIds = new List<Id>();
            for(Opportunity opp : scope) {
                oppMap.put(opp.Id, opp);
                lstOriginalOppIds.add(opp.SBQQ__RenewedContract__r.Original_Contracted_Opportunity__c);
                if (opp.SBQQ__PrimaryQuote__c != null) primaryQuoteIds.add(opp.SBQQ__PrimaryQuote__c);
            }
            
            // Handle QuoteLines - Set static override to ensure Gainsight audit status gets processed / Shallow update
            SBQQQuoteLineHelper.GainsightProcessingOverride = true;
            List<SBQQ__QuoteLine__c> quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :primaryQuoteIds];
            if (quoteLine.size() > 0) executeUpdateDml(quoteLine, 'Failed updating CPQ QuoteLine({0}). Error: {1}');
            SBQQQuoteLineHelper.GainsightProcessingOverride = false;

            // Handle Opportunity update
            Map<Id, Opportunity> mapOriginalOpps = new Map<Id, Opportunity>([SELECT Id, NS_Payment_Terms__c, Shipping_Contact__c, Selected_Payment_Type__c FROM Opportunity WHERE Id IN : lstOriginalOppIds]);
            List<Opportunity> oppListToUpdate = new List<Opportunity>();
            for(Opportunity opp : scope) {
                oppListToUpdate.add(
                    new Opportunity(
                        Id = opp.Id, 
                        Name = opp.Name.contains('Evergreen - ') ? opp.Name : 'Evergreen - ' + opp.Name,
                        Revenue_Opportunity_Type__c = 'Auto-Renewal', 
                        StageName = 'Purchase',
                        License_Term__c = 12,
                        //CloseDate = System.Today(),
                        OwnerID = '0051a000002k4I5',
                        Finance_Notes__c  = 'Evergreen opportunity',  
                        Payment_Terms__c = opp.Account.Segment__c != 'AE1' ? opp.Account.Payment_Terms__c : mapOriginalOpps.get(opp.SBQQ__RenewedContract__r.Original_Contracted_Opportunity__c).Payment_Terms__c, 
                        Selected_Payment_Type__c = mapOriginalOpps.get(opp.SBQQ__RenewedContract__r.Original_Contracted_Opportunity__c).Selected_Payment_Type__c,
                        License_Term_Approval_Status__c = 'Approved',
                        ContractId = null,
                        PO_Number__c = 'Auto-Renewal',
                        Shipping_Contact__c = opp.Shipping_Contact__c == null ? mapOriginalOpps.get(opp.SBQQ__RenewedContract__r.Original_Contracted_Opportunity__c).Shipping_Contact__c : opp.Shipping_Contact__c,
                        Sub_Type__c = 'Auto-Renewal'
                    )
                );
            }
            executeUpdateDml(oppListToUpdate, 'Error Auto Renewing Opportunity({0}). Error: {1}');
        }catch(Exception e){
            this.logError('On BatchAutoRenewOpportunities error: {0}. Stack trace: {1}', new List<Object>{ e.getMessage(), e.getStackTraceString()});
        }finally{
            thisLogger.dispatch();
        }
        // Database.Update(lstLinesToUpdate, false);
    }

    private void executeUpdateDml(List<SObject> recordList, String logMessage){
        List<Database.SaveResult> saveResultList = Database.update(recordList, false);
        for (Integer it = 0; it < saveResultList.size(); it++){
            Database.SaveResult result = saveResultList.get(it);
            if (!result.isSuccess()) this.logError(logMessage, new List<Object>{ recordList[it].Id, getErrorList(result.getErrors()) });
        }
    }

    private String getErrorList(List<Database.Error> errorList){
        String errorMessage = '';
        for (Database.Error err : errorList)
            errorMessage += (String.isBlank(errorMessage) ? '' : '; ')+err.getMessage();
        return errorMessage;
    }

    private void logError(String message, List<Object> values){
        thisLogger.logError(
            String.format(
                message,
                values
            )
        );
    }
    
    global void finish(Database.BatchableContext BC) {
        
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id =: BC.getJobId()];
        
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'no-reply@samsara.com'];
		
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {System.Label.Email_Auto_Renewal_Batch, 'satya.dodda@samsara.com'};
        mail.setToAddresses(toAddress);
        mail.setOrgWideEmailAddressId(owea.get(0).Id);
        mail.setSubject('BatchAutoRenewOpportunities Apex Job status is ' + apexJob.Status);
        mail.setPlainTextBody('Hello Team,\n\nThe BatchAutoRenewOpportunities batch Apex job processed ' + 
                              apexJob.TotalJobItems + ' batches with '+ 
                              apexJob.NumberOfErrors + 
                              ' failures.\n\nPlease refer to this Report: https://samsara.my.salesforce.com/00O4p000004Nyo8\n\nThanks\nGTMS Team');
        
        if(apexJob.NumberOfErrors > 0)
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    global void execute(SchedulableContext sc)
    {
        BatchAutoRenewOpportunities b = new BatchAutoRenewOpportunities();
        database.executebatch(b, 3);
    }
}