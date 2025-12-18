public class PriceRuleDocumentationGenerator {
    
    // Main method to generate documentation for all active price rules
    public static List<RuleDocumentation> generateAllRuleDocumentation() {
        List<RuleDocumentation> documentationList = new List<RuleDocumentation>();
        
        // Query all active price rules with related records
        List<SBQQ__PriceRule__c> rules = [
            SELECT Id, Name, SBQQ__Active__c, SBQQ__AdvancedCondition__c, SBQQ__ConditionsMet__c, 
                   SBQQ__ConfiguratorEvaluationEvent__c, SBQQ__EvaluationEvent__c, SBQQ__EvaluationOrder__c, 
                   SBQQ__LookupObject__c, SBQQ__Product__c, SBQQ__Product__r.Name, SBQQ__TargetObject__c,
                   (SELECT Id, Name, SBQQ__Field__c, SBQQ__FilterFormula__c, SBQQ__FilterType__c, 
                           SBQQ__Value__c, SBQQ__FilterVariable__c, SBQQ__Index__c, SBQQ__Object__c, 
                           SBQQ__Operator__c, SBQQ__ParentRuleIsActive__c, SBQQ__TestedFormula__c, 
                           SBQQ__TestedVariable__c, SBQQ__TestedVariable__r.SBQQ__CombineWith__c, SBQQ__FilterVariable__r.SBQQ__CombineWith__c
                    FROM SBQQ__PriceConditions__r ORDER BY SBQQ__Index__c),
                   (SELECT Id, Name, SBQQ__Field__c, SBQQ__Value__c, SBQQ__ValueField__c, SBQQ__SourceLookupField__c,
                           SBQQ__SourceVariable__c, SBQQ__Rule__c, SBQQ__TargetObject__c
                    FROM SBQQ__PriceActions__r)
            FROM SBQQ__PriceRule__c
            WHERE SBQQ__Active__c = true
            ORDER BY SBQQ__EvaluationOrder__c NULLS LAST
        ];
        
        // Query all lookup queries related to price rules
        Map<Id, List<SBQQ__LookupQuery__c>> lookupQueriesMap = new Map<Id, List<SBQQ__LookupQuery__c>>();
        List<SBQQ__LookupQuery__c> lookupQueries = [
            SELECT Id, Name, SBQQ__LookupField__c, SBQQ__MatchType__c, SBQQ__Operator__c, 
                   SBQQ__TestedField__c, SBQQ__TestedObject__c, SBQQ__TestedValue__c,
                   SBQQ__PriceRule2__c
            FROM SBQQ__LookupQuery__c
            WHERE SBQQ__PriceRule2__c IN :rules
        ];
        
        for(SBQQ__LookupQuery__c query : lookupQueries) {
            if(!lookupQueriesMap.containsKey(query.SBQQ__PriceRule2__c)) {
                lookupQueriesMap.put(query.SBQQ__PriceRule2__c, new List<SBQQ__LookupQuery__c>());
            }
            lookupQueriesMap.get(query.SBQQ__PriceRule2__c).add(query);
        }
        
        // Collect all summary variable IDs before processing rules
        Set<Id> allSummaryVarIds = new Set<Id>();
        for(SBQQ__PriceRule__c rule : rules) {
            for(SBQQ__PriceCondition__c condition : rule.SBQQ__PriceConditions__r) {
                if(condition.SBQQ__TestedVariable__c != null) {
                    allSummaryVarIds.add(condition.SBQQ__TestedVariable__c);
                }
                if(condition.SBQQ__FilterVariable__c != null) {
                    allSummaryVarIds.add(condition.SBQQ__FilterVariable__c);
                }
                if(condition.SBQQ__TestedVariable__r != null && condition.SBQQ__TestedVariable__r.SBQQ__CombineWith__c != null) {
                    allSummaryVarIds.add(condition.SBQQ__TestedVariable__r.SBQQ__CombineWith__c);
                }
                if(condition.SBQQ__FilterVariable__r != null && condition.SBQQ__FilterVariable__r.SBQQ__CombineWith__c != null) {
                    allSummaryVarIds.add(condition.SBQQ__FilterVariable__r.SBQQ__CombineWith__c);
                }
            }

            for(SBQQ__PriceAction__c action : rule.getSObjects('SBQQ__PriceActions__r')) {
                if(action.SBQQ__SourceVariable__c != null) {
                    allSummaryVarIds.add(action.SBQQ__SourceVariable__c);
                }
            }
        }
        
        // Query all summary variables at once
        Map<Id, SBQQ__SummaryVariable__c> summaryVarsMap = new Map<Id, SBQQ__SummaryVariable__c>();
        if(!allSummaryVarIds.isEmpty()) {
            summaryVarsMap = new Map<Id, SBQQ__SummaryVariable__c>([
                SELECT Id, Name, SBQQ__AggregateField__c, SBQQ__AggregateFunction__c, SBQQ__CombineWith__c, SBQQ__CompositeOperator__c, 
                       SBQQ__ConstraintField__c, SBQQ__FilterField__c, SBQQ__FilterValue__c, SBQQ__Operator__c, SBQQ__Scope__c, 
                       SBQQ__TargetObject__c, SBQQ__ValueElement__c
                FROM SBQQ__SummaryVariable__c
                WHERE Id IN :allSummaryVarIds
            ]);
        }
        
        // Process each rule with the pre-fetched summary variables and lookup queries
        for(SBQQ__PriceRule__c rule : rules) {
            RuleDocumentation doc = generateRuleDocumentation(rule, summaryVarsMap, lookupQueriesMap.get(rule.Id));
            documentationList.add(doc);
        }
        
        return documentationList;
    }
    
    // Generate documentation for a single rule
    private static RuleDocumentation generateRuleDocumentation(SBQQ__PriceRule__c rule, 
                                                              Map<Id, SBQQ__SummaryVariable__c> summaryVarsMap,
                                                              List<SBQQ__LookupQuery__c> lookupQueries) {
        RuleDocumentation doc = new RuleDocumentation();
        doc.ruleName = rule.Name;
        doc.ruleId = rule.Id;
        doc.evaluationScope = rule.SBQQ__TargetObject__c;
        doc.evaluationEvent = getEvaluationEventDescription(rule);
        doc.evaluationOrder = rule.SBQQ__EvaluationOrder__c;
        doc.conditionsMet = rule.SBQQ__ConditionsMet__c;
        doc.advancedCondition = rule.SBQQ__AdvancedCondition__c;
        doc.lookupObject = rule.SBQQ__LookupObject__c;
        
        // Add product information if specified
        if(rule.SBQQ__Product__c != null) {
            doc.productName = rule.SBQQ__Product__r.Name;
        }
        
        // Process conditions
        doc.conditionLogic = processConditionLogic(rule, summaryVarsMap);
        
        // Process actions
        doc.actions = processActions(rule, summaryVarsMap);
        
        // Process lookup queries
        if(lookupQueries != null && !lookupQueries.isEmpty()) {
            doc.lookupQueries = processLookupQueries(lookupQueries);
            
            // Get sample data for any lookup object (not just SBQQ__LookupData__c)
            doc.lookupData = getSampleLookupData(lookupQueries);
        }
        
        return doc;
    }
    
    // Helper to get evaluation event description
    private static String getEvaluationEventDescription(SBQQ__PriceRule__c rule) {
        String eventDescription = '';
        
        if(rule.SBQQ__TargetObject__c == 'Calculator') {
            eventDescription = rule.SBQQ__EvaluationEvent__c;
        } else if(rule.SBQQ__TargetObject__c == 'Configurator') {
            eventDescription = rule.SBQQ__ConfiguratorEvaluationEvent__c;
        }
        
        return eventDescription;
    }
    
    // Process condition logic including summary variables
    private static String processConditionLogic(SBQQ__PriceRule__c rule, Map<Id, SBQQ__SummaryVariable__c> summaryVarsMap) {
        String conditionLogic = '';
        
        // Build condition logic description
        String conditionsMetText = rule.SBQQ__ConditionsMet__c == 'All' ? 'ALL of the following conditions are met' : 
                                  (rule.SBQQ__ConditionsMet__c == 'Any' ? 'ANY of the following conditions are met' : 
                                  'Custom logic is applied: ' + rule.SBQQ__AdvancedCondition__c);
        
        conditionLogic = 'This rule will trigger when ' + conditionsMetText + ':\n\n';
        
        for(SBQQ__PriceCondition__c condition : rule.SBQQ__PriceConditions__r) {
            if((conditionsMetText.contains('Custom logic is applied') && rule.SBQQ__AdvancedCondition__c.contains(String.valueOf(condition.SBQQ__Index__c))) ||
                rule.SBQQ__ConditionsMet__c == 'All' || rule.SBQQ__ConditionsMet__c == 'Any') {
                
                Integer conditionNumber = 1;
                
                if (condition.SBQQ__Index__c != null) {
                    conditionNumber = Integer.valueOf(condition.SBQQ__Index__c);
                }
                
                conditionLogic += conditionNumber + '. ';
                
                // Describe the tested object
                conditionLogic += 'When ' + (condition.SBQQ__Object__c != null ? condition.SBQQ__Object__c + ' ' : '');
                
                // Describe the tested field or variable
                if(condition.SBQQ__TestedVariable__c != null) {
                    SBQQ__SummaryVariable__c var = summaryVarsMap.get(condition.SBQQ__TestedVariable__c);
                    conditionLogic += describeSummaryVariable(var, summaryVarsMap);
                } else if(condition.SBQQ__TestedFormula__c != null) {
                    conditionLogic += 'formula (' + condition.SBQQ__TestedFormula__c + ') ';
                } else {
                    conditionLogic += condition.SBQQ__Field__c + ' ';
                }
                
                // Describe the operator and comparison value
                conditionLogic += condition.SBQQ__Operator__c + ' ';
                
                if(condition.SBQQ__FilterType__c == 'Variable' && condition.SBQQ__FilterVariable__c != null) {
                    SBQQ__SummaryVariable__c var = summaryVarsMap.get(condition.SBQQ__FilterVariable__c);
                    conditionLogic += describeSummaryVariable(var, summaryVarsMap);
                } else if(condition.SBQQ__FilterType__c == 'Formula' && condition.SBQQ__FilterFormula__c != null) {
                    conditionLogic += 'formula (' + condition.SBQQ__FilterFormula__c + ')';
                } else {
                    conditionLogic += '"' + condition.SBQQ__Value__c + '"';
                }
                
                conditionLogic += '\n';

                if (condition.SBQQ__Index__c == null) {
                    conditionNumber++;
                }
            }
        }
        
        return conditionLogic;
    }
    
    // Helper to describe a summary variable in plain language
    private static String describeSummaryVariable(SBQQ__SummaryVariable__c var, Map<Id, SBQQ__SummaryVariable__c> summaryVarsMap) {
        if(var == null) return 'Unknown Variable';
        
        String description = '';
        
        // Describe the aggregation
        if(var.SBQQ__AggregateFunction__c != null && var.SBQQ__TargetObject__c != null && var.SBQQ__AggregateField__c != null) {
            description += var.SBQQ__AggregateFunction__c + ' of ' + 
                          var.SBQQ__TargetObject__c + '.' + var.SBQQ__AggregateField__c;
        } else {
            // Handle case where essential fields are missing
            description += 'Variable ' + (var.Name != null ? var.Name : 'with missing aggregation details');
        }
        
        // Add filter criteria if present
        if(var.SBQQ__FilterField__c != null) {
            description += ' where ' + var.SBQQ__FilterField__c + ' ' + 
                          (var.SBQQ__Operator__c != null ? var.SBQQ__Operator__c : '=') + ' ' + 
                          '"' + (var.SBQQ__FilterValue__c != null ? var.SBQQ__FilterValue__c : '') + '"';
        }
        
        // Add constraint field if present
        if(var.SBQQ__ConstraintField__c != null) {
            description += ' with constraint on ' + var.SBQQ__ConstraintField__c;
        }
        
        // Add composite information if present
        if(var.SBQQ__CompositeOperator__c != null && (var.SBQQ__ValueElement__c != null || var.SBQQ__CombineWith__c != null)) {
            description += ' ' + var.SBQQ__CompositeOperator__c + ' ';
            
            // Check if it's combining with another variable
            if(var.SBQQ__CombineWith__c != null && summaryVarsMap != null && summaryVarsMap.containsKey(var.SBQQ__CombineWith__c)) {
                description += describeSummaryVariable(summaryVarsMap.get(var.SBQQ__CombineWith__c), summaryVarsMap);
            } else if(var.SBQQ__ValueElement__c != null) {
                description += 'value element "' + var.SBQQ__ValueElement__c + '"';
            } else {
                description += 'unknown value';
            }
        }
        
        return description;
    }
    
    // Process actions into human-readable format
    private static String processActions(SBQQ__PriceRule__c rule, Map<Id, SBQQ__SummaryVariable__c> summaryVarsMap) {
        String actionsText = '';
        
        if(rule.getSObjects('SBQQ__PriceActions__r') == null || rule.getSObjects('SBQQ__PriceActions__r').isEmpty()) {
            return 'No actions defined for this rule.';
        }
        
        actionsText = 'When triggered, this rule will perform the following actions:\n\n';
        
        Integer actionNumber = 1;
        for(SBQQ__PriceAction__c action : rule.getSObjects('SBQQ__PriceActions__r')) {
            actionsText += actionNumber + '. ';
            
            // Describe the target object if specified
            if(action.SBQQ__TargetObject__c != null) {
                actionsText += 'Set ' + action.SBQQ__TargetObject__c + '.' + action.SBQQ__Field__c + ' to ';
            } else {
                actionsText += 'Set ' + action.SBQQ__Field__c + ' to ';
            }
            
            // Describe the value source
            if(action.SBQQ__SourceVariable__c != null) {
                actionsText += 'the ' + describeSummaryVariable(summaryVarsMap.get(action.SBQQ__SourceVariable__c), summaryVarsMap);
            } else if(action.SBQQ__SourceLookupField__c != null) {
                actionsText += 'lookup field ' + action.SBQQ__SourceLookupField__c;
            } else if(action.SBQQ__ValueField__c != null) {
                actionsText += 'field ' + action.SBQQ__ValueField__c;
            } else {
                actionsText += '"' + action.SBQQ__Value__c + '"';
            }
            
            actionsText += '\n';
            actionNumber++;
        }
        
        return actionsText;
    }
    
    // Process lookup queries into human-readable format
    private static String processLookupQueries(List<SBQQ__LookupQuery__c> lookupQueries) {
        if(lookupQueries == null || lookupQueries.isEmpty()) {
            return 'No lookup queries defined for this rule.';
        }
        
        String queriesText = '';
        
        // Show simplified field descriptions for lookup queries
        List<String> fieldDescriptions = new List<String>();
        for(SBQQ__LookupQuery__c query : lookupQueries) {
            if(query.SBQQ__MatchType__c == 'Field Value') {
                fieldDescriptions.add('Lookup Data records where ' + query.SBQQ__LookupField__c + 
                                     ' ' + query.SBQQ__Operator__c + ' ' + 
                                     query.SBQQ__TestedObject__c + '.' + query.SBQQ__TestedField__c);
            } else if(query.SBQQ__MatchType__c == 'Static Value') {
                fieldDescriptions.add('Lookup Data records where ' + query.SBQQ__LookupField__c + 
                                     ' ' + query.SBQQ__Operator__c + ' "' + 
                                     query.SBQQ__TestedValue__c + '"');
            } else if(query.SBQQ__MatchType__c == 'Configuration Attribute Value' && 
                      query.SBQQ__TestedConfigurationAttribute__c != null) {
                fieldDescriptions.add('Lookup Data records where ' + query.SBQQ__LookupField__c + 
                                     ' ' + query.SBQQ__Operator__c + ' Configuration Attribute "' + 
                                     query.SBQQ__TestedConfigurationAttribute__r.Name + '"');
            }
        }
        
        queriesText = String.join(fieldDescriptions, ' AND ');
        
        return queriesText;
    }
    
    // Get sample lookup data for documentation purposes
    private static String getSampleLookupData(List<SBQQ__LookupQuery__c> lookupQueries) {
        try {
            // First, determine the lookup object from the price rule
            Id priceRuleId = null;
            
            if(!lookupQueries.isEmpty()) {
                if(lookupQueries[0].SBQQ__PriceRule2__c != null) {
                    priceRuleId = lookupQueries[0].SBQQ__PriceRule2__c;
                }
            }
            
            String lookupObjectName = 'SBQQ__LookupData__c'; // Default
            
            // Query for the actual lookup object name from the parent rule
            if(priceRuleId != null) {
                List<SBQQ__PriceRule__c> rules = [
                    SELECT Id, SBQQ__LookupObject__c 
                    FROM SBQQ__PriceRule__c 
                    WHERE Id = :priceRuleId
                ];
                if(!rules.isEmpty() && rules[0].SBQQ__LookupObject__c != null) {
                    lookupObjectName = rules[0].SBQQ__LookupObject__c;
                }
            }
            
            // Extract lookup fields from queries to build dynamic filtering
            Set<String> lookupFieldNames = new Set<String>();
            
            for(SBQQ__LookupQuery__c query : lookupQueries) {
                // Get the lookup field - this is the field on the lookup object
                if(query.SBQQ__LookupField__c != null) {
                    lookupFieldNames.add(query.SBQQ__LookupField__c);
                }
            }
            
            // If no lookup fields found, early return
            if(lookupFieldNames.isEmpty()) {
                return 'No relevant lookup data field names found in the specified lookup queries.';
            }
            
            // Get the object type and field map for later use
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(lookupObjectName);
            if(objectType == null) {
                return 'Object ' + lookupObjectName + ' not found in schema.';
            }
            
            Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
            
            // Build a dynamic query based on the lookup object
            String queryStr = 'SELECT Id';
            
            // Track fields already added to avoid duplicates
            Set<String> fieldsInQuery = new Set<String>{'Id'};
            
            // Add all lookup fields to the query, but only if they exist on the object
            for(String fieldName : lookupFieldNames) {
                if(!fieldsInQuery.contains(fieldName) && fieldMap.containsKey(fieldName)) {
                    queryStr += ', ' + fieldName;
                    fieldsInQuery.add(fieldName);
                }
            }
            
            // Add common fields if they exist and haven't been added yet
            List<String> potentialFields = new List<String>{
                'Name', 'SBQQ__Category__c', 'SBQQ__Type__c', 'SBQQ__Value__c', 
                'SBQQ__Message__c', 'SBQQ__Required__c'
            };
            
            for(String field : potentialFields) {
                if(fieldMap.containsKey(field) && !fieldsInQuery.contains(field)) {
                    queryStr += ', ' + field;
                    fieldsInQuery.add(field);
                }
            }
            
            // If this object has the Product relationship field, include it
            if(fieldMap.containsKey('SBQQ__Product__c') && !fieldsInQuery.contains('SBQQ__Product__c')) {
                queryStr += ', SBQQ__Product__r.Name, SBQQ__Product__r.ProductCode';
                fieldsInQuery.add('SBQQ__Product__c');
            }
            
            queryStr += ' FROM ' + lookupObjectName + ' WHERE ';
            
            // Build WHERE clause to find records with ALL lookup fields populated (AND condition)
            // Only include fields that actually exist on the object
            List<String> whereConditions = new List<String>();
            
            for(String fieldName : lookupFieldNames) {
                if(fieldMap.containsKey(fieldName)) {
                    whereConditions.add(fieldName + ' != null');
                }
            }
            
            if(whereConditions.isEmpty()) {
                return 'No valid lookup fields found for ' + lookupObjectName + '.';
            }
            
            // Join the conditions with AND instead of OR for an AND relationship
            queryStr += String.join(whereConditions, ' AND ');
            //queryStr += ' LIMIT 50'; // Add a reasonable limit
            
            try {
                System.debug('Executing dynamic query: ' + queryStr);
                // Execute the dynamic query
                List<SObject> lookupDataList = Database.query(queryStr);
                
                if(lookupDataList.isEmpty()) {
                    return 'No matching records found in ' + lookupObjectName + '.';
                }
                
                String dataText = '';
                
                Integer sampleNumber = 1;
                for(SObject data : lookupDataList) {
                    dataText += sampleNumber + '. ';
                    
                    // Add all requested lookup fields first, but only if they exist
                    List<String> fieldValues = new List<String>();
                    for(String fieldName : lookupFieldNames) {
                        // Only try to access fields that exist on the object
                        if(fieldMap.containsKey(fieldName)) {
                            Object fieldValue = data.get(fieldName);
                            if(fieldValue != null) {
                                fieldValues.add(fieldName + ': ' + fieldValue);
                            }
                        }
                    }
                    
                    // Add Type if it exists on this object and has a value
                    if(fieldMap.containsKey('SBQQ__Type__c') && data.get('SBQQ__Type__c') != null) {
                        fieldValues.add('Type: ' + data.get('SBQQ__Type__c'));
                    }
                    
                    // Add Product Code instead of Name if available
                    if(fieldMap.containsKey('SBQQ__Product__c') && data.get('SBQQ__Product__c') != null) {
                        // For relationship fields, we need to use getSObject
                        SObject product = data.getSObject('SBQQ__Product__r');
                        if(product != null && product.get('ProductCode') != null) {
                            fieldValues.add('Product Code: ' + product.get('ProductCode'));
                        }
                    }
                    
                    // Add Required if it exists on this object and has a value
                    if(fieldMap.containsKey('SBQQ__Required__c') && data.get('SBQQ__Required__c') != null) {
                        fieldValues.add('Required: ' + data.get('SBQQ__Required__c'));
                    }
                    
                    dataText += String.join(fieldValues, '; ') + '\n';
                    sampleNumber++;
                }
                
                return dataText;
            } catch(QueryException qe) {
                return 'Error querying ' + lookupObjectName + ': ' + qe.getMessage();
            }
        } catch(Exception e) {
            return 'Unable to retrieve lookup data: ' + e.getMessage() + ' (Line: ' + e.getLineNumber() + ')';
        }
    }
    
    // Wrapper class to hold rule documentation
    public class RuleDocumentation {
        public String ruleName { get; set; }
        public Id ruleId { get; set; }
        public String evaluationScope { get; set; }
        public String evaluationEvent { get; set; }
        public Decimal evaluationOrder { get; set; }
        public String conditionsMet { get; set; }
        public String productName { get; set; }
        public String advancedCondition { get; set; }
        public String conditionLogic { get; set; }
        public String actions { get; set; }
        public String lookupObject { get; set; }
        public String lookupQueries { get; set; }
        public String lookupData { get; set; }
        
        // Generate a complete human-readable description
        public String getCompleteDescription() {
            String description = '';
            
            description += '=== PRICE RULE: ' + ruleName + ' ===\n\n';
            description += 'Evaluation Scope: ' + evaluationScope + '\n';
            description += 'Evaluation Event: ' + evaluationEvent + '\n';
            description += 'Evaluation Order: ' + evaluationOrder + '\n';
            description += 'Conditions Met: ' + conditionsMet + '\n';
            
            if(String.isNotBlank(productName)) {
                description += 'Product: ' + productName + '\n';
            }
            
            if(String.isNotBlank(advancedCondition)) {
                description += 'Advanced Condition Logic: ' + advancedCondition + '\n';
            }
            
            if(String.isNotBlank(lookupObject)) {
                description += 'Lookup Object: ' + lookupObject + '\n';
            }
            
            description += '\n--- CONDITIONS ---\n';
            description += conditionLogic + '\n';
            
            description += '--- ACTIONS ---\n';
            description += actions + '\n';
            
            // Add lookup query information if available
            if(String.isNotBlank(lookupQueries) && lookupQueries != 'No lookup queries defined for this rule.') {
                description += '--- LOOKUP QUERIES ---\n';
                description += lookupQueries + '\n';
            }
            
            // Add lookup data information if available
            if(String.isNotBlank(lookupData) && lookupData != 'No sample lookup data available.') {
                description += '--- LOOKUP DATA SAMPLES ---\n';
                description += lookupData + '\n';
            }
            
            return description;
        }
    }

    // Method to export price rule documentation to a ContentVersion file
    public static Id exportToContentFile() {
        try {
            // Generate the data
            List<Map<String, String>> exportData = prepareExcelExport();
            
            // Convert to CSV content
            String csvContent = createCSVContent(exportData);
            
            // Create a ContentVersion record (Salesforce File)
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Price Rule Documentation ' + DateTime.now().format('yyyy-MM-dd');
            cv.PathOnClient = 'PriceRuleDocumentation.csv';
            cv.VersionData = Blob.valueOf('\uFEFF' + csvContent); // Add BOM for UTF-8
            cv.IsMajorVersion = true;
            
            insert cv;
            
            return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        } catch(Exception e) {
            System.debug('Error exporting price rule documentation: ' + e.getMessage());
            throw e;
        }
    }

    // Prepare data with the updated column order and ConditionsMet field
    public static List<Map<String, String>> prepareExcelExport() {
        List<RuleDocumentation> docs = generateAllRuleDocumentation();
        List<Map<String, String>> exportRows = new List<Map<String, String>>();
        
        for(RuleDocumentation doc : docs) {
            Map<String, String> row = new Map<String, String>{
                'Rule ID' => doc.ruleId,
                'Rule Name' => doc.ruleName,
                'Evaluation Scope' => doc.evaluationScope,
                'Evaluation Event' => doc.evaluationEvent,
                'Evaluation Order' => String.valueOf(doc.evaluationOrder),
                'Conditions Met' => doc.conditionsMet,
                'Product' => doc.productName != null ? doc.productName : '',
                'Advanced Condition Logic' => doc.advancedCondition != null ? doc.advancedCondition : '',
                'Lookup Object' => doc.lookupObject != null ? doc.lookupObject : '',
                'Conditions' => formatConditionsForExcel(doc.conditionLogic),
                'Actions' => formatActionsForExcel(doc.actions),
                'Lookup Queries' => formatLookupQueriesForExcel(doc.lookupQueries),
                'Lookup Data' => formatLookupDataForExcel(doc.lookupData)
            };
            exportRows.add(row);
        }
        
        return exportRows;
    }

    // Format conditions in a structured way for Excel, preserving numbers and newlines
    private static String formatConditionsForExcel(String conditionsText) {
        if(conditionsText == null) return '';
        
        // Remove the initial explanatory text if present
        String formattedText = conditionsText;
        if(formattedText.contains('This rule will trigger when')) {
            formattedText = formattedText.substringAfter(':\n\n');
        }
        
        // Split by lines and format each condition, but keep numbers
        List<String> lines = formattedText.split('\n');
        List<String> formattedLines = new List<String>();
        
        for(String line : lines) {
            if(String.isBlank(line)) continue;
            
            // Trim the line but preserve the leading number
            String cleanLine = line.trim();
            if(String.isNotBlank(cleanLine)) {
                formattedLines.add(cleanLine);
            }
        }
        
        return String.join(formattedLines, '\n');
    }

    // Format actions in a structured way for Excel
    private static String formatActionsForExcel(String actionsText) {
        if(actionsText == null) return '';
        
        // Remove the initial explanatory text if present
        String formattedText = actionsText;
        if(formattedText.contains('When triggered, this rule will perform')) {
            formattedText = formattedText.substringAfter(':\n\n');
        } else if(formattedText.contains('No actions defined')) {
            return 'No actions defined';
        }
        
        // Split by lines and format each action
        List<String> lines = formattedText.split('\n');
        List<String> formattedLines = new List<String>();
        
        for(String line : lines) {
            if(String.isBlank(line)) continue;
            
            // Remove any leading numbers (e.g., "1. ") and trim
            String cleanLine = line.replaceFirst('^\\d+\\.\\s+', '').trim();
            if(String.isNotBlank(cleanLine)) {
                // Ensure proper formatting for Excel cell
                formattedLines.add(cleanLine.replace('\n', ' '));
            }
        }
        
        return String.join(formattedLines, '\n');
    }
    
    // Format lookup queries for Excel export
    private static String formatLookupQueriesForExcel(String queriesText) {
        if(queriesText == null) return '';
        
        if(queriesText.contains('No lookup queries defined')) {
            return 'No lookup queries defined';
        }
        
        // Already formatted cleanly, just return as is
        return queriesText;
    }
    
    // Format lookup data for Excel export
    private static String formatLookupDataForExcel(String dataText) {
        if(dataText == null) return '';
        
        if(dataText.contains('No matching records found') || 
           dataText.contains('No relevant lookup data field names found')) {
            return 'No lookup data available';
        }
        
        // Already formatted cleanly, just return as is
        return dataText;
    }

    // Create CSV content respecting the specific column order
    private static String createCSVContent(List<Map<String, String>> exportData) {
        if(exportData.isEmpty()) return '';
        
        // Specify the exact column order we want, including new columns
        List<String> orderedHeaders = new List<String>{
            'Rule ID',
            'Rule Name',
            'Evaluation Scope',
            'Evaluation Event',
            'Evaluation Order',
            'Conditions Met',
            'Product',
            'Advanced Condition Logic',
            'Lookup Object',
            'Conditions',
            'Actions',
            'Lookup Queries',
            'Lookup Data'
        };
        
        // Start with headers in our specified order
        String csvContent = String.join(orderedHeaders, ',') + '\n';
        
        // Add each row in the same order
        for(Map<String, String> row : exportData) {
            List<String> rowValues = new List<String>();
            for(String header : orderedHeaders) {
                // Get the value, defaulting to empty string
                String value = row.get(header) != null ? row.get(header) : '';
                
                // Properly escape for CSV - preserve newlines by quoting
                value = '"' + value.replace('"', '""') + '"';
                
                rowValues.add(value);
            }
            csvContent += String.join(rowValues, ',') + '\n';
        }
        
        return csvContent;
    }

    // Export to Excel file to preserve formatting
    public static Id exportToExcelFile() {
        try {
            // Generate the data
            List<Map<String, String>> exportData = prepareExcelExport();
            
            // Create Excel-compatible content
            String csvContent = createExcelCSVContent(exportData);
            
            // Create a ContentVersion record (Salesforce File)
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Price Rule Documentation ' + DateTime.now().format('yyyy-MM-dd');
            cv.PathOnClient = 'PriceRuleDocumentation.csv';
            // Add UTF-8 BOM to help Excel recognize the file encoding
            Blob bom = Blob.valueOf('\uFEFF');
            Blob contentBlob = Blob.valueOf(csvContent);
            cv.VersionData = Blob.valueOf(bom.toString() + csvContent);
            cv.IsMajorVersion = true;
            
            insert cv;
            
            // Get the ContentDocumentId for later use if needed
            ContentVersion insertedCv = [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :cv.Id 
                LIMIT 1
            ];
            
            return insertedCv.ContentDocumentId;
        } catch(Exception e) {
            System.debug('Error exporting price rule documentation: ' + e.getMessage());
            throw e;
        }
    }

    // Create Excel-compatible content
    private static String createExcelCSVContent(List<Map<String, String>> exportData) {
        if(exportData.isEmpty()) return '';
        
        // Specify the exact column order we want, including new columns
        List<String> orderedHeaders = new List<String>{
            'Rule ID',
            'Rule Name',
            'Evaluation Scope',
            'Evaluation Event',
            'Evaluation Order',
            'Conditions Met',
            'Product',
            'Advanced Condition Logic',
            'Lookup Object',
            'Conditions',
            'Actions',
            'Lookup Queries',
            'Lookup Data'
        };
        
        // Start with headers in our specified order
        String csvContent = String.join(orderedHeaders, ',') + '\n';
        
        // Add each row in the same order
        for(Map<String, String> row : exportData) {
            List<String> rowValues = new List<String>();
            for(String header : orderedHeaders) {
                // Get the value, defaulting to empty string
                String value = row.get(header) != null ? row.get(header) : '';
                
                // Escape quotes and wrap in quotes to preserve newlines
                value = '"' + value.replace('"', '""') + '"';
                rowValues.add(value);
            }
            csvContent += String.join(rowValues, ',') + '\n';
        }
        
        return csvContent;
    }

    // Export to HTML file for best formatting preservation
    public static Id exportToHTMLFile() {
        try {
            // Generate the data
            List<Map<String, String>> exportData = prepareExcelExport();
            
            // Define column headers in desired order, including new columns
            List<String> orderedHeaders = new List<String>{
                'Rule ID',
                'Rule Name',
                'Evaluation Scope',
                'Evaluation Event',
                'Evaluation Order',
                'Conditions Met',
                'Product',
                'Advanced Condition Logic',
                'Lookup Object',
                'Conditions',
                'Actions',
                'Lookup Queries',
                'Lookup Data'
            };
            
            // Use StringBuilder for better performance with large strings
            List<String> htmlParts = new List<String>();
            
            // HTML opening tags
            htmlParts.add('<html><body>');
            htmlParts.add('<style>');
            htmlParts.add('table { border-collapse: collapse; width: 100%; }');
            htmlParts.add('th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
            htmlParts.add('th { background-color: #f2f2f2; }');
            htmlParts.add('tr:nth-child(even) { background-color: #f9f9f9; }');
            htmlParts.add('</style>');
            htmlParts.add('<table>');
            
            // Table header row
            htmlParts.add('<tr>');
            for(String header : orderedHeaders) {
                htmlParts.add('<th>' + escapeHtml(header) + '</th>');
            }
            htmlParts.add('</tr>');
            
            // Table data rows
            for(Map<String, String> row : exportData) {
                htmlParts.add('<tr>');
                for(String header : orderedHeaders) {
                    String value = row.get(header) != null ? row.get(header) : '';
                    // Replace newlines with HTML line breaks
                    value = value.replace('\n', '<br/>');
                    htmlParts.add('<td>' + escapeHtml(value) + '</td>');
                }
                htmlParts.add('</tr>');
            }
            
            // Close table and HTML
            htmlParts.add('</table>');
            htmlParts.add('</body></html>');
            
            // Join all HTML parts
            String htmlContent = String.join(htmlParts, '');
            
            // Create a ContentVersion record
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Price Rule Documentation ' + DateTime.now().format('yyyy-MM-dd');
            cv.PathOnClient = 'PriceRuleDocumentation.html';
            cv.VersionData = Blob.valueOf(htmlContent);
            cv.IsMajorVersion = true;
            
            insert cv;
            
            return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        } catch(Exception e) {
            System.debug('Error exporting price rule documentation to HTML: ' + e.getMessage());
            throw e;
        }
    }

    // Helper method to escape HTML special characters
    private static String escapeHtml(String input) {
        if(input == null) return '';
        
        // Replace special characters with HTML entities
        String escaped = input
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&#39;');
            
        return escaped;
    }
}