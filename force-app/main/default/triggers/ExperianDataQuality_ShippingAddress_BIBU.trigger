trigger ExperianDataQuality_ShippingAddress_BIBU on Shipping_Address__c (before insert,
before update) {
 EDQ.DataQualityService.SetValidationStatus(Trigger.new, Trigger.old,
Trigger.IsInsert, 2); }