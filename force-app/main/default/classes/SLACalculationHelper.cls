/**********************************************************************
Name: SLACalculationHelper
=======================================================================
Purpose: This class will logic to related to partner registration functionality                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Aug-25        INITIAL DEVELOPMENT for GTMS-28939

**********************************************************************/
public class SLACalculationHelper {
    private Map<String, SLA_Holiday__c> holidayMap = new Map<String, SLA_Holiday__c>();
    /* constructor */
    public SLACalculationHelper(set<string> countryCodeList) {
        // Query holiday data
        List<SLA_Holiday__c > holidayList = [SELECT Id, Holiday_Date__c, Holiday_Name__c FROM SLA_Holiday__c 
                                             WHERE Country__c IN: countryCodeList
                                             ORDER BY Holiday_Date__c DESC LIMIT 1000];
        
        for (SLA_Holiday__c each : holidayList) {
            holidayMap.put(each.Holiday_Date__c.format(),each);
        }
        
    }
    
    /* calculates the SLA End date base of the input parameter */
    public datetime calculateSLADueDate(string SLADays, datetime SLAStartDateTime) {
        datetime SLADateTime = SLAStartDateTime;
        Integer addedDays = 0;
       
        if (SLADays==null || SLAStartDateTime==null) return null;
        
        while (addedDays < Integer.valueOf(SLADays)) {
            SLADateTime = SLADateTime.addDays(1);
            if (SLADateTime.format('E') != 'Sat' && SLADateTime.format('E') != 'Sun' && !holidayMap.containsKey(SLADateTime.date().format())) {
                addedDays++;
            }
        }
        
        return SLADateTime;
    }
}