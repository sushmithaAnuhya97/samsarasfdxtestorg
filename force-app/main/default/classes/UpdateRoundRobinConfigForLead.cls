/* 
* Class Created: 08/01/2023 - @author: Saiteja
* GTMS 10339-Updates to Partner Application lead routing in partner portal
* Test Class: UpdateRoundRobinConfigForLeadTest
* 
*/
public class UpdateRoundRobinConfigForLead {
    @InvocableMethod (Label='Update Lead RoundRobin Configs' Description='Method to update Lead roundrobin configs')
    public static void updateRRLeadConfigs(List<Lead> leads){
        CommercialLead_Count__c leadCommercial = [Select Id, Count__c from CommercialLead_Count__c];
		InsuranceLead_Count__c leadInsurance = [Select Id, Count__c from InsuranceLead_Count__c];
        Decimal commercialleadNum = leadCommercial.Count__c;
        Decimal insuranceleadNum = leadInsurance.Count__c;
        
        for(Lead lead : leads){
            if(lead.Partner_Type__c != null){
                if(lead.Partner_Type__c == System.label.Lead_Insurance_Type){
                    insuranceleadNum = insuranceleadNum + 1;
                }else if(lead.Partner_Type__c == System.label.Lead_Commercial_Type){
                    commercialleadNum = commercialleadNum + 1;
                }
            }
        }
        
        if(leadCommercial.Count__c != commercialleadNum){
            leadCommercial.Count__c = commercialleadNum;
            update leadCommercial;
        }
        
        if(leadInsurance.Count__c != insuranceleadNum){
            leadInsurance.Count__c = insuranceleadNum;
            update leadInsurance; 
        }   
    }
    
}