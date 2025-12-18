/**
 * @description       : https://samsaradev.atlassian.net/browse/GTMS-10150
 * @author            : nishita.dhar@samsara.com
 * @group             : 
 * @last modified on  : 01-04-2023
 * @last modified by  : 
**/
@isTest
public class JobContractAutomationTests {
    @testSetup
    private static void testDataSetup() {
         
       List<Opportunity> newOpportunities = new List<Opportunity>();
       List<Account> newAccounts = new List<Account>();
       List<Contact> newContacts = new List<Contact>();
       
        
        User u = [SELECT Id FROM User WHERE UserRole.Name ='Fleet ADR NA US Team 1 - Manager' LIMIT 1];

        //Create Accounts
        Account accountOne = (Account) TestFactory.createSObject(new Account(Name = 'Testers 8 Inc',
                                BillingState='California',
                                BillingCountry = 'United States',
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                Industry = 'Other',
                                Account_Lifetime_ACV__c = 11000,
                                Renewal_AE__c = u.Id,
                                Auto_renewal_Opt_Out__c=false,
                                Quarantine_Enabled__c = false,
                                Customer_ARR__c = 500,
                                Customer_ARR_Netsuite__c = 500,
                                Billing_Stripe_Customer_Id__c = 'ABC',
                                Netsuite_Delinquent_Status__c = 'Current'));
        newAccounts.add(accountOne);
        insert newAccounts;
        
        
        //Create Contacts
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id, Email = 'test@test.com'));
        newContacts.add(contactOne);
        TriggerHandler.bypass('ContractTriggerHandler');
        insert newContacts;
        TriggerHandler.clearBypass('ContractTriggerHandler');
        
        //Create Opportunities
        Opportunity opportunityOne = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne);  
        insert newOpportunities;
        
        Product2 prod = new Product2(Name = '36-Month License for Vehicle Gateways', ProductCode = 'LIC-VG-36MO',
                                    Product_Type__c = 'License', SBQQ__SubscriptionPricing__c = 'Fixed Price',
                                    SBQQ__SubscriptionTerm__c = 36, SBQQ__SubscriptionType__c = 'Renewable');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        //------------------------------------------------------------------------------------------------------------
        SBQQ.TriggerControl.disable();
        List<SBQQ__Quote__c> listQuote = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = accountOne.Id, SBQQ__Opportunity2__c =opportunityOne.Id, 
            SBQQ__SubscriptionTerm__c =36, Selected_Payment_Type__c = 'Direct Annual', 
                                                  SBQQ__Primary__c = true,  SBQQ__StartDate__c = Date.Today(),
                                                 SBQQ__EndDate__c = Date.Today().addMonths(36),SBQQ__PriceBook__c = Test.getStandardPricebookId());
            listQuote.add(quote);
     	
        insert listQuote;
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(SBQQ__Quote__c =quote.Id,SBQQ__PricebookEntryId__c = standardPrice.Id, SBQQ__Product__c = standardPrice.Product2Id,
                                                      SBQQ__Quantity__c = 2);
        insert ql;
        
       
        SBQQ.TriggerControl.enable();
        //------------------------------------------------------------------------------------------------------------
    }
    @isTest
    static void testJobContractAutomation1(){
		Account accountOne = [SELECT Id FROM Account WHERE Name='Testers 8 Inc' LIMIT 1];
        Opportunity opportunityOne = [SELECT ID From Opportunity WHERE Name='Opp Testers 3 Inc' LIMIT 1];
        
        
        Contract contractOne = new Contract();
        contractOne.AccountId = accountOne.Id;
        
        contractOne.SBQQ__Opportunity__c = opportunityOne.Id;
        contractOne.Auto_Renewal__c = FALSE;
        contractOne.SBQQ__RenewalTerm__c = 36;
        contractOne.Health_Status__c = 'Healthy';
        contractOne.Renewal_Data_Clean__c = true;
        contractOne.EndDate = System.today().addMonths(2);
 
        insert contractOne;
        Test.setCreatedDate(contractOne.Id, Datetime.now().addMonths(-35));
        contractOne.StartDate = System.today().addMonths(-35);
        contractOne.EndDate = System.today().addMonths(1);
        update contractOne;
        Test.startTest();
         
        Database.executeBatch(new JobContractAutomation(),1);
        Test.stopTest();
        Contract uc=[Select id,SBQQ__RenewalForecast__c,SBQQ__RenewalQuoted__c FROM Contract LIMIT 1];
        System.assertEquals(uc.SBQQ__RenewalForecast__c,true);
        System.assertEquals(uc.SBQQ__RenewalQuoted__c,true);
    }
    @isTest
    static void testJobContractAutomation2(){
		Account accountOne = [SELECT Id FROM Account WHERE Name='Testers 8 Inc' LIMIT 1];
        Opportunity opportunityOne = [SELECT ID From Opportunity WHERE Name='Opp Testers 3 Inc' LIMIT 1];
        
        
        Contract contractOne = new Contract();
        contractOne.AccountId = accountOne.Id;
        contractOne.StartDate = Date.today();
        contractOne.EndDate = Date.today().addMonths(36);
        contractOne.SBQQ__Opportunity__c = opportunityOne.Id;
        contractOne.Auto_Renewal__c = FALSE;
        contractOne.SBQQ__RenewalTerm__c = 36;
        contractOne.ContractTerm = 36;
        contractOne.SBQQ__RenewalForecast__c = true;
        contractOne.Health_Status__c = 'Healthy';
 
        insert contractOne;
       
        
        Test.startTest();
         
        Database.executeBatch(new JobContractAutomation(),1);
        Test.stopTest();
        Contract uc=[Select id,Auto_Renewal__c,SBQQ__RenewalTerm__c FROM Contract LIMIT 1];
        System.assertEquals(uc.Auto_Renewal__c,true);
        System.assertEquals(uc.SBQQ__RenewalTerm__c,36);
        
    }
    
	@isTest
    static void testScheduledJob(){
        String CRON_EXP = '0 0 0 3 9 ? 2049';
        String jobId = System.schedule('JobContractAutomation', CRON_EXP, new JobContractAutomation());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2049-09-03 00:00:00', String.valueOf(ct.NextFireTime)); 
    }    
}