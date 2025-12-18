/* 
 * Class Created: 03/18/20 Harsha - (GTMS-562)
 * Test Class: ScheduledAccountUpdateTest
 */  

global class ScheduledAccountUpdate implements Schedulable
{
   global void execute(SchedulableContext SC) 
   {
       
        List<Id> accountIds = new List<Id>() ;
        List<Opportunity> lstOpp = [SELECT Id, AccountId FROM Opportunity Where StageName IN ('Closed Won', 'Closed Lost') AND SystemModstamp >= YESTERDAY];
        if(lstOpp != null && lstOpp.size() > 0) {
            for(Opportunity opp : lstOpp) {
                accountIds.add(opp.AccountId);
            }
        }
        //List<Contract> contracts = [SELECT AccountId FROM Contract 
         //                          		WHERE SystemModStamp = Today];
       /*List<Id> accountIds = new List<Id>() ;
       if(contracts.size() > 0)
       {
           for(Contract contract : contracts)
           {
               accountIds.add(contract.AccountId);
           }
       }*/
       if(accountIds.size() > 0)
       {
           AccountUpdateBatch updateBatch = new AccountUpdateBatch(accountIds);
           Database.executebatch(updateBatch, 10);
       }
   }
}