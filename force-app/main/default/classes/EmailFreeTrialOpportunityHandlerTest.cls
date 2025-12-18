@isTest
public class EmailFreeTrialOpportunityHandlerTest {
    
    @testSetup
    static void setupTestData() {

        insert new Global_Automation_Settings__c(Skip_Trigger__c = true, Skip_Validation_Rule__c = true);

        // Create test Account
        Account testAccount = new Account(Name = 'Testers 1 Inc',
            BillingStreet = '26 Napier Street',
            BillingCity = 'London',
            BillingPostalCode  = '1030',
            BillingCountry = 'United Kingdom',
            Billing_Email__c  = 'qdasdas@gmail.com',
            Organization_Size__c = '100 - 499',
            Industry = 'Other');
        insert testAccount;

        // Create test Opportunity
        Opportunity testOpportunity = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = testAccount.Id,
            Type = 'Revenue Opportunity',
            Name = 'Opp Testers 1 Inc',
            StageName = 'Decision',
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard',
            Send_Invoice__c = false));
        insert testOpportunity;

        // Create related Opportunity with StageName 'Closed Won' and Type 'Free Trial Opportunity'
        Opportunity relatedOpportunity = new Opportunity(
            Name = 'Related Opportunity',
            StageName = 'Closed Won',
            Type = 'Free Trial Opportunity',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            TrialResolutionOppty__c = testOpportunity.Id
        );
        insert relatedOpportunity;
    }

    @isTest
    static void testSendFreeTrialEmail() {
        // Retrieve the test Opportunity
        Opportunity testOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Opp Testers 1 Inc' LIMIT 1];

        // Call the method
        Test.startTest();
        EmailFreeTrialOpportunityHandler.sendFreeTrialEmail(new List<Id> { testOpportunity.Id });
        Test.stopTest();

        // Verify that the email was sent
        List<EmailMessage> sentEmails = [SELECT Id, Subject, HtmlBody FROM EmailMessage WHERE Subject LIKE '[Reminder] Return Needed for %'];
        System.assertEquals(1, sentEmails.size(), 'One email should have been sent.');
        System.assert(sentEmails[0].HtmlBody.contains('Testers 1 Inc'), 'Email body should contain the account name.');
        System.assert(sentEmails[0].HtmlBody.contains('Related Opportunity'), 'Email body should contain the related opportunity link.');
    }
}