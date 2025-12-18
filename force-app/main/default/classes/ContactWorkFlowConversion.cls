/**
 * Created by vikasmishra on 2020-12-07.
 */

public without sharing class ContactWorkFlowConversion {
    public static Slack_Enabled_Campaign_Type__mdt slackEnabledCampaignTypes = [
            SELECT Contact_To_Campaign_Member_Fields__c
            FROM Slack_Enabled_Campaign_Type__mdt
            LIMIT 1
    ];
    public static void processCampaignToAdd(Contact thisContact) {

        List<String> targetFields = new List<String>();
        targetFields =
                slackEnabledCampaignTypes.Contact_To_Campaign_Member_Fields__c != null ?
                        slackEnabledCampaignTypes.Contact_To_Campaign_Member_Fields__c.split(',') : new List<String>();

        for (String token : targetFields) {
            thisContact.put(token.trim(), null);
        }
    }
}