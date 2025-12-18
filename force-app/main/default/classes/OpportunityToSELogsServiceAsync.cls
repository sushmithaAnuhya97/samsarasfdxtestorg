public with sharing class OpportunityToSELogsServiceAsync extends BaseAsyncHandler{
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger(); 
    public override String getRequestType(){
        return 'Sales Engineering Logs Job';
    }

    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Sales_Engineering_Log__c.SObjectType
    };

    public static final Date FOLLOW_UP_DATE = System.today().addDays(7);
    public static final String TECH_STAGE_TEXT = Label.Sales_Engineering_Default_Tech_Stage;
    @TestVisible private static Boolean PERFORM_DMLS = true;

    @TestVisible List<Id> recordsIds;
    private Options option;
    
    @TestVisible Map<Id, Opportunity> queriedOppMap;
    private Set<Id> oppIdSetWithLogs;
    private OpportunityToSELogsService serviceRef;

    public override void execute(Async_Request__c ar)
    {
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        option = (Options) JSON.deserialize(ar.Options__c, Options.class);

        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        
        serviceRef = new OpportunityToSELogsService();

        try{
            thisLogger.logTrace('Entering in OpportunityToSELogsServiceAsync');
            switch on option.Operation {
                when 'Insert' {
                    this.handleCreateLogs(recordsIds);
                }
            }
        }catch(Exception ex){
            System.debug('ON EXCEPTION: '+ex.getMessage()+' --- '+ex.getStackTraceString());
            thisLogger.logError(
                'Error in OpportunityToSELogsServiceAsync::',
                new SamsaraLoggerObjectMVP(
                    ex, recordsIds
                )
            );
            throw ex;
        }finally{
            thisLogger.dispatch();
        }
    }

    @TestVisible
    private void fetchOpportunities(List<Id> oppIds){
        if (queriedOppMap == null || queriedOppMap.isEmpty()){
            queriedOppMap = new Map<Id, Opportunity>([
                SELECT Id, SE_Key_Account__c,Owner_Role_Copy__c, StageName, Segment_Sales_Role__c, RecordTypeId, CloseDate, Account.SE_Assignment__c, TrialResolutionOppty__c, TrialResolutionOppty__r.CloseDate, TrialResolutionOppty__r.Notes__c, TrialResolutionOppty__r.Account.SE_Assignment__c
                  FROM Opportunity
                WHERE Id IN :oppIds  AND StageName NOT IN ('Closed Won', 'Closed Lost') AND IsClosed = FALSE
            ]);
        }
    }

    public void handleCreateLogs(List<Id> oppIds){
        fetchOpportunities(oppIds);

        // Get all existing Sales Logs
        fetchExistingLogsForOppId(queriedOppMap);
        
        // Start creating logs
        for (Id oppId : queriedOppMap.keySet()){
            Opportunity opp = queriedOppMap.get(oppId);

            System.debug(JSON.serializePretty(opp));

            if (serviceRef.isEnterprise(opp)){
                if (serviceRef.shouldRunTrial(opp)){
                    this.createLog(
                        opp.TrialResolutionOppty__c,
                        opp.TrialResolutionOppty__r.Account.SE_Assignment__c,
                        opp.TrialResolutionOppty__r.CloseDate,
                        null,
                        null,
                        opp.CloseDate,
                        opp.CloseDate,
                        opp.TrialResolutionOppty__r.Notes__c,
                        opp.Owner_Role_Copy__c
                    );
                } else if (serviceRef.shouldRunStandard(opp)){
                    this.createLog(
                        opp.Id,
                        opp.Account.SE_Assignment__c,
                        opp.CloseDate,
                        null,
                        null,
                        null,
                        null,
                        null,
                        opp.Owner_Role_Copy__c
                    );
                }
            }else if (serviceRef.isKeyAccount(opp) && serviceRef.shouldRunStandard(opp)){
                this.createLog(
                    opp.Id,
                    opp.Account.SE_Assignment__c,
                    opp.CloseDate,
                    FOLLOW_UP_DATE,
                    TECH_STAGE_TEXT,
                    null,
                    null,
                    null,
                    opp.Owner_Role_Copy__c
                );                
            }
        }

        if (PERFORM_DMLS) DMLWrapper.publishDML();
    }

    private Set<Id> getAllOppIdsFromMap(Map<Id, Opportunity> oppMap){
        Set<Id> idSet = new Set<Id>();
        for (Id oppId : oppMap.keySet()){
            Opportunity opp = oppMap.get(oppId);

            idSet.add(oppId);
            if (opp.TrialResolutionOppty__c != null) idSet.add(opp.TrialResolutionOppty__c);
        }

        return idSet;
    }

    @TestVisible
    private void fetchExistingLogsForOppId(Map<Id, Opportunity> oppMap){
        if (oppIdSetWithLogs == null || oppIdSetWithLogs.isEmpty()){
            Set<Id> querySet = this.getAllOppIdsFromMap(oppMap);

            oppIdSetWithLogs = new Set<Id>();
            for (Sales_Engineering_Log__c log : [
                SELECT Opportunity__c
                FROM Sales_Engineering_Log__c
                WHERE Opportunity__c IN :querySet
            ]){
                oppIdSetWithLogs.add(log.Opportunity__c);
            }
        }
    }

    private void createLog(Id opportunityId, Id SE_Assignment, Date techCloseDate, Date SEFollowUpDate, String techStage, Date TrialOpptyCloseDateforInstall, Date TrialOpptyCloseDateforGear, String AENotes, String ownerRoleCopy ){
        if (oppIdSetWithLogs.contains(opportunityId)) return;

           Sales_Engineering_Log__c seLogRec = new Sales_Engineering_Log__c(
                Opportunity__c = opportunityId,
                SE_Assignment__c = SE_Assignment,
                Tech_Close_Date__c = techCloseDate, 
                SE_Follow_Up_Date__c = SEFollowUpDate,
                Tech_Stage__c = techStage,
                Trial_Hardware_Install_date__c = TrialOpptyCloseDateforInstall,
                Trial_gear_ship_date__c = TrialOpptyCloseDateforGear,
                AE_Notes__c = AENotes         
             );
        if (ownerRoleCopy != null && !String.isBlank(ownerRoleCopy) && ownerRoleCopy.contains('EMEA')) {
            seLogRec.RecordTypeId = Schema.SObjectType.Sales_Engineering_Log__c.getRecordTypeInfosByDeveloperName().get('EMEA_SE_Log').getRecordTypeId();
            seLogRec.Key_Account__c = true;
        } 
        DMLWrapper.doInsert(seLogRec);        
    }
    
    public class Options {
        public String Operation {get; set;}
        
        public Options(String operation){
            this.Operation = operation;
        }
    }
}