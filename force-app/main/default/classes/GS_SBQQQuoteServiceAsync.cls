/**
* Created By : Groundswell - Suman Kundu
* @Date September 10, 2021
*
* @description : This class will be responsible for handling Async Actions on SBQQ Quote
* SFA-11
*
**/

public without sharing class GS_SBQQQuoteServiceAsync extends BaseAsyncHandler{
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger(); 
    public override String getRequestType(){
        return 'SBQQ Quote Service Async Job';
    } 
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        SBQQ__Quote__c.SObjectType
    };
                
    UnitOfWork uow = new UnitOfWork(MY_SOBJECTS);
    @TestVisible List<Id> recordsIds = new List<Id>();
    private Options option;
    public static String asyncContext;
    
    public override void execute(Async_Request__c ar)
    {
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        option = (Options) JSON.deserialize(ar.Options__c, Options.class);
        
        // Do something with Quote Records
        try{
            thisLogger.logTrace('Entering in GS_SBQQQuoteServiceAsync');
            System.debug('****option.Operation> '+option.Operation);
            switch on option.Operation {
                when 'Insert' {
                }
                when 'Update' {
                }
                when 'Upsert' {
                }
                when 'Delete' {
                }
                /* when 'recalculateQuote' {
                    recalculateQuote();
                } */
                when 'CopyQuoteFieldsToOppty' {
                    asyncContext = 'CopyQuoteFieldsToOppty';
                    copyValuesToOpporttunity();
                }
                /*when 'updatedQuoteLines' {
                    updatedQuoteLines();
                }*/
            }
        }catch(Exception ex){
            thisLogger.logError(
                'Error in GS_SBQQQuoteServiceAsync::',
                new SamsaraLoggerObjectMVP(
                    ex, recordsIds
                )
            );
            throw ex;
        }finally{
            thisLogger.dispatch();
        }
    }

    /* public void recalculateQuote() {
        List<SBQQ__Quote__c> qts = new List <SBQQ__Quote__c>();
        for (Id quoteId : recordsIds) {
            SBQQ__Quote__c cpq = new SBQQ__Quote__c(Id = quoteId, Recalculate_Quote__c = true, First_Calculated__c = Date.today());
            qts.add(cpq);
        }
        if (!qts.isempty()) {
            thisLogger.logDebug('Recalculating Quote Records :: ', recordsIds);
            uow.registerDirty(qts);
            uow.commitWork();
        }

        List<CS_Record__c> csRecords = new List<CS_Record__c>();
        csRecords = new GS_CS_RecordSelector(true).checkFatalError().getCSRecordsByIds(recordsIds);
        if(!csRecords.isEmpty()) {
            thisLogger.logDebug('Deleting CS Record  ::', csRecords);
            //delete csRecords;
            uow.registerDeleted(csRecords);
            uow.commitWork();
        }
    } */

    // Below method copies values from Quote to Oppotunity
    public void copyValuesToOpporttunity() {
        thisLogger.logTrace('Entering into copyValuesToOpportunity');
        DMLWrapper.intializeUnitOfWork(new List<Schema.SObjectType>{
            Opportunity.SObjectType
        });
        Set<Id> quoteIds = new Set<Id>();
        quoteIds.addAll(recordsIds);
        List<SBQQ__Quote__c> quoteList = new GS_SBQQQuoteSelector(true).checkFatalError().getAllCustomFieldsQuotesById(quoteIds).values();
        Set<Id> opptyIds = new Set<Id>();
        for (SBQQ__Quote__c quote : quoteList) {
            opptyIds.add(quote.SBQQ__Opportunity2__c);
        }
        List<Quote_To_Opportunity_Mapping__mdt> quoteToOpptyFieldMapping = new GS_QuoteToOpportunityMappingSelector(true).checkFatalError().getFieldMapping();
        Map<Id, Opportunity> opptyMap = new GS_OpportunitySelector(true).checkFatalError().getQuoteToOppotyFieldMappingData(opptyIds, quoteToOpptyFieldMapping);
        if (opptyMap == null || opptyMap.size() == 0) {
            return;
        }
        Map<String, Quote_To_Opportunity_Mapping__mdt> fieldMappings = new Map<String, Quote_To_Opportunity_Mapping__mdt>();
        for (Quote_To_Opportunity_Mapping__mdt mapping : quoteToOpptyFieldMapping) {
            fieldMappings.put(mapping.Quote_Field__c, mapping);
        }
        Map<String, Schema.SobjectField> opptyFieldSchema = Opportunity.SObjectType.getDescribe().fields.getMap();
        List<SobjectField> dirtyFields = new List<SObjectField>();
        for (SBQQ__Quote__c updatedQuote : quoteList) {
            Boolean changeFlag = false;
            if (updatedQuote.SBQQ__Primary__c == true) {
                Opportunity relatedOpportunity = opptyMap.get(updatedQuote.SBQQ__Opportunity2__c);
                dirtyFields.clear();
                //* 11/5/2020 Ron - (GTMS - 2064) Waterfall approach to ternary operators to make checks based on declarative updates to custom metadata
                for(String quoteField : fieldMappings.keySet()) {
                    Quote_To_Opportunity_Mapping__mdt mappingMetadata = fieldMappings.get(quoteField);
                    String oppField = mappingMetadata.Opportunity_Field__c;
                    Boolean noBypass = mappingMetadata.Bypass__c? false: true;
                    Boolean isChanged = relatedOpportunity.get(oppField) != updatedQuote.get(quoteField)? true: false;
                    Boolean nullCheck = mappingMetadata.Null_Check__c == true && isChanged? updatedQuote.get(quoteField) != null: isChanged;
                    Boolean typeCheck = mappingMetadata.Type__c != null && isChanged? mappingMetadata.Type__c == updatedQuote.Configuration_Segment__c||relatedOpportunity.Is_Webstore_Upsell_Opportunity__c : nullCheck;
                	Boolean ownerCheck = mappingMetadata.Owner_Segment__c != null && isChanged? mappingMetadata.Owner_Segment__c.contains(relatedOpportunity.Account.Segment__c) : nullCheck;
                    
                    if(isChanged && nullCheck && typeCheck && noBypass && ownerCheck){
                        relatedOpportunity.put(oppField, updatedQuote.get(quoteField));
                        changeFlag = true;
                        Schema.SobjectField theDirtyField = opptyFieldSchema.get(oppField);
                        dirtyFields.add(theDirtyField);
                    }
                }
                
                if (updatedQuote.Upsell_Amount__c != NULL && (updatedQuote.License_Term__c != NULL || updatedQuote.Custom_License_Term__c != NULL)) {
                    Decimal term = updatedQuote.License_Term__c != NULL? Decimal.valueOf(updatedQuote.License_Term__c) : updatedQuote.Custom_License_Term__c;
                    relatedOpportunity.FP_and_Upsell_ACV__c = updatedQuote.Upsell_Amount__c / (term /12) ;
                    changeFlag = true;
                    dirtyFields.add(Opportunity.FP_and_Upsell_ACV__c);
                }
                
                if (updatedQuote.SBQQ__RenewalTerm__c != NULL && updatedQuote.Renewal_Amount__c != NULL && String.isNotBlank(updatedQuote.License_Term__c)) {
                    relatedOpportunity.Renewal_ACV__c = (updatedQuote.Renewal_Amount__c  + updatedQuote.Downsell_Amount__c) / (Decimal.valueOf(updatedQuote.License_Term__c) /12);
                    //relatedOpportunity.FP_and_Upsell_ACV__c = updatedQuote.Upsell_Amount__c / (Decimal.valueOf(updatedQuote.License_Term__c) /12) ;
                    changeFlag = true;
                    //dirtyFields.add(Opportunity.Upsell_ACV__c);
                    dirtyFields.add(Opportunity.Renewal_ACV__c);
                } 
                
                if ((updatedQuote.License_Term__c != null) &&
                        (relatedOpportunity.License_Term_CPQ__c != Decimal.valueOf(updatedQuote.License_Term__c))) {
                    relatedOpportunity.License_Term_CPQ__c = Decimal.valueOf(updatedQuote.License_Term__c);
                    changeFlag = true;
                    dirtyFields.add(Opportunity.License_Term_CPQ__c);
                }
                if (updatedQuote.License_Term__c != null) {
                    Decimal licenseTerm = Decimal.valueOf(updatedQuote.License_Term__c);
                    if (relatedOpportunity.License_Term__c != licenseTerm) {
                        relatedOpportunity.License_Term__c = licenseTerm;
                        changeFlag = true;
                        dirtyFields.add(Opportunity.License_Term__c);
                    } 
                }
                /*To sync License Term Fields on Opportunity from CPQ Quote's Custom License Term - GTMS-3734 - @Gaurav Sharma Start*/
                if (updatedQuote.Custom_License_Term__c != null) {
                    if(relatedOpportunity.License_Term_CPQ__c != updatedQuote.Custom_License_Term__c){
                        relatedOpportunity.License_Term_CPQ__c = updatedQuote.Custom_License_Term__c;
                        changeFlag = true;
                        dirtyFields.add(Opportunity.License_Term_CPQ__c);
                    }
                    if(relatedOpportunity.License_Term__c != updatedQuote.Custom_License_Term__c){
                        relatedOpportunity.License_Term__c = updatedQuote.Custom_License_Term__c;
                        changeFlag = true;
                        dirtyFields.add(Opportunity.License_Term__c);
                    }
                }
                thisLogger.logTrace('Values:'+option.quoteEligibleActions+' :: '+updatedQuote.Id);
                if (option.quoteEligibleActions != null && option.quoteEligibleActions.containsKey(updatedQuote.Id)) {
                    List<String> actions = option.quoteEligibleActions.get(updatedQuote.Id).split(',');
                    for (String action : actions) {
                        if (action == 'DA') {
                            String discountApprovedStatus = updatedQuote.Discount_Approval_Required__c;
                            if (discountApprovedStatus.contains('No Approval Needed')) {
                                relatedOpportunity.Discount_Approval_Status_from_Quote__c = false;
                            } else {
                                relatedOpportunity.Discount_Approval_Status_from_Quote__c = true;
                            }
                            changeFlag = true;
                            dirtyFields.add(Opportunity.Discount_Approval_Status_from_Quote__c);
                        } else if (action == 'PA') {
                            String productApprovedStatus = updatedQuote.Product_Approval__c;
                            if (productApprovedStatus.contains('No Approval Needed')) {
                                relatedOpportunity.Product_Approval_Status_from_Quote__c = false;
                            } else {
                                relatedOpportunity.Product_Approval_Status_from_Quote__c = true;
                            }
                            changeFlag = true;
                            dirtyFields.add(Opportunity.Product_Approval_Status_from_Quote__c);
                        } else if (action == 'AD') {
                            relatedOpportunity.Approved_Discount__c = updatedQuote.Approved_Discount__c;
                            changeFlag = true;
                            dirtyFields.add(Opportunity.Approved_Discount__c);
                        } 
                    }
                }

                if(changeFlag == true) {
                    System.debug('++++relatedOpportunity> '+relatedOpportunity);
                    System.debug('++++dirtyFields> '+dirtyFields);
                    DMLWrapper.doUpdate(relatedOpportunity, dirtyFields);
                }
            }
        }
        DMLWrapper.publishDML(); 
    }
    /*
    // Below method updates quote lines from Quote DML statement
    public void updatedQuoteLines() {
        thisLogger.logTrace('Entering into updatedQuoteLines');
        DMLWrapper.intializeUnitOfWork(new List<Schema.SObjectType>{
            SBQQ__QuoteLine__c.SObjectType
        });
        Set<Id> quoteIds = new Set<Id>();
        quoteIds.addAll(recordsIds);
        Map<Id, SBQQ__QuoteLine__c> relatedQuoteLines;
        if (quoteIds.size() > 0) {
            relatedQuoteLines = new GS_SBQQQuoteLineSelector(true).checkFatalError().getQuoteLinessByQuoteId(quoteIds);
        }

        List<SObjectField> dirtyFields = new List<SObjectField>();
        // Code to stamp the changed Ship TO on line items.
        List<SBQQ__QuoteLine__c> updatedQuoteLines = new List<SBQQ__QuoteLine__c>();
        if (relatedQuoteLines != null) {
            for (SBQQ__QuoteLine__c quoteLine : relatedQuoteLines.values()) {
                Boolean changeFlag = false;
                if (quoteLine.Ship_To__c != quoteLine.SBQQ__Quote__r.Shipping_Address_NEW__c) {
                    quoteLine.Ship_To__c = quoteLine.SBQQ__Quote__r.Shipping_Address_NEW__c;
                    changeFlag = true;
                    dirtyFields.add(SBQQ__QuoteLine__c.Ship_To__c);
                }
                if(quoteLine.Ship_From_Location__c  != quoteLine.SBQQ__Quote__r.Ship_From_Location__c ){
                    quoteLine.Ship_From_Location__c = quoteLine.SBQQ__Quote__r.Ship_From_Location__c ;
                    changeFlag = true;
                    dirtyFields.add(SBQQ__QuoteLine__c.Ship_From_Location__c);
                }
                if(changeFlag == true) {
                    //updatedQuoteLines.add(quoteLine);
                    DMLWrapper.doUpdate(quoteLine, dirtyFields);
                }
            } 
        }
        if (!Test.isRunningTest()) {
            DMLWrapper.publishDML();
        }
    }*/

    public class Options {
        public String Operation {get; set;}
        public Map<String, String> quoteEligibleActions; // Eligible actions comma separated
        
        public Options(String operation){
            this.Operation = operation;
        }

        public Options(String operation, Map<String, String> quoteEligibleActions){
            this.Operation = operation;
            this.quoteEligibleActions = quoteEligibleActions;
        }
    }
}