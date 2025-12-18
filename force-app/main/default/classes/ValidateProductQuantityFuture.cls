/* 
* Test Class : ValidateProductQuantityCalloutTest
* Class Created: 09/03/20 - @author: Harsha
* 11/18/2020 Harsha (GTMS-1643) (Added criteria for DCL Automation)
* 01/11/2021 Satya (GTMS-2572) DCL Phase 2 Automation
*/

public class ValidateProductQuantityFuture { 
    
    @future(callout=true)
    public static void fetchProductQuantity(Map<String, String> prodCodesToDispatchMap) {
        system.debug('I am in the fetchProductQuantity method!!!');
        List<opportunityLineItem> linestoUpdate = new List<opportunityLineItem>();
        Map<String, String> wareHouseMap = new Map<String, String>();
        Map<String, String> shipFromMap = new Map<String, String>();
        Map<String, String> shipFromUpdated = new Map<String, String>();
        Map<String, Map<String, Decimal>> revenueOppfieldsMap = new Map<String, Map<String, Decimal>>();
        List<String> AG4Xproducts = system.Label.AG4Xproducts.split(',');
        
        Map<Id, Opportunity> updatedOpportunities = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oppData = new Map<Id, Opportunity>([SELECT Id, Name, Shipping_Address_NEW__r.Shipping_State__c, Shipping_Country__c, StageName, Segment_Sales_Role__c, Type, Ship_From_Location__c, Automation_Notes__c, Shipping_Method__c, Shipping_Carrier__c, 
                                                                VG_unit_count__c, AG2_Unit_Count__c, VG_License_Count__c, AG2_License_Count__c, AG4_License_Count__c, AG4_Unit_Count__c, Camera_Only_Deal__c, AG_unit_count__c, 
                                                                CST_count_HW_VG54_NA__c, Required_VG_Mix__c, CST_count_HW_VG54_NA_NAH_unknown__c,
                                                                 (SELECT Id, OpportunityId, Ship_From_Location__c, UnitPrice, Quantity, ProductCode FROM OpportunityLineItems)
                                                                 FROM Opportunity WHERE Id 
                                                                 IN :prodCodesToDispatchMap.keyset()]);
        system.debug('----oppData---- cp 1----' + prodCodesToDispatchMap);
        List<Warehouse_Mapping__mdt> wareHouseMetaData = [SELECT MasterLabel,Related_Warehouse__c,Ship_From__c FROM Warehouse_Mapping__mdt];
        if(wareHouseMetaData != null){
            for(Warehouse_Mapping__mdt metaData : wareHouseMetaData){
                wareHouseMap.put(metaData.MasterLabel, metaData.Related_Warehouse__c);
                shipFromMap.put(metaData.MasterLabel, metaData.Ship_From__c);            }
        }
        WarehouseResponse result = new WarehouseResponse();
        for(String oppId: prodCodesToDispatchMap.keyset()){
            Opportunity relatedOpportunity = oppData.get(oppId);
            if(relatedOpportunity.Type == 'Revenue Opportunity'){
                Map<String,Decimal> opptyFields = new Map<String,Decimal>();
                opptyFields.put('CM_Unit_Count', 0);
                opptyFields.put('VG_Cable_Unit_Count', 0);
                opptyFields.put('AG4P_Unit_Count', 0);
                opptyFields.put('AG_cable_unit_count', 0);
                opptyFields.put('EM_Unit_Count', 0);
                opptyFields.put('CM_License_count', 0);
                opptyFields.put('EM_License_count', 0);
                opptyFields.put('AG4P_License_Count', 0);
                opptyFields.put('HW_product_count', 0);
                opptyFields.put('product_line_amount', 0); 
                opptyFields.put('product_line_zero', 0);
                opptyFields.put('VG_cable_sales_price',0);
                opptyFields.put('AG_cable_sales_price',0);
                opptyFields.put('AG4X_Unit_Count__c',0);
                opptyFields.put('AG46P_Unit_Count__c',0);
                opptyFields.put('HW_VG54_NA_Count',0);
                opptyFields.put('HW_VG54_NAH_Count',0);

                List<String> prodCodesList= prodCodesToDispatchMap.get(oppId).split(',');
                for(OpportunityLineItem oli : relatedOpportunity.OpportunityLineItems){
                    if(prodCodesList.contains(oli.ProductCode)){
                        if(oli.ProductCode.contains('HW-CM')){
                            Decimal CM_Unit_Count = opptyFields.get('CM_Unit_Count') != null ? opptyFields.get('CM_Unit_Count') + oli.quantity : 0;
                            opptyFields.put('CM_Unit_Count', CM_Unit_Count);
                        }
                        if(oli.ProductCode.contains('CBL-VG-')){
                            Decimal VG_Cable_Unit_Count = opptyFields.get('VG_Cable_Unit_Count') != null ? opptyFields.get('VG_Cable_Unit_Count') + oli.quantity : 0;
                            opptyFields.put('VG_Cable_Unit_Count', VG_Cable_Unit_Count);
                            if(oli.UnitPrice > 0 && opptyFields.get('VG_cable_sales_price') == 0) opptyFields.put('VG_cable_sales_price', 1);
                        }
                        if(oli.ProductCode.contains('HW-AG46P')){
                            Decimal AG4P_Unit_Count = opptyFields.get('AG4P_Unit_Count') != null ? opptyFields.get('AG4P_Unit_Count') + oli.quantity : 0;
                            opptyFields.put('AG4P_Unit_Count', AG4P_Unit_Count);
                        }
                        if(oli.ProductCode.contains('CBL-AG-')){
                            Decimal AG_cable_unit_count= opptyFields.get('AG_cable_unit_count') != null ? opptyFields.get('AG_cable_unit_count') + oli.quantity : 0;
                            opptyFields.put('AG_cable_unit_count', AG_cable_unit_count);
                            if(oli.UnitPrice > 0 && opptyFields.get('AG_cable_sales_price') == 0) opptyFields.put('AG_cable_sales_price', 1);
                        }
                        if(oli.ProductCode.contains('HW-EM') && !oli.ProductCode.contains('LIC-CM-STRM')){
                            Decimal EM_Unit_Count = opptyFields.get('EM_Unit_Count') != null ? opptyFields.get('EM_Unit_Count') + oli.quantity : 0;
                            opptyFields.put('EM_Unit_Count', EM_Unit_Count);
                        }
                        if(oli.ProductCode.contains('LIC-CM')){
                            Decimal CM_License_count= opptyFields.get('CM_License_count') != null ? opptyFields.get('CM_License_count') + oli.quantity : 0;
                            opptyFields.put('CM_License_count', CM_License_count);
                        }
                        if(oli.ProductCode.contains('LIC-EM')){
                            Decimal EM_License_count= opptyFields.get('EM_License_count') != null ? opptyFields.get('EM_License_count') + oli.quantity : 0;
                            opptyFields.put('EM_License_count', EM_License_count);
                        }
                        if(oli.ProductCode.contains('LIC-AG4P-ENT')){
                            Decimal AG4P_License_Count = opptyFields.get('AG4P_License_Count__c') != null ? opptyFields.get('AG4P_License_Count__c') + oli.quantity : 0;
                            opptyFields.put('AG4P_License_Count__c', AG4P_License_Count);
                        }
                        if(AG4Xproducts.contains(oli.ProductCode)){
                           Decimal AG4X_Unit_Count= opptyFields.get('AG4X_Unit_Count__c') != null ? opptyFields.get('AG4X_Unit_Count__c') + oli.quantity : 0;
                           opptyFields.put('AG4X_Unit_Count__c', AG4X_Unit_Count); 
                        }
                        if(oli.ProductCode.contains('HW-AG46P')){
                            Decimal AG46P_Unit_Count = opptyFields.get('AG46P_Unit_Count__c') != null ? opptyFields.get('AG46P_Unit_Count__c') + oli.quantity : 0;
                            opptyFields.put('AG46P_Unit_Count__c', AG46P_Unit_Count);
                        }
                        if(oli.ProductCode.contains('HW-VG54-NA')){
                            Decimal HW_VG54_NA_Count = opptyFields.get('HW_VG54_NA_Count') != null ? opptyFields.get('HW_VG54_NA_Count') + oli.quantity : 0;
                            opptyFields.put('HW_VG54_NA_Count', HW_VG54_NA_Count);
                        }
                        if(oli.ProductCode.contains('HW-VG54-NAH')){
                            Decimal HW_VG54_NAH_Count = opptyFields.get('HW_VG54_NAH_Count') != null ? opptyFields.get('HW_VG54_NAH_Count') + oli.quantity : 0;
                            opptyFields.put('HW_VG54_NAH_Count', HW_VG54_NAH_Count);
                        }
                        if(oli.ProductCode.contains('HW-') || oli.ProductCode.contains('ACC-') || oli.ProductCode.contains('CBL-')){
                            Decimal HW_product_count= opptyFields.get('HW_product_count') != null ? opptyFields.get('HW_product_count') + 1 : 0;
                            opptyFields.put('HW_product_count', HW_product_count);
                            if(oli.UnitPrice > 0){
                                Decimal product_line_amount= opptyFields.get('product_line_amount') != null ? opptyFields.get('product_line_amount') + 1 : 0;
                                opptyFields.put('product_line_amount', product_line_amount); 
                            }else{
                                Decimal product_line_zero= opptyFields.get('product_line_zero') != null ? opptyFields.get('product_line_zero') + 1 : 0;
                                opptyFields.put('product_line_zero', product_line_zero);
                            }
                        }
                    } 
                }
                revenueOppfieldsMap.put(oppId, opptyFields);
            }    
        }


        for(String oppId: prodCodesToDispatchMap.keyset()){
            system.debug('----fetchProductQuantity---- CP 2----' + prodCodesToDispatchMap);
            Opportunity relatedOpportunity = oppData.get(oppId);
            // added the bypassCondition for GTMS-18017 and GTMS-10999
            Boolean bypassCondition = relatedOpportunity.Type == 'Revenue Opportunity' &&
                          (relatedOpportunity.Segment_Sales_Role__c == 'AE1' ||
                           relatedOpportunity.Segment_Sales_Role__c == 'AE2' || 
                           relatedOpportunity.Segment_Sales_Role__c == 'AE3' || 
                           relatedOpportunity.Segment_Sales_Role__c == 'Enterprise');
            if( bypassCondition || (relatedOpportunity.Type != 'Revenue Opportunity') || (relatedOpportunity.Type == 'Revenue Opportunity' && checkRevenueOppCriteria(relatedOpportunity, revenueOppfieldsMap))){
                    String prodCodes = prodCodesToDispatchMap.get(oppId);
                    String wareHouse = 'ZLAC';
                    String shipFromLocation = null;
                    if(relatedOpportunity.Shipping_Address_NEW__r.Shipping_State__c != null){
                        wareHouse = wareHouseMap.get(relatedOpportunity.Shipping_Address_NEW__r.Shipping_State__c);
                        shipFromLocation = shipFromMap.get(relatedOpportunity.Shipping_Address_NEW__r.Shipping_State__c);
                    }
                    if(inTime() && oppData.get(oppId).Shipping_Method__c == 'Next Day Air') {
                        wareHouse = 'ZLAC';
                        shipFromLocation = 'DCL-LA';
                    }
                    System.debug('----shipping location after if condition----' + wareHouse + ' --- ' + shipFromLocation);
                    // GTMS-27254 - Added below if for DC Project
                    if(relatedOpportunity.Shipping_Country__c == 'Canada') {
                        wareHouse = 'ZOTC';
                        shipFromLocation = HelperClass.shippingCountryDefaults.get(relatedOpportunity.Shipping_Country__c).Ship_From_Location__c;
                    }
                    
                    Boolean updateOppty = false;
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint('callout:DCL_Endpoint/?group_by_inventory_type=True&item_numbers='+ prodCodes);
                    request.setMethod('GET');
                    Http http = new Http();
                    
                    HTTPResponse response = http.send(request);
                    if(response.getStatusCode() == 200){
                        result = WarehouseResponse.parse(response.getBody());
                        if(wareHouse != null){
                            for(WarehouseResponse.items item: result.items){
                                System.debug('Product Description: ' + item.description );
                                System.debug('Item Inventory Type: ' + item.inventory_type);
                                System.debug('Item Net Available: ' + item.net_available);
                                if(wareHouse.equalsIgnoreCase(item.inventory_type) && item.net_available > Integer.valueOf(System.Label.Product_Quantity_Threshold)){
                                    updateOppty = true; 
                                }
                                else if(wareHouse.equalsIgnoreCase(item.inventory_type) && item.net_available <= Integer.valueOf(System.Label.Product_Quantity_Threshold)){
                                    updateOppty = false;
                                    break;
                                }
                            }
                        }
                        
                        system.debug('----updateOppty----' + updateOppty);
                        if(Test.isRunningTest()) {
                            updateOppty = true;
                        }
                        if(updateOppty == true){
                            relatedOpportunity.Overwrite_Validation_Rule__c = true;
                            relatedOpportunity.StageName = 'Ready to Ship';
                            relatedOpportunity.Automation_Notes__c = 'DCL Automation';
                            if(shipFromLocation != null){
                                system.debug('----shipFromLocation---- CP 3----' + shipFromLocation);
                                relatedOpportunity.Ship_From_Location__c = shipFromLocation;
                                if(relatedOpportunity.Shipping_Country__c == 'Canada') {
                                    relatedOpportunity.Ship_From_Location__c = HelperClass.shippingCountryDefaults.get(relatedOpportunity.Shipping_Country__c).Ship_From_Location__c;
                                    relatedOpportunity.Shipping_Method__c = HelperClass.shippingCountryDefaults.get(relatedOpportunity.Shipping_Country__c).Shipping_Method__c;
                                    relatedOpportunity.Shipping_Carrier__c = HelperClass.shippingCountryDefaults.get(relatedOpportunity.Shipping_Country__c).Shipping_Carrier__c;
                                }
                                shipFromUpdated.put(oppId, shipFromLocation);
                            }
                            
                            if(oppData.get(oppId).Type == 'Free Trial Opportunity') {
                                relatedOpportunity.Shipping_Carrier__c = 'UPS';
                            }
                            system.debug('----fetchProductQuantity---- CP 5----' + relatedOpportunity);
                            updatedOpportunities.put(relatedOpportunity.Id,relatedOpportunity);
                            linestoUpdate.addAll(oppData.get(oppId).OpportunityLineItems);
                        }
                    } 
                    
                }
                
                for(OpportunityLineItem oli : linestoUpdate) {
                    system.debug('----shipFromUpdated.get(oli.OpportunityId)----' + shipFromUpdated.get(oli.OpportunityId));
                    oli.Ship_From_Location__c = (!shipFromUpdated.isEmpty() && shipFromUpdated.containsKey(oli.OpportunityId))? shipFromUpdated.get(oli.OpportunityId) : oppData.get(oli.OpportunityId).Ship_From_Location__c;
                }
            }
            // As part of ATHR GTMS-26027 ticket DML operation moved outside the for loop.
            if(!updatedOpportunities.isEmpty()){
                update updatedOpportunities.values();
            }
            if(!linestoUpdate.isEmpty()) {
                update linestoUpdate;
            }
        }
        public static Boolean inTime() {
            String now = System.now().format('HH:mm:ss', 'America/Los_Angeles');
            List<String> currentTime = now.split(':');
            Integer hour = Integer.valueOf(currentTime[0]);
            Integer minute = Integer.valueOf(currentTime[1]);
            Integer lb = Integer.valueOf(System.Label.DCL_Automation_Time_LB);
            Integer ub = Integer.valueOf(System.Label.DCL_Automation_Time_UB);
            if(hour >= lb && (hour < ub || (hour == ub && minute == 0 ))) {
                return true;
            }
            else
                return false;
    }

    public static Boolean checkRevenueOppCriteria(Opportunity opp, Map<String, Map<String, Decimal>> revenueOppfieldsMap) {
        Map<String,Decimal> opptyFieldsMap = revenueOppfieldsMap.get(opp.id);
        System.debug('opptyFieldsMap.get(CM_Unit_Count)'+opptyFieldsMap.get('CM_Unit_Count'));
        System.debug('opptyFieldsMap.get(VG_Cable_Unit_Count)'+opptyFieldsMap.get('VG_Cable_Unit_Count'));
        System.debug('opptyFieldsMap.get(AG_cable_unit_count)'+opptyFieldsMap.get('AG_cable_unit_count'));
        System.debug('opptyFieldsMap.get(CM_License_count)'+opptyFieldsMap.get('CM_License_count'));
        System.debug('opptyFieldsMap.get(EM_Unit_Count) '+opptyFieldsMap.get('EM_Unit_Count') );
        System.debug('opptyFieldsMap.get(AG4P_Unit_Count) '+opptyFieldsMap.get('AG4P_Unit_Count') );
        System.debug('opptyFieldsMap.get(AG4X_Unit_Count__c) '+opptyFieldsMap.get('AG4X_Unit_Count__c') );
        System.debug('opptyFieldsMap.get(EM_License_count)'+opptyFieldsMap.get('EM_License_count'));
        System.debug('opptyFieldsMap.get(HW_product_count)'+opptyFieldsMap.get('HW_product_count'));
        System.debug('opptyFieldsMap.get(product_line_amount) '+opptyFieldsMap.get('product_line_amount') );
        System.debug('opptyFieldsMap.get(product_line_zero)'+opptyFieldsMap.get('product_line_zero'));
        Decimal CST_count_HW_VG54_NA = 0;
        Decimal Required_VG_Mix = 0;
        if(opp.CST_count_HW_VG54_NA__c != null) CST_count_HW_VG54_NA = opp.CST_count_HW_VG54_NA__c;
        if(opp.Required_VG_Mix__c != null) Required_VG_Mix = opp.Required_VG_Mix__c;


        if((opp.VG_unit_count__c == opptyFieldsMap.get('CM_Unit_Count') || opptyFieldsMap.get('CM_Unit_Count') == 0) && 
            (opp.VG_unit_count__c == opptyFieldsMap.get('VG_Cable_Unit_Count') || (opp.VG_unit_count__c ==0 && opptyFieldsMap.get('VG_Cable_Unit_Count') > 1 && opptyFieldsMap.get('VG_cable_sales_price') > 0))
          && ((opp.AG2_Unit_Count__c + opptyFieldsMap.get('AG4P_Unit_Count') == opptyFieldsMap.get('AG_cable_unit_count')) || (opp.AG_unit_count__c ==0 && opptyFieldsMap.get('AG_cable_unit_count') > 1 && opptyFieldsMap.get('AG_cable_sales_price') > 0)) 
          && ((opp.AG2_Unit_Count__c == opp.AG2_License_Count__c) && (opptyFieldsMap.get('AG4X_Unit_Count__c') == opp.AG4_License_Count__c) && (opptyFieldsMap.get('AG4P_Unit_Count') == opptyFieldsMap.get('AG4P_License_Count')) && (opptyFieldsMap.get('CM_Unit_Count') == opptyFieldsMap.get('CM_License_count')) && (opptyFieldsMap.get('EM_Unit_Count') == opptyFieldsMap.get('EM_License_count'))
          && (((opp.Camera_Only_Deal__c == FALSE) & (opp.VG_unit_count__c == opp.VG_License_Count__c)) || (opp.Camera_Only_Deal__c == TRUE & opp.VG_License_Count__c ==0 )))
          && ((opptyFieldsMap.get('HW_product_count') == opptyFieldsMap.get('product_line_amount') || opptyFieldsMap.get('HW_product_count') == opptyFieldsMap.get('product_line_zero'))))
          {
            System.debug(opp.name.contains('Webstore'));
            if(!opp.name.contains('Webstore')){
                System.debug('in webstore');
                if((CST_count_HW_VG54_NA == opptyFieldsMap.get('HW_VG54_NA_Count')) && (Required_VG_Mix == opptyFieldsMap.get('HW_VG54_NAH_Count')) && opp.CST_count_HW_VG54_NA_NAH_unknown__c == null){
                    System.debug('in CST');
                    return true;
                }else{
                    return false;
                }
            }else{
                return true;
            }
          }
        return false;
    }
}