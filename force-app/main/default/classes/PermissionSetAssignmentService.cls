/**
 * Created by vikasmishra on 2021-06-23.
 */

public without sharing class PermissionSetAssignmentService implements IService{

    @TestVisible
    static ISelector thisPSSelector = new  PermissionSetSelector();
    @TestVisible
    static IDMLHelper thisPSADMLHelper = new PermissionSetAssignmentDMLHelper();
    @TestVisible
    static SamsaraEmailService.IService thisEmailService = new SamsaraEmailService();
    @TestVisible
    static ITemplateSelector thisTemplateSelector = new EmailTemplateSelector();
    @TestVisible
    static IUserSelector thisUserSelector = new UserSelector();
    @TestVisible
    static EmailTemplate thisEmailTemplate = thisTemplateSelector.getTemplateByDeveloperName('Notify_PSM_ON_Conversion');
    @TestVisible
    static PermissionSetAssignmentService.IService thisPSAS = new PermissionSetAssignmentService();

    @Future
    public static void asyncAssignPermissionSetByName(List<Id> userIdsIds, String PermissionSetName){
        try{
            thisPSAS.assignPermissionSetByName(userIdsIds, PermissionSetName);
        }
        catch(Exception ex){
            System.debug('Permission set Assignment to User has been failed with following exception ::::' + ex);
        }
        try{
            System.debug('PSM Email Notification is turned off. To Enable Uncomment bellow code.');
            //Turning off notification for AE Bug
           // new NotifyPSMAboutTheUser().notifyPSM(new Set<Id>(userIdsIds));
        }
        catch(Exception ex){
            System.debug('Notification to PSM has been failed with following exception ::::' + ex);
        }

    }

    public void assignPermissionSetByName(List<Id> userIdsIds, String PermissionSetName){
        List<PermissionSet> PrmSetList = thisPSSelector.getPermissionSetByName(PermissionSetName);
        String pSId = PrmSetList[0] ?.Id;
        List<PermissionSetAssignment> permissionSetAssignments = processUserForAssignment(pSId, userIdsIds);

        thisPSADMLHelper.insertPSA(permissionSetAssignments, false);
    }

    private List<PermissionSetAssignment> processUserForAssignment(String psId, List<Id> ids) {
        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
        for(Id thisId : ids){
            permissionSetAssignments.add(
                    new PermissionSetAssignment(PermissionSetId = psId, AssigneeId = thisId)
            );
        }
        return permissionSetAssignments;
    }


    public inherited sharing class PermissionSetAssignmentDMLHelper implements IDMLHelper{
        public Database.SaveResult[] insertPSA(List<PermissionSetAssignment> permissionSetAssignments, Boolean allOrNothing){
            return Database.insert(permissionSetAssignments, allOrNothing);
        }
    }

    public inherited sharing class PermissionSetSelector implements ISelector{
        public List<PermissionSet> getPermissionSetByName( String permissionSetName){
            return [SELECT Id FROM PermissionSet WHERE Name =: permissionSetName];
        }
    }

    public interface IDMLHelper{
        Database.SaveResult[] insertPSA(List<PermissionSetAssignment> permissionSetAssignments, Boolean allOrNothing);
    }

    public interface ISelector{
        List<PermissionSet> getPermissionSetByName( String permissionSetName);
    }

    public interface IUserSelector{
        List<User> getUsersFromIds( Set<Id> userIds);
    }

    public interface ITemplateSelector{
        EmailTemplate getTemplateByDeveloperName( String templateName);
    }
    public interface IService {
        void assignPermissionSetByName(List<Id> userIdsIds, String PermissionSetName);
    }

    public inherited sharing class NotifyPSMAboutTheUser {
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        public void notifyPSM(Set<Id> userIds){
            for(User thisUser : thisUserSelector.getUsersFromIds(userIds)){
                Messaging.SingleEmailMessage mail = thisEmailService.setupEmailMessage(thisUser.Id, thisEmailTemplate.Id, false);
                mail.setTreatTargetObjectAsRecipient(false);
                mail.setToAddresses(new List<String>{thisUser.Account.OwnerId});
                emailMessages.add(mail);
            }
            for(Messaging.SendEmailResult thisMSR : thisEmailService.sendEmail(emailMessages)){
                if(!thisMSR.isSuccess()){
                    System.debug(JSON.serialize(thisMSR.errors));
                    System.debug('The following error has occurred:- ');
                    for(Messaging.SendEmailError error : thisMSR.errors){
                        System.debug(error.getMessage());
                    }
                }

            }
        }
    }

    public without sharing class UserSelector implements IUserSelector{
        public List<User> getUsersFromIds( Set<Id> userIds){
            return [SELECT Id,
                    Account.OwnerId
            FROM User
            WHERE Id IN : userIds];
        }
    }

    public inherited sharing class EmailTemplateSelector implements ITemplateSelector{
        public EmailTemplate getTemplateByDeveloperName( String templateName){
            return [SELECT Id,
                    DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName =: templateName];
        }
    }

}