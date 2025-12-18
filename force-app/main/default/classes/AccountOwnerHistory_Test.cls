@isTest
public class AccountOwnerHistory_Test {
    
    @testSetup
    static void setupData() {
        // --- Create User Roles ---
        UserRole adrRole = new UserRole(Name = 'Test ADR IB Role');
        insert adrRole;

        UserRole aeRole = new UserRole(Name = 'Test CML AE Role');
        insert aeRole;

        // --- Create Users ---
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u1 = new User(
            FirstName = 'Test',
            LastName = 'ADRUser',
            Email = 'testu1' + DateTime.now().getTime() + '@example.com',
            Username = 'testu1' + DateTime.now().getTime() + '@example.com',
            Alias = 'tu1',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = prof.Id,
            UserRoleId = adrRole.Id,
            EmployeeNumber = 'EMP-' + DateTime.now().getTime()
        );
        insert u1;

        User u2 = new User(
            FirstName = 'Test',
            LastName = 'AEUser',
            Email = 'testu2' + DateTime.now().getTime() + '@example.com',
            Username = 'testu2' + DateTime.now().getTime() + '@example.com',
            Alias = 'tu2',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = prof.Id,
            UserRoleId = aeRole.Id,
            EmployeeNumber = 'EMP-' + (DateTime.now().getTime() + 1)
        );
        insert u2;
    }
    
    @isTest
    static void testOwnerChangeWithADRTransferLog() {
        User u1 = [SELECT Id FROM User WHERE Alias = 'tu1' LIMIT 1]; // ADR IB user
        User u2 = [SELECT Id FROM User WHERE Alias = 'tu2' LIMIT 1]; // AE user

        // Step 1: Create account with AE user as owner
        Account acc = new Account(
            Name = 'Test Account',
            OwnerId = u2.Id,
            Organization_Size__c = '100 - 499',
            BillingCountry = 'India'
        );
        insert acc;

        // Step 2: Change owner to ADR IB user
        acc.OwnerId = u1.Id;
        acc.Overwrite_Validation_Rule__c = true;
        update acc;

        // Step 3: Create ADR Transfer Log record (minimal required fields)
        ADR_Transfer_Log__c adrLog = new ADR_Transfer_Log__c(
            OwnerId = u1.Id,
            Account__c = acc.Id
        );
        insert adrLog;

        // Step 4: Call apex method with Account Id + adrLog.CreatedDate
        AccountOwnerHistory.Request req = new AccountOwnerHistory.Request();
        req.accountId = acc.Id;
        req.checkDate = adrLog.CreatedDate;

        Test.startTest();
        List<AccountOwnerHistory.Response> resp = AccountOwnerHistory.checkOwner(
            new List<AccountOwnerHistory.Request>{req}
        );
        Test.stopTest();
    }
}