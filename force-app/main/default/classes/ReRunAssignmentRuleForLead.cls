/**
 * Created by vikasmishra on 2021-06-10.
 */

public without sharing class ReRunAssignmentRuleForLead {

    public static IDMLHelper thisLeadDMLHelper = new LeadDMLHelper();
    public static final String UNDER_STATUS_CONSTANT = 'New';
    @InvocableMethod (Label='Re-Run Lead Assignment Rules' Description='Method to rerun Lead Assignment rule')
    public static void assignLeads(List<Lead> leads){
        reRunAssignmentRules(leads);
    }

    public static void reRunAssignmentRules(List<Lead> leadList){
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        //dmo.emailHeader.triggerUserEmail = true;
        thisLeadDMLHelper.updateLeadWithDMLOptions(leadList, dmo);
    }
    
    public without sharing class LeadDMLHelper implements IDMLHelper{
        public void updateLeadWithDMLOptions(List<Lead> leadList, Database.DMLOptions dmo){
            List<Database.SaveResult> saveResults = Database.update(leadList,dmo);
            // Iterate through each returned result
            for (Database.SaveResult sr : saveResults) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully updated records. Lead ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.****');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        //System.debug('Lead fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
    public interface IDMLHelper{
        void updateLeadWithDMLOptions(List<Lead> leadList, Database.DMLOptions dmo);

    }
}