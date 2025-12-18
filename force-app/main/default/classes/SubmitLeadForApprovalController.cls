/**
 * Created by vikasmishra on 2021-06-29.
 */

public with sharing class SubmitLeadForApprovalController {

    @TestVisible
    static SubmitLeadForApprovalControllerService.IService thisCtrlService = new SubmitLeadForApprovalControllerService();
    @AuraEnabled
    public static AuraResponse approveLead(String recordId){
        AuraResponse thisResponse = new AuraResponse();
        try{
            thisCtrlService.submitLeadForApprovalByPSM(recordId);
            thisResponse.hasError = false;
            thisResponse.response = 'Success';
        }
        catch (Exception ex){
            thisResponse.hasError = true;
            thisResponse.errorMessage = ex.getMessage();
        }
        return thisResponse;
    }

    /**
     * @description : Inner class to pass the uniform response to the Component
     */
    public class AuraResponse {
        @AuraEnabled public Boolean hasError{get;  set;}
        @AuraEnabled public String errorMessage{get;  set;}
        @AuraEnabled public Object response{get;  set;}

        public AuraResponse (){
            hasError = false;
            errorMessage = '';
        }
    }
}