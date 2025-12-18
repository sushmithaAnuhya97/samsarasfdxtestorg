/**
 * @description Controller for handling Free Trial to Purchase conversion process
 * @author Your Name
 * @date 2024
 */
public without sharing class CreateFreeTrialReturnController {
    
    /**
     * @description Custom exception class for Free Trial specific errors
     */
    public class FreeTrialException extends Exception {}
    
    /**
     * @description Wrapper class for Flow input parameters
     */
    public class FreeTrialRequest {
        @InvocableVariable(label='Opportunity Line Items')
        public List<OpportunityLineItem> optyLineItems;
        
        @InvocableVariable(label='Opportunity Id')
        public String opportunityId;
    }
    
    /**
     * @description Constants for CSV column names and error messages
     */
    private static final String CSV_FILENAME = 'UpdatedOpportunityLineItems';
    private static final Set<String> REQUIRED_COLUMNS = new Set<String>{
        'Trial Quantity',
        'Buying Quantity',
        'Product Code'
    };
    
    /**
     * @description Error message constants
     */
    private static final String ERROR_INVALID_REQUEST = 'Invalid request parameters provided';
    private static final String ERROR_OPPORTUNITY_NOT_FOUND = 'Opportunity not found';
    private static final String ERROR_CSV_NOT_FOUND = 'CSV file not found for opportunity';
    private static final String ERROR_CSV_INVALID_FORMAT = 'Invalid CSV format - required columns missing';
    private static final String ERROR_INVALID_TRIAL_TYPE = 'Invalid Free Trial Purchase type: {0}';
    private static final String ERROR_PROCESSING_CSV = 'Error processing CSV: {0}';
    private static final String ERROR_INSERTING_ITEMS = 'Error inserting line items: {0}';
    
    /**
     * @description Main invocable method to process free trial returns
     * @param requests List of FreeTrialRequest objects
     * @throws FreeTrialException if validation fails
     */
    @InvocableMethod(label='Insert OpportunityLineItems' description='Process free trial returns and insert opportunity line items')
    public static void insertOptyLineItem(List<FreeTrialRequest> requests) {
        try {
            System.debug('=== Starting Free Trial Return Process ===');
            System.debug('Number of requests received: ' + requests.size());
            
            validateRequests(requests);
            
            List<Database.SaveResult> results = new List<Database.SaveResult>();
            
            for(FreeTrialRequest request : requests) {
                try {
                    System.debug('Processing request for Opportunity ID: ' + request.opportunityId);
                    System.debug('Number of line items in request: ' + (request.optyLineItems != null ? request.optyLineItems.size() : 0));
                    
                    processRequest(request);
                } catch(Exception e) {
                    logError('Error processing request', e);
                }
            }
        } catch(Exception e) {
            System.debug('Error in insertOptyLineItem: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            handleException(e);
        }
    }
    
    /**
     * @description Validates the incoming requests
     * @param requests List of FreeTrialRequest objects to validate
     * @throws FreeTrialException if validation fails
     */
    private static void validateRequests(List<FreeTrialRequest> requests) {
        if(requests == null || requests.isEmpty()) {
            throw new FreeTrialException(ERROR_INVALID_REQUEST);
        }
        
        for(FreeTrialRequest request : requests) {
            if(request.optyLineItems == null || request.optyLineItems.isEmpty() || 
               String.isBlank(request.opportunityId)) {
                throw new FreeTrialException(ERROR_INVALID_REQUEST);
            }
        }
    }
    
    /**
     * @description Processes individual free trial request
     * @param request FreeTrialRequest object to process
     * @throws FreeTrialException if processing fails
     */
    private static void processRequest(FreeTrialRequest request) {
        Savepoint sp = Database.setSavepoint();
        try {
            SBQQ.TriggerControl.disable();
            
            Opportunity opp = queryOpportunity(request.opportunityId);
            String purchaseType = String.isBlank(opp?.TrialResolutionOppty__r?.Free_Trial_Purchase__c) ? 'no purchase' : 
                opp?.TrialResolutionOppty__r?.Free_Trial_Purchase__c.toLowerCase();
            
            System.debug('Processing request with purchase type: ' + purchaseType);
            
            switch on purchaseType {
                when 'full buy' {
                    return; // No action needed for full buy
                }
                when 'no purchase' {
                    insertLineItems(request.optyLineItems);
                }
                when 'partial buy' {
                    processPartialBuy(request, opp);
                }
                when else {
                    throw new FreeTrialException(String.format(ERROR_INVALID_TRIAL_TYPE, 
                        new List<String>{purchaseType}));
                }
            }
        } catch(Exception e) {
            Database.rollback(sp);
            throw e;
        } finally {
            SBQQ.TriggerControl.enable();
        }
    }
    
    /**
     * @description Queries opportunity with necessary fields
     * @param opportunityId Id of the opportunity to query
     * @return Opportunity record
     * @throws FreeTrialException if opportunity not found
     */
    private static Opportunity queryOpportunity(String opportunityId) {
        List<Opportunity> opps = [
            SELECT Id,TrialResolutionOppty__c, TrialResolutionOppty__r.Free_Trial_Purchase__c 
            FROM Opportunity 
            WHERE Id = :opportunityId 
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        System.debug('opps trial'+opps);
        if(opps.isEmpty()) {
            throw new FreeTrialException(ERROR_OPPORTUNITY_NOT_FOUND);
        }
        
        return opps[0];
    }
    
    /**
     * @description Processes partial buy scenario using CSV data
     * @param request FreeTrialRequest object
     * @param opp Opportunity record
     * @throws FreeTrialException if processing fails
     */
    private static void processPartialBuy(FreeTrialRequest request, Opportunity opp) {
        if(opp == null) {
            throw new FreeTrialException(ERROR_OPPORTUNITY_NOT_FOUND);
        }
        
        System.debug('Starting processPartialBuy with request OLIs: ' + request.optyLineItems);
        
        ContentVersion csvVersion = getCsvFile(opp.Id, opp.TrialResolutionOppty__c);
        if(csvVersion == null) {
            insertLineItems(request.optyLineItems);
            return;
        }

        System.debug('Retrieved CSV file: ' + csvVersion.VersionData.toString());
        
        Map<String, Map<String, Decimal>> productQuantities = processCsvData(csvVersion);
        System.debug('Processed product quantities: ' + productQuantities);
        
        List<OpportunityLineItem> validOLIs = updateLineItemQuantities(request.optyLineItems, productQuantities);
        System.debug('Valid OLIs after quantity update: ' + validOLIs);
        
        if(!validOLIs.isEmpty()) {
            insertLineItems(validOLIs);
        } else {
            System.debug('No valid OLIs to insert - all quantities were zero or negative');
        }
    }
    
    /**
     * @description Retrieves CSV file from Salesforce Files
     * @param opportunityId Id of the linked opportunity
     * @param trialOpportunityId Id of the trial opportunity
     * @return ContentVersion containing CSV data
     * @throws FreeTrialException if file not found
     */
    private static ContentVersion getCsvFile(Id opportunityId, Id trialOpportunityId) {
        System.debug('Looking for CSV file for opportunity: ' + opportunityId);
        
        // First try to find the file on the current opportunity
        List<ContentDocumentLink> documentLinks = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :opportunityId 
            AND ContentDocument.Title LIKE 'UpdatedOpportunityLineItems%'
            WITH SECURITY_ENFORCED
        ];
        System.debug('Found document links on current opportunity: ' + documentLinks);
        
        if(documentLinks.isEmpty() && trialOpportunityId != null) {
            System.debug('Looking for CSV file on trial opportunity: ' + trialOpportunityId);
            documentLinks = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :trialOpportunityId 
                AND ContentDocument.Title LIKE 'UpdatedOpportunityLineItems%'
                WITH SECURITY_ENFORCED
            ];
            System.debug('Found document links on trial opportunity: ' + documentLinks);
        }

        if(documentLinks.isEmpty()) {
            return null;    
        }
        
        List<ContentVersion> versions = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :documentLinks[0].ContentDocumentId
            AND IsLatest = true
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        System.debug('Found content versions: ' + versions);

        if(versions.isEmpty()) {
            return null;
        }
        
        return versions[0];
    }
    
    /**
     * @description Splits CSV row handling values that contain commas
     * @param row CSV row to split
     * @return List of column values
     */
    private static List<String> parseCSVRow(String row) {
        List<String> fields = new List<String>();
        String field = '';
        Boolean inQuotes = false;
        
        for(Integer i = 0; i < row.length(); i++) {
            String character = row.substring(i, i + 1);
            
            if(character == '"') {
                inQuotes = !inQuotes; // Toggle quote state
            } else if(character == ',' && !inQuotes) {
                fields.add(field.trim());
                field = '';
            } else {
                field += character;
            }
        }
        fields.add(field.trim());
        return fields;
    }
    
    /**
     * @description Processes CSV data and returns quantity mapping
     * @param csvVersion ContentVersion containing CSV data
     * @return Map of product code to quantities
     * @throws FreeTrialException if CSV processing fails
     */
    private static Map<String, Map<String, Decimal>> processCsvData(ContentVersion csvVersion) {
        Map<String, Map<String, Decimal>> productQuantities = new Map<String, Map<String, Decimal>>();
        
        try {
            String csvData = csvVersion.VersionData.toString();
            List<String> rows = csvData.split('\n');
            
            System.debug('Processing CSV with ' + rows.size() + ' rows');
            
            if(rows.size() < 2) {
                throw new FreeTrialException(ERROR_CSV_INVALID_FORMAT);
            }
            
            Map<String, Integer> columnIndexes = getColumnIndexes(rows[0]);
            System.debug('Column indexes found: ' + columnIndexes);
            
            for(Integer i = 1; i < rows.size(); i++) {
                String row = cleanHyperlinkFormula(rows[i]);
                List<String> columns = parseCSVRow(row);
                
                System.debug('Processing row ' + i + ': ' + row);
                System.debug('Parsed columns: ' + columns);
                
                if(isValidRow(columns, columnIndexes)) {
                    processDataRow(columns, columnIndexes, productQuantities);
                } else {
                    System.debug('WARNING: Invalid row format at row ' + i);
                }
            }
            
            System.debug('Final processed quantities: ' + productQuantities);
        } catch(Exception e) {
            System.debug('ERROR in processCsvData: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new FreeTrialException(String.format(ERROR_PROCESSING_CSV, 
                new List<String>{e.getMessage()}));
        }
        
        return productQuantities;
    }
    
    /**
     * @description Gets column indexes from CSV header
     * @param headerRow CSV header row
     * @return Map of column name to index
     * @throws FreeTrialException if required columns are missing
     */
    private static Map<String, Integer> getColumnIndexes(String headerRow) {
        Map<String, Integer> columnIndexes = new Map<String, Integer>();
        List<String> headers = parseCSVRow(headerRow);
        
        for(Integer i = 0; i < headers.size(); i++) {
            String header = headers[i].trim().toLowerCase();
            for(String requiredColumn : REQUIRED_COLUMNS) {
                if(header == requiredColumn.toLowerCase()) {
                    columnIndexes.put(requiredColumn, i);
                }
            }
        }
        
        if(columnIndexes.size() != REQUIRED_COLUMNS.size()) {
            throw new FreeTrialException(ERROR_CSV_INVALID_FORMAT);
        }
        
        return columnIndexes;
    }
    
    /**
     * @description Validates if a row has all required columns
     * @param columns List of column values
     * @param columnIndexes Map of column names to indexes
     * @return Boolean indicating if row is valid
     */
    private static Boolean isValidRow(List<String> columns, Map<String, Integer> columnIndexes) {
        Integer maxIndex = Math.max(Math.max(
            columnIndexes.get('Trial Quantity'),
            columnIndexes.get('Buying Quantity')),
            columnIndexes.get('Product Code'));
            
        return columns.size() > maxIndex;
    }
    
    /**
     * @description Processes a single data row from CSV
     * @param columns List of column values
     * @param columnIndexes Map of column names to indexes
     * @param productQuantities Map to store processed quantities
     */
    private static void processDataRow(
        List<String> columns,
        Map<String, Integer> columnIndexes,
        Map<String, Map<String, Decimal>> productQuantities
    ) {
        try {
            String productCode = columns[columnIndexes.get('Product Code')].trim().remove('"');
            String trialQtyStr = columns[columnIndexes.get('Trial Quantity')].trim().remove('"').remove(',');
            String buyingQtyStr = columns[columnIndexes.get('Buying Quantity')].trim().remove('"').remove(',');
            
            System.debug('=== Processing Product Quantities ===');
            System.debug('Product Code: ' + productCode);
            System.debug('Trial Quantity: ' + trialQtyStr);
            System.debug('Buying Quantity: ' + buyingQtyStr);
            
            if(String.isBlank(trialQtyStr) || String.isBlank(buyingQtyStr)) {
                System.debug('WARNING: Empty quantity values found for product: ' + productCode);
                return;
            }
            
            Decimal trialQuantity = Decimal.valueOf(trialQtyStr);
            Decimal buyingQuantity = Decimal.valueOf(buyingQtyStr);
            
            if(String.isNotBlank(productCode) && trialQuantity != null && buyingQuantity != null) {
                Decimal remainingQty = trialQuantity - buyingQuantity;
                System.debug('=== Quantity Calculation Results ===');
                System.debug('Product: ' + productCode);
                System.debug('Trial Quantity: ' + trialQuantity);
                System.debug('Buying Quantity: ' + buyingQuantity);
                System.debug('Remaining Quantity: ' + remainingQty);
                
                productQuantities.put(productCode, new Map<String, Decimal>{
                    'trial' => trialQuantity,
                    'buying' => buyingQuantity,
                    'remaining' => remainingQty
                });
            }
        } catch(Exception e) {
            System.debug('ERROR processing row: ' + columns);
            logError('Error processing CSV row', e);
        }
    }
    
    /**
     * @description Updates line item quantities based on CSV data
     * @param lineItems List of OpportunityLineItem records
     * @param productQuantities Map of product quantities
     * @return List<OpportunityLineItem> List of valid OLIs with positive quantities
     */
    private static List<OpportunityLineItem> updateLineItemQuantities(
        List<OpportunityLineItem> lineItems,
        Map<String, Map<String, Decimal>> productQuantities
    ) {
        Set<Id> pricebookEntryIds = new Set<Id>();
        for(OpportunityLineItem oli : lineItems) {
            pricebookEntryIds.add(oli.PricebookEntryId);
        }
        
        System.debug('Querying PricebookEntries for IDs: ' + pricebookEntryIds);
        
        Map<Id, String> pbeToProductCode = new Map<Id, String>();
        for(PricebookEntry pbe : [
            SELECT Id, ProductCode 
            FROM PricebookEntry 
            WHERE Id IN :pricebookEntryIds
            WITH SECURITY_ENFORCED
        ]) {
            pbeToProductCode.put(pbe.Id, pbe.ProductCode);
        }
        
        System.debug('PBE to ProductCode mapping: ' + pbeToProductCode);
        
        List<OpportunityLineItem> validOLIs = new List<OpportunityLineItem>();
        
        for(OpportunityLineItem oli : lineItems) {
            String productCode = pbeToProductCode.get(oli.PricebookEntryId);
            System.debug('Processing OLI with PBE: ' + oli.PricebookEntryId + ', ProductCode: ' + productCode);
            
            if(productCode != null && productQuantities.containsKey(productCode)) {
                Decimal remainingQty = productQuantities.get(productCode).get('remaining');
                System.debug('Calculated remaining quantity for product ' + productCode + ': ' + remainingQty);
                
                if(remainingQty > 0) {
                    oli.Quantity = remainingQty;
                    validOLIs.add(oli);
                    System.debug('Added OLI with quantity ' + remainingQty + ' for product ' + productCode);
                } else {
                    System.debug('Skipping OLI for product ' + productCode + ' due to zero/negative quantity: ' + remainingQty);
                }
            } else {
                System.debug('WARNING: No quantity mapping found for product code: ' + productCode);
            }
        }
        
        System.debug('Total valid OLIs to be inserted: ' + validOLIs.size());
        return validOLIs;
    }
    
    /**
     * @description Inserts opportunity line items with error handling
     * @param lineItems List of OpportunityLineItem records to insert
     * @throws FreeTrialException if insert fails
     */
    private static void insertLineItems(List<OpportunityLineItem> lineItems) {
        try {
            System.debug('=== Starting Line Item Insertion ===');
            System.debug('Original number of line items: ' + lineItems.size());
            
            // Get PricebookEntry IDs to query Product Codes
            Set<Id> pbeIds = new Set<Id>();
            for(OpportunityLineItem oli : lineItems) {
                pbeIds.add(oli.PricebookEntryId);
            }
            
            // Query PricebookEntries to get Product Codes
            Map<Id, String> pbeToProductCode = new Map<Id, String>();
            for(PricebookEntry pbe : [
                SELECT Id, ProductCode 
                FROM PricebookEntry 
                WHERE Id IN :pbeIds
                WITH SECURITY_ENFORCED
            ]) {
                pbeToProductCode.put(pbe.Id, pbe.ProductCode);
            }
            
            // Filter line items based on product code adding only HW, CBL, ACC products GTMS-27750
            List<OpportunityLineItem> filteredLineItems = new List<OpportunityLineItem>();
            for(OpportunityLineItem oli : lineItems) {
                String productCode = pbeToProductCode.get(oli.PricebookEntryId);
                System.debug('Processing product: ' + productCode);
                
                if(productCode != null && 
                   (productCode.startsWith('HW') || 
                    productCode.startsWith('CBL') || 
                    productCode.startsWith('ACC'))) {
                    filteredLineItems.add(oli);
                    System.debug('Added product to filtered list: ' + productCode);
                } else {
                    System.debug('Skipped product (not HW/CBL/ACC): ' + productCode);
                }
            }
            
            System.debug('Filtered number of line items: ' + filteredLineItems.size());
            
            if(!filteredLineItems.isEmpty()) {
                insert filteredLineItems;
                System.debug('Successfully inserted ' + filteredLineItems.size() + ' line items');
            } else {
                System.debug('No valid line items to insert after filtering');
            }
        } catch(Exception e) {
            System.debug('ERROR inserting line items: ' + e.getMessage());
            System.debug('ERROR stack trace: ' + e.getStackTraceString());
            throw new FreeTrialException(String.format(ERROR_INSERTING_ITEMS, 
                new List<String>{e.getMessage()}));
        }
    }
    
    /**
     * @description Cleans HYPERLINK formula from CSV row
     * @param row CSV row
     * @return Cleaned row
     */
    private static String cleanHyperlinkFormula(String row) {
        if(!row.contains('=HYPERLINK(')) {
            return row;
        }
        
        String hyperlinkPart = row.substringBetween('=HYPERLINK(', '"")');
        if(String.isBlank(hyperlinkPart)) {
            return row;
        }
        
        List<String> hyperlinkParts = hyperlinkPart.split(',');
        if(hyperlinkParts.size() >= 2) {
            String productCode = hyperlinkParts[1].trim().remove('""');
            return row.substringBefore('=HYPERLINK(') + productCode + row.substringAfterLast('"")');
        }
        return row;
    }
    
    /**
     * @description Logs error messages with stack trace
     * @param message Error message
     * @param e Exception to log
     */
    private static void logError(String message, Exception e) {
        System.debug(LoggingLevel.ERROR, message + ': ' + e.getMessage());
        System.debug(LoggingLevel.ERROR, e.getStackTraceString());
    }
    
    /**
     * @description Handles exceptions by logging and rethrowing as FreeTrialException
     * @param e Exception to handle
     * @throws FreeTrialException with formatted message
     */
    private static void handleException(Exception e) {
        String errorMessage = 'Error in CreateFreeTrialReturnController: ' + e.getMessage();
        logError(errorMessage, e);
        throw new FreeTrialException(errorMessage);
    }
}