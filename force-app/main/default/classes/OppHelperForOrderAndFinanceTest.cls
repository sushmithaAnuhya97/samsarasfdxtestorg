@isTest
public class OppHelperForOrderAndFinanceTest {
   @testSetup
   static void setupTestData() {
       // Create Samsara - Finance Profile
       Profile financeProfile = [SELECT Id FROM Profile WHERE Name = 'Samsara - Finance' LIMIT 1];

       // Create a test user with financeProfile
       User financeUser = new User(
           FirstName = 'Test',
           LastName = 'User',
           Alias = 'tuser',
           Email = 'testuser@example.com',
           Username = 'testuser@example.com' + DateTime.now().getTime(),
           ProfileId = financeProfile.Id,
           TimeZoneSidKey = 'America/Los_Angeles',
           LocaleSidKey = 'en_US',
           EmailEncodingKey = 'UTF-8',
           LanguageLocaleKey = 'en_US',
           UserPermissionsOfflineUser = false,
           EmployeeNumber = '12345'
       );
       insert financeUser;
   }

   @isTest
   static void testUpdateOrderManagementProcessor() {
       User financeUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
       System.runAs(financeUser) {
           
			Account acc = new Account(
                Name = 'MyTestAccount',
                Type = 'Fleet',
                Industry = 'Other',
                Organization_Size__c = '1 - 99',
                BillingStreet = '123 Main St, San Francisco CA, 94110',
                BillingState = 'California',
                BillingCountry = 'United States',
                BillingCity = 'San Francisco',
                BillingPostalCode = '94110',
                Billing_Email__c = 'test@test.test'
            );
           insert acc;
           
           Contact con = new Contact(AccountId = acc.Id, LastName = 'test', Email = 'test@test.test');
           insert con;
           
           acc.Billing_Contact__c = con.Id;
           update acc;
           
           Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = acc.Id, Shipping_Contact__c = con.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                            , Shipping_City__c = 'San', Shipping_State__c = 'Ontario', Shipping_Country__c ='Canada'
                                                            , Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
           insert shipTo;
           Test.startTest();
           Opportunity oldOpp = new Opportunity(
               Shipping_Address_NEW__c = shipTo.Id,
               Name = 'Old Opportunity',
               Shipping_Country__c = 'Canada',
               StageName = 'Closing',
               CloseDate = Date.today(),
               AccountId = acc.Id
           );
           insert oldOpp;
		
           Opportunity newOpp1 = new Opportunity(
               Id = oldOpp.Id,
               Name = 'New Opportunity 1',
               StageName = 'Orders Processing',
               CloseDate = Date.today(),
               Order_Management_Processor__c = null,
			   AccountId = acc.Id
           );

           Opportunity oldOpp2 = new Opportunity(
               Shipping_Address_NEW__c = shipTo.Id,
               Name = 'Old Opportunity 2',
               Shipping_Country__c = 'Canada',
               StageName = 'Closing',
               CloseDate = Date.today(),
               AccountId = acc.Id
           );
           insert oldOpp2;

           Opportunity newOpp2 = new Opportunity(
               Id = oldOpp2.Id,
               Name = 'New Opportunity 2',
               StageName = 'Purchase',
               CloseDate = Date.today(),
               Order_Management_Processor__c = null,
			   AccountId = acc.Id
           );

           Opportunity oldOpp3 = new Opportunity(
               Shipping_Address_NEW__c = shipTo.Id,
               Name = 'Old Opportunity 3',
               Shipping_Country__c = 'Canada',
               StageName = 'Orders Processing',
               CloseDate = Date.today(),
               Order_Management_Processor__c = 'Previous User',
               AccountId = acc.Id
           );
           insert oldOpp3;

           Opportunity newOpp3 = new Opportunity(
               Id = oldOpp3.Id,
               Name = 'New Opportunity 3',
               StageName = 'Purchase',
               CloseDate = Date.today(),
               Order_Management_Processor__c = 'Previous User',
			   AccountId = acc.Id
           );

           // Prepare input data for the method
           List<Opportunity> newOppList = new List<Opportunity>{ newOpp1, newOpp2, newOpp3 };
           Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{ 
               oldOpp.Id => oldOpp, 
               oldOpp2.Id => oldOpp2, 
               oldOpp3.Id => oldOpp3 
           };

           // Call the method
           OppHelperForOrderAndFinance helper = new OppHelperForOrderAndFinance();
           helper.updateOrderManagementProcessor(newOppList, oldOppMap);
           
           Test.stopTest();
       }
   }
}