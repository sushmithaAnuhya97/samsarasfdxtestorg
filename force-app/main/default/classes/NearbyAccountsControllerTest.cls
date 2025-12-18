/**
* @File Name : NearbyAccountsControllerTest.cls
* @Description :Test class used to cover NearbyAccountsController
* @Author : Vigneshwaran Durairaj
* @Last Modified By : June 3, 2025
* @Last Modified On : June 3, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 3, 2025 |   | Initial Version
**/

@isTest
public class NearbyAccountsControllerTest {
    @testSetup
    static void setup() {
        // Create test Accounts
        List<Account> accounts = new List<Account>();
        Account acc = new Account(
            Name = 'Test', 
            Organization_Size__c = '5000+', 
            BillingCountry = 'Canada', 
            Industry = 'Construction'
        );
        accounts.add(acc);
        insert accounts;
    }

    @isTest
    static void testGetNearbyAccounts() {
        Map<String, Object> params = new Map<String, Object>{
            'userLat' => 37.7749,
            'userLon' => -122.4194,
            'radiusMiles' => 10,
			'accountTypeFilter' => new List<String>{'all_near_me', 'all_customers', 'prospects_with_pipeline'},
			'ownerFilter' => new List<String>{'005WR000002IQXZYA4'}  // Multiple User IDs
        };
            
        Map<String, Object> sessionData = new Map<String, Object>{
    'deviceType' => 'Desktop',           // String: 'Desktop', 'Mobile', 'Tablet', 'Unknown'
    'formFactor' => 'Large',             // String: 'Large', 'Medium', 'Small'
    'userAgent' => 'Mozilla/5.0...',     // String: Browser user agent
    'timestamp' => '2025-01-01T00:00:00.000Z'  // String: ISO timestamp
};
    	String sessionLogId = 'a0XWD00000A1B2C3D4E5F';  // SamsaraLog__c record ID from createUserSession
        String action = 'Filter Change';                 // String: Action name
        Map<String, Object> details = new Map<String, Object>{
            'filterType' => 'Account Type',
            'oldValue' => 'all_near_me',
            'newValue' => 'all_customers'
        };
            
            String detailsJson = '{"result": "Found 5 accounts"}';  // String: JSON serialized details
        Test.startTest();
        List<Account> results = NearbyAccountsController.getNearbyAccounts(params);
        String recordId = NearbyAccountsController.createUserSession(sessionData);
        NearbyAccountsController.addLogEntryToSession(sessionLogId,action,details);
        NearbyAccountsController.processLogEntryAsync(sessionLogId,action,detailsJson);
        Test.stopTest();
    }

    @isTest
    static void testGetNearbyAccounts_AllBranches() {
        // Test Decimal and String for userLat, userLon, radiusMiles
        Map<String, Object> paramsDecimal = new Map<String, Object>{
            'userLat' => Decimal.valueOf('37.7749'),
            'userLon' => Decimal.valueOf('-122.4194'),
            'radiusMiles' => Decimal.valueOf('10'),
			'accountTypeFilter' => new List<String>{'all_near_me', 'all_customers', 'prospects_with_pipeline'},
			'ownerFilter' => new List<String>{'005WR000002IQXZYA4'}  // Multiple User IDs
        };
        Map<String, Object> paramsString = new Map<String, Object>{
            'userLat' => '37.7749',
            'userLon' => '-122.4194',
            'radiusMiles' => '10',
			'accountTypeFilter' => new List<String>{'all_near_me', 'all_customers', 'prospects_with_pipeline'},
			'ownerFilter' => new List<String>{'005WR000002IQXZYA4'}  // Multiple User IDs
        };
        Test.startTest();
        List<Account> results1 = NearbyAccountsController.getNearbyAccounts(paramsDecimal);
        List<Account> results2 = NearbyAccountsController.getNearbyAccounts(paramsString);
        Test.stopTest();

        // Test all accountTypeFilter branches
        List<String> filters = new List<String>{
            'customers_with_pipeline',
            'all_customers',
            'prospects_with_pipeline',
            'customers_without_pipeline',
            'all_with_pipeline'
        }; 
        for (String filter : filters) {
            Map<String, Object> p = new Map<String, Object>{
                'userLat' => 37.7749,
                'userLon' => -122.4194,
                'radiusMiles' => 10,
                'accountTypeFilter' => filter,
				'ownerFilter' => new List<String>{'005WR000002IQXZYA4'}  // Multiple User IDs
            };
            List<Account> r = NearbyAccountsController.getNearbyAccounts(p);
        }

        // Test city, state, segment, industry, csSentiment
        Map<String, Object> paramsFilters = new Map<String, Object>{
            'userLat' => 37.7749,
            'userLon' => -122.4194,
            'radiusMiles' => 10,
            'city' => 'San Francisco',
            'state' => 'CA',
            'segment' => 'A',
            'industry' => 'Tech',
            'csSentiment' => 'Green',
			'accountTypeFilter' => new List<String>{'all_near_me', 'all_customers', 'prospects_with_pipeline'},
			'ownerFilter' => new List<String>{'005WR000002IQXZYA4'}  // Multiple User IDs
        };
        List<Account> results3 = NearbyAccountsController.getNearbyAccounts(paramsFilters);
        NearbyAccountsController.getAllSubordinateUserIds();
    }

    // Mock for Google API callouts
    class GoogleApiMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"OK","predictions":[{"description":"Test Place","place_id":"123"}]}');
            return res;
        }
    }

    @isTest
    static void testGetGooglePlaceSuggestions() {
        Test.setMock(HttpCalloutMock.class, new GoogleApiMock());
        Test.startTest();
        String response = NearbyAccountsController.getGooglePlaceSuggestions('San Francisco');
        Test.stopTest();
        System.assert(response.contains('OK'), 'Should return OK status');
    }

    class GoogleDetailsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"OK","result":{"formatted_address":"Test Address","geometry":{"location":{"lat":37.7749,"lng":-122.4194}}}}');
            return res;
        }
    }

    @isTest
    static void testGetGooglePlaceDetails() {
        Test.setMock(HttpCalloutMock.class, new GoogleDetailsMock());
        Test.startTest();
        String response = NearbyAccountsController.getGooglePlaceDetails('123');
        Test.stopTest();
        System.assert(response.contains('OK'), 'Should return OK status');
    }
}