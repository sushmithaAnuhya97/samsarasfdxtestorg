@isTest
public with sharing class GS_OpportunityPrepopulationTest {
    private static String FIRST_ACCOUNT_NAME  = 'Testers 1 Inc';
    private static String SECOND_ACCOUNT_NAME = 'Testers 2 Inc';
    private static String RESOLUTION_OPP_NAME = 'Resolution Opp';
    private static String CONTRACT_OPP_NAME   = 'Contract Opportunity';
    private static String OPP_RESELLER_NAME   = 'Reseller Opportunity';
    private static String CONTRACT_NAME       = 'Contract Record';
    
    @TestSetup
    static void setup(){

        
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
         
        Account accountOne = new Account(Name = FIRST_ACCOUNT_NAME,
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        newAccounts.add(accountOne);
        
        Account accountTwo = new Account(Name = SECOND_ACCOUNT_NAME,
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

        Opportunity opportunityContract = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                    Type = 'Revenue Opportunity',
                                                    Name = CONTRACT_OPP_NAME,
                                                    StageName = 'Proposal',
                                                    Payment_Terms__c = 'Net 15',
                                                    Shipping_Contact__c = contactOne.Id,
                                                    Reseller__c = accountOne.Id,
                                                    Selected_Payment_Type__c = 'Direct Monthly',
                                                    Finance_Partner__c = accountTwo.Id,
                                                    Shipping_Address_NEW__c = sa.Id,
                                                    OwnerId = UserInfo.getUserId(),
                                                    Approved_Discount__c = 10,
                                                    Price_Book_Name__c = 'Standard',
                                                    Send_Invoice__c = false));
        newOpportunities.add(opportunityContract); 


        Opportunity returningOpportunity = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                    Type = 'Revenue Opportunity',
                                                    Name = OPP_RESELLER_NAME,
                                                    Reseller_Partner__c = accountTwo.Id,
                                                    StageName = 'Proposal',
                                                    Payment_Terms__c = 'Net 15',
                                                    Shipping_Contact__c = contactOne.Id,
                                                    Reseller__c = accountOne.Id,
                                                    Selected_Payment_Type__c = 'Direct Monthly',
                                                    Finance_Partner__c = accountTwo.Id,
                                                    Shipping_Address_NEW__c = sa.Id,
                                                    OwnerId = UserInfo.getUserId(),
                                                    Approved_Discount__c = 10,
                                                    Price_Book_Name__c = 'Standard',
                                                    Send_Invoice__c = false));
        newOpportunities.add(returningOpportunity); 

        insert newOpportunities;

        Contract contractOne = new Contract(
            name = CONTRACT_NAME,
            AccountId = accountOne.id,
            SBQQ__Opportunity__c = opportunityContract.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(1),
            Status = 'Draft',
            ContractTerm = 36,
            CurrencyIsoCode = 'USD'
        );
        insert contractOne;
    }

    @isTest
    public static void test_FieldsFromAmendedContract(){
        // System.debug('PROFILE HERE: '+UserInfo.getProfileId());
        // System.debug(JSON.serializePretty(Global_Automation_Settings__c.getInstance(UserInfo.getUserId())));
        Account accountOne = [SELECT Id FROM Account WHERE Name = :FIRST_ACCOUNT_NAME LIMIT 1];
        Contract contractOpp = [SELECT Id FROM Contract WHERE Name = :CONTRACT_NAME LIMIT 1];
        Contact contactOne = [SELECT Id FROM Contact LIMIT 1];
        Opportunity returningOpportunity = [SELECT Id, Reseller_Partner__c, Owner_Segment__c, Returning_Opportunity__c, Returning_Opportunity__r.Owner_Segment__c, Returning_Opportunity__r.Reseller_Partner__c FROM Opportunity WHERE Name = :OPP_RESELLER_NAME LIMIT 1];

        Opportunity oppOne = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                Type = 'Free Trial Opportunity',
                                                Name = 'Free Trial 1',
                                                StageName = 'Proposal',
                                                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                Shipping_Contact__c = contactOne.Id,
                                                SBQQ__RenewedContract__c = contractOpp.Id,
                                                Returning_Opportunity__c = returningOpportunity.Id,
                                                Returning_Opportunity__r = returningOpportunity,
                                                Selected_Payment_Type__c = 'Direct Annual',
                                                Price_Book_Name__c = 'Standard',
                                                Send_Invoice__c = false));

        Opportunity oppTwo = (Opportunity)
                TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                Type = 'Rebate',
                                                Name = 'Free Trial 2',
                                                StageName = 'Proposal',
                                                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                Shipping_Contact__c = contactOne.Id,
                                                SBQQ__AmendedContract__c = contractOpp.Id,
                                                Returning_Opportunity__c = returningOpportunity.Id,
                                                Returning_Opportunity__r = returningOpportunity,
                                                Selected_Payment_Type__c = 'Direct Annual',
                                                Price_Book_Name__c = 'Standard',
                                                Send_Invoice__c = false));

        Opportunity oppThree = (Opportunity)
                TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                        Type = 'Free Trial Opportunity',
                        Name = 'Free Trial 2',
                        StageName = 'Closed Won',
                        RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                        Shipping_Contact__c = contactOne.Id,
                        SBQQ__AmendedContract__c = contractOpp.Id,
                        Returning_Opportunity__c = returningOpportunity.Id,
                        Returning_Opportunity__r = returningOpportunity,
                        Selected_Payment_Type__c = 'Direct Monthly',
                        Small_Fleet_Opportunity__c = true,
                        Express_Annual_Discount__c = 10,
                        Express_Upfront_Discount__c = 10,
                        Price_Book_Name__c = 'Standard',
                        Send_Invoice__c = false));

        Test.startTest();
        List<Opportunity> oppList = new List<Opportunity>{oppOne, oppTwo, oppThree};
        (new GS_OpportunityPrepopulationService()).runBeforeInsertService(oppList, (new GS_OpportunityCacheService()));
        Test.stopTest();

        Id shippingAddressId = [SELECT Id FROM Shipping_Address__c WHERE Shipping_Zip_Code__c = '94105' LIMIT 1].Id;
        Id secondAccountId = [SELECT Id FROM Account WHERE Name = :SECOND_ACCOUNT_NAME].Id; 
        // Data from Contracts on opp1
        System.assertEquals('Net 15', oppOne.Payment_Terms__c);
        System.assertEquals(contactOne.Id, oppOne.Shipping_Contact__c);
        System.assertEquals(accountOne.Id, oppOne.Reseller__c);
        System.assertEquals('Direct Monthly', oppOne.Selected_Payment_Type__c);
        System.assertEquals(shippingAddressId, oppOne.Shipping_Address_NEW__c);
        System.assertEquals(UserInfo.getUserId(), oppOne.Original_AE__c);
        System.assertEquals(10, oppOne.Approved_Discount__c);
        System.assertEquals(true, oppOne.Name.startsWith('Renewal'));

        // Shipping details
        System.assertEquals('United Kingdom', oppOne.Shipping_Country__c);
        System.assertEquals(true, String.isBlank(oppOne.Shipping_State__c));
        System.assertEquals('Non Express', oppOne.Configuration_Segment__c);
        
        
        // Data from Contracts on opp2
        System.assertEquals('Net 15', oppOne.Payment_Terms__c);
        System.assertEquals(contactOne.Id, oppOne.Shipping_Contact__c);
        System.assertEquals(10, oppOne.Approved_Discount__c);
        System.assertEquals('Direct Monthly', oppOne.Selected_Payment_Type__c);

        // Reseller Partner
        System.assertEquals(secondAccountId, oppTwo.Reseller_Partner__c);
    }
}