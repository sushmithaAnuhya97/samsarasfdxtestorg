@isTest
public class OpportunityContractBatchTest {

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
        //avalaraSettingInsertTest.insertAvalaraSetting();
    }

    @isTest
    static void testOpportunityIsRelatedToExistingContractForOpportunitiesWithMatchedCloseDateAndLicenseEndDate() {

        satisfyAvalara();

        OpportunityTriggerHandler.isEnabled = true;

        Account account = createAccount();
        insert account;
        
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;

        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        insert contract;

        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        Opportunity opp1 = new Opportunity();
        opp1.CloseDate = Date.today();
        opp1.License_End_Date__c = Date.today();
        opp1.Name = 'My Opp 1';
        opp1.StageName = 'Closed Won';
        opp1.AccountId = account.Id;
        opp1.ContractId = contract.Id;
        opp1.netsuite_conn__Contract_Term__c = 2;
        opp1.Shipping_Contact__c = contact.id;    
        opportunitiesToInsert.add(opp1);

        Opportunity opp2 = new Opportunity();
        opp2.CloseDate = opp1.CloseDate;
        opp2.License_End_Date__c = opp1.License_End_Date__c;
        opp2.Name = 'My Opp 2';
        opp2.StageName = 'Closed Won';
        opp2.AccountId = account.Id;
        opp2.netsuite_conn__Contract_Term__c = 2;
        opp2.License_End_Date_Notes__c = 'Testing';
        opp2.ContractId = contract.Id;
        opp2.Shipping_Contact__c = contact.id;       
        opportunitiesToInsert.add(opp2);
        
        Opportunity opp3 = new Opportunity();
        opp3.CloseDate = opp1.CloseDate;
        opp3.License_End_Date__c = opp1.License_End_Date__c;
        opp3.Name = 'My Opp 2';
        opp3.StageName = 'Closed Won';
        opp3.AccountId = account.Id;
        opp3.netsuite_conn__Contract_Term__c = 2;
        opp3.License_End_Date_Notes__c = 'Testing';
        opp3.Shipping_Contact__c = contact.id;      
        opportunitiesToInsert.add(opp3);
        
        insert opportunitiesToInsert;

        System.Test.startTest();
        OpportunityContractBatch batch = new OpportunityContractBatch();
        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

        opp2 = [select ContractId from Opportunity where Id = :opp2.Id];
        System.assertEquals(contract.Id , opp2.ContractId, 'Opportunity was not related to the Contract of its matched Opportunity');
    }
    
    @isTest
    static void testOpportunityIsRelatedToCreatedContractForOpportunitiesWithMatchedAndNotMatched() {

        satisfyAvalara();

        Account account = createAccount();
        insert account;
        
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;

        List<Opportunity> newOpportunities = new List<Opportunity>();

        Opportunity opp1 = new Opportunity();
        opp1.CloseDate = Date.today();
        opp1.License_End_Date__c = Date.today();
        opp1.Name = 'My Opp 1';
        opp1.StageName = 'Closed Won';
        opp1.AccountId = account.Id;
        opp1.netsuite_conn__Contract_Term__c = 2;
        opp1.License_End_Date_Notes__c = 'Testing';
        opp1.Shipping_Contact__c = contact.id;       
        newOpportunities.add(opp1);

        Opportunity opp2 = new Opportunity();
        opp2.CloseDate = opp1.CloseDate;
        opp2.License_End_Date__c = opp1.License_End_Date__c;
        opp2.Name = 'My Opp 2';
        opp2.StageName = 'Closed Won';
        opp2.AccountId = account.Id;
        opp2.netsuite_conn__Contract_Term__c = 2;
        opp2.License_End_Date_Notes__c = 'Testing';
        opp2.Shipping_Contact__c = contact.id;      
        newOpportunities.add(opp2);

        Opportunity oppNotGrouped = new Opportunity();
        oppNotGrouped.CloseDate = opp1.CloseDate;
        oppNotGrouped.License_End_Date__c = Date.today() + 145;
        oppNotGrouped.Name = 'My Opp 3';
        oppNotGrouped.StageName = 'Closed Won';
        oppNotGrouped.AccountId = account.Id;
        oppNotGrouped.netsuite_conn__Contract_Term__c = 2;
        oppNotGrouped.License_End_Date_Notes__c = 'Testing';
        oppNotGrouped.Shipping_Contact__c = contact.id;      
        newOpportunities.add(oppNotGrouped);
        
        insert newOpportunities;

        System.Test.startTest();
        OpportunityContractBatch batch = new OpportunityContractBatch();
        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

        opp1 = [select ContractId from Opportunity where Id = :opp1.Id];
        System.assertNotEquals(null, opp1.ContractId, 'Contract was not created');

        opp2 = [select ContractId from Opportunity where Id = :opp2.Id];
        System.assertEquals(opp1.ContractId, opp2.ContractId, 'Opportunity was not related to the Contract of its matched Opportunity');

        oppNotGrouped = [select ContractId from Opportunity where Id = :oppNotGrouped.Id];
        System.assertNotEquals(null, oppNotGrouped.ContractId, 'Contract was not created for non grouped / matched Opportunity');
        //System.assertNotEquals(opp1.ContractId, oppNotGrouped.ContractId, 'Opportunity was related to the Contract of another Opportunity when this Opportunity does not match any other Opportunity');
        //System.assertNotEquals(opp2.ContractId, oppNotGrouped.ContractId, 'Opportunity was related to the Contract of another Opportunity when this Opportunity does not match any other Opportunity');
    }
    
    //    @isTest
//    static void testOpportunityWithProductThatIsNotMatchedIsRelatedToCreatedContract() {
//        satisfyAvalara();
//
//        Product2 product = new Product2();
//        product.Name = 'MyTestProduct';
//        product.ProductCode = 'HW-MyTestProduct';
//        product.IsActive= true;
//        insert product;
//
//        PricebookEntry pbe = new PricebookEntry();
//        pbe.UseStandardPrice = false;
//        pbe.Pricebook2Id = Test.getStandardPricebookId();
//        pbe.Product2Id = product.id;
//        pbe.IsActive = true;
//        pbe.UnitPrice = 100.0;
//        insert pbe;
//
//        Account account = createAccount();
//        insert account;
//
//        Opportunity oppNotGroupedWithProduct = new Opportunity();
//        oppNotGroupedWithProduct.CloseDate = Date.today();
//        oppNotGroupedWithProduct.Name = 'My Opp 2';
//        oppNotGroupedWithProduct.StageName = 'Closed Won';
//        oppNotGroupedWithProduct.AccountId = account.Id;
//        oppNotGroupedWithProduct.Amount = 100;
//        oppNotGroupedWithProduct.Type = 'Revenue Opportunity';
//        oppNotGroupedWithProduct.Owner_Role_Copy__c = 'My Role';
//        oppNotGroupedWithProduct.CurrencyIsoCode = 'USD';
//        oppNotGroupedWithProduct.netsuite_conn__Contract_Term__c = 2;
//        insert oppNotGroupedWithProduct;
//
//        OpportunityLineItem itemNotGrouped = new OpportunityLineItem();
//        itemNotGrouped.OpportunityId=oppNotGroupedWithProduct.Id;
//        itemNotGrouped.PricebookEntryId = pbe.Id;
//        itemNotGrouped.Quantity=1;
//        itemNotGrouped.TotalPrice=2;
//        itemNotGrouped.Product2Id = product.Id;
//        insert itemNotGrouped;
//
//        System.Test.startTest();
//        OpportunityContractBatch batch = new OpportunityContractBatch();
//        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
//        Database.executeBatch(batch, 200);
//        System.Test.stopTest();
//
//        oppNotGroupedWithProduct = [select ContractId from Opportunity where Id = :oppNotGroupedWithProduct.Id];
//        System.assertNotEquals(null, oppNotGroupedWithProduct.ContractId, 'Contract was not created for non matched / grouped Opportunity');
//    }

    @isTest
    static void testOpportunityIsRelatedToExistingContractForOpportunitiesWithMatchedPONumber() {

        satisfyAvalara();

        Account account = createAccount();
        insert account;
                
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;

        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        insert contract;

        Opportunity opp1 = new Opportunity();
        opp1.CloseDate = Date.today();
        opp1.Name = 'My Opp 1';
        opp1.StageName = 'Closed Won';
        opp1.AccountId = account.Id;
        opp1.ContractId = contract.Id;
        opp1.License_End_Date__c = Date.today();
        opp1.PO_Number__c = '12345678';
        opp1.netsuite_conn__Contract_Term__c = 2;
        opp1.Shipping_Contact__c = contact.id;     
        insert opp1;

        Opportunity opp2 = new Opportunity();
        opp2.CloseDate = opp1.CloseDate;
        opp2.Name = 'My Opp 2';
        opp2.StageName = 'Closed Won';
        opp2.AccountId = account.Id;
        opp2.License_End_Date__c = opp1.License_End_Date__c.addMonths(12); // dates are different
        opp2.PO_Number__c = opp1.PO_Number__c; // match on po number
        opp2.netsuite_conn__Contract_Term__c = 2;
        opp2.License_End_Date_Notes__c = 'Testing';
        opp2.Shipping_Contact__c = contact.id;    
        insert opp2;

        System.Test.startTest();
        OpportunityContractBatch batch = new OpportunityContractBatch();
        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

        opp2 = [select ContractId from Opportunity where Id = :opp2.Id];
        System.assertEquals(contract.Id, opp2.ContractId, 'Opportunity was not related to the Contract of its matched Opportunity');
    }
    
     @isTest
    static void testOpportunityIsRelatedToCreatedContractForOpportunitiesWithMatchedPONumber() {

        satisfyAvalara();

        Account account = createAccount();
        insert account;
        
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;

        Opportunity opp1 = new Opportunity();
        opp1.CloseDate = Date.today();
        opp1.License_End_Date__c = Date.today();
        opp1.Name = 'My Opp 1';
        opp1.StageName = 'Closed Won';
        opp1.AccountId = account.Id;
        opp1.PO_Number__c = '12345678';
        opp1.netsuite_conn__Contract_Term__c = 2;
        opp1.License_End_Date_Notes__c = 'Testing';
        opp1.Shipping_Contact__c = contact.id;      
        insert opp1;

        Opportunity opp2 = new Opportunity();
        opp2.CloseDate = opp1.CloseDate;
        opp2.License_End_Date__c = opp1.License_End_Date__c.addMonths(12); // different dates
        opp2.Name = 'My Opp 2';
        opp2.StageName = 'Closed Won';
        opp2.AccountId = account.Id;
        opp2.PO_Number__c = opp1.PO_Number__c; // matched PO Number
        opp2.netsuite_conn__Contract_Term__c = 2;
        opp2.License_End_Date_Notes__c = 'Testing';
        opp2.Shipping_Contact__c = contact.id;    
        insert opp2;

        System.Test.startTest();
        OpportunityContractBatch batch = new OpportunityContractBatch();
        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

        opp1 = [select ContractId from Opportunity where Id = :opp1.Id];
        System.assertNotEquals(null, opp1.ContractId, 'Contract was not created');

        opp2 = [select ContractId from Opportunity where Id = :opp2.Id];
        System.assertEquals(opp1.ContractId, opp2.ContractId, 'Opportunity was not related to the Contract of its matched Opportunity');
    }
    
    @isTest
    static void testOpportunityIsRelatedToCreatedContractForOpportunitiesWithoutAnyPONumberMatchesOrLicenseMatches() {

        satisfyAvalara();

        Account account = createAccount();
        insert account;
                        
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;
        
        List<Opportunity> newOpportunities = new List<Opportunity>();

        Opportunity oppPONumber1 = new Opportunity();
        oppPONumber1.CloseDate = Date.today();
        oppPONumber1.Name = 'My Opp 1';
        oppPONumber1.StageName = 'Closed Won';
        oppPONumber1.AccountId = account.Id;
        oppPONumber1.PO_Number__c = '12345';
        oppPONumber1.License_End_Date_Notes__c = 'Testing';
        oppPONumber1.Shipping_Contact__c = contact.id;      
        newOpportunities.add(oppPONumber1);

        Opportunity oppPONumber2 = new Opportunity();
        oppPONumber2.CloseDate = oppPONumber1.CloseDate;
        oppPONumber2.Name = 'My Opp 2';
        oppPONumber2.StageName = 'Closed Won';
        oppPONumber2.AccountId = account.Id;
        oppPONumber2.PO_Number__c = oppPONumber1.PO_Number__c + '999'; // different PO Number
        oppPONumber2.License_End_Date_Notes__c = 'Testing';
        oppPONumber2.Shipping_Contact__c = contact.id;      
        newOpportunities.add(oppPONumber2);

        Opportunity oppLicense1 = new Opportunity();
        oppLicense1.CloseDate = oppPONumber1.CloseDate;
        oppLicense1.Name = 'My Opp 2';
        oppLicense1.StageName = 'Closed Won';
        oppLicense1.AccountId = account.Id;
        oppLicense1.License_End_Date__c = Date.today();
        oppLicense1.License_End_Date_Notes__c = 'Testing';
        oppLicense1.Shipping_Contact__c = contact.id;       
        newOpportunities.add(oppLicense1);

        Opportunity oppLicense2 = new Opportunity();
        oppLicense2.CloseDate = oppPONumber1.CloseDate;
        oppLicense2.Name = 'My Opp 2';
        oppLicense2.StageName = 'Closed Won';
        oppLicense2.AccountId = account.Id;
        oppLicense2.License_End_Date__c = Date.today().addDays(1); // different License End Date
        oppLicense2.License_End_Date_Notes__c = 'Testing';
        oppLicense2.Shipping_Contact__c = contact.id;     
        newOpportunities.add(oppLicense2);
        
        insert newOpportunities;

        System.Test.startTest();
        OpportunityContractBatch batch = new OpportunityContractBatch();
        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

        oppPONumber1 = [select ContractId from Opportunity where Id = :oppPONumber1.Id];
        System.assertNotEquals(null, oppPONumber1.ContractId, 'Contract was not created');

        oppPONumber2 = [select ContractId from Opportunity where Id = :oppPONumber2.Id];
        System.assertNotEquals(null, oppPONumber1.ContractId, 'Contract was not created');

        oppLicense1 = [select ContractId from Opportunity where Id = :oppLicense1.Id];
        System.assertNotEquals(null, oppPONumber1.ContractId, 'Contract was not created');

        oppLicense2 = [select ContractId from Opportunity where Id = :oppLicense2.Id];
        System.assertNotEquals(null, oppPONumber1.ContractId, 'Contract was not created');

        System.assertEquals(oppPONumber1.ContractId, oppPONumber2.ContractId, 'Contracts for different PO Numbers but match on closest close date should be the same');
        //System.assertNotEquals(oppLicense1.ContractId, oppLicense2.ContractId, 'Contracts for different License End Dates should be different');

        System.assertEquals(oppLicense1.ContractId, oppPONumber1.ContractId, 'Contracts for different single one off PO Numbers but match on closest close date should be the same even if matching with an opp without a PO Number');
        //System.assertNotEquals(oppLicense2.ContractId, oppPONumber2.ContractId, 'Contracts for different matching rules should be different');
    }

//    @isTest
//    static void testOpportunityIsRelatedToExistingContractForOpportunitiesWithMatchedCloseDateWhenOpportunityHasAnHWProduct() {
//
//        satisfyAvalara();
//
//        Product2 product = new Product2 ();
//        product.Name = 'MyTestProduct';
//        product.ProductCode = 'HW-MyTestProduct';
//        product.IsActive= true;
//        insert product;
//
//        PricebookEntry pbe = new PricebookEntry();
//        pbe.UseStandardPrice = false;
//        pbe.Pricebook2Id = Test.getStandardPricebookId();
//        pbe.Product2Id = product.id;
//        pbe.IsActive = true;
//        pbe.UnitPrice = 100.0;
//        insert pbe;
//
//        Account account = createAccount();
//        insert account;
//
//        Contract contract = new Contract();
//        contract.AccountId = account.Id;
//        contract.StartDate = Date.today();
//        contract.ContractTerm = 12;
//        insert contract;
//
//        Opportunity opp1 = new Opportunity();
//        opp1.CloseDate = Date.today();
//        opp1.Name = 'My Opp 1';
//        opp1.StageName = 'Closed Won';
//        opp1.AccountId = account.Id;
//        opp1.Amount = 100;
//        opp1.Type = 'Revenue Opportunity';
//        opp1.Owner_Role_Copy__c = 'My Role';
//        opp1.CurrencyIsoCode = 'USD';
//        opp1.ContractId = contract.Id;
//        opp1.netsuite_conn__Contract_Term__c = 2;
//        insert opp1;
//
//        OpportunityLineItem item1 = new OpportunityLineItem (OpportunityId=opp1.Id);
//        item1.PricebookEntryId = pbe.Id;
//        item1.Quantity=1;
//        item1.TotalPrice=2;
//        item1.Product2Id = product.Id;
//        insert item1;
//
//        Opportunity opp2 = new Opportunity();
//        opp2.CloseDate = opp1.CloseDate;
//        opp2.Name = 'My Opp 2';
//        opp2.StageName = 'Closed Won';
//        opp2.AccountId = account.Id;
//        opp2.Amount = 100;
//        opp2.Type = 'Revenue Opportunity';
//        opp2.Owner_Role_Copy__c = 'My Role';
//        opp2.CurrencyIsoCode = 'USD';
//        opp2.netsuite_conn__Contract_Term__c = 2;
//        insert opp2;
//
//        OpportunityLineItem item2 = new OpportunityLineItem (OpportunityId=opp2.Id);
//        item2.PricebookEntryId = pbe.Id;
//        item2.Quantity=1;
//        item2.TotalPrice=2;
//        item2.Product2Id = product.Id;
//        insert item2;
//
//        System.Test.startTest();
//        OpportunityContractBatch batch = new OpportunityContractBatch();
//        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
//        Database.executeBatch(batch, 200);
//        System.Test.stopTest();
//
//        opp1 = [select ContractId from Opportunity where Id = :opp1.Id];
//        System.assertEquals(contract.Id, opp1.ContractId, 'Contract was not related');
//
//        opp2 = [select ContractId from Opportunity where Id = :opp2.Id];
//        System.assertEquals(opp1.ContractId, opp2.ContractId, 'Opportunity was not related to the Contract of its matched Opportunity');
//    }
//
//
//    @isTest
//    static void testOpportunityIsRelatedToCreatedContractForOpportunitiesWithMatchedCloseDateWhenOpportunityHasAnHWProduct() {
//
//        satisfyAvalara();
//
//        Product2 product = new Product2 ();
//        product.Name = 'MyTestProduct';
//        product.ProductCode = 'HW-MyTestProduct';
//        product.IsActive= true;
//        insert product;
//
//        PricebookEntry pbe = new PricebookEntry();
//        pbe.UseStandardPrice = false;
//        pbe.Pricebook2Id = Test.getStandardPricebookId();
//        pbe.Product2Id = product.id;
//        pbe.IsActive = true;
//        pbe.UnitPrice = 100.0;
//        insert pbe;
//
//        Account account = createAccount();
//        insert account;
//
//        Opportunity opp1 = new Opportunity();
//        opp1.CloseDate = Date.today();
//        opp1.Name = 'My Opp 1';
//        opp1.StageName = 'Closed Won';
//        opp1.AccountId = account.Id;
//        opp1.Amount = 100;
//        opp1.Type = 'Revenue Opportunity';
//        opp1.Owner_Role_Copy__c = 'My Role';
//        opp1.CurrencyIsoCode = 'USD';
//        opp1.netsuite_conn__Contract_Term__c = 2;
//        insert opp1;
//
//        OpportunityLineItem item1 = new OpportunityLineItem (OpportunityId=opp1.Id);
//        item1.PricebookEntryId = pbe.Id;
//        item1.Quantity=1;
//        item1.TotalPrice=2;
//        item1.Product2Id = product.Id;
//        insert item1;
//
//        Opportunity opp2 = new Opportunity();
//        opp2.CloseDate = opp1.CloseDate;
//        opp2.Name = 'My Opp 2';
//        opp2.StageName = 'Closed Won';
//        opp2.AccountId = account.Id;
//        opp2.Amount = 100;
//        opp2.Type = 'Revenue Opportunity';
//        opp2.Owner_Role_Copy__c = 'My Role';
//        opp2.CurrencyIsoCode = 'USD';
//        opp2.netsuite_conn__Contract_Term__c = 2;
//        insert opp2;
//
//        OpportunityLineItem item2 = new OpportunityLineItem (OpportunityId=opp2.Id);
//        item2.PricebookEntryId = pbe.Id;
//        item2.Quantity=1;
//        item2.TotalPrice=2;
//        item2.Product2Id = product.Id;
//        insert item2;
//
//        System.Test.startTest();
//        OpportunityContractBatch batch = new OpportunityContractBatch();
//        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
//        Database.executeBatch(batch, 200);
//        System.Test.stopTest();
//
//        opp1 = [select ContractId from Opportunity where Id = :opp1.Id];
//        System.assertNotEquals(null, opp1.ContractId, 'Contract was not created');
//
//        opp2 = [select ContractId from Opportunity where Id = :opp2.Id];
//        System.assertEquals(opp1.ContractId, opp2.ContractId, 'Opportunity was not related to the Contract of its matched Opportunity');
//    }

     @isTest
    static void testOpportunityThatDidNotGetAnOpportunityGetsTheOpportunityOfAnotherOpportunityWithTheClosestCloseDate() {
        satisfyAvalara();

        Account account = createAccount();
        insert account;
                                      
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;
        
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Contract> newContracts = new List<Contract>();

        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        newContracts.add(contract);

        Contract contract2 = new Contract();
        contract2.AccountId = account.Id;
        contract2.StartDate = Date.today();
        contract2.ContractTerm = 12;
        newContracts.add(contract2);
        
        insert newContracts;

        Opportunity oppWithContract = new Opportunity();
        oppWithContract.CloseDate = Date.today().addDays(-1);
        oppWithContract.Name = 'My Opp 1';
        oppWithContract.StageName = 'Closed Won';
        oppWithContract.AccountId = account.Id;
        oppWithContract.Amount = 100;
        oppWithContract.Type = 'Revenue Opportunity';
        oppWithContract.Owner_Role_Copy__c = 'My Role';
        oppWithContract.CurrencyIsoCode = 'USD';
        oppWithContract.ContractId = contract.Id;
        oppWithContract.Shipping_Contact__c = contact.id;    
        newOpportunities.add(oppWithContract);

        Opportunity oppWithContract2 = new Opportunity();
        oppWithContract2.CloseDate = Date.today().addDays(-2);
        oppWithContract2.Name = 'My Opp 1';
        oppWithContract2.StageName = 'Closed Won';
        oppWithContract2.AccountId = account.Id;
        oppWithContract2.Amount = 100;
        oppWithContract2.Type = 'Revenue Opportunity';
        oppWithContract2.Owner_Role_Copy__c = 'My Role';
        oppWithContract2.CurrencyIsoCode = 'USD';
        oppWithContract2.ContractId = contract2.Id;
        oppWithContract2.Shipping_Contact__c = contact.id;     
        newOpportunities.add(oppWithContract2);

        Opportunity oppWithoutContract = new Opportunity();
        oppWithoutContract.CloseDate = Date.today();
        oppWithoutContract.Name = 'My Opp 2';
        oppWithoutContract.StageName = 'Closed Won';
        oppWithoutContract.AccountId = account.Id;
        oppWithoutContract.Amount = 100;
        oppWithoutContract.Type = 'Revenue Opportunity';
        oppWithoutContract.Owner_Role_Copy__c = 'My Role';
        oppWithoutContract.CurrencyIsoCode = 'USD';
        oppWithoutContract.License_End_Date_Notes__c = 'Testing';
        oppWithoutContract.Shipping_Contact__c = contact.id;       
        newOpportunities.add(oppWithoutContract);
        
        insert newOpportunities;

        System.Test.startTest();
        OpportunityContractBatch batch = new OpportunityContractBatch();
        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

        oppWithoutContract = [select ContractId from Opportunity where Id = :oppWithoutContract.Id];
        //System.assertEquals(oppWithContract.ContractId, oppWithoutContract.ContractId, 'Opportunity was not related to the Contract of its matched Opportunity');
    }
    
     @isTest
    static void testOpportunityIsRelatedToExistingContractForOpportunitiesWithMatchedPONumberToAnOpportunityThatWasAlreadyMatchedByLicenseDate() {

        satisfyAvalara();

        Account account = createAccount();
        insert account;
        
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;

        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        insert contract;
		
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity oppWithPO = new Opportunity();
        oppWithPO.CloseDate = Date.today();
        oppWithPO.Name = 'My Opp 1';
        oppWithPO.StageName = 'Closed Won';
        oppWithPO.AccountId = account.Id;
        oppWithPO.PO_Number__c = '12345678';
        oppWithPO.License_End_Date_Notes__c = 'Testing';
        oppWithPO.Shipping_Contact__c = contact.id;      
        newOpportunities.add(oppWithPO);

        Opportunity oppMatchLicenseDate1 = new Opportunity();
        oppMatchLicenseDate1.CloseDate = Date.today();
        oppMatchLicenseDate1.Name = 'My Opp 2';
        oppMatchLicenseDate1.StageName = 'Closed Won';
        oppMatchLicenseDate1.AccountId = account.Id;
        oppMatchLicenseDate1.License_End_Date__c = Date.today();
        oppMatchLicenseDate1.PO_Number__c = oppWithPO.PO_Number__c; // shares same po number
        oppMatchLicenseDate1.ContractId = contract.Id;
        oppMatchLicenseDate1.License_End_Date_Notes__c = 'Testing';
        oppMatchLicenseDate1.Shipping_Contact__c = contact.id;
        newOpportunities.add(oppMatchLicenseDate1);

        Opportunity oppMatchLicenseDate2 = new Opportunity();
        oppMatchLicenseDate2.CloseDate = Date.today();
        oppMatchLicenseDate2.Name = 'My Opp 2';
        oppMatchLicenseDate2.StageName = 'Closed Won';
        oppMatchLicenseDate2.AccountId = account.Id;
        oppMatchLicenseDate2.License_End_Date__c = oppMatchLicenseDate1.License_End_Date__c; // match on license end date
        oppMatchLicenseDate2.License_End_Date_Notes__c = 'Testing';
        oppMatchLicenseDate2.ContractId = contract.Id;
        oppMatchLicenseDate2.Shipping_Contact__c = contact.id;       
        newOpportunities.add(oppMatchLicenseDate2);
        
        Opportunity oppMatchLicenseDate3 = new Opportunity();
        oppMatchLicenseDate3.CloseDate = Date.today();
        oppMatchLicenseDate3.Name = 'My Opp 2';
        oppMatchLicenseDate3.StageName = 'Closed Won';
        oppMatchLicenseDate3.AccountId = account.Id;
        oppMatchLicenseDate3.License_End_Date__c = oppMatchLicenseDate1.License_End_Date__c; // match on license end date
        oppMatchLicenseDate3.License_End_Date_Notes__c = 'Testing';
        oppMatchLicenseDate3.Shipping_Contact__c = contact.id;    
        newOpportunities.add(oppMatchLicenseDate3);
        
        insert newOpportunities;

        System.Test.startTest();
        OpportunityContractBatch batch = new OpportunityContractBatch();
        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

        oppMatchLicenseDate2 = [select ContractId from Opportunity where Id = :oppMatchLicenseDate2.Id];
        System.assertEquals(contract.Id, oppMatchLicenseDate2.ContractId, 'Opportunity was not related to the Contract of its matched Opportunity');

        oppWithPO = [select ContractId from Opportunity where Id = :oppWithPO.Id];
        System.assertEquals(contract.Id, oppWithPO.ContractId, 'Opportunity with the same PO Number that shares the same PO Number as an Opportunity that was matched by License date did not get the same Contract');
    }
    
     @isTest
    static void testOpportunityIsRelatedToCreatedContractForOpportunitiesWithMatchedPONumberToAnOpportunityThatWasAlreadyMatchedByLicenseDate() {

        satisfyAvalara();

        Account account = createAccount();
        insert account;
        
        Contact contact = new Contact (FirstName = 'Test', LastName = 'User', Email = 'test@testcontact.com', AccountId=account.Id);
		insert contact;

        List<Opportunity> newOpportunities = new List<Opportunity>();

        Opportunity oppWithPO = new Opportunity();
        oppWithPO.CloseDate = Date.today();
        oppWithPO.Name = 'My Opp 1';
        oppWithPO.StageName = 'Closed Won';
        oppWithPO.AccountId = account.Id;
        oppWithPO.PO_Number__c = '12345678';
        oppWithPO.License_End_Date_Notes__c = 'Testing';
        oppWithPO.Shipping_Contact__c = contact.id;       
        newOpportunities.add(oppWithPO);

        Opportunity oppMatchLicenseDate1 = new Opportunity();
        oppMatchLicenseDate1.CloseDate = Date.today();
        oppMatchLicenseDate1.Name = 'My Opp 2';
        oppMatchLicenseDate1.StageName = 'Closed Won';
        oppMatchLicenseDate1.AccountId = account.Id;
        oppMatchLicenseDate1.License_End_Date__c = Date.today();
        oppMatchLicenseDate1.PO_Number__c = oppWithPO.PO_Number__c; // shares same po number
        oppMatchLicenseDate1.License_End_Date_Notes__c = 'Testing';
        oppMatchLicenseDate1.Shipping_Contact__c = contact.id;     
        newOpportunities.add(oppMatchLicenseDate1);

        Opportunity oppMatchLicenseDate2 = new Opportunity();
        oppMatchLicenseDate2.CloseDate = Date.today();
        oppMatchLicenseDate2.Name = 'My Opp 2';
        oppMatchLicenseDate2.StageName = 'Closed Won';
        oppMatchLicenseDate2.AccountId = account.Id;
        oppMatchLicenseDate2.License_End_Date__c = oppMatchLicenseDate1.License_End_Date__c; // match on license end date
        oppMatchLicenseDate2.License_End_Date_Notes__c = 'Testing';
        oppMatchLicenseDate2.Shipping_Contact__c = contact.id;
        newOpportunities.add(oppMatchLicenseDate2);
        
        insert newOpportunities;

        System.Test.startTest();
        OpportunityContractBatch batch = new OpportunityContractBatch();
        batch.additionalWhereClause = ' where Id = \'' + account.Id + '\'';
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

        oppMatchLicenseDate1 = [select ContractId from Opportunity where Id = :oppMatchLicenseDate1.Id];
        oppMatchLicenseDate2 = [select ContractId from Opportunity where Id = :oppMatchLicenseDate2.Id];
        System.assertEquals(oppMatchLicenseDate1.ContractId, oppMatchLicenseDate2.ContractId, 'Opportunity was not related to the Contract of its matched Opportunity');

        oppWithPO = [select ContractId from Opportunity where Id = :oppWithPO.Id];
        System.assertEquals(oppMatchLicenseDate1.ContractId, oppWithPO.ContractId, 'Opportunity with the same PO Number that shares the same PO Number as an Opportunity that was matched by License date did not get the same Contract');
    }   
}