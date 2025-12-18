/**
 * Created by vikasmishra on 2021-08-19.
 */

@IsTest
private class EncodeAndDecodeEmailForFlowTest {
    @IsTest
    static void testDecodeEmailUtility() {
        System.assert(
                EncodeAndDecodeEmailForFlow.getDecodedEmail(
                        new List<String>{'test%40test.com'})[0]== 'test@test.com', 'Should return decoded email'
        );
    }
}