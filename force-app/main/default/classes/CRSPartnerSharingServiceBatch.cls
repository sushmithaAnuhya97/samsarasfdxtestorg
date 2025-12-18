/**
 * Created by vikasmishra on 2021-07-02.
 */

public with sharing class CRSPartnerSharingServiceBatch implements Database.Batchable<SObject> {

    @TestVisible
    static ChannelRelationShipPartnerSharingService.IService thisCRSPartnerSharingService =
            new ChannelRelationShipPartnerSharingService();
    @TestVisible
    String query;
    public CRSPartnerSharingServiceBatch(String query){
        this.query = query;
    }

    public CRSPartnerSharingServiceBatch(){
        this.query ='SELECT Id, ' +
                'Opportunity__c, ' +
                'Channel_Partner_User_lr__c ' +
                'FROM Channel_Relationship__c ' +
            	'WHERE Channel_Partner_User_lr__c != null ' +
                'LIMIT 1000000';
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Channel_Relationship__c> CRS){
        thisCRSPartnerSharingService.runPartnerSharingForOpportunity(
                new Map<Id, Channel_Relationship__c>(CRS),
                new Map<Id, Channel_Relationship__c>()
        );
    }

    public void finish(Database.BatchableContext BC){
    }

}