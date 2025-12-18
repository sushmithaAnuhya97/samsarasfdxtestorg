global class OpportunityContractDeleteBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'select Id from Contract';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> objects) {
        delete ((List<Contract>)objects);
    }

    global void finish(Database.BatchableContext BC){}

}