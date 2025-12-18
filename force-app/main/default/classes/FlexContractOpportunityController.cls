public without sharing class FlexContractOpportunityController {
    @AuraEnabled(cacheable=true)
    public static List<OpportunityWrapper> getOpportunitiesWithExceptions(List<Id> contractIds) {
        List<OpportunityWrapper> results = new List<OpportunityWrapper>();
        
        // Get field labels dynamically
        Map<String, String> fieldLabels = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();
        
        // Query contracts, primary opportunities and amendments
        List<Contract> contracts = [
            SELECT Id,
                   ContractNumber,
                   Name,
                   SBQQ__Opportunity__c,
                   SBQQ__Opportunity__r.AccountId,
                   SBQQ__Opportunity__r.Account.Name,
                   SBQQ__Opportunity__r.Name,
                   SBQQ__Opportunity__r.StageName,
                   SBQQ__Opportunity__r.Owner.Name,
                   SBQQ__Opportunity__r.OwnerId,
                   SBQQ__Opportunity__r.Payment_Terms_Opportunity_only_exception__c,
                   SBQQ__Opportunity__r.Payment_Type_Opportunity_only_Exception__c,
                   SBQQ__Opportunity__r.Initial_Payment_Terms__c,
                   SBQQ__Opportunity__r.Payment_Terms__c,
                   SBQQ__Opportunity__r.Selected_Payment_Type__c,
                   SBQQ__Opportunity__r.Custom_Schedule__c,
                   SBQQ__Opportunity__r.Stub_Payment__c,
                   SBQQ__Opportunity__r.SLA_Termination_right__c,
                   SBQQ__Opportunity__r.Samsara_insolvency__c,
                   SBQQ__Opportunity__r.Permanent_Downsize__c,
                   SBQQ__Opportunity__r.Partial_use_seasonal__c,
                   SBQQ__Opportunity__r.MSA_negotiated_under_good_faith_after_or__c,
                   SBQQ__Opportunity__r.Termination_for_convenience__c,
                   SBQQ__Opportunity__r.Termination_for_lack_of_appropriation_of__c,
                   SBQQ__Opportunity__r.Temporary_Suspension__c,
                   SBQQ__Opportunity__r.Extended_returns_beyond_30_days__c,
                   SBQQ__Opportunity__r.Price_lock_language_for_add_on_orders__c,
                   SBQQ__Opportunity__r.Non_Standard_terms_description__c,
                   SBQQ__Opportunity__r.Price_stability_for_renewal__c
            FROM Contract 
            WHERE Id IN :contractIds
        ];
    
        // Separately query amendment opportunities to avoid too many rows
        List<Opportunity> amendmentOpps = [
            SELECT Id, Name, StageName, AccountId, Account.Name,
                   Owner.Name,
                   OwnerId,
                   Payment_Terms_Opportunity_only_exception__c,
                   Payment_Type_Opportunity_only_Exception__c,
                   Initial_Payment_Terms__c,
                   Payment_Terms__c,
                   Selected_Payment_Type__c,
                   Custom_Schedule__c,
                   Stub_Payment__c,
                   SLA_Termination_right__c,
                   Samsara_insolvency__c,
                   Permanent_Downsize__c,
                   Partial_use_seasonal__c,
                   MSA_negotiated_under_good_faith_after_or__c,
                   Termination_for_convenience__c,
                   Termination_for_lack_of_appropriation_of__c,
                   Temporary_Suspension__c,
                   Extended_returns_beyond_30_days__c,
                   Price_lock_language_for_add_on_orders__c,
                   Non_Standard_terms_description__c,
                   Price_stability_for_renewal__c,
                   SBQQ__AmendedContract__c
            FROM Opportunity
            WHERE SBQQ__AmendedContract__c IN :contractIds
            AND StageName = 'Closed Won'
        ];
        System.debug('RP Number of amendment opportunities found: ' + amendmentOpps.size());
        // Create map of contract ID to amendment opportunities
        Map<Id, List<Opportunity>> contractToAmendments = new Map<Id, List<Opportunity>>();
        for(Opportunity opp : amendmentOpps) {
            if(!contractToAmendments.containsKey(opp.SBQQ__AmendedContract__c)) {
                contractToAmendments.put(opp.SBQQ__AmendedContract__c, new List<Opportunity>());
            }
            contractToAmendments.get(opp.SBQQ__AmendedContract__c).add(opp);
        }
        System.debug('RP  amendments Map: ' + contractToAmendments);
        // Get field labels for all fields we're checking
        List<String> fieldsToCheck = new List<String>{
            'Payment_Terms_Opportunity_only_exception__c',
            'Payment_Type_Opportunity_only_Exception__c',
            'Initial_Payment_Terms__c',
            'Payment_Terms__c',
            'Selected_Payment_Type__c',
            'Custom_Schedule__c',
            'Stub_Payment__c',
            'SLA_Termination_right__c',
            'Samsara_insolvency__c',
            'Permanent_Downsize__c',
            'Partial_use_seasonal__c',
            'MSA_negotiated_under_good_faith_after_or__c',
            'Termination_for_convenience__c',
            'Termination_for_lack_of_appropriation_of__c',
            'Temporary_Suspension__c',
            'Extended_returns_beyond_30_days__c',
            'Price_lock_language_for_add_on_orders__c',
            'Non_Standard_terms_description__c',
            'Price_stability_for_renewal__c'
        };
        
        for(String fieldName : fieldsToCheck) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            if(field != null) {
                fieldLabels.put(fieldName, field.getDescribe().getLabel());
            }
        }
    
        for(Contract c : contracts) {
            // Process primary opportunity
            if(c.SBQQ__Opportunity__c != null && 
               c.SBQQ__Opportunity__r.StageName == 'Closed Won') {
                String oppOwnerName = c.SBQQ__Opportunity__r.Owner.Name;
                String oppOwnerUrl = '/' + c.SBQQ__Opportunity__r.OwnerId;
                processOpportunity(c.SBQQ__Opportunity__r, fieldLabels, results, c.ContractNumber, c.Id, oppOwnerName, oppOwnerUrl);
            }
            
            // Process amendment opportunities
            if(contractToAmendments.containsKey(c.Id)) {
                for(Opportunity amendmentOpp : contractToAmendments.get(c.Id)) {
                    String oppOwnerName = amendmentOpp.Owner.Name;
                    String oppOwnerUrl = '/' + amendmentOpp.OwnerId;
                    processOpportunity(amendmentOpp, fieldLabels, results, c.ContractNumber, c.Id, oppOwnerName, oppOwnerUrl);
                }
            }
        }
        
        return results;
    }
    @AuraEnabled(cacheable=true)
    public static List<OpportunityWrapper> fetchOpportunitiesForUpgradedOpportunity(Id opportunityId) {
        
        List<OpportunityWrapper> results = new List<OpportunityWrapper>();
         
        // Query contracts directly using the given OpportunityId
        List<Contract> contracts = [
        SELECT Id,Name,ContractNumber,Flex_Replacement_Opportunity__c 
        FROM Contract 
        WHERE Flex_Replacement_Opportunity__c = :opportunityId];

        // Collect contract IDs
        Set<Id> contractIds = new Set<Id>();
        for (Contract contract : contracts) {
        contractIds.add(contract.Id);
        }

        if (!contractIds.isEmpty()) {
        results = getOpportunitiesWithExceptions(new List<Id>(contractIds));
        }

        return results;
        
    }
    
    private static void processOpportunity(Opportunity opp, Map<String,String> fieldLabels, List<OpportunityWrapper> results,String contractNumber, Id contractId,String oppOwnerName,String oppOwnerUrl) {
        Map<String,FieldWrapper> exceptions = new Map<String,FieldWrapper>();
        
        // Check boolean fields
        Boolean hasPaymentTermsException = opp.Payment_Terms_Opportunity_only_exception__c;
        Boolean hasPaymentTypeException = opp.Payment_Type_Opportunity_only_Exception__c;

        if(hasPaymentTermsException)
            exceptions.put('Payment_Terms_Opportunity_only_exception__c', 
            new FieldWrapper(fieldLabels.get('Payment_Terms_Opportunity_only_exception__c'), true));
        if(hasPaymentTypeException)
            exceptions.put('Payment_Type_Opportunity_only_Exception__c', 
            new FieldWrapper(fieldLabels.get('Payment_Type_Opportunity_only_Exception__c'), true));
        if(opp.Custom_Schedule__c)
            exceptions.put('Custom_Schedule__c', 
            new FieldWrapper(fieldLabels.get('Custom_Schedule__c'), true));
        if(opp.Stub_Payment__c)
            exceptions.put('Stub_Payment__c', 
            new FieldWrapper(fieldLabels.get('Stub_Payment__c'), true));

        // Add additional fields if specific exceptions are present
        if(hasPaymentTermsException || hasPaymentTypeException) {
            exceptions.put('Initial_Payment_Terms__c', 
            new FieldWrapper(fieldLabels.get('Initial_Payment_Terms__c'), opp.Initial_Payment_Terms__c));
            exceptions.put('Payment_Terms__c', 
            new FieldWrapper(fieldLabels.get('Payment_Terms__c'), opp.Payment_Terms__c));
            exceptions.put('Selected_Payment_Type__c', 
            new FieldWrapper(fieldLabels.get('Selected_Payment_Type__c'), opp.Selected_Payment_Type__c));
        }
        
        // Check picklist/text fields
        addExceptionIfPresent(exceptions, fieldLabels, 'SLA_Termination_right__c', opp.SLA_Termination_right__c);
        addExceptionIfPresent(exceptions, fieldLabels, 'Samsara_insolvency__c', opp.Samsara_insolvency__c);
        addExceptionIfPresent(exceptions, fieldLabels, 'Permanent_Downsize__c', opp.Permanent_Downsize__c);
        addExceptionIfPresent(exceptions, fieldLabels, 'Partial_use_seasonal__c', opp.Partial_use_seasonal__c);
        addExceptionIfPresent(exceptions, fieldLabels, 'MSA_negotiated_under_good_faith_after_or__c', opp.MSA_negotiated_under_good_faith_after_or__c);
        addExceptionIfPresent(exceptions, fieldLabels, 'Termination_for_convenience__c', opp.Termination_for_convenience__c);
        addExceptionIfPresent(exceptions, fieldLabels, 'Termination_for_lack_of_appropriation_of__c', opp.Termination_for_lack_of_appropriation_of__c);
        addExceptionIfPresent(exceptions, fieldLabels, 'Temporary_Suspension__c', opp.Temporary_Suspension__c);
        addExceptionIfPresent(exceptions, fieldLabels, 'Extended_returns_beyond_30_days__c', opp.Extended_returns_beyond_30_days__c);
        addExceptionIfPresent(exceptions, fieldLabels, 'Price_lock_language_for_add_on_orders__c', opp.Price_lock_language_for_add_on_orders__c);
        addExceptionIfPresent(exceptions, fieldLabels, 'Non_Standard_terms_description__c', opp.Non_Standard_terms_description__c);
        addExceptionIfPresent(exceptions, fieldLabels, 'Price_stability_for_renewal__c', opp.Price_stability_for_renewal__c);

        if(!exceptions.isEmpty()) {
            results.add(new OpportunityWrapper(
                opp.Id,
                opp.Account.Name,
                opp.Name,
                contractNumber,
                contractId,
                exceptions,
                oppOwnerName,
                oppOwnerUrl
            ));
        }
    }
    
    private static void addExceptionIfPresent(Map<String,FieldWrapper> exceptions, Map<String,String> fieldLabels, 
                                            String fieldName, String value) {
                                                   
        if(String.isNotBlank(value) && value != 'not requested') {
            exceptions.put(fieldName, new FieldWrapper(fieldLabels.get(fieldName), value));
        }
    }
    
    public class OpportunityWrapper {
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public String contractNumber;
        @AuraEnabled public Id contractId;
        @AuraEnabled public Map<String,FieldWrapper> exceptions;
        @AuraEnabled public String opportunityOwnerName;
        @AuraEnabled public String opportunityOwnerUrl;

        
        public OpportunityWrapper(Id oppId,String accName, String oppName,String contractNumber, Id contractId, Map<String,FieldWrapper> excp,String oppOwnerName,String oppOwnerUrl) {
            this.opportunityId = oppId;
            this.accountName = accName;
            this.opportunityName = oppName;
            this.contractNumber = contractNumber;
            this.contractId = contractId;
            this.exceptions = excp;
            this.opportunityOwnerName = oppOwnerName; 
            this.opportunityOwnerUrl = oppOwnerUrl; 
        }
    }

    public class FieldWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public Object value;
        
        public FieldWrapper(String label, Object value) {
            this.label = label;
            this.value = value; 
        }
    }
}