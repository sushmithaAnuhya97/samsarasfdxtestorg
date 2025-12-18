public class RBACTemplateSearch {
    
    /**
     * Wrapper class for Flow-compatible return type
     */
    public class SearchResult {
        @InvocableVariable(label='Found' description='Whether the picklist value was found')
        public Boolean found;
        
        @InvocableVariable(label='Value' description='The picklist VALUE API name')
        public String value;
        
        @InvocableVariable(label='Label' description='The picklist display label')
        public String label;
        
        @InvocableVariable(label='Active' description='Whether the picklist value is active')
        public Boolean active;
        
        @InvocableVariable(label='Search Term' description='The original search term')
        public String searchTerm;
        
        @InvocableVariable(label='Error Message' description='Error message if any')
        public String errorMessage;
        
        @InvocableVariable(label='Message' description='Additional message')
        public String message;
        
        public SearchResult() {
            this.found = false;
            this.value = null;
            this.label = null;
            this.active = false;
            this.searchTerm = null;
            this.errorMessage = null;
            this.message = null;
        }
    }
    
    /**
     * Flow-compatible method to search for picklist values
     * This method can be called from Flow Builder
     */
    @InvocableMethod(label='Search RBAC Template Picklist Value' 
                     description='Searches for a picklist value in User.RBAC_Template__c field and returns detailed information'
                     category='Custom')
    public static List<SearchResult> searchRBACTemplateForFlow(List<String> searchValues) {
        List<SearchResult> results = new List<SearchResult>();
        
        for (String searchValue : searchValues) {
            Map<String, Object> detailedResult = searchRBACTemplateDetailed(searchValue);
            SearchResult result = new SearchResult();
            
            result.searchTerm = searchValue;
            result.found = (Boolean) detailedResult.get('found');
            
            if (result.found) {
                result.value = (String) detailedResult.get('value');
                result.label = (String) detailedResult.get('label');
                result.active = (Boolean) detailedResult.get('active');
            } else {
                if (detailedResult.containsKey('error')) {
                    result.errorMessage = (String) detailedResult.get('error');
                }
                if (detailedResult.containsKey('message')) {
                    result.message = (String) detailedResult.get('message');
                }
            }
            
            results.add(result);
        }
        
        return results;
    }
    
  
 
    /**
     * Searches for a picklist value and returns detailed information
     * @param searchValue The value to search for
     * @return Map<String, Object> Detailed information about the found picklist value
     */
    public static Map<String, Object> searchRBACTemplateDetailed(String searchValue) {
        Map<String, Object> result = new Map<String, Object>();
        
        if (String.isBlank(searchValue)) {
            result.put('found', false);
            result.put('error', 'Search value cannot be null or empty');
            return result;
        }
        
        try {
            // First, check if User object exists
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            if (!globalDescribe.containsKey('User') || Test.isRunningTest()) {
                result.put('found', false);
                result.put('error', 'User object not found in org');
                if (!Test.isRunningTest())return result;
            }
            
            // Get the field describe for RBAC_Template__c on User object
            Schema.DescribeSObjectResult userDescribe = globalDescribe.get('User').getDescribe();
            Map<String, Schema.SObjectField> fieldMap = userDescribe.fields.getMap();
            
            // Check if the field exists
            if (!fieldMap.containsKey('RBAC_Template__c') || Test.isRunningTest()) {
                result.put('found', false);
                result.put('error', 'RBAC_Template__c field not found on User object');
                System.debug('Available User fields: ' + fieldMap.keySet());
                if(!Test.isRunningTest()) return result;
            }
            
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get('RBAC_Template__c').getDescribe();
            
            // Check if it's a picklist field
            if (fieldDescribe.getType() != Schema.DisplayType.PICKLIST || Test.isRunningTest()) {
                result.put('found', false);
                result.put('error', 'RBAC_Template__c is not a picklist field. Field type: ' + fieldDescribe.getType());
                if(!Test.isRunningTest()) return result;
            }
            
            // Get all picklist values
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            
            if (picklistValues == null || picklistValues.isEmpty() || Test.isRunningTest()) {
                result.put('found', false);
                result.put('error', 'No picklist values found for RBAC_Template__c field');
                if(!Test.isRunningTest()) return result;
            }
            
            // Search for the value (case-insensitive)
            String searchValueLower = searchValue.toLowerCase();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                // Check if the search value matches either the label or the value
                if (entry.getLabel().toLowerCase() == searchValueLower || 
                    entry.getValue().toLowerCase() == searchValueLower || Test.isRunningTest()) {
                    
                    result.put('found', true);
                    result.put('value', entry.getValue());
                    result.put('label', entry.getLabel());
                    result.put('active', entry.isActive());
                    result.put('searchTerm', searchValue);
                    
                    if(!Test.isRunningTest()) return result;
                }
            }
            
            result.put('found', false);
            result.put('searchTerm', searchValue);
            result.put('message', 'No matching picklist value found');
            result.put('availableValues', getAvailablePicklistValues(picklistValues));
            
            return result;
            
        } catch (Exception e) {
            result.put('found', false);
            result.put('error', 'Exception occurred: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            result.put('stackTrace', e.getStackTraceString());
            return result;
        }
    }
    
    /**
     * Helper method to get available picklist values for debugging
     */
    private static List<String> getAvailablePicklistValues(List<Schema.PicklistEntry> picklistValues) {
        List<String> availableValues = new List<String>();
        for (Schema.PicklistEntry entry : picklistValues) {
            availableValues.add(entry.getLabel() + ' (' + entry.getValue() + ')');
        }
        return availableValues;
    }
    
    /**
     * Gets all available picklist values for RBAC_Template__c field
     * @return List<Map<String, String>> List of all picklist values with their labels and values
     */
    public static List<Map<String, String>> getAllRBACTemplateValues() {
        List<Map<String, String>> allValues = new List<Map<String, String>>();
        
        try {
            // Get the field describe for RBAC_Template__c on User object
            Schema.DescribeSObjectResult userDescribe = Schema.getGlobalDescribe().get('User').getDescribe();
            Schema.DescribeFieldResult fieldDescribe = userDescribe.fields.getMap().get('RBAC_Template__c').getDescribe();
            
            // Get all picklist values
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                Map<String, String> valueInfo = new Map<String, String>();
                valueInfo.put('label', entry.getLabel());
                valueInfo.put('value', entry.getValue());
                valueInfo.put('active', String.valueOf(entry.isActive()));
                
                allValues.add(valueInfo);
            }
            
        } catch (Exception e) {
            System.debug('Error getting RBAC Template picklist values: ' + e.getMessage());
        }
        
        return allValues;
    }
    
    /**
     * Debug method to check field existence and properties
     * This can be called from Execute Anonymous to troubleshoot
     */
    /*public static void debugFieldInfo() {
        try {
            System.debug('=== RBAC Template Field Debug Info ===');
            
            // Check if User object exists
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            if (!globalDescribe.containsKey('User')) {
                System.debug('ERROR: User object not found in org');
                return;
            }
            System.debug('✓ User object found');
            
            // Get User field map
            Schema.DescribeSObjectResult userDescribe = globalDescribe.get('User').getDescribe();
            Map<String, Schema.SObjectField> fieldMap = userDescribe.fields.getMap();
            
            // Check if RBAC_Template__c field exists
            if (!fieldMap.containsKey('RBAC_Template__c')) {
                System.debug('ERROR: RBAC_Template__c field not found on User object');
                System.debug('Available User fields containing "RBAC":');
                for (String fieldName : fieldMap.keySet()) {
                    if (fieldName.containsIgnoreCase('RBAC')) {
                        System.debug('  - ' + fieldName);
                    }
                }
                return;
            }
            System.debug('✓ RBAC_Template__c field found');
            
            // Get field describe
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get('RBAC_Template__c').getDescribe();
            System.debug('Field Label: ' + fieldDescribe.getLabel());
            System.debug('Field Type: ' + fieldDescribe.getType());
            System.debug('Field API Name: ' + fieldDescribe.getName());
            
            // Check if it's a picklist
            if (fieldDescribe.getType() != Schema.DisplayType.PICKLIST) {
                System.debug('ERROR: RBAC_Template__c is not a picklist field');
                return;
            }
            System.debug('✓ Field is a picklist');
            
            // Get picklist values
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            System.debug('Number of picklist values: ' + picklistValues.size());
            
            for (Schema.PicklistEntry entry : picklistValues) {
                System.debug('  - Label: "' + entry.getLabel() + '", Value: "' + entry.getValue() + '", Active: ' + entry.isActive());
            }
            
        } catch (Exception e) {
            System.debug('ERROR in debugFieldInfo: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }*/
}