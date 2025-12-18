public class ApprovalHelper {
    private static Map<Id, List<SBAA__ApprovalCondition__c>> conditionsCache = new Map<Id, List<SBAA__ApprovalCondition__c>>();
    private static List<SBAA__ApprovalCondition__c> allConditions;
    
    public static List<Approval_Log__c> createApprovalLogs(List<SBAA__Approval__c> newApprovals) {
        if (newApprovals == null || newApprovals.isEmpty()) return new List<Approval_Log__c>();
        
        Set<Id> approvalRuleIds = getApprovalRuleIds(newApprovals);
        Set<Id> quoteIds = getQuoteIds(newApprovals);
        List<SBAA__ApprovalCondition__c> conditions = getApprovalConditions(approvalRuleIds);
        Map<Id, RuleMetadata> ruleMetadataMap = new Map<Id, RuleMetadata>();
        for(SBAA__ApprovalCondition__c condition : conditions) {
            if(!ruleMetadataMap.containsKey(condition.SBAA__ApprovalRule__c)) {
                ruleMetadataMap.put(condition.SBAA__ApprovalRule__c, new RuleMetadata());
            }
            RuleMetadata metadata = ruleMetadataMap.get(condition.SBAA__ApprovalRule__c);
            metadata.conditions.add(condition);
            
            if(condition.SBAA__TestedField__c != null) {
                metadata.addQuoteField(condition.SBAA__TestedField__c);
            }
            if(condition.SBAA__TestedVariable__c != null) {
                metadata.addQuoteLineField(
                    condition.SBAA__TestedVariable__r.sbaa__FilterField__c,
                    condition.SBAA__TestedVariable__r.sbaa__Operator__c,
                    condition.SBAA__TestedVariable__r.sbaa__FilterValue__c
                );
            }
        }
        
        Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteId = getQuoteLinesForAllQuotes(quoteIds, ruleMetadataMap.values());
        Map<String, List<Approval_Log__c>> existingLogsMap = getLatestApprovalLogs(quoteIds);
        Map<Id, SBQQ__Quote__c> quoteMap = getQuoteRecords(conditions, quoteIds);
        List<Approval_Log__c> approvalLogs = new List<Approval_Log__c>();
        
        for(SBAA__Approval__c approval : newApprovals) {
            RuleMetadata ruleMetadata = ruleMetadataMap.get(approval.SBAA__Rule__c);
            if(ruleMetadata == null) continue;
            
            Map<String, Object> currentValues = getCurrentValues(
                approval, 
                quoteMap, 
                ruleMetadata.conditions,
                quoteLinesByQuoteId.get(approval.Quote__c)
            );
            
            String key = approval.Quote__c + '-' + approval.SBAA__Rule__c;
            Integer submitCount = 1;
            String differences = '{}';
            
            List<Approval_Log__c> previousLogs = existingLogsMap.get(key);
            if(previousLogs != null && !previousLogs.isEmpty()) {
                Approval_Log__c lastLog = previousLogs[0];
                submitCount = Integer.valueOf(lastLog.Submit_Count__c + 1);
                
                if(String.isNotBlank(lastLog.Approval_Field_Values__c)) {
                    differences = compareJSON(
                        JSON.serialize(cleanFieldNames(currentValues)),
                        lastLog.Approval_Field_Values__c,
                        ruleMetadata
                    );
                }
            }
            
            System.debug('Rule: ' + approval.SBAA__Rule__c);
            System.debug('Tracked Quote Fields: ' + ruleMetadata.quoteFields);
            System.debug('Tracked Quote Line Fields: ' + ruleMetadata.quoteLineFields);
            System.debug('Current Values: ' + JSON.serialize(currentValues));
            System.debug('Differences: ' + differences);
            
            Approval_Log__c log = new Approval_Log__c(
                Quote__c = approval.Quote__c,
                Approval__c = approval.Id,
                Approval_Rule__c = approval.SBAA__Rule__c,
                Submit_Count__c = submitCount,
                Approval_Field_Values__c = JSON.serialize(cleanFieldNames(currentValues)),
                Approval_Fiels_Changes__c = differences == '{}' ? null : differences
            );
            
            approvalLogs.add(log);
        }
        
        return approvalLogs;
    }
    
    public static Set<Id> getApprovalRuleIds(List<SBAA__Approval__c> approvals) {
        Set<Id> approvalRuleIds = new Set<Id>();
        for(SBAA__Approval__c approval : approvals) {
            approvalRuleIds.add(approval.SBAA__Rule__c);
        }
        return approvalRuleIds;
    }
    
    public static Set<Id> getQuoteIds(List<SBAA__Approval__c> approvals) {
        Set<Id> quoteIds = new Set<Id>();
        for(SBAA__Approval__c approval : approvals) {
            quoteIds.add(approval.Quote__c);
        }
        return quoteIds;
    }
    
    public static Map<String, List<String>> getQuoteApprovalRulesMap(List<SBAA__Approval__c> approvals) {
        Map<String, List<String>> quoteApprovalRules = new Map<String, List<String>>();
        for(SBAA__Approval__c approval : approvals) {
            if(!quoteApprovalRules.containsKey(approval.Quote__c)) {
                quoteApprovalRules.put(approval.Quote__c, new List<String>());
            }
            quoteApprovalRules.get(approval.Quote__c).add(approval.SBAA__Rule__c);
        }
        return quoteApprovalRules;
    }
    
    public static Map<String, List<Approval_Log__c>> getLatestApprovalLogs(Set<Id> quoteIds) {
        Map<String, List<Approval_Log__c>> existingLogsMap = new Map<String, List<Approval_Log__c>>();
        List<Approval_Log__c> logList = [
            SELECT Id, Quote__c, Approval_Rule__c, Submit_Count__c, 
                   Approval_Field_Values__c, CreatedDate
            FROM Approval_Log__c 
            WHERE Quote__c IN :quoteIds
            ORDER BY CreatedDate DESC
        ];
        Decimal subCount = logList != null && logList.size()> 0 ? logList[0].Submit_Count__c: 0;
        for(Approval_Log__c log : logList) {
            String key = log.Quote__c + '-' + log.Approval_Rule__c;
            if(log.Submit_Count__c == subCount){
                if(!existingLogsMap.containsKey(key)) {
                    existingLogsMap.put(key, new List<Approval_Log__c>());
                }
                existingLogsMap.get(key).add(log);
            }
        }
        return existingLogsMap;
    }
    
    public static Map<Id, SBQQ__Quote__c> getQuoteRecords(List<SBAA__ApprovalCondition__c> conditions, Set<Id> quoteIds) {
        Set<String> uniqueFields = getUniqueFields(conditions);
        
        if (uniqueFields.isEmpty()) {
            return new Map<Id, SBQQ__Quote__c>();
        }
        
        String soqlQuery = 'SELECT ' + String.join(new List<String>(uniqueFields), ',');
        soqlQuery += ' FROM SBQQ__Quote__c WHERE Id IN :quoteIds';
        
        return new Map<Id, SBQQ__Quote__c>((List<SBQQ__Quote__c>)Database.query(soqlQuery));
    }
    
    public static Set<String> getUniqueFields(List<SBAA__ApprovalCondition__c> conditions) {
        Set<String> uniqueFields = new Set<String>();
        for(SBAA__ApprovalCondition__c condition : conditions) {    
            if (condition.SBAA__TestedField__c != null) {
                uniqueFields.add(condition.SBAA__TestedField__c);
            }
        }
        return uniqueFields;
    }
    
    public static Map<Id, List<SBQQ__QuoteLine__c>> getQuoteLinesForAllQuotes(
        Set<Id> quoteIds, 
        List<RuleMetadata> ruleMetadataList
    ) {
        Set<String> fields = new Set<String>{'Id', 'SBQQ__Quote__c'};
        
        for(RuleMetadata metadata : ruleMetadataList) {
            for(SBAA__ApprovalCondition__c condition : metadata.conditions) {
                if(condition.SBAA__TestedVariable__c != null) {
                    if(String.isNotBlank(condition.SBAA__TestedVariable__r.sbaa__FilterField__c)) {
                        fields.add(condition.SBAA__TestedVariable__r.sbaa__FilterField__c);
                    }
                    if(String.isNotBlank(condition.SBAA__TestedVariable__r.sbaa__AggregateField__c)) {
                        fields.add(condition.SBAA__TestedVariable__r.sbaa__AggregateField__c);
                    }
                }
            }
        }
        
        String query = 'SELECT ' + String.join(new List<String>(fields), ',') + 
                      ' FROM SBQQ__QuoteLine__c' +
                      ' WHERE SBQQ__Quote__c IN :quoteIds';
        
        Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteId = new Map<Id, List<SBQQ__QuoteLine__c>>();
        for(SBQQ__QuoteLine__c line : Database.query(query)) {
            if(!quoteLinesByQuoteId.containsKey(line.SBQQ__Quote__c)) {
                quoteLinesByQuoteId.put(line.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
            }
            quoteLinesByQuoteId.get(line.SBQQ__Quote__c).add(line);
        }
        
        return quoteLinesByQuoteId;
    }
    
    public static Map<String, Object> getCurrentValues(
        SBAA__Approval__c approval,
        Map<Id, SBQQ__Quote__c> quoteMap,
        List<SBAA__ApprovalCondition__c> conditions,
        List<SBQQ__QuoteLine__c> quoteLines
    ) {
        Map<String, Object> combinedValues = new Map<String, Object>();
        Map<String, Object> quoteFields = new Map<String, Object>();
        Map<String, Object> quoteLineFields = new Map<String, Object>();
        
        SBQQ__Quote__c quote = quoteMap.get(approval.Quote__c);
        
        for(SBAA__ApprovalCondition__c condition : conditions) {
            if(condition.SBAA__TestedField__c != null && quote != null) {
                String fieldName = condition.SBAA__TestedField__c;
                Object fieldValue = quote.get(fieldName);
                quoteFields.put(fieldName, fieldValue);
            }
            
            if(condition.SBAA__TestedVariable__c != null) {
                String compositeKey = String.format('{0}-{1}-{2}',
                    new List<String>{
                        condition.SBAA__TestedVariable__r.sbaa__FilterField__c,
                        condition.SBAA__TestedVariable__r.sbaa__Operator__c,
                        condition.SBAA__TestedVariable__r.sbaa__FilterValue__c
                    }
                );
                
                Decimal aggregateValue = calculateAggregateValue(
                    quoteLines != null ? quoteLines : new List<SBQQ__QuoteLine__c>(),
                    condition.SBAA__TestedVariable__r.sbaa__FilterField__c,
                    condition.SBAA__TestedVariable__r.sbaa__Operator__c,
                    condition.SBAA__TestedVariable__r.sbaa__FilterValue__c,
                    condition.SBAA__TestedVariable__r.sbaa__AggregateField__c,
                    condition.SBAA__TestedVariable__r.sbaa__AggregateFunction__c
                );
                
                quoteLineFields.put(compositeKey, aggregateValue);
            }
        }
        
        combinedValues.put('QuoteFields', quoteFields);
        combinedValues.put('QuoteLineFields', quoteLineFields);
        
        return combinedValues;
    }
    
    private static Decimal calculateAggregateValue(
        List<SBQQ__QuoteLine__c> quoteLines,
        String filterField,
        String operator,
        String filterValue,
        String aggregateField,
        String aggregateFunction
    ) {
        List<SBQQ__QuoteLine__c> matchingLines = new List<SBQQ__QuoteLine__c>();
        
        for(SBQQ__QuoteLine__c line : quoteLines) {
            if(matchesFilter(line, filterField, operator, filterValue)) {
                matchingLines.add(line);
            }
        }
        
        Decimal result = 0;
        String aggFunction = String.isBlank(aggregateFunction) ? 'SUM' : aggregateFunction.toUpperCase();
        
        if(!matchingLines.isEmpty()) {
            switch on aggFunction {
                when 'SUM' {
                    for(SBQQ__QuoteLine__c line : matchingLines) {
                        Object val = line.get(aggregateField);
                        if(val != null) {
                            result += (Decimal)val;
                        }
                    }
                }
                when 'AVG' {
                    Decimal sum = 0;
                    Integer count = 0;
                    for(SBQQ__QuoteLine__c line : matchingLines) {
                        Object val = line.get(aggregateField);
                        if(val != null) {
                            sum += (Decimal)val;
                            count++;
                        }
                    }
                    result = count > 0 ? sum/count : 0;
                }
                when 'COUNT' {
                    result = matchingLines.size();
                }
                when 'MIN' {
                    result = null;
                    for(SBQQ__QuoteLine__c line : matchingLines) {
                        Object val = line.get(aggregateField);
                        if(val != null) {
                            Decimal current = (Decimal)val;
                            result = (result == null || current < result) ? current : result;
                        }
                    }
                    result = result == null ? 0 : result;
                }
                when 'MAX' {
                    result = null;
                    for(SBQQ__QuoteLine__c line : matchingLines) {
                        Object val = line.get(aggregateField);
                        if(val != null) {
                            Decimal current = (Decimal)val;
                            result = (result == null || current > result) ? current : result;
                        }
                    }
                    result = result == null ? 0 : result;
                }
            }
        }
        
        return result;
    }
    
    private static Boolean matchesFilter(SBQQ__QuoteLine__c line, String filterField, String operator, String filterValue) {
        Object fieldValue = line.get(filterField);
        if(fieldValue == null) return false;
        
        String strValue = String.valueOf(fieldValue);
        operator = String.isBlank(operator) ? 'equals' : operator.toLowerCase();
        
        switch on operator {
            when 'equals' {
                return strValue == filterValue;
            }
            when 'contains' {
                return strValue.contains(filterValue);
            }
            when 'starts with' {
                return strValue.startsWith(filterValue);
            }
            when else {
                return false;
            }
        }
    }
    
    private static String compareJSON(String json1, String json2, RuleMetadata ruleMetadata) {
        try {
            if (String.isBlank(json1)) json1 = '{"QuoteFields":{}, "QuoteLineFields":{}}';
            if (String.isBlank(json2)) json2 = '{"QuoteFields":{}, "QuoteLineFields":{}}';
            System.debug('Comparing JSON: ' + json1);
            System.debug('With: ' + json2);
            System.debug('Rule Metadata: ' + JSON.serialize(ruleMetadata));
            Map<String, Object> currentValues = (Map<String, Object>) JSON.deserializeUntyped(json1);
            Map<String, Object> previousValues = (Map<String, Object>) JSON.deserializeUntyped(json2);
            Map<String, Object> differences = new Map<String, Object>();
            System.debug('Current Values: ' + JSON.serialize(currentValues));
            System.debug('Previous Values: ' + JSON.serialize(previousValues));
            Map<String, Object> currentQuoteFields = (Map<String, Object>)currentValues.get('QuoteFields');
            Map<String, Object> previousQuoteFields = (Map<String, Object>)previousValues.get('QuoteFields');
            System.debug('Current Quote Fields: ' + JSON.serialize(currentQuoteFields));
            System.debug('Previous Quote Fields: ' + JSON.serialize(previousQuoteFields));
            if (currentQuoteFields != null && previousQuoteFields != null) {
                for (String fieldName : currentQuoteFields.keySet()) {
                    String cleanFieldName = fieldName.replace('SBQQ__', '').replace('__c', '');
                    if (!ruleMetadata.quoteFields.contains(fieldName) && 
                        !ruleMetadata.quoteFields.contains(cleanFieldName)) continue;
                    System.debug('Comparing Field: ' + fieldName);
                    Object currentValue = currentQuoteFields.get(fieldName);
                    Object previousValue = previousQuoteFields.get(fieldName);
                    
                    if (hasValueChanged(currentValue, previousValue)) {
                        differences.put('QuoteFields.' + fieldName, new Map<String, Object>{
                            'oldValue' => previousValue,
                            'newValue' => currentValue
                        });
                    }
                }
            }

            Map<String, Object> currentLineFields = (Map<String, Object>)currentValues.get('QuoteLineFields');
            Map<String, Object> previousLineFields = (Map<String, Object>)previousValues.get('QuoteLineFields');
            
            if (currentLineFields != null && previousLineFields != null) {
                for (String compositeKey : currentLineFields.keySet()) {
                    if (!ruleMetadata.quoteLineFields.contains(compositeKey)) continue;
                    
                    Object currentValue = currentLineFields.get(compositeKey);
                    Object previousValue = previousLineFields.get(compositeKey);
                    
                    System.debug('Comparing QuoteLineField: ' + compositeKey);
                    System.debug('Current Value: ' + currentValue);
                    System.debug('Previous Value: ' + previousValue);
                    
                    if (hasValueChanged(currentValue, previousValue)) {
                        differences.put('QuoteLineFields.' + compositeKey, new Map<String, Object>{
                            'oldValue' => previousValue,
                            'newValue' => currentValue
                        });
                    }
                }
            }

            return !differences.isEmpty() ? JSON.serialize(differences) : '{}';
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error comparing JSON: ' + e.getMessage());
            return '{}';
        }
    }
    
    public static Boolean hasValueChanged(Object val1, Object val2) {
        try {
            if (val1 == null && val2 == null) return false;
            if (val1 == null || val2 == null) return true;
            
            if (val1 instanceof Decimal || val1 instanceof Integer || 
                val2 instanceof Decimal || val2 instanceof Integer) {
                Decimal num1 = val1 instanceof Decimal ? (Decimal)val1 : Decimal.valueOf(String.valueOf(val1));
                Decimal num2 = val2 instanceof Decimal ? (Decimal)val2 : Decimal.valueOf(String.valueOf(val2));
                
                Decimal tolerance = 0.000001;
                Boolean hasChanged = Math.abs(num1 - num2) > tolerance;
                
                System.debug('Numeric comparison: ' + num1 + ' vs ' + num2 + ' = ' + hasChanged);
                return hasChanged;
            }
            
            String str1 = String.valueOf(val1).trim();
            String str2 = String.valueOf(val2).trim();
            Boolean hasChanged = str1 != str2;
            
            System.debug('String comparison: ' + str1 + ' vs ' + str2 + ' = ' + hasChanged);
            return hasChanged;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in hasValueChanged: ' + e.getMessage());
            return true;
        }
    }
    
    public static Map<String, Object> cleanFieldNames(Map<String, Object> originalMap) {
        if (originalMap == null) return null;
        
        Map<String, Object> cleanedMap = new Map<String, Object>();
        for (String key : originalMap.keySet()) {
            String cleanKey = key.replace('SBQQ__', '').replace('__c', '');
            Object value = originalMap.get(key);
            
            if (value instanceof Map<String, Object>) {
                value = cleanFieldNames((Map<String, Object>)value);
            }
            
            cleanedMap.put(cleanKey, value);
        }
        return cleanedMap;
    }
    
    public static List<SBAA__ApprovalCondition__c> getApprovalConditions(Set<Id> approvalRuleIds) {
        List<SBAA__ApprovalCondition__c> ruleConditions = new List<SBAA__ApprovalCondition__c>();
        
        if (allConditions == null) {
            allConditions = [
                SELECT Id, SBAA__ApprovalRule__c, 
                       SBAA__TestedField__c, 
                       SBAA__TestedVariable__c,
                       SBAA__TestedVariable__r.Name,
                       SBAA__TestedVariable__r.sbaa__AggregateField__c,
                       SBAA__TestedVariable__r.sbaa__AggregateFunction__c,
                       SBAA__TestedVariable__r.sbaa__FilterField__c,
                       SBAA__TestedVariable__r.sbaa__Operator__c,
                       SBAA__TestedVariable__r.sbaa__FilterValue__c
                FROM SBAA__ApprovalCondition__c 
                WHERE SBAA__ApprovalRule__c IN :approvalRuleIds
            ];
        }
        
        return allConditions;
    }
    
    public static Map<String, List<String>> getApprovalRuleVariablesMap(Set<Id> approvalRuleIds) {
        Map<String, List<String>> approvalRuleVariablesMap = new Map<String, List<String>>();
        
        List<SBAA__ApprovalCondition__c> conditions = getApprovalConditions(approvalRuleIds);
        
        for(SBAA__ApprovalCondition__c condition : conditions) {
            if (condition.SBAA__TestedVariable__c != null) {
                if(!approvalRuleVariablesMap.containsKey(condition.SBAA__ApprovalRule__c)) {
                    approvalRuleVariablesMap.put(condition.SBAA__ApprovalRule__c, new List<String>());
                } 
                approvalRuleVariablesMap.get(condition.SBAA__ApprovalRule__c).add(condition.SBAA__TestedVariable__c);
            }
        }
        return approvalRuleVariablesMap;
    }

    public class RuleMetadata {
        public List<SBAA__ApprovalCondition__c> conditions;
        public Set<String> quoteFields;
        public Set<String> quoteLineFields;
        
        public RuleMetadata() {
            this.conditions = new List<SBAA__ApprovalCondition__c>();
            this.quoteFields = new Set<String>();
            this.quoteLineFields = new Set<String>();
        }
        
        public void addQuoteField(String fieldName) {
            if(String.isNotBlank(fieldName)) {
                String cleanFieldName = fieldName.replace('SBQQ__', '').replace('__c', '');
                this.quoteFields.add(cleanFieldName);
            }
        }
        
        public void addQuoteLineField(String filterField, String operator, String filterValue) {
            if(String.isNotBlank(filterField)) {
                String cleanFilterField = filterField.replace('SBQQ__', '').replace('__c', '');
                String compositeKey = String.format('{0}-{1}-{2}',
                    new List<String>{
                        cleanFilterField,
                        operator,
                        filterValue
                    }
                );
                this.quoteLineFields.add(compositeKey);
            }
        }
    }
}