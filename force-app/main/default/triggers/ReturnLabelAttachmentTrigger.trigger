/*
 * 9/17/2020 Ron - (GTMS-1457): update trigger to handle concatenation of multiple attachments with either batch or non batch attachment addition
*/

trigger ReturnLabelAttachmentTrigger on Attachment (after insert, after update) {
    DiagnosticsInstrumentation.push('ReturnLabelAttachmentTrigger');
    List<Opportunity> opptysToUpdate = new List<Opportunity>();
    Map<Id, String> shipmentIdToAttachmentId = new Map<Id, String>();
    Boolean batchFlag = false;
    if(Trigger.new.size() > 1){
        batchFlag = true;
    }
    
    for(Attachment attachment : Trigger.new){
        Boolean addAttachment = false;

        if((attachment.name.toLowercase().contains('label') || attachment.name.toLowercase().contains('international forms') || attachment.name.toLowercase().contains('international-forms')) && (attachment.name.toLowercase().contains('.gif') || attachment.name.toLowercase().contains('.pdf'))){
            addAttachment = true;
        }

        if(addAttachment){
            if(batchFlag){
                if(shipmentIdToAttachmentId.containsKey(attachment.ParentId)){
                    String shipmentAttachmentInitialId = shipmentIdToAttachmentId.get(attachment.parentId);
                    shipmentAttachmentInitialId = shipmentAttachmentInitialId+','+attachment.Id;
                    shipmentIdToAttachmentId.put(attachment.ParentId, shipmentAttachmentInitialId);
                } else{
                    shipmentIdToAttachmentId.put(attachment.parentId, attachment.Id);
                }
            } else{
                if(!shipmentIdToAttachmentId.containsKey(attachment.ParentId)){
                    shipmentIdToAttachmentId.put(attachment.ParentId, attachment.Id);
                }
            }
        }
    }

    if(shipmentIdToAttachmentId.size() > 0){   
        Set<Id> oppIds = new Set<Id>();

        for(zkmulti__MCShipment__c shipment : [  SELECT  Id, 
                                                        Name, 
                                                        Opportunity__c 
                                                FROM zkmulti__MCShipment__c 
                                                WHERE Id IN :shipmentIdToAttachmentId.keyset()]){
            oppIds.add(shipment.Opportunity__c);
            if(batchFlag){
                opptysToUpdate.add(new Opportunity(Id = shipment.Opportunity__c, Return_Label_Attachment__c = shipmentIdToAttachmentId.get(shipment.Id), StageName = 'Return Label Sent'));
            }
        }

        if(!batchFlag){
            Map<Id, Opportunity> opps = new Map<Id, Opportunity>([  SELECT  Id,
                                                                            StageName,
                                                                            Name, 
                                                                            Return_Label_Attachment__c 
                                                                    FROM Opportunity 
                                                                    WHERE Id IN : oppIds]);

            for(zkmulti__MCShipment__c shipment : [  SELECT  Id, 
                                                            Name, 
                                                            Opportunity__c 
                                                    FROM zkmulti__MCShipment__c 
                                                    WHERE Id IN :shipmentIdToAttachmentId.keyset()]){

                Opportunity opp = opps.get(shipment.Opportunity__c);
                String idToAttach = shipmentIdToAttachmentId.get(shipment.Id);
                opp.StageName = 'Return Label Sent';
                if(opp.Return_Label_Attachment__c != null){
                    if(idToAttach != opp.Return_Label_Attachment__c){
                        opp.Return_Label_Attachment__c = opp.Return_Label_Attachment__c+','+idToAttach;
                    }
                } else{
                    opp.Return_Label_Attachment__c = idToAttach;
                }
                opptysToUpdate.add(opp);
            }
        }
    }
    
    if(opptysToUpdate.size() > 0) {
        update opptysToUpdate;
    }    
    DiagnosticsInstrumentation.pop();

}