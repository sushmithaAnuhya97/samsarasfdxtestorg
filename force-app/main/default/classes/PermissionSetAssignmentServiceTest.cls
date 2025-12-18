/**
 * Created by vikasmishra on 2021-07-05.
 */

@IsTest
private class PermissionSetAssignmentServiceTest {
    @IsTest
    static void shouldAssignPermissionSet() {
        PSSelectorMock thisPSSelectorMock = new PSSelectorMock();
        PermissionSetAssignmentService.thisPSSelector = thisPSSelectorMock;
        PSADMLHelperMock thisPSADMLHelperMock = new PSADMLHelperMock();
        PermissionSetAssignmentService.thisPSADMLHelper = thisPSADMLHelperMock;
        TemplateSelectorMock thisTemplateSelectorMock = new TemplateSelectorMock();
        PermissionSetAssignmentService.thisTemplateSelector =thisTemplateSelectorMock;
        PermissionSetAssignmentService.thisEmailTemplate = thisTemplateSelectorMock.getTemplateByDeveloperName('Test');
        UserSelectorMock thisUserSelectorMock = new UserSelectorMock();
        PermissionSetAssignmentService.thisUserSelector = thisUserSelectorMock;
        PermissionSetAssignmentService thisService = new PermissionSetAssignmentService();
        thisService.assignPermissionSetByName(new List<Id>(), 'TestName');
        System.assert(thisPSADMLHelperMock.methodCalled, 'Permission Set Assignment DMl should be called');
        System.assert(thisPSSelectorMock.methodCalled, 'Permission Set Selector method should be called');
        System.assert(thisTemplateSelectorMock.methodCalled, 'Template Selector should be called');

    }
    @IsTest
    static void testPermissionSetAssignmentDMLHelper(){
        PermissionSetAssignmentService.PermissionSetAssignmentDMLHelper thisDMLHelper =
                new PermissionSetAssignmentService.PermissionSetAssignmentDMLHelper();

        System.assert(thisDMLHelper.insertPSA(new List<PermissionSetAssignment>(), true).isEmpty(), 'Should return empty list');

    }

    @IsTest
    static void testPermissionSetSelector(){
        PermissionSetAssignmentService.PermissionSetSelector thisPMS =
                new PermissionSetAssignmentService.PermissionSetSelector();
        System.assert(
                thisPMS.getPermissionSetByName('Test').isEmpty(),
                'Should return empty list of Permission Set'
        );
    }

    @IsTest
    static void testUserSelector(){
        PermissionSetAssignmentService.UserSelector thisUserSelector =
                new PermissionSetAssignmentService.UserSelector();
        System.assert(
                thisUserSelector.getUsersFromIds(new Set<Id>{UserInfo.getUserId()})[0].Id == UserInfo.getUserId(),
                'Should return context user'
        );
    }

    @IsTest
    static void testNotifyPSMAboutTheUser(){
        SamsaraEmailServiceMock thisEmailServiceMock = new SamsaraEmailServiceMock();
        PermissionSetAssignmentService.thisEmailService = thisEmailServiceMock;
        PermissionSetAssignmentService.NotifyPSMAboutTheUser notifyPSMAboutTheUser =
                new PermissionSetAssignmentService.NotifyPSMAboutTheUser();
                notifyPSMAboutTheUser.notifyPSM(new Set<Id>{UserInfo.getUserId()});
        System.assert(thisEmailServiceMock.setupEmailMessageMethod, 'Should Set up single message');
        System.assert(thisEmailServiceMock.sendEmailMethod, 'Should call email method');

    }

    public class PSSelectorMock implements PermissionSetAssignmentService.ISelector{
        Boolean methodCalled = false;
        public List<PermissionSet> getPermissionSetByName( String permissionSetName){
            methodCalled = true;
            return new List<PermissionSet>{new PermissionSet(Name = 'Test',
                    Id = PermissionSetAssignmentServiceTest.generateId(PermissionSet.SObjectType, 101) )};
        }
    }

    public class UserSelectorMock implements PermissionSetAssignmentService.IUserSelector{
        Boolean methodCalled = false;
        public List<User> getUsersFromIds( Set<Id> userIds){
            methodCalled = true;
            return new List<User>{
                    new User(Id = PermissionSetAssignmentServiceTest.generateId(User.SObjectType, 101))
            };
        }
    }

    public class TemplateSelectorMock implements PermissionSetAssignmentService.ITemplateSelector{
        public Boolean methodCalled = false;
        public EmailTemplate getTemplateByDeveloperName( String templateName){
            methodCalled = true;
            return new EmailTemplate(
                    Id = PermissionSetAssignmentServiceTest.generateId(EmailTemplate.SObjectType, 101)
            );
        }
    }

    public class PSADMLHelperMock implements PermissionSetAssignmentService.IDMLHelper{
       public Boolean methodCalled = false;
        public Database.SaveResult[] insertPSA(List<PermissionSetAssignment> permissionSetAssignments, Boolean allOrNothing){
            methodCalled = true;
            Database.SaveResult sr = (Database.SaveResult)
                    JSON.deserialize('{"success":true,"id":"'+PermissionSetAssignmentServiceTest.generateId(PermissionSetAssignment.SObjectType,101) + '"}', Database.SaveResult.class);
            return new List<Database.SaveResult>{sr};
        }
    }

    public class SamsaraEmailServiceMock implements SamsaraEmailService.IService{
        Boolean sendEmailMethod = false;
        Boolean setupEmailMessageMethod = false;
       public Messaging.SendEmailResult [] sendEmail(List<Messaging.SingleEmailMessage> emailMessages){
           sendEmailMethod = true;
            return new List<Messaging.SendEmailResult>() ;
        }
       public  Messaging.SingleEmailMessage setupEmailMessage (Id targetObjectId, String templateId, Boolean activity){
            setupEmailMessageMethod = true;
            return new Messaging.SingleEmailMessage();
        }
    }

    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
}