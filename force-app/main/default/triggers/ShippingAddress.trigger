trigger ShippingAddress on Shipping_Address__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    //new ShippingAddressHandler().run();
    new GS_TriggerHandlerRunnerConfig().createHandler('ShippingAddress').run();
}