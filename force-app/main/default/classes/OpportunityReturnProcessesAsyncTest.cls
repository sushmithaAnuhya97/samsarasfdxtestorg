@isTest
public without sharing class OpportunityReturnProcessesAsyncTest {
    
    @IsTest
    static void testAsyncExecution(){

        Account newAccount = createAccount('English', 'newAccount', 'SMB');
        insert newAccount;
        String name = 'Smith';
        Contact contact = new Contact (email = name + '@test.com', LastName = name, AccountId = newAccount.Id);
        insert contact;

        Shipping_Address__c shippingAddress = new Shipping_Address__c();
        shippingAddress.Account__c = newAccount.Id;
        shippingAddress.Shipping_Country__c = 'United States';
        shippingAddress.Name = 'test';
        shippingAddress.Shipping_Contact__c = contact.Id;
        insert shippingAddress;

        Opportunity returnOpp = (Opportunity) TestFactory.createSObject(new Opportunity(
            AccountId = newAccount.Id,
            StageName = 'Return Created',
            Type = 'Exchange',
            Name = 'Promo Opportunity - 123',
            //Returning_Opportunity__c = opp.Id,
            Corresponding_Netsuite_ID__c = '01010101',
            Amount = 0,
            Notes__c = 'Notes',
            Cable_Tool_Activated__c = false,
            Return_Number_Shipping__c = 'RTN-00001',
            Shipping_Address_NEW__c = shippingAddress.Id,
            Zendesk_Ticket_Number__c = '100',
            CurrencyIsoCode = 'USD',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId()
        ), true);

        Test.startTest();
        OpportunityReturnProcessesAsync.Options option = new OpportunityReturnProcessesAsync.Options('CreateShipment', new List<String>{String.valueOf(returnOpp.Id)});
        insert (new OpportunityReturnProcessesAsync()).prepareAsyncRequests(JSON.serialize(option), new Set<Id>{returnOpp.Id});
        Test.stopTest();

        Opportunity promoOpp = [SELECT AccountId, StageName, Cable_Tool_Activated__c, Corresponding_Netsuite_ID__c, CurrencyIsoCode, Return_Number_Shipping__c, Notes__c, Type, Shipping_Address_NEW__c, Zendesk_Ticket_Number__c FROM Opportunity WHERE Name LIKE 'Promo Opportunity - %' LIMIT 1];
        System.assertEquals(false, promoOpp.Cable_Tool_Activated__c);
        //System.assertEquals('Promo Opportunity', promoOpp.Type);
        //System.assertEquals('Purchase', promoOpp.StageName);

        Opportunity startingOpp = [SELECT Replacement_Opportunity__c FROM Opportunity WHERE Id = :returnOpp.Id LIMIT 1];
        //System.assert(String.isNotBlank(startingOpp.Replacement_Opportunity__c));
    }
    
    @IsTest
    static void testShippingAddressChange(){

        Account newAccount = createAccount('English', 'newAccount', 'SMB');
        insert newAccount;
        String name = 'Smith';
        Contact contact = new Contact (email = name + '@test.com', LastName = name, AccountId = newAccount.Id);
        insert contact;

        Shipping_Address__c shippingAddress1 = new Shipping_Address__c();
        shippingAddress1.Account__c = newAccount.Id;
        shippingAddress1.Shipping_Country__c = 'United States';
        shippingAddress1.Name = 'test1';
        shippingAddress1.Shipping_Contact__c = contact.Id;
        insert shippingAddress1;
        
        Shipping_Address__c shippingAddress2 = new Shipping_Address__c();
        shippingAddress2.Account__c = newAccount.Id;
        shippingAddress2.Shipping_Country__c = 'United States';
        shippingAddress2.Name = 'test2';
        shippingAddress2.Shipping_Contact__c = contact.Id;
        insert shippingAddress2;

        Opportunity returnOpp = (Opportunity) TestFactory.createSObject(new Opportunity(
            AccountId = newAccount.Id,
            StageName = 'Return Created',
            Type = 'Exchange',
            Name = 'Promo Opportunity - 123',
            //Returning_Opportunity__c = opp.Id,
            Corresponding_Netsuite_ID__c = '01010101',
            Amount = 0,
            Notes__c = 'Notes',
            Cable_Tool_Activated__c = false,
            Return_Number_Shipping__c = 'RTN-00001',
            Shipping_Address_NEW__c = shippingAddress1.Id,
            Zendesk_Ticket_Number__c = '100',
            CurrencyIsoCode = 'USD',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId()
        ), true);

        Test.startTest();
        OpportunityReturnProcessesAsync.Options option = new OpportunityReturnProcessesAsync.Options('CreateShipment', new List<String>{String.valueOf(returnOpp.Id)});
        insert (new OpportunityReturnProcessesAsync()).prepareAsyncRequests(JSON.serialize(option), new Set<Id>{returnOpp.Id});
        
        returnOpp.Shipping_Address_NEW__c = shippingAddress2.Id;
        update returnOpp;
        Test.stopTest();

        Opportunity promoOpp = [SELECT AccountId, StageName, Cable_Tool_Activated__c, Corresponding_Netsuite_ID__c, CurrencyIsoCode, Return_Number_Shipping__c, Notes__c, Type, Shipping_Address_NEW__c, Zendesk_Ticket_Number__c FROM Opportunity WHERE Name LIKE 'Promo Opportunity - %' LIMIT 1];
        System.assertEquals(false, promoOpp.Cable_Tool_Activated__c);
        //System.assertEquals('Promo Opportunity', promoOpp.Type);
        //System.assertEquals('Purchase', promoOpp.StageName);

        Opportunity startingOpp = [SELECT Replacement_Opportunity__c FROM Opportunity WHERE Id = :returnOpp.Id LIMIT 1];
        //System.assert(String.isNotBlank(startingOpp.Replacement_Opportunity__c));
    }

    public static Account createAccount(String writtenLanguage, String accountName, String segment) {
        Account testAccount = new Account();
        testAccount.Name = accountName;
        testAccount.Industry = 'Biotechnology';
        testAccount.Organization_Size__c = '500 - 999';
        testAccount.BillingStreet = '123 main';
        testAccount.BillingCity = 'Missoula';
        testAccount.BillingState = 'California';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingPostalCode = '59801';
        testAccount.Billing_Email__c = 'foo@bar.com';
        testAccount.Segment_Text_stamped__c = segment;
        testAccount.Approved_Payment_Type__c = 'Direct Monthly';
        testAccount.Which_written_language__c = writtenLanguage;
        return testAccount;
    }
}