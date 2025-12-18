/**********************************************************************
Name: RRAssignmentMappingHandler
=======================================================================
Purpose: This class will logic to RR Mapping trigger handler                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Aug-02        INITIAL DEVELOPMENT FOR GTMS-13494

***********************************************************************/ 
public class RRAssignmentMappingHandler extends TriggerHandler {
    private Map<Id, RR_Assignment_Mapping__c> oldRRAssignmentMap;
	private Map<Id, RR_Assignment_Mapping__c> newRRAssignmentMap;
	private List<RR_Assignment_Mapping__c> newRRAssignmentList;
    private RRAssignmentMappingHelper mappingHelper;
    @TestVisible private static Integer maxRuns = 1;
    @TestVisible private static Map<String, Integer> methodsCalled = new Map<String, Integer>();
    
	public RRAssignmentMappingHandler() {
        mappingHelper = new RRAssignmentMappingHelper();
		this.oldRRAssignmentMap = (Map<Id, RR_Assignment_Mapping__c >) Trigger.oldMap;
		this.newRRAssignmentMap = (Map<Id, RR_Assignment_Mapping__c >) Trigger.newMap;
		this.newRRAssignmentList = (List<RR_Assignment_Mapping__c >) Trigger.new;
		
	}
    public override void beforeInsert() {
    }
    
    public override void afterInsert() {
        if (timesCalled('afterInsert') < maxRuns) {
            mappingHelper.performAssignNextAssignment(newRRAssignmentList, newRRAssignmentMap);
            addCall('afterInsert');
        }
    }
    
    public override void beforeUpdate() {
    }
    
    public override void afterUpdate() {
        if (timesCalled('afterUpdate') < maxRuns) {
            mappingHelper.updateRuleNextAssignment(newRRAssignmentList, oldRRAssignmentMap);
            addCall('afterUpdate');
        }
    }
    
    public override void beforeDelete() {
        if (timesCalled('beforeDelete') < maxRuns) {
            //system.debug('RODRIGO before Delete');
            //system.debug('RODRIGO before Delete newRRAssignmentList ' + newRRAssignmentList);
            mappingHelper.performDeleteNextAssignment(newRRAssignmentList, oldRRAssignmentMap);
            addCall('beforeDelete');
        }
    }
    
    public override void afterDelete() {
        if (timesCalled('afterDelete') < maxRuns) {
            //system.debug('RODRIGO After Delete');
            //system.debug('RODRIGO After Delete newRRAssignmentList ' + newRRAssignmentList);
            //RRAssignmentMappingHelper.performDeleteNextAssignment(newRRAssignmentList, oldRRAssignmentMap);
            addCall('afterDelete');
        }
    }
    
    public static integer timesCalled(String Input) {

        if (!methodsCalled.containsKey(Input)) {
            return 0;
        } else {
            return methodsCalled.get(Input);
        }

    }

    public static integer addCall(String Input) {

        if (!methodsCalled.containsKey(Input)) {
            methodsCalled.put(input, 1);
        } else {
            Integer i = methodsCalled.get(input) + 1;
            methodsCalled.put(input, i);
        }

        return methodsCalled.get(input);
    }
}