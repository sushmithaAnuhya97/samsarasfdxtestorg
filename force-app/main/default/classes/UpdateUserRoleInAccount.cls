/*
* Test Class   :   UpdateUserRoleInAccountTest
* Coverage     :   100%
* *************************************************************************************************************
* 14/02/2024 Joshna - (Mercury): Created
*/
public class UpdateUserRoleInAccount implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext BC)
    {	
        Integer batchSize = integer.valueof(System.label.BatchSize);
        String query = 'SELECT Id, Segment__c, Segment_Text_stamped__c, Owner_Role__c,Owner_Role_Text_Stamped__c FROM Account where Segment_Not_Match__c  = true OR Owner_Role_Not_Match__c = true LIMIT :batchSize';   
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope)
    {
        list<Account> AccountsToUpdate = new list<Account>();
        for(Account Acc: scope){
            If(Acc.Segment_Text_stamped__c == null || Acc.Segment_Text_stamped__c != Acc.Segment__c){
                Acc.Segment_Text_stamped__c = Acc.Segment__c;
            }
            If(Acc.Owner_Role_Text_Stamped__c == null || Acc.Owner_Role_Text_Stamped__c != Acc.Owner_Role__c){
                Acc.Owner_Role_Text_Stamped__c = Acc.Owner_Role__c;
            }
            AccountsToUpdate.add(Acc);
        }
        if(AccountsToUpdate.size() > 0){
            update AccountsToUpdate;
         }
    }  
    public void finish(Database.BatchableContext BC) {
        system.debug('Apex Job Id'+BC.getJobId());
    }   
}