public class SubmitDealRegToNotreDame {
@InvocableMethod(label='Submit Lead to Notre Dame' description='Submit Deal Reg Lead record to Notre Dame for processing')
    public static List<String> submitLeadForConversion(List<Payload> leadIdList){
        SubmitLeadForApprovalControllerService.IService thisCtrlService = new SubmitLeadForApprovalControllerService();
        List<String> returnMessages = new List<String>();
        try {
            thisCtrlService.submitLeadForApprovalByPSM(leadIdList.get(0).leadId);
            returnMessages.add('success');
        }
        catch(Exception ex) {
            returnMessages.add('error');
        }
        return returnMessages;
    }
    
    public class Payload {
        @InvocableVariable(Label='Lead Id' Description='Lead Id for processing' Required=true)
        public String leadId;

    }
}