public with sharing class ShippingAddressDataQualityExt {
 public ShippingAddressDataQualityExt(ApexPages.StandardController stdController) {
 this.PageRenderer = new EDQ.PageRenderer(stdController, 'Shipping_Address__c');
 }
 public EDQ.PageRenderer PageRenderer { get; private set; }
}