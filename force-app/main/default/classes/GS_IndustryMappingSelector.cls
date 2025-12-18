/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 09, 2021
*
* @description : This class will be responsible for handling all the Industry_Mapping Queries
* SFA-11
*
**/

public class GS_IndustryMappingSelector extends GS_SObjectBaseSelector{
    
    public GS_IndustryMappingSelector(boolean checkFatalError){
        super(checkFatalError);
    }
    
    public GS_IndustryMappingSelector checkFatalError(){
        return (GS_IndustryMappingSelector) super.validateFatalError();
    }
    
    
    public Map<String, Industry_Mapping__c> getIndustryMapping(){
        map<String, Industry_Mapping__c> industryMapByString = new map<String, Industry_Mapping__c>();
        for(Industry_Mapping__c objIM : [Select Id, X2017_NAICS_Code__c, Samsara_Industry_Mapping__c from Industry_Mapping__c]){
            industryMapByString.put(objIM.X2017_NAICS_Code__c, objIM);
        }
        return industryMapByString;
    }
}