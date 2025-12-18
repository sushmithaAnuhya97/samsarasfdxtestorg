/**
 * @description Generates documentation for Salesforce Advanced Approvals Rules
 * This class queries approval rules and related objects to produce human-readable
 * documentation and provides methods to export the data to Excel.
 */
public class ApprovalRuleDocumentationGenerator {
    
    /**
     * @description Generate documentation for all active approval rules
     * @return String Formatted documentation text
     */
    public static String generateDocumentation() {
        return generateDocumentation(null);
    }
    
    /**
     * @description Generate documentation for specified approval rules
     * @param ruleIds List of approval rule Ids to document
     * @return String Formatted documentation text
     */
    public static String generateDocumentation(List<Id> ruleIds) {
        String documentation = 'APPROVAL RULES DOCUMENTATION\n';
        documentation += '===========================\n\n';
        
        // Get all rule documentation objects
        List<ApprovalRuleWrapper> wrappers = generateApprovalRuleWrappers(ruleIds);
        
        // Format each rule's documentation
        for (ApprovalRuleWrapper wrapper : wrappers) {
            documentation += wrapper.getCompleteDescription();
            documentation += '\n-------------------------------------------\n\n';
        }
        
        return documentation;
    }
    
    /**
     * @description Generate wrapper objects for all approval rules
     * @param ruleIds Optional list of rule IDs to retrieve (if null, gets all active rules)
     * @return List<ApprovalRuleWrapper> List of wrapper objects
     */
    private static List<ApprovalRuleWrapper> generateApprovalRuleWrappers(List<Id> ruleIds) {
        List<ApprovalRuleWrapper> wrappers = new List<ApprovalRuleWrapper>();
        
        // Query approval rules and related objects
        List<sbaa__ApprovalRule__c> rules;
        
        String baseQuery = 'SELECT Id, Name, sbaa__TargetObject__c, sbaa__Active__c, sbaa__ConditionsMet__c, ' +
                        'sbaa__AdvancedCondition__c, sbaa__ApprovalStep__c, ' +
                        'sbaa__ApprovalChain__c, sbaa__ApprovalChain__r.Name, ' +
                        'sbaa__Approver__c, sbaa__Approver__r.Name, sbaa__Approver__r.sbaa__GroupId__c, sbaa__Approver__r.sbaa__User__c, ' +
                        'sbaa__RequireExplicitApproval__c, sbaa__Parallel__c, ' +
                        'sbaa__EffectiveStartDate__c, sbaa__EffectiveEndDate__c, sbaa__EffectiveDateField__c, ' +
                        'sbaa__RequestTemplate__c, sbaa__RequestTemplate__r.Name, ' +
                        'sbaa__ApprovalTemplate__c, sbaa__ApprovalTemplate__r.Name, ' +
                        'sbaa__RejectionTemplate__c, sbaa__RejectionTemplate__r.Name, ' +
                        'sbaa__RecallTemplate__c, sbaa__RecallTemplate__r.Name, ' +
                        'sbaa__ApprovalRecipients__c, sbaa__RejectionRecipients__c, ' +
                        'sbaa__ApproverField__c, sbaa__OverrideField__c, ' +
                        'sbaa__SmartApprovalIgnoresConditionsMet__c, sbaa__ExcludedStatuses__c ' +
                        'FROM sbaa__ApprovalRule__c';
        
        if (ruleIds != null && !ruleIds.isEmpty()) {
            rules = Database.query(baseQuery + ' WHERE Id IN :ruleIds ORDER BY Name');
        } else {
            rules = Database.query(baseQuery + ' WHERE sbaa__Active__c = true ORDER BY Name');
        }
        
        // Query approval conditions for all the rules in one query
        Set<Id> allRuleIds = new Set<Id>();
        // Also collect all Group IDs for later querying group members
        Set<String> groupIds = new Set<String>();
        // Collect User IDs for individual user approvers
        Set<Id> userIds = new Set<Id>();
        Set<Id> variableIds = new Set<Id>();
        
        for (sbaa__ApprovalRule__c rule : rules) {
            allRuleIds.add(rule.Id);
            
            // Check if the approver has a group ID and collect it
            if (rule.sbaa__Approver__c != null) {
                if (rule.sbaa__Approver__r.sbaa__GroupId__c != null && 
                    rule.sbaa__Approver__r.sbaa__GroupId__c != '') {
                    groupIds.add(rule.sbaa__Approver__r.sbaa__GroupId__c);
                } else if (rule.sbaa__Approver__r.sbaa__User__c != null) {
                    // Collect user IDs for individual user approvers
                    userIds.add(rule.sbaa__Approver__r.sbaa__User__c);
                }
            }
        }
        
        // Query group members
        Map<Id, List<String>> groupMembersMap = new Map<Id, List<String>>();
        if (!groupIds.isEmpty()) {
            try {
                // Query group members for all groups
                List<GroupMember> groupMembers = [
                    SELECT Id, GroupId, UserOrGroupId 
                    FROM GroupMember 
                    WHERE GroupId IN :groupIds
                ];
                
                // Get all user IDs from group members
                for (GroupMember member : groupMembers) {
                    // Only include user IDs, not nested groups
                    if (String.valueOf(member.UserOrGroupId).startsWith('005')) {
                        userIds.add(member.UserOrGroupId);
                    }
                }
                
                // Build map of group ID to list of member names
                for (GroupMember member : groupMembers) {
                    if (String.valueOf(member.UserOrGroupId).startsWith('005')) { // It's a user
                        if (!groupMembersMap.containsKey(member.GroupId)) {
                            groupMembersMap.put(member.GroupId, new List<String>());
                        }
                        // We'll add the names after querying users below
                        groupMembersMap.get(member.GroupId).add(String.valueOf(member.UserOrGroupId));
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error querying group members: ' + e.getMessage());
            }
        }
        
        // Query user information for all users (both group members and individual approvers)
        Map<Id, User> usersMap = new Map<Id, User>();
        if (!userIds.isEmpty()) {
            try {
                List<User> users = [SELECT Id, Name, Username FROM User WHERE Id IN :userIds];
                usersMap = new Map<Id, User>(users);
                
                // Now update the group members map with actual user names
                for (Id groupId : groupMembersMap.keySet()) {
                    List<String> memberIds = groupMembersMap.get(groupId);
                    List<String> memberNames = new List<String>();
                    
                    for (String memberId : memberIds) {
                        Id userId = Id.valueOf(memberId);
                        if (usersMap.containsKey(userId)) {
                            memberNames.add(usersMap.get(userId).Name);
                        }
                    }
                    
                    groupMembersMap.put(groupId, memberNames);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error querying users: ' + e.getMessage());
            }
        }
        
        // Query conditions
        Map<Id, List<sbaa__ApprovalCondition__c>> conditionsByRule = new Map<Id, List<sbaa__ApprovalCondition__c>>();
        try {
            List<sbaa__ApprovalCondition__c> conditions = [
                SELECT Id, Name, sbaa__ApprovalRule__c, 
                       sbaa__TestedField__c, sbaa__TestedVariable__c, sbaa__TestedVariable__r.Name,
                       sbaa__Operator__c, 
                       sbaa__FilterType__c, sbaa__FilterField__c, sbaa__FilterValue__c, 
                       sbaa__FilterVariable__c, sbaa__FilterVariable__r.Name,
                       sbaa__Index__c, sbaa__EnableSmartApproval__c
                FROM sbaa__ApprovalCondition__c 
                WHERE sbaa__ApprovalRule__c IN :allRuleIds 
                ORDER BY sbaa__Index__c NULLS LAST, Name
            ];
            
            for (sbaa__ApprovalCondition__c condition : conditions) {
                if (!conditionsByRule.containsKey(condition.sbaa__ApprovalRule__c)) {
                    conditionsByRule.put(condition.sbaa__ApprovalRule__c, new List<sbaa__ApprovalCondition__c>());
                }
                conditionsByRule.get(condition.sbaa__ApprovalRule__c).add(condition);
                
                // Collect variable IDs for querying
                if (condition.sbaa__TestedVariable__c != null) {
                    variableIds.add(condition.sbaa__TestedVariable__c);
                }
                if (condition.sbaa__FilterVariable__c != null) {
                    variableIds.add(condition.sbaa__FilterVariable__c);
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error querying approval conditions: ' + e.getMessage());
        }
        
        // Query approval variables for detailed information
        Map<Id, sbaa__ApprovalVariable__c> variableDetailsMap = new Map<Id, sbaa__ApprovalVariable__c>();
        if (!variableIds.isEmpty()) {
            try {
                List<sbaa__ApprovalVariable__c> variables = [
                    SELECT Id, Name, sbaa__TargetObject__c, sbaa__AggregateField__c, 
                           sbaa__AggregateFunction__c, sbaa__FilterField__c, sbaa__FilterValue__c,
                           sbaa__Operator__c, sbaa__CombineWith__c, sbaa__Type__c,
                           sbaa__ListVariable__c, sbaa__NetVariable__c
                    FROM sbaa__ApprovalVariable__c
                    WHERE Id IN :variableIds
                ];
                
                variableDetailsMap = new Map<Id, sbaa__ApprovalVariable__c>(variables);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error querying approval variables: ' + e.getMessage());
            }
        }
        
        // Get tracked fields related to approval rules
        Map<Id, List<sbaa__TrackedField__c>> trackedFieldsByRule = getTrackedFieldsByRule(allRuleIds);
        
        // Create wrapper objects for each rule
        for (sbaa__ApprovalRule__c rule : rules) {
            ApprovalRuleWrapper wrapper = new ApprovalRuleWrapper();
            
            // Set basic rule information
            wrapper.ruleId = rule.Id;
            wrapper.ruleName = rule.Name;
            wrapper.targetObject = rule.sbaa__TargetObject__c;
            wrapper.status = rule.sbaa__Active__c ? 'Active' : 'Inactive';
            wrapper.approvalStep = rule.sbaa__ApprovalStep__c != null ? String.valueOf(rule.sbaa__ApprovalStep__c) : '';
            wrapper.conditionsMet = rule.sbaa__ConditionsMet__c;
            wrapper.advancedCondition = rule.sbaa__AdvancedCondition__c;
            
            // Set approver information
            if (rule.sbaa__Approver__c != null) {
                wrapper.approver = rule.sbaa__Approver__r.Name;
                
                // Determine if approver is a user or group
                if (rule.sbaa__Approver__r.sbaa__User__c != null) {
                    wrapper.approverType = 'User';
                    // Get the user's name for the members column instead of "N/A"
                    Id userId = rule.sbaa__Approver__r.sbaa__User__c;
                    if (usersMap.containsKey(userId)) {
                        wrapper.groupMembers = usersMap.get(userId).Name;
                    } else {
                        wrapper.groupMembers = 'User: ' + userId;
                    }
                } else if (rule.sbaa__Approver__r.sbaa__GroupId__c != null) {
                    wrapper.approverType = 'Group';
                    
                    // Get group members
                    String groupId = rule.sbaa__Approver__r.sbaa__GroupId__c;
                    if (groupMembersMap.containsKey(groupId)) {
                        List<String> memberNames = groupMembersMap.get(groupId);
                        wrapper.groupMembers = String.join(memberNames, '; ');
                    } else {
                        wrapper.groupMembers = 'No members found';
                    }
                } else {
                    wrapper.approverType = 'Unknown';
                    wrapper.groupMembers = 'N/A';
                }
            } else if (rule.sbaa__ApproverField__c != null) {
                wrapper.approver = 'Dynamic: ' + rule.sbaa__ApproverField__c;
                wrapper.approverType = 'Dynamic Field';
                wrapper.groupMembers = 'Dynamic (determined at runtime)';
            } else {
                wrapper.approver = 'None';
                wrapper.approverType = 'None';
                wrapper.groupMembers = 'N/A';
            }
            
            // Set chain information
            if (rule.sbaa__ApprovalChain__c != null) {
                wrapper.approvalChain = rule.sbaa__ApprovalChain__r.Name;
            }
            
            // Set approval options
            wrapper.requireExplicitApproval = rule.sbaa__RequireExplicitApproval__c ? 'Yes' : 'No';
            wrapper.parallelApprovals = rule.sbaa__Parallel__c ? 'Yes' : 'No';
            wrapper.smartApproval = rule.sbaa__SmartApprovalIgnoresConditionsMet__c ? 'Yes' : 'No';
            wrapper.excludedStatuses = rule.sbaa__ExcludedStatuses__c;
            
            // Set effective dates
            if (rule.sbaa__EffectiveStartDate__c != null) {
                wrapper.effectiveStartDate = rule.sbaa__EffectiveStartDate__c.format();
            }
            if (rule.sbaa__EffectiveEndDate__c != null) {
                wrapper.effectiveEndDate = rule.sbaa__EffectiveEndDate__c.format();
            }
            wrapper.effectiveDateField = rule.sbaa__EffectiveDateField__c;
            
            // Set email templates
            if (rule.sbaa__RequestTemplate__c != null) {
                wrapper.requestTemplate = rule.sbaa__RequestTemplate__r.Name;
            }
            if (rule.sbaa__ApprovalTemplate__c != null) {
                wrapper.approvalTemplate = rule.sbaa__ApprovalTemplate__r.Name;
            }
            if (rule.sbaa__RejectionTemplate__c != null) {
                wrapper.rejectionTemplate = rule.sbaa__RejectionTemplate__r.Name;
            }
            if (rule.sbaa__RecallTemplate__c != null) {
                wrapper.recallTemplate = rule.sbaa__RecallTemplate__r.Name;
            }
            
            // Set email recipients
            wrapper.approvalRecipients = rule.sbaa__ApprovalRecipients__c;
            wrapper.rejectionRecipients = rule.sbaa__RejectionRecipients__c;
            
            // Process conditions with expanded variable details
            List<sbaa__ApprovalCondition__c> ruleConditions = conditionsByRule.get(rule.Id);
            if (ruleConditions != null && !ruleConditions.isEmpty()) {
                wrapper.conditions = documentConditions(ruleConditions, variableDetailsMap);
            } else {
                wrapper.conditions = 'No conditions defined. This rule will always apply.';
            }
            
            // Process tracked fields
            List<sbaa__TrackedField__c> trackedFields = trackedFieldsByRule.get(rule.Id);
            if (trackedFields != null && !trackedFields.isEmpty()) {
                wrapper.trackedFields = documentTrackedFields(trackedFields);
            } else {
                wrapper.trackedFields = 'No tracked fields defined.';
            }
            
            wrappers.add(wrapper);
        }
        
        return wrappers;
    }
    
    /**
     * @description Retrieve tracked fields for approval rules
     * @param ruleIds Set of approval rule Ids
     * @return Map<Id, List<sbaa__TrackedField__c>> Map of rule Id to tracked fields
     */
    private static Map<Id, List<sbaa__TrackedField__c>> getTrackedFieldsByRule(Set<Id> ruleIds) {
        Map<Id, List<sbaa__TrackedField__c>> trackedFieldsByRule = new Map<Id, List<sbaa__TrackedField__c>>();
        
        // Build query for tracked fields
        try {
            List<sbaa__TrackedField__c> trackedFields = [
                SELECT Id, sbaa__TrackedField__c, sbaa__TrackedObject__c, 
                       sbaa__RecordField__c, sbaa__TrackingType__c, sbaa__ApprovalRule__c 
                FROM sbaa__TrackedField__c
                WHERE sbaa__ApprovalRule__c IN :ruleIds
            ];
            
            for (sbaa__TrackedField__c field : trackedFields) {
                if (!trackedFieldsByRule.containsKey(field.sbaa__ApprovalRule__c)) {
                    trackedFieldsByRule.put(field.sbaa__ApprovalRule__c, new List<sbaa__TrackedField__c>());
                }
                trackedFieldsByRule.get(field.sbaa__ApprovalRule__c).add(field);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error querying tracked fields: ' + e.getMessage());
        }
        
        return trackedFieldsByRule;
    }
    
    /**
     * @description Document conditions for an approval rule
     * @param conditions The approval conditions to document
     * @param variableDetailsMap Map of variable IDs to their detailed information
     * @return String Formatted documentation text for conditions
     */
    private static String documentConditions(List<sbaa__ApprovalCondition__c> conditions, 
                                         Map<Id, sbaa__ApprovalVariable__c> variableDetailsMap) {
        String conditionLogic = '';
        
        for (sbaa__ApprovalCondition__c condition : conditions) {
            // Add condition number - simple numbered format
            if (condition.sbaa__Index__c != null) {
                conditionLogic += String.valueOf((Integer)condition.sbaa__Index__c) + '. ';
            } else {
                // If no index, just use a bullet point
                conditionLogic += '• ';
            }
            
            // Add Smart Approval indicator
            if (condition.sbaa__EnableSmartApproval__c) {
                conditionLogic += '[Smart Approval] ';
            }
            
            // Determine what is being tested - field, variable, or expanded variable
            if (String.isNotBlank(condition.sbaa__TestedField__c)) {
                // Regular field test
                conditionLogic += condition.sbaa__TestedField__c + ' ';
            } else if (condition.sbaa__TestedVariable__c != null && 
                      variableDetailsMap.containsKey(condition.sbaa__TestedVariable__c)) {
                // Expand variable inline rather than just showing its name
                sbaa__ApprovalVariable__c var = variableDetailsMap.get(condition.sbaa__TestedVariable__c);
                
                // Format as per example: "Sum of QuoteLine.EffectiveQuantity where ProductCode equals ACC-RS232"
                if (var.sbaa__AggregateFunction__c != null && var.sbaa__AggregateField__c != null) {
                    conditionLogic += var.sbaa__AggregateFunction__c + ' of ';
                    
                    // Format the object and field names nicely
                    String objName = var.sbaa__TargetObject__c;
                    if (objName.endsWith('__c')) {
                        objName = objName.substringBeforeLast('__c');
                        if (objName.contains('__')) {
                            objName = objName.substringAfterLast('__');
                        }
                    }
                    
                    String fieldName = var.sbaa__AggregateField__c;
                    if (fieldName.endsWith('__c')) {
                        fieldName = fieldName.substringBeforeLast('__c');
                        if (fieldName.contains('__')) {
                            fieldName = fieldName.substringAfterLast('__');
                        }
                    }
                    
                    conditionLogic += objName + '.' + fieldName + ' ';
                    
                    // Add filter details if present
                    if (String.isNotBlank(var.sbaa__FilterField__c) && 
                        String.isNotBlank(var.sbaa__FilterValue__c) &&
                        String.isNotBlank(var.sbaa__Operator__c)) {
                        
                        String filterField = var.sbaa__FilterField__c;
                        if (filterField.endsWith('__c')) {
                            filterField = filterField.substringBeforeLast('__c');
                            if (filterField.contains('__')) {
                                filterField = filterField.substringAfterLast('__');
                            }
                        }
                        
                        conditionLogic += 'where ' + filterField + ' ' + 
                                         var.sbaa__Operator__c + ' ' + 
                                         var.sbaa__FilterValue__c + ' ';
                    }
                } else {
                    // Fallback if variable structure doesn't match expected format
                    conditionLogic += 'Variable: ' + condition.sbaa__TestedVariable__r.Name + ' ';
                }
            } else if (condition.sbaa__TestedVariable__c != null) {
                // Variable without details available
                conditionLogic += 'Variable: ' + condition.sbaa__TestedVariable__r.Name + ' ';
            }
            
            // Add operator
            conditionLogic += condition.sbaa__Operator__c + ' ';
            
            // Determine comparison type and value
            if (condition.sbaa__FilterType__c == 'Value') {
                conditionLogic += '"' + condition.sbaa__FilterValue__c + '"';
            } else if (condition.sbaa__FilterType__c == 'Field') {
                conditionLogic += 'Field: ' + condition.sbaa__FilterField__c;
            } else if (condition.sbaa__FilterType__c == 'Variable') {
                // Handle comparison to another variable
                if (condition.sbaa__FilterVariable__c != null && 
                    variableDetailsMap.containsKey(condition.sbaa__FilterVariable__c)) {
                    
                    sbaa__ApprovalVariable__c var = variableDetailsMap.get(condition.sbaa__FilterVariable__c);
                    
                    // Use same expansion logic as for tested variables
                    if (var.sbaa__AggregateFunction__c != null && var.sbaa__AggregateField__c != null) {
                        conditionLogic += var.sbaa__AggregateFunction__c + ' of ';
                        
                        String objName = var.sbaa__TargetObject__c;
                        if (objName.endsWith('__c')) {
                            objName = objName.substringBeforeLast('__c');
                            if (objName.contains('__')) {
                                objName = objName.substringAfterLast('__');
                            }
                        }
                        
                        String fieldName = var.sbaa__AggregateField__c;
                        if (fieldName.endsWith('__c')) {
                            fieldName = fieldName.substringBeforeLast('__c');
                            if (fieldName.contains('__')) {
                                fieldName = fieldName.substringAfterLast('__');
                            }
                        }
                        
                        conditionLogic += objName + '.' + fieldName + ' ';
                        
                        if (String.isNotBlank(var.sbaa__FilterField__c) && 
                            String.isNotBlank(var.sbaa__FilterValue__c) &&
                            String.isNotBlank(var.sbaa__Operator__c)) {
                            
                            String filterField = var.sbaa__FilterField__c;
                            if (filterField.endsWith('__c')) {
                                filterField = filterField.substringBeforeLast('__c');
                                if (filterField.contains('__')) {
                                    filterField = filterField.substringAfterLast('__');
                                }
                            }
                            
                            conditionLogic += 'where ' + filterField + ' ' + 
                                             var.sbaa__Operator__c + ' ' + 
                                             var.sbaa__FilterValue__c;
                        }
                    } else {
                        conditionLogic += 'Variable: ' + condition.sbaa__FilterVariable__r.Name;
                    }
                } else {
                    conditionLogic += 'Variable: ' + (condition.sbaa__FilterVariable__r != null ? 
                                                 condition.sbaa__FilterVariable__r.Name : 
                                                 'Unknown Variable');
                }
            }
            
            conditionLogic += '\n';
        }
        
        return conditionLogic;
    }
    
    /**
     * @description Document tracked fields for an approval rule
     * @param trackedFields The tracked fields to document
     * @return String Formatted documentation text for tracked fields
     */
    private static String documentTrackedFields(List<sbaa__TrackedField__c> trackedFields) {
        String fieldDocs = '';
        
        for (sbaa__TrackedField__c field : trackedFields) {
            fieldDocs += '- ' + field.sbaa__TrackedObject__c + '.' + field.sbaa__TrackedField__c;
            fieldDocs += ' (Tracking Type: ' + field.sbaa__TrackingType__c + ')\n';
        }
        
        return fieldDocs;
    }
    
    /**
     * @description Format conditions for Excel display
     * @param conditionsText The conditions text to format
     * @return String Formatted text for Excel
     */
    private static String formatConditionsForExcel(String conditionsText) {
        if(conditionsText == null) return '';
        
        // Split by lines and format each condition
        List<String> lines = conditionsText.split('\n');
        List<String> formattedLines = new List<String>();
        
        for(String line : lines) {
            if(String.isBlank(line)) continue;
            
            // Trim the line but preserve the leading number/text
            String cleanLine = line.trim();
            if(String.isNotBlank(cleanLine)) {
                formattedLines.add(cleanLine);
            }
        }
        
        return String.join(formattedLines, '\n');
    }
    
    /**
     * @description Format tracked fields for Excel display
     * @param trackedFieldsText The tracked fields text to format
     * @return String Formatted text for Excel
     */
    private static String formatTrackedFieldsForExcel(String trackedFieldsText) {
        if(trackedFieldsText == null) return '';
        
        // Split by lines and format each tracked field
        List<String> lines = trackedFieldsText.split('\n');
        List<String> formattedLines = new List<String>();
        
        for(String line : lines) {
            if(String.isBlank(line)) continue;
            
            // Remove the leading dash for cleaner Excel display
            String cleanLine = line.trim();
            if(cleanLine.startsWith('- ')) {
                cleanLine = cleanLine.substring(2);
            }
            
            if(String.isNotBlank(cleanLine)) {
                formattedLines.add(cleanLine);
            }
        }
        
        return String.join(formattedLines, '\n');
    }
    
    /**
     * @description Prepare data for Excel export
     * @return List<Map<String, String>> List of data rows ready for Excel export
     */
    public static List<Map<String, String>> prepareExcelExport() {
        List<ApprovalRuleWrapper> wrappers = generateApprovalRuleWrappers(null);
        List<Map<String, String>> exportRows = new List<Map<String, String>>();
        
        for(ApprovalRuleWrapper wrapper : wrappers) {
            Map<String, String> row = new Map<String, String>{
                'Rule ID' => wrapper.ruleId,
                'Rule Name' => wrapper.ruleName,
                'Target Object' => wrapper.targetObject,
                'Status' => wrapper.status,
                'Approval Step' => wrapper.approvalStep,
                'Conditions Met' => wrapper.conditionsMet,
                'Advanced Condition' => wrapper.advancedCondition,
                'Approver' => wrapper.approver,
                'Approver Type' => wrapper.approverType,
                'Group Members' => wrapper.groupMembers,
                'Approval Chain' => wrapper.approvalChain,
                'Require Explicit Approval' => wrapper.requireExplicitApproval,
                'Parallel Approvals' => wrapper.parallelApprovals,
                'Smart Approval' => wrapper.smartApproval,
                'Excluded Statuses' => wrapper.excludedStatuses,
                'Effective Date Field' => wrapper.effectiveDateField,
                'Effective Start Date' => wrapper.effectiveStartDate,
                'Effective End Date' => wrapper.effectiveEndDate,
                'Request Template' => wrapper.requestTemplate,
                'Approval Template' => wrapper.approvalTemplate,
                'Rejection Template' => wrapper.rejectionTemplate,
                'Recall Template' => wrapper.recallTemplate,
                'Approval Recipients' => wrapper.approvalRecipients,
                'Rejection Recipients' => wrapper.rejectionRecipients,
                'Conditions' => formatConditionsForExcel(wrapper.conditions),
                'Tracked Fields' => formatTrackedFieldsForExcel(wrapper.trackedFields)
            };
            exportRows.add(row);
        }
        
        return exportRows;
    }
    
    /**
     * @description Export approval rules documentation to an Excel-compatible CSV file
     * @return Id ContentDocumentId of the created file
     */
    public static Id exportToExcelFile() {
        try {
            // Generate the data
            List<Map<String, String>> exportData = prepareExcelExport();
            
            // Create Excel-compatible CSV content
            String csvContent = createExcelContent(exportData);
            
            // Create a ContentVersion record (Salesforce File)
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Approval Rule Documentation ' + DateTime.now().format('yyyy-MM-dd');
            cv.PathOnClient = 'ApprovalRuleDocumentation.csv';
            cv.VersionData = Blob.valueOf('\uFEFF' + csvContent); // Add BOM for UTF-8
            cv.IsMajorVersion = true;
            
            insert cv;
            
            // Query for the ContentDocumentId to return
            ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
            return insertedCv.ContentDocumentId;
        } catch(Exception e) {
            System.debug('Error exporting approval rule documentation: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Export approval rules documentation to an HTML file
     * @return Id ContentDocumentId of the created file
     */
    public static Id exportToHTMLFile() {
        try {
            // Generate the data
            List<Map<String, String>> exportData = prepareExcelExport();
            
            // Define column headers in desired order
            List<String> orderedHeaders = new List<String>{
                'Rule ID',
                'Rule Name',
                'Target Object',
                'Status',
                'Approval Step',
                'Conditions Met',
                'Advanced Condition',
                'Approver',
                'Approver Type',
                'Group Members',
                'Approval Chain',
                'Require Explicit Approval',
                'Parallel Approvals',
                'Smart Approval',
                'Excluded Statuses',
                'Effective Date Field',
                'Effective Start Date',
                'Effective End Date',
                'Request Template',
                'Approval Template',
                'Rejection Template',
                'Recall Template',
                'Approval Recipients',
                'Rejection Recipients',
                'Conditions',
                'Tracked Fields'
            };
            
            // Use StringBuilder for better performance with large strings
            List<String> htmlParts = new List<String>();
            
            // HTML opening tags
            htmlParts.add('<html><body>');
            htmlParts.add('<style>');
            htmlParts.add('table { border-collapse: collapse; width: 100%; }');
            htmlParts.add('th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
            htmlParts.add('th { background-color: #f2f2f2; }');
            htmlParts.add('tr:nth-child(even) { background-color: #f9f9f9; }');
            htmlParts.add('</style>');
            htmlParts.add('<h1>Approval Rule Documentation</h1>');
            htmlParts.add('<table>');
            
            // Table header row
            htmlParts.add('<tr>');
            for(String header : orderedHeaders) {
                htmlParts.add('<th>' + escapeHtml(header) + '</th>');
            }
            htmlParts.add('</tr>');
            
            // Table data rows
            for(Map<String, String> row : exportData) {
                htmlParts.add('<tr>');
                for(String header : orderedHeaders) {
                    String value = row.get(header) != null ? row.get(header) : '';
                    
                    // Special handling for multiline fields to preserve formatting
                    if(header == 'Conditions' || header == 'Tracked Fields') {
                        // Replace newlines with HTML line breaks
                        value = value.replace('\n', '<br/>');
                    }
                    
                    htmlParts.add('<td>' + escapeHtml(value) + '</td>');
                }
                htmlParts.add('</tr>');
            }
            
            // Close table and HTML
            htmlParts.add('</table>');
            htmlParts.add('</body></html>');
            
            // Join all HTML parts
            String htmlContent = String.join(htmlParts, '');
            
            // Create a ContentVersion record
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Approval Rule Documentation ' + DateTime.now().format('yyyy-MM-dd');
            cv.PathOnClient = 'ApprovalRuleDocumentation.html';
            cv.VersionData = Blob.valueOf(htmlContent);
            cv.IsMajorVersion = true;
            
            insert cv;
            
            // Query for the ContentDocumentId to return
            ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
            return insertedCv.ContentDocumentId;
        } catch(Exception e) {
            System.debug('Error exporting approval rule documentation to HTML: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Create content for Excel export using CSV format
     * @param exportData The data to export
     * @return String CSV formatted content
     */
    private static String createExcelContent(List<Map<String, String>> exportData) {
        if(exportData.isEmpty()) return '';
        
        // Specify the exact column order we want - remove Variable Details
        List<String> orderedHeaders = new List<String>{
            'Rule ID',
            'Rule Name',
            'Target Object',
            'Status',
            'Approval Step',
            'Conditions Met',
            'Advanced Condition',
            'Approver',
            'Approver Type',
            'Group Members',
            'Approval Chain',
            'Require Explicit Approval',
            'Parallel Approvals',
            'Smart Approval',
            'Excluded Statuses',
            'Effective Date Field',
            'Effective Start Date',
            'Effective End Date',
            'Request Template',
            'Approval Template',
            'Rejection Template',
            'Recall Template',
            'Approval Recipients',
            'Rejection Recipients',
            'Conditions',
            'Tracked Fields'
        };
        
        // Start with headers in our specified order
        String csvContent = String.join(orderedHeaders, ',') + '\n';
        
        // Add each row in the same order
        for(Map<String, String> row : exportData) {
            List<String> rowValues = new List<String>();
            for(String header : orderedHeaders) {
                // Get the value, defaulting to empty string
                String value = row.get(header) != null ? row.get(header) : '';
                
                // Properly escape value for CSV format
                // Replace quotes with double quotes and wrap in quotes to preserve newlines
                value = '"' + value.replace('"', '""') + '"';
                
                // Add the escaped value
                rowValues.add(value);
            }
            csvContent += String.join(rowValues, ',') + '\n';
        }
        
        return csvContent;
    }
    
    /**
     * @description Helper method to escape HTML special characters
     * @param input The input string to escape
     * @return String The escaped string
     */
    private static String escapeHtml(String input) {
        if(input == null) return '';
        
        // Don't escape the <br/> tags we intentionally added
        String escaped = input;
        if(input.contains('<br/>')) {
            // Handle the case where we've already added HTML break tags
            List<String> parts = input.split('<br/>');
            for(Integer i = 0; i < parts.size(); i++) {
                parts[i] = parts[i]
                    .replace('&', '&amp;')
                    .replace('<', '&lt;')
                    .replace('>', '&gt;')
                    .replace('"', '&quot;')
                    .replace('\'', '&#39;');
            }
            escaped = String.join(parts, '<br/>');
        } else {
            // Normal HTML escaping
            escaped = input
                .replace('&', '&amp;')
                .replace('<', '&lt;')
                .replace('>', '&gt;')
                .replace('"', '&quot;')
                .replace('\'', '&#39;');
        }
        
        return escaped;
    }
    
    /**
     * @description Format any multi-line text for Excel display
     * @param text The text to format
     * @return String Formatted text for Excel
     */
    private static String formatForExcel(String text) {
        if(text == null) return '';
        
        // Split by lines and format each line
        List<String> lines = text.split('\n');
        List<String> formattedLines = new List<String>();
        
        for(String line : lines) {
            if(String.isBlank(line)) continue;
            
            // Trim the line but preserve indentation
            String cleanLine = line.trim();
            if(String.isNotBlank(cleanLine)) {
                formattedLines.add(cleanLine);
            }
        }
        
        return String.join(formattedLines, '\n');
    }
    
    /**
     * @description Wrapper class to hold approval rule documentation data
     */
    public class ApprovalRuleWrapper {
        public Id ruleId { get; set; }
        public String ruleName { get; set; }
        public String targetObject { get; set; }
        public String status { get; set; }
        public String approvalStep { get; set; }
        public String conditionsMet { get; set; }
        public String advancedCondition { get; set; }
        public String approver { get; set; }
        public String approverType { get; set; }
        public String groupMembers { get; set; }
        public String approvalChain { get; set; }
        public String requireExplicitApproval { get; set; }
        public String parallelApprovals { get; set; }
        public String smartApproval { get; set; }
        public String excludedStatuses { get; set; }
        public String effectiveDateField { get; set; }
        public String effectiveStartDate { get; set; }
        public String effectiveEndDate { get; set; }
        public String requestTemplate { get; set; }
        public String approvalTemplate { get; set; }
        public String rejectionTemplate { get; set; }
        public String recallTemplate { get; set; }
        public String approvalRecipients { get; set; }
        public String rejectionRecipients { get; set; }
        public String conditions { get; set; }
        public String trackedFields { get; set; }
        
        /**
         * @description Generate a complete human-readable description of the rule
         * @return String Formatted description
         */
        public String getCompleteDescription() {
            String description = '';
            
            // Rule header
            description += 'APPROVAL RULE: ' + ruleName + '\n';
            description += '==================================\n';
            description += 'Status: ' + status + '\n';
            description += 'Target Object: ' + targetObject + '\n';
            
            if (String.isNotBlank(approvalStep)) {
                description += 'Approval Step: ' + approvalStep + '\n';
            }
            
            description += 'Conditions Met: ' + conditionsMet + '\n';
            
            // Add advanced condition if present
            if (String.isNotBlank(advancedCondition)) {
                description += 'Advanced Condition: ' + advancedCondition + '\n';
            }
            
            // Add Smart Approval setting
            description += 'Reevaluate Smart Approvals Individually: ' + smartApproval + '\n';
            
            // Add excluded statuses if present
            if (String.isNotBlank(excludedStatuses)) {
                description += 'Excluded Statuses: ' + excludedStatuses + '\n';
            }
            
            // Add approver information
            if (String.isNotBlank(approver)) {
                description += 'Approver: ' + approver + '\n';
                description += 'Approver Type: ' + approverType + '\n';
                
                // Add group members if applicable
                if (approverType == 'Group' && String.isNotBlank(groupMembers)) {
                    description += 'Group Members: ' + groupMembers + '\n';
                }
            }
            
            // Add approval chain information
            if (String.isNotBlank(approvalChain)) {
                description += 'Approval Chain: ' + approvalChain + '\n';
            }
            
            // Approval options
            description += 'Require Explicit Approval: ' + requireExplicitApproval + '\n';
            description += 'Parallel Approvals: ' + parallelApprovals + '\n';
            
            // Email templates
            if (String.isNotBlank(requestTemplate)) {
                description += 'Request Email Template: ' + requestTemplate + '\n';
            }
            if (String.isNotBlank(approvalTemplate)) {
                description += 'Approval Email Template: ' + approvalTemplate + '\n';
            }
            if (String.isNotBlank(rejectionTemplate)) {
                description += 'Rejection Email Template: ' + rejectionTemplate + '\n';
            }
            if (String.isNotBlank(recallTemplate)) {
                description += 'Recall Email Template: ' + recallTemplate + '\n';
            }
            
            // Email recipients
            if (String.isNotBlank(approvalRecipients)) {
                description += 'Approval Email Recipients: ' + approvalRecipients + '\n';
            }
            if (String.isNotBlank(rejectionRecipients)) {
                description += 'Rejection Email Recipients: ' + rejectionRecipients + '\n';
            }
            
            // Effective dates
            if (String.isNotBlank(effectiveDateField) || String.isNotBlank(effectiveStartDate) || String.isNotBlank(effectiveEndDate)) {
                if (String.isNotBlank(effectiveDateField)) {
                    description += 'Effective Date Field: ' + effectiveDateField + '\n';
                }
                if (String.isNotBlank(effectiveStartDate)) {
                    description += 'Effective Start Date: ' + effectiveStartDate + '\n';
                }
                if (String.isNotBlank(effectiveEndDate)) {
                    description += 'Effective End Date: ' + effectiveEndDate + '\n';
                }
            }
            
            description += '\n';
            
            // Document conditions
            description += 'CONDITIONS:\n';
            description += '-----------\n';
            description += conditions + '\n';
            
            // Document tracked fields
            description += 'TRACKED FIELDS:\n';
            description += '--------------\n';
            description += trackedFields + '\n';
            
            return description;
        }
    }
}