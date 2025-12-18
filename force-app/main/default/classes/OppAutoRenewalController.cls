/*
 * Test Class: OppAutoRenewalControllerTest
 * ********************************************************************************
 Modification History:
 * 4/22/20 Satya - (GTMS - )Convert opportunity to Auto Renewal(Evergreen)
 GTMS-5119-Jan13-2023 -- Zakeer -- Modified line# 46-50
 */
public class OppAutoRenewalController {
    public OppAutoRenewalController(ApexPages.StandardController stdController) {}
    public class MyException extends Exception{}
    
    public static PageReference convertToEverGreen() {
        Id oppId = ApexPages.currentPage().getParameters().get('id');
        String result = null;
        PageReference detailPage = new PageReference('/' + oppId);
        if(!Test.isRunningTest())updateEvergreen(oppId);
        detailPage.setRedirect(true);
        return detailPage;
        
    }
    
    public static void updateEvergreen(Id oppId) {
        List<OpportunityLineItem> lstoli;
        List<Opportunity> lstOpp;
        List<Opportunity> oppCurrent = [SELECT Id, Name, Renewal__c, ContractId, netsuite_conn__From_Contract__r.Original_Contracted_Opportunity__c ,   
                           Payment_Terms__c, Selected_Payment_Type__c, Original_License_Term__c, Shipping_Contact__c, 
                           (SELECT Id, Original_Quantity__c, Original_List_Rate__c, UnitPrice, Quantity FROM OpportunityLineItems)
                           FROM Opportunity WHERE Id =: oppId];
        List<OpportunityLineItem> lstToUpdate = oppCurrent[0].OpportunityLineItems.isEmpty() ? null : oppCurrent[0].OpportunityLineItems;
        Id originalOppId = oppCurrent[0].netsuite_conn__From_Contract__c != null ? oppCurrent[0].netsuite_conn__From_Contract__r.Original_Contracted_Opportunity__c : null;
        if(originalOppId != null) {
            lstOpp = [SELECT Id, NS_Payment_Terms__c, Selected_Payment_Type__c FROM Opportunity WHERE Id =: originalOppId];
        }
        if(!lstOpp.isEmpty() && oppCurrent[0].Renewal__c && oppCurrent[0].Shipping_Contact__c != null) {
            if(!lstToUpdate.isEmpty() && oppCurrent[0].Original_License_Term__c != null) {
                for(OpportunityLineItem oli : lstToUpdate) {
                    if(oli.Original_Quantity__c > 0 && oli.Original_List_Rate__c != null) {
                        oli.Quantity = oli.Original_Quantity__c;
                        oli.UnitPrice = (oli.Original_List_Rate__c/oppCurrent[0].Original_License_Term__c)*12;
                    }
                }
                update lstToUpdate;
            }
            update new Opportunity(Id = oppCurrent[0].Id, 
                                   Name = oppCurrent[0].Name.contains('Evergreen - ') ? oppCurrent[0].Name : 'Evergreen - ' + oppCurrent[0].Name,
                                   Sub_Type__c='Auto-Renewal', 
                                   StageName = 'Closing',
                                   License_Term__c = 12,
                                   CloseDate = System.Today(),
                                   OwnerID = System.Label.GTMS_AutoRenew_OwnerId,//'0051a000002k4I5',
                                   PO_Number__c = 'Auto-Renewal',
                                   Finance_Notes__c  = 'Evergreen opportunity',  
                                   Payment_Terms__c = lstOpp[0].NS_Payment_Terms__c, 
                                   Selected_Payment_Type__c = lstOpp[0].Selected_Payment_Type__c,
                                   License_Term_Approval_Status__c = 'Approved',
                                   ContractId = null
                                  );
            
        }
        else {
            throw new MyException('Please Verify Shipping Contact and Original Contracted Opportunity');
        }
        
    }
}