/**
 * Created by fcontini on 2021-09-21.
 */

public with sharing class GS_ADRTransferService {

    public void updateTransferLog(List<Opportunity> oppList){
        for (Opportunity oppty : oppList){
            if((oppty.OpportunityLineItems.size() > 0 || oppty.Probability >= 10) && oppty.ADR_Transfer__c != null){
                /* Replaces Node 'ADR Transfer Qualified' */
                System.debug(LoggingLevel.INFO, 'ADR Transfer Logic Called');
                if(oppty.ADR_Transfer__r.ADR_Transfer_Qualified_Date__c == null){
                    System.debug(LoggingLevel.INFO, 'ADR Transfer Logic Executing');
                    oppty.ADR_Transfer__r.AE_Qualified_Transfer_To__c = oppty.OwnerId;
                    oppty.ADR_Transfer__r.ADR_Manager_Name_Copy_at_Qualification__c = oppty.ADR_Transfer__r.ADR_Transfer_By__r.ManagerId;
                    oppty.ADR_Transfer__r.ADR_Role_Copy_at_Qualification__c = oppty.ADR_Transfer__r.ADR_Transfer_By__r.UserRole.Name;
                    oppty.ADR_Transfer__r.ADR_Transfer_Qualified_Date__c = System.today();
                    oppty.ADR_Transfer__r.ADR_Transfer_Status__c = 'Accepted and Qualified';
                    DMLWrapper.doUpdate(oppty.ADR_Transfer__r);
                    //System.debug('OpportunityProcessBuilderConversion - Running Node: ADR Transfer Qualified');
                }
            }
        }
    }
}