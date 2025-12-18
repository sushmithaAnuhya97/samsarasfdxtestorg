@isTest(SeeAllData=false)
public class QuoteOpptyOwnerPnPPilotControllerTest {
    
    
    public static testmethod void QuoteOpptyOwnerPnPPilotControllerMethod1() {
        
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        
        User currentUser = [SELECT Id,name FROM User WHERE Id=:userInfo.getuserId()];
        User ae2User;
        User entUser;
        system.runAs(currentUser){
            Id profileId = [SELECT Id,Name  FROM Profile WHERE Name LIKE '%AE2%' LIMIT 1].Id;
            Id ae2Role = [SELECT Id,Name FROM UserRole WHERE name LIKE '%AE2%' LIMIT 1].Id;
            
            ae2User = OrderValidationServiceAutomationTest.createUser('AE2','Sales1',ae2Role,profileId,'AE2usr');
            ae2User.P_P_Pilot__c = true;
            insert ae2User;
            
            Id entRole = [SELECT Id,Name FROM UserRole WHERE name LIKE '%FLEET ENT AE%' LIMIT 1].Id;
            
            entUser = OrderValidationServiceAutomationTest.createUser('ENT','Sales2',entRole,profileId,'ENTusr');
            ae2User.P_P_Pilot__c = true;
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
        
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        
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
        
        // Create Contact
        List<Contact> newContacts = new List<Contact>();
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=account.Id);
        newContacts.add(contact);
        
        insert newContacts;
            
        //Create Opportunity
       
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         closeDate = System.today() + 90, Owner_Role_Copy__c='Industrial',StageName = 'Incubate');            
         // ABU:GTMS-15650 09/18/2023
         Opportunity revenueOpportunitywithInsurancePartner = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue OpportunitywithInPartner', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90,  StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8',Insurance_Partner__c=partnerAccount.Id);
        // ABU:GTMS-15650 09/18/2023 --> End
       
        newOpportunities.add(revenueOpportunity);
        newOpportunities.add(revenueOpportunitywithInsurancePartner);
        insert newOpportunities;
        //List<SBQQ__Quote__c> quoteLst = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c =revenueOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, Oppty_Owner_PnP_Pilot__c = true,Buyout_Amount__c = 6.0, Subsidy_Amount__c=3.0,SBQQ__Primary__c = false, Custom_License_Term__c = 2);
       
        
        insert quote;
        QuoteOpptyOwnerPnPPilotController.updatePilotOnQuote(quote.Id);
    }

}