// GTMS - 28514 : Adding OLI for promo asset tag automtacially after closed won.
public with sharing class CreatePromoOLIController {
    
   @AuraEnabled
public static String createOLIPromobutton(Id OppId) {
    if (OppId == null) return 'Error: Opportunity Id is null';
     if (!OpportunityTriggerHandlerContext.runPromoBySetting()) {
        return 'This functionality is disabled';
    }

    Set<Id> allowedProfiles = new Set<Id>();
    Set<Id> prodIds = new Set<Id>();

    List<SFS_Promo_Product_Setting__mdt> settings = [
        SELECT Id, Product_Id__c, Allowed_Profiles_for_Button__c, Evaluation_Order__c
        FROM SFS_Promo_Product_Setting__mdt
        WHERE Active__c = true
        ORDER BY Evaluation_Order__c ASC NULLS LAST, DeveloperName ASC
    ];
    if (settings.isEmpty()) return 'This Opportunity does not met the criteria';

    for (SFS_Promo_Product_Setting__mdt s : settings) {
        if (String.isNotBlank(s.Allowed_Profiles_for_Button__c)) {
            for (String pid : s.Allowed_Profiles_for_Button__c.split(',')) {
                if (String.isNotBlank(pid)) allowedProfiles.add((Id)pid.trim());
            }
        }
        if (String.isNotBlank(s.Product_Id__c)) {
            for (String p : s.Product_Id__c.split(',')) {
                if (String.isNotBlank(p)) prodIds.add((Id)p.trim());
            }
        }
    }

    if (!allowedProfiles.isEmpty() && !allowedProfiles.contains(UserInfo.getProfileId())) {
        return 'You dont have access. Please contact Sales Ops.';
    }

    // If we have configured products, only block when ALL of them already exist on the Opp
    if (!prodIds.isEmpty()) {
        Set<Id> existingProdIds = new Set<Id>();
        for (OpportunityLineItem oli : [
            SELECT PricebookEntry.Product2Id
            FROM OpportunityLineItem
            WHERE OpportunityId = :OppId
            AND PricebookEntry.Product2Id IN :prodIds
        ]) {
            if (oli.PricebookEntry != null) {
                existingProdIds.add(oli.PricebookEntry.Product2Id);
            }
        }
        Set<Id> missingProdIds = new Set<Id>(prodIds);
        missingProdIds.removeAll(existingProdIds);

        if (missingProdIds.isEmpty()) {
            return 'Already promo product is linked with this opportunity.';
        }
        // Optional: you could pass missingProdIds to your helper if it supports narrowing
    }

    // Delegate to helper (button path)
    List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id = :OppId LIMIT 1];
    String msg = new OpportunityHelperAfterUpdate().createOLIForPromo(new Map<Id, Opportunity>(), opps, true);     

    return String.isBlank(msg)
        ? 'No OpportunityLineItem created due to criteria mismatch'
        : msg;
}
    
}