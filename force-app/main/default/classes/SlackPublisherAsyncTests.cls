@IsTest
public without sharing class SlackPublisherAsyncTests {
    
    @IsTest
    public static void executeTest1(){
        Opportunity opp = (Opportunity) TestFactory.createSObject(new Opportunity(
            Payment_Terms__c = 'Net 30',
            License_Term__c = 12,
            Account = (Account) TestFactory.createSObject(new Account(
                Renewal_AE__r = new User(LastName = 'AE 1'),
                SIC__r = new User(LastName = 'SIC 1'),
                Name = 'Test account 1'
            )),
            Id = TestFactory.getFakeId(Opportunity.getSObjectType())
        ));

        SlackPublisherAsync.TEST_RECORDS_OVERRIDE = new List<Opportunity>{opp};

        new SlackPublisherAsync.CSBellNotification();
        SlackPublisherAsync handler = new SlackPublisherAsync();
        handler.getRequestType();
        handler.isHandlerReadOnly();

        (new SlackPublisherAsync()).execute(new Async_Request__c(
            Params__c = String.valueOf(TestFactory.getFakeId(Opportunity.SObjectType))+';',
            Options__c = JSON.serialize(new SlackPublisherAsync.Options('CS_BELL'))
        ));
    }
}