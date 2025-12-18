@isTest
public class OpportunityContractReturnBatchTest {

    static Account createAccount() {
        Account account = new Account();
        account.Name = 'MyTestAccount';
        account.Type = 'Fleet';
        account.Industry = 'Other';
        account.organization_size__c = '1 - 99';
        account.billingstreet = '123 Main St, San Francisco CA, 94110';
        account.billingstate = 'California';
        account.billingcountry = 'United States';
        account.billingcity = 'San Francisco';
        account.billingPostalCode = '94110';
        account.shippingstreet = '123 Main St, San Francisco CA, 94110';
        account.shippingstate = 'California';
        account.shippingcountry = 'United States';
        account.shippingcity = 'San Francisco';
        account.shippingPostalCode = '94110';
               
        return account;
    }

    static void satisfyAvalara() {
        
    }

//    static Id getReturnOpportunityRecordTypeId() {
//
//        Id returnOpportunityRecordTypeId = null;
//        for (RecordType rt : [select Id
//                                from RecordType
//                               where SobjectType = 'Opportunity'
//                                 and DeveloperName = :OpportunityContractUtil.RETURN_OPPORTUNITY_RECORD_TYPE_DEVELOPER_NAME
//                                limit 1
//                            ])
//        {
//            returnOpportunityRecordTypeId = rt.Id;
//        }
//        return returnOpportunityRecordTypeId;
//    }

    @isTest
    static void testOpportunityIsRelatedToExistingContract() {

        satisfyAvalara();

//        Id returnOpportunityRecordTypeId = getReturnOpportunityRecordTypeId();
        String validReturnType = OpportunityContractReturnBatch.validTypes.get(0);

        Account account = createAccount();
        insert account;
        
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;

        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        insert contract;

        Opportunity parentOpp = new Opportunity();
        parentOpp.CloseDate = Date.today();
        parentOpp.Name = 'Parent Opp 1';
        parentOpp.StageName = 'Closed Won';
        parentOpp.AccountId = account.Id;
        parentOpp.ContractId = contract.Id;
        parentOpp.Shipping_Contact__c = contact.id;
        insert parentOpp;

        Opportunity returnOpp1 = new Opportunity();
        returnOpp1.CloseDate = Date.today();
        returnOpp1.License_End_Date__c = Date.today();
        returnOpp1.Name = 'My Opp 1';
        returnOpp1.StageName = 'Closed Won';
        returnOpp1.AccountId = account.Id;
        returnOpp1.Returning_Opportunity__c = parentOpp.Id;
        returnOpp1.Shipping_Contact__c = contact.id;
        returnOpp1.License_End_Date_Notes__c = 'Testing';

//        returnOpp1.RecordTypeId = returnOpportunityRecordTypeId;
        returnOpp1.Type = validReturnType;
        insert returnOpp1;

        Opportunity returnOpp2 = new Opportunity();
        returnOpp2.CloseDate = returnOpp1.CloseDate;
        returnOpp2.License_End_Date__c = returnOpp1.License_End_Date__c;
        returnOpp2.Name = 'My Opp 2';
        returnOpp2.StageName = 'Closed Won';
        returnOpp2.AccountId = account.Id;
        returnOpp2.Returning_Opportunity__c = parentOpp.Id;
        returnOpp2.Shipping_Contact__c = contact.id;
        returnOpp2.License_End_Date_Notes__c = 'Testing';

//        returnOpp2.RecordTypeId = returnOpportunityRecordTypeId;
        returnOpp2.Type = validReturnType;
        insert returnOpp2;

        System.Test.startTest();
        OpportunityContractReturnBatch batch = new OpportunityContractReturnBatch();
        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

        returnOpp2 = [select Returning_Opportunity__r.ContractId from Opportunity where Id = :returnOpp2.Id];
        System.assertEquals(contract.Id, returnOpp2.Returning_Opportunity__r.ContractId, 'Opportunity was not related to the Contract of its other Return Opportunity in the same Account');
    }

    @isTest
    static void testOpportunityIsRelatedToNewlyCreatedContract() {

        satisfyAvalara();

//        Id returnOpportunityRecordTypeId = getReturnOpportunityRecordTypeId();
        String validReturnType = OpportunityContractReturnBatch.validTypes.get(0);
        List<Account> newAccounts = new List<Account>();

        Account account = createAccount();
        newAccounts.add(account);
        
        insert newAccounts;
        
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;
        
        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        insert contract;

        Opportunity parentOpp1 = new Opportunity();
        parentOpp1.CloseDate = Date.today();
        parentOpp1.Name = 'Parent Opp 1';
        parentOpp1.StageName = 'Closed Won';
        parentOpp1.AccountId = account.Id;
        parentOpp1.ContractId = contract.Id;
        parentOpp1.Shipping_Contact__c = contact.id;
        insert parentOpp1;
        
        Opportunity opp1 = new Opportunity();
        opp1.CloseDate = Date.today();
        opp1.License_End_Date__c = Date.today();
        opp1.Name = 'My Opp 1';
        opp1.StageName = 'Refunded - Closed';
        opp1.AccountId = account.Id;
        opp1.Returning_Opportunity__c = parentOpp1.Id;
        opp1.License_End_Date_Notes__c = 'Testing';
//        opp1.RecordTypeId = returnOpportunityRecordTypeId;
        opp1.Type = validReturnType;
        opp1.Shipping_Contact__c = contact.id;        
        insert opp1;

        Opportunity opp2 = new Opportunity();
        opp2.CloseDate = opp1.CloseDate;
        opp2.License_End_Date__c = opp1.License_End_Date__c;
        opp2.Name = 'My Opp 2';
        opp2.StageName = 'Refunded - Closed';
        opp2.AccountId = account.Id;
        opp2.Returning_Opportunity__c = parentOpp1.Id;
        opp2.License_End_Date_Notes__c = 'Testing';
//        opp2.RecordTypeId = returnOpportunityRecordTypeId;
        opp2.Type = validReturnType;
        opp2.Shipping_Contact__c = contact.id;        
        insert opp2;
        

        System.Test.startTest();
        OpportunityContractReturnBatch batch = new OpportunityContractReturnBatch();
        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

        opp1 = [select Returning_Opportunity__r.ContractId from Opportunity where Id = :opp1.Id];
        System.assertNotEquals(null, opp1.Returning_Opportunity__r.ContractId, 'Opportunity was not created');

        opp2 = [select Returning_Opportunity__r.ContractId from Opportunity where Id = :opp2.Id];
        System.assertEquals(opp1.Returning_Opportunity__r.ContractId, opp2.Returning_Opportunity__r.ContractId, 'Opportunity was not related to the newly created Contract of its other Return Opportunity in the same Account');
    }
    
    @isTest
    static void testOpportunityIsRelatedToNewlyCreatedContractForCoverage() {

        satisfyAvalara();

//        Id returnOpportunityRecordTypeId = getReturnOpportunityRecordTypeId();
        String validReturnType = OpportunityContractReturnBatch.validTypes.get(0);

        Account account = createAccount();
        insert account;

        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;

        Opportunity parentOpp1 = new Opportunity();
        parentOpp1.CloseDate = Date.today();
        parentOpp1.Name = 'Parent Opp 1';
        parentOpp1.StageName = 'Closed Won';
        parentOpp1.AccountId = account.Id;
        parentOpp1.License_End_Date_Notes__c = 'Testing';
        parentOpp1.Shipping_Contact__c = contact.id;        
        insert parentOpp1;

        Opportunity opp1 = new Opportunity();
        opp1.CloseDate = Date.today();
        opp1.License_End_Date__c = Date.today();
        opp1.Name = 'My Opp 1';
        opp1.StageName = 'Refunded - Closed';
        opp1.AccountId = account.Id;
        opp1.Returning_Opportunity__c = parentOpp1.Id;
//        opp1.RecordTypeId = returnOpportunityRecordTypeId;
        opp1.Type = validReturnType;
        opp1.License_End_Date_Notes__c = 'Testing';
        opp1.Shipping_Contact__c = contact.id;      
        insert opp1;

        Opportunity opp2 = new Opportunity();
        opp2.CloseDate = opp1.CloseDate;
        opp2.License_End_Date__c = opp1.License_End_Date__c;
        opp2.Name = 'My Opp 2';
        opp2.StageName = 'Refunded - Closed';
        opp2.AccountId = account.Id;
        opp2.Returning_Opportunity__c = parentOpp1.Id;
//        opp2.RecordTypeId = returnOpportunityRecordTypeId;
        opp2.Type = validReturnType;
        opp2.License_End_Date_Notes__c = 'Testing';
        opp2.Shipping_Contact__c = contact.id;     
        insert opp2;

        System.Test.startTest();
        OpportunityContractReturnBatch batch = new OpportunityContractReturnBatch();
        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

    }


}