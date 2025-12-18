/**
 * Created by vikasmishra on 2021-07-07.
 */

@IsTest
private class SubmitLeadForApprovalCtrlServiceTest {
    @IsTest
    static void shouldSuccessfullyCallSubmitLeadForApprovalByPSM() {
        LeadDmlHelperMock thisLeadDmlHelperMock = new LeadDmlHelperMock();
        SubmitLeadForApprovalControllerService.thisLeadDMLHelper = thisLeadDmlHelperMock;

        SubmitLeadToNotreDameMock thisSubmitLeadToNotreDameMock = new SubmitLeadToNotreDameMock();
        SubmitLeadForApprovalControllerService.notreDameService = thisSubmitLeadToNotreDameMock;

        SubmitLeadForApprovalControllerService thisService = new SubmitLeadForApprovalControllerService();
        thisService.submitLeadForApprovalByPSM(new Lead().Id);
        System.assert(
                thisSubmitLeadToNotreDameMock.postLeadToNotreDameMethodCalled,
                'Should call postLeadToNotreDameMethodCalled method'
        );
        System.assert(
                thisSubmitLeadToNotreDameMock.getProcessedLeadRecordMethodCalled,
                'Should call getProcessedLeadRecord method'
        );
        thisService.updateLeadStatus(new Lead());
        System.assert(thisLeadDmlHelperMock.methodCalled, 'Should call updateObjects');

    }

    @IsTest
    static void shouldTestLeadDMLHelper() {
        SubmitLeadForApprovalControllerService.LeadDmlHelper thisLeadDMLHelper =
                new SubmitLeadForApprovalControllerService.LeadDmlHelper();
        System.assert(
                thisLeadDMLHelper.updateObjects(
                        new List<Lead>(),
                        false).isEmpty(),
                'Should return empty list'
        );
    }

    @IsTest
    static void shouldTestLeadDMLHelperError() {
        SubmitLeadForApprovalControllerService.LeadDmlHelper thisLeadDMLHelper =
                new SubmitLeadForApprovalControllerService.LeadDmlHelper();
        System.assert(
                !thisLeadDMLHelper.updateObjects(
                        new List<Lead>{
                                new Lead(
                                        Id = generateId(Lead.SObjectType, 101),
                                        LastName ='Should failed'
                                )
                        },
                        false)[0].errors.isEmpty(),
                'Should return error list'
        );
    }

    public class LeadDmlHelperMock implements SubmitLeadForApprovalControllerService.IDMLHelper{
        Boolean methodCalled = false;
        public Database.SaveResult[] updateObjects(List<Lead> leadList, Boolean allOrNothing) {
            methodCalled = true;
            return new List<Database.SaveResult>();
        }
    }

    public class SubmitLeadToNotreDameMock implements SubmitLeadToNotreDame.IService{
        public Boolean postLeadToNotreDameMethodCalled = false;
        public Boolean getProcessedLeadRecordMethodCalled = false;
        public void postLeadToNotreDame (Id leadId){
            postLeadToNotreDameMethodCalled = true;
        }
        public Lead getProcessedLeadRecord(){
            getProcessedLeadRecordMethodCalled = true;
            return new Lead();
        }
    }
    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
}