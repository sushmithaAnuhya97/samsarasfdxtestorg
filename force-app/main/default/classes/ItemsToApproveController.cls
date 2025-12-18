public class ItemsToApproveController{
    public List<SBAA__Approval__c> requestedApprovals {get;set;}
    public List<ApprovalListItemWrapper> approvalLists {get;set;}
    public List<ProcessInstanceWorkItem> processInstanceItems {get;set;}
    
    public Integer approvalListSize {get;set;}
  
    
    public ItemsToApproveController(){
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
        List<Group> groupList = getGroups(userIds);
        //System.debug('groupList ---->' + groupList);
        //System.debug('userIds ---->' + userIds);
         
        for(Id userId : userIds){
          for(Group groupRecord : groupList){
            if(groupRecord.groupMembers != null &&  groupRecord.groupMembers.size() > 0){
                
                for(GroupMember member : groupRecord.groupMembers){
                    userIds.add(member.Id);
                }
            }else if (groupRecord.relatedId  == UserInfo.getUserRoleId()){
                userIds.add(groupRecord.relatedId);
            }
          }
        }
        
        requestedApprovals = getRequestedApprovals(userIds);
        List<SBAA__Approval__c> approvedApprovals = getApprovedApprovals();
//get standard approvals                                                                                     
        processInstanceItems = getProcessInstanceWorkItem(userIds);
        
        for(ProcessInstanceWorkItem processItem: processInstanceItems){
            instanceIds.add(processItem.ProcessInstance.Id);
        }
        
        List<ProcessInstanceStep> processInstanceSteps = getProcessInstanceSteps(instanceIds);
                                            
        for(ProcessInstanceStep processStep: processInstanceSteps){
            
            if(!mapProcessInstanceStep.containsKey(processStep.ProcessInstance.Id)){
                mapProcessInstanceStep.put(processStep.ProcessInstance.Id, processStep);
            }
        }
        
        for(ProcessInstanceWorkItem processItem: processInstanceItems){
            ProcessInstanceStep processStep = mapProcessInstanceStep.get(processItem.ProcessInstance.Id);
            lastActorInfo = processStep != null ? processItem.Actor.Name : '';
            createdDateValue = processItem.CreatedDate.format('MM/dd/yyyy hh:mm a');
            approvalLists.add(new ApprovalListItemWrapper(processItem.ProcessInstance.TargetObjectId,
                            processItem.ProcessInstance.TargetObject.Name,
                            processItem.ProcessInstance.TargetObject.Type.substringBefore('_'),
                            lastActorInfo, processItem.Id,true,createdDateValue));
        }
    
//get Advanced Approvals
    //get approved approvals to populate last actor info - if approval is in a chain
        for(SBAA__Approval__c currentApproval: approvedApprovals){
            if(!mapApprovals.containsKey(currentApproval.Quote__c)){
               mapApprovals.put(currentApproval.Quote__c, currentApproval.SBAA__ApprovedBy__r.Name);
            }
        }
    //get requested approvals to display
        for(SBAA__Approval__c currentApproval: requestedApprovals)
        {
            lastActorInfo = mapApprovals.get(currentApproval.Quote__c) != null ? mapApprovals.get(currentApproval.Quote__c) : ' ';
            createdDateValue = currentApproval.CreatedDate.format('MM/dd/yyyy hh:mm a');
            approvalLists.add(new ApprovalListItemWrapper(currentApproval.Quote__c, currentApproval.Quote__r.Name,
                                                        'Quote', lastActorInfo, currentApproval.Id, false, createdDateValue));
        }
        
        approvalListSize = approvalLists.size();
        return approvalLists;
    }

//query helper methods 
    public List<Group> getGroups(Set<Id> userIds){
        List<Group> groupList = [
            SELECT Id, Type, RelatedId,
                (SELECT Id, UserOrGroupId
                FROM GroupMembers 
                WHERE Id IN : userIds) 
            FROM Group
        ]; 
        return groupList;
    } 
    public List<SBAA__Approval__c> getRequestedApprovals(Set<Id> userIds){
        List<SBAA__Approval__c> requestedApprovals = [
            SELECT Id,SBAA__Approver__c, Quote__c,Quote__r.Name,
                    SBAA__Approver__r.Name,CreatedDate
            FROM SBAA__Approval__c 
            WHERE (SBAA__AssignedTo__c IN :userIds OR SBAA__AssignedGroupId__c IN :userIds) 
            AND SBAA__Status__c = 'Requested'
        ];
        
        return requestedApprovals;
    }
    public List<SBAA__Approval__c> getApprovedApprovals(){
        List<SBAA__Approval__c> approvedApprovals = [
            SELECT Id, SBAA__ApprovedBy__r.Name, Quote__c 
            FROM SBAA__Approval__c 
            WHERE SBAA__Status__c = 'Approved' 
            ORDER BY LastModifiedDate ASC LIMIT 45000
        ];
        return approvedApprovals;
    }
    public List<ProcessInstanceStep> getProcessInstanceSteps(Set<Id> instanceIds){
        List<ProcessInstanceStep> processInstanceSteps = [
            SELECT Id,ActorId,Actor.Name, ProcessInstance.Id 
            FROM ProcessInstanceStep
            WHERE (StepStatus = 'Approved' OR StepStatus = 'Started')
            AND ProcessInstance.Id in : instanceIds
            ORDER BY CreatedDate DESC
        ];
        return processInstanceSteps;
    }
    public List<ProcessInstanceWorkItem> getProcessInstanceWorkItem(Set<Id> userIds){
        List<ProcessInstanceWorkItem> workItems = [
            SELECT Id, ActorId, ElapsedTimeInDays, ProcessInstanceId, Actor.Name,
                ProcessInstance.TargetObjectId,
                ProcessInstance.TargetObject.Name,
                ProcessInstance.TargetObject.Type,
                ProcessInstance.LastActorId, OriginalActorId,
                ProcessInstance.LastActor.Name,CreatedDate,
                OriginalActor.Name, ProcessInstance.Status 
            FROM ProcessInstanceWorkItem
            WHERE ActorId IN :userIds
            AND ProcessInstance.Status = 'Pending'
            ORDER BY CreatedDate DESC
        ];
        return workItems;
    }
    
//Approval List Items Wrapper Class
    public class ApprovalListItemWrapper
    {
        public string relatedTo {get;set;}
        public string objectType {get;set;}
        public string mostRecentApprover {get;set;}
        public string targetObjectId {get;set;}
        public boolean isStandard {get;set;}
        public string processId {get;set;}
        public string dateSubmitted {get;set;}
        
        public ApprovalListItemWrapper(String objId, String objRelatedTo, String objType, String recentApprover, String processId, Boolean objIsStandard, String dateSubmitted)
        {
            this.isStandard = objIsStandard;
            this.targetObjectId = objId;
            this.relatedTo = objRelatedTo;
            this.objectType = objType;
            this.mostRecentApprover= recentApprover; 
            this.processId = processId;
            this.dateSubmitted = dateSubmitted;
            
        }
    }
}