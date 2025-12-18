@IsTest
public class WarehouseResponseTest {
	
	static testMethod void testParse() {
		String json = '{'+
		'  \"error_code\": 0,'+
		'  \"error_message\": \"\",'+
		'  \"items\": ['+
		'    {'+
		'      \"item_number\": \"\\\"CSTR-NVYOWL\",'+
		'      \"description\": \"Coaster - Navy Owl 1=100\",'+
		'      \"open_wo\": 0,'+
		'      \"open_po\": 0,'+
		'      \"open_rma\": 0,'+
		'      \"on_demand\": 0,'+
		'      \"on_hand\": 0,'+
		'      \"on_hold\": 0,'+
		'      \"committed\": 0,'+
		'      \"in_process\": 0,'+
		'      \"available\": 0,'+
		'      \"net_available\": 0,'+
		'      \"inventory_type\": null,'+
		'      \"min_quantity\": 0,'+
		'      \"dcl_quantity\": 0,'+
		'      \"lots\": null'+
		'    }'+
		']'+
		'}';
		WarehouseResponse obj = WarehouseResponse.parse(json);
		System.assert(obj != null);
	}
}