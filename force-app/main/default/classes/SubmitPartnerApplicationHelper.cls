/**********************************************************************
Name: SubmitPartnerApplicationHelper
=======================================================================
Purpose: This class will contain methods that handles the partner application                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Vijay Amaraneni       					INITIAL DEVELOPMENT 
1.1.       Rodrigo Carpio		Aug-14-2024			Added change for GTMS-22939
***********************************************************************/ 
public class SubmitPartnerApplicationHelper {
	public static void afterInsertOperations(Map<Id, SubmitPartnerApplicationEvent__e> oldEventMap, List<SubmitPartnerApplicationEvent__e> newEventList){
        Map<Id, Lead> recordsToUpdate = new Map<Id, Lead>();
        Set<Id> leadRecordIdSet = new Set<Id>();
        Set<Id> leadOwnerIdSet = new Set<Id>();
		List<Id> leadtoCreateUserSet = new List<Id>(); // GTMS-22939
        for (SubmitPartnerApplicationEvent__e event : newEventList) {
            string processType = event.Process_Type__c; // GTMS-22939
            if(!String.isBlank(event.Lead_Id__c) && string.IsBlank(processType)) {
                leadRecordIdSet.add(event.Lead_Id__c);
            }
            if(!String.isBlank(event.Contact_Id__c) && !string.IsBlank(processType) && processType == SYSTEM.LABEL.PROCESS_TYPE_FOR_USER_CREATION ) {
                leadtoCreateUserSet.add(event.Contact_Id__c);
            }
        }
        
        if(!leadRecordIdSet.isEmpty()){
            callNotreDamFuture(leadRecordIdSet);
        }
        
        if(!leadtoCreateUserSet.isEmpty()){ // GTMS-22939
            List<List<Id>> leadIds = new List<List<Id>>();
            leadIds.add(leadtoCreateUserSet);
            LeadConversionRestResourceHelper.invokeUserProvision(leadIds);
        }
    }
    
    
    @future(callout=true)
    public static void callNotreDamFuture(Set<Id> leadIdSet){
        for(Id leadId:leadIdSet){
            SubmitLeadForApprovalControllerService.IService thisCtrlService = new SubmitLeadForApprovalControllerService();
        	thisCtrlService.submitLeadForApprovalByPSM(leadId);
        }
        
    }
        
}