/**
 * Created by fcontini on 2021-09-20.
 */

@IsTest
public with sharing class GS_OpportunityPBConversionServiceTest {

    @TestSetup
    static void setup(){
        GS_GlobalAutomationSettingsTest.createAutomationTestSetting();
    }
    
    @IsTest
    public static void readyToShipOrClosedWon_fireEvent(){
        List<Opportunity> newOppList = new List<Opportunity>{
            new Opportunity(
                    Id = TestFactory.getFakeId(Opportunity.SObjectType),
                    Type = 'Revenue Opportunity',
                    StageName = 'Orders Processing',
                    Send_Virtual_Bell__c = true,
                    AccountId = TestFactory.getFakeId(Account.SObjectType)
            )
        };

        Test.startTest();
        (new GS_OpportunityPBConversionService(null, newOppList, null)).readyToShipOrClosedWon();
        Test.stopTest();

        System.assertEquals(true, GS_OpportunityEventPublisherService.hasPublishedAnEvent);
    }
    
    @IsTest
    public static void closingOppWithStripeTrialOrExpessFinanceApprovalTest(){
        
        List<Opportunity> newOppList = new List<Opportunity>{
            new Opportunity(
                    Id = TestFactory.getFakeId(Opportunity.SObjectType),
                    Type = 'Free Trial Opportunity',
                    StageName = 'Closing',
                    AccountId = TestFactory.getFakeId(Account.SObjectType)
            )
        };

        Test.startTest();
        GS_OpportunityPBConversionService opportunityPBConversionServiceObj = (new GS_OpportunityPBConversionService(null, newOppList, null));
        opportunityPBConversionServiceObj.closingOppWithStripeTrialOrExpessFinanceApproval();
        
        Test.stopTest();

        System.assertEquals(true, opportunityPBConversionServiceObj.newOppList[0].Overwrite_Validation_Rule__c);
    }
    
    
    @isTest
    private static void testContractRenewalCreate() {
	
        List<Opportunity> newOppList = new List<Opportunity>();
         List<Opportunity> oldOppList = new List<Opportunity>();
          List<Account> newAccounts = new List<Account>();
       List<Contact> newContacts = new List<Contact>();
         Account a = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other',
                                Segment_Text_stamped__c = 'SMB');
        newAccounts.add(a);
         insert newAccounts;
        
        Contact c = (Contact) TestFactory.createSObject(new Contact(AccountId = a.Id, Email = 'test@test.com'));
        newContacts.add(c);

        insert newContacts;
        
        Contract contract = new Contract(Name = 'Test Contract', AccountId = a.Id, ContractTerm = 24);
        insert contract;

     Opportunity oldOpportunityRenewal = (Opportunity)
                TestFactory.createSObject(new Opportunity(AccountId = a.Id,
                        Type = 'Revenue Opportunity',
                        Name = 'Opp Testers 2 Inc',
                        StageName = 'Proposal',
                        Shipping_Contact__c = c.Id,
                        Renewal__c = true,
                        netsuite_conn__Bill_To_Tier__c = 'End User',
                        ContractId = contract.id,
                        License_Term_Approval_Status__c = 'Pending ',
                        Selected_Payment_Type__c = 'Direct Annual'));
        
        insert oldOpportunityRenewal;
        oldOppList.add(oldOpportunityRenewal);
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>(oldOppList);
        
        
        Opportunity opportunityRenewal = (Opportunity)
                TestFactory.createSObject(new Opportunity(AccountId = a.Id,
                        Type = 'Revenue Opportunity',
                        Name = 'Opp Testers 2 Inc',
                        StageName = 'Proposal',
                        Shipping_Contact__c = c.Id,
                        Renewal__c = true,
                        netsuite_conn__Bill_To_Tier__c = 'End User',
                        ContractId = contract.id,
                        License_Term_Approval_Status__c = 'Pending ',
                        Selected_Payment_Type__c = 'Direct Annual'));

        Test.startTest();
        insert opportunityRenewal;
       
		oldOppMap.put(opportunityRenewal.Id,oldOpportunityRenewal);

        Contract newContract = [SELECT Id, Renewed_To_Oppty__c FROM Contract WHERE Id = :contract.Id];
        
        opportunityRenewal.ContractId = contract.id;
        opportunityRenewal.netsuite_conn__From_Contract__c =contract.Id;
        opportunityRenewal.Type = 'Revenue Opportunity';
        opportunityRenewal.StageName = 'Closed Won';
        opportunityRenewal.Adjust_License_Start_Date__c = false;
        opportunityRenewal.License_Start_Date__c = null;
        opportunityRenewal.netsuite_conn__Bill_To_Tier__c = null;
        
         update opportunityRenewal;
        
        opportunityRenewal.ContractId = null;
        opportunityRenewal.netsuite_conn__From_Contract__c = null;
        opportunityRenewal.Type = 'Revenue Opportunity';
        opportunityRenewal.StageName = 'Closed Won';
        opportunityRenewal.Adjust_License_Start_Date__c = false;
        opportunityRenewal.License_Start_Date__c = null;
        opportunityRenewal.netsuite_conn__Bill_To_Tier__c = null;
        opportunityRenewal.License_Term_Approval_Status__c = 'Approved';
        opportunityRenewal.License_Term__c = 36;
        
        newOppList.add(opportunityRenewal);
                
        
        GS_OpportunityPBConversionService opportunityPBConversionServiceObj = (new GS_OpportunityPBConversionService(oldOppMap, newOppList, null));
        opportunityPBConversionServiceObj.updateContractBasedFields();

      System.assertEquals(10, opportunityPBConversionServiceObj.newOppList[0].Approved_Discount__c);
        Test.stopTest();
    }
    
    
    @isTest
    private static void testContractRenewalCreateWithAdjustLicenseStartDate() {
	
        List<Opportunity> newOppList = new List<Opportunity>();
         List<Opportunity> oldOppList = new List<Opportunity>();
          List<Account> newAccounts = new List<Account>();
       List<Contact> newContacts = new List<Contact>();
         Account a = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other',
                                Segment_Text_stamped__c = 'SMB');
        newAccounts.add(a);
         insert newAccounts;
        
        Contact c = (Contact) TestFactory.createSObject(new Contact(AccountId = a.Id, Email = 'test@test.com'));
        newContacts.add(c);

        insert newContacts;
        
        Contract contract = new Contract(Name = 'Test Contract', AccountId = a.Id, ContractTerm = 24);
        insert contract;

     Opportunity oldOpportunityRenewal = (Opportunity)
                TestFactory.createSObject(new Opportunity(AccountId = a.Id,
                        Type = 'Revenue Opportunity',
                        Name = 'Opp Testers 2 Inc',
                        StageName = 'Proposal',
                        Shipping_Contact__c = c.Id,
                        Renewal__c = true,
                        netsuite_conn__Bill_To_Tier__c = 'End User',
                        ContractId = contract.id,
                        License_Term_Approval_Status__c = 'Pending ',
                        Selected_Payment_Type__c = 'Direct Annual'));
        
        insert oldOpportunityRenewal;
        oldOppList.add(oldOpportunityRenewal);
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>(oldOppList);
        
        
        Opportunity opportunityRenewal = (Opportunity)
                TestFactory.createSObject(new Opportunity(AccountId = a.Id,
                        Type = 'Revenue Opportunity',
                        Name = 'Opp Testers 2 Inc',
                        StageName = 'Proposal',
                        Shipping_Contact__c = c.Id,
                        Renewal__c = true,
                        netsuite_conn__Bill_To_Tier__c = 'End User',
                        ContractId = contract.id,
                        License_Term_Approval_Status__c = 'Pending ',
                        Selected_Payment_Type__c = 'Direct Annual'));

        Test.startTest();
        insert opportunityRenewal;
       
		oldOppMap.put(opportunityRenewal.Id,oldOpportunityRenewal);

        Contract newContract = [SELECT Id, Renewed_To_Oppty__c FROM Contract WHERE Id = :contract.Id];
        
        opportunityRenewal.ContractId = contract.id;
        opportunityRenewal.netsuite_conn__From_Contract__c =contract.Id;
        opportunityRenewal.Type = 'Revenue Opportunity';
        opportunityRenewal.StageName = 'Closed Won';
        opportunityRenewal.Adjust_License_Start_Date__c = true;
        opportunityRenewal.License_Start_Date__c = System.today();
        opportunityRenewal.netsuite_conn__Bill_To_Tier__c = null;
        
         update opportunityRenewal;
        
        opportunityRenewal.ContractId = null;
        opportunityRenewal.netsuite_conn__From_Contract__c = null;
        opportunityRenewal.Type = 'Revenue Opportunity';
        opportunityRenewal.StageName = 'Closed Won';
        opportunityRenewal.Adjust_License_Start_Date__c = true;
        opportunityRenewal.License_Start_Date__c = System.today();
        opportunityRenewal.netsuite_conn__Bill_To_Tier__c = null;
        opportunityRenewal.License_Term_Approval_Status__c = 'Approved';
        opportunityRenewal.License_Term__c = 36;
        
        newOppList.add(opportunityRenewal);
                
        
        GS_OpportunityPBConversionService opportunityPBConversionServiceObj = (new GS_OpportunityPBConversionService(oldOppMap, newOppList, null));
        opportunityPBConversionServiceObj.updateContractBasedFields();

		System.assertEquals(10, opportunityPBConversionServiceObj.newOppList[0].Approved_Discount__c);
        Test.stopTest();
    }
    
    
    @isTest
    private static void testContractRenewalPromoReason() {
	
        List<Opportunity> newOppList = new List<Opportunity>();
         List<Opportunity> oldOppList = new List<Opportunity>();
          List<Account> newAccounts = new List<Account>();
       List<Contact> newContacts = new List<Contact>();
         Account a = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other',
                                Segment_Text_stamped__c = 'SMB');
        newAccounts.add(a);
         insert newAccounts;
        
        Contact c = (Contact) TestFactory.createSObject(new Contact(AccountId = a.Id, Email = 'test@test.com'));
        newContacts.add(c);

        insert newContacts;
        
        Contract contract = new Contract(Name = 'Test Contract', AccountId = a.Id, ContractTerm = 24);
        insert contract;

     Opportunity oldOpportunityRenewal = (Opportunity)
                TestFactory.createSObject(new Opportunity(AccountId = a.Id,
                        Type = 'Revenue Opportunity',
                        Name = 'Opp Testers 2 Inc',
                        StageName = 'Proposal',
                        Shipping_Contact__c = c.Id,
                        Renewal__c = true,
                        netsuite_conn__Bill_To_Tier__c = 'End User',
                        ContractId = contract.id,
                        License_Term_Approval_Status__c = 'Pending ',
                        License_Term__c = 72,
                        Selected_Payment_Type__c = 'Direct Annual'));
        
        insert oldOpportunityRenewal;
        oldOppList.add(oldOpportunityRenewal);
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>(oldOppList);
        
        
        Opportunity opportunityRenewal = (Opportunity)
                TestFactory.createSObject(new Opportunity(AccountId = a.Id,
                        Type = 'Revenue Opportunity',
                        Name = 'Opp Testers 2 Inc',
                        StageName = 'Proposal',
                        Shipping_Contact__c = c.Id,
                        Renewal__c = true,
                        netsuite_conn__Bill_To_Tier__c = 'End User',
                        ContractId = contract.id,
                        License_Term_Approval_Status__c = 'Pending ',
                        Selected_Payment_Type__c = 'Direct Annual'));

        Test.startTest();
        insert opportunityRenewal;
       
		oldOppMap.put(opportunityRenewal.Id,oldOpportunityRenewal);

        Contract newContract = [SELECT Id, Renewed_To_Oppty__c FROM Contract WHERE Id = :contract.Id];
        
        opportunityRenewal.ContractId = contract.id;
        opportunityRenewal.netsuite_conn__From_Contract__c =contract.Id;
        opportunityRenewal.Type = 'Promo Opportunity';
        opportunityRenewal.StageName = 'Closed Won';
        opportunityRenewal.Adjust_License_Start_Date__c = true;
        opportunityRenewal.License_Start_Date__c = null;
        opportunityRenewal.netsuite_conn__Bill_To_Tier__c = null;
        
         update opportunityRenewal;
        
        opportunityRenewal.ContractId = null;
        opportunityRenewal.netsuite_conn__From_Contract__c = null;
        opportunityRenewal.StageName = 'Closed Won';
        opportunityRenewal.Adjust_License_Start_Date__c = true;
        opportunityRenewal.License_Start_Date__c = null;
        opportunityRenewal.Promo_Reason__c = 'Beta Program';
        opportunityRenewal.Type = 'Promo Opportunity';
        opportunityRenewal.netsuite_conn__Bill_To_Tier__c = null;
        opportunityRenewal.License_Term_Approval_Status__c = 'Approved';
        opportunityRenewal.License_Term__c = 36;
        
        newOppList.add(opportunityRenewal);
                
        
        GS_OpportunityPBConversionService opportunityPBConversionServiceObj = (new GS_OpportunityPBConversionService(oldOppMap, newOppList, null));
        opportunityPBConversionServiceObj.updateContractBasedFields();

        System.assertEquals(10, opportunityPBConversionServiceObj.newOppList[0].Approved_Discount__c);
        Test.stopTest();
    }
 
    
}