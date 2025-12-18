@isTest
public class ShippingAddressDataQualityExt_Test {
    public static @isTest void testShippingAddress(){
        Shipping_Address__c shippingAddress = new Shipping_Address__c();
        PageReference pageRef = Page.ShippingAddressDataQuality;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(shippingAddress);
        ShippingAddressDataQualityExt dataQuality = new ShippingAddressDataQualityExt(sc);
        
        
    }
}