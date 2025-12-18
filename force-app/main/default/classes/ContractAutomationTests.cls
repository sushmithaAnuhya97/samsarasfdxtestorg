@isTest
public class ContractAutomationTests {
    @testSetup
    private static void testDataSetup() {
         
       List<Opportunity> newOpportunities = new List<Opportunity>();
       List<Account> newAccounts = new List<Account>();
       List<Contact> newContacts = new List<Contact>();
       List<Contract> newContracts = new List<Contract>();
        
        User u = [SELECT Id FROM User WHERE UserRole.Name ='Fleet ADR NA US Team 1 - Manager' LIMIT 1];

        //Create Accounts
        Account accountOne = new Account(Name = 'Testers 8 Inc',
                                BillingState='California',
                                BillingCountry = 'United States',
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                Industry = 'Other',
                                Account_Lifetime_ACV__c = 11000,
                                Renewal_AE__c = u.Id);
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
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityOne);  
        
        Opportunity opportunityTwo = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 4 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Configuration_Segment__c = 'Non Express', Rebate_Amount__c=2));
        newOpportunities.add(opportunityTwo);  
        
        Opportunity opportunityThree = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 5 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Configuration_Segment__c = 'Non Express',
                                                      SBQQ__Renewal__c = TRUE,
                                                 	  License_Term_CPQ__c = 36, Rebate_Amount__c=1));
        newOpportunities.add(opportunityThree);  

        
        
        Opportunity opportunityFour = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 6 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Configuration_Segment__c = 'Non Express',
                                                      SBQQ__Renewal__c = FALSE,
                                                 	  License_Term_CPQ__c = 36, 
                                                  License_Term__c = 72,
                                                  Blended_Discount_CPQ__c = 12,

                                                 Buyout_Opportunity__c = opportunityThree.Id, 
                                                 Subsidy_Opportunity__c = opportunityThree.Id));
        newOpportunities.add(opportunityFour); 
                insert newOpportunities;
        List<SBQQ__Quote__c> listQuote = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = accountOne.Id, SBQQ__Opportunity2__c =opportunityFour.Id, 
            SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, Selected_Payment_Type__c = 'Direct Annual', 
                                                  SBQQ__Primary__c = true, Custom_License_Term__c = 2);
            listQuote.add(quote);
        
        SBQQ__Quote__c quote2 = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = accountOne.Id, SBQQ__Opportunity2__c =opportunityThree.Id, 
            SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, Selected_Payment_Type__c = 'Direct Annual', 
                                                  SBQQ__Primary__c = true, Custom_License_Term__c = 2);
            listQuote.add(quote2);
        insert listQuote;
        opportunityFour.Buyout_Opportunity__c = opportunityThree.Id;
        opportunityFour.Subsidy_Opportunity__c = opportunityThree.Id;
        update opportunityFour;
        
        opportunityThree.SBQQ__PrimaryQuote__c =  quote2.id;
        update opportunityThree;
        
        //Create Contracts
        Contract contractOne = new Contract();
        contractOne.AccountId = accountOne.Id;
        contractOne.StartDate = Date.today() - 200;
        contractOne.EndDate = Date.today() + 365;
        newContracts.add(contractOne);
        
        Contract contractTwo = new Contract();
        contractTwo.AccountId = accountOne.Id;
        contractTwo.StartDate = Date.today() - 200;
        contractTwo.EndDate = Date.today() + 160;
        contractTwo.SBQQ__Opportunity__c = opportunityTwo.Id;
        newContracts.add(contractTwo);
        
        Contract contractThree = new Contract();
        contractThree.AccountId = accountOne.Id;
        contractThree.StartDate = Date.today() - 200;
        contractThree.EndDate = Date.today() + 5;
        contractThree.SBQQ__Opportunity__c = opportunityTwo.Id;
        contractThree.Auto_Renewal__c = TRUE;
        contractThree.SBQQ__RenewalOpportunity__c = opportunityThree.Id; 
        newContracts.add(contractThree);
      
        Contract contractFour = new Contract();
        contractFour.AccountId = accountOne.Id;
        contractFour.StartDate = Date.today() - 200;
        contractFour.EndDate = Date.today() + 5;
        contractFour.SBQQ__Opportunity__c = opportunityFour.Id;
        contractFour.Original_Contracted_Opportunity__c = opportunityFour.Id;
        contractFour.Auto_Renewal__c = FALSE;
        contractFour.SBQQ__RenewalOpportunity__c = opportunityThree.Id; 
        newContracts.add(contractFour);
        
        insert newContracts;
    }
    
    
    @isTest
    static void testContractAutomation(){
        List<OpportunityLineItem> newLines = new List<OpportunityLineItem>();
        Opportunity oppty = [SELECT id, VAT_Number__c, VAT_Validation_Status__c, List_Price__c FROM Opportunity WHERE Name = 'Opp Testers 6 Inc' LIMIT 1];
        Test.startTest();
        PricebookEntry pricebookEntry = createPricebookEntry();
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId=oppty.Id, PriceBookEntryId=pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
        newLines.add(li);

        insert newLines;
        oppty = [SELECT id, VAT_Number__c, VAT_Validation_Status__c, List_Price__c, Blended_Discount__c, Blended_Discount_CPQ__c
                 , Buyout_Amount__c, Subsidy_Amount__c, Amount, SBQQ__PrimaryQuote__c, Buyout_Opportunity__c
                 FROM Opportunity WHERE Name = 'Opp Testers 6 Inc' LIMIT 1];
        
        	Database.executeBatch(new ContractAutomation(System.Label.Contract_Automation_Query , true), 15);
        Test.stopTest();
    }

    /*@isTest
    static void testContractAutomation2(){
        List<OpportunityLineItem> newLines = new List<OpportunityLineItem>();
        Opportunity oppty = [SELECT id, VAT_Number__c, VAT_Validation_Status__c, List_Price__c, Blended_Discount__c, Blended_Discount_CPQ__c
                 , Buyout_Amount__c, Subsidy_Amount__c, Amount, SBQQ__PrimaryQuote__c, Buyout_Opportunity__c
                 FROM Opportunity WHERE Name = 'Opp Testers 6 Inc' LIMIT 1];
        Test.startTest();
        PricebookEntry pricebookEntry = createPricebookEntry();
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId=oppty.Id, PriceBookEntryId=pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
        newLines.add(li);

        insert newLines;
        
        ContractAutomation autoCA = new ContractAutomation(System.Label.Contract_Automation_Query , true);
        List<Contract> sobjList =  Database.query(System.Label.Contract_Automation_Query);
        system.debug('opportunityFour' + sobjList[0] );
        autoCA.mockedBlendedDiscount = true;
        autoCA.execute(null, sobjList);
        Test.stopTest();
    }*/
    static private PricebookEntry createPricebookEntry() {
        
        Product2 prod = new Product2(Name = 'Laptop X200', Family = 'Hardware', ProductCode = 'T123');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        return standardPrice;
    }    
    
    @isTest
    static void testScheduledJob(){
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('ScheduledContractAutomation', CRON_EXP, new ScheduledContractAutomation());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime)); 
    }
    @isTest
    static void testContractAutoRenewalAutomation(){
        Test.startTest();
        //String query = 'SELECT EndDate, SBQQ__RenewalOpportunity__r.CloseDate, Auto_Renewal__c, Account.Account_Lifetime_ACV__c,Account.Approved_Payment_Type__c, Account.Auto_renewal_Opt_Out__c, Account.Quarantine_Enabled__c,SBQQ__Opportunity__r.Configuration_Segment__c, SBQQ__Evergreen__c, SBQQ__RenewalOpportunity__r.Renewable_ACV__c,SBQQ__RenewalOpportunity__r.Finance_Partner__c, SBQQ__RenewalOpportunity__r.Payment_Type__c,Account.Customer_ARR__c,Original_Contracted_Opportunity__r.Name, Original_Contracted_Opportunity__r.SBQQ__PrimaryQuote__c,Original_Contracted_Opportunity__r.Blended_Discount_CPQ__c,Original_Contracted_Opportunity__r.Buyout_Opportunity__c,Original_Contracted_Opportunity__r.Subsidy_Opportunity__c,Original_Contracted_Opportunity__r.License_Term__c,Original_Contracted_Opportunity__c FROM Contract WHERE Auto_Renewal__c = FALSE AND EndDate >= Today AND EndDate';
            String query = 'SELECT EndDate, Auto_Renewal__c, Account.Account_Lifetime_ACV__c, Account.Approved_Payment_Type__c, Account.Auto_renewal_Opt_Out__c, Account.Quarantine_Enabled__c, SBQQ__Opportunity__r.Configuration_Segment__c, SBQQ__Evergreen__c, SBQQ__RenewalOpportunity__r.Renewable_ACV__c, SBQQ__RenewalOpportunity__r.Finance_Partner__c, SBQQ__RenewalOpportunity__r.Payment_Type__c, Account.Customer_ARR__c FROM Contract WHERE Auto_Renewal__c = FALSE AND EndDate >= Today AND EndDate';
        	Database.executeBatch(new ContractAutoRenewalAutomation(query, true), 15);
        Test.stopTest();
    }
    
    @isTest
    static void testBatchRenewalAssignment(){
        Test.startTest();
                Opportunity opportunity = [SELECT ID, SBQQ__RenewedContract__c FROM Opportunity WHERE Name = 'Opp Testers 5 Inc'];
        		Contract contract = [SELECT ID FROM Contract WHERE Auto_Renewal__c = TRUE];
        		opportunity.SBQQ__RenewedContract__c = contract.ID;
        		update opportunity;
        	database.executebatch(new BatchRenewalAssignment(), 15);
        Test.stopTest();
    }

}