@isTest
private class SlackInboundAlertTest{

    @isTest
    public static void testSlack(){
        User u = [SELECT Id FROM User WHERE Name = 'Ron Saavedra' LIMIT 1][0];
        Account acct = new Account(Name = 'Testing 123', OwnerId = u.Id, Organization_Size__c = '1 - 99', Industry = 'Unknown', BillingCountry = 'United States', BillingState = 'California', Prospecting_Status__c = 'ADR Prospecting');
        insert acct;

        Contact ctc = new Contact(FirstName = 'Testy', LastName = 'McTesterson', AccountId = acct.Id);
        insert ctc;

        List<SlackInboundAlert.InboundCampaignMember> cmList = new List<SlackInboundAlert.InboundCampaignMember>();
        SlackInboundAlert.InboundCampaignMember cm = new SlackInboundAlert.InboundCampaignMember();
        cm.ownerSlackUserId = '@ron.saavedra';
        cm.contactName = 'Testy McTesterson';
        //cm.contactLastName = 'McTesterson';
        cm.accountName = 'Testing 123';
        cm.contactId = ctc.Id;
        cm.SlackSwitch = false;
        //GTMS-21676 by Manjusha Jammula 
        cm.accountOwner = acct.Owner.Name;
        cm.accProspectingStatus = acct.Prospecting_Status__c;
        cm.campaignName = 'Campaign Event-Tradeshow';
        cm.campaignType = 'Website - Conversational Chat';
        cm.campaignMemberStatus = 'Responded' ;
        cm.campaignOwner = 'TestUser';
        //End GTMS-21676
        cmList.add(cm);
    
        SlackInboundAlert.postToSlackInbound(cmList);
    }

    public class mockCallout implements HttpCalloutMock{

        public HttpResponse respond(HttpRequest request){
            HttpResponse res = new HttpResponse();
            res.setBody( '{"text":"value"}');
            res.setStatusCode(200);
            return res;
        }   
    }

}