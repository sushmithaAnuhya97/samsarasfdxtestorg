@isTest
public class BatchUpdateContactTest {
	
    @testSetup 
    public static void dataSetup() {
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        Account accountTwo = new Account(Name = 'Testers 2 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
    	insert accountOne;
        Contact contactOne = (Contact)TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        insert contactOne;
        Contact contactTwo = (Contact)TestFactory.createSObject(new Contact(AccountId = accountTwo.Id));
        insert contactTwo;
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
        insert sa;
        List<Opportunity> lstOppty = new List<Opportunity>();
        for(Integer i=0; i<3; i++) {
        Opportunity opportunityOne = new Opportunity(AccountId = accountOne.Id, 
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Decision',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 505000,
                                                      Send_Invoice__c = false,
                                                      Related_Contact__c = contactOne.Id,
                                                      CloseDate = system.today()
                                                      //SalesLoft1__Most_Recent_Cadence_Name__c = 'SalesLoft1__Most_Recent_Cadence_Name__c'
                                                    );
            lstOppty.add(opportunityOne);
        }
        insert lstOppty;
        lstOppty[2].Related_Contact__c = contactTwo.Id;
        lstOppty[1].StageName = 'Closed Won';
        lstOppty[1].Amount = 5050000;
        update lstOppty;
        
        
    }
    @isTest
    public static void testMethod1() {
        BatchUpdateContact b = new BatchUpdateContact();
        database.executebatch(b,200);
        
        BatchUpdateContact sc = new BatchUpdateContact ();   
         String chron = '0 0 23 * * ?';        
         system.schedule('Test Sched', chron, sc);
    }
    
}