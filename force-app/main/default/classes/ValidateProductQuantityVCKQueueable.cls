/*
* Test Class : ValidateProductQuantityCalloutTest
* Class Created: 09/06/24 - @author: Purushotham Boddu
* 11/18/2020 Purushotham Boddu (GTMS-22357) (Moved ValidateProductQuantityFuture class into Queueable class)
* 04/14/2025 GTMS-27362 Fixes: Avoid repeated error messages & DML exceptions from Automation Notes exceeding length
*/

public class ValidateProductQuantityVCKQueueable implements Queueable, Database.AllowsCallouts {
    private Map<String, String> prodCodesToDispatchMap;
    Map<Id, Opportunity> oppmaptoUpate = new Map<Id, Opportunity>();
    List<Opportunity> oppstoUpdate = new List<Opportunity>();
    
    public ValidateProductQuantityVCKQueueable(Map<String, String> prodCodesToDispatchMap) {
        this.prodCodesToDispatchMap = prodCodesToDispatchMap;
    }
    
    public void execute(QueueableContext context) {
        System.debug('I am in the fetchVCKProductQuantity method!!!');
        
        WarehouseResponseVCK result = new WarehouseResponseVCK();
        
        Map<Id, Opportunity> oppData = new Map<Id, Opportunity>([
            SELECT Id, Name, Shipping_Address_NEW__r.Shipping_State__c, StageName, Segment_Sales_Role__c, Type, Ship_From_Location__c, Automation_Notes__c,
            Shipping_Method__c, Shipping_Carrier__c, VG_unit_count__c, AG2_Unit_Count__c, VG_License_Count__c, AG2_License_Count__c,
            AG4_License_Count__c, AG4_Unit_Count__c, Camera_Only_Deal__c, AG_unit_count__c, CST_count_HW_VG54_NA__c,
            Required_VG_Mix__c, CST_count_HW_VG54_NA_NAH_unknown__c,
            (SELECT Id, OpportunityId, Ship_From_Location__c, UnitPrice, Quantity, ProductCode FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id IN :prodCodesToDispatchMap.keySet()
        ]);
        
        for (String oppId : prodCodesToDispatchMap.keySet()) {
            Opportunity relatedOpportunity = oppData.get(oppId);
            
            // Clean up empty or malformed product codes
            List<String> rawCodes = prodCodesToDispatchMap.get(oppId).split(',');
            List<String> prodCodesList = new List<String>();
            for (String code : rawCodes) {
                if (!String.isBlank(code)) prodCodesList.add(code.trim());
            }
            
            Set<String> errorMessages = new Set<String>();
            Boolean allProductsValid = true;
            
            for (String prodCode : prodCodesList) {
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:VCK_Endpoint/' + prodCode);
                request.setMethod('GET');
                request.setHeader('Authorization', 'Bearer bFPDYwB1LKwxb5OtjgVu44U5p2fKQjxIEMXbLcwzcsDmkSryuQ6GiCOC3AIptc11');
                
                Http http = new Http();
                HTTPResponse response = http.send(request);
                
                if (response.getStatusCode() == 200) {
                    result = WarehouseResponseVCK.parse(response.getBody());
                    
                    for (WarehouseResponseVCK.results res : result.results) {
                        if (res.qtyAvailable == null || res.qtyAvailable < Integer.valueOf(System.Label.VCK_Product_Quantity_Threshold)) {
                            errorMessages.add('Please verify the Warehouse Quantity');
                            allProductsValid = false;
                            break;
                        }
                    }
                } else {
                    errorMessages.add('Error from Warehouse API for product: ' + prodCode);
                    allProductsValid = false;
                    break;
                }
                
                if (!allProductsValid) break;
            }
            
            // Handle Automation Notes when validation fails
            if (!allProductsValid) {
                String finalMessage = String.join(new List<String>(errorMessages), '; ');
                String existingNotes = String.isNotBlank(relatedOpportunity.Automation_Notes__c)
                    ? relatedOpportunity.Automation_Notes__c + '; '
                    : '';
                
                if (!existingNotes.contains(finalMessage)) {
                    String combinedNotes = existingNotes + finalMessage;
                    if (combinedNotes.length() > 255) {
                        combinedNotes = combinedNotes.substring(0, 255);
                    }
                    relatedOpportunity.Automation_Notes__c = combinedNotes;
                    oppstoUpdate.add(relatedOpportunity);
                }
            }
            
            // Only move to Ready to Ship if all products valid
            if (allProductsValid) {
                Opportunity oppRec = new Opportunity();
                oppRec.Id = Id.valueOf(oppId);
                oppRec.StageName = 'Ready To Ship';
                oppRec.Probability = 99;
                oppRec.Went_To_Ready_To_Ship_Date__c = Datetime.Now();
                oppRec.Went_To_Ready_To_Ship__c = TRUE;
                oppRec.Automation_Notes__c = 'Logical Automation';
                oppstoUpdate.add(oppRec);
            }
        }
        
        if (!oppstoUpdate.isEmpty()) {
            oppmaptoUpate.putAll(oppstoUpdate);
            if (!oppmaptoUpate.isEmpty()) {
                update oppmaptoUpate.values();
                System.debug('Updated Opportunities: ' + oppmaptoUpate);
            }
        }
    }
}