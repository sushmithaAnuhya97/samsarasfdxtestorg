public with sharing class GS_OpportunitySendEmailAsync extends BaseAsyncHandler{
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();

    public override String getRequestType(){
        return 'OpportunitySendEmailAsync Async Job';
    }

    List<Id> recordsIds;
    List<Opportunity> opptyList;
    public GS_OpportunityCacheService oppCache = new GS_OpportunityCacheService();
    public override void execute(Async_Request__c ar){

        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in GS_OpportunitySendEmailAsync');   
            switch on opt.Operation {
                when 'SEND_RETURN_EMAIL_OPERATIONS' {	
                    this.loadOpportunities(recordsIds);
                    this.sendReturnEmails();
                }
            }
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_OpportunitySendEmailAsync::', new SamsaraLoggerObjectMVP(
                ex, recordsIds
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.logTrace('Exiting in GS_OpportunitySendEmailAsync');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    private void loadOpportunities(List<Id> idList){
        if (opptyList == null){
            this.opptyList = (new GS_OpportunitySelector(false)).loadOpportunityWithItems(new Set<Id>(idList));
        }
    }
    
    private void sendReturnEmails(){
        Map<Id, Opportunity> returnOpptysToEmail = new Map<Id, Opportunity>();

        for (Opportunity newOpp : this.opptyList) {
            returnOpptysToEmail.put(newOpp.Id, newOpp);
        }

        if (!returnOpptysToEmail.isEmpty()) {
            ReturnLabelEmailer.sendReturnEmails(returnOpptysToEmail);
        }
    } 


    public void sendReturnLabelEmail(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOpportunityList) {
        // Could be modified to a process builder
        Set<Id> opptyIdsSet = new Set<Id>();
        for (Opportunity newOppty : newOpportunityList) {
            if (newOppty.type == 'Free Trial Return' || newOppty.type == 'Exchange' || newOppty.type == 'Remorse Refund'|| newOppty.type == 'Warranty Exchange') {
                if (newOppty.Return_Label_Attachment__c != null && ((!System.Label.Commercial_Invoice_Inernational_Shipment.contains(newOppty.Shipping_Country__c) && (newOppty.StageName != oldOppMap.get(newOppty.Id).StageName && newOppty.StageName == 'Return Label Sent')) 
                    || (System.Label.Commercial_Invoice_Inernational_Shipment.contains(newOppty.Shipping_Country__c) && newOppty.Return_Label_Attachment__c != oldOppMap.get(newOppty.Id).Return_Label_Attachment__c 
                        && newOppty.Return_Label_Attachment__c.contains(',') && newOppty.StageName == 'Return Label Sent')
                    || (newOppty.Resend_Return_Email__c != oldOppMap.get(newOppty.Id).Resend_Return_Email__c && newOppty.Resend_Return_Email__c))) {
                    if (newOppty.Tracking_Number__c != NULL && newOppty.Shipping_Address_NEW__c != NULL) {
                        opptyIdsSet.add(newOppty.Id);                        
                    }
                }
            }
        }
        if (!opptyIdsSet.isEmpty()) {
            DMLWrapper.doInsert(new GS_OpportunitySendEmailAsync().prepareAsyncRequests(
                JSON.serialize(new GS_OpportunitySendEmailAsync.Options('SEND_RETURN_EMAIL_OPERATIONS')),
                opptyIdsSet
            )); 
        }
    }

    public class Options {
        public String Operation {get; set;}

        public Options(String operation){
            this.Operation = operation;
        }
        
    }
}