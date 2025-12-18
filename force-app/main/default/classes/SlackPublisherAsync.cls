public without sharing class SlackPublisherAsync extends BaseAsyncHandler {

    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();

    public override String getRequestType(){
        return 'Post to Slack Service Async Job';
    }

    public override Boolean isHandlerReadOnly(){
        return true;
    }
    
    List<Id> recordsIds = new List<Id>();
    
    public  static Boolean USE_SANDBOX_URL_FOR_SANDBOX   = true;

    private static final String SANDBOX_CSBELL_SLACK_URL = 'callout:Slack_Publisher_SANDBOX';
    private static final String CSBELL_SLACK_URL         = 'callout:Slack_Publisher_CSBELL';

    private static final String DEFAULT_REQUEST_METHOD   = 'POST';
    private static final String DEFAULT_SUCCESS_RESPONSE = 'ok';

    @TestVisible private static List<Opportunity> TEST_RECORDS_OVERRIDE;

    public override void execute(Async_Request__c ar){

        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);
        
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in SlackPublisherAsync');
            switch on opt.Channel {
                /* when 'PUSH_TO_SLACK' {
                    this.postToSlack(recordsIds);
                } */
                when 'CS_BELL' {
                    postToCSBell(
                        buildNotification((List<Id>) recordsIds)
                    );
                }
            }
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in SlackPublisherAsync::', new SamsaraLoggerObjectMVP(
                ex, recordsIds
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.logTrace('Exiting in SlackPublisherAsync');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
     
    public class CSBellNotification {
        @InvocableVariable(label='Account Name')
        public String accName;
        @InvocableVariable(label='RAE Name')
        public String raeName;
        @InvocableVariable(label='CSM Name')
        public String csmName;    
        @InvocableVariable(label='ACV Bookings')
        public String acvAmount;         
        @InvocableVariable(label='Payment Terms')
        public String paymentTerms; 
        @InvocableVariable(label='License Term')
        public String licenseTerm;   
        @InvocableVariable(label='Opportunity Id')
        public Id oppId;

        public CSBellNotification(){
            this('','','','','','',null);
        }

        public CSBellNotification(
            String accName,
            String raeName,
            String csmName,
            String acvAmount,
            String paymentTerms,
            String licenseTerm,
            Id oppId
        ){
            this.accName      = (String.isNotBlank(accName)      ? accName      : '');
            this.raeName      = (String.isNotBlank(raeName)      ? raeName      : '');
            this.csmName	  = (String.isNotBlank(csmName)      ? csmName      : '');
            this.acvAmount    = (String.isNotBlank(acvAmount)    ? acvAmount    : '');
            this.paymentTerms = (String.isNotBlank(paymentTerms) ? paymentTerms : '');
            this.licenseTerm  = (String.isNotBlank(licenseTerm)  ? licenseTerm  : '');
            this.oppId        = oppId;
        }
    }

    @TestVisible
    private static List<SlackPublisherAsync.CSBellNotification> buildNotification(List<Id> recordIdList){
        List<SlackPublisherAsync.CSBellNotification> notificationList = new List<SlackPublisherAsync.CSBellNotification>();
        for (Opportunity opp : fetchOpportunities(recordIdList)){
            notificationList.add(new SlackPublisherAsync.CSBellNotification(
                opp.Account.Name,
                opp.Account.Renewal_AE__r.Name,
                opp.Account.SIC__r.Name,
                (!Test.isRunningTest() ? (String) opp.get('acv') : String.valueOf(opp.ACV_Bookings__c)),
                opp.Selected_Payment_Type__c,
                String.valueOf(opp.License_Term__c),
                opp.Id
            ));
        }

        return notificationList;
    }

    @TestVisible
    private static List<Opportunity> fetchOpportunities(List<Id> recordIdList){
        return (Test.isRunningTest() && TEST_RECORDS_OVERRIDE != null ? TEST_RECORDS_OVERRIDE : [
            SELECT Id, Account.Name, Account.Renewal_AE__r.Name, Account.SIC__r.Name, FORMAT(ACV_Bookings__c) acv, Selected_Payment_Type__c, License_Term__c
              FROM Opportunity
             WHERE Id IN :recordIdList
        ]);
    }
    
    @InvocableMethod(label='Post Deal to Slack CSBell')
    public static void postToCSBell ( List<CSBellNotification> notification ) {
        CSBellNotification n = notification[0]; // bulkify the code later

        String notificationTemplate =
            'Congratulations to {0}, {1} and everyone who helped support {2} for a successful renewal! This customer has renewed their partnership with us and is in closing for {3} and paying {4} for {5} months.\nSee details at {6}';

        Map<String,Object> msg = new Map<String,Object>();
        msg.put('text', String.format(notificationTemplate, new List<String>{
            n.raeName,
            n.csmName,
            n.accName,
            n.acvAmount,
            n.paymentTerms,
            n.licenseTerm,
            getRecordUrl(n.oppId)
        }));
        msg.put('mrkdwn', true);

        executeCallout(
            (isSandbox() ? SANDBOX_CSBELL_SLACK_URL : CSBELL_SLACK_URL),
            DEFAULT_REQUEST_METHOD,
            JSON.serialize(msg)
        );
    }

    @TestVisible
    private static String getRecordUrl(Id recordId){
        return System.Url.getSalesforceBaseURL().toExternalForm()+(recordId != null ? '/'+String.valueOf(recordId) : '');
    }

    @TestVisible
    private static Boolean isSandbox(){
        return USE_SANDBOX_URL_FOR_SANDBOX && [SELECT IsSandbox FROM Organization LIMIT 1]?.IsSandbox;
    }


    public static void executeCallout(String url, String method, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        req.setBody(body);
        Http http = new Http();
        if (!Test.isRunningTest()){
            HttpResponse res = http.send(req);
            if (res.getBody() != DEFAULT_SUCCESS_RESPONSE) throw new FailedSlackCalloutException('Unexpected Slack API response:\n'+res.getStatusCode()+'/'+res.getStatus()+'\n'+res.getBody());
        }
    }
    
    public class Options {
        public String Channel {get; set;}
        
        public Options(String Channel){
            this.Channel = Channel;
        }
    }

    public class FailedSlackCalloutException extends Exception{}
}