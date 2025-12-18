global class sendEmail{
    public static void sendEmailMethod(string EmailTemplateName,string toEmailAddress,string ccEmailAddress, string opptyID){
        opportunity opp=[select id,AccountId,OwnerId from opportunity where Id =: opptyID];
        list<contact> contactList=[select id from contact where AccountId=:opp.AccountId limit 1];
        
        OrgWideEmailAddress owa = [select id, DisplayName, Address from OrgWideEmailAddress limit 1];
        EmailTemplate templateId = [Select  id, Subject, Body from EmailTemplate where name =: EmailTemplateName];
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateID(templateId.Id);
        mail.setSaveAsActivity(false);
       // mail.setOrgWideEmailAddressId(owa.id);
        mail.setToAddresses(new String[]{toEmailAddress});
        mail.setCcAddresses(new String[]{ccEmailAddress});
        if(contactList.size()>0)
        mail.setTargetObjectId(contactList[0].id);
         mail.setWhatId(opp.id);

        allmsg.add(mail);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}