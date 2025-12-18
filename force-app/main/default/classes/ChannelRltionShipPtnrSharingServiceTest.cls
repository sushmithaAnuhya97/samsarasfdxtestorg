/**
 * Created by vikasmishra on 2021-07-06.
 */

@IsTest
private class ChannelRltionShipPtnrSharingServiceTest {
    @IsTest
    static void shouldRunSharingForOpportunity() {
        OpportunityTeamMemberServiceMock thisOTMS = new OpportunityTeamMemberServiceMock();
        OpportunityTeamSelectorMock thisOpportunityTeamSelectorMock = new OpportunityTeamSelectorMock();
        ChannelRelationShipPartnerSharingService.thisOTMService = thisOTMS;
        ChannelRelationShipPartnerSharingService.thisOTMSelector = thisOpportunityTeamSelectorMock;
        ChannelRelationShipPartnerSharingService thisService = new  ChannelRelationShipPartnerSharingService();
        thisService.runPartnerSharingForOpportunity(
                new Map<Id, Channel_Relationship__c>{
                        generateId(Channel_Relationship__c.SObjectType, 101) =>
                                new Channel_Relationship__c(
                                        Id = generateId(Channel_Relationship__c.SObjectType, 101),
                                        Opportunity__c = generateId(Opportunity.SObjectType, 101),
                                        Channel_Partner_User_lr__c = generateId(User.SObjectType, 101)
                                )

                },
                new Map<Id, Channel_Relationship__c>()
        );
        System.assert(thisOTMS.methodCalled, 'Should call sharing ');
    }

    @IsTest
    static void shouldRunSharingForOpportunityDelete() {
        OpportunityTeamMemberServiceMock thisOTMS = new OpportunityTeamMemberServiceMock();
        OpportunityTeamSelectorMock thisOpportunityTeamSelectorMock = new OpportunityTeamSelectorMock();
        ChannelRelationShipPartnerSharingService.thisOTMService = thisOTMS;
        ChannelRelationShipPartnerSharingService.thisOTMSelector = thisOpportunityTeamSelectorMock;
        ChannelRelationShipPartnerSharingService thisService = new  ChannelRelationShipPartnerSharingService();
        thisService.runPartnerSharingForOpportunity(
                new Map<Id, Channel_Relationship__c>(),
                new Map<Id, Channel_Relationship__c>{
                        generateId(Channel_Relationship__c.SObjectType, 101) =>
                                new Channel_Relationship__c(
                                        Id = generateId(Channel_Relationship__c.SObjectType, 101),
                                        Opportunity__c = generateId(Opportunity.SObjectType, 101),
                                        Channel_Partner_User_lr__c = generateId(User.SObjectType, 101)
                                )

                }
        );
        System.assert(thisOTMS.methodCalled, 'Should call sharing ');
        System.assert(thisOpportunityTeamSelectorMock.methodCalled, 'Should call Selector ');
    }

    public class OpportunityTeamMemberServiceMock  implements OpportunityTeamMemberService.IService{
        public Boolean methodCalled = false;
        public void runSharingForChannelRelation(OpportunityTeamMemberService.ShareByChannelRelation shareData){
            methodCalled = true;
        }
    }

    public class OpportunityTeamSelectorMock implements OpportunityTeamMemberService.ISelector{
        public Boolean methodCalled = false;
        public List<OpportunityTeamMember> getOpportunityTeamMembersByOppIdAndUserIds(Set<Id> opportunityIds, Set<Id> userIds) {
            methodCalled = true;
            return new List<OpportunityTeamMember>{
                    new OpportunityTeamMember(
                            Id = generateId(OpportunityTeamMember.SObjectType, 101),
                            OpportunityId = generateId(Opportunity.SObjectType, 101),
                            UserId = generateId(User.SObjectType, 101),
                            TeamMemberRole = OpportunityTeamMemberService.CHANNEL_PARTNER_ROLE_CONSTANT
                    )
            };
        }
    }

    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
}