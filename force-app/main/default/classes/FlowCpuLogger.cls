public with sharing class FlowCpuLogger {
    // Static variable to temporarily hold start time during one transaction
    public static Long startCpuTime;
    public static set<string> logExecution = new set<string>();

    public class CpuTrackingInput {
        @InvocableVariable(required=true description='Action type: START or END')
        public String action;
        @InvocableVariable(description='Opportunity Record/SObject Record')
        public Id objId; 
        @InvocableVariable(description='Functionality Name')
        public String functionalityName;
    }

    @InvocableMethod(label='CPU Time Tracker' description='Tracks Apex CPU time for a Flow. Use START or END as action.')
    public static void trackCpuTime(List<CpuTrackingInput> requests) {
        SamsaraLogEntries__c log = new SamsaraLogEntries__c(); 
        Long usedCpu;
        Set<Id> sobjIds = new Set<id>();
        for (CpuTrackingInput req : requests) {
            if (req.action == null) continue;
            
            String actionType = req.action.trim().toUpperCase();

            if (actionType == 'START') {
                startCpuTime = Limits.getCpuTime();
            } 
            else if (actionType == 'END' && startCpuTime != Limits.getCpuTime()) {
                usedCpu = (startCpuTime != null) ? (Limits.getCpuTime() - startCpuTime) : Limits.getCpuTime();
                
                if(usedCpu != null){
                    Logger logRec = new Logger();
                    Logger.LogContext logContext = logRec.createLogContext((System.LoggingLevel.INFO));
                    log.RecordId__c = req.objId;
                    log.sourceApiName__c = req.functionalityName==null ? 'Flow' : req.functionalityName;
                    log.SourceMetadataType__c = 'Flow';
                    log.CPU_Time__c = usedCpu;
                    log.Level__c = 'INFO';
                    logContext.stageLog(log);
                    sobjIds.add(req.objId);
                }
            }
        }

        try{
            Logger.setRecordIds(sobjIds);
            Logger.insertMasterLogs();
        }catch(Exception e) {
                LOGGER.atError().setClassName('FlowCPULogger').setExceptionOrMessage(e);
                Logger.setFunctionalityType('Flow'); 
                Logger.insertMasterLogs();
            }
        }
    }