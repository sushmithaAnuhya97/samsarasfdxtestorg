/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 17, 2021
*
* @description : This class will be responsible for handling all the Campaign Member Related Queries
* SFA-14
*
**/
public with sharing class GS_CampaignMemberSelector extends GS_SObjectBaseSelector{
        
    public GS_CampaignMemberSelector(boolean checkFatalError){
        super(checkFatalError);
    }
    
    public GS_CampaignMemberSelector checkFatalError(){
        return (GS_CampaignMemberSelector) super.validateFatalError();
    }


    public List<CampaignMember> getCampaignMemberByAgeDays(List<Contact> contactOwnerChangesFromPool){
        List<CampaignMember> campaignMemberList = new List<CampaignMember>();
        campaignMemberList = [SELECT  Id,
                                Owner_At_Interaction__c,
                                ContactId,
                                Account__r.RR_Assigned_On__c,
                                Owner_at_Interaction_Lookup__r.RR_Is_Pool_User__c,
                                Campaign_Interaction_Date__c
                                FROM CampaignMember
                                WHERE ContactId IN: contactOwnerChangesFromPool
                                AND ContactId != NULL
                                AND Campaign_Member_Age_Days__c <= 2
                                ORDER BY CreatedDate DESC];
        return campaignMemberList;
    }
}