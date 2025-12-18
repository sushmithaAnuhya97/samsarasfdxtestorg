/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 17, 2021
*
* @description : This class will be responsible for handling all the Campaign Related Queries
* SFA-11
*
**/
public with sharing class GS_CampaignSelector extends GS_SObjectBaseSelector{

    public GS_CampaignSelector(Boolean checkFatalError){
        super(checkFatalError);
    }
     
    public GS_CampaignSelector checkFatalError(){
        return (GS_CampaignSelector) super.validateFatalError();
    }
    
 
    public List<Campaign> getCampaigns(String CAMPAIGN_EMAIL ,String CAMPAIGN_CHATBOT, String CAMPAIGN_REFERRAL){
        
        List<Campaign> campaignList = [SELECT  Id,
                                       Name
                                       FROM Campaign
                                       WHERE Name IN (:CAMPAIGN_EMAIL, :CAMPAIGN_CHATBOT, :CAMPAIGN_REFERRAL)];
        return campaignList;
    }

}