/* ClassName - ReturnOwnerCopyDataUtility
 * Author - devansh.pathak@samsara.com
 * Functionality - This class is is used to update owner and copy fields on Rebate Delinquent or Remorse Refund Opportunity
 * JIRA: GTMS-29333; GTMS-27863
 *
 */
public class ReturnOwnerCopyDataUtility {

    //Invocation - OpportunityTriggerHelperContext -> Before Insert / Before Update
    //This method assigns owner based on revenue opportunity owner and stamped copy fields
    public static void updateReturnOwner(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        
        Set<Id> returnIds = new Set<Id>();
        Map<Id, Id> rebateOppByOwnerId = new Map<Id, Id>();
        
        for(Opportunity oppRec : newOppList) {
            
            if(((oppRec.type == 'Remorse Refund')
                || (oppRec.type=='Rebate' && oppRec.rebate_type__c=='Delinquent'))
               && oppRec.Returning_Opportunity__c != null
               && ((oldOppMap == null //If return is created
                    || (oldOppMap != null && oppRec.Returning_Opportunity__c != oldOppMap.get(oppRec.Id).Returning_Opportunity__c)))) //If Returning_Opportunity__c is updated on return opportunity
               {
                   returnIds.add(oppRec.Returning_Opportunity__c);
               }
        }
        
        if(!returnIds.isEmpty()){
            rebateOppByOwnerId = getOwnerForDelinquentRebateOpportunity(returnIds);
        }
        
        for(Opportunity oppRec : newOppList) {
            if(returnIds.contains(oppRec.Returning_Opportunity__c)
               && rebateOppByOwnerId != null
               && rebateOppByOwnerId.containsKey(oppRec.Returning_Opportunity__c)) 
            {
                oppRec.ownerId = rebateOppByOwnerId.get(oppRec.Returning_Opportunity__c);
            }
        }
    }
    
    public static Map<Id, Id> getOwnerForDelinquentRebateOpportunity(Set<Id> revenueOppIdSet){
        
        Map<String, Id> defaultUsers = new Map<String, Id>();
        Map<Id, Id> oppByOwnerId = new Map<Id, Id>();
        Map<Id, Opportunity> revOppData = new Map<Id, Opportunity>();

        if(!revenueOppIdSet.isEmpty()){
            revOppData = getReturnAndRebateOpps(revenueOppIdSet);
        }

        defaultUsers = getUserForOwnerId();
        for(Id revOppId : revOppData.keySet()){
            Opportunity revenueOpp = revOppData.get(revOppId);
            oppByOwnerId.put(revOppId, getOwnerIdForRebateOpp(revenueOpp, defaultUsers));
        }

        return oppByOwnerId;
    }
    
    private static Id getOwnerIdForRebateOpp(Opportunity returnOpp, Map<String, Id> defaultUsers){
        Id rebateOwnerId = null;
        String AEUser = System.Label.RebateDefaultUserAmitVyas;
        String entUser = System.Label.RebateDefaultUserClintNelson;
        String defUser = System.Label.RebateDefaultUserAndyMcCall;
        
        Set<String> segmentCodesForAE = new Set<String> (System.Label.RebateAESegment.split(','));
        String segmentCodesForEnterprise = System.Label.RebateEnterpriseSegment;
        
        if(returnOpp.Owner.isActive){
            rebateOwnerId = returnOpp.OwnerId;
        }else if(returnOpp.Owner_Manager_Name_Copy__c != null && returnOpp.Owner_Manager_Name_Copy__r.isActive){
            rebateOwnerId = returnOpp.Owner_Manager_Name_Copy__c;
        }else if(returnOpp.Owner_Director_Name_Copy__c != null && returnOpp.Owner_Director_Name_Copy__r.isActive){
            rebateOwnerId = returnOpp.Owner_Director_Name_Copy__c;
        }else if(segmentCodesForAE.contains(returnOpp.Owner_Segment__c)){
            rebateOwnerId = defaultUsers.containsKey(AEUser) ? defaultUsers.get(AEUser) : defaultUsers.get(defUser);
        }else if(segmentCodesForEnterprise.contains(returnOpp.owner_segment__c)){
            rebateOwnerId= defaultUsers.containsKey(entUser) ? defaultUsers.get(entUser) : defaultUsers.get(defUser);
        }else{
            rebateOwnerId =  defaultUsers.get(defUser);
        }
        
        return rebateOwnerId;
    }
    
    private static Map<String, Id> getUserForOwnerId(){
        List<String> userNames = new List<String>();
        userNames.add(System.Label.RebateDefaultUserAmitVyas);
        userNames.add(System.Label.RebateDefaultUserClintNelson);
        userNames.add(System.Label.RebateDefaultUserAndyMcCall);
        Map<String, Id> userNameById = new Map<String, Id>();
        List<user> usrs = [Select Id, name from user where Name in :userNames and isActive = true];
        for(User usr : usrs){
            userNameById.put(usr.name, usr.Id);
        }
        return userNameById;
    }
    
    private static Map<Id, Opportunity> getReturnAndRebateOpps(Set<Id> oppIds){
        return new Map<Id, Opportunity>([SELECT Id, OwnerId, owner.isActive, 
                                         Owner_Manager_Name_Copy__c, Owner_Manager_Name_Copy__r.isActive, 
                                         Owner_Director_Name_Copy__c, Owner_Director_Name_Copy__r.isActive, 
                                         Owner_Segment__c, Owner_Director_Email_Copy__c
                                         FROM Opportunity
                                         WHERE id in: oppIds]);
    }
    
    //This method assigns copy fields for Rebate and Remorse Refund opportunity from revenue opportunity or owner heirarchy
    //isInsertOrLinked - True -> if Return is created OR method is called from RelatedReturnOpportunityController to link Swap
    //isInsertOrLinked - False -> if Return is updated 
    public static Opportunity updateCopyFields(Opportunity returnOpp, Opportunity oldOpp, Opportunity revOpp, Map<Id, User> mapUsers, Boolean isInsertOrLinked) {
        
        If((returnOpp.Returning_Opportunity__c != null
            && (returnOpp.type == 'Remorse Refund'
                || (returnOpp.type == 'Rebate' && returnOpp.Rebate_Type__c == 'delinquent')))
           || returnOpp.Overwrite_Validation_Rule__c)
        {
            
            If(isInsertOrLinked
               || (!isInsertOrLinked
                   && ((returnOpp.Returning_Opportunity__c != oldOpp.Returning_Opportunity__c && returnOpp.Returning_Opportunity__c != null)
                       || (returnOpp.Type != oldOpp.Type && returnOpp.Type == 'Remorse Refund' && oldOpp.Type == 'Revenue Opportunity'))))
            {
                returnOpp.Owner_Role_Copy__c = (String) updateReturnCopyFieldsFromRevenue(revOpp, 'Owner Role');
                returnOpp.Owner_Manager_Name_Copy__c = (Id) updateReturnCopyFieldsFromRevenue(revOpp, 'Manager Name');
                returnOpp.Owner_Manager_Role_Copy__c = (String) updateReturnCopyFieldsFromRevenue(revOpp, 'Manager Role');
                returnOpp.Owner_Manager_Email_Copy__c = (String) updateReturnCopyFieldsFromRevenue(revOpp, 'Manager Email');
                returnOpp.Owner_Director_Name_Copy__c = (Id) updateReturnCopyFieldsFromRevenue(revOpp, 'Director Name');
                returnOpp.Owner_Director_Role_Copy__c = (String) updateReturnCopyFieldsFromRevenue(revOpp, 'Director Role');
                returnOpp.Owner_Director_Email_Copy__c = (String) updateReturnCopyFieldsFromRevenue(revOpp, 'Director Email');
                returnOpp.Owner_AVP_Name_Copy__c = (String) updateReturnCopyFieldsFromRevenue(revOpp, 'AVP Name');
                returnOpp.Owner_AVP_Role_Copy__c = (String) updateReturnCopyFieldsFromRevenue(revOpp, 'AVP Role');
            }
            
            else if(!isInsertOrLinked
               && returnOpp.ownerId != oldOpp.ownerId
               && mapUsers != null
               && mapUsers.containsKey(returnOpp.ownerId)
               && mapUsers.get(returnOpp.ownerId) != null) 
            {
                User opportunityOwner = mapUsers.get(returnOpp.ownerId);
                
                returnOpp.Owner_Role_Copy__c = (String) updateReturnCopyFieldsFromUser(opportunityOwner, 'Owner Role');
                returnOpp.Owner_Manager_Name_Copy__c = (Id) updateReturnCopyFieldsFromUser(opportunityOwner, 'Manager Name');
                returnOpp.Owner_Manager_Role_Copy__c = (String) updateReturnCopyFieldsFromUser(opportunityOwner, 'Manager Role');
                returnOpp.Owner_Manager_Email_Copy__c = (String) updateReturnCopyFieldsFromUser(opportunityOwner, 'Manager Email');
                returnOpp.Owner_Director_Name_Copy__c = (Id) updateReturnCopyFieldsFromUser(opportunityOwner, 'Director Name');
                returnOpp.Owner_Director_Role_Copy__c = (String) updateReturnCopyFieldsFromUser(opportunityOwner, 'Director Role');
                returnOpp.Owner_Director_Email_Copy__c = (String) updateReturnCopyFieldsFromUser(opportunityOwner, 'Director Email');
                returnOpp.Owner_AVP_Name_Copy__c = (String) updateReturnCopyFieldsFromUser(opportunityOwner, 'AVP Name');
                returnOpp.Owner_AVP_Role_Copy__c = (String) updateReturnCopyFieldsFromUser(opportunityOwner, 'AVP Role');
            }
        }
        return returnOpp;
    }
    
    private static Object updateReturnCopyFieldsFromRevenue(Opportunity revOpp, String managerType) {
        Object returnObject = null; 
        switch on managerType {
            when 'Owner Role' {
                returnObject = revOpp.Owner_Role_Copy__c;
            }
            when 'Manager Name' {
                returnObject = revOpp.Owner_Manager_Name_Copy__c;
            }
            when 'Manager Role' {
                returnObject = revOpp.Owner_Manager_Role_Copy__c;
            }
            when 'Manager Email' {
                returnObject = revOpp.Owner_Manager_Email_Copy__c;
            }
            when 'Director Name' {
                returnObject = revOpp.Owner_Director_Name_Copy__c;
            }
            when 'Director Role' {
                returnObject = revOpp.Owner_Director_Role_Copy__c;
            }
            when 'Director Email' {
                returnObject = revOpp.Owner_Director_Email_Copy__c;
            }
            when 'AVP Name' {
                returnObject = revOpp.Owner_AVP_Name_Copy__c;
            }
            when 'AVP Role' {
                returnObject = revOpp.Owner_AVP_Role_Copy__c;
            }
        }
        return returnObject;
    }
    
    @testVisible
    private static Object updateReturnCopyFieldsFromUser(User opportunityOwner, String managerType) {
        Object returnObject = null; 
        switch on managerType {
            when 'Owner Role' {
                if(opportunityOwner.userroleId != null) {
                    returnObject = opportunityOwner.userrole.name;
                }
            }
            when 'Manager Name' {
                if(opportunityOwner.managerId != null) {
                    returnObject = opportunityOwner.managerId;
                }
            }
            when 'Manager Role' {
                if(opportunityOwner.managerId != null && opportunityOwner.manager.userroleId != null) {
                    returnObject = opportunityOwner.manager.userrole.name;
                }
            }
            when 'Manager Email' {
                if(opportunityOwner.managerId != null) {
                    returnObject = opportunityOwner.manager.email;
                }
            }
            when 'Director Name' {
                if(opportunityOwner.managerId != null && opportunityOwner.manager.managerId != null) {
                    returnObject = opportunityOwner.manager.managerId;
                }
            }
            when 'Director Role' {
                if(opportunityOwner.managerId != null && opportunityOwner.manager.managerId != null && opportunityOwner.manager.manager.userroleId != null) {
                    returnObject = opportunityOwner.manager.manager.userrole.name;
                }
            }
            when 'Director Email' {
                if(opportunityOwner.managerId != null && opportunityOwner.manager.managerId != null) {
                    returnObject = opportunityOwner.manager.manager.email;
                }
            }
            when 'AVP Name' {
                if(opportunityOwner.managerId != null && opportunityOwner.manager.managerId != null 
                   &&  opportunityOwner.manager.manager.managerId != null) 
                {
                    returnObject = opportunityOwner.manager.manager.manager.name;
                }
            }
            when 'AVP Role' {
                if(opportunityOwner.managerId != null && opportunityOwner.manager.managerId != null 
                   &&  opportunityOwner.manager.manager.managerId != null && opportunityOwner.manager.manager.manager.userroleId != null) 
                {
                    returnObject = opportunityOwner.manager.manager.manager.userrole.name;
                }
            }
        }
        return returnObject;
    }
    
}