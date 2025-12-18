public class OpportunitySplitTriggerHandler extends TriggerHandler {
    private Map<Id, OpportunitySplit> oldSplitMap;
    private Map<Id, OpportunitySplit> newSplitMap;
    private List<OpportunitySplit> newSplitList;
    
    public OpportunitySplitTriggerHandler() {
        
        this.oldSplitMap = (Map<Id, OpportunitySplit>) Trigger.oldMap;
        this.newSplitMap = (Map<Id, OpportunitySplit>) Trigger.newMap;
        this.newSplitList = (List<OpportunitySplit>) Trigger.new;
        //Already been initialized in Opportunity Domain Class
        
        
    }
    
    
    public override void beforeInsert() {
        updateManagerAndDirectorNames(newSplitList,null);
    }
    
    
    public override void beforeUpdate() {
        updateManagerAndDirectorNames(newSplitList,oldSplitMap);  
    }
    
    public static void updateManagerAndDirectorNames(List<OpportunitySplit> newSplitList, Map<Id,OpportunitySplit> oldSplitMap){
        Set<String> userIds = new Set<String>();
        Map<String,user> mapOfUsers = new Map<String ,user>();  
        for(OpportunitySplit split:newSplitList){
            
            if( split.SplitOwnerId != null && (oldSplitMap == null ||
                                               ( oldSplitMap != null && split.SplitOwnerId != oldSplitMap.get(split.Id)?.SplitOwnerId ))){
                                                   
                                                   userIds.add(split.SplitOwnerId);   
                                               }
            
        }
        if( ! userIds.isEmpty() && userIds.Size() >0){
            mapOfUsers = new Map<String,user>([Select Id,Email,Name,UserRole.Name,ManagerId,Manager.Name,Manager.Email,Manager.UserRole.Name,Manager.ManagerId,
                                               Manager.Manager.Name ,Manager.Manager.Email, Manager.Manager.UserRole.Name from user where Id IN:userIds]);
        }
        
        for(OpportunitySplit split:newSplitList){
            if( split.SplitOwnerId != null && (oldSplitMap == null ||
                                               ( oldSplitMap != null && split.SplitOwnerId != oldSplitMap.get(split.Id)?.SplitOwnerId ))){
                user u = (mapOfUsers.containsKey(split.SplitOwnerId))? mapOfUsers.get(split.SplitOwnerId):null;
                split.User_Email__c = (u != null) ? u.Email:null;
                split.User_Name__c = (u != null) ? u.Name:null;
                Split.User_Role__c =  (u != null) ? u.UserRole.Name:null;                                  
                split.Manager_Name_Copy__c    = (u != null) ? u.Manager.Name:null;
                split.Manager_Email_Copy__c   = (u != null) ? u.Manager.Email:null;
                split.Manager_Role_Copy__c    = (u != null) ? u.Manager.UserRole.Name:null;
                split.Manager_Copy_Lookup__c  = (u != null) ? u.ManagerId:null;
                split.Director_Name_Copy__c   = (u != null) ? u.Manager.Manager.Name:null;
                split.Director_Email_Copy__c  = (u != null) ? u.Manager.Manager.Email:null;
                split.Director_Role_Copy__c   = (u != null) ? u.Manager.Manager.UserRole.Name:null;
                split.Director_Copy_Lookup__c = (u != null) ? u.Manager.ManagerId:null;
                
            }
        }
    }
    
    
    
}