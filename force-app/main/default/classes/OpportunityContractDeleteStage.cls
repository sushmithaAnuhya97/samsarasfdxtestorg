global class OpportunityContractDeleteStage implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'select Id, (select Id from Opportunities limit 1) from Account';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> objects) {

        // get all account lookups in the staging object that lookup up to accounts that have opportunities
        // keep account lookups that do not have opportunties to optimize batch performance so that we aren't querying accounts that do not have opportunities
        Set<Id> accountIds = new Set<Id>();
        for (Account acct : (List<Account>) objects) {
            if (!acct.Opportunities.isEmpty()) {
                accountIds.add(acct.Id);
            }
        }

        delete [select Id from OpportunityContractAccount__c where Account__c IN :accountIds];
    }

    global void finish(Database.BatchableContext BC){}

}