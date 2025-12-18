/**
 * Created by vikasmishra on 2021-07-06.
 */

@IsTest
private class CRSPartnerSharingServiceBatchTest {
    @IsTest
    static void testBatchRun() {
        ChannelRelationShipPartnerSharingServiceMock thisCRSPSMock =
                new ChannelRelationShipPartnerSharingServiceMock();

        CRSPartnerSharingServiceBatch.thisCRSPartnerSharingService = thisCRSPSMock;

        System.assert( new CRSPartnerSharingServiceBatch().query != null, 'Should not be null');
    }

    @IsTest
    static void testQuery() {
        CRSPartnerSharingServiceBatch thisBatch =
                new CRSPartnerSharingServiceBatch('Select id FROM Channel_Relationship__c');
        System.assert(
                thisBatch.query == 'Select id FROM Channel_Relationship__c',
                'Should set Query'
        );
    }

    @IsTest
    static void runBatchWithDatabaseRecords(){
        ChannelRelationShipPartnerSharingServiceMock thisCRSPSMock =
                new ChannelRelationShipPartnerSharingServiceMock();

        CRSPartnerSharingServiceBatch.thisCRSPartnerSharingService = thisCRSPSMock;
        List<Account> newAccounts = new List<Account>();

        Account account = new Account(  Name = 'Testers 1 Inc',
                BillingCountry = 'United States',
                BillingState = 'California',
                Organization_Size__c = '100 - 499',
                Industry = 'Other');
        newAccounts.add(account);

        Account partnerAccount = new Account(   Name = 'Partner Testers',
                BillingCountry = 'United Kingdom',
                Organization_Size__c = '100 - 499',
                Industry = 'Other',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId());
        newAccounts.add(partnerAccount);
        insert newAccounts;

        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();

        // Create Contact
        List<Contact> newContacts = new List<Contact>();
        Contact contact =
                new Contact (
                        FirstName = 'User',
                        LastName = 'Tester',
                        Email = 'test@test.com',
                        AccountId=account.Id
                );
        newContacts.add(contact);
        insert newContacts;

        //Create Opportunity
        Opportunity channelOpportunity =
                new Opportunity(
                        Name = 'Channel Opportunity Test',
                        AccountId = account.Id, License_Term__c =36,
                        Pricebook2Id = pricebookId,
                        Max_Approved_Discount__c=0,
                        Price_Book_Name__c = 'Standard Price Book',
                        CloseDate = System.today() + 90, StageName = 'Incubate');
        insert channelOpportunity;

        Channel_Relationship__c channelRelationship =
                new Channel_Relationship__c(
                        Channel_Partner__c = partnerAccount.Id,
                        Opportunity__c = channelOpportunity.Id,
                        Channel_Partner_User_lr__c = UserInfo.getUserId()
                );
        insert channelRelationship;

        Test.startTest();
        Database.executeBatch(new CRSPartnerSharingServiceBatch());
        Test.stopTest();

        System.assert(thisCRSPSMock.methodCalled, 'Should call runPartnerSharingForOpportunity method');

    }

    public class ChannelRelationShipPartnerSharingServiceMock implements ChannelRelationShipPartnerSharingService.IService{
       public Boolean methodCalled = false;
        public void runPartnerSharingForOpportunity(Map<Id, Channel_Relationship__c> newMap, Map<Id,Channel_Relationship__c> oldMap){
            methodCalled = true;
       }
    }
}