@isTest
public class GongCalloutInvocableTest {
    
    // Static variables for shared test data
    public static User adminUser;
    
    /**
* Mock class to simulate HTTP response for Gong API
*/
    public class MockGongApiResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success","message":"Contact assigned to Gong Flow"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
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
    
    @testSetup
    static void prepareTestData(){
        
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
    
    
    /**
* Test for successful API callout
*/
    @isTest
    static void testSuccessfulApiCallout() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Contact testContact = [Select Id from Contact where Email ='test.user@example.com' limit 1];
            
            GongCalloutInvocable.GongFlowInput gfi = new GongCalloutInvocable.GongFlowInput();
            gfi.contactId = testContact.Id;
            
            List<GongCalloutInvocable.GongFlowInput> gfinputs = new List<GongCalloutInvocable.GongFlowInput>();
            gfinputs.add(gfi);
            
            
            Test.setMock(HttpCalloutMock.class, new MockGongApiResponse());
            
            Test.startTest();
            List<GongCalloutInvocable.GongFlowOutput> gfOutput = GongCalloutInvocable.assignContactToGongFlow(gfinputs);
            Test.stopTest();
        }
    }
    
    
    /**
* Test for No parameters scenario
*/
    @isTest
    static void testNoParametersApiCallout() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            GongCalloutInvocable.GongFlowInput gfi = new GongCalloutInvocable.GongFlowInput();
            gfi.contactId = '';
            
            List<GongCalloutInvocable.GongFlowInput> gfinputs = new List<GongCalloutInvocable.GongFlowInput>();
            gfinputs.add(gfi);
            
            
            Test.setMock(HttpCalloutMock.class, new MockGongApiResponse());
            
            Test.startTest();
            try{
                List<GongCalloutInvocable.GongFlowOutput> gfOutput = GongCalloutInvocable.assignContactToGongFlow(gfinputs);
                List<GongCalloutInvocable.GongFlowOutput> gfOutputs = GongCalloutInvocable.assignContactToGongFlow(null);
            }catch(Exception e){
                System.debug('Exception occurred');
            }
            Test.stopTest();
        }
    }
    
    
    
    /**
* Test for API callout Failures
*/
    @isTest
    static void testFailureApiCallout() {
        System.runAs([SELECT Id FROM User WHERE Alias = 'adminusr' LIMIT 1][0]) {
            Contact testContact = [Select Id from Contact where Email ='test.user@example.com' limit 1];
            
            
            GongCalloutInvocable.GongFlowInput gfi = new GongCalloutInvocable.GongFlowInput();
            gfi.contactId = testContact.Id;
            GongCalloutInvocable.GongFlowInput gfi2 = new GongCalloutInvocable.GongFlowInput();
            gfi2.contactId = '00585883921';
            
            List<GongCalloutInvocable.GongFlowInput> gfinputs = new List<GongCalloutInvocable.GongFlowInput>();
            gfinputs.add(gfi);
            gfinputs.add(gfi2);
            
            
            
            Test.setMock(HttpCalloutMock.class, new MockGongApiResponse());
            
            Test.startTest();
            try{
            List<GongCalloutInvocable.GongFlowOutput> gfOutput = GongCalloutInvocable.assignContactToGongFlow(gfinputs);
            }catch(Exception e){
                System.debug('Exception Occurred');
            }
            Test.stopTest();
        }
    }
    
}