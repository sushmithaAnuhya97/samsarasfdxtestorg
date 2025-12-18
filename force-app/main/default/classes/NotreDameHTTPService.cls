/**
 * Created by vikasmishra on 2021-06-21.
 */

public with sharing class NotreDameHTTPService extends gslib_RestClient{

    @TestVisible
    private static String LEAD_CONVERSION_PATH = System.Label.LEAD_CONVERSION_PATH;//'/organic-lead';6/4/24 Vijaychandra (GTMS-21405):Coomented to change the url
    private static final String APPLICATION_FORM_URLENCODED = 'application/json';
    @TestVisible
    static gslib_IRestClientSerializer thisNotreDameLeadSerializer = new NotreDameLeadSerializer();
    public NotreDameHTTPService(){
        super('Callout:NotreDame_API', thisNotreDameLeadSerializer);
    }

    public Object postLeadToNotreDame( SObject thisLead){

        Object response = this.createRequest().post(
                LEAD_CONVERSION_PATH,
                thisLead
        );
        return response;
    }

    public with sharing class NotreDameLeadSerializer implements gslib_IRestClientSerializer{

        public String contentType(){
            return NotreDameHTTPService.APPLICATION_FORM_URLENCODED;
        }
        public Object serialize(HttpRequest request, Object payload){
            Lead thisLead = new Lead();
            if(payload instanceof Lead){
                thisLead = (Lead) payload;
            }
            Map<String, Object> flatResponseMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(createPayloadMap(thisLead))) ;
            flatResponseMap.put('sent_from_partner_portal', true);//(GTMS-21405): replaced SentFromPartnerPortal with sent_from_partner_portal
        	System.domain d = System.DomainParser.parse(URL.getOrgDomainUrl());
            flatResponseMap.put('non_production_sfdc_env_name', d.getSandboxName());//8/8/24: replace below isSandbox with current line
            //flatResponseMap.put('use_sfdc_int_env',[SELECT Id,isSandbox FROM Organization].isSandbox);
            //flatResponseMap.put('LeadId', thisLead.Id);(GTMS-21405): added id in createPayloadMap method
            string leadDealRegRT = sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Channel_Registration').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Channel Registration' LIMIT 1];
            string leadPartnerAppRT = sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Partner_Application').getRecordTypeId(); //[Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Partner Application' LIMIT 1];
            if(thisLead.RecordTypeId == leadPartnerAppRT) {
                flatResponseMap.put('campaign', 'Partner Application Form');
            }
            else {
                flatResponseMap.put('campaign', 'Deal Registration Form');
            }
            return JSON.serialize(flatResponseMap);
        }
        //6/4/24 Vijaychandra --START-- (GTMS-21405): Below method will create payload of lead data for NotreDame
        /****
         * @Description: Below method will create payload of lead data for NotreDame
         * @param: (leadRec) lead record
         * @return: Map<string, Object> map of NotreDame property and respective lead Data
         */
        public Map<string, Object> createPayloadMap(Lead leadRec){
            Map<String, Object> payLoadMap = new Map<String, Object>();
            Map<String, Object> leadFieldMap = leadRec.getPopulatedFieldsAsMap();
        
            if(!leadFieldMap.isEmpty()){
                for(NotreDame_Fields_Mapping__mdt mdtRec: NotreDame_Fields_Mapping__mdt.getAll().values()){
                    if(mdtRec.MasterLabel != null && mdtRec.Lead_Field_Name__c != null){
                        payLoadMap.put(mdtRec.MasterLabel, leadFieldMap.get(mdtRec.Lead_Field_Name__c));
                    }
                }
            }
            return payLoadMap;
        }
        //--END-- (GTMS-21405)

        public Object deserialize(HttpRequest request, HttpResponse response){
            /*gslib_RestJsonSerializer restJsonSerializer = new gslib_RestJsonSerializer();
            Map<String, Object> deSerializedRes = (Map<String, Object>) restJsonSerializer.deserialize(request, response);
            Map<String, String> returnResponse = new Map<String, String>{
                    'status'=>''
            };
            for(String thisKey : deSerializedRes.keySet()){
                if(returnResponse.containsKey(thisKey)){
                    returnResponse.put(
                            thisKey,
                            String.valueOf(deSerializedRes.get(thisKey))
                    );
                }
            }*/
            return response.getBody();
        }

        public Object deserializeError(HttpRequest request, HttpResponse response){
            return response.getBody();
        }
    }
}