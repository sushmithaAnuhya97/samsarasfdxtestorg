/**
 * Created by vikasmishra on 2021-06-10.
 */

@IsTest
private class ReRunAssignmentRuleForLeadTest {
    @IsTest
    static void shouldRunAssignmentRule() {

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        LeadDMLHelperMock thisDMLMock = new LeadDMLHelperMock();
        ReRunAssignmentRuleForLead.thisLeadDMLHelper = thisDMLMock;
        ReRunAssignmentRuleForLead.assignLeads(
                new List<Lead>{
                        new Lead(
                                Id = generateId(
                                        Lead.SObjectType,
                                        100
                                )
                        )
                }
        );
        System.assert(thisDMLMock.methodCalled, 'DML Helper has been called');
    }

    @IsTest
    static void shouldTestLeadDMLHelper(){
        ReRunAssignmentRuleForLead.LeadDMLHelper thisActualDmlHelper= new ReRunAssignmentRuleForLead.LeadDMLHelper();
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        dmo.emailHeader.triggerUserEmail = true;
        thisActualDmlHelper.updateLeadWithDMLOptions(new List<Lead>(), dmo);
        System.assert(Limits.getDmlRows() == 0, 'Should be zero');
    }

    public class LeadDMLHelperMock implements ReRunAssignmentRuleForLead.IDMLHelper{
        public Boolean methodCalled = false;
        public void updateLeadWithDMLOptions (List<Lead> leadList, Database.DMLOptions dos){
            methodCalled = true;
        }
    }

    public static String generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
}