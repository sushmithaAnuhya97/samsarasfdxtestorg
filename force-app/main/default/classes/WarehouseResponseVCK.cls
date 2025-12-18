/* 
 * Test Class : WarehouseResponseVCKTest
 * Class Created: 01/18/2024 
 */
//GTMS-15414
public class WarehouseResponseVCK {
	public Integer total;
	public Integer length;
	public List<Results> results;

	public class Results {
		public String skuCode;
		public String productCode;
        public String description;
		public Integer qtyOnHand;
		public Integer qtyInbound;
		public Integer qtyReserved;
		public Integer qtyAvailable;
	}

	public static WarehouseResponseVCK parse(String json) {
		return (WarehouseResponseVCK) System.JSON.deserialize(json, WarehouseResponseVCK.class);
	}
}