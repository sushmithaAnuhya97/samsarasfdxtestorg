public class PreviewApprovalController {
    private static Map<String, Discount_Approval_Attribute__mdt> fieldValueMapMDT = new Map<String, Discount_Approval_Attribute__mdt>();
    private static Map<String, String> mcsMatrixMap = new Map<String, String>();
    private static Map<String, Quote_Approval_Attribute__c> mapQAAttr = new Map<String, Quote_Approval_Attribute__c>(); 
    private static List<SBQQ__Quote__c> myQuotes = new List<SBQQ__Quote__c>();
    private static SBQQ__Quote__c forUpdate = new SBQQ__Quote__c();
    private static Map<String, Quote_Approval_Attribute__c> forUpsertQAA = new Map<String, Quote_Approval_Attribute__c>();
    private static Map<String, Object> currQuoteFieldValues = new Map<String, Object>();
    private static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    private static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    private static final String CLASS_NAME = 'PreviewApprovalController';

    @InvocableMethod(label='Validate Discount Approval Attributes')
    public static void validateApprovalAttributes(List<Id> quoteIds) {
        try {
            String quoteId = quoteIds[0];
            initializeClassVariables(quoteId);
            processApprovalAttributes(quoteId);

            if (fieldValueMapMDT.size() != forUpsertQAA.size()) {
                for (String mdt : fieldValueMapMDT.keySet()) {
                    Quote_Approval_Attribute__c qaa = forUpsertQAA.get(mdt);
                    if (qaa == null && myQuotes[0].ApprovalStatus__c == null) {
                        qaa = new Quote_Approval_Attribute__c();
                        qaa.Field_API_Name__c = mdt;
                        qaa.Field_Value__c = null;
                        qaa.Quote__c = quoteId;
                        forUpsertQAA.put(mdt, qaa);
                    } else if (qaa == null) {
                        Quote_Approval_Attribute__c qaaMap = mapQAAttr.get(mdt);
                        if (qaaMap != null && String.isNotBlank(qaaMap.Field_Value__c)) {
                            Discount_Approval_Attribute__mdt mdtDetail = fieldValueMapMDT.get(mdt);
                            validateFieldValues(quoteId, mdtDetail, mdt, null);
                        }
                    }
                }
            }

            if (!forUpsertQAA.isEmpty()) {
                upsert forUpsertQAA.values();
            }

            if (myQuotes[0].Smart_Approve_Fields_Indicator__c != forUpdate.Smart_Approve_Fields_Indicator__c && String.isNotBlank(myQuotes[0].ApprovalStatus__c)) {
                SBQQ.TriggerControl.disable();
                TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
                update forUpdate;
                SBQQ.TriggerControl.enable();
            }
        } catch (Exception e) {
            thisLogger.logError('PreviewApprovalController. Preview Error Message ::'+ e.getMessage() +' | StackTrace:: '+ e.getStackTraceString() +' | QuoteId ::', quoteIds[0]);
            throw new AuraHandledException('Error previewing approval: ' + e.getMessage());
		}
		finally{
			thisLogger.dispatch();
		}
    }

    private static void processApprovalAttributes(String quoteId) {
        currQuoteFieldValues = myQuotes[0].getPopulatedFieldsAsMap();
        forUpdate.Id = quoteId;
        forUpdate.Smart_Approve_Fields_Indicator__c = myQuotes[0].Smart_Approve_Fields_Indicator__c;

        for (String fieldName : currQuoteFieldValues.keySet()) {
            String fieldValue = String.valueOf(currQuoteFieldValues.get(fieldName));
            Discount_Approval_Attribute__mdt mdtDetail = fieldValueMapMDT.get(fieldName);
            if (mdtDetail != null) {
                validateFieldValues(quoteId, mdtDetail, fieldName, fieldValue);
            }
        }
    }

    private static void validateFieldValues(String quoteId, Discount_Approval_Attribute__mdt mdtDetail, String fieldName, String fieldValue) {
        Quote_Approval_Attribute__c qaa = new Quote_Approval_Attribute__c();
        Boolean isForApproval = false;
        Quote_Approval_Attribute__c qaaValue = mapQAAttr.get(fieldName);

        if (qaaValue != null) {
            qaa.Id = qaaValue.Id;
            if (mdtDetail.Logic_Operator__c == 'Matrix') {
                if (qaaValue.Field_Value__c != String.valueOf(currQuoteFieldValues.get(fieldName))) {
                    String noApproval = mcsMatrixMap.get(qaaValue.Field_Value__c);
                    if (noApproval != null && !noApproval.containsIgnoreCase(String.valueOf(currQuoteFieldValues.get(fieldName)))) {
                        isForApproval = true;
                    }
                }
            } else if (mdtDetail.Logic_Operator__c == '<') {
                if ((String.isNotBlank(qaaValue.Field_Value__c) && Double.valueOf(currQuoteFieldValues.get(fieldName)) < Double.valueOf(qaaValue.Field_Value__c)) || 
                    (fieldValue == null && Double.valueOf(qaaValue.Field_Value__c) > 0)) {
                    isForApproval = true;
                }
            } else if (mdtDetail.Logic_Operator__c == '%') {
                if ((qaaValue.Field_Value__c != String.valueOf(currQuoteFieldValues.get(fieldName))) || 
                    (fieldValue == null && Double.valueOf(qaaValue.Field_Value__c) > 0)) {
                    Double oldValue = (String.isNotBlank(qaaValue.Field_Value__c)) ? Double.valueOf(qaaValue.Field_Value__c) : 0;
                    isForApproval = !isWithinThreePercent(Double.valueOf(currQuoteFieldValues.get(fieldName)), oldValue, mdtDetail.Percent__c);
                }
            }
        }

        if (isForApproval) {
            DateTime myDateTime = DateTime.now();
            forUpdate.Smart_Approve_Fields_Indicator__c = (forUpdate.Smart_Approve_Fields_Indicator__c != null) ? forUpdate.Smart_Approve_Fields_Indicator__c + 5 : myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year();
        }

        if (mdtDetail != null) {
            qaa.Field_API_Name__c = fieldName;
            qaa.Field_Value__c = String.valueOf(currQuoteFieldValues.get(fieldName));
            qaa.Quote__c = quoteId;
            forUpsertQAA.put(qaa.Field_API_Name__c, qaa);
        }
    }

    private static void initializeClassVariables(String inQuoteID) {
        List<Discount_Approval_Attribute__mdt> mcs = Discount_Approval_Attribute__mdt.getAll().values();
        String strSOQLFields = null;

        for (Discount_Approval_Attribute__mdt mdt : mcs) {
            if (mdt.Active__c) {
                strSOQLFields = (strSOQLFields != null) ? strSOQLFields + ', ' + mdt.Field_API_Name__c : mdt.Field_API_Name__c;
                fieldValueMapMDT.put(mdt.Field_API_Name__c, mdt);
            }
        }

        List<Selected_Payment_Type_Matrix__mdt> mcsMatrix = Selected_Payment_Type_Matrix__mdt.getAll().values();
        for (Selected_Payment_Type_Matrix__mdt mcsRec : mcsMatrix) {
            mcsMatrixMap.put(mcsRec.MasterLabel, mcsRec.No_ReApproval_Selected_Payment_Type__c);
        }

        String query = 'SELECT ApprovalStatus__c, Discount_Approval_Process__c, Smart_Approve_Fields_Indicator__c, ' + strSOQLFields + ' FROM SBQQ__Quote__c WHERE Id =:inQuoteID';
        myQuotes = Database.query(query);

        List<Quote_Approval_Attribute__c> myQuoteAttrs = [SELECT Field_API_Name__c, Field_Value__c FROM Quote_Approval_Attribute__c WHERE Quote__c =: inQuoteID];
        for (Quote_Approval_Attribute__c attr : myQuoteAttrs) {
            mapQAAttr.put(attr.Field_API_Name__c, attr);
        }
    }

    private static Boolean isWithinThreePercent(Decimal newValue, Decimal oldValue, Decimal percentValue) {
        double percentToCompareWith = (percentValue != null) ? percentValue : 3;
        if (newValue == 0 || newValue == null || oldValue == null || oldValue == 0) {
            return false;
        }
        Decimal difference = Math.abs(newValue - oldValue);
        Decimal percentage = difference / oldValue * 100;
        return percentage <= percentToCompareWith;
    }

    static Set<Id> ruleChainIdSet = new Set<Id>();
    static Set<Id> ruleIds = new Set<Id>();
    static Set<Id> approverIdSet = new Set<Id>();
    static Set<Id> approverGroupIdSet = new Set<Id>();
    static List<SBAA__ApprovalCondition__c> allConditions = new List<SBAA__ApprovalCondition__c>();
    static Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();
    static Map<Id, SBAA__Approval__c> ruleToApprovalMap = new Map<Id, SBAA__Approval__c>();
    static Map<Id, sbaa__ApprovalChain__c> approvalRuleChainMap = new Map<Id, sbaa__ApprovalChain__c>();
    static Map<Id, sbaa__ApprovalRule__c> approvalRuleMap = new Map<Id, sbaa__ApprovalRule__c>();
    static Map<Id, sbaa__Approver__c> approverMap = new Map<Id, sbaa__Approver__c>();
    static Map<Id, GroupMember> groupMemberMap = new Map<Id, GroupMember>();
    static Map<Id, User> groupUserMap = new Map<Id, User>();
    static Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteId = new Map<Id, List<SBQQ__QuoteLine__c>>();
    static Map<Id, ApprovalHelper.RuleMetadata> ruleMetadataMap = new Map<Id, ApprovalHelper.RuleMetadata>();
    static Map<Id, List<SBAA__ApprovalCondition__c>> conditionsByRule = new Map<Id, List<SBAA__ApprovalCondition__c>>();
    static Map<String, List<Approval_Log__c>> existingLogsMap = new Map<String, List<Approval_Log__c>>();
    static Map<String, Schema.SObjectField> quoteFieldMap = Schema.SObjectType.SBQQ__Quote__c.fields.getMap();
    static List<Preview_Approval_Fields__mdt> fieldData = new List<Preview_Approval_Fields__mdt>();

    public class ApprovalChainDetails {
        @AuraEnabled public String chainId { get; set; }
        @AuraEnabled public String chainName { get; set; }
        @AuraEnabled public List<ApprovalRuleDetails> approvalRuleDetailsList = new List<ApprovalRuleDetails>();
    }

    public class ApprovalRuleDetails {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String ruleId { get; set; }
        @AuraEnabled public String ruleName { get; set; }
        @AuraEnabled public String approverId { get; set; }
        @AuraEnabled public String approvalStep { get; set; }
        @AuraEnabled public List<ApproverDetails> approverDetailsList = new List<ApproverDetails>();
        @AuraEnabled public List<ApprovalFieldTrigger> triggerFields { get; set; }
        public ApprovalRuleDetails() {
            this.triggerFields = new List<ApprovalFieldTrigger>();
            this.approverDetailsList = new List<ApproverDetails>();
        }
    }

    public class ApproverDetails {
        @AuraEnabled public String approverUserId { get; set; }
        @AuraEnabled public String approverName { get; set; }
        @AuraEnabled public String SmallPhotoUrl { get; set; }
    }

    public class ApprovalFieldTrigger {
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldValue { get; set; }
        @AuraEnabled public String previousValue { get; set; }
        @AuraEnabled public String aggregateFunction { get; set; }
        @AuraEnabled public String filterCondition { get; set; }
        @AuraEnabled public Boolean isChanged { get; set; }
    }

    @AuraEnabled(cacheable=false)
    public static List<ApprovalChainDetails> previewApproval(Id quoteId) {
        try {
            List<SBAA__Approval__c> approvals = (Test.isRunningTest()) ? 
                [SELECT sbaa__ApprovalChain__c, sbaa__Rule__c, sbaa__AssignedGroupId__c,Quote__c, sbaa__AssignedTo__c, sbaa__Approver__c, sbaa__ApprovalStep__c 
                 FROM sbaa__Approval__c WHERE Quote__c =: quoteId] : 
                SBAA.ApprovalAPI.preview(quoteId, SBAA__Approval__c.Quote__c);
            Map<Id, List<sbaa__Approval__c>> approvalChainMap = new Map<Id, List<sbaa__Approval__c>>();

            for (SBAA__Approval__c approval : approvals) {
                List<sbaa__Approval__c> listApprovals = approvalChainMap.get(approval.sbaa__ApprovalChain__c);
                if (listApprovals == null) {
                    listApprovals = new List<sbaa__Approval__c>();
                    approvalChainMap.put(approval.sbaa__ApprovalChain__c, listApprovals);
                }
                ruleToApprovalMap.put(approval.sbaa__Rule__c, approval);
                listApprovals.add(approval);
                ruleChainIdSet.add(approval.sbaa__ApprovalChain__c);
                ruleIds.add(approval.sbaa__Rule__c);
                if (approval.sbaa__AssignedGroupId__c != null && approval.sbaa__AssignedTo__c == null) {
                    approverGroupIdSet.add(approval.sbaa__AssignedGroupId__c);
                } else {
                    approverIdSet.add(approval.sbaa__Approver__c);
                }
            }
            Set<Id> quoteIds = new Set<id> {quoteId};
            allConditions = ApprovalHelper.getApprovalConditions(ruleIds);
            quoteMap = ApprovalHelper.getQuoteRecords(allConditions, quoteIds);
            approvalRuleChainMap = new Map<Id, sbaa__ApprovalChain__c>([SELECT Id, Name FROM sbaa__ApprovalChain__c WHERE Id IN: ruleChainIdSet]);
            approvalRuleMap = new Map<Id, sbaa__ApprovalRule__c>([SELECT Id, sbaa__ApprovalStep__c, Name FROM sbaa__ApprovalRule__c WHERE Id IN: ruleIds ORDER BY sbaa__ApprovalChain__c]);
            approverMap = new Map<Id, sbaa__Approver__c>([SELECT Id, Name, sbaa__User__r.Photo_URL__c FROM sbaa__Approver__c WHERE Id IN: approverIdSet]);
            groupMemberMap = new Map<Id, GroupMember>([SELECT Id, GroupId, UserOrGroupId, UserOrGroup.Name, UserOrGroup.Photo_URL__c, Group.Name FROM GroupMember WHERE Group.Id IN: approverGroupIdSet ORDER BY Group.Id]);
            existingLogsMap = ApprovalHelper.getLatestApprovalLogs(quoteIds);
            fieldData = [select id, DeveloperName, MasterLabel,Visible_Fields__c, Text_to_show_on_Page__c from Preview_Approval_Fields__mdt ];  
            Map<Id, ApprovalRuleDetails> ruleMap = new Map<Id, ApprovalRuleDetails>();
            Set<Id> grpUserIdSet = new Set<Id>();
            for (GroupMember grpUser : groupMemberMap.values()) {
                grpUserIdSet.add(grpUser.UserOrGroupId);
            }
            groupUserMap = new Map<Id, User>([SELECT Id, Name, Photo_URL__c, SmallPhotoUrl FROM User WHERE Id IN: grpUserIdSet]);
            if(allConditions != null) {
                for(SBAA__ApprovalCondition__c condition : allConditions) {
                    if(!conditionsByRule.containsKey(condition.SBAA__ApprovalRule__c)) {
                        conditionsByRule.put(condition.SBAA__ApprovalRule__c, new List<SBAA__ApprovalCondition__c>());
                    }
                    conditionsByRule.get(condition.SBAA__ApprovalRule__c).add(condition);
                    if(!ruleMetadataMap.containsKey(condition.SBAA__ApprovalRule__c)) {
                        ruleMetadataMap.put(condition.SBAA__ApprovalRule__c, new ApprovalHelper.RuleMetadata());
                    }
                    ApprovalHelper.RuleMetadata metadata = ruleMetadataMap.get(condition.SBAA__ApprovalRule__c);
                    metadata.conditions.add(condition);
                    
                    if(condition.SBAA__TestedField__c != null) {
                        metadata.addQuoteField(condition.SBAA__TestedField__c);
                    }
                    if(condition.SBAA__TestedVariable__c != null) {
                        metadata.addQuoteLineField(
                            condition.SBAA__TestedVariable__r.sbaa__FilterField__c,
                            condition.SBAA__TestedVariable__r.sbaa__Operator__c,
                            condition.SBAA__TestedVariable__r.sbaa__FilterValue__c
                        );
                    }
                }
            }
            System.debug('ruleMetadataMap' + ruleMetadataMap);
            quoteLinesByQuoteId = ApprovalHelper.getQuoteLinesForAllQuotes(quoteIds, ruleMetadataMap.values());
            List<ApprovalChainDetails> chainDetailList = new List<ApprovalChainDetails>();
            for (Id listMapId : approvalChainMap.keySet()) {
                sbaa__ApprovalChain__c chainRec = approvalRuleChainMap.get(listMapId);
                List<ApprovalRuleDetails> ruleList = getApprovalRuleDetails(approvalChainMap.get(listMapId));
                ApprovalChainDetails chainDetail = new ApprovalChainDetails();
                chainDetail.chainId = listMapId;
                chainDetail.chainName = chainRec != null ? chainRec.Name : 'Unknown Chain';
                chainDetail.approvalRuleDetailsList = ruleList;
                chainDetailList.add(chainDetail);
            }

            return chainDetailList;
        } catch (Exception e) {
            thisLogger.logError('PreviewApprovalController. Preview Error Message ::'+ e.getMessage() +' | StackTrace:: '+ e.getStackTraceString() +' | QuoteId ::', quoteId);
			System.debug('Error in previewApproval: ' + e.getMessage());
			System.debug('Error Stack: ' + e.getStackTraceString());
			throw new AuraHandledException('Error previewing approval: ' + e.getMessage());
		}
		finally{
			thisLogger.dispatch();
		}
    }

    public static List<ApprovalRuleDetails> getApprovalRuleDetails(List<sbaa__Approval__c> approvals) {
        if(approvals == null || approvals.isEmpty()) return null;
        List<ApprovalRuleDetails> ruleList = new List<ApprovalRuleDetails>();
        Map<Id, ApprovalRuleDetails> ruleMap = new Map<Id, ApprovalRuleDetails>();
        Map<Id, sbaa__Approval__c> approvalMap = new Map<Id, sbaa__Approval__c>();

        for (SBAA__Approval__c approval : approvals) {
            ApprovalRuleDetails ruleRec = new ApprovalRuleDetails();
            ruleRec.id = approval.sbaa__Rule__c;
            ruleRec.ruleId = approval.sbaa__Rule__c;
            ruleRec.approverId = approval.sbaa__Approver__c;
            ruleMap.put(approval.sbaa__Rule__c, ruleRec);
            approvalMap.put(approval.sbaa__Rule__c, approval);
        }
        Map<String, String> fieldDataMap = new Map<String, String>();
        for(Preview_Approval_Fields__mdt paf : fieldData) {
            fieldDataMap.put(paf.Visible_Fields__c, paf.Text_to_show_on_Page__c);
        }
        System.debug('fieldDataMap' + fieldDataMap);
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm().replace('my.salesforce', 'file.force');
        
        for (Id ruleId : ruleMap.keySet()) {
            ApprovalRuleDetails ruleRec = ruleMap.get(ruleId);
            sbaa__ApprovalRule__c approvalRuleRec = approvalRuleMap.get(ruleRec.ruleId);
            sbaa__Approver__c approverRec = approverMap != null ? approverMap.get(ruleRec.approverId) : null;
            sbaa__Approval__c approvalRec = approvalMap != null ? approvalMap.get(ruleId) : null;
            ruleRec.ruleName = approvalRuleRec != null ? approvalRuleRec.Name : '';
            Decimal step = approvalRuleRec != null ? approvalRuleRec.sbaa__ApprovalStep__c : null;
            ruleRec.approvalStep = 'Approval Step ' + step;
            if (approvalRec != null && approvalRec.sbaa__AssignedGroupId__c != null && approvalRec.sbaa__AssignedTo__c == null) {
                for (GroupMember grpMember : groupMemberMap.values()) {
                    if (approvalRec.sbaa__AssignedGroupId__c == grpMember.GroupId) {
                        User usr = groupUserMap.get(grpMember.UserOrGroupId);
                        ApproverDetails apprDetails = new ApproverDetails();
                        apprDetails.approverUserId = grpMember.UserOrGroupId;
                        apprDetails.approverName = usr.Name;
                        apprDetails.SmallPhotoUrl = (usr.Photo_URL__c != null) ? usr.Photo_URL__c : (usr.SmallPhotoUrl != null) ? usr.SmallPhotoUrl : sfdcBaseURL + '/profilephoto/005/T';
                        ruleRec.approverDetailsList.add(apprDetails);
                    }
                }
            } else {
                ApproverDetails apprDetails = new ApproverDetails();
                apprDetails.approverUserId = approverRec != null ? approverRec.Id : '001000000000000';
                apprDetails.approverName = (approverRec != null) ? approverRec.Name : null;
                apprDetails.SmallPhotoUrl = (approverRec != null && approverRec.sbaa__User__c != null && approverRec.sbaa__User__r.Photo_URL__c != null) ? approverRec.sbaa__User__r.Photo_URL__c : sfdcBaseURL + '/profilephoto/005/T';
                ruleRec.approverDetailsList.add(apprDetails);
            }
            List<SBAA__ApprovalCondition__c> ruleConditions = conditionsByRule.get(ruleId);
            String keys = approvalRec != null ?  approvalRec.Quote__c + '-' + approvalRec.SBAA__Rule__c: 'test';
            ApprovalHelper.RuleMetadata ruleMetadata = ruleMetadataMap.get(ruleId);
            Approval_Log__c lastLog = existingLogsMap != null && !existingLogsMap.isEmpty() && existingLogsMap.containsKey(keys)  ? existingLogsMap.get(keys)[0] : null;
            Map<String, Object> previousValues = lastLog != null ? (Map<String, Object>) JSON.deserializeUntyped(lastLog.Approval_Field_Values__c): null;
            System.debug('previousValues: ' + previousValues);
            System.debug('lastLog: ' + lastLog);
            if(ruleConditions != null) {
                Boolean hasAnyChanges = false;
                List<ApprovalFieldTrigger> tempTriggerFields = new List<ApprovalFieldTrigger>();

                for(SBAA__ApprovalCondition__c condition : ruleConditions) {
                    Map<String, Object> currentValues = new Map<String, Object>();
                    if(approvalRec != null){
                        currentValues = ApprovalHelper.cleanFieldNames(ApprovalHelper.getCurrentValues(approvalRec, quoteMap, ruleMetadata.conditions ,quoteLinesByQuoteId.get(approvalRec.Quote__c)));
                    }
                    System.debug('condition.SBAA__TestedField__c' + condition.SBAA__TestedField__c);
                    if(condition.SBAA__TestedField__c != null) {
                        if(fieldDataMap != null && fieldDataMap.containsKey(condition.SBAA__TestedField__c)) {
                            String fieldName = condition.SBAA__TestedField__c.replace('SBQQ__', '').replace('__c', '');                               
                            Schema.SObjectField field = quoteFieldMap.get(fieldName);
                            String fieldLabel = (field != null) ? field.getDescribe().getLabel() : 
                                fieldName.replace('SBQQ__', '').replace('__c', '').replace('_', ' ');
                            
                            Map<String, Object> currentQuoteFields = currentValues != null ? (Map<String, Object>)currentValues.get('QuoteFields') : null;
                            Map<String, Object> previousQuoteFields = previousValues != null ? (Map<String, Object>)previousValues.get('QuoteFields'): null;
                            System.debug('last log'+ lastLog);
                            System.debug('currentQuoteFields: '+currentQuoteFields);
                            System.debug('previousQuoteFields: '+previousQuoteFields);
                            if(lastLog == null && String.isNotBlank(fieldName)){
                                ApprovalFieldTrigger triggerField = new ApprovalFieldTrigger();
                                Object currentValue = currentQuoteFields.get(fieldName);
                                triggerField.fieldValue = String.valueOf(currentValue);
                                if(fieldLabel == 'Blended Discount'){
                                    triggerField.fieldLabel = 'Blended Discount Changed';
                                }else{
                                    triggerField.fieldLabel = fieldDataMap.get(condition.SBAA__TestedField__c);
                                }
                                triggerField.fieldName = fieldName;
                                triggerField.isChanged = false;
                                tempTriggerFields.add(triggerField);
                            } else if (lastLog != null && currentQuoteFields != null && previousQuoteFields != null) {                           
                                if (String.isNotBlank(fieldName) && String.isNotBlank(fieldLabel)) {
                                    if (!ruleMetadata.quoteFields.contains(fieldName.replace('__c', ''))) continue;
                                        Object currentValue = currentQuoteFields.get(fieldName);
                                        Object previousValue = previousQuoteFields.get(fieldName);
                                        Boolean fieldChanged = ApprovalHelper.hasValueChanged(currentValue, previousValue);
                                        
                                    if(fieldChanged){
                                        hasAnyChanges = true;
                                        ApprovalFieldTrigger triggerField = new ApprovalFieldTrigger();
                                        triggerField.fieldValue = String.valueOf(currentValue);
                                        triggerField.previousValue = String.valueOf(previousValue);
                                        if(fieldLabel == 'Blended Discount'){
                                            triggerField.fieldLabel = 'Blended Discount Changed';
                                        }else{
                                            triggerField.fieldLabel = fieldDataMap.get(condition.SBAA__TestedField__c);
                                        }
                                        triggerField.fieldName = fieldName;
                                        triggerField.isChanged = true;
                                        tempTriggerFields.add(triggerField);
                                    }
                                }
                            }
                        }
                    }

                    Map<String, Object> currentLineFields = currentValues != null ? (Map<String, Object>)currentValues.get('QuoteLineFields') : null;
                    Map<String, Object> previousLineFields = previousValues != null ? (Map<String, Object>)previousValues.get('QuoteLineFields') : null;
                    
                    if (currentLineFields != null) {
                        for (String compositeKey : currentLineFields.keySet()) {
                            if (!ruleMetadata.quoteLineFields.contains(compositeKey)) continue;
                            
                            String fieldName = condition.SBAA__TestedVariable__r.sbaa__AggregateField__c;
                            String fieldLabel = condition.SBAA__TestedVariable__r.Name;
                            
                            if (String.isNotBlank(fieldName) && String.isNotBlank(fieldLabel)) {
                                if(lastLog == null) {
                                    ApprovalFieldTrigger triggerField = new ApprovalFieldTrigger();
                                    Object currentValue = currentLineFields.get(compositeKey);
                                    triggerField.fieldName = fieldName;
                                    if(compositeKey.startsWith('Product') || compositeKey.startsWith('isStandalone')){
                                        triggerField.fieldLabel = 'Product Quantity Changed';
                                    } else if(compositeKey.startsWith('LineItem')){
                                        triggerField.fieldLabel = 'Renewal Products Adjusted';
                                    } else if(compositeKey.startsWith('Approval')){
                                        triggerField.fieldLabel = 'Blended Discount Changed';
                                    } else{
                                        triggerField.fieldLabel = compositeKey;
                                    }
                                    triggerField.fieldValue = String.valueOf(currentValue);
                                    triggerField.isChanged = false;
                                    tempTriggerFields.add(triggerField);
                                }
                                else if(previousLineFields != null && lastLog != null && previousLineFields.containsKey(compositeKey) ){
                                    Object currentValue = currentLineFields.get(compositeKey);
                                    Object previousValue = previousLineFields.get(compositeKey);
                                    Boolean fieldChanged = ApprovalHelper.hasValueChanged(currentValue, previousValue);
                                    if(fieldChanged) {
                                        hasAnyChanges = true;
                                        ApprovalFieldTrigger triggerField = new ApprovalFieldTrigger();
                                        triggerField.fieldName = fieldName;
                                        if(compositeKey.startsWith('Product') || compositeKey.startsWith('isStandalone')){
                                            triggerField.fieldLabel = 'Product Quantity Changed';
                                        } else if(compositeKey.startsWith('LineItem')){
                                            triggerField.fieldLabel = 'Renewal Products Adjusted';
                                        } else if(compositeKey.startsWith('Approval')){
                                            triggerField.fieldLabel = 'Blended Discount Changed';
                                        } else{
                                            triggerField.fieldLabel = compositeKey;
                                        }
                                        triggerField.fieldValue = String.valueOf(currentValue);
                                        triggerField.previousValue = String.valueOf(previousValue);
                                        triggerField.isChanged = true;
                                        tempTriggerFields.add(triggerField);
                                    }
                                }
                            }
                        }
                    }
                }

                if (previousValues != null) {
                    if (hasAnyChanges) {
                        System.debug('temp trriggere field'+tempTriggerFields);
                        List<ApprovalFieldTrigger> changedFields = tempTriggerFields;
                        
                        ruleRec.triggerFields.addAll(changedFields);
                    } else {
                        ApprovalFieldTrigger noChangesTrigger = new ApprovalFieldTrigger();
                        noChangesTrigger.fieldLabel = 'No changes since recall';
                        ruleRec.triggerFields.add(noChangesTrigger);
                    }
                } else if (lastLog == null) {
                    ruleRec.triggerFields.addAll(tempTriggerFields);
                }
            }

            ruleList.add(ruleRec);
        }
        return ruleList;
    }
}