@isTest
private class FlexOpportunityTest {
    
    private static void SetupData()
    {
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User userRecord = new User(
            alias = 'flexuser', email='random@salesforce.com', 
            emailencodingkey='UTF-8', FirstName='Flex', LastName='Test User', 
            localesidkey='en_US', languagelocalekey='en_US',
            profileid = profileRecord.Id,
            timezonesidkey='America/Los_Angeles',
            Username='flextestuser@salesforce.com',
            EmployeeNumber='123'
        );
        insert userRecord; 
        List<Account> newAccounts = new List<Account>();
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Account accountOne = new Account(Name = 'Flex Account',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         Account_C_R_In_Progress__c= true,
                                         BillingPostalCode  = '1030',
                                         BillingCountry = 'United Kingdom',
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Industry = 'Other');
        newAccounts.add(accountOne);
        insert newAccounts;   
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            Contract_C_R_In_Progress__c = true,
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Auto_Renewal__c = true,
            Status = 'Draft',
            Weighted_Average_Start_Date__c =  System.today()
        );
        insert cont;
        cont.Status = 'Activated';   
        Contract cont1 = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            Contract_C_R_In_Progress__c = true,
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Auto_Renewal__c = true,
            Status = 'Draft',
            Weighted_Average_Start_Date__c =  System.today()
        );
        insert cont1;
        cont1.Status = 'Activated'; 
        Opportunity upgradedOpportunity = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Sub_Type__c = 'Contract Replacement',
                                                      Name = 'Flex Ugrade Opp',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standard_Opportunity').getRecordTypeId(),
                                                      CloseDate = System.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Monthly'));
        insert upgradedOpportunity;
        Opportunity returnOpportunity = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Remorse Refund',
                                                      Name = 'Flex Return Opp',
                                                      StageName = 'Return Initiated',
                                                      Amount = -264,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Return_Opportunity').getRecordTypeId(),
                                                      CloseDate = System.today(),
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__AmendedContract__C = cont.Id,
                                                      Selected_Payment_Type__c = 'Direct Monthly',
                                                      //Upgraded_Opportunity__c = upgradedOpportunity.Id
                                                      Upgraded_Opportunity_ID__c=upgradedOpportunity.Id));
        newOpportunities.add(returnOpportunity);  
        Opportunity returnOpportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Amount=-100,
                                                      Type = 'Remorse Refund',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Return_Opportunity').getRecordTypeId(),
                                                      Sub_Type__c = 'Contract Cancellation',
                                                      Name = 'Flex Return oppty',
                                                      Bypass_Validation_Rule_DateTime__c = Datetime.now(),
                                                      //Upgraded_Opportunity__c = upgradedOpportunity.Id,
                                                      Upgraded_Opportunity_ID__c=upgradedOpportunity.Id,
                                                      SBQQ__AmendedContract__C = cont1.Id,
                                                      StageName = 'Return Creatd',
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(returnOpportunityOne);
        insert newOpportunities;
        Related_Opportunity__c relatedOpp = new Related_Opportunity__c();
        relatedOpp.Revenue_Opportunity__c = upgradedOpportunity.Id;
        relatedOpp.Cancelation_Opportunity__c = returnOpportunity.Id;
        insert relatedOpp;
        Related_Opportunity__c relatedOppOne = new Related_Opportunity__c();
        relatedOppOne.Revenue_Opportunity__c = upgradedOpportunity.Id;
        relatedOppOne.Cancelation_Opportunity__c = returnOpportunityOne.Id;
        insert relatedOppOne;
        List<SBQQ__Quote__c> quotesListInsert = new List<SBQQ__Quote__c>();
        for (Opportunity flexOpp : [SELECT Id, Name FROM Opportunity WHERE Name = 'Flex Ugrade Opp' OR Name = 'Flex Return Opp']) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Flex - ' + flexOpp.Name, 
                                                      SBQQ__Account__c = accountOne.Id, 
                                                      SBQQ__Opportunity2__c = flexOpp.Id,
                                                      SBQQ__SubscriptionTerm__c = 10,
                                                      Estimated_Annual_Payment__c = 24, 
                                                      Flex_Related_Opportunity__c=relatedOpp.Id,
                                                      Selected_Payment_Type__c = 'Upfront Payments', 
                                                      SBQQ__Status__c = 'Draft');
            quotesListInsert.add(quote);
        }
        insert quotesListInsert;          
        
    }
    
    @isTest
    private static void testFlexSyncReturnOpportunites()
    {
        SetupData();
        User userRecord = [SELECT Id, Name FROM User WHERE Username='flextestuser@salesforce.com'];
        Account accountRecord = [SELECT Id, Name FROM Account WHERE Name = 'Flex Account'];
        Opportunity upgradedOpportunity = [SELECT Id, Name, StageName, CloseDate, OwnerId FROM Opportunity WHERE Name = 'Flex Ugrade Opp'];
        Test.startTest();
            upgradedOpportunity.CloseDate = upgradedOpportunity.CloseDate + 1;
            upgradedOpportunity.StageName = 'Qualified';
            upgradedOpportunity.OwnerId = userRecord.Id;
            update upgradedOpportunity;
        Test.stopTest();
        Opportunity opp = [SELECT Id, Name, StageName, OwnerId FROM Opportunity WHERE Name = 'Flex Return Opp'];
        List<SBQQ__Quote__c> quotes = [SELECT Id, Name, OwnerId FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id];
        System.assertEquals('Return Created', opp.StageName );
        System.assertEquals(userRecord.Id, opp.OwnerId);
        System.assertEquals(userRecord.Id, quotes[0].OwnerId);
    }  
    @isTest
    private static void testsetCnRFlagOnAccountClosedWon()
    {
        SetupData();
        Opportunity opptyRecord = [SELECT Id, Name,Closed_Lost_Reason__c,stageName FROM Opportunity WHERE Name = 'Flex Ugrade Opp'];
        
        Test.startTest();
        opptyRecord.StageName = 'Closed Won';
        update opptyRecord;
        Test.stopTest();
        
        Opportunity opp = [SELECT Id, Name, stageName, SBQQ__AmendedContract__r.Contract_C_R_In_Progress__c,Closed_Lost_Reason__c FROM Opportunity WHERE Name = 'Flex Return Opp'];
        System.assertEquals('Finance Processing', opp.StageName, 'The StageName should be Finance Processing');  
    }
    @isTest
    private static void testsetCnRFlagOnAccountClosedLost()
    {           
        SetupData();
        Opportunity opptyRecord = [SELECT Id, Name,Closed_Lost_Reason__c,stageName FROM Opportunity WHERE Name = 'Flex Ugrade Opp'];
        
        Test.startTest();
        opptyRecord.StageName = 'Closed Lost';
        opptyRecord.Closed_Lost_Reason__c = 'Test';
        update opptyRecord;
        Test.stopTest(); 
        
        Opportunity opp = [SELECT Id, Name, stageName, SBQQ__AmendedContract__r.Contract_C_R_In_Progress__c,Closed_Lost_Reason__c FROM Opportunity WHERE Name = 'Flex Return Opp'];
        system.assertEquals(false, opp.SBQQ__AmendedContract__r.Contract_C_R_In_Progress__c, 'Contract flag on return opportunity should be false');
        
        //Verify Account flag is false because all the opportunity are closed "
        Account testAccount = [SELECT Id, Account_C_R_In_Progress__c FROM Account WHERE Name ='Flex Account'];
        system.assertEquals(false, testAccount.Account_C_R_In_Progress__c, 'Account flag should should be false as all the opportunity are closed');
        
    }       
    @isTest
    static void testCnRClosingValidation() {
        Account acc = new Account(Name = 'Flex Account',
                                  BillingState='California',
                                  BillingCountry = 'United States',
                                  BillingStreet = '26 Napier Street',
                                  BillingCity = 'London',
                                  BillingPostalCode  = '1030',
                                  Billing_Email__c  = 'qdasdas@gmail.com',
                                  Organization_Size__c = '100 - 499',
                                  Account_C_R_In_Progress__c= true,
                                  Approved_Payment_Type__c = 'Direct Monthly',
                                  Industry = 'Other');
        insert acc;           
        Contract contract= new Contract(Name = 'Test Contract',
                                        Contract_C_R_In_Progress__c=true, 
                                        StartDate = Date.today(), 
                                        AccountId = acc.Id);
        insert contract;
         System.debug('SOQL queries contract used: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            SBQQ__AmendedContract__c=contract.Id,
            StageName = 'Qualified',
            CloseDate = Date.today(),
            Sub_Type__c = 'Virtual Return'
        );
        insert opp;
            System.debug('SOQL queries opp used: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());                
            Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', 
                                         Family = 'Hardware', 
                                         ProductCode = 'LIC-2GB-WIFI-DATA',
                                         Product_Type__c = 'License');
            insert prod;
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry PricebookEntry = new PricebookEntry(
                Pricebook2Id = pricebookId, 
                Product2Id = prod.Id,
                UnitPrice = 10000, 
                IsActive = true);
            
            insert PricebookEntry;
            TriggerHandler.bypass('AccountTriggerHandler');
            TriggerHandler.bypass('OpportunitySplitTriggerHandler');
            TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
            System.debug('SOQL queries PricebookEntry used: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());       
            OpportunityLineItem oppProduct = new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 5,
                UnitPrice = 10,
                Product2Id = prod.Id,
                PricebookEntryId = PricebookEntry.Id,   
                Product_Code_Copy__c='LIC-SG-STRG16'
            );
            insert oppProduct;  
              Test.startTest();         
            // Update the Opportunity with StageName = 'Closing' to check for the error condition
            opp.StageName = 'Closing';
            try {
                update opp; 
                System.assert(false, 'The error should have been thrown.');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('You cannot submit this Opportunity to “Closing”'),e.getMessage());
                System.debug('Caught DmlException: ' + e.getMessage());        
            }
        Test.stopTest();
    }   
}