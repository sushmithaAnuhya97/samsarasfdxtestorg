@IsTest
public class DiscountApprovalSLAAutomation_Test {
    @testSetup
    private static void testDataSetup() {
        
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);

        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            Name = 'Standard Price Book',
            IsActive = true
        );
        Update standardPricebook;
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
        //Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
        //products.add(vgLicense);
        /*Product2 em11 = new Product2(Name= 'HW-EM11', ProductCode = 'HW-EM11', Family = 'Test');
        products.add(em11);
        Product2 emLicense = new Product2(Name= 'LIC-EM-36MO', ProductCode = 'LIC-EM-36MO', Family = 'Test');
        products.add(emLicense);*/
        
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        //PricebookEntry em11PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = em11.Id, UnitPrice = 10000, IsActive = true);
        //pricebookEntries.add(em11PB);
        //PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        //pricebookEntries.add(vgLicensePB);
        //PricebookEntry emLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = emLicense.Id, UnitPrice = 10000, IsActive = true);
        //pricebookEntries.add(emLicensePB);
        
        insert pricebookEntries;
        
        // Create account
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        newAccount.add(account);

        insert newAccount;
        
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
                                                            , Shipping_City__c = 'Santa Clara', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                            , Shipping_Zip_Code__c = '95054', Name = 'Ship To Two');
        shippingAddresses.add(shipToTwo);
        
        insert shippingAddresses;
            
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate');            
        newOpportunities.add(revenueOpportunity);
        insert newOpportunities;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c =revenueOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = false, Custom_License_Term__c = 2);
        insert quote;
        
        SBQQ__Quote__c queriedInsertedQuote = [SELECT Id, SBQQ__StartDate__c FROM SBQQ__Quote__c Limit 1];
        
        sbaa__Approval__c approvalInsert = new sbaa__Approval__c();
        approvalInsert.Quote__c = queriedInsertedQuote.id;
        approvalInsert.sbaa__Status__c = 'Requested';
        approvalInsert.sbaa__RecordField__c = 'Quote__c';
        approvalInsert.sbaa__ApprovalStep__c = 1;
        insert approvalInsert;
        
    }
    
    @isTest 
    private static void runSLABreachAutomation() {
        SBQQ__Quote__c queriedInsertedQuote = [SELECT Id, SBQQ__StartDate__c FROM SBQQ__Quote__c Limit 1];
        sbaa__Approval__c approvalInsert = new sbaa__Approval__c();
        approvalInsert.Quote__c = queriedInsertedQuote.id;
        approvalInsert.sbaa__Status__c = 'Requested';
        approvalInsert.sbaa__RecordField__c = 'Quote__c';
        approvalInsert.sbaa__ApprovalStep__c = 1;
        insert approvalInsert;
        
        Test.startTest();
        
        Database.executeBatch(new DiscountApprovalSLAAutomation());
        Test.stopTest();
    }
    
    @IsTest
    private static void scheduleSLABreachAutomation(){
               
        String chron = '0 1 * * * ?';
        Test.startTest();
        
            DiscountApprovalSLAAutomation myClass = new DiscountApprovalSLAAutomation(); 
            system.schedule('Test Sched', chron, myClass);
            //database.executebatch(new SilentAutoRenewalBatch(),2);
        Test.stopTest();
    }
    
    

}