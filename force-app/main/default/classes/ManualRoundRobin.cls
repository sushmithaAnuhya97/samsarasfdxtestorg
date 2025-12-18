global class ManualRoundRobin {

    @InvocableMethod(Label='Manual Round Robin')
    public static List<ManualRoundRobinResponse> invokeRounRobin(List<ManualRoundRobinRequest> request) {
        List<ManualRoundRobinResponse> response = new List<ManualRoundRobinResponse>();
        ManualRoundRobinResponse responseRecord = new ManualRoundRobinResponse();
        string accountField = request[0].fieldToUpdate;
        String fieldToAssignUser =  accountField == 'IC' ? 'CSM__c' : 'SIC__c'; 
        Account accntRec = request[0].accountRecord;
        
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account',fieldToAssignUser); 
        RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
        rrInfo = rr.getAssignedUser(accntRec);
        Account accInfo = new Account();
        if (rrInfo.fieldToUpdate != null && rrInfo.userId != null) {
            accInfo.put(rrInfo.fieldToUpdate, rrInfo.userId);
            //accInfo.RR_Assigned_On__c = System.now();
            accInfo.Account_Assignment_Date__c = System.now();
            accInfo.RR_Assignment_Rule__c = rrInfo.ruleId;
            accInfo.RR_Assignment_Mapping__c = rrInfo.mappingId;
            
            accInfo.Id = accntRec.Id;
            update accInfo;
            rr.updateRuleDetail();
            responseRecord.isSuccess = true;
            if(accountField == 'IC'){
                responseRecord.successMessage = 'Implementation Consultant Assigned Successfully';
            }else if(accountField == 'CSM'){
                responseRecord.successMessage = 'Customer Success Manager Assigned Successfully';
            }
            
        }else{
            responseRecord.isSuccess = false;
            responseRecord.successMessage = 'No Matching Rule Found';
        }
        response.add(responseRecord);
        return response;
    }
    
    public class ManualRoundRobinRequest {
        @InvocableVariable public String fieldToUpdate;
        @InvocableVariable public Account accountRecord;
    }
    
    public class ManualRoundRobinResponse {
        @InvocableVariable public Boolean isSuccess;
        @InvocableVariable public String successMessage;
       
    }
    
}