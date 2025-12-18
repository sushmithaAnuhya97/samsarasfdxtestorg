/* 
 * Class Created: 11/19/18 - Epic SS-63 @author: Harsha
 */

/* Class to create a Map of ShipTo, Product Code and opportunity Line item to help with multi line shipping 
   This is used in QuantityControllerExtensionRefactored Class*/
public without sharing class MappedRevenueLineItems { 

    //This method returns all the free trail line items associated with the opportunity.
    public static Map<String, Map<String, OpportunityLineItem>> mapFreeTrialLines(Opportunity opportunity){
        List<OpportunityLineItem> freeTrialLineItems = new List <OpportunityLineItem>([Select Id, Quantity, Shipped_Quantity__c, Discount, ListPrice, Ship_To_Address_Concatenated__c, Ship_To__c, Related_Order_Number__c, Trial_Order_Number__c, Product_Code_Copy__c from OpportunityLineItem 
                                                                                       where OpportunityId=:opportunity.Id AND Ship_From_Location__c='Free Trial'
                                                                                        order by Ship_To__c]);

        //system.debug('Free Trails are ' +freeTrialLineItems);
        Map<String, Map<String, OpportunityLineItem>> detailedMap = new Map<String, Map<String, OpportunityLineItem>>();
        detailedMap = loopLogic(freeTrialLineItems);
        //system.debug('Values in finalMap ' +detailedMap);
        system.debug('Size of finalMap ' +detailedMap.size());
        return detailedMap;
    }

    // This method returns are the non free trail line items associated with the opportunity.
    public static Map<String, Map<String, OpportunityLineItem>> mapNonFreeTrialLines(Opportunity opportunity){
        List<OpportunityLineItem> nonFreeTrialLineItems = new List <OpportunityLineItem>([Select Id, Quantity, Shipped_Quantity__c, Product_Code_Copy__c, Ship_To_Address_Concatenated__c, Ship_To__c, Discount,ListPrice, Related_Order_Number__c, Trial_Order_Number__c from OpportunityLineItem 
                                                                                       where OpportunityId=:opportunity.Id AND Ship_From_Location__c != 'Free Trial'
                                                                                       order by Ship_To__c]);




        //system.debug('Non Free Trails are ' +nonFreeTrailLineItems);
        Map<String, Map<String, OpportunityLineItem>> detailedMap = new Map<String, Map<String, OpportunityLineItem>>();
        detailedMap = loopLogic(nonFreeTrialLineItems);
        //system.debug('Values in finalMap ' +detailedMap);
        //system.debug('Size of finalMap ' +detailedMap.size());
        return detailedMap;
    }

    //Method to populate the Map <ShipToID,ProductCode,OpportunityLineItem>
    private static Map<String, Map<String, OpportunityLineItem>> loopLogic(List<OpportunityLineItem> lineItems){
            
        Map<String, Map<String, OpportunityLineItem>> finalMap = new Map<String, Map<String, OpportunityLineItem>>();
        Map<String, OpportunityLineItem> productQuantity;
        
        if(lineItems.size() > 0){
            try{
                for(OpportunityLineItem lineItem : lineItems){
                    if(!finalMap.containsKey(lineItem.Ship_To__c)){
                        productQuantity = new Map<String, OpportunityLineItem>();
                        finalMap.put(lineItem.Ship_To__c, productQuantity);
                    }     
                    if(finalMap.containsKey(lineItem.Ship_To__c)){
                        productQuantity.put(lineItem.Product_Code_Copy__c, lineItem);
                        finalMap.put(lineItem.Ship_To__c, productQuantity);
                    }           
                }
            }
            catch(exception e){
                System.debug('An exception occurred in the method mapNonFreeTrialLines: ' + e.getMessage());
            }
        }  
        //system.debug('Values in finalMap ' +finalMap);
        return finalMap;
    }
}