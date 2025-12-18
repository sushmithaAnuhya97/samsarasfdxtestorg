@isTest(SeeAllData=false)
public class GS_OpportunityToUpdateAccountTests {

    @testSetup
    private static void testDataSetup() {
       insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
       List<Opportunity> newOpportunities = new List<Opportunity>();
       List<Account> newAccounts = new List<Account>();
       List<Contact> newContacts = new List<Contact>();
       List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
        
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        newAccounts.add(accountOne);

        
        Account accountTwo = new Account(Name = 'Testers 3 Inc',
                                BillingStreet = 'test 123',
                                BillingState='California',
                                BillingCountry = 'United States',
                                BillingPostalCode = '94856',
                                Netsuite_Id__c = null,     
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                Industry = 'Other');
        newAccounts.add(accountTwo);
        
        insert newAccounts;
        
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        newContacts.add(contactOne);
        
        
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'tesdft@test.com'));
        newContacts.add(contactTwo);

        insert newContacts;
        
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
        shippingAddressList.add(sa);
        
        Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactTwo.Id, Shipping_Address_Line_1__c='1 Dolores, DallasNew', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountTwo.Id);
        shippingAddressList.add(sa2);

        insert shippingAddressList;

        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Configuration_Segment__c = 'Express',
                                                      Payment_Token__c = 'Payment_Token',
                                                      Probability = 100,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        
         newOpportunities.add(opportunityOne); 
        
        Opportunity opportunityTwo = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 4 Inc',
                                                      StageName = 'Decision',
                                                      Shipping_Contact__c = contactTwo.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        
         newOpportunities.add(opportunityTwo); 
        
         Opportunity closedWonRevOpp = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Closed Won Opp Testers 4 Inc',
                                                      StageName = 'Closed Won', 
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard'));

        newOpportunities.add(closedWonRevOpp);  
        insert newOpportunities;
        
        // Update Revenue Opportunity for Express Configuration_Segment__c;
        opportunityOne.Configuration_Segment__c = 'Express';
        
        update opportunityOne;
    }
    
    
    
    @isTest static void testVATSync() {
        Opportunity newOpportunity = [SELECT id, AccountId, VAT_Number__c, VAT_Validation_Status__c FROM Opportunity WHERE Type = 'Revenue Opportunity' LIMIT 1];
        Test.startTest();
        newOpportunity.VAT_Number__c = 'ART33W';
        newOpportunity.VAT_Validation_Status__c = 'Verified';
        update newOpportunity;       
        (new GS_OpportunityToUpdateAccountAsync()).execute(new Async_Request__c(
            Params__c = newOpportunity.Id+';',
            Options__c = JSON.serialize((new GS_OpportunityToUpdateAccountAsync.Options('BEFORE_UPDATE_OPERATIONS',
                    new Map<Id,GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions>{
                    newOpportunity.Id => new GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions(true,false,false)
                })))
        ));
         Test.stopTest();
        Account newOpportunityAccount = [Select VAT_Validation_Status__c, VATId__c from Account where Id =: newOpportunity.AccountId];
        system.assertEquals(newOpportunity.VAT_Number__c, newOpportunityAccount.VATId__c);
        system.assertEquals(newOpportunity.VAT_Validation_Status__c, newOpportunityAccount.VAT_Validation_Status__c);
        
    }
    
    @isTest static void testFirstPurchaseValue() {
        Opportunity newOpportunity = [SELECT id, AccountId, Type, IsWon, Amount FROM Opportunity WHERE Name = 'Closed Won Opp Testers 4 Inc' LIMIT 1];
        Test.startTest();
        newOpportunity.Type = 'Revenue Opportunity';
        newOpportunity.Amount = 1000;
        
        update newOpportunity;
       
        (new GS_OpportunityToUpdateAccountAsync()).execute(new Async_Request__c(
            Params__c = newOpportunity.Id+';',
            Options__c = JSON.serialize((new GS_OpportunityToUpdateAccountAsync.Options('BEFORE_UPDATE_OPERATIONS',
                    new Map<Id,GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions>{
                    newOpportunity.Id => new GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions(false,true,false)
                })))
        ));
         Test.stopTest(); 
        Account newOpportunityAccount = [Select First_Purchase_Value__c from Account where Id =: newOpportunity.AccountId];
        system.assertEquals(newOpportunity.Amount, newOpportunityAccount.First_Purchase_Value__c);
    }
    
    @isTest static void testIsNewBillingProcessApproved() {
        Opportunity newOpportunity = [SELECT id, AccountId, IsClosed FROM Opportunity WHERE Name = 'Opp Testers 3 Inc' LIMIT 1];
        Test.startTest();
        
         update newOpportunity;
        
        newOpportunity = [SELECT id, AccountId, Configuration_Segment__c FROM Opportunity WHERE id =: newOpportunity.Id];
       
        (new GS_OpportunityToUpdateAccountAsync()).execute(new Async_Request__c(
            Params__c = newOpportunity.Id+';',
            Options__c = JSON.serialize((new GS_OpportunityToUpdateAccountAsync.Options('BEFORE_UPDATE_OPERATIONS',
                    new Map<Id,GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions>{
                    newOpportunity.Id => new GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions(false,false,true)
                })))
        ));
         Test.stopTest(); 
        Account newOpportunityAccount = [Select New_Billing_Process_Approved__c from Account where Id =: newOpportunity.AccountId];
        system.assertEquals(true, newOpportunityAccount.New_Billing_Process_Approved__c);
    }
    
    
    
     //Groundswell - Nilesh Jain : Workflow Optimization changes related to Account Updates
    @isTest
    private static void testAccountUpdates(){
		Test.startTest();
        Opportunity opptyAfterInsert = [Select id, AccountId, CloseDate, Amount_Received__c, StageName, Internal_Finance__c FROM Opportunity WHERE Name = 'Opp Testers 4 Inc'];
        opptyAfterInsert.StageName = 'Closed Won';
        opptyAfterInsert.Internal_Finance__c = 'Approved';
        opptyAfterInsert.CloseDate = Date.today();
        opptyAfterInsert.Amount_Received__c = 60;
        update opptyAfterInsert;
        
        (new GS_OpportunityToUpdateAccountAsync()).execute(new Async_Request__c(
            Params__c = opptyAfterInsert.Id+';',
            Options__c = JSON.serialize((new GS_OpportunityToUpdateAccountAsync.Options('AFTER_UPDATE_OPERATIONS',
                    new Map<Id,GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions>{
                    opptyAfterInsert.Id => new GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions(false,false,false,true,false,true)
                })))
        ));
        
       Account acc = [Select id, Internally_Financed__c, Churn_Update_CC_Link__c FROM Account WHERE Id =: opptyAfterInsert.AccountId LIMIT 1];
        //Update Payment Method Link on Account workflow
        system.assertEquals(true, acc.Internally_Financed__c);
        //Account Internally Financed workflow
        system.assertEquals(acc.Churn_Update_CC_Link__c, System.Label.UpdatePaymentMethodLink + acc.Id);

        test.stopTest();

    }
    
    // Groundswell : Tanuj - WFlow Rule : Update Account for NS Sync
     @isTest
    private static void testUpdateAccountForNsSync(){
        
        
       Opportunity thisOpp = [Select id, AccountId, CloseDate, Amount_Received__c, StageName, Internal_Finance__c FROM Opportunity WHERE Name = 'Opp Testers 4 Inc'];
        
        test.startTest();
        thisOpp = [Select AccountId from opportunity where id =: thisOpp.id];
     /*   (new GS_OpportunityServiceAsync()).execute(new Async_Request__c(
            Params__c = thisOpp.Id+';',
            Options__c = JSON.serialize(new GS_OpportunityServiceAsync.Options('AFTER_INSERT_OPERATIONS'))
        ));
        
        acc = [Select id, Netsuite_Id__c, Push_to_Netsuite__c  FROM Account WHERE Id =: thisOpp.AccountId LIMIT 1];
        system.assertEquals(true, acc.Push_to_Netsuite__c);
        */
        
        Opportunity opptyAfterInsert = [Select id, AccountId, StageName FROM Opportunity WHERE Id=: thisOpp.Id];        
        opptyAfterInsert.StageName = 'Qualified';
        
        update opptyAfterInsert;
        
        (new GS_OpportunityToUpdateAccountAsync()).execute(new Async_Request__c(
            Params__c = opptyAfterInsert.Id+';',
            Options__c = JSON.serialize((new GS_OpportunityToUpdateAccountAsync.Options('AFTER_UPDATE_OPERATIONS',
                    new Map<Id,GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions>{
                    opptyAfterInsert.Id => new GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions(false,false,false,true,true,false)
                })))
        ));
        
      Account  acc = [Select id, Netsuite_Id__c, Push_to_Netsuite__c  FROM Account WHERE Id =: opptyAfterInsert.AccountId LIMIT 1];
        system.assertEquals(true, acc.Push_to_Netsuite__c);
        
        test.stopTest(); 
      
    }
    
     @isTest
    private static void testIsAccountStatusOpenOpportunity(){
        test.startTest();
        Opportunity newOpportunity = [SELECT id, AccountId, Type, IsWon, Amount FROM Opportunity WHERE Name = 'Opp Testers 3 Inc' LIMIT 1];
		newOpportunity.StageName = 'Decision';
        update newOpportunity;
        
        (new GS_OpportunityToUpdateAccountAsync()).execute(new Async_Request__c(
            Params__c = newOpportunity.Id+';',
            Options__c = JSON.serialize((new GS_OpportunityToUpdateAccountAsync.Options('AFTER_UPDATE_OPERATIONS',
                    new Map<Id,GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions>{
                    newOpportunity.Id => new GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions(true,false,false,false,false,false)
                })))
        ));
        
        Account  acc = [Select id, Status__c FROM Account WHERE Id =: newOpportunity.AccountId LIMIT 1];
        system.assertEquals('Open Opportunity', acc.Status__c);
        
         test.stopTest(); 
    }

    @isTest
    private static void testIsAccountStatusExistingCustomer(){
        test.startTest();
        Opportunity newOpportunity = [SELECT id, AccountId, Type, IsWon, Amount FROM Opportunity WHERE Name = 'Opp Testers 3 Inc' LIMIT 1];
		newOpportunity.StageName = 'Closed Won';
        update newOpportunity;
        
        (new GS_OpportunityToUpdateAccountAsync()).execute(new Async_Request__c(
            Params__c = newOpportunity.Id+';',
            Options__c = JSON.serialize((new GS_OpportunityToUpdateAccountAsync.Options('AFTER_UPDATE_OPERATIONS',
                    new Map<Id,GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions>{
                    newOpportunity.Id => new GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions(false,true,false,false,false,false)
                })))
        ));
        
        Account  acc = [Select id, Status__c FROM Account WHERE Id =: newOpportunity.AccountId LIMIT 1];
        system.assertEquals('Existing Customer', acc.Status__c);
        
         test.stopTest(); 
    }

    @isTest
    private static void testIsAccountLinkedToLastOrder(){
        test.startTest();
        Opportunity newOpportunity = [SELECT id, AccountId, Type, IsWon, Amount FROM Opportunity WHERE Name = 'Opp Testers 3 Inc' LIMIT 1];
		newOpportunity.StageName = 'Closed Won';
        update newOpportunity;
        
        (new GS_OpportunityToUpdateAccountAsync()).execute(new Async_Request__c(
            Params__c = newOpportunity.Id+';',
            Options__c = JSON.serialize((new GS_OpportunityToUpdateAccountAsync.Options('AFTER_UPDATE_OPERATIONS',
                    new Map<Id,GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions>{
                    newOpportunity.Id => new GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions(false,false,true,false,false,false)
                })))
        ));
        
        Account  acc = [Select id, Link_to_Last_Order__c FROM Account WHERE Id =: newOpportunity.AccountId LIMIT 1];
        system.assertEquals(URL.getSalesforceBaseUrl().toExternalForm() + '/' + newOpportunity.Id, acc.Link_to_Last_Order__c);
        
         test.stopTest(); 
    }

}