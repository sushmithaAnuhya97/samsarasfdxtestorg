public class ByPassDealDeskUserHierarchy {
   //Recursive method to identify whether the user hierarchy is having bypass flag till director level
   public static String getSalesDirectorBypassFlag(Id userId) {
            try{
        User currentUser = [
            SELECT Id, userRole.Name,isActive, By_Pass_Deal_Desk_Approval__c, ManagerId
            FROM User
            WHERE Id = :userId 
            LIMIT 1
        ];
        if(!currentUser.IsActive){
            return null;
        }
        if (currentUser.userRole.Name.contains('Director')||currentUser.userRole.Name.contains('ISD')) 
        {
            if(currentUser.By_Pass_Deal_Desk_Approval__c==true)
            return currentUser.Id ;
            else
            return null;
        }
        if (currentUser.ManagerId == null) {
            return null;
        }
                return getSalesDirectorBypassFlag(currentUser.ManagerId);
            }
            catch(Exception exc){
                return null;
            }
        
    }
    // called from flow to take by pass flag is true or not for the current user 's manager hierarchy
    @InvocableMethod(label='getByPassDealDeskUserHierarchy' description='To get the user ,sales director -By_Pass_Deal_Desk_Approval__c field value')
    public  static List<String> getBypassFlagValue(List<Id>userId){
        List<String> returnList=new List<String>();
        string result=null;
        try{
        if(userId.size()>0){
        result=getSalesDirectorBypassFlag(userId.get(0));
         }
        If(result!=null){
        returnList.add(result);
        }
       
        }
        catch(Exception e){
            
        }
        return returnList;
    }
    
}