@isTest
private class AdrTransferOpportunityLinkBatchTest {

    @TestSetup
    static void setupData() {

        Account acc = new Account(Name = 'Test Account RODRIGO USA - Partner', Organization_Size__c = '5000+', BillingCountry = 'United States', 
                                        Partner_Type__c='Insurance', Program_Type__c='Premium Discount',
                                        BillingStateCode='TX', Industry = 'Other', Account_Lifetime_ACV__c=40000,
                                        CSM_Initial_onboarding_completed_Time__c = datetime.now());
        insert acc;

        Contact con = new Contact(FirstName = 'Test',
                LastName = 'Contact',
                AccountId = acc.Id,
                email = 'kelly@slater.com');

        insert con;

        Profile profile = [SELECT Id FROM Profile WHERE Name LIKE '%ADR%' LIMIT 1];
        
        String uniqueUsername1 = 'adr.test.' + DateTime.now().getTime() + '@example.com';
        String uniqueUsername2 = 'adr.test2.' + DateTime.now().getTime() + '@example.com';
        
        User adrUser = new User(
            Alias = 'adr',
            Email = 'adruser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test ADR User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = uniqueUsername1,
            ADR_Segment_Alignment__c = 'Enterprise',
            EmployeeNumber = '1000775',
            ProfileId = profile.Id
        );

        insert adrUser;

        User aeDemoTransferTo = new User(
            Alias = 'aeDemo',
            Email = 'aeuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test ADR User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = uniqueUsername2,
            Region__c = 'North America',
            EmployeeNumber = '1000778',
            ProfileId = profile.Id
        );

        insert aeDemoTransferTo;


        ADR_Transfer_Log__c atl = new ADR_Transfer_Log__c(
            Account__c = acc.Id,
            Contact__c = con.Id,
            OwnerId = adrUser.Id,
            AE_Demo_Transfer_To__c = aeDemoTransferTo.Id,
            ADR_Transfer_Status__c = 'Accepted and Qualified',
            ADR_Transfer_Date__c = DateTime.now().addDays(-5)
        );

        insert atl;

        Test.setCreatedDate(atl.Id, DateTime.now().addSeconds(-2));

        ADR_Transfer_Log__c atl2 = new ADR_Transfer_Log__c(
            Account__c = acc.Id,
            Contact__c = con.Id,
            OwnerId = adrUser.Id,
            AE_Demo_Transfer_To__c = aeDemoTransferTo.Id,
            ADR_Transfer_Status__c = 'Accepted and Qualified',
            ADR_Transfer_Date__c = DateTime.now().addDays(-5)
        );

        insert atl2;

        Test.setCreatedDate(atl2.Id, DateTime.now().addSeconds(-1));

        Opportunity opp = new Opportunity(
            Type = 'Revenue Opportunity',
            Name = 'Opp Testers 5 Inc',
            StageName = 'Proposal',
            //Shipping_Contact__c = contactOne.Id, 
            Price_Book_Name__c = 'Standard',
            Configuration_Segment__c = 'Non Express',
            SBQQ__Renewal__c = TRUE,
            License_Term_CPQ__c = 36, Rebate_Amount__c=1,
            Selected_Payment_Type__c = 'Direct Annual',
            AccountId = acc.Id,
            Related_Contact__c = con.Id,
            CloseDate = Date.today().addDays(200)
        );

        insert opp;

        // Test.setCreatedDate(opp.Id, DateTime.now().addSeconds(-20));

        Opportunity opp2 = new Opportunity(
            Type = 'Revenue Opportunity',
            Name = 'Opp Testers',
            StageName = 'Proposal',
            Price_Book_Name__c = 'Standard',
            Configuration_Segment__c = 'Non Express',
            SBQQ__Renewal__c = TRUE,
            License_Term_CPQ__c = 36, Rebate_Amount__c=1,
            Selected_Payment_Type__c = 'Direct Annual',
            AccountId = acc.Id,
            Related_Contact__c = con.Id,
            CloseDate = Date.today().addDays(200)
        );

        insert opp2;

        // Test.setCreatedDate(opp2.Id, DateTime.now().addSeconds(-10));
    }


    @isTest
    static void testAdrOpportunityLinkBatch() {
        // List<>Account testAccount = [SELECT Id FROM Account LIMIT 1];
        // Contact testContact = [Select Id From Contact Limit 1];
        List<Opportunity> oppList = [SELECT id, createdDate, ADR_Transfer__c FROM Opportunity ORDER BY CreatedDate Asc LIMIT 2];
        List<ADR_Transfer_Log__c> atlList = [SELECT Id, Opportunity__c FROM ADR_Transfer_Log__c ORDER BY CreatedDate Desc LIMIT 2];
        System.Debug('Batch Class Being Tested!');
        Test.startTest();
        // AdrTransferOpportunityLinkBatch linkBatch = new AdrTransferOpportunityLinkBatch();
        // Database.executeBatch(linkBatch);
        AdrOppLinkBatchInvoker.launch();
        Test.stopTest();

        System.assertEquals(True, atlList[0].Opportunity__c == oppList[0].ADR_Transfer__c);

    }

    @isTest
    static void testScheduleJob() {

        Test.startTest();
        String sch = '0 0 1 * * ?';
        AdrTransferOpportunityLinkScheduled adrLinkBatchScheduled = new AdrTransferOpportunityLinkScheduled();

        String jobId = System.schedule('Test adrLinkBatchScheduled', sch, adrLinkBatchScheduled);
        Test.stopTest();
    }
}