@isTest
public class ScheduledFreeTrialInvoicesTest {
    
    @testSetup
    private static void testDataSetup() {
         
         Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', ADR_Transfer__c = false);
         insert account;
                
         Contact contact = new Contact(AccountId = account.Id, FirstName = 'Cntc', LastName = 'Test', Source__c = 'Facebook Form', Email='test@test.com');  
         insert contact;
        
         Opportunity opportunity = new Opportunity(Name='Oppty 1', CloseDate = System.Today(), AccountId = account.Id, StageName='Decision', Trial_Primary_Contact__c = contact.Id);
         insert opportunity;    
    }
    
    @isTest
    static void testScheduledJob(){
        Datetime futureTime = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 ' + String.valueOf(futureTime.minute()) + ' ' + String.valueOf(futureTime.hour()) + ' ' + String.valueOf(futureTime.day()) + ' ' + String.valueOf(futureTime.month()) + ' ? ' + String.valueOf(futureTime.year());
        String jobId = System.schedule('ScheduledFreeTrialInvoices', CRON_EXP, new ScheduledFreeTrialInvoices());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assert(ct.NextFireTime > Datetime.now());
    }

}