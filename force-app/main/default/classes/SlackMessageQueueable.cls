/**
 * Created by henryzhao on 2021-01-19.
 */

public with sharing class SlackMessageQueueable implements Queueable, Database.AllowsCallouts {
    @TestVisible private List<SlackMessageService.SlackMessagePayload> messagesInQueue;

    public SlackMessageQueueable(List<SlackMessageService.SlackMessagePayload> messages) {
        this.messagesInQueue = messages;
    }

    public void execute(QueueableContext param1) {
        while (Limits.getLimitCallouts() > 0 && !this.messagesInQueue.isEmpty()) {
            final SlackMessageService.SlackMessagePayload currentMessage = this.messagesInQueue[0];
            this.messagesInQueue.remove(0);
            httpCallout(currentMessage);
        }

        /** If we've exhausted the callout limit, chain another queueable **/
        if (!this.messagesInQueue.isEmpty()) {
            System.enqueueJob(this.messagesInQueue);
        }
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2021-01-19
    *
    * @description Generic HTTP callout method that reads from SlackMessagePayload
    */
    @TestVisible
    private static void httpCallout(SlackMessageService.SlackMessagePayload payload) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(payload.url);
        if (!String.isEmpty(payload.token)) {
            req.setHeader('Authorization', 'Bearer ' + payload.token);
        }
        req.setHeader('content-type', 'application/json');
        req.setMethod(payload.method);
        req.setBody(payload.message);
        Http http = new Http();
//        TODO: Switch this to mocking instead. Kept for backwards compatibility
        if (!Test.isRunningTest()) {
            HttpResponse res = http.send(req);
            System.debug(LoggingLevel.INFO, 'Slack for Inbound Enqueue Sent\n\n' + 'Status Code: ' + res.getStatusCode() + '\n\n' + 'Response: \n' + res.getBody());
        }
    }
}