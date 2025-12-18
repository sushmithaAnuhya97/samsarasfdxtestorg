/***********************************************************************************************************************************************
* Date      	- Project#     - Developer/ Company      	   - Description
* ----------------------------------------------------------------------------------------------------------------------------------------------
* 01/06/2025    - Flex         - Anas Siddiquee/ Accenture 	   - Test class for Cancel & Replace Amendment Process
*											
*/

@IsTest
public class FlexAccountCancelReplaceControllerTest {
    public static String currentTestMethod;
    
    /**
* @description - Sets up test data for the test methods by creating test accounts, opportunities, quotes, contracts and other related records
*/
    @TestSetup
    private static void testDataSetup() {
        bypassTriggers();
        // Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        // Create Product
        List<Product2> productList = new List<Product2>();
        Product2 vgLicense = new Product2(
            Name= 'LIC-VG-36MO', 
            ProductCode = 'LIC-VG-36MO', 
            Family = 'Test', 
            IsActive = true, 
            SBQQ__SubscriptionPricing__c = 'Fixed Price'
        );
        productList.add(vgLicense); 
        Product2 ineligibleProduct = new Product2(
            Name= 'Ineligible Product', 
            ProductCode = 'IE', 
            Family = 'Test', 
            IsActive = true, 
            SBQQ__SubscriptionPricing__c = 'Fixed Price'
        );
        productList.add(ineligibleProduct);
        Product2 eligibleProduct = new Product2(
            Name= 'Eligible Product', 
            ProductCode = 'IE', 
            Family = 'Test', 
            IsActive = true, 
            SBQQ__SubscriptionPricing__c = 'Fixed Price'
        );
        productList.add(eligibleProduct); 
        Product2 eligibleProductUpgrade = new Product2(
            Name= 'Eligible Product Upgrade', 
            ProductCode = 'IE', 
            Family = 'Test', 
            IsActive = true, 
            SBQQ__SubscriptionPricing__c = 'Fixed Price'
        );
        productList.add(eligibleProductUpgrade);

        Product2 originalProduct1 = new Product2(
            Name= 'Original Product One', 
            ProductCode = 'IE', 
            Family = 'Test', 
            IsActive = true, 
            SBQQ__SubscriptionPricing__c = 'Fixed Price'
        );
        productList.add(originalProduct1);
        insert productList;
        
        // Create PriceBookEntries
        List<PricebookEntry> pricebookEntriesList = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = productList[0].Id, 
            UnitPrice = 10000, 
            IsActive = true
        );
        pricebookEntriesList.add(vg33PB);
        PricebookEntry ineligibleProductPricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = [SELECT Id, Name FROM Product2 WHERE Name = 'Ineligible Product'].Id, 
            UnitPrice = 100, 
            IsActive = true
        );
        pricebookEntriesList.add(ineligibleProductPricebookEntry);
        PricebookEntry eligibleProductPricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = [SELECT Id, Name FROM Product2 WHERE Name = 'Eligible Product'].Id, 
            UnitPrice = 100, 
            IsActive = true
        );        
        pricebookEntriesList.add(eligibleProductPricebookEntry);

        PricebookEntry eligibleProductUpgradePricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = [SELECT Id, Name FROM Product2 WHERE Name = 'Eligible Product Upgrade'].Id, 
            UnitPrice = 100, 
            IsActive = true
        );        
        pricebookEntriesList.add(eligibleProductUpgradePricebookEntry);

        PricebookEntry originalProductOnePricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = [SELECT Id, Name FROM Product2 WHERE Name = 'Original Product One'].Id, 
            UnitPrice = 100, 
            IsActive = true
        );        
        pricebookEntriesList.add(originalProductOnePricebookEntry);
        insert pricebookEntriesList;
        
        // Create Accounts
        Account testAccount = TestFactory.initializeAccount('Test Account');
        Account shippingAddressAccount = TestFactory.initializeAccount('Shipping Address Account');
        insert new List<Account> { testAccount, shippingAddressAccount };
            
            // Create Opportunity
        List<Opportunity> newOppsList = new List<Opportunity>();
        Opportunity revenueOpportunity1 = new Opportunity(
            AccountId = testAccount.Id, 
            License_Term__c = 36, 
            Pricebook2Id = pricebookId, 
            Max_Approved_Discount__c = 0, 
            Name = 'Revenue Opportunity1', 
            Price_Book_Name__c = 'Standard Price Book', 
            CloseDate = System.today() + 90, 
            StageName = 'Incubate', 
            Owner_Role_Copy__c = 'Fleet IS AE2 NA US Team 8',
            Selected_Payment_Type__c = 'Direct Annual'
        ); 
        newOppsList.add(revenueOpportunity1);
        insert newOppsList;
        
        // Create OpportunityLineItems
        List<OpportunityLineItem> oppProductList = new List<OpportunityLineItem>();
        OpportunityLineItem ol1 = new OpportunityLineItem(
            OpportunityId = newOppsList[0].Id, 
            Quantity = 2, 
            PricebookEntryId = pricebookEntriesList[0].Id, 
            UnitPrice = pricebookEntriesList[0].UnitPrice
        );
        oppProductList.add(ol1);
        insert oppProductList;
        System.debug('oppProductList: ' + oppProductList);
        
        // Create quote
        createQuoteData();
        List<SBQQ__Quote__c> quoteList = [SELECT Id FROM SBQQ__Quote__c];
        System.debug('Enter quoteList ' + quoteList.size());
        
        // Create Contracts
        List<Contract> contractList = new List<Contract>(); 
        Contract contract1 = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c = revenueOpportunity1.Id,
            SBQQ__Quote__c = quoteList[0].Id
        );
        contractList.add(contract1);
        insert contractList;
        
        // Create Subscriptions
        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = contractList[0].id,
            SBQQ__Account__c = testAccount.id,
            SBQQ__Product__c = productList[0].Id
        );
        subList.add(sub1);
        insert subList;
        
        // Activate Contracts
        List<Contract> contractsToUpdate = [SELECT Id, Is_Active__c, Status, Deactivated__c FROM Contract WHERE AccountId = :testAccount.Id];
        for(Contract cont : contractsToUpdate) {
            cont.Status = 'Activated';
        }
        update contractsToUpdate;
        
        // Create Custom Settings
        FlexConstants__c flexConstants = new FlexConstants__c(
            Name = 'FlexConstants',
            RetryAttemptLimit__c = 1,
            ContractAmendmentProcessTime__c = 2,
            PostContractAmendmentWaitTime__c = 1,
            Carryover_Products__c = 'Carryover Products',
            Upgraded_Products__c = 'Upgraded Products',
            Net_New_Products__c = 'Net New Products'
        );
        insert flexConstants;
        
        // Create Contact and Shipping Address
        Contact contact = new Contact(
            AccountId = shippingAddressAccount.Id,
            LastName = 'Test Contact'
        );
        insert contact;
        
        Shipping_Address__c sa = new Shipping_Address__c(
            Shipping_Zip_Code__c = '94105', 
            Shipping_Contact__c = contact.Id, 
            Shipping_Address_Line_1__c = '1 Dolores, Dallas', 
            Shipping_City__c = 'Dallas', 
            Shipping_Country__c = 'United States', 
            Shipping_State__c = 'Texas', 
            Name = 'Test', 
            Account__c = shippingAddressAccount.Id
        );
        insert sa;
    }
    
    /**
* @description - Helper method to create quote test data
*/
    public static void createQuoteData() {
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        Map<String, Opportunity> oppNameToOppMap = new Map<String, Opportunity>();
        for (Opportunity testOpportunity : [SELECT id, Name From Opportunity]) {
            oppNameToOppMap.put(testOpportunity.Name, testOpportunity);
        }        
        
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        for (Opportunity o : oppNameToOppMap.values()) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                Quote_Name__c = 'Test Flex ', 
                SBQQ__Account__c = testAccount.Id, 
                SBQQ__Opportunity2__c = o.Id,
                SBQQ__SubscriptionTerm__c = 10,
                Estimated_Annual_Payment__c = 24, 
                Selected_Payment_Type__c = 'Direct Annual',
                SBQQ__Status__c = 'Draft',
                SBQQ__Primary__c = true
            );
            quoteList.add(quote);
        }
        
        insert quoteList;
    }
    
    /**
* @description - Tests the successful amendment of contracts for booking scenario
* Verifies creation of replacement opportunity, quote and flex logs
*/
    @IsTest
    static void testFlexAmendContractsForBooking() {
        bypassTriggers();
        // Retrieve test data
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Selected_Payment_Type__c, SBQQ__Primary__c FROM SBQQ__Quote__c];
        System.debug('test => ' + quoteList.size());
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        
        List<String> contractIdsList = new List<String>();
        for (Contract contract : [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id]) {
            contractIdsList.add(contract.Id);
        }
        System.debug('Enter contractIdsList ' + contractIdsList.size());
        System.debug(String.valueOf(Date.today()));
        System.debug(String.valueOf(Date.today().addMonths(36)));
        
        Test.startTest();
        // Create amendment request
        FlexAmendContractsMsg amendContracts = new FlexAmendContractsMsg();
        amendContracts.contractIds = contractIdsList;
        amendContracts.startDate = String.valueOf(Date.today());
        amendContracts.accountId = testAccount.Id;
        amendContracts.termLength = 36;
        amendContracts.isRebook = false;
        amendContracts.endDate = String.valueOf(Date.today().addMonths(36));
        System.debug('Enter FlexAmendContractsMsg ' + amendContracts);
        
        
        FlexAccountCancelReplaceController.FlexAmendResponse response = FlexAccountCancelReplaceController.flexAmendContracts(amendContracts);
        System.debug('result => ' + response);
        System.assertEquals(true, response.success);
        System.assertEquals(null, response.errorMessage);
        
        // Verify replacement opportunity and quote created
        List<Opportunity> replacementOpp = [SELECT Id, Name FROM Opportunity WHERE Sub_Type__c = 'Contract Replacement'];
        System.assertEquals(1, replacementOpp.size(), 'Replacement Opportunity not created!');
        system.debug('TT replacementOpp ' +replacementOpp);
        
        if (replacementOpp != null) {
            List<SBQQ__Quote__c> replacementQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :replacementOpp[0].Id];
            System.assertEquals(1, replacementQuote.size(), 'Replacement Quote not created!');
        }
        Test.stopTest();
        
        // Verify logs created and updated
        List<Flex_Log__c> logs = [
            SELECT Id, Status__c 
            FROM Flex_Log__c 
            WHERE AccountId__c = :testAccount.Id
        ];
        System.assertEquals(contractIdsList.size(), logs.size(), 'Log size does not match the number of contract IDs');
    }
    
    /**
* @description - Tests the successful amendment of contracts for rebooking scenario
* Verifies creation of replacement opportunity, quote and flex logs
*/
    @IsTest
    static void testFlexAmendContractsForRebooking() {
        // Retrieve test data
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Selected_Payment_Type__c, SBQQ__Primary__c FROM SBQQ__Quote__c];
        System.debug('test => ' + quoteList.size());
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        
        bypassTriggers();
        List<String> contractIdsList = new List<String>();
        for (Contract contract : [SELECT Id,Is_Active__c,Status,Deactivated__c, contract.AccountId FROM Contract WHERE AccountId = :testAccount.Id] ) {
            System.debug('Enter Account ID '+contract.AccountId);
            system.debug('Contract ID '+contract.Id+' status '+ contract.Status+ ' Is_Active__c '+contract.Is_Active__c+' Deactivated__c '+contract.Deactivated__c);
            contractIdsList.add(contract.Id);
        }
        
        System.debug('Enter contractIdsList ' + contractIdsList.size());
        System.debug(String.valueOf(Date.today()));
        System.debug(String.valueOf(Date.today().addMonths(36)));
        
        Test.startTest();
        // Test data to input flexAmendContracts method of FlexAccountCancelReplaceController
        FlexAmendContractsMsg amendContracts = new FlexAmendContractsMsg();
        amendContracts.contractIds = contractIdsList;
        amendContracts.startDate = String.valueOf(Date.today());
        amendContracts.accountId = testAccount.Id;
        amendContracts.termLength = 36;
        amendContracts.isRebook = true;
        amendContracts.endDate = String.valueOf(Date.today().addMonths(36));
        System.debug('TT Enter FlexAmendContractsMsg ' + amendContracts);
        
        FlexAccountCancelReplaceController.FlexAmendResponse response = FlexAccountCancelReplaceController.flexAmendContracts(amendContracts);
        System.debug('result => ' + response);
        System.assertEquals(true, response.success);
        System.assertEquals(null, response.errorMessage);
        
        // Verify replacement opportunity and quote created
        List<Opportunity> replacementOpp = [SELECT Id, Name FROM Opportunity WHERE Sub_Type__c = 'Contract Replacement'];
        System.assertEquals(1, replacementOpp.size(), 'Replacement Opportunity not created!');
        system.debug('TT replacementOpp ' +replacementOpp);
        
        if (replacementOpp != null) {
            List<SBQQ__Quote__c> replacementQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :replacementOpp[0].Id];
            System.assertEquals(1, replacementQuote.size(), 'Replacement Quote not created!');
        }
        Test.stopTest();
        
        // Verify logs created and updated
        List<Flex_Log__c> logs = [
            SELECT Id, Status__c 
            FROM Flex_Log__c 
            WHERE AccountId__c = :testAccount.Id
        ];
        System.assertEquals(contractIdsList.size(), logs.size(), 'Log size does not match the number of contract IDs');
    }
    
    /**
* @description - Tests the failure scenario of contract amendment process
* Verifies error handling and log updates
*/
    @IsTest
    static void testFlexAmendContractsFailure() {
        bypassTriggers();
        // Retrieve test data
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Selected_Payment_Type__c, SBQQ__Primary__c FROM SBQQ__Quote__c];
        System.debug('test => ' + quoteList.size());
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        
        List<Contract> contractsToUpdate = [SELECT Id,Is_Active__c,Status,Deactivated__c FROM Contract WHERE AccountId = :testAccount.Id];
        
        List<String> contractIdsList = new List<String>();
        for (Contract contract : contractsToUpdate ) {
            system.debug('Contract ID '+contract.Id+' status '+ contract.Status+ ' Is_Active__c '+contract.Is_Active__c+' Deactivated__c '+contract.Deactivated__c);
            contractIdsList.add(contract.Id);
        }
        
        System.debug('Enter contractsToUpdate ' + contractsToUpdate.size());
        System.debug(String.valueOf(Date.today()));
        System.debug(String.valueOf(Date.today().addMonths(36)));
        
        // Update SBQQ__Subscription__c records to create an error in C&R process
        Shipping_Address__c sa = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        List<SBQQ__Subscription__c> subscriptionsToUpdate = [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__Account__c = :testAccount.Id];
        for (SBQQ__Subscription__c subscription : subscriptionsToUpdate) {
            subscription.Ship_To__c = sa.Id;
        }
        update subscriptionsToUpdate;
        
        Test.startTest();
        // Test data to input flexAmendContracts method of FlexAccountCancelReplaceController
        FlexAmendContractsMsg amendContracts = new FlexAmendContractsMsg();
        amendContracts.contractIds = contractIdsList;
        amendContracts.startDate = String.valueOf(Date.today());
        amendContracts.accountId = testAccount.Id;
        amendContracts.termLength = 36;
        
        amendContracts.endDate = String.valueOf(Date.today().addMonths(36));
        System.debug('TT Enter FlexAmendContractsMsg ' + amendContracts);
        
        
        FlexAccountCancelReplaceController.FlexAmendResponse response = FlexAccountCancelReplaceController.flexAmendContracts(amendContracts);
        System.debug('result => ' + response);
        System.assertEquals(false, response.success);
        
        
        Test.stopTest();
        
        // Verify logs created and updated
        List<Flex_Log__c> logs = [
            SELECT Id, Status__c 
            FROM Flex_Log__c 
            WHERE AccountId__c = :testAccount.Id
        ];
        System.assertEquals(contractsToUpdate.size(), logs.size(), 'Log size does not match the number of contract IDs');
    }
    
    /**
* @description - Tests successful amendment API call
* Verifies creation of cancellation opportunity and quote
*/
    @IsTest
    static void testAmendApiSuccess() {
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        Contract contract = [ SELECT Id FROM Contract LIMIT 1];
        Flex_Log__c logRecord = new Flex_Log__c(
            Status__c = 'Completed',  
            AccountId__c = testAccount.Id, 
            ContractId__c = contract.Id
        );
        insert logRecord;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        FlexCancelAndReplaceHandler.callAmenderApi(String.valueOf(contract.Id), Date.today(), String.valueOf(opp.Id), false);
        Test.stopTest();
        // Checking cancellation Opp and Quote creation 
        List<Opportunity> cancellationOppList =  [ SELECT Id FROM Opportunity WHERE Sub_Type__c = 'Contract Cancellation'];
        System.assertEquals(1, cancellationOppList.size(), 'Cancellation Opportunity not created!');
        
        if(cancellationOppList.size() > 0) {
            List<SBQQ__Quote__c> cancellationQuoteList = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN :cancellationOppList];
            System.assertEquals(1, cancellationQuoteList.size(), 'Cancellation Quote not created!');
        }
    }
    
    /**
* @description - Tests amendment API failure scenario
* Verifies error handling when amendment fails
*/
    @IsTest
    static void testAmendApiFailure() {
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        Contract contract = [ SELECT Id FROM Contract LIMIT 1];
        Flex_Log__c logRecord = new Flex_Log__c(
            Status__c = 'In Progress',  
            AccountId__c = testAccount.Id, 
            ContractId__c = contract.Id
        );
        insert logRecord;
        
        // Update SBQQ__Subscription__c records to create an error in C&R process
        Shipping_Address__c sa = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        List<SBQQ__Subscription__c> subscriptionsToUpdate = [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__Account__c = :testAccount.Id];
        for (SBQQ__Subscription__c subscription : subscriptionsToUpdate) {
            subscription.Ship_To__c = sa.Id;
        }
        update subscriptionsToUpdate;
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        FlexCancelAndReplaceHandler.callAmenderApi(String.valueOf(contract.Id), Date.today(), String.valueOf(opp.Id), false);
        Test.stopTest();
        // Checking cancellation Opp and Quote creation 
        List<Opportunity> cancellationOppList =  [ SELECT Id FROM Opportunity WHERE Sub_Type__c = 'Contract Cancellation'];
        //System.assertEquals(0, cancellationOppList.size(), 'Cancellation Opportunity should not have been created!');
        
        if(cancellationOppList.size() > 0) {
            List<SBQQ__Quote__c> cancellationQuoteList = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN :cancellationOppList];
            //System.assertEquals(0, cancellationQuoteList.size(), 'Cancellation Quote should not have been not created!');
        }
    }
    
    /**
* @description - Tests the quote line queueable notification functionality
* Verifies email notifications are sent correctly
*/
    @IsTest
    static void testFlexQuoteLineQueueableNotification() {
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        
        List<String> contractIdsList = new List<String>();
        for (Contract contract : [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id]) {
            contractIdsList.add(contract.Id);
        }
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'Completed',  
            AccountId__c = testAccount.Id, 
            ContractId__c =contractIdsList[0],
            RevenueOpportunityId__c = opp.Id 
        );
        logRecordList.add(logRecord1);
        insert logRecordList;
        FlexQuoteLineQueueable flexQuoteLineQueueable = new FlexQuoteLineQueueable(logRecordList);
        Test.startTest();
        System.enqueueJob(new FlexQuoteLineQueueable(logRecordList));
        Test.stopTest();
        // Check if the email was sent
        // List<EmailMessage> sentEmails = [SELECT Id FROM EmailMessage];
        // System.assertEquals(1, sentEmails.size(), 'Notification email not sent');  
    }
    
    /**
* @description - Tests quote line queueable with failed logs
* Verifies error handling and notifications for failed logs
*/
    @IsTest
    static void testFlexQuoteLineQueueableWithFailedLogs() {
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        List<Id> contractIdsList = new List<String>();
        for (Contract contract : [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id]) {
            contractIdsList.add(contract.Id);
        }
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'Failed',  
            AccountId__c = testAccount.Id, 
            ContractId__c = contractIdsList[0], 
            ErrorMessage__c = 'Error Occured !!'
        );
        logRecordList.add(logRecord1);
        insert logRecordList;
        FlexQuoteLineQueueable flexQuoteLineQueueable = new FlexQuoteLineQueueable(logRecordList);
        Test.startTest();
        System.enqueueJob(new FlexQuoteLineQueueable(logRecordList));
        Test.stopTest();
        
        // Check if the email was sent
        // List<EmailMessage> sentEmails = [SELECT Id FROM EmailMessage];
        // System.assertEquals(1, sentEmails.size(), 'Email not sent');
    }
    
    /**
* @description - Tests quote line queueable with no logs
* Verifies behavior when no logs are present
*/
    @IsTest
    static void testFlexQuoteLineQueueableWithNoLogs() {
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        List<String> contractIdsList = new List<String>();
        for (Contract contract : [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id]) {
            contractIdsList.add(contract.Id);
        }
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'Failed',   
            ErrorMessage__c = 'Error Occured !!'
        );
        logRecordList.add(logRecord1);
        insert logRecordList;
        FlexQuoteLineQueueable flexQuoteLineQueueable = new FlexQuoteLineQueueable(logRecordList);
        Test.startTest();
        System.enqueueJob(new FlexQuoteLineQueueable(logRecordList));
        Test.stopTest();
        
        // Check that no email was sent
        List< EmailMessage> sentEmails = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, sentEmails.size(), 'Email should not have been sent');
    }
    
    
    @IsTest
    static void testFlexQuoteLineQueueable_failed() {
        currentTestMethod = 'testFlexQuoteLineQueueable_failed';
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        List<String> contractIdsList = new List<String>();
        for (Contract contract : [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id]) {
            contractIdsList.add(contract.Id);
        }
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'Failed',   
            ErrorMessage__c = 'Error Occured !!'
        );
        logRecordList.add(logRecord1);
        insert logRecordList;
        FlexQuoteLineQueueable flexQuoteLineQueueable = new FlexQuoteLineQueueable(logRecordList);
        Test.startTest();
        System.enqueueJob(new FlexQuoteLineQueueable(logRecordList));
        Test.stopTest();
        
        // Check that no email was sent
        List< EmailMessage> sentEmails = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, sentEmails.size(), 'Email should not have been sent');
    }
    
    
    /**
* @description - Tests handling of future jobs when status is in progress
* Verifies job re-queuing behavior
*/
    @isTest
    static void testHandleFutureJobsInProgress() {
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        // Create Flex Log record
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'In Progress',  
            AccountId__c = testAccount.Id, 
            ContractId__c = testContract.Id
        );
        logRecordList.add(logRecord1);
        insert logRecordList;
        
        FlexAmendQueueableParams params = new FlexAmendQueueableParams.Builder()
            .withContractIdList(new List<String>{testContract.Id})
            .withStartDate(Date.Today())
            .withLogRecordList(logRecordList)
            .withCurrentIndex(10)
            .withIsRebook(false)
            .withQueueableJobIdSet(new Set<Id>())
            .build();
        
        Test.startTest();
        // Mock the future jobs status check
        FlexTestMocks.setMock(
            FlexCancelReplaceHelper.class,
            'hasFutureJobsCompleted',
            new List<String>{'In Progress'}
        );
        System.enqueueJob(new FlexAmendQueueable(params));
        Test.stopTest();
        
        // Verify that the job was re-enqueued (by checking debug logs or related records)
        List<AsyncApexJob> jobs = [
            SELECT Id, Status 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = 'FlexAmendQueueable'
            ORDER BY CreatedDate DESC ];
        System.assert(!jobs.isEmpty(), 'Job should have been re-enqueued');
    }
    
    /**
    * @description - Tests handling of future jobs when they fail
    * Verifies error handling and job status updates
    */
    @isTest
    static void testHandleFutureJobsFailure() {
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Opportunity replacementOppId = [ SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Create Flex Log record
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'Failed',  
            AccountId__c = testAccount.Id, 
            ContractId__c = testContract.Id,
            AmendedQuoteId__c= quote.Id
        );
        
        logRecordList.add(logRecord1);
        insert logRecordList;
        
        FlexAmendQueueableParams params = new FlexAmendQueueableParams.Builder()
            .withContractIdList(new List<String>{testContract.Id})
            .withStartDate(Date.Today())
            .withLogRecordList(logRecordList)
            .withCurrentIndex(10)
            .withIsRebook(false)
            .withQueueableJobIdSet(new Set<Id>())
            .withQuoteRecalcStarted(true)
            .withRetryCount(0)
            .build();
        
        Test.startTest();
        FlexCancelAndReplaceHandler.callAmenderApi(testContract.Id, Date.Today(), replacementOppId.Id, true);
        System.enqueueJob(new FlexAmendQueueable(params));
        Test.stopTest();
        
        // Verify that the job was re-enqueued (by checking debug logs or related records)
        List<AsyncApexJob> jobs = [
            SELECT Id, Status 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = 'FlexAmendQueueable'
            ORDER BY CreatedDate DESC
        ];
        System.assert(!jobs.isEmpty(), 'Job should have been re-enqueued');
        System.assertEquals(1, jobs.size(), 'Job should');
    }


    public static FlexAmendContractsMsg prepareAmendContractData(Boolean updateContact) {
        // Fetch required records using helper methods
        Account testAccount = getAccountByPartialName('Test Account');
        Contract testContract = getAnyContract();
        Opportunity replacementOpp = getAnyOpportunity();
        Contact con = getContactByLastName('Test Contact');
        Shipping_Address__c shipTo = getShippingAddressByName('Test');
        SBQQ__Quote__c quote = getAnyQuote();
        Product2 eligibleProductUpgrade = getProductByName('Eligible Product Upgrade');
        Product2 originalProduct = getProductByName('Original Product One');
        Product2 eligibleProduct = getProductByName('Eligible Product');
        Product2 ineligibleProduct = getProductByName('Ineligible Product');
    
        // Conditional update of Contact
        if (updateContact && con != null && testAccount != null) {
            con.AccountId = testAccount.Id;
            update con;
        }
    
        // Update Shipping Address Account reference
        if (updateContact && shipTo != null && testAccount != null) {
            shipTo.Account__c = testAccount.Id;
            update shipTo;
        }
    
        // Update Quote fields
        if (quote != null) {
            quote.SBQQ__PriceBook__c = Test.getStandardPricebookId();
            quote.SBQQ__SubscriptionTerm__c = 6;
            update quote;
        }
    
        // Build amendContracts message
        FlexAmendContractsMsg amendContracts = new FlexAmendContractsMsg();
        amendContracts.contractIds = new List<String>{ testContract.Id };
        amendContracts.startDate = '2024-01-01';
        amendContracts.endDate = '2024-12-31';
        amendContracts.termLength = 12;
        amendContracts.isRebook = false;
        amendContracts.originalAccountFlag = true;
        amendContracts.accountId = testAccount.Id;
    
        // Build wrapper data
        ProductWrapper.SelectedUpgradeProduct selectedUpgrade = new ProductWrapper.SelectedUpgradeProduct();
        selectedUpgrade.productId = eligibleProductUpgrade.Id;
        selectedUpgrade.productName = 'WiFi Hotspot - 4GB Total Data';
        selectedUpgrade.productCode = 'LIC-4GB-WIFI-DATA';
        selectedUpgrade.defaultHardwareCodeURL = 'https://example.com/hardware';
        selectedUpgrade.defaultHardwareId = eligibleProductUpgrade.Id;
    
        ProductWrapper.PlatformUpgradeScreenDetail platformDetail = new ProductWrapper.PlatformUpgradeScreenDetail();
        platformDetail.shippingAddressId = shipTo.Id;
        platformDetail.shippingAddressName = shipTo.Name;
        platformDetail.quantity = 1;
        platformDetail.selectedUpgradeProduct = selectedUpgrade;
    
        ProductWrapper.UpgradeProduct upgradeProd = new ProductWrapper.UpgradeProduct();
        upgradeProd.productId = eligibleProduct.Id;
        upgradeProd.productName = 'WiFi Hotspot - 4GB Total Data';
        upgradeProd.productCode = 'LIC-4GB-WIFI-DATA';
        upgradeProd.defaultHardwareCodeURL = 'https://example.com/hardware';
        upgradeProd.defaultHardwareId = eligibleProductUpgrade.Id;
        upgradeProd.upgradeQuantity = 1;
        upgradeProd.remainingQuantity = 3;

        
    
        List<ProductWrapper.ShipToAddress> shipToAddressList2 =  new List<ProductWrapper.ShipToAddress>();

        ProductWrapper.ShipToAddress shipToAddress = new ProductWrapper.ShipToAddress();
        shipToAddress.addressId = shipTo.Id;
        shipToAddress.addressName = shipTo.Name;
        shipToAddress.quantity = 1;
        shipToAddress.isSelectedUpgrade = true;
        shipToAddress.upgradeProduct = upgradeProd;
        shipToAddress.averageMonthlyUnitPrice = 33.5;
        

        ProductWrapper.ShipToAddress shipToAddress2 = new ProductWrapper.ShipToAddress();
        shipToAddress2.addressId = shipTo.Id;
        shipToAddress2.addressName = shipTo.Name;
        shipToAddress2.quantity = 1;
        shipToAddress2.isSelectedUpgrade = true;
        shipToAddress2.upgradeProduct = null;
        shipToAddress2.averageMonthlyUnitPrice = 33.5;

        shipToAddressList2.add(shipToAddress);
        shipToAddressList2.add(shipToAddress2);

    
        ProductWrapper.FinalScreenDetails finalScreen = new ProductWrapper.FinalScreenDetails();
        finalScreen.productId = ineligibleProduct.Id;
        finalScreen.productName = 'WiFi Hotspot - 2GB Total Data';
        finalScreen.productCode = 'LIC-2GB-WIFI-DATA';
        finalScreen.defaultHardwareCodeURL = 'https://example.com/hardware';
        finalScreen.defaultHardwareId = 'None';
        finalScreen.originalTotalQuantity = 2;
        finalScreen.allSelected = true;
        finalScreen.shipToAddresses = shipToAddressList2;
    
        ProductWrapper pw = new ProductWrapper();
        pw.originalProductId = originalProduct.Id;
        pw.originalProductName = 'WiFi Hotspot - 2GB Total Data';
        pw.originalProductCode = 'LIC-2GB-WIFI-DATA';
        pw.defaultHardwareCodeURL = 'https://example.com/hardware';
        pw.defaultHardwareId = 'New';
        pw.originalTotalQuantity = 2;
        pw.isPlatformUpgradeEnabled = true;
        pw.platformUpgradeScreenDetails = new List<ProductWrapper.PlatformUpgradeScreenDetail>{ platformDetail };
        pw.finalScreenDetails = finalScreen;
    

        // Create a List<ProductWrapper> and add pw to it
        List<ProductWrapper> productWrapperList = new List<ProductWrapper>();
        productWrapperList.add(pw);


        // Build wrapper data for scenario-2 : no plateformUpgrade no hardwareUpgrade  
        ProductWrapper.PlatformUpgradeScreenDetail platformDetail1 = new ProductWrapper.PlatformUpgradeScreenDetail();
        platformDetail1.shippingAddressId = shipTo.Id;
        platformDetail1.shippingAddressName = shipTo.Name;
        platformDetail1.quantity = 1;
        platformDetail1.selectedUpgradeProduct = null;
    
        ProductWrapper.ShipToAddress shipToAddress1 = new ProductWrapper.ShipToAddress();
        shipToAddress1.addressId = shipTo.Id;
        shipToAddress1.addressName = shipTo.Name;
        shipToAddress1.quantity = 1;
        shipToAddress1.isSelectedUpgrade = true;
        shipToAddress1.upgradeProduct = null;
        shipToAddress1.averageMonthlyUnitPrice = 33.5;
    
        ProductWrapper.FinalScreenDetails finalScreen1 = new ProductWrapper.FinalScreenDetails();
        finalScreen1.productId = ineligibleProduct.Id;
        finalScreen1.productName = 'WiFi Hotspot - 2GB Total Data';
        finalScreen1.productCode = 'LIC-2GB-WIFI-DATA';
        finalScreen1.defaultHardwareCodeURL = 'https://example.com/hardware';
        finalScreen1.defaultHardwareId = 'None';
        finalScreen1.originalTotalQuantity = 2;
        finalScreen1.allSelected = true;
        finalScreen1.shipToAddresses = new List<ProductWrapper.ShipToAddress>{ shipToAddress1 };
    
        ProductWrapper pw1 = new ProductWrapper();
        pw1.originalProductId = originalProduct.Id;
        pw1.originalProductName = 'WiFi Hotspot - 2GB Total Data';
        pw1.originalProductCode = 'LIC-2GB-WIFI-DATA';
        pw1.defaultHardwareCodeURL = 'https://example.com/hardware';
        pw1.defaultHardwareId = 'New';
        pw1.originalTotalQuantity = 2;
        pw1.isPlatformUpgradeEnabled = false;
        pw1.platformUpgradeScreenDetails = new List<ProductWrapper.PlatformUpgradeScreenDetail>{ platformDetail1 };
        pw1.finalScreenDetails = finalScreen1;
        productWrapperList.add(pw1);
        

        // Build wrapper data for scenario-3 no platefrom upgrade only hardware upgrade
        ProductWrapper.PlatformUpgradeScreenDetail platformDetail3 = new ProductWrapper.PlatformUpgradeScreenDetail();
        platformDetail3.shippingAddressId = shipTo.Id;
        platformDetail3.shippingAddressName = shipTo.Name;
        platformDetail3.quantity = 1;
        platformDetail3.selectedUpgradeProduct = null;
    
    
        ProductWrapper.UpgradeProduct upgradeProd3a = new ProductWrapper.UpgradeProduct();
        upgradeProd3a.productId = eligibleProduct.Id;
        upgradeProd3a.productName = 'WiFi Hotspot - 4GB Total Data';
        upgradeProd3a.productCode = 'LIC-4GB-WIFI-DATA';
        upgradeProd3a.defaultHardwareCodeURL = 'https://example.com/hardware';
        upgradeProd3a.defaultHardwareId = 'None';
        upgradeProd3a.upgradeQuantity = 1;
        upgradeProd3a.remainingQuantity = 0;

        ProductWrapper.UpgradeProduct upgradeProd3b = new ProductWrapper.UpgradeProduct();
        upgradeProd3b.productId = eligibleProduct.Id;
        upgradeProd3b.productName = 'WiFi Hotspot - 4GB Total Data';
        upgradeProd3b.productCode = 'LIC-4GB-WIFI-DATA';
        upgradeProd3b.defaultHardwareCodeURL = 'https://example.com/hardware';
        upgradeProd3b.defaultHardwareId = 'None';
        upgradeProd3b.upgradeQuantity = 1;
        upgradeProd3b.remainingQuantity = 1;
        upgradeProd3b.defaultHardwareId = eligibleProduct.Id;
    
        ProductWrapper.ShipToAddress shipToAddress3a = new ProductWrapper.ShipToAddress();
        shipToAddress3a.addressId = shipTo.Id;
        shipToAddress3a.addressName = shipTo.Name;
        shipToAddress3a.quantity = 1;
        shipToAddress3a.isSelectedUpgrade = true;
        shipToAddress3a.upgradeProduct = upgradeProd3a;
        shipToAddress3a.averageMonthlyUnitPrice = 33.5;
    
        ProductWrapper.ShipToAddress shipToAddress3b = new ProductWrapper.ShipToAddress();
        shipToAddress3b.addressId = shipTo.Id;
        shipToAddress3b.addressName = shipTo.Name;
        shipToAddress3b.quantity = 1;
        shipToAddress3b.isSelectedUpgrade = true;
        shipToAddress3b.upgradeProduct = upgradeProd3b;
        shipToAddress3b.averageMonthlyUnitPrice = 33.5;
        

        ProductWrapper.ShipToAddress shipToAddress3c = new ProductWrapper.ShipToAddress();
        shipToAddress3c.addressId = shipTo.Id;
        shipToAddress3c.addressName = shipTo.Name;
        shipToAddress3c.quantity = 1;
        shipToAddress3c.isSelectedUpgrade = false;
        shipToAddress3c.upgradeProduct = null;
        shipToAddress3c.averageMonthlyUnitPrice = 33.5;

        List<ProductWrapper.ShipToAddress> shipToAddressList = new List<ProductWrapper.ShipToAddress>();
        shipToAddressList.add(shipToAddress3b);
        shipToAddressList.add(shipToAddress3a);
        shipToAddressList.add(shipToAddress3c);



        ProductWrapper.FinalScreenDetails finalScreen3 = new ProductWrapper.FinalScreenDetails();
        finalScreen3.productId = ineligibleProduct.Id;
        finalScreen3.productName = 'WiFi Hotspot - 2GB Total Data';
        finalScreen3.productCode = 'LIC-2GB-WIFI-DATA';
        finalScreen3.defaultHardwareCodeURL = 'https://example.com/hardware';
        finalScreen3.defaultHardwareId = 'None';
        finalScreen3.originalTotalQuantity = 2;
        finalScreen3.allSelected = true;
        finalScreen3.shipToAddresses = shipToAddressList ;
    
        ProductWrapper pw3 = new ProductWrapper();
        pw3.originalProductId = originalProduct.Id;
        pw3.originalProductName = 'WiFi Hotspot - 2GB Total Data';
        pw3.originalProductCode = 'LIC-2GB-WIFI-DATA';
        pw3.defaultHardwareCodeURL = 'https://example.com/hardware';
        pw3.defaultHardwareId = 'New';
        pw3.originalTotalQuantity = 2;
        pw3.isPlatformUpgradeEnabled = false;
        pw3.platformUpgradeScreenDetails = new List<ProductWrapper.PlatformUpgradeScreenDetail>{ platformDetail3 };
        pw3.finalScreenDetails = finalScreen3;
        productWrapperList.add(pw3);


        // scenario
        ProductWrapper.PlatformUpgradeScreenDetail platformDetail4 = new ProductWrapper.PlatformUpgradeScreenDetail();
        platformDetail4.shippingAddressId = shipTo.Id;
        platformDetail4.shippingAddressName = shipTo.Name;
        platformDetail4.quantity = 1;
        platformDetail4.selectedUpgradeProduct = null;

        ProductWrapper.UpgradeProduct upgradeProd4 = new ProductWrapper.UpgradeProduct();
        upgradeProd4.productId = eligibleProduct.Id;
        upgradeProd4.productName = 'WiFi Hotspot - 4GB Total Data';
        upgradeProd4.productCode = 'LIC-4GB-WIFI-DATA';
        upgradeProd4.defaultHardwareCodeURL = 'https://example.com/hardware';
        upgradeProd4.defaultHardwareId = 'None';
        upgradeProd4.upgradeQuantity = 1;
        upgradeProd4.remainingQuantity = 1;
        upgradeProd4.defaultHardwareId = eligibleProduct.Id;
    
        ProductWrapper.ShipToAddress shipToAddress4 = new ProductWrapper.ShipToAddress();
        shipToAddress4.addressId = shipTo.Id;
        shipToAddress4.addressName = shipTo.Name;
        shipToAddress4.quantity = 3;
        shipToAddress4.isSelectedUpgrade = true;
        shipToAddress4.upgradeProduct = upgradeProd4;
        shipToAddress4.averageMonthlyUnitPrice = 33.5;

        ProductWrapper.FinalScreenDetails finalScreen4 = new ProductWrapper.FinalScreenDetails();
        finalScreen4.productId = ineligibleProduct.Id;
        finalScreen4.productName = 'WiFi Hotspot - 2GB Total Data';
        finalScreen4.productCode = 'LIC-2GB-WIFI-DATA';
        finalScreen4.defaultHardwareCodeURL = 'https://example.com/hardware';
        finalScreen4.defaultHardwareId = ineligibleProduct.Id;
        finalScreen4.originalTotalQuantity = 2;
        finalScreen4.allSelected = true;
        finalScreen4.shipToAddresses = new List<ProductWrapper.ShipToAddress>{ shipToAddress4 };
    
        ProductWrapper pw4 = new ProductWrapper();
        pw4.originalProductId = originalProduct.Id;
        pw4.originalProductName = 'WiFi Hotspot - 2GB Total Data';
        pw4.originalProductCode = 'LIC-2GB-WIFI-DATA';
        pw4.defaultHardwareCodeURL = 'https://example.com/hardware';
        pw4.defaultHardwareId = 'New';
        pw4.originalTotalQuantity = 2;
        pw4.isPlatformUpgradeEnabled = false;
        pw4.platformUpgradeScreenDetails = null;
        pw4.finalScreenDetails = finalScreen4;
        productWrapperList.add(pw4);



        // scenario
        ProductWrapper.PlatformUpgradeScreenDetail platformDetail5 = new ProductWrapper.PlatformUpgradeScreenDetail();
        platformDetail5.shippingAddressId = shipTo.Id;
        platformDetail5.shippingAddressName = shipTo.Name;
        platformDetail5.quantity = 1;
        platformDetail5.selectedUpgradeProduct = null;

        ProductWrapper.UpgradeProduct upgradeProd5 = new ProductWrapper.UpgradeProduct();
        upgradeProd5.productId = eligibleProduct.Id;
        upgradeProd5.productName = 'WiFi Hotspot - 5GB Total Data';
        upgradeProd5.productCode = 'LIC-5GB-WIFI-DATA';
        upgradeProd5.defaultHardwareCodeURL = 'https://example.com/hardware';
        upgradeProd5.defaultHardwareId = 'None';
        upgradeProd5.upgradeQuantity = 1;
        upgradeProd5.remainingQuantity = 1;
        upgradeProd5.defaultHardwareId = eligibleProduct.Id;
    
        ProductWrapper.ShipToAddress shipToAddress5 = new ProductWrapper.ShipToAddress();
        shipToAddress5.addressId = shipTo.Id;
        shipToAddress5.addressName = shipTo.Name;
        shipToAddress5.quantity = 3;
        shipToAddress5.isSelectedUpgrade = true;
        shipToAddress5.upgradeProduct = upgradeProd5;
        shipToAddress5.averageMonthlyUnitPrice = 33.5;

        ProductWrapper.FinalScreenDetails finalScreen5 = new ProductWrapper.FinalScreenDetails();
        finalScreen5.productId = ineligibleProduct.Id;
        finalScreen5.productName = 'WiFi Hotspot - 2GB Total Data';
        finalScreen5.productCode = 'LIC-2GB-WIFI-DATA';
        finalScreen5.defaultHardwareCodeURL = 'https://example.com/hardware';
        finalScreen5.defaultHardwareId = ineligibleProduct.Id;
        finalScreen5.originalTotalQuantity = 2;
        finalScreen5.allSelected = true;
        finalScreen5.shipToAddresses = new List<ProductWrapper.ShipToAddress>{ shipToAddress5 };
    
        ProductWrapper pw5 = new ProductWrapper();
        pw5.originalProductId = originalProduct.Id;
        pw5.originalProductName = 'WiFi Hotspot - 2GB Total Data';
        pw5.originalProductCode = 'LIC-2GB-WIFI-DATA';
        pw5.defaultHardwareCodeURL = 'https://example.com/hardware';
        pw5.defaultHardwareId = 'New';
        pw5.originalTotalQuantity = 2;
        pw5.isPlatformUpgradeEnabled = false;
        pw5.platformUpgradeScreenDetails = null;
        pw5.finalScreenDetails = finalScreen5;
        productWrapperList.add(pw5);

        
        // Build wrapper data
        ProductWrapper.SelectedUpgradeProduct selectedUpgrade6 = new ProductWrapper.SelectedUpgradeProduct();
        selectedUpgrade6.productId = eligibleProductUpgrade.Id;
        selectedUpgrade6.productName = 'WiFi Hotspot - 4GB Total Data';
        selectedUpgrade6.productCode = 'LIC-4GB-WIFI-DATA';
        selectedUpgrade6.defaultHardwareCodeURL = 'https://example.com/hardware';
        selectedUpgrade6.defaultHardwareId = eligibleProductUpgrade.Id;
    
        ProductWrapper.PlatformUpgradeScreenDetail platformDetail6 = new ProductWrapper.PlatformUpgradeScreenDetail();
        platformDetail6.shippingAddressId = shipTo.Id;
        platformDetail6.shippingAddressName = shipTo.Name;
        platformDetail6.quantity = 1;
        platformDetail6.selectedUpgradeProduct = selectedUpgrade;
    
        ProductWrapper.UpgradeProduct upgradeProd6 = new ProductWrapper.UpgradeProduct();
        upgradeProd6.productId = eligibleProduct.Id;
        upgradeProd6.productName = 'WiFi Hotspot - 4GB Total Data';
        upgradeProd6.productCode = 'LIC-4GB-WIFI-DATA';
        upgradeProd6.defaultHardwareCodeURL = 'https://example.com/hardware';
        upgradeProd6.defaultHardwareId = eligibleProductUpgrade.Id;
        upgradeProd6.upgradeQuantity = 1;
        upgradeProd6.remainingQuantity = 0;
    
        List<ProductWrapper.ShipToAddress> shipToAddressList26 =  new List<ProductWrapper.ShipToAddress>();

        ProductWrapper.ShipToAddress shipToAddress6 = new ProductWrapper.ShipToAddress();
        shipToAddress6.addressId = shipTo.Id;
        shipToAddress6.addressName = shipTo.Name;
        shipToAddress6.quantity = 1;
        shipToAddress6.isSelectedUpgrade = true;
        shipToAddress6.upgradeProduct = null;
        shipToAddress6.averageMonthlyUnitPrice = 33.5;
        

        shipToAddressList26.add(shipToAddress6);
        

    
        ProductWrapper.FinalScreenDetails finalScreen6 = new ProductWrapper.FinalScreenDetails();
        finalScreen6.productId = ineligibleProduct.Id;
        finalScreen6.productName = 'WiFi Hotspot - 2GB Total Data';
        finalScreen6.productCode = 'LIC-2GB-WIFI-DATA';
        finalScreen6.defaultHardwareCodeURL = 'https://example.com/hardware';
        finalScreen6.defaultHardwareId = 'None';
        finalScreen6.originalTotalQuantity = 2;
        finalScreen6.allSelected = true;
        finalScreen6.shipToAddresses = shipToAddressList26;
    
        ProductWrapper pw6 = new ProductWrapper();
        pw6.originalProductId = originalProduct.Id;
        pw6.originalProductName = 'WiFi Hotspot - 2GB Total Data';
        pw6.originalProductCode = 'LIC-2GB-WIFI-DATA';
        pw6.defaultHardwareCodeURL = 'https://example.com/hardware';
        pw6.defaultHardwareId = 'New';
        pw6.originalTotalQuantity = 2;
        pw6.isPlatformUpgradeEnabled = true;
        pw6.platformUpgradeScreenDetails = new List<ProductWrapper.PlatformUpgradeScreenDetail>{ platformDetail6 };
        pw6.finalScreenDetails = finalScreen6;
    
        productWrapperList.add(pw6);



        amendContracts.quoteLineData = productWrapperList;
        amendContracts.configData = '{"Enable_Term_Overwrite__c": true}';
        amendContracts.selectedContracts = '[{"Id": "' + testContract.Id + '"}]';
    
        return amendContracts;
    }

    public static Account getAccountByPartialName(String partialName) {
        return [SELECT Id FROM Account WHERE Name LIKE :('%' + partialName + '%') LIMIT 1];
    }

    public static Contract getAnyContract() {
        return [SELECT Id FROM Contract LIMIT 1];
    }

    public static Opportunity getAnyOpportunity() {
        return [SELECT Id FROM Opportunity LIMIT 1];
    }

    public static Contact getContactByLastName(String lastName) {
        return [SELECT Id, LastName, AccountId FROM Contact WHERE LastName = :lastName LIMIT 1];
    }

    public static Shipping_Address__c getShippingAddressByName(String name) {
        return [SELECT Id, Name FROM Shipping_Address__c WHERE Name = :name LIMIT 1];
    }

    public static SBQQ__Quote__c getAnyQuote() {
        return [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    }

    public static Product2 getProductByName(String name) {
        return [SELECT Id FROM Product2 WHERE Name = :name LIMIT 1];
    }

    @isTest
    private static void testReinitiateProcess()
    {
        bypassTriggers();
        // Build amendContracts using Apex object model
        FlexAmendContractsMsg amendContracts = prepareAmendContractData(true);

        // Create ContentVersion with serialized amendContracts
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Quote Line Data ' + System.now().format();
        cv.PathOnClient = 'QuoteLineData.json';
        cv.VersionData = Blob.valueOf(JSON.serializePretty(amendContracts));
        cv.IsMajorVersion = true;
        insert cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        // Create Flex Log record
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'Failed',  
            AccountId__c = getAccountByPartialName('Test Account').Id,
            ContractId__c = getAnyContract().Id,
            // AmendedQuoteId__c= quote.Id,
            RevenueQuoteId__c = getAnyQuote().Id
        );
        
        logRecordList.add(logRecord1);
        insert logRecordList;
        System.debug('logRecordListt ' + logRecordList);
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = logRecordList[0].Id;
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.ShareType = 'V'; // V = Viewer permission
        cdl.Visibility = 'AllUsers';
        insert cdl;  
        
        Test.startTest();
            Flex_Log__c insertedLog = [SELECT Id, Log_Group_Id__c FROM Flex_Log__c WHERE Id = :logRecordList[0].Id];
            FlexAmendContractsMsg result = FlexCancelReplaceHelper.reinitiateProcess(insertedLog.Log_Group_Id__c);
        Test.stopTest();
    }

    /**
    * @description - Tests processing of flex records.
    * Verifies error handling
    */
    @isTest
    static void testCreateUpgradedQuoteLines() {
        bypassTriggers();
        // Build amendContracts using Apex object model
        FlexAmendContractsMsg amendContracts = prepareAmendContractData(true);

        // Create ContentVersion with serialized amendContracts
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Quote Line Data ' + System.now().format();
        cv.PathOnClient = 'QuoteLineData.json';
        cv.VersionData = Blob.valueOf(JSON.serializePretty(amendContracts));
        cv.IsMajorVersion = true;
        insert cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        // Create Flex Log record
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'Failed',  
            AccountId__c = getAccountByPartialName('Test Account').Id,
            ContractId__c = getAnyContract().Id,
            // AmendedQuoteId__c= quote.Id,
            RevenueQuoteId__c = getAnyQuote().Id
        );
        
        logRecordList.add(logRecord1);
        insert logRecordList;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = logRecordList[0].Id;
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.ShareType = 'V'; // V = Viewer permission
        cdl.Visibility = 'AllUsers';
        insert cdl;        
        
        FlexAmendQueueableParams params = new FlexAmendQueueableParams.Builder()
            .withContractIdList(new List<String>{getAnyContract().Id})
            .withStartDate(Date.Today())
            .withLogRecordList(logRecordList)
            .withCurrentIndex(10)
            .withIsRebook(false)
            .withQueueableJobIdSet(new Set<Id>())
            .withQuoteRecalcStarted(true)
            .withRetryCount(1)
            .build();
        
        Test.startTest();
            //List<ProductWrapper> wrappers = (List<ProductWrapper>)JSON.deserialize(getQuoteLineDataJSON(), List<ProductWrapper>.class);
            FlexCancelAndReplaceHandler.callAmenderApi(getAnyContract().Id, Date.Today(), getAnyOpportunity().Id, true);
            System.enqueueJob(new FlexAmendQueueable(params));
        Test.stopTest();
        
        // Verify that the job was re-enqueued (by checking debug logs or related records)
        List<AsyncApexJob> jobs = [
            SELECT Id, Status 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = 'FlexAmendQueueable'
            ORDER BY CreatedDate DESC
        ];
        System.assertEquals(false, [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :getAnyQuote().Id].isEmpty(), 'Quote Lines not inserted');
    }

/**
    * @description - Tests processing of flex records when they fail
    * Verifies error handling
    */
    @isTest
    static void testCreateUpgradedQuoteLinesFailure() {
        bypassTriggers();
        FlexAmendContractsMsg amendContracts = prepareAmendContractData(false);
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Quote Line Data ' + System.now().format();
        cv.PathOnClient = 'QuoteLineData.json';
        cv.VersionData = Blob.valueOf(JSON.serializePretty(amendContracts));
        cv.IsMajorVersion = true;
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        // Create Flex Log record
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'Failed',  
            AccountId__c = getAccountByPartialName('Test Account').Id,
            ContractId__c = getAnyContract().Id,
            AmendedQuoteId__c= getAnyQuote().Id,
            RevenueQuoteId__c = getAnyQuote().Id
        );
        
        logRecordList.add(logRecord1);
        insert logRecordList;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = logRecordList[0].Id;
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.ShareType = 'V'; // V = Viewer permission
        cdl.Visibility = 'AllUsers';
        insert cdl;        
        
        FlexAmendQueueableParams params = new FlexAmendQueueableParams.Builder()
            .withContractIdList(new List<String>{getAnyContract().Id})
            .withStartDate(Date.Today())
            .withLogRecordList(logRecordList)
            .withCurrentIndex(10)
            .withIsRebook(false)
            .withQueueableJobIdSet(new Set<Id>())
            .withQuoteRecalcStarted(true)
            .withRetryCount(1)
            .build();
        
        Test.startTest();
        //List<ProductWrapper> wrappers = (List<ProductWrapper>)JSON.deserialize(getQuoteLineDataJSON(), List<ProductWrapper>.class);
        FlexCancelAndReplaceHandler.callAmenderApi(getAnyContract().Id, Date.Today(), getAnyOpportunity().Id, true);
        System.enqueueJob(new FlexAmendQueueable(params));
        Test.stopTest();
        
        // Verify that the job was re-enqueued (by checking debug logs or related records)
        List<AsyncApexJob> jobs = [
            SELECT Id, Status 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = 'FlexAmendQueueable'
            ORDER BY CreatedDate DESC
        ];
        System.assertEquals(true, [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :getAnyQuote().Id].isEmpty(), 'Quote Lines inserted');
    }    

    // @isTest
    // static void testProcessFlexRecords() {
    //     bypassTriggers();
    //     Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
    //     Contract testContract = [SELECT Id FROM Contract LIMIT 1];
    //     Opportunity replacementOppId = [ SELECT Id FROM Opportunity LIMIT 1];
        
    //     Contact con = [SELECT Id, LastName, AccountId FROM Contact WHERE LastName = 'Test Contact'];
    //     con.AccountId = testAccount.Id;
    //     update con;

    //     Shipping_Address__c shipTo = [SELECT Id FROM Shipping_Address__c WHERE Name = 'Test'];
    //     shipTo.Account__c = testAccount.Id;
    //     update shipTo;

    //     SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    //     quote.SBQQ__PriceBook__c = Test.getStandardPricebookId();
    //     quote.SBQQ__SubscriptionTerm__c = 6;
    //     update quote;
        
    //     ContentVersion cv = new ContentVersion();
    //     cv.Title = 'Quote Line Data ' + System.now().format();
    //     cv.PathOnClient = 'QuoteLineData.json';
    //     cv.VersionData = Blob.valueOf(getQuoteLineDataJSON());
    //     cv.IsMajorVersion = true;
    //     insert cv;
    //     cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
    //     // Create Flex Log record
    //     List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
    //     Flex_Log__c logRecord1 = new Flex_Log__c(
    //         Status__c = 'Failed',  
    //         AccountId__c = testAccount.Id, 
    //         ContractId__c = testContract.Id,
    //         // AmendedQuoteId__c= quote.Id,
    //         RevenueQuoteId__c = quote.Id
    //     );
        
    //     logRecordList.add(logRecord1);
    //     insert logRecordList;
        
    //     ContentDocumentLink cdl = new ContentDocumentLink();
    //     cdl.LinkedEntityId = logRecordList[0].Id;
    //     cdl.ContentDocumentId = cv.ContentDocumentId;
    //     cdl.ShareType = 'V'; // V = Viewer permission
    //     cdl.Visibility = 'AllUsers';
    //     insert cdl;        
        
    //     FlexAmendQueueableParams params = new FlexAmendQueueableParams.Builder()
    //         .withContractIdList(new List<String>{testContract.Id})
    //         .withStartDate(Date.Today())
    //         .withLogRecordList(logRecordList)
    //         .withCurrentIndex(10)
    //         .withIsRebook(false)
    //         .withQueueableJobIdSet(new Set<Id>())
    //         .withQuoteRecalcStarted(true)
    //         .withRetryCount(1)
    //         .build();
        
    //     Test.startTest();
    //         //List<ProductWrapper> wrappers = (List<ProductWrapper>)JSON.deserialize(getQuoteLineDataJSON(), List<ProductWrapper>.class);
    //         FlexCancelAndReplaceHandler.callAmenderApi(testContract.Id, Date.Today(), replacementOppId.Id, true);
    //         System.enqueueJob(new FlexAmendQueueable(params));
    //     Test.stopTest();
        
    //     // Verify that the job was re-enqueued (by checking debug logs or related records)
    //     List<AsyncApexJob> jobs = [
    //         SELECT Id, Status 
    //         FROM AsyncApexJob 
    //         WHERE ApexClass.Name = 'FlexAmendQueueable'
    //         ORDER BY CreatedDate DESC
    //     ];
    //     System.assertEquals(false, [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id].isEmpty(), 'Quote Lines not inserted');
    // }
     
    @isTest
    static void testHandleQuoteRecalculation_with_One_retryCount() {
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Opportunity replacementOppId = [ SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Create Flex Log record
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'Failed',  
            AccountId__c = testAccount.Id, 
            ContractId__c = testContract.Id,
            AmendedQuoteId__c= quote.Id
        );
        
        logRecordList.add(logRecord1);
        insert logRecordList;
        
        FlexAmendQueueableParams params = new FlexAmendQueueableParams.Builder()
            .withContractIdList(new List<String>{testContract.Id})
            .withStartDate(Date.Today())
            .withLogRecordList(logRecordList)
            .withCurrentIndex(10)
            .withIsRebook(false)
            .withQueueableJobIdSet(new Set<Id>())
            .withQuoteRecalcStarted(true)
            .withRetryCount(1)
            .build();
        
        Test.startTest();
        FlexCancelAndReplaceHandler.callAmenderApi(testContract.Id, Date.Today(), replacementOppId.Id, true);
        System.enqueueJob(new FlexAmendQueueable(params));
        Test.stopTest();
        
        // Verify that the job was re-enqueued (by checking debug logs or related records)
        List<AsyncApexJob> jobs = [
            SELECT Id, Status 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = 'FlexAmendQueueable'
            ORDER BY CreatedDate DESC
        ];
        System.assert(!jobs.isEmpty(), 'Job should have been re-enqueued');
        System.assertEquals(1, jobs.size(), 'Job should');
    }
    
    @isTest
    static void testCheckAmendmentFutureStatus_fail() {
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Opportunity replacementOppId = [ SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Create Flex Log record
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'Failed',  
            AccountId__c = testAccount.Id, 
            ContractId__c = testContract.Id,
            AmendedQuoteId__c= quote.Id
        );
        
        logRecordList.add(logRecord1);
        insert logRecordList;
        
        FlexAmendQueueableParams params = new FlexAmendQueueableParams.Builder()
            .withContractIdList(new List<String>{testContract.Id})
            .withStartDate(Date.Today())
            .withLogRecordList(logRecordList)
            .withCurrentIndex(10)
            .withIsRebook(false)
            .withQueueableJobIdSet(new Set<Id>())
            .withQuoteRecalcStarted(false)
            .withRetryCount(0)
            .build();
        
        Test.startTest();
        FlexCancelAndReplaceHandler.callAmenderApi(testContract.Id, Date.Today(), replacementOppId.Id, true);
        System.enqueueJob(new FlexAmendQueueable(params));
        Test.stopTest();
        
        // Verify that the job was re-enqueued (by checking debug logs or related records)
        List<AsyncApexJob> jobs = [
            SELECT Id, Status 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = 'FlexAmendQueueable'
            ORDER BY CreatedDate DESC
        ];
        System.assert(!jobs.isEmpty(), 'Job should have been re-enqueued');
        System.assertEquals(1, jobs.size(), 'Job should');
    }
    
    @isTest
    static void testCheckAmendmentFutureStatus_Success() {
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Opportunity replacementOppId = [ SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Create Flex Log record
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c logRecord1 = new Flex_Log__c(
            Status__c = 'Completed',  
            AccountId__c = testAccount.Id, 
            ContractId__c = testContract.Id,
            AmendedQuoteId__c= quote.Id
        );
        
        logRecordList.add(logRecord1);
        insert logRecordList;
        
        FlexAmendQueueableParams params = new FlexAmendQueueableParams.Builder()
            .withContractIdList(new List<String>{testContract.Id})
            .withStartDate(Date.Today())
            .withLogRecordList(logRecordList)
            .withCurrentIndex(10)
            .withIsRebook(false)
            .withQueueableJobIdSet(new Set<Id>())
            .withQuoteRecalcStarted(false)
            .withRetryCount(0)
            .build();
        
        Test.startTest();
        FlexCancelAndReplaceHandler.callAmenderApi(testContract.Id, Date.Today(), replacementOppId.Id, true);
        System.enqueueJob(new FlexAmendQueueable(params));
        Test.stopTest();
        
        // Verify that the job was re-enqueued (by checking debug logs or related records)
        List<AsyncApexJob> jobs = [
            SELECT Id, Status 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = 'FlexAmendQueueable'
            ORDER BY CreatedDate DESC
        ];
        System.assert(!jobs.isEmpty(), 'Job should have been re-enqueued');
        System.assertEquals(1, jobs.size(), 'Job should');
    }
    @isTest
    static void testFlexNotificationDataController() {
        bypassTriggers();
        User testUser = [SELECT Id FROM User LIMIT 1];
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Flex_Log__c logRecord = new Flex_Log__c(
            Status__c = 'Failed',
            AccountId__c = testAccount.Id,
            ContractId__c = testContract.Id,
            userNotified__c = false,
            ErrorMessage__c = 'Test Error',
            CreatedById = testUser.Id
        );
        insert logRecord;
        // Set up test parameters
        Test.startTest();
        ApexPages.currentPage().getParameters().put('accountId', testAccount.Id);
        ApexPages.currentPage().getParameters().put('userId', testUser.Id);
        ApexPages.currentPage().getParameters().put('notify', 'false');
        ApexPages.currentPage().getParameters().put('contractIds', testContract.Id);
        ApexPages.currentPage().getParameters().put('showLogs', 'true');
        
        // Instantiate the controller
        FlexNotificationDataController controller = new FlexNotificationDataController();
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(1, controller.logs.size(), 'Log size does not match');
    }
    
    /**
* @description - Tests the performRollback method for successful rollback
*/
    @IsTest
    static void testPerformRollbackSuccess() {
        Account testAccount = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        
        
        Opportunity amendedOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Amended Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert amendedOpp;
        
        Opportunity replacementOppId = [ SELECT Id FROM Opportunity LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        
        Flex_Log__c logRecord = new Flex_Log__c(
            AccountId__c = testAccount.Id,
            AmendedOpportunityId__c = amendedOpp.Id,
            RevenueOpportunityId__c = replacementOppId.Id,
            ContractId__c = testContract.Id,
            Status__c = 'In Progress'
        );
        insert logRecord;
        
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>{ logRecord };
            
            Test.startTest();
        //FlexCancelReplaceHelper.updateFutureJobLog(logRecordList, false, 'testMethod');
        FlexCancelReplaceHelper.performRollback(logRecordList, false);
        Test.stopTest();
        // Verify log record update
        // Flex_Log__c updatedLogRecord = [SELECT Id, Status__c FROM Flex_Log__c WHERE Id = :logRecord.Id];
        // System.assertNotEquals(null, updatedLogRecord, 'Updated LogRecord should not be null');
        
        // Verify that opportunities are deleted
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id IN :new Set<Id>{amendedOpp.Id, replacementOppId.Id}];
        System.assertEquals(0, opps.size(), 'Opportunities should be deleted');
        
        // Verify that contract flags are reset
        Contract updatedContract = [SELECT Flex_Is_Rebook__c, Contract_C_R_In_Progress__c FROM Contract WHERE Id = :testContract.Id];
        System.assertEquals(false, updatedContract.Flex_Is_Rebook__c, 'Flex_Is_Rebook__c should be false');
        System.assertEquals(false, updatedContract.Contract_C_R_In_Progress__c, 'Contract_C_R_In_Progress__c should be false');
        
        // Verify that account flag is reset
        Account updatedAccount = [SELECT Account_C_R_In_Progress__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(false, updatedAccount.Account_C_R_In_Progress__c, 'Account_C_R_In_Progress__c should be false');
    }
    
    @IsTest
    static void testFlexAmendContracts_failed() {
        // Retrieve test data
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Selected_Payment_Type__c, SBQQ__Primary__c FROM SBQQ__Quote__c];
        System.debug('test => ' + quoteList.size());
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        
        // Collect all contract IDs into a list of strings
        List<String> contractIdsList = new List<String>();
        for (Contract contract : [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id]) {
            contractIdsList.add(contract.Id);
        }
        System.debug('Enter contractIdsList ' + contractIdsList.size());
        System.debug(String.valueOf(Date.today()));
        System.debug(String.valueOf(Date.today().addMonths(36)));
        
        // Test data to input flexAmendContracts method of FlexAccountCancelReplaceController
        FlexAmendContractsMsg amendContracts = new FlexAmendContractsMsg();
        amendContracts.contractIds = contractIdsList;
        amendContracts.startDate = String.valueOf(Date.today());
        amendContracts.accountId = testAccount.Id;
        amendContracts.termLength = 36;
        amendContracts.endDate = String.valueOf(Date.today().addMonths(36));
        System.debug('Enter FlexAmendContractsMsg ' + amendContracts);
        
        Test.startTest();
        FlexAccountCancelReplaceController.FlexAmendResponse result = FlexAccountCancelReplaceController.flexAmendContracts(amendContracts);
        System.debug('result => ' + result);
        Test.stopTest();
        
        
        
    }
    
    
    
    
    @isTest
    static void testHandleError() {
        // Create test data for Flex_Log__c
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c log1 = new Flex_Log__c(
            Status__c = 'In Progress',
            ErrorMessage__c = 'Initial error message'
        );
        logRecordList.add(log1);
        
        Flex_Log__c log2 = new Flex_Log__c(
            Status__c = 'In Progress',
            ErrorMessage__c = null
        );
        logRecordList.add(log2);
        
        insert logRecordList;
        
        // Call the handleError method
        Test.startTest();
        FlexCancelReplaceHelper.handleError(logRecordList, 'testMethod', 'Test error message');
        Test.stopTest();
        
        // Retrieve the updated records
        logRecordList = [SELECT Status__c, ErrorMessage__c FROM Flex_Log__c WHERE Id IN :logRecordList];
        
        // Add assertions to verify the expected behavior
        for (Flex_Log__c logRecord : logRecordList) {
            System.assertEquals('Failed', logRecord.Status__c, 'Status should be Failed');
            System.assert(logRecord.ErrorMessage__c.contains('testMethod: Test error message'), 'ErrorMessage should contain the method name and error message');
        }
    }
    
    
    @isTest
    static void testFlexQuotelineQueueableException() {
        // Create test data for Flex_Log__c
        List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        Flex_Log__c log1 = new Flex_Log__c(
            Status__c = 'In Progress',
            ErrorMessage__c = 'Initial error message'
        );
        logRecordList.add(log1);
        
        Flex_Log__c log2 = new Flex_Log__c(
            Status__c = 'In Progress',
            ErrorMessage__c = null
        );
        logRecordList.add(log2);
        
        insert logRecordList;
        
        Set<Id> logRecordIdSet = new Set<Id>();
        for (Flex_Log__c logRecord : logRecordList) {
            logRecordIdSet.add(logRecord.Id);
        }
        
        // Call the handleError method
        Test.startTest();
        FlexQuoteLineQueueable.handleException( 'testMethod', 'Test error message',logRecordIdSet);
        Test.stopTest();
        
        // Retrieve the updated records
        logRecordList = [SELECT Status__c, ErrorMessage__c FROM Flex_Log__c WHERE Id IN :logRecordList];
        
        // Add assertions to verify the expected behavior
        for (Flex_Log__c logRecord : logRecordList) {
            System.assertEquals('Failed', logRecord.Status__c, 'Status should be Failed');
            
        }
    }
    
    /** @description - Helper method to bypass triggers for testing
*/
    public static void bypassTriggers(){
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        SBQQ.TriggerControl.disable();
    }
}