public class BillingAddressPicklistUtil {
     private static Map<String, String> countryMap;
     private static Map<String, String> stateMap;
    /**
     * @description Get all billing country codes and their labels
     * @return Map<String, String> Map of country codes to country names
     */

    private static void populateBillingCountries() {
        countryMap = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Account.BillingCountryCode.getDescribe();
        List<Schema.PicklistEntry> countries = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry entry : countries) {
            countryMap.put(entry.getLabel().toLowerCase(),entry.getValue());
        }
    }
    
    /**
     * @description Get all billing state codes and their labels
     * @return Map<String, String> Map of state codes to state names
     */
    private static void populateBillingStates() {
        stateMap = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Account.BillingStateCode.getDescribe();
        List<Schema.PicklistEntry> states = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry entry : states) {
            stateMap.put(entry.getLabel().toLowerCase(),entry.getValue());
        }
    }
    
    /**
     * @description Get country code by providing full country name
     * @param countryName The full name of the country (e.g., 'United States')
     * @return String The country code (e.g., 'US')
     * @throws TriggerHandler.TriggerHandlerException if countryName is null, blank or invalid
     */
    public static String getBillingCountryCode(String countryName) {

       
        if(String.isBlank(countryName?.trim())) { return null; }

         if(countryMap == null){ populateBillingCountries(); }

        String trimmedCountryName = countryName?.trim();

        return countryMap.get(trimmedCountryName.toLowerCase());
    }
    
    /**
     * @description Get state code by providing full state name
     * @param stateName The full name of the state (e.g., 'California')
     * @return String The state code (e.g., 'CA')
     * @throws TriggerHandler.TriggerHandlerException if stateName is null, blank or invalid
     */
    public static String getBillingStateCode(String stateName) {
       
        if(String.isBlank(stateName?.trim())) { return null;}

         if(stateMap == null){ populateBillingStates(); }
        
        String trimmedStateName = stateName?.trim();
        
        return stateMap.get(trimmedStateName.toLowerCase());
    }
}