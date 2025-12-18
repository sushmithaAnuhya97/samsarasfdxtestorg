public class OrderAutomationService extends OpportunityHelperContext {
    
    public static boolean validatePoBox(Opportunity opp){
        
        If(String.isEmpty(opp.Concatenated_Shipping_Address__c)) {
            return true;
        }
        String address = opp.Concatenated_Shipping_Address__c.replace('_BR_ENCODED_', '<br>');
        Set<String> emeaShippingCountryList = new Set<String>(System.Label.EMEA_SHIPPING_COUNTRIES.split(','));
        If(opp.Shipping_Country__c == 'Mexico' || emeaShippingCountryList.contains(opp.Shipping_Country__c)) {
            return false;
        }
        String regex = '(?si).*\\b(p\\.?\\s*o\\.?\\s*|.*post\\s+office)\\s+box.*';
        If(opp.Shipping_Country__c == 'Canada') {
            regex = '(?si).*\\bbox\\b.*';
        }
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(address);
        return matcher.matches();
    }

    public static Boolean satisfyShipFromLocation(Opportunity opp) {
        Set<String> emeaShippingCountryList = new Set<String>(System.Label.EMEA_SHIPPING_COUNTRIES.split(','));
        List<String> usShipFromLoc = OrderFinanceSetting__mdt.getInstance('US_Ship_From_Location').value__c.split(',');
        String canadaShipFromLoc = OrderFinanceSetting__mdt.getInstance('Canada_Ship_From_Location').value__c;
        String mexicoShipFromLoc = OrderFinanceSetting__mdt.getInstance('Mexico_Ship_From_Location').value__c;
        String emeaShipFromLoc = OrderFinanceSetting__mdt.getInstance('EMEA_Ship_From_Location').value__c;
        If((opp.Shipping_Country__c == 'United States' && usShipFromLoc.contains(opp.Ship_From_Location__c))
           || (opp.Shipping_Country__c == 'Canada' && canadaShipFromLoc == opp.Ship_From_Location__c)
           || (opp.Shipping_Country__c == 'Mexico' && mexicoShipFromLoc == opp.Ship_From_Location__c)
           || (emeaShippingCountryList.contains(opp.Shipping_Country__c) && emeaShipFromLoc == opp.Ship_From_Location__c)) 
        {
            return true;
        }
        return false;
    }
    
    public static List<String> getProductCodesByCountryAndType(String shippingCountry, String oppType) {
        List<String> productCodes = new List<String>();
        List<String> emeaShippingCountryList = System.Label.EMEA_SHIPPING_COUNTRIES.split(',');
        Boolean isUS = (shippingCountry == 'United States');
        Boolean isCanada = (shippingCountry == 'Canada');
        Boolean isMexico = (shippingCountry == 'Mexico');
        Boolean isEMEA = emeaShippingCountryList.contains(shippingCountry);
        
        switch on oppType {
            when 'Free Trial Opportunity' {
                if (isUS) {
                    productCodes.addAll(System.Label.US_FT_Revenue_SKU_List_1.split(','));
                    productCodes.addAll(System.Label.US_FT_Revenue_SKU_List_2.split(','));
                    productCodes.addAll(System.Label.US_FT_Revenue_SKU_List_3.split(','));
                    productCodes.addAll(System.Label.US_FT_Revenue_SKU_List_4.split(','));
                    productCodes.addAll(System.Label.US_FT_Revenue_SKU_List_5.split(','));
                } else if (isCanada) {
                    productCodes.addAll(System.Label.Canada_FT_Revenue_SKU_List_1.split(','));
                    productCodes.addAll(System.Label.Canada_FT_Revenue_SKU_List_2.split(','));
                    productCodes.addAll(System.Label.Canada_FT_Revenue_SKU_List_3.split(','));
                    productCodes.addAll(System.Label.Canada_FT_Revenue_SKU_List_4.split(','));
                    productCodes.addAll(System.Label.Canada_FT_Revenue_SKU_List_5.split(','));
                } else if (isEMEA) {
                    productCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU.split(','));
                    productCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_1.split(','));
                    productCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_2.split(','));
                    productCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_3.split(','));
                    productCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_4.split(','));
                } else if (isMexico) {
                    productCodes.addAll(System.Label.Mexico_SKU_Product_for_Revenue.split(','));
                    productCodes.addAll(System.Label.Mexico_SKU_Products_for_Revenue_1.split(','));
                    productCodes.addAll(System.Label.Mexico_SKU_Products_for_Revenue_2.split(','));
                    productCodes.addAll(System.Label.Mexico_SKU_Products_for_Revenue_3.split(','));
                }
            }
            when 'Promo Opportunity' {
                if (isUS) {
                    productCodes.addAll(System.Label.US_Promo_SKU_List_1.split(','));
                    productCodes.addAll(System.Label.US_Promo_SKU_List_2.split(','));
                } else if(isCanada) {
                    productCodes.addAll(System.Label.Canada_Promo_SKU_List_1.split(','));
                    productCodes.addAll(System.Label.Canada_Promo_SKU_List_2.split(','));
                } else if (isEMEA) {
                    productCodes.addAll(System.Label.VCK_EMEA_Promo_SKU.split(','));
                    productCodes.addAll(System.Label.VCK_EMEA_Promo_SKU_2.split(','));
                } else if (isMexico) {
                    productCodes.addAll(System.Label.Mexico_SKU_Product_for_Promo.split(','));
                    productCodes.addAll(System.Label.Mexico_SKU_Product_for_Promo_2.split(','));
                }
            }
            when 'Revenue Opportunity' {
                if (isUS) {
                    productCodes.addAll(System.Label.US_FT_Revenue_SKU_List_1.split(','));
                    productCodes.addAll(System.Label.US_FT_Revenue_SKU_List_2.split(','));
                    productCodes.addAll(System.Label.US_FT_Revenue_SKU_List_3.split(','));
                    productCodes.addAll(System.Label.US_FT_Revenue_SKU_List_4.split(','));
                    productCodes.addAll(System.Label.US_FT_Revenue_SKU_List_5.split(','));
                } else if(isCanada) {
                    productCodes.addAll(System.Label.Canada_FT_Revenue_SKU_List_1.split(','));
                    productCodes.addAll(System.Label.Canada_FT_Revenue_SKU_List_2.split(','));
                    productCodes.addAll(System.Label.Canada_FT_Revenue_SKU_List_3.split(','));
                    productCodes.addAll(System.Label.Canada_FT_Revenue_SKU_List_4.split(','));
                    productCodes.addAll(System.Label.Canada_FT_Revenue_SKU_List_5.split(','));
                } else if (isEMEA) {
                    productCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU.split(','));
                    productCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_1.split(','));
                    productCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_2.split(','));
                    productCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_3.split(','));
                    productCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_4.split(','));
                } else if (isMexico) {
                    productCodes.addAll(System.Label.Mexico_SKU_Product_for_Revenue.split(','));
                    productCodes.addAll(System.Label.Mexico_SKU_Products_for_Revenue_1.split(','));
                    productCodes.addAll(System.Label.Mexico_SKU_Products_for_Revenue_2.split(','));
                    productCodes.addAll(System.Label.Mexico_SKU_Products_for_Revenue_3.split(','));
                }
            }
            when else {
                // No action for other types
            }
        }
        return productCodes;
    }
    
    public static Boolean satisfyRevenueOwnerSegmentConditions(Opportunity opp) {
        return (opp.Owner_Segment__c == 'SMB' || opp.Owner_Segment__c == 'Small business');
    }
               
    public static Boolean satisfyRevenueAE1Conditions(Opportunity opp) {
        return (opp.Segment_Sales_Role__c == 'AE1' && opp.Free_Trial_Purchase__c == null);
    }
    
    public static Boolean satisfyRevenueAe2Ae3EntConditions(Opportunity opp) {
        return ((opp.Segment_Sales_Role__c == 'AE2' || opp.Segment_Sales_Role__c == 'AE3' || opp.Segment_Sales_Role__c == 'Enterprise') 
                && (opp.name.contains('Webstore') ? (opp.Free_Trial_Purchase__c == NULL) : (opp.Free_Trial_Purchase__c == 'No Purchase')) 
                && ((opp.CurrencyIsoCode == 'USD' || opp.CurrencyIsoCode == 'CAD') && opp.Amount < Decimal.valueOf(System.Label.US_Canada_EMEA_Amount_Threshold)));
    }
    
    public static Boolean satisfyCurrencyISOCode(Opportunity opp) {
        Set<String> emeaShippingCountryList = new Set<String>(System.Label.EMEA_SHIPPING_COUNTRIES.split(','));
        String usCurrencyIsoCode = OrderFinanceSetting__mdt.getInstance('US_CurrencyISOCode').value__c;
        String canadaCurrencyIsoCode = OrderFinanceSetting__mdt.getInstance('Canada_CurrencyISOCode').value__c;
        String mexicoCurrencyIsoCode = OrderFinanceSetting__mdt.getInstance('Mexico_CurrencyISOCode').value__c;
        List<String> emeaCurrencyIsoCode = OrderFinanceSetting__mdt.getInstance('Emea_CurrencyISOCode').value__c.split(',');
        
        If((opp.Shipping_Country__c == 'United States' && opp.CurrencyISOCode == usCurrencyIsoCode)
           || (opp.Shipping_Country__c == 'Canada' && opp.CurrencyISOCode == canadaCurrencyIsoCode)
           || (opp.Shipping_Country__c == 'Mexico' && opp.CurrencyISOCode == mexicoCurrencyIsoCode)
           || (emeaShippingCountryList.contains(opp.Shipping_Country__c) && emeaCurrencyIsoCode.contains(opp.CurrencyISOCode)))
        {
            return true;
        }
        return false;
    }
    
}