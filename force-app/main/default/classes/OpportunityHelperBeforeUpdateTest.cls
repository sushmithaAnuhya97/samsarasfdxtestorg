/**********************************************************************
Name: OpportunityHelperBeforeUpdateTest

Purpose: This class will contain test methods related to OpportunityHelperBeforeUpdate                                                     

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Apr-30        INITIAL DEVELOPMENT 

***********************************************************************/

@isTest(SeeAllData=false)
public class OpportunityHelperBeforeUpdateTest {


    private static final String SUB_TYPE_UPGRADE            =   'Upgrade Opportunity';
    private static final String OPP_STAGE_RET_LABEL_SENT    =   'Return Label Sent';
    private static final String OPP_STAGE_RET_FIN_PROCESS   =   'Finance Processing';
    private static final String OPP_TYPE_REMORSE_REFUND     =   'Remorse Refund';
    private static final String OPP_RETURN_REC_TYPE_ID      =   Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(
                                                                    'Return_Opportunity').getRecordTypeId();

@testSetup
    private static void testDataSetup() {
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert new Global_Automation_Settings__c(Name = 'Automation_Settings',Allow_Handler_Selection__c = true);
        User userAE3 = [SELECT Id from USER where IsActive=true AND UserRole.name like '%AE3%' LIMIT 1];
        User objProfileAE3 = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara Sales - NA US AE3' order by Id limit 1];
        User objProfileADR = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara ADRs' order by Id limit 1];
        
        Book_Of_Business__c book2 = new Book_Of_Business__c(Name='Book Two', AE__c=objProfileAE3.Id, ADR__c=objProfileADR.Id, Active__c=true);
         FlexConstants__c flexConstants = new FlexConstants__c(
            Name = 'FlexConstants',
            Flex_Access_QuoteLine__c = 'FlexAccessQuoteLine',
            Carryover_Products__c = 'Carryover Products',
            Upgraded_Products__c = 'Upgraded Products',
            Error_Message__c = 'You do not have permission to make modifications, additions, or deletions in the Carryover or Upgraded Products groups.'
        );
        insert flexConstants;
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        //TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        SBQQ.TriggerControl.disable();
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
                                         Payment_Terms__c = 'Net 60',
                                         Approved_Payment_Type__c = 'Direct Monthly',
                                         Organization_Size__c = '100 - 499',
                                         OwnerId = userAE3.id,
                                         Book_of_Business__c = book2.id,
                                         Account_C_R_In_Progress__c = true,
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
                                         OwnerId = userAE3.id,
                                         Book_of_Business__c = book2.id,
                                         Payment_Terms__c = 'Net 60',
                                         Account_C_R_In_Progress__c = true,
                                         Approved_Payment_Type__c = 'Direct Monthly',
                                         Industry = 'Other');
        newAccounts.add(accountTwo);
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
        acc3.Account_C_R_In_Progress__c = true;
        acc3.Organization_Size__c = '1 - 99';
        
        acc3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        acc3.Is_Finance_Partner_Active__c = true;
        newAccounts.add(acc3);
        insert newAccounts;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(15),
            Name = 'TEST Contract',
            ContractTerm = 1,
            Auto_Renewal__c = true,
            Status = 'Draft'
        );
        insert cont;
        cont.Status = 'Activated';
        update cont;
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        newContacts.add(contactOne);
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'test@test.com'));
        newContacts.add(contactTwo);
        insert newContacts;
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
        shippingAddressList.add(sa);
        Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = accountOne.Id);
        shippingAddressList.add(sa2);
        Shipping_Address__c sa3 = new Shipping_Address__c(Shipping_Zip_Code__c = 'C.P. 45610', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Adolf B Horn 1737-1', Shipping_City__c='San Pedro Tlaquepaque, Jal', Shipping_Country__c='Mexico', Name='Test Mexico', Account__c = accountOne.Id);
        shippingAddressList.add(sa3);
        insert shippingAddressList;
        Id trialRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId();
        Opportunity opportunityFT = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id,
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'FreeTrialOpp',
                                                      StageName = 'Decision',
                                                      RecordTypeId = trialRecordTypeId,
                                                      OwnerId = userAE3.id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Finance_Partner__c = acc3.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Shipping_Address_NEW__c = sa.Id,
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Opportunity_Tracking__c = 'Order Processing set By OrderValidationAutomation',
                                                      amount = 1000,
                                                      Owner_Role_Copy__c = 'COR Fleet IS AE3 EMEA UK - Director'));
        newOpportunities.add(opportunityFT);
        
        Opportunity opportunityTwo = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Before Update Revenue Oppty',
                                                      StageName = 'Decision',
                                                      OwnerId = userAE3.id,
                                                      Shipping_Contact__c = contactTwo.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Finance_Partner__c = acc3.Id, 
                                                      Express_Agreement_Accepted_Date__c = Date.today(),
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityTwo);
        
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Before Update FT Test',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = trialRecordTypeId,
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne);
        
        Opportunity opportunityThree = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Before Update Rev Oppty Test',
                                                      StageName = 'Decision',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Finance_Partner__c = acc3.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityThree);
        Opportunity opportunityFour = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Promo Opportunity',
                                                      Name = 'Before Update Promo Test Opportunity',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Shipping_Country__c='United Kingdom',
                                                      Shipping_Carrier__c = 'DHL',
                                                      Ship_From_Location__c = 'DCL',
                                                      Shipping_Method__c = 'UK Standard',
                                                      CurrencyIsoCode = 'GBP',
                                                      Promo_Reason__c='Exchange'
                                                     ));
        newOpportunities.add(opportunityFour);
        Opportunity opportunityFive = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Work Order',
                                                      Name = 'Before Update Work Order Test Opportunity',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Finance_Partner__c = acc3.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual'
                                                     ));
        newOpportunities.add(opportunityFive);
        Opportunity opportunitySix = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Rebate',
                                                      Name = 'Before Update Rebate Test Opportunity',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Rebate_Type__c = 'Subsidy',
                                                      OwnerId = userAE3.id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Finance_Partner__c = acc3.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual'
                                                     ));
        newOpportunities.add(opportunitySix);
        Opportunity opportunitySeven = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Remorse Refund',
                                                      Name = 'Before Update Remorse Refund Test Opportunity',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
													StageName = 'Return Created',
                                                      Amount = -1000,
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Shipping_Carrier__c = 'DHL',
                                                      Ship_From_Location__c = 'DCL',
                                                      Shipping_Method__c = 'UK Standard',
                                                      CurrencyIsoCode = 'GBP'
                                                     ));
        newOpportunities.add(opportunitySeven);
        Opportunity opportunityEight = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Exchange',
                                                      Name = 'Before Update Exchange Test Opportunity',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Rebate_Type__c = 'Subsidy',
                                                      Price_Book_Name__c = 'Standard',
                                                      Finance_Partner__c = acc3.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual'
                                                     ));
        newOpportunities.add(opportunityEight);

        Opportunity opportunityPromo = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Exchange',
                                                      Name = 'Promo Creation Test Opportunity',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Rebate_Type__c = 'Subsidy',
                                                      Price_Book_Name__c = 'Standard',
                                                      Finance_Partner__c = acc3.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual'
                                                     ));
        newOpportunities.add(opportunityPromo);

        Opportunity swapOppRec  =   (Opportunity)   TestFactory.createSObject(
                                                        new Opportunity(    
                                                            AccountId = accountOne.Id,
                                                            Type = 'Remorse Refund',
                                                            Name = 'Swap Opportunity - GTMS-27442',
                                                            RecordTypeId = OPP_RETURN_REC_TYPE_ID,
                                                            StageName = 'Return Created',
                                                            Amount = -1000,
                                                            Shipping_Contact__c = contactOne.Id,
                                                            Price_Book_Name__c = 'Standard',
                                                            Selected_Payment_Type__c = 'Direct Annual',
                                                            Shipping_Country__c='United Kingdom',
                                                            Shipping_Carrier__c = 'DHL',
                                                            Ship_From_Location__c = 'DCL',
                                                            Shipping_Method__c = 'UK Standard',
                                                            CurrencyIsoCode = 'GBP',
                                                            Swap__c = true,
                                                            Sub_Type__c = 'Upgrade'
                                                        )
                                                    );
        newOpportunities.add( swapOppRec );

        Opportunity promoOpp = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Promo Opportunity',
                                                      Name = 'Promo Opportunity Test',
                                                      amount = 0,
                                                      StageName = 'Proposal',
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Shipping_Country__c='United Kingdom',
                                                      Shipping_Carrier__c = 'DHL',
                                                      Ship_From_Location__c = 'DCL',
                                                      Shipping_Method__c = 'UK Standard',
                                                      Promo_Reason__c='Exchange'
                                                     ));
        newOpportunities.add(promoOpp);
        
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert newOpportunities;
        
        Related_Opportunity__c relatedOppRec    =   (Related_Opportunity__c)   
                                                    TestFactory.createSObject(
                                                        new Related_Opportunity__c( 
                                                            Revenue_Opportunity__c      = opportunityThree.Id,
                                                            Associated_Opportunity__c   = swapOppRec.Id,
                                                            Sub_Type__c = SUB_TYPE_UPGRADE 
                                                        ) 
                                                    );
        insert relatedOppRec;
        
        //opportunityFive.Returning_Opportunity__c = opportunityTwo.id;
        //update opportunityFive;
        
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote Opportunity Two';
        ftQuote.SBQQ__Opportunity2__c = opportunityTwo.Id;
        ftQuote.SBQQ__Account__c = accountTwo.Id;
        ftQuote.Finance_Partner_Account__c = acc3.Id;
        ftQuote.License_Term__c = '12';
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Quote';
        newQuotes.add(ftQuote);
        
        insert newQuotes; 
        
        list<Finance_Partner_Quote__c>FinanceQuotelist=new list<Finance_Partner_Quote__c>();
        Finance_Partner_Quote__c FinanceQuote=new Finance_Partner_Quote__c();
        FinanceQuote.Financing_Decision__c='Pending';
        FinanceQuote.Preferred_Offer__c=false;
        FinanceQuote.Opportunity__c=opportunityTwo.id;
        FinanceQuote.Account__c=accountTwo.id;
        //FinanceQuote.CPQ_Quote__c = ftQuote.id;
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
        
        OpportunityTriggerHandler.isEnabled();
        //opportunityFive.Returning_Opportunity__c = opportunityTwo.id;
        //update opportunityFive;
        TriggerHandler.clearBypass('GS_OpportunityTriggerHandler');
        TriggerHandler.clearBypass('OpportunityTriggerHandlerContext');
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.clearBypass('GS_SBQQQuoteTriggerHandler');
        //TriggerHandler.clearBypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.clearBypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearBypass('GS_AccountTriggerHandler');
        TriggerHandler.clearBypass('ContractTriggerHandler');
        TriggerHandler.clearBypass('GS_ContactTriggerHandler');
        TriggerHandler.clearBypass('ContactTriggerHandler');
        SBQQ.TriggerControl.enable();
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
        dRec.License_Term__c = 12;
        insert dRec;
        
        //createFiles(dRec.Id);
        
        return dRec.Id;
    }
    
    @isTest static void testUKOpportunity() {
        Opportunity newOpportunity = [SELECT Id, AccountId, Referral_Partner__c, Name, Owner_Role_Copy__c, Owner_Business_Unit__c, Finance_Partner__c,
                                      Reseller__c, Insurance_Partner__c, Shipping_Method__c, VAT_Number__c, Shipping_Instructions__c,
                                      Order_Ops_Notes__c, Internal_RFO_Notes__c, Hold_Reason__c, Netsuite_Id__c, Sales_Tax__c,
                                      Balance_Due__c, Shipping_and_Handling__c, of_HW_Products__c, Segment_Sales_Role__c, Free_Trial_Purchase__c,
                                      Total_Weight_oz__c, of_Accessories__c, Amount,CurrencyIsoCode
                                      from Opportunity where Name ='Before Update Promo Test Opportunity' LIMIT 1];
        //Opportunity newOpportunity1 = [SELECT Id, Name, Owner_Role_Copy__c, Owner_Business_Unit__c from Opportunity WHERE Name ='Opp Testers 2 Inc' LIMIT 1];
        //SBQQ__Quote__c primaryQuote = [SELECT Id from SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote Opportunity Two'];
        //Contact cc = [Select Id from Contact where Email = 'test@test.com' limit 1];
        //Account acc = [Select id, Name, SLED_Account__c, Owner_Role__c from Account Limit 1];
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        //primaryQuote.SBQQ__Primary__c = true;
        //update primaryQuote;
        //newOpportunity.Trial_Goal_1__c = 'fooo';
        //newOpportunity.closeDate = system.today().adddays(50);
        //newOpportunity.Trial_Primary_Contact__c = cc.Id;
        //newOpportunity.Trial_Goal_2__c  = 'foooo1';
        //newOpportunity.Trial_Period__c = 10;
        //newOpportunity.Planned_Trial_Installation_Date__c = system.today();
        newOpportunity.StageName = 'Orders Processing';
        newOpportunity.Type = 'Revenue Opportunity';
        newOpportunity.Shipping_Country__c = 'France';
        newOpportunity.Order_Admin__c = null;
        newOpportunity.Probability = 98;
        newOpportunity.Shipping_Carrier__c = 'DHL';
        newOpportunity.Ship_From_Location__c = 'DCL';
        newOpportunity.Price_Book_Name__c = 'Samsara FY22';
        newOpportunity.Shipping_Method__c = 'UK Standard';
        newOpportunity.Type = 'Promo Opportunity';
        newOpportunity.Owner_Role_Copy__c = 'AE3';
        newOpportunity.Free_Trial_Purchase__c = 'No Purchase';
        List<Opportunity> newOpp1List = new List<Opportunity>();
        Map<Id, Opportunity> oldOpp1Map = new Map<Id, Opportunity> ();
        newOpp1List.add(newOpportunity);
        oldOpp1Map.put(newOpportunity.Id, newOpportunity);
        OpportunityHelperBeforeUpdate ext = new OpportunityHelperBeforeUpdate();
        ext.emeaOpsAutomationPromoOppty(newOpp1List, oldOpp1Map);
        ext.emeaOpsAutomationRevnueOppty(newOpp1List, oldOpp1Map);
        //newOpportunity.SBQQ__PrimaryQuote__c = primaryQuote.Id;
        //newOpportunity.TrialResolutionOppty__c  = newOpportunity1.Id;
        update newOpportunity;
        Set<Id> setopp = new Set<Id>();
        //setopp.add(newOpportunity.Id);
        //OpptyHelperBeforeUpdateExt.setOwnerSubRegion(newOpportunity, acc);
        //system.debug('newOpportunity---'+newOpportunity);
        test.stopTest();
    }
    @isTest private static void testOrderProcessing() {
        User runAsAEUser = [select id, name from user 
                            where IsActive=true AND Profile.id in ('00e4p000001ZhlOAAS','00e4p000001ZhlYAAS','00e4p000001ZhldAAC',
                                                 '00e4p000001ZhliAAC','00e4p000001ZhlnAAC','00e4p000001ZhmMAAS') limit 1];
        Opportunity revNewOpp = [SELECT Id, Name, CloseDate, License_End_Date__c, Gainsight_Audit_Override__c, Opportunity_Tracking__c,
                              Sub_Type__c,Gainsight_Audit_Status__c, OwnerId, Type, StageName, Rebate_Type__c, Returning_Opportunity_Closed_Won__c,
                                 Push_Return_to_Netsuite__c, Corresponding_Netsuite_ID__c, Sync_in_Progress__c,Probability, Finance_Partner__c, SBQQ__PrimaryQuote__c,
                                 License_Term__c
                              FROM Opportunity WHERE Name = 'Before Update Revenue Oppty' LIMIT 1];
        Opportunity revOldOpp = [SELECT Id, Name, CloseDate, License_End_Date__c, Gainsight_Audit_Override__c, Opportunity_Tracking__c,
                              Sub_Type__c,Gainsight_Audit_Status__c, OwnerId, Type, StageName, Rebate_Type__c, Returning_Opportunity_Closed_Won__c,
                                 Push_Return_to_Netsuite__c, Corresponding_Netsuite_ID__c, Sync_in_Progress__c,Probability, Finance_Partner__c, SBQQ__PrimaryQuote__c,
                                 License_Term__c
                              FROM Opportunity WHERE Name = 'Before Update Revenue Oppty' LIMIT 1];
        SBQQ__Quote__c qte = [SELECT id from SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote Opportunity Two' ];
        Account acc = [SELECT id FROM Account WHERE Name = 'TestFirst Partner'];
        Account acc2 = [SELECT id FROM Account WHERE Name = 'Testers 1 Inc'];
        
        Map<Id, Opportunity> oldOpp1Map = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newOpp1Map = new Map<Id, Opportunity>();
        List<Opportunity> newOpp1List = new List<Opportunity>();
        List<Product2> prodList = new List<Product2>();
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        //insert prod;
        prodList.add(prod);
        Product2 prod2 = new Product2(Name = 'WiFi2 Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA2',Product_Type__c = 'License');
        
        //insert prod;
        prodList.add(prod2);
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test',Product_Type__c = 'Hardware');
        prodList.add(vg33);
        insert prodList;
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        Id pricebookId = Test.getStandardPricebookId();
        list<PricebookEntry> listpb = new List<PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        listpb.add(standardPrice);
        PricebookEntry standardPrice2 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = vg33.Id,
            UnitPrice = 10000, IsActive = true);
        listpb.add(standardPrice2);
        insert listpb;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=10, OpportunityId=revNewOpp.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000, 
                                                          Product2Id = prod.id, Product_Code_Copy__c = prod.ProductCode);
        //insert li;
        OpportunityLineItem li2 = new OpportunityLineItem (Quantity=10, OpportunityId=revNewOpp.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000, 
                                                           Product2Id = prod.id, Renewed_Line__c=true, Product_Code_Copy__c = prod.ProductCode);
        //insert li2;
        OpportunityLineItem li3 = new OpportunityLineItem (Quantity=10, OpportunityId=revNewOpp.Id, PriceBookEntryId=standardPrice2.Id, UnitPrice = 10000, 
                                                           Product2Id = vg33.id, Renewed_Line__c=true, Product_Code_Copy__c = vg33.ProductCode);
        //insert li2;
        oppLineItems.add(li);
        oppLineItems.add(li2);
        oppLineItems.add(li3);
        insert oppLineItems;
        
        //System.runAs(runAsAEUser) {
        //    test.startTest();
        Id docId = createDocusign(revNewOpp.Id);
        createFiles(docId);
        revNewOpp.StageName = 'Orders Processing';
        //revNewOpp.SBQQ__PrimaryQuote__c =qte.id;
        revNewOpp.Finance_Partner__c = acc.id;
        revNewOpp.AccountId = acc2.id;
        revNewOpp.Shipping_Country__c = 'Canada';
        //revNewOpp.CurrencyIsoCode='MXN';
        update revNewOpp;
        //revNewOpp.StageName = 'Order Processing';
        newOpp1Map.put(revNewOpp.Id, revNewOpp);
        oldOpp1Map.put(revOldOpp.Id, revOldOpp);
        newOpp1List.add(revNewOpp);
        OpportunityHelperBeforeUpdate opptyExt = new OpportunityHelperBeforeUpdate();
        opptyExt.validateLicenseTermOnOfandCPQ(newOpp1List, oldOpp1Map);
        TriggerHandler.clearbypass('GS_AccountTriggerHandler');
        test.stopTest();
        //}
    }
    
    @isTest static void testEMEAOpportunity() {
        Opportunity newOpportunity = [SELECT Id, Name, Owner_Role_Copy__c, Owner_Business_Unit__c from Opportunity where Name ='Before Update Promo Test Opportunity' LIMIT 1];
        //Opportunity newOpportunity1 = [SELECT Id, Name, Owner_Role_Copy__c, Owner_Business_Unit__c from Opportunity WHERE Name ='Opp Testers 2 Inc' LIMIT 1];
        //SBQQ__Quote__c primaryQuote = [SELECT Id from SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote Opportunity Two'];
        //Contact cc = [Select Id from Contact where Email = 'test@test.com' limit 1];
        Account acc = [Select id, Name, SLED_Account__c, Owner_Role__c from Account Limit 1];
        Contract cont = [SELECT Id from Contract WHERE Name = 'TEST Contract'];
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        //primaryQuote.SBQQ__Primary__c = true;
        //update primaryQuote;
        //newOpportunity.Trial_Goal_1__c = 'fooo';
        //newOpportunity.closeDate = system.today().adddays(50);
        //newOpportunity.Trial_Primary_Contact__c = cc.Id;
        //newOpportunity.Trial_Goal_2__c  = 'foooo1';
        //newOpportunity.Trial_Period__c = 10;
        //newOpportunity.Planned_Trial_Installation_Date__c = system.today();
        newOpportunity.StageName = 'Refunded - Closed';
        newOpportunity.Shipping_Country__c = 'United Kingdom';
        newOpportunity.Order_Admin__c = null;
        newOpportunity.Is_Webstore_Upsell_Opportunity__c = true;
        newOpportunity.SBQQ__RenewedContract__c = cont.id;
        newOpportunity.Opportunity_Tracking__c = 'Order Processing set By OrderValidationAutomation';
        //newOpportunity.SBQQ__PrimaryQuote__c = primaryQuote.Id;
        //newOpportunity.TrialResolutionOppty__c  = newOpportunity1.Id;
        newOpportunity.Non_Standard_terms_description__c = 'EMEA Test';
        newOpportunity.Shipping_Carrier__c = 'DHL';
        newOpportunity.SBQQ__AmendedContract__c = cont.id;
        update newOpportunity;
        Set<Id> setopp = new Set<Id>();
        //setopp.add(newOpportunity.Id);
        OpportunityHelperBeforeUpdate.setOwnerSubRegion(newOpportunity, acc);
        //system.debug('newOpportunity---'+newOpportunity);
        test.stopTest();
    }
    
    @isTest private static void directMethodCallTest() {
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c, Gainsight_Audit_Override__c, Opportunity_Tracking__c,
                              Sub_Type__c,Gainsight_Audit_Status__c, OwnerId, Type, StageName, Rebate_Type__c, Returning_Opportunity_Closed_Won__c,
                                 Push_Return_to_Netsuite__c, Corresponding_Netsuite_ID__c, Sync_in_Progress__c,Probability, SBQQ__PrimaryQuote__c,
                              Shipping_Country__c, of_LIC_Products__c, of_HW_Products__c, of_Accessories__c, Finance_Kickback_Reason__c,
                              Bypass_Validation_rule__c, Free_Trial_Purchase__c, Total_Weight_oz__c, Shipping_Carrier__c, Shipping_Method__c,
                               Segment_Sales_Role__c
                              FROM Opportunity WHERE Name = 'Before Update Revenue Oppty' LIMIT 1];
        Opportunity rebateNewOpp = [SELECT Id, Name, CloseDate, License_End_Date__c, Gainsight_Audit_Override__c, Opportunity_Tracking__c,
                              Sub_Type__c,Gainsight_Audit_Status__c, OwnerId, Type, StageName, Rebate_Type__c, Returning_Opportunity_Closed_Won__c,
                                 Push_Return_to_Netsuite__c, Corresponding_Netsuite_ID__c, Sync_in_Progress__c,Probability, SBQQ__PrimaryQuote__c
                              FROM Opportunity WHERE Name = 'Before Update Rebate Test Opportunity' LIMIT 1];
        Opportunity rebateOldOpp = [SELECT Id, Name, CloseDate, License_End_Date__c, Gainsight_Audit_Override__c, Opportunity_Tracking__c,
                              Sub_Type__c,Gainsight_Audit_Status__c, OwnerId, Type, StageName, Rebate_Type__c, Returning_Opportunity_Closed_Won__c,
                                 Push_Return_to_Netsuite__c, Corresponding_Netsuite_ID__c, Sync_in_Progress__c,Probability, SBQQ__PrimaryQuote__c
                              FROM Opportunity WHERE Name = 'Before Update Rebate Test Opportunity' LIMIT 1];
        
        Contract con = [SELECT Id, EndDate from Contract limit 1];
        List<Product2> prodList = new List<Product2>();
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        //insert prod;
        prodList.add(prod);
        Product2 prod2 = new Product2(Name = 'WiFi2 Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA2',Product_Type__c = 'License');
        
        //insert prod;
        prodList.add(prod2);
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test',Product_Type__c = 'Hardware');
        prodList.add(vg33);
        insert prodList;
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=revOpp.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000, Product2Id = prod.id );
        //insert li;
        OpportunityLineItem li2 = new OpportunityLineItem (Quantity=1, OpportunityId=revOpp.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000, Product2Id = prod.id, Renewed_Line__c=true);
        //insert li2;
        OpportunityLineItem li3 = new OpportunityLineItem (Quantity=1, OpportunityId=revOpp.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000, Product2Id = vg33.id, Renewed_Line__c=true);
        //insert li2;
        oppLineItems.add(li);
        oppLineItems.add(li2);
        oppLineItems.add(li3);
        revOpp.Gainsight_Audit_Override__c = true;
        revOpp.Opportunity_Tracking__c = 'Warning: Stage';
        revOpp.Sub_Type__c = 'Auto-Renewal';
        OpportunityHelperBeforeUpdate opptyExt = new OpportunityHelperBeforeUpdate();
        opptyExt.processFutureDatedAutoRenewal(revOpp, null, con);
        opptyExt.removeWarningFromOptyTrackerField(revOpp);
        
        OpportunityHelperBeforeUpdate.checkLicenceProducts(oppLineItems);
        Map<Id, Id> opportunityIds = new Map<Id, Id>();
        opportunityIds.put(revOpp.Id, revOpp.Id);
        insert oppLineItems;
        OpportunityHelperBeforeUpdate.UpdateRenewedLinesforRebate(opportunityIds);
        
        Map<Id, Opportunity> oldOpp1Map = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newOpp1Map = new Map<Id, Opportunity>();
        List<Opportunity> newOpp1List = new List<Opportunity>();
        oldOpp1Map.put(rebateOldOpp.id, rebateOldOpp);
        newOpp1Map.put(rebateNewOpp.id, rebateNewOpp);
        rebateNewOpp.StageName = 'Finance Processing';
        rebateNewOpp.Push_Return_to_Netsuite__c = true;
        rebateNewOpp.Sync_in_Progress__c = false;
        newOpp1List.add(rebateNewOpp);
        opptyExt.syncOpportunity(newOpp1List, oldOpp1Map);
        revOpp.StageName = 'Order Processing';
        revOpp.Order_Admin__c = null;
        revOpp.Opportunity_UUID__c = null;
        revOpp.Is_Webstore_Upsell_Opportunity__c = true;
        revOpp.Shipping_Country__c = 'Canada';
        update revOpp;
        newOpp1Map.put(revOpp.id, revOpp);
        newOpp1List = new List<Opportunity>(); 
        newOpp1List.add(revOpp);
        //opptyExt.masterSheetReqBefore(newOpp1List, oldOpp1Map);
        opptyExt.orderAdminRoundRobin(oldOpp1Map, newOpp1Map);
        OpportunityHelperBeforeUpdate.opportunityEvents.add(new Opportunity_Event__e(Id__c = revOpp.Id));
        OpportunityHelperBeforeUpdate.orderSyncEvents.add(new Order_Event__e(Id__c = revOpp.Id, Type__c = revOpp.Type));
        OpportunityHelperBeforeUpdate.rebateSyncEvents.add(new Rebate_Event__e(Id__c = revOpp.Id, Type__c = revOpp.Type, Sub_Type__c = revOpp.Rebate_Type__c));
        //opptyExt.createPlatformEvent(newOpp1List, oldOpp1Map);
        opptyExt.createPlatformEvent();
        //opptyExt.beforeUpdateOnly(oldOpp1Map, newOpp1List);
        test.stopTest();
    }
    
    @isTest static void testReadyToShip() {
        Opportunity newOpportunity = [SELECT id,AccountId from Opportunity WHERE name = 'Before Update Work Order Test Opportunity' LIMIT 1];
        Opportunity newOpportunity2 = [SELECT id,AccountId from Opportunity WHERE name = 'Before Update Revenue Oppty' LIMIT 1];
        Opportunity newOpportunity3 = [SELECT id,AccountId from Opportunity WHERE name = 'Before Update Promo Test Opportunity' LIMIT 1];
        Contract con = [SELECT Id, EndDate from Contract limit 1];
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity2.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;
        List<Opportunity> toUpdateOppty = new List<Opportunity>();
        Account acc = new Account();
        acc.Id = newOpportunity.AccountId;
        newOpportunity.StageName = 'Ready To Ship';
        newOpportunity.Amount_Received__c = 100000;
        newopportunity.PO_Number__c = 'A-00002';
        newOpportunity.Push_to_Mulesoft__c = TRUE;
        newOpportunity.Opportunity_UUID__c = null;
        newOpportunity.Is_Webstore_Upsell_Opportunity__c = true;
        newOpportunity.Customer_require_PO_for_invoicing__c = 'No';
        newOpportunity.Bypass_Validation_Rule_DateTime__c  = system.now();
        toUpdateOppty.add(newOpportunity);
        
        /*newOpportunity2.StageName = 'Ready To Ship';
        newOpportunity2.Amount_Received__c = 100000;
        newopportunity2.PO_Number__c = 'A-00001';
        newOpportunity2.Push_to_Mulesoft__c = TRUE;
        newOpportunity2.Express_Agreement_Accepted_Date__c = date.today()+7;
        newOpportunity2.SBQQ__RenewedContract__c = con.id;
        newOpportunity2.Non_Standard_terms_description__c = 'test2';
        newOpportunity2.Opportunity_Tracking__c='Order Processing set By OrderValidationAutomation';
        toUpdateOppty.add(newOpportunity2);
        
        newOpportunity3.StageName = 'Ready To Ship';
        newOpportunity3.Amount_Received__c = 100000;
        newopportunity3.PO_Number__c = 'A-00001';
        newOpportunity3.Push_to_Mulesoft__c = TRUE;
        newOpportunity3.Is_Webstore_Upsell_Opportunity__c = true;
        newOpportunity3.Opportunity_Tracking__c='Order Processing set By OrderValidationAutomation';
        toUpdateOppty.add(newOpportunity3);*/
        
        update toUpdateOppty;
        TriggerHandler.clearBypass('GS_AccountTriggerHandler');
        test.stopTest();
    }
    @isTest
    private static void testRebateType(){
        OpportunityTriggerHandler.maxRuns = 10;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Before Update Revenue Oppty' LIMIT 1];
        Opportunity rebOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Before Update Rebate Test Opportunity' LIMIT 1];
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        revOpp.License_Term__c = 12;
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        revOpp.StageName = 'Closed Won';
        revOpp.Non_Standard_terms_description__c = 'test';
        update revOpp;
        //Opportunity thisOppRet = new Opportunity();
        //thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        rebOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        rebOpp.Returning_Opportunity__c = revOpp.Id;
        rebOpp.AccountId = acc.Id;
        rebOpp.Amount = 0;
        rebOpp.Type = 'Rebate' ;
        rebOpp.Rebate_Type__c = 'Partner Referral';
        rebOpp.StageName = 'Finance Processing';
        rebOpp.Push_Return_to_Netsuite__c = true;
        rebOpp.Corresponding_Netsuite_ID__c = null;
        rebOpp.Sync_in_Progress__c = false;
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        update rebOpp;
        
        test.stopTest();
    }
    @isTest
    private static void testUpdateToClosedLost(){
        Opportunity revOpp = [SELECT Id, Name, CloseDate, StageName, License_End_Date__c FROM Opportunity WHERE Name = 'Before Update Rev Oppty Test' LIMIT 1];
        revOpp.StageName = 'Closed Lost';
        revOpp.Closed_Lost_Reason__c = 'Test';
        Test.startTest(); 
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        
        update revOpp;
        Test.stopTest();
    }
    
    @isTest private static void testcreateRemorseRefund() {
        OpportunityTriggerHandler.maxRuns = 3; // Inorder to complete the third cycle 3 time update in test class
        Opportunity oppty = [SELECT Id from Opportunity where name = 'Before Update Remorse Refund Test Opportunity'];
        String countQuery = 'SELECT count() FROM Opportunity';
        Contract con = [SELECT Id, EndDate from Contract limit 1];
        Integer currentCount = Database.countQuery(countQuery);
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        Opportunity revOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Before Update Revenue Oppty' LIMIT 1];
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
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert thisOpp;
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        thisOpp.StageName = 'Return Initiated';
        //thisOpp.of_LIC_Products__c = -1;
        update thisOpp;
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        thisOpp.StageName = 'Return Cancelled';
        //thisOpp.of_LIC_Products__c = -1;
        update thisOpp;
        //OpportunityTriggerHandler.resetAll();
        //OpportunityWorkflowConversion.firstRun = true;
        //oppty.StageName = 'Return Cancelled';
        //oppty.SBQQ__AmendedContract__c = con.id;
        //thisOpp.of_LIC_Products__c = -1;
        //update oppty;
        Test.stopTest();
        //system.assertEquals(Database.countQuery(countQuery), currentCount + 1);
    }
    
    @isTest
    private static void testRebateTypeDelinquent(){
        OpportunityTriggerHandler.maxRuns = 10;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Before Update Revenue Oppty' LIMIT 1];
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        revOpp.License_Term__c = 12;
        revOpp.StageName = 'Qualified';
        revOpp.Non_Standard_terms_description__c = 'test';
        test.startTest();
        OpportunityTeamMember otm = new OpportunityTeamMember (OpportunityId = revOpp.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Product Specialist');
        insert otm;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        update revOpp;
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOppRet.Returning_Opportunity__c = revOpp.Id;
        thisOppRet.AccountId = acc.Id;
        thisOppRet.Amount = 0;
        thisOppRet.Type = 'Rebate' ;
        thisOppRet.Rebate_Type__c = 'Delinquent';
        thisOppRet.StageName = 'Return Created';
        //OpportunityTriggerHandler.resetAll();
        //OpportunityWorkflowConversion.firstRun = true;
        insert thisOppRet;
        thisOppRet.StageName = 'Refunded - Closed';
        update thisOppRet;
        test.stopTest();
    }
    
    @isTest
    private static void testClickpath_existingQuoteLines(){
        SBQQ.TriggerControl.disable();
        OpportunityTriggerHandler.maxRuns = 1;
        Account acc = [SELECT Id, Name FROM Account WHERE Name LIKE 'Testers 6%' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId =:acc.Id LIMIT 1];
        Opportunity thisOpp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Before Update Rev Oppty%' LIMIT 1];
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
        Contract cont = new Contract(
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
        update cont;
        Test.startTest();
        SBQQ.TriggerControl.enable();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c =thisOpp.Id,
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = true, Custom_License_Term__c = 2);
        insert quote;
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
        thisOpp.AccountId = acc.Id;
        thisOpp.Type = 'Revenue Opportunity';
        thisOpp.Sub_Type__c = 'Clickpath';
        thisOpp.Renewal__c = true;
        //thisOpp.SBQQ__RenewedContract__c = cont.id;
        thisOpp.StageName = 'Decision';
        thisOpp.Shipping_Contact__c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1].Id;
        update thisOpp;
        thisOpp = [SELECT Id, Gainsight_Audit_Status__c, Gainsight_Audit_Override__c FROM Opportunity WHERE Id = :thisOpp.Id];
        System.assert(thisOpp.Gainsight_Audit_Status__c.contains('Pending'));
        Test.stopTest();
    }

    @isTest 
    private static void testFreeTrialOpptyUScadEmeaUnderQtyLogic() {
    
        Opportunity oppRec = [Select Id, stageName From Opportunity where type = 'Free Trial Opportunity' and name = 'FreeTrialOpp' limit 1];
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', 
                                     Family = 'Hardware', 
                                     ProductCode = 'ACC-2A12-W1',
                                     Product_Type__c = 'License');
        insert prod;
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, 
                                                          Product2Id = prod.Id,
                                                          UnitPrice = 10000, 
                                                          IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem oli = new OpportunityLineItem (Quantity=1, 
                                                          OpportunityId=oppRec.Id, 
                                                          PriceBookEntryId=standardPrice.Id, 
                                                          UnitPrice = 10000);
        insert oli;
        /*
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('United States','Free Trial Opportunity');
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('United States','Promo Opportunity');
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('United States','Revenue Opportunity');
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('Canada','Free Trial Opportunity');
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('Canada','Promo Opportunity');
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('Canada','Revenue Opportunity');
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('Mexico','Free Trial Opportunity');
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('Mexico','Promo Opportunity');
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('Mexico','Revenue Opportunity');
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('Austria','Free Trial Opportunity');
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('Austria','Promo Opportunity');
        OpportunityHelperBeforeUpdate.getProductCodesByCountryAndType('Austria','Revenue Opportunity');
        */
        Test.startTest();
        oppRec.Bypass_Validation_Rule_DateTime__c=DateTime.now();

        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        oppRec.stageName = 'Orders Processing';
        oppRec.Owner_Role_Copy__c = 'COR Fleet IS AE3 EMEA UK - Director';
        oppRec.Shipping_Country__c = 'Canada';
        oppRec.Shipping_Method__c = 'Next Day Air';
        oppRec.Shipping_Carrier__c = 'UPS';
        oppRec.Ship_From_Location__c = 'ON-Logistics';
        update oppRec;
        Test.stopTest();
    }
    
    @isTest 
    private static void testFreeTrialOpptyUScadEmeaOverQtyLogic() {
         
        Opportunity oppRec = [Select Id, stageName From Opportunity where type = 'Free Trial Opportunity' and name = 'FreeTrialOpp'  limit 1];
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', 
                                     Family = 'Hardware', 
                                     ProductCode = 'ACC-2A12-W1',
                                     Product_Type__c = 'License');
        insert prod;
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, 
                                                          Product2Id = prod.Id,
                                                          UnitPrice = 10000, 
                                                          IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem oli = new OpportunityLineItem (Quantity=17, 
                                                          OpportunityId=oppRec.Id, 
                                                          PriceBookEntryId=standardPrice.Id, 
                                                          UnitPrice = 10000);
        insert oli;
        
        Test.startTest();
        oppRec.Bypass_Validation_Rule_DateTime__c=DateTime.now();

        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        oppRec.stageName = 'Orders Processing';
        oppRec.Owner_Role_Copy__c = 'COR Fleet IS AE3 EMEA UK - Director';
        oppRec.Shipping_Country__c = 'Canada';
        oppRec.Shipping_Method__c = 'Next Day Air';
        oppRec.Shipping_Carrier__c = 'UPS';
        oppRec.Ship_From_Location__c = 'ON-Logistics';
        update oppRec;
        Test.stopTest();
    }
    
    @isTest 
    private static void testFreeTrialMexicoLogic() {
         
        Opportunity oppRec = [Select Id, stageName From Opportunity where type = 'Free Trial Opportunity' and name = 'FreeTrialOpp'  limit 1];
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', 
                                     Family = 'Hardware', 
                                     ProductCode = 'ACC-2A12-W1',
                                     Product_Type__c = 'License');
        insert prod;
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, 
                                                          Product2Id = prod.Id,
                                                          UnitPrice = 10000, 
                                                          IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem oli = new OpportunityLineItem (Quantity=1, 
                                                          OpportunityId=oppRec.Id, 
                                                          PriceBookEntryId=standardPrice.Id, 
                                                          UnitPrice = 10000);
        insert oli;
        
        Test.startTest();
        oppRec.Bypass_Validation_Rule_DateTime__c=DateTime.now();
 
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        oppRec.stageName = 'Orders Processing';
        oppRec.Owner_Role_Copy__c = 'COR Fleet IS AE3 EMEA UK - Director';
        oppRec.Shipping_Country__c = 'Mexico';
        oppRec.Shipping_Method__c = 'MX Express';
        oppRec.Shipping_Carrier__c = 'Estafeta';
        oppRec.Ship_From_Location__c = 'Estafeta';
        update oppRec;
        Test.stopTest();
    }


    @isTest
    private static void validateSwapOpportunityTest() {

        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;

        Opportunity swapOppRec  =   [   SELECT Id, StageName 
                                        FROM Opportunity 
                                        WHERE Type = :OPP_TYPE_REMORSE_REFUND 
                                        AND NAME = 'Swap Opportunity - GTMS-27442'
                                        AND RecordTypeId = :OPP_RETURN_REC_TYPE_ID
                                        LIMIT 1
                                    ] ?? new Opportunity();

        Test.startTest();
            swapOppRec.StageName = OPP_STAGE_RET_LABEL_SENT;
            update swapOppRec;
        Test.stopTest();

        Opportunity updatedSwapOppRec = [   SELECT Id, StageName
                                            FROM Opportunity 
                                            WHERE Type = :OPP_TYPE_REMORSE_REFUND 
                                            AND NAME = 'Swap Opportunity - GTMS-27442'
                                            AND RecordTypeId = :OPP_RETURN_REC_TYPE_ID
                                            LIMIT 1
                                        ] ?? new Opportunity();

       Assert.isTrue(   updatedSwapOppRec?.StageName == OPP_STAGE_RET_FIN_PROCESS, 
                        'validateSwapOpportunityTest assert failed.' );

    }
    
     @isTest
    private static void validatePromoOpportunity(){
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        Opportunity opp = [SELECT Id,AccountId,RMA_Return_Opportunity__c,Replacement_Opportunity__c from Opportunity WHERE Name = 'Promo Creation Test Opportunity' LIMIT 1];
        
        Test.startTest();
        opp.StageName = 'End of Life with Promo';
        update opp;
    }
    @isTest
    public static void orderAutomationEmeaRevenueTest() {
        
        List<Opportunity> newOppList = new List<Opportunity>();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();
        
        Opportunity revOpp = [Select Id from Opportunity Where name = 'Before Update Revenue Oppty' LIMIT 1];
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Product2> products = new List<Product2>();
        Product2 accProd = new Product2(Name= 'LIC-AG-PWR-REEFER', ProductCode = 'LIC-AG-PWR-REEFER', Family = 'Test');
        products.add(accProd);
        insert products;
        
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry accPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = accProd.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(accPB);
        insert pricebookEntries;
        
        OpportunityLineItem oli = new OpportunityLineItem (Quantity=1, OpportunityId=revOpp.Id, PriceBookEntryId=accPB.Id, UnitPrice = 10000);
        insert oli;

        Shipping_Address__c usShipAdd = new Shipping_Address__c(Shipping_Zip_Code__c = '94105',
                                                                Shipping_Address_Line_1__c='1 Dolores, Dallas', 
                                                                Shipping_Country__c='United States', Shipping_City__c='Dallas', Shipping_State__c='Idaho', Name='US SA');
        
        insert usShipAdd;
        
        Opportunity oldOpp = [Select Id, name, stagename, type, sub_Type__c, Amount, AccountId, Shipping_Country__c, Shipping_Method__c,
                              CurrencyIsoCode, Free_Trial_Purchase__c, Ship_From_Location__c,
                              Owner_Segment__c, Segment_Sales_Role__c, Sales_Tax__c, Balance_Due__c, Shipping_and_Handling__c, 
                              Shipping_and_Handling_Manual__c, Shipping_and_Handling_Amount__c, Multi_Line_Shipping__c, 
                              Order_Ops_Notes__c, Shipping_Address_NEW__c, Shipping_Instructions__c,
                              Internal_RFO_Notes__c, Hold_Reason__c, Price_Book_Name__c, Concatenated_Shipping_Address__c,
                              Referral_Partner__c, Finance_Partner__c, Reseller__c, Insurance_Partner__c, 
                              (Select Id, ProductCode, quantity, Ship_To_Country__c, Product2.Product_Type__c from OpportunityLineItems) 
                              From Opportunity 
                              Where name = 'Before Update Revenue Oppty' LIMIT 1];
        
        oldOppMap.put(oldOpp.Id, oldOpp);
        
        OpportunityHelperContext.oppFields = oldOppMap;
        
        Opportunity newOpp = oldOpp.clone(true, true, false, false);
        newOpp.stageName = 'Orders Processing';
        newOpp.Shipping_Country__c = 'United Kingdom';
        newOpp.CurrencyISOCode = 'EUR';
        newOpp.Free_Trial_Purchase__c = 'No Purchase';
        newOpp.Ship_From_Location__c = 'DHL';
        newOpp.Shipping_Address_NEW__c = usShipAdd.Id;
        newOppList.add(newOpp);
        
        OpportunityHelperBeforeUpdate beforeUpdate = new OpportunityHelperBeforeUpdate();
        beforeUpdate.emeaOpsAutomationRevnueOppty(newOppList, oldOppMap);        
        
    }
    
    @isTest
    public static void orderAutomationEmeaPromoTest() {
        
        List<Opportunity> newOppList = new List<Opportunity>();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();
        
        Opportunity revOpp = [Select Id from Opportunity Where name = 'Promo Opportunity Test' LIMIT 1];
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Product2> products = new List<Product2>();
        Product2 accProd = new Product2(Name= 'ACC-2A12-W1', ProductCode = 'ACC-2A12-W1', Family = 'Test');
        products.add(accProd);
        insert products;
         
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry accPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = accProd.Id, UnitPrice = 0, IsActive = true);
        pricebookEntries.add(accPB);
        insert pricebookEntries;
        
        OpportunityLineItem oli = new OpportunityLineItem (Quantity=1, OpportunityId=revOpp.Id, PriceBookEntryId=accPB.Id, UnitPrice = 0);
        insert oli;

        Shipping_Address__c usShipAdd = new Shipping_Address__c(Shipping_Zip_Code__c = '94105',
                                                                Shipping_Address_Line_1__c='1 Dolores, Dallas', 
                                                                Shipping_Country__c='United States', Shipping_City__c='Dallas', Shipping_State__c='Idaho', Name='US SA');
        
        insert usShipAdd;
        
        Opportunity oldOpp = [Select Id, name, stagename, type, sub_Type__c, Amount, Amount_Received__c , AccountId, Shipping_Country__c, Shipping_Method__c,
                              CurrencyIsoCode, Free_Trial_Purchase__c, Ship_From_Location__c,
                              Owner_Segment__c, Segment_Sales_Role__c, Sales_Tax__c, Balance_Due__c, Shipping_and_Handling__c, 
                              Shipping_and_Handling_Manual__c, Shipping_and_Handling_Amount__c, Multi_Line_Shipping__c, 
                              Order_Ops_Notes__c, Shipping_Address_NEW__c, Shipping_Instructions__c,
                              Internal_RFO_Notes__c, Hold_Reason__c, Price_Book_Name__c, Concatenated_Shipping_Address__c,
                              Referral_Partner__c, Finance_Partner__c, Reseller__c, Insurance_Partner__c, 
                              Netsuite_Id__c, Push_to_Mulesoft__c, Sync_in_Progress__c, 
                              (Select Id, ProductCode, quantity, Ship_To_Country__c, Product2.Product_Type__c from OpportunityLineItems) 
                              From Opportunity 
                              Where name = 'Promo Opportunity Test' LIMIT 1];
        
        oldOppMap.put(oldOpp.Id, oldOpp);
        
        OpportunityHelperContext.oppFields = oldOppMap;
         
        Opportunity newOpp = oldOpp.clone(true, true, false, false);
        newOpp.stageName = 'Orders Processing';
        newOpp.Shipping_Country__c = 'United Kingdom';
        newOpp.CurrencyISOCode = 'EUR';
        newOpp.Free_Trial_Purchase__c = 'No Purchase';
        newOpp.Ship_From_Location__c = 'DHL';
        newOppList.add(newOpp);
        System.debug('newOpp.Amount ----> ' + newOpp.Amount);
        System.debug('newOpp.Amount_Received__c  ----> ' + newOpp.Amount_Received__c );
        System.debug('newOpp.Sales_Tax__c ----> ' + newOpp.Sales_Tax__c);
        System.debug('newOpp.Balance_Due__c ----> ' + newOpp.Balance_Due__c);
        System.debug('newOpp.Shipping_and_Handling__c ----> ' + newOpp.Shipping_and_Handling__c);
        System.debug('newOpp.Multi_Line_Shipping__c ----> ' + newOpp.Multi_Line_Shipping__c);
        System.debug('newOpp.Price_Book_Name__c ----> ' + newOpp.Price_Book_Name__c);
        OpportunityHelperBeforeUpdate beforeUpdate = new OpportunityHelperBeforeUpdate();
        beforeUpdate.emeaOpsAutomationPromoOppty(newOppList, oldOppMap);        
        
        beforeUpdate.getLoggerMessage('test');
    }
    
    @isTest
    public static void orderAutomationEmeaFreeTrialTest() {
        
        List<Opportunity> newOppList = new List<Opportunity>();
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();
        
        Opportunity revOpp = [Select Id from Opportunity Where name = 'Before Update Revenue Oppty' LIMIT 1];
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Product2> products = new List<Product2>();
        Product2 accProd = new Product2(Name= 'ACC-2A12-W1', ProductCode = 'ACC-2A12-W1', Family = 'Test');
        products.add(accProd);
        insert products;
        
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry accPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = accProd.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(accPB);
        insert pricebookEntries;
        
        OpportunityLineItem oli = new OpportunityLineItem (Quantity=1, OpportunityId=revOpp.Id, PriceBookEntryId=accPB.Id, UnitPrice = 10000);
        insert oli;

        Shipping_Address__c usShipAdd = new Shipping_Address__c(Shipping_Zip_Code__c = '94105',
                                                                Shipping_Address_Line_1__c='1 Dolores, Dallas', 
                                                                Shipping_Country__c='United States', Shipping_City__c='Dallas', Shipping_State__c='Idaho', Name='US SA');
        
        insert usShipAdd;        
        
        Opportunity oldOpp = [Select Id, name, stagename, type, sub_Type__c, Amount, Shipping_Country__c, Shipping_Method__c,
                              CurrencyIsoCode, Free_Trial_Purchase__c, Ship_From_Location__c,
                              Owner_Segment__c, Segment_Sales_Role__c, Sales_Tax__c, Balance_Due__c, Shipping_and_Handling__c, 
                              Shipping_and_Handling_Manual__c, Shipping_and_Handling_Amount__c, Multi_Line_Shipping__c, 
                              Order_Ops_Notes__c, Shipping_Address_NEW__c, Shipping_Instructions__c,
                              Internal_RFO_Notes__c, Hold_Reason__c, Price_Book_Name__c, Concatenated_Shipping_Address__c,
                              (Select Id, ProductCode, quantity, Ship_To_Country__c, Product2.Product_Type__c from OpportunityLineItems) 
                              From Opportunity 
                              Where Name = 'Before Update Rev Oppty Test' LIMIT 1];
        
        oldOppMap.put(oldOpp.Id, oldOpp);
        
        OpportunityHelperContext.oppFields = oldOppMap;
        
        Opportunity newOpp = oldOpp.clone(true, true, false, false);
        newOpp.stageName = 'Orders Processing';
        newOpp.type = 'Free Trial Opportunity';
        newOpp.Free_Trial_Purchase__c = 'No Purchase';
        newOpp.Ship_From_Location__c = 'DHL';
        newOpp.Shipping_Country__c = 'United Kingdom';
        newOpp.CurrencyIsoCode = 'EUR';
        newOpp.Shipping_Address_NEW__c = usShipAdd.Id;
        newOppList.add(newOpp);
        newOppMap.put(newOpp.Id, newOpp);
        
        OpportunityHelperBeforeUpdate beforeUpdate = new OpportunityHelperBeforeUpdate();
        beforeUpdate.freeTrialOpptyUScadEmeaMexicoLogic(newOppList, oldOppMap);        
        
    }
    
    /*
    @isTest
    static void testEmeaOpsAutomationPromoOppty_ExistingData() {
        Test.startTest();
        
        Account acc = [Select Id From Account Limit 1];
        // Get the existing Promo Opportunity created in @testSetup
        Opportunity oldPromoOpp = [SELECT Id, StageName, Type, Shipping_Country__c, Shipping_Carrier__c, Ship_From_Location__c, 
                                    Shipping_Method__c, CurrencyIsoCode, Owner_Role_Copy__c, Price_Book_Name__c, accountId
                                FROM Opportunity
                                WHERE Name = 'Before Update Promo Test Opportunity'
                                LIMIT 1];

        Opportunity newPromoOpp = oldPromoOpp.clone(false, true, false, false);

        // Create a valid EMEA promo SKU product and pricebook entry
        Product2 emeaPromoProduct = new Product2(
            Name = 'EMEA Promo Product',
            ProductCode = 'ACC-2A12-W1', // from VCK_EMEA_Promo_SKU
            Product_Type__c = 'Accessory',
            IsActive = true
        );
        insert emeaPromoProduct;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = emeaPromoProduct.Id,
            CurrencyIsoCode = oldPromoOpp.CurrencyIsoCode,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create an OpportunityLineItem for the promo opportunity
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = oldPromoOpp.Id,
            Quantity = 1,
            PricebookEntryId = pbe.Id,
            UnitPrice = 100,
            Product2Id = emeaPromoProduct.Id
            );
            insert oli;
            
        // Set fields to match EMEA promo criteria
        newPromoOpp.StageName = 'Orders Processing';
        newPromoOpp.Type = 'Promo Opportunity';
        newPromoOpp.Shipping_Country__c = 'United Kingdom';
        newPromoOpp.Shipping_Carrier__c = 'UPS';
        newPromoOpp.Ship_From_Location__c = 'DHL';
        newPromoOpp.Shipping_Method__c = 'UK Standard';
        newPromoOpp.CurrencyIsoCode = 'GBP';
        newPromoOpp.Owner_Role_Copy__c = 'AE3';
        newPromoOpp.Price_Book_Name__c = 'Samsara FY22';
        newPromoOpp.accountId = acc.Id;
        newPromoOpp.Referral_Partner__c = acc.Id;
        newPromoOpp.Finance_Partner__c = acc.Id;
        newPromoOpp.Reseller__c = acc.Id;
        newPromoOpp.Insurance_Partner__c = acc.Id;
        //update newPromoOpp;
        // Prepare input for the method
        List<Opportunity> newOppList = new List<Opportunity>();
        newOppList.add(newPromoOpp);
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        oldOppMap.put(newPromoOpp.Id, oldPromoOpp);

        // // Act
        OpportunityHelperBeforeUpdate helper = new OpportunityHelperBeforeUpdate();
        helper.emeaOpsAutomationPromoOppty(newOppList, oldOppMap);
        Test.stopTest();

        // Assert (customize as needed)
        // Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :promoOpp.Id];
        // System.assertEquals('Orders Processing', updatedOpp.StageName, 'StageName should remain Orders Processing or be updated as per logic');
    }
    */
    /*
    @isTest private static void testRollupProbabilityInsertUpdateDeleteUndelete()
    {
        //Test.startTest();
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountExpectedRevenue');
        insert acc;
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue');
        thisOpp.AccountId = acc.Id;
        thisOpp.StageName = 'Qualified';
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.Amount = 10000;
        insert thisOpp;
        //Alekya
        Test.startTest();
        thisOpp = [SELECT id, probability FROM Opportunity WHERE NAME like 'RollupToAccountExpectedRevenue%' LIMIT 1];
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);
        thisOpp.StageName = 'Purchase';
        update thisOpp;
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);
        delete thisOpp;
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, null);
        Opportunity[] savedopps = [SELECT Id, probability FROM Opportunity WHERE Name LIKE 'RollupToAccountExpectedRevenue%' ALL ROWS ];
        undelete savedopps;
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, savedopps[0].probability);
        Test.stopTest();
    }
    
    /*@isTest static void testOrdersProcessing() {
        Opportunity newOpportunity = [SELECT Id, Name, Owner_Role_Copy__c, Owner_Business_Unit__c from Opportunity where Name ='Before Update Rev Oppty Test' LIMIT 1];
        Opportunity newOpportunity1 = [SELECT Id, Name, Owner_Role_Copy__c, Owner_Business_Unit__c from Opportunity WHERE Name ='Before Update Revenue Oppty' LIMIT 1];
        SBQQ__Quote__c primaryQuote = [SELECT Id from SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote Opportunity Two'];
        
        Contact cc = [Select Id from Contact where Email = 'test@test.com' limit 1];
        Account acc = [Select id, Name, SLED_Account__c, Owner_Role__c from Account Limit 1];
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
         Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;
        test.startTest();
        
        primaryQuote.SBQQ__Primary__c = true;
        update primaryQuote;
        newOpportunity.Trial_Goal_1__c = 'fooo';
        newOpportunity.closeDate = system.today().adddays(50);
        //newOpportunity.Trial_Primary_Contact__c = cc.Id;
        newOpportunity.Trial_Goal_2__c  = 'foooo1';
        newOpportunity.Trial_Period__c = 10;
        newOpportunity.Planned_Trial_Installation_Date__c = system.today();
        newOpportunity.StageName = 'Orders Processing';
        newOpportunity.Is_Webstore_Upsell_Opportunity__c= true;
        //newOpportunity.SBQQ__PrimaryQuote__c = primaryQuote.Id;
        newOpportunity.TrialResolutionOppty__c  = newOpportunity1.Id;
        update newOpportunity;
        Set<Id> setopp = new Set<Id>();
        setopp.add(newOpportunity.Id);
        OpptyHelperBeforeUpdateExt.setOwnerSubRegion(newOpportunity, acc);
        system.debug('newOpportunity---'+newOpportunity);
        test.stopTest();
    }
    
    
    
    
    
    /*@isTest
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
        revOpp.Free_Trial_Purchase__c = 'Full Buy';
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
        thisOppRet.Type = 'Rebate';
        thisOppRet.Rebate_Type__c = 'Buyout';
        insert thisOppRet;
        thisOppRet.StageName = 'Refunded - Closed';
        thisOppRet.Type = 'Rebate' ;
        thisOppRet.Is_Webstore_Upsell_Opportunity__c= true;
        thisOppRet.Owner_Manager_Email_Copy__c = null;
        update thisOppRet;
        Opportunity oppAfterRetOpptyRefunded = [Select id, Returning_Opportunity__r.Owner_Manager_Email_Copy__c, Owner.Manager.Email, Owner_Manager_Email_Copy__c  FROM Opportunity WHERE Id=: thisOppRet.Id];
        system.assertEquals(oppAfterRetOpptyRefunded.Returning_Opportunity__r.Owner_Manager_Email_Copy__c,oppAfterRetOpptyRefunded.Owner_Manager_Email_Copy__c);
        test.stopTest();
    } */
/*
	@isTest
    private static void testClickpath_existingQuoteLines(){
        SBQQ.TriggerControl.disable();
        OpportunityTriggerHandler.maxRuns = 1;
        Account acc = [SELECT Id, Name FROM Account WHERE Name LIKE 'Testers 6%' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId =:acc.Id LIMIT 1];
        Opportunity thisOpp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Before Update Rev Oppty%' LIMIT 1];
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
        Contract cont = new Contract(
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
        update cont;
        Test.startTest();
        SBQQ.TriggerControl.enable();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c =thisOpp.Id,
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = true, Custom_License_Term__c = 2);
        insert quote;
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
        OpportunityTriggerHandler.resetAll();
        thisOpp.AccountId = acc.Id;
        thisOpp.Type = 'Revenue Opportunity';
        thisOpp.Sub_Type__c = 'Clickpath';
        thisOpp.Renewal__c = true;
        //thisOpp.SBQQ__RenewedContract__c = cont.id;
        thisOpp.StageName = 'Decision';
        thisOpp.Shipping_Contact__c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1].Id;
        update thisOpp;
        thisOpp = [SELECT Id, Gainsight_Audit_Status__c, Gainsight_Audit_Override__c FROM Opportunity WHERE Id = :thisOpp.Id];
        System.assert(thisOpp.Gainsight_Audit_Status__c.contains('Pending'));
        Test.stopTest();
    }
*/
}