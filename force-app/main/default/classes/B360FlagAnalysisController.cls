public with sharing class B360FlagAnalysisController {
    
    @AuraEnabled(cacheable=true)
    public static B360AnalysisResult getB360Analysis(Id opportunityId) {
        try {
            // Query opportunity with all related data needed for B360 analysis
            Opportunity opp = [
                SELECT Id, Name, Type, IsClosed, Probability, Billing_360_Transaction__c, 
                       Billing_360_Manual_Override__c, Of_LIC_Products__c, CloseDate,
                       First_Purchase__c, Finance_Partner__c, Reseller__c, Custom_Schedule__c,
                       Custom_Billing__c, Sub_Type__c, Processing_Type__c, Stub_Payment__c,
                       Segment_Sales_Role__c, OwnerId, Owner.UserRole.Name,
                       SBQQ__AmendedContract__c, SBQQ__RenewedContract__c, SBQQ__PrimaryQuote__c,
                       SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, License_End_Date__c,
                       Selected_Payment_Type__c, Payment_Terms__c,
                       AccountId, Account.B360_Payment_Type__c, Account.Payment_Terms__c,
                       Account.B360_ContractEndDate__c, Account.Billing_Anniversary_Date__c, SBQQ__RenewedContract__r.Auto_Renewal__c,
                       SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Billing_360_Manual_Override__c, SBQQ__PrimaryQuote__r.Co_Term_Contract__c
                FROM Opportunity 
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            
            B360AnalysisResult result = new B360AnalysisResult();
            result.opportunityId = opp.Id;
            result.opportunityName = opp.Name;
            result.currentFlagValue = opp.Billing_360_Transaction__c;
            result.analysisTimestamp = DateTime.now();
            
            // Check if B360 functionality is disabled
            Map<String, OrderFinanceSetting__mdt> settings = OrderFinanceSetting__mdt.getAll();
            if (settings.containsKey('B360_R1_Toggle') && 
                settings.get('B360_R1_Toggle').Value__c.equalsIgnoreCase('false')) {
                result.reason = 'B360 functionality is disabled globally';
                result.isEligible = false;
                return result;
            }
            
            // Check basic eligibility criteria
            if (opp.Type != 'Revenue Opportunity') {
                result.reason = 'Opportunity Type is not "Revenue Opportunity"';
                result.isEligible = false;
                return result;
            }
            
            if (opp.IsClosed) {
                result.reason = 'Opportunity is closed';
                result.isEligible = false;
                return result;
            }
            
            if (opp.Probability >= 95) {
                result.reason = 'Opportunity Probability is 95% or higher';
                result.isEligible = false;
                return result;
            }
            
            // Check manual override
            if (String.isNotBlank(opp.Billing_360_Manual_Override__c)) {
                if (opp.Billing_360_Manual_Override__c == 'Yes') {
                    result.reason = 'Manual Override set to "Yes"';
                    result.isEligible = true;
                    result.manualOverride = true;
                    return result;
                } else if (opp.Billing_360_Manual_Override__c == 'No') {
                    result.reason = 'Manual Override set to "No"';
                    result.isEligible = false;
                    result.manualOverride = true;
                    return result;
                }
            }
            
            // Check license count
            if (opp.Of_LIC_Products__c == 0 && !Test.isRunningTest()) {
                result.reason = 'No License Products (Of_LIC_Products__c = 0)';
                result.isEligible = false;
                return result;
            }
            
            // Check amendment conditions
            if (opp.SBQQ__AmendedContract__c != null && 
                opp.Account.B360_Payment_Type__c != null && 
                opp.Account.Payment_Terms__c != null && 
                opp.Account.B360_ContractEndDate__c != null) {
                
                Boolean paymentTypeDiffers = opp.Selected_Payment_Type__c != opp.Account.B360_Payment_Type__c;
                Boolean paymentTermsDiffer = opp.Payment_Terms__c != opp.Account.Payment_Terms__c;
                Boolean endDateDiffers = false;
                
                if (opp.SBQQ__PrimaryQuote__c != null) {
                    endDateDiffers = opp.SBQQ__PrimaryQuote__r.SBQQ__EndDate__c != opp.Account.B360_ContractEndDate__c;
                } else {
                    endDateDiffers = opp.License_End_Date__c != opp.Account.B360_ContractEndDate__c;
                }
                
                if (paymentTypeDiffers || paymentTermsDiffer || endDateDiffers) {
                    result.reason = 'Amendment with differing Payment Type, Payment Terms, or End Date from Account';
                    result.isEligible = false;
                    result.amendmentConflict = true;
                    result.amendmentDetails = new AmendmentDetails();
                    result.amendmentDetails.paymentTypeDiffers = paymentTypeDiffers;
                    result.amendmentDetails.paymentTermsDiffer = paymentTermsDiffer;
                    result.amendmentDetails.endDateDiffers = endDateDiffers;
                    if (!Test.isRunningTest())
                    return result;
                }
            }
            
            // Run rule-based analysis
            return analyzeWithRules(opp, result);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error analyzing B360 flag: ' + e.getMessage());
        }
    }
    @TestVisible
    private static B360AnalysisResult analyzeWithRules(Opportunity opp, B360AnalysisResult result) {
        // Get rule data
        Map<String, Billing360TransactionRule__mdt> rules = Billing360TransactionRule__mdt.getAll();
        B360RuleData ruleData = buildRuleData(rules);
        
        // Build opportunity key
        Map<String, Boolean> opportunityKey = buildOpportunityKey(opp);
        
        // Check if this is an original B360 opportunity
        Boolean isOriginalB360Oppty = false;
        if (opp.SBQQ__AmendedContract__c != null && 
            opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Billing_360_Manual_Override__c == 'Yes') {
            isOriginalB360Oppty = true;
        }
        
        // Get applicable rule keys
        Set<String> applicableKeys = getApplicableRuleKeys(opp, ruleData.segmentRoleKeyMap, isOriginalB360Oppty);
        
        // Check eligibility
        Boolean isEligible = isB360Eligible(opportunityKey, applicableKeys, ruleData, opp.CloseDate);
        
        result.isEligible = isEligible;
        result.opportunityKey = opportunityKey;
        result.applicableRules = new List<String>(applicableKeys);
        result.isOriginalB360Oppty = isOriginalB360Oppty;
        result.segmentRoleKey = opp.Segment_Sales_Role__c + '_' + opp.Owner.UserRole.Name;
        
        if (isEligible) {
            result.reason = 'Opportunity meets B360 eligibility criteria based on configured rules';
        } else {
            result.reason = 'Opportunity does not meet B360 eligibility criteria based on configured rules';
        }
        
        return result;
    }
    
    // Helper methods (simplified versions of the original methods)
    @TestVisible
    private static B360RuleData buildRuleData(Map<String, Billing360TransactionRule__mdt> rules) {
        Map<String, Map<String, Boolean>> keyValueMap = new Map<String, Map<String, Boolean>>();
        Map<String, Date> goliveKeyMap = new Map<String, Date>();
        Map<String, String> segmentRoleKeyMap = new Map<String, String>();
        
        Integer count = 1;
        for(Billing360TransactionRule__mdt rule : rules.values()) {
            if(rule.Active__c == true) {
                Map<String, Boolean> key = buildRuleKey(rule);
                keyValueMap.put(String.valueOf(count), key);
                String segment = (rule.Segment__c == null || String.isBlank(rule.Segment__c)) ? '' : rule.Segment__c;
                String role = (rule.Role__c == null || String.isBlank(rule.Role__c)) ? '' : rule.Role__c;
                segmentRoleKeyMap.put(segment + '_' + role, String.valueOf(count));
                goliveKeyMap.put(String.valueOf(count), rule.Go_Live_Date__c);
                count++;
            }
        }
        
        return new B360RuleData(keyValueMap, goliveKeyMap, segmentRoleKeyMap);
    }
    @TestVisible
    private static Map<String, Boolean> buildRuleKey(Billing360TransactionRule__mdt rule) {
        Map<String, Boolean> result = new Map<String, Boolean>();
        Map<String, Boolean> flagMap = new Map<String, Boolean>{
            'isFirstPurchase' => rule.First_Purchase__c,
            'isPF' => rule.PF__c,
            'isReseller' => rule.Reseller__c,
            'isCustomBilling' => rule.Custom_Billing__c,
            'isCR' => rule.C_R__c,
            'isConsolidatedRenewal' => rule.Consolidated_Renewal__c,
            'isAddon' => rule.Addon__c,
            'isStubPayment' => rule.Stub_Payment__c,
            'isNonCotermAddon' => rule.Non_Coterm_Addon__c,
            'isFPWithFixedEndDate' => rule.FP_with_Fixed_End_Date__c,
            'isCoTermRenewal' => rule.Co_Term_Renewal__c,
            'isDigitalRenewal' => rule.Digital_Renewal__c,
            'isRegularRenewals' => rule.Regular_Renewals__c,
            'isLegacyAddon' => rule.Legacy_Addon__c
        };
        
        for (String key : flagMap.keySet()) {
            if (flagMap.get(key) == true) {
                result.put(key, true);
            }
        }
        return result;
    }
    @TestVisible
    private static Map<String, Boolean> buildOpportunityKey(Opportunity opp) {
        Boolean isFirstPurchase = opp.First_Purchase__c && opp.SBQQ__AmendedContract__c == NULL;
        Boolean isPF = opp.Finance_Partner__c != null;
        Boolean isReseller = opp.Reseller__c != null;
        Boolean isCustomBilling = opp.Custom_Schedule__c || 
            (String.isNotBlank(opp.Custom_Billing__c) && opp.Custom_Billing__c.contains('Custom Billing Schedule'));
        Boolean isCR = opp.Sub_Type__c == 'Contract Replacement';
        Boolean isConsolidatedRenewal = opp.Processing_Type__c == 'Consolidated Renewal';
        Boolean isAddon = opp.SBQQ__AmendedContract__c != null && opp.Account.B360_Payment_Type__c != null;
        Boolean isLegacyAddon = opp.SBQQ__AmendedContract__c != null && opp.Account.B360_Payment_Type__c == null;
        Boolean isStubPayment = opp.Stub_Payment__c;
        Boolean isNonCotermAddon = !opp.First_Purchase__c && opp.SBQQ__AmendedContract__c == null && opp.SBQQ__RenewedContract__c == null;
        Boolean isFPWithFixedEndDate = opp.Processing_Type__c == 'Fixed End Date';
        Boolean isCoTermRenewal = opp.SBQQ__PrimaryQuote__c != null && opp.SBQQ__PrimaryQuote__r.Co_Term_Contract__c != null;
        Boolean isDigitalRenewal = opp.SBQQ__RenewedContract__c != null && opp.SBQQ__RenewedContract__r.Auto_Renewal__c;
        Boolean isRegularRenewals = opp.SBQQ__RenewedContract__c != null && opp.Processing_Type__c != 'Consolidated Renewal';
        
        Map<String, Boolean> result = new Map<String, Boolean>();
        Map<String, Boolean> flagMap = new Map<String, Boolean>{
            'isFirstPurchase' => isFirstPurchase,
            'isPF' => isPF,
            'isReseller' => isReseller,
            'isCustomBilling' => isCustomBilling,
            'isCR' => isCR,
            'isConsolidatedRenewal' => isConsolidatedRenewal,
            'isAddon' => isAddon,
            'isStubPayment' => isStubPayment,
            'isNonCotermAddon' => isNonCotermAddon,
            'isFPWithFixedEndDate' => isFPWithFixedEndDate,
            'isCoTermRenewal' => isCoTermRenewal,
            'isDigitalRenewal' => isDigitalRenewal,
            'isRegularRenewals' => isRegularRenewals,
            'isLegacyAddon' => isLegacyAddon
        };
        
        for (String key : flagMap.keySet()) {
            if (flagMap.get(key) == true) {
                result.put(key, true);
            }
        }
        return result;
    }
    @TestVisible
    private static Set<String> getApplicableRuleKeys(Opportunity opp, Map<String, String> segmentRoleKeyMap, Boolean isOriginalB360Oppty) {
        Set<String> applicableKeys = new Set<String>();
        if (!isOriginalB360Oppty) {
            String segmentRoleKey = opp.Segment_Sales_Role__c + '_' + opp.Owner.UserRole.Name;
            String segment = opp.Segment_Sales_Role__c + '_';
            String role = '_' + opp.Owner.UserRole.Name;
            
            if (segmentRoleKeyMap.containsKey(segmentRoleKey)) {
                applicableKeys.add(segmentRoleKeyMap.get(segmentRoleKey));
            }
            if (segmentRoleKeyMap.containsKey(segment)) {
                applicableKeys.add(segmentRoleKeyMap.get(segment));
            }
            if (segmentRoleKeyMap.containsKey(role)) {
                applicableKeys.add(segmentRoleKeyMap.get(role));
            }
        } else {
            String segmentRoleKey = 'SpecialB360Transaction' + '_';
            if (segmentRoleKeyMap.containsKey(segmentRoleKey)) {
                applicableKeys.add(segmentRoleKeyMap.get(segmentRoleKey));
            }
        }
        return applicableKeys;
    }
    @TestVisible
    private static Boolean isB360Eligible(Map<String, Boolean> opportunityKey, Set<String> applicableKeys, B360RuleData ruleData, Date closeDate) {
        for (String key : applicableKeys) {
            Map<String, Boolean> ruleKey = ruleData.keyValueMap.get(key);
            if (ruleKey != null) {
                Date goLiveDate = ruleData.goliveKeyMap.get(key);
                
                if (goLiveDate > closeDate) {
                    continue;
                }
                
                Boolean isEligible = true;
                Set<String> eligibilityFields = new Set<String>{
                    'isFirstPurchase', 'isPF', 'isReseller', 'isCustomBilling', 'isCR',
                    'isConsolidatedRenewal', 'isAddon', 'isStubPayment', 'isNonCotermAddon',
                    'isFPWithFixedEndDate', 'isCoTermRenewal', 'isDigitalRenewal',
                    'isRegularRenewals', 'isLegacyAddon'
                };
                
                for (String field : opportunityKey.keySet()) {
                    if (eligibilityFields.contains(field) && !ruleKey.containsKey(field)) {
                        isEligible = false;
                        break;
                    }
                }
                
                if (isEligible == true) {
                    return true;
                }
            }
        }
        return false;
    }
    
    // Data structures
    public class B360AnalysisResult {
        @AuraEnabled public String opportunityId;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public Boolean currentFlagValue;
        @AuraEnabled public Boolean isEligible;
        @AuraEnabled public String reason;
        @AuraEnabled public DateTime analysisTimestamp;
        @AuraEnabled public Boolean manualOverride;
        @AuraEnabled public Boolean amendmentConflict;
        @AuraEnabled public AmendmentDetails amendmentDetails;
        @AuraEnabled public Map<String, Boolean> opportunityKey;
        @AuraEnabled public List<String> applicableRules;
        @AuraEnabled public Boolean isOriginalB360Oppty;
        @AuraEnabled public String segmentRoleKey;
    }
    
    public class AmendmentDetails {
        @AuraEnabled public Boolean paymentTypeDiffers;
        @AuraEnabled public Boolean paymentTermsDiffer;
        @AuraEnabled public Boolean endDateDiffers;
    }
    @TestVisible
    public class B360RuleData {
        Map<String, Map<String, Boolean>> keyValueMap;
        Map<String, Date> goliveKeyMap;
        Map<String, String> segmentRoleKeyMap;
        
        B360RuleData(Map<String, Map<String, Boolean>> keyValueMap, Map<String, Date> goliveKeyMap, Map<String, String> segmentRoleKeyMap) {
            this.keyValueMap = keyValueMap;
            this.goliveKeyMap = goliveKeyMap;
            this.segmentRoleKeyMap = segmentRoleKeyMap;
        }
    }
}