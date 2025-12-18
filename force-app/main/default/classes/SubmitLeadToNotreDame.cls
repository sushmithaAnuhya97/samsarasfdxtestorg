/**
 * Created by vikasmishra on 2021-06-21.
 */

public with sharing class SubmitLeadToNotreDame implements IService{

    @TestVisible
    static ISelector thisLeadSelector = new LeadSelector();
    Lead queriedLead = new Lead();
    public void postLeadToNotreDame (Id leadId){
        queriedLead = thisLeadSelector.getLeadById(leadId)[0];
        doPost(queriedLead);
    }

    private void doPost(Lead thisLead){

            Object response = new NotreDameHTTPService().postLeadToNotreDame(thisLead);
    }

    public Lead getProcessedLeadRecord(){
        return queriedLead;
    }

    public class LeadSelector implements ISelector{
        public List<Lead> getLeadById (Id thisId){
            return Database.query(
                    buildDynamicQueryWithAllFields('Lead')+ ' WHERE Id =: thisId'
            );
        }

        public String buildDynamicQueryWithAllFields (String thisSobjectName){
            String query = 'SELECT ';
            Set<String> fieldNames = SchemaUtils.getGlobalDescribe().get(thisSobjectName).getDescribe().fields.getMap().keySet();
            query += String.join(new List<String>(fieldNames), ',');
            query += ' FROM '+ thisSobjectName ;
            return query;
        }
    }


    public interface IService{
        void postLeadToNotreDame (Id leadId);
        Lead getProcessedLeadRecord();
    }

    public interface ISelector{
        List<Lead> getLeadById (Id thisId);
    }


}