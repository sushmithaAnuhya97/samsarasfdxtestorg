/**
 * Created by henryzhao on 2021-01-19.
 */

@IsTest
private class SlackMessageQueueableTest {
    private static final String MOCK_URL = 'https://samsara.test';
    @IsTest
    static void testCallout() {
        /*Arrange*/
        SlackMessageService.SlackMessagePayload payload
                = new SlackMessageService.SlackMessagePayload(MOCK_URL, 'POST', 'baz');
        /*Act*/
        Test.startTest();
        SlackMessageQueueable.httpCallout(payload);
        Test.stopTest();
        /*Assert*/
        System.assert(true);
    }

    @IsTest
    static void testBasicCall() {
        /*Arrange*/
        final List<SlackMessageService.SlackMessagePayload> payloads =
                new List<SlackMessageService.SlackMessagePayload>{
                        new SlackMessageService.SlackMessagePayload(
                                MOCK_URL,
                                'POST',
                                'baz1',
                                'token'),
                        new SlackMessageService.SlackMessagePayload(
                                MOCK_URL,
                                'POST',
                                'baz2',
                                'token2')
                };
        SlackMessageQueueable queueable = new SlackMessageQueueable(payloads);
        /*Act*/
        Test.startTest();
        queueable.execute(null);
        Test.stopTest();

        /*Assert*/
        System.assertEquals(true, queueable.messagesInQueue.isEmpty());

    }
}