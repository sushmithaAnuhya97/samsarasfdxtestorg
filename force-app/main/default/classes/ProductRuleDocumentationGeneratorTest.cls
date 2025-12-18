/**
 * Test class for ProductRuleDocumentationGenerator
 */
@isTest
private class ProductRuleDocumentationGeneratorTest {
    
    /**
     * Set up test data for the product rule documentation tests
     */
    @testSetup
    static void setupTestData() {
        // Create a test product
        Product2 product = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001',
            IsActive = true
        );
        insert product;
        
        // Create a test product rule
        SBQQ__ProductRule__c productRule = new SBQQ__ProductRule__c(
            Name = 'Test Product Rule',
            SBQQ__Active__c = true,
            SBQQ__ConditionsMet__c = 'All',
            SBQQ__Scope__c = 'Product',
            SBQQ__EvaluationEvent__c = 'Edit',
            SBQQ__Type__c = 'Selection',
            SBQQ__LookupObject__c = 'SBQQ__LookupData__c',
            SBQQ__LookupTypeField__c = 'SBQQ__Type__c',
            SBQQ__LookupProductField__c = 'SBQQ__Product__c',
            SBQQ__ErrorMessage__c = 'Test Error Message'
        );
        insert productRule;
        
        // Create a test error condition
        SBQQ__ErrorCondition__c errorCondition = new SBQQ__ErrorCondition__c(
            SBQQ__Rule__c = productRule.Id,
            SBQQ__Index__c = 1,
            SBQQ__TestedField__c = 'SBQQ__Quantity__c',
            SBQQ__TestedObject__c = 'SBQQ__QuoteLine__c',
            SBQQ__Operator__c = 'greater than',
            SBQQ__FilterValue__c = '10'
        );
        insert errorCondition;
        
        // Create a test product action
        SBQQ__ProductAction__c productAction = new SBQQ__ProductAction__c(
            SBQQ__Rule__c = productRule.Id,
            SBQQ__Type__c = 'Add',
            SBQQ__Product__c = product.Id,
            SBQQ__Required__c = true
        );
        insert productAction;
        
        // Create a test lookup query
        SBQQ__LookupQuery__c lookupQuery = new SBQQ__LookupQuery__c(
            SBQQ__ProductRule__c = productRule.Id,
            SBQQ__MatchType__c = 'Field Value',
            SBQQ__Operator__c = 'equals',
            SBQQ__TestedField__c = 'VG_Tier__c',
            SBQQ__TestedObject__c = 'Quote',
            SBQQ__LookupField__c = 'VG_Tier__c'
        );
        insert lookupQuery;
        
        // Create test lookup data
        SBQQ__LookupData__c lookupData = new SBQQ__LookupData__c(
            SBQQ__Type__c = 'Add',
            SBQQ__Product__c = product.Id,
            SBQQ__Value__c = 'Test Value',
            SBQQ__Category__c = 'Test Category',
            SBQQ__Required__c = true
        );
        insert lookupData;
        
        // Create a test configuration rule
        SBQQ__ConfigurationRule__c configRule = new SBQQ__ConfigurationRule__c(
            SBQQ__ProductRule__c = productRule.Id,
            SBQQ__Active__c = true,
            SBQQ__Product__c = product.Id
        );
        insert configRule;
        
        // Create a test summary variable for testing the describe method
        SBQQ__SummaryVariable__c summaryVar = new SBQQ__SummaryVariable__c(
            Name = 'Test Summary Variable',
            SBQQ__TargetObject__c = 'Quote Line',
            SBQQ__AggregateField__c = 'SBQQ__Quantity__c',
            SBQQ__AggregateFunction__c = 'SUM',
            SBQQ__FilterField__c = 'SBQQ__Product__c',
            SBQQ__Operator__c = 'equals',
            SBQQ__FilterValue__c = product.Id
        );
        insert summaryVar;
    }
    
    /**
     * Test the generateAllRuleDocumentation method
     */
    @isTest
    static void testGenerateAllRuleDocumentation() {
        Test.startTest();
        
        // Call the method to test
        List<ProductRuleDocumentationGenerator.RuleDocumentation> documentation = 
            ProductRuleDocumentationGenerator.generateAllRuleDocumentation();
        
        // Verify results
        System.assertNotEquals(null, documentation, 'Documentation should not be null');
        System.assertEquals(1, documentation.size(), 'Should have documentation for one rule');
        
        ProductRuleDocumentationGenerator.RuleDocumentation doc = documentation[0];
        System.assertEquals('Test Product Rule', doc.ruleName, 'Rule name should match');
        System.assertEquals('Selection', doc.ruleType, 'Rule type should match');
        System.assertEquals('Product', doc.scope, 'Scope should match');
        System.assertEquals('Edit', doc.evaluationEvent, 'Evaluation event should match');
        System.assertEquals('Test Error Message', doc.errorMessage, 'Error message should match');
        System.assertEquals('SBQQ__LookupData__c', doc.lookupObject, 'Lookup object should match');
        
        // Verify the document has condition logic, actions, and configuration rules
        System.assertNotEquals(null, doc.conditionLogic, 'Condition logic should not be null');
        System.assertNotEquals(null, doc.actions, 'Actions should not be null');
        System.assertNotEquals(null, doc.configurationRules, 'Configuration rules should not be null');
        
        // Test the complete description
        String description = doc.getCompleteDescription();
        System.assertNotEquals(null, description, 'Complete description should not be null');
        System.assert(description.contains('PRODUCT RULE: Test Product Rule'), 'Description should contain rule name');
        
        Test.stopTest();
    }
    
    /**
     * Test the prepareExcelExport method
     */
    @isTest
    static void testPrepareExcelExport() {
        Test.startTest();
        
        // Call the method to test
        List<Map<String, String>> exportData = ProductRuleDocumentationGenerator.prepareExcelExport();
        
        // Verify results
        System.assertNotEquals(null, exportData, 'Export data should not be null');
        System.assertEquals(1, exportData.size(), 'Should have one row in export data');
        
        Map<String, String> row = exportData[0];
        System.assertEquals('Test Product Rule', row.get('Rule Name'), 'Rule name should match');
        System.assertEquals('Selection', row.get('Rule Type'), 'Rule type should match');
        System.assertEquals('Product', row.get('Scope'), 'Scope should match');
        
        Test.stopTest();
    }
    
    /**
     * Test the export to file methods
     */
    @isTest
    static void testExportToFile() {
        Test.startTest();
        
        try {
            // Test export to ContentVersion file
            Id contentDocId = ProductRuleDocumentationGenerator.exportToExcelFile();
            System.assertNotEquals(null, contentDocId, 'Content Document ID should not be null');
            
            // Verify the ContentVersion record was created
            ContentVersion cv = [SELECT Id, Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :contentDocId LIMIT 1];
            System.assertNotEquals(null, cv, 'ContentVersion should be created');
            System.assert(cv.Title.contains('Product Rule Documentation'), 'Title should include "Product Rule Documentation"');
            System.assertNotEquals(null, cv.VersionData, 'Version data should not be null');
            
        } catch (Exception e) {
            System.assert(false, 'Exception occurred: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    /**
     * Test the lookup queries and lookup data methods
     */
    @isTest
    static void testLookupQueriesAndData() {
        Test.startTest();
        
        // Get the product rule
        SBQQ__ProductRule__c rule = [SELECT Id FROM SBQQ__ProductRule__c LIMIT 1];
        
        // Get the lookup query
        SBQQ__LookupQuery__c query = [SELECT Id, SBQQ__MatchType__c, SBQQ__Operator__c, 
                                     SBQQ__TestedField__c, SBQQ__TestedObject__c, 
                                     SBQQ__LookupField__c, SBQQ__ProductRule__c 
                                     FROM SBQQ__LookupQuery__c WHERE SBQQ__ProductRule__c = :rule.Id LIMIT 1];
        
        // Call the processLookupQueries method directly (need to use reflection or just test via the main method)
        List<SBQQ__LookupQuery__c> queries = new List<SBQQ__LookupQuery__c>{query};
        
        // Generate documentation and test the lookup pieces
        List<ProductRuleDocumentationGenerator.RuleDocumentation> documentation = 
            ProductRuleDocumentationGenerator.generateAllRuleDocumentation();
        
        ProductRuleDocumentationGenerator.RuleDocumentation doc = documentation[0];
        System.assertNotEquals(null, doc.lookupQueries, 'Lookup queries should not be null');
        System.assert(doc.lookupQueries.contains('Lookup Data records where'), 'Lookup queries should include formatted text');
        
        Test.stopTest();
    }
    
    /**
     * Test handling of non-existent fields in lookups
     */
    @isTest
    static void testNonExistentFields() {
        Test.startTest();
        
        // Get the product rule
        SBQQ__ProductRule__c rule = [SELECT Id FROM SBQQ__ProductRule__c LIMIT 1];
        
        // Update the lookup query to reference a field that doesn't exist
        SBQQ__LookupQuery__c query = [SELECT Id FROM SBQQ__LookupQuery__c LIMIT 1];
        query.SBQQ__LookupField__c = 'NonExistentField__c';
        update query;
        
        // Generate documentation - this should handle the non-existent field gracefully
        List<ProductRuleDocumentationGenerator.RuleDocumentation> documentation = 
            ProductRuleDocumentationGenerator.generateAllRuleDocumentation();
        
        // Should still get documentation back
        System.assertNotEquals(null, documentation, 'Documentation should not be null');
        System.assertEquals(1, documentation.size(), 'Should have documentation for one rule');
        
        Test.stopTest();
    }
    
    /**
     * Test documentation generation with summary variables in error conditions
     */
    @isTest
    static void testSummaryVariableConditions() {
        Test.startTest();
        
        // Get the product rule and summary variable created in the setup
        SBQQ__ProductRule__c rule = [SELECT Id, SBQQ__ConditionsMet__c FROM SBQQ__ProductRule__c LIMIT 1];
        SBQQ__SummaryVariable__c summaryVar = [SELECT Id, Name FROM SBQQ__SummaryVariable__c LIMIT 1];
        
        // Create a second summary variable to test the CombineWith feature
        SBQQ__SummaryVariable__c secondVar = new SBQQ__SummaryVariable__c(
            Name = 'Second Summary Variable',
            SBQQ__TargetObject__c = 'Quote Line',
            SBQQ__AggregateField__c = 'SBQQ__NetPrice__c',
            SBQQ__AggregateFunction__c = 'SUM',
            SBQQ__Scope__c = 'Quote'
        );
        insert secondVar;
        
        // Update the first summary variable to combine with the second one
        summaryVar.SBQQ__CompositeOperator__c = 'Add';
        summaryVar.SBQQ__CombineWith__c = secondVar.Id;
        update summaryVar;
        
        // Create an error condition that uses the summary variable
        SBQQ__ErrorCondition__c varCondition = new SBQQ__ErrorCondition__c(
            SBQQ__Rule__c = rule.Id,
            SBQQ__Index__c = 2,
            SBQQ__TestedVariable__c = summaryVar.Id,
            SBQQ__Operator__c = 'greater than',
            SBQQ__FilterValue__c = '100'
        );
        insert varCondition;
        
        // Create another error condition that uses the summary variable as filter variable too
        SBQQ__ErrorCondition__c filterVarCondition = new SBQQ__ErrorCondition__c(
            SBQQ__Rule__c = rule.Id,
            SBQQ__Index__c = 3,
            SBQQ__TestedField__c = 'SBQQ__Quantity__c',
            SBQQ__TestedObject__c = 'SBQQ__QuoteLine__c',
            SBQQ__Operator__c = 'greater than',
            SBQQ__FilterType__c = 'Variable',
            SBQQ__FilterVariable__c = secondVar.Id
        );
        insert filterVarCondition;
        
        // Generate documentation
        List<ProductRuleDocumentationGenerator.RuleDocumentation> documentation = 
            ProductRuleDocumentationGenerator.generateAllRuleDocumentation();
        
        System.assertNotEquals(null, documentation, 'Documentation should not be null');
        System.assertEquals(1, documentation.size(), 'Should have documentation for one rule');
        
        ProductRuleDocumentationGenerator.RuleDocumentation doc = documentation[0];
        
        // Debug the actual text for inspection
        System.debug('Condition Logic Text: ' + doc.conditionLogic);
        
        // More flexible assertions that should pass regardless of exact format
        String conditionText = doc.conditionLogic.toLowerCase();
        
        // Test for the presence of the summary variable information
        System.assert(conditionText.contains('sum') && 
                     conditionText.contains('quantity') && 
                     conditionText.contains('netprice'), 
                     'Documentation should include summary variable references');
        
        // Test for the presence of the composite operator 
        System.assert(conditionText.contains('add'), 
                     'Documentation should include the composite operator');
        
        // Verify that both error conditions are included
        System.assert(doc.conditionLogic.contains('2.'), 
                     'Documentation should include the first summary variable condition');
        System.assert(doc.conditionLogic.contains('3.'), 
                     'Documentation should include the second summary variable condition');
        
        Test.stopTest();
    }
}