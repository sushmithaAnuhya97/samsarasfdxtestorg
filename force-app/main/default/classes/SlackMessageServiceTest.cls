/**
 * Created by henryzhao on 2021-01-19.
 */

@IsTest
private class SlackMessageServiceTest {
    private static final String MOCK_URL = 'https://samsara.test';
    @IsTest
    static void multiSlackIntegrationTest() {
        /*Arrange*/
        SlackMessageService.SlackMessagePayload payload
                = new SlackMessageService.SlackMessagePayload(MOCK_URL, 'POST', 'baz');
        SlackMessageService.getInstance().register(payload);

        SlackMessageService.getInstance().register(
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
                }
        );
        /*Act*/
        Test.startTest();
        SlackMessageService.getInstance().fire();
        Test.stopTest();
        /*Assert*/
        System.assertEquals(true, SlackMessageService.getInstance().messageQueue.isEmpty());
    }
    
    @IsTest
    static void singleSlackIntegrationTest() {
        /*Arrange*/
        SlackMessageService.SlackMessagePayload payload
                = new SlackMessageService.SlackMessagePayload(MOCK_URL, 'POST', 'baz');
        SlackMessageService.getInstance().register(payload);

        SlackMessageService.getInstance().register(
                new List<SlackMessageService.SlackMessagePayload>{
                        new SlackMessageService.SlackMessagePayload(
                                MOCK_URL,
                                'POST',
                                'baz1',
                                'token')
                }
        );
        /*Act*/
        Test.startTest();
        SlackMessageService.getInstance().fire();
        Test.stopTest();
        /*Assert*/
        System.assertEquals(true, SlackMessageService.getInstance().messageQueue.isEmpty());
    }
}