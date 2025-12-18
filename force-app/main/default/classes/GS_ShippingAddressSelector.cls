/**
* Created By : Groundswell - Flávio Contini
* @Date August 26, 2021
*
* @description : This class will be responsible for handling all Shipping_Address__c queries / SOQLs
* SFA-10
*
**/
public with sharing class GS_ShippingAddressSelector extends GS_SObjectBaseSelector{

    public GS_ShippingAddressSelector(Boolean checkFatalError){
        super(checkFatalError);
    }
     
    public GS_ShippingAddressSelector checkFatalError(){
        return (GS_ShippingAddressSelector) super.validateFatalError();
    }

    public List<Shipping_Address__c> loadShippingAddressById(List<Id> idList){
        return [
            SELECT Id, Name, Shipping_State__c, Shipping_City__c, Shipping_Country__c,
                   Shipping_Address_Line_1__c, Shipping_Zip_Code__c
              FROM Shipping_Address__c
             WHERE ID IN :idList
        ];
    }

    public Map<Id, Shipping_Address__c> getShippingAddressById(Set<Id> addressIds){
        return new Map<Id, Shipping_Address__c>([
            SELECT Id, Name, Shipping_State__c, Shipping_City__c, Shipping_Country__c,
                Shipping_Address_Line_1__c, Shipping_Zip_Code__c
            FROM Shipping_Address__c
            WHERE ID IN :addressIds
        ]);
    }
}