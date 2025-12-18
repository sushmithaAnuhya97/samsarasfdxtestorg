/**********************************************************************
Name: AccountMonthlyExpBatch_Test
Realated Class: AccountMonthlyExpiration_Batch
-----------------------------------------------------------------------
Purpose: This class contains the test case methods for AccountMonthlyExpiration_Batch class                                                       
-----------------------------------------------------------------------
History  

VERSION     AUTHOR               			DATE               DETAIL                       
1.0        vijaychandra AMARANENI        2023-SEP-01        INITIAL DEVELOPMENT FOR GTMS-14503

***********************************************************************/ 
@IsTest
public class AccountMonthlyExpBatch_Test {
    /*****************************************8
	 * @Description:this method will create test data of users and accounts
	*/
    @testSetup
    static void setupMethod(){
        string ProfileId = [SELECT Id FROM Profile WHERE Name LIKE 'Samsara Sales - NA%' LIMIT 1].Id;
        
        User testManager = new User();
        
        testManager.ProfileId = ProfileId;
        testManager.LastName = 'testManager';
        testManager.Email = 'testManager@samsara.com';
        testManager.Username = 'testmanager@siigroup.com';
        testManager.Alias = 'Mngr';
        testManager.CompanyName = 'Samsara';
        testManager.TimeZoneSidKey='America/New_York';
        testManager.EmailEncodingKey='UTF-8';
        testManager.LanguageLocaleKey='en_US';
        testManager.LocaleSidKey='en_US';
        testManager.EmployeeNumber = '12345';
        
        insert testManager;
        
        User testUser = new User();
        
        testUser.ProfileId = ProfileId;
        testUser.LastName = 'testUser';
        testUser.Email = 'testUser@samsara.com';
        testUser.Username = 'testUser@samsara.com';
        testUser.Alias = 'user1';
        testUser.CompanyName = 'Samsara';
        testUser.TimeZoneSidKey='America/New_York';
        testUser.EmailEncodingKey='UTF-8';
        testUser.LanguageLocaleKey='en_US';
        testUser.LocaleSidKey='en_US';
        testUser.ManagerId = testManager.Id;
        testUser.EmployeeNumber = '3456';
        
        insert testUser;
        
        List<Account> accountList = new List<Account>();
        
        Account acc1 = new Account(Name='Acc1',Organization_Size__c = '1 - 99',Industry='Banking',BillingState='California',
                                   ShippingState='California',Approved_Payment_Type__c = 'Direct Monthly',
                                   IF_Response_Date__c=Date.today().addDays(-90),IF_Submitter_Email__c='testUser@Samsara.com',
                                  OwnerId=testUser.Id);
        accountList.add(acc1);
        
        Account acc2 = new Account(Name='Acc2',Organization_Size__c = '1 - 99',Industry='Agriculture',BillingState='Texas',
                                   ShippingState='Texas',Approved_Payment_Type__c = 'Direct Monthly',
                                   IF_Response_Date__c=Date.today().addDays(-60),IF_Submitter_Email__c='testUser@Samsara.com',
                                  OwnerId=testUser.Id);
        accountList.add(acc2);
        
        insert accountList;
        
        List<Internal_Finance_Approval_Request__c> ifaList = new List<Internal_Finance_Approval_Request__c>();
        
        Internal_Finance_Approval_Request__c ifr1 = new Internal_Finance_Approval_Request__c(Account__c=accountList[0].Id,Request_Type__c='Direct Monthly Financing',
                                                                                            Submitter__c = userInfo.getUserId(),Approver__c = testUser.Id,Payment_Type_Approval_Status__c = 'Approved',
                                                                                            Finance_Response_Date__c = Datetime.now().addDays(-90));
        ifaList.add(ifr1);
        Internal_Finance_Approval_Request__c ifr2 = new Internal_Finance_Approval_Request__c(Account__c=accountList[1].Id,Request_Type__c='Direct Monthly Financing',
                                                                                            Submitter__c = userInfo.getUserId(),Approver__c = testUser.Id,Payment_Type_Approval_Status__c = 'Approved',
                                                                                            Finance_Response_Date__c = Datetime.now().addDays(-60));
        ifaList.add(ifr2);
        
        insert ifaList;
        
    }
    /*****************************************8
	 * @Description:this method has the logic to test batch class
	*/
	@IsTest
    public static void BatchTest(){
        Test.StartTest();
        	Database.executeBatch(new AccountMonthlyExpiration_Batch(),80);
        Test.StopTest();
        
        Date date90 = Date.Today().addDays(-90);
        
        Account acc = [SELECT Id,Approved_Payment_Type__c,IF_Response_Date__c FROM Account WHERE IF_Response_Date__c =:date90];
        System.debug(acc);
        
        Assert.isTrue(acc.Approved_Payment_Type__c=='Direct Annual','date90 logic was not executed');        
    }
    /*****************************************8
	 * @Description:this method has the logic to test schedule job
	*/
    @IsTest
    public static void scheduleTest(){
        string jobId;
        Test.StartTest();
        	String sch = '0 6 * * * ?';
			jobId = system.schedule('MonthlyExpirationBatch', sch, new AccountMonthlyExpiration_Batch());
        Test.StopTest();
        
        CronTrigger ct = [SELECT Id, cronJobDetail.Name FROM CronTrigger WHERE id = :jobId];
        
        Assert.isTrue(ct.CronJObDetail.Name=='MonthlyExpirationBatch','job was not scheduled');
    }
}