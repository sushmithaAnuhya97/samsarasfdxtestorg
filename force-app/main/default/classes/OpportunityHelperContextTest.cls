/**********************************************************************
Name: OpportunityHelperContextTest

Purpose: This class will contain test methods related to OpportunityHelperContext                                                     

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Apr-11        INITIAL DEVELOPMENT 

***********************************************************************/

@isTest(SeeAllData=false)
public class OpportunityHelperContextTest {
    @testSetup
    private static void testDataSetup() {
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert new Global_Automation_Settings__c(Name = 'Automation_Settings',Allow_Handler_Selection__c = true);
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         BillingPostalCode  = '1030',
                                         BillingCountry = 'United Kingdom',
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Industry = 'Other');
        newAccounts.add(accountOne);
        Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                         BillingState='California',
                                         BillingCountry = 'United States',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         BillingPostalCode  = '1030',
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Approved_Payment_Type__c = 'Direct Monthly',
                                         Industry = 'Other');
        newAccounts.add(accountTwo);
        Account accountThree = new Account(Name = 'Testers 34 Inc',
                                           BillingState='California',
                                           BillingCountry = 'United States',
                                           BillingStreet = '26 Napier Street',
                                           BillingCity = 'London',
                                           BillingPostalCode  = '1030',
                                           Billing_Email__c  = 'qdasdas@gmail.com',
                                           Organization_Size__c = '100 - 499',
                                           Approved_Payment_Type__c = 'Direct Monthly',
                                           Industry = 'Other');
        newAccounts.add(accountThree);
        Account acc3 = new Account();
        acc3.Name = 'TestFirst Partner';
        //acc2.Business_Unit__c = 'Partner';
        acc3.BillingStreet = '123 Testing St';
        acc3.BillingCity = 'San Francisco';
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'CA';
        acc3.BillingPostalCode = '94109';
        acc3.DUNS_Number__c = '12345';
        acc3.Website = 'www.samsara.com';
        acc3.Organization_Size__c = '1 - 99';
        
        acc3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        acc3.Is_Finance_Partner_Active__c = true;
        //insert acc3;
        
        newAccounts.add(acc3);
        insert newAccounts;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Auto_Renewal__c = true,
            Status = 'Draft',
            Weighted_Average_Start_Date__c =  System.today()
        );
        insert cont;
        cont.Status = 'Activated';
        update cont;
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        newContacts.add(contactOne);
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'test@test.com'));
        newContacts.add(contactTwo);
        insert newContacts;
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, 
                                                         Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', 
                                                         Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
        shippingAddressList.add(sa);
        Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contactOne.Id, 
                                                          Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', 
                                                          Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = accountOne.Id);
        shippingAddressList.add(sa2);
        Shipping_Address__c sa3 = new Shipping_Address__c(Shipping_Zip_Code__c = 'C.P. 45610', Shipping_Contact__c=contactOne.Id, 
                                                          Shipping_Address_Line_1__c='Adolf B Horn 1737-1', Shipping_City__c='San Pedro Tlaquepaque, Jal', 
                                                          Shipping_Country__c='Mexico', Name='Test Mexico', Account__c = accountOne.Id);
        shippingAddressList.add(sa3);
        Shipping_Address__c sa4 = new Shipping_Address__c(Shipping_Zip_Code__c = 'J0E 9Z9', Shipping_Contact__c=contactOne.Id, 
                                                          Shipping_Address_Line_1__c='Adolf B Horn 1737-1', Shipping_City__c='San Pedro Tlaquepaque, Jal', 
                                                          Shipping_Country__c='Canada', Name='Test Canada', Account__c = accountOne.Id);
        shippingAddressList.add(sa4);
        insert shippingAddressList;
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Free Trial Opportunity Test',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__AmendedContract__c = cont.id,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne);
        Opportunity opportunityTwo = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Revenue Opportunity Test',
                                                      StageName = 'Purchase',
                                                      Shipping_Contact__c = contactTwo.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Finance_Partner__c = acc3.Id, 
                                                      Ship_From_Location__c = 'DCL-LA',
                                                      Shipping_Method__c = 'Ground',
                                                      Referral_Partner__c = acc3.Id, 
                                                      Insurance_Partner__c = acc3.Id, 
                                                      Probability = 90,
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Shipping_Address_NEW__c = sa.Id));
        newOpportunities.add(opportunityTwo);
        Opportunity opportunityThree = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Revenue Opportunity Test 2',
                                                      StageName = 'Incubate',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Finance_Partner__c = acc3.Id, 
                                                      Ship_From_Location__c = 'DCL-LA',
                                                      Shipping_Method__c = 'Ground',
                                                      Referral_Partner__c = acc3.Id, 
                                                      Insurance_Partner__c = acc3.Id, 
                                                      VAT_Number__c= 'VAT  NUMBER 12345',
                                                      Selected_Payment_Type__c = 'Direct Quarterly',
                                                      Shipping_Address_NEW__c = sa.Id));
        newOpportunities.add(opportunityThree);
        Opportunity opportunitySix = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Remorse Refund',
                                                      Name = 'Remorse Refund Opporunity Test',
                                                      StageName = 'Return Created',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 0,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Monthly',
                                                      Shipping_Address_NEW__c = sa.Id));
        newOpportunities.add(opportunitySix);
        Opportunity opportunityFour = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Promo Opportunity',
                                                      Name = 'Promo Opportunity Test',
                                                      StageName = 'Qualified',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Upfront Payments',
                                                      Shipping_Country__c='United Kingdom',
                                                      Shipping_Carrier__c = 'DHL',
                                                      Ship_From_Location__c = 'VCK',
                                                      Shipping_Method__c = 'UK Standard',
                                                      CurrencyIsoCode = 'GBP',
                                                      ContractId = cont.id,
                                                      Shipping_Address_NEW__c = sa2.Id,
                                                      Promo_Reason__c='Exchange'
                                                     ));
        newOpportunities.add(opportunityFour);
        Opportunity opportunityFive = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Exchange',
                                                      Name = 'Exchange Opporunity Test',
                                                      StageName = 'Return Created',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 0,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Monthly'));
        newOpportunities.add(opportunityFive);
        
        Opportunity opportunitySeven = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Warrant Exchange',
                                                      Name = 'Warrant Exchange Opporunity Test',
                                                      StageName = 'Return Created',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 0,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Monthly'));
        newOpportunities.add(opportunitySeven);
        Opportunity opportunityEight = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Promo Opportunity',
                                                      Name = 'Promo Opportunity Test 2',
                                                      StageName = 'Decision',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Shipping_Country__c='United Kingdom',
                                                      Shipping_Carrier__c = 'DHL',
                                                      Ship_From_Location__c = 'VCK',
                                                      Shipping_Method__c = 'UK Standard',
                                                      CurrencyIsoCode = 'GBP',
                                                      ContractId = cont.id,
                                                      Shipping_Address_NEW__c = sa4.Id,
                                                      Promo_Reason__c='Exchange'
                                                     ));
        newOpportunities.add(opportunityEight);
        Opportunity opportunityNine = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Revenue Opporunity Test 3',
                                                      StageName = 'Closed Won',
                                                      Probability=98,
                                                      Configuration_Segment__c = 'Express',
                                                      Payment_Token__c = 'xyq12345678990',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 0,
                                                      Shipping_Address_NEW__c = sa.Id,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityNine);
        Opportunity opportunityTen = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Revenue Opporunity Test 4',
                                                      StageName = 'Orders Processing',
                                                      //Probability=90,
                                                      Configuration_Segment__c = 'Express',
                                                      Payment_Token__c = 'xyq12345678990',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 0,
                                                      Shipping_Address_NEW__c = sa.Id,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Quarterly'));
        newOpportunities.add(opportunityTen);
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert newOpportunities;
        OpportunityTeamMember otm = new OpportunityTeamMember (OpportunityId = opportunityTwo.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Product Specialist');
            insert otm;
        cont.SBQQ__Opportunity__c = opportunityThree.id;
        update cont;
        
        SBQQ.TriggerControl.disable();
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opportunityTwo.Id;
        ftQuote.SBQQ__Account__c = accountTwo.Id;
        ftQuote.Finance_Partner_Account__c = acc3.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Quote';
        newQuotes.add(ftQuote);
        
        SBQQ__Quote__c ftQuote2 = new SBQQ__Quote__c();
        ftQuote2.Quote_Name__c = 'Test Quote 2';
        ftQuote2.SBQQ__Opportunity2__c = opportunityThree.Id;
        ftQuote2.SBQQ__Account__c = accountOne.Id;
        ftQuote2.Finance_Partner_Account__c = acc3.Id;
        ftQuote2.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote2.SBQQ__Type__c = 'Quote';
        newQuotes.add(ftQuote2);
        
        insert newQuotes; 
        
        List< Finance_Partner_Quote__c > financeQuoteList   =   new List< Finance_Partner_Quote__c >();

        Finance_Partner_Quote__c finQuoteRec    =   new Finance_Partner_Quote__c();
        finQuoteRec.Financing_Decision__c       =   'Pending';
        finQuoteRec.Preferred_Offer__c          =   true;
        finQuoteRec.Opportunity__c              =   opportunityThree.id;
        finQuoteRec.Account__c                  =   accountOne.id; 
        finQuoteRec.Finance_Partner__c          =   acc3.id;

        financeQuoteList.add( finQuoteRec );
        
        insert financeQuoteList;
        
        /*
        list<Finance_Partner_Quote__c>FinanceQuotelist=new list<Finance_Partner_Quote__c>();
        Finance_Partner_Quote__c FinanceQuote=new Finance_Partner_Quote__c();
        FinanceQuote.Financing_Decision__c='Pending';
        FinanceQuote.Preferred_Offer__c=false;
        FinanceQuote.Opportunity__c=opportunityTwo.id;
        FinanceQuote.Account__c=accountTwo.id;
        FinanceQuote.CPQ_Quote__c = ftQuote.id;
        FinanceQuote.Finance_Partner__c=acc3.id;
        FinanceQuotelist.add(FinanceQuote);
        
        Finance_Partner_Quote__c FinanceQuoteNew3=new Finance_Partner_Quote__c();
        FinanceQuoteNew3.Financing_Decision__c='Pending';
        FinanceQuoteNew3.Preferred_Offer__c=true;
        FinanceQuoteNew3.Opportunity__c=opportunityThree.id;
        FinanceQuoteNew3.Account__c=accountOne.id; 
        FinanceQuoteNew3.Finance_Partner__c=acc3.id;
        //FinanceQuoteNew3.Subsidy_Amount__c=1000;
        FinanceQuotelist.add(FinanceQuoteNew3);
        
        insert FinanceQuotelist;
        List<Channel_Relationship__c> channelRelationshipList = new List<Channel_Relationship__c>();
        Channel_Relationship__c channelRelationship = new Channel_Relationship__c(Channel_Partner__c = acc3.Id, Opportunity__c = opportunityTwo.Id);
        channelRelationshipList.add(channelRelationship);
        Channel_Relationship__c channelRelationship2 = new Channel_Relationship__c(Channel_Partner__c = acc3.Id, Opportunity__c = opportunityThree.Id);
        channelRelationshipList.add(channelRelationship2);
        insert channelRelationshipList;
        */
        SBQQ.TriggerControl.enable();
        /*Id docId = createDocusign(opportunityTwo.Id);
        createFiles(docId);
        Id docId2 = createDocusign(opportunityThree.Id);
        createFiles(docId2);*/
    }
    static private PricebookEntry getPricebookEntry(Id pricebookId, String productCode) {
        PricebookEntry entry = [Select Id, UnitPrice, Pricebook2Id, ProductCode from PricebookEntry where ProductCode = :productCode and Pricebook2Id = :pricebookId LIMIT 1];
        return entry;
    }
    static void createFiles(string recId){
        
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body to be insert in test class for testing the'); 
            
            ContentVersion contentVersion_1 = new ContentVersion(
                Title='SampleTitle', 
                PathOnClient ='SampleTitle.jpg',
                VersionData = bodyBlob, 
                origin = 'H'
            );
            insert contentVersion_1;
            
            ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId 
                            FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
            
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId = recId;
            contentlink.contentdocumentid = contentVersion_2.contentdocumentid;
            contentlink.ShareType = 'V';
            insert contentlink;
    }
    static Id createDocusign(string oppId){
        dsfs__DocuSign_Status__c dRec = new dsfs__DocuSign_Status__c();
        dRec.dsfs__Subject__c = 'Test REcord';
        dRec.dsfs__Envelope_Status__c = 'Completed';
        dRec.dsfs__Opportunity__c = oppId;
        
        insert dRec;
        
        //createFiles(dRec.Id);
        
        return dRec.Id;
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
    
    @isTest static void testRevenue() {
        test.startTest();
        Opportunity newOpportunity = [SELECT id,AccountId from Opportunity WHERE Name = 'Revenue Opportunity Test' LIMIT 1];
        Opportunity newOpportunity2 = [SELECT id,AccountId from Opportunity WHERE Name = 'Revenue Opportunity Test 2' LIMIT 1];
        SBQQ__Quote__c qte = [SELECT Id from SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote 2' LImit 1];
        Contract cont = [SELECT id from Contract limit 1];
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        List<Opportunity> updList = new List<Opportunity>();
        newOpportunity.StageName = 'Orders Processing';
        newOpportunity.Ship_From_Location__c = 'DCL-KY';
        newOpportunity.Sub_Type__c = 'Clickpath';
        newOpportunity.Selected_Payment_Type__c = 'Direct Quarterly';
        newOpportunity.Renewal__c = true;
        newOpportunity.Express_Agreement_Accepted_Date__c = System.today()+45;
        //newOpportunity.SBQQ__AmendedContract__c = cont.id;
        updList.add(newOpportunity) ;
        
        newOpportunity2.StageName = 'Closing';
        newOpportunity2.Ship_From_Location__c = 'DCL-KY';
        newOpportunity2.Selected_Payment_Type__c = 'Direct Quarterly';
        newOpportunity2.Payment_Token__c = 'zzzxxxx1233444';
        newOpportunity2.Configuration_Segment__c = 'Express';
        newOpportunity2.SBQQ__PrimaryQuote__c = qte.Id;
        newOpportunity2.VAT_Number__c= 'VAT NUMBER 12345';
        newOpportunity2.VAT_Validation_Status__c = 'Verified';
        updList.add(newOpportunity2) ;
        Triggerhandler.bypass('GS_AccountTriggerHandler');
        Triggerhandler.bypass('GS_SBQQQuoteTriggerHandler');
        Triggerhandler.bypass('OpportunityLineItemTriggerHandler');
        update updList;
        TriggerHandler.clearAllBypasses();
        test.stopTest();
    }
    
    @isTest
    private static void testRebateType(){
        //OpportunityTriggerHandler.maxRuns = 10;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        Triggerhandler.bypass('GS_AccountTriggerHandler');
        Triggerhandler.bypass('GS_SBQQQuoteTriggerHandler');
        Triggerhandler.bypass('OpportunityLineItemTriggerHandler');
        test.startTest();
        insert acc;
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Revenue Opportunity Test' LIMIT 1];
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        revOpp.License_Term__c = 12;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        Triggerhandler.bypass('OpportunityTriggerHandlerContext');
        update revOpp;
        Triggerhandler.clearbypass('OpportunityTriggerHandlerContext');
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOppRet.Returning_Opportunity__c = revOpp.Id;
        thisOppRet.AccountId = acc.Id;
        thisOppRet.Amount = 0;
        thisOppRet.Type = 'Rebate' ;
        thisOppRet.Rebate_Type__c = 'Partner Referral';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        insert thisOppRet;
        TriggerHandler.clearAllBypasses();
        
        
        test.stopTest();
    }
    
   @isTest static void managerFormula_Test(){
        Test.startTest();

        User ae1LevelUser = [Select id from user where Level__c = 'AE 1' and IsActive = true limit 1];
        User Nonae1LevelUser = [Select id from user where Level__c != 'AE 1' and IsActive = true limit 1];

        Opportunity newOpportunity  =   [   SELECT Id,AccountId, Type, Returning_Opportunity__c, ownerId, Returning_Opportunity__r.Owner.Level__c,
                                            Owner_Role_Copy__c, SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.ManagerId, 
                                            SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.UserRole.Name, Owner.Manager.UserRole.Name,
                                            Owner.Manager.ManagerId, Owner.Manager.Manager.Level__c, Owner.Manager.Email, Owner.Email,
                                            SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.Email,
                                            Owner.Manager.Sales_User_Type__c,Owner.Manager.Manager.Name,Owner.Manager.Manager.Manager.Name,
                                            Owner.Manager.Manager.Sales_User_Type__c,Owner.Manager.Manager.Manager.Sales_User_Type__c,
                                            Owner_Manager_Email_Copy__c, Owner_Manager_Name_Copy__c, Owner_Director_Name_Copy__c,
                                            Owner_Director_Email_Copy__c, Owner_AVP_Name_Copy__c, Owner_AVP_Role_Copy__c,
                                            Owner.ManagerId, Owner_Manager_Role_Copy__c
                                            FROM Opportunity 
                                            WHERE Name = 'Revenue Opportunity Test' LIMIT 1];
                                      
        Opportunity newOpportunity2 =   [   SELECT id,AccountId, Type, Returning_Opportunity__c, ownerId, Returning_Opportunity__r.Owner.Level__c,
                                            Owner_Role_Copy__c, SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.ManagerId, 
                                            SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.UserRole.Name, Owner.Manager.UserRole.Name,
                                            Owner.Manager.ManagerId, Owner.Manager.Manager.Level__c, Owner.Manager.Email, Owner.Email,
                                            SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.Email,
                                            Owner.Manager.Sales_User_Type__c,Owner.Manager.Manager.Name,Owner.Manager.Manager.Manager.Name,
                                            Owner.Manager.Manager.Sales_User_Type__c,Owner.Manager.Manager.Manager.Sales_User_Type__c,
                                            Owner_Manager_Email_Copy__c, Owner_Manager_Name_Copy__c, Owner_Director_Name_Copy__c,
                                            Owner_Director_Email_Copy__c, Owner_AVP_Name_Copy__c, Owner_AVP_Role_Copy__c,
                                            Owner_Manager_Role_Copy__c
                                            FROM Opportunity 
                                            WHERE Name = 'Remorse Refund Opporunity Test' LIMIT 1
                                        ];

GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
            List< Opportunity > oppToUpdateList         = new List< Opportunity >();

            newOpportunity.OwnerId                      = ae1LevelUser.Id;

            newOpportunity2.OwnerId                     = ae1LevelUser.Id;
            newOpportunity2.Returning_Opportunity__c    = newOpportunity.Id;

            oppToUpdateList.add( newOpportunity );
            oppToUpdateList.add( newOpportunity2 );
            Triggerhandler.bypass('GS_AccountTriggerHandler');
            Triggerhandler.bypass('GS_SBQQQuoteTriggerHandler');
            Triggerhandler.bypass('OpportunityLineItemTriggerHandler');
            update oppToUpdateList;
            TriggerHandler.clearAllBypasses();
            Assert.isTrue(  
                newOpportunity.Owner_Manager_Name_Copy__c == newOpportunity.Owner.ManagerId, 
                'managerFormula_Test assert failed. Owner_Manager_Name_Copy__c value is incorrect.' 
            );

        Test.stopTest();
    }
    
    @isTest static void testPromo() {
        Opportunity newOpportunity = [SELECT id,AccountId from Opportunity WHERE Name = 'Promo Opportunity Test' LIMIT 1];
        Opportunity newOpportunity2 = [SELECT id,AccountId from Opportunity WHERE Name = 'Promo Opportunity Test 2' LIMIT 1];
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        newOpportunity.StageName = 'Orders Processing';
        newOpportunity.Shipping_Country__c = 'Canada';
        newOpportunity.Shipping_State__c = 'Alberta';
        //newOpportunity.VAT_Number__c= 'VAT  NUMBER 12345';
        newOpportunity.VAT_Validation_Status__c = 'Verified';
        update newOpportunity;
        
        newOpportunity2.StageName = 'Closing';
        newOpportunity2.Shipping_Country__c = 'Canada';
        newOpportunity2.Shipping_State__c = 'Alberta';
        newOpportunity2.Configuration_Segment__c = 'Express';
        //newOpportunity2.Probability = 98;
        update newOpportunity2;
        //checkDCLQualified
        //checkForCrossSellOnOppItems
        //updateCrossSellIdentifier
        ////Clickpath
        test.stopTest();
    }
    
    @isTest static void testClosedWonLost() {
        Opportunity newOpportunity = [SELECT id,AccountId from Opportunity WHERE Name = 'Revenue Opportunity Test' LIMIT 1];
        Opportunity newOpportunity2 = [SELECT id,AccountId from Opportunity WHERE Name = 'Revenue Opportunity Test 2' LIMIT 1];
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        List<Opportunity> updList = new List<Opportunity>();
        newOpportunity.StageName = 'Closed Lost';
        newOpportunity.Ship_From_Location__c = 'DCL-KY';
        newOpportunity.Express_Annual_Discount__c = 25;
        newOpportunity.Express_Upfront_Discount__c = 25;
        newOpportunity.Small_Fleet_Opportunity__c = true;
        newOpportunity.Closed_Lost_Reason__c = 'Oppty Lost';
        updList.add(newOpportunity) ;
        
        newOpportunity2.StageName = 'Closed Won';
        newOpportunity2.Ship_From_Location__c = 'DCL-KY';
        //newOpportunity2.Adjust_License_Start_Date__c = true;
        newOpportunity2.VAT_Validation_Status__c = 'Verified';
        //newOpportunity2.VAT_Number__c = 'Verified VAT 12345';
        newOpportunity2.Payment_Token__c = 'zzzxxxx1233444';
        updList.add(newOpportunity2) ;
        
        update updList;
        test.stopTest();
    }
    
    @isTest static void testRemorseRefund() {
        Opportunity newOpportunity = [SELECT id,AccountId from Opportunity WHERE Name = 'Remorse Refund Opporunity Test' LIMIT 1];
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        newOpportunity.StageName = 'Refunded - Closed';
        update newOpportunity;
        test.stopTest();
    }
    
    
    
    /*@isTest static void testLicenseProducts() {
        Opportunity newOpportunity = [SELECT Id   from Opportunity WHERE TYPE = 'Revenue Opportunity' LIMIT 1];
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        test.startTest();
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        newOpportunity.StageName = 'Orders Processing';
        newOpportunity.Customer_require_PO_for_invoicing__c = 'No';
        update newOpportunity;
        test.stopTest();
    }*/
    
    @isTest static void testExchange() {
        Opportunity newOpportunity = [SELECT id,AccountId from Opportunity WHERE Type = 'Warrant Exchange' LIMIT 1];
        Account acct = [SELECT id from Account limit 1];
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        //Order ord = new Order(OpportunityId=newOpportunity.Id, AccountId=acct.id, Status__c='Draft', Status='Draft',EffectiveDate=Date.today());
        //insert ord;
        newOpportunity.StageName = 'Return Cancelled';
        update newOpportunity;
        test.stopTest();
    }
    
    @isTest static void testTrial() {
        Opportunity newOpportunity = [SELECT id,AccountId, type, Send_Invoice__c,Free_Trial_Extension_Status__c, Free_Trial_Approval__c from Opportunity WHERE Type = 'Free Trial Opportunity' LIMIT 1];
        //Opportunity newOpportunity2 = [SELECT id,AccountId, type, Send_Invoice__c,Free_Trial_Extension_Status__c, Free_Trial_Approval__c from Opportunity WHERE Type = 'Free Trial Opportunity' LIMIT 1];
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        //Contract objCon = new Contract();
        //objCon.SBQQ__Opportunity__c = newOpportunity.Id;
        //objCon.AccountId = newOpportunity.AccountId;
        //objCon.EndDate = system.today().addDays(10);
        //objCon.Auto_Renewal__c = true;
        //objCon.ContractTerm = 4;
        //insert objCon;
        test.startTest();
        Opportunity newOpportunity2 = [SELECT id,AccountId, type, Send_Invoice__c,Free_Trial_Extension_Status__c, Free_Trial_Approval__c from Opportunity WHERE Type = 'Free Trial Opportunity' LIMIT 1];
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        newOpportunity.Free_Trial_Approval__c = true;
        newOpportunity.Send_Invoice__c = true;
        newOpportunity.StageName = 'Trial';
        newOpportunity.Shipping_Instructions__c = 'shipped to mexico';
        newOpportunity.Shipping_Country__c = 'Mexico';
        newOpportunity.Payment_Terms__c = 'Net 60';
        newOpportunity.Initial_Payment_Terms__c = 'Due in advance';
        newOpportunity.Cable_Send_Only__c = true;
        newOpportunity.Trial_Period__c = 10;
        //newOpportunity.Free_Trial_Extension_Status__c ='Approved';
        update newOpportunity;
        Map<Id, Opportunity> oldOpptyMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newOpptyMap = new Map<Id, Opportunity>();
        List<Opportunity> newOpptyList = new List<Opportunity>();
        oldOpptyMap.put(newOpportunity2.id, newOpportunity2);
        newOpportunity.Send_Invoice__c=true;
        newOpportunity.Free_Trial_Extension_Status__c ='Approved';
        newOpptyMap.put(newOpportunity.id, newOpportunity);
        //OpportunityHelperContext opp = new OpportunityHelperContext();
        //opp.setFreeTrialInvoice(oldOpptyMap, newOpptyMap);
        //newOpptyList.add(newOpportunity);
        //opp.updateContractDate(newOpptyList, oldOpptyMap);
        //opp.submitForTrialExtensionApproval(newOpptyList, oldOpptyMap);
        test.stopTest();
    }
    /*
    @isTest static void callOtherMethods() {
        Opportunity newOpportunity = [SELECT id,Sales_Tax__c,Balance_Due__c,Internal_RFO_Notes__c, Shipping_and_Handling__c,Shipping_and_Handling_Manual__c,AccountId,
                                      Shipping_and_Handling_Amount__c, Trial_Agreement_Accepted__c,Shipping_Contact__c,Netsuite_Transfer_Order_ID__c,
                                      Netsuite_Transfer_Order__c,Owner_Segment__c, Total_Weight_oz__c,Multi_Line_Shipping__c,Shipping_Instructions__c,
                                      Order_Ops_Notes__c,Hold_Reason__c,Netsuite_Id__c,Unique_Shipping_Addresses__c,Shipping_Carrier__c,Segment_Sales_Role__c,
                                      Concatenated_Shipping_Address__c,Shipping_Method__c,Ship_From_Location__c,Price_Book_Name__c from Opportunity LIMIT 1];
        Contract objCon = new Contract();
        objCon.SBQQ__RenewalOpportunity__c = newOpportunity.Id;
        objCon.AccountId = newOpportunity.AccountId;
        objCon.EndDate = system.today().addDays(10);
        objCon.Auto_Renewal__c = true;
        objCon.ContractTerm = 4;
        insert objCon;
        Contract objCon1 = new Contract();
        objCon1.SBQQ__RenewalOpportunity__c = newOpportunity.Id;
        objCon1.AccountId = newOpportunity.AccountId;
        objCon1.EndDate = system.today().addDays(10);
        objCon1.Auto_Renewal__c = true;
        objCon1.ContractTerm = 3;
        insert objCon1;
        Contract objCon2 = new Contract();
        objCon2.SBQQ__RenewalOpportunity__c = newOpportunity.Id;
        objCon2.AccountId = newOpportunity.AccountId;
        objCon2.EndDate = system.today().addDays(10);
        objCon2.Auto_Renewal__c = true;
        objCon2.ContractTerm = 2;
        insert objCon2;
        test.startTest();
        Set<Id> setOppId = new Set<Id>();
        setOppId.add(newOpportunity.Id);
        
        //OpportunityHelper.updateContractRecords(setOppId);
        OpptyHelperAfterUpdateExt opp = new OpptyHelperAfterUpdateExt();
        opp.satisfyPromoOpp(newOpportunity, 20);
        opp.satisfyFreeTrailOpp(newOpportunity, 20);
        opp.satisfyRevenueOpp(newOpportunity, 20);
        opp.getQtyLimitPerProduct('Free Trial Opportunity');
        opp.getQtyLimitPerProduct('Revenue Opportunity');
        opp.satisfyMatchingconditions(newOpportunity);
        opp.validatePoBox('this is my address');
        
        test.stopTest();
    }
    
    @isTest static void callOtherMethods2() {
        Opportunity newOpportunity = [SELECT id,Sales_Tax__c,Balance_Due__c,Internal_RFO_Notes__c, Shipping_and_Handling__c,Shipping_and_Handling_Manual__c,AccountId,
                                      Shipping_and_Handling_Amount__c, Trial_Agreement_Accepted__c,Shipping_Contact__c,Netsuite_Transfer_Order_ID__c,
                                      Netsuite_Transfer_Order__c,Owner_Segment__c, Total_Weight_oz__c,Multi_Line_Shipping__c,Shipping_Instructions__c,
                                      Order_Ops_Notes__c,Hold_Reason__c,Netsuite_Id__c,Unique_Shipping_Addresses__c,Shipping_Carrier__c,Segment_Sales_Role__c,
                                      Concatenated_Shipping_Address__c,Shipping_Method__c,Ship_From_Location__c,Price_Book_Name__c, Total_License_Due__c,
                                      Express_Annual_Discount__c, License_Term__c, Express_Selected_Discount__c, Selected_Payment_Type__c
                                      from Opportunity WHERE Type = 'Revenue Opportunity' LIMIT 1];
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        
        //OpportunityHelper.updateContractRecords(setOppId);
        
        test.startTest();
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;
        List<OpportunityLineItem> lstOppLI = [Select Id,OpportunityId, Product2.Product_Status__c, Product2.CPQ_Enabled_Product__c, ProductCode, Express_Selected_Discount__c
                                              ,Express_Upfront_Discount__c, Discount, Express_Annual_Discount__c, Selected_Sales_Price__c, UnitPrice    from
                                              OpportunityLineItem limit 2];
        newOpportunity = [SELECT id,Sales_Tax__c,Balance_Due__c,Internal_RFO_Notes__c, Shipping_and_Handling__c,Shipping_and_Handling_Manual__c,AccountId,
                                      Shipping_and_Handling_Amount__c, Trial_Agreement_Accepted__c,Shipping_Contact__c,Netsuite_Transfer_Order_ID__c,
                                      Netsuite_Transfer_Order__c,Owner_Segment__c, Total_Weight_oz__c,Multi_Line_Shipping__c,Shipping_Instructions__c,
                                      Order_Ops_Notes__c,Hold_Reason__c,Netsuite_Id__c,Unique_Shipping_Addresses__c,Shipping_Carrier__c,Segment_Sales_Role__c,
                                      Concatenated_Shipping_Address__c,Shipping_Method__c,Ship_From_Location__c,Price_Book_Name__c, Total_License_Due__c,
                                      Express_Annual_Discount__c, License_Term__c, Express_Selected_Discount__c, Selected_Payment_Type__c, Express_Upfront_Discount__c
                                      from Opportunity WHERE Id=:newOpportunity.Id];
        
        OpptyHelperAfterUpdateExt opp = new OpptyHelperAfterUpdateExt();
        newOpportunity.Selected_Payment_Type__c = 'Direct Annual';
        opp.expressSetDiscountLineItem(newOpportunity, lstOppLI, 3);
        newOpportunity.Selected_Payment_Type__c = 'Upfront Payments';
        opp.expressSetDiscountLineItem(newOpportunity, lstOppLI, 1);
        newOpportunity.Selected_Payment_Type__c = 'Direct Monthly';
        opp.expressSetDiscountLineItem(newOpportunity, lstOppLI, 5);
        newOpportunity.License_Term__c=null;
        newOpportunity.Express_Selected_Discount__c=null;
        newOpportunity.Selected_Payment_Type__c = 'Direct Annual';
        opp.expressSetDiscountLineItem(newOpportunity, lstOppLI, 3);
        newOpportunity.Selected_Payment_Type__c = 'Upfront Payments';
        opp.expressSetDiscountLineItem(newOpportunity, lstOppLI, 1);
        newOpportunity.Selected_Payment_Type__c = 'Direct Monthly';
        opp.expressSetDiscountLineItem(newOpportunity, lstOppLI, 5);
        test.stopTest();
    }
*/
    
    
    /*@isTest static void testWebstore() {
        Opportunity newOpportunity = [SELECT id,AccountId from Opportunity WHERE TYPE = 'Revenue Opportunity' LIMIT 1];
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        test.startTest();
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;
        newOpportunity = [SELECT id,AccountId,Total_License_Due__c from Opportunity WHERE Id=:newOpportunity.id];
        Account acc = new Account();
        acc.Id = newOpportunity.AccountId;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        newOpportunity.StageName = 'Orders Processing';
        newOpportunity.Customer_require_PO_for_invoicing__c = 'No';
        newOpportunity.Amount_Received__c = 100000;
        newopportunity.PO_Number__c = 'A-0000';
        newOpportunity.Push_to_Mulesoft__c = TRUE;
        newOpportunity.Selected_Payment_Type__c = 'Direct Annual';
        newOpportunity.Configuration_Segment__c='Express';
        newOpportunity.Shipping_Carrier__c = 'UPS';
        newOpportunity.Shipping_Method__c = 'Ground';
        newOpportunity.SBQQ__PrimaryQuote__c = null;
        update newOpportunity;
        TriggerHandler.clearbypass('GS_AccountTriggerHandler');
        test.stopTest();
    }*/
    
    @isTest static void testReadyToShip() {
        Opportunity newOpportunity = [SELECT id,AccountId from Opportunity WHERE TYPE = 'Revenue Opportunity' LIMIT 1];
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        
        test.startTest();
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;
        Id docId = createDocusign(newOpportunity.Id);
        createFiles(docId);
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        //Account acc = new Account();
        //acc.Id = newOpportunity.AccountId;
        newOpportunity.Name = 
        newOpportunity.StageName = 'Ready To Ship';
        newOpportunity.Amount_Received__c = 100000;
        newopportunity.PO_Number__c = 'A-0000';
        newOpportunity.Push_to_Mulesoft__c = TRUE;
        newOpportunity.Payment_Token__c = 'zzzxxxx1233444';
        newOpportunity.Payment_Terms__c = 'Net 60';
        newOpportunity.Initial_Payment_Terms__c = 'Due in advance';
        update newOpportunity;
        TriggerHandler.clearbypass('GS_AccountTriggerHandler');
        test.stopTest();
    } //removing commented line        
    
    /**@isTest static void testLicenseProducts2() {
        Opportunity newOpportunity = [SELECT Id   from Opportunity WHERE TYPE = 'Revenue Opportunity' LIMIT 1];
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        test.startTest();
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        newOpportunity.StageName = 'Orders Processing';
        newOpportunity.Customer_require_PO_for_invoicing__c = 'No';
newOpportunity.Bypass_Validation_Rule_DateTime__c  = system.now();
        try{
        update newOpportunity;
        test.stopTest();
            }catch(exception e){
                 
             }
    }**/
    
    @isTest 
    static void valueforSelectedPaymentTypeTest() {
        Account acc = [SELECT Id, ownerId FROM Account LIMIT 1];
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE Type = 'Revenue Opportunity'];
        List<Contract> contractList = new List<Contract>();
        Contract contract1 = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            Weighted_Average_Start_Date__c = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12
        );
        Contract contract2 = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            Weighted_Average_Start_Date__c = Date.today(),
            EndDate = Date.today().adddays(135),
            ContractTerm = 12
        );
        contractList.add(contract1);
        contractList.add(contract2);
        Test.startTest();
        Triggerhandler.bypass('GS_AccountTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        insert contractList;
        oppList[0].SBQQ__AmendedContract__c = contract1.Id;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        update oppList;
        TriggerHandler.clearAllBypasses();
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity opp1 = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp 1 Inc',
                                                      StageName = 'Proposal',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__Renewal__c = true,
                                                      SBQQ__RenewedContract__c = contract1.Id,
                                                      SBQQ__AmendedContract__c = contract1.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opp1);
        Opportunity opp2 = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp 2 Inc',
                                                      StageName = 'Proposal',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__AmendedContract__c = contract1.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opp2);
        
        insert newOpportunities;
        delete newOpportunities;
        undelete newOpportunities;
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }
    @isTest
    private static void testUpdateToClosedWon(){
        Account acct = [SELECT Id from Account where name = 'Testers 1 Inc'];
        Opportunity revOpp = [SELECT Id, Name, CloseDate, StageName, License_End_Date__c FROM Opportunity WHERE Name = 'Revenue Opportunity Test 2' LIMIT 1];
        revOpp.StageName = 'Closed Won';
        revOpp.Payment_Token__c = 'zzzxxxx1233444';
        revOpp.Configuration_Segment__c = 'Express';
        //acct.First_Purchase_Date__c = System.Today()+60;
        Test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        //update acct;
        update revOpp;
            Test.stopTest();
    }
    @isTest
    private static void testUpdateToClosedLost(){
        Opportunity revOpp = [SELECT Id, Name, CloseDate, StageName, License_End_Date__c FROM Opportunity WHERE Name = 'Revenue Opportunity Test 2' LIMIT 1];
        revOpp.StageName = 'Closed Lost';
        revOpp.Closed_Lost_Reason__c = 'Oppty Lost';
        Test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        
        update revOpp;
            Test.stopTest();
    }
    
    @isTest
    private static void testRebateTypeDelinquent(){
        OpportunityTriggerHandler.maxRuns = 10;
        Account accRF = [SELECT id from Account where name='TestFirst Partner'];
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');     
        test.startTest();
        insert acc;
        Triggerhandler.bypass('GS_AccountTriggerHandler');
        Triggerhandler.bypass('OpportunityLineItemTriggerHandler');
        User u = [SELECT Id,UserRoleId  FROM User WHERE UserRoleId  != null and IsActive = true and Level__c != 'AE 1' LIMIT 1];
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true; 
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Revenue Opportunity Test' LIMIT 1];
        revOpp.License_Term__c = 12;
        revOpp.StageName = 'Qualified';
        revOpp.CloseDate = System.Today()-370;
        OpportunityTeamMember otm = new OpportunityTeamMember (OpportunityId = revOpp.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Product Specialist');
            insert otm;
        //OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        revOpp.ownerId = u.Id;
        Triggerhandler.bypass('OpportunityTriggerHandlerContext');
        update revOpp;
        TriggerHandler.clearBypass('OpportunityTriggerHandlerContext');
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOppRet.Returning_Opportunity__c = revOpp.Id;
        thisOppRet.AccountId = acc.Id;
        thisOppRet.Referral_Partner__c = accRF.Id;
        thisOppRet.Amount = 0;
        thisOppRet.Type = 'Rebate' ;
        thisOppRet.Rebate_Type__c = 'Delinquent';
        thisOppRet.StageName = 'Refunded - Closed';
        thisOppRet.Shipping_Country__c = 'United States';
        //OpportunityTriggerHandler.resetAll();
        //OpportunityWorkflowConversion.firstRun = true;
        insert thisOppRet;
        thisOppRet.Shipping_Country__c = 'Mexico';
        thisOppRet.Shipmate_Preference__c = 'ShippingPreference-000012';
        //update thisOppRet;
        TriggerHandler.clearAllBypasses();
        
        //thisOppRet.Shipping_Country__c = 'Canada';
        //thisOppRet.Shipmate_Preference__c = 'ShippingPreference-000027';
        //update thisOppRet;
        
        
        test.stopTest();
    }

    

    @isTest
    private static void testRebateType1(){
        //OpportunityTriggerHandler.maxRuns = 10;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        Triggerhandler.bypass('GS_AccountTriggerHandler');
        Triggerhandler.bypass('GS_SBQQQuoteTriggerHandler');
        Triggerhandler.bypass('OpportunityLineItemTriggerHandler');
        test.startTest();
        insert acc;
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Revenue Opportunity Test' LIMIT 1];
        OpportunityTriggerHandler.resetAll();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        OpportunityWorkflowConversion.firstRun = true;
        revOpp.License_Term__c = 12;
        //OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        revOpp.StageName = 'Purchase';
        revOpp.VAT_Number__c= 'VAT NUMBER 12345';
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        update revOpp;
        TriggerHandler.clearbypass('OpportunityTriggerHandlerContext');
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOppRet.Returning_Opportunity__c = revOpp.Id;
        thisOppRet.AccountId = acc.Id;
        thisOppRet.Amount = 0;
        thisOppRet.Type = 'Rebate' ;
        thisOppRet.Rebate_Type__c = 'Subsidy';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        insert thisOppRet;
        Triggerhandler.clearAllBypasses();
        
        test.stopTest();
    }
    
    @isTest
    private static void testRebateType2(){
        //OpportunityTriggerHandler.maxRuns = 10;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        Triggerhandler.bypass('GS_AccountTriggerHandler');
        Triggerhandler.bypass('GS_SBQQQuoteTriggerHandler');
        Triggerhandler.bypass('OpportunityLineItemTriggerHandler');
        test.startTest();
        insert acc;
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Revenue Opportunity Test' LIMIT 1];
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        revOpp.License_Term__c = 12;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        //OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        revOpp.StageName = 'Decision';
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        update revOpp;
        TriggerHandler.clearbypass('OpportunityTriggerHandlerContext');
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOppRet.Returning_Opportunity__c = revOpp.Id;
        thisOppRet.AccountId = acc.Id;
        thisOppRet.Amount = 0;
        thisOppRet.Type = 'Rebate' ;
        thisOppRet.Rebate_Type__c = 'Buyout';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        insert thisOppRet;
        Triggerhandler.clearAllBypasses();
        
        test.stopTest();
    }
    
    @isTest
    private static void testClickpath_existingQuoteLines(){
        SBQQ.TriggerControl.disable();
        OpportunityTriggerHandler.maxRuns = 1;
        Account acc = [SELECT Id, Name FROM Account WHERE Name LIKE 'Testers 6%' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId =:acc.Id LIMIT 1];
        Opportunity thisOpp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Revenue Opportunity Test 2%' LIMIT 1];
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=con.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = acc.Id);
        insert sa;
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
        //Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
        //products.add(vgLicense);
        insert products;
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        //PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        //pricebookEntries.add(vgLicensePB);
        insert pricebookEntries;
        /*Contract cont = new Contract(
            AccountId = acc.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Status = 'Draft',
            SBQQ__Opportunity__c = thisOpp.Id,
            Weighted_Average_Start_Date__c = System.today().addDays(-1)
        );
        insert cont;
        cont.Status = 'Activated';
        update cont;*/
        Test.startTest();
        SBQQ.TriggerControl.enable();
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', Selected_Payment_Type__c = 'Direct Annual', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c =thisOpp.Id,
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = true, Custom_License_Term__c = 2);
        insert quote;
        TriggerHandler.clearbypass('GS_SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id,SBQQ__PricebookEntryId__c = vg33PB.Id,SBQQ__Quantity__c  = 1,
                                                                  SBQQ__Discount__c = 0,SBQQ__Product__c = vg33.Id,SBQQ__CustomerPrice__c = 10000,
                                                                  Ship_To__c = sa.Id);
        newlineItems.add(quoteLineOne);
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = vg33PB.Id, SBQQ__Quantity__c  = 5,
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vg33.Id, SBQQ__CustomerPrice__c = 10000,
                                                                  Ship_To__c = sa.Id);
        newlineItems.add(quoteLineTwo);
        insert newlineItems;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        OpportunityTriggerHandler.resetAll();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        thisOpp.AccountId = acc.Id;
        thisOpp.Type = 'Revenue Opportunity';
        thisOpp.Sub_Type__c = 'Clickpath';
        thisOpp.Renewal__c = true;
        //thisOpp.SBQQ__RenewedContract__c = cont.id;
        thisOpp.StageName = 'Decision';
        thisOpp.Shipping_Contact__c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1].Id;
        update thisOpp;
        thisOpp = [SELECT Id, Gainsight_Audit_Status__c, Gainsight_Audit_Override__c FROM Opportunity WHERE Id = :thisOpp.Id];
        //System.assert(thisOpp.Gainsight_Audit_Status__c.contains('Pending'));
        Test.stopTest();
    }
    
    @isTest 
    static void testRenewalOpportunityCheckoutLink() {
        Test.StartTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;

        Account acc = [SELECT Id, ownerId FROM Account where name = 'Testers 6 Inc'  LIMIT 1];
        Contract con = [Select id from Contract Limit 1];
        Opportunity opp = [SELECT Id,sbqq__PrimaryQuote__c, ownerId FROM opportunity where Accountid =: acc.id];        
        SBQQ__Quote__c qt = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id, SBQQ__Primary__c = true, SBQQ__Status__c = 'Approved');
    
        insert qt;      
        opp.Amount = 100;
        opp.Opportunity_UUID__c = '1234567890';
        
        opp.closeDate = System.today() + 90;
        opp.SBQQ__RenewedContract__c = con.Id;
        opp.Shipping_and_Handling_Manual__c = 10;
        opp.Unique_Shipping_Addresses__c  = 2;
        
        update opp; 
        Test.StopTest();
        
    }
    @isTest 
    static void updateOpptyFromContractUsingWASDTest() {
        OpportunityTriggerHandler.maxRuns = 1;
        Test.StartTest();
        Account acc = [SELECT Id, ownerId FROM Account where name = 'Testers 6 Inc'  LIMIT 1];
        acc.Customer_require_PO_for_invoicing__c = 'No';
        update acc;
        Contract con = [Select id from Contract Limit 1];
        Opportunity opp = [SELECT Id,sbqq__PrimaryQuote__c, ownerId FROM opportunity where Accountid =: acc.id];        
     
        opp.Express_Agreement_Accepted_Date__c = Date.today() + 10;
        opp.SBQQ__RenewedContract__c = con.Id;
        opp.Sub_Type__c = 'ClickPath';
        opp.Renewal__c = true;
        update opp; 
        Test.StopTest();
        
    }
   
    @isTest 
    private static void AccountReparenting()
    {
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        List<Account> accList = new List<account>();
        accList.add(TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT'));
        accList.add(TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT'));
        insert accList;
        system.debug('SOQL limit'+Limits.getQueries());
         Test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Qualified';
        thisOpp.AccountId = accList[0].Id;
        insert thisOpp;
        system.debug('SOQL limit 1'+Limits.getQueries());
        thisOpp.AccountId = accList[1].id;
        update thisOpp;
        Test.stopTest();
    }
}