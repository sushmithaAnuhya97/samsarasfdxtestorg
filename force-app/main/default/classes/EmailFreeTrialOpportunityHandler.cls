public class EmailFreeTrialOpportunityHandler {

    @InvocableMethod (label = 'Send Return Free Trial Reminder Email' description='Send Email to Free Trial Optys related to a Revenue Opportunity if the Trial Purchase is "Partial Buy" or "No Buy"' category = 'Opportunity')
    public static void sendFreeTrialEmail(List<Id> OppIds){

        Id oppId = OppIds[0];

        Opportunity opp = [SELECT Id, Name, Owner.email, OwnerId, Owner.Name, Account.Name, 
                                (SELECT Id, Name FROM Opportunities__r WHERE StageName = 'Closed Won' AND Type = 'Free Trial Opportunity') 
                            FROM Opportunity WHERE Id =:oppId ];

        string emailSubject = System.Label.Free_Trial_Return_Email_Subject.replace('<Opportunity Account Name>', opp.Name);
        string emailBodyLinks = '';
        string emailBodyContent = System.Label.Free_Trial_Return_Email_Body.replace('<Opportunity Account Name>', opp.Name);
        string baseUrl = URL.getOrgDomainURL().toExternalForm();

        for(Opportunity trialOpp :opp.Opportunities__r){

            emailBodyLinks += '<br/>Trial Opportunity: <a href ="'+baseUrl+'/flow/Create_Free_Trial_Return?OpportunityId='+trialOpp.Id+'" >'+trialOpp.Name+'</a>';
        }

        if (String.isBlank(emailBodyLinks)) return;

        emailBodyLinks = '<br/>Revenue Opportunity: <a href ="'+baseUrl+'/'+opp.Id+'" >'+opp.Name+'</a>'+emailBodyLinks;

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] {opp.Owner.Email};
        message.setOrgWideEmailAddressId(Utility.getOrgWideEmailAddressBasedOnAddress('no-reply@samsara.com').Id);
        message.subject = emailSubject;
        message.setHtmlBody(emailBodyContent+emailBodyLinks);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {message});
    }    
}