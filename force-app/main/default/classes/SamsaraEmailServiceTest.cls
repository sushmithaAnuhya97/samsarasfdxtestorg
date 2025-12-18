/**
 * Created by vikasmishra on 2021-07-05.
 */
@IsTest
private class SamsaraEmailServiceTest {
    @IsTest
    static void shouldSendEmail() {

        SamsaraEmailService thisService = new SamsaraEmailService();
        Messaging.SingleEmailMessage emailMessage = thisService.setupEmailMessage(UserInfo.getUserId(), null, false);
        emailMessage.plainTextBody ='test';
        emailMessage.setSubject('test');
        emailMessage.toAddresses = new List<String>{'test@test.com.invalid'};
        Test.startTest();
        Messaging.SendEmailResult [] result = thisService.sendEmail(
                new List<Messaging.SingleEmailMessage>{
                        emailMessage
                }
        );

        Test.stopTest();

        System.assert(result[0].isSuccess(), 'Email should be sent');
    }

    @IsTest
    static void setupEmailMessageTest(){
        SamsaraEmailService thisService = new SamsaraEmailService();
        Messaging.SingleEmailMessage emailMessage = thisService.setupEmailMessage(UserInfo.getUserId(), null, false);
        emailMessage.plainTextBody ='test';
        emailMessage.setSubject('test');
        emailMessage.toAddresses = new List<String>{'test@test.com.invalid'};
        SamsaraEmailService.SetupEmailMessage setupEmailMessage = new SamsaraEmailService.SetupEmailMessage(emailMessage);

        System.assert(setupEmailMessage.emailMessage.targetObjectId == UserInfo.getUserId(), 'Email message should be set');
        System.assert(setupEmailMessage.getEmailMessage().targetObjectId == UserInfo.getUserId(), 'Email message should be set');
    }

}