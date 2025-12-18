/**
* @description       : This class is used to perform opportunity field update for Order and Finance
* @author            : Mayank G
* @group             :
* @last modified on  : 03-26-2025
* @last modified by  : Mayank G
**/
public class OppHelperForOrderAndFinance {
    public static void updateShipFromLocationBasedOnCountry(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap){ 
        Set<Id> shippingAddNew = new Set<Id>();
        for (Opportunity oppty : newOppList) {
            if(oppty.Shipping_Country__c != null && oppty.Shipping_Country__c == 'Canada' && (oldOppMap == null || (oldOppMap != null && (oldOppMap.get(oppty.Id).Shipping_Country__c != oppty.Shipping_Country__c)))) { 
                if(HelperClass.shippingCountryDefaults.containskey(oppty.Shipping_Country__c)) {
                 	oppty.Ship_From_Location__c = HelperClass.shippingCountryDefaults.get(oppty.Shipping_Country__c).Ship_From_Location__c;
                    oppty.Shipping_Method__c = HelperClass.shippingCountryDefaults.get(oppty.Shipping_Country__c).Shipping_Method__c;
                    oppty.Shipping_Carrier__c = HelperClass.shippingCountryDefaults.get(oppty.Shipping_Country__c).Shipping_Carrier__c;   
                }
            }
        }
    }
  
  public void updateOrderManagementProcessor(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap){
        
        if (UserInfo.getProfileId() == label.Profile_Samsara_Finance){
            for (Opportunity oppty : newOppList) {
                if (oldOppMap != null && oppty.StageName != oldOppMap.get(oppty.Id).StageName && (oppty.StageName == 'Purchase' || oppty.StageName == 'Orders Processing')) { 
                    oppty.Order_Management_Processor__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                }
            }
        }

    }
}