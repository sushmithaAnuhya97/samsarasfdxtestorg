public with sharing class GS_OpportunitySlackServiceAsync extends BaseAsyncHandler {
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();

    public override String getRequestType(){
        return 'Opportunity Post to Slack Service Async Job';
    } 
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Opportunity.SObjectType
        //Account.SObjectType
    };
    
    List<Id> recordsIds = new List<Id>();

    private UnitOfWork uow;
    
    public override void execute(Async_Request__c ar){

        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);

        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in GS_OpportunitySlackServiceAsync');
            switch on opt.Operation {
                when 'PUSH_TO_SLACK' {
                    this.postToSlack(recordsIds);
                }
            }
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_OpportunitySlackServiceAsync::', new SamsaraLoggerObjectMVP(
                ex, recordsIds
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.logTrace('Exiting in GS_OpportunitySlackServiceAsync');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    // Replaces: Post Closed Won to Slack
    public void postToSlack(List<Id> idList){

        if(!idList.isEmpty()){
            List<Opportunity> queriedOpptys = (new GS_OpportunitySelector(false)).getOppForPostToSlackServiceById(idList);

            for(Opportunity opp : queriedOpptys){
                // Ideally we could post the entire opp list
                // but the Slack apex method is not equipped to handle multiple Opps
                SlackPublisher.Oppty oppty = new SlackPublisher.Oppty();
                oppty.opptyName = opp.Name;
                oppty.opptyOwnerFN = opp.Owner.FirstName;
                oppty.opptyOwnerLN = opp.Owner.LastName;
                oppty.opptyAmount = opp.Amount_Number_Formula__c;
                oppty.accountName = opp.Account.Name;
                oppty.opptyId = opp.Id;
                oppty.opportunityACVBookings = opp.ACV_Bookings__c;
                SlackPublisher.postToSlack(new List<SlackPublisher.Oppty>{ oppty });
            }
        }
    }
    
    /* public void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    } */
    
    public class Options {
        public String Operation {get; set;}
        
        public Options(String operation){
            this.Operation = operation;
        }
    }
}