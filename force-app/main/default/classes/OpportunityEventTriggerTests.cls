@isTest
public class OpportunityEventTriggerTests {

   @testSetup
    private static void testDataSetup() {
         
       List<Opportunity> newOpportunities = new List<Opportunity>();
       List<Account> newAccounts = new List<Account>();
       List<Contact> newContacts = new List<Contact>();
       List<Contract> newContracts = new List<Contract>();
       List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
   
        User u = [SELECT Id FROM User WHERE UserRole.Name ='Fleet ADR NA US Team 1 - Manager' LIMIT 1];

        //Create Accounts
        Account accountOne = new Account(Name = 'Testers 8 Inc',
                                BillingState='California',
                                BillingCountry = 'United States',
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                Industry = 'Other',
                                Account_Lifetime_ACV__c = 11000);
        newAccounts.add(accountOne);
        insert newAccounts;
        
        //Create Contacts
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id, Email = 'test@test.com'));
        newContacts.add(contactOne);
        
        insert newContacts; 
        
        //Create Opportunities
        Opportunity opportunityOne = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      License_Term_CPQ__c = 36,
                                                      Original_AE__c = u.Id));
        newOpportunities.add(opportunityOne);

        insert newOpportunities;
        
        SBQQ__Quote__c quoteOne = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = accountOne.Id, SBQQ__Opportunity2__c = opportunityOne.Id, 
                                                  SBQQ__Primary__c = true, Downsell_Amount__c = 1250, Upsell_Amount__c = 1250, Renewal_Amount__c = 2500);
        
        newQuotes.add(quoteOne);
                
        insert newQuotes;
        
        //Create Contracts
        Contract contractOne = new Contract();
        contractOne.AccountId = accountOne.Id;
        contractOne.StartDate = Date.today() - 200;
        contractOne.EndDate = Date.today() + 365;
        newContracts.add(contractOne);
      
        insert newContracts;
        
    }
    
    @isTest
    static void testOpportunityEvents(){
        Opportunity opportunity = [SELECT ID, SBQQ__RenewedContract__c FROM Opportunity WHERE Name = 'Opp Testers 3 Inc'];
        Contract contract = [SELECT ID FROM Contract LIMIT 1];
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        	opportunity.SBQQ__RenewedContract__c = contract.Id;
        	opportunity.StageName = 'Ready to Ship';
        	update opportunity;
        
        // Create a test event instance
        Opportunity_Event__e oppEvent = new Opportunity_Event__e(Id__c = opportunity.ID);
        Database.SaveResult sr = EventBus.publish(oppEvent);
                
        Test.stopTest();
    }
}