/**
 * Created by vikasmishra on 2021-09-09.
 */

@IsTest
private class BaseAsyncHandlerTest {

    private static final String NEW_DESCRIPTION = 'New Description';

    @isTest static void should_update_all_accounts(){
        // Arrange
        List<Account> newAccounts = new List<Account>();

        newAccounts.add((Account) TestFactory.createSObject(new Account(Name='Blah1', Website='test.test', CSM_First_30d_Stage__c = 'Pending Intro')));
        newAccounts.add((Account) TestFactory.createSObject(new Account(Name='Blah2', Website='um.um', CSM_First_30d_Stage__c = 'Pending Delivery')));
        newAccounts.add((Account) TestFactory.createSObject(new Account(Name='Blah2', Website='um.um', CSM_First_30d_Stage__c = 'Attempting Training')));
        newAccounts.add((Account) TestFactory.createSObject(new Account(Name='Blah2', Website='um.um', CSM_First_30d_Stage__c = 'Scheduled Training')));
        newAccounts.add((Account) TestFactory.createSObject(new Account(Name='Blah2', Website='um.um', CSM_First_30d_Stage__c = 'Health Check')));
        newAccounts.add((Account) TestFactory.createSObject(new Account(Name='Blah2', Website='um.um', CSM_First_30d_Stage__c = 'Scheduled Additional Training')));


        insert newAccounts;

        // Act
        System.assert(new GS_AccountSelector(true).checkFatalError().getAccountsByIds(new List<Id>()).isEmpty());
        System.assert(new GS_AccountSelector(true).checkFatalError().getAccountsWithOppAndShipAddrByIds(new List<Id>()).isEmpty());
      
         new BaseAsyncHandlerTest.SampleOptionsJobAsync().moreRequestToProcess();
        new BaseAsyncHandlerTest.SampleOptionsJobAsync().prepareAsyncRequests(new Set<Id>(), 10);
        Test.startTest();

        Set<Id> accIds = new Map<Id, Account>(newAccounts).keySet();
        insert new BaseAsyncHandlerTest.SampleOptionsJobAsync().prepareAsyncRequests(
                JSON.serialize(new BaseAsyncHandlerTest.Options(NEW_DESCRIPTION)),
                accIds);

        Test.stopTest();

        (new BaseAsyncHandlerTest.SampleOptionsJobAsync()).prepareAsyncRequests(new Set<Id>{TestFactory.getFakeId(Opportunity.getSObjectType())});
        (new BaseAsyncHandlerTest.SampleOptionsJobAsync()).getRequestType();
        (new BaseAsyncHandlerTest.SampleOptionsJobAsync()).isHandlerReadOnly();
    }

    public without sharing class SampleOptionsJobAsync extends BaseAsyncHandler {

        public override String getRequestType(){
            return 'Sample Options Job';
        }

        public  Boolean moreRequestToProcess(){
           return this.moreRequestsToProcess(null);
        }
        public override void execute(Async_Request__c ar)
        {
            List<Id> accountIds = ar.Params__c.split(PARAMETERS_SPLITTER);
            if(accountIds.size() == 0) return;

            Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);

            // Do something with Accounts

            List<Account> accountsToUpdate = [
                    SELECT Id, Description
                    FROM Account
                    WHERE Id IN :accountIds
            ];

            for(Account acc : accountsToUpdate){
                acc.Description = opt.Description;
            }

            update accountsToUpdate;
        }


    }

    public class Options {
        public String Description {get; set;}

        public Options(String description){
            this.Description = description;
        }
    }
}