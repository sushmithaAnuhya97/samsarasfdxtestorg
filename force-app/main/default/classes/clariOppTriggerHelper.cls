/**********************************
* GTMS-4349 (Lavanya): Moved the opportunity update logic into a future method.
**********************************/

public class clariOppTriggerHelper {
    
    public static void afterInsert(){
        Map<Id,Id> oppIDMap = new Map<Id,Id>();
        //Zakeer: !System.isBatch() GTMS-5174 --Oct-26--> ContractAutomation
        if(!System.isBatch()){
            for (Clari_Opp__c clariOpp : (List<Clari_Opp__c>)trigger.new){
                oppIDMap.put(clariOpp.id,clariOpp.Opportunity__c);
            }
            if(!System.isFuture()) {
                updateOpportunitiesAsync(oppIDMap);
            }
            else {
            	updateOpportunities(oppIDMap);    
            }
        }
        
    }

	@future    
    public static void updateOpportunitiesAsync(Map<Id,Id> oppIdMap) {
        updateOpportunities(oppIdMap);
    }
    
    public static void updateOpportunities(Map<Id,Id> oppIdMap){
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Map<Id, Opportunity> oppMap = new Map <Id, Opportunity>([SELECT Id, Clari_Opp__c
                                                                 FROM Opportunity
                                                                 WHERE Id in :oppIdMap.values()]);
        for (Id clariOppId : oppIdMap.keySet()){
            Opportunity relatedOpp = oppMap.get(oppIdMap.get(clariOppId));
            if(relatedOpp != Null) {
                relatedOpp.Clari_Opp__c = clariOppId;
                oppsToUpdate.add(relatedOpp);   
            }
        }
        string nameTriggerClass = new SamsaraAuditToggleMdtSelector().getInstanceByDeveloperName('Opportunity').Trigger_Handler__c;
		
        if(nameTriggerClass!=null && nameTriggerClass.containsIgnoreCase('OpportunityTriggerHandlerContext'))
        {
            OpportunityTriggerHandlerContext.addCall('beforeUpdate');
        	OpportunityTriggerHandlerContext.addCall('afterUpdate');
        }
        else {
            OpportunityTriggerHandler.addCall('beforeUpdate');
        	OpportunityTriggerHandler.addCall('afterUpdate');
        }
        
        update oppsToUpdate;  
        if(nameTriggerClass!=null && nameTriggerClass.containsIgnoreCase('OpportunityTriggerHandlerContext'))
            OpportunityTriggerHandlerContext.resetAll();
        else
            OpportunityTriggerHandler.resetAll();
          
    }
   
}