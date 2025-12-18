/*
 * 02/06/19 - Added changes to display ACV values in the message. - @author: Harsha
 * 02/21/19 - Added code to enable/disable the slack notification's using custom metadata. - @author: Harsha
 */
public with sharing class SlackPublisher {
     
    private static final String SLACK_URL = 'https://hooks.slack.com/services/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';
    static Slack_Notification__mdt thisSlackPublisher;

     
    public class Oppty {
        @InvocableVariable(label='Opportunity Name')
        public String opptyName; 
        @InvocableVariable(label='Owner First Name')
        public String opptyOwnerFN;   
        @InvocableVariable(label='Owner Last Name')
        public String opptyOwnerLN;    
        @InvocableVariable(label='Amount')
        public Decimal opptyAmount;         
        @InvocableVariable(label='Account Name')
        public String accountName; 
        @InvocableVariable(label='Opportunity Id')
        public String opptyId;   
        @InvocableVariable(label='ACV Bookings')
        public Decimal opportunityACVBookings; 
    }
     
    @InvocableMethod(label='Post Deal to Slack')
    public static void postToSlack ( List<Oppty> opps ) {
        Oppty o = opps[0]; // bulkify the code later
        String amount;
        String acvBookings;

        if(thisSlackPublisher == null){
            thisSlackPublisher = new List<Slack_Notification__mdt>([SELECT ID, Enable_SlackPublisher__c FROM Slack_Notification__mdt WHERE MasterLabel = 'Notifications' LIMIT 1])[0];
        }
        
        try {
            amount = '$' + String.valueOf(o.opptyAmount).replaceAll('(\\d)(?=(\\d{3})+(?!\\d{1,2}.))', '$1,');  
            acvBookings = '$' + String.valueOf(o.opportunityACVBookings.setScale(1)).replaceAll('(\\d)(?=(\\d{3})+(?!\\d{1,2}.))', '$1,');        
        } catch (exception e) {
            amount = '$' + String.valueOf(o.opptyAmount);
            acvBookings = '$' + String.valueOf(o.opportunityACVBookings.setScale(1));
        }
                
        Map<String,Object> msg = new Map<String,Object>();
        msg.put('text', 'Congratulations to '+o.opptyOwnerFN+' '+o.opptyOwnerLN+' and everyone who helps support the ' + o.accountName + ' account! The opportunity '+o.opptyName+' is ready to ship and is closing for the ACV value: '+acvBookings+' (TCV: '+amount+'). See details at https://samsara.my.salesforce.com/'+o.opptyId);
        msg.put('mrkdwn', true);
        
        String body = JSON.serialize(msg);   
        if(thisSlackPublisher.Enable_SlackPublisher__c){
            System.enqueueJob(new QueueableSlackPost(SLACK_URL, 'POST', body));
        }
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
            if (!Test.isRunningTest()) {
                HttpResponse res = http.send(req);
            }
        }
    }
}