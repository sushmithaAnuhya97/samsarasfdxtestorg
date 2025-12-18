/**
 * Created by vikasmishra on 2021-07-07.
 */

@IsTest
private class GoogleCaptchaServiceTest {
    static final String googleEndpoint = 'Callout:Google_Api/recaptcha/api/siteverify';

    @IsTest
    static void shouldReturnTestAuth() {

        Test.setMock(HttpCalloutMock.class, new GoogleCaptchaServiceTestMocks());
        GoogleCaptchaSerializerMock thisMock = new GoogleCaptchaSerializerMock();
        GoogleCaptchaService.thisSerializer = thisMock;
        GoogleCaptchaService recaptchaService = new GoogleCaptchaService();
        System.assert(
                recaptchaService.verifyCaptcha('test'),
                'Positive response from mock'
        );
        System.assert(thisMock.contentTypeMethodCalled, 'Content Type method should be called');
        System.assert(thisMock.serializeMethodCalled, 'serializeMethodCalled should be called');
        System.assert(thisMock.deserializeMethodCalled, 'deserializeMethodCalled should be called');
    }

    @IsTest
    static void shouldTestSerializer() {
        Test.setMock(HttpCalloutMock.class, new GoogleCaptchaServiceTestMocks());
        GoogleCaptchaService recaptchaService = new GoogleCaptchaService();
        System.assert(
                recaptchaService.verifyCaptcha('test'),
                'Positive response from mock'
        );
    }

    @IsTest
    static void shouldTestError() {
        Test.setMock(HttpCalloutMock.class, new GoogleCaptchaServiceTestMocks());
        GoogleCaptchaService recaptchaService = new GoogleCaptchaService();
        GoogleCaptchaService.CAPTCHA_PATH_CONSTANT = '/fail';
        System.assert(
                !recaptchaService.verifyCaptcha('test'),
                'Negative response from mock'
        );
    }

    @IsTest
    static void shouldTestErrorWithFailedCallOut() {
        Test.setMock(HttpCalloutMock.class, new GoogleCaptchaServiceTestMocks());
        GoogleCaptchaService recaptchaService = new GoogleCaptchaService();
        GoogleCaptchaService.CAPTCHA_PATH_CONSTANT = '/failed';
        System.assert(
                !recaptchaService.verifyCaptcha('test'),
                'Negative response from mock'
        );
    }

    @IsTest
    static void shouldTestFromController() {
        Test.setMock(HttpCalloutMock.class, new GoogleCaptchaServiceTestMocks());
        GoogleCaptchaService.CAPTCHA_PATH_CONSTANT = '/failed';
        System.assert(
                !GoogleReCaptchaController.verifyCaptcha('test'),
                'Negative response from mock'
        );
    }

    public class GoogleCaptchaSerializerMock implements gslib_IRestClientSerializer{
        public Boolean contentTypeMethodCalled = false;
        public Boolean serializeMethodCalled = false;
        public Boolean deserializeMethodCalled = false;
        public Boolean deserializeErrorMethodCalled = false;
        public String contentType(){
            contentTypeMethodCalled = true;
            return 'application/x-www-form-urlencoded';
        }
        public Object serialize(HttpRequest request, Object payload){
            serializeMethodCalled = true;
            return 'test';
        }

        public Object deserialize(HttpRequest request, HttpResponse response){
            deserializeMethodCalled = true;
            return true;
        }

        public Object deserializeError(HttpRequest request, HttpResponse response){
            deserializeErrorMethodCalled = true;
            return response.getBody();
        }
    }
    public class GoogleCaptchaServiceTestMocks implements HttpCalloutMock {



        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            if(req.getEndpoint().contains(googleEndpoint)){
                System.assertEquals('POST', req.getMethod());
                res.setBody('{"success":true}');
                res.setStatusCode(200);
            }
            else if(req.getEndpoint().contains('fail')){
                res.setBody('{"success":false}');
                res.setStatusCode(200);
            }
            else{
                res.setBody('{"success":false}');
                res.setStatusCode(400);
            }

            return res;


        }
    }

}