global class ScheduledContractAutomation implements Schedulable{
    global void execute(SchedulableContext sc) {
        System.debug('CPU time before the job for the class <ContractAutomation> is scheduled: ' +  Limits.getCpuTime());
        //String query = 'SELECT SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c, Id FROM Contract WHERE SBQQ__RenewalForecast__c = FALSE AND SBQQ__RenewalQuoted__c = FALSE';
        Database.executeBatch(new ContractAutomation(System.Label.Contract_Automation_Query , true), 1);
        System.debug('CPU time after the job for the class <ContractAutomation> is completed: ' +  Limits.getCpuTime());
    }
}