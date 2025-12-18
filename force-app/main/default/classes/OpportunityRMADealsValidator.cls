/**
* @description       : This class is used to validate RMA Deals
* @author            : asha.koyya@samsara.com
* @last modified on  : 03-10-2025
* @last modified by  : asha.koyya@samsara.com
* @test class        : OpportunityRMADealsValidatorTest        
**/
/* 07/04/25 Asha Rani (GTMS-26176) For RMA (Replacement) deals- automatically add ACC-PL-MNT-MA1 with HW-PL11
*/
public class OpportunityRMADealsValidator {
    
    // Constants for product codes
    private static final String HW_PL11_PRODUCT_CODE = 'HW-PL11';
    private static final String ACCESSORY_PRODUCT_CODE = 'ACC-PL-MNT-MA1';
    private static final String PROMO_OPPORTUNITY_TYPE = 'Promo Opportunity';
    private static final String BYPASS_PERMISSION_SET = 'Validation_Rule_By_Pass';
    private static final Boolean HAS_VALIDATION_EXEMPTION = FeatureManagement.checkPermission('Validation_Rule_Exemption');
    
    /** GTMS-26176 Started **/ 
    public static void checkRMAOppHasPL1HWAndAccessories(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        
        // Early validation checks
        if (!isValidInput(newOppList, oldOppMap) || (!Test.isRunningTest() && HAS_VALIDATION_EXEMPTION) || 
            !isValidationEnforced()) {
            return;
        }
        
        // Get valid stages for processing
        Set<String> validStages = getValidStages();
        if (validStages.isEmpty()) {
            return;
        }
        
        // Load opportunity data
        OpportunityHelperContext oppHelperObj = new OpportunityHelperContext();
        oppHelperObj.loadOppFields(newOppList);
        
        // Process opportunities and validate quantities
        List<Opportunity> validOpps = getValidOpportunities(newOppList, oldOppMap, validStages);
        if (validOpps.isEmpty()) {
            return;
        }
        
        // Calculate quantities and validate
        Map<Id, Decimal> hwPl11Quantities = calculateProductQuantities(validOpps, HW_PL11_PRODUCT_CODE);
        Map<Id, Decimal> accessoryQuantities = calculateProductQuantities(validOpps, ACCESSORY_PRODUCT_CODE);
        
        // Add validation errors where quantities don't match
        validateQuantityMismatch(validOpps, hwPl11Quantities, accessoryQuantities);
    }
    
    /**
     * @description Validates input parameters
     * @param newOppList List of new opportunities
     * @param oldOppMap Map of old opportunities
     * @return Boolean indicating if inputs are valid
     */
    private static Boolean isValidInput(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        return newOppList != null && !newOppList.isEmpty() && oldOppMap != null;
    }
    
    /**
     * @description Checks if validation is enforced via custom label
     * @return Boolean indicating if validation is enforced
     */
    private static Boolean isValidationEnforced() {
        return System.Label.PPP_RMA_HW_PL11_Validation_Enforcement == 'TRUE';
    }
    
    /**
     * @description Gets valid stages from custom label
     * @return Set of valid stage names
     */
    private static Set<String> getValidStages() {
        String stageLabel = System.Label.HW_PL11_RMA_Stage;
        if (String.isBlank(stageLabel)) {
            return new Set<String>();
        }
        
        Set<String> validStages = new Set<String>();
        for (String stage : stageLabel.split(',')) {
            String trimmedStage = stage.trim();
            if (String.isNotBlank(trimmedStage)) {
                validStages.add(trimmedStage);
            }
        }
        return validStages;
    }
    
    /**
     * @description Filters opportunities based on validation criteria
     * @param newOppList List of new opportunities
     * @param oldOppMap Map of old opportunities
     * @param validStages Set of valid stage names
     * @return List of valid opportunities for processing
     */
    private static List<Opportunity> getValidOpportunities(List<Opportunity> newOppList, 
                                                          Map<Id, Opportunity> oldOppMap, 
                                                          Set<String> validStages) {
        List<Opportunity> validOpps = new List<Opportunity>();
        
        for (Opportunity opp : newOppList) {
            if (isValidOpportunity(opp, oldOppMap, validStages)) {
                validOpps.add(opp);
            }
        }
        return validOpps;
    }
    
    /**
     * @description Checks if opportunity meets validation criteria
     * @param opp Current opportunity
     * @param oldOppMap Map of old opportunities
     * @param validStages Set of valid stage names
     * @return Boolean indicating if opportunity is valid
     */
    private static Boolean isValidOpportunity(Opportunity opp, 
                                            Map<Id, Opportunity> oldOppMap, 
                                            Set<String> validStages) {
        if (opp == null || String.isBlank(opp.Name) || opp.Type != PROMO_OPPORTUNITY_TYPE 
            || String.isBlank(opp.StageName) || !validStages.contains(opp.StageName) 
            || !oldOppMap.containsKey(opp.Id) || opp.of_HW_Products__c <= 0) {
            return false;
        }
        
        Opportunity oldOpp = oldOppMap.get(opp.Id);
        if (oldOpp == null || opp.StageName == oldOpp.StageName) {
            return false;
        }
        
        // Check if opportunity has line items
        return OpportunityHelperContext.oppFields != null 
            && OpportunityHelperContext.oppFields.containsKey(opp.Id) 
            && OpportunityHelperContext.oppFields.get(opp.Id)?.OpportunityLineItems != null;
    }
    
    /**
     * @description Calculates quantities for a specific product code across opportunities
     * @param validOpps List of valid opportunities
     * @param productCode Product code to calculate quantities for
     * @return Map of opportunity ID to quantity
     */
    private static Map<Id, Decimal> calculateProductQuantities(List<Opportunity> validOpps, String productCode) {
        Map<Id, Decimal> quantities = new Map<Id, Decimal>();
        
        for (Opportunity opp : validOpps) {
            if (OpportunityHelperContext.oppFields.get(opp.Id)?.OpportunityLineItems != null) {
                for (OpportunityLineItem oli : OpportunityHelperContext.oppFields.get(opp.Id).OpportunityLineItems) {
                    if (isValidLineItem(oli) && oli.ProductCode == productCode) {
                        Id oppId = oli.OpportunityId;
                        quantities.put(oppId, (quantities.get(oppId) ?? 0) + oli.Quantity);
                    }
                }
            }
        }
        return quantities;
    }
    
    /**
     * @description Validates if line item meets criteria
     * @param oli Opportunity line item
     * @return Boolean indicating if line item is valid
     */
    private static Boolean isValidLineItem(OpportunityLineItem oli) {
        return oli != null && String.isNotBlank(oli.ProductCode) && oli.Quantity != null && oli.Quantity >= 1;
    }
    
    /**
     * @description Validates quantity mismatch and adds errors to opportunities
     * @param validOpps List of valid opportunities
     * @param hwPl11Quantities Map of HW-PL11 quantities
     * @param accessoryQuantities Map of accessory quantities
     */
    private static void validateQuantityMismatch(List<Opportunity> validOpps, 
                                               Map<Id, Decimal> hwPl11Quantities, 
                                               Map<Id, Decimal> accessoryQuantities) {
        for (Opportunity opp : validOpps) {
            if (hwPl11Quantities.containsKey(opp.Id)) {
                Decimal accQuantity = accessoryQuantities.get(opp.Id) ?? 0;
                Decimal hwPl11Quantity = hwPl11Quantities.get(opp.Id);
                
                if (hwPl11Quantity != accQuantity) {
                    addValidationError(opp);
                }
            }
        }
    }
    
    /**
     * @description Adds validation error to opportunity
     * @param opp Opportunity to add error to
     */
    private static void addValidationError(Opportunity opp) {
        String errorMessage = System.Label.HW_PL11_RMA_Error_Message;
        if (String.isNotBlank(errorMessage)) {
            opp.addError(errorMessage);
        }
    }
    /** GTMS-26176 Ended **/
}