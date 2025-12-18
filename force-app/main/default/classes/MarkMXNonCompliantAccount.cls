/*
* @Author : Siddharth Kumar Mishra
* @Description : GTMS - 6447  -  4/20/2022  -called by button to  Mark account if the RFC__c on MX Non-Compliant Taxpayers Object is present on any Account( VATId__c )
*/
public class MarkMXNonCompliantAccount 
{
    @InvocableMethod
	public static void markAccount()
    {
        database.executebatch((new Batch_UnMarkMXNonCompliantAccounts()),200);
    }
}