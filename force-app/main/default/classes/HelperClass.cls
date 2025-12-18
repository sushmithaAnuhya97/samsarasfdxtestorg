/*
 * 4/02/20 Harsha - (GTMS-713): isChanged (Created this method to be used across the board) 
 * 5/18/20 Harsha - (GTMS-877) quoteAfterUpdateRecursionCheck (Recursion check for quote after updates)
 * 5/19/20 Tommy/Harsha - (GTMS-84, 650) queryShippingCountryDefaults, setShippingDefaults, getShippingData (Centrailized Shipping Methods)
 * 7/11/20 Harsha - (GTMS-1307) deleted udlRun variable
 */

public class HelperClass {
    public static boolean firstRun = true;
    public static boolean unloadContactQueryFlag = false; 
    // After speaking to the stakeholders it looks to be that this list wont be changing frequently or in near future, so going with this instead of using custom metadata.
    public static  Set<String> euCountryCodes = new Set<String>{'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE',
        'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 
        'RO', 'SK', 'SI', 'ES', 'SE', 'GB', 'GF', 'GP', 'MQ', 'ME', 'YT', 
        'RE', 'MF', 'GI', 'AX', 'PM', 'GL', 'BL', 'SX', 'AW', 'CW', 'WF',
        'PF', 'NC', 'TF', 'AI', 'BM', 'IO', 'VG', 'KY', 'FK', 'MS', 'PN', 
        'SH', 'GS', 'TC', 'AD', 'LI', 'MC', 'SM', 'VA', 'JE', 'GG', 'GI', 'CH'};
    public Static Trigger_Setting__mdt contactTriggerPlug;
    public Static Trigger_Setting__mdt opportunityAuditTriggerPlug;
    //Static variable to make sure ReturnLabelEmailer sends out the emails only once. 
    //Since we could not restrict the method in the trigger handler.  -@Harsha/SS-124
    public Static Set<Id>  recursionCheckForReturnOpps = new Set<Id>(); 
    public static Boolean quoteAfterUpdateRecursionCheck = false;
    public static Map<String,Shipping_Countries__mdt> shippingCountryDefaults = new map<String, Shipping_Countries__mdt>();
    public static Map<Id, Shipping_Address__c> opportunityShippingAddresses = new map<Id, Shipping_Address__c>();
    
    public static Boolean isChanged(Opportunity newOpportunity, Opportunity oldOpportunity, Schema.SObjectField field){
        if(oldOpportunity == null){
            return true;
        }else if(newOpportunity.get(field) != oldOpportunity.get(field)){
            return true;
        }else{
            return false;
        }
    }

    public static Integer calculateWorkingDays(Date startDate, Date endDate) {          
         
        Integer workingDays = 0;  
        for(integer i=0; i < startDate.daysBetween(endDate); i++) {  
            Date dt = startDate + i;  
            DateTime currDate = DateTime.newInstance(dt.year(), dt.month(), dt.day());  
            String todayDay = currDate.format('EEEE');  
            if(todayDay != 'Saturday' && todayDay !='Sunday')  
                {  
                    workingDays = workingDays + 1;  
                }     
        }  
        return workingDays;  
    }
    
     public static String getGlobalValue(String developerName) {
        Map<String, String> valueByKey = new Map<String, String>();
        Global_Variable__mdt globalVariable = [
                SELECT DeveloperName, Value__c
                FROM Global_Variable__mdt
                WHERE DeveloperName = :developerName
        ];
        return globalVariable.Value__c;
    }
     
    public static void queryShippingCountryDefaults(){
        List <Shipping_Countries__mdt> shippingCountries = [SELECT MasterLabel, Region__c, Ship_From_Location__c,
                                                           Shipping_Carrier__c, Shipping_Method__c, Country__c
                                                           FROM Shipping_Countries__mdt]; 
        for (Shipping_Countries__mdt shippingCountry : shippingCountries){
            shippingCountryDefaults.put(shippingCountry.MasterLabel, shippingCountry);
        }     
    }
    
    public static void setShippingDefaults(Opportunity o, SBQQ__Quote__c quote, string ShippingCountry){
        if (shippingCountryDefaults.isEmpty()){
            queryShippingCountryDefaults();
        }
        if (quote == NULL){
            if (ShippingCountry != NULL && (shippingCountryDefaults.containsKey(ShippingCountry))){
                    o.Shipping_Carrier__c   = shippingCountryDefaults.get(ShippingCountry).Shipping_Carrier__c;
                    if(Trigger.isUpdate || Trigger.isInsert)
                        o.Shipping_Method__c = shippingCountryDefaults.get(ShippingCountry).Shipping_Method__c;
                        o.Ship_From_Location__c = shippingCountryDefaults.get(ShippingCountry).Ship_From_Location__c;
                }
            }
        else if (o == NULL){
            if (ShippingCountry != NULL && (shippingCountryDefaults.containsKey(ShippingCountry))){
                quote.Shipping_Carrier__c   = shippingCountryDefaults.get(ShippingCountry).Shipping_Carrier__c;
                if((ShippingCountry != 'United States' && Trigger.isUpdate) || Trigger.isInsert)
                    quote.Shipping_Method__c = shippingCountryDefaults.get(ShippingCountry).Shipping_Method__c;
                quote.Ship_From_Location__c = shippingCountryDefaults.get(ShippingCountry).Ship_From_Location__c;
            }
        }       
    }
    
    public static Map<Id, Shipping_Address__c> getShippingData(Set<Id> shippingIds){
        Map<Id, Shipping_Address__c> shippingData = new Map<Id, Shipping_Address__c>([SELECT Id, Name, Shipping_State__c, Shipping_City__c, Shipping_Country__c,
                                                             Shipping_Address_Line_1__c, Shipping_Zip_Code__c
                                                             FROM Shipping_Address__c WHERE ID IN : shippingIds]);
         return shippingData;    
    }
    //Zakeer:GTMS5381-Jan13-added below for Products-ShipFromLocation
    public static void setShippingDefaultsProducts(OpportunityLineItem item,  String ShippingCountry){
        if (shippingCountryDefaults.isEmpty()){
            queryShippingCountryDefaults();
        }
            if (ShippingCountry != NULL && (shippingCountryDefaults.containsKey(ShippingCountry))){
                    //item.Shipping_Carrier__c   = shippingCountryDefaults.get(ShippingCountry).Shipping_Carrier__c;
                    if(Trigger.isInsert || Trigger.isUpdate )
                        //item.Shipping_Method__c = shippingCountryDefaults.get(ShippingCountry).Shipping_Method__c;
                        item.Ship_From_Location__c = shippingCountryDefaults.get(ShippingCountry).Ship_From_Location__c;
            }     
    }
}