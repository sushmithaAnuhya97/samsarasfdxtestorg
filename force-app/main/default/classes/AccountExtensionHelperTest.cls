@IsTest
public class AccountExtensionHelperTest {
	@TestSetup
    static void setup(){
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
		List<Account> accList = new List<Account>();
        Account acc = (Account) TestFactory.createSObject(new Account(Status__c = 'Acc Status'));
        insert acc;
		accList.add(acc);
        Account acc2 = (Account) TestFactory.createSObject(new Account(Status__c = 'Acc Status 2'));
        insert acc2;
        accList.add(acc);
        Contact ctt = (Contact) TestFactory.createSObject(new Contact(Email = 'phillip.front@samsara.com', AccountId = acc.Id, Status__c = 'New'));
		insert ctt;
        
        Account_Extension__c  accExt = (Account_Extension__c ) TestFactory.createSObject(new Account_Extension__c(Account__c  = acc.Id));
        insert accExt;
    }
    
    @isTest
    public static void testWithAccountExtenstion(){
        Test.startTest();
        Account acc = [SELECT Id from Account where Status__c = 'Acc Status' limit 1];
        AccountExtensionHelper.getAccountExtension(acc.Id);
        Test.stopTest();
    }
    @isTest
    public static void testWithNOAccountExtenstion(){
        Test.startTest();
        Account acc = [SELECT Id from Account where Status__c = 'Acc Status 2'  limit 1];
        AccountExtensionHelper.getAccountExtension(acc.Id);
        Test.stopTest();
    }
}