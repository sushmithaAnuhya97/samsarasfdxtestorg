public with sharing class GS_OpportunityNetSuiteServiceAsync extends BaseAsyncHandler {
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();

    public override String getRequestType(){
        return 'Opportunity Post to Net Suite Service Async Job';
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
            thisSamsaraLoggerService.logger.logTrace('Entering in GS_OpportunityNetSuiteServiceAsync');
            switch on opt.Operation {
                when 'RELATED_RECORDS_UPDATE' {
                    this.executeRelatedOpportunityUpdate(recordsIds);
                }
            }

            this.publishDMLs();
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_OpportunityNetSuiteServiceAsync::', new SamsaraLoggerObjectMVP(
                ex, recordsIds
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.logTrace('Exiting in GS_OpportunityNetSuiteServiceAsync');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    private void executeRelatedOpportunityUpdate(List<Id> idList){
        List<Opportunity> oppList = (new GS_OpportunitySelector(false)).getOppForPostToNetSuiteServiceById(idList);
        
        for (Opportunity opp : oppList){
            // Nodes in this code path are going to update fields on related Opportunities
            // which indicate they need to push a return to Netsuite
            Opportunity oppToUpdate;
            /* Replaces Node 'Revenue Opportunity with Buyout Going to Closed Won' */
            if(opp.Buyout_Opportunity__c != null){
                oppToUpdate = this.createRelatedOppObjectForUpdate(opp.Buyout_Opportunity__c, true, opp.CloseDate);
            }
            /* Replaces Node 'Revenue Opportunity with Subsidy Going to Closed Won' */
            else if(opp.Subsidy_Opportunity__c != null){
                oppToUpdate = this.createRelatedOppObjectForUpdate(opp.Subsidy_Opportunity__c, true, opp.CloseDate);
            }
            /* Replaces Node 'Revenue Opportunity with Referral Going to Closed Won' */ 
            else if (opp.Partner_Referral_Opportunity__c != null) {
                oppToUpdate = this.createRelatedOppObjectForUpdate(opp.Partner_Referral_Opportunity__c, true, opp.CloseDate);
            }
            if (oppToUpdate.Id != null) DMLWrapper.doUpdate(oppToUpdate, new List<SobjectField>{
                Opportunity.Push_Return_to_Netsuite__c, 
                Opportunity.CloseDate
            });
        }
    }
    
    public void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }

    private Opportunity createRelatedOppObjectForUpdate(Id recordId, Boolean pushToNetsuite, Date closeDate){
        return new Opportunity(
            Id                         = recordId,
            Push_Return_to_Netsuite__c = pushToNetsuite,
            CloseDate                  = closeDate
        );
    }
    
    public class Options {
        public String Operation {get; set;}
        
        public Options(String operation){
            this.Operation = operation;
        }
    }
}