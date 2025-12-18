/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-14-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class RebateLogicHandler {
    // GTMS-26606 START
    public static void checkFirstInvoiceAmounts(Map<Id, SBQQ__Quote__c> oldMap, List<SBQQ__Quote__c> newList) {
    for (SBQQ__Quote__c quote : newList) {
        Boolean isCurrentlyNegative = false;
        
        if (quote.Selected_Payment_Type__c != null) {
            if (quote.Selected_Payment_Type__c == 'Direct Monthly') {
                isCurrentlyNegative = quote.First_Months_Payment__c < 0;
            } else if (quote.Selected_Payment_Type__c == 'Direct Quarterly') {
                isCurrentlyNegative = quote.First_Quarter_Payment__c < 0;
            } else if (quote.Selected_Payment_Type__c == 'Direct Semi-Annual') {
                isCurrentlyNegative = quote.First_Semi_Annual_Payment__c < 0;
            } else if (quote.Selected_Payment_Type__c == 'Direct Annual') {
                isCurrentlyNegative = quote.First_Annual_Payment__c < 0;
            } else if (quote.Selected_Payment_Type__c == 'Upfront Payments') {
                isCurrentlyNegative = quote.SBQQ__NetAmount__c < 0;
            }
        }
        
        quote.Is_First_Invoice_Amount_Negative__c = isCurrentlyNegative;
    }
}
    // GTMS-26606 END
    // GTMS-26318 STARTS
    public static void calculateBuyoutAmount(Map<Id, SBQQ__Quote__c> oldMap, List<SBQQ__Quote__c> newList) {
        for (SBQQ__Quote__c quote : newList) {
            String infoMessage = '';
            if( oldMap != null && (oldMap.get(quote.Id).Total_Estimated_Installation_Costs__c != quote.Total_Estimated_Installation_Costs__c || oldMap.get(quote.Id).Competitor_Buyout_Amount__c != quote.Competitor_Buyout_Amount__c || quote.New_DC_architecture__c == true)) {
                  
                // Simply set value
                quote.Buyout_Amount__c = ((quote.Total_Estimated_Installation_Costs__c==null)?0:quote.Total_Estimated_Installation_Costs__c)
                    + ((quote.Competitor_Buyout_Amount__c==null)?0:quote.Competitor_Buyout_Amount__c);

                if(quote.Competitor_Buyout_Amount__c > 0){
                    quote.Contract_buyout_requested__c = true;
                }else{
                    quote.Contract_buyout_requested__c = false;
                }
                infoMessage = ' Buyout Amount Changed from ' + oldMap.get(quote.Id).Buyout_Amount__c + ' to ' + quote.Buyout_Amount__c;
            }
            if( oldMap != null && (oldMap.get(quote.Id).Future_Free_Months_Amount__c != quote.Future_Free_Months_Amount__c || oldMap.get(quote.Id).X3rd_PF_Interest_Subsidy__c != quote.X3rd_PF_Interest_Subsidy__c || oldMap.get(quote.Id).OTD_Amt__c != quote.OTD_Amt__c || quote.New_DC_architecture__c == true)) {
                  
                // Simply set value
                quote.Subsidy_Amount__c = ((quote.Future_Free_Months_Amount__c==null)?0:quote.Future_Free_Months_Amount__c)
                    + ((quote.X3rd_PF_Interest_Subsidy__c==null)?0:quote.X3rd_PF_Interest_Subsidy__c)
                    + ((quote.OTD_Amt__c==null)?0:quote.OTD_Amt__c); //GTMS-29862 Included OTD_Amt__c


                if(quote.Number_of_months_of_Free_service__c > 0){
                    quote.Free_service_months_requested__c = true;
                }else{
                    quote.Free_service_months_requested__c = false;
                }
                infoMessage = infoMessage + ' Subsidy Amount Changed from ' + oldMap.get(quote.Id).Subsidy_Amount__c + ' to ' + quote.Subsidy_Amount__c;
            }
            if(infoMessage != ''){
                Logger.atInfo()
                        .setCLassName('RebateLogicHandler')
                        .setMethod('calculateBuyoutAmount')
                        .setRecordId(quote.Id)
                        .setExceptionOrMessage(infoMessage);
            }
        }
        Logger.setFunctionalityType('Rebates');
        Logger.insertMasterLogs();
    }

    public void validateRebateBuyoutLineDeletion(List<SBQQ__QuoteLine__c> quoteLines) {
        if (GS_SBQQQuoteService.bypassValidation) return;
    
        
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__QuoteLine__c ql : quoteLines) {
            if (ql.SBQQ__Quote__c != null) {
                quoteIds.add(ql.SBQQ__Quote__c);
            }
        }
    
        if (quoteIds.isEmpty()) return;

        try{
        GS_SBQQQuoteSelector quoteSelector = new GS_SBQQQuoteSelector(false);
        Map<Id, SBQQ__Quote__c> quotes = quoteSelector.getQuotesAndQuoteLinesById(quoteIds);

        Map<String, Rebate_Buyout_Product_Mapping__mdt> activeMappings = BuyoutQuoteLineQueueable.getActiveRebateBuyoutProductMappings();

        // Precompute license quote line counts for each quote
        Map<Id, Integer> licenseQuoteLinesInTrigger = new Map<Id, Integer>();
        Map<Id, Integer> totalLicenseQuoteLines = new Map<Id, Integer>();
        for (SBQQ__QuoteLine__c ql : quoteLines) {
            if (ql.Product_Type__c == 'License' && ql.SBQQ__Quote__c != null) {
                Id quoteId = ql.SBQQ__Quote__c;
                Integer count = licenseQuoteLinesInTrigger.containsKey(quoteId) ? licenseQuoteLinesInTrigger.get(quoteId) : 0;
                licenseQuoteLinesInTrigger.put(quoteId, count + 1);
            }
        }
        for (SBQQ__Quote__c quote : quotes.values()) {
            Integer count = 0;
            if (quote.SBQQ__LineItems__r != null) {
                for (SBQQ__QuoteLine__c ql : quote.SBQQ__LineItems__r) {
                    if (ql.Product_Type__c == 'License') {
                        count++;
                    }
                }
            }
            totalLicenseQuoteLines.put(quote.Id, count);
        }

        // Single loop over quoteLines
        for (SBQQ__QuoteLine__c ql : quoteLines) {
            if (ql.SBQQ__Quote__c == null) continue;
            SBQQ__Quote__c quote = quotes.get(ql.SBQQ__Quote__c);
            if (quote == null) continue;

            Decimal competitorBuyoutAmount = quote.Competitor_Buyout_Amount__c;
            Decimal futureFreeMonthAmount = quote.Future_Free_Months_Amount__c;
            Decimal installationCosts = quote.Total_Estimated_Installation_Costs__c;
            Decimal futureFreeMonth = quote.Number_of_months_of_Free_service__c;            
            Decimal otdAmount = quote.OTD_Amt__c;

            if (activeMappings.containsKey(ql.SBQQ__ProductCode__c)) {
                String quoteField = activeMappings.get(ql.SBQQ__ProductCode__c).CPQ_Quote_Field__c;

                // Check Competitor Buyout
                if (quoteField == 'Competitor_Buyout_Amount__c' && competitorBuyoutAmount != null && competitorBuyoutAmount != 0) {
                    ql.addError('Deletion of rebate buyout lines are not allowed for quotes with a Competitor Buyout Amount');
                }
                // Check Future Free Months
                if (quoteField == 'Number_of_months_of_Free_service__c' && futureFreeMonth != null && futureFreeMonth != 0) {
                    ql.addError('Deletion of rebate buyout lines are not allowed for quotes with a Future Free Months Amount');
                }
                // Check Installation Costs
                if (quoteField == 'Total_Estimated_Installation_Costs__c' && installationCosts != null && installationCosts != 0) {
                    ql.addError('Deletion of rebate buyout lines are not allowed for quotes with a Total Estimated Installation Costs');
                }
                // Check Samsara Pass Through
                if (quoteField == 'Is_Installation_Reimbursable__c' && installationCosts != null && installationCosts != 0
                    && quote.Is_Installation_Reimbursable__c == 'Yes') {
                    ql.addError('Deletion of rebate buyout lines are not allowed for quotes with a Is Installation Reimbursable');
                }
                // Check One Time Discount
                if (quoteField == 'OTD_Amt__c' && otdAmount != null && otdAmount != 0) {
                    ql.addError('Deletion of rebate buyout lines are not allowed for quotes with a One Time Discount');
                }
            }

            // Check License lines for Future Free Month
            if (futureFreeMonth != null && futureFreeMonth != 0
                && ql.Product_Type__c == 'License'
                && licenseQuoteLinesInTrigger.get(ql.SBQQ__Quote__c) != null
                && totalLicenseQuoteLines.get(ql.SBQQ__Quote__c) != null
                && licenseQuoteLinesInTrigger.get(ql.SBQQ__Quote__c) > 0
                && licenseQuoteLinesInTrigger.get(ql.SBQQ__Quote__c) == totalLicenseQuoteLines.get(ql.SBQQ__Quote__c)) {
                ql.addError('Deletion of License quotelines are not allowed for quotes with Future Free Month.');
            }
        } 
    }catch(Exception e){
            LOGGER.atError().setCLassName('RebateLogicHandler').setExceptionOrMessage(e);
            Logger.setFunctionalityType('Rebates'); 
            Logger.setRecordIds(quoteIds);
            Logger.insertMasterLogs();
        }
    }

    //GTMS-27273
    public static void updateQuoteFieldsDealComp(Map<Id, Opportunity> newOpptyMap, Map<Id, Opportunity> loadedOpportunityMap) {
        try{
        Map<String, Rebate_Buyout_Product_Mapping__mdt> activeMappings = BuyoutQuoteLineQueueable.getActiveRebateBuyoutProductMappings();

        for(Id oppId : newOpptyMap.keySet()) {
            Set<String> listOfMultipicklistValues = new Set<String>();

            if(loadedOpportunityMap.containsKey(oppId)) {
                Opportunity oppty = loadedOpportunityMap.get(oppId);

                for(OpportunityLineItem oli : oppty.OpportunityLineItems) {
                    if (activeMappings.containsKey(oli.Product2.ProductCode)) {
                        listOfMultipicklistValues.add(activeMappings.get(oli.Product2.ProductCode).Deal_Component__c);
                    }
                }
            }
            newOpptyMap.get(oppId).Deal_Components__c = !listOfMultipicklistValues.isEmpty()
                ? String.join((Iterable<String>)listOfMultipicklistValues, ';')
                : '';
        }
    }catch(Exception e){
        LOGGER.atError().setCLassName('RebateLogicHandler').setExceptionOrMessage(e);
        Logger.setFunctionalityType('Rebates'); 
        Logger.setRecordIds(newOpptyMap.keySet());
        Logger.insertMasterLogs();
    }
    }
    

    //Methods for RebateComponent
    @AuraEnabled
    public static Boolean checkForConflicts(Id quoteId) {
        try {
            return BuyoutQuoteLineQueueable.checkForConflicts(quoteId);
        } catch(Exception e) {
            LOGGER.atError().setCLassName('RebateLogicHandler').setRecordId(quoteId).setExceptionOrMessage(e);
            Logger.setFunctionalityType('Rebates'); 
            Logger.setRecordId(quoteId);
            Logger.insertMasterLogs();
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static QuoteWrap getRebateDetails(Id quoteId) {
        try {
            List<String> bypassStatus = System.Label.Rebates_Bypass_Annual_x_Status?.split(';');
            List<SBQQ__QuoteLine__c> quoteLines = [Select Id, Total_Annual_Price__c, Conga_Line_Item_Type__c, SBQQ__Quote__r.Estimated_Annual_Payment__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteId and Conga_Line_Item_Type__c = true and ( NOT SBQQ__Quote__r.SBQQ__Status__c IN  :bypassStatus )];
            SBQQ__Quote__c quote = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesById(new Set<Id>{quoteId}).get(quoteId);
            Decimal totalLicensePrice = BuyoutQuoteLineQueueable.getTotalLicensePrice(quote, quoteLines);
            //Do prechecks
            String errorMessage = '';
            if(quote.SBQQ__Opportunity2__r==null || (quote.SBQQ__Opportunity2__r.Type!='Revenue Opportunity')){
                errorMessage='There should be a Revenue Opportunity attached to this Quote.';
            }
            if(errorMessage != ''){
                return new QuoteWrap(errorMessage);
            }
            String profileId = UserInfo.getProfileId();
            List<String> superUserProfileIds = System.Label.DCSuperUserProfileIds.split(';');
            //Boolean isSuperUser = superUserProfileIds.contains(profileId);
            //GTMS-29048 Start
            Id currentUserId = UserInfo.getUserId();
            Boolean isInSuperUserGroup = ![
                    SELECT Id
                    FROM GroupMember
                    WHERE UserOrGroupId = :currentUserId
                    AND Group.DeveloperName = 'Rebate_DCSuperUserUserIds'
                    AND Group.Type = 'Regular'
                    LIMIT 1
                ].isEmpty(); // GTMS-29048 END
            Boolean isSuperUser = superUserProfileIds.contains(profileId) || /*GTMS-29048 */ isInSuperUserGroup; /*GTMS-29048*/

            BuyoutQuoteLineQueueable.initializeProductIds(quote.CurrencyIsoCode,quote.SBQQ__Pricebook__c);
            
            Boolean isBuyoutProductAvailable = BuyoutQuoteLineQueueable.isBuyoutProductAvailable;
            Boolean isInstallationCostProductAvailable = BuyoutQuoteLineQueueable.isInstallationCostProductAvailable;
            Boolean isFutureFreeMonthsProductAvailable = BuyoutQuoteLineQueueable.isFutureFreeMonthsProductAvailable;
            Boolean isOTDProductAvailable = BuyoutQuoteLineQueueable.isOTDProductAvailable;

            //Check if Opp is present in quote
            return new QuoteWrap(
                quote, 
                String.isBlank(quote?.SBQQ__Opportunity2__r?.Buyout_Opportunity__c) ? false : true,
                isBuyoutProductAvailable,
                isInstallationCostProductAvailable,
                isFutureFreeMonthsProductAvailable,
                isOTDProductAvailable,
                isSuperUser,
                totalLicensePrice
            );
        } catch(Exception e) {
            LOGGER.atError().setCLassName('RebateLogicHandler').setRecordId(quoteId).setExceptionOrMessage(e);
            Logger.setFunctionalityType('Rebates'); 
            Logger.setRecordId(quoteId);
            Logger.insertMasterLogs();
            throw new AuraHandledException(e.getMessage());
        }
    }
	@testvisible
    private static SBQQ__Quote__c updateQuoteFields(Id quoteId, String fieldValues) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = quoteId);
        Map<String, String> fieldValuesMap = (Map<String, String>) JSON.deserialize(fieldValues, Map<String, String>.class);
        
        quote.Competitor_Buyout_Amount__c = String.isNotBlank(fieldValuesMap.get('Competitor_Buyout_Amount__c')) ? Decimal.valueOf(fieldValuesMap.get('Competitor_Buyout_Amount__c')) : null;
        quote.Total_Estimated_Installation_Costs__c = String.isNotBlank(fieldValuesMap.get('Total_Estimated_Installation_Costs__c')) ? Decimal.valueOf(fieldValuesMap.get('Total_Estimated_Installation_Costs__c')) : null;
        quote.Is_Installation_Reimbursable__c = String.isNotBlank(fieldValuesMap.get('Is_Installation_Reimbursable__c')) ? fieldValuesMap.get('Is_Installation_Reimbursable__c') : null;
        quote.Number_of_months_of_Free_service__c = String.isNotBlank(fieldValuesMap.get('Number_of_months_of_Free_service__c')) ? Decimal.valueOf(fieldValuesMap.get('Number_of_months_of_Free_service__c')) : null;
        quote.Bypass_Multiline__c = String.isNotBlank(fieldValuesMap.get('Bypass_Multiline__c')) ? Boolean.valueOf(fieldValuesMap.get('Bypass_Multiline__c')) : true;
        
        quote.Future_Free_Months_Amount__c = String.isNotBlank(fieldValuesMap.get('Future_Free_Months_Amount__c')) ? Decimal.valueOf(fieldValuesMap.get('Future_Free_Months_Amount__c')) : null;
        
        if((quote.Future_Free_Months_Amount__c == null || quote.Future_Free_Months_Amount__c == 0)
            && (quote.Number_of_months_of_Free_service__c==null || quote.Number_of_months_of_Free_service__c==0)) {
            quote.Future_Free_Months_Amount__c = 0;
        }
    
        quote.Future_Free_Service_Type__c = String.isNotBlank(fieldValuesMap.get('Future_Free_Service_Type__c')) ? String.valueOf(fieldValuesMap.get('Future_Free_Service_Type__c')) : null;
        quote.OTD_Amt__c = String.isNotBlank(fieldValuesMap.get('OTD_Amt__c')) ? Decimal.valueOf(fieldValuesMap.get('OTD_Amt__c')) : null;
        quote.Buyout_Incumbent_Provider__c = String.isNotBlank(fieldValuesMap.get('Buyout_Incumbent_Provider__c')) ? String.valueOf(fieldValuesMap.get('Buyout_Incumbent_Provider__c')) : null;
        BuyoutQuoteLineQueueable.updateNewDCArchitecture(quote);
        return quote;
    }
	@testvisible
    private static Id processQuoteUpdate(SBQQ__Quote__c quote) {
        GS_SBQQQuoteService.TaxCalculationScheduled = true;
        SBQQ.TriggerControl.disable();
        GS_SBQQQuoteServiceAsync.asyncContext = 'CopyQuoteFieldsToOppty';
        update quote;
        SBQQ.TriggerControl.enable();

        Set<Id> quoteIds = new Set<Id>{quote.Id};
        Map<Id, SBQQ__Quote__c> sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesAndQuoteLinesById(quoteIds);
        BuyoutQuoteLineQueueable queueable = new BuyoutQuoteLineQueueable(sourceQuoteData);
        return System.enqueueJob(queueable);
    }
	@testvisible
    private static void logJobExecution(Id quoteId, Id jobId) {
        Log__c log = new Log__c(
            Quote__c = quoteId,
            Timestamp__c = System.now(),
            Type__c = 'RebateQueueable', 
            Message__c = 'Queueable job ID: ' + jobId
        );
        insert log;
    }

    @AuraEnabled
    public static Id createUpdateRebateLines(Id quoteId, String fieldValues, String operation) {
        try {
            if (operation == 'upsert') {
                SBQQ__Quote__c quote = updateQuoteFields(quoteId, fieldValues);
                Id jobId = processQuoteUpdate(quote);
                logJobExecution(quoteId, jobId);
                return jobId;
            } else if (operation == 'recalculate') {
                Set<Id> quoteIds = new Set<Id>{quoteId};
                Map<Id, SBQQ__Quote__c> sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesAndQuoteLinesById(quoteIds);
                BuyoutQuoteLineQueueable queueable = new BuyoutQuoteLineQueueable(sourceQuoteData);
                Id jobId = System.enqueueJob(queueable);
                logJobExecution(quoteId, jobId);
                return jobId;
            }
            return null;
        } catch(Exception e) {
            LOGGER.atError().setCLassName('RebateLogicHandler').setRecordId(quoteId).setExceptionOrMessage(e);
            Logger.setFunctionalityType('Rebates'); 
            Logger.setRecordId(quoteId);
            Logger.insertMasterLogs();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static AsyncApexJob trackJob(Id quoteId){
        try{
            Log__c log = [select id, Timestamp__c, Type__c, Message__c from Log__c where Quote__c = :quoteId and Type__c = 'RebateQueueable' order by Timestamp__c desc limit 1];
            Id jobId = log.Message__c.split(':')[1].trim();
            AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, CompletedDate, ExtendedStatus FROM AsyncApexJob WHERE Id = :jobId];
            if(job!=null){
                return job;
            }else{
                return null;
            }
        }catch(Exception e){
            LOGGER.atError().setCLassName('RebateLogicHandler').setRecordId(quoteId).setExceptionOrMessage(e);
            Logger.setFunctionalityType('Rebates'); 
            Logger.setRecordId(quoteId);
            Logger.insertMasterLogs();
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class QuoteWrap {
        @AuraEnabled public Id id;
        @AuraEnabled public Decimal competitorBuyoutAmount;
        @AuraEnabled public Decimal totalEstimatedInstallationCosts;
        @AuraEnabled public String isInstallationReimbursable;
        @AuraEnabled public Decimal oneTimeDiscount;
        @AuraEnabled public Datetime lastCalculatedOn;
        @AuraEnabled public String opportunityType;
        @AuraEnabled public String opportunityStage; // GTMS-28482: Added to check opportunity stage for component disable logic
        @AuraEnabled public Decimal opportunityProbability;
        @AuraEnabled public Boolean rebateOpp;
        @AuraEnabled public Boolean isBuyoutProductAvailable;
        @AuraEnabled public Boolean isInstallationCostProductAvailable;
        @AuraEnabled public Boolean isFutureFreeMonthsProductAvailable;
        @AuraEnabled public Boolean isOTDProductAvailable;
        @AuraEnabled public Decimal futureFreeMonths;
        @AuraEnabled public Decimal futureFreeMonthsAmount;
        @AuraEnabled public Boolean isDCMultiline;
        @AuraEnabled public String quoteStatus;
        @AuraEnabled public Boolean isSuperUser;
        @AuraEnabled public Boolean isDealDeskUser;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Decimal perMonthlicenseAmount;
        @AuraEnabled public Decimal netAmount;
        @AuraEnabled public Integer licenseTerm;
        @AuraEnabled public Decimal totalLicensePrice;
        @AuraEnabled public Boolean disableDC;
        @AuraEnabled public String disableDCReason;
        @AuraEnabled public Boolean newDCArchitecture;
        @AuraEnabled public String futureFreeServiceType;
        @AuraEnabled public String buyoutIncumbentProvider;

        public QuoteWrap(SBQQ__Quote__c quote, Boolean rebateOpp, Boolean isBuyoutProductAvailable,Boolean isInstallationCostProductAvailable,Boolean isFutureFreeMonthsProductAvailable,Boolean isOTDProductAvailable,Boolean isSuperUser, Decimal totalLicensePrice) {
            this.id = quote.Id;
            this.competitorBuyoutAmount = quote.Competitor_Buyout_Amount__c;
            this.totalEstimatedInstallationCosts = quote.Total_Estimated_Installation_Costs__c;
            this.isInstallationReimbursable = quote.Is_Installation_Reimbursable__c;
            this.oneTimeDiscount = quote.OTD_Amt__c;
            this.isDCMultiline = quote.Bypass_Multiline__c;
            this.lastCalculatedOn = quote.SBQQ__LastCalculatedOn__c;
            this.opportunityType = quote.SBQQ__Opportunity2__r.Type;
            this.opportunityStage = quote.SBQQ__Opportunity2__r.StageName; // GTMS-28482: Populate opportunity stage for component disable logic
            this.opportunityProbability = quote.SBQQ__Opportunity2__r.Probability;
            this.newDCArchitecture = quote.New_DC_architecture__c;
            if(rebateOpp){
                this.rebateOpp = true;
            }else{
                this.rebateOpp = false;
            }
            this.isBuyoutProductAvailable = isBuyoutProductAvailable;
            this.isInstallationCostProductAvailable = isInstallationCostProductAvailable;
            this.isFutureFreeMonthsProductAvailable = isFutureFreeMonthsProductAvailable;
            this.isOTDProductAvailable = isOTDProductAvailable;
            this.futureFreeMonths = quote.Number_of_months_of_Free_service__c;
            this.futureFreeMonthsAmount = quote.Future_Free_Months_Amount__c;
            this.quoteStatus = quote.SBQQ__Status__c;
            this.isSuperUser = isSuperUser;
            List<String> OTDVisibilityProfileIds = System.Label.OTDVisibilityProfileIds.split(';');
            this.isDealDeskUser = OTDVisibilityProfileIds.contains(UserInfo.getProfileId());

            if(totalLicensePrice != null && totalLicensePrice != 0 && quote.License_Term__c != null && quote.License_Term__c != '0'){
                this.perMonthlicenseAmount = totalLicensePrice / Decimal.valueOf(quote.License_Term__c);
            }else{
                this.perMonthlicenseAmount = 0;
            }
            this.netAmount = quote.Net_Amount_Rebate__c;
            this.licenseTerm = (quote.License_Term__c == null ) ? 0 : Integer.valueOf(quote.License_Term__c);
            this.totalLicensePrice = totalLicensePrice;
            if(quote.SBQQ__Opportunity2__r.Buyout_Opportunity__c != null ){
                this.disableDC = true;
                this.disableDCReason = 'A buyout Opportunity is already present on the Opportunity linked to this Quote.';
            }else{
                this.disableDC = false;
            }

            this.futureFreeServiceType = String.isBlank(quote.Future_Free_Service_Type__c) ? 'Months' : quote.Future_Free_Service_Type__c;
            this.buyoutIncumbentProvider = quote.Buyout_Incumbent_Provider__c;
        }
        public QuoteWrap(String errorMessage){
            this.errorMessage = errorMessage;
        }
    }

    public class RebateConflictInput {
        @InvocableVariable(required=true description='Quote ID to check for conflicts')
        public Id quoteId;
    }
    
    public class RebateConflictOutput {
        @InvocableVariable(description='True if conflicts exist, false otherwise')
        public Boolean hasConflicts;
    }

    @InvocableMethod(label='Check Rebate Conflicts' description='Checks if there are any conflicts with rebate quote lines')
    public static List<RebateConflictOutput> checkRebateConflictsFlow(List<RebateConflictInput> inputs) {
        List<RebateConflictOutput> outputs = new List<RebateConflictOutput>();
        
        for (RebateConflictInput input : inputs) {
            RebateConflictOutput output = new RebateConflictOutput();
            
            try {
                output.hasConflicts = BuyoutQuoteLineQueueable.checkForConflicts(input.quoteId);
            } catch (Exception e) {
                output.hasConflicts = false; // Default to true if there's an error
                LOGGER.atError().setCLassName('RebateLogicHandler').setRecordId(input.quoteId).setExceptionOrMessage(e);
                Logger.setFunctionalityType('Rebates'); 
                if(input.quoteId != null){
                Logger.setRecordId(input.quoteId);
                }
                Logger.insertMasterLogs();
            }
            
            outputs.add(output);
        }
        
        return outputs;
    }

}