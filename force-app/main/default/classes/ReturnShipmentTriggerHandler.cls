//Aug-22-2022  Chinmaya Dash GTMS-6069 Created This class for Updating tracking number of opportunity from return shipment.
public class ReturnShipmentTriggerHandler
{	
    Public static Boolean ExecuteBlock=true;
    
    public void onAfterInsert(List<zkups__UPSShipment__c> triggerNew)
    {
         If(ExecuteBlock==true && System.label.ReturnShipmentLabel=='PE'){
            
            for (zkups__UPSShipment__c shipment : triggerNew){
                
                Return_Shipment__e  event = new Return_Shipment__e ();
                event.Opportunity_Id__c  = shipment.Shipmate_Label__c;
                event.Tracking_Id__c  = shipment.zkups__MasterTrackingId__c;
                EventBus.publish(event); 
            }
        }
        Else{
            List<Id> associatedOpptyIds = new List<Id>();
            Map<Id, String> trackingNumbers = new Map<Id, String>();
            
            for (zkups__UPSShipment__c shipment : triggerNew){
                associatedOpptyIds.add(shipment.Shipmate_Label__c);
                trackingNumbers.put(shipment.Shipmate_Label__c, shipment.zkups__MasterTrackingId__c);
            }
            
            List<Opportunity> returnOpptys = [SELECT Id, Type, Tracking_Number__c FROM Opportunity WHERE ( Type = 'Free Trial Return' OR Type = 'Exchange' OR Type = 'Remorse Refund'
                                                                                                          OR Type = 'Warranty Exchange' OR (Type = 'Rebate' AND (Rebate_Type__c = 'Buyout' OR Rebate_Type__c = 'Partner Referral')) ) AND Id IN :associatedOpptyIds];
            
            if(returnOpptys.size() > 0){
                
                for (Opportunity oppty : returnOpptys){
                    oppty.Tracking_Number__c = trackingNumbers.get(oppty.Id);
                }                
                update returnOpptys;
            }
        }
    }
}