/**
 * Created by vikasmishra on 2021-07-07.
 */

@IsTest
private class SubmitLeadForApprovalControllerTest {

    @IsTest
    static void shouldReturnSuccessfulResponse() {
        SubmitLeadForApprovalControllerServiceMock thisServiceMock = new SubmitLeadForApprovalControllerServiceMock();
        SubmitLeadForApprovalController.thisCtrlService = thisServiceMock;
        System.assert(
                !SubmitLeadForApprovalController.approveLead(new Lead().Id).hasError,
                'Should return successful aura response'
        );
        System.assert(thisServiceMock.methodCalled, 'Should call submitLeadForApprovalByPSM successfully');
    }

    @IsTest
    static void shouldCatchException() {
        SubmitLeadForApprovalControllerServiceFailureMock thisServiceMock =
                new SubmitLeadForApprovalControllerServiceFailureMock();
        SubmitLeadForApprovalController.thisCtrlService = thisServiceMock;
        System.assert(
                SubmitLeadForApprovalController.approveLead(new Lead().Id).hasError,
                'Should return failure aura response'
        );
        System.assert(thisServiceMock.methodCalled, 'Should call submitLeadForApprovalByPSM successfully');
    }

    public class SubmitLeadForApprovalControllerServiceMock implements SubmitLeadForApprovalControllerService.IService{
        Boolean methodCalled = false;
        public void submitLeadForApprovalByPSM(Id thisLeadId){
            methodCalled = true;
        }
    }

    public class SubmitLeadForApprovalControllerServiceFailureMock implements SubmitLeadForApprovalControllerService.IService{
        Boolean methodCalled = false;
        public void submitLeadForApprovalByPSM(Id thisLeadId){
            methodCalled = true;
            throw new DmlException('Something went wrong');
        }
    }

}