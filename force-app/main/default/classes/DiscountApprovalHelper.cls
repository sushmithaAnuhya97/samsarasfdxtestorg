/**********************************************************************
Name: DiscountApprovalHelper
=======================================================================
Purpose: This class will contain methods that handles the discount approval logic                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2024-May-29        INITIAL DEVELOPMENT FOR GTMS-20146, initial logic base other tickets and moved from GS_SBQQQuoteService
***********************************************************************/ 
public class DiscountApprovalHelper {
    private static Map<String, Discount_Approval_Attribute__mdt> fieldValueMapMDT = new Map<String, Discount_Approval_Attribute__mdt>();
    private static Map<String, String> mcsMatrixMap = new Map<String, String>();
    private static Map<String, Quote_Approval_Attribute__c> mapQAAttr = new Map<String, Quote_Approval_Attribute__c>(); 
    private static List<SBQQ__Quote__c> myQuotes = new List<SBQQ__Quote__c>();
    private static SBQQ__Quote__c forUpdate = new SBQQ__Quote__c();
    private static Map<String, Quote_Approval_Attribute__c> forUpsertQAA = new Map<String, Quote_Approval_Attribute__c>();
    private static Map<String, Object> currQuoteFieldValues = new Map<String, Object> ();
    private static Boolean approvalEligibleToggle=false;  
    @InvocableMethod(label='Validate Discount Approval Attributes')
    public static void validateApprovalAttributes(List<Id> quoteIds){
        string quoteId = quoteIds[0];
        initializeClassVariables(quoteId);
        // checking the value for toggle
        Automation_Settings__c discountApprovalEligibleToggle = Automation_Settings__c.getInstance('GTMS-26685');
        approvalEligibleToggle =  discountApprovalEligibleToggle != null && discountApprovalEligibleToggle.Disabled__c == false;
       
        //system.debug('RODRIGO quoteIds[0] ' + quoteIds[0]);
        
        processApprovalAttributes(quoteId);
        
        // check quote approval attribute against mdt
        //system.debug('qaa forUpsertQAA.size ' + forUpsertQAA.size());
        //system.debug('RODRIGO forUpdate ' + forUpdate);
        if (fieldValueMapMDT.size() != forUpsertQAA.size() ) {
            FOR (string mdt : fieldValueMapMDT.keyset()) {
                Quote_Approval_Attribute__c qaa = forUpsertQAA.get(mdt);
                if (qaa == null && myQuotes[0].ApprovalStatus__c == null) {
                    qaa = new Quote_Approval_Attribute__c();
                    qaa.Field_API_Name__c = mdt;
                    qaa.Field_Value__c = null;
                    qaa.Quote__c = quoteId;
                    forUpsertQAA.put(mdt, qaa);
                    //system.debug('RODRIGO qaa null mdt ' + mdt);
                }
                else {
                    if (qaa == null) {
                        Quote_Approval_Attribute__c qaaMap = mapQAAttr.get(mdt);
                        //Fix added for not null check GTMS-24814
                        if (qaaMap != null && String.isNotBlank(qaaMap.Field_Value__c)) {
                            //system.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ' + mdt);
                            Discount_Approval_Attribute__mdt mdtDetail = fieldValueMapMDT.get(mdt);
                            //system.debug('RODRIGO qaa mdt ' + mdt);
                            //system.debug('RODRIGO qaa qaaMap ' + qaaMap);
                            validateFieldValues(quoteId, mdtDetail, mdt, null);
                        }
                    }
                }
            }
        }
        //system.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ');
        //system.debug('RODRIGO qaa forUpsertQAA.size after ' + forUpsertQAA.size());
        if (forUpsertQAA.size()>0)
            upsert forUpsertQAA.values();
        //system.debug('RODRIGO forUpdate ' + forUpdate);
        
        if (myQuotes[0].Smart_Approve_Fields_Indicator__c != forUpdate.Smart_Approve_Fields_Indicator__c && String.isNotBlank(myQuotes[0].ApprovalStatus__c)) {
            SBQQ.TriggerControl.disable();
            TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
            update forUpdate;
            SBQQ.TriggerControl.enable();
        }
       
    }
    
    // this method contains the logic to process approval related logic
    private static void processApprovalAttributes(string quoteId) {
        currQuoteFieldValues = myQuotes[0].getPopulatedFieldsAsMap();
        forUpdate.Id = quoteId;
        forUpdate.Smart_Approve_Fields_Indicator__c = myQuotes[0].Smart_Approve_Fields_Indicator__c;
        Boolean isForApproval = false;
        for(String fieldName: currQuoteFieldValues.keySet()) {
            isForApproval = false;
            string fieldValue = string.valueof(currQuoteFieldValues.get(fieldName));
            Discount_Approval_Attribute__mdt mdtDetail = fieldValueMapMDT.get(fieldName);
            if (mdtDetail != null) {
               
                validateFieldValues(quoteId, mdtDetail, fieldName, fieldValue);
                
            } 
            
        }
    }
    
    // this method will check the values against existing approval attributes
    private static void validateFieldValues(string quoteId, Discount_Approval_Attribute__mdt mdtDetail, string fieldName, string fieldValue) {
        Quote_Approval_Attribute__c qaa = new Quote_Approval_Attribute__c();
        Boolean isForApproval = false;
        Quote_Approval_Attribute__c qaaValue = mapQAAttr.get(fieldName);
        if(qaaValue != null) {
            qaa.Id = qaaValue.Id;
            if(mdtDetail.Logic_Operator__c == 'Matrix') {
                // perform matrix logic check
                if (qaaValue.Field_Value__c != string.valueof(currQuoteFieldValues.get(fieldName))) {
                    string noApproval = mcsMatrixMap.get(qaaValue.Field_Value__c);
                    if(noApproval != null && !noApproval.containsIgnoreCase(string.valueof(currQuoteFieldValues.get(fieldName)))) {
                        isForApproval = true;
                    }
                }
            }
            if(mdtDetail.Logic_Operator__c == '<') {
                 //check if the eligible set in metadata satisfies the condition -GTMS-26685
                if(approvalEligibleToggle && mdtDetail.isEligibleSet__c &&(String.isNotBlank(qaaValue.Field_Value__c) && Double.valueof(currQuoteFieldValues.get(fieldName)) > Double.valueof(qaaValue.Field_Value__c)) || 
                    (fieldValue==null && Double.valueof(qaaValue.Field_Value__c)>0)) {
                        isForApproval = true;
                   }
               
                // check if current field value is less than previous value
                if(!approvalEligibleToggle||(approvalEligibleToggle && !mdtDetail.isEligibleSet__c)) { 
                   if((String.isNotBlank(qaaValue.Field_Value__c) && Double.valueof(currQuoteFieldValues.get(fieldName)) < Double.valueof(qaaValue.Field_Value__c)) || 
                    (fieldValue==null && Double.valueof(qaaValue.Field_Value__c)>0)) {
                       isForApproval = true;
                   }
                
            }
            }
            if(mdtDetail.Logic_Operator__c == '%') {
            //check if the eligible set in metadata satisfies the condition -GTMS-26685
                 if(approvalEligibleToggle && mdtDetail.isEligibleSet__c &&(qaaValue.Field_Value__c != string.valueof(currQuoteFieldValues.get(fieldName))) || 
                    (fieldValue==null && Double.valueof(qaaValue.Field_Value__c)>0))
                 {
                    Double oldValue = (String.isNotBlank(qaaValue.Field_Value__c)) ? Double.valueof(qaaValue.Field_Value__c) : 0 ;
                    if(currQuoteFieldValues.get(fieldName)!=null && currQuoteFieldValues.get(fieldName)!=0)
                    {
                        if(Double.valueof(currQuoteFieldValues.get(fieldName))<oldValue)
                        {
                         isForApproval = !isWithinThreePercent(Double.valueof(currQuoteFieldValues.get(fieldName)), oldValue, mdtDetail.Percent__c);
                         }
                    }
                     
                 }
                 
                // check if current field value change by percent value from old value
                if(!approvalEligibleToggle || (approvalEligibleToggle && !mdtDetail.isEligibleSet__c)) 
                {
                    if((qaaValue.Field_Value__c != string.valueof(currQuoteFieldValues.get(fieldName))) || 
                    (fieldValue==null && Double.valueof(qaaValue.Field_Value__c)>0)) {
                    Double oldValue = (String.isNotBlank(qaaValue.Field_Value__c)) ? Double.valueof(qaaValue.Field_Value__c) : 0 ;
                    isForApproval = !isWithinThreePercent(Double.valueof(currQuoteFieldValues.get(fieldName)), oldValue, mdtDetail.Percent__c);
                    }  
                }
                
            }
        }
        
        if (isForApproval) {
            DateTime myDateTime = DateTime.now();
            forUpdate.Smart_Approve_Fields_Indicator__c = (forUpdate.Smart_Approve_Fields_Indicator__c != null) ? forUpdate.Smart_Approve_Fields_Indicator__c + 5 : myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year() ; // GTMS-15659
        }
        system.debug('mdtDetail + ' + mdtDetail);
        if (mdtDetail != null) {
            qaa.Field_API_Name__c = fieldName;
            qaa.Field_Value__c = string.valueof(currQuoteFieldValues.get(fieldName));
            qaa.Quote__c = quoteId;
            forUpsertQAA.put(qaa.Field_API_Name__c, qaa);
        }
    }
    
    // this method initializes variables that will be used in the class to perform certain logic
    private static void initializeClassVariables(string inQuoteID) {
        // retrieves the metadata that contains that list of field(s) that is will be used in the approval logic
        //Map<String, Discount_Approval_Attribute__mdt > mcs = new Map<String, Discount_Approval_Attribute__mdt >([SELECT DeveloperName, Field_API_Name__c, Logic_Operator__c, Percent__c    
        //                                                                                                         FROM Discount_Approval_Attribute__mdt WHERE Active__c=true]);
        List<Discount_Approval_Attribute__mdt> mcs = Discount_Approval_Attribute__mdt.getAll().values();
        String strSOQLFields = null;
        //String quoteId = inQuoteID;
        // sets the field value map and fields that will used to query the quote field values
        FOR (Discount_Approval_Attribute__mdt mdt : mcs) {
            //Discount_Approval_Attribute__mdt mdtDetail = mcs.get(mdt);
            if (mdt.Active__c){
                strSOQLFields = (strSOQLFields != null) ? strSOQLFields + ', ' + mdt.Field_API_Name__c : mdt.Field_API_Name__c;
                fieldValueMapMDT.put(mdt.Field_API_Name__c, mdt);
            }
            
        }
        
        // retrieves the metadata that has the selected payment type matrix definition
        List<Selected_Payment_Type_Matrix__mdt> mcsMatrix = Selected_Payment_Type_Matrix__mdt.getAll().values();
        
        // load the matrix definition into a map
        FOR(Selected_Payment_Type_Matrix__mdt mcsRec : mcsMatrix) {
            mcsMatrixMap.put(mcsRec.MasterLabel, mcsRec.No_ReApproval_Selected_Payment_Type__c);
        }
        
        // format the SOQL statement to pull the Quote data
        String query = 'SELECT ApprovalStatus__c, Discount_Approval_Process__c, Smart_Approve_Fields_Indicator__c, ' + strSOQLFields + ' FROM SBQQ__Quote__c WHERE Id =:inQuoteID';
        
        // perform database query
        myQuotes = Database.query(query);
        
        // pull the quote approval attributes if any is already created
        List<Quote_Approval_Attribute__c> myQuoteAttrs = [SELECT  Field_API_Name__c, Field_Value__c 
                                                          FROM Quote_Approval_Attribute__c WHERE Quote__c =:  inQuoteID ];
        
        // load the quote approval attribute into a map
        for(Quote_Approval_Attribute__c attr: myQuoteAttrs) {
            mapQAAttr.put(attr.Field_API_Name__c, attr);
        }
        
    }
    
    // added for GTMS-15659 to calculate if the difference between 2 value is within 3%
    private static Boolean isWithinThreePercent(Decimal newValue, Decimal oldValue, Decimal percentValue) {
        double percentToCompareWith = (percentValue!=null) ? percentValue : 3;
        if (newValue==0 || newValue==null || oldValue==null || oldValue==0)
            return false;
        Decimal difference = Math.abs(newValue - oldValue);
        Decimal percentage = difference / oldValue * 100;
        Decimal percentageFinal= (percentage >= 0) ? percentage : percentage * -1;
        return percentageFinal <= percentToCompareWith;
    }
    
    
}