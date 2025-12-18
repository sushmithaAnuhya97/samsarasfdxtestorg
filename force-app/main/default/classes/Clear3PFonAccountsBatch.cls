//18-JAN-2024 GTMS-16221 -- Created batch apex to clear 3PF fields on accounts if Contract has previos day EndDate
//Test class for this is covered in PopulateFinancePartneronAccountBatchTest
global class Clear3PFonAccountsBatch implements Database.Batchable<SObject>, Schedulable {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,SBQQ__Opportunity__c,EndDate,name,SBQQ__Opportunity__r.account.Finance_Partner__c, SBQQ__Opportunity__r.account.X3PF_Customer__c,SBQQ__Opportunity__r.stagename,SBQQ__Opportunity__r.Type,SBQQ__Opportunity__r.Finance_Partner__c,SBQQ__Opportunity__r.accountId from contract where EndDate = yesterday and SBQQ__Opportunity__r.Type = \'Revenue Opportunity\' and SBQQ__Opportunity__r.stagename = \'Closed Won\' and SBQQ__Opportunity__r.Finance_Partner__c != \'\' and SBQQ__Opportunity__r.account.Finance_Partner__c != \'\' and SBQQ__Opportunity__r.account.X3PF_Customer__c = true';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Contract> scope) {
        system.debug('*****'+scope);
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountstoUpdate = new List<Account>();
        for(Contract cont:scope){
            accountIds.add(cont.SBQQ__Opportunity__r.accountId);
        }
        if(accountIds.size() > 0){
            for(Id accId:accountIds){
                Account acc = new Account();
                acc.Id = accId;
                acc.Finance_Partner__c = null;
                acc.X3PF_Customer__c = false;
                accountstoUpdate.add(acc);
            }
        }
        if(accountstoUpdate.size() > 0){
            update accountstoUpdate;
        }
    }
    public void execute(System.schedulableContext sc){
        Database.executeBatch(new Clear3PFonAccountsBatch());
    }
    global void finish(Database.BatchableContext BC) {
        
    }
}