public with sharing class SlackCasePublisher {
     
    private static final String slackURL = 'https://hooks.slack.com/services/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';
    public class SCase {
        @InvocableVariable(label='Subject')
        public String subject;
        @InvocableVariable(label='Description')
        public String description;
        @InvocableVariable(label='Account Name')
        public String accountName;
        @InvocableVariable(label='Email')
        public String email;
        @InvocableVariable(label='Case Number')
        public String caseNumber;
    }    
    @InvocableMethod(label='Post to Slack')
    public static void postToSlack(List<SCase> cases) {
        SCase o = cases[0]; // If bulk, only post first to avoid overloading Slack channel
        Map<String,Object> msg = new Map<String,Object>();
        String url = System.URL.getSalesforceBaseUrl().toExternalForm()  + '/' + o.caseNumber;
        String text = 'New case';
        if (o.email != null && o.email.length() > 0) {
            text += ' from ' + o.email;
        }
        text += '\n';
                
        if (o.accountName != null && o.accountName.length() > 0) {
            text += 'company ' + o.accountName + '\n';
        }
        if (o.subject != null && o.subject.length() > 0) {
            text += 'subject: ' + o.subject + '\n';
        }
        if (o.description  != null && o.description.length() > 0) {
            text += o.description + '\n';
        }
        text += url + '\n';
        msg.put('text', text);
        msg.put('mrkdwn', true);
        String body = JSON.serialize(msg);    
        System.enqueueJob(new QueueableSlackCall(slackURL, 'POST', body));
    }
     
    public class QueueableSlackCall implements System.Queueable, Database.AllowsCallouts {
         
        private final String url;
        private final String method;
        private final String body;
         
        public QueueableSlackCall(String url, String method, String body) {
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
            if (!Test.isRunningTest()) {
                HttpResponse res = http.send(req);
            }
        }
 
    }
    
}