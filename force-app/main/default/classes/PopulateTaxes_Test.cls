/**
* Created By : 
* @Date September 2, 2022
*
* @description : This class will be responsible for the test coverage for PopulateTaxes
*
* Modification History:
* Date          Author              Story/Defect            Description
* 2022-04-08    Rodrigo Carpio      GTMS-7293               Initial Draft
**/
@isTest
public class PopulateTaxes_Test {
    Static Account testAccount;
    Static Opportunity testOpportunity;
    
    @testSetup
    private static void testDataSetup() {
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        
        insert pricebookEntries;
        
        // Create account
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        newAccount.add(account);
        
        insert newAccount;

        Contract cont = new Contract(
            AccountId = newAccount[0].Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Status = 'Draft'
        );
        insert cont;
        cont.Status = 'Activated';
        update cont;
        
        // Create Contact
        List<Contact> newContacts = new List<Contact>();
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=account.Id);
        newContacts.add(contact);
        
        insert newContacts;
        
        //Create Shipping Address
        List<Shipping_Address__c> shippingAddresses = new  List<Shipping_Address__c>();
        
        Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                            , Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                            , Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
        shippingAddresses.add(shipTo);        
        
        Shipping_Address__c shipToTwo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '610 Park View Dr'
                                                            , Shipping_Address_Line_2__c= 'XYZ', Shipping_City__c = 'Santa Clara'
                                                            , Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                            , Shipping_Zip_Code__c = '95054', Name = 'Ship To Two');
        
        shippingAddresses.add(shipToTwo);   
        
        Shipping_Address__c shipToThree = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '1 Parliment St'
                                                            , Shipping_City__c = 'London'
                                                            , Shipping_Country__c ='United Kingdom'
                                                            , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Three');
        
        shippingAddresses.add(shipToThree);
        
        Shipping_Address__c shipToFour = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '1 Parliment St'
                                                            , Shipping_Address_Line_2__c= 'XYZ'
                                                            , Shipping_City__c = 'London'
                                                            , Shipping_Country__c ='United Kingdom'
                                                            , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Four');
        
        shippingAddresses.add(shipToFour);
        
        insert shippingAddresses;
            
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate');            
        newOpportunities.add(revenueOpportunity);
        insert newOpportunities;
    }
    
    @isTest 
    static void populateVertexTaxesTest(){
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Three'];
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id, Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id, VertexCPQ__Tax_Amount__c=5);
        insert quote;
        
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, VertexCPQ__Tax_Amount__c=6);
        insert quoteLineOne; 
        
        /* Set<ID> quotelistIDs = new Set<ID>();
        Map<String, Object> responseMap = New Map<String, Object>();
        //List<SBQQ__Quote__c> quotes = [SELECT Id from SBQQ__Quote__c WHERE Quote_Name__c = 'First Quote'];
        for(SBQQ__Quote__c  quoteloc : [select ID, VertexCPQ__Tax_Amount__c from SBQQ__Quote__c where Quote_Name__c = 'Test Version']){
            quotelistIDs.add(quoteloc.id);
            responseMap.put(quoteloc.id, 100);
            
        }
        PopulateTaxes.mockedResponse = JSON.serialize(responseMap);
        PopulateTaxes.populateVertexTaxes(quotelistIDs); */

        Map<String, Object> mockData = new Map<String, Object>();
        mockData.put(quote.Id, 11);
        mockData.put(quoteLineOne.Id, 11);
        PopulateTaxes.mockedResponse = JSON.serialize(mockData);
        PopulateTaxes.populateVertexTaxes(new Set<Id>{quote.Id});
        Test.stopTest();
    }

    
    @isTest 
    static void emptyResponse_Test(){
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];
        testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        
        Test.startTest(); 
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'HW-VG33'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To Three'];
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id, Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id, VertexCPQ__Tax_Amount__c=100, Tax_Calculation_Status__c = 'Updated');
        insert quote;
        
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, VertexCPQ__Tax_Amount__c=100);
        insert quoteLineOne; 
        
        PopulateTaxes.mockedResponse = '{}';
        PopulateTaxes.populateVertexTaxes(new Set<Id>{quote.Id});
        Test.stopTest();

        quote = [SELECT Id, VertexCPQ__Tax_Amount__c, Tax_Calculation_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        //System.assertEquals(null, quote.VertexCPQ__Tax_Amount__c);
        //System.assertEquals(PopulateTaxes.STATUS_TAX_CALCULATION_ERROR, quote.Tax_Calculation_Status__c);

        quoteLineOne = [SELECT Id, VertexCPQ__Tax_Amount__c FROM SBQQ__QuoteLine__c WHERE Id = :quoteLineOne.Id];
        //System.assertEquals(null, quoteLineOne.VertexCPQ__Tax_Amount__c);
    }
}