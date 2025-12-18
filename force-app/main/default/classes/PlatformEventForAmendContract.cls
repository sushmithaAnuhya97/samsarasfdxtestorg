@RestResource(urlMapping='/amendContracts')
global with sharing class PlatformEventForAmendContract {
    
    @HttpPost
    global static String doPost(String contractId){ 
        String response;
        try{
            if(String.isBlank(contractId)){
                response = 'ContractId must be valid.';
            }else{
                amendContract(contractId);
                response = 'amendContract queued. DateTime:'+DateTime.now();
            }
        }catch(Exception exp){
            response = exp.getMessage();
        }
        return response;
    }
    
    @future(callout=true)
    public static void amendContract(String contractId){
        List<AmendContractResponse__e> events = new List<AmendContractResponse__e>();
        try{
            String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contractId, null);
            System.debug('quoteJSON==='+quoteJSON);  
            createPlatformEvent(quoteJSON,contractId);
        }catch(Exception exp){
            AmendContractResponse__e  event = new AmendContractResponse__e ();
            event.ContractId__c =contractId;
            event.Status__c = 'FAILED';
            event.message__c = 'Contract Amendment Failed.'+exp.getMessage();
            events.add(event);
            publishPlatformEvent(events);
        }   
    }
    
    public static void createPlatformEvent(String quoteJSON,String contractId){
        List<AmendContractResponse__e> events = new List<AmendContractResponse__e>();
        AmendContractResponse__e  event = new AmendContractResponse__e ();
        
        if(String.isBlank(quoteJSON)){
            event.Status__c = 'FAILED';
            event.message__c = 'Contract Amended Failed.'; 
        }else{
            Map<String, Object> quoteResponse = (Map<String, Object>) JSON.deserializeUntyped(quoteJSON);
            Map<String, Object> record = (Map<String, Object>)quoteResponse.get('record');
            
            event.AccountId__c =(String)record.get('SBQQ__Account__c');
            event.ContractId__c =contractId;
            event.OpportunityId__c =(String)record.get('SBQQ__Opportunity2__c');
            event.QuoteId__c =(String)record.get('Id');
            event.Status__c = 'SUCCESS';
            event.message__c = 'Contract Amended Successfully';
        }
        events.add(event);
        publishPlatformEvent(events);
    }
    public static void publishPlatformEvent(List<AmendContractResponse__e> events){
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }       
        } 
    }
}