@isTest
public class ContractSubscriptionRollupBatchTest {
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
        Product2 agLicense = new Product2(Name= 'LIC-AG-12MO', ProductCode = 'LIC-AG-12MO', Family = 'Test');
        products.add(agLicense);
        Product2 scLicense = new Product2(Name= 'LIC-SC31', ProductCode = 'LIC-SC31', Family = 'Test');
        products.add(scLicense);
        Product2 cmLicense = new Product2(Name= 'LIC-CM1-36MO', ProductCode = 'LIC-CM1-36MO', Family = 'Test');
        products.add(cmLicense); 
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
        
        list<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = cont.id,
            SBQQ__Account__c = newAccount[0].id,
            SBQQ__Product__c = vgLicense.id

        );
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = cont.id,
            SBQQ__Account__c = newAccount[0].id,
            SBQQ__Product__c = agLicense.id

        );
         SBQQ__Subscription__c sub3 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = cont.id,
            SBQQ__Account__c = newAccount[0].id,
            SBQQ__Product__c = scLicense.id

        );
         SBQQ__Subscription__c sub4 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = cont.id,
            SBQQ__Account__c = newAccount[0].id,
            SBQQ__Product__c = cmLicense.id

        );
        subList.add(sub1);
        subList.add(sub2);
        subList.add(sub3);
        subList.add(sub4);
        insert subList;
        
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
        
        Shipping_Address__c shipToThree = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, 
                                                                  Shipping_Address_Line_1__c = '1 Parliment St'
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
        
        Shipping_Address__c shipToMexico = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '1 Parliment St'
                                                            , Shipping_Address_Line_2__c= 'XYZ'
                                                            , Shipping_City__c = 'Mexico'
                                                            , Shipping_State__c = 'Distrito Federal'       
                                                            , Shipping_Country__c ='Mexico'
                                                            , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Mexico');
        
        shippingAddresses.add(shipToMexico);
        
        insert shippingAddresses;
            
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8'); 
        newOpportunities.add(revenueOpportunity);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity2', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null); 
        
        newOpportunities.add(revenueOpportunity2); 
        insert newOpportunities;

    }
    
    @isTest static void ContractSubscriptionRollupBatch1() {
        
        ContractSubscriptionRollupBatchSchedular cs = new ContractSubscriptionRollupBatchSchedular ();
         String sch = '0 0 23 * * ?';
         system.schedule('Test status Check', sch, cs );
        ContractSubscriptionRollupBatch jcop = new ContractSubscriptionRollupBatch();
        Database.executeBatch(jcop);
        
    }
}