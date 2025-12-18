public with sharing class SlackIssuePublisher {
     
    private static final String slackURL = 'https://hooks.slack.com/services/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';
    
    public class SIssue {
        @InvocableVariable(label='Issue Number')
        public String issueNumber;
        @InvocableVariable(label='Subject')
        public String subject;
        @InvocableVariable(label='Description')
        public String description;
        @InvocableVariable(label='Status')
        public String status;
        @InvocableVariable(label='Dev Assigned')
        public String devAssigned;
        @InvocableVariable(label='ID')
        public String id;
        @InvocableVariable(label='Reason')
        public String Reason;
        @InvocableVariable(label='Priority')
        public String priority;
        @InvocableVariable(label='Area')
        public String area;
    }
    
    public class SlackField{
    	public String title;
    	public String value;
    }

    public class SlackAttachment{
        public String fallback;
        public String pretext;
        public String title;
        public String title_link;
        public String text;
        public String color;
        public List<SlackField> fields;
    }    
    
    @InvocableMethod(label='Post Issue to Slack')
    public static void postToSlack(List<SIssue> issues) {
        for (SIssue issue : issues){
            Map<String,Object> msg = new Map<String,Object>();
            String url = System.URL.getSalesforceBaseUrl().toExternalForm()  + '/' + issue.id;
            
            SlackAttachment attachment = new SlackAttachment();
            
            attachment.fallback = '';
            attachment.pretext = '';
            attachment.title = '';
            attachment.title_link = url;
            attachment.text = '';
            
            
            if (issue.Reason == 'issueCreated') {
                attachment.pretext = 'Issue created';
                attachment.title = issue.issueNumber + ': ' + issue.subject;
                String html_description = issue.description;
                attachment.text = html_description.replaceAll('<[/a-zAZ0-9]*>','\n');
                attachment.fallback = '*Issue created* ' + issue.issueNumber + ': ' + issue.subject + '\n';
                
                SlackField issue_priority = new SlackField();
                issue_priority.title = 'Priority';
                issue_priority.value = issue.priority;
                
                SlackField issue_area = new SlackField();
                issue_area.title = 'Area Impacted';
                issue_area.value = issue.area;
                                
                List<SlackField> issue_fields = new List<SlackField>();
                issue_fields.add(issue_priority);
                issue_fields.add(issue_area);
                
                attachment.fields = issue_fields;
            }
            else if (issue.Reason == 'statusChanged'){
                
                if (issue.status == 'dev-accepted'){
                    attachment.pretext = 'Issue accepted';
                    attachment.fallback += '*Issue accepted* ';
                }
                else if (issue.status == 'dev-rejected'){
                    attachment.pretext = 'Issue rejected';
                    attachment.fallback += '*Issue rejected* ';
                    attachment.color = 'danger';
                }
                else if (issue.status == 'dev-fixed'){
                    attachment.pretext = 'Issue fixed';
                    attachment.fallback += '*Issue fixed* ';
                    attachment.color = 'good';
                }
                else if (issue.status == 'Product_Management'){
                    attachment.pretext = 'Issue moved to PM';
                    attachment.fallback += '*Issue moved to PM * ';
                    attachment.color = 'warning';
                }
                else{
                    return;
                }
    
                attachment.title = issue.issueNumber + ': ' + issue.subject;
                attachment.fallback += issue.issueNumber + ': ' + issue.subject + '\n';
            }
            else if (issue.Reason == 'devAssigned'){
                attachment.pretext = 'Issue assigned -> ' + issue.devAssigned;
                attachment.title = issue.issueNumber + ': ' + issue.subject;
                attachment.fallback += '*Issue assigned -> ' + issue.devAssigned + '* ' + issue.issueNumber + ': ' + issue.subject + '\n';
            }
            
            List<SlackAttachment> attachments = new List<SlackAttachment>();
            attachments.add(attachment);
            
            msg.put('attachments', attachments);
            String body = JSON.serialize(msg);
            System.debug(body);
            System.enqueueJob(new QueueableSlackCall(slackURL, 'POST', body));
        }
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