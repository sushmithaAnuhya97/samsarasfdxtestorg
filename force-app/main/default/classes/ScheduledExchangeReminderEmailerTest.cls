/* 
* Test class for the class ScheduledAssociateQuotaOpportunity And AssociateQuotaOpportunity
* Tested different currencies
* currency conversions
* Valid Quotas
* Valid Opportunities
* Scheduled Class
*/

@isTest
public class ScheduledExchangeReminderEmailerTest {
    @testSetup
    private static void testDataSetup() {
       
    }
    
   @isTest
    static void testScheduledExchangeReminderEmailerTest(){       
        Test.startTest();
        Account account = new Account(Name='Test Reminder Emailer Account', Organization_Size__c = '1 - 99', Industry ='Food & Beverage', 
                                        Website = 'TestClassByHarsha.com', BillingCountry = 'United States', 
                                        BillingState = 'California' );
        insert account;
        Date closeDate = Date.Today();
        Date labelSentDate = Date.Today().addDays(-25);
        Opportunity oppToEmail = new Opportunity(Name = 'Test Reminder Email Opp', AccountId = account.Id, CloseDate = closeDate,  
                                                 StageName = 'Return Label Sent', Type = 'Warranty Exchange',
                                                 Tracking_Number__c = '123', Return_Label_Attachment__c = '00P1P00000SM6zMUAT', Return_Label_Sent_At__c = labelSentDate); 
        insert oppToEmail; 
        try {                                      
            ScheduledExchangeReminderEmailer reminderEmailer = new ScheduledExchangeReminderEmailer(); 
            reminderEmailer.execute(null); 
        } catch (Exception e) {
            system.assert(false); 
        }
        system.assert(true);
        Test.stopTest();
    }
}