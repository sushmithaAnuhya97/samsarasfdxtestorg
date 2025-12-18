/**********************************************************************
Name: DiscountApprovalHelper_Test
=======================================================================
Purpose: This is test class for DiscountApprovalHelper                                                       
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2024-May-29        INITIAL DEVELOPMENT FOR GTMS-20146
***********************************************************************/ 
@isTest(SeeAllData=false)
public class DiscountApprovalHelper_Test {
    @testSetup
    private static void testDataSetup() {
        
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        
        User currentUser = [SELECT Id,name FROM User WHERE Id=:userInfo.getuserId()];
        User ae2User;
        User entUser;
        system.runAs(currentUser){
            Id profileId = [SELECT Id,Name  FROM Profile WHERE Name LIKE '%AE2%' LIMIT 1].Id;
            Id ae2Role = [SELECT Id,Name FROM UserRole WHERE name LIKE '%AE2%' LIMIT 1].Id;
            
            ae2User = OrderValidationServiceAutomationTest.createUser('AE2','Sales1',ae2Role,profileId,'AE2usr');
            
            insert ae2User;
            
            Id entRole = [SELECT Id,Name FROM UserRole WHERE name LIKE '%FLEET ENT AE%' LIMIT 1].Id;
            
            entUser = OrderValidationServiceAutomationTest.createUser('ENT','Sales2',entRole,profileId,'ENTusr');
            
            insert entUser;
        }
        
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
        // ABU:GTMS-15650 09/18/2023
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account partnerAccount = new Account (Name = 'Test Partner Account',RecordTypeId = accRecordTypeId,Partner_Type__c ='Insurance',Program_Type__c ='Subsidy', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        newAccount.add(partnerAccount);
        // ABU:GTMS-15650 09/18/2023--> End
        insert newAccount;
        
        Customer_360__c c360 = new Customer_360__c(LIC_AG2_Discount__c=1,LIC_AG4_Discount__c=1,LIC_CM1_Discount__c=1,LIC_CM2_Discount__c=1,
                                                   LIC_CRGO_Discount__c=1,LIC_DM11_Discount__c=1,LIC_VG_Discount__c=1,LIC_AG4P_Discount__c=1,
                                                   LIC_EM_Discount__c=1,Account__c=account.Id);
        insert c360;
        
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
                                                         CloseDate = System.today() + 90, Owner_Role_Copy__c='Industrial',StageName = 'Incubate');            
        // ABU:GTMS-15650 09/18/2023
        Opportunity revenueOpportunitywithInsurancePartner = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                                             Max_Approved_Discount__c=0, Name = 'Revenue OpportunitywithInPartner', Price_Book_Name__c = 'Standard Price Book', 
                                                                             CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8',Insurance_Partner__c=partnerAccount.Id);
        // ABU:GTMS-15650 09/18/2023 --> End
        
        newOpportunities.add(revenueOpportunity);
        newOpportunities.add(revenueOpportunitywithInsurancePartner);
        insert newOpportunities;
        //List<SBQQ__Quote__c> quoteLst = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c =revenueOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, Buyout_Amount__c = null, 
                                                  Subsidy_Amount__c=300.0,SBQQ__Primary__c = false, Custom_License_Term__c = 2, Selected_Payment_Type__c='Direct Quarterly');
        
        
        insert quote;
        
        
    } 
    @isTest public static void validateApproval(){
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Primary__c,Configuration_Segment__c,Buyout_Amount__c,Subsidy_Amount__c 
                                FROM SBQQ__Quote__c WHERE Quote_Name__c='First Quote'];
        Test.startTest();
        List<Id> quoteIds = new List<Id>();
        quoteIds.add(quote.id);
        DiscountApprovalHelper.validateApprovalAttributes(quoteIds);
        Test.stopTest();
    }
    
    @isTest public static void validateApproval2(){
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Primary__c,Configuration_Segment__c,Buyout_Amount__c,Subsidy_Amount__c 
                                FROM SBQQ__Quote__c WHERE Quote_Name__c='First Quote'];
        List<Quote_Approval_Attribute__c> qaaList = new List<Quote_Approval_Attribute__c>();
        
        Quote_Approval_Attribute__c qaa1 = new Quote_Approval_Attribute__c(Quote__c=quote.Id, Field_API_Name__c='Buyout_Amount__c', Field_Value__c='1000');
        qaaList.add(qaa1);
        Quote_Approval_Attribute__c qaa2 = new Quote_Approval_Attribute__c(Quote__c=quote.Id, Field_API_Name__c='of_HW_Products__c', Field_Value__c='100');
        qaaList.add(qaa2);
        Quote_Approval_Attribute__c qaa3 = new Quote_Approval_Attribute__c(Quote__c=quote.Id, Field_API_Name__c='Of_LIC_Products__c', Field_Value__c='100');
        qaaList.add(qaa3);
        Quote_Approval_Attribute__c qaa4 = new Quote_Approval_Attribute__c(Quote__c=quote.Id, Field_API_Name__c='Selected_Payment_Type__c', Field_Value__c='Direct Annual');
        qaaList.add(qaa4);
        Quote_Approval_Attribute__c qaa5 = new Quote_Approval_Attribute__c(Quote__c=quote.Id, Field_API_Name__c='Subsidy_Amount__c', Field_Value__c='1000');
        qaaList.add(qaa5);
        Quote_Approval_Attribute__c qaa6 = new Quote_Approval_Attribute__c(Quote__c=quote.Id, Field_API_Name__c='Total_License_Price__c', Field_Value__c='100000');
        qaaList.add(qaa6);
        
        insert qaaList;
        quote.ApprovalStatus__c='Recalled';
        //quote.Subsidy_Amount__c=null;
        update quote;
        Test.startTest();
        List<Id> quoteIds = new List<Id>();
        quoteIds.add(quote.id);
        DiscountApprovalHelper.validateApprovalAttributes(quoteIds);
        Test.stopTest();
    }
}