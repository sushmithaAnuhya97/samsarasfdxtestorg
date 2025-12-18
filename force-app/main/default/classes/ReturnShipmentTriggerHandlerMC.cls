public class ReturnShipmentTriggerHandlerMC
{   
    Public static Boolean ExecuteBlock=true;
    
    public void onAfterInsert(List<zkmulti__MCShipment__c> triggerNew)
    {
         If(ExecuteBlock==true && System.label.ReturnShipmentLabel=='PE'){
            for (zkmulti__MCShipment__c shipment : triggerNew){
                Return_Shipment__e  event = new Return_Shipment__e (Opportunity_Id__c = shipment.Opportunity__c, Tracking_Id__c  = shipment.zkmulti__Tracking_Number__c);
                EventBus.publish(event); 
            }
        }
        Else{
            List<Id> associatedOpptyIds = new List<Id>();
            Map<Id, String> trackingNumbers = new Map<Id, String>();
            
            for (zkmulti__MCShipment__c shipment : triggerNew){
                associatedOpptyIds.add(shipment.Opportunity__c);
                trackingNumbers.put(shipment.Opportunity__c, shipment.zkmulti__Tracking_Number__c);
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