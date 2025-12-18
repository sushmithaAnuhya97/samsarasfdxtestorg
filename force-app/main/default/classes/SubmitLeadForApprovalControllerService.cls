/**
 * Created by vikasmishra on 2021-06-29.
 */

public with sharing class SubmitLeadForApprovalControllerService implements IService{

    @TestVisible
    static IDMLHelper thisLeadDMLHelper = new LeadDmlHelper();
    @TestVisible
    static SubmitLeadToNotreDame.IService notreDameService= new SubmitLeadToNotreDame();
    static final String LEAD_PROCESSING_APPROVAL_STATUS = 'Processing Approval';

    public void submitLeadForApprovalByPSM(Id LeadId){

            notreDameService.postLeadToNotreDame(LeadId);
            updateLeadStatus(notreDameService.getProcessedLeadRecord());
    }

    public class LeadDmlHelper implements IDMLHelper{

        public Database.SaveResult[] updateObjects(List<Lead> leadList, Boolean allOrNothing) {
            return Database.update(leadList, allOrNothing);
        }
    }

    public void updateLeadStatus(Lead thisLead){
        //thisLead.Status = LEAD_PROCESSING_APPROVAL_STATUS;//08/22/24 Vijaychandra (GTMS-22483): commented as part of Partner Application Phase 2 Project.
        thisLead.Approved_and_Provision_User_Initiated__c=true;
        thisLeadDMLHelper.updateObjects(new List<Lead>{thisLead}, true);
    }

    public interface IService{
        void submitLeadForApprovalByPSM(Id thisLeadId);
    }

    public interface IDMLHelper {
        Database.SaveResult[] updateObjects(List<Lead> leadList, Boolean allOrNothing);
    }

}