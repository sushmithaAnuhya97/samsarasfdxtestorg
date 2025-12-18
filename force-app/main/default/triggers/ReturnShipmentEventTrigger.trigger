//Aug-22-2022  Chinmaya Dash GTMS-6069 Created this Trigger for Optimizing ReturnShipmentTrigger.
trigger ReturnShipmentEventTrigger on Return_Shipment__e (after insert) {
    
    List<Database.SaveResult> updateResults = new List<Database.SaveResult>();//GTMS-6069
    List<Opportunity> OppList = new List<Opportunity>();//GTMS - 6069
    Map<Id, String> trackingNumbers = new Map<Id, String>();
    List<Contract> contractListToUpdate = new List<Contract>();
    
    for (Return_Shipment__e shipment : Trigger.new){
        if(shipment.Opportunity_Id__c.startsWith('006'))
            trackingNumbers.put(shipment.Opportunity_Id__c, shipment.Tracking_Id__c);
        if(shipment.Opportunity_Id__c.startsWith('800'))
            contractListToUpdate.add(new Contract(Id = shipment.Opportunity_Id__c, Status = 'Activated'));
    }
    
    if(trackingNumbers.size() > 0){
        List<Opportunity> returnOpptys = [SELECT Id, Type, Tracking_Number__c FROM Opportunity WHERE ( Type = 'Free Trial Return' OR Type = 'Exchange' OR Type = 'Remorse Refund'
                                                                                                  OR Type = 'Warranty Exchange' OR (Type = 'Rebate' AND (Rebate_Type__c = 'Buyout' OR Rebate_Type__c = 'Partner Referral')) ) AND Id IN :trackingNumbers.keyset()];
    
        List<Opportunity> newlistopp = new List<Opportunity>();
        if(returnOpptys.size() > 0){       
            for (Opportunity oppty : returnOpptys){
                oppty.Tracking_Number__c = trackingNumbers.get(oppty.Id);
                newlistopp.add(oppty);
            }
            //update returnOpptys;        
            if(newlistopp.size()>0)
            {
                updateResults = Database.update(newlistopp,false);
            }
            for(Integer i=0;i<updateResults.size();i++)
            {
                if(!updateResults[i].isSuccess())
                {
                    for(Database.Error err : updateResults[i].getErrors())
                    {
                        //System.DmlException: Insert failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                        if(err.getMessage().contains('UNABLE_TO_LOCK_ROW') )
                        {
                            OppList.add(newlistopp[i]);                        
                        }
                    }
                }
            }
            Database.update(OppList,false);        
        }
    }
    if(contractListToUpdate.size() > 0){
         Database.update(contractListToUpdate,false);
    }
}