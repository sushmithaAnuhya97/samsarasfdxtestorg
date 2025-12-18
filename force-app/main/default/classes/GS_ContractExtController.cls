/*
 Author: Abu Saleh Khan
 GTMS Ticket Details: GTMS-14429, 14430
 Description: Submit Advanced Approval for Grace Period Extension.
 Visualforce Page: SubmitContract.vfp
 Test Class: GS_ContractExtControllerTest.apxc
*/
public with sharing class GS_ContractExtController {
    private Id contractId;
    public String RequestReason { get; set; }
    //public Boolean show {get;set;}
    //String requestedReason;
    public GS_ContractExtController(ApexPages.StandardController stdController) {
		contractId = stdController.getId();
        //contractRec = (Contract)stdController.getRecord();
        //show = true;
	}
    
	public PageReference onSubmit() {
        System.debug('contractRec.requestReason__c: '+ RequestReason);
		if (contractId != null) {
            Contract crt = new Contract();
                List<Contract> crtLst = new List<Contract>();
            crt.Id = contractId;
            crt.RequestReason__c = RequestReason;
            User appUsers = [SELECT ID,ManagerId,Manager.Name,Manager.managerId,Manager.Manager.Name,Manager.Manager.managerId,Manager.Manager.Manager.Name FROM User WHERE Id = :UserInfo.getUserId()];
            
            Set<Id> userIDs = new Set<Id>();
            Map<Id,String> userIdToName = new  Map<Id,String>();
            if(appUsers.ManagerId != Null){
               crt.Initial_Approver_Id__c = appUsers.ManagerId;
               userIdToName.put(appUsers.ManagerId,appUsers.Manager.Name);
            }     
            if(appUsers.Manager.ManagerId != Null){
                crt.Manager2__c = appUsers.Manager.ManagerId;
                userIdToName.put(appUsers.Manager.ManagerId,appUsers.Manager.Manager.Name);
            } 
            if(appUsers.Manager.Manager.ManagerId != Null){
                crt.Manager3__c = appUsers.Manager.Manager.ManagerId;
                userIdToName.put(appUsers.Manager.Manager.ManagerId,appUsers.Manager.Manager.Manager.Name);
            }
            List<sbaa__Approver__c> approvers = [SELECT ID,sbaa__User__c FROM sbaa__Approver__c WHERE sbaa__User__c IN :userIdToName.keySet()];
            Set<Id> existingApproverIds = new Set<Id>();
            List<sbaa__Approver__c> newApprovers = new List<sbaa__Approver__c>();
			for(sbaa__Approver__c approver : approvers){
    			existingApproverIds.add(approver.sbaa__User__c);
			}
            for(Id managerId : userIdToName.keySet()){
    			if(!existingApproverIds.contains(managerId)){
        			sbaa__Approver__c newApprover = new sbaa__Approver__c();
                    newApprover.Name = userIdToName.containsKey(managerId) ? userIdToName.get(managerId) : managerId;
        			newApprover.sbaa__User__c = managerId;
        			newApprovers.add(newApprover);
    			}
			} 
            crtLst.add(crt);
            try{
                if(!newApprovers.isEmpty()){
    			insert newApprovers;
				}
                update crtLst;
            }Catch(Exception e){
                System.debug('Error Message: '+e.getMessage());
            }
               SBAA.ApprovalAPI.submit(contractId, SBAA__Approval__c.Contract__c); 
            //Contract crt = new Contract();
		}
		return new PageReference('/' + contractId);
	}
    public PageReference onCancel() {
        return new PageReference('/' + contractId);
    }
	public PageReference onRecall() {
		if (contractId != null) {
			SBAA.ApprovalAPI.recall(contractId, SBAA__Approval__c.Contract__c);
		}
		return new PageReference('/' + contractId);
	}
}