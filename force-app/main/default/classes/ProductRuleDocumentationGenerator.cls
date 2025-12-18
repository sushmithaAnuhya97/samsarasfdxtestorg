public class ProductRuleDocumentationGenerator {
    
    // Main method to generate documentation for all active rules
    public static List<RuleDocumentation> generateAllRuleDocumentation() {
        List<RuleDocumentation> documentationList = new List<RuleDocumentation>();
        
        // Query all active product rules with related records
        List<SBQQ__ProductRule__c> rules = [
            SELECT Id, Name, SBQQ__Active__c, SBQQ__AdvancedCondition__c, SBQQ__ConditionsMet__c, SBQQ__ErrorMessage__c, 
                    SBQQ__EvaluationEvent__c, SBQQ__EvaluationOrder__c, SBQQ__LookupMessageField__c, SBQQ__LookupObject__c, 
                    SBQQ__LookupProductField__c, SBQQ__LookupRequiredField__c, SBQQ__LookupTypeField__c, SBQQ__Scope__c, SBQQ__Type__c, PPP_Description__c,
                   (SELECT Id, Name, SBQQ__Rule__c, SBQQ__FilterType__c, SBQQ__FilterValue__c, SBQQ__FilterVariable__c, SBQQ__Index__c, SBQQ__Operator__c, 
                            SBQQ__ParentRuleIsActive__c, SBQQ__RuleTargetsQuote__c, SBQQ__TestedAttribute__c, SBQQ__TestedField__c, SBQQ__TestedObject__c, SBQQ__TestedVariable__c,
                            SBQQ__TestedVariable__r.SBQQ__CombineWith__c, SBQQ__FilterVariable__r.SBQQ__CombineWith__c
                    FROM SBQQ__ErrorConditions__r ORDER BY SBQQ__Index__c),
                   (SELECT Id, Name, SBQQ__Rule__c, SBQQ__FilterField__c, SBQQ__FilterValue__c, SBQQ__Operator__c, SBQQ__ParentRuleIsActive__c, SBQQ__Product__c, 
                            SBQQ__Required__c, SBQQ__Type__c, SBQQ__ValueAttribute__c, SBQQ__ValueField__c, SBQQ__ValueObject__c , SBQQ__Product__r.Name
                    FROM SBQQ__Actions__r),
                   (SELECT Id, Name, SBQQ__ProductRule__c, SBQQ__Active__c, SBQQ__AscendingNestedLevel__c, SBQQ__DescendingActionNesting__c, 
                            SBQQ__DescendingNestedLevel__c, SBQQ__ProductFeature__c, SBQQ__Product__c, SBQQ__RuleEvaluationEvent__c, SBQQ__RuleType__c,
                            SBQQ__Product__r.Name, SBQQ__ProductFeature__r.Name
                    FROM SBQQ__ConfigurationRules__r)
            FROM SBQQ__ProductRule__c
            WHERE SBQQ__Active__c = true
            ORDER BY SBQQ__EvaluationOrder__c NULLS LAST
        ];
        
        // Query all lookup queries related to product rules
        Map<Id, List<SBQQ__LookupQuery__c>> lookupQueriesMap = new Map<Id, List<SBQQ__LookupQuery__c>>();
        List<SBQQ__LookupQuery__c> lookupQueries = [
            SELECT Id, Name, SBQQ__LookupField__c, SBQQ__MatchType__c, SBQQ__Operator__c, 
                   SBQQ__TestedField__c, SBQQ__TestedObject__c, SBQQ__TestedValue__c,
                   SBQQ__TestedConfigurationAttribute__c, SBQQ__TestedConfigurationAttribute__r.Name,
                   SBQQ__ProductRule__c
            FROM SBQQ__LookupQuery__c
            WHERE SBQQ__ProductRule__c IN :rules
        ];
        
        for(SBQQ__LookupQuery__c query : lookupQueries) {
            if(!lookupQueriesMap.containsKey(query.SBQQ__ProductRule__c)) {
                lookupQueriesMap.put(query.SBQQ__ProductRule__c, new List<SBQQ__LookupQuery__c>());
            }
            lookupQueriesMap.get(query.SBQQ__ProductRule__c).add(query);
        }
        
        // Collect all summary variable IDs before processing rules
        Set<Id> allSummaryVarIds = new Set<Id>();
        for(SBQQ__ProductRule__c rule : rules) {
            for(SBQQ__ErrorCondition__c condition : rule.SBQQ__ErrorConditions__r) {
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
        }
        
        // Query all summary variables at once
        Map<Id, SBQQ__SummaryVariable__c> summaryVarsMap = new Map<Id, SBQQ__SummaryVariable__c>();
        if(!allSummaryVarIds.isEmpty()) {
            summaryVarsMap = new Map<Id, SBQQ__SummaryVariable__c>([
                SELECT Id, Name, SBQQ__AggregateField__c, SBQQ__AggregateFunction__c, SBQQ__CombineWith__c, SBQQ__CompositeOperator__c, SBQQ__ConstraintField__c, 
                        SBQQ__FilterField__c, SBQQ__FilterValue__c, SBQQ__Operator__c, SBQQ__Scope__c, SBQQ__TargetObject__c, SBQQ__ValueElement__c
                FROM SBQQ__SummaryVariable__c
                WHERE Id IN :allSummaryVarIds
            ]);
        }
        
        // Process each rule with the pre-fetched summary variables and lookup queries
        for(SBQQ__ProductRule__c rule : rules) {
            RuleDocumentation doc = generateRuleDocumentation(rule, summaryVarsMap, lookupQueriesMap.get(rule.Id));
            documentationList.add(doc);
        }
        
        return documentationList;
    }
    
    // Generate documentation for a single rule
    private static RuleDocumentation generateRuleDocumentation(SBQQ__ProductRule__c rule, 
                                                              Map<Id, SBQQ__SummaryVariable__c> summaryVarsMap,
                                                              List<SBQQ__LookupQuery__c> lookupQueries) {
        RuleDocumentation doc = new RuleDocumentation();
        doc.ruleName = rule.Name;
        doc.ruleId = rule.Id;
        doc.ruleType = rule.SBQQ__Type__c;
        doc.scope = rule.SBQQ__Scope__c;
        doc.evaluationEvent = rule.SBQQ__EvaluationEvent__c;
        doc.evaluationOrder = rule.SBQQ__EvaluationOrder__c;
        doc.errorMessage = rule.SBQQ__ErrorMessage__c;
        doc.lookupObject = rule.SBQQ__LookupObject__c;
        
        // Add lookup fields if specified
        if(rule.SBQQ__LookupMessageField__c != null || rule.SBQQ__LookupProductField__c != null || 
           rule.SBQQ__LookupRequiredField__c != null || rule.SBQQ__LookupTypeField__c != null) {
            doc.lookupFields = describeLookupFields(rule);
        }
        
        // Process conditions
        doc.conditionLogic = processConditionLogic(rule, summaryVarsMap);
        
        // Process actions
        doc.actions = processActions(rule);
        
        // Process configuration rules
        doc.configurationRules = processConfigRules(rule);
        
        // Process lookup queries
        if(lookupQueries != null && !lookupQueries.isEmpty()) {
            doc.lookupQueries = processLookupQueries(lookupQueries);
            
            // If we have lookup data object specified, get sample data
            if(rule.SBQQ__LookupObject__c == 'SBQQ__LookupData__c') {
                doc.lookupData = getSampleLookupData(lookupQueries);
            }
        }
        
        return doc;
    }
    
    // Helper to describe lookup fields in a formatted way
    private static String describeLookupFields(SBQQ__ProductRule__c rule) {
        String fieldsDescription = '';
        
        if(rule.SBQQ__LookupMessageField__c != null) {
            fieldsDescription += 'Message Field: ' + rule.SBQQ__LookupMessageField__c + '\n';
        }
        
        if(rule.SBQQ__LookupProductField__c != null) {
            fieldsDescription += 'Product Field: ' + rule.SBQQ__LookupProductField__c + '\n';
        }
        
        if(rule.SBQQ__LookupRequiredField__c != null) {
            fieldsDescription += 'Required Field: ' + rule.SBQQ__LookupRequiredField__c + '\n';
        }
        
        if(rule.SBQQ__LookupTypeField__c != null) {
            fieldsDescription += 'Type Field: ' + rule.SBQQ__LookupTypeField__c;
        }
        
        return fieldsDescription;
    }
    
    // Process condition logic including summary variables
    private static String processConditionLogic(SBQQ__ProductRule__c rule, Map<Id, SBQQ__SummaryVariable__c> summaryVarsMap) {
        String conditionLogic = '';
        
        // Build condition logic description
        String conditionsMetText = rule.SBQQ__ConditionsMet__c == 'All' ? 'ALL of the following conditions are met' : 
                                  (rule.SBQQ__ConditionsMet__c == 'Any' ? 'ANY of the following conditions are met' : 
                                  'Custom logic is applied: ' + rule.SBQQ__AdvancedCondition__c);
        
        conditionLogic = 'This rule will trigger when ' + conditionsMetText + ':\n\n';
        
        for(SBQQ__ErrorCondition__c condition : rule.SBQQ__ErrorConditions__r) {

            if ((conditionsMetText.contains('Custom logic is applied') && rule.SBQQ__AdvancedCondition__c.contains(string.valueOf(condition.SBQQ__Index__c))) ||
                    rule.SBQQ__ConditionsMet__c == 'All') {
                
                Integer conditionNumber = 1;
        
                if (condition.SBQQ__Index__c != null) {
                    conditionNumber = Integer.valueOf(condition.SBQQ__Index__c);
                }

                conditionLogic += conditionNumber + '. ';
                
                // Describe the tested object and field or variable
                if(condition.SBQQ__TestedVariable__c != null) {
                    SBQQ__SummaryVariable__c var = summaryVarsMap.get(condition.SBQQ__TestedVariable__c);
                    conditionLogic += describeSummaryVariable(var, summaryVarsMap);
                } else {
                    conditionLogic += condition.SBQQ__TestedObject__c + '.' + condition.SBQQ__TestedField__c + ' ';
                }
                
                // Describe the operator and comparison value
                conditionLogic += ' ' + condition.SBQQ__Operator__c + ' ';
                
                if(condition.SBQQ__FilterType__c == 'Variable' && condition.SBQQ__FilterVariable__c != null) {
                    SBQQ__SummaryVariable__c var = summaryVarsMap.get(condition.SBQQ__FilterVariable__c);
                    conditionLogic += describeSummaryVariable(var, summaryVarsMap);
                } else {
                    conditionLogic += '"' + condition.SBQQ__FilterValue__c + '"';
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
        String description = '';
        
        // Return a default message if var is null
        if(var == null) {
            return 'Unknown Variable';
        }
        
        // Basic description with variable name
        // description += var.Name + ': ';
        
        // Describe the aggregation
        if(var.SBQQ__AggregateFunction__c != null && var.SBQQ__TargetObject__c != null && var.SBQQ__AggregateField__c != null) {
            description += var.SBQQ__AggregateFunction__c + ' of ' + 
                          var.SBQQ__TargetObject__c + '.' + var.SBQQ__AggregateField__c;
        } else {
            // Handle case where essential fields are missing
            description += 'Variable ' + (var.Name != null ? var.Name : 'with missing aggregation details');
        }
        
        // Add scope information
        if(var.SBQQ__Scope__c != null) {
            // description += ' (Scope: ' + var.SBQQ__Scope__c + ')';
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
    private static String processActions(SBQQ__ProductRule__c rule) {
        String actionsText = '';
        
        if(rule.getSObjects('SBQQ__Actions__r') == null || rule.getSObjects('SBQQ__Actions__r').isEmpty()) {
            return 'No actions defined for this rule.';
        }
        
        actionsText = 'When triggered, this rule will perform the following actions:\n\n';
        
        Integer actionNumber = 1;
        for(SBQQ__ProductAction__c action : rule.getSObjects('SBQQ__Actions__r')) {
            actionsText += actionNumber + '. ';
            
            // Describe the action type
            actionsText += describeActionType(action.SBQQ__Type__c) + ' ';
            
            // Describe the product if specified
            if(action.SBQQ__Product__c != null) {
                actionsText += 'product "' + action.SBQQ__Product__r.Name + '"';
            } else {
                actionsText += 'products that match criteria: ';
                
                if(action.SBQQ__ValueObject__c != null && action.SBQQ__ValueField__c != null) {
                    actionsText += action.SBQQ__ValueObject__c + '.' + action.SBQQ__ValueField__c;
                    
                    if(action.SBQQ__FilterValue__c != null) {
                        actionsText += ' = "' + action.SBQQ__FilterValue__c + '"';
                    }
                } else if (action.SBQQ__FilterField__c != null && action.SBQQ__FilterValue__c != null) {
                    actionsText += action.SBQQ__FilterField__c + ' ' + action.SBQQ__Operator__c + ' "' + action.SBQQ__FilterValue__c + '"';
                }
            }
            
            actionsText += '\n';
            actionNumber++;
        }
        
        return actionsText;
    }
    
    // Helper to describe action type in plain language
    private static String describeActionType(String actionType) {
        Map<String, String> actionDescriptions = new Map<String, String>{
            'Add' => 'Add',
            'Remove' => 'Remove',
            'Enable' => 'Enable',
            'Disable' => 'Disable',
            'Enable & Add' => 'Enable and add',
            'Disable & Remove' => 'Disable and remove',
            'Show' => 'Show',
            'Hide' => 'Hide',
            'Show & Add' => 'Show and add',
            'Hide & Remove' => 'Hide and remove',
            'Default Filter' => 'Set as default filter',
            'Optional Filter' => 'Set as optional filter'
        };
        
        return actionDescriptions.containsKey(actionType) ? 
               actionDescriptions.get(actionType) : actionType;
    }
    
    // Process configuration rules
    private static String processConfigRules(SBQQ__ProductRule__c rule) {
        String configRulesText = '';
        
        if(rule.getSObjects('SBQQ__ConfigurationRules__r') == null || rule.getSObjects('SBQQ__ConfigurationRules__r').isEmpty()) {
            return 'This rule is not linked to any specific product configurations.';
        }
        
        configRulesText = 'This rule applies to the following product configurations:\n\n';
        
        Integer configNumber = 1;
        for(SBQQ__ConfigurationRule__c config : rule.getSObjects('SBQQ__ConfigurationRules__r')) {
            configRulesText += configNumber + '. ';
            
            if(config.SBQQ__Product__c != null) {
                configRulesText += 'Product: "' + config.SBQQ__Product__r.Name + '"';
            }
            
            if(config.SBQQ__ProductFeature__c != null) {
                configRulesText += ' Feature: "' + config.SBQQ__ProductFeature__r.Name + '"';
            }
            
            if(!config.SBQQ__Active__c) {
                configRulesText += ' (Inactive)';
            }
            
            configRulesText += '\n';
            configNumber++;
        }
        
        return configRulesText;
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
            // First, determine the lookup object from the product rule
            // We need to get the parent rule since lookupQueries only has the relationship field
            Id productRuleId = null;
            Id priceRuleId = null;
            
            if(!lookupQueries.isEmpty()) {
                if(lookupQueries[0].SBQQ__ProductRule__c != null) {
                    productRuleId = lookupQueries[0].SBQQ__ProductRule__c;
                } else if(lookupQueries[0].SBQQ__PriceRule2__c != null) {
                    priceRuleId = lookupQueries[0].SBQQ__PriceRule2__c;
                }
            }
            
            String lookupObjectName = 'SBQQ__LookupData__c'; // Default
            
            // Query for the actual lookup object name from the parent rule
            if(productRuleId != null) {
                List<SBQQ__ProductRule__c> rules = [
                    SELECT Id, SBQQ__LookupObject__c 
                    FROM SBQQ__ProductRule__c 
                    WHERE Id = :productRuleId
                ];
                if(!rules.isEmpty() && rules[0].SBQQ__LookupObject__c != null) {
                    lookupObjectName = rules[0].SBQQ__LookupObject__c;
                }
            } else if(priceRuleId != null) {
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
        public String ruleType { get; set; }
        public String scope { get; set; }
        public String evaluationEvent { get; set; }
        public Decimal evaluationOrder { get; set; }
        public String errorMessage { get; set; }
        public String conditionLogic { get; set; }
        public String actions { get; set; }
        public String configurationRules { get; set; }
        public String lookupObject { get; set; }
        public String lookupFields { get; set; }
        public String lookupQueries { get; set; }
        public String lookupData { get; set; }
        
        // Generate a complete human-readable description
        public String getCompleteDescription() {
            String description = '';
            
            description += '=== PRODUCT RULE: ' + ruleName + ' ===\n\n';
            description += 'Type: ' + ruleType + '\n';
            description += 'Scope: ' + scope + '\n';
            description += 'Evaluation Event: ' + evaluationEvent + '\n';
            description += 'Evaluation Order: ' + evaluationOrder + '\n';
            
            if(String.isNotBlank(errorMessage)) {
                description += 'Error Message: "' + errorMessage + '"\n';
            }
            
            if(String.isNotBlank(lookupObject)) {
                description += 'Lookup Object: ' + lookupObject + '\n';
                
                if(String.isNotBlank(lookupFields)) {
                    description += 'Lookup Fields:\n' + lookupFields + '\n';
                }
            }
            
            description += '\n--- CONDITIONS ---\n';
            description += conditionLogic + '\n';
            
            description += '--- ACTIONS ---\n';
            description += actions + '\n';
            
            description += '--- CONFIGURATION RULES ---\n';
            description += configurationRules + '\n';
            
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

    // Prepare data for Excel export
    public static List<Map<String, String>> prepareExcelExport() {
        List<RuleDocumentation> docs = generateAllRuleDocumentation();
        List<Map<String, String>> exportRows = new List<Map<String, String>>();
        
        for(RuleDocumentation doc : docs) {
            Map<String, String> row = new Map<String, String>{
                'Rule ID' => doc.ruleId,
                'Rule Name' => doc.ruleName,
                'Rule Type' => doc.ruleType,
                'Scope' => doc.scope,
                'Evaluation Event' => doc.evaluationEvent,
                'Evaluation Order' => String.valueOf(doc.evaluationOrder),
                'Conditions Met' => doc.evaluationEvent != null ? doc.evaluationEvent.substringBefore(' of the following') : '',
                'Advanced Condition' => doc.conditionLogic != null && doc.conditionLogic.contains('Custom logic is applied') ? 
                                       doc.conditionLogic.substringBetween('Custom logic is applied: ', '\n') : '',
                'Error Message' => doc.errorMessage,
                'Lookup Object' => doc.lookupObject != null ? doc.lookupObject : '',
                'Lookup Fields' => doc.lookupFields != null ? doc.lookupFields : '',
                'Conditions' => formatConditionsForExcel(doc.conditionLogic),
                'Actions' => formatActionsForExcel(doc.actions),
                'Configuration Rules' => formatConfigRulesForExcel(doc.configurationRules),
                'Lookup Queries' => formatLookupQueriesForExcel(doc.lookupQueries),
                'Lookup Data' => formatLookupDataForExcel(doc.lookupData)
            };
            exportRows.add(row);
        }
        
        return exportRows;
    }

    // Format conditions in a structured way for Excel, preserving numbers
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
            
            // Keep the line as is
            String cleanLine = line.trim();
            if(String.isNotBlank(cleanLine)) {
                formattedLines.add(cleanLine);
            }
        }
        
        return String.join(formattedLines, '\n');
    }

    // Format configuration rules for Excel
    private static String formatConfigRulesForExcel(String configRulesText) {
        if(configRulesText == null) return '';
        
        // Remove the initial explanatory text if present
        String formattedText = configRulesText;
        if(formattedText.contains('This rule applies to')) {
            formattedText = formattedText.substringAfter(':\n\n');
        } else if(formattedText.contains('This rule is not linked')) {
            return 'No configuration rules';
        }
        
        // Split by lines and format each configuration rule
        List<String> lines = formattedText.split('\n');
        List<String> formattedLines = new List<String>();
        
        for(String line : lines) {
            if(String.isBlank(line)) continue;
            
            // Keep the line as is
            String cleanLine = line.trim();
            if(String.isNotBlank(cleanLine)) {
                formattedLines.add(cleanLine);
            }
        }
        
        return String.join(formattedLines, '\n');
    }
    
    // Format lookup fields for Excel export
    private static String formatLookupFieldsForExcel(String fieldsText) {
        if(fieldsText == null) return '';
        
        // Replace newlines with semicolons for Excel
        return fieldsText.replace('\n', '; ');
    }
    
    // Format lookup queries for Excel export
    private static String formatLookupQueriesForExcel(String queriesText) {
        if(queriesText == null) return '';
        
        // Remove the initial explanatory text if present
        String formattedText = queriesText;
        if(formattedText.contains('This rule uses the following lookup queries')) {
            formattedText = formattedText.substringAfter(':\n\n');
        } else if(formattedText.contains('No lookup queries defined')) {
            return 'No lookup queries defined';
        }
        
        // Split by lines and format each query
        List<String> lines = formattedText.split('\n\n');
        List<String> formattedLines = new List<String>();
        
        for(String line : lines) {
            if(String.isBlank(line)) continue;
            
            // Clean up any extra whitespace but preserve structure
            String cleanLine = line.replaceAll('\\s+', ' ').trim();
            if(String.isNotBlank(cleanLine)) {
                formattedLines.add(cleanLine);
            }
        }
        
        return String.join(formattedLines, '\n');
    }
    
    // Format lookup data for Excel export
    private static String formatLookupDataForExcel(String dataText) {
        if(dataText == null) return '';
        
        // Remove the initial explanatory text if present
        String formattedText = dataText;
        if(formattedText.contains('Sample lookup data that may be used by this rule')) {
            formattedText = formattedText.substringAfter(':\n\n');
        } else if(formattedText.contains('No sample lookup data available')) {
            return 'No sample data available';
        }
        
        // Remove the footer note
        if(formattedText.contains('Note: This is just a sample')) {
            formattedText = formattedText.substringBefore('Note: This is just a sample');
        }
        
        // Split by sample and format each
        List<String> samples = formattedText.split('\n\n');
        List<String> formattedSamples = new List<String>();
        
        for(String sample : samples) {
            if(String.isBlank(sample)) continue;
            
            // Clean up but maintain important structure
            String cleanSample = sample.replace('\n   ', '; ').trim();
            if(String.isNotBlank(cleanSample)) {
                formattedSamples.add(cleanSample);
            }
        }
        
        return String.join(formattedSamples, '\n');
    }

    // Export to Excel file to preserve formatting
    public static Id exportToExcelFile() {
        try {
            // Generate the data
            List<Map<String, String>> exportData = prepareExcelExport();
            
            // Create Excel-compatible CSV content
            String csvContent = createExcelContent(exportData);
            
            // Create a ContentVersion record (Salesforce File)
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Product Rule Documentation ' + DateTime.now().format('yyyy-MM-dd');
            cv.PathOnClient = 'ProductRuleDocumentation.csv'; // Using .csv extension
            cv.VersionData = Blob.valueOf('\uFEFF' + csvContent); // Add BOM for UTF-8
            cv.IsMajorVersion = true;
            
            insert cv;
            
            return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        } catch(Exception e) {
            System.debug('Error exporting product rule documentation: ' + e.getMessage());
            throw e;
        }
    }  

    // Create content for Excel export using CSV format
    private static String createExcelContent(List<Map<String, String>> exportData) {
        if(exportData.isEmpty()) return '';
        
        // Specify the exact column order we want, including lookup fields/data
        List<String> orderedHeaders = new List<String>{
            'Rule ID',
            'Rule Name',
            'Rule Type',
            'Scope',
            'Evaluation Event',
            'Evaluation Order',
            'Conditions Met',
            'Advanced Condition',
            'Error Message',
            'Lookup Object',
            'Lookup Fields',
            'Conditions',
            'Actions',
            'Configuration Rules',
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
                
                // Properly escape value for CSV format
                // Replace quotes with double quotes and wrap in quotes to preserve newlines
                value = '"' + value.replace('"', '""') + '"';
                
                // Add the escaped value
                rowValues.add(value);
            }
            csvContent += String.join(rowValues, ',') + '\n';
        }
        
        return csvContent;
    }

}