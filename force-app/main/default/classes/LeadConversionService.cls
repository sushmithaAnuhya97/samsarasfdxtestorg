/**
 * Created by vikasmishra on 2021-06-21.
 */

/**
 * @description : This class will be responsible for lead conversion
 */
public inherited sharing class LeadConversionService implements IService{

    public static final Set<Id> recordTypeToProcess = new Set<Id>{
            getRecordTypeId(
                    'Lead',
                    'Partner_Application'
            ),
            getRecordTypeId(
                    'Lead',
                    'Channel_Registration'
            )

    };

    static final String statusMasterLabel = 'Qualified';
    List<Lead> successfullyConvertedLeads = new List<Lead>();
    @TestVisible
    static ISelector leadSelector = new LeadSelector();
    @TestVisible
    static IDMLHelper leadDMLHelper = new LeadDmlHelper();
    @TestVisible
    Map<Id, Lead> idToLeadMap = new Map<Id, Lead>();
    Map<Id, Lead> mapOfQueriedLeadsById = new Map<Id, Lead>();
    List<Database.LeadConvertResult> conversionResultList = new List<Database.LeadConvertResult>();
    List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
    public LeadConversionService  setIdToLeadMap(Map<Id, Lead> idToLeadMap){
        this.idToLeadMap = idToLeadMap;
        return this;
    }

    public LeadConversionService processIncomingLeads(){
         mapOfQueriedLeadsById = new Map<Id, Lead>(leadSelector.getLeadsByIds(idToLeadMap.keySet()));
        return this;
    }

    public LeadConversionService doConversion (){
        for(Lead thisLead : mapOfQueriedLeadsById.values()){
            if(recordTypeToProcess.contains(thisLead.RecordTypeId)){
                leadsToConvert.add(instantiateLead(thisLead));
            }
        }
        conversionResultList = leadDMLHelper.convertLead(leadsToConvert, false);
        return this;
    }

    private Database.LeadConvert instantiateLead (Lead thisLead){
        Database.LeadConvert thisLC = new Database.LeadConvert();
        thisLC.setLeadId(thisLead.Id);
        thisLC.setDoNotCreateOpportunity(true);
        thisLC.setConvertedStatus(statusMasterLabel);//08/22/24 Vijaychandra (GTMS-22483): Commented as part of Partner Application phase 2 project
        thisLC.setAccountId(idToLeadMap?.get(thisLead?.Id)?.ConvertedAccountId);
        thisLC.setContactId(idToLeadMap?.get(thisLead?.Id)?.ConvertedContactId);
        thisLC.setOwnerId(idToLeadMap?.get(thisLead?.Id)?.OwnerId);
        return thisLC;
    }

    /**
         * @description Collects the conversion errors and updates the Lead with  Conversion Error.
         * @param conversionErrorLeadList The list that will be store the Leads to update.
         * @return LeadConversionService
        */
    public LeadConversionService collectConversionErrors(List<Lead> conversionErrorLeadList) {
        System.debug('******Conversion'+JSON.serialize(conversionResultList));
        for (Database.LeadConvertResult result : conversionResultList){
            if (!result.isSuccess()){
                String errorMessage = this.joinErrors(result.getErrors(), ', ');

                System.debug(LoggingLevel.ERROR, errorMessage);

                // Adds the lead into a list to update their conversion status
                conversionErrorLeadList.add(
                        this.setLeadConversionError(
                                this.idToLeadMap.get(result.getLeadId()),
                                errorMessage
                        )
                );
                continue;
            }
            Lead thisLead = this.idToLeadMap.get(result.getLeadId());
            thisLead.RecordTypeId = this.mapOfQueriedLeadsById.get(result.getLeadId()).RecordTypeId;
            this.successfullyConvertedLeads.add(thisLead);
        }


        return this;
    }

    /**
     * Rollback the Leads changes.
     * @param conversionErrorLeadList The list of Leads that failed on the conversion process.
     */
    public void rollbackChanges(List<Lead> conversionErrorLeadList) {
        List<Database.SaveResult> updateResults = leadDMLHelper.updateObjects(conversionErrorLeadList, false);
        // Log rollback errors
        for (Database.SaveResult result : updateResults){
            if (!result.isSuccess()){
                String errorMessage = this.joinErrors(result.getErrors(), ', ');
                System.debug(LoggingLevel.ERROR, errorMessage);
            }
        }
    }

    public List<Lead> getConvertedLead (){
        return this.successfullyConvertedLeads;
    }

    /**
     * Receives a list of Database.Errors and join them into one string
     * @param errorList :
     * @param separator :
     * @return String
     */
    private String joinErrors(List<Database.Error> errorList, String separator){
        String returnString = '';
        for (Database.Error err : errorList) returnString += (String.isBlank(returnString) ? '' : separator)+'Error in fields: '+String.join(err.fields, '|')+'/ Error message: '+err.getMessage();
        return returnString;
    }

    /**
     * Adds the error message into the lead Object.
     * @param lead :
     * @param errorMessage :
     * @return {Lead}
     */
    private Lead setLeadConversionError(Lead lead, String errorMessage){
        return new Lead(
                Id = lead.Id,
                ConvertedAccountId = null,
                ConvertedContactId = null,
                Conversion_Error_Message_tal__c = errorMessage
        );
    }

    public inherited sharing class LeadSelector implements ISelector{
        public List<Lead> getLeadsByIds (Set<Id> ids){
            return [SELECT Id,
                    RecordTypeId
                    FROM Lead
                    WHERE Id IN : ids];
        }
    }

    public inherited sharing class LeadDmlHelper implements IDMLHelper{
        public List<Database.LeadConvertResult> convertLead(List<Database.LeadConvert> toLeadConvertList, Boolean allOrNothing){
            List<Database.LeadConvertResult> conversionResultList = Database.convertLead(
                    toLeadConvertList, allOrNothing
            );
            return conversionResultList;
        }

        public Database.SaveResult[] updateObjects(List<Lead> leadList, Boolean allOrNothing) {
            return Database.update(leadList, allOrNothing);
        }


    }

    public static Map<String,Schema.RecordTypeInfo> getRecordTypeByDeveloperNameMap (String sobjectType)
    {
        SObjectType objToken = SchemaUtils.getGlobalDescribe().get(sobjectType);
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByDeveloperName = objDef.getRecordTypeInfosByDeveloperName();
        return rtMapByDeveloperName;
    }

    public static String getRecordTypeId (String sobjectType, String recordTypeName)
    {
        Map<String,Schema.RecordTypeInfo> rtMapByName = getRecordTypeByDeveloperNameMap(sobjectType);
        Schema.RecordTypeInfo rtByDeveloperName =  rtMapByName.get(recordTypeName);
        return rtByDeveloperName.getRecordTypeId();
    }

    public interface IService{
        IService setIdToLeadMap(Map<Id, Lead> idToLeadMap);
        IService processIncomingLeads ();
        IService doConversion ();
        IService collectConversionErrors(List<Lead> leadsWithError);
        void rollbackChanges(List<Lead> leadsWithError);
        List<Lead> getConvertedLead();
    }
    public interface ISelector{
        List<Lead> getLeadsByIds (Set<Id> ids);
    }
    public interface IDMLHelper {
        List<Database.LeadConvertResult> convertLead(List<Database.LeadConvert> toLeadConvertList, Boolean allOrNothing);
        Database.SaveResult[] updateObjects(List<Lead> leadList, Boolean allOrNothing);
    }
}