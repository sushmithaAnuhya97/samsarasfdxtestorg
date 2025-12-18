/**
* * Created By : Groundswell - Tanuj Tyagi
* @Date August 24, 2021
* @description : This class will be responsible to Add Campaign to Contact
* SFA-14
*
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* GTMS-2415
*/
public with sharing class GS_ContactCampaignToAddService {

    public void workflowConversionProcess(List<Contact> contactList, Map<Id, Contact> OldContactMap) {
        processWorkflows(contactList, OldContactMap);
    }
    
    private void processWorkflows(List<Contact> contactList, Map<Id, Contact> OldContactMap) {
        Set<Id> contactRecordsIds = new Set<Id>();
        for (Contact thisContact : contactList) {
            if (wfCampaignToAddCondition(thisContact)) {
                contactRecordsIds.add(thisContact.Id);  
            }
        }
        if(!contactRecordsIds.isEmpty()){
            DMLWrapper.doInsert(new GS_ContactCampaignToAddAsync().prepareAsyncRequests(contactRecordsIds));
        }
    }  
    
    private Boolean wfCampaignToAddCondition(Contact thisContact) {
        return (thisContact.Campaign_to_Add__c != null);
    }
}