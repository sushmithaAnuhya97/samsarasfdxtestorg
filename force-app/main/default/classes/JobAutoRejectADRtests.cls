@isTest
private class JobAutoRejectADRtests {

    @TestSetup
    static void makeData(){
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Samsara ADRs' LIMIT 1];
            UserRole r = [SELECT Id FROM UserRole WHERE Name like '%ADR%' AND Name like '%NA US%' LIMIT 1];
            String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueNameManager = orgId + dateString + randomInt;
            User ADRuser = new User(lastName = 'User',
                                        FirstName = 'testADR',
                                        email = uniqueNameManager + '@test' + orgId + '.org',
                                        Username = uniqueNameManager + '@test' + orgId + '.org',
                                        EmailEncodingKey = 'ISO-8859-1',
                                        Alias = uniqueNameManager.substring(18, 23),
                                        TimeZoneSidKey = 'America/Los_Angeles',
                                        LocaleSidKey = 'en_US',
                                        LanguageLocaleKey = 'en_US',
                                        ProfileId = p.Id,
                                        UserRoleId = r.Id,
                                        EmployeeNumber='123');
            insert ADRuser;
            
            
            List<Account> newAccount = new List<Account>();
            Account account = new Account (Name = 'Test Nish',OwnerId='0051P000003KrI7QAK', Organization_Size__c = '5000+', 
                                        Prospecting_Status__c = 'ADR Prospecting', Book_Of_Business__c = '', 
                                        BillingCountry = 'Canada', Industry = 'Other',  Account_Lifetime_ACV__c=1000, Customer_ARR__c=1000);
            newAccount.add(account);
            insert newAccount;
        }
    }

    @isTest
    static void testJobAutoRejectADR_2Days() {

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User ADRuser = [SELECT Id FROM User WHERE FirstName = 'testADR' AND LastName = 'User'];

        System.runAs (thisUser) {
            Account newAccount = [SELECT Id from Account LIMIT 1];

            ADR_Transfer_Log__c testADRLog1 = new ADR_Transfer_Log__c(
                ADR_Demo_Date__c = date.valueOf('2024-03-04'), // Using a past date
                Email_Sent_SLA_Reminder__c = false,
                ADR_Transfer_Status__c ='Demo Scheduled',
                Account__c = newAccount.Id,
                OwnerId = ADRuser.id,
                ADR_Transfer_By__c = '0051a000002IiV2AAK',
                ADR_Manager_Name_Copy__c = '0051a000002BW9XAAW',
                AE_Demo_Transfer_To__c = UserInfo.getUserId(),
                AE_Manager_Name_Copy_at_Transfer__c = '0051P000003BfIuQAK'
            );
            insert testADRLog1;
        }
        
        Test.startTest();
        JobAutoRejectADR job = new JobAutoRejectADR();
        job.currentDate = date.valueOf('2024-03-06');
        ID batchProcessId = Database.executeBatch(job, 1);
        Test.stopTest();
        
        // Retrieve updated records
        //testADRLog = [SELECT Email_Sent_SLA_Reminder__c, AE_Manager__c FROM ADR_Transfer_Log__c WHERE Id = :testADRLog.Id];
        
        // Perform assertions
        //System.assertEquals(true, testADRLog.Email_Sent_SLA_Reminder__c);
        // Since the Manager_ID__c field is not writeable, we can't directly set it.
        // Instead, we can check if the AE_Manager__c field is correctly populated based on your code's logic.
        //System.assertNotEquals(null, testADRLog.AE_Manager__c);
    }

    @isTest
    static void testJobAutoRejectADR_3Days() {

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User ADRuser = [SELECT Id FROM User WHERE FirstName = 'testADR' AND LastName = 'User'];

        System.runAs (thisUser) {
            Account newAccount = [SELECT Id from Account LIMIT 1];

            ADR_Transfer_Log__c testADRLog1 = new ADR_Transfer_Log__c(
                ADR_Demo_Date__c = date.valueOf('2024-03-04'), // Using a past date
                Email_Sent_SLA_Reminder__c = true,
                ADR_Transfer_Status__c ='Demo Scheduled',
                Account__c = newAccount.Id,
                OwnerId = ADRuser.id,
                ADR_Transfer_By__c = '0051a000002IiV2AAK',
                ADR_Manager_Name_Copy__c = '0051a000002BW9XAAW',
                AE_Demo_Transfer_To__c = UserInfo.getUserId(),
                AE_Manager_Name_Copy_at_Transfer__c = '0051P000003BfIuQAK'
            );
            insert testADRLog1;
        }
        
        Test.startTest();
        JobAutoRejectADR job = new JobAutoRejectADR();
        job.currentDate = date.valueOf('2024-03-07');
        ID batchProcessId = Database.executeBatch(job, 1);
        Test.stopTest();
        
        // Retrieve updated records
        //testADRLog = [SELECT Email_Sent_SLA_Reminder__c, AE_Manager__c FROM ADR_Transfer_Log__c WHERE Id = :testADRLog.Id];
        
        // Perform assertions
        //System.assertEquals(true, testADRLog.Email_Sent_SLA_Reminder__c);
        // Since the Manager_ID__c field is not writeable, we can't directly set it.
        // Instead, we can check if the AE_Manager__c field is correctly populated based on your code's logic.
        //System.assertNotEquals(null, testADRLog.AE_Manager__c);
    }

        @isTest
        static void testSchedulerExecution() {
            
            // Schedule the Schedulable class
            Test.startTest();
            String cronExp = '0 0 0 * * ?'; // Set the schedule to run every day at midnight
            System.schedule('Test Job', cronExp, new JobAutoRejectADR());
            Test.stopTest();
            
            // Assert or perform checks on the scheduled execution
            // ... (assertions or debug statements)
        }
    @isTest
    static void testSendErrorEmail() {
        // Create a test error message
        String errorMessage = 'Test error message';

        // Create a mock Email service
        Test.startTest();

        // Call the sendErrorEmail method
        JobAutoRejectADR job = new JobAutoRejectADR();
        job.sendErrorEmail(errorMessage);

        // Use Test.stopTest() to send the email
        Test.stopTest();

        // Verify the email by checking the email logs
        List<EmailMessage> emailLogs = [SELECT Subject, ToAddress, HtmlBody FROM EmailMessage WHERE Subject = 'Error in Batch Processing' LIMIT 1];

        // Assert that an email log with the expected subject and recipient exists
        System.assertEquals(1, emailLogs.size());
        EmailMessage emailLog = emailLogs[0];
        System.assertEquals('Error in Batch Processing', emailLog.Subject);
        System.assertEquals('nishita.dhar@samsara.com', emailLog.ToAddress);
        // You can also assert the email body and other properties if needed
    }
    
}