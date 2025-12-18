/* 
* Class Created: 07/18/19 - @author: Harsha
* 7/11/20 Harsha - (GTMS-1307) updateQuotes,fetchQuotes (Changes to Remove Avalara Dependencies)
* 9/13/21 Anil - (GTMS-4512) Partner tagging on opportunity 
* 2023-Apr-25 Rodrigo Carpio- (GTMS-12025) added logic that will set the SBQQ__Quote__c->SBQQ__Ordered__c to true
* 2023-July-28 Rajesh GTMS-13262 Extended the Free Trial logic to Revenue Opp
*/ 
public class UpdateQuoteFromOpportunity {
    Static Map<Id, SBQQ__Quote__c> quoteData;
    Static Set<Id> QuoteIdSet = new Set<Id>();
    List<SBQQ__Quote__c> quotesToUpdateAsync = new List<SBQQ__Quote__c>();
    private void fetchQuotes(Map<Id, Opportunity> newOppMap){
        if(quoteData == null){
            //fetching the quotes related to the opportunities
            quoteData = new Map<Id, SBQQ__Quote__c>([SELECT  Id,DCA_Validation__c,SBQQ__Status__c, SBQQ__Opportunity2__c, SBQQ__StartDate__c, SBQQ__EndDate__c,SBQQ__SubscriptionTerm__c,SBQQ__Primary__c,/*gtms-21313*/SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__c,SBQQ__Opportunity2__r.Owner.UserRoleId,SBQQ__Opportunity2__r.Owner.UserRole.Name,
            SBQQ__MasterContract__c,Co_Term_Contract__c,Contract_End_Date__c, SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.EndDate, SBQQ__Opportunity2__r.Renewal__c,/*gtms-21313*/ SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.License_Term__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Blended_Discount__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c,
            SBQQ__Opportunity2__r.stageName, SBQQ__Opportunity2__r.SBQQ__RenewedContract__c, SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c,SBQQ__Opportunity2__r.License_Start_Date__c,/*gtms-21313*/Original_Blended_Discount__c,Original_License_Term__c,Original_Selected_Payment_Type__c,
            SBQQ__Opportunity2__r.OwnerId, SBQQ__Opportunity2__r.Owner.ProfileId, SBQQ__SalesRep__c, SBQQ__Opportunity2__r.Sub_Type__c 
            FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c  IN : newOppMap.keyset()
            ORDER BY LastModifiedDate DESC]);            
        }
    }

    public void updateQuotes(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap, List<Opportunity> newOppList){
        fetchQuotes(newOppMap);
        if(quoteData != null){
            Map<Id, Boolean> validatedOpportunities = new Map<Id, Boolean>();
            Set<SBQQ__Quote__c> updatedQuotes = new Set<SBQQ__Quote__c>();
            
            for(SBQQ__Quote__c quoteToFilter: quoteData.values()){
                Opportunity oldOpportunityData = oldOppMap.get(quoteToFilter.SBQQ__Opportunity2__c);
                Opportunity newOpportunityData = newOppMap.get(quoteToFilter.SBQQ__Opportunity2__c);
                // Logic to narrow down the Opportunities as per the criteria to Retrigger the tax. 
                // It will be manual on the quote though but we are marking the quotes that needs to retrigger.
                //GTMS-23000
                if(newOpportunityData != null){
                    if(newOpportunityData != null){
                    if((validatedOpportunities == null) || (!validatedOpportunities.containsKey(quoteToFilter.SBQQ__Opportunity2__c))){
                        if(((newOpportunityData.VAT_Number__c != oldOpportunityData.VAT_Number__c && !System.isQueueable()) ||
                        (newOpportunityData.Reseller__c != oldOpportunityData.Reseller__c) ||
                        (newOpportunityData.CloseDate != oldOpportunityData.CloseDate) || (newOpportunityData.SBQQ__RenewedContract__c != null && newOpportunityData.License_Start_Date__c != oldOpportunityData.License_Start_Date__c)) &&
                        (newOpportunityData.Probability < 99) &&
                        (newOpportunityData.Probability >= 10) && 
                        (newOpportunityData.Type == 'Revenue Opportunity') &&
                        (newOpportunityData.CPQ_Opportunity__c == true)){
                            validatedOpportunities.put(quoteToFilter.SBQQ__Opportunity2__c,true);                            
                        }
                        else{
                            validatedOpportunities.put(quoteToFilter.SBQQ__Opportunity2__c,false);
                        }
                    }
                }         
                }
            }
            
            Org_Setting__mdt orderTransformationSetting = Org_Setting__mdt.getInstance('OrderTransformationPhase2');
            
            for(SBQQ__Quote__c QuoteToUpdate: quoteData.values()){
                Boolean changeFlag = false;
                Opportunity oldOpportunityData = oldOppMap.get(QuoteToUpdate.SBQQ__Opportunity2__c);
                Opportunity newOpportunityData = newOppMap.get(QuoteToUpdate.SBQQ__Opportunity2__c);
              

                if(oldOpportunityData != null && newOpportunityData != null){
                         /*GTMS-21313 Starts*/
                    if (QuoteToUpdate.SBQQ__Opportunity2__r.Owner.UserRoleId <> null && QuoteToUpdate.SBQQ__Opportunity2__r.Owner.UserRole.Name.Contains('Renewal') && QuoteToUpdate.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c <> null &&
                        QuoteToUpdate.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__c <> null) {
                        if (QuoteToUpdate.Original_Blended_Discount__c == null &&
                            QuoteToUpdate.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Blended_Discount__c <> null) {
                            QuoteToUpdate.Original_Blended_Discount__c = QuoteToUpdate.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Blended_Discount__c;
                            changeFlag = true;  
                        }

                        if (QuoteToUpdate.Original_License_Term__c == null &&
                            QuoteToUpdate.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.License_Term__c <> null) {
                            QuoteToUpdate.Original_License_Term__c = QuoteToUpdate.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.License_Term__c;
                            changeFlag = true;
                        }

                        if (QuoteToUpdate.Original_Selected_Payment_Type__c == null &&
                            QuoteToUpdate.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c <> null) {
                            QuoteToUpdate.Original_Selected_Payment_Type__c = QuoteToUpdate.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c;
                            changeFlag = true;
                        }
                    }
                     /*GTMS-21313 End*/

                     /*GTMS-21781 Start*/

                    if((QuoteToUpdate.SBQQ__Opportunity2__r.Owner.ProfileId == System.Label.SamsaraSalesRenewalsNewSystem || QuoteToUpdate.SBQQ__Opportunity2__r.Owner.ProfileId == System.Label.SamsaraSalesRenewalsSpecialist) && QuoteToUpdate.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c != null && oldOpportunityData.OwnerId != newOpportunityData.OwnerId){
                        QuoteToUpdate.OwnerId =  newOpportunityData.OwnerId;
                     	QuoteToUpdate.SBQQ__SalesRep__c = newOpportunityData.OwnerId; //Added for GTMS-27773

                        changeFlag = true;
                    }
                /*GTMS-21781 End*/
                
                //Anil 08/27/2021 GTMS-4512
                if(oldOpportunityData.Insurance_Partner__c != newOpportunityData.Insurance_Partner__c &&
                newOpportunityData.Insurance_Partner__c != null){
                    QuoteToUpdate.SBQQ__Partner__c = newOpportunityData.Insurance_Partner__c;         
                    changeFlag = true;
                }else if(oldOpportunityData.Reseller_Partner__c != newOpportunityData.Reseller_Partner__c && 
                newOpportunityData.Reseller_Partner__c != null){
                    QuoteToUpdate.SBQQ__Partner__c = newOpportunityData.Reseller_Partner__c;         
                    changeFlag = true;
                }else if(oldOpportunityData.Referral_Partner__c != newOpportunityData.Referral_Partner__c && 
                newOpportunityData.Referral_Partner__c != null){
                    QuoteToUpdate.SBQQ__Partner__c = newOpportunityData.Referral_Partner__c;            
                    changeFlag = true;
                }
                
                    // Rodrigo added for GTMS-12025
                if (QuoteToUpdate.SBQQ__Primary__c == True && oldOpportunityData.StageName != newOpportunityData.StageName
                    && ((newOpportunityData.StageName == 'Ready To Ship' && newOpportunityData.Type == 'Free Trial Opportunity') 
                        || (Boolean.valueOf(orderTransformationSetting.Value__c) == true && (
                        (newOpportunityData.StageName == 'Return Initiated' && newOpportunityData.Type == 'Free Trial Return')
                        || ((newOpportunityData.StageName == 'Return Label Sent' || newOpportunityData.StageName == 'Finance Processing') && (newOpportunityData.Type == 'Remorse Refund' || newOpportunityData.Type == 'Warranty' || newOpportunityData.Type == 'Rebate'))
                        || (newOpportunityData.StageName == 'Ready To Ship' && newOpportunityData.Type == 'Revenue Opportunity'))
                       ))
                   ) {
                        QuoteToUpdate.SBQQ__Ordered__c = true;
                        changeFlag = true;
                    }
                
                if((validatedOpportunities.containsKey(QuoteToUpdate.SBQQ__Opportunity2__c) && (validatedOpportunities.get(QuoteToUpdate.SBQQ__Opportunity2__c) == true))){
                    //GTMS-12302
                    //GTMS-23000
                    // Logic to populate start & end date 
                    if(newOpportunityData != NULL && oldOpportunityData != NULL && ((newOpportunityData.CloseDate != null && oldOpportunityData.CloseDate != newOpportunityData.CloseDate) ||
                      (newOpportunityData.SBQQ__RenewedContract__c != null && newOpportunityData.License_Start_Date__c != oldOpportunityData.License_Start_Date__c))){
                       if(newOpportunityData.SBQQ__AmendedContract__c != NULL && newOpportunityData.Type != 'Free Trial Opportunity' && newOpportunityData.Sub_Type__c != 'Contract Cancellation'){
                                QuoteToUpdate.SBQQ__StartDate__c = newOpportunityData.CloseDate + 15;
                        }else{
                            QuoteToUpdate.SBQQ__StartDate__c = newOpportunityData.CloseDate;
                            // Logic to populate end date for Renewal Quotes when the close date changes.
                            // Added extra condition to null check Subscription Term and start Date --> ABU (01/19/2024)
                            //GTMS-23000
                            if(newOpportunityData.SBQQ__RenewedContract__c != null){
                                if(QuoteToUpdate.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c != null){
                                    QuoteToUpdate.SBQQ__StartDate__c = QuoteToUpdate.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c;
                                }else if(QuoteToUpdate.Co_Term_Contract__c != NULL){
                                    QuoteToUpdate.SBQQ__StartDate__c = QuoteToUpdate.SBQQ__Opportunity2__r.License_Start_Date__c;
                                }
                            }
                            if((newOpportunityData.SBQQ__Renewal__c || newOpportunityData.Renewal__c || newOpportunityData.SBQQ__RenewedContract__c != Null) && (QuoteToUpdate.SBQQ__StartDate__c!=null && QuoteToUpdate.SBQQ__SubscriptionTerm__c!=null)){
                                QuoteToUpdate.SBQQ__EndDate__c = Date.valueOf(QuoteToUpdate.SBQQ__StartDate__c-1).addMonths(Integer.valueOf(QuoteToUpdate.SBQQ__SubscriptionTerm__c));
                            }
                                    // Added extra condition to null check Subscription Term and start Date --> ABU (01/19/2024) --> END   
                        }
                    }
                QuoteToUpdate.Recalculate_Quote__c  = true;
                changeFlag = true;
                }
               if(QuoteToUpdate.DCA_Validation__c == 'DCA' && QuoteToUpdate.SBQQ__Status__c != 'Approved' && newOpportunityData.Reseller__c != oldOpportunityData.Reseller__c ){
                    changeFlag = true;
                }
                if (changeFlag){
                        if(!QuoteToUpdate.SBQQ__Primary__c && !System.isFuture() && !System.isQueueable() && !System.isScheduled() && !System.isBatch()){
                            quotesToUpdateAsync.add(QuoteToUpdate);
                        }else{
                    DMLWrapper.doUpdate(QuoteToUpdate, new List<SObjectField>{
                        SBQQ__Quote__c.SBQQ__StartDate__c,
                        SBQQ__Quote__c.SBQQ__EndDate__c,
                        SBQQ__Quote__c.Recalculate_Quote__c,
                        SBQQ__Quote__c.SBQQ__Partner__c,
                        SBQQ__Quote__c.SBQQ__Ordered__c});
                  OpportunityTriggerHandlerContext.logExecution.add('UpdateQuoteFromOpportunity');
		        }
             }
        }
     } 
    } 

        if(!quotesToUpdateAsync.isEmpty()) {
            String jsonQuotes = JSON.serialize(quotesToUpdateAsync);
            UpdateQuoteFromOpportunity.updateQuotesFromFuture(jsonQuotes);
        }
    }

    @future
    public static void updateQuotesFromFuture(String serializedQuotes) {
        List<SBQQ__Quote__c> deserializedQuotes = (List<SBQQ__Quote__c>) JSON.deserialize(serializedQuotes, List<SBQQ__Quote__c>.class);
        
        Boolean isError = false,isError2 = false;
        List<SBQQ__Quote__c> firstThreeQuotes = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> remainingQuotes = new List<SBQQ__Quote__c>();
        Integer counter = 0;
        for(SBQQ__Quote__c quote : deserializedQuotes) {
            if(counter < 3) {
                firstThreeQuotes.add(quote);
            } else {
                remainingQuotes.add(quote);
            }
            counter++;
        }
        List<Database.SaveResult> failedResults = new List<Database.SaveResult>();
        if (!firstThreeQuotes.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(firstThreeQuotes, false); // partial success allowed
            isError = handleSaveResults(saveResults);
        }
        if (!remainingQuotes.isEmpty()) {
            TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
            SBQQ.TriggerControl.disable();
            Database.SaveResult[] saveResults = Database.update(remainingQuotes, false); // partial success allowed
            isError2 = handleSaveResults(saveResults);
        }
        if(isError||isError2)
        {
            Logger.insertMasterLogs();
        }
    }
    
    private static Boolean handleSaveResults(Database.SaveResult[] saveResults) {
        Set<Id> failedQuoteIds = new Set<Id>();
        String failureMessage = '';
        for (Database.SaveResult result : saveResults) {
            if (!result.isSuccess()) {
                failedQuoteIds.add(result.getId());
                for (Database.Error error : result.getErrors()) {
                    // Add comma if needed
                    if (!String.isEmpty(failureMessage)) {
                        failureMessage += ', '; 
                    }
                    failureMessage += error.getMessage();
                }
            }
        }
        if (failureMessage.length() >= 131072) {
            failureMessage = failureMessage.substring(0, 131065) + '...'; 
        }
        if(!failedQuoteIds.isEmpty())
        {
            Logger.atError()
            .setClassName('UpdateQuoteFromOpportunity')
            .setExceptionOrMessage(failureMessage);
            Logger.setRecordIds(failedQuoteIds);
            return true;
        }
        return false;
    }
}