public class OpportunityTeamMemberHelper {
        
    private static Map<Id, User> userMap = null;

    public void stampFields(List<OpportunityTeamMember> newOpptyTeamList, Map<Id, OpportunityTeamMember> newOpptyTeamMap, Map<Id, OpportunityTeamMember> oldOpptyTeamMap){
    	List<Id> userIds = new List<Id>();
   		for(OpportunityTeamMember teamMember: newOpptyTeamList){
        	userIds.add(teamMember.UserId);
    	}   
        if(userMap == null && userIds.size() > 0){
            userMap = new Map<Id, User>([SELECT Id, Name, UserRole.Name, Manager.UserRole.Name, Manager.Name, Manager.Manager.Name FROM USER WHERE ID IN : userIds]);
        }
        for(OpportunityTeamMember teamMember: newOpptyTeamList){
            if(!userMap.containsKey(teamMember.UserId)) {
                continue;
          }
        	User userData = userMap.get(teamMember.UserId);
        	teamMember.Owner_Name__c = userData.Name;
        	teamMember.Owner_Role__c = userData.UserRole.Name;
        	teamMember.Owner_Manager_Name__c = userData.Manager.Name;
        	teamMember.Owner_Director_Name__c = userData.Manager.Manager.Name;
        	teamMember.Owner_Manager_Role__c = userData.Manager.UserRole.Name;
    	}  
    }
}