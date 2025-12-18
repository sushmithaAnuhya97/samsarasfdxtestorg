/**********************************************************************
Name: NewDealRegLeadOwnerHandler_Test
=======================================================================
Purpose: This class will contain test class for New Deal Reg Owner Handler                                                       
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-May-15        INITIAL DEVELOPMENT FOR GTMS-11208

***********************************************************************/

@IsTest
public class NewDealRegLeadOwnerHandler_Test {
	Static Account testAccount;
    Static Opportunity testOpportunity;
    static Contract testContract;
    //private stac final Id pricebookId = Test.getStandardPricebookId();
    private static List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
    
	// Do not add any insert statements - It will cause CPU Time limit issues. Data insert until the quote is taking aroung 75% of CPU time.
    @testSetup
    private static void testDataSetup() {
        
        
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        User objProfileADR = [select Id, IsActive, Profile.Name, UserRole.Name from User where IsActive = true and UserRole.Name like '%ADR%' order by Id limit 1];
        User objProfileAE = [select Id, IsActive, Profile.Name, UserRole.Name from User where IsActive = true and Profile.Name like '%AE2%' order by Id limit 1];
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33-BUNDLE', Family = 'Test', Geo_Availablity__c='USA');
        products.add(vg33);
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test', Geo_Availablity__c='USA');
        products.add(vgLicense);       
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        
        insert pricebookEntries;
        
        // Create account
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', 
                                       OwnerId = objProfileADR.id, Enterprise_Assignment__c=null );
        newAccount.add(account);
        
        Account account2 = new Account (Name = 'Test Account2', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', 
                                        OwnerId = objProfileADR.id, Enterprise_Assignment__c='Abbey Wilson' );
        newAccount.add(account2);
        
        Account account3 = new Account (Name = 'Test Account3', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', 
                                        OwnerId = objProfileADR.id, Inside_Sales_Assignment__c='Adam Regos' );
        newAccount.add(account3);
        
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
        
        Contact contact2 = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=account2.Id);
        newContacts.add(contact2);
        
        Contact contact3 = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=account3.Id);
        newContacts.add(contact3);
        insert newContacts;
        
        //Create Shipping Address
        List<Shipping_Address__c> shippingAddresses = new  List<Shipping_Address__c>();
        
       	Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                            , Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                            , Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
        shippingAddresses.add(shipTo);        
        
        Shipping_Address__c shipToTwo = new Shipping_Address__c(Account__c = account2.Id, Shipping_Contact__c = contact2.Id, Shipping_Address_Line_1__c = '610 Park View Dr'
                                                            , Shipping_Address_Line_2__c= 'XYZ', Shipping_City__c = 'Santa Clara'
                                                            , Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                            , Shipping_Zip_Code__c = '95054', Name = 'Ship To Two');
        
        shippingAddresses.add(shipToTwo);   
        
        Shipping_Address__c shipToThree = new Shipping_Address__c(Account__c = account3.Id, Shipping_Contact__c = contact3.Id, 
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
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId,Shipping_Country__c='United States',
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8'); 
        newOpportunities.add(revenueOpportunity);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = account2.Id, License_Term__c =36, Pricebook2Id = pricebookId,Shipping_Country__c='United States', 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity2', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', 
                                                          Shipping_Address_NEW__c=null); 
        
        newOpportunities.add(revenueOpportunity2); 
        Opportunity revenueOpportunity3 = new Opportunity( AccountId = account3.Id, License_Term__c =36, Pricebook2Id = pricebookId,Shipping_Country__c='United States', 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity3', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Not Shipped', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8',
                                                          Shipping_Address_NEW__c=null); 
        
        newOpportunities.add(revenueOpportunity3); 
        
        insert newOpportunities;
        
        Book_Of_Business__c book = new Book_Of_Business__c();
        book.name = 'test book of business';
        book.Active__c = true;
        book.AE__c=objProfileAE.id;
        insert book;
        
        account.Books_Of_Business__c = book.id;
        update account;
    }
    
    @isTest 
    static void validateAssignedOwner(){
        List<OpportunityLineItem> newLines = new List<OpportunityLineItem>();
        Opportunity oppty = [SELECT id, Name, Type, VAT_Number__c, VAT_Validation_Status__c, List_Price__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        List<NewDealRegLeadOwnerHandler.ownerValidationInput> inputList = new List<NewDealRegLeadOwnerHandler.ownerValidationInput>();
        NewDealRegLeadOwnerHandler.ownerValidationInput input = new NewDealRegLeadOwnerHandler.ownerValidationInput();
        input.opportunityId = oppty.Id;
        inputList.add(input);
        NewDealRegLeadOwnerHandler.validateAssignedOwner(inputList);
    }
    
    /*@isTest 
    static void validateAssignedOwner(){
        List<OpportunityLineItem> newLines = new List<OpportunityLineItem>();
        Opportunity oppty = [SELECT id, Name, Type, VAT_Number__c, VAT_Validation_Status__c, List_Price__c FROM Opportunity WHERE Name = 'Revenue Opportunity' LIMIT 1];
        List<NewDealRegLeadOwnerHandler.ownerValidationInput> inputList = new List<NewDealRegLeadOwnerHandler.ownerValidationInput>();
        NewDealRegLeadOwnerHandler.ownerValidationInput input = new NewDealRegLeadOwnerHandler.ownerValidationInput();
        input.opportunityId = oppty.Id;
        inputList.add(input);
        NewDealRegLeadOwnerHandler.validateAssignedOwner(inputList);
    }
    
    @isTest 
    static void validateAssignedOwner2(){
        List<OpportunityLineItem> newLines = new List<OpportunityLineItem>();
        Opportunity oppty = [SELECT id, Name, Type, VAT_Number__c, VAT_Validation_Status__c, List_Price__c FROM Opportunity WHERE Name = 'Revenue Opportunity2' LIMIT 1];
        List<NewDealRegLeadOwnerHandler.ownerValidationInput> inputList = new List<NewDealRegLeadOwnerHandler.ownerValidationInput>();
        NewDealRegLeadOwnerHandler.ownerValidationInput input = new NewDealRegLeadOwnerHandler.ownerValidationInput();
        input.opportunityId = oppty.Id;
        inputList.add(input);
        NewDealRegLeadOwnerHandler.validateAssignedOwner(inputList);
    }
    @isTest 
    static void validateAssignedOwner3(){
        List<OpportunityLineItem> newLines = new List<OpportunityLineItem>();
        Opportunity oppty = [SELECT id, Name, Type, VAT_Number__c, VAT_Validation_Status__c, List_Price__c FROM Opportunity WHERE Name = 'Revenue Opportunity3' LIMIT 1];
        List<NewDealRegLeadOwnerHandler.ownerValidationInput> inputList = new List<NewDealRegLeadOwnerHandler.ownerValidationInput>();
        NewDealRegLeadOwnerHandler.ownerValidationInput input = new NewDealRegLeadOwnerHandler.ownerValidationInput();
        input.opportunityId = oppty.Id;
        inputList.add(input);
        NewDealRegLeadOwnerHandler.validateAssignedOwner(inputList);
    }*/
    
    @isTest 
    static void validateAssignedOwner4(){
        //Book_Of_Business__c book = [select id from Book_Of_Business__c limit 1];
        Account accnt = [SELECT id, Name, Books_Of_Business__r.AE__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        //accnt.Books_Of_Business__c = book.id;
        //update accnt;
        
        List<NewDealRegLeadOwnerHandler.ownerValidationInput> inputList = new List<NewDealRegLeadOwnerHandler.ownerValidationInput>();
        NewDealRegLeadOwnerHandler.ownerValidationInput input = new NewDealRegLeadOwnerHandler.ownerValidationInput();
        input.accountId = accnt.Id;
        inputList.add(input);
        NewDealRegLeadOwnerHandler.validateAssignedOwner(inputList);
    }
}