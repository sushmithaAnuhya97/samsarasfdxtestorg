/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-06-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@istest
public class AssignRenewalAEOnOpportunityScheduleTest {
    public static testMethod void testschedule() {
		Test.StartTest();
		String CRON_EXP = '0 0 23 * * ?';
            AssignRenewalAEOnOpportunitySchedule objsj = new AssignRenewalAEOnOpportunitySchedule();
            String jobId = System.schedule('DeactivateInactiveUsers',
                                            CRON_EXP, 
                                            objsj);
		Test.stopTest();
	}
}