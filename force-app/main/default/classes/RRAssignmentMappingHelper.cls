/**********************************************************************
Name: RRAssignmentMappingHelper
=======================================================================
Purpose: This class will logic to RR Mapping trigger helper                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Aug-02        INITIAL DEVELOPMENT FOR GTMS-13494
1.1.       Rodrigo Carpio.       2024-Jul-16.       added updateNextAssignmentFromRuleFlag identifier that update is initiated from rule next assignment update
***********************************************************************/ 
public class RRAssignmentMappingHelper {
    public void updateRuleNextAssignment(List<RR_Assignment_Mapping__c> rrMappingList, Map<Id, RR_Assignment_Mapping__c> oldRRMappingMap){
        Set<Id> idForUpdateTrue = new Set<Id>();
        Set<Id> idForUpdateFalse = new Set<Id>();
        Set<Id> idForInactiveTrue = new Set<Id>();
        Set<Id> idForInactiveFalse = new Set<Id>();
        // loop thru all mapping records
        FOR (RR_Assignment_Mapping__c currRec : rrMappingList) {
            //RR_Assignment_Mapping__c oldRec = oldRRMappingMap.get(currRec.Id);
            RR_Assignment_Mapping__c oldRec = (oldRRMappingMap==null) ? null : oldRRMappingMap.get(currRec.Id);
            
            // check if Pause Assignment field is change to true
            if ((oldRec!=null && (oldRec.Pause_Assignment__c != currRec.Pause_Assignment__c)) 
                || (oldRec==null && currRec.Active__c==true)) {
                //RoundRobinHandler.updateRuleNextAssignmentFuture(currRec.User__c, currRec.Pause_Assignment__c);
                if (currRec.Pause_Assignment__c)
                	idForUpdateTrue.add(currRec.User__c);
                else
                    idForUpdateFalse.add(currRec.User__c);
            }
            // check if user mapping becomes inactive
            if (oldRec!=null && (oldRec.Active__c!=currRec.Active__c)) {
                if (currRec.Active__c)
                	idForInactiveTrue.add(currRec.Id);
                else
                    idForInactiveFalse.add(currRec.Id);
			}
        }
        
        if (idForUpdateTrue.size()>0) // handles update for Pause Assignment as true
        //    RoundRobinHandler.updateRuleNextAssignmentFuture(idForUpdateTrue, true);
        	updateRuleNextAssignment(idForUpdateTrue, true);
        if (idForUpdateFalse.size()>0) // handles update for Pause Assignment as false
        //    RoundRobinHandler.updateRuleNextAssignmentFuture(idForUpdateFalse, false);
            updateRuleNextAssignment(idForUpdateFalse, false);
        //system.debug('RODRIGO idForInactiveTrue ' + idForInactiveTrue);
        if (idForInactiveTrue.size()>0) // handles update for Pause Assignment as true
        	updateRuleNextAssignmentById(idForInactiveTrue, true, false);
        if (idForInactiveFalse.size()>0) // handles update for Pause Assignment as false
            updateRuleNextAssignmentById(idForInactiveFalse, false, false);
    }
    
    //Firdoss
  @InvocableMethod(label='Update Rule Next Assignment By ID' description='Updates the Rule Next Assignment based on the provided Mapping IDs and toggle flag value.')
    public static void updateRuleInvocable(List<Wrapper> requestList) {
        //system.debug('requestList'+requestList);
       // Wrapper wrp=new Wrapper();
        // Initialize sets to collect IDs and flag
        Set<Id> mappingIds = new Set<Id>();
        Boolean toggleFlagValue = null;

        System.debug('RequestList-->'+requestList);

        // Extract data from the request list
        for (Wrapper request : requestList) {
            mappingIds.add(request.mappingIds);
            toggleFlagValue = request.toggleFlagValue;
        }
       system.debug('mappingIds >>'+mappingIds);
        system.debug('toggleFlagValue >>'+toggleFlagValue);
 
        updateRuleNextAssignmentById(mappingIds,toggleFlagValue, true);
       
    }
    public class Wrapper {
        @InvocableVariable(label='Mapping IDs' description='List of Assignment Mapping IDs to update.')
        public Id mappingIds;

        @InvocableVariable(label='Toggle Flag Value' description='Boolean value to determine the update behavior.')
        public Boolean toggleFlagValue;

       /* public Wrapper(Id mappingIds, Boolean toggleFlagValue) {
            this.mappingIds = mappingIds;
            this.toggleFlagValue = toggleFlagValue;
        }*/
    }
    /**********************************************************************
    Name: updateRuleNextAssignmentById
    =======================================================================
    Purpose: handles the logic to update the Rule Next Assignment                                                        
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Aug-23        INITIAL DEVELOPMENT
    1.1.       Rodrigo Carpio.       2024-Jul-16.       added updateNextAssignmentFromRuleFlag identifier that update is initiated from rule next assignment update
    ***********************************************************************/
    
    
    public static void updateRuleNextAssignmentById (Set<Id> inMappingId, boolean toggleFlagValue, boolean updateNextAssignmentFromRuleFlag) {
        //inMappingId.add('a01TH000008oyQzYAI');
        system.debug('RODRIGO updateRuleNextAssignmentById inMappingId ' + inMappingId);
        system.debug('RODRIGO updateRuleNextAssignmentById toggleFlagValue ' + toggleFlagValue);
        Map<Id,RR_Assignment_Mapping__c> assignMapList = new Map<Id,RR_Assignment_Mapping__c>([SELECT Id, Pause_Assignment__c, User__c, Assignment_Rule__c, Assignment_Rule__r.Next_Assignment_Mapping__c,
                                     Assignment_Rule__r.Next_Assignment__c, Assignment_Rule__r.Always_Use_Next_Assignment__c, Active__c, Order__c   
                                                            FROM RR_Assignment_Mapping__c 
                                                            WHERE Assignment_Rule__r.Category__c='Lane Four' 
                                                        			AND Id IN:inMappingId order by Order__c asc] );
        if (toggleFlagValue) {
            updateRuleInfo(assignMapList.values());
        }
        else {
            //system.debug('RODRIGO before performUpdateOnNextAssignment ' + assignMapList.size());
            performUpdateOnNextAssignment(assignMapList, assignMapList, false, updateNextAssignmentFromRuleFlag);
        }
    }
   
    public static void updateRuleInfo(List<RR_Assignment_Mapping__c> assignMapList)
    {
        Map<Id, RR_Assignment_Rule__c> forUpdate = new Map<Id, RR_Assignment_Rule__c>();
        FOR(RR_Assignment_Mapping__c rraObj : assignMapList) {
            if(rraObj.Assignment_Rule__r.Next_Assignment_Mapping__c == null && rraObj.Active__c==true && rraObj.Pause_Assignment__c==false) { // check if mapping rule next assignment is null
                RR_Assignment_Rule__c rraLoc = new RR_Assignment_Rule__c();
                rraLoc.Next_Assignment__c = rraObj.User__c;
                rraLoc.Next_Assignment_Mapping__c = rraObj.Id;
                rraLoc.Id = rraObj.Assignment_Rule__c;
                forUpdate.put(rraLoc.Id, rraLoc);
            }
        }
        update forUpdate.values();
    }
    /**********************************************************************
    Name: updateRuleNextAssignment
    =======================================================================
    Purpose: handles the logic to update the Rule Next Assignment                                                        
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Aug-02        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    public  void updateRuleNextAssignment (Set<Id> inUserId, boolean toggleFlagValue) {
        Set<Id> ruleIdsLoc = new Set<Id>();
        Boolean queryFlag = toggleFlagValue;
        Map<Id, RR_Assignment_Rule__c> forUpdate = new Map<Id, RR_Assignment_Rule__c>();
        List<RR_Assignment_Mapping__c> assignMapList = [SELECT Id, Pause_Assignment__c, User__c, Assignment_Rule__c, Assignment_Rule__r.Next_Assignment_Mapping__c,
                                     Assignment_Rule__r.Next_Assignment__c, Assignment_Rule__r.Always_Use_Next_Assignment__c, Active__c  
                                                            FROM RR_Assignment_Mapping__c 
                                                            WHERE Assignment_Rule__r.Category__c='Lane Four' 
                                                        AND Active__c = true AND Pause_Assignment__c =: queryFlag AND User__c IN:inUserId order by Order__c asc];
        FOR(RR_Assignment_Mapping__c maprec : assignMapList) {
            ruleIdsLoc.add(maprec.Assignment_Rule__c);
        }
        //system.debug('RODRIGO updateRuleNextAssignment ' + assignMapList.size());
        RoundRobinHandler rr = new RoundRobinHandler(ruleIdsLoc);
        // check for pause assignment value, if false
        if (!toggleFlagValue) {
            updateRuleInfo(assignMapList);
            /*FOR(RR_Assignment_Mapping__c rraObj : assignMapList) {
                if(rraObj.Assignment_Rule__r.Next_Assignment_Mapping__c == null) { // check if mapping rule next assignment is null
                    RR_Assignment_Rule__c rraLoc = new RR_Assignment_Rule__c();
                    rraLoc.Next_Assignment__c = rraObj.User__c;
                    rraLoc.Next_Assignment_Mapping__c = rraObj.Id;
                    rraLoc.Id = rraObj.Assignment_Rule__c;
                    forUpdate.put(rraLoc.Id, rraLoc);
                }
            }
            update forUpdate.values();
			*/
        }
        else // logic that handles pause assignment true
        {
            //system.debug('RODRIGO updateRuleNextAssignment else ');
        List<RR_Assignment_Mapping__c> assignMapForUpd = new List<RR_Assignment_Mapping__c>();
        List<RR_Assignment_Rule__c > assignRuleForUpd = new List<RR_Assignment_Rule__c >();
        Map<Id, RR_Assignment_Mapping__c> assignUserRuleMap = new Map<Id, RR_Assignment_Mapping__c>();
        Map<Id, Id> assignUserRuleAlwaysAssignMap = new Map<Id, Id>();
        //system.debug('RODRIGO assignMapList ' + assignMapList.size());
        
        // get assignment mapping base on the list of rules -- replaced the //Pause_Assignment__c != true  with EnableADRLeads and added user query.
        rr.mapMapping = new Map<Id, RR_Assignment_Mapping__c>([SELECT Id, Order__c, User__c, Assignment_Rule__c, User_Group__c, Is_SLED__c,Type__c,
                                                             Max_Value__c, Value_Total__c, Field_To_Assign__c, Queue_Name__c, Pause_Assignment__c   
                                                            FROM RR_Assignment_Mapping__c 
                                                            WHERE Active__c=true AND Pause_Assignment__c= false
                                                            AND Assignment_Rule__c IN: rr.mapRule.keySet() order by Order__c asc]);

        
    	
        //system.debug('RODRIGO ruleId ' + rr.mapMapping.size());
        // collect the user and put them into rule map
        FOR(Id ruleId : rr.mapRule.keySet()) {
            //system.debug('RODRIGO ruleId ' + ruleId);
            Map<Id, RR_Assignment_Mapping__c > userMapping = new Map<Id, RR_Assignment_Mapping__c >();
            FOR (RR_Assignment_Mapping__c userMap : rr.mapMapping.values()) {
                if (userMap.Assignment_Rule__c == ruleId) {
                    userMapping.put(userMap.Id, userMap);
                }
                    
            }
            //system.debug('RODRIGO ruleId ' + userMapping.size());
            if (userMapping.size()>0) {
                //system.debug(ruleId + ' RODRIGO ruleId ruleUserMaps ' + userMapping);
                rr.ruleUserMaps.put(ruleId, userMapping);
            }
        }
        
        // get rules assigned mapping count
        Map<Id, RR_Assignment_Rule__c> rules = new Map<Id, RR_Assignment_Rule__c>([SELECT Id, Name, (SELECT id FROM RR_Assignment_Mappings__r  WHERE Pause_Assignment__c=false ) 
                                             FROM RR_Assignment_Rule__c 
                                             WHERE Category__c='Lane Four' AND Always_Use_Next_Assignment__c=false order by Order__c asc]);
        Set<Id> ruleWithNoAssignment = new Set<Id>();
        List<RR_Assignment_Rule__c> ruleToClearNextAssignment = new List<RR_Assignment_Rule__c>();
        for (RR_Assignment_Rule__c rule : rules.Values()) {
            
            if (rule.RR_Assignment_Mappings__r.size()==0) {
                ruleWithNoAssignment.add(rule.Id);
                rule.Next_Assignment__c = null;
                rule.Next_Assignment_Mapping__c = null;
                ruleToClearNextAssignment.add(rule);
            }
                
            //system.debug('RODRIGO size ' + rule.RR_Assignment_Mappings__r.size());
        }
        
        FOR (RR_Assignment_Mapping__c rec : assignMapList)
        {
            //rec.Pause_Assignment__c = toggleFlagValue;
            //assignMapForUpd.add(rec);
            
            if(rec.Assignment_Rule__r.Next_Assignment__c != null && inUserId.contains(rec.Assignment_Rule__r.Next_Assignment__c)) {
                if(!rec.Assignment_Rule__r.Always_Use_Next_Assignment__c)
                	assignUserRuleMap.put(rec.Assignment_Rule__c, rec);
                
            }
        }
        
        
        FOR(Id ruleId : assignUserRuleMap.keySet()) {
            RR_Assignment_Mapping__c locAssignMap = assignUserRuleMap.get(ruleId);
            //system.debug('RODRIGO ' + ruleId);
            if (!ruleWithNoAssignment.contains(ruleId))
            	rr.assignNextAssignmentUserUsingOrder(ruleId, locAssignMap.User__c, null, false, locAssignMap.Id);
        }
        //system.debug('RODRIGO ruleId ' + rr.mapRuleToBeUpdated.size());
        // perform update on the assignment where the next assignment will be updated, mapRule value is being set to updated in assignNextAssignmentUserUsingOrder
        update rr.mapRuleToBeUpdated.values();
        
        if (ruleToClearNextAssignment.size()>0)
            update ruleToClearNextAssignment;
        
        }
    }
    /*
     * 1.1.       Rodrigo Carpio.       2024-Jul-16.       added updateNextAssignmentFromRuleFlag identifier that update is initiated from rule next assignment update
*/
    private static void performUpdateOnNextAssignment(Map<Id, RR_Assignment_Mapping__c> newRRMappingMap, Map<Id, RR_Assignment_Mapping__c> assignMapList, boolean isDeletion, boolean updateNextAssignmentFromRuleFlag) {
        //system.debug('RODRIGO performUpdateOnNextAssignment Inside');
        //Map<Id, RR_Assignment_Mapping__c> newRRMappingMap: A map of new assignment mappings.
        //Map<Id, RR_Assignment_Mapping__c> assignMapList: A map of existing assignment mappings.
        //boolean isDeletion: A flag indicating whether the operation is a deletion.
        //Set<Id> ruleIds: Collects IDs of assignment rules that need to be updated.
        Set<Id> ruleIds = new Set<Id>();
       // Set<Id> setMapIdforRuleToUpdate: Collects IDs of mappings that need their associated rules updated.
        Set<Id> setMapIdforRuleToUpdate = new Set<Id>();
        //Iterate through the newRRMappingMap to gather the rule IDs and determine which mappings need to be updated.
        FOR(RR_Assignment_Mapping__c rrMapping : newRRMappingMap.values()) {
            ruleIds.add(rrMapping.Assignment_Rule__c);
            RR_Assignment_Mapping__c curMapping = assignMapList.get(rrMapping.Id);
            // check if the mapping id is assigned as the rule next assignment mapping
            if(rrMapping.Id == curMapping.Assignment_Rule__r.Next_Assignment_Mapping__c || 
               (updateNextAssignmentFromRuleFlag && curMapping.Assignment_Rule__r.Next_Assignment_Mapping__c==null)){
                //If a mapping’s ID matches the Next_Assignment_Mapping__c of its rule, add it to setMapIdforRuleToUpdate.
                setMapIdforRuleToUpdate.add(rrMapping.Id);
            }
        }
        
        system.debug('RODRIGO performUpdateOnNextAssignment setMapIdforRuleToUpdate ' + setMapIdforRuleToUpdate);
        // instantiate the Round Robin Handler
        RoundRobinHandler rr = new RoundRobinHandler(ruleIds);
        //If a mapping ID is in setMapIdforRuleToUpdate, add it to the handler’s mapMappingPause map for paused mappings.
        FOR(RR_Assignment_Mapping__c rrMapping : newRRMappingMap.values()) {
            if (setMapIdforRuleToUpdate.contains(rrMapping.Id))
            	rr.mapMappingPause.put(rrMapping.Id, rrMapping);
        }
        //Iterate through setMapIdforRuleToUpdate and update the Next_Assignment_Mapping__c field using the 
        //assignNextAssignmentUserUsingOrder method of the RoundRobinHandler class.
        List<RR_Assignment_Rule__c> rulesToBeUpdated = new List<RR_Assignment_Rule__c>();
        FOR(Id locId : setMapIdforRuleToUpdate) {
            RR_Assignment_Mapping__c curMapping = assignMapList.get(locId);
            //system.debug('RODRIGO curMapping ' + curMapping);
            rr.assignNextAssignmentUserUsingOrder(curMapping.Assignment_Rule__c, curMapping.User__c, null, false, curMapping.Id);
        }
        system.debug('RODRRIGO mapRuleToBeUpdated ' + rr.mapRuleToBeUpdated.size());
        system.debug('RODRRIGO mapRuleToBeUpdated ' + rr.mapRuleToBeUpdated);
       //If there are no rules to be updated  create a list of rules to clear their Next_Assignment__c and Next_Assignment_Mapping__c fields.
        if (rr.mapRuleToBeUpdated.size()==0) {
            FOR(RR_Assignment_Mapping__c rrMapping : newRRMappingMap.values()) {
                RR_Assignment_Rule__c recRule = new RR_Assignment_Rule__c();
                recRule.id = rrMapping.Assignment_Rule__c;
                recRule.Next_Assignment__c = null;
                recRule.Next_Assignment_Mapping__c = null;
                rulesToBeUpdated.add(recRule);
            }
        }
        //update the Next_Assignment__c and Next_Assignment_Mapping__c fields for rules in rr.mapRuleToBeUpdated.
        else {
            FOR (RR_Assignment_Rule__c recRule : rr.mapRuleToBeUpdated.values()) {
                if (setMapIdforRuleToUpdate.contains(recRule.Next_Assignment_Mapping__c) && isDeletion){
                    recRule.Next_Assignment__c = null;
                    recRule.Next_Assignment_Mapping__c = null;
                }
                rulesToBeUpdated.add(recRule);
            }
        }
        
        //system.debug('RODRIGO performUpdateOnNextAssignment rulesToBeUpdated ' + rulesToBeUpdated);
        // perform update on the assignment where the next assignment will be updated
        update rulesToBeUpdated;
        
    }
    
    public void performDeleteNextAssignment(List<RR_Assignment_Mapping__c> rrMappingList, Map<Id, RR_Assignment_Mapping__c> newRRMappingMap) {
        //system.debug('RODRIGO newRRMappingMap ' + newRRMappingMap.keySet());
        
        Map<Id, RR_Assignment_Mapping__c> assignMapList = new Map<Id, RR_Assignment_Mapping__c>([SELECT Id, Pause_Assignment__c, User__c, Assignment_Rule__c
                                                                                                 , Assignment_Rule__r.Next_Assignment_Mapping__c,
                                     Assignment_Rule__r.Next_Assignment__c, Assignment_Rule__r.Always_Use_Next_Assignment__c, Order__c  
                                                            FROM RR_Assignment_Mapping__c 
                                                            WHERE Id IN:newRRMappingMap.keySet() order by Order__c asc]);
        performUpdateOnNextAssignment(assignMapList, assignMapList, true, false);
        
    }
    
    public void performAssignNextAssignment(List<RR_Assignment_Mapping__c> rrMappingList, Map<Id, RR_Assignment_Mapping__c> newRRMappingMap) {
        //system.debug('RODRIGO newRRMappingMap ' + newRRMappingMap.keySet());
        
        Map<Id, RR_Assignment_Mapping__c> assignMapList = new Map<Id, RR_Assignment_Mapping__c>([SELECT Id, Pause_Assignment__c, User__c, Assignment_Rule__c
                                                                                                 , Assignment_Rule__r.Next_Assignment_Mapping__c,
                                     Assignment_Rule__r.Next_Assignment__c, Assignment_Rule__r.Always_Use_Next_Assignment__c, Active__c  
                                                            FROM RR_Assignment_Mapping__c 
                                                            WHERE Id IN:newRRMappingMap.keySet() order by Order__c asc]);
        //system.debug('RODRRIGO assignMapList ' + assignMapList.size());

        updateRuleInfo(assignMapList.values());
        /*Set<Id> setMapIdforRuleToUpdate = new Set<Id>();
        Map<Id, RR_Assignment_Rule__c> rulesToBeUpdated = new Map<Id, RR_Assignment_Rule__c>();
        FOR(RR_Assignment_Mapping__c rrMapping : newRRMappingMap.values()) {
            RR_Assignment_Mapping__c curMapping = assignMapList.get(rrMapping.Id);
            // check if the mapping id is assigned as the rule next assignment mapping
            if(curMapping.Assignment_Rule__r.Next_Assignment_Mapping__c==null && rrMapping.Active__c==true){
                if(rulesToBeUpdated.get(curMapping.Assignment_Rule__c)==null) {
                    RR_Assignment_Rule__c locR = new RR_Assignment_Rule__c();
                    locR.Id = curMapping.Assignment_Rule__c;
                    locR.Next_Assignment_Mapping__c = curMapping.Id;
                    locR.Next_Assignment__c = curMapping.User__c;
                    rulesToBeUpdated.put(locR.Id, locR);
                }
                
            }
        }
        
        if(rulesToBeUpdated.size()>0) 
            update rulesToBeUpdated.values();
		*/
    }
	
}