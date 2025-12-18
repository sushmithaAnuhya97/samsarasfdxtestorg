/*
* Test Class   :   AutoRejectRemorseRefundTest
* Coverage     :   100%
* *************************************************************************************************************
* 11/05/20 Harsha - (GTMS-496): Created
*/
public class AutoRejectRemorseRefunds implements Database.Batchable<sObject>, Database.stateful{
    Date queryDate = Date.today() - 60;
    public Database.QueryLocator start(Database.BatchableContext BC)
    {	
        String query = 'SELECT StageName FROM Opportunity WHERE Type = \'Remorse Refund\'AND StageName = \'Return Label Sent\' AND Return_Label_Sent_At__c <=: queryDate';   
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Opportunity> scope)
    {
        list<Opportunity> updatedOpportunities = new list<Opportunity>();
        for(Opportunity opportunity: scope){
            opportunity.StageName = 'Return Cancelled';
            updatedOpportunities.add(opportunity);
        }
        if(updatedOpportunities.size() > 0){
            update updatedOpportunities;
        }
    }  
    public void finish(Database.BatchableContext BC) {		
    }   
}