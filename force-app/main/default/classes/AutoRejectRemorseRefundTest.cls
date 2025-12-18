@isTest
public class AutoRejectRemorseRefundTest {
    @testSetup 
    public static void dataSetup() {
        
 	Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        
        insert accountOne;

        Contact contact = new Contact(FirstName = 'Test', LastName='Tester', AccountId = accountOne.Id, Email = 'test@test.com');
        insert contact;

        Opportunity opp = new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 2 Inc',
                                                      StageName = 'Decision',
                                                      Shipping_Contact__c = contact.Id, 
                                                      CloseDate = Date.today());

        insert opp;

        Opportunity opp1 = new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Remorse Refund',
                                                      Name = 'RRF',
                                                     Shipping_Contact__c = contact.Id, 
                                      				StageName = 'Return Initiated',     
                                           			CloseDate = Date.today(), Returning_Opportunity__c = opp.id);

        insert opp1;
        
    }
    
    @isTest
    public static void testMethod1() {
        
        Opportunity opportunity = [SELECT id, StageName, Return_Label_Sent_At__c FROM Opportunity WHERE Type = 'Remorse Refund'];
        opportunity.StageName = 'Return Label Sent';
        opportunity.Return_Label_Sent_At__c = Date.Today() - 62;
        
        Test.startTest();
        update opportunity;
        AutoRejectRemorseRefunds b = new AutoRejectRemorseRefunds();
        database.executebatch(b,200);
        Test.stopTest();
    }

}