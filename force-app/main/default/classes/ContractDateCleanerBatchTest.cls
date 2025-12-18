@IsTest
public without sharing class ContractDateCleanerBatchTest {

    public static Contract testContract;
    
    public static void makeData(){
        Date startDate = Date.today().addMonths(-36).addDays(1);
        Date endDate = Date.today();
        
        // BUILD CONTRACT 
        testContract = (Contract) TestFactory.createSObject(new Contract(
            Id = TestFactory.getFakeId(Contract.SObjectType),
            Status = 'Activated',
            StartDate = startDate,
            EndDate = endDate.addDays(3)
        ));

        Opportunity opp1 = (Opportunity) TestFactory.createSObject(new Opportunity(
            Id          = TestFactory.getFakeId(Opportunity.SObjectType),
            Name        = 'Test Opportunity',
            StageName   = 'Closed Won',
            CloseDate   = startDate,
            Probability = 1,
            License_Start_Date__c = startDate,
            License_End_Date__c = endDate
        ));

        testContract.SBQQ__Opportunity__c = opp1.Id;
        testContract.SBQQ__Opportunity__r = opp1;

        // START BUILDING QUOTE
        Opportunity opp2 = (Opportunity) TestFactory.createSObject(new Opportunity(
            Id          = TestFactory.getFakeId(Opportunity.SObjectType),
            Name        = 'Test Opportunity 2',
            StageName   = 'Closed Won',
            Probability = 1,
            License_Start_Date__c = startDate,
            License_End_Date__c = endDate
        ));

        SBQQ__Quote__c quote = (SBQQ__Quote__c) TestFactory.createSObject(new SBQQ__Quote__c(
            Id = TestFactory.getFakeId(SBQQ__Quote__c.SObjectType),
            SBQQ__Opportunity2__c = opp2.Id,
            SBQQ__Opportunity2__r = opp2
        ));

        SBQQ__QuoteLine__c quoteLine = (SBQQ__QuoteLine__c) TestFactory.createSObject(new SBQQ__QuoteLine__c(
            Id = TestFactory.getFakeId(SBQQ__QuoteLine__c.SObjectType),
            SBQQ__Quote__c = quote.Id,
            SBQQ__Quote__r = quote
        ));

        SBQQ__Subscription__c subscription = (SBQQ__Subscription__c) TestFactory.createSObject(new SBQQ__Subscription__c(
            Id = TestFactory.getFakeId(SBQQ__Subscription__c.SObjectType),
            SBQQ__QuoteLine__c = quoteLine.Id,
            SBQQ__QuoteLine__r = quoteLine,
            SBQQ__SubscriptionStartDate__c = startDate.addDays(5),
            SBQQ__SubscriptionEndDate__c = endDate.addDays(2)
        ));

        String subscriptionListJSON = '{'+
            ' "totalSize" : 1, '+
            ' "done" : true, '+
            '"records" : '+JSON.serializePretty(new List<SBQQ__Subscription__c>{subscription})+'}';
        
        String testContractJSON = JSON.serializePretty(testContract).replaceAll('}$', ', "SBQQ__Subscriptions__r" : '+subscriptionListJSON+'}');
        testContract = (Contract) JSON.deserialize(testContractJSON, Contract.class);
    }

    @IsTest
    public static void executeTest(){
        makeData();

        Test.startTest();
        ContractDateCleanerBatch batch = new ContractDateCleanerBatch();
        batch.TEST_EXCEPTION_OVERRIDE = new ManuallyThrownTestException('This is a test exception');
        
        batch.start(null);
        
        batch.execute(null, new List<Contract>{testContract});
        batch.TEST_PERFORM_DMLS = false;
        batch.execute(null, new List<Contract>{testContract});

        try{
            // To avoid issues with mail permissions
            batch.finish(null);
            batch.execute(null);
        }catch(Exception ex){}
    }

    public class ManuallyThrownTestException extends Exception {}
}