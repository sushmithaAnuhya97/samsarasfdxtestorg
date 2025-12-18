@isTest
public class PlatformEventForAmendContractTest {
 
    @testSetup
    private static void testDataSetup() {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ContractAccount');
        insert acc;
        Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(130),
                ContractTerm = 12
        );
        insert contract;
    }
    
    @isTest
    public static void testPost() {
        Contract ctt = [SELECT Id, StartDate FROM Contract LIMIT 1];
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/amendContracts/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response= res;
        
        String response = PlatformEventForAmendContract.doPost(ctt.Id);
    }
    
    @isTest
    public static void testPost_InvalidContractId() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/amendContracts/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response= res;
        
        String response = PlatformEventForAmendContract.doPost(null);
    }
    
    @isTest
    public static void testPost_QuoteJSONISBlank() {
        Contract ctt = [SELECT Id, StartDate FROM Contract LIMIT 1];
        PlatformEventForAmendContract.createPlatformEvent(null,ctt.Id);
    }
    
    @isTest
    public static void testPost_QuoteJSONISNotBlank() {
        Contract ctt = [SELECT Id, StartDate FROM Contract LIMIT 1];
        String quoteJSON = '{"record":{"Id":"a8ODK0000004mJr2AI","SBQQ__Account__c":"0014p00001iUfNfAAK","SBQQ__Opportunity2__c":"006DK00000DGOEDYA5"}}';
        PlatformEventForAmendContract.createPlatformEvent(quoteJSON,ctt.Id);
    }
}