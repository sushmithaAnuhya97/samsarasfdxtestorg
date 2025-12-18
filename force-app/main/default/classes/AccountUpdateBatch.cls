/* 
 * Class Created: 03/18/20 Harsha/Agamani - (GTMS-562)
 * Test Class:AccountUpdateBatchTest
 * Added condition to SOQL query for Renewed_To_Oppty_Stage__c not in ('Closed Won','Closed Lost') - 03/27/20 Agamani
 * Added condition to SOQL query for enddate>today - 04/15/20 Agamani

 */  

// Centralized class to do all the scheduled updates on the Account records
global class AccountUpdateBatch implements Database.Batchable<sObject> 
{   
    List<Id> accountIds = new List<Id>();
    public AccountUpdateBatch(List<Id> filteredAccountIds){
        this.accountIds = filteredAccountIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        String query = 'SELECT Id FROM account WHERE Id IN : accountIds';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) 
    {   
        List<Date> startDates = new List<Date>();
        List<Date> endDates = new List<Date>();
        Id previousId = null;
        
        Map<Id, Account> updatedAccounts = new Map<Id, Account>();
        List<Account> lstAccounts = new list<Account>();
        List<Account> updateAccountList = new List<Account>();
        
        if(scope.size() > 0){
            lstAccounts = [Select Id,Contract_Renewed_On__c,(SELECT startdate, 
                                enddate, 
                                accountId,
                                Is_Active__c,Deactivated__c,
                                Status, Renewed_To_Oppty_Stage__c,
                                SBQQ__RenewalOpportunity__c
                         FROM Contracts 
                         WHERE Is_Active__c= true
                         AND enddate>today
                         /*AND Renewed_To_Oppty_Stage__c != null
                         AND Renewed_To_Oppty_Stage__c not in ('Closed Won','Closed Lost')*/
                         ORDER BY accountId, EndDate ASC LIMIT 1) 
                         from Account Where Id =: scope];
        }
        //Integer numberOfContracts = lstAccounts.size();
        //Integer loopCount = 0;
        
        //commented below code for GTMS-10852
        // Logic to loop through all the associated contracts and sort through the dates
        /*for(Contract relatedContract : contracts){
            loopCount++; 
            if(previousId == null){
                previousId = relatedContract.accountId;
                startDates.add(relatedContract.startdate);
                endDates.add(relatedContract.enddate);
            }
            else if(previousId == relatedContract.accountId){
                startDates.add(relatedContract.startdate);
                endDates.add(relatedContract.enddate);
            }
            else if(previousId != relatedContract.accountId){
                startDates.sort();
                endDates.sort();
                updatedAccounts.put(previousId, new Account(id= previousId, Contract_Start_Date_new__c = startDates.get(0), Contract_Renewed_On__c = endDates.get(0)));
                startDates.clear();
                endDates.clear();
                startDates.add(relatedContract.startdate);
                endDates.add(relatedContract.enddate);
                previousId = relatedContract.accountId;
            }
            if(loopCount == numberOfContracts){
                startDates.sort();
                endDates.sort();
                updatedAccounts.put(relatedContract.accountId, new Account(id= relatedContract.accountId, Contract_Start_Date_new__c = startDates.get(0), Contract_Renewed_On__c = endDates.get(0)));
            }
        }*/
        //Added below code for GTMS-10852
        for(Account relatedAccount : lstAccounts){
            Contract objContract = new Contract();
            if(relatedAccount.Contracts != null && relatedAccount.Contracts.size() > 0) {
                objContract = relatedAccount.Contracts[0];
                if(relatedAccount.Contract_Renewed_On__c != objContract.EndDate.addDays(1)) {
                    Account acc = new Account();
                    acc.Id = relatedAccount.Id;
                    acc.Contract_Renewed_On__c = objContract.EndDate.addDays(1);
                    updateAccountList.add(acc);
                }
            }            
        }

        if(updateAccountList.size() > 0){
            try{
                Database.update(updateAccountList, false);
                //update updatedAccounts.values();       
            }
            catch(Exception e){
                // Need to add the logic to create a record when the class fails or trigger an email to the group.
                system.debug('The AccountUpdateBatch class failed with the following exception '+e.getMessage()); 
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){}
}