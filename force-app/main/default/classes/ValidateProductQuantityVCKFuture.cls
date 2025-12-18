/* 
* Test Class : 
* Class Created: 01/18/2024
*/
//GTMS-15414
public class ValidateProductQuantityVCKFuture { 
    
    @future(callout=true)
    public static void fetchVCKProductQuantity(Map<String, String> prodCodesToDispatchMap) {
        System.debug('I am in the fetchVCKProductQuantity method!!!'); 
        
        List<Opportunity> oppstoUpdate = new List<Opportunity>();
        Map<Id, Opportunity> oppmaptoUpate = new Map<Id, Opportunity>();
        WarehouseResponseVCK result = new WarehouseResponseVCK();
        
        // EMEA Automation Notes logic Start
        Map<Id, Opportunity> oppData = new Map<Id, Opportunity>([
            SELECT Id, Name, Shipping_Address_NEW__r.Shipping_State__c, StageName, Segment_Sales_Role__c, Type, Ship_From_Location__c, 
            Automation_Notes__c, Shipping_Method__c, Shipping_Carrier__c, VG_unit_count__c, AG2_Unit_Count__c, VG_License_Count__c, 
            AG2_License_Count__c, AG4_License_Count__c, AG4_Unit_Count__c, Camera_Only_Deal__c, AG_unit_count__c, 
            CST_count_HW_VG54_NA__c, Required_VG_Mix__c, CST_count_HW_VG54_NA_NAH_unknown__c,
            (SELECT Id, OpportunityId, Ship_From_Location__c, UnitPrice, Quantity, ProductCode FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id IN :prodCodesToDispatchMap.keySet()
        ]);
        // EMEA Automation Notes logic end
        
        for (String oppId : prodCodesToDispatchMap.keySet()) {
            System.debug('----fetchVCKProductQuantity---- CP 2----' + prodCodesToDispatchMap);
            Opportunity relatedOpportunity = oppData.get(oppId);
            List<String> prodCodesList = prodCodesToDispatchMap.get(oppId).split(',');
            
            Boolean updateOppty = false;
            String warehouseErrorMessage = ''; // EMEA Automation Notes logic
            
            // EMEA Automation Notes logic Start
            // Reorganized inner logic and moved update outside product loop
            for (String prodCode : prodCodesList) {
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:VCK_Endpoint/' + prodCode);
                request.setMethod('GET');
                String authorizationHeader = 'Bearer bFPDYwB1LKwxb5OtjgVu44U5p2fKQjxIEMXbLcwzcsDmkSryuQ6GiCOC3AIptc11';
                request.setHeader('Authorization', authorizationHeader);
                
                Http http = new Http();                    
                HTTPResponse response = http.send(request);
                
                if (response.getStatusCode() == 200) {
                    result = WarehouseResponseVCK.parse(response.getBody());
                    
                    for (WarehouseResponseVCK.results res : result.results) {
                        System.debug('Product Description: ' + res.description);
                        System.debug('Product Code: ' + res.productCode);
                        System.debug('qtyAvailable: ' + res.qtyAvailable);
                        
                        if (res.qtyAvailable == null || res.qtyAvailable < Integer.valueOf(System.Label.VCK_Product_Quantity_Threshold)) {
                            updateOppty = false;
                            warehouseErrorMessage = 'Please verify the Warehouse Quantity';
                            System.debug('warehouseErrorMessage: ' + warehouseErrorMessage);
                            break; // Exit product loop if quantity is not sufficient
                        } else {
                            updateOppty = true;
                        }
                    }
                }
            }
            
            // Move Opportunity update logic *after* product loop
            Opportunity oppRec = new Opportunity();
            oppRec.Id = Id.valueOf(oppId);
            
            if (updateOppty) {
                oppRec.StageName = 'Ready To Ship';
                oppRec.Probability = 99;
                oppRec.Went_To_Ready_To_Ship_Date__c = Datetime.Now();
                oppRec.Went_To_Ready_To_Ship__c = TRUE;
                oppRec.Automation_Notes__c = 'Logicall Automation';
            } else if (String.isNotBlank(warehouseErrorMessage)) {
                oppRec.Automation_Notes__c = relatedOpportunity.Automation_Notes__c != null 
                    ? relatedOpportunity.Automation_Notes__c + ';' + warehouseErrorMessage 
                    : warehouseErrorMessage;
            }
            oppstoUpdate.add(oppRec);
            // EMEA Automation Notes logic
        }
        
        if (oppstoUpdate.size() > 0) {
            oppmaptoUpate.putAll(oppstoUpdate);
            if (oppmaptoUpate.size() > 0) {
                update oppmaptoUpate.values();
            }
        }
    }
}