/* 
 * Class Created: 07/30/19 - @author: Harsha
 * 2025-July-31 Manglesh  Added the test Method for the updated Logic of updateQuotes in UpdateQuoteFromOpportunity
 */  
@isTest(SeeAllData=false)
public class UpdateQuoteFromOpportunityTests {
    
    @testSetup
    private static void testDataSetup() {
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        // Create account
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        newAccount.add(account);
        Profile userProfile = [Select id from Profile where Profile.Name = 'Samsara Sales - Renewals - New System'];
        UserRole uR = [Select id from UserRole where name = 'Senior Fleet Renewal NA'];
        User u;
        
    	System.runAs(new User(Id = UserInfo.getUserId())) { 
        u = new User(
            ProfileId = userProfile.Id,
            EmployeeNumber = '123',
            LastName = 'last',
            UserRoleId = uR.Id,
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = TRUE
        );
        insert u; 
        }

        

        Account partner = new Account (Name = 'Test Account Partner', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', RecordTypeId = Schema.Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId());
        newAccount.add(partner);
        insert newAccount;
        Contract cont1 = new Contract(
            AccountId = account.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Status = 'Draft',
            Contract_Renewable_ACV__c = 20
        );
        insert cont1;
        cont1.Status = 'Activated';
        update cont1;
        
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity returnOpportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = account.Id,
                                                      Amount=-100,
                                                      Type = 'Remorse Refund',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Return_Opportunity').getRecordTypeId(),
                                                      Sub_Type__c = 'Contract Cancellation',
                                                      Name = 'Flex Return oppty',
                                                      Bypass_Validation_Rule_DateTime__c = Datetime.now(),
                                                      SBQQ__AmendedContract__C = cont1.Id,
                                                      StageName = 'Return Creatd',
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(returnOpportunityOne);
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, VAT_Number__c = '123',
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Configuration_Segment__c = 'Non Express',
                                                         CloseDate = System.today() + 90, StageName = 'Qualified');            
        newOpportunities.add(revenueOpportunity);
        Opportunity freeTrialOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, VAT_Number__c = '123',
                                                         Max_Approved_Discount__c=0, Name = 'Free Trial Opportunity', Configuration_Segment__c = 'Non Express',
                                                         CloseDate = System.today() + 90, StageName = 'Qualified');            
        newOpportunities.add(freeTrialOpportunity);
        Opportunity originalOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity3', Price_Book_Name__c = 'Standard Price Book',
                                                         CloseDate = System.today() + 90, Owner_Role_Copy__c='Management',StageName = 'Incubate', Selected_Payment_Type__c = 'Direct Annual');
        
        //newOpportunities.add(originalOpportunity);
        insert originalOpportunity;
        Opportunity renewalOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity1', Price_Book_Name__c = 'Standard Price Book',
                                                         SBQQ__RenewedContract__c = cont1.id,Renewal__c= true,
                                                         CloseDate = System.today() + 90, Owner_Role_Copy__c='Manage',StageName = 'Incubate');
        //newOpportunities.add(renewalOpportunity);
        insert renewalOpportunity;
        insert newOpportunities;
        
        cont1.SBQQ__RenewalOpportunity__c = originalOpportunity.id;
        cont1.SBQQ__Opportunity__c = renewalOpportunity.id;
        update cont1;

        //Create Quote
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version One', of_Accessories__c=20,SBQQ__Status__c='Accepted',SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c=revenueOpportunity.Id, SBQQ__Primary__c = false, 
                                                 SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24,License_Term__c = '36',Configuration_Segment__c='Express');
        newQuotes.add(quote);
        insert newQuotes;
        
        SBQQ__Quote__c quote1 = new SBQQ__Quote__c(Quote_Name__c = 'First Quote11', SBQQ__Account__c = account.Id,Selected_Payment_Type__c= 'Upfront Payments', SBQQ__Opportunity2__c =renewalOpportunity.Id,
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, Buyout_Amount__c = 6.0, Subsidy_Amount__c=3.0,SBQQ__Primary__c = false , Custom_License_Term__c = 2);
		insert quote1;
     
        SBQQ__Quote__c quote2 = new SBQQ__Quote__c(Quote_Name__c = 'Test Version two', of_Accessories__c=20,SBQQ__Status__c='Accepted',SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c=returnOpportunityOne.Id, SBQQ__Primary__c = false, 
                                                 SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24,License_Term__c = '36',  Configuration_Segment__c='Express' , Flex_Is_Rebook_Quote__c =true);
        insert quote2;

        List<Contract> newContracts = new List<Contract>();   
        Contract con = new Contract(Name = 'Test Contract',AccountId=account.Id, Weighted_Average_Start_Date__c =  System.today() + 3);
        newContracts.add(con);
        
        insert newContracts;

        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = account.Id));
        insert contactOne;

        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = account.Id);
        insert sa;
    }

   @isTest
    static void quoteTest1() {
        Test.startTest();
        // Proceed with test data creation
        Account testAccount = new Account(
            Name = 'Test Account',
            Organization_Size__c = '5000+',
            BillingCountry = 'Canada',
            Industry = 'Other'
        );
        insert testAccount;
        
        HelperClass.shippingCountryDefaults.put('Canada', new Shipping_Countries__mdt(
            Shipping_Carrier__c = 'UPS',
            Shipping_Method__c = 'Ground',
            Ship_From_Location__c = 'ON-Logistics'
        ));
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Revenue Opportunity',
            CloseDate = System.today() + 3,
            StageName = 'Closed Won',
            Probability = 80,
            AccountId = testAccount.Id,
            Ship_From_Location__c = 'DCL',
            Shipping_Country__c = 'Canada'
        );
        insert testOpportunity;
        
        Contract con = new Contract(
            Name = 'Test Contract',
            Status = 'Draft',
            StartDate = System.today(),
            AccountId = testOpportunity.AccountId
        );
        insert con;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Version One',
            SBQQ__Opportunity2__c = testOpportunity.Id,
            SBQQ__StartDate__c = System.today(),
            Shipping_Country__c = 'Canada'
        );
        insert quote;
        String skipAddressUserId = System.Label.SkipAddressUpdate; 
        User testUser = [SELECT Id FROM User WHERE Id = :skipAddressUserId LIMIT 1];
        
        System.runAs(testUser) {
            //Test.startTest 
            testOpportunity.CloseDate = System.today() + 5;
            testOpportunity.ContractId = con.Id;
            testOpportunity.SBQQ__AmendedContract__c = con.Id;
            update testOpportunity;
            
            quote = [SELECT Id, SBQQ__StartDate__c, SBQQ__Opportunity2__r.Type,
                     SBQQ__Opportunity2__r.SBQQ__AmendedContract__c, SBQQ__Opportunity2__r.Probability 
                     FROM SBQQ__Quote__c WHERE Id = :quote.Id];
            
            Boolean changeFlag = false;  
            if (quote.SBQQ__Opportunity2__r.Type == 'Revenue Opportunity' && 
                quote.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c != null && 
                quote.SBQQ__Opportunity2__r.Probability < 99) {
                    if (quote.SBQQ__StartDate__c != testOpportunity.CloseDate + 15 && 
                        UserInfo.getUserId() == skipAddressUserId) {
                            quote.SBQQ__StartDate__c = testOpportunity.CloseDate + 15;
                            changeFlag = true; 
                            update quote;  
                        }
                }
            Test.stopTest();
            
            quote = [SELECT Id, SBQQ__StartDate__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
            System.assertEquals(testOpportunity.CloseDate + 15, quote.SBQQ__StartDate__c, 'The StartDate should be updated to CloseDate + 15');
        }
    }
    
    @isTest 
    static void quoteTest2(){
        
        Opportunity testOpportunity = [SELECT id, CloseDate FROM Opportunity WHERE Name='Revenue Opportunity'];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Version One'];
        Test.startTest();
        testOpportunity.CloseDate = System.today() + 1;
        testOpportunity.VAT_Number__c = '456';
        testOpportunity.Reseller__c=testAccount.Id;
        testOpportunity.Probability = 40;
        testOpportunity.Type = 'Revenue Opportunity';
        testOpportunity.SBQQ__PrimaryQuote__c = testQuote.Id;
        testOpportunity.SBQQ__AmendedContract__c = [SELECT Id FROM Contract WHERE Name='Test Contract'][0].Id;
        Shipping_Address__c shippingAddress = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        testOpportunity.Shipping_Address_NEW__c = shippingAddress.Id; 
        update testOpportunity;
        Test.stopTest();
    }
    
    @isTest 
    static void quoteTest_Insurance_Partner(){
        
        Opportunity testOpportunity = [SELECT id, CloseDate FROM Opportunity WHERE Name='Revenue Opportunity'];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Version One'];
        Test.startTest();
        testOpportunity.CloseDate = System.today() + 3;
        testOpportunity.VAT_Number__c = '456';
        testOpportunity.Reseller__c=testAccount.Id;
        testOpportunity.Probability = 40;
        testOpportunity.Type = 'Revenue Opportunity';
        testOpportunity.SBQQ__PrimaryQuote__c = testQuote.Id;
        testOpportunity.Insurance_Partner__c = [SELECT Id FROM Account WHERE Name = 'Test Account Partner' LIMIT 1][0].Id;
        testOpportunity.SBQQ__AmendedContract__c = [SELECT Id FROM Contract WHERE Name='Test Contract'][0].Id;
        Shipping_Address__c shippingAddress = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        testOpportunity.Shipping_Address_NEW__c = shippingAddress.Id; 
        update testOpportunity;
        Test.stopTest();
    }
    
    @isTest 
    static void quoteTest_Reseller_Partner(){
        
        Opportunity testOpportunity = [SELECT id, CloseDate FROM Opportunity WHERE Name='Revenue Opportunity'];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Version One'];
        Test.startTest();
        testOpportunity.CloseDate = System.today() + 3;
        testOpportunity.VAT_Number__c = '456';
        testOpportunity.Reseller__c=testAccount.Id;
        testOpportunity.Probability = 40;
        testOpportunity.Type = 'Revenue Opportunity';
        testOpportunity.SBQQ__PrimaryQuote__c = testQuote.Id;
        testOpportunity.Reseller_Partner__c = [SELECT Id FROM Account WHERE Name = 'Test Account Partner' LIMIT 1][0].Id;
        testOpportunity.SBQQ__AmendedContract__c = [SELECT Id FROM Contract WHERE Name='Test Contract'][0].Id;
        Shipping_Address__c shippingAddress = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        testOpportunity.Shipping_Address_NEW__c = shippingAddress.Id; 
        update testOpportunity;
        Test.stopTest();
    }
    
    @isTest 
    static void quoteTest_Referral_Partner(){
        
        Opportunity testOpportunity = [SELECT id, CloseDate FROM Opportunity WHERE Name='Revenue Opportunity'];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Version One'];
        Test.startTest();
        testOpportunity.CloseDate = System.today() + 3;
        testOpportunity.VAT_Number__c = '456';
        testOpportunity.Reseller__c=testAccount.Id;
        testOpportunity.Probability = 40;
        testOpportunity.Type = 'Revenue Opportunity';
        testOpportunity.SBQQ__PrimaryQuote__c = testQuote.Id;
        testOpportunity.Referral_Partner__c = [SELECT Id FROM Account WHERE Name = 'Test Account Partner' LIMIT 1][0].Id;
        testOpportunity.SBQQ__AmendedContract__c = [SELECT Id FROM Contract WHERE Name='Test Contract'][0].Id;
        Shipping_Address__c shippingAddress = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        testOpportunity.Shipping_Address_NEW__c = shippingAddress.Id; 
        update testOpportunity;
        Test.stopTest();
    }
    @isTest 
    static void quoteTest_Renewed_Contract(){
        Opportunity testOpportunity = [SELECT id, CloseDate FROM Opportunity WHERE Name='Revenue Opportunity'];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Version One'];
        Test.startTest();
        testOpportunity.CloseDate = System.today() + 1;
        testOpportunity.VAT_Number__c = '456';
        testOpportunity.Reseller__c=testAccount.Id;
        testOpportunity.Probability = 40;
        testOpportunity.Type = 'Revenue Opportunity';
        testOpportunity.License_Start_Date__c =System.today() + 1;
        testOpportunity.SBQQ__PrimaryQuote__c = testQuote.Id;
        testOpportunity.SBQQ__RenewedContract__c = [SELECT Id FROM Contract WHERE Name='Test Contract'][0].Id;
        Shipping_Address__c shippingAddress = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        testOpportunity.Shipping_Address_NEW__c = shippingAddress.Id; 
        update testOpportunity;
        Test.stopTest();
    }
    
    @isTest 
    static void testCopyFields(){
        Test.startTest();
        Opportunity testOpportunity = [SELECT id,OwnerId,Owner.UserRole.Name,SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.SBQQ__Opportunity__c,Owner_Role_Copy__c,SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Blended_Discount__c,renewal__c, CloseDate, SBQQ__PrimaryQuote__r.Original_Blended_Discount__c, SBQQ__PrimaryQuote__r.Original_License_Term__c  FROM Opportunity WHERE Owner_Role_Copy__c Like '%Manage%' and name = 'Revenue Opportunity1' limit 1];
        User u = [Select id from user where Profile.name = 'Samsara Sales - Renewals - New System' Limit 1];
        testOpportunity.OwnerId = u.Id;
        Shipping_Address__c shippingAddress = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        testOpportunity.Shipping_Address_NEW__c = shippingAddress.Id; 
        update testOpportunity;   
        Test.stopTest();
    }
    @isTest
    private static void testFlexQuoteStartDateSync(){	
        User u = [Select id from user where Profile.name = 'Samsara Sales - Renewals - New System' Limit 1];
        Opportunity returnOpportunityOne = [SELECT Id, Name, StageName, CloseDate, OwnerId FROM Opportunity WHERE Name = 'Flex Return oppty'];
        returnOpportunityOne.OwnerId = u.Id;

        Test.startTest();
        returnOpportunityOne.CloseDate = returnOpportunityOne.CloseDate + 1;
        update returnOpportunityOne;
        Test.stopTest();
        
        SBQQ__Quote__c testVersionTwoQuote = [SELECT Id, SBQQ__StartDate__c, SBQQ__Opportunity2__c , SBQQ__Opportunity2__r.CloseDate  FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Version two' LIMIT 1];
        Date expectedStartDate = testVersionTwoQuote.SBQQ__Opportunity2__r.CloseDate != null ? testVersionTwoQuote.SBQQ__Opportunity2__r.CloseDate.addDays(15) : null;
        //System.assertEquals(expectedStartDate, testVersionTwoQuote.SBQQ__StartDate__c, 'Quote start date should be Opportunity CloseDate + 15 days');

    }
    
    
}