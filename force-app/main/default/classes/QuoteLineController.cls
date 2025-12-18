public class QuoteLineController {
    
    public class QuoteLineResponse {
        @AuraEnabled public Boolean showAlert;
        
        public QuoteLineResponse(Boolean alert) {
            this.showAlert = alert;
        }
    }
    @AuraEnabled
    public static QuoteLineResponse getQuoteLinesByQuoteId(String quoteId) {
        try {
            if (String.isBlank(quoteId)) {
                throw new AuraHandledException('Quote ID cannot be empty');
            }
            
            String multiCamProductCodes = System.Label.MultiCam_Product_Codes;
            
            Set<String> multiCamCodesSet = new Set<String>();
            
            if (String.isNotBlank(multiCamProductCodes)) {
                for (String code : multiCamProductCodes.split(',')) {
                    multiCamCodesSet.add(code.trim());
                }
            }
            
            List<SBQQ__QuoteLine__c> relevantQuoteLines = [SELECT Id, SBQQ__Quote__c,SBQQ__ProductCode__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteId 
                                                          AND (SBQQ__ProductCode__c IN :multiCamCodesSet OR SBQQ__ProductCode__c LIKE '%VG55%' OR SBQQ__ProductCode__c LIKE '%VG54%')];
            
            Boolean hasMultiCamProduct = false;
            Boolean hasVG55VG54Product = false;
            
            for (SBQQ__QuoteLine__c line : relevantQuoteLines) {
                String productCode = line.SBQQ__ProductCode__c;
                
                if (!hasMultiCamProduct && !multiCamCodesSet.isEmpty() && multiCamCodesSet.contains(productCode)) {
                    hasMultiCamProduct = true;
                }
                
                if (!hasVG55VG54Product && (productCode.contains('VG55') || productCode.contains('VG54'))) {
                    hasVG55VG54Product = true;
                }
                
                if (hasMultiCamProduct && hasVG55VG54Product) {
                    break;
                }
            }
            
            Boolean showAlert = hasMultiCamProduct && !hasVG55VG54Product;
            return new QuoteLineResponse(showAlert);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving quote lines: ' + e.getMessage());
        }
    }
}