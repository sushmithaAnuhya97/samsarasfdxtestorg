@isTest
public class BatchClickPathToGainSightTest {
    
    @TestSetup
    static void setupTestData() {
        // Bypass triggers to reduce SOQL queries
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');

        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Contact> newContacts = new List<Contact>();
        
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                         BillingCountry = 'United States',
                                         BillingState = 'Texas', 
                                         Organization_Size__c = '100 - 499',
                                         Industry = 'Other',
                                         //Customer_ARR__c = 5000,
                                         Customer_ARR_Netsuite__c = 5000,
                                         Auto_renewal_Opt_Out__c  = true);
        
        insert accountOne;
        
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        newContacts.add(contactOne);
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id, Email = 'test@test.com'));
        newContacts.add(contactTwo);
        insert newContacts;
        
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', 
                                                        Shipping_Contact__c=contactOne.Id, 
                                                        Shipping_Address_Line_1__c='1 Dolores, Dallas', 
                                                        Shipping_City__c='Dallas', 
                                                        Shipping_Country__c='United States', 
                                                        Shipping_State__c='Texas', 
                                                        Name='Test', 
                                                        Account__c = accountOne.Id);
        insert sa;
        
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 2 Inc',
                                                      StageName = 'Incubate',
                                                      Shipping_Contact__c = contactTwo.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'
                                                     ));
        insert opportunityOne;
        
        Contract contract = new Contract(
            AccountId = accountOne.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c = opportunityOne.Id
        );
        insert contract;

        Opportunity opportunityFT = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Incubate', // Use safe stage
                                                      Probability = 50, // Keep below 95% to avoid validation rule
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Returning_Opportunity__c = opportunityOne.Id,
                                                      Send_Invoice__c = false,
                                                      CloseDate = System.today().addDays(1),
                                                      SBQQ__RenewedContract__c = contract.Id,
                                                      OwnerId = System.Label.Renewal_Pool_User,
                                                      Renewal__c = true
                                                     ));
        insert opportunityFT;                                             
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', 
                                                  SBQQ__Account__c = accountOne.Id, 
                                                  SBQQ__Opportunity2__c = opportunityFT.Id,
                                                  SBQQ__SubscriptionTerm__c =10,
                                                  Estimated_Annual_Payment__c = 24, 
                                                  Selected_Payment_Type__c = 'Direct Annual', 
                                                  SBQQ__Primary__c = true);
        insert quote;
        
        opportunityFT.SBQQ__PrimaryQuote__c = quote.Id;
        update opportunityFT;
    }
    
    @isTest private static void testRunBatch() {
        Test.startTest();
        BatchClickPathToGainSight b = new BatchClickPathToGainSight();  
        database.executebatch(b,200); 
        String CRON_EXP = '0 0 0 ? * * *';
        String jobId = System.schedule('BatchClickPathToGainSightTestClass', CRON_EXP, new BatchClickPathToGainSight());
        Test.stopTest();
    }
    
    @isTest private static void forceErrorsTesting() {
        // Get the opportunity created in setup
        Opportunity opportunityFT = [SELECT Id FROM Opportunity WHERE Name = 'Opp Testers 1 Inc' LIMIT 1];
        
        // Creating integrity exception scenario on next update.
        Test.setCreatedDate(opportunityFT.Id, System.today().addDays(5));
        try {
            Test.startTest();
            BatchClickPathToGainSight b = new BatchClickPathToGainSight();  
            database.executebatch(b,200); 
            Test.stopTest();
        } catch(Exception ex) { } // This is to prevent the test class from being considered an error. The exception is expected.
    }
}