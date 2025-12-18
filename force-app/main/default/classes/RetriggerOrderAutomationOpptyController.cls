public with sharing class RetriggerOrderAutomationOpptyController {
    
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunitiesInProcessing() {
        List<Opportunity> oppListToReturn = new List<Opportunity>();
        List<Opportunity> oppList = [
            SELECT Id, Order_Admin__r.name, ACV_Bookings_SOT__c, Order_Number__c, Account.Name, Name, Shipping_Zone__c, Unique_Shipping_Addresses__c, Type, Segment__c, 
            Free_Trial_Purchase__c, Shipping_Method__c, Went_to_Orders_Processing_Date__c, Internal_RFO_Notes__c, Hold_Reason__c, of_HW_Products__c, of_Accessories__c,
            Order_Ops_Notes__c, Estimated_Ship_Date__c, Amount, Owner.Name, CloseDate, Sales_Tax__c, Balance_Due__c, Shipping_and_Handling__c, Shipping_and_Handling_Manual__c, 
            Shipping_and_Handling_Amount__c, Trial_Agreement_Accepted__c, Shipping_Contact__c, Netsuite_Transfer_Order_ID__c, Netsuite_Transfer_Order__c, Total_Weight_oz__c,
            Owner_Segment__c, Segment_Sales_Role__c, CurrencyIsoCode, Shipping_Country__c, Automation_Notes__c
            FROM Opportunity 
            WHERE StageName = 'Orders Processing' 
            LIMIT 5000
        ];
        return oppList;
    }
    
    @AuraEnabled
    public static void processOpportunityProducts(List<String> opportunityIds) {
        Map<String, String> prodCodesToDispatchMap = new Map<String, String>();
        Boolean isFreeTrialPromo = false;
        Boolean isRevenue = false;
        List<String> emeaShippingCountryList = System.Label.EMEA_Countries.split(',');
        List<Opportunity> oppList = new List<Opportunity>();
        for (Opportunity opp : [
            SELECT Id, Type, Shipping_Country__c, Automation_Notes__c, StageName, (SELECT Id, OpportunityId, ProductCode, Quantity, UnitPrice, Ship_To_Country__c FROM OpportunityLineItems) 
            FROM Opportunity WHERE Id IN :opportunityIds
        ]) {
            if (opp.stageName == 'Orders Processing') {
                String prodCodesToDispatch = '';
                for(OpportunityLineItem oli : opp.OpportunityLineItems) {
                    if (oli.Quantity >= 1 && (oli.Ship_To_Country__c == 'United States' || oli.Ship_To_Country__c == 'Canada' || oli.Ship_To_Country__c == 'Mexico')) {
                        prodCodesToDispatch = prodCodesToDispatch + ',' + oli.ProductCode;                   
                    } else if (oli.Quantity >= 1 && emeaShippingCountryList.contains(oli.Ship_To_Country__c)) {
                        prodCodesToDispatch = prodCodesToDispatch + ',' + oli.ProductCode;  
                        break;
                    }
                }
                if (prodCodesToDispatch != '') {
                    prodCodesToDispatchMap.put(opp.Id, prodCodesToDispatch);
                }
            }
            
        }
        // Enqueue the validation job
        if(!prodCodesToDispatchMap.isEmpty() && !Test.isRunningTest() ){
            ValidateProductQuantityQueueable que = new ValidateProductQuantityQueueable(prodCodesToDispatchMap, true);
            System.enqueueJob(que);
        }
    }
}