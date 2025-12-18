/**
 * Created by vikasmishra on 2021-06-28.
 */

public with sharing class ChannelRelationShipPartnerSharingService implements IService{
    @TestVisible
    static OpportunityTeamMemberService.IService thisOTMService = new OpportunityTeamMemberService();
    @TestVisible
    static OpportunityTeamMemberService.ISelector thisOTMSelector = new OpportunityTeamMemberService.OpportunityTeamSelector();
    public void runPartnerSharingForOpportunity(Map<Id, Channel_Relationship__c> newMap, Map<Id,Channel_Relationship__c> oldMap){
        OpportunityTeamMemberService.ShareByChannelRelation shareByChannelRelation =
                new OpportunityTeamMemberService.ShareByChannelRelation();
        if(oldMap.isEmpty()){
            shareByChannelRelation.processChannelRelationToAdd(newMap);
        }
        else if(!oldMap.isEmpty()){
            shareByChannelRelation.processChannelRelationToRemove(oldMap);
            shareByChannelRelation.filterChannelRelationToRemove(
                    thisOTMSelector.getOpportunityTeamMembersByOppIdAndUserIds(
                            shareByChannelRelation.getOpportunityIds(),
                            shareByChannelRelation.getUserIds()
                    ));
        }

        thisOTMService.runSharingForChannelRelation(shareByChannelRelation);

    }

   public interface IService{
       void runPartnerSharingForOpportunity(Map<Id, Channel_Relationship__c> newMap, Map<Id,Channel_Relationship__c> oldMap);
   }
}