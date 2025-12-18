public with sharing class SlackPublisherSupport {
     
    private static final String SLACK_URL = 'https://hooks.slack.com/services/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';
     
    public class CasePriority {
        @InvocableVariable(label='Case Number')
        public String CasePriorityNumber; 
        @InvocableVariable(label='Subject')
        public String CasePrioritySubject;   
        @InvocableVariable(label='Id')
        public String CasePriorityId;    
        @InvocableVariable(label='Date/Time Opened')
        public Datetime CasePriorityOpenDate; 
       
                  
    }
     
    @InvocableMethod(label='Post Priority Customer Voicemail to Slack')
    public static void postToSlack ( List<CasePriority> Cases ) {
        CasePriority c = Cases[0]; // bulkify the code later
        
        //String amount = '$' + String.valueOf(o.opptyAmount);
        
        Map<String,Object> msg = new Map<String,Object>();
        msg.put('text', 'We have received a new voicemail from a priority customer. The Support Case# is'+c.CasePriorityNumber+ 'and the subject is ' + c.CasePrioritySubject + '. This Voicemail was received at '+c.CasePriorityOpenDate+'. The Case is under New Case Queue. Please respond to the case. See details at https://samsara.my.salesforce.com/'+c.CasePriorityId);
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