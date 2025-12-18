/**
 * Created by vikasmishra on 2021-07-01.
 */

public inherited sharing class SamsaraEmailService implements IService{

    public  Messaging.SendEmailResult [] sendEmail(List<Messaging.SingleEmailMessage> emailMessages){
       return Messaging.sendEmail(emailMessages);
    }

    public Messaging.SingleEmailMessage setupEmailMessage(Id targetObjectId, String templateId, Boolean activity){
        return new SetupEmailMessage(targetObjectId, templateId, activity).getEmailMessage();
    }
    public interface IService{
        Messaging.SendEmailResult [] sendEmail(List<Messaging.SingleEmailMessage> emailMessages);
        Messaging.SingleEmailMessage setupEmailMessage (Id targetObjectId, String templateId, Boolean activity);
    }
    public inherited sharing class SetupEmailMessage{
        @TestVisible
        Messaging.SingleEmailMessage emailMessage;
        public SetupEmailMessage(Messaging.SingleEmailMessage emailMessage){
            this.emailMessage = emailMessage;
        }
        public SetupEmailMessage(Id targetObjectId, String templateId, Boolean activity){
            this.emailMessage = new Messaging.SingleEmailMessage();
            this.emailMessage.targetObjectId = targetObjectId;
            this.emailMessage.setTemplateId(templateId);
            this.emailMessage.setSaveAsActivity(activity);
        }

        public Messaging.SingleEmailMessage getEmailMessage(){
            return this.emailMessage;
        }
    }
}