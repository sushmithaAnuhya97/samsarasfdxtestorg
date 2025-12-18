@isTest(SeeAllData=false)
public class JobReCalculateQuoteTest {
    
    //Static Account testAccount;
    //Static Opportunity testOpportunity;
    
    // Do not add any insert statements - It will cause CPU Time limit issues. Data insert until the quote is taking aroung 75% of CPU time.
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
        User usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE '%System Administrator%' LIMIT 1];
        
        System.runAs(usr) {
            Test.startTest();
            setupUsers(p.Id);
            Test.stopTest();
        }
        
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 50, StageName = 'Qualified', Type = 'Revenue Opportunity', SBQQ__Renewal__c = true);            
        // ABU:GTMS-15650 09/18/2023
        Opportunity revenueOpportunitywithInsurancePartner = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                                             Max_Approved_Discount__c=0, Name = 'Revenue OpportunitywithInPartner', Price_Book_Name__c = 'Standard Price Book', 
                                                                             CloseDate = System.today() + 50, StageName = 'Qualified',Insurance_Partner__c=partnerAccount.Id);
        // ABU:GTMS-15650 09/18/2023 --> End
        // 
        
        newOpportunities.add(revenueOpportunity);
        newOpportunities.add(revenueOpportunitywithInsurancePartner);
        
        User usr1 = [SELECT Id FROM User WHERE Name LIKE '%Elan%' AND IsActive = true LIMIT 1];
        System.runAs(usr1) {
            insert newOpportunities;
        }
        Contract objCon = new Contract();
        objCon.SBQQ__RenewalOpportunity__c = newOpportunities[0].Id;
        objCon.AccountId = newOpportunities[0].AccountId;
        objCon.EndDate = system.today().addDays(5);
        objCon.Auto_Renewal__c = true;
        objCon.ContractTerm = 1;
        insert objCon;
        //List<SBQQ__Quote__c> quoteLst = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c =revenueOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = true, Custom_License_Term__c = 2);
        
        
        insert quote;
       
        
        revenueOpportunity.SBQQ__PrimaryQuote__c = quote.Id;
        revenueOpportunity.SBQQ__RenewedContract__c = objCon.Id;
        revenueOpportunity.SBQQ__Renewal__c = true;
        revenueOpportunity.Shipping_Address_NEW__c = shipTo.Id;
        
        update revenueOpportunity;
        
    }
    
    @Future
    private static void setupUsers(Id profileId) {
        
        User activeUser = new User(
            LastName = 'Elan',
            FirstName = 'Renewal Pool',
            Email = 'puser001@test.com',
            Username = 'puser001@test.com' + System.currentTimeMillis(),
            ManagerId = UserInfo.getUserId(),
            UserRoleId = UserInfo.getUserRoleId(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'test2',
            CommunityNickName = 'CoolGuy',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            EmployeeNumber = 'abcdefg',
            IsActive = true,
            Team_Email_Alias__c = 'superawesometeam@email.com'
        );
        insert activeUser;
    }
    
    
    @isTest private static void updatingRecalculateFieldthroughSchedule() {
        
        List<SBQQ__Quote__c> quoteList = [Select Id from SBQQ__Quote__c];
        quoteList[0].Recalculate_Quote__c = true;
        quoteList[0].SBQQ__Primary__c = true;
        quoteList[0].Selected_Payment_Type__c = 'Upfront Payments';
        bypassTriggers();
        update quoteList;
        enableTriggers();
        String chron = '0 1 * * * ?';
        Test.StartTest();
        JobReCalculateQuote myClass = new JobReCalculateQuote(10); 
        system.schedule('Test Sched', chron, myClass);
        
        
        Test.stopTest();    
        
        //SBQQ__Quote__c quote = [Select Id,Recalculate_Quote__c from SBQQ__Quote__c where Id =:quoteList[0].Id];  
        
        //system.assert(true,quote.Recalculate_Quote__c);
        
    } 
    
    
    @isTest private static void updatingRecalculateField() {
        
        List<SBQQ__Quote__c> quoteList = [Select Id, Renewal_Data_Error_Category__c,SBQQ__NetAmount__c  from SBQQ__Quote__c limit 1];
        system.debug('gg log ------- ' + quoteList);
        quoteList[0].Recalculate_Quote__c = true;
            
        quoteList[0].SBQQ__Primary__c = true;
        quoteList[0].Selected_Payment_Type__c = 'Upfront Payments';
        bypassTriggers();
        update quoteList;
        enableTriggers();
       
        
        
        Test.StartTest();
        String query = 'Select id,SBQQ__PrimaryQuote__c from Opportunity limit 1';
        
        Database.executeBatch(new JobReCalculateQuote(false, query));
        
        Test.stopTest(); 
        
        
        // SBQQ__Quote__c quote = [Select Id,Recalculate_Quote__c from SBQQ__Quote__c where Id =:quoteList[0].Id];  
        
        //system.assert(true,quote.Recalculate_Quote__c);
        
    }
    
    public static void bypassTriggers() {
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        SBQQ.TriggerControl.disable();        
    }
    
    public static void enableTriggers() {
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
    }
    
}