/**
 * Created by vikasmishra on 2021-09-15.
 */

public with sharing class GS_OpportunityLineItemSelector extends GS_SObjectBaseSelector{
    public GS_OpportunityLineItemSelector(Boolean checkFatalError){
        super(checkFatalError);
    }

    public GS_OpportunityLineItemSelector checkFatalError(){
        return (GS_OpportunityLineItemSelector) super.validateFatalError();
    }

    public List<OpportunityLineItem> getOpportunityLineItemByOpportunityIds(Set<Id> OpportunityIds){
        return [
                SELECT Description,Id,
                        Discount,ListPrice,
                        Name,OpportunityId,
                        Product2Id,PricebookEntryId,
                        ProductCode,Quantity,TotalPrice,
                        UnitPrice 
                FROM OpportunityLineItem
                WHERE OpportunityId IN : OpportunityIds
        ];
    }

}