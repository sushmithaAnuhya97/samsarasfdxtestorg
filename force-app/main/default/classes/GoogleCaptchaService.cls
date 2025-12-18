/**
 * Created by vikasmishra on 2021-06-07.
 */

public with sharing class GoogleCaptchaService extends gslib_RestClient {

    private static String SECRET_CONSTANT_STRING = 'secret=';
    private static String RESPONSE_CONSTANT_STRING = '&response=';
    @TestVisible
    private static String CAPTCHA_PATH_CONSTANT = '/recaptcha/api/siteverify';
    private static final String APPLICATION_FORM_URLENCODED ='application/x-www-form-urlencoded';
    @TestVisible
    static gslib_IRestClientSerializer thisSerializer = new GoogleCaptchaSerializer();

    public GoogleCaptchaService(){
        super('Callout:Google_Api',thisSerializer);
    }
    public Boolean verifyCaptcha(String recaptchaResponse){

        System.debug('recaptchaResponse****'+recaptchaResponse);
        Object response = this.createRequest().post(
                CAPTCHA_PATH_CONSTANT,
                recaptchaResponse
        );
        return (Boolean) response;
    }
    public with sharing class GoogleCaptchaSerializer implements gslib_IRestClientSerializer{

        public String contentType(){
            return GoogleCaptchaService.APPLICATION_FORM_URLENCODED;
        }
        public Object serialize(HttpRequest request, Object payload){
            String recaptchaResponse;
            if(payload instanceof String){
                recaptchaResponse = String.valueOf(payload);
            }
            System.debug('recaptchaResponse****'+recaptchaResponse);
            return GoogleCaptchaService.SECRET_CONSTANT_STRING
                    + '{!$Credential.Password}'
                    + GoogleCaptchaService.RESPONSE_CONSTANT_STRING
                    + recaptchaResponse;
        }

        public Object deserialize(HttpRequest request, HttpResponse response){

            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            System.debug('result****'+result);
            if (result.containsKey('success') && result.get('success') == true) {
                return true;
            } else {
                return false;
            }
        }

        public Object deserializeError(HttpRequest request, HttpResponse response){
            return response.getBody();
        }
    }
}