/**
 * Created by vikasmishra on 2021-08-18.
 */

public without sharing class EncodeAndDecodeEmailForFlow {

    @InvocableMethod (Label='Get Decoded Email' Description='Returns decoded email from param' Category='Util')
    public static List<String>getDecodedEmail(List<String> Emails){
        List<String>targetEmails = new  List<String>();
        for(String email : Emails){
            email = EncodingUtil.urlDecode(email, 'UTF-8');
            targetEmails.add(email.trim().replace(' ', '+'));
        }
        return targetEmails;
    }



}