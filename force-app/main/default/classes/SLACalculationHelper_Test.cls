/**********************************************************************
Name: SLACalculationHelper_Test
=======================================================================
Purpose: This is test class for SLACalculationHelper                                                  
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Aug-25        INITIAL DEVELOPMENT 
**********************************************************************/

@isTest
public class SLACalculationHelper_Test {
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

}