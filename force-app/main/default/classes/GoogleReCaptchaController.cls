/**
 * Created by vikasmishra on 2021-06-07.
 */

public with sharing class GoogleReCaptchaController {

    private static GoogleCaptchaService reCaptchaService = new GoogleCaptchaService();
    @AuraEnabled
    public static Boolean verifyCaptcha(String recaptchaResponse){
        return reCaptchaService.verifyCaptcha(recaptchaResponse);
    }
}