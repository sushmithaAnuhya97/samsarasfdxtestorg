public with sharing class SlackPublisherITSupport {
     
    private static final String SLACK_URL = 'https://hooks.slack.com/services/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';
     
    public class CaseITrelated {
        @InvocableVariable(label='Case Number')
        public String CaseITrelatedNumber; 
        @InvocableVariable(label='Subject')
        public String CaseITrelatedSubject;   
        @InvocableVariable(label='Id')
        public String CaseITrelatedId;    
        @InvocableVariable(label='Date/Time Opened')
        public Datetime CaseITrelatedOpenDate;
         
       
                  
    }
     
    @InvocableMethod(label='Post IT related Case to Slack')
    public static void postToSlack ( List<CaseITrelated> Cases ) {
        CaseITrelated c = Cases[0]; // bulkify the code later
        
        //String amount = '$' + String.valueOf(o.opptyAmount);
        
        Map<String,Object> msg = new Map<String,Object>();
        msg.put('text', 'We have received a new IT request. The IT related Case# is'+c.CaseITrelatedNumber+ 'and the subject is ' + c.CaseITrelatedSubject + '. This case was received at '+c.CaseITrelatedOpenDate+'. See details at https://samsara.my.salesforce.com/'+c.CaseITrelatedId);
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