/*
* @Author : Siddharth Kumar Mishra
* @Description : GTMS - 6447  -  4/20/2022  -  Mark account if the RFC__c on MX Non-Compliant Taxpayers Object is present on any Account( VATId__c )
*/
public class Batch_MarkMXNonCompliantAccount implements Database.Batchable<sObject>
{
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    
    //START METHOD
    public Database.QueryLocator start(Database.BatchableContext BC)
    {  
        String query = 'SELECT id,RFC__c FROM MX_Non_Compliant_Taxpayers__c';
        return Database.getQueryLocator(query);
    }
    
    //EXECUTE METHOD
    public void execute(Database.BatchableContext BC, List<MX_Non_Compliant_Taxpayers__c> records)
    {   
        try
        {
            markAccounts(records);
        }
        catch(exception e)
        {
            thisLogger.logError('GS_TaskRollupHelper. Error Message ::'+ e.getMessage() +' | StackTrace:: '+ e.getStackTraceString());
        }
        
    }
    
    //FINISH METHOD
    public void finish(Database.BatchableContext BC)
    {  
    }
    
    public void markAccounts(List<MX_Non_Compliant_Taxpayers__c> records)
    {
        Set<String> NonCompliantTaxIds = new Set<String>();
        for(MX_Non_Compliant_Taxpayers__c rec : records)
        {
            NonCompliantTaxIds.add(rec.RFC__c);
        }
        List<Account> nonCompliantTaxPayerAccounts = [SELECT Id,VATId__c,MX_Non_Compliant_Tax_Payer__c FROM Account WHERE VATId__c IN :NonCompliantTaxIds];
        if(!nonCompliantTaxPayerAccounts.isEmpty())
        {
            for(Account acc : nonCompliantTaxPayerAccounts)
            {
                acc.MX_Non_Compliant_Tax_Payer__c = true;
            }
            update nonCompliantTaxPayerAccounts;
        }
    }
}