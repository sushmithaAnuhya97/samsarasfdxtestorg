@isTest(SeeAllData=false)
public class GS_OpportunityWorkflowConversionTests {
    
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
        
        Opportunity resolutionOpp = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                Type = 'Free Trial Opportunity',
                                                Name = 'Resolution Opp',
                                                StageName = 'Closed Won',
                                                Probability = 100,
                                                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                Send_Invoice__c = false));
        newOpportunities.add(resolutionOpp);
        
        insert newOpportunities;
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
    
    
    //Groundswell - Nilesh Jain : Workflow Optimization changes
    @isTest
    private static void testWorkflowChanges(){
        OpportunityTriggerHandler.maxRuns = 1;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('WorkflowChanges');
        acc.BillingStreet = 'test 123';
        acc.BillingCity = 'San jose';
        acc.BillingPostalCode = '94856';
        acc.Churn_Update_CC_Link__c = 'test';
        insert acc;
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Incubate';
        thisOpp.Shipping_Method__c = 'Will Call';
        thisOpp.Freight_Cost__c = 500;
        thisOpp.AccountId = acc.Id;
        thisOpp.Cust_Partner_Shipping_Account_Number__c = 'test';
        //thisOpp.Pricebook2Id = pricebookId;
        test.startTest();
        insert thisOpp;

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice);
        insert oli;

        Opportunity opp = [Select id, CloseDate, Freight_Cost__c, Overwrite_Validation_Rule__c, Freight_Account__c, Amount_Received__c,
                Price_Book_Name__c, Shipping_Account_Type__c, Shipping_Method__c, StageName, Finance_Segment__c, Finance_Segment_Stamp__c,
                Shipping_Address_Line_1__c, Shipping_City__c, Shipping_Zip_Code__c, PriceBook2Id, PriceBook2.Name FROM Opportunity WHERE Id=: thisOpp.Id];
        //Make freight charge $0 workflow
        system.assertEquals(opp.Freight_Cost__c, 0);
        //Customer Freight Account workflow
        system.assertEquals(opp.Freight_Account__c, '00000');
        //Set Default Shipping Address workflow
        system.assertEquals(opp.Shipping_Address_Line_1__c, acc.BillingStreet);
        system.assertEquals(opp.Shipping_City__c, acc.BillingCity);
        system.assertEquals(opp.Shipping_Zip_Code__c, acc.BillingPostalCode);
        //Update To Qualified workflow
        system.assertEquals(opp.StageName, 'Qualified');
        //Finance Segment Stamp workflow
        system.assertEquals(opp.Finance_Segment_Stamp__c, opp.Finance_Segment__c);

        test.stopTest();

    }
    
    
     @isTest
    private static void testWorkflowChangesSecondIteration(){
        OpportunityTriggerHandler.maxRuns = 1;
        
       Opportunity thisOpp = [ SELECT Id FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
        
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
      //  Opportunity thisOpp = new Opportunity();
      //  thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.StageName = 'Return Cancelled';
        thisOpp.CloseDate = null;
        thisOpp.Overwrite_Validation_Rule__c = true;
        thisOpp.Cust_Partner_Shipping_Account_Number__c = 'test';
        thisOpp.Freight_Account__c = 'test';
        thisOpp.Shipping_Account_Type__c = 'Cust/Partner Account - FedEx';
        thisOpp.Shipping_Method__c = 'Ground';
        thisOpp.Freight_Cost__c = 20;
        
        test.startTest();

        update thisOpp;
        
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice);
        insert oli;

        //Set Closed Date for Returns workflow
      Opportunity  opp = [Select id, StageName, Freight_Cost__c, Internal_Finance__c, Amount_Received__c,
                Overwrite_Validation_Rule__c, Freight_Account__c, CloseDate, MBO_Authorized_By__c, MBO_Authorized_Date_Time__c FROM Opportunity WHERE Id=: thisOpp.Id];
        system.assertEquals(opp.CloseDate, system.today());
        //Make freight charge $0 workflow
        system.assertEquals(opp.Freight_Cost__c, 0);
        //Uncheck Overwrite Validation workflow
        system.assertEquals(opp.Overwrite_Validation_Rule__c, false);
        //Customer Freight Account workflow
        system.assertEquals(opp.Freight_Account__c, '00000');
        test.stopTest();

    }

    // Groundswell : Tanuj - WFlow Rule : Copy Owner Role
    @isTest
    private static void testCopyOwnerRoleWflow(){
        OpportunityTriggerHandler.maxRuns = 1;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        acc.BillingStreet = 'test 123';
        acc.BillingCity = 'San jose';
        acc.BillingPostalCode = '94856';
        insert acc;

        test.startTest();
        
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        UserRole urMgmt = new UserRole();
        UserRole urSrDrPartner = new UserRole();
        
        User userRecordWithMgmtRole = new User();
        User userRecordWithSrPartnrRole = new User();
        
        system.runAs(thisUser){
            urMgmt = new UserRole(Name = 'Management');
            insert urMgmt;
            urSrDrPartner = new UserRole(Name = 'Senior Director Partner');
            insert urSrDrPartner;
            
            userRecordWithMgmtRole = (User)
                TestFactory.createSObject(new User(ProfileId = pId,
                                                   EmployeeNumber = '123',
                                                   LastName = 'last',
                                                   Email = 'puser000@amamama.com',
                                                   Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
                                                   CompanyName = 'TEST',
                                                   Title = 'title',
                                                   Alias = 'alias',
                                                   TimeZoneSidKey = 'America/Los_Angeles',
                                                   EmailEncodingKey = 'UTF-8',
                                                   LanguageLocaleKey = 'en_US',
                                                   LocaleSidKey = 'en_US',
                                                   Order_Admin_Fallback_User__c = TRUE,
                                                   isActive = TRUE,
                                                   UserRoleId = urMgmt.Id ));
            insert userRecordWithMgmtRole;
            
            
            userRecordWithSrPartnrRole = (User)
                TestFactory.createSObject(new User(ProfileId = pId,
                                                   EmployeeNumber = '123',
                                                   LastName = 'last',
                                                   Email = 'puser000@amamama.com',
                                                   Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
                                                   CompanyName = 'TEST',
                                                   Title = 'title',
                                                   Alias = 'alias',
                                                   TimeZoneSidKey = 'America/Los_Angeles',
                                                   EmailEncodingKey = 'UTF-8',
                                                   LanguageLocaleKey = 'en_US',
                                                   LocaleSidKey = 'en_US',
                                                   Order_Admin_Fallback_User__c = TRUE,
                                                   isActive = TRUE,
                                                   UserRoleId = urSrDrPartner.Id ));
            insert userRecordWithSrPartnrRole;
  
        }
        
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('CopyOwnerWflow_Ott');
        thisOpp.AccountId = acc.Id;
        thisOpp.OwnerId = userRecordWithMgmtRole.Id;
        
        thisOpp.StageName = 'Qualified';
        //thisOpp.Pricebook2Id = pricebookId;
        
        system.debug('Start Insert');
        
        insert thisOpp;

        
        
        Opportunity oppAfterInsert = [Select id, Owner_Role_Copy__c, Owner.UserRole.Name, StageName FROM Opportunity WHERE Id=: thisOpp.Id];
        //Copy Owner Role
        system.assertEquals(oppAfterInsert.Owner.UserRole.Name, oppAfterInsert.Owner_Role_Copy__c);
       
        test.stopTest(); 
    
    }


    
     @isTest
    private static void testCopyOwnerRoleWflowUpdate(){
        OpportunityTriggerHandler.maxRuns = 1;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        acc.BillingStreet = 'test 123';
        acc.BillingCity = 'San jose';
        acc.BillingPostalCode = '94856';
        insert acc;
        Opportunity oppAfterInsert = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];

        test.startTest();
        
        
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        UserRole urMgmt = new UserRole();
        UserRole urSrDrPartner = new UserRole();
        
        User userRecordWithMgmtRole = new User();
        User userRecordWithSrPartnrRole = new User();
        
        system.runAs(thisUser){
            urMgmt = new UserRole(Name = 'Management');
            insert urMgmt;
            urSrDrPartner = new UserRole(Name = 'Senior Director Partner');
            insert urSrDrPartner;
     
            userRecordWithSrPartnrRole = (User)
                TestFactory.createSObject(new User(ProfileId = pId,
                                                   EmployeeNumber = '123',
                                                   LastName = 'last',
                                                   Email = 'puser000@amamama.com',
                                                   Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
                                                   CompanyName = 'TEST',
                                                   Title = 'title',
                                                   Alias = 'alias',
                                                   TimeZoneSidKey = 'America/Los_Angeles',
                                                   EmailEncodingKey = 'UTF-8',
                                                   LanguageLocaleKey = 'en_US',
                                                   LocaleSidKey = 'en_US',
                                                   Order_Admin_Fallback_User__c = TRUE,
                                                   isActive = TRUE,
                                                   UserRoleId = urSrDrPartner.Id ));
            insert userRecordWithSrPartnrRole;
  
        }
        
        
        oppAfterInsert.StageName = 'Qualified';
        oppAfterInsert.OwnerId = userRecordWithSrPartnrRole.Id;
        
        update oppAfterInsert;

        Opportunity oppAfterOwnerUpdate = [Select id, Owner_Role_Copy__c, Owner.UserRole.Name, StageName FROM Opportunity WHERE Id=: oppAfterInsert.Id];
        //Copy Owner Role on Update
        system.assertEquals(oppAfterOwnerUpdate.Owner.UserRole.Name, oppAfterOwnerUpdate.Owner_Role_Copy__c);
        
        test.stopTest();         
    }

    // Copy Owner Role Wflow
    // 2nd Test Case -  Copy Returning Oppty role
    @isTest
    private static void testCopyOwnerRoleWflowRetOppty(){
        OpportunityTriggerHandler.maxRuns = 3;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        acc.BillingStreet = 'test 123';
        acc.BillingCity = 'San jose';
        acc.BillingPostalCode = '94856';
        insert acc;
        
        Opportunity revOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];        
        
        
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.AccountId = acc.Id;
        thisOppRet.Returning_Opportunity__c = revOpp.Id;
        thisOppRet.StageName = 'Qualified';
        thisOppRet.Type = 'Rebate' ;
        
        test.startTest();
        
        insert thisOppRet;
        
        
        Opportunity oppAfterRetOpptyInsert = [Select id, Owner_Role_Copy__c, Owner.UserRole.Name, StageName,Returning_Opportunity__r.Owner_Role_Copy__c FROM Opportunity WHERE Id=: thisOppRet.Id];
        //Copy Owner Role - AfterRetOpptyUpdate (2nd Condition)
        system.assertEquals(oppAfterRetOpptyInsert.Returning_Opportunity__r.Owner_Role_Copy__c, oppAfterRetOpptyInsert.Owner_Role_Copy__c);       
           
         test.stopTest(); 
        
    }
    
    // Groundswell : Tanuj - Common Wflow Test Method
    @isTest
    private static void testCommonWflowConversion(){
        OpportunityTriggerHandler.maxRuns = 1;
        
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('UpdateAccountForNsSync');
        acc.BillingStreet = 'test 123';
        acc.BillingCity = 'San jose';
        acc.BillingPostalCode = '94856';
        acc.BillingCountry  = 'United States';
        acc.Billing_Email__c = 'testaccEmail@tst.com';
        acc.Netsuite_Id__c = null;
        
        insert acc; 
        
        //Update License Term Credit on Creation
        Opportunity revOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
        
        
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        User userRecord = new User();
        userRecord = (User)TestFactory.createSObject(new User(ProfileId = pId,
                                               EmployeeNumber = '123',
                                               LastName = 'last',
                                               Email = 'puser000@amamama.com',
                                               Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
                                               CompanyName = 'TEST',
                                               Title = 'title',
                                               Alias = 'alias',
                                               TimeZoneSidKey = 'America/Los_Angeles',
                                               EmailEncodingKey = 'UTF-8',
                                               LanguageLocaleKey = 'en_US',
                                               LocaleSidKey = 'en_US',
                                               Order_Admin_Fallback_User__c = TRUE,
                                               isActive = TRUE,
                                               Level__c = 'AE 1'));
        insert userRecord;
        
        test.startTest();
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('CommonWFlow_Oppty');
        thisOpp.AccountId = acc.Id;
        thisOpp.StageName = 'Decision';
        thisOpp.OwnerId = userRecord.Id;
        
        // Update License Term Credit on Creation
        thisOpp.Returning_Opportunity__c = revOpp.Id;
        thisOpp.Rebate_Type__c = 'License Term Credit' ;
        thisOpp.License_Months_to_Credit__c = '1';
        thisOpp.Amount = 1000;
        
        
        insert thisOpp;
        
        Opportunity opptyAfterInsert = [Select id, Name, Amount, StageName FROM Opportunity WHERE Id=: thisOpp.Id];    
        
        //Update License Term Credit on Creation
        system.assertEquals(revOpp.Name+'& - License Term Credit', opptyAfterInsert.Name);
        system.assertEquals(0, opptyAfterInsert.Amount);

        //MBO Authorized Stamping
        opptyAfterInsert.MBO_Authorized__c = true;
        //Clear Push Return to Netsuite Checkbox
        opptyAfterInsert.Corresponding_Netsuite_ID__c = 'NetsuiteId';
        opptyAfterInsert.Push_Return_to_Netsuite__c = true;
        opptyAfterInsert.Rebate_Type__c = 'Buyout';
        //Move Webstore Oppty to Closing
        opptyAfterInsert.Small_Fleet_Opportunity__c = true;
        opptyAfterInsert.Express_Agreement_Accepted_Date__c = system.today();
        opptyAfterInsert.Amount_Received__c = 1000;
        opptyAfterInsert.Amount = 1000;
        //Add Default Expiring Discount Date
        opptyAfterInsert.Discount_Approval_Status__c = 'Approved';
        
        
        update opptyAfterInsert;
        Opportunity opptyAfterUpdate = [Select id, Amount, MBO_Authorized_By__c, MBO_Authorized_Date_Time__c, Push_Return_to_Netsuite__c, StageName, Checkout_Discount_Expiration_Date_Time__c,Historical_Amount__c FROM Opportunity WHERE Id=: opptyAfterInsert.Id];        
        
        //MBO Authorized By Stamp       
        system.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(),opptyAfterUpdate.MBO_Authorized_By__c);
        //MBO Authorized Date/Time Stamp
        system.assertNotEquals(null, opptyAfterUpdate.MBO_Authorized_Date_Time__c);
        //Clear Push Return to Netsuite Checkbox
        system.assertEquals(false, opptyAfterUpdate.Push_Return_to_Netsuite__c);
        //Move Webstore Oppty to Closing
        system.assertEquals('Closing', opptyAfterUpdate.StageName);
        //Add Default Expiring Discount Date
        system.assertNotEquals(null, opptyAfterUpdate.Checkout_Discount_Expiration_Date_Time__c);

        
        //Clear Push Transfer Order to Netsuite Checkbox
        opptyAfterUpdate.Retry_TO_to_NS__c = true;
        opptyAfterUpdate.Netsuite_Transfer_Order_ID__c = 'NetSuiteOrderID';
        
        update opptyAfterUpdate;
        
        Opportunity oppAfterSecondUpdate = [Select id, Name, Retry_TO_to_NS__c FROM Opportunity WHERE Id=: opptyAfterUpdate.Id];
        
        
        //Clear Push Transfer Order to Netsuite Checkbox
        system.assertEquals(false, oppAfterSecondUpdate.Retry_TO_to_NS__c);
        
        test.stopTest(); 
    }
    
    
    // Groundswell : Tanuj - Common Wflow 2nd Test Method
    @isTest
    private static void testCommonWflowConversionSecond(){
        OpportunityTriggerHandler.maxRuns = 1;
        test.startTest();
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('UpdateAccountForNsSync');
        acc.BillingStreet = 'test 123';
        acc.BillingCity = 'San jose';
        acc.BillingPostalCode = '94856';
        acc.BillingCountry  = 'United States';
        acc.Billing_Email__c = 'testaccEmail@tst.com';
        acc.Netsuite_Id__c = null;
        
        insert acc; 
        

        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.AccountId = acc.Id;
        
        insert thisOpp;
        
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c =thisOpp.Id, 
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = true, Custom_License_Term__c = 2);
        insert quote;
        
        
        //Save the Amount of the Opportunity when Closed Won
        //opptyAfterUpdate.Type = 'Remorse Refund';
        thisOpp.StageName = 'Closed Won';
        thisOpp.Historical_Amount__c = null;
       
        // To pass the validation rule
        thisOpp.Probability = 90;
        
        //Clear the field values from the primary quote workflow changes
        thisOpp.SBQQ__PrimaryQuote__c = quote.id;
        thisOpp.Approved_Discount__c = 10;
        thisOpp.Blended_Discount_CPQ__c = 10;
        thisOpp.Discount_Approval_Status_from_Quote__c = true;
        thisOpp.Discount__c = 'Test Class';
        thisOpp.License_Term_CPQ__c = 36;
        thisOpp.Product_Approval_Status_from_Quote__c = true;
        thisOpp.Sales_Tax_Amount__c = 1000;
        thisOpp.Shipping_and_Handling_Amount__c = 1000;
        thisOpp.Hardware_Sales_Tax_CPQ__c = 1000;
        thisOpp.License_Sales_Tax_CPQ__c = 1000; 
        
        
        update thisOpp;
        
        Opportunity oppAfterUpdate = [Select id, Name, Historical_Amount__c, Amount,  Retry_TO_to_NS__c, Netsuite_Transfer_Order_ID__c FROM Opportunity WHERE Id=: thisOpp.Id];
        
        //Save the Amount of the Opportunity when Closed Won
        system.assertEquals(oppAfterUpdate.Amount, oppAfterUpdate.Historical_Amount__c); 
        
        
       // Clear the field values from the primary quote workflow changes
        oppAfterUpdate.SBQQ__PrimaryQuote__c = null;
        update oppAfterUpdate;
        
        
        Opportunity oppAfterSecondUpdate = [Select id, Name, Approved_Discount__c, Blended_Discount_CPQ__c, Discount_Approval_Status_from_Quote__c, Discount__c, License_Term_CPQ__c, Product_Approval_Status_from_Quote__c, Sales_Tax_Amount__c, Shipping_and_Handling_Amount__c, Hardware_Sales_Tax_CPQ__c, License_Sales_Tax_CPQ__c FROM Opportunity WHERE Id=: oppAfterUpdate.Id];

        //Clear the field values from the primary quote workflow changes
        system.assertEquals(null, oppAfterSecondUpdate.Approved_Discount__c);
        system.assertEquals(null, oppAfterSecondUpdate.Blended_Discount_CPQ__c);
        system.assertEquals(false, oppAfterSecondUpdate.Discount_Approval_Status_from_Quote__c);
        system.assertEquals(null, oppAfterSecondUpdate.Discount__c);
        system.assertEquals(null, oppAfterSecondUpdate.License_Term_CPQ__c);
        system.assertEquals(false, oppAfterSecondUpdate.Product_Approval_Status_from_Quote__c);
        system.assertEquals(null, oppAfterSecondUpdate.Sales_Tax_Amount__c);
        system.assertEquals(null, oppAfterSecondUpdate.Shipping_and_Handling_Amount__c);
        system.assertEquals(null, oppAfterSecondUpdate.Hardware_Sales_Tax_CPQ__c);
        system.assertEquals(null, oppAfterSecondUpdate.License_Sales_Tax_CPQ__c);
        
        test.stopTest(); 
    }
    

    // Groundswell : Tanuj - Test Method for Referral Payout Amount - Fleet Oppty Wflows
    @isTest
    private static void testReferralPayoutAmountFleetWflowConversionFirstIteration(){
        OpportunityTriggerHandler.maxRuns = 1;

        Account partnerAccountForReferralOppty = new Account(Name = 'Testers Partner Inc',
                                                             BillingState='California',
                                                             BillingCountry = 'United States',
                                                             Organization_Size__c = '100 - 499',
                                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId(),
                                                             Type = 'Partner');
        insert partnerAccountForReferralOppty;
        
        // Referral Payout Amount - Fleet
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('ReferralOpptyOne');
        thisOpp.AccountId = partnerAccountForReferralOppty.Id;
        thisOpp.Referral_Partner__c = partnerAccountForReferralOppty.Id;
        thisOpp.Uncapped_Partner_Referral_Payout_Amount__c = false;
        thisOpp.License_Term__c =12;
        thisOpp.CurrencyIsoCode = 'USD';
        test.startTest();
        insert thisOpp;
        
        Opportunity opptyAfterInsert = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c FROM Opportunity WHERE Id=: thisOpp.Id];    
        
        // Referral Payout Amount - Fleet
        system.assertEquals(0, opptyAfterInsert.Partner_Referral_Payout_Amount_V2__c);
        
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opptyAfterInsert.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, License_Term_Copy__c = 36);
        insert oli;

     Opportunity opptyAfterUpdate = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c,List_Price__c,License_Term_Formula__c FROM Opportunity WHERE Id=: opptyAfterInsert.Id];    

        // Referral Payout Amount - Fleet 
        // After Update OLI
        system.assertEquals((-0.2*opptyAfterUpdate.ACV_List_Price__c), opptyAfterUpdate.Partner_Referral_Payout_Amount_V2__c);
           
        
        test.stopTest(); 
    }
    
  
    // Groundswell : Tanuj - Test Method for Referral Payout Amount - Fleet Oppty Wflows
    @isTest
    private static void testReferralPayoutAmountFleetWflowConversionSecondIteration(){
        OpportunityTriggerHandler.maxRuns = 1;

        Account partnerAccountForReferralOppty = new Account(Name = 'Testers Partner Inc',
                                                             BillingState='California',
                                                             BillingCountry = 'United States',
                                                             Organization_Size__c = '100 - 499',
                                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId(),
                                                             Type = 'Partner');
        insert partnerAccountForReferralOppty;
        
        
        // Referral Payout Amount - Fleet
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('ReferralOpptyOne');
        thisOpp.AccountId = partnerAccountForReferralOppty.Id;
        thisOpp.Referral_Partner__c = partnerAccountForReferralOppty.Id;
        thisOpp.Uncapped_Partner_Referral_Payout_Amount__c = false;
        thisOpp.License_Term__c =12;
        thisOpp.CurrencyIsoCode = 'USD';
        test.startTest();
        insert thisOpp;
        
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
        vg33.UnitPrice = 1500;
        update vg33;
        
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 2000, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, License_Term_Copy__c = 36);
        insert oli;
        
  
        // Referral Payout Amount - Fleet 
        // After Update OLI & Product to satisfy 2nd condition

        
        Opportunity opptyAfterSecondUpdate = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c,List_Price__c,License_Term_Formula__c FROM Opportunity WHERE Id=: thisOpp.Id];    
        
        system.assertEquals((-50000 *opptyAfterSecondUpdate.Currency_Exchange_Rate__c), opptyAfterSecondUpdate.Partner_Referral_Payout_Amount_V2__c);
        
        
        test.stopTest(); 
    }
    
    
   // Groundswell : Tanuj - Test Method for Referral Payout Amount Industrial ENT Oppty Wflows
    @isTest
    private static void testReferralPayoutAmountIndustrialENTWflowConversionFirstIteration(){
        OpportunityTriggerHandler.maxRuns = 1;
        

        
        Account partnerAccountForReferralOppty = new Account(Name = 'Testers Partner Inc',
                                                             BillingState='California',
                                                             BillingCountry = 'United States',
                                                             Organization_Size__c = '100 - 499',
                                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId(),
                                                             Type = 'Partner');
        insert partnerAccountForReferralOppty;
        
        
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        UserRole urSrDrPartner = new UserRole();
        
        User userRecordWithSrPartnrRole = new User();
        
        system.runAs(thisUser){

            urSrDrPartner = new UserRole(Name = 'Industrial');
            insert urSrDrPartner;
     
            userRecordWithSrPartnrRole = (User)
                TestFactory.createSObject(new User(ProfileId = pId,
                                                   EmployeeNumber = '123',
                                                   LastName = 'last',
                                                   Email = 'puser000@amamama.com',
                                                   Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
                                                   CompanyName = 'TEST',
                                                   Title = 'title',
                                                   Alias = 'alias',
                                                   TimeZoneSidKey = 'America/Los_Angeles',
                                                   EmailEncodingKey = 'UTF-8',
                                                   LanguageLocaleKey = 'en_US',
                                                   LocaleSidKey = 'en_US',
                                                   Order_Admin_Fallback_User__c = TRUE,
                                                   isActive = TRUE,
                                                   Business_Unit__c = 'Industrial',
                                                   Segment__c = 'Enterprise',
                                                   UserRoleId = urSrDrPartner.Id ));
            insert userRecordWithSrPartnrRole;
  
        }

        //Referral Payout Amount Industrial ENT
        Opportunity thisOppPayoutIndustrial = new Opportunity();
        thisOppPayoutIndustrial = TestFactory.initializeOpportunity ('ReferralOpptyOne');
        thisOppPayoutIndustrial.AccountId = partnerAccountForReferralOppty.Id;
        thisOppPayoutIndustrial.OwnerId = userRecordWithSrPartnrRole.id;
        thisOppPayoutIndustrial.Referral_Partner__c = partnerAccountForReferralOppty.Id;
        thisOppPayoutIndustrial.License_Term__c =12;
        thisOppPayoutIndustrial.CurrencyIsoCode = 'USD';
       
        test.startTest();
        
        insert thisOppPayoutIndustrial;
        
        Opportunity oppPayoutIndustrialAfterInsert = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c FROM Opportunity WHERE Id=: thisOppPayoutIndustrial.Id];    
        
        //Referral Payout Amount Industrial ENT
        system.assertEquals(0, oppPayoutIndustrialAfterInsert.Partner_Referral_Payout_Amount_V2__c);
        
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');

        OpportunityLineItem oliSecond = new OpportunityLineItem(OpportunityId = oppPayoutIndustrialAfterInsert.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, License_Term_Copy__c = 36);
        insert oliSecond;
        
        
        
     Opportunity oppPayoutIndustrialAfterUpdate = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c,List_Price__c,License_Term_Formula__c FROM Opportunity WHERE Id=: oppPayoutIndustrialAfterInsert.Id];    

        //Referral Payout Amount Industrial ENT
        // After Update OLI
        system.assertEquals(oppPayoutIndustrialAfterUpdate.List_Price__c * (-0.05*oppPayoutIndustrialAfterUpdate.Currency_Exchange_Rate__c ), oppPayoutIndustrialAfterUpdate.Partner_Referral_Payout_Amount_V2__c);

        
        test.stopTest();
    } 
    
    
    
    // Groundswell : Tanuj - Test Method for Referral Payout Amount Industrial ENT Oppty Wflows
    @isTest
    private static void testReferralPayoutAmountIndustrialENTWflowConversionSecondIteration(){
        OpportunityTriggerHandler.maxRuns = 1;
        

        
        Account partnerAccountForReferralOppty = new Account(Name = 'Testers Partner Inc',
                                                             BillingState='California',
                                                             BillingCountry = 'United States',
                                                             Organization_Size__c = '100 - 499',
                                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId(),
                                                             Type = 'Partner');
        insert partnerAccountForReferralOppty;
        
        
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        UserRole urSrDrPartner = new UserRole();
        
        User userRecordWithSrPartnrRole = new User();
        
        system.runAs(thisUser){

            urSrDrPartner = new UserRole(Name = 'Industrial');
            insert urSrDrPartner;
     
            userRecordWithSrPartnrRole = (User)
                TestFactory.createSObject(new User(ProfileId = pId,
                                                   EmployeeNumber = '123',
                                                   LastName = 'last',
                                                   Email = 'puser000@amamama.com',
                                                   Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
                                                   CompanyName = 'TEST',
                                                   Title = 'title',
                                                   Alias = 'alias',
                                                   TimeZoneSidKey = 'America/Los_Angeles',
                                                   EmailEncodingKey = 'UTF-8',
                                                   LanguageLocaleKey = 'en_US',
                                                   LocaleSidKey = 'en_US',
                                                   Order_Admin_Fallback_User__c = TRUE,
                                                   isActive = TRUE,
                                                   Business_Unit__c = 'Industrial',
                                                   Segment__c = 'Enterprise',
                                                   UserRoleId = urSrDrPartner.Id ));
            insert userRecordWithSrPartnrRole;
  
        }

        //Referral Payout Amount Industrial ENT
        Opportunity thisOppPayoutIndustrial = new Opportunity();
        thisOppPayoutIndustrial = TestFactory.initializeOpportunity ('ReferralOpptyOne');
        thisOppPayoutIndustrial.AccountId = partnerAccountForReferralOppty.Id;
        thisOppPayoutIndustrial.OwnerId = userRecordWithSrPartnrRole.id;
        thisOppPayoutIndustrial.Referral_Partner__c = partnerAccountForReferralOppty.Id;
        thisOppPayoutIndustrial.License_Term__c =12;
        thisOppPayoutIndustrial.CurrencyIsoCode = 'USD';
       
        test.startTest();
        
        insert thisOppPayoutIndustrial;
        
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');

        // Referral Payout Amount Industrial ENT
        // After Update OLI & Product to satisfy 2nd condition
        vg33.UnitPrice = 1500;
        update vg33;
        
        
        OpportunityLineItem oliSecond = new OpportunityLineItem(OpportunityId = thisOppPayoutIndustrial.Id, Quantity = 2000, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, License_Term_Copy__c = 36);
        insert oliSecond;
        
 
        Opportunity opptyPayoutIndustrialAfterSecondUpdate = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c,List_Price__c,License_Term_Formula__c FROM Opportunity WHERE Id=: thisOppPayoutIndustrial.Id];    
        system.assertEquals((-100000*opptyPayoutIndustrialAfterSecondUpdate.Currency_Exchange_Rate__c), opptyPayoutIndustrialAfterSecondUpdate.Partner_Referral_Payout_Amount_V2__c);

        test.stopTest();
    }
    
    // WFlow Rule - License Term Update for other rebate type
    @isTest
    private static void testLicenseTermUpdateForRebateTypeMethod(){
        OpportunityTriggerHandler.maxRuns = 1;
        
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];        
        revOpp.License_Term__c = 12;
        
        test.startTest();
        update revOpp;
        
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOppRet.Returning_Opportunity__c = revOpp.Id;
        thisOppRet.AccountId = acc.Id;
        thisOppRet.Amount = 0;
        thisOppRet.Type = 'Rebate' ;
        thisOppRet.Rebate_Type__c = 'License Term Credit';
        
        
        
        insert thisOppRet;
        
        
        
        Opportunity oppAfterRetOpptyInsert = [Select id, License_Term__c  FROM Opportunity WHERE Id=: thisOppRet.Id];
        system.assertEquals(revOpp.License_Term__c, oppAfterRetOpptyInsert.License_Term__c);       
        
        oppAfterRetOpptyInsert.Rebate_Type__c = 'Buyout';
        update oppAfterRetOpptyInsert;
        
        Opportunity oppAfterRetOpptyUpdate = [Select id, License_Term__c  FROM Opportunity WHERE Id=: oppAfterRetOpptyInsert.Id];
        system.assertEquals(revOpp.License_Term__c, oppAfterRetOpptyUpdate.License_Term__c); 
        
        test.stopTest(); 
    }
    
    // Groundswell : Tanuj - Test Method for Referral Payout Amount Uncapped - Fleet Oppty Wflows
    @isTest
    private static void testReferralPayoutAmountUncappedFleetMethod(){
        OpportunityTriggerHandler.maxRuns = 1;

        Account partnerAccountForReferralOppty = new Account(Name = 'Testers Partner Inc',
                                                             BillingState='California',
                                                             BillingCountry = 'United States',
                                                             Organization_Size__c = '100 - 499',
                                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId(),
                                                             Type = 'Partner');
        insert partnerAccountForReferralOppty;
        
        // Referral Payout Amount Uncapped
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('ReferralOpptyOne');
        thisOpp.AccountId = partnerAccountForReferralOppty.Id;
        thisOpp.Referral_Partner__c = partnerAccountForReferralOppty.Id;
        thisOpp.Uncapped_Partner_Referral_Payout_Amount__c = true;
        thisOpp.License_Term__c =12;
        thisOpp.CurrencyIsoCode = 'USD';
        test.startTest();
        insert thisOpp;
        
        Opportunity opptyAfterInsert = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c FROM Opportunity WHERE Id=: thisOpp.Id];    
        
        // Referral Payout Amount - Fleet
        system.assertEquals(0, opptyAfterInsert.Partner_Referral_Payout_Amount_V2__c);
        
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opptyAfterInsert.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, License_Term_Copy__c = 36);
        insert oli;

        Opportunity opptyAfterUpdate = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c,List_Price__c,License_Term_Formula__c FROM Opportunity WHERE Id=: opptyAfterInsert.Id];    

        // Referral Payout Amount - Fleet 
        // After Update OLI
        system.assertEquals((-0.2*opptyAfterUpdate.ACV_List_Price__c), opptyAfterUpdate.Partner_Referral_Payout_Amount_V2__c);
           
        
        test.stopTest(); 
    }
    
    // WFlow Rule - Copy Owner Manager Email When Closing
    @isTest		
    private static void testCopyOwnerManagerEmailWhenClosingMethod(){
        OpportunityTriggerHandler.maxRuns = 1;
        
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        acc.BillingStreet = 'test 123';
        acc.BillingCity = 'San jose';
        acc.BillingPostalCode = '94856';
        acc.BillingCountry = 'United States';
        acc.Billing_Email__c = 'test@testemail.com';
        
        insert acc;
        
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id, Email = 'test@test.com'));
        insert contactTwo;
        
        Opportunity revOpp = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 2 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactTwo.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        
        insert revOpp;        
        revOpp.StageName = 'Closing';
        revOpp.Owner_Manager_Email_Copy__c = null; 
        test.startTest();
        
        update revOpp;    
        
        Opportunity revOppUpdateFirst = [Select id, Owner.Manager.Email, Owner_Manager_Email_Copy__c FROM Opportunity WHERE Id=: revOpp.Id];
        system.assertEquals(revOppUpdateFirst.Owner.Manager.Email,revOppUpdateFirst.Owner_Manager_Email_Copy__c);
        
        
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOppRet.Returning_Opportunity__c = revOpp.Id;
        thisOppRet.AccountId = acc.Id;
    	thisOppRet.Amount = 0;
        insert thisOppRet;
        
        thisOppRet.StageName = 'Refunded - Closed';
        thisOppRet.Type = 'Rebate' ;
        thisOppRet.Owner_Manager_Email_Copy__c = null;
        update thisOppRet;
        
        Opportunity oppAfterRetOpptyRefunded = [Select id, Returning_Opportunity__r.Owner_Manager_Email_Copy__c, Owner.Manager.Email, Owner_Manager_Email_Copy__c  FROM Opportunity WHERE Id=: thisOppRet.Id];
        system.assertEquals(oppAfterRetOpptyRefunded.Returning_Opportunity__r.Owner_Manager_Email_Copy__c,oppAfterRetOpptyRefunded.Owner_Manager_Email_Copy__c);
        
        test.stopTest(); 
        
    }
   
    
    // WFlow Rule - Stamp Responsible Party Email
    @isTest
    private static void testStampResponsiblePartyEmail(){
        OpportunityTriggerHandler.maxRuns = 1;
        
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
		thisOppRet.AccountId = acc.id;      
    	thisOppRet.Amount = 0;
        insert thisOppRet;    
        
        thisOppRet.Rebate_Type__c = 'License Term Credit';
        thisOppRet.License_Term_Credit_Reason__c = 'Product';
        thisOppRet.License_Credit_Subreason__c = 'VG - Compliance fine from DOT due to product failure';
        
        test.startTest();
        
        update thisOppRet;
        
        Opportunity revOppUpdateFirst = [Select id, License_Credit_Responsible_Party__c FROM Opportunity WHERE Id=: thisOppRet.Id];
        system.assertEquals(System.Label.Email_vg_concession,revOppUpdateFirst.License_Credit_Responsible_Party__c);  
        
        revOppUpdateFirst.License_Term_Credit_Reason__c = 'Sales';
        revOppUpdateFirst.License_Credit_Subreason__c = 'Sales - Does not support primary use case';
        
        update revOppUpdateFirst;
        
        Opportunity revOppUpdateForSales = [Select id, Return_Oppty_Owner_Email__c,License_Credit_Responsible_Party__c FROM Opportunity WHERE Id=: thisOppRet.Id];
        system.assertEquals(revOppUpdateForSales.Return_Oppty_Owner_Email__c,revOppUpdateForSales.License_Credit_Responsible_Party__c); 
        
         test.stopTest(); 
            
    }

    @isTest
    private static void teststampRTNNumberMethod(){
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
		thisOppRet.AccountId = acc.id;  
        thisOppRet.Return_Number_Shipping__c = null;
        thisOppRet.Type = 'Rebate';
        thisOppRet.Amount = 0;
        
        
        test.startTest();
        
      	insert thisOppRet;
 
        Opportunity revOppUpdateForSales = [Select id, Return_Number_Shipping__c, Return_Number__c FROM Opportunity WHERE Id=: thisOppRet.Id];
        system.assertEquals(revOppUpdateForSales.Return_Number_Shipping__c,revOppUpdateForSales.Return_Number__c); 
            
 		test.stopTest();
        
    }
    
    
    // Groundswell : Tanuj - Common Wflow Test Method for Trial Record Type Oppty
    @isTest
    private static void testTrialOpptyWflowConversion(){
       
       Opportunity freeTrial = [ SELECT Id, Deactivate__c, Send_Invoice__c, Trial_Period__c, Trial_Start_Date_new__c, Trial_Number_of_Days_Left__c, CloseDate, Trial_Status__c, Trial_Completion_Date__c FROM Opportunity WHERE Name='Opp Testers 1 Inc'];

       // Deactivation Timestamp
       // Trial Invoice Timestamp
       freeTrial.Deactivate__c = true;
       freeTrial.Send_Invoice__c = true;
       freeTrial.Trial_Status__c = 'Purchased';
       
       update freeTrial;
       
       test.startTest();
       
       Opportunity opptyAfterUpdate = [Select id, Name, Amount, StageName, Deactivation_Date__c, Invoice_Date__c, Trial_Period__c, Trial_Start_Date_new__c, Trial_Number_of_Days_Left__c, CloseDate, Trial_Status__c, Trial_Completion_Date__c FROM Opportunity WHERE Id=: freeTrial.Id];    
       
       //Deactivation Timestamp
       //Trial Invoice Timestamp
       system.assertNotEquals(null, opptyAfterUpdate.Deactivation_Date__c);
       system.assertNotEquals(null, opptyAfterUpdate.Invoice_Date__c);
       // Stamp Trial Completion Date
       system.assertEquals(system.today(), opptyAfterUpdate.Trial_Completion_Date__c);
       
       // Free Trial Return Date Update
       opptyAfterUpdate.Deactivate__c = false;
       opptyAfterUpdate.Trial_Status__c = 'Return In Process';
       
       update opptyAfterUpdate;
       
       Opportunity opptyAfterTrialReturn = [Select id, Name, Amount, StageName, Deactivation_Date__c, Invoice_Date__c, Trial_Period__c, Trial_Start_Date_new__c, Trial_Number_of_Days_Left__c, CloseDate, Trial_Status__c, Trial_Completion_Date__c FROM Opportunity WHERE Id=: opptyAfterUpdate.Id];    

       // Free Trial Return Date Update
       system.assertEquals((opptyAfterTrialReturn.Trial_Start_Date_new__c.daysBetween(system.today())) + 30, opptyAfterTrialReturn.Trial_Period__c);
       
       
       test.stopTest(); 
   }
    
    @isTest
    private static void testOpenTrialStatusWflowConversion(){
        Opportunity freeTrial = [ SELECT Id, Deactivate__c, Send_Invoice__c, Trial_Period__c, Trial_Start_Date_new__c, Trial_Number_of_Days_Left__c, CloseDate, Trial_Status__c, Trial_Completion_Date__c FROM Opportunity WHERE Name='Opp Testers 1 Inc'];
        test.startTest();
        
        // Re Open Trial when End Date Exceeded
       freeTrial.CloseDate = System.today() - 60;
       
      system.debug('testOpenTrialStatusWflowConversion'); 
       update freeTrial;
       
       Opportunity opptyAfterEndDateExceeded = [Select id, Name, Amount, StageName, Deactivation_Date__c, Invoice_Date__c, Trial_Period__c, Trial_Start_Date_new__c, Trial_Number_of_Days_Left__c, CloseDate, Trial_Status__c, Trial_Completion_Date__c FROM Opportunity WHERE Id=: freeTrial.Id];    

       // Re Open Trial when End Date Exceeded
       system.assertEquals('Open', opptyAfterEndDateExceeded.Trial_Status__c);

        
        test.stopTest();
        
    }
}