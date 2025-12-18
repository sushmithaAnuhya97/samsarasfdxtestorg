/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 05, 2021
*
* @description : This class will be responsible for handling all the User Related Queries
* SFA-11
*
**/
public class GS_UserSelector extends GS_SObjectBaseSelector{
    
    public Boolean checkFatalError = false;
    
    public GS_UserSelector(boolean checkFatalError){
        super(checkFatalError);
    }
    
    public GS_UserSelector checkFatalError(){
        return (GS_UserSelector) super.validateFatalError();
    }
    
    public Map<Id, User> getUserMapByIds(Set<Id>userIds){
        Map<Id, User> userMap  = new Map<Id, User>([SELECT Name, Email, FirstName, LastName, ADR_Assignment__c, Level__c, UserRole.Name, Business_Unit__c, Segment__c, Team_Email_Alias__c,
                                                    ManagerID, Manager.FirstName, Manager.LastName, Manager.Email, Manager.Manager.email, Profile.Name FROM User where Id IN : userIds]);
        return userMap;
    }

    public List<User> getOrderAdminAvailableUser(){
        return [SELECT Id, Order_Admin_Oppty_Date__c, Entity__c FROM User WHERE Order_Admin_Available__c = TRUE AND isActive = TRUE ORDER BY Order_Admin_Oppty_Date__c ASC];
    }

    public List<User> getOrderAdminFallbackUser(){
        return [SELECT Id, Order_Admin_Oppty_Date__c, Entity__c FROM User WHERE Order_Admin_Fallback_User__c = TRUE AND isActive = TRUE ORDER BY Order_Admin_Oppty_Date__c ASC];
    }
}