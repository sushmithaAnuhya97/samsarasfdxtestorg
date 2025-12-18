public with sharing class QuoteLineC360Controller {
    // DTO for returning quote line data to LWC
    public class QuoteLineC360DTO {
        @AuraEnabled public String productCode;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal mup;
        @AuraEnabled public Decimal c360Discount;
    }



    /**
     * Returns quote line data for a given Quote Id
     * @param quoteId Id of the SBQQ__Quote__c
     * @return List of QuoteLineC360DTO
     */
    @AuraEnabled(cacheable=true)
    public static List<QuoteLineC360DTO> getQuoteLines(Id quoteId) {
        List<QuoteLineC360DTO> result = new List<QuoteLineC360DTO>();
        try {
            // Get approval rules for the quote
            List<SBAA__Approval__c> approvals = SBAA.ApprovalAPI.preview(quoteId, SBAA__Approval__c.Quote__c);
            Set<Id> ruleIds = new Set<Id>();
            
            for (SBAA__Approval__c approval : approvals) {
                ruleIds.add(approval.sbaa__Rule__c);
            }
            
            // Get approval rules and check for custom label
            Map<Id, sbaa__ApprovalRule__c> approvalRuleMap = new Map<Id, sbaa__ApprovalRule__c>(
                [SELECT Id, sbaa__ApprovalStep__c, Name FROM sbaa__ApprovalRule__c WHERE Id IN :ruleIds ORDER BY sbaa__ApprovalChain__c]
            );
            
            // Check if any rule contains keywords from custom label
            Boolean hasDiscountApprovalRule = false;
            String discountApprovalKeywords = System.Label.C360_Approval_Rule_Keywords;
            
            // Only process if keywords exist and are not empty
            if (String.isNotBlank(discountApprovalKeywords)) {
                String[] keywords = discountApprovalKeywords.toLowerCase().split('[,;]');
                
                for (sbaa__ApprovalRule__c rule : approvalRuleMap.values()) {
                    for (String keyword : keywords) {
                        keyword = keyword.trim(); // Remove any spaces
                        // Skip empty keywords
                        if (String.isNotBlank(keyword) && rule.Name != null && 
                            rule.Name.toLowerCase().contains(keyword)) {
                            hasDiscountApprovalRule = true;
                            break;
                        }
                    }
                    if (hasDiscountApprovalRule) break;
                }
            }
            
            // Only process QLIs if approval rules exist
            if (hasDiscountApprovalRule) {
                for (SBQQ__QuoteLine__c ql : [
                    SELECT SBQQ__ProductCode__c, SBQQ__Product__r.Name, Monthly_Unit_Price__c, C360_MUP__c, LineItem_type__c
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c = :quoteId
                ]) {
                    // Only show Upsell lines (only ones that get proper C360 discount evaluation)
                    // Skip bundle products and non-upsell lines
                    if ((ql.SBQQ__ProductCode__c != null && ql.SBQQ__ProductCode__c.toUpperCase().contains('BUNDLE')) ||
                        ql.LineItem_type__c != 'Upsell') {
                        continue;
                    }
                   // Check if this specific QLI exceeds C360 threshold
                    if (ql.C360_MUP__c != null && ql.Monthly_Unit_Price__c < ql.C360_MUP__c) {
                        QuoteLineC360DTO dto = new QuoteLineC360DTO();
                        dto.productCode = ql.SBQQ__ProductCode__c;
                        dto.productName = ql.SBQQ__Product__r != null ? ql.SBQQ__Product__r.Name : null;
                        //dto.discount = ql.SBQQ__Discount__c != null ? ql.SBQQ__Discount__c / 100 : null;
                        //dto.c360Discount = ql.C360_Discount__c != null ? ql.C360_Discount__c / 100 : null;
                        dto.mup = ql.Monthly_Unit_Price__c != null ? ql.Monthly_Unit_Price__c : null;
                        dto.c360Discount = ql.C360_MUP__c != null ? ql.C360_MUP__c  : null;
                       
                        result.add(dto);
                    }
                }
            }
        } catch (Exception e) {
            // Log error if needed, but return empty list to avoid blocking flow
        }
        return result;
    }
}