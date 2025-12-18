/**
 * Created by vikasmishra on 2021-06-24.
 */

public with sharing class OpportunityTeamMemberService implements IService{

    static final String READ_ACCESS_CONSTANT = 'Read';
    @TestVisible
    static final String CHANNEL_PARTNER_ROLE_CONSTANT = 'Channel Partner';
    @TestVisible
    static IDMLHelper thisOTMSDMLHelper = new OTMDMLHelper();
    public void runSharingForChannelRelation(ShareByChannelRelation shareData){
        thisOTMSDMLHelper.insertOpportunityTeamMembers(shareData.opportunityTeamMembersToAdd, true);
        thisOTMSDMLHelper.deleteOpportunityTeamMembers(shareData.opportunityTeamMembersToDelete, true);
    }

    public class ShareByChannelRelation{
        @TestVisible
        List<OpportunityTeamMember> opportunityTeamMembersToAdd = new List<OpportunityTeamMember>();
        @TestVisible
        List<OpportunityTeamMember> opportunityTeamMembersToDelete = new List<OpportunityTeamMember>();
        Set<String> compoundIdentifier = new Set<String>();
        Set<Id> opportunityIds;
        Set<Id> userIds;
        public void processChannelRelationToAdd(Map<Id, Channel_Relationship__c> newMap){
            for(Id so_id : newMap.keySet()){
                Channel_Relationship__c thisCR = newMap.get(so_id);
                if(thisCR.Channel_Partner_User_lr__c == null) {
                    continue;
                }
                opportunityTeamMembersToAdd.add(
                        new OpportunityTeamMember(
                                OpportunityId = thisCR.Opportunity__c,
                                UserId = thisCR.Channel_Partner_User_lr__c,
                                OpportunityAccessLevel = READ_ACCESS_CONSTANT,
                                TeamMemberRole = CHANNEL_PARTNER_ROLE_CONSTANT
                        )
                );
            }


        }

        public void processChannelRelationToRemove(Map<Id, Channel_Relationship__c> oldMap){
            opportunityIds = new Set<Id>();
            userIds = new Set<Id>();
            for(Id so_id : oldMap.keySet()){
                Channel_Relationship__c thisCR = oldMap.get(so_id);
                if(thisCR.Channel_Partner_User_lr__c == null) {
                    continue;
                }
                userIds.add(thisCR.Channel_Partner_User_lr__c);
                opportunityIds.add(thisCR.Opportunity__c);
                compoundIdentifier.add(thisCR.Opportunity__c+ '-'+thisCR.Channel_Partner_User_lr__c);
            }
        }

        public void filterChannelRelationToRemove(List<OpportunityTeamMember> otMembers){
            for(OpportunityTeamMember thisOtm : otMembers){
                String thisKey = thisOtm.OpportunityId + '-' +thisOtm.UserId;
                if(compoundIdentifier?.contains(thisKey)){
                    opportunityTeamMembersToDelete.add(thisOtm);
                }
            }
        }

        public Set<Id> getOpportunityIds(){
            return opportunityIds;
        }

        public Set<Id> getUserIds(){
            return userIds;
        }


    }

    public class OTMDMLHelper implements IDMLHelper{
        public Database.SaveResult[] insertOpportunityTeamMembers(List<OpportunityTeamMember> oTMList, Boolean allOrNothing){
            return Database.insert(oTMList, allOrNothing);
        }

        public Database.DeleteResult[] deleteOpportunityTeamMembers(List<OpportunityTeamMember> oTMList, Boolean allOrNothing){
            return Database.delete(oTMList, allOrNothing);
        }
    }

    public inherited sharing class OpportunityTeamSelector implements ISelector{

        public List<OpportunityTeamMember> getOpportunityTeamMembersByOppIdAndUserIds(Set<Id> opportunityIds, Set<Id> userIds) {
            return [SELECT Id,
                    OpportunityId,
                    UserId
            FROM OpportunityTeamMember
            WHERE OpportunityId IN : opportunityIds
            AND UserId IN : userIds];
        }
    }


    public interface IService{
        void runSharingForChannelRelation(ShareByChannelRelation shareData);
    }

    public interface IDMLHelper{
        Database.SaveResult[] insertOpportunityTeamMembers(List<OpportunityTeamMember> oTMList, Boolean allOrNothing);
        Database.DeleteResult[] deleteOpportunityTeamMembers(List<OpportunityTeamMember> oTMList, Boolean allOrNothing);
    }
    public interface ISelector{
        List<OpportunityTeamMember> getOpportunityTeamMembersByOppIdAndUserIds(Set<Id> opportunityIds, Set<Id> userIds);
    }
}