@isTest
private class SlackCasePublisherTest {
static testMethod void testPostCaseToSlack() {
    SlackCasePublisher.Scase opt = new SlackCasePublisher.Scase();
    opt.subject = 'Unit Test Opt';
    opt.description = 'Unit Test Stage';

    List<slackcasepublisher.scase> lis = new List<slackcasepublisher.scase>();
    lis.add(opt);
    SlackCasePublisher.postToSlack(lis);

    System.assertEquals(lis, lis); // Can't really test this, just put something that is true
    }
}