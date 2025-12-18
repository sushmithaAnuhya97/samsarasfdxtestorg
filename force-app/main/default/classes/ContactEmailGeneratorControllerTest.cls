@isTest
private class ContactEmailGeneratorControllerTest {
    
    // Static variables for shared test data
    public static User adminUser;

    // Helper to create a test Contact
    private static Contact createTestContact() {
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test.user@example.com'
        );
        insert c;
        return c;
    }

    // Mock implementation of the callout service
    private class MockWorkatoCalloutService implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"queued"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup
    static void setupData() {
        
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        adminUser = new User(
            Alias = 'adminusr',
            EmployeeNumber = '123',
            Email = 'adminusr@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'adminusr' + DateTime.now().getTime() + '@example.com'
        );
        insert adminUser;
        
        CRMA_TestDataUtility.assignPermissionSet(adminUser.Id, 'Gong_Smart_Flow');

        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
        createTestContact();
            
        }
    }

    @isTest
    static void testGenerateEmailForContact_Success() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Contact testContact = [SELECT Id FROM Contact LIMIT 1];
            Map<String, Object> logMap1 = ContactEmailGeneratorController.getLastLogStatus(testContact.Id);
            Test.setMock(HttpCalloutMock.class, new MockWorkatoCalloutService());

            Test.startTest();
            String result = ContactEmailGeneratorController.generateEmailForContact(testContact.Id);
            Test.stopTest();

            SamsaraLogEntries__c logentry = [Select Id from SamsaraLogEntries__c limit 1];
            logentry.Level__c = 'Warn';
            update logentry;
            Map<String, Object> logMap2 = ContactEmailGeneratorController.getLastLogStatus(testContact.Id);
            
            logentry.Level__c = 'Error';
            update logentry;
            Map<String, Object> logMap3 = ContactEmailGeneratorController.getLastLogStatus(testContact.Id);
            
            logentry.Level__c = 'Info';
            logentry.Exception_Type__c = 'Completed';
            update logentry;
            Map<String, Object> logMap4 = ContactEmailGeneratorController.getLastLogStatus(testContact.Id);
            
            Map<String, String> logentryStatusMap = ContactEmailGeneratorController.getLogEntryStatus(logentry.Id);
            try{
             Map<String, String> logentryStsMap = ContactEmailGeneratorController.getLogEntryStatus(null);   
            }catch(Exception ex){
                System.debug('Exception ccurred');
            }
            
            
            
            try{
                Map<String, Object> logMap5 = ContactEmailGeneratorController.getLastLogStatus(null);
            }catch(Exception ex){
                System.debug('Exception ccurred');
            }
            
            try{
            ContactEmailGeneratorController.validateContactForSmartFlow(null);
            ContactEmailGeneratorController.validateContactForSmartFlow(testContact.Id);
            testContact.Sales_Email_Opt_Out__c = true;
                update testContact;
            ContactEmailGeneratorController.validateContactForSmartFlow(testContact.Id);
            testContact.Email = '';   
                update testContact;
            ContactEmailGeneratorController.validateContactForSmartFlow(testContact.Id);
                
                testContact.Email = 'test@test.invalid';   
                update testContact;
            ContactEmailGeneratorController.validateContactForSmartFlow(testContact.Id);
            }catch(Exception error){
                system.debug(error.getMessage());
            }
        }
    }
    

    @isTest
    static void testGenerateEmailForContact_MissingId() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Map<String, String> config = ContactEmailGeneratorController.getGongDetails();
            try {
                Test.startTest();
                ContactEmailGeneratorController.generateEmailForContact(null);
                Test.stopTest();
            } catch (Exception ex) {
                System.debug('Exception occurred');
            }
        }
    }

    @isTest
    static void testMakeWorkatoCallout_Error() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            try {
                Test.startTest();
                WorkatoCalloutService.makeWorkatoCallout(null,null);
                Test.stopTest();
            } catch (Exception ex) {
                System.debug('Exception occurred');
            }
        }
    }
}