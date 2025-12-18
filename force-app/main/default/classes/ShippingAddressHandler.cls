/* 
 * Class Created:  05/16/21 - @author: Satya
 * 08/03/22 Raghav - (GTMS-6072) Consolidated multiple unmanaged trigger, workflow field updates and process builder into one
 */ 
public class ShippingAddressHandler extends TriggerHandler 
{
    private Map<Id, Shipping_Address__c> oldShippingAddressMap;
    private Map<Id, Shipping_Address__c> newShippingAddressMap;
    private List<Shipping_Address__c> newShippingAddressList;
    private List<Shipping_Address__c> oldDeleteShippingAddressList;
    public static Boolean alreadyUpdateRan = false;
    public static Boolean alreadyInsertRan = false;
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{Shipping_Address__c.SobjectType};
    Private UnitOfWork uow;
    
    public ShippingAddressHandler() {
        this.oldShippingAddressMap = (Map<Id, Shipping_Address__c>) Trigger.oldMap;
        this.newShippingAddressMap = (Map<Id, Shipping_Address__c>) Trigger.newMap;
        this.newShippingAddressList = (List<Shipping_Address__c>) Trigger.new;
        this.oldDeleteShippingAddressList = (List<Shipping_Address__c>) Trigger.old;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }

    public override void beforeInsert() {
        if (!alreadyInsertRan) {
            //ShippingAddressHelper.shippingAddressSynch = true;
            EDQ.DataQualityService.SetValidationStatus(newShippingAddressList, oldDeleteShippingAddressList,
                                                       Trigger.IsInsert, 2); // GTMS-6072 - calls managed code
            ShippingAddressHelper.processDefaultValues(newShippingAddressList, oldShippingAddressMap, true);// GTMS-6072 - Call to logic that was part of workflow field update
            //ShippingAddressHelper.shippingAddressSynch = false;
            //if (!ShippingAddressHelper.shippingAddressSynch)
            ShippingAddressHelper.syncShippingAddress(newShippingAddressList, null);
            //ShippingAddressHelper.shippingAddressSynch = true;
            alreadyInsertRan = true;
        }
        
    }
    
    public override void afterInsert() {
        ShippingAddressHelper.createPlatformEvent();
        EDQ.DataQualityService.ExecuteWebToObject(newShippingAddressList, 2, Trigger.IsUpdate);// GTMS-6072 - call to logic that wass part of Process builder 
        
    }

    public override void beforeUpdate() {
        if (!alreadyUpdateRan) {
            system.debug('RODRIGO beforeUpdate');
            //ShippingAddressHelper.shippingAddressSynch = true;
            ShippingAddressHelper.processDefaultValues(newShippingAddressList, oldShippingAddressMap, false);// GTMS-6072 - Call to logic that was part of workflow field update
            //EDQ.DataQualityService.SetValidationStatus(newShippingAddressList, oldDeleteShippingAddressList,
            //                                           Trigger.IsInsert, 2);  // GTMS-6072 - calls managed code
            //ShippingAddressHelper.shippingAddressSynch = false;
            //if (!ShippingAddressHelper.shippingAddressSynch)
            ShippingAddressHelper.syncShippingAddress(newShippingAddressList, oldShippingAddressMap);
            //ShippingAddressHelper.shippingAddressSynch = true;
            alreadyUpdateRan = true;
        }
    }

    public override void afterUpdate() {
        ShippingAddressHelper.createPlatformEvent();
        system.debug('RODRIGO afterUpdate');
        //ShippingAddressHelper.shippingAddressSynch = true;
        //EDQ.DataQualityService.ExecuteWebToObject(newShippingAddressList, 2, Trigger.IsUpdate);// GTMS-6072 - call to logic that wass part of Process builder
        ShippingAddressHelper.updateOpportunityShippingAddress(newShippingAddressList, oldShippingAddressMap); // GTMS-25842
    }

    public override void beforeDelete() {
        
    }

    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
}