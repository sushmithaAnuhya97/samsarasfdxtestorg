public with sharing class AccountFieldSetProvider {
    private static Boolean mdtCacheLoaded = false;
    private static Map<String, List<Account_Segment_Owner_Mapping__mdt>> mdtByReason = new Map<String, List<Account_Segment_Owner_Mapping__mdt>>();
    private static Map<String, Schema.DescribeFieldResult> accountDescribeByField = new Map<String, Schema.DescribeFieldResult>();
    private static Map<String, Schema.DescribeFieldResult> caseDescribeByField = new Map<String, Schema.DescribeFieldResult>();

    private static void loadAllMdt() {
        if (mdtCacheLoaded) {
            return;
        }
        List<Account_Segment_Owner_Mapping__mdt> allRows = [
            SELECT Submission_Reason__c, Account_API_Field_Name__c, Case_API_Field_Name__c, Sequence__c, Text_to_Present__c
            FROM Account_Segment_Owner_Mapping__mdt
            ORDER BY Submission_Reason__c ASC, Sequence__c ASC NULLS LAST
        ];
        for (Account_Segment_Owner_Mapping__mdt r : allRows) {
            if (String.isBlank(r.Submission_Reason__c)) continue;
            List<Account_Segment_Owner_Mapping__mdt> bucket = mdtByReason.get(r.Submission_Reason__c);
            if (bucket == null) {
                bucket = new List<Account_Segment_Owner_Mapping__mdt>();
                mdtByReason.put(r.Submission_Reason__c, bucket);
            }
            bucket.add(r);
        }
        mdtCacheLoaded = true;
    }

    private static void ensureDescribeCaches() {
        if (accountDescribeByField.isEmpty()) {
            Map<String, Schema.SObjectField> accFields = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
            for (String f : accFields.keySet()) {
                try { accountDescribeByField.put(f, accFields.get(f).getDescribe()); } catch (Exception ignore) {}
            }
        }
        if (caseDescribeByField.isEmpty()) {
            Map<String, Schema.SObjectField> csFields = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();
            for (String f : csFields.keySet()) {
                try { caseDescribeByField.put(f, csFields.get(f).getDescribe()); } catch (Exception ignore) {}
            }
        }
    }

 
    public class FieldConfigDTO {
        @AuraEnabled public String apiName;
        @AuraEnabled public Integer sequence;
        @AuraEnabled public String caseFieldApiName;
        @AuraEnabled public String displayLabel;
        @AuraEnabled public Boolean required;
    }

    /**
     * Returns ordered Account field configs
     * for the given submission reason from Account_Segment_Owner_Mapping__mdt,
     * ordered by Sequence__c.
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldConfigDTO> getFieldsForReason(String submissionReason) {
        List<FieldConfigDTO> result = new List<FieldConfigDTO>();
        if (String.isBlank(submissionReason)) {
            return result;
        }
        try {
            ensureDescribeCaches();
            loadAllMdt();
            List<Account_Segment_Owner_Mapping__mdt> rows = mdtByReason.get(submissionReason);
            if (rows != null) for (Account_Segment_Owner_Mapping__mdt r : rows) {
                if (String.isBlank(r.Account_API_Field_Name__c)) continue;
                FieldConfigDTO dto = new FieldConfigDTO();
                dto.apiName = r.Account_API_Field_Name__c;
                dto.caseFieldApiName = r.Case_API_Field_Name__c;
                dto.sequence = (Integer) r.Sequence__c;
                String fname = dto.apiName;
                if (fname == 'BillingAddress') {
                    dto.displayLabel = 'Billing Address';
                } else if (fname == 'ShippingAddress') {
                    dto.displayLabel = 'Shipping Address';
                } else {
                    Schema.DescribeFieldResult d = accountDescribeByField.get(fname);
                    dto.displayLabel = (d != null) ? d.getLabel() : fname;
                }
                result.add(dto);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'getFieldsForReason failed: ' + ex.getMessage());
        }
        return result;
    }

    /**
     * Returns the instructional text to display for Screen 2 for a given submission reason.
     * We return the first matching metadata row ordered by Sequence__c (if present).
     */
    @AuraEnabled(cacheable=true)
    public static String getReasonText(String submissionReason) {
        if (String.isBlank(submissionReason)) {
            return '';
        }
        try {
            ensureDescribeCaches();
            loadAllMdt();
            List<Account_Segment_Owner_Mapping__mdt> rows = mdtByReason.get(submissionReason);
            if (rows != null) {
                for (Account_Segment_Owner_Mapping__mdt r : rows) {
                    if (r.Text_to_Present__c != null) {
                        return r.Text_to_Present__c;
                    }
                }
            }
            return '';
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'getReasonText failed: ' + ex.getMessage());
            return '';
        }
    }

    public class ApplyCaseFieldsRequest {
        @InvocableVariable(required=true)
        public Id caseId;

        @InvocableVariable(required=true)
        public Id accountId;

        @InvocableVariable(required=true)
        public String submissionReason;

        @InvocableVariable
        public String fieldValuesJson; // JSON map of Account field API name -> value from Screen 2
    }

    public class ApplyCaseFieldsResponse {
        @InvocableVariable
        public Id caseId;

        @InvocableVariable
        public String error;
    }

    @InvocableMethod(label='Apply Case Fields from Screen 2' description='Maps Account field values from Screen 2 to Case fields using Account_Segment_Owner_Mapping__mdt.')
    public static List<ApplyCaseFieldsResponse> applyCaseFields(List<ApplyCaseFieldsRequest> requests) {
        List<ApplyCaseFieldsResponse> responses = new List<ApplyCaseFieldsResponse>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }
        ensureDescribeCaches();

        // Collect Account ids and Case ids to load as needed
        Set<Id> accountIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        Set<String> submissionReasons = new Set<String>();
        for (ApplyCaseFieldsRequest req : requests) {
            ApplyCaseFieldsResponse resp = new ApplyCaseFieldsResponse();
            resp.caseId = req != null ? req.caseId : null;
            responses.add(resp);
            if (req == null || req.caseId == null || req.accountId == null || String.isBlank(req.submissionReason)) {
                resp.error = 'Missing required inputs (caseId, accountId, submissionReason).';
                continue;
            }
            accountIds.add(req.accountId);
            caseIds.add(req.caseId);
            submissionReasons.add(req.submissionReason);
        }

        Map<Id, Account> accountsById = new Map<Id, Account>();
        Map<Id, Account> accountUpdatesById = new Map<Id, Account>();
        if (!accountIds.isEmpty()) {
            accountsById = new Map<Id, Account>([
                SELECT Id FROM Account WHERE Id IN :accountIds
            ]);
        }

        // Load Case records to update
        Map<Id, Case> casesById = new Map<Id, Case>();
        if (!caseIds.isEmpty()) {
            casesById = new Map<Id, Case>([
                SELECT Id FROM Case WHERE Id IN :caseIds
            ]);
        }

        // Load CMDT once per transaction; avoid repeated guarded calls below
        loadAllMdt();

        // Build all derived structures in one pass over CMDT
        Map<String, List<String>> reasonToAccountFields = new Map<String, List<String>>();
        Map<String, List<String>> reasonToCaseFields = new Map<String, List<String>>();
        Set<String> allSourceFields = new Set<String>();
        Map<String, String> uniquePairs = new Map<String, String>(); // src->tgt across all CMDT rows
        for (String rKey : mdtByReason.keySet()) {
            List<Account_Segment_Owner_Mapping__mdt> rows = mdtByReason.get(rKey);
            if (rows == null) continue;
            Boolean includeReason = submissionReasons.contains(rKey);
            for (Account_Segment_Owner_Mapping__mdt row : rows) {
                String src = row.Account_API_Field_Name__c;
                if (String.isBlank(src)) continue;
                String tgt = String.isBlank(row.Case_API_Field_Name__c) ? src : row.Case_API_Field_Name__c;

                // Reason-scoped mappings only for requested submission reasons
                if (includeReason) {
                    List<String> srcList = reasonToAccountFields.get(rKey);
                    if (srcList == null) { srcList = new List<String>(); reasonToAccountFields.put(rKey, srcList); }
                    List<String> tgtList = reasonToCaseFields.get(rKey);
                    if (tgtList == null) { tgtList = new List<String>(); reasonToCaseFields.put(rKey, tgtList); }
                    srcList.add(src);
                    tgtList.add(tgt);
                }

                // Unique global src->tgt pair
                String key = src + '->' + tgt;
                if (!uniquePairs.containsKey(key)) uniquePairs.put(key, tgt);

                // Superset of Account fields for dynamic query
                if (src == 'BillingAddress') {
                    allSourceFields.add('BillingStreet');
                    allSourceFields.add('BillingCity');
                    allSourceFields.add('BillingState');
                    allSourceFields.add('BillingPostalCode');
                    allSourceFields.add('BillingCountry');
                } else if (src == 'ShippingAddress') {
                    allSourceFields.add('ShippingStreet');
                    allSourceFields.add('ShippingCity');
                    allSourceFields.add('ShippingState');
                    allSourceFields.add('ShippingPostalCode');
                    allSourceFields.add('ShippingCountry');
                } else {
                    allSourceFields.add(src);
                }
            }
        }
        // Add any additional fields used in logic elsewhere
        List<String> additionalAccountFieldsToFetch = new List<String>{
            'ParentId','Updated_Account_Size_Segment__c','Global_Geography__c',
            'Number_of_Vehicles__c','Number_of_Powered_Assets__c','Number_of_Unpowered_Assets__c','Number_of_Smart_Trailers__c',
            'Netsuite_Delinquent_Status__c','Facebook_URL__c','LinkedIn_URL__c','Website','Phone','Industry','Billing_Email__c'
        };
        allSourceFields.addAll(additionalAccountFieldsToFetch);

        if (!accountIds.isEmpty() && !allSourceFields.isEmpty()) {
            List<String> selectFields = new List<String>();
            selectFields.add('Id');
            selectFields.addAll(new List<String>(allSourceFields));
            String soql = 'SELECT ' + String.join(selectFields, ',') + ' FROM Account WHERE Id IN :accountIds';
            try {
                List<Account> accList = Database.query(soql);
                accountsById = new Map<Id, Account>(accList);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'applyCaseFields: error querying Accounts dynamically: ' + ex.getMessage());
            }
        }

        Map<String, Schema.SObjectField> accountFieldMap = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> caseFieldMap = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();

        List<Case> updates = new List<Case>();
        for (Integer i = 0; i < requests.size(); i++) {
            ApplyCaseFieldsRequest req = requests[i];
            ApplyCaseFieldsResponse resp = responses[i];
            if (resp.error != null) { continue; }

            List<String> sourceFields = reasonToAccountFields.get(req.submissionReason);
            List<String> targetFields = reasonToCaseFields.get(req.submissionReason);
            if (sourceFields == null) sourceFields = new List<String>();
            if (targetFields == null) targetFields = new List<String>();

            Map<String, Object> valuesFromJson = new Map<String, Object>();
            if (!String.isBlank(req.fieldValuesJson)) {
                try { valuesFromJson = (Map<String, Object>) JSON.deserializeUntyped(req.fieldValuesJson);} catch (Exception ignore) {}
            }

            // Prepare the Case record to update BEFORE any mapping uses it
            Case existing = casesById.get(req.caseId);
            Case toUpdate = existing != null ? new Case(Id = existing.Id) : null;

            // Metadata-driven row mapping (future-safe): map ALL CMDT-defined pairs (no reason filter), precomputed
            if (toUpdate != null) {
                // Apply each unique mapping
                for (String key : uniquePairs.keySet()) {
                    List<String> parts = key.split('->');
                    String srcField = parts[0];
                    String tgtField = uniquePairs.get(key);
                    if (srcField == 'BillingAddress' || srcField == 'ShippingAddress') {
                        applyCompositeAddress(srcField, valuesFromJson, accountsById.get(req.accountId), toUpdate, tgtField, caseFieldMap, accountUpdatesById, req.accountId);
                        continue;
                    }
                    Object v;
                    {
                        v = normalizeJsonValue(valuesFromJson.get(srcField));
                        if (v == null) {
                            Account acc = accountsById.get(req.accountId);
                            if (acc != null) { try { v = acc.get(srcField);} catch (Exception e) {} }
                        }
                    }
                    if (isUpdateable(caseFieldMap, tgtField) && v != null) {
                        try { toUpdate.put(tgtField, coerceForField(caseFieldMap, tgtField, v)); } catch (Exception e) {}
                    }
                    if (valuesFromJson.containsKey(srcField) && v != null && isUpdateable(accountFieldMap, srcField)) {
                        Account accUpd = accountUpdatesById.get(req.accountId);
                        if (accUpd == null) { accUpd = new Account(Id = req.accountId); accountUpdatesById.put(req.accountId, accUpd);} 
                        try { accUpd.put(srcField, coerceForField(accountFieldMap, srcField, v)); } catch (Exception e) {}
                    }
                }
            }

            if (!sourceFields.isEmpty() && !targetFields.isEmpty() && sourceFields.size() == targetFields.size()) {
                for (Integer idx = 0; idx < sourceFields.size(); idx++) {
                    String srcField = sourceFields[idx];
                    String tgtField = targetFields[idx];
                    if (String.isBlank(srcField) || String.isBlank(tgtField)) continue;
                    if (srcField == 'BillingAddress' || srcField == 'ShippingAddress') {
                        applyCompositeAddress(srcField, valuesFromJson, accountsById.get(req.accountId), toUpdate, tgtField, caseFieldMap, accountUpdatesById, req.accountId);
                        continue;
                    }
                    Object v;
                    {
                        v = normalizeJsonValue(valuesFromJson.get(srcField));
                        if (v == null) {
                            Account acc = accountsById.get(req.accountId);
                            if (acc != null) { try { v = acc.get(srcField);} catch (Exception e) {} }
                        }
                    }
                    if (toUpdate != null && isUpdateable(caseFieldMap, tgtField)) {
                        Object valueForCase = (tgtField == 'AccountId') ? req.accountId : v;
                        if (valueForCase != null) {
                            valueForCase = coerceForField(caseFieldMap, tgtField, valueForCase);
                            try { toUpdate.put(tgtField, valueForCase);} catch (Exception e) {}
                        }
                    }
                    if (v != null && isUpdateable(accountFieldMap, srcField)) {
                        Account accUpd = accountUpdatesById.get(req.accountId);
                        if (accUpd == null) { accUpd = new Account(Id = req.accountId); accountUpdatesById.put(req.accountId, accUpd);} 
                        try { Object coerced = coerceForField(accountFieldMap, srcField, v); accUpd.put(srcField, coerced);} catch (Exception e) {}
                    }
                }
            }

            // Generic fallback: write JSON same-name fields to Account and Case
            if (!valuesFromJson.isEmpty()) {
                Account accUpdGeneric = accountUpdatesById.get(req.accountId);
                if (accUpdGeneric == null) { accUpdGeneric = new Account(Id = req.accountId); accountUpdatesById.put(req.accountId, accUpdGeneric);} 
                for (String key : valuesFromJson.keySet()) {
                    if (key == 'BillingAddress' || key == 'ShippingAddress') continue;
                    Object val = normalizeJsonValue(valuesFromJson.get(key));
                    try { if (isUpdateable(accountFieldMap, key)) accUpdGeneric.put(key, coerceForField(accountFieldMap, key, val)); } catch (Exception e) {}
                }
                if (toUpdate != null) {
                    Map<String, String> mappings = getAccountToCaseMappings();
                    if (mappings.containsKey('ParentId') && valuesFromJson.containsKey('ParentId')) {
                        String aliasField = mappings.get('ParentId');
                        if (isUpdateable(caseFieldMap, aliasField)) {
                            Object coercedAlias = coerceForField(caseFieldMap, aliasField, normalizeJsonValue(valuesFromJson.get('ParentId')));
                            try { toUpdate.put(aliasField, coercedAlias);} catch (Exception ignore) {}
                        }
                    }
                    for (String key : valuesFromJson.keySet()) {
                        if (key == 'BillingAddress' || key == 'ShippingAddress') continue;
                        Object val = normalizeJsonValue(valuesFromJson.get(key));
                        if (isUpdateable(caseFieldMap, key)) {
                            try { toUpdate.put(key, coerceForField(caseFieldMap, key, val)); } catch (Exception ignore) {}
                        } else {
                            String aliasField = mappings.get(key);
                            if (aliasField != null && isUpdateable(caseFieldMap, aliasField)) {
                                try { toUpdate.put(aliasField, coerceForField(caseFieldMap, aliasField, val)); } catch (Exception ignore) {}
                            }
                        }
                    }
                    if (mappings.containsKey('BillingAddress')) {
                        String caseAddressField = mappings.get('BillingAddress');
                        applyCompositeAddress('BillingAddress', valuesFromJson, accountsById.get(req.accountId), toUpdate, caseAddressField, caseFieldMap, accountUpdatesById, req.accountId);
                    }
                }
            }

            if (toUpdate != null) { updates.add(toUpdate);} 
        }

        if (!updates.isEmpty()) {
            try { update updates; } catch (DmlException dmlEx) {
                String msg = dmlEx.getMessage();
                for (ApplyCaseFieldsResponse r : responses) { r.error = msg; }
            }
        }

        if (!accountUpdatesById.isEmpty()) {
            try { update accountUpdatesById.values(); } catch (DmlException dmlEx) {
                String msg = dmlEx.getMessage();
                for (ApplyCaseFieldsResponse r : responses) { if (String.isBlank(r.error)) r.error = msg; }
            }
        }

        return responses;
    }

    private static List<String> splitCsv(String raw) {
        if (String.isBlank(raw)) return new List<String>();
        String normalized = raw.replace(' ,', ',').replace(', ', ',').trim();
        List<String> parts = new List<String>();
        for (String p : normalized.split(',')) { if (!String.isBlank(p)) parts.add(p.trim()); }
        return parts;
    }

    private static String buildAddressString(Map<String, Object> jsonValues, Account acc, String street, String city, String state, String postal, String country) {
        String st = (String) jsonValues.get(street);
        String ci = (String) jsonValues.get(city);
        String stt = (String) jsonValues.get(state);
        String pc = (String) jsonValues.get(postal);
        String co = (String) jsonValues.get(country);
        if (st == null && acc != null && acc.getSObjectType() == Account.SObjectType) st = (String) safeGet(acc, street);
        if (ci == null && acc != null && acc.getSObjectType() == Account.SObjectType) ci = (String) safeGet(acc, city);
        if (stt == null && acc != null && acc.getSObjectType() == Account.SObjectType) stt = (String) safeGet(acc, state);
        if (pc == null && acc != null && acc.getSObjectType() == Account.SObjectType) pc = (String) safeGet(acc, postal);
        if (co == null && acc != null && acc.getSObjectType() == Account.SObjectType) co = (String) safeGet(acc, country);
        List<String> parts = new List<String>();
        if (!String.isBlank(st)) parts.add(st);
        if (!String.isBlank(ci)) parts.add(ci);
        if (!String.isBlank(stt)) parts.add(stt);
        if (!String.isBlank(pc)) parts.add(pc);
        if (!String.isBlank(co)) parts.add(co);
        return String.join(parts, ', ');
    }

    private static Object safeGet(SObject sobj, String field) { try { return sobj.get(field);} catch (Exception e) { return null; } }

    private static Object normalizeJsonValue(Object v) {
        if (v == null) return null;
        if (v instanceof List<Object>) { List<Object> lst = (List<Object>) v; return lst.isEmpty() ? null : lst[0]; }
        return v;
    }

    private static Boolean isUpdateable(Map<String, Schema.SObjectField> fieldMap, String fieldApiName) {
        if (String.isBlank(fieldApiName)) return false;
        Schema.DescribeFieldResult d = fieldMap == null ? null : (fieldMap.containsKey(fieldApiName) ? fieldMap.get(fieldApiName).getDescribe() : null);
        if (d == null) {
            // fallback to cached describes if available
            d = caseDescribeByField.containsKey(fieldApiName) ? caseDescribeByField.get(fieldApiName) : accountDescribeByField.get(fieldApiName);
        }
        if (d == null) return false;
        try { return d.isUpdateable(); } catch (Exception e) { return false; }
    }

    private static void upsertAccountAddressComponents(Map<Id, Account> accountUpdatesById, Id accountId, Map<String, Object> jsonValues,
                                                       String street, String city, String state, String postal, String country) {
        Boolean hasAny = jsonValues.containsKey(street) || jsonValues.containsKey(city) || jsonValues.containsKey(state) || jsonValues.containsKey(postal) || jsonValues.containsKey(country);
        if (!hasAny) return;
        Account accUpd = accountUpdatesById.get(accountId);
        if (accUpd == null) { accUpd = new Account(Id = accountId); accountUpdatesById.put(accountId, accUpd);} 
        try { if (jsonValues.containsKey(street)) accUpd.put(street, jsonValues.get(street)); } catch (Exception ignore) {}
        try { if (jsonValues.containsKey(city)) accUpd.put(city, jsonValues.get(city)); } catch (Exception ignore) {}
        try { if (jsonValues.containsKey(state)) accUpd.put(state, jsonValues.get(state)); } catch (Exception ignore) {}
        try { if (jsonValues.containsKey(postal)) accUpd.put(postal, jsonValues.get(postal)); } catch (Exception ignore) {}
        try { if (jsonValues.containsKey(country)) accUpd.put(country, jsonValues.get(country)); } catch (Exception ignore) {}
    }

    private static void applyCompositeAddress(String srcField,
                                              Map<String, Object> jsonValues,
                                              Account accountRecord,
                                              Case caseToUpdate,
                                              String caseFieldApiName,
                                              Map<String, Schema.SObjectField> caseFieldMap,
                                              Map<Id, Account> accountUpdatesById,
                                              Id accountId) {
        Boolean isBilling = (srcField == 'BillingAddress');
        String street = isBilling ? 'BillingStreet' : 'ShippingStreet';
        String city = isBilling ? 'BillingCity' : 'ShippingCity';
        String state = isBilling ? 'BillingState' : 'ShippingState';
        String postal = isBilling ? 'BillingPostalCode' : 'ShippingPostalCode';
        String country = isBilling ? 'BillingCountry' : 'ShippingCountry';

        String addr = buildAddressString(jsonValues, accountRecord, street, city, state, postal, country);
        if (caseToUpdate != null && !String.isBlank(caseFieldApiName) && isUpdateable(caseFieldMap, caseFieldApiName) && !String.isBlank(addr)) {
            try { caseToUpdate.put(caseFieldApiName, addr); } catch (Exception ignore) {}
        }
        upsertAccountAddressComponents(accountUpdatesById, accountId, jsonValues, street, city, state, postal, country);
    }

    private static Object coerceForField(Map<String, Schema.SObjectField> fieldMap, String fieldApiName, Object value) {
        if (value == null) return null;
        Schema.DescribeFieldResult d = null;
        if (fieldMap != null && fieldMap.containsKey(fieldApiName)) {
            try { d = fieldMap.get(fieldApiName).getDescribe(); } catch (Exception ignore) {}
        }
        if (d == null) {
            d = caseDescribeByField.containsKey(fieldApiName) ? caseDescribeByField.get(fieldApiName) : accountDescribeByField.get(fieldApiName);
        }
        Schema.DisplayType t = d.getType();
        try {
            switch on t {
                when Integer {
                    if (value instanceof Integer) return value;
                    if (value instanceof Long) return (Integer) value;
                    if (value instanceof Decimal) return ((Decimal) value).intValue();
                    return Integer.valueOf(String.valueOf(value));
                }
                when Double, Currency, Percent {
                    if (value instanceof Decimal) return value;
                    if (value instanceof Integer) return Decimal.valueOf((Integer) value);
                    if (value instanceof Long) return Decimal.valueOf((Long) value);
                    return Decimal.valueOf(String.valueOf(value));
                }
                when Boolean {
                    if (value instanceof Boolean) return value;
                    String s = String.valueOf(value).toLowerCase();
                    return (s == 'true' || s == '1' || s == 'yes');
                }
                when Date {
                    if (value instanceof Date) return value;
                    if (value instanceof Datetime) return ((Datetime) value).date();
                    return System.Date.valueOf(String.valueOf(value));
                }
                when Datetime {
                    if (value instanceof Datetime) return value;
                    if (value instanceof Date) return System.Datetime.newInstanceGMT((Date) value, System.Time.newInstance(0,0,0,0));
                    return System.Datetime.valueOf(String.valueOf(value));
                }
                when Time {
                    if (value instanceof Time) return value;
                    return null;
                }
                when Reference, Id {
                    return (Id) String.valueOf(value);
                }
                when else {
                    return String.valueOf(value);
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'coerceForField: failed coercion for field ' + fieldApiName + ' value=' + value + ' type=' + t + ' err=' + ex.getMessage());
            return null;
        }
    }

    // Minimal alias map for exceptional cases only
    private static Map<String, String> getAccountToCaseMappings() {
        Map<String, String> mapAll = new Map<String, String>();
        mapAll.put('ParentId', 'Parent_Account__c');
        return mapAll;
    }
}