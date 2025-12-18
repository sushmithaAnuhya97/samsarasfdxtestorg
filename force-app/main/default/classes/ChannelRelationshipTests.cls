@isTest
public class ChannelRelationshipTests {

    @TestSetup
    static void createChannelRelationshipTestData(){
        

        List<Account> newAccounts = new List<Account>();

        Account account = new Account(  Name = 'Testers 1 Inc',
                                        BillingCountry = 'United States',
                                        BillingState = 'California',
                                        Organization_Size__c = '100 - 499',
                                        Industry = 'Other');
        newAccounts.add(account);

        Account partnerAccount = new Account(   Name = 'Partner Testers',
                                                BillingCountry = 'United Kingdom',
                                                Organization_Size__c = '100 - 499',
                                                Industry = 'Other', 
                                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId());
        newAccounts.add(partnerAccount);
        insert newAccounts;

        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();

        // Create Contact
        List<Contact> newContacts = new List<Contact>();
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=account.Id);
        newContacts.add(contact);
        insert newContacts;

        //Create Opportunity
        Opportunity revenueOpportunity = new Opportunity( Name = 'Channel Opportunity Test', AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate');            
        insert revenueOpportunity;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote', SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c =revenueOpportunity.Id, 
                                                  SBQQ__Primary__c = false, SBQQ__Status__c = 'Draft');
        insert quote;
        
    }
    @isTest
    static void ChannelRelationshipTests() {
		Account customerAccount = [SELECT Id, Name FROM Account WHERE Name = 'Testers 1 Inc'];
        Account partnerAccount = [SELECT Id, Name FROM Account WHERE Name = 'Partner Testers'];
        Opportunity channelOpportunity = [SELECT Id, Name FROM Opportunity WHERE Name = 'Channel Opportunity Test'];

        Test.startTest();
        Channel_Relationship__c channelRelationship = new Channel_Relationship__c(Customer_Account__c = customerAccount.Id,Channel_Partner__c = partnerAccount.Id, Opportunity__c = channelOpportunity.Id);
        insert channelRelationship;
        Test.stopTest();

        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Partner__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = : channelOpportunity.Id];
        system.assert(quote.SBQQ__Partner__c != null);
    }
    
    @isTest
    static void getCountryStateCodeTest() {
        ChannelRelationshipHelper.countryStateCodeReq req = new ChannelRelationshipHelper.countryStateCodeReq();
        req.countryName='United States';
        req.stateName='Texas';
        List<ChannelRelationshipHelper.countryStateCodeReq> reqList = new List<ChannelRelationshipHelper.countryStateCodeReq>();
        reqList.add(req);
        ChannelRelationshipHelper.getCountryStateCode(reqList);
    }
}