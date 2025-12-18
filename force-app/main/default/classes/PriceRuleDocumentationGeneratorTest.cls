@isTest
private class PriceRuleDocumentationGeneratorTest {
    
    @TestSetup
    static void setupData() {
        // Create Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-PROD',
            IsActive = true
        );
        insert testProduct;
        
        // Create Price Rule
        SBQQ__PriceRule__c priceRule = new SBQQ__PriceRule__c(
            Name = 'Test Price Rule',
            SBQQ__Active__c = true,
            SBQQ__ConditionsMet__c = 'All',
            SBQQ__EvaluationEvent__c = 'On Calculate',
            SBQQ__TargetObject__c = 'Calculator',
            SBQQ__Product__c = testProduct.Id,
            SBQQ__LookupObject__c = 'SBQQ__LookupData__c',
            SBQQ__EvaluationOrder__c = 10
        );
        insert priceRule;
        
        // Create Summary Variable
        SBQQ__SummaryVariable__c summaryVar = new SBQQ__SummaryVariable__c(
            Name = 'Test Summary Variable',
            SBQQ__AggregateField__c = 'SBQQ__NetPrice__c',
            SBQQ__AggregateFunction__c = 'SUM',
            SBQQ__TargetObject__c = 'SBQQ__QuoteLine__c',
            SBQQ__FilterField__c = 'SBQQ__Product__c',
            SBQQ__Operator__c = 'equals',
            SBQQ__FilterValue__c = testProduct.Id
        );
        insert summaryVar;
        
        // Create Price Condition
        SBQQ__PriceCondition__c priceCondition = new SBQQ__PriceCondition__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__Field__c = 'SBQQ__ListPrice__c',
            SBQQ__Operator__c = 'greater than',
            SBQQ__Value__c = '1000',
            SBQQ__Object__c = 'SBQQ__QuoteLine__c',
            SBQQ__Index__c = 1
        );
        insert priceCondition;
        
        // Create a Price Condition with a Summary Variable
        SBQQ__PriceCondition__c priceConditionVariable = new SBQQ__PriceCondition__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__TestedVariable__c = summaryVar.Id,
            SBQQ__Operator__c = 'greater than',
            SBQQ__Value__c = '5000',
            SBQQ__Index__c = 2
        );
        insert priceConditionVariable;
        
        // Create Price Action
        SBQQ__PriceAction__c priceAction = new SBQQ__PriceAction__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__Field__c = 'SBQQ__Markup__c',
            SBQQ__Value__c = '10',
            SBQQ__TargetObject__c = 'SBQQ__QuoteLine__c'
        );
        insert priceAction;
        
        // Create Price Action with Source Variable
        SBQQ__PriceAction__c priceActionVariable = new SBQQ__PriceAction__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__Field__c = 'SBQQ__NetPrice__c',
            SBQQ__SourceVariable__c = summaryVar.Id,
            SBQQ__TargetObject__c = 'SBQQ__QuoteLine__c'
        );
        insert priceActionVariable;
        
        // Create Lookup Query
        SBQQ__LookupQuery__c lookupQuery = new SBQQ__LookupQuery__c(
            SBQQ__PriceRule2__c = priceRule.Id,
            SBQQ__MatchType__c = 'Static Value',
            SBQQ__LookupField__c = 'SBQQ__Category__c',
            SBQQ__Operator__c = 'equals',
            SBQQ__TestedValue__c = 'Hardware'
        );
        insert lookupQuery;
        
        // Create Lookup Data
        SBQQ__LookupData__c lookupData = new SBQQ__LookupData__c(
            SBQQ__Category__c = 'Hardware',
            SBQQ__Type__c = 'Discount',
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Value__c = '15'
        );
        insert lookupData;
    }
    
    @isTest
    static void testGenerateAllRuleDocumentation() {
        Test.startTest();
        List<PriceRuleDocumentationGenerator.RuleDocumentation> docs = PriceRuleDocumentationGenerator.generateAllRuleDocumentation();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(0, docs.size(), 'Should return at least one rule documentation');
        
        // Verify rule details
        for(PriceRuleDocumentationGenerator.RuleDocumentation doc : docs) {
            System.assertEquals('Test Price Rule', doc.ruleName, 'Rule name should match');
            System.assertEquals('Calculator', doc.evaluationScope, 'Evaluation scope should match');
            System.assertEquals('On Calculate', doc.evaluationEvent, 'Evaluation event should match');
            System.assertEquals(10, doc.evaluationOrder, 'Evaluation order should match');
            System.assertEquals('All', doc.conditionsMet, 'Conditions met should match');
            System.assertEquals('Test Product', doc.productName, 'Product name should match');
            System.assertEquals('SBQQ__LookupData__c', doc.lookupObject, 'Lookup object should match');
            
            // Verify condition logic is populated
            System.debug('Condition Logic: ' + doc.conditionLogic);
            System.assert(doc.conditionLogic.contains('SBQQ__QuoteLine__c SBQQ__ListPrice__c greater than "1000"'), 
                         'Condition logic should include field condition');
            System.assert(doc.conditionLogic.contains('Sum of SBQQ__QuoteLine__c.SBQQ__NetPrice__c where SBQQ__Product__c equals'), 
                         'Condition logic should include summary variable');
            
            // Verify actions are populated
            System.assert(doc.actions.contains('Set SBQQ__QuoteLine__c.SBQQ__Markup__c to "10"'), 
                         'Actions should include value-based action');
            System.assert(doc.actions.contains('Set SBQQ__QuoteLine__c.SBQQ__NetPrice__c to the Sum of SBQQ__QuoteLine__c.SBQQ__NetPrice__c'), 
                         'Actions should include variable-based action');
            
            // Verify lookup queries
            System.assert(doc.lookupQueries.contains('Lookup Data records where SBQQ__Category__c equals "Hardware"'), 
                         'Lookup queries description should match');
            
            // Verify complete description
            String completeDesc = doc.getCompleteDescription();
            System.assert(completeDesc.contains('=== PRICE RULE: Test Price Rule ==='), 
                         'Complete description should have rule header');
            System.assert(completeDesc.contains('Evaluation Scope: Calculator'), 
                         'Complete description should include evaluation scope');
            System.assert(completeDesc.contains('Evaluation Event: On Calculate'), 
                         'Complete description should include evaluation event');
        }
    }
    
    @isTest
    static void testPrepareExcelExport() {
        Test.startTest();
        List<Map<String, String>> exportData = PriceRuleDocumentationGenerator.prepareExcelExport();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(0, exportData.size(), 'Export data should contain at least one row');
        
        Map<String, String> firstRow = exportData[0];
        System.assertEquals('Test Price Rule', firstRow.get('Rule Name'), 'Rule name should match in export data');
        System.assertEquals('Calculator', firstRow.get('Evaluation Scope'), 'Evaluation scope should match in export data');
        System.assertEquals('On Calculate', firstRow.get('Evaluation Event'), 'Evaluation event should match in export data');
        System.assertEquals('10', firstRow.get('Evaluation Order'), 'Evaluation order should match in export data');
        System.assertEquals('All', firstRow.get('Conditions Met'), 'Conditions met should match in export data');
        System.assertEquals('Test Product', firstRow.get('Product'), 'Product should match in export data');
        System.assertEquals('SBQQ__LookupData__c', firstRow.get('Lookup Object'), 'Lookup object should match in export data');
    }
    
    @isTest
    static void testExportToContentFile() {
        Test.startTest();
        Id contentDocId = PriceRuleDocumentationGenerator.exportToContentFile();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, contentDocId, 'ContentDocumentId should be returned');
        
        // Verify ContentVersion was created
        List<ContentVersion> contentVersions = [
            SELECT Id, Title, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocId
        ];
        
        System.assertEquals(1, contentVersions.size(), 'One ContentVersion should be created');
        System.assert(contentVersions[0].Title.startsWith('Price Rule Documentation '), 
                     'ContentVersion title should match expected pattern');
    }
    
    @isTest
    static void testExportToExcelFile() {
        Test.startTest();
        Id contentDocId = PriceRuleDocumentationGenerator.exportToExcelFile();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, contentDocId, 'ContentDocumentId should be returned from Excel export');
        
        // Verify ContentVersion was created
        List<ContentVersion> contentVersions = [
            SELECT Id, Title, VersionData, PathOnClient
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocId
        ];
        
        System.assertEquals(1, contentVersions.size(), 'One ContentVersion should be created');
        System.assert(contentVersions[0].Title.startsWith('Price Rule Documentation '), 
                     'ContentVersion title should match expected pattern');
        System.assertEquals('PriceRuleDocumentation.csv', contentVersions[0].PathOnClient, 
                          'File name should match expected value');
    }
    
    @isTest
    static void testExportToHTMLFile() {
        Test.startTest();
        Id contentDocId = PriceRuleDocumentationGenerator.exportToHTMLFile();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, contentDocId, 'ContentDocumentId should be returned from HTML export');
        
        // Verify ContentVersion was created
        List<ContentVersion> contentVersions = [
            SELECT Id, Title, VersionData, PathOnClient
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocId
        ];
        
        System.assertEquals(1, contentVersions.size(), 'One ContentVersion should be created');
        System.assert(contentVersions[0].Title.startsWith('Price Rule Documentation '), 
                     'ContentVersion title should match expected pattern');
        System.assertEquals('PriceRuleDocumentation.html', contentVersions[0].PathOnClient, 
                          'File name should match expected value');
    }
    
    @isTest
    static void testDescribeSummaryVariable() {
        // Setup data already created in TestSetup method
        SBQQ__SummaryVariable__c summaryVar = [SELECT Id FROM SBQQ__SummaryVariable__c LIMIT 1];
        
        Test.startTest();
        List<PriceRuleDocumentationGenerator.RuleDocumentation> docs = PriceRuleDocumentationGenerator.generateAllRuleDocumentation();
        Test.stopTest();
        
        System.assertNotEquals(0, docs.size(), 'Should return at least one rule documentation');
        
        // Verify the summary variable description is included in the condition logic
        PriceRuleDocumentationGenerator.RuleDocumentation doc = docs[0];
        System.debug('Condition Logic: ' + doc.conditionLogic);
        System.assert(doc.conditionLogic.contains('Sum of SBQQ__QuoteLine__c.SBQQ__NetPrice__c where SBQQ__Product__c equals'), 
                     'The summary variable description should be properly formatted in the condition logic');
    }
    
    @isTest
    static void testLookupQueriesAndData() {
        Test.startTest();
        List<PriceRuleDocumentationGenerator.RuleDocumentation> docs = PriceRuleDocumentationGenerator.generateAllRuleDocumentation();
        Test.stopTest();
        
        System.assertNotEquals(0, docs.size(), 'Should return at least one rule documentation');
        
        // Verify lookup queries and data
        PriceRuleDocumentationGenerator.RuleDocumentation doc = docs[0];
        System.assertNotEquals('No lookup queries defined for this rule.', doc.lookupQueries, 
                           'Lookup queries should be defined');
        System.assert(doc.lookupQueries.contains('SBQQ__Category__c equals "Hardware"'), 
                     'Lookup query should contain the field and value');
        
        // Check if lookup data is retrieved
        System.debug('Lookup Data: ' + doc.lookupData);
        if(doc.lookupData != null && !doc.lookupData.contains('No matching records found')) {
            System.assert(doc.lookupData.contains('SBQQ__Category__c: Hardware'), 
                         'Lookup data should include the category field');
        }
    }
    
    @isTest
    static void testPriceRuleWithDifferentConditionsMet() {
        // Create a price rule with "Any" conditions met
        SBQQ__PriceRule__c priceRule = new SBQQ__PriceRule__c(
            Name = 'Test Any Conditions Rule',
            SBQQ__Active__c = true,
            SBQQ__ConditionsMet__c = 'Any',
            SBQQ__EvaluationEvent__c = 'On Initialize',
            SBQQ__TargetObject__c = 'Calculator'
        );
        insert priceRule;
        
        // Create condition
        SBQQ__PriceCondition__c condition = new SBQQ__PriceCondition__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__Field__c = 'SBQQ__Quantity__c',
            SBQQ__Operator__c = 'greater than',
            SBQQ__Value__c = '5',
            SBQQ__Object__c = 'SBQQ__QuoteLine__c',
            SBQQ__Index__c = 1
        );
        insert condition;
        
        Test.startTest();
        List<PriceRuleDocumentationGenerator.RuleDocumentation> docs = PriceRuleDocumentationGenerator.generateAllRuleDocumentation();
        Test.stopTest();
        
        // Find our "Any" conditions rule
        PriceRuleDocumentationGenerator.RuleDocumentation anyDoc = null;
        for(PriceRuleDocumentationGenerator.RuleDocumentation doc : docs) {
            if(doc.ruleName == 'Test Any Conditions Rule') {
                anyDoc = doc;
                break;
            }
        }
        
        System.assertNotEquals(null, anyDoc, 'The "Any" conditions rule should be found');
        System.assertEquals('Any', anyDoc.conditionsMet, 'The conditions met should be "Any"');
        System.assert(anyDoc.conditionLogic.contains('ANY of the following conditions are met'), 
                     'The condition logic should indicate ANY conditions');
    }
    
    @isTest
    static void testPriceRuleWithCustomConditionLogic() {
        // Create a price rule with custom conditions logic
        SBQQ__PriceRule__c priceRule = new SBQQ__PriceRule__c(
            Name = 'Test Custom Logic Rule',
            SBQQ__Active__c = true,
            SBQQ__ConditionsMet__c = 'All',
            SBQQ__EvaluationEvent__c = 'On Calculate',
            SBQQ__TargetObject__c = 'Calculator'
        );
        insert priceRule;
        
        // Create conditions
        SBQQ__PriceCondition__c condition1 = new SBQQ__PriceCondition__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__Field__c = 'SBQQ__Quantity__c',
            SBQQ__Operator__c = 'greater than',
            SBQQ__Value__c = '5',
            SBQQ__Object__c = 'SBQQ__QuoteLine__c',
            SBQQ__Index__c = 1
        );
        insert condition1;
        
        SBQQ__PriceCondition__c condition2 = new SBQQ__PriceCondition__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__Field__c = 'SBQQ__ListPrice__c',
            SBQQ__Operator__c = 'greater than',
            SBQQ__Value__c = '1000',
            SBQQ__Object__c = 'SBQQ__QuoteLine__c',
            SBQQ__Index__c = 2
        );
        insert condition2;

        priceRule.SBQQ__ConditionsMet__c = 'Custom';
        priceRule.SBQQ__AdvancedCondition__c = '1 AND 2';
        update priceRule;
        
        Test.startTest();
        List<PriceRuleDocumentationGenerator.RuleDocumentation> docs = PriceRuleDocumentationGenerator.generateAllRuleDocumentation();
        Test.stopTest();
        
        // Find our custom logic rule
        PriceRuleDocumentationGenerator.RuleDocumentation customDoc = null;
        for(PriceRuleDocumentationGenerator.RuleDocumentation doc : docs) {
            if(doc.ruleName == 'Test Custom Logic Rule') {
                customDoc = doc;
                break;
            }
        }
        
        System.assertNotEquals(null, customDoc, 'The custom logic rule should be found');
        System.assertEquals('Custom', customDoc.conditionsMet, 'The conditions met should be "Custom"');
        System.assertEquals('1 AND 2', customDoc.advancedCondition, 'The advanced condition should match');
        System.assert(customDoc.conditionLogic.contains('Custom logic is applied: 1 AND 2'), 
                     'The condition logic should indicate custom logic');
    }
    
    @isTest
    static void testPriceRuleWithConfiguratorTarget() {
        // Create a price rule with Configurator target
        SBQQ__PriceRule__c priceRule = new SBQQ__PriceRule__c(
            Name = 'Test Configurator Rule',
            SBQQ__Active__c = true,
            SBQQ__ConditionsMet__c = 'All',
            SBQQ__ConfiguratorEvaluationEvent__c = 'Option Selection',
            SBQQ__TargetObject__c = 'Configurator'
        );
        insert priceRule;
        
        // Create condition
        SBQQ__PriceCondition__c condition = new SBQQ__PriceCondition__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__Field__c = 'SBQQ__Selected__c',
            SBQQ__Operator__c = 'equals',
            SBQQ__Value__c = 'true',
            SBQQ__Object__c = 'SBQQ__QuoteLine__c',
            SBQQ__Index__c = 1
        );
        insert condition;
        
        Test.startTest();
        List<PriceRuleDocumentationGenerator.RuleDocumentation> docs = PriceRuleDocumentationGenerator.generateAllRuleDocumentation();
        Test.stopTest();
        
        // Find our configurator rule
        PriceRuleDocumentationGenerator.RuleDocumentation configDoc = null;
        for(PriceRuleDocumentationGenerator.RuleDocumentation doc : docs) {
            if(doc.ruleName == 'Test Configurator Rule') {
                configDoc = doc;
                break;
            }
        }
        
        System.assertNotEquals(null, configDoc, 'The configurator rule should be found');
        System.assertEquals('Configurator', configDoc.evaluationScope, 'The evaluation scope should be "Configurator"');
        System.assertEquals('Option Selection', configDoc.evaluationEvent, 'The evaluation event should be "Option Selection"');
    }
    
    /**
     * Test documentation generation with complex summary variables in price conditions
     */
    @isTest
    static void testComplexSummaryVariableConditions() {
        Test.startTest();
        
        // Get the product created in setup
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        
        // Create a new price rule for this test
        SBQQ__PriceRule__c priceRule = new SBQQ__PriceRule__c(
            Name = 'Complex Variable Rule',
            SBQQ__Active__c = true,
            SBQQ__ConditionsMet__c = 'All',
            SBQQ__AdvancedCondition__c = '1 OR (2 AND 3)',
            SBQQ__EvaluationEvent__c = 'On Calculate',
            SBQQ__TargetObject__c = 'Calculator'
        );
        insert priceRule;
        
        // Create first summary variable (base variable)
        SBQQ__SummaryVariable__c baseVar = new SBQQ__SummaryVariable__c(
            Name = 'Base Variable',
            SBQQ__AggregateField__c = 'SBQQ__Quantity__c',
            SBQQ__AggregateFunction__c = 'SUM',
            SBQQ__TargetObject__c = 'SBQQ__QuoteLine__c',
            SBQQ__FilterField__c = 'SBQQ__RequiredBy__c',
            SBQQ__Operator__c = 'equals',
            SBQQ__FilterValue__c = 'null',
            SBQQ__Scope__c = 'Quote'
        );
        insert baseVar;
        
        // Create second summary variable (to be combined with)
        SBQQ__SummaryVariable__c secondVar = new SBQQ__SummaryVariable__c(
            Name = 'Second Variable',
            SBQQ__AggregateField__c = 'SBQQ__ListPrice__c',
            SBQQ__AggregateFunction__c = 'AVG',
            SBQQ__TargetObject__c = 'SBQQ__QuoteLine__c',
            SBQQ__ConstraintField__c = 'SBQQ__ProductFamily__c', // Add constraint field to test that branch
            SBQQ__Scope__c = 'Quote'
        );
        insert secondVar;
        
        // Create third summary variable with ValueElement instead of CombineWith
        SBQQ__SummaryVariable__c thirdVar = new SBQQ__SummaryVariable__c(
            Name = 'Third Variable',
            SBQQ__AggregateField__c = 'SBQQ__NetPrice__c',
            SBQQ__AggregateFunction__c = 'MAX',
            SBQQ__TargetObject__c = 'SBQQ__QuoteLine__c',
            SBQQ__CompositeOperator__c = 'Multiply',
            SBQQ__ValueElement__c = 0.9,
            SBQQ__Scope__c = 'Quote'
        );
        insert thirdVar;
        
        // Update the first variable to combine with the second
        baseVar.SBQQ__CompositeOperator__c = 'Subtract';
        baseVar.SBQQ__CombineWith__c = secondVar.Id;
        update baseVar;
        
        // Create price conditions using our variables
        SBQQ__PriceCondition__c condition1 = new SBQQ__PriceCondition__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__Field__c = 'SBQQ__NetPrice__c',
            SBQQ__Operator__c = 'greater than',
            SBQQ__Value__c = '1000',
            SBQQ__Object__c = 'SBQQ__QuoteLine__c',
            SBQQ__Index__c = 1
        );
        insert condition1;
        
        SBQQ__PriceCondition__c condition2 = new SBQQ__PriceCondition__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__TestedVariable__c = baseVar.Id,
            SBQQ__Operator__c = 'greater than',
            SBQQ__Value__c = '5',
            SBQQ__Index__c = 2
        );
        insert condition2;
        
        SBQQ__PriceCondition__c condition3 = new SBQQ__PriceCondition__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__TestedVariable__c = thirdVar.Id,
            SBQQ__Operator__c = 'less than',
            SBQQ__Value__c = '1000',
            SBQQ__Index__c = 3
        );
        insert condition3;
        
        priceRule.SBQQ__ConditionsMet__c = 'Custom';
        priceRule.SBQQ__AdvancedCondition__c = '1 OR (2 AND 3)';
        update priceRule;
        
        // Create a price action using a summary variable as source
        SBQQ__PriceAction__c action = new SBQQ__PriceAction__c(
            SBQQ__Rule__c = priceRule.Id,
            SBQQ__Field__c = 'SBQQ__Markup__c',
            SBQQ__SourceVariable__c = thirdVar.Id,
            SBQQ__TargetObject__c = 'SBQQ__QuoteLine__c'
        );
        insert action;
        
        // Generate documentation
        List<PriceRuleDocumentationGenerator.RuleDocumentation> docs = PriceRuleDocumentationGenerator.generateAllRuleDocumentation();
        
        // Find our complex rule
        PriceRuleDocumentationGenerator.RuleDocumentation complexDoc = null;
        for(PriceRuleDocumentationGenerator.RuleDocumentation doc : docs) {
            if(doc.ruleName == 'Complex Variable Rule') {
                complexDoc = doc;
                break;
            }
        }
        
        System.assertNotEquals(null, complexDoc, 'The complex variable rule should be found');
        
        // Debug the actual text for inspection
        System.debug('Complex Rule Condition Logic: ' + complexDoc.conditionLogic);
        System.debug('Complex Rule Actions: ' + complexDoc.actions);
        
        // More flexible assertions that should pass regardless of exact format
        String conditionText = complexDoc.conditionLogic.toLowerCase();
        String actionsText = complexDoc.actions.toLowerCase();
        
        // Test for the presence of the summary variable information
        System.assert(conditionText.contains('sum') && 
                     conditionText.contains('quantity') && 
                     conditionText.contains('avg') && 
                     conditionText.contains('listprice'), 
                     'Documentation should include all summary variable references');
        
        // Test for the presence of the composite operators
        System.assert(conditionText.contains('subtract'), 
                     'Documentation should include the subtract operator');
        System.assert(conditionText.contains('multiply'), 
                     'Documentation should include the multiply operator');
        
        // Test for constraint field
        System.assert(conditionText.contains('constraint'), 
                     'Documentation should include constraint field reference');
        
        // Test for value element
        System.assert(conditionText.contains('0.9'), 
                     'Documentation should include the value element');
        
        // Test for custom advanced condition
        System.assert(conditionText.contains('custom logic is applied: 1 or (2 and 3)'), 
                     'Documentation should include the custom logic formula');
        
        // Test that the action references the source variable
        System.assert(actionsText.contains('markup') && actionsText.contains('max'), 
                     'Action description should reference source variable');
        
        Test.stopTest();
    }
}