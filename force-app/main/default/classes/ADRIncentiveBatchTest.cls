@isTest
public class ADRIncentiveBatchTest {

    @TestSetup
    private static void setup() {

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            // Create a role
            UserRole role = new UserRole(Name = 'Fleet ADR OB NA US Test');
            insert role;

            // Pick a profile
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

            // Create a user with that role
            User u = new User(
                FirstName = 'Test', LastName = 'User',
                Email = 'testuser@example.com', Username = 'testuser@example.com.' + System.currentTimeMillis(),
                Alias = 'tuser', TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
                ProfileId = p.Id, UserRoleId = role.Id, EmployeeNumber = '1234567890'
            );
            insert u;
        }

        Test.startTest();
        
        Account account = createAccount('English', 'Test Account', 'AE2');
        insert account;
        
        insert createOppty('FedEx', 'Revenue Opportunity', account.Id);
        
        Test.stopTest();
    }
    
    @isTest
    private static void AdrOnOpportunityTest() {
        // Fetch the opportunity created in setup
        Opportunity oppty = [SELECT Id, ACV_Bookings__c,ACV_Bookings_SOT__c  FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Period currentMonth = [SELECT Id, StartDate, EndDate FROM Period WHERE StartDate <= TODAY AND EndDate >= TODAY AND Type = 'Month' LIMIT 1];
        User adrOwner = [SELECT Id, name, userRole.Name FROM User WHERE isActive = TRUE 
                            AND (UserRole.Name like '%Fleet ADR OB SLED NA US%' OR UserRole.Name like '%Fleet ADR OB NA US%') 
                            AND ADR_Segment_Alignment__c = 'AE2' LIMIT 1];
        
        Test.startTest();

        insert new Automation_Settings__c(Name = 'ADR Incentive',Disabled__c = false);

        insert new ADR_Transfer_Log__c(
                        Opportunity__c = oppty.Id,
                        ADR_Transfer_Qualified_Date__c = currentMonth.startDate,
                        ADR_Transfer_Status__c = 'Accepted and Qualified',
                        ownerId = adrOwner.Id
                    );

        Database.executeBatch(new ADRIncentiveBatch());
        
        Test.stopTest();
    }

    @isTest
    private static void FirstPurchaseThresholdCheck_Positive() {

        Test.startTest();
        boolean thresholdMet = new ADRIncentiveBatch().meetsACVThreshold('Fleet ADR OB SLED NA US Test', 10002, true);
        Test.stopTest();

        Assert.isTrue(thresholdMet, 'Threshold must be met');
    }

    @isTest
    private static void FirstPurchaseThresholdCheck_Negative1() {

        Test.startTest();
        boolean thresholdMet = new ADRIncentiveBatch().meetsACVThreshold('Fleet ADR OB SLED NA US Test', 9002, true);
        Test.stopTest();

        Assert.isFalse(thresholdMet, 'Threshold must not be met');
    }

    @isTest
    private static void FirstPurchaseFalseThresholdCheck_Positive() {

        Test.startTest();
        boolean thresholdMet = new ADRIncentiveBatch().meetsACVThreshold('Random Test', 119002, false);
        Test.stopTest();

        Assert.isTrue(thresholdMet, 'Threshold must be met');
    }

    @isTest
    private static void FirstPurchaseFalseThresholdCheck_Negative1() {

        Test.startTest();
        boolean thresholdMet = new ADRIncentiveBatch().meetsACVThreshold('Random Test', 302, false);
        Test.stopTest();

        Assert.isFalse(thresholdMet, 'Threshold must not be met');
    }
    
    @isTest
    private static void adrInFiscalMonthTest() {

        Test.startTest();
        ADRIncentiveBatch batch = new ADRIncentiveBatch();
        batch.fiscalMonthStartDate = System.today();
        batch.fiscalMonthEndDate = System.today().addDays(10);

        ADR_Transfer_Log__c adr = new ADR_Transfer_Log__c(

            ADR_Transfer_Qualified_Date__c = Date.today().addDays(2),
            ADR_Transfer_Status__c = 'Accepted and Qualified',
            Transfer_Points_At_Transfer_Copy__c = 0,
            Transfer_Points_at_Trial__c = 0
        );

        boolean inFiscalMonth = batch.adrInFiscalMonth(adr);
        Test.stopTest();

        Assert.isTrue(inFiscalMonth, 'ADR Transfer Log must be in Fiscal Month');
    }
    
    @isTest
    private static void updateTransferPointsAtTrialPlusTest() {

        List<Opportunity> opportunities = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        opportunities[0].Went_to_Closed_Won_Date__c = System.Today();
        opportunities[0].Went_to_Closed_Won__c = true;

        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        update opportunities;

        setting.Skip_Trigger__c = false;
        update setting;

        Test.startTest();
        ADRIncentiveBatch batch = new ADRIncentiveBatch();
        batch.fiscalMonthStartDate = System.today();
        batch.fiscalMonthEndDate = System.today().addDays(10);

        ADR_Transfer_Log__c adr = new ADR_Transfer_Log__c(
            Opportunity__c = opportunities[0].Id,
            ADR_Transfer_Qualified_Date__c = Date.today().addDays(2),
            ADR_Transfer_Status__c = 'Accepted and Qualified',
            Transfer_Points_At_Transfer_Copy__c = 0,
            Transfer_Points_at_Trial__c = 0
        ); 

        insert adr;

        ADR_Transfer_Log__c adrQueried = [SELECT Id, Opportunity__c, Transfer_Points_at_Trial__c, Transfer_Points_At_Transfer_Copy__c, 
                                            Opportunity__r.Went_to_Trial__c, Opportunity__r.Went_to_Proposal__c, Opportunity__r.Went_to_Decision__c, 
                                            Opportunity__r.Went_to_Purchase__c, Opportunity__r.Went_to_Closing__c, Opportunity__r.Went_to_Orders_Processing__c, 
                                            Opportunity__r.Went_to_Ready_to_Ship__c, Opportunity__r.Went_to_Closed_Won__c,
                                            Opportunity__r.Went_to_Trial_Date__c, Opportunity__r.Went_to_Proposal_Date__c, 
                                            Opportunity__r.Went_to_Decision_Date__c, Opportunity__r.Went_to_Purchase_Date__c, 
                                            Opportunity__r.Went_to_Closing_Date__c, Opportunity__r.Went_to_Orders_Processing_Date__c, 
                                            Opportunity__r.Went_to_Ready_to_Ship_Date__c, Opportunity__r.Went_to_Closed_Won_Date__c
                                            FROM ADR_Transfer_Log__c WHERE Id = :adr.Id];

        batch.updateTransferPointsAtTrialPlus(adrQueried, new Map<Id,ADR_Transfer_Log__c>());
        Test.stopTest();
    }

    @isTest
    private static void updateTrailForQuotaTransferLogsTest() {
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        User adrTestUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        Quota__c quota = new Quota__c(User__c = adrTestUser.Id, CurrencyIsoCode = 'USD', Adj_Role_Start_Date_v2__c = Date.Today(), Quota_Period_End_Date__c = Date.Today() + 4, Quota_Period_Start_Date__c = Date.Today() - 4, Fiscal_Period_End_Date__c = Date.Today() + 4, Fiscal_Period_Start_Date__c = Date.Today() - 4, Quota_Period__c = 'Test', Fiscal_Period__c = 'Test',
                                            Quota__c = 4, Q1_Quota__c = 1,Q2_Quota__c = 1,Q3_Quota__c = 1,Q4_Quota__c = 1);
        insert quota;

        ADR_Transfer_Log__c adr = new ADR_Transfer_Log__c(
            Opportunity__c = opportunities[0].Id,
            ADR_Transfer_Qualified_Date__c = Date.today().addDays(3),
            ADR_Transfer_Status__c = 'Accepted and Qualified',
            Transfer_Points_At_Transfer_Copy__c = 4,
            Transfer_Points_at_Trial__c = 3
        );
        insert adr;

        insert new Quota_Transfer_Log__c(Related_Quota_for_the_ADR_Log__c = quota.Id, ADR_Transfer_Log__c = adr.Id);

        Test.startTest();
        new ADRIncentiveBatch().updateTrailForQuotaTransferLogs(new map<Id, ADR_Transfer_Log__c>{adr.Id => adr});
        Test.stopTest();

        Quota_Transfer_Log__c queriedQuotaLog = [SELECT Id, ADR_Transfer_Points_At_Transfer_Copy__c, ADR_Transfer_Points_at_Trial__c FROM Quota_Transfer_Log__c ORDER BY LastModifiedDate desc LIMIT 1];

        Assert.areEqual(4, queriedQuotaLog.ADR_Transfer_Points_At_Transfer_Copy__c, 'ADR_Transfer_Points_At_Transfer_Copy__c value must be 4');
        Assert.areEqual(3, queriedQuotaLog.ADR_Transfer_Points_at_Trial__c, 'ADR_Transfer_Points_at_Trial__c value must be 3');
    }

    @isTest
    static void testFinishMethod() {
        
        User adrTestUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        Quota__c testQuota = new Quota__c(
            User__c = adrTestUser.Id,
            Fiscal_Period__c = 'FY23',
            Adj_Role_Start_Date_v2__c = Date.Today().addDays(-15),
            Fiscal_Period_End_Date__c = Date.today().addDays(-10),
            Fiscal_Period_Start_Date__c = Date.today().addDays(-20),
            ADR_Quota__c = 100);
        
        insert testQuota;
        
        ADRIncentiveBatch batchInstance = new ADRIncentiveBatch();
        batchInstance.userId = UserInfo.getUserId();
        batchInstance.recordId = testQuota.Id;

        Test.startTest();
        batchInstance.notifyUser(0, 'samosa');
        Test.stopTest();
    }

    @isTest static void lwcInvocationTest_NoCustomSetting(){
        
        User adrTestUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        Quota__c testQuota = new Quota__c(
            User__c = adrTestUser.Id,
            Fiscal_Period__c = 'FY23',
            Adj_Role_Start_Date_v2__c = Date.Today().addDays(-15),
            Fiscal_Period_End_Date__c = Date.today().addDays(-10),
            Fiscal_Period_Start_Date__c = Date.today().addDays(-20),
            ADR_Quota__c = 100);
        
        insert testQuota;

        Test.startTest();

        ADRIncentiveBatch.invokeADRIncentiveBatchFromLWC(UserInfo.getUserId(), true, (String)testQuota.Id);

        Test.stopTest();
    }

    @isTest static void lwcInvocationTest_RandomJobId(){
        
        User adrTestUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        Quota__c testQuota = new Quota__c(
            User__c = adrTestUser.Id,
            Fiscal_Period__c = 'FY23',
            Adj_Role_Start_Date_v2__c = Date.Today().addDays(-15),
            Fiscal_Period_End_Date__c = Date.today().addDays(-10),
            Fiscal_Period_Start_Date__c = Date.today().addDays(-20),
            ADR_Quota__c = 100);
        
        insert testQuota;

        insert new Automation_Settings__c(Name = 'ADR Incentive', Data__c = '{"lastRunJobId":"707Wr000016siJYIAY"}');

        Test.startTest();

        ADRIncentiveBatch.invokeADRIncentiveBatchFromLWC(UserInfo.getUserId(), true, (String)testQuota.Id);

        Test.stopTest();
    }

    @isTest static void lwcInvocationTest_CompletedBatch(){
        
        User adrTestUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        Quota__c testQuota = new Quota__c(
            User__c = adrTestUser.Id,
            Fiscal_Period__c = 'FY23',
            Adj_Role_Start_Date_v2__c = Date.Today().addDays(-15),
            Fiscal_Period_End_Date__c = Date.today().addDays(-10),
            Fiscal_Period_Start_Date__c = Date.today().addDays(-20),
            ADR_Quota__c = 100);
        
        insert testQuota;

        Test.startTest();

        Id jobId = database.executeBatch(new ADRIncentiveBatch());

        insert new Automation_Settings__c(Name = 'ADR Incentive', Data__c = '{"lastRunJobId":"'+(String)jobId+'"}');

        Test.stopTest();
        ADRIncentiveBatch.invokeADRIncentiveBatchFromLWC(UserInfo.getUserId(), true, (String)testQuota.Id);
    }

    @isTest
	static void testRunBatchAndReturnTrue() {
    	Automation_Settings__c adrConfig = new Automation_Settings__c(
                                                Name = 'ADR Incentive',
                                                Data__c = '{"lastRunJobId":"707Wr000016siJYIAY"}');
    	insert adrConfig;

    	Map<String, Object> configData = (Map<String, Object>) JSON.deserializeUntyped(adrConfig.Data__c);

    	User adrOwner = [SELECT Id, Name, UserRole.Name FROM User WHERE IsActive = TRUE
                            AND (UserRole.Name LIKE '%Fleet ADR OB SLED NA US%' 
                                OR UserRole.Name LIKE '%Fleet ADR OB NA US%')
                            AND ADR_Segment_Alignment__c = 'AE2'
                            LIMIT 1];

    	Boolean initiatedByAgent = true;

        User adrTestUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
    	Quota__c testQuota = new Quota__c(
                                User__c = adrTestUser.Id,
                                Fiscal_Period__c = 'FY23',
                                Adj_Role_Start_Date_v2__c = Date.Today().addDays(-15),
                                Fiscal_Period_End_Date__c = Date.today().addDays(-10),
                                Fiscal_Period_Start_Date__c = Date.today().addDays(-20),
                                ADR_Quota__c = 100);

    	insert testQuota;

    	Test.startTest();

    	Id batchJobId = Database.executeBatch(new ADRIncentiveBatch(adrOwner.Id, true, testQuota.Id));

    	Boolean result;
    	System.runAs(adrOwner) {
            result = ADRIncentiveBatch.runBatchAndReturnTrue(adrConfig, configData, adrOwner.Id, true, testQuota.Id);
   	 	}

    	Test.stopTest();

    	System.assert(batchJobId != null, 'Batch job ID should not be null');
    	System.assert(result, 'Result should be true after running the batch');
	}


    /*HELPER METHODS*/

    private static Account createAccount(String writtenLanguage, String accountName, String segment) {
        Account testAccount = new Account();
        testAccount.Name = accountName;
        testAccount.Industry = 'Biotechnology';
        testAccount.Organization_Size__c = '500 - 999';
        testAccount.BillingStreet = '123 main';
        testAccount.BillingCity = 'Missoula';
        testAccount.BillingState = 'California';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingPostalCode = '59801';
        testAccount.Billing_Email__c = 'foo@bar.com';
        testAccount.Segment_Text_stamped__c = segment;
        testAccount.Approved_Payment_Type__c = 'Direct Monthly';
        testAccount.Which_written_language__c = writtenLanguage;
        return testAccount;
    }

    private static Opportunity createOppty(String shippingCarrier, String returnType, Id accountId) {
        Opportunity testOppty = new Opportunity();
        testOppty.Can_Create__c = true;
        testOppty.ForecastCategoryName = 'Forecast';
        testOppty.Shipping_Method__c = 'Will Call';
        testOppty.Type = returnType;
        testOppty.Shipping_Email_Sent_bypassed__c = false;
        testOppty.Shipping_Country__c = 'Canada';
        testOppty.Shipping_Carrier__c = shippingCarrier;
        testOppty.Pricebook2Id = Test.getStandardPricebookId();
        testOppty.Name = 'Test Opportunity';
        testOppty.AccountId = accountId;
        testOppty.ACV_Bookings_Copy__c = 0;
        testOppty.Amount = 150000000;
        testOppty.CloseDate = Date.today().addDays(30);
        testOppty.ACV_Commissionable_Dollars_Copy__c = 0;
        testOppty.Internal_Finance__c = 'Approved';
        testOppty.Internal_Financing_Response_Timestamp__c = Datetime.now();
        testOppty.LeadSource = 'Italian';
        testOppty.Lead_Source_Encoded__c = 2019072519;
        testOppty.netsuite_conn__Order_Type__c = 'Contract - New';
        testOppty.Owner_Role_Copy__c = 'Management';
        testOppty.Selected_Payment_Type__c = 'Upfront Payments';
        testOppty.Shipping_Address_New_Concatenated__c = ',';
        testOppty.StageName = 'Qualified';
        testOppty.Went_to_closed_won_date__c = datetime.now().adddays(30);
        testOppty.Split_New_ACV__c = 100.00;
        testOppty.Split_Renewal_ACV__c = 100.00;
        testOppty.License_Term__c = 12;
        testOppty.CurrencyIsoCode = 'USD';
        return testOppty;
    }
}