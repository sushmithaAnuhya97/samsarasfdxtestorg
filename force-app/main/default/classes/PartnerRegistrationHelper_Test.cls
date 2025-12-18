/**********************************************************************
Name: PartnerRegistrationHelper_Test
=======================================================================
Purpose: This is test class for PartnerRegistrationHelper                                                  
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2024-Jul-17        INITIAL DEVELOPMENT 
1.1.       Rodrigo Carpio.       2025-Aug-21.       added test method for GTMS-28939
**********************************************************************/

@isTest
public class PartnerRegistrationHelper_Test {
	@testSetup
    private static void testDataSetup() {
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
        products.add(vgLicense);  
        Product2 insuranceSUBSIDY = new Product2(Name= 'INS-SUBSIDY', ProductCode = 'INS-SUBSIDY', Family = 'Test');
        products.add(insuranceSUBSIDY);  
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        PricebookEntry insuranceSUBSIDYPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = insuranceSUBSIDY.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(insuranceSUBSIDYPB);
        insert pricebookEntries;        
        List<Account> newAccounts = new List<Account>();

        Account account = new Account(  Name = 'Test Account',
                                        BillingCountry = 'United States',
                                        BillingState = 'California',
                                        Organization_Size__c = '100 - 499',
                                        Industry = 'Other');
        newAccounts.add(account);

        Account partnerAccount = new Account(   Name = 'Partner Testers',
                                                BillingCountry = 'United Kingdom',
                                                Organization_Size__c = '100 - 499',
                                             	Partner_Status__c = 'Transacting Partner',
                                             	Partner_Type__c = 'Insurance',
                                                Industry = 'Other', 
                                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId());
        newAccounts.add(partnerAccount);
        insert newAccounts;
        List<Contact> newContacts = new List<Contact>();
        Contact partnerContact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=partnerAccount.Id);
        newContacts.add(partnerContact);
        Contact contact2 = new Contact (FirstName = 'TestClass', LastName = 'TesterLawfulBasis', Email = 'ttesterstampfulbasis@a.com', AccountId=account.Id);
        newContacts.add(contact2);
        insert newContacts;
        
        List<Contract> contracts = new List<Contract>();
        Contract contract = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(365),
                ContractTerm = 12
        );
        contracts.add(contract);
        Contract contract2 = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(180),
                ContractTerm = 12
        );
        contracts.add(contract2);
        
        Contract contract3 = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(90),
                ContractTerm = 12
        );
        contracts.add(contract3);
        insert contracts;
        
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        insert revenueOpportunity;       
        
        Partner_Registration__c prCreate = new Partner_Registration__c(Account__c = account.Id,Contact__c=contact2.Id, Status__c='New', Address__CountryCode__s='US',Address__StateCode__s='TX');
        insert prCreate;
        
        Partner_Program__c partnerProgram = createPartnerProgram();
        insert partnerProgram;
        
        Partner_Program_Enrollment__c programEnrollment = createProgramEnrollment(partnerProgram.Id, partnerAccount.Id, partnerContact.Id);
        insert programEnrollment;
        SLA_Holiday__c hol = new SLA_Holiday__c(Holiday_Name__c='test holiday', Holiday_Date__c=System.Today(),Country__c='United States');
        insert hol;
    }
    
    static Partner_Program__c createPartnerProgram(){
        Partner_Program__c program = new Partner_Program__c();
        program.Name = 'Test Program';
        program.Allow_Enrollment__c = 'Yes';
        program.Approvals_Required__c = 'No';
        program.Program_Status__c = 'Active';
        program.Member_Review_Period__c = 'Evergreen';
        program.Sourced_Payout_Model__c = 'Percentage';
        program.Sourced_Payout_Percentage__c = 10;
        program.Sourced_Payout_Fee__c = 1000;
        program.Sourced_Payout_Cap__c = 75000;
        program.Influence_Payout_Model__c = 'Percentage';
        program.Influence_Payout_Percentage__c = 10;
        program.Influence_Payout_Fee__c = 500;
        program.Influence_Payout_Cap__c = 5000;
        program.Partner_Discount__c = 20;
        program.SalesProgramType__c = 'Paid Referral';
        return program;        
    }
    
    static Partner_Program_Enrollment__c createProgramEnrollment(string programId, string partnerAccId, string partnerConId){
        Partner_Program_Enrollment__c enrollment = new Partner_Program_Enrollment__c();
        enrollment.Partner_Program__c = programId;
        enrollment.Partner_Account__c = partnerAccId;
        enrollment.Partner_Contact__c = partnerConId;
        enrollment.Member_Status__c = 'Active';
        enrollment.Sourced_Payout_Model__c = 'Percentage';
        enrollment.Sourced_Payout_Percentage__c = 10;
        enrollment.Sourced_Payout_Fee__c = 1000;
        enrollment.Sourced_Payout_Cap__c = 75000;
        enrollment.Influence_Payout_Model__c = 'Percentage';
        enrollment.Influence_Payout_Percentage__c = 10;
        enrollment.Influence_Payout_Fee__c = 500;
        enrollment.Influence_Payout_Cap__c = 5000;
        enrollment.SalesProgramType__c = 'Paid Referral';
        enrollment.Approved_for_Add_a_Partner_workflow__c = true;
        return enrollment;
    }
    
	@IsTest
    private static void partnerregistrationupdate() {
        Partner_Registration__c pr = [SELECT Id FROM Partner_Registration__c limit 1];
        Partner_Program__c pp = [SELECT Id FROM Partner_Program__c  limit 1];
        Partner_Program_Enrollment__c ppe = [SELECT Id FROM Partner_Program_Enrollment__c  limit 1];
        Test.startTest();
        pr.Status__c ='PAM Reviewed';
        pr.SLA_Business_Days__c ='1';
        pr.Partner_Program__c =pp.id;
        pr.Partner_Program_Enrollment__c =ppe.id;
        update pr;
        Test.stopTest();
    }
    
    @IsTest
    private static void testContractAmend2() {
        
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name like '%Test Account%'];
        Opportunity testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        List<Contract> ctt = [SELECT Id, StartDate,EndDate FROM Contract];
        List<Partner_Registration__c> pr = [SELECT Id FROM Partner_Registration__c];
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, SBQQ__Type__c='Quote',
                                                  SBQQ__SubscriptionTerm__c=12);
        SBQQ__Quote__c quote2 = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, SBQQ__Type__c='Quote',
                                                  SBQQ__SubscriptionTerm__c=37);
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        quotes.add(quote);
        quotes.add(quote2);
        insert quotes;
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id,
                                                                  SBQQ__ListPrice__c=100);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote2.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id,
                                                                  SBQQ__ListPrice__c=100);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        Test.startTest();
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c=quoteLineOne.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt[0].Id,
            SBQQ__RenewalQuantity__c = -5,
SBQQ__NetPrice__c = 10,
            SBQQ__SubscriptionStartDate__c = Date.today().adddays(1),
            SBQQ__SubscriptionEndDate__c=Date.today().adddays(365)
            
        );
        subscriptionList.add(subscription1);
        
        insert subscriptionList;     
        ctt[0].SBQQ__Opportunity__c = testOpportunity.Id;
        ctt[0].SBQQ__Quote__c = quote.Id; 
		ctt[0].Status='Activated';
        update ctt[0];
        //Contract contract = [SELECT id, StartDate FROM Contract LIMIT 1];
        List<PartnerRegistrationHelper.AmendedContractInput> inputList = new List<PartnerRegistrationHelper.AmendedContractInput>();
        PartnerRegistrationHelper.AmendedContractInput input = new PartnerRegistrationHelper.AmendedContractInput();
        input.contractId = ctt[0].Id;
        input.partnerRegistrationId = pr[0].id;
        inputList.add(input);
        PartnerRegistrationHelper.AmendContract(inputList);
        Test.stopTest();
    }
    
    
    @IsTest
    private static void testContractAmend1() {
        
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name like '%Test Account%'];
        Opportunity testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        List<Contract> ctt = [SELECT Id, StartDate,EndDate FROM Contract];
        List<Partner_Registration__c> pr = [SELECT Id FROM Partner_Registration__c];
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, SBQQ__Type__c='Quote',
                                                  SBQQ__SubscriptionTerm__c=12);
        SBQQ__Quote__c quote2 = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, SBQQ__Type__c='Quote',
                                                  SBQQ__SubscriptionTerm__c=37);
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        quotes.add(quote);
        quotes.add(quote2);
        insert quotes;
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id,
                                                                  SBQQ__ListPrice__c=100);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote2.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id,
                                                                  SBQQ__ListPrice__c=100);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        Test.startTest();
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c=quoteLineOne.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt[0].Id,
            SBQQ__RenewalQuantity__c = -5,
SBQQ__NetPrice__c = 10,
            SBQQ__SubscriptionStartDate__c = Date.today().adddays(1),
            SBQQ__SubscriptionEndDate__c=Date.today().adddays(365)
            
        );
        subscriptionList.add(subscription1);
        SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c=quoteLineTwo.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt[0].Id,
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = 10,
SBQQ__BundledQuantity__c=10,
            SBQQ__SubscriptionStartDate__c = Date.today().adddays(1),
            SBQQ__SubscriptionEndDate__c=Date.today().adddays(365)
            
        );
        subscriptionList.add(subscription2);
        insert subscriptionList;     
        ctt[0].SBQQ__Opportunity__c = testOpportunity.Id;
        ctt[0].SBQQ__Quote__c = quote.Id; 
		ctt[0].Status='Activated';
        update ctt[0];
        //Contract contract = [SELECT id, StartDate FROM Contract LIMIT 1];
        List<PartnerRegistrationHelper.AmendedContractInput> inputList = new List<PartnerRegistrationHelper.AmendedContractInput>();
        PartnerRegistrationHelper.AmendedContractInput input = new PartnerRegistrationHelper.AmendedContractInput();
        input.contractId = ctt[0].Id;
        input.partnerRegistrationId = pr[0].id;
        inputList.add(input);
        PartnerRegistrationHelper.AmendContract(inputList);
        Test.stopTest();
    }
    
    @IsTest
    private static void testContractAmend0() {
        Test.startTest();
        List<Contract> ctt = [SELECT Id, StartDate,EndDate FROM Contract];
        List<Partner_Registration__c> pr = [SELECT Id FROM Partner_Registration__c];
        
        //Contract contract = [SELECT id, StartDate FROM Contract LIMIT 1];
        List<PartnerRegistrationHelper.AmendedContractInput> inputList = new List<PartnerRegistrationHelper.AmendedContractInput>();
        PartnerRegistrationHelper.AmendedContractInput input = new PartnerRegistrationHelper.AmendedContractInput();
        input.contractId = ctt[0].Id;
        input.partnerRegistrationId = pr[0].id;
        inputList.add(input);
        PartnerRegistrationHelper.AmendContract(inputList);
        PartnerRegistrationHelper.performContractAmender(inputList);
        Test.stopTest();
    }
}