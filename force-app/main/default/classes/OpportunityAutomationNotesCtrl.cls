/**
* @description       : This class is used to populate Automation Notes for Opportunity
* @author            : Shashank P
* @group             :
* @last modified on  : 03-11-2025
* @last modified by  : Shashank P
**/
public class OpportunityAutomationNotesCtrl {
    
    private static final String WIFIPRODUCTV1 = 'WIFI';
    private static final String WIFIPRODUCTV2 = 'WI-FI';
    private static final String WIFISKU = 'WIFI SKU';
    
    public static void upatedAutomationNotesForWifiProduct(List<Opportunity> newList, map<Id,Opportunity> oldOppMap){
        set<Id> setOfIds = new set<Id>();
        Map<Id, OpportunityLineItem> mapOfOppItem = new Map<Id, OpportunityLineItem>();
        
        for(Opportunity opp : newList){
            if(oldOppMap.get(opp.Id).StageName == 'Orders Processing' && opp.StageName == 'Ready to Ship' && opp.of_LIC_Products__c != 0 && opp.of_HW_Products__c == 0 && opp.of_Accessories__c == 0){
                setOfIds.add(opp.Id); 
            }
            if(oldOppMap.get(opp.Id).StageName != opp.StageName && opp.StageName == 'Orders Processing' && opp.of_LIC_Products__c != 0 && opp.of_HW_Products__c == 0 && opp.of_Accessories__c == 0){
                setOfIds.add(opp.Id); 
            }
        }
        
        if(!setOfIds.isEmpty()){            
            for(OpportunityLineItem oppItem : [SELECT Id,Product2.ProductCode,OpportunityId FROM OpportunityLineItem WHERE OpportunityId =: setOfIds AND Product2.ProductCode != null]){
                if(oppItem.Product2.ProductCode.toLowerCase().contains(WIFIPRODUCTV1.toLowerCase()) || oppItem.Product2.ProductCode.toLowerCase().contains(WIFIPRODUCTV2.toLowerCase())){
                    mapOfOppItem.put(oppItem.OpportunityId, oppItem);
                } 
            }
            
            for(Opportunity opp : newList){
                if(mapOfOppItem.containsKey(opp.Id) && oldOppMap.get(opp.Id).StageName != opp.StageName && opp.StageName == 'Orders Processing' && opp.of_LIC_Products__c != 0 && opp.of_HW_Products__c == 0 && opp.of_Accessories__c == 0){
                    opp.Automation_Notes__c  = WIFISKU;                      
                }else if(oldOppMap.get(opp.Id).StageName == 'Orders Processing' && opp.StageName == 'Ready to Ship' && opp.Automation_Notes__c != System.Label.Canada_Automation_Notes && opp.Automation_Notes__c != System.Label.US_Automation_Notes && opp.Automation_Notes__c != 'Logicall Automation' && opp.Automation_Notes__c != 'License Automation'
                        && opp.Automation_Notes__c != System.Label.EMEA_Automation_Notes && opp.Automation_Notes__c != System.Label.Mexico_Automation_Notes  && (String.isBlank(opp.Automation_Notes__c) || (String.isNotBlank(opp.Automation_Notes__c) && !opp.Automation_Notes__c.contains('Re-Push Automation'))) && opp.of_LIC_Products__c != 0 && opp.of_HW_Products__c == 0 && opp.of_Accessories__c == 0){
                    String automationNotes = String.isNotBlank(opp.Automation_Notes__c) ? 'Manually Processed\n' + opp.Automation_Notes__c : 'Manually Processed';
                    opp.Automation_Notes__c =   automationNotes.length() > 255 ? automationNotes.substring(0, 255): automationNotes;                 
                }
            }
        }
    }
}