public without sharing class OpportunityToSELogsService {

    private Map<String, Schema.RecordTypeInfo> rTypeMap;
    private final fflib_SObjectUnitOfWork uow;

    public OpportunityToSELogsService(){
        this.rTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        this.uow = new fflib_SObjectUnitOfWork(
            new List<Schema.SObjectType>{
                Opportunity.SObjectType,
                Async_Request__c.SObjectType
            }
        );
    }

    public void runAfter(Map<Id, Opportunity> oppMap){
        Set<Id> idsToProcess = new Set<Id>();

        for (Id oppId : oppMap.keySet()){
            Opportunity opp = oppMap.get(oppId);

            if (this.isEnterprise(opp) && (this.shouldRunStandard(opp) || this.shouldRunTrial(opp))){
                // Create Enterprise SE Logs
                idsToProcess.add(oppId);
            }else if (this.isKeyAccount(opp) && this.shouldRunStandard(opp)){
                // Create SE Logs
                idsToProcess.add(oppId);
            }
        }
          try{
            if (!idsToProcess.isEmpty()){
                List<Async_Request__c> asyncRequests = new OpportunityToSELogsServiceAsync().prepareAsyncRequests(
                    JSON.serialize(new OpportunityToSELogsServiceAsync.Options('Insert')), 
                    idsToProcess
                );

                for(Async_Request__c request : asyncRequests) {
                    uow.registerNew(request);
                }

                uow.commitWork();
                DMLWrapper.doInsert(asyncRequests);
            }
        } catch(Exception e) {
            // Log the error and throw custom exception
            System.debug(LoggingLevel.ERROR, 'Error in OpportunityToSELogsService: ' + e.getMessage());
        }
       /* if (!idsToProcess.isEmpty()){
            DMLWrapper.doInsert(
                new OpportunityToSELogsServiceAsync().prepareAsyncRequests(
                    JSON.serialize(new OpportunityToSELogsServiceAsync.Options('Insert')), 
                    idsToProcess
                )
            );
        }*/
    }

    public Boolean isEnterprise(Opportunity opp){
        return (opp.Segment_Sales_Role__c == 'Enterprise');
    }

    public Boolean isKeyAccount(Opportunity opp){
        return (opp.SE_Key_Account__c);
    }

    public Boolean shouldRunTrial(Opportunity opp){
        return (opp.RecordTypeId == rTypeMap.get('Trial').getRecordTypeId() && opp.StageName == 'Closed Won' && opp.TrialResolutionOppty__c != null);
    }

    public Boolean shouldRunStandard(Opportunity opp){
        return (opp.RecordTypeId == rTypeMap.get('Standard_Opportunity').getRecordTypeId() && opp.StageName == 'Trial');
    }
}