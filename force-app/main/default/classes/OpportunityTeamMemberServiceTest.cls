/**
 * Created by vikasmishra on 2021-07-06.
 */

@IsTest
private class OpportunityTeamMemberServiceTest {
    @IsTest
    static void shouldRunSharing() {
        OTMDMLHelperMock thisOTMDMLHelperMock = new OTMDMLHelperMock();
        OpportunityTeamMemberService.thisOTMSDMLHelper = thisOTMDMLHelperMock;
        OpportunityTeamMemberService thisService = new OpportunityTeamMemberService();
        thisService.runSharingForChannelRelation(new OpportunityTeamMemberService.ShareByChannelRelation());
        System.assert(
                thisOTMDMLHelperMock.insertOpportunityTeamMembersMethodCalled,
                'insertOpportunityTeamMembers should be called'
        );
        System.assert(
                thisOTMDMLHelperMock.deleteOpportunityTeamMembersMethodCalled,
                'deleteOpportunityTeamMembers should be called'
        );

    }

    @IsTest
    static void shouldTestOTMDMLHelper(){
        OpportunityTeamMemberService.OTMDMLHelper thisDMLHelper = new OpportunityTeamMemberService.OTMDMLHelper();

        System.assert(
                thisDMLHelper.insertOpportunityTeamMembers(
                        new List<OpportunityTeamMember>(),
                        true).isEmpty(),
                'Should be Empty List'
        );

        System.assert(
                thisDMLHelper.deleteOpportunityTeamMembers(
                        new List<OpportunityTeamMember>(),
                        true).isEmpty(),
                'Should be Empty List'
        );
    }

    @IsTest
    static void shouldTestOpportunityTeamSelector(){
        OpportunityTeamMemberService.OpportunityTeamSelector thisSelector =
                new OpportunityTeamMemberService.OpportunityTeamSelector();

        System.assert(
                thisSelector.getOpportunityTeamMembersByOppIdAndUserIds(
                        new Set<Id>(), new Set<Id>()
                ).isEmpty(),
                'Should be Empty List'
        );

    }

    @IsTest
    static void shouldTestShareByChannelRelationAdd(){
        OpportunityTeamMemberService.ShareByChannelRelation thisRelation =
                new OpportunityTeamMemberService.ShareByChannelRelation();
        thisRelation.processChannelRelationToAdd(
                new Map<Id, Channel_Relationship__c>{
                        generateId(
                                Channel_Relationship__c.SObjectType,
                                101) => new Channel_Relationship__c(
                                Id = generateId(
                                        Channel_Relationship__c.SObjectType,
                                        101
                                ),
                                Channel_Partner_User_lr__c = generateId(
                                        User.SObjectType,
                                        101
                                ),
                                Opportunity__c = generateId(
                                        Opportunity.SObjectType,
                                        101
                                )
                        )
                }
        );

        System.assert(
                thisRelation.opportunityTeamMembersToAdd[0].OpportunityId ==
                        generateId(
                                Opportunity.SObjectType,
                                101
                        ),
                'Should have opportunity Id'
        );
    }

    @IsTest
    static void shouldTestShareByChannelRelationRemove(){
        OpportunityTeamMemberService.ShareByChannelRelation thisRelation =
                new OpportunityTeamMemberService.ShareByChannelRelation();
        thisRelation.processChannelRelationToRemove(
                new Map<Id, Channel_Relationship__c>{
                        generateId(
                                Channel_Relationship__c.SObjectType,
                                101) => new Channel_Relationship__c(
                                Id = generateId(
                                        Channel_Relationship__c.SObjectType,
                                        101
                                ),
                                Channel_Partner_User_lr__c = generateId(
                                        User.SObjectType,
                                        101
                                ),
                                Opportunity__c = generateId(
                                        Opportunity.SObjectType,
                                        101
                                )
                        )
                }
        );

        thisRelation.filterChannelRelationToRemove(
                new List<OpportunityTeamMember>{
                        new OpportunityTeamMember(
                                OpportunityId = generateId(
                                        Opportunity.SObjectType,
                                        101),
                                UserId = generateId(
                                        User.SObjectType,
                                        101
                                )
                        )
                }
        );

        System.assert(
                thisRelation.opportunityTeamMembersToDelete[0].OpportunityId ==
                        generateId(
                                Opportunity.SObjectType,
                                101
                        ),
                'Should have opportunity Id'
        );
        System.assert(
                thisRelation.getUserIds().contains(
                        generateId(
                                User.SObjectType,
                                101
                        )
                ),
                'Should Contain User Ids'
        );

        System.assert(
                thisRelation.getOpportunityIds().contains(
                        generateId(
                                Opportunity.SObjectType,
                                101
                        )
                ),
                'Should Contain Opportunity Ids'
        );
    }

    public class OTMDMLHelperMock implements OpportunityTeamMemberService.IDMLHelper{
        public Boolean insertOpportunityTeamMembersMethodCalled = false;
        public Boolean deleteOpportunityTeamMembersMethodCalled = false;
        public Database.SaveResult[] insertOpportunityTeamMembers(List<OpportunityTeamMember> oTMList, Boolean allOrNothing){
            insertOpportunityTeamMembersMethodCalled = true;
            return new List<Database.SaveResult>();
        }

        public Database.DeleteResult[] deleteOpportunityTeamMembers(List<OpportunityTeamMember> oTMList, Boolean allOrNothing){
            deleteOpportunityTeamMembersMethodCalled = true;
            return new List<Database.DeleteResult>();
        }
    }

    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
}