/*
* @Author : Siddharth Kumar Mishra
* @Description : GTMS - 6447  -  4/23/2022  -  Unmarks all accounts for MX Non Compliant TaxPayer and then calls Batch_MarkMXNonCompliantAccount to freshly mark them
*/
public class Batch_UnMarkMXNonCompliantAccounts implements Database.Batchable<sObject>
{
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    
    //START METHOD
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query = 'SELECT Id,Name,MX_Non_Compliant_Tax_Payer__c FROM Account WHERE MX_Non_Compliant_Tax_Payer__c = TRUE';
        return Database.getQueryLocator(query);
    }
    
    //EXECUTE METHOD
    public void execute(Database.BatchableContext BC, List<Account> markedAccounts)
    {   
        try
        {
            unMarkAccounts(markedAccounts);
        }
        catch(exception e)
        {
            thisLogger.logError('GS_TaskRollupHelper. Error Message ::'+ e.getMessage() +' | StackTrace:: '+ e.getStackTraceString());
        }
        
    }
    
    //FINISH METHOD
    public void finish(Database.BatchableContext BC)
    { 
        database.executebatch((new Batch_MarkMXNonCompliantAccount()),200);
    }
    public void unMarkAccounts(List<Account> markedAccounts)
    {
        if(!markedAccounts.isEmpty())
        {
            for(Account acc : markedAccounts)
            {
                acc.MX_Non_Compliant_Tax_Payer__c = false ;
            }
            Update markedAccounts;
        }
    }
}