/* 
 * 01/10/19 - Epic SS-245 @author: Harsha
 * 02/11/2020 - Update to slacks
 * 9/3/20 Ron (GTMS-1504) QueueableSlackCall (add debug statement to log the status code + response body for REST calls)
 */

public with sharing class SlackInboundAlert {

    private static final String channelSlackURL = 'https://hooks.slack.com/services/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';
    private static final String personalSlackURL = 'https://slack.com/api/chat.postMessage';
    private static Integer maxQueueable = 1;

    public class InboundCampaignMember {
        @InvocableVariable(label='Contact Id')
        public String contactId;
        @InvocableVariable(label='Owner Slack UserId')
        public String ownerSlackUserId;
        //GTMS-22839 by Firdoss
        @InvocableVariable(label='LeadScore')
        public String leadScore;
        @InvocableVariable(label='Owner Slack Username')
        public String ownerSlackUsername;
        //@InvocableVariable(label='Contact First Name')
        //public String contactFirstName;
        //@InvocableVariable(label='Contact Last Name')
        //public String contactLastName;        
        @InvocableVariable(label='AccountName')
        public String accountName;
        //GTMS-21676 by Manjusha Jammula
        @InvocableVariable(label='AccProspectingStatus')
        public String accProspectingStatus;
        @InvocableVariable(label='AccADRAssignment')
        public String accADRAssignment;
        @InvocableVariable(label='Contact Name')
        public String contactName;
        @InvocableVariable(label='AccountOwner')//acc owner
        public String accountOwner;
        @InvocableVariable(label='CampaignName')//Campaign Name
        public String campaignName;
        @InvocableVariable(label='CampaignType')//Campaign Type
        public String campaignType;
        @InvocableVariable(label='CampaignMemberStatus')//Campaign Member Status
        public String campaignMemberStatus;
        @InvocableVariable(label='CampaignOwner')//Campaign Owner
        public String campaignOwner;
        //END GTMS-21676
        @InvocableVariable(label='SlackSwitch')
        public Boolean slackSwitch;
    }

    @InvocableMethod(label='Post Inbound to Slack Inbound Channel')
    public static void postToSlackInbound(List<InboundCampaignMember> campaignMembers) {
        String url;
        Slack_Enabled_Campaign_Type__mdt slackCampaignTypes = [SELECT Token__c FROM Slack_Enabled_Campaign_Type__mdt LIMIT 1][0];
        String token = slackCampaignTypes.Token__c;

        for (InboundCampaignMember cm : campaignMembers){
            Map<String,Object> msg = new Map<String,Object>();
            String URLs = System.URL.getSalesforceBaseUrl().toExternalForm();
            /*msg.put('text', 'Hello '+cm.ownerSlackUserName+', *'+cm.contactFirstName+' '+cm.contactLastName+'* from *'
                    +cm.accountName+'* just came in as an inbound contact! Contacts called before 1 min have a 4x chance of connecting, give them a call now!\n' 
                    + '<' + URLs + '/'+cm.contactId+ '>');*/
            
            //GTMS-21676 by Manjusha Jammula  
            String accountOwnerOrAdrAssigned;
            if(cm.accProspectingStatus == 'ADR Prospecting' && cm.accADRAssignment != null)
                accountOwnerOrAdrAssigned = cm.accountOwner+' & '+cm.accADRAssignment;   
            else
                accountOwnerOrAdrAssigned = cm.accountOwner;
                              
            msg.put('text', 'Hello '+accountOwnerOrAdrAssigned+', *'+cm.contactName+'* from *'+cm.accountName+'* just came in as a *'+cm.leadScore+'* inbound lead \n'
                    +'More Details: This Contact is marked as *'+cm.campaignMemberStatus+'* for the *'+cm.campaignName+'* (*'+cm.campaignType+'*) For questions about this campaign, reach out to *'+cm.campaignOwner+'*\n'
                    + '<' + URLs + '/'+cm.contactId+ '>');    
            //END GTMS-21676
            
            msg.put('link_names', true);

            if(cm.slackSwitch){
                msg.put('channel', cm.ownerSlackUserId);
                msg.put('as_user', true);
                url = personalSlackURL;
            }
            else{
                url = channelSlackURL;
            }

            String body = JSON.serialize(msg);
            SlackMessageService.getInstance().register(
                    new SlackMessageService.SlackMessagePayload(
                            url,
                            'POST',
                            body,
                            token
                    )
            );
        }
    }

}