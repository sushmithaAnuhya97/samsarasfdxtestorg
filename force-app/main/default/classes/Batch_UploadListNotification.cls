/*
 * @Author : Siddharth Kumar Mishra
 * @Description : GTMS - 6447  -  4/20/2022  -  Notification activites to remind Admin users to upload list of MX Non Compliant tax payers
 * @note : to run the job :System.schedule('Schedule Job Name 1',  '0 0 8 1 FEB,MAY,AUG,NOV ? *', new Batch_UploadListNotification());
*/
    public class Batch_UploadListNotification implements Database.Batchable<sObject>,Schedulable
{
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    
    //START METHOD
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        //set<Id> testIDs = new set<Id>{'0054p000003EpK6AAK'};
        //String query = 'select id,name from User where Id in :testIDs'; 
        
        List<String> registeredUsers = System.Label.MX_Non_Compliant_Tax_Payers_Uploaders.split(',');
        String query = 'select id,name from User where ID IN :registeredUsers';
        return Database.getQueryLocator(query);
    }
    
    //EXECUTE METHOD
    public void execute(Database.BatchableContext BC, List<User> registeredAdminUsers)
    {   
        try
        {
            sendEmail(registeredAdminUsers);
            createTaskAndSendNotification(registeredAdminUsers);
        }
        catch(exception e)
        {
            thisSamsaraLoggerService.logger.logTrace('GS_TaskRollupHelper. Error Message ::'+ e.getMessage() +' | StackTrace:: '+ e.getStackTraceString());
        }
        finally
        {
            thisSamsaraLoggerService.logger.dispatch();
        }
        
    }
    
    //FINISH METHOD
    public void finish(Database.BatchableContext BC)
    { 
        
    }
    
    public void sendEmail(List<User> registeredAdminUsers)
    {
        //List of emails to be sent
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        String emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Notify_admins_to_update_MX_noncompliant_taxpayers'].Id;
        for(User u: registeredAdminUsers)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSaveAsActivity(false);
            mail.setTemplateId(emailTemplateId);
            mail.setTargetObjectId(u.Id);
            emails.add(mail);
        }
        //Send all emails
        Messaging.sendEmail(emails,false);          
    }
    
    public void createTaskAndSendNotification(List<User> registeredAdminUsers)
    {
        /* Create Task*/
        //List of tasks to be created
        List<Task> uploadTasks = new List<Task>();
        for(User u : registeredAdminUsers)
        {
            Task uploadTask = new Task();
            uploadTask.OwnerId = u.Id;
            uploadTask.Subject = 'Upload List of MX Non Compliant Tax payers';
            uploadTask.Description = 'Please upload the most recent list of noncompliant taxpayers issued by the MX Government to Salesforce. The list can be found at the following link: http://omawww.sat.gob.mx/cifras_sat/Paginas/datos/vinculo.html?page=ListCompleta69B.html';
            uploadTask.Status = 'Open';
            uploadTask.Priority = 'High';
            uploadTasks.add(uploadTask);
        }
        Insert uploadTasks;
        System.debug('Task created ---->'+uploadTasks);
        
        /*Send Custom Notification*/
        //Getting the custom notification
        Id customNotificationId =  [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='Upload_List_of_MX_NonCompliant_Taxpayers'].Id;
        for(Task t : uploadTasks)
        {
            set<String> recipientIds = new set<String>();
            recipientIds.add(t.OwnerId);
            //Send custom notification to all 'System administrator' Users
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setBody('Please upload the most recent list of noncompliant taxpayers issued by the MX Government to Salesforce. The list can be found at the following link: http://omawww.sat.gob.mx/cifras_sat/Paginas/datos/vinculo.html?page=ListCompleta69B.html');
            notification.setTitle('Upload list of MX Non compliant Tax payers');
            notification.setSenderId(Userinfo.getUserId());
            notification.setNotificationTypeId(customNotificationId);
            notification.setTargetId(t.Id); //Redirect to the task created
            notification.send(recipientIds);
        } 
    }
    
    public void execute(SchedulableContext SC)
    {       
        database.executebatch((new Batch_UploadListNotification()),200);
    }
    
}