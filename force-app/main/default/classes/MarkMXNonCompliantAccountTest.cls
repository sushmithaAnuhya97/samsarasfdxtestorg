/*
* @Author : Siddharth Kumar Mishra
* @Description:- Test class for MarkMXNonCompliantAccount,Batch_UnMarkMXNonCompliantAccounts,Batch_MarkMXNonCompliantAccount ( GTMS - 6447  -  4/23/2022  -  MX Non Compliant Tax Payers )
*/
@IsTest
public class MarkMXNonCompliantAccountTest
{
    @TestSetup 
    public static void setup()
    {
        //Test Accounts
        Account testAccount = new Account
        (
            name = 'Test Account 1',
            VATId__c = '1001001',
            Organization_Size__c = '1 - 99',
            BillingCountry = 'India'
        );
        Insert testAccount;
        Account testAccount2 = new Account
        (
            name = 'Test Account 2',
            VATId__c = '1001001',
            Organization_Size__c = '1 - 99',
            BillingCountry = 'India',
            MX_Non_Compliant_Tax_Payer__c = true
        );
        Insert testAccount2;
        
        MX_Non_Compliant_Taxpayers__c testRec = new MX_Non_Compliant_Taxpayers__c
        (
            RFC__c = '1001001',
            Status__c = '',
            Taxpayer_Name__c = 'test non compliant tax payer'
        );
        Insert testRec;
    }
    @IsTest
    static void testMethod01()
    {
        Account testAccOld1 = [SELECT Id,Name,MX_Non_Compliant_Tax_Payer__c FROM Account WHERE MX_Non_Compliant_Tax_Payer__c = TRUE];
        Account testAccOld2 = [SELECT Id,Name,MX_Non_Compliant_Tax_Payer__c FROM Account WHERE MX_Non_Compliant_Tax_Payer__c = FALSE];
        Test.startTest();
        MarkMXNonCompliantAccount.markAccount();
        Test.stopTest();
        List<Account> testAccNew = [SELECT Id,Name,MX_Non_Compliant_Tax_Payer__c FROM Account limit 2];
        System.assertEquals(TRUE, testAccOld1.MX_Non_Compliant_Tax_Payer__c);
        System.assertEquals(FALSE, testAccOld2.MX_Non_Compliant_Tax_Payer__c);
        System.assertEquals(TRUE, testAccNew[0].MX_Non_Compliant_Tax_Payer__c);
        System.assertEquals(TRUE, testAccNew[1].MX_Non_Compliant_Tax_Payer__c);
    }
    
}