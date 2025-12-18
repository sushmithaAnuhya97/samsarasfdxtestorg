public without sharing class GS_SBQQQuoteVertexTaxService {

    @TestVisible private static final Boolean isWithinIgnoreContext = (System.isBatch() || System.isFuture());

    @TestVisible private static final String STATUS_VERTEX_ERROR_SEPARATOR = '; ';

    @TestVisible private static Set<Id> quoteIdsToCall;

    // Used for unit testing purposes only - This is to avoid DMLs during test class and still allow this to work
    @TestVisible private static Map<Id, List<SBQQ__QuoteLine__c>> TEST_OVERRIDE_QL_MAP;

    private static Boolean hasCalledVertex = false;

    public static Boolean callVertexManually = false;

    public void run(Map<Id, SBQQ__Quote__c> newQuoteMap, Map<Id, SBQQ__Quote__c> oldQuoteMap, Map<Id, SBQQ__Quote__c> quoteMapWithItems){
        System.debug('System.isFuture()'+System.isFuture());   
        System.debug('System.isBatch()'+System.isBatch());
        System.debug('System.isQueueable()'+System.isQueueable());
        System.debug('System.Label.Skip_Taxes'+System.Label.Skip_Taxes);
        if (isWithinIgnoreContext) return;

        quoteIdsToCall = new Set<Id>();

        for (Id quoteId : newQuoteMap.keySet()) {
            SBQQ__Quote__c editedQuote = newQuoteMap.get(quoteId);
            SBQQ__Quote__c oldQuote = oldQuoteMap.get(quoteId);
            List<SBQQ__QuoteLine__c> lineList = (!Test.isRunningTest() || TEST_OVERRIDE_QL_MAP == null ? quoteMapWithItems.get(quoteId).SBQQ__LineItems__r : TEST_OVERRIDE_QL_MAP.get(quoteId));

            System.debug('editedQuote.SBQQ__LastSavedOn__c --> '+editedQuote.SBQQ__LastSavedOn__c);
            System.debug('oldQuote.SBQQ__LastSavedOn__c --> '+oldQuote.SBQQ__LastSavedOn__c);
            System.debug('editedQuote.SBQQ__LastCalculatedOn__c --> '+editedQuote.SBQQ__LastCalculatedOn__c);
            System.debug('oldQuote.SBQQ__LastCalculatedOn__c --> '+oldQuote.SBQQ__LastCalculatedOn__c);
            System.debug('editedQuote.SBQQ__NetAmount__c --> '+editedQuote.SBQQ__NetAmount__c);
            System.debug('oldQuote.SBQQ__NetAmount__c --> '+oldQuote.SBQQ__NetAmount__c);

            // Run Quote validations and tax status update
            if (this.validate(editedQuote, oldQuote, lineList)){
                System.debug('VERTEX Validation successful for '+editedQuote.Id+' / '+editedQuote.Name);
                quoteIdsToCall.add(editedQuote.Id);
            }
        }

        if (!callVertexManually) {
            callVertex();
        }
    }

    private Boolean validate(SBQQ__Quote__c quote, SBQQ__Quote__c oldQuote, List<SBQQ__QuoteLine__c> lines){
        // Just skip calculation and other validations.
        if (this.shouldSkipVertex(quote, oldQuote)) return false;

        String errorMessage = this.getErrorsBeforeCall(quote, lines);
        if (String.isBlank(errorMessage)){
            this.updateVertexTaxStatus(quote, PopulateTaxes.STATUS_TAX_CALCULATION_REFRESH, '', quote.VertexCPQ__Tax_Amount__c);
            return true;
        }else{
            this.updateVertexTaxStatus(quote, PopulateTaxes.STATUS_TAX_CALCULATION_VALIDATION, errorMessage, null);
            return false;
        }
    }

    private String getErrorsBeforeCall(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> lines){
        String errorMessage = '';
        if (quote.Shipping_Address_NEW__c == null) errorMessage += Label.Vertex_Missing_Shipping_Address_error;
        for (SBQQ__QuoteLine__c ql : lines) {
            // This validation is for NULL only, not 0.
            if (ql.SBQQ__NetTotal__c == null) {
                errorMessage += (String.isBlank(errorMessage) ? '' : STATUS_VERTEX_ERROR_SEPARATOR)+Label.Vertex_Null_Line_Net_Total_error;
                break;
            }
        }

        return errorMessage;
    }

    private Boolean shouldSkipVertex(SBQQ__Quote__c quote, SBQQ__Quote__c oldQuote){
        if(quote.SBQQ__Account__c == null)
        	{
				return false;
        	}
        return ((System.Label.Skip_Taxes).contains(String.valueOf(quote.SBQQ__Account__c)) || quote.SBQQ__LastSavedOn__c == oldQuote.SBQQ__LastSavedOn__c);
    }

    private void updateVertexTaxStatus(SBQQ__Quote__c quote, String taxCalculationStatus, String vertexStatus, Decimal taxAmount){
        quote.Tax_Calculation_Status__c = taxCalculationStatus;
        quote.VertexCPQ__Tax_Status__c  = vertexStatus;
        quote.VertexCPQ__Tax_Amount__c  = taxAmount;
    }

    public static void callVertex(){
        if (!hasCalledVertex && quoteIdsToCall != null && quoteIdsToCall.size() > 0){
            PopulateTaxes.populateVertexTaxes(quoteIdsToCall);
            hasCalledVertex = true;
        }
    }
}