public with sharing class SlackPublisherIssueReview {
     
    private static final String SLACK_URL = 'https://hooks.slack.com/services/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';
     
    public class IssueReview {
        @InvocableVariable(label='Issue Number')
        public String IssueNumber; 
        @InvocableVariable(label='Subject')
        public String IssueSubject;   
        @InvocableVariable(label='Product Owner')
        public String IssueProductOwner;
        @InvocableVariable(label='Id')
        public String IssueId;                                     
    }
     
    @InvocableMethod(label='Post Issue that needs PM review to Slack')
    public static void postToSlack ( List<IssueReview> Issues ) {
        IssueReview c = Issues[0]; // bulkify the code later
        
        //String amount = '$' + String.valueOf(o.opptyAmount);
        
        Map<String,Object> msg = new Map<String,Object>();
        msg.put('text', 'An Issue is ready for a review. The Issue# is' +c.IssueNumber+ 'and the subject is ' +c.IssueSubject+ '. The Product Owner is ' +c.IssueProductOwner+ '. See details at https://samsara.my.salesforce.com/'+c.IssueId);
        msg.put('mrkdwn', true);
        
        String body = JSON.serialize(msg);   
        System.enqueueJob(new QueueableSlackPost(SLACK_URL, 'POST', body));
    }
     
    public class QueueableSlackPost implements System.Queueable, Database.AllowsCallouts {
         
        private final String url;
        private final String method;
        private final String body;
         
        public QueueableSlackPost(String url, String method, String body) {
            this.url = url;
            this.method = method;
            this.body = body;
        }
         
        public void execute(System.QueueableContext ctx) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod(method);
            req.setBody(body);
            Http http = new Http();
            HttpResponse res = http.send(req);
        }
    }
}