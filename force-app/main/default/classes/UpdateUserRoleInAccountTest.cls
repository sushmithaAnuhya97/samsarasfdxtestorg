@isTest
public class UpdateUserRoleInAccountTest {
    
    @testSetup 
    private static void setup() {
        List<Account> acctList = new List<Account>();
        for(Integer i=0;i<5;i++){
            Account account = new Account(Name = 'SegmentAccount-'+i,Organization_Size__c='100 - 499',BillingState='California', BillingCountry= 'United States');
            acctList.add(account);
        }
        
        for(Integer i=0;i<5;i++){
            Account account = new Account(Name = 'OwnerRoleAccount-'+i,Organization_Size__c='100 - 499',BillingState='California', BillingCountry= 'United States');
            acctList.add(account);
        }
        INSERT acctList;
    }
    
    @isTest
    public static void testUpdateUserRoleInAccount() {
        Test.startTest();
        UpdateUserRoleInAccount c = new UpdateUserRoleInAccount();
        Database.executeBatch(c);
        Test.stopTest();
    }
}