/**
 * Created by vikasmishra on 2021-07-07.
 */

@IsTest
public class SubmitLeadToNotreDameTest {
    static final String NOTRE_DAME_ENDPOINT = 'Callout:NotreDame_API';
    @IsTest
    static void shouldDoSuccessfulPost() {
        LeadSelectorMock thisLeadSelectorMock = new LeadSelectorMock();
        SubmitLeadToNotreDame.thisLeadSelector = thisLeadSelectorMock;
        SubmitLeadToNotreDame thisSubmitLeadToNotreDame = new SubmitLeadToNotreDame();
        Test.setMock(HttpCalloutMock.class, new NotreDameHTTPServiceTestMocks());
        thisSubmitLeadToNotreDame.postLeadToNotreDame(new Lead().Id);
        System.assert(thisLeadSelectorMock.methodCalled, 'Should call getLeadById');
        System.assert(
                thisSubmitLeadToNotreDame.getProcessedLeadRecord().Id == generateId(Lead.SObjectType, 101),
                'Should return mocked lead with sequence 101'
        );

    }

    @IsTest
    static void shouldTestLeadSelector() {
        SubmitLeadToNotreDame.LeadSelector thisSelector = new SubmitLeadToNotreDame.LeadSelector();
        System.assert(thisSelector.getLeadById(new Lead().Id).isEmpty(), 'Should return empty list');
    }

    public class LeadSelectorMock implements SubmitLeadToNotreDame.ISelector{
        public Boolean methodCalled = false;
        public List<Lead> getLeadById (Id thisId){
            methodCalled = true;
            return new List<Lead>{
                    new Lead (
                            Id = generateId(Lead.SObjectType, 101)
                    )
            };
        }
    }

    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
    
    public class NotreDameHTTPServiceTestMocks implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            if(req.getEndpoint().contains(NOTRE_DAME_ENDPOINT)){
                System.assertEquals('POST', req.getMethod());
                res.setBody('{"status":"success"}');
                res.setStatusCode(200);
            }
            else if(req.getEndpoint().contains('fail')){
                res.setBody('{"status":"success"}');
                res.setStatusCode(200);
            }
            else{
                res.setBody('{"status":"success"}');
                res.setStatusCode(400);
            }

            return res;


        }
    }
	
}