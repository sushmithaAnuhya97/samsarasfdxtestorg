public class OpportunityAmendmentQueueable implements Queueable {
    private String serializedTrialDiffs;
    private Set<Id> oppIdsToUpdate;
    
    public OpportunityAmendmentQueueable(String serializedTrialDiffs, Set<Id> oppIdsToUpdate) {
        this.serializedTrialDiffs = serializedTrialDiffs;
        this.oppIdsToUpdate = oppIdsToUpdate;
    }
    
    public void execute(QueueableContext context) {
        Map<Id, Integer> contractTrialDiffs = new Map<Id, Integer>();
        if (!String.isBlank(serializedTrialDiffs)) {
            contractTrialDiffs = (Map<Id, Integer>) JSON.deserialize(serializedTrialDiffs, Map<Id, Integer>.class);
        }
    
        // Ensure sets are not null
        if (oppIdsToUpdate == null) oppIdsToUpdate = new Set<Id>();
    
        List<Contract> contractsToProcess = new List<Contract>();
        if (!oppIdsToUpdate.isEmpty() || !contractTrialDiffs.isEmpty()) {
            contractsToProcess = [
                SELECT Id, EndDate, SBQQ__Opportunity__c, SBQQ__Opportunity__r.Trial_End_Date__c
                FROM Contract 
                WHERE SBQQ__Opportunity__c IN :oppIdsToUpdate
                OR Id IN :contractTrialDiffs.keySet()
            ];
        }
    	System.debug('contractsToProcess'+contractsToProcess);
        if (contractsToProcess.isEmpty()) return;
    
        List<Contract> contractsToUpdate = new List<Contract>();
        Set<Id> contractIdsToUpdate = new Set<Id>(); // Track contract IDs to prevent duplicates
        Map<Id, Integer> oppTrialDaysMap = new Map<Id, Integer>();
        Map<Id, Id> amendedToOriginalOppMap = new Map<Id, Id>();
    
        for (Contract contract : contractsToProcess) {
            if (contractTrialDiffs.containsKey(contract.Id)) {
                oppTrialDaysMap.put(contract.SBQQ__Opportunity__c, contractTrialDiffs.get(contract.Id));
            }
    
            if (oppIdsToUpdate.contains(contract.SBQQ__Opportunity__c)) {
                if (contract.EndDate != contract.SBQQ__Opportunity__r.Trial_End_Date__c && !contractIdsToUpdate.contains(contract.Id)) {
                    contract.EndDate = contract.SBQQ__Opportunity__r.Trial_End_Date__c;
                    contractsToUpdate.add(contract);
                    contractIdsToUpdate.add(contract.Id); // Add to set to prevent duplicates
                }
            }
    
        }
    
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        if (!oppTrialDaysMap.isEmpty()) {
            oppsToUpdate = [
                SELECT Id, Trial_Period__c, Trial_End_Date__c
                FROM Opportunity
                WHERE Id IN :oppTrialDaysMap.keySet()
            ];
        }
    
        for (Opportunity opp : oppsToUpdate) {
            Integer newTrialPeriod = Integer.valueOf(opp.Trial_Period__c + oppTrialDaysMap.get(opp.Id));
            if (opp.Trial_Period__c != newTrialPeriod) {
                opp.Trial_Period__c = newTrialPeriod;
            }
        }
    
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    
        if (!contractsToUpdate.isEmpty()) {
            update contractsToUpdate;
        }
    }
}