@isTest
public class QuoteLineC360ControllerTest {
    
    // Bypass method to disable triggers during test data setup
    public static void bypass() {
        SBQQ.TriggerControl.disable();
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('B360LogicHandler');
    }
    
    // Helper method to create approval test data
    private static void createApprovalTestData(SBQQ__Quote__c quote) {
        // Create approval chain
        sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c(
            Name = 'Test Approval Chain',
            sbaa__TargetObject__c = 'SBQQ__Quote__c'
        );
        insert chain;
        
        // Create approver
        sbaa__Approver__c approver = new sbaa__Approver__c(
            Name = 'Test Approver',
            sbaa__User__c = UserInfo.getUserId()
        );
        insert approver;
        
        // Create approval rule with a name that matches our keywords
        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
            Name = 'DiscountApprovalNoDir - AVP',
            sbaa__TargetObject__c = 'SBQQ__Quote__c',
            sbaa__ApprovalChain__c = chain.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__ConditionsMet__c = 'Any',
            sbaa__Active__c = true,
            sbaa__Approver__c = approver.Id
        );
        insert rule;
        
        // Create approval condition (required for rule to be active)
        sbaa__ApprovalCondition__c condition = new sbaa__ApprovalCondition__c(
            sbaa__ApprovalRule__c = rule.Id,
            sbaa__FilterType__c = 'Value',
            sbaa__TestedField__c = 'SBQQ__Status__c',
            sbaa__Operator__c = 'equals',
            sbaa__FilterValue__c = 'Draft'
        );
        insert condition;
        
        // Create approval record that links quote to rule
        SBAA__Approval__c approval = new SBAA__Approval__c(
            Quote__c = quote.Id,
            sbaa__Rule__c = rule.Id,
            sbaa__ApprovalChain__c = chain.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__AssignedTo__c = UserInfo.getUserId(),
            sbaa__Approver__c = approver.Id,
            sbaa__RecordField__c = 'Quote__c',
            sbaa__Status__c = 'Pending'  // Changed from 'Requested' to 'Pending'
        );
        insert approval;
    }
    
    @isTest
    static void TestMethod1() {
        // Disable triggers/automation to prevent test failures
        bypass();
        
        Account acc = new Account(
            Name = 'Test Account 2831',
            Organization_Size__c = '1 - 99',
            BillingStreet = '123 Main St',
            BillingCity = 'San Francisco',
            BillingStateCode='TX',
            BillingPostalCode = '94110',
            BillingCountry = 'United States'
        );
        insert acc;

        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'LIC-TEST', Family = 'Test', IsActive = true);
        insert prod;
        

        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Quote', SBQQ__Account__c = acc.Id);
        insert quote;

        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = prod.Id,
            SBQQ__Discount__c = 50,
            C360_MUP__c = 0,
            SBQQ__ListPrice__c=200,
            Approval_Required__c = true
        );
        insert ql;

        // Create approval test data
        createApprovalTestData(quote);

        Test.startTest();
        QuoteLineC360Controller.getQuoteLines(quote.Id);
        Test.stopTest();
    }
    

}