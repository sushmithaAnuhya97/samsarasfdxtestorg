public class GS_SBQQQuoteLineService {
    
    public void createQuoteLines(Set<Id> quoteIds) {
        
        Map<Id, List<Id>> mapOppLinesByQuoteId = new Map<Id, List<Id>>();
        List<String> oppLineItemIds = new List<String>();
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Opportunity2__r.Original_FT_Oppty_Line_Item_SF_Ids__c, SBQQ__Account__c, SBQQ__Opportunity2__r.Shipping_Address_NEW__c 
            FROM SBQQ__Quote__c WHERE Id IN:quoteIds];
        for(SBQQ__Quote__c quote : quotes) {
            if(String.isNotBlank(quote.SBQQ__Opportunity2__r.Original_FT_Oppty_Line_Item_SF_Ids__c)) {
                mapOppLinesByQuoteId.put(quote.Id, quote.SBQQ__Opportunity2__r.Original_FT_Oppty_Line_Item_SF_Ids__c.split(';'));
                oppLineItemIds.addAll(quote.SBQQ__Opportunity2__r.Original_FT_Oppty_Line_Item_SF_Ids__c.split(';'));   
            }
        }
        
        Map<Id, OpportunityLineItem> mapOppLineItem = new Map<Id, OpportunityLineItem>([SELECT Id, Product2Id, PricebookEntryId, Quantity, ProductCode,
            Line_Item_ID__c, SBQQ__QuoteLine__r.SBQQ__ListPrice__c FROM OpportunityLineItem WHERE Id IN:oppLineItemIds]);
        for(SBQQ__Quote__c quote : quotes) {
            if(String.isNotBlank(quote.SBQQ__Opportunity2__r.Original_FT_Oppty_Line_Item_SF_Ids__c)) {
                oppLineItemIds = quote.SBQQ__Opportunity2__r.Original_FT_Oppty_Line_Item_SF_Ids__c.split(';');
                for(String oppLineItemId : oppLineItemIds) {
                    OpportunityLineItem oppLineItem = mapOppLineItem.get(oppLineItemId);
                    if(oppLineItem != null) {
                        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
                        quoteLine.SBQQ__Quote__c  = quote.Id;
                        quoteLine.SBQQ__Product__c  = oppLineItem.Product2Id;
                        quoteLine.Account__c = quote.SBQQ__Account__c; 
                        quoteLine.Ship_To__c  = quote.SBQQ__Opportunity2__r.Shipping_Address_NEW__c;
                        quoteLine.SBQQ__PricebookEntryId__c = oppLineItem.PricebookEntryId;
                        if(!oppLineItem.ProductCode.containsIgnoreCase('LIC')) {
                            quoteLine.SBQQ__ListPrice__c = oppLineItem.SBQQ__QuoteLine__r.SBQQ__ListPrice__c;
                        }
                        quoteLine.Original_FT_Oppty_Line_Item_SF_Id__c = oppLineItem.Line_Item_ID__c;
                        quoteLine.SBQQ__Quantity__c  = oppLineItem.Quantity;
                        quoteLines.add(quoteLine);
                    }
                }
            }
        }
        if(!quoteLines.isEmpty()) {
            insert quoteLines;
        }
    }

}