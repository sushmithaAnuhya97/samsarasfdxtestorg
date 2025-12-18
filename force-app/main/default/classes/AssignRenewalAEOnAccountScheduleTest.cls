/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-06-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@istest
public class AssignRenewalAEOnAccountScheduleTest {
    public static testMethod void testschedule() {
    Test.StartTest();
    String CRON_EXP = '0 0 23 * * ?';
            AssignRenewalAEOnAccountSchedule objsj = new AssignRenewalAEOnAccountSchedule();
            String jobId = System.schedule('RenewalJobOnAccount',
                                            CRON_EXP, 
                                            objsj);
    Test.stopTest();
  }
}