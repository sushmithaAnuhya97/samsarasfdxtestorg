//02-JAN-2024 GTMS-16221 -- Created batch apex to update accounts with Finance Partner details - One time job
global class PopulateFinancePartneronAccountBatch implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name,Finance_Partner__c FROM ACCOUNT WHERE Finance_Partner__c = \'\'';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        Map<Id, Opportunity> oldestOpportunityMap = new Map<Id, Opportunity>();
        List<Account> listAccountstoUpdate = new List<Account>();
		List<Opportunity> listOpportunities = new List<Opportunity>([SELECT Id, Name, AccountId, CloseDate,Finance_Partner__c FROM Opportunity WHERE AccountId In:scope and StageName = 'Closed Won' and Finance_Partner__c != '' and Type = 'Revenue Opportunity' ORDER BY CloseDate ASC]);
        for (Opportunity opp : listOpportunities) {
            if (!oldestOpportunityMap.containsKey(opp.AccountId)) {
                // If account is not already in the map, add the opportunity
                oldestOpportunityMap.put(opp.AccountId, opp);
            } else {
                // Check if the current opportunity's close date is earlier than the one in the map
                Opportunity existingOldestOpportunity = oldestOpportunityMap.get(opp.AccountId);
                if (opp.CloseDate < existingOldestOpportunity.CloseDate) {
                    // Update the map if the current opportunity is older
                    oldestOpportunityMap.put(opp.AccountId, opp);
                }
            }
        }
        for (Opportunity opp : oldestOpportunityMap.values()) {
            Account acc = new Account();
            acc.Id = opp.AccountId;
            acc.Finance_Partner__c = opp.Finance_Partner__c;
            acc.X3PF_Customer__c = true;
            listAccountstoUpdate.add(acc);
        }
        if(listAccountstoUpdate.size() > 0){
            update listAccountstoUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
        
    }
}