@isTest
public class OrderValidationServiceAutomationTest {
    @testSetup
    static void setup(){
        
        Id profileId = [SELECT Id,Name  FROM Profile WHERE Name LIKE '%AE2%' LIMIT 1].Id;
        Id ae2Role = [SELECT Id,Name FROM UserRole WHERE name LIKE '%AE2%' LIMIT 1].Id;
        
        User ae2User = createUser('AE2','Sales1',ae2Role,profileId,'AE2usr');
        
        insert ae2User;
        
        Id entRole = [SELECT Id,Name FROM UserRole WHERE name LIKE '%FLEET ENT AE%' LIMIT 1].Id;
        
        User entUser = createUser('ENT','Sales2',entRole,profileId,'ENTusr');
        
        insert entUser;        
    }

        @IsTest
        static void MexicoComplianceRequirementTest(){

        Test.startTest();

        User aeUser = [SELECT Id,Name FROM User WHERE alias = 'AE2Usr'];
        UserRole role = [SELECT Id,Name FROM UserRole WHERE Name like '%MX%' LIMIT 1];
        
        //createOVASetting(true,aeUser.Id,false);
        
        Account testAcc = createAccount('testAccount', aeUser.Id);
        Insert testAcc;

        opportunity opp = createOpportunity('testOppty',testAcc.Id,aeUser.Id, 'Due In Advance');
        opp.closeDate = System.today().addMonths(4);
        Insert opp;

        Opportunity oppRecrd = [SELECT Id, Payment_Terms__c, CurrencyIsoCode, Type, First_Purchase__c, initial_Payment_Terms__c, Finance_Segment_Stamp__c, Amount_Received__c, Alternative_Cable_Selection__c, Owner_Role_Copy__c, Segment_Sales_Role__c, Free_Trial_Purchase__c, Payment_Method__c FROM Opportunity WHERE Id = :opp.Id];
        
        oppRecrd.Type = 'Revenue Opportunity';
        oppRecrd.Payment_Terms__c = 'Due in advance';
        oppRecrd.Payment_Method__c = 'Credit Card';
        oppRecrd.Amount_Received__c = 20;
        oppRecrd.Owner_Role_Copy__c = role.Name;
        
        boolean result = new OrderValidationServiceAutomation().isMexicoComplianceRequirementOpty(oppRecrd, new Opportunity());

        Assert.isFalse(result);

        Test.stopTest();
    }
    
    public static void createOVASetting(Boolean ownerExp, string ownerId, Boolean dcaExp){
        Order_Validation_Setting__c ovaSetting = new Order_Validation_Setting__c();
        
        ovaSetting.Owner_Exception__c = ownerExp;
        ovaSetting.SetupOwnerId = ownerId;
        //ovaSetting.DCA_Owner_Exception__c = dcaExp;
        
        insert ovaSetting;
    }
	
    public static User createUser(string firstName, string lastName, string roleId, string profileId, string alias){
        User activeUser = new User(
                LastName = firstName,
                FirstName = lastName,
                Email = firstName+'.'+lastname+'@samsara.com',
                Username = firstName+'.'+lastname+'@samsara.com.test',
                ManagerId = UserInfo.getUserId(),
                UserRoleId = roleId,
                CompanyName = 'TEST',
                Title = 'title',
                Alias = alias,
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profileId,
                EmployeeNumber = 'abcdefg',
                IsActive = true   
        );
        return activeUser;
    }
    
    public static Account createAccount(String accountName, string userId){
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
        testAccount.Approved_Payment_Type__c = 'Direct Monthly';
     	testAccount.ownerid = userId;
        return testAccount;
    }

    public static Contact createContact(Id accountId) {
        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = accountId;
        testContact.Source__c = 'Adwords';
        testContact.Email = 'test@test.com';
        return testContact;
    }
    
    public static Shipping_Address__c createShippingAddress(Id accountId, Id contactId) {
        Shipping_Address__c shippingAddress = new Shipping_Address__c();
        shippingAddress.Account__c = accountId;
        shippingAddress.Shipping_Contact__c = contactId;
        shippingAddress.Shipping_Address_Line_1__c = '111 Test Drive';
        shippingAddress.Shipping_City__c = 'Testington';
        shippingAddress.Shipping_Country__c = 'Canada';
        shippingAddress.Name = 'Test';

        return shippingAddress;
    }
    
    public static Opportunity createOpportunity(string oppName, Id accId, string ownerId, string pTerms){
         Opportunity opp = new Opportunity(
             Name = oppName, 
             StageName = 'Purchase',
             CloseDate = Date.today(),
             Custom_Schedule__c = false,
             Type = 'Revenue Opportunity',
             Is_Webstore_Upsell_Opportunity__c = false,
             SBQQ__Renewal__c = false,
             Selected_Payment_Type__c = 'Upfront Payments',
             AccountId = accId,
             Payment_Terms__c = pTerms,
             Initial_Payment_Terms__c = pTerms,
             OwnerId = ownerId
              
        );
        return Opp;
    }
    
     static SBQQ__Quote__c createQuote(string oppId, string accId,string currencyVal){
        
        SBQQ__Quote__c qte = new SBQQ__Quote__c();
        qte.Quote_Name__c = 'Test Quote';
        qte.SBQQ__Opportunity2__c = oppId;
        qte.SBQQ__Primary__c = true;
        qte.SBQQ__Status__c='Approved';
        qte.SBQQ__StartDate__c = Date.today();
        qte.SBQQ__EndDate__c = Date.today().addMonths(12);
        qte.CurrencyIsoCode = currencyVal;
        return qte;
    }
    
    @IsTest
    static void AE2Test(){
        User aeUser = [SELECT Id,Name FROM User WHERE alias = 'AE2Usr'];
        
        createOVASetting(true,aeUser.Id,false);
        
        Account testAcc = createAccount('testAccount', aeUser.Id);
        Insert testAcc;
        
        Contact testCon = createContact(testAcc.Id);
        insert testCon;
        
        Shipping_Address__c shpngAddrs= createShippingAddress(testAcc.Id, testCon.Id);
        insert shpngAddrs;
        
        opportunity testopp = createOpportunity('testOppty',testAcc.Id,aeUser.Id, 'Due In Advance');
        testOpp.Amount_Received__c = 100;
        Insert testOpp;
        
        SBQQ__Quote__c cpqQuote = createQuote(testOpp.Id,testAcc.Id,'USD');
        Insert cpqQuote;
        
        Opportunity oppRecrd = new Opportunity();
        oppRecrd.Alternative_Cable_Selection__c = true;
        oppRecrd.Free_Trial_Purchase__c = 'Full Buy';
        oppRecrd.Initial_Payment_Terms__c = 'Due In Advance';
        oppRecrd.Id = testOpp.Id;
        oppRecrd.StageName = 'Closing';
        
        Test.startTest();
        SBQQ__Quote__c qte = new SBQQ__Quote__c();
        qte.Id = cpqQuote.Id;
        qte.SBQQ__Status__c = 'Approved';
        
        update qte;
        
        update oppRecrd;
        
        Test.stopTest();
        
    }
    
   @IsTest
    static void AE2netTermsTest(){
        User aeUser = [SELECT Id,Name FROM User WHERE alias = 'AE2Usr'];
        
        createOVASetting(true,aeUser.Id,false);
        
        Account testAcc = createAccount('testAccount', aeUser.Id);
        testAcc.Payment_Terms__c = 'Net 45';
        Insert testAcc;
        
        Contact testCon = createContact(testAcc.Id);
        insert testCon;
        
        Shipping_Address__c shpngAddrs= createShippingAddress(testAcc.Id, testCon.Id);
        insert shpngAddrs;
        
        opportunity testopp = createOpportunity('testOppty',testAcc.Id,aeUser.Id, 'Net 45');
        Insert testOpp;
        
        SBQQ.TriggerControl.disable();
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        
        Test.startTest();
        
        Opportunity oppRecrd = new Opportunity();
        oppRecrd.Alternative_Cable_Selection__c = true;
        oppRecrd.Free_Trial_Purchase__c = 'Full Buy';
        oppRecrd.Id = testOpp.Id;
        oppRecrd.StageName = 'Closing';
        
        update oppRecrd;
        
        Test.stopTest();
        
        TriggerHandler.clearbypass('OpportunityTriggerHandlerContext');
        TriggerHandler.clearbypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.clearbypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.clearbypass('OpportunityLineItemTriggerHandler');
    }
@IsTest
    static void AE2netTermsTestSubsidy(){
        User aeUser = [SELECT Id,Name FROM User WHERE alias = 'AE2Usr'];
        
        createOVASetting(true,aeUser.Id,false);
        
        Account testAcc = createAccount('testAccount', aeUser.Id);
        testAcc.Payment_Terms__c = 'Net 45';
        Insert testAcc;
        
        Contact testCon = createContact(testAcc.Id);
        insert testCon;
        
        Shipping_Address__c shpngAddrs= createShippingAddress(testAcc.Id, testCon.Id);
        insert shpngAddrs;
        
        opportunity testopp = createOpportunity('testOppty',testAcc.Id,aeUser.Id, 'Net 45');
        Insert testOpp;
        SBQQ.TriggerControl.disable();
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        SBQQ__Quote__c cpqQuote = createQuote(testOpp.Id,testAcc.Id,'USD');
        Insert cpqQuote;
        
        Product2 prod = new Product2(Name = 'INS-SUBSIDY', Family = 'Hardware', ProductCode = 'INS-SUBSIDY',Product_Type__c = 'License');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=testOpp.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;
        
        TriggerHandler.clearbypass('OpportunityTriggerHandlerContext');
        TriggerHandler.clearbypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.clearbypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.clearbypass('OpportunityLineItemTriggerHandler');
        Opportunity oppRecrd = new Opportunity();
        oppRecrd.Alternative_Cable_Selection__c = true;
        oppRecrd.Free_Trial_Purchase__c = 'Full Buy';
        oppRecrd.Id = testOpp.Id;
        oppRecrd.StageName = 'Closing';
        oppRecrd.SBQQ__PrimaryQuote__c = cpqQuote.id;
        update oppRecrd;

        
    }
 
	/*
    static testMethod void testRunAfter() {
        // Create test data
        Account testAccount = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', Record_Type_Stamp_for_Dupes__c = 'Fleet',Industry = 'Unknown',Enable_Delinquency_Process__c = false, Current_Telematics_Provider__c = 'Azuga', Number_of_Vehicles__c= 101);
        insert testAccount;

        Opportunity validOpportunity = new Opportunity(
            Name = 'Valid Opportunity', 
            StageName = 'Purchase',
            CloseDate = Date.today(),
            Custom_Schedule__c = false,
            Type = 'Revenue Opportunity',
            Owner_Role_Copy__c = 'Fleet IS AE2 NA MX Team 14',
            Owner_Manager_Role_Copy__c = 'Fleet IS AE2 NA MX Team 14',
            Is_Webstore_Upsell_Opportunity__c = false,
            SBQQ__Renewal__c = false,
            Bookings_Owner_Segment__c = 'AE2',
            Selected_Payment_Type__c = 'Upfront Payments',
            AccountId = testAccount.Id
        );
        insert validOpportunity;

        Opportunity invalidOpportunity = new Opportunity(
            Name = 'Invalid Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Custom_Schedule__c = false,
            Type = 'Revenue Opportunity',
            Owner_Role_Copy__c ='FTMS',
            Owner_Manager_Role_Copy__c = 'FTMS',
            Is_Webstore_Upsell_Opportunity__c = true,
            SBQQ__Renewal__c = true,
            AccountId = testAccount.Id
        );
        insert invalidOpportunity;

        // Create a new instance of the OrderValidationServiceAutomation class
        OrderValidationServiceAutomation orderValidationService = new OrderValidationServiceAutomation();

        // Create a Map of old Opportunities to pass to the runAfter method
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        oldOppMap.put(validOpportunity.Id, validOpportunity);
        oldOppMap.put(invalidOpportunity.Id, invalidOpportunity);
        
        opportunity newValidOpp = validOpportunity;
        newValidOpp.StageName = 'Closing';
        
        Opportunity oppRec = [SELECT Id,name,StageName,Owner_Segment__c,Custom_Schedule__c,Type,Owner_Role_Copy__c,Owner_Manager_Role_Copy__c,Finance_Segment__c,Is_Webstore_Upsell_Opportunity__c,Payment_Type__c,SBQQ__Renewal__c FROM Opportunity WHERE Id =:validOpportunity.Id];
        
        System.debug(oppRec.StageName);
        System.debug(oppRec.Owner_Segment__c);
        System.debug(oppRec.Custom_Schedule__c);
        System.debug(oppRec.Type);
        System.debug(oppRec.Owner_Role_Copy__c);
        System.debug(oppRec.Owner_Manager_Role_Copy__c);
        System.debug(oppRec.Finance_Segment__c);
        System.debug(oppRec.Is_Webstore_Upsell_Opportunity__c);
        System.debug(oppRec.Payment_Type__c);

        // Call the runAfter method and assert the expected output
        Test.startTest();
        orderValidationService.runAfter(new List<Opportunity>{newValidOpp, invalidOpportunity}, oldOppMap);
        orderValidationService.outOfScopeCheck(newValidOpp);

        Test.stopTest();

    }
	*/
}