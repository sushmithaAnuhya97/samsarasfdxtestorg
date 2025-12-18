public class ScheduledAccountAutomation implements Schedulable{
    public void execute(SchedulableContext sc) {
        System.debug('CPU time before the job for the class <AccountAutomation> is scheduled: ' +  Limits.getCpuTime());
        Database.executeBatch(new AccountAutomation(System.Label.Last_Meaningful_Engagement_Date, true, 1), 5);
        System.debug('CPU time after the job for the class <AccountAutomation> is completed: ' +  Limits.getCpuTime());
    }
}