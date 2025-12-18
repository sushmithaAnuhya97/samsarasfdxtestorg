/**
 * Created by vikasmishra on 2021-05-06.
 */

public with sharing class Samsara_ClearLogs implements Database.Batchable<SObject>, Schedulable{
    @TestVisible
    private Integer DAYS_TO_DELETE = 30;
    @TestVisible
    private String query = 'SELECT Id ' +
            'FROM Log__c ' +
            'WHERE CreatedDate <= LAST_N_DAYS:' +
            DAYS_TO_DELETE;
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject>scope){
        Database.delete(scope);
    }

    public void execute(SchedulableContext sc){
        Database.executeBatch(new Samsara_ClearLogs());
    }

    public void finish(Database.BatchableContext BC){

    }
}