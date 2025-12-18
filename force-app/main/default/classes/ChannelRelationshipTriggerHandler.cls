/**
* Created By : 
* @Date 
*
* @description : This class will be responsible for handling all Channel Relationship Trigger
* Jan-19-2024 Rodrigo - GTMS-16044 added related logic
**/
public class ChannelRelationshipTriggerHandler extends TriggerHandler{

    private Map<Id, Channel_Relationship__c> oldChannelRelationshipMap; 
    private Map<Id, Channel_Relationship__c> newChannelRelationshipMap;
    private List<Channel_Relationship__c> newChannelRelationshipList;

    @TestVisible
    static ChannelRelationShipPartnerSharingService.IService thisCRSPartnerSharingService =
            new ChannelRelationShipPartnerSharingService();

    public ChannelRelationshipTriggerHandler() {
        this.oldChannelRelationshipMap = (Map<Id, Channel_Relationship__c>) Trigger.oldMap;
        this.newChannelRelationshipMap = (Map<Id, Channel_Relationship__c>) Trigger.newMap;
        this.newChannelRelationshipList = (List<Channel_Relationship__c>) Trigger.new;
    }

    public override void beforeInsert(){
        ChannelRelationshipHelper.setDefualtFieldValues(newChannelRelationshipList);// added for GTMS-16044 
    }
    
    public override void afterInsert(){
        ChannelRelationshipHelper.updateCPQQuoteWithPartnerDetails(newChannelRelationshipList);
        thisCRSPartnerSharingService.runPartnerSharingForOpportunity(this.newChannelRelationshipMap, new Map<Id, Channel_Relationship__c>());
        //ChannelRelationshipHelper.updNewChannelRelationship14DaysAutoTag(newChannelRelationshipList); //add for GTMS-26105 14 Day Auto-Tag for Partner Deals - Commented, aleady performing same in flow(CR Auto Creation on Revenue Oppty Creation).
    }

    public override void beforeDelete(){
        thisCRSPartnerSharingService.runPartnerSharingForOpportunity(new Map<Id, Channel_Relationship__c>(), this.oldChannelRelationshipMap);
    }
}