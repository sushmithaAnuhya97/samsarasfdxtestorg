@isTest
public class RBACTemplateSearchTest {
    
    @isTest
    static void testSearchResultWrapperClass() {
        // Test SearchResult constructor and default values
        RBACTemplateSearch.SearchResult result = new RBACTemplateSearch.SearchResult();
        
        System.assertEquals(false, result.found, 'Default found should be false');
        System.assertEquals(null, result.value, 'Default value should be null');
        System.assertEquals(null, result.label, 'Default label should be null');
        System.assertEquals(false, result.active, 'Default active should be false');
        System.assertEquals(null, result.searchTerm, 'Default searchTerm should be null');
        System.assertEquals(null, result.errorMessage, 'Default errorMessage should be null');
        System.assertEquals(null, result.message, 'Default message should be null');
        
        // Test setting values
        result.found = true;
        result.value = 'Test_Value';
        result.label = 'Test Label';
        result.active = true;
        result.searchTerm = 'Test';
        result.errorMessage = 'Test Error';
        result.message = 'Test Message';
        
        System.assertEquals(true, result.found, 'Found should be set to true');
        System.assertEquals('Test_Value', result.value, 'Value should be set correctly');
        System.assertEquals('Test Label', result.label, 'Label should be set correctly');
        System.assertEquals(true, result.active, 'Active should be set to true');
        System.assertEquals('Test', result.searchTerm, 'SearchTerm should be set correctly');
        System.assertEquals('Test Error', result.errorMessage, 'ErrorMessage should be set correctly');
        System.assertEquals('Test Message', result.message, 'Message should be set correctly');
    }
    
  
    
    @isTest
    static void testSearchRBACTemplateDetailed() {
        // Test with null value
        Map<String, Object> nullResult = RBACTemplateSearch.searchRBACTemplateDetailed(null);
        System.assertEquals(false, nullResult.get('found'), 'Should return found=false for null input');
        System.assertEquals('Search value cannot be null or empty', nullResult.get('error'), 'Should return error message for null input');
        
        // Test with empty string
        Map<String, Object> emptyResult = RBACTemplateSearch.searchRBACTemplateDetailed('');
        System.assertEquals(false, emptyResult.get('found'), 'Should return found=false for empty input');
        System.assertEquals('Search value cannot be null or empty', emptyResult.get('error'), 'Should return error message for empty input');
        
        // Test with blank string
        Map<String, Object> blankResult = RBACTemplateSearch.searchRBACTemplateDetailed('   ');
        System.assertEquals(false, blankResult.get('found'), 'Should return found=false for blank input');
        System.assertEquals('Search value cannot be null or empty', blankResult.get('error'), 'Should return error message for blank input');
        
        // Test with valid search value
        Map<String, Object> validResult = RBACTemplateSearch.searchRBACTemplateDetailed('Test');
        System.assertNotEquals(null, validResult, 'Result should not be null');
        System.assert(validResult.containsKey('found'), 'Result should contain found key');
        System.assert(validResult.containsKey('searchTerm'), 'Result should contain searchTerm key');
        System.assertEquals('Test', validResult.get('searchTerm'), 'SearchTerm should match input');
        
        // Test structure of result
        if ((Boolean)validResult.get('found')) {
            System.assert(validResult.containsKey('value'), 'Should contain value when found=true');
            System.assert(validResult.containsKey('label'), 'Should contain label when found=true');
            System.assert(validResult.containsKey('active'), 'Should contain active when found=true');
        } else {
            // If not found, should contain either error or message
            System.assert(validResult.containsKey('error') || validResult.containsKey('message'), 
                         'Should contain error or message when found=false');
        }
    }
    
    @isTest
    static void testGetAllRBACTemplateValues() {
        // Test getting all picklist values
        List<Map<String, String>> allValues = RBACTemplateSearch.getAllRBACTemplateValues();
        System.assertNotEquals(null, allValues, 'Should return a list (even if empty)');
        
        // If there are values, verify the structure
        if (!allValues.isEmpty()) {
            Map<String, String> firstValue = allValues[0];
            System.assert(firstValue.containsKey('label'), 'Should contain label key');
            System.assert(firstValue.containsKey('value'), 'Should contain value key');
            System.assert(firstValue.containsKey('active'), 'Should contain active key');
        }
    }
    
   
    
    @isTest
    static void testGetAvailablePicklistValues() {
        // Test helper method indirectly through searchRBACTemplateDetailed
        Map<String, Object> result = RBACTemplateSearch.searchRBACTemplateDetailed('NonExistentValue');
        
        if (result.containsKey('availableValues')) {
            List<String> availableValues = (List<String>) result.get('availableValues');
            System.assertNotEquals(null, availableValues, 'Available values should not be null');
            
            // If there are available values, verify they have the expected format
            for (String value : availableValues) {
                System.assert(value.contains('('), 'Available value should contain parentheses');
                System.assert(value.contains(')'), 'Available value should contain parentheses');
            }
        }
    }
    
    @isTest
    static void testErrorHandling() {
        // Test various error scenarios
        
        // Test with very long search term
        String longSearchTerm = 'A'.repeat(1000);
        Map<String, Object> longResult = RBACTemplateSearch.searchRBACTemplateDetailed(longSearchTerm);
        System.assertNotEquals(null, longResult, 'Should handle long search terms');
        
        // Test with special characters
        String specialChars = '!@#$%^&*()_+-=[]{}|;:,.<>?';
        Map<String, Object> specialResult = RBACTemplateSearch.searchRBACTemplateDetailed(specialChars);
        System.assertNotEquals(null, specialResult, 'Should handle special characters');
        
        // Test with unicode characters
        String unicodeChars = '测试Unicode字符';
        Map<String, Object> unicodeResult = RBACTemplateSearch.searchRBACTemplateDetailed(unicodeChars);
        System.assertNotEquals(null, unicodeResult, 'Should handle unicode characters');
    }
    
    @isTest
    static void testCaseInsensitiveSearch() {
        // Test case insensitive search functionality
        String searchTerm = 'TEST';
        Map<String, Object> result = RBACTemplateSearch.searchRBACTemplateDetailed(searchTerm);
        
        // The method should handle case insensitive search
        // If there's a picklist value that matches 'TEST' (case insensitive), it should be found
        System.assertNotEquals(null, result, 'Case insensitive search should work');
        System.assertEquals(searchTerm, result.get('searchTerm'), 'SearchTerm should be preserved');
    }
    
    @isTest
    static void testFlowMethodIntegration() {
        // Test integration between Flow methods and underlying methods
        
        // Test that Flow method calls underlying detailed method correctly
        List<String> searchValues = new List<String>{'TestValue'};
        List<RBACTemplateSearch.SearchResult> flowResults = RBACTemplateSearch.searchRBACTemplateForFlow(searchValues);
        
        System.assertEquals(1, flowResults.size(), 'Should return one result');
        RBACTemplateSearch.SearchResult flowResult = flowResults[0];
        
        // Verify that the Flow result contains the same information as the detailed method
        Map<String, Object> detailedResult = RBACTemplateSearch.searchRBACTemplateDetailed('TestValue');
        
        System.assertEquals(detailedResult.get('found'), flowResult.found, 'Found status should match');
        System.assertEquals(detailedResult.get('searchTerm'), flowResult.searchTerm, 'SearchTerm should match');
        
        if ((Boolean)detailedResult.get('found')) {
            System.assertEquals(detailedResult.get('value'), flowResult.value, 'Value should match');
            System.assertEquals(detailedResult.get('label'), flowResult.label, 'Label should match');
            System.assertEquals(detailedResult.get('active'), flowResult.active, 'Active status should match');
        }
    }
    
    
}