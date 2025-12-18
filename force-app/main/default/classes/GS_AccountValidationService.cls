/**
* Created By : Groundswell - Rajesh
* @Date March 25, 2022
*
* @description : This class will be responsible for handling any validations that are Custom Validations
* GTMS-5219
* 
**/
public without sharing class GS_AccountValidationService {
    public static void sitesUnloadAccount(List<Account> newAccountList) { 
        Set<Id> setOwners = new Set<Id>();
        id connectedWorkerPoolId = System.label.Sites_Unload_Account_Connected_Worker_Pool;  //'0051P000003IOMR';
        Boolean isUnloadedChecked = false;
        for (Account a : newAccountList) {
            if (a.Sites_Unload_Account__c == true) {
                setOwners.add(a.OwnerId);
                if(isUnloadedChecked <> true) 
                    isUnloadedChecked = true;               
            } 
        }
        setOwners.add(UserInfo.getUserId());
        if(isUnloadedChecked)
        {
            Map<Id,User> mapUser = new Map<Id,User>([SELECT id, userRole.name FROM user WHERE userrole.name<>null AND Id IN: setOwners]);
        
            //update owner & SitesSpecialist to ConnectedWorkerPool
            //GTMS-6844
            if(mapUser <> null && !mapUser.isEmpty() && mapUser.size() > 0 && mapUser.containsKey(UserInfo.getUserId())) {

                if(mapUser.get(UserInfo.getUserId()).userRole.name.contains('Sites IS ADR') ||
                   mapUser.get(UserInfo.getUserId()).userRole.name.contains('Sites IS AE2')){

                    for (Account a : newAccountList) {
                        if (a.Sites_Unload_Account__c == true) {
                    
                            if(mapUser.get(a.OwnerId).userRole.name.contains('Sites')) 
                                a.OwnerId = connectedWorkerPoolId;  
                            
                            a.Sites_Specialist__c = connectedWorkerPoolId;
                            //a.Sites_Unload_Account__c = false;
                        }
                    } 
                } 
            }            
        }   
    }
}