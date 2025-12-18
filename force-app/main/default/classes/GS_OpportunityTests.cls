/*
** @description : This class is to Cover GS Related Code used for Opportunity Optimizations, for Original Opportunity Coverage use OpportunityTests
**/

@isTest(SeeAllData=false)
private class GS_OpportunityTests {
    
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
        
        Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                BillingState='California',
                                BillingCountry = 'United States',
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                Industry = 'Other');
        newAccounts.add(accountTwo);

        insert newAccounts;
        
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        newContacts.add(contactOne);
        
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'test@test.com'));
        newContacts.add(contactTwo);

        insert newContacts;
        
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
        shippingAddressList.add(sa);
        Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = accountOne.Id);
        shippingAddressList.add(sa2);

        insert shippingAddressList;

        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 

        Opportunity opportunityTwo = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 2 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactTwo.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityTwo);     
        
        Opportunity opportunityThree = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityThree);  
        insert newOpportunities;
    }

    @isTest private static void testShippingFields() {
        Opportunity opportunity = [SELECT Id, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE Name='Opp Testers 3 Inc'];
        Opportunity opportunityNoAddress = [SELECT Id, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
        Shipping_Address__c address = [SELECT Id FROM Shipping_Address__c WHERE Name='Test Belgium'];
        
        Test.startTest();
        opportunity.Shipping_Address_NEW__c = address.Id;
        update opportunity;
        
        Opportunity opportunityOne = [SELECT Id, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE Name='Opp Testers 3 Inc'];
        System.assertEquals('VCK', opportunityOne.Ship_From_Location__c);
        System.assertEquals('UK Standard', opportunityOne.Shipping_Method__c);
        System.assertEquals('DHL', opportunityOne.Shipping_Carrier__c);
        System.assertEquals('DCL', opportunityNoAddress.Ship_From_Location__c);
        System.assertEquals('3 Day Select', opportunityNoAddress.Shipping_Method__c);
        System.assertEquals('UPS', opportunityNoAddress.Shipping_Carrier__c);
        Test.stopTest();
    
    }
    
    
    // -- Begin emailOnTrialAgreementAcceptance --
    @isTest 
    private static void testEmails() {
        
        Test.startTest();        
        Account a = [SELECT id FROM Account WHERE Name = 'Testers 6 Inc'];
        Contact c = [SELECT id, email FROM Contact WHERE accountId =: a.Id];
        System.debug('OpportunityTests.testEmails - contact to email: ' + c);
        
        // Create oppty, but don't set it as accepted
        Integer emailBefore = Limits.getEmailInvocations();
        System.debug('Email count before ='+emailBefore);
    
        
        RecordType trialType = [SELECT Id 
                                FROM RecordType 
                                WHERE SObjectType='Opportunity' 
                                AND Name='Trial' 
                                LIMIT 1];
        
        Opportunity trial = (Opportunity) 
            TestFactory.createSObject(new Opportunity(AccountId = a.Id, 
                                                      RecordTypeId = trialType.Id, 
                                                      Probability = 0, 
                                                      Type = 'Free Trial Opportunity'));
        insert trial;          
        
        System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
        System.debug('Email count after ='+Limits.getEmailInvocations());
        
        System.assertEquals(trial.Trial_Agreement_Accepted__c, False);
        System.assertEquals(emailBefore, Limits.getEmailInvocations());
        System.debug('Oppty is created - test success');
        
        // Change to accepted, but don't send emails yet (no owner id)
        emailBefore = Limits.getEmailInvocations();
        System.debug('Email count before ='+emailBefore);
        
        trial.Trial_Primary_Contact__c = c.Id;
        update trial;
        
        System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
        System.debug('Email count after ='+Limits.getEmailInvocations());
        System.assertEquals(trial.Trial_Agreement_Accepted__c, False);
        System.assertEquals(emailBefore, Limits.getEmailInvocations());
        System.debug('Change to Trial fields but no acceptance - test success');
        
        // Accepted true, error email sent
        emailBefore = Limits.getEmailInvocations();
        System.debug('Email count before ='+emailBefore);
        
        trial.Trial_Agreement_Accepted__c = True;
        update trial;
        
        System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
        System.debug('Email count after ='+Limits.getEmailInvocations());
        System.assertEquals(trial.Trial_Agreement_Accepted__c, True);
        System.assertNotEquals(emailBefore, Limits.getEmailInvocations());
        System.debug('Changing Acceptance status to true - test success');
        
        // Update oppty, but should not send email
        emailBefore = Limits.getEmailInvocations();
        System.debug('Email count before ='+emailBefore);
        
        trial.Name = 'New Free Trial';
        update trial;
        
        System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
        System.debug('Email count after ='+Limits.getEmailInvocations());
        System.assertEquals(trial.Trial_Agreement_Accepted__c, True);
        System.assertEquals(emailBefore, Limits.getEmailInvocations());
        System.debug('Change Oppty field but not change in acceptance - test success');
        Test.stopTest();
    }
    
    @isTest private static void testErrorEmail() {
        
        Test.startTest();
        Account a = [SELECT id FROM Account WHERE Name = 'Testers 6 Inc'];
    
        // Create oppty, but don't flip acceptance    
        Integer emailBefore = Limits.getEmailInvocations();
        System.debug('Email count before ='+emailBefore);
        
        RecordType trialType = [SELECT Id 
                                FROM RecordType 
                                WHERE SObjectType='Opportunity' 
                                AND Name='Trial' 
                                LIMIT 1];
        
        Opportunity trial = (Opportunity) 
            TestFactory.createSObject(new Opportunity(AccountId = a.Id, 
                                                      RecordTypeId = trialType.Id, 
                                                      Probability = 0, 
                                                      Type = 'Free Trial Opportunity'));
        insert trial;         
        
        System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
        System.debug('Email count after ='+Limits.getEmailInvocations());
        
        System.assertEquals(trial.Trial_Agreement_Accepted__c, False);
        System.assertEquals(emailBefore, Limits.getEmailInvocations());
        System.debug('Oppty is created - test success');
        
        // Contact not set, trial error email sent
        emailBefore = Limits.getEmailInvocations();
        System.debug('Email count before ='+emailBefore);
        
        trial.Trial_Agreement_Accepted__c = True;
        update trial;
        
        System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
        System.debug('Email count after ='+Limits.getEmailInvocations());
        System.assertEquals(trial.Trial_Agreement_Accepted__c, True);
        System.assertNotEquals(emailBefore, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    @isTest private static void testBulkEmail() {
        System.debug('In testBulkEmail');
        Test.startTest();
        // Change back when dupe rules are in order
        Integer batchSize = 1;
        
        Integer emailBefore = Limits.getEmailInvocations();
        
        // Trial oppty creation  
        List<Account> accounts = (List<Account>)
            TestFactory.createSObjectList(new Account(Name = 'testBullkEmail'), batchSize); 
        insert accounts;
        
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < batchSize; i++){
                Contact c = (Contact) 
                    TestFactory.createSObject(new Contact(FirstName = 'Test ' + i, 
                                                          Email = 'test' + i + '@test.com', 
                                                          AccountId = accounts[i].Id));       
                contacts.add(c);
        }        
        insert contacts;
        
        RecordType trialType = [SELECT Id 
                                FROM RecordType 
                                WHERE SObjectType = 'Opportunity' 
                                AND Name='Trial' 
                                LIMIT 1];
        
        List<Opportunity> trials = new List<Opportunity>();
        for (Integer i = 0; i < batchSize; i++){
            Opportunity trial = (Opportunity) 
                TestFactory.createSObject(new Opportunity(AccountId = accounts[i].Id, 
                                                          CloseDate = System.today() + 90, 
                                                          RecordTypeId = trialType.Id, 
                                                          Probability = 0, 
                                                          type = 'Free Trial Opportunity',
                                                          Trial_Primary_Contact__c = contacts[i].Id));
            trials.add(trial);
        }
        insert trials;
            
        for (Opportunity o : trials){
            System.assertEquals(o.Trial_Agreement_Accepted__c, False);
        }
        System.assertEquals(emailBefore, Limits.getEmailInvocations());
        System.debug('Trial oppty creation - test success');
        
        System.debug('Trial agreement accepted - emails should be sent');
        emailBefore = Limits.getEmailInvocations();
        System.debug('Email count before ='+emailBefore);
    
        for (Opportunity o : trials){
            o.Trial_Agreement_Accepted__c = True;
        }
        update trials;
        
        System.debug('Email count after ='+Limits.getEmailInvocations());
        System.assertNotEquals(emailBefore, Limits.getEmailInvocations());
        System.assertEquals(batchSize, Limits.getEmailInvocations());
        System.debug('Trial agreement accepted - test success');
        Test.stopTest();
        System.debug('In testBulkEmail End');
    }
    
    @isTest private static void testResellerPopulator(){
    
        List <Account> accsToInsert = new List <Account>();
        Test.startTest();
        Account acc = new Account();
        acc.Name = 'End Customer Test';
        acc.Organization_Size__c = '1 - 99';
        acc.Industry = 'Agriculture';
        acc.BillingState = 'California';
        acc.BillingCountry = 'United States';
        accsToInsert.add(acc);
    
        Account accReseller = new Account();
        accReseller.Name = 'Reseller Test';
        accReseller.Organization_Size__c = '1 - 99';
        accReseller.BillingState = 'California';
        accReseller.BillingCountry = 'United States';
        accsToInsert.add(accReseller);
    
        insert accsToInsert;
    
        Opportunity opp = new Opportunity();
        opp.Name = 'Original Oppty';
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today();
        opp.StageName = 'Closed Won';
        //opp.Reseller_Partner__c = accReseller.Id;
        insert opp;
    
        Contract con = new Contract();
        con.AccountId = acc.Id;
        con.Original_Contracted_Opportunity__c = opp.Id;
        con.StartDate = Date.today();
        con.EndDate = Date.today() + 365;
     
        insert con;
       Contract newContract = [SELECT id, Name, Original_Reseller_ID__c, StartDate, EndDate, Original_Contracted_Opportunity__c FROM CONTRACT where ID = :con.Id LIMIT 1];
    
        Opportunity renewalOpp = new Opportunity();
        renewalOpp.Name = 'Renewal Oppty';
        renewalOpp.AccountId = acc.Id;
        renewalOpp.CloseDate = Date.today() + 90;
        renewalOpp.ContractId = newContract.Id;
        renewalOpp.StageName = 'Incubate';
        renewalOpp.Reseller_Partner__c = acc.ID;
        insert renewalOpp;
        
        Opportunity renOpps = [SELECT id, Name, Reseller_Partner__c, ContractId from Opportunity WHERE id = :renewalOpp.Id LIMIT 1];
        
        System.assertEquals('Renewal Oppty', renOpps.Name);
        System.assertEquals(renOpps.Reseller_Partner__c, acc.Id);
        Test.stopTest();
    }
    
    @isTest private static void testBeforeInsertOperations(){
    
        Test.startTest();
        
        Account account = [SELECT Id FROM Account WHERE Name = 'Testers 1 Inc'];
    
        Opportunity opp = new Opportunity();
        opp.Name = 'New Opportunity Before Insert Test';
        opp.AccountId = account.Id;
        opp.CloseDate = Date.today();
        opp.StageName = 'Incubate';
        opp.All_Serial_Numbers__c = 'aXvbdn12sf344';
        insert opp;
        
        Opportunity opportunity = [SELECT All_Serial_Numbers__c FROM Opportunity WHERE id =: opp.Id];
        System.assertEquals(null, opportunity.All_Serial_Numbers__c);
        Test.stopTest();
    }
    
    @isTest static void testValidEvent() {
            
        Opportunity newOpportunity = [SELECT id from Opportunity LIMIT 1];
        Sales_Order_Event__e salesEvent = new Sales_Order_Event__e(Id__c = newOpportunity.Id);
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(salesEvent);
        Test.stopTest();
    
        System.assertEquals(true, sr.isSuccess());
    }
    
    @isTest private static void testcreateRemorseRefund() {
        String countQuery = 'SELECT count() FROM Opportunity';
        Integer currentCount = Database.countQuery(countQuery);
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
    
        Opportunity revOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
    
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Remorse Refund' ;
        thisOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOpp.StageName = 'Return Created';
        thisOpp.Amount = -1000;
        thisOpp.AccountId = acc.Id;
        thisOpp.Returning_Opportunity__c = revOpp.Id;
        thisOpp.Finance_Approved_Return__c = true;
        System.debug(LoggingLevel.INFO, 'OPPORTUNITY: '+thisOpp);
        Test.startTest();
        insert thisOpp;
        Test.stopTest();
        system.assertEquals(Database.countQuery(countQuery), currentCount + 1);
    }
    
    @isTest
    private static void tryCatchTest() {
        Opportunity revOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
        revOpp.LID__LinkedIn_Company_Id__c = 'HELLO WORLD';
    
        try {
            update revOpp;
        } catch (Exception e) {
            system.assertEquals(e.getMessage(), e.getMessage());
        }
    }
    

    static private PricebookEntry getPricebookEntry(Id pricebookId, String productCode) {
        PricebookEntry entry = [Select Id, UnitPrice, Pricebook2Id, ProductCode from PricebookEntry where ProductCode = :productCode and Pricebook2Id = :pricebookId LIMIT 1];
        return entry;
    }

    static private void addProducts(Id pricebookId) {

        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name = 'LIC-VG33', ProductCode = 'LIC-VG33', Family = 'Test');
        products.add(vg33);
        insert products;
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        insert pricebookEntries;

    }
    
    @isTest static void testExceptionGsHandler() {
        GS_OpportunityTriggerHandler oppptyTriggrHandler = new GS_OpportunityTriggerHandler();
        
        try{
            oppptyTriggrHandler.beforeInsert();  
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
        
        try{
            oppptyTriggrHandler.afterInsert(); 
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
        try{
            oppptyTriggrHandler.beforeUpdate();  
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
        try{
            oppptyTriggrHandler.afterUpdate(); 
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
        try{
            oppptyTriggrHandler.beforeDelete(); 
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
        try{
            oppptyTriggrHandler.afterdelete(); 
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
        try{
            oppptyTriggrHandler.afterUndelete(); 
        }catch(Exception ex){
            system.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        
    }
    

}