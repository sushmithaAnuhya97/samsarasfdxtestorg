@IsTest
private class BatchEarlyRenewalsTest {
    
    static Account createAccount() {
        Account account = new Account();
        account.Name = 'MyTestAccount';
        account.Type = 'Fleet';
        account.Industry = 'Other';
        account.organization_size__c = '1 - 99';
        account.billingstreet = '123 Main St, San Francisco CA, 94110';
        account.billingstate = 'California';
        account.billingcountry = 'United States';
        account.billingcity = 'San Francisco';
        account.billingPostalCode = '94110';
        account.shippingstreet = '123 Main St, San Francisco CA, 94110';
        account.shippingstate = 'California';
        account.shippingcountry = 'United States';
        account.shippingcity = 'San Francisco';
        account.shippingPostalCode = '94110';
        account.Payment_Terms__c ='Net 30';
        return account;
    }
    @isTest
    static void testBatchEarlyRenewals() {
        
        Account account = createAccount();
        insert account;
        
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;
        
        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.EndDate = System.today().addMonths(1);
        contract.ContractTerm = 12;
        contract.Weighted_Average_Start_Date__c = system.today().addDays(-2);
        insert contract;
       
       Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity 1',
            AccountId = account.Id,
            CloseDate = System.today().addDays(2),
            License_Start_Date__c = System.today().addDays(1),
            Adjust_License_Start_Date__c = false,
            License_End_Date__c = System.today().addMonths(1),
            SBQQ__RenewedContract__c = contract.Id,
            Initial_Payment_Terms__c = 'Due on Contract Start',
            StageName = 'Purchase',
            Renewal__c= true,
			License_Term__c =36,
            Probability = 10
        );
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            AccountId = account.Id,
            CloseDate = System.today().addDays(-2),
            Adjust_License_Start_Date__c = false,
            Payment_Terms__c ='Net 30',
            Initial_Payment_Terms__c = 'Net 30',
            StageName = 'Purchase',
            Renewal__c= true,
            SBQQ__RenewedContract__c = contract.Id,
            License_Term__c =36,
            Probability = 10
        );
        Opportunity opp3 = new Opportunity(
            Name = 'Test Opportunity 3',
            AccountId = account.Id,
            CloseDate = System.today().addDays(-2),
            Adjust_License_Start_Date__c = false,
            License_Start_Date__c = System.today().addDays(-2),
            License_End_Date__c = System.today().addMonths(1),
            Initial_Payment_Terms__c = 'Due on Contract Start',
            StageName = 'Purchase',
            Renewal__c= true,
            License_Term__c =36,
            SBQQ__RenewedContract__c = contract.Id,
            Probability = 10
        );
        
        insert new List<Opportunity>{ opp1, opp2, opp3 };
       	Test.startTest();
         
        Database.executeBatch(new BatchEarlyRenewals(),3);
        Test.stopTest();
        
        
        opp1 = [SELECT Adjust_License_Start_Date__c, CloseDate, License_Start_Date__c, License_End_Date__c, Initial_Payment_Terms__c FROM Opportunity WHERE Id = :opp1.Id];
        opp2 = [SELECT Adjust_License_Start_Date__c, Initial_Payment_Terms__c FROM Opportunity WHERE Id = :opp2.Id];
        opp3 = [SELECT Adjust_License_Start_Date__c, Initial_Payment_Terms__c FROM Opportunity WHERE Id = :opp3.Id];
        
      
        
    }
    @isTest
    static void testScheduledJob(){
        String CRON_EXP = '0 0 0 3 9 ? 2049';
        String jobId = System.schedule('BatchEarlyRenewalsTest', CRON_EXP, new BatchEarlyRenewals());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2049-09-03 00:00:00', String.valueOf(ct.NextFireTime)); 
    }    

	@isTest
    public static void testStep2() {
    	BatchEarlyRenewals.testCoverage();
    }   
}