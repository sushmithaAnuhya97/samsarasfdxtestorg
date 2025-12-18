/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-01-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class DocuSignStatusHandler {
    
    public static void updatePrimaryQuote(List<dsfs__DocuSign_Status__c> docuStatusRecords,Map<Id,dsfs__DocuSign_Status__c> oldMap){
        try{ 
            List<String> envelopeIds = new List<String>();
            List<string> oppIds = new List<string>();
            Map<String,dsfs__DocuSign_Envelope__c> docusignEnvelop = new Map<String,dsfs__DocuSign_Envelope__c>();
            Map<string,opportunity> oppsMap = new Map<string,opportunity>();
            
            for(dsfs__DocuSign_Status__c status: docuStatusRecords){
                if(String.isNotBlank(status.dsfs__DocuSign_Envelope_ID__c)){
                    envelopeIds.add(status.dsfs__DocuSign_Envelope_ID__c);
                }
                
                if(status.dsfs__Envelope_Status__c == 'Completed' && oldMap != null && oldMap.get(status.Id)?.dsfs__Envelope_Status__c != status.dsfs__Envelope_Status__c){
                    oppIds.add(status.dsfs__Opportunity__c);
                }
            }
            if(! oppIds.isEmpty() && oppIds.size() >0){
                for(opportunity opp:[select Id,Customer_require_PO_for_invoicing__c,PO_Number__c from opportunity where Id IN:oppIds]){
                   oppsMap.put(opp.Id,opp); 
                }
            }
            if(! envelopeIds.isEmpty() && envelopeIds.size() >0){
                
                for(dsfs__DocuSign_Envelope__c envelope :[Select Id,dsfs__DocuSign_Envelope_ID__c,dsfs__Source_Object__c from dsfs__DocuSign_Envelope__c where dsfs__DocuSign_Envelope_ID__c IN :envelopeIds]){
                    docusignEnvelop.put(envelope.dsfs__DocuSign_Envelope_ID__c?.toUpperCase(),envelope);  
                }
            }
            
            for(dsfs__DocuSign_Status__c status: docuStatusRecords){
                
                if(String.isNotBlank(status.dsfs__DocuSign_Envelope_ID__c) &&  ! docusignEnvelop.isEmpty() && docusignEnvelop.containsKey(status.dsfs__DocuSign_Envelope_ID__c.toUpperCase())
                   && String.isNotBlank(docusignEnvelop.get(status.dsfs__DocuSign_Envelope_ID__c.toUpperCase()).dsfs__Source_Object__c )){
                       Id myId = Id.valueOf(docusignEnvelop.get(status.dsfs__DocuSign_Envelope_ID__c.toUpperCase()).dsfs__Source_Object__c);
                       String sObjName = myId.getSObjectType().getDescribe().getName();
                       
                       if(sObjName == 'SBQQ__Quote__c'){
                           status.Primary_Quote__c = docusignEnvelop.get(status.dsfs__DocuSign_Envelope_ID__c?.toUpperCase()).dsfs__Source_Object__c;  
                       }
                       
                       
                   }
                
                if( string.isBlank( status.Customer_require_PO_for_invoicing__c) && status.dsfs__Envelope_Status__c == 'Completed' && oldMap != null && oldMap.get(status.Id)?.dsfs__Envelope_Status__c != status.dsfs__Envelope_Status__c
                    &&  !oppsMap.isempty() && oppsMap.containsKey(status.dsfs__Opportunity__c)){
                    status.PO_Number__c = oppsMap.get(status.dsfs__Opportunity__c)?.PO_Number__c;
                    status.Customer_require_PO_for_invoicing__c =  oppsMap.get(status.dsfs__Opportunity__c)?.Customer_require_PO_for_invoicing__c;   
                }

                
            }
        }catch(Exception e){
            
        }     
        
    }
    
}