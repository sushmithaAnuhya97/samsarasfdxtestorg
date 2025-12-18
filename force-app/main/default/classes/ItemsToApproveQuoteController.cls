/* 
 * Class Created: 09/18/19 - @author: Harsha
 * 11/18/20 Harsha - (GTMS-1913) Added changes to display new fields
 * 5/17/2023 Siddharth - GTMS-11952 - Added more filter to prevent showing approvals whose quotes are approved/rejected
 */  
public class ItemsToApproveQuoteController {

    public List<SBAA__Approval__c> requestedApprovals {get;set;}
    public List<ApprovalListItemWrapper> approvalLists {get;set;}
    public List<ProcessInstanceWorkItem> processInstanceItems {get;set;}
    
    public Integer approvalListSize {get;set;}
  
    
    public ItemsToApproveQuoteController(){
        getApprovalListItemWrapperItems();
    }
    
    public List<ApprovalListItemWrapper> getApprovalListItemWrapperItems(){
        Set<Id> instanceIds = new Set<Id>();
        Map<Id, ProcessInstanceStep> mapProcessInstanceStep = new Map<Id, ProcessInstanceStep>();
        Map<Id, String> mapApprovals = new Map<Id, String>();
        String createdDateValue;
        String lastActorInfo;
        approvalLists = new List<ApprovalListItemWrapper>();
        approvalListSize=0;
        
        Set<Id> userIds = new Set<Id>{UserInfo.getUserId()};
       // List<Group> groupList = getGroups(userIds);
       List<GroupMember> groupMemberList=getGroupMemberList(userIds);
       // System.debug('groupList please ---->' + groupList);
        System.debug('userIds get the userId ---->' + userIds);
         
        /*for(Id userId : userIds){
          for(Group groupRecord : groupList){
            if(groupRecord.groupMembers != null &&  groupRecord.groupMembers.size() > 0){
                
                for(GroupMember member : groupRecord.groupMembers){
                    userIds.add(member.Id);
                }
            }else if (groupRecord.relatedId  == UserInfo.getUserRoleId()){
                userIds.add(groupRecord.relatedId);
            }
          }
        }*/
        Set<Id> groupIDs=new Set<Id>();
        for(GroupMember gm: groupMemberList){
            groupIDs.add(gm.GroupId);
        }
        requestedApprovals = getRequestedApprovals(userIds,groupIDs);
        //List<SBAA__Approval__c> approvedApprovals = getApprovedApprovals();
    
    //get Advanced Approvals
    //get approved approvals to populate last actor info - if approval is in a chain
        for(SBAA__Approval__c currentApproval: [SELECT Id, SBAA__ApprovedBy__r.Name, Quote__c 
            FROM SBAA__Approval__c 
            WHERE SBAA__Status__c = 'Approved' 
            ORDER BY LastModifiedDate DESC LIMIT 40000]){
            if(!mapApprovals.containsKey(currentApproval.Quote__c)){
               mapApprovals.put(currentApproval.Quote__c, currentApproval.SBAA__ApprovedBy__r.Name);
            }
        }
        
        //get requested approvals to display
        for(SBAA__Approval__c currentApproval: requestedApprovals)
        {
            lastActorInfo = mapApprovals.get(currentApproval.Quote__c) != null ? mapApprovals.get(currentApproval.Quote__c) : ' ';
            createdDateValue = currentApproval.CreatedDate.format('MM/dd/yyyy hh:mm a');
            approvalLists.add(new ApprovalListItemWrapper(currentApproval.Quote__c, currentApproval.Id, currentApproval.Quote__r.Name,
                                                          lastActorInfo, currentApproval.Quote__r.Reason_for_Discount__c, 
                                                          currentApproval.Quote__r.Blended_Discount__c,
                                                          currentApproval.Quote__r.License_Term__c,
                                                          currentApproval.Quote__r.SBQQ__Account__c,
                                                          currentApproval.Quote__r.SBQQ__SalesRep__r.Name,                                                          
                                                          currentApproval.Id, false, createdDateValue, currentApproval.Name, currentApproval.sbaa__Rule__r.Name));
        }
        
        approvalListSize = approvalLists.size();
        return approvalLists;
    }

//query helper methods 
    /*public List<Group> getGroups(Set<Id> userIds){
        List<Group> groupList = [
            SELECT Id, Type, RelatedId,
                (SELECT Id, UserOrGroupId,GroupId
                FROM GroupMembers 
                WHERE Id IN : userIds) 
            FROM Group
        ]; 
        return groupList;
    } */
    public List<GroupMember> getGroupMemberList(Set<Id> userIds){
        List<GroupMember> groupList = [
            SELECT Id, UserOrGroupId,GroupId
            FROM GroupMember
            WHERE UserOrGroupId IN : userIds
        ]; 
        return groupList;
    }  
    //GTMS-11952   
    public List<SBAA__Approval__c> getRequestedApprovals(Set<Id> userIds,Set<Id> groupIDs){
        // Create sets with both 15 and 18 character ID formats to match text field storage
        Set<String> allGroupIdFormats = getAllIdFormats(groupIDs);
        Set<String> allUserIdFormats = getAllIdFormats(userIds);
        
        List<SBAA__Approval__c> requestedApprovals = [
            SELECT Id,SBAA__Approver__c, Quote__c,Quote__r.Name,Quote__r.SBQQ__Status__c,Quote__r.Reason_for_Discount__c,
            Quote__r.Blended_Discount__c, Quote__r.License_Term__c, 
            Quote__r.SBQQ__Account__c, Quote__r.SBQQ__SalesRep__r.Name,
                    SBAA__Approver__r.Name,CreatedDate, Name, sbaa__Rule__r.Name
            FROM SBAA__Approval__c 
            WHERE (SBAA__AssignedTo__c IN :allUserIdFormats OR SBAA__AssignedGroupId__c IN :allGroupIdFormats) 
            AND SBAA__Status__c = 'Requested' AND Quote__r.SBQQ__Status__c!='Approved' AND Quote__r.SBQQ__Status__c!='Rejected' LIMIT 500
        ];
        
        return requestedApprovals;
    }
    
    /**
     * Helper method to create both 15-character and 18-character formats of Salesforce IDs
     * This ensures we match records regardless of how IDs are stored in text fields
     */
    private Set<String> getAllIdFormats(Set<Id> idSet) {
        Set<String> allFormats = new Set<String>();
        for (Id currentId : idSet) {
            if (currentId != null) {
                String idString = String.valueOf(currentId);
                // Add 15-character format
                allFormats.add(idString.substring(0, 15));
                // Add 18-character format (if not already 18 characters, this ensures we have the full ID)
                allFormats.add(idString);
            }
        }
        return allFormats;
    }
    /*public List<SBAA__Approval__c> getApprovedApprovals(){
        List<SBAA__Approval__c> approvedApprovals = [
            SELECT Id, SBAA__ApprovedBy__r.Name, Quote__c 
            FROM SBAA__Approval__c 
            WHERE SBAA__Status__c = 'Approved' 
            ORDER BY LastModifiedDate DESC LIMIT 10000
        ];
        return approvedApprovals;
    }*/
     
//Approval List Items Wrapper Class
    public class ApprovalListItemWrapper
    {
        public string relatedTo {get;set;}
        public string recordId {get;set;}
        public string mostRecentApprover {get;set;}
        public string reasonForDiscount {get;set;}
        public decimal blendedDiscount {get;set;}
        public string licenseTerm {get;set;}
        public Id accountId {get;set;}
        public string salesRep {get;set;}
        public string targetObjectId {get;set;}
        public boolean isStandard {get;set;}
        public string processId {get;set;}
        public string dateSubmitted {get;set;}
        public string approvalName {get;set;}
        public string approvalRuleName {get;set;}

        public ApprovalListItemWrapper(String objId, String recordId, String objRelatedTo, String recentApprover, String reasonForDiscount, Decimal blendedDiscount, 
                                       String licenseTerm, Id accountId, String salesRep, String processId, Boolean objIsStandard, String dateSubmitted, String approvalName, String approvalRuleName)
        {
            this.isStandard = objIsStandard;
            this.targetObjectId = objId;
            this.recordId = recordId;
            this.relatedTo = objRelatedTo;
            this.reasonForDiscount = reasonForDiscount;
            this.blendedDiscount = blendedDiscount;
            this.licenseTerm = licenseTerm;
            this.accountId = accountId;
            this.salesRep = salesRep;
            this.mostRecentApprover= recentApprover; 
            this.processId = processId;
            this.dateSubmitted = dateSubmitted;
            this.approvalName = approvalName;
            this.approvalRuleName = approvalRuleName;
            
        }
    }
}