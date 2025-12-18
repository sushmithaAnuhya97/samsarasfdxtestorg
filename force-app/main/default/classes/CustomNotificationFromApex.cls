/**
 * @description       : 
 * @author            : navees.ahmed@samsara.com
 * @group             : 
 * @last modified on  : 06-06-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class CustomNotificationFromApex {
    public static String Contract_Consolidation='Contract_Consolidation';
    public static void notifyUsers(Set<String> recipientsIds, String targetId,String notificationDeveloperName,String notificationTitle,String notificationBody) {

        // Get the Id for our custom notification type
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName,CustomNotifTypeName 
             FROM CustomNotificationType 
             WHERE DeveloperName=:notificationDeveloperName];
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle((String.isBlank(notificationTitle)?notificationType.CustomNotifTypeName:notificationTitle));
        notification.setBody(notificationBody);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
        
        // Actually send the notification
        try {
            notification.send(recipientsIds);
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
}