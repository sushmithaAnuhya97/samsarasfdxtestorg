/**
 * Created by henryzhao on 2021-01-19.
 */

public with sharing class SlackMessageService {
    private static SlackMessageService instance;
    @TestVisible private List<SlackMessagePayload> messageQueue;

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2021-01-19
    *
    * @description Singleton instance retriever
    */
    public static SlackMessageService getInstance() {
        if (SlackMessageService.instance == null) {
            SlackMessageService.instance = new SlackMessageService();
        }
        return SlackMessageService.instance;
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2021-01-19
    *
    * @description Adds a SlackMessagePayload object to the message queue
    */
    public void register(SlackMessagePayload payload) {
        this.messageQueue.add(payload);
    }
    public void register(List<SlackMessagePayload> payloads) {
        for (SlackMessagePayload payload : payloads) {
            this.register(payload);
        }
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2021-01-19
    *
    * @description Fires off all enqueued slack messages via a Queueable, then clears the queue
    */
    public void fire() {
        if (this.messageQueue.isEmpty()) {
            return;
        }
        final SlackMessageQueueable queueable = new SlackMessageQueueable(this.messageQueue);
        System.enqueueJob(queueable);
        this.messageQueue.clear();
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2021-01-19
    *
    * @description Singleton private constructor
    */
    private SlackMessageService() {
        this.messageQueue = new List<SlackMessagePayload>();
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2021-01-19
    *
    * @description Wrapper class to store slack callout details
    */
    public class SlackMessagePayload {
        public String url;
        public String method;
        public String message;
        public String token;

        public SlackMessagePayload(String url, String httpMethod, String slackMsg, String token) {
            this(url, httpMethod, slackMsg);
            this.token = token;
        }
        public SlackMessagePayload(String url, String httpMethod, String slackMsg) {
            this.url = url;
            this.method = httpMethod;
            this.message = slackMsg;
        }
    }
}