/**
 * Created by vikasmishra on 2021-10-04.
 */

@IsTest
private class AsyncRequestQueueableTest {

    @IsTest
    static void should_update_all_accounts(){
        // Arrange
        AsyncRequestQueueable.requestHandlers = new Map<String, Type>{
                new SampleJobAsync().getRequestType() => SampleJobAsync.class
        };
        List<Account> newAccounts = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        newAccounts.add(account);

        insert newAccounts;

        // Act

        Test.startTest();
        Set<Id> accIds = new Map<Id, Account>(newAccounts).keySet();
        insert new SampleJobAsync().prepareAsyncRequests(accIds);
        Test.stopTest();

        // Assert

        List<Account> updatedAccounts = [
                SELECT Id, Description
                FROM Account
        ];

        System.assertEquals(1, updatedAccounts.size(), 'Expected 1 account in the system');

        for(Account acc : updatedAccounts){
            System.assert(acc.Description.startsWith('Updated: '), 'Expected all accounts descriptions to be updated with "Updated: xxx" string');
        }
    }

    @IsTest
    static void shouldRunRetryLogic(){
        // Arrange
        AsyncRequestQueueable.requestHandlers = new Map<String, Type>{
                new SampleJobAsyncWithExceptionsRowLock().getRequestType() => SampleJobAsyncWithExceptionsRowLock.class
        };

        // Act

        Test.startTest();
       try{
           insert new SampleJobAsyncWithExceptionsRowLock().prepareAsyncRequests(new Set<Id>{generateId(Account.SObjectType, 101)});
       }
       catch (Exception ex){

       }

        Test.stopTest();

    }

    @IsTest
    static void shouldNotRunRetryLogic(){
        // Arrange
        AsyncRequestQueueable thisQueue = new AsyncRequestQueueable();
        AsyncRequestQueueable.requestHandlers = new Map<String, Type>{
                new SampleJobAsyncWithExceptionsRowLock().getRequestType() => SampleJobAsyncWithExceptionsNoRowLock.class
        };
        List<Account> newAccounts = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        newAccounts.add(account);

        insert newAccounts;

        // Act

        Test.startTest();
        Set<Id> accIds = new Map<Id, Account>(newAccounts).keySet();
            insert new SampleJobAsyncWithExceptionsNoRowLock().prepareAsyncRequests(accIds);

        Test.stopTest();

    }

    @IsTest
    static void shouldRunIgnoringOwner(){

        // Arrange
        AsyncRequestQueueable.requestHandlers = new Map<String, Type>{
            new SampleJobAsync().getRequestType() => SampleJobAsync.class
        };
        List<Account> newAccounts = new List<Account>();
        Account account = new Account (
            Name = 'Test Account',
            Organization_Size__c = '5000+',
            BillingCountry = 'Canada',
            Industry = 'Other',
            Credit_Limit__c = 10000,
            OwnerId = [SELECT Id FROM User WHERE isActive = true AND Id != :UserInfo.getUserId() LIMIT 1].Id
        );
        newAccounts.add(account);

        insert newAccounts;

        // Act
        AsyncRequestQueueable.startJob(false);

        Set<Id> accIds = new Map<Id, Account>(newAccounts).keySet();
        Async_Request__c req = new SampleJobAsync().prepareAsyncRequests(accIds)[0];
        insert req;
        Test.setCreatedDate(req.Id, System.now().addHours(-6));

        // This is required for testing, as the queueables in place will run on stopTest()
        Test.startTest();
        Test.stopTest();

        // Assert
        List<Account> updatedAccounts = [
            SELECT Id, Description
            FROM Account
        ];

        System.assertEquals(1, updatedAccounts.size(), 'Expected 1 account in the system');

        for(Account acc : updatedAccounts){
            System.assert(acc.Description.startsWith('Updated: '), 'Expected all accounts descriptions to be updated with "Updated: xxx" string');
        }
    }

    @isTest
    static void runSchedulableRoutine(){
        // Arrange
        AsyncRequestQueueable.requestHandlers = new Map<String, Type>{
            new SampleJobAsync().getRequestType() => SampleJobAsync.class
        };
        List<Account> newAccounts = new List<Account>();
        Account account = new Account (
            Name = 'Test Account',
            Organization_Size__c = '5000+',
            BillingCountry = 'Canada',
            Industry = 'Other',
            Credit_Limit__c = 10000,
            OwnerId = [SELECT Id FROM User WHERE isActive = true AND Id != :UserInfo.getUserId() LIMIT 1].Id
        );
        newAccounts.add(account);

        insert newAccounts;

        Set<Id> accIds = new Map<Id, Account>(newAccounts).keySet();
        Async_Request__c req = new SampleJobAsync().prepareAsyncRequests(accIds)[0];
        insert req;
        Test.setCreatedDate(req.Id, System.now().addHours(-6));

        Test.startTest();
        (new AsyncRequestQueueable(false, 0));
        System.schedule('Async job', '0 0 * ? * * *', new AsyncRequestSchedulable());
        Test.stopTest();

        // Assert
        List<Account> updatedAccounts = [
            SELECT Id, Description
            FROM Account
        ];

        System.assertEquals(1, updatedAccounts.size(), 'Expected 1 account in the system');

        for(Account acc : updatedAccounts){
            System.assert(acc.Description.startsWith('Updated: '), 'Expected all accounts descriptions to be updated with "Updated: xxx" string');
        }
    }

    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }

    /**
 * Sample job that does something dumb.
 * It sets the Account.Description to current execution time.
 */
    public without sharing class SampleJobAsync extends BaseAsyncHandler {

        public override String getRequestType(){
            return 'Sample Job';
        }

        public override void execute(Async_Request__c ar)
        {
            List<Id> accountIds = ar.Params__c.split(PARAMETERS_SPLITTER);

            if(accountIds.size() == 0) return;

            // Do something with Accounts

            List<Account> accountsToUpdate = [
                    SELECT Id, Description
                    FROM Account
                    WHERE Id IN :accountIds
            ];

            String now = String.valueOf(Datetime.now());
            for(Account acc : accountsToUpdate){
                acc.Description = 'Updated: ' + now;
            }

            update accountsToUpdate;
        }
    }

    /**
* Sample job that does something dumb.
* It sets the Account.Description to current execution time.
*/
    public without sharing class SampleJobAsyncWithExceptionsRowLock extends BaseAsyncHandler {

        public override String getRequestType(){
            return 'Sample Job';
        }

        public override void execute(Async_Request__c ar)
        {
            throw new customException('UNABLE_TO_LOCK_ROW');
        }
    }

    /**
* Sample job that does something dumb.
* It sets the Account.Description to current execution time.
*/
    public without sharing class SampleJobAsyncWithExceptionsNoRowLock extends BaseAsyncHandler {

        public override String getRequestType(){
            return 'Sample Job';
        }

        public override void execute(Async_Request__c ar)
        {
            throw new customException('Unknown Exceptions');
        }
    }

    public class customException extends Exception{

    }
}