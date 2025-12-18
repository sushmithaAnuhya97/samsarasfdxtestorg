@isTest
public class OpportunityReturnProcessesTest {
    
    @testSetup
    private static void testSetup(){
        insert new Global_Automation_Settings__c(Name = 'Automation_Settings',Allow_Handler_Selection__c = true);
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
        
        //Test Accounts
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Critically_Escalated_Hardware_Returns__c=true,
                                Industry = 'Other');
        newAccounts.add(accountOne);
        
        Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                BillingState='California',
                                BillingCountry = 'United States',
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                Industry = 'Other');
        newAccounts.add(accountTwo);

        insert newAccounts;
        
        //Test COntacts
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        newContacts.add(contactOne);
        
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'test@test.com'));
        newContacts.add(contactTwo);

        insert newContacts;
        
        //Test Shipping Address
        Shipping_Address__c sa1 = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
        shippingAddressList.add(sa1);
        Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = accountOne.Id);
        shippingAddressList.add(sa2);
        Shipping_Address__c sa3 = new Shipping_Address__c(Shipping_Zip_Code__c = 'C.P. 45610', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Adolf B Horn 1737-1', Shipping_City__c='San Pedro Tlaquepaque, Jal', Shipping_Country__c='Mexico', Name='Test Mexico', Account__c = accountOne.Id);
        shippingAddressList.add(sa3);
        
        insert shippingAddressList;
        
        //Test Opportunities
        Opportunity returningOppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactTwo.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert returningOppty;
    }
    
    @isTest private static void testMethod001(){
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        
        System.debug('test Method 001');
        Opportunity ReturningOppty = [Select id,Shipmate_Preference__c from Opportunity where name = 'Returning Oppty 001'];
        Account accountOne = [Select id from Account where name = 'Testers 1 Inc'];
        Contact contactOne = [Select id from Contact where AccountId =:accountOne.id ];
        Shipping_Address__c sa1 = [select id from Shipping_Address__c where name ='Test'];
        Shipping_Address__c sa2 = [select id from Shipping_Address__c where name ='Test Belgium'];
        Shipping_Address__c sa3 = [select id from Shipping_Address__c where name ='Test Mexico'];
        List<List<Opportunity>> opp = new List<List<Opportunity>>();
        List<Opportunity> oppList =  new List<Opportunity>();
        
        Test.startTest();
        Opportunity ReturnOppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Exchange',
                                                      Name = 'Return Opportunity 001',
                                                      StageName = 'Return initiated',
                                                      Returning_Opportunity__c = returningOppty.id,
                                                      amount = null,  
                                                      Rebate_Amount__c = null,
                                                      CloseDate = System.today() + 90,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id,
                                                     Shipping_Address_NEW__c = sa1.Id));
        Insert ReturnOppty;
        
        ReturnOppty.CloseDate = System.today() + 91;
        ReturnOppty.Shipping_Address_NEW__c = sa2.Id;
        ReturnOppty.Replacement_Opportunity__c = '/'+ReturningOppty.Id;
        Update ReturnOppty;
        ReturnOppty.Shipping_Address_NEW__c = sa3.Id;
        Update ReturnOppty;
        oppList.add(ReturnOppty);
        opp.add(oppList);
        //OpportunityReturnProcesses op = new OpportunityReturnProcesses(oppList,null);
        OpportunityReturnProcesses.createdRemorseRefund(opp);
        Test.stopTest();
        //System.assertEquals(null, ReturnOppty.Shipmate_Preference__c);
    }
}