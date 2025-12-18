public class OrderAutomationLoggingService {
    
    public static void evaluateAutomationErrors(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        
        For(Opportunity oppRec : newOppList) {
            If(oppRec.stagename == 'Orders Processing' && oppRec.stagename != oldOppMap.get(oppRec.Id).stageName
               && (oppRec.type == 'Revenue Opportunity'
                   || oppRec.type == 'Free Trial Opportunity'
                   || oppRec.type == 'Promo Opportunity'))
            {
                Set<String> fieldErrorList = new Set<String>();
                
                String errorTextValue = '';
                
                errorTextValue += populateOppTypeAndRegion(oppRec);
                populateCommonConditionLogs(oppRec, fieldErrorList);
                
                Set<String> emeaShippingCountryList = new Set<String>(System.Label.EMEA_SHIPPING_COUNTRIES.split(','));
                
                If(oppRec.type == 'Revenue Opportunity') {
                    
                    If(oppRec.Shipping_Country__c == 'United States' || oppRec.Shipping_Country__c == 'Canada') {
                        populateRevenueUSCadLogs(oppRec, fieldErrorList);
                    }
                    If(oppRec.Shipping_Country__c == 'Mexico') {
                        populateRevenueMexicoLogs(oppRec, fieldErrorList);
                    }
                    If(emeaShippingCountryList.contains(oppRec.Shipping_Country__c)) {
                        populateRevenueEMEALogs(oppRec, fieldErrorList);
                    }
                }
                If(oppRec.type == 'Free Trial Opportunity') {
                    If(oppRec.Shipping_Country__c == 'United States' || oppRec.Shipping_Country__c == 'Canada' || oppRec.Shipping_Country__c == 'Mexico' || emeaShippingCountryList.contains(oppRec.Shipping_Country__c)) 
                    {
                        populateFreeTrialUSCadMxnEmeaLogs(oppRec, fieldErrorList);
                    }
                }
                If(oppRec.type == 'Promo Opportunity') {
                    If(oppRec.Shipping_Country__c == 'United States' || oppRec.Shipping_Country__c == 'Canada' || oppRec.Shipping_Country__c == 'Mexico' || emeaShippingCountryList.contains(oppRec.Shipping_Country__c)) 
                    {
                        populatePromoUsCadMxnEmeaLogs(oppRec, fieldErrorList);
                    }
                }
                if(!fieldErrorList.isEmpty()) {
                    String errorListString = String.join(fieldErrorList,', ');
                    
                    oppRec.Automation_Notes__c = errorListString == null ? null : (errorListString.length() < 255 ? errorListString : ((errorListString.substring(0, 255).lastIndexOf(',') >= 0) ? errorListString.substring(0, errorListString.substring(0, 255).lastIndexOf(',')) : ''));
                    LOGGER.atInfo().setCLassName('OrderAutomationLoggingService').setMethod('evaluateAutomationErrors').setRecordId(oppRec.Id).setExceptionOrMessage(populateOppTypeAndRegion(oppRec) + errorListString);
                }
            }
        }
        Logger.setFunctionalityType('Order Automation Error Logging'); 
        Logger.insertMasterLogs(); 
    }
    
    public static void populateCommonConditionLogs(Opportunity opp, Set<String>  fieldErrorList) {
        If(!String.isBlank(opp.Shipping_Instructions__c)) {
            fieldErrorList.add('Shipping Instructions should be blank');
        }
        If(!String.isBlank(opp.Internal_RFO_Notes__c)) {
            fieldErrorList.add('Internal RFO Notes should be blank');
        }
        If(opp.Hold_Reason__c != null) {
            fieldErrorList.add('Hold Reason should be null');
        }
        If(opp.Price_Book_Name__c != 'Samsara FY22') {
            fieldErrorList.add('Price Book Name should be Samsara FY22');
        }
        If(!OrderAutomationService.satisfyShipFromLocation(opp)) {
            fieldErrorList.add('Invalid Ship From Location');
        }
        If(OrderAutomationService.validatePoBox(opp)) {
            fieldErrorList.add('Invalid Concatenated Shipping Address');
        }
    }
    
    public static void populateRevenueUsCadLogs(Opportunity opp, Set<String> fieldErrorList) {
        If(!String.isBlank(opp.Order_Ops_Notes__c)) {
            fieldErrorList.add('Order Ops Notes should be blank');
        }
        If(opp.Shipping_and_Handling__c == null || opp.Shipping_and_Handling__c >= 99999) {
            fieldErrorList.add('Invalid Shipping & Handling');
        }
        If(opp.Sub_Type__c == 'Virtual Return') {
            fieldErrorList.add('Sub Type is virtual return');
        }
        If(!OrderAutomationService.satisfyCurrencyISOCode(opp) ) {
            fieldErrorList.add('Invalid CurrencyISOCode');
        }
        If(opp.Owner_Segment__c != 'SMB' && opp.Owner_Segment__c != 'Small business' 
           && opp.Segment_Sales_Role__c != 'AE1' && opp.Segment_Sales_Role__c != 'AE2' && opp.Segment_Sales_Role__c != 'AE3' 
           && opp.Segment_Sales_Role__c != 'Enterprise') 
        {
            fieldErrorList.add('Invalid Owner Segment/Segment Sales Role');
        } 
        else If(!OrderAutomationService.satisfyRevenueOwnerSegmentConditions(opp) 
           && !OrderAutomationService.satisfyRevenueAE1Conditions(opp) 
           && !OrderAutomationService.satisfyRevenueAe2Ae3EntConditions(opp)) 
        {
            fieldErrorList.add('Owner Segment/Segment Sales Role conditions not satisfied');
        }
    }
    
    public static void populateRevenueMexicoLogs(Opportunity opp, Set<String> fieldErrorList) {
        If(opp.Segment_Sales_Role__c != 'AE2' && opp.Segment_Sales_Role__c != 'Enterprise') {
            fieldErrorList.add('Segment Sales Role should be AE2 or Enterprise');
        }
        If(opp.name.contains('Webstore') ? (opp.Free_Trial_Purchase__c != NULL) : (opp.Free_Trial_Purchase__c != 'No Purchase')) {
            fieldErrorList.add('Invalid Free Trial Purchase');
        }
        If(opp.Amount >= Decimal.valueOf(System.Label.Mexico_Amount_Threshold)) {
            fieldErrorList.add('Amount should be less than ' + System.Label.Mexico_Amount_Threshold);
        }
        If(!OrderAutomationService.satisfyCurrencyISOCode(opp) ) {
            fieldErrorList.add('Invalid CurrencyISOCode');
        }
    }
    
    public static void populateRevenueEmeaLogs(Opportunity opp, Set<String> fieldErrorList) {
        If(!String.isBlank(opp.Order_Ops_Notes__c)) {
            fieldErrorList.add('Order Ops Notes should be blank');
        }
        If(opp.Shipping_and_Handling__c == null || opp.Shipping_and_Handling__c >= 99999) {
            fieldErrorList.add('Invalid Shipping & Handling');
        }
        If(opp.Sub_Type__c == 'Virtual Return') {
            fieldErrorList.add('Sub Type is virtual return');
        }
        If(opp.Segment_Sales_Role__c != 'AE2' && opp.Segment_Sales_Role__c != 'AE3' && opp.Segment_Sales_Role__c != 'Enterprise') {
            fieldErrorList.add('Invalid Segment Sales Role');
        }
        If((opp.name.contains('Webstore') ? (opp.Free_Trial_Purchase__c != NULL) : (opp.Free_Trial_Purchase__c != 'No Purchase'))) {
            fieldErrorList.add('Invalid Free Trial Purchase');
        }
        If(opp.Amount >= Decimal.valueOf(System.Label.US_Canada_EMEA_Amount_Threshold)) {
            fieldErrorList.add('Amount shuold be less than ' + System.Label.US_Canada_EMEA_Amount_Threshold);
        }
        If(!OrderAutomationService.satisfyCurrencyISOCode(opp) ) {
            fieldErrorList.add('Invalid CurrencyISOCode');
        }
    }
    
    public static void populateFreeTrialUSCadMxnEmeaLogs(Opportunity opp, Set<String> fieldErrorList) {
        If(!String.isBlank(opp.Order_Ops_Notes__c)) {
            fieldErrorList.add('Order Ops Notes should be blank');
        }
        If((opp.Segment_Sales_Role__c != 'AE2' && opp.Segment_Sales_Role__c != 'AE3' && opp.Segment_Sales_Role__c != 'ENT' && opp.Segment_Sales_Role__c != 'Enterprise')) {
            fieldErrorList.add('Segment Sales Role should be AE2 or AE3 or Enterprise');
        }
        If((opp.Shipping_Address_NEW__c == null)) {
            fieldErrorList.add('Invalid Shipping Address');
        }
    }
    
    public static void populatePromoUsCadMxnEmeaLogs(Opportunity opp, Set<String> fieldErrorList) {
        If(opp.Sales_Tax__c != 0 && opp.Sales_Tax__c != null) {
            fieldErrorList.add('Sales Tax should be 0 or null');
        }
        If(opp.Balance_Due__c != 0 && opp.Balance_Due__c != null) {
            fieldErrorList.add('Balance Due should be 0 or null');
        }
        If(opp.Shipping_and_Handling__c != 0 && opp.Shipping_and_Handling__c != null) {
            fieldErrorList.add('Shipping and Handling should be 0 or null');
        }
        If(opp.Multi_Line_Shipping__c) {
            fieldErrorList.add('Multi Line Shipping should be false');
        }
    }
    
    public static String populateOppTypeAndRegion(Opportunity opp) {
        return 'Type:' + opp.type + ' - ' + 'Region:' + opp.Shipping_Country__c + ' - Errors:';
    }
}