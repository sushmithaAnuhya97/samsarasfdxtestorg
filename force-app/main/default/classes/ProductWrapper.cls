public class ProductWrapper {
    @AuraEnabled
    public String originalProductId { get; set; }
    @AuraEnabled 
    public String originalProductName { get; set; }
    @AuraEnabled
    public String originalProductCode { get; set; }
    @AuraEnabled
    public String defaultHardwareCodeURL { get; set; }
    @AuraEnabled
    public String defaultHardwareId { get; set; }
    @AuraEnabled
    public Integer originalTotalQuantity { get; set; }
    @AuraEnabled
    public Boolean isPlatformUpgradeEnabled { get; set; }
    @AuraEnabled
    public List<PlatformUpgradeScreenDetail> platformUpgradeScreenDetails { get; set; }
    @AuraEnabled
    public FinalScreenDetails finalScreenDetails { get; set; }
    
    public class PlatformUpgradeScreenDetail {
        @AuraEnabled
        public String shippingAddressId { get; set; }
        @AuraEnabled
        public String shippingAddressName { get; set; }
        @AuraEnabled
        public Integer quantity { get; set; }
        @AuraEnabled
        public SelectedUpgradeProduct selectedUpgradeProduct { get; set; }
    }
    
    public class SelectedUpgradeProduct {
        @AuraEnabled
        public String productId { get; set; }
        @AuraEnabled
        public String productName { get; set; }
        @AuraEnabled
        public String productCode { get; set; }
        @AuraEnabled
        public String defaultHardwareCodeURL { get; set; }
        @AuraEnabled
        public String defaultHardwareId { get; set; }
    }
    
    public class FinalScreenDetails {
        @AuraEnabled
        public String productId { get; set; }
        @AuraEnabled
        public String productName { get; set; }
        @AuraEnabled
        public String productCode { get; set; }
        @AuraEnabled
        public String defaultHardwareCodeURL { get; set; }
        @AuraEnabled
        public String defaultHardwareId { get; set; }
        @AuraEnabled
        public Integer originalTotalQuantity { get; set; }
        @AuraEnabled
        public Boolean allSelected { get; set; }
        @AuraEnabled
        public List<ShipToAddress> shipToAddresses { get; set; }
    }
    
    public class ShipToAddress {
        @AuraEnabled
        public String addressId { get; set; }
        @AuraEnabled
        public String addressName { get; set; }
        @AuraEnabled
        public Integer quantity { get; set; }
        @AuraEnabled
        public Boolean isSelectedUpgrade { get; set; }
        @AuraEnabled
        public UpgradeProduct upgradeProduct { get; set; }
        @AuraEnabled
        public Decimal averageMonthlyUnitPrice { get; set; }
    }
    
    public class UpgradeProduct {
        @AuraEnabled
        public String productId { get; set; }
        @AuraEnabled
        public String productName { get; set; }
        @AuraEnabled
        public String productCode { get; set; }
        @AuraEnabled
        public String defaultHardwareCodeURL { get; set; }
        @AuraEnabled
        public String defaultHardwareId { get; set; }
        @AuraEnabled
        public Integer upgradeQuantity { get; set; }
        @AuraEnabled
        public Integer remainingQuantity { get; set; }
    }
}