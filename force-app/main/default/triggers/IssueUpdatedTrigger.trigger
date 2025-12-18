trigger IssueUpdatedTrigger on Issue__c (after insert, after update) {
    JCFS.API.pushUpdatesToJira();
}