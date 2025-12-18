/**********************************************************************
Name: Acc_UpdatePartnerGroupCls
Test Class: Acc_UpdatePartnerGroupCls_Test
------------------------------------------------------------------------------
Purpose: This class contains the logic to add or remove users from partner group
------------------------------------------------------------------------------
History  

Ticket			 AUTHOR              DATE               DETAIL                       
GTMS-14030  Vijaychandra            11/03/23        Added logic to add or remove users from partner group
***********************************************************************/
//11/03/23 vijaychandra --START-- (GTMS-14030) to add or remove group members from partner public groups if account values changes
/**
* Description: This method will values between account Old and accont new
* @Param : oldAccMap - account trigger old map
* @Param : newAccMap - account trigger new map
*/
public Without Sharing class Acc_UpdatePartnerGroupCls {
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{GroupMember.SObjectType};
        
   	//10/13/23 vijaychandra --START-- (GTMS-14030) to add or remove group members from partner public groups if account values changes
   	/**
    * Description: This method will values between account Old and accont new
    * @Param : oldAccMap - account trigger old map
    * @Param : newAccMap - account trigger new map
    */
    public static void updatePartnerGroup(Map<Id,Account> oldAccMap, Map<Id,Account> newAccMap){
        
        Set<Id> accIdSet = new Set<Id>();
        //String partnerId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        String partnerId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        for(Account newAcc:newAccMap.values()){
            Account oldAcc = oldAccMap.get(newAcc.Id);
            if(newAcc.RecordTypeId == partnerId && (newAcc.Program_Type__c != oldAcc.Program_Type__c || newAcc.Partner_Description__c != oldAcc.Partner_Description__c || newAcc.ServicesIntegration_Program_Type__c != oldAcc.ServicesIntegration_Program_Type__c)){accIdSet.add(newAcc.Id);}
        }
        
        if(!accIdSet.isEmpty()) updatePartnerGroupFuture(accIdSet);
    }
    //10/13/23 --END-- (GTMS-14030)

        /**
* Description: This method will udpate Partner related groups for documentation library access in partner portal
* @Param : oldAccMap - account trigger old map
* @Param : newAccMap - account trigger new map
*/
        @Future
        public static void updatePartnerGroupFuture(Set<Id> accIdSet){
            
            DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            
            List<Account> accList = new List<Account>([SELECT Id,Program_Type__c,Partner_Description__c,ServicesIntegration_Program_Type__c FROM Account WHERE Id IN :accIdSet]);
            
            Map<String,Map<String,GroupMember>> grpMemMap = new Map<String,Map<String,GroupMember>>();
            Map<String,List<User>> accUserMap = new Map<String,List<User>>();
            List<String> groupIdList = new List<String>{
                System.Label.Referral_Program_Partner_Group_Id,
                    System.Label.Resale_Program_Partner_Group_Id,
                    System.Label.Insurance_Partner_Group_Id,
                    System.Label.Service_Partner_Group_Id
                    };
            List<GroupMember> gMemberList = new List<GroupMember>();
            List<GroupMember> grpMemDelList = new List<GroupMember>();
            Set<Id> userIdSet = new Set<Id>();
            
            Map<String,String> grpMap = new Map<String,String>();
            
            if(!accIdSet.isEmpty()){
                for(User rec:[SELECT Id,AccountId FROM User WHERE AccountId IN:accIdSet AND IsActive = TRUE]){
                    if(!accUserMap.containsKey(rec.AccountId)){
                        accUserMap.put(rec.accountId,new List<User>());
                    }
                    accUserMap.get(rec.AccountId).add(rec);
                    userIdSet.add(rec.Id);
                }
                
                For(Group grp:[SELECT id,DeveloperName FROM Group WHERE DeveloperName IN :groupIdList]){
                    grpMap.put(grp.DeveloperName,grp.Id);
                }
            }
            if(!userIdSet.isEmpty()){
                for(GroupMember grpMemRec:[SELECT Id,GroupId,UserOrGroupId FROM GroupMember 
                                           WHERE UserOrGroupId IN :userIdSet AND group.DeveloperName IN :groupIdList]){
                    if(!grpMemMap.containsKey(grpMemRec.groupId)){grpMemMap.put(grpMemRec.groupId,new Map<String,GroupMember>());
                    }
                    grpMemMap.get(grpMemRec.groupId).put(grpMemRec.UserOrGroupId,grpMemRec);
                }
            }
            if(!grpMap.isEmpty()){
                for(Account newAcc:accList){
                    if(accUserMap.get(newAcc.Id) != null){
                        for(User userRec:accUserMap.get(newAcc.Id)){
                            if(newAcc.Program_Type__c != null){
                                if(String.valueOf(newAcc.Program_Type__c).contains('Referral') && grpMap.get(System.Label.Referral_Program_Partner_Group_Id) != null){
                                    GroupMember grpMmberVar = grpMmbrAddCheck(grpMap.get(System.Label.Referral_Program_Partner_Group_Id),userRec,grpMemMap);
                                    if(grpMmberVar != null) gMemberList.add(grpMmberVar);
                                }else if(grpMap.get(System.Label.Referral_Program_Partner_Group_Id) != null){
                                    GroupMember grpMemId = grpMmbrDltCheck(grpMap.get(System.Label.Referral_Program_Partner_Group_Id),userRec,grpMemMap);
                                    if(grpMemId != null) grpMemDelList.add(grpMemId);
                                }
                                if(String.valueOf(newAcc.Program_Type__c).contains('Resale') && grpMap.get(System.Label.Resale_Program_Partner_Group_Id) != null){
                                    GroupMember grpMmberVar = grpMmbrAddCheck(grpMap.get(System.Label.Resale_Program_Partner_Group_Id),userRec,grpMemMap);
                                    if(grpMmberVar != null) gMemberList.add(grpMmberVar);
                                }else if(grpMap.get(System.Label.Resale_Program_Partner_Group_Id) != null){
                                    GroupMember grpMemId = grpMmbrDltCheck(grpMap.get(System.Label.Resale_Program_Partner_Group_Id),userRec,grpMemMap);
                                    if(grpMemId != null) grpMemDelList.add(grpMemId);
                                }
                            }
                            if(newAcc.Partner_Description__c != null && grpMap.get(System.Label.Insurance_Partner_Group_Id) != null && (String.valueOf(newAcc.Partner_Description__c).Contains('Carrier')||String.valueOf(newAcc.Partner_Description__c).Contains('Broker')||String.valueOf(newAcc.Partner_Description__c).Contains('Captive'))){
                                GroupMember grpMmberVar = grpMmbrAddCheck(grpMap.get(System.Label.Insurance_Partner_Group_Id),userRec,grpMemMap);
                                if(grpMmberVar != null) gMemberList.add(grpMmberVar);
                            }else if(grpMap.get(System.Label.Insurance_Partner_Group_Id) != null){
                                GroupMember grpMemId = grpMmbrDltCheck(grpMap.get(System.Label.Insurance_Partner_Group_Id),userRec,grpMemMap);
                                if(grpMemId != null) grpMemDelList.add(grpMemId);
                            }
                            if(grpMap.get(System.Label.Service_Partner_Group_Id) != null && newAcc.ServicesIntegration_Program_Type__c != null && String.isNotBlank(newAcc.ServicesIntegration_Program_Type__c)){
                                GroupMember grpMmberVar = grpMmbrAddCheck(grpMap.get(System.Label.Service_Partner_Group_Id),userRec,grpMemMap);
                                if(grpMmberVar != null) gMemberList.add(grpMmberVar);
                            }else if(grpMap.get(System.Label.Service_Partner_Group_Id) != null){
                                GroupMember grpMemId = grpMmbrDltCheck(grpMap.get(System.Label.Service_Partner_Group_Id),userRec,grpMemMap);
                                if(grpMemId != null) grpMemDelList.add(grpMemId);
                            }
                        }
                    }
                }
            }
            if(!gMemberList.isEmpty()) DMLWrapper.doInsert(gMemberList);
            if(!grpMemDelList.isEmpty()) DMLWrapper.doDelete(grpMemDelList);
            
            DMLWrapper.publishDML();
        }
    /**
    * Description: This method contains the logic to check exsisting group members parter documentation gorups and add group memeber if doesnt exist
    * @Param : groupId - partner documentaion group Id
    * @Param : userRec - updated account related user
    * @Param : grpMemMap - Map of partner gorup and group member
    */
    public static GroupMember grpMmbrAddCheck(String groupId, User userRec,Map<String,Map<String,GroupMember>> grpMemMap){
        GroupMember grpMemberVar;
        if(grpMemMap.ContainsKey(groupId)){
            if(grpMemMap.get(groupId).get(userRec.Id)== null){grpMemberVar = new GroupMember(GroupId = groupId, UserOrGroupId = userRec.Id);}
        }else{
            grpMemberVar = new GroupMember(GroupId = groupId, UserOrGroupId = userRec.Id);
        }
        return grpMemberVar;
    }
    /**
    * Description: This method contains the logic to check exsisting group members parter documentation gorups and delete if exist
    * @Param : groupId - partner documentaion group Id
    * @Param : userRec - updated account related user
    * @Param : grpMemMap - Map of partner gorup and group member
    */
    public static GroupMember grpMmbrDltCheck(String groupId, User userRec, Map<String,Map<String,GroupMember>> grpMemMap){
        GroupMember grpMemberVar;
        if(grpMemMap.ContainsKey(groupId)){
            if(grpMemMap.get(groupId).get(userRec.Id)!= null){grpMemberVar = grpMemMap.get(groupId).get(userRec.Id);}
        }
        return grpMemberVar;
    }
    //11/03/23 vijaychandra --END-- (GTMS-14030)
}