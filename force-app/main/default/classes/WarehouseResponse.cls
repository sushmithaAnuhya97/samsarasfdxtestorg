/* 
 * Test Class : WarehouseResponseTest
 * Class Created: 09/03/20 - @author: Harsha
 */

public class WarehouseResponse {
	public Integer error_code;
	public String error_message;
	public List<Items> items;

	public class Items {
		public String item_number;
		public String description;
		public Integer open_wo;
		public Integer open_po;
		public Integer open_rma;
		public Integer on_demand;
		public Integer on_hand;
		public Integer on_hold;
		public Integer committed;
		public Integer in_process;
		public Integer available;
		public Integer net_available;
		public String inventory_type;
		public Integer min_quantity;
		public Integer dcl_quantity;
		public Object lots;
	}

	
	public static WarehouseResponse parse(String json) {
		return (WarehouseResponse) System.JSON.deserialize(json, WarehouseResponse.class);
	}
}