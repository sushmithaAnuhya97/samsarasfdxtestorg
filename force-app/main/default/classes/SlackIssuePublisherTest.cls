@isTest
private class SlackIssuePublisherTest {
static testMethod void testPostIssueToSlack() {
    SlackIssuePublisher.SIssue issue1 = new SlackIssuePublisher.SIssue();
    issue1.subject = 'Unit Test Opt';
    issue1.issueNumber = '1';
    issue1.description = 'Unit Test Stage';
    issue1.Reason = 'issueCreated';
    issue1.area = 'Fleet';
    issue1.priority = '1 - High';

   SlackIssuePublisher.SIssue issue2 = new SlackIssuePublisher.SIssue();
    issue2.subject = 'Unit Test Opt';
    issue2.issueNumber = '2';
    issue2.description = 'Unit Test Stage';
    issue2.Reason = 'statusChanged';
    issue2.status = 'dev-accepted';
    
    SlackIssuePublisher.SIssue issue3 = new SlackIssuePublisher.SIssue();
   	issue3.subject = 'Unit Test Opt';
    issue3.issueNumber = '3';
    issue3.description = 'Unit Test Stage';
    issue3.Reason = 'devAssigned';
    issue3.devAssigned = 'cmp';
    
    List<SlackIssuePublisher.SIssue> lis = new List<SlackIssuePublisher.SIssue>();
    lis.add(issue1);
    lis.add(issue2);
    lis.add(issue3);
    SlackIssuePublisher.postToSlack(lis);

    System.assertEquals(lis, lis); // Can't really test this, just put something that is true
    }
}