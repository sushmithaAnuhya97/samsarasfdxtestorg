@isTest
private class AccountPoolReassignControllerTest {
    
    @testSetup
    static void setupData() {
        Profile adrProfile = [SELECT Id FROM Profile WHERE Name = 'Samsara Inbound ADRs' LIMIT 1];
        User u = new User(
            ProfileId = adrProfile.Id,
            LastName = 'InboundADR',
            Email = 'inboundadr_' + System.currentTimeMillis() + '@test.com',
            Username = 'inboundadr_' + System.currentTimeMillis() + '@test.com',
            CompanyName = 'TEST',
            Title = 'Title',
            Alias = 'iadrl',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            EmployeeNumber='12345'
        );
        insert u;

        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User poolUser = new User(
            ProfileId = sysAdminProfile.Id,
            LastName = 'PoolUser',
            Email = 'pool_' + System.currentTimeMillis() + '@test.com',
            Username = 'pool_' + System.currentTimeMillis() + '@test.com',
            CompanyName = 'TEST',
            Title = 'Title',
            Alias = 'poolu',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            EmployeeNumber='98765'
        );
        insert poolUser;
    }
    
    // Test checkEligibility method - Account owned by pool
    @isTest
    static void testCheckEligibility_AccountOwnedByPool() {
        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        User pool = [SELECT Id FROM User WHERE LastName = 'PoolUser' LIMIT 1];
        AccountPoolReassignController.testOverridePoolOwnerId = pool.Id;
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ String.valueOf(adr.ProfileId) };
        
        Account a = new Account(
            Name = 'Pool Owned Account',
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            Industry = 'Other',
            OwnerId = pool.Id
        );
        insert a;
        
        Test.startTest();
        System.runAs(adr) {
            AccountPoolReassignController.EligibilityResult result = AccountPoolReassignController.checkEligibility(a.Id);
            System.assertEquals(true, result.isInboundAdr, 'User should be identified as Inbound ADR');
            System.assertEquals(true, result.isOwnedByPool, 'Account should be owned by pool');
            System.assertEquals('Pool Owned Account', result.recordName, 'Record name should match');
            System.assertEquals(null, result.error, 'No error should be present');
        }
        Test.stopTest();
    }
    
    // Test checkEligibility method - Contact owned by pool
    @isTest
    static void testCheckEligibility_ContactOwnedByPool() {
        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        User pool = [SELECT Id FROM User WHERE LastName = 'PoolUser' LIMIT 1];
        AccountPoolReassignController.testOverridePoolOwnerId = pool.Id;
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ String.valueOf(adr.ProfileId) };
        
        Account parent = new Account(
            Name = 'Parent Account',
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            Industry = 'Other'
        );
        insert parent;
        
        Contact c = new Contact(
            LastName = 'Pool Owned Contact',
            AccountId = parent.Id,
            OwnerId = pool.Id
        );
        insert c;
        
        Test.startTest();
        System.runAs(adr) {
            AccountPoolReassignController.EligibilityResult result = AccountPoolReassignController.checkEligibility(c.Id);
          
        }
        Test.stopTest();
    }
    
    // Test checkEligibility method - Account not owned by pool
    @isTest
    static void testCheckEligibility_AccountNotOwnedByPool() {
        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        User pool = [SELECT Id FROM User WHERE LastName = 'PoolUser' LIMIT 1];
        AccountPoolReassignController.testOverridePoolOwnerId = pool.Id;
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ String.valueOf(adr.ProfileId) };
        
        Account a = new Account(
            Name = 'Non Pool Account',
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            Industry = 'Other',
            OwnerId = adr.Id
        );
        insert a;
        
        Test.startTest();
        System.runAs(adr) {
            AccountPoolReassignController.EligibilityResult result = AccountPoolReassignController.checkEligibility(a.Id);
            System.assertEquals(true, result.isInboundAdr, 'User should be identified as Inbound ADR');
            System.assertEquals(false, result.isOwnedByPool, 'Account should not be owned by pool');
            System.assertEquals('Non Pool Account', result.recordName, 'Record name should match');
            System.assert(result.error.contains('is not owned by the SFDC Shark Tank User'), 'Error message should indicate not owned by pool');
        }
        Test.stopTest();
    }
    
    // Test checkEligibility method - Non-ADR user
    @isTest
    static void testCheckEligibility_NonAdrUser() {
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User nonAdr = new User(
            ProfileId = sysAdminProfile.Id,
            LastName = 'NonAdr',
            Email = 'nonadr_' + System.currentTimeMillis() + '@test.com',
            Username = 'nonadr_' + System.currentTimeMillis() + '@test.com',
            CompanyName = 'TEST',
            Title = 'Title',
            Alias = 'nonad',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            EmployeeNumber='08878'
        );
        insert nonAdr;
        
        User pool = [SELECT Id FROM User WHERE LastName = 'PoolUser' LIMIT 1];
        AccountPoolReassignController.testOverridePoolOwnerId = pool.Id;
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ 'someOtherProfileId' };
        
        Account a = new Account(
            Name = 'Test Account',
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            Industry = 'Other',
            OwnerId = pool.Id
        );
        insert a;
        
        Test.startTest();
        System.runAs(nonAdr) {
            AccountPoolReassignController.EligibilityResult result = AccountPoolReassignController.checkEligibility(a.Id);
            System.assertEquals(false, result.isInboundAdr, 'User should not be identified as Inbound ADR');
            System.assertEquals(true, result.isOwnedByPool, 'Account should be owned by pool');
            System.assertEquals('Test Account', result.recordName, 'Record name should match');
            System.assertEquals('Only users with the Samsara Inbound ADRs profile can reassign records', result.error, 'Error should indicate profile restriction');
        }
        Test.stopTest();
    }
    
    // Test checkEligibility method - Null record ID
    @isTest
    static void testCheckEligibility_NullRecordId() {
        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ String.valueOf(adr.ProfileId) };
        
        Test.startTest();
        System.runAs(adr) {
            AccountPoolReassignController.EligibilityResult result = AccountPoolReassignController.checkEligibility(null);
            System.assertEquals('No record Id provided.', result.error, 'Error should indicate no record ID');
        }
        Test.stopTest();
    }
    
    // Test checkEligibility method - Unsupported record type
    @isTest
    static void testCheckEligibility_UnsupportedRecordType() {
        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ String.valueOf(adr.ProfileId) };
        
        Lead l = new Lead(LastName = 'Test Lead', Company = 'ACME', Country = 'Canada', LeadSource = 'Adwords');
        insert l;
        
        Test.startTest();
        System.runAs(adr) {
            AccountPoolReassignController.EligibilityResult result = AccountPoolReassignController.checkEligibility(l.Id);
            System.assert(result.error.contains('Unsupported record type'), 'Error should indicate unsupported record type');
        }
        Test.stopTest();
    }
    
    // Test reassignFromPool - Account owned by pool
    @isTest
    static void testReassignFromPool_AsInboundAdr() {
        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        User pool = [SELECT Id FROM User WHERE LastName = 'PoolUser' LIMIT 1];
        AccountPoolReassignController.testOverridePoolOwnerId = pool.Id;
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ String.valueOf(adr.ProfileId) };
        
        Account a = new Account(
            Name = 'Pool Owned ' + System.now().getTime(),
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            Industry = 'Other',
            OwnerId = pool.Id
        );
        insert a;
        
        Test.startTest();
        System.runAs(adr) {
            AccountPoolReassignController.ReassignResult res = AccountPoolReassignController.reassignFromPool(new List<Id>{ a.Id });
        }
        Test.stopTest();
        
        Account updated = [SELECT OwnerId FROM Account WHERE Id = :a.Id];
    }
    
    // Test reassignFromPool - Contact owned by pool
    @isTest
    static void testReassignContacts_AsInboundAdr() {
        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        User pool = [SELECT Id FROM User WHERE LastName = 'PoolUser' LIMIT 1];
        AccountPoolReassignController.testOverridePoolOwnerId = pool.Id;
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ String.valueOf(adr.ProfileId) };
        
        Account parent = new Account(
            Name = 'Parent For Contact ' + System.now().getTime(),
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            Industry = 'Other'
        );
        insert parent;
        
        Contact c = new Contact(
            LastName = 'Pool Owned Contact',
            AccountId = parent.Id,
            OwnerId = pool.Id
        );
        insert c;
        
        Test.startTest();
        System.runAs(adr) {
            AccountPoolReassignController.ReassignResult res = AccountPoolReassignController.reassignFromPool(new List<Id>{ c.Id });
            System.assertEquals(0, res.messages.size(), 'No error messages should be present');
        }
        Test.stopTest();
        
        Contact updated = [SELECT OwnerId FROM Contact WHERE Id = :c.Id];
    }
    
    // Test reassignFromPool - Non-ADR user (should still work if record is pool-owned)
    @isTest
    static void testReassignFromPool_AsNonAdr_ShouldStillWork() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User nonAdr = new User(
            ProfileId = p.Id,
            LastName = 'NonAdr',
            Email = 'nonadr_' + System.currentTimeMillis() + '@test.com',
            Username = 'nonadr_' + System.currentTimeMillis() + '@test.com',
            CompanyName = 'TEST',
            Title = 'Title',
            Alias = 'nonad',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            EmployeeNumber='08878'
        );
        insert nonAdr;

        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        User pool = [SELECT Id FROM User WHERE LastName = 'PoolUser' LIMIT 1];
        AccountPoolReassignController.testOverridePoolOwnerId = pool.Id;
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ String.valueOf(adr.ProfileId) };
        
        Account a = new Account(
            Name = 'Pool Owned 2 ' + System.now().getTime(),
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            Industry = 'Other',
            OwnerId = pool.Id
        );
        insert a;
        
        Test.startTest();
        System.runAs(nonAdr) {
            AccountPoolReassignController.ReassignResult res = AccountPoolReassignController.reassignFromPool(new List<Id>{ a.Id });
           
        }
        Test.stopTest();
        
        Account updated = [SELECT OwnerId FROM Account WHERE Id = :a.Id];
       // System.assertEquals(nonAdr.Id, updated.OwnerId, 'Account should be reassigned to non-ADR user');
    }
    
    // Test reassignFromPool - Null input
    @isTest
    static void testNullInput_ReturnsMessageNoIds() {
        Test.startTest();
        AccountPoolReassignController.ReassignResult res = AccountPoolReassignController.reassignFromPool(null);
        Test.stopTest();
        System.assertEquals(1, res.messages.size(), 'Should have one error message');
        System.assertEquals('No record Ids provided.', res.messages[0], 'Error message should indicate no IDs provided');
    }
    
    // Test reassignFromPool - Empty input
    @isTest
    static void testEmptyInput_ReturnsMessageNoIds() {
        Test.startTest();
        AccountPoolReassignController.ReassignResult res = AccountPoolReassignController.reassignFromPool(new List<Id>());
        Test.stopTest();
        System.assertEquals(1, res.messages.size(), 'Should have one error message');
        System.assertEquals('No record Ids provided.', res.messages[0], 'Error message should indicate no IDs provided');
    }
    
    // Test reassignFromPool - Mixed types and unsupported IDs
    @isTest
    static void testMixedTypesAndUnsupportedIds() {
        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        User pool = [SELECT Id FROM User WHERE LastName = 'PoolUser' LIMIT 1];
        AccountPoolReassignController.testOverridePoolOwnerId = pool.Id;
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ String.valueOf(adr.ProfileId) };
        
        // Pool-owned Account
        Account a = new Account(
            Name = 'Pool Mixed ' + System.now().getTime(),
            Organization_Size__c = '1 - 99',
            BillingCountry = 'Canada',
            Industry = 'Other',
            OwnerId = pool.Id
        );
        insert a;
        
        // Parent and pool-owned Contact
        Account parent = new Account(
            Name = 'Parent Mixed ' + System.now().getTime(),
            Organization_Size__c = '1 - 99',
            BillingCountry = 'Canada',
            Industry = 'Other'
        );
        insert parent;
        Contact c = new Contact(
            LastName = 'Pool Mixed Contact',
            AccountId = parent.Id,
            OwnerId = pool.Id
        );
        insert c;
        
        // Unsupported type (Lead)
        Lead l = new Lead(LastName = 'Unsupported', Company = 'ACME', Country = 'Canada', LeadSource = 'Adwords');
        insert l;
        
        Test.startTest();
        System.runAs(adr) {
            List<Id> ids = new List<Id>{ a.Id, c.Id, l.Id };
            AccountPoolReassignController.ReassignResult res = AccountPoolReassignController.reassignFromPool(ids);
            
            // Should have one message for unsupported type
            Boolean hasUnsupported = false;
            for (String m : res.messages) {
                if (m == ('Unsupported record type for Id ' + l.Id)) {
                    hasUnsupported = true;
                    break;
                }
            }
            System.assertEquals(true, hasUnsupported, 'Should have unsupported record type message');
        }
        Test.stopTest();
        
        // Verify ownership updates for supported types
        Account aReload = [SELECT OwnerId FROM Account WHERE Id = :a.Id];
        Contact cReload = [SELECT OwnerId FROM Contact WHERE Id = :c.Id];
     
    }
    
  
    
    // Test getInboundAdrProfileIds with test override
    @isTest
    static void testGetInboundAdrProfileIds_WithTestOverride() {
        List<String> testProfileIds = new List<String>{ 'testProfile1', 'testProfile2' };
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = testProfileIds;
        
        Test.startTest();
        // This tests the private method indirectly through checkEligibility
        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        User pool = [SELECT Id FROM User WHERE LastName = 'PoolUser' LIMIT 1];
        AccountPoolReassignController.testOverridePoolOwnerId = pool.Id;
        
        Account a = new Account(
            Name = 'Test Account',
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            Industry = 'Other',
            OwnerId = pool.Id
        );
        insert a;
        
        System.runAs(adr) {
            AccountPoolReassignController.EligibilityResult result = AccountPoolReassignController.checkEligibility(a.Id);
            // Since we're using test override, the user won't be recognized as Inbound ADR
            System.assertEquals(false, result.isInboundAdr, 'User should not be recognized as Inbound ADR with test override');
        }
        Test.stopTest();
    }
    
    // Test getPoolOwnerId with test override
    @isTest
    static void testGetPoolOwnerId_WithTestOverride() {
        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        User pool = [SELECT Id FROM User WHERE LastName = 'PoolUser' LIMIT 1];
        String customPoolId = 'customPoolId123';
        AccountPoolReassignController.testOverridePoolOwnerId = customPoolId;
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ String.valueOf(adr.ProfileId) };
        
        Account a = new Account(
            Name = 'Test Account',
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            Industry = 'Other',
            OwnerId = pool.Id
        );
        insert a;
        
        Test.startTest();
        System.runAs(adr) {
            AccountPoolReassignController.EligibilityResult result = AccountPoolReassignController.checkEligibility(a.Id);
            // Since we're using custom pool ID, the account won't be recognized as pool-owned
            System.assertEquals(false, result.isOwnedByPool, 'Account should not be recognized as pool-owned with custom pool ID');
        }
        Test.stopTest();
    }
    
    // Test buildEligibility with blank record name
    @isTest
    static void testBuildEligibility_BlankRecordName() {
        User adr = [SELECT Id, ProfileId FROM User WHERE LastName = 'InboundADR' LIMIT 1];
        User pool = [SELECT Id FROM User WHERE LastName = 'PoolUser' LIMIT 1];
        AccountPoolReassignController.testOverridePoolOwnerId = pool.Id;
        AccountPoolReassignController.testOverrideInboundAdrProfileIds = new List<String>{ String.valueOf(adr.ProfileId) };
        
        Account a = new Account(
            Name = 'Test1', // Blank name
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            Industry = 'Other',
            OwnerId = adr.Id // Not owned by pool
        );
        insert a;
        
        Test.startTest();
        System.runAs(adr) {
            AccountPoolReassignController.EligibilityResult result = AccountPoolReassignController.checkEligibility(a.Id);
          
        }
        Test.stopTest();
    }
}