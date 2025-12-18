public class Utility {

    public static Map<String,OrgWideEmailAddress> getAllOrgWideEmailAddress{
        get{
            if(getAllOrgWideEmailAddress == null){
                getAllOrgWideEmailAddress = new Map<String,OrgWideEmailAddress>();
                for(OrgWideEmailAddress emailAddress:[SELECT Id, Address FROM OrgWideEmailAddress]){
                    getAllOrgWideEmailAddress.put(emailAddress.Address,emailAddress);
                }

            }

            return getAllOrgWideEmailAddress;
        }
        set{getAllOrgWideEmailAddress = value;}
    }


    public static OrgWideEmailAddress getOrgWideEmailAddressBasedOnAddress(String emailAddress){
     return (getAllOrgWideEmailAddress != null && !getAllOrgWideEmailAddress.isEmpty() && getAllOrgWideEmailAddress.containsKey(emailAddress))? getAllOrgWideEmailAddress.get(emailAddress):null;  
    }

    public static string getCustomLabelByDeveloperName(String developerName){
        return label.get(null,developerName);
    }

    public static boolean hasPermission(String permissionName)
    {
        return featureManagement.checkPermission(permissionName);
    }

    public static boolean areValidationsSkippedAtCustomSettings(Id userOrProfileId)
    {
        return Global_Automation_Settings__c.getInstance( userOrProfileId )?.Skip_Validation_Rule__c;
    }

    public static string getRoleFromRoleId(Id roleId)
    {
        return [SELECT Name FROM UserRole WHERE Id = :roleId LIMIT 1].Name;
    }
}