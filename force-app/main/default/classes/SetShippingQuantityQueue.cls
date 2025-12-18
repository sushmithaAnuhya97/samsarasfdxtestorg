/*
 * Test Class   :   ShippingQuantitySplitCtrlTest
 * Coverage     :   92%
 * Description  :   This class is used in ShippingQuantitySplitCtrl to update 
 *                  opportunities and opportunity line items asynchronously
 * Related Jira :   SS-14, SS-44
*/
public class SetShippingQuantityQueue implements Queueable {
    List<OpportunityLineItem> lstOLINew { get; set; }
    List<Opportunity> lstTrailOpportunity { get; set; }
    Opportunity opp { get; set; }
    public SetShippingQuantityQueue(List<OpportunityLineItem> oliToUpsert, Id oppId, List<Opportunity> lstTrailOpportunity) {
        this.lstOLINew = oliToUpsert;
        opp = [SELECT Id, Set_Shipping_Quantity_Status__c  FROM Opportunity WHERE Id =: oppId];
        this.lstTrailOpportunity = lstTrailOpportunity;
    }
    public void execute (QueueableContext context) { 
        List<OpportunityLineItem> lstOLIToUpsert = new List<OpportunityLineItem>();
        List<OpportunityLineItem> lstOLIToDelete = new List<OpportunityLineItem>();
        //these are the lines to delete when we adjust the quantities to be zero update the rest
        for(OpportunityLineItem oli : lstOLINew){
            if(oli.Quantity == 0 && oli.Id != null) {
                lstOLIToDelete.add(oli);
            }else if(oli.Quantity != 0) {
                lstOLIToUpsert.add(oli);
            }
        }
        
        if(!lstOLIToDelete.isEmpty())
            delete lstOLIToDelete;
        if(!lstOLIToUpsert.isEmpty())
            upsert lstOLIToUpsert;
        if(lstTrailOpportunity.size()>0) {
            for(Opportunity opp : lstTrailOpportunity) {
                opp.Trial_Status__c = 'Purchased';
            }
            //update lstTrailOpportunity;
        }
        opp.Set_Shipping_Quantity_Status__c = 'Completed';
        update opp; 
        
        
        
    }
}